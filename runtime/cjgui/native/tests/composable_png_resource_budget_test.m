// Native production-path counterexample for PNG image resource accounting.
// This translation unit compiles the renderer implementation directly so the
// assertions observe its real decoder, cache, headroom check and close path.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>

#include <stdio.h>

static int fail(const char *message, int code) {
    fprintf(stderr, "png resource budget test: FAIL %s\n", message);
    return code;
}

static CjguiInternalRendererStatus prepare(CJGuiInternalSession *session, const char *identity,
                                           NSData *bytes, uint32_t *width, uint32_t *height) {
    uint64_t decodeMicros = 0;
    return cjgui_internal_renderer_prepare_composable_png_transfer(
        session.rendererSessionToken, identity, bytes.bytes, (uint32_t)bytes.length,
        width, height, &decodeMicros);
}

static BOOL stats(CJGuiInternalSession *session, uint32_t *entries, uint64_t *bytes,
                  uint32_t *inFlight, uint32_t *pending, uint32_t *records) {
    uint64_t loads = 0, decodes = 0;
    uint32_t references = 0, subscribers = 0, sessions = 0;
    return cjgui_internal_renderer_test_composable_application_image_domain_stats(
        session.rendererSessionToken, entries, bytes, inFlight, pending, &loads,
        &decodes, &references, &subscribers, &sessions, records) == CJGUI_INTERNAL_RENDERER_OK;
}

static id<MTLTexture> pressureTexture(id<MTLDevice> device) {
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor
        texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
        width:2048 height:2048 mipmapped:NO];
    descriptor.usage = MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModeShared;
    return [device newTextureWithDescriptor:descriptor];
}

static BOOL addBeaconSceneReference(CJGuiInternalSession *session, NSString *path, NSString *identity) {
    NSString *key = nil;
    for (NSUInteger attempt = 0; attempt < 500; attempt++) {
        uint32_t state = CjguiPrepareComposableImageResourceOnMain(
            session, session.rendererSessionToken, path, identity, 1, nil, YES, YES, &key);
        if (state == CjguiComposableImageResourceReady) {
            id<MTLTexture> texture = session.composableImageDomain.textureCache[key];
            if (!texture) return NO;
            CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
            CjguiInternalRendererComposableNode rawNode = {0};
            rawNode.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
            node.node = rawNode;
            node.imageTextureCacheKey = key;
            node.imageTexture = texture;
            if (!session.composableNodes) session.composableNodes = [NSMutableArray array];
            [session.composableNodes addObject:node];
            return YES;
        }
        if (state == CjguiComposableImageResourceFailed) return NO;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
    }
    return NO;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 4) return fail("usage: test <valid-3x2.png> <beacon.png> <beacon-coral.png>", 2);
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return fail("Metal device unavailable", 3);
        NSData *small = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
        NSString *beaconAPath = [NSString stringWithUTF8String:argv[2]];
        NSString *beaconBPath = [NSString stringWithUTF8String:argv[3]];
        if (!small || ![[NSFileManager defaultManager] fileExistsAtPath:beaconAPath] ||
            ![[NSFileManager defaultManager] fileExistsAtPath:beaconBPath]) {
            return fail("fixture or beacon input unavailable", 4);
        }

        CJGuiInternalSession *session = [[CJGuiInternalSession alloc] init];
        NSApplication *app = [NSApplication sharedApplication];
        CJGuiInternalComposableImageResourceDomain *domain =
            [[CJGuiInternalComposableImageResourceDomain alloc] initWithDevice:device];
        if (!session || !app || !domain) return fail("native session/domain initialization failed", 5);
        session.app = app;
        session.device = device;
        session.rendererSessionToken = 1;
        session.sessionGeneration = 1;
        session.composableImageDomain = domain;
        domain.sessionCount = 1;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;

        uint32_t width = 0, height = 0;
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
        if (!addBeaconSceneReference(session, beaconAPath, @"png-budget-beacon-blue") ||
            !addBeaconSceneReference(session, beaconBPath, @"png-budget-beacon-coral")) {
            return fail("normal two-beacon resource load did not complete", 6);
        }
        uint32_t baselineEntries = 0, inFlight = 0, pending = 0, records = 0;
        uint64_t baselineBytes = 0;
        if (!stats(session, &baselineEntries, &baselineBytes, &inFlight, &pending, &records) ||
            baselineEntries != 2 || records != 2 || baselineBytes == 0) {
            return fail("normal two-beacon baseline was not represented by two cached resources", 10);
        }
        fprintf(stdout, "png_budget baseline=2_beacons entries=%u records=%u cache_bytes=%llu\n",
                baselineEntries, records, (unsigned long long)baselineBytes);

        const char *smallId = "cjgui-transfer:budget-small-3x2";
        status = prepare(session, smallId, small, &width, &height);
        if (status != CJGUI_INTERNAL_RENDERER_OK || width != 3 || height != 2) {
            return fail("legal 3x2 PNG was not admitted with its parsed dimensions", 11);
        }
        NSString *smallIdentity = [NSString stringWithUTF8String:smallId];
        NSString *smallKey = CjguiComposableImageCacheKey(smallIdentity, smallIdentity, 0, NULL);
        id<MTLTexture> firstTexture = domain.textureCache[smallKey];
        CJGuiInternalComposableImageResource *smallResource = domain.resources[smallKey];
        uint32_t repeatedWidth = 0, repeatedHeight = 0;
        status = prepare(session, smallId, small, &repeatedWidth, &repeatedHeight);
        if (status != CJGUI_INTERNAL_RENDERER_OK || repeatedWidth != 3 || repeatedHeight != 2 ||
            !firstTexture || domain.textureCache[smallKey] != firstTexture ||
            smallResource.transferPreparationCount != 2) {
            return fail("repeated PNG identity did not reuse its accepted texture", 12);
        }
        if (cjgui_internal_renderer_finish_composable_png_transfer(1, smallId, 1) != CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, smallId, 1) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("repeated preparation acknowledgements failed", 13);
        }
        uint32_t replacementWidth = 0, replacementHeight = 0;
        NSData *replacement = [NSData dataWithContentsOfFile:beaconAPath];
        status = prepare(session, smallId, replacement, &replacementWidth, &replacementHeight);
        if (status != CJGUI_INTERNAL_RENDERER_PNG_INVALID) {
            return fail("same identity with replacement bytes was not rejected", 14);
        }
        fprintf(stdout, "png_budget small=accepted width=3 height=2 repeated=cache_hit replacement=png_invalid\n");

        // Two real 2048x2048 RGBA Metal allocations exhaust the 32 MiB live
        // texture budget. The weak native ledger sees these only while this
        // test-owned array keeps their true allocations alive.
        NSMutableArray<id<MTLTexture>> *pressure = [NSMutableArray array];
        id<MTLTexture> pressureA = pressureTexture(device);
        id<MTLTexture> pressureB = pressureTexture(device);
        if (!pressureA || !pressureB) return fail("could not allocate deterministic budget pressure textures", 15);
        [pressure addObjectsFromArray:@[ pressureA, pressureB ]];
        for (id<MTLTexture> texture in pressure) [domain.textureLedger addObject:texture];
        uint32_t entriesBeforeReject = 0, recordsBeforeReject = 0;
        uint64_t bytesBeforeReject = 0;
        if (!stats(session, &entriesBeforeReject, &bytesBeforeReject, &inFlight, &pending, &recordsBeforeReject)) {
            return fail("domain stats unavailable before no-headroom case", 16);
        }
        uint32_t rejectedWidth = 0, rejectedHeight = 0;
        status = prepare(session, "cjgui-transfer:budget-no-headroom", small, &rejectedWidth, &rejectedHeight);
        uint32_t entriesAfterReject = 0, recordsAfterReject = 0;
        uint64_t bytesAfterReject = 0;
        if (!stats(session, &entriesAfterReject, &bytesAfterReject, &inFlight, &pending, &recordsAfterReject)) {
            return fail("domain stats unavailable after no-headroom case", 17);
        }
        BOOL baselinePreserved = entriesAfterReject == baselineEntries && recordsAfterReject == baselineEntries &&
            bytesAfterReject == baselineBytes && session.composableNodes.count == 2 &&
            ((CJGuiInternalComposableSceneNode *)session.composableNodes[0]).imageTexture != nil &&
            ((CJGuiInternalComposableSceneNode *)session.composableNodes[1]).imageTexture != nil;
        if (status != CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED || !baselinePreserved) {
            fprintf(stderr, "png resource budget test: no-headroom status=%d entries=%u/%u records=%u/%u bytes=%llu/%llu ledger=%lu\n",
                    (int)status, entriesBeforeReject, entriesAfterReject, recordsBeforeReject, recordsAfterReject,
                    (unsigned long long)bytesBeforeReject, (unsigned long long)bytesAfterReject,
                    (unsigned long)domain.textureLedger.allObjects.count);
            return fail("no-headroom PNG was not rejected without changing cache/resource state", 18);
        }
        fprintf(stdout, "png_budget no_headroom=status_28 entries=%u records=%u cache_bytes=%llu baseline_preserved=true evictable_cache_reclaimed=true\n",
                entriesAfterReject, recordsAfterReject, (unsigned long long)bytesAfterReject);
        for (id<MTLTexture> texture in pressure) [domain.textureLedger removeObject:texture];
        [pressure removeAllObjects];
        pressureA = nil;
        pressureB = nil;

        status = prepare(session, "cjgui-transfer:budget-after-pressure-release", small, &width, &height);
        if (status != CJGUI_INTERNAL_RENDERER_OK || width != 3 || height != 2) {
            return fail("PNG admission did not recover after test-owned live budget was released", 19);
        }
        if (cjgui_internal_renderer_finish_composable_png_transfer(
                1, "cjgui-transfer:budget-after-pressure-release", 1) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("post-pressure acceptance acknowledgement failed", 20);
        }
        fprintf(stdout, "png_budget pressure_released=recovered\n");

        firstTexture = nil;
        smallResource = nil;
        session.composableNodes = nil;
        NSHashTable<id<MTLTexture>> *weakTextures = domain.textureLedger;
        CjguiReleaseComposableImageDomain(session);
        if (!domain.destroyed || domain.sessionCount != 0 || domain.textureCache.count != 0 ||
            domain.resources.count != 0 || domain.pendingKeys.count != 0 || domain.loaders.count != 0) {
            return fail("closing the last session did not clear image budget ownership", 21);
        }
        fprintf(stdout, "png_budget close=domain_destroyed cache=0 records=0 weak_ledger_after_clear=%lu\n",
                (unsigned long)weakTextures.allObjects.count);
        gCjguiSessionOccupied[0] = NO;
        gCjguiSessions[0] = nil;
    }
    return 0;
}
