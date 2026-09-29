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

static BOOL decodedPixelsMatchFixture(id<MTLDevice> device, id<MTLTexture> texture) {
    if (!texture || texture.width != 3 || texture.height != 2 ||
        (texture.pixelFormat != MTLPixelFormatRGBA8Unorm &&
         texture.pixelFormat != MTLPixelFormatBGRA8Unorm)) return NO;
    id<MTLCommandQueue> queue = [device newCommandQueue];
    id<MTLBuffer> buffer = [device newBufferWithLength:512 options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [command blitCommandEncoder];
    if (!queue || !buffer || !command || !blit) return NO;
    [blit copyFromTexture:texture sourceSlice:0 sourceLevel:0
             sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(3, 2, 1)
               toBuffer:buffer destinationOffset:0 destinationBytesPerRow:256
       destinationBytesPerImage:512];
    [blit endEncoding];
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return NO;
    const uint8_t *pixels = (const uint8_t *)buffer.contents;
    if (!pixels) return NO;
    const BOOL bgra = texture.pixelFormat == MTLPixelFormatBGRA8Unorm;
    const uint8_t expectedRGBA[3][4] = {
        {255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}
    };
    for (NSUInteger x = 0; x < 3; x++) {
        const uint8_t *actual = pixels + x * 4;
        const uint8_t *expected = expectedRGBA[x];
        if (actual[0] != expected[bgra ? 2 : 0] || actual[1] != expected[1] ||
            actual[2] != expected[bgra ? 0 : 2] || actual[3] != expected[3]) return NO;
    }
    return YES;
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

// Stage and "commit" one transfer image through the ordinary scene setter (the
// same entry a public declaration reaches), then promote the staged array the
// way a successful present does.
static BOOL commitTransferImageScene(CJGuiInternalSession *session, uint64_t version, int64_t nodeId,
                                     const char *identity, NSData *bytes) {
    CjguiInternalRendererComposableNode node = {0};
    node.projectionVersion = version;
    node.nodeId = nodeId;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
    node.width = 3; node.height = 2;
    node.clipWidth = 320; node.clipHeight = 160;
    if (cjgui_internal_renderer_configure_composable_scene(session.rendererSessionToken, version, 1) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    if (cjgui_internal_renderer_set_composable_scene_node_bytes(session.rendererSessionToken, 0, &node,
            "", "", identity, identity, 0, bytes.bytes, (uint32_t)bytes.length) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    session.composableNodes = [session.stagedComposableNodes mutableCopy];
    CjguiSettleComposableImageCandidateLeases(session.composableImageDomain, session, NO);
    CjguiPruneUnreferencedComposableTransferResources(session.composableImageDomain);
    return YES;
}

static id<MTLTexture> committedTextureForKey(CJGuiInternalSession *session, NSString *key) {
    for (CJGuiInternalComposableSceneNode *node in session.composableNodes) {
        if ([node.imageTextureContentKey isEqualToString:key]) return node.imageTexture;
    }
    return nil;
}

static BOOL budgetCounters(CJGuiInternalSession *session, uint64_t *outLoads, uint64_t *outDecodes,
                           uint64_t *outDecodeStarts) {
    uint32_t entries = 0, inFlight = 0, pending = 0, records = 0;
    uint32_t references = 0, subscribers = 0, sessions = 0;
    uint64_t bytes = 0, loads = 0, decodes = 0, sessionStarts = 0, domainStarts = 0;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_test_composable_application_image_domain_stats(
        session.rendererSessionToken, &entries, &bytes, &inFlight, &pending, &loads, &decodes,
        &references, &subscribers, &sessions, &records);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        status = cjgui_internal_renderer_test_composable_image_decode_start_count(
            session.rendererSessionToken, &sessionStarts, &domainStarts);
    }
    if (outLoads) *outLoads = loads;
    if (outDecodes) *outDecodes = decodes;
    if (outDecodeStarts) *outDecodeStarts = domainStarts;
    return status == CJGUI_INTERNAL_RENDERER_OK;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 12) return fail("usage: test <valid> <beacon> <beacon-coral> <over-dimension> <gray> <indexed> <rgb16> <bad-deflate> <valid-alt> <over-pixel> <valid-rgb>", 2);
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return fail("Metal device unavailable", 3);
        NSData *small = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
        NSData *overDimension = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[4]]];
        NSData *gray = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[5]]];
        NSData *indexed = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[6]]];
        NSData *rgb16 = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[7]]];
        NSData *badDeflate = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[8]]];
        NSData *validAlternate = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[9]]];
        NSData *overPixel = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[10]]];
        NSData *validRgb = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[11]]];
        NSString *beaconAPath = [NSString stringWithUTF8String:argv[2]];
        NSString *beaconBPath = [NSString stringWithUTF8String:argv[3]];
        if (!small || !overDimension || !gray || !indexed || !rgb16 || !badDeflate || !validAlternate ||
            !overPixel || !validRgb ||
            ![[NSFileManager defaultManager] fileExistsAtPath:beaconAPath] ||
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
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 320, 160)
            device:device commandQueue:[device newCommandQueue]];
        session.view.sessionToken = 1;
        CJGuiInternalSession *sourceSession = [[CJGuiInternalSession alloc] init];
        if (!sourceSession) return fail("source session initialization failed", 27);
        sourceSession.app = app;
        sourceSession.device = device;
        sourceSession.rendererSessionToken = 2;
        sourceSession.sessionGeneration = 2;
        sourceSession.composableImageDomain = domain;
        domain.sessionCount = 2;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;
        gCjguiSessions[1] = sourceSession;
        gCjguiSessionOccupied[1] = YES;

        // The public createBinary -> ImageFromTransfer declaration reaches
        // this ordinary scene setter without a clipboard prepare. It must be
        // rejected before an async decoder or retained record starts.
        CjguiInternalRendererComposableNode direct = {0};
        direct.projectionVersion = 1;
        direct.nodeId = 5001;
        direct.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
        direct.width = 48; direct.height = 48;
        direct.clipWidth = 320; direct.clipHeight = 160;
        if (cjgui_internal_renderer_configure_composable_scene(1, 1, 1) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("direct image scene configure failed", 30);
        }
        CjguiInternalRendererStatus directStatus = cjgui_internal_renderer_set_composable_scene_node_bytes(
            1, 0, &direct, "", "", "cjgui-transfer:direct-over-dimension",
            "cjgui-transfer:direct-over-dimension", 0, overDimension.bytes, (uint32_t)overDimension.length);
        if (directStatus != CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED ||
            domain.resources.count != 0 || domain.pendingKeys.count != 0 || domain.loaders.count != 0) {
            fprintf(stderr, "png direct admission: status=%d records=%lu pending=%lu loaders=%lu\n",
                (int)directStatus, (unsigned long)domain.resources.count,
                (unsigned long)domain.pendingKeys.count, (unsigned long)domain.loaders.count);
            return fail("direct public image exceeded dimensions before decoder admission", 31);
        }
        fprintf(stdout, "png_budget direct_over_dimension=predecode_rejected records=0 loads=0\n");
        CjguiInternalRendererStatus pixelStatus = cjgui_internal_renderer_set_composable_scene_node_bytes(
            1, 0, &direct, "", "", "cjgui-transfer:direct-over-pixel",
            "cjgui-transfer:direct-over-pixel", 0, overPixel.bytes, (uint32_t)overPixel.length);
        if (pixelStatus != CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED ||
            domain.resources.count != 0 || domain.pendingKeys.count != 0 || domain.loaders.count != 0) {
            return fail("direct public image exceeded pixel budget before decoder admission", 43);
        }
        fprintf(stdout, "png_budget direct_over_pixel=predecode_rejected records=0 loads=0\n");
        NSData *unsupported[] = {gray, indexed, rgb16};
        const char *variantNames[] = {"gray", "indexed", "rgb16"};
        for (NSUInteger variant = 0; variant < 3; variant++) {
            CjguiInternalRendererStatus variantStatus = cjgui_internal_renderer_set_composable_scene_node_bytes(
                1, 0, &direct, "", "", "cjgui-transfer:direct-unsupported",
                "cjgui-transfer:direct-unsupported", 0,
                unsupported[variant].bytes, (uint32_t)unsupported[variant].length);
            if (variantStatus != CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED ||
                domain.resources.count != 0 || domain.loaders.count != 0) {
                fprintf(stderr, "png variant=%s status=%d records=%lu loaders=%lu\n", variantNames[variant],
                    (int)variantStatus, (unsigned long)domain.resources.count, (unsigned long)domain.loaders.count);
                return fail("recognized PNG variant was not classified unsupported before decode", 32);
            }
        }
        CjguiInternalRendererStatus badDeflateStatus = cjgui_internal_renderer_set_composable_scene_node_bytes(
            1, 0, &direct, "", "", "cjgui-transfer:direct-bad-deflate",
            "cjgui-transfer:direct-bad-deflate", 0, badDeflate.bytes, (uint32_t)badDeflate.length);
        if (badDeflateStatus != CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED ||
            domain.resources.count != 0 || domain.loaders.count != 0) {
            return fail("CRC-correct invalid zlib image reached a scene or retained resource", 33);
        }
        fprintf(stdout, "png_budget unsupported=gray,indexed,rgb16 decode_failure=not_accepted\n");
        const char *abandonedId = "cjgui-transfer:direct-abandoned";
        if (cjgui_internal_renderer_set_composable_scene_node_bytes(1, 0, &direct, "", "",
                abandonedId, abandonedId, 0, small.bytes, (uint32_t)small.length) !=
                CJGUI_INTERNAL_RENDERER_OK || domain.resources.count != 1 ||
            cjgui_internal_renderer_discard_composable_scene_candidate(1) != CJGUI_INTERNAL_RENDERER_OK ||
            domain.resources.count != 0 || domain.textureCache.count != 0 ||
            session.stagedComposableNodes.count != 0) {
            return fail("abandoned direct candidate retained encoded/texture ownership", 34);
        }
        fprintf(stdout, "png_budget abandoned_candidate=record_and_texture_released\n");

        // A committed image outlives reusable cache ownership. Rebuilding
        // the same public declaration after eviction must re-admit the exact
        // immutable bytes and reuse that committed texture; substitution of
        // the same offer identity must fail before touching the accepted node.
        const char *rebuildId = "cjgui-transfer:direct-rebuild";
        if (cjgui_internal_renderer_configure_composable_scene(1, 1, 1) != CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_set_composable_scene_node_bytes(1, 0, &direct, "", "",
                rebuildId, rebuildId, 0, small.bytes, (uint32_t)small.length) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("initial direct image declaration was not admitted", 37);
        }
        session.composableNodes = [session.stagedComposableNodes mutableCopy];
        NSString *rebuildIdentity = [NSString stringWithUTF8String:rebuildId];
        NSString *rebuildKey = CjguiComposableImageCacheKey(rebuildIdentity, rebuildIdentity, 0, NULL);
        id<MTLTexture> committedTexture = ((CJGuiInternalComposableSceneNode *)session.composableNodes[0]).imageTexture;
        if (!committedTexture) return fail("initial direct image has no decoded texture", 38);
        [domain.textureCache removeObjectForKey:rebuildKey];
        [domain.resources removeObjectForKey:rebuildKey];
        if (cjgui_internal_renderer_configure_composable_scene(1, 2, 1) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("cache-rebuild scene configure failed", 39);
        }
        direct.projectionVersion = 2;
        if (cjgui_internal_renderer_set_composable_scene_node_bytes(1, 0, &direct, "", "",
                rebuildId, rebuildId, 0, small.bytes, (uint32_t)small.length) != CJGUI_INTERNAL_RENDERER_OK ||
            ((CJGuiInternalComposableSceneNode *)session.stagedComposableNodes[0]).imageTexture != committedTexture ||
            !domain.resources[rebuildKey] || domain.resources[rebuildKey].transferPreparationCount != 0) {
            return fail("cache rebuild failed to re-admit and reuse exact committed bytes", 40);
        }
        NSData *replacementBytes = validAlternate;
        CjguiInternalRendererStatus replacementStatus = cjgui_internal_renderer_set_composable_scene_node_bytes(
            1, 0, &direct, "", "", rebuildId, rebuildId, 0,
            replacementBytes.bytes, (uint32_t)replacementBytes.length);
        if (replacementStatus != CJGUI_INTERNAL_RENDERER_PNG_INVALID ||
            ((CJGuiInternalComposableSceneNode *)session.composableNodes[0]).imageTexture != committedTexture) {
            fprintf(stderr, "png budget replacement status=%d resource=%lu encoded=%lu bytes=%lu\n",
                (int)replacementStatus, (unsigned long)domain.resources.count,
                (unsigned long)domain.resources[rebuildKey].encodedData.length,
                (unsigned long)replacementBytes.length);
            return fail("same identity replacement bypassed immutable transfer admission", 41);
        }
        [session.composableNodes removeAllObjects];
        if (cjgui_internal_renderer_discard_composable_scene_candidate(1) != CJGUI_INTERNAL_RENDERER_OK ||
            domain.resources.count != 0 || domain.textureCache.count != 0) {
            return fail("cache rebuild candidate resources survived rejection", 42);
        }
        committedTexture = nil;
        fprintf(stdout, "png_budget cache_rebuild=same_texture_revalidated replacement=rejected cleanup=0\n");

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
        const char *sourceOnlyId = "cjgui-transfer:source-close-owned";
        if (prepare(sourceSession, sourceOnlyId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_finish_composable_png_transfer(2, sourceOnlyId, 1) !=
                CJGUI_INTERNAL_RENDERER_OK) {
            return fail("source window could not prepare its own transferable image", 35);
        }
        NSString *sourceOnlyIdentity = [NSString stringWithUTF8String:sourceOnlyId];
        NSString *sourceOnlyKey = CjguiComposableImageCacheKey(sourceOnlyIdentity, sourceOnlyIdentity, 0, NULL);
        if (!domain.resources[sourceOnlyKey] || !domain.textureCache[sourceOnlyKey]) {
            return fail("source-owned image was not retained before close", 36);
        }
        if (cjgui_internal_renderer_destroy(2) != CJGUI_INTERNAL_RENDERER_OK ||
            domain.destroyed || domain.sessionCount != 1 ||
            domain.resources[sourceOnlyKey] || domain.textureCache[sourceOnlyKey] ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, "cjgui-transfer:not-prepared", 1) !=
                CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED) {
            return fail("closing source retained its orphan PNG or released target's shared domain", 28);
        }
        fprintf(stdout, "png_budget source_close=orphan_released domain_retained target_session_live=true\n");

        status = prepare(session, "cjgui-transfer:rgb-positive", validRgb, &width, &height);
        NSString *rgbIdentity = @"cjgui-transfer:rgb-positive";
        NSString *rgbKey = CjguiComposableImageCacheKey(rgbIdentity, rgbIdentity, 0, NULL);
        id<MTLTexture> rgbTexture = domain.textureCache[rgbKey];
        if (status != CJGUI_INTERNAL_RENDERER_OK || width != 3 || height != 2 ||
            !decodedPixelsMatchFixture(device, rgbTexture) ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, "cjgui-transfer:rgb-positive", 0) !=
                CJGUI_INTERNAL_RENDERER_OK || domain.resources[rgbKey] || domain.textureCache[rgbKey]) {
            return fail("supported 8-bit RGB did not decode or release like RGBA", 44);
        }
        rgbTexture = nil;
        fprintf(stdout, "png_budget rgb_8bit=decoded_pixels_match rgba_8bit=decoded_pixels_match\n");

        const char *smallId = "cjgui-transfer:budget-small-3x2";
        status = prepare(session, smallId, small, &width, &height);
        if (status != CJGUI_INTERNAL_RENDERER_OK || width != 3 || height != 2) {
            return fail("legal 3x2 PNG was not admitted with its parsed dimensions", 11);
        }
        NSString *smallIdentity = [NSString stringWithUTF8String:smallId];
        NSString *smallKey = CjguiComposableImageCacheKey(smallIdentity, smallIdentity, 0, NULL);
        id<MTLTexture> firstTexture = domain.textureCache[smallKey];
        CJGuiInternalComposableImageResource *smallResource = domain.resources[smallKey];
        if (!decodedPixelsMatchFixture(device, firstTexture)) {
            return fail("decoded 3x2 PNG RGB pixels do not match source fixture", 29);
        }
        fprintf(stdout, "png_budget decoded_pixels=red,green,blue source_rgb_match=true\n");
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
        if (cjgui_internal_renderer_finish_composable_png_transfer(1, smallId, 1) !=
            CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED) {
            return fail("extra finish consumed a preparation that did not exist", 22);
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
        BOOL rejectPreserved = entriesAfterReject == entriesBeforeReject &&
            recordsAfterReject == recordsBeforeReject && bytesAfterReject == bytesBeforeReject &&
            session.composableNodes.count == 2 &&
            ((CJGuiInternalComposableSceneNode *)session.composableNodes[0]).imageTexture != nil &&
            ((CJGuiInternalComposableSceneNode *)session.composableNodes[1]).imageTexture != nil;
        if (status != CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED || !rejectPreserved) {
            fprintf(stderr, "png resource budget test: no-headroom status=%d entries=%u/%u records=%u/%u bytes=%llu/%llu ledger=%lu\n",
                    (int)status, entriesBeforeReject, entriesAfterReject, recordsBeforeReject, recordsAfterReject,
                    (unsigned long long)bytesBeforeReject, (unsigned long long)bytesAfterReject,
                    (unsigned long)domain.textureLedger.allObjects.count);
            return fail("no-headroom PNG was not rejected without changing cache/resource state", 18);
        }
        // The rejected admission reclaimed nothing: under this pressure the only
        // non-scene entry is the accepted transfer whose owning candidate has not
        // been staged yet, and a pending candidate hold is deliberately not an
        // eviction victim. The hold ends with the candidate cycle, so a discard
        // releases it and the ordinary transfer prune reclaims the entry.
        if (cjgui_internal_renderer_discard_composable_scene_candidate(1) != CJGUI_INTERNAL_RENDERER_OK ||
            domain.resources[smallKey] || domain.textureCache[smallKey]) {
            return fail("accepted transfer hold survived its candidate cycle", 66);
        }
        uint32_t entriesAfterSettle = 0, recordsAfterSettle = 0;
        uint64_t bytesAfterSettle = 0;
        if (!stats(session, &entriesAfterSettle, &bytesAfterSettle, &inFlight, &pending, &recordsAfterSettle) ||
            entriesAfterSettle != baselineEntries || recordsAfterSettle != baselineEntries ||
            bytesAfterSettle != baselineBytes) {
            fprintf(stderr, "png resource budget test: settle entries=%u/%u records=%u/%u bytes=%llu/%llu\n",
                entriesAfterSettle, baselineEntries, recordsAfterSettle, baselineEntries,
                (unsigned long long)bytesAfterSettle, (unsigned long long)baselineBytes);
            return fail("released cache did not return to the two-beacon baseline", 67);
        }
        firstTexture = nil;
        smallResource = nil;
        fprintf(stdout,
                "png_budget no_headroom=status_28 entries=%u records=%u cache_bytes=%llu reject_preserved=true "
                "pending_hold_released_by_discard=true entries_after_settle=%u\n",
                entriesAfterReject, recordsAfterReject, (unsigned long long)bytesAfterReject, entriesAfterSettle);
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

        // ---- F-A pressure handoff: the 9th transfer image under a full cache ----
        // Eight images are committed in ONE accepted scene through the ordinary
        // setter, so all eight reusable-cache entries are protected by scene
        // references. The ninth is a transfer preparation whose owning node does
        // not exist yet: exactly the gap between "admitted" and "candidate owns it".
        NSMutableArray<NSString *> *pressureKeys = [NSMutableArray array];
        const NSUInteger pressureCount = 8;
        const uint64_t pressureVersion = 100;
        (void)cjgui_internal_renderer_discard_composable_scene_candidate(1);
        if (cjgui_internal_renderer_configure_composable_scene(session.rendererSessionToken, pressureVersion,
                (uint32_t)pressureCount) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("pressure scene configure failed", 45);
        }
        for (NSUInteger index = 0; index < pressureCount; index++) {
            char identity[64];
            snprintf(identity, sizeof(identity), "cjgui-transfer:pressure-%lu", (unsigned long)index);
            CjguiInternalRendererComposableNode node = {0};
            node.projectionVersion = pressureVersion;
            node.nodeId = 6000 + (int64_t)index;
            node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
            node.width = 3; node.height = 2;
            node.clipWidth = 320; node.clipHeight = 160;
            if (cjgui_internal_renderer_set_composable_scene_node_bytes(session.rendererSessionToken,
                    (uint32_t)index, &node, "", "", identity, identity, 0, small.bytes,
                    (uint32_t)small.length) != CJGUI_INTERNAL_RENDERER_OK) {
                return fail("pressure image node could not be staged", 46);
            }
            NSString *identityValue = [NSString stringWithUTF8String:identity];
            NSString *key = CjguiComposableImageCacheKey(identityValue, identityValue, 0, NULL);
            if (!key || !domain.textureCache[key]) return fail("pressure image was not decoded", 46);
            [pressureKeys addObject:key];
        }
        session.composableNodes = [session.stagedComposableNodes mutableCopy];
        for (NSString *key in pressureKeys) {
            if (!committedTextureForKey(session, key)) {
                return fail("pressure image missing from the committed scene", 46);
            }
        }
        // Clean slate for the handoff measurement: only the eight pressure
        // entries (all scene-referenced) may remain evictable-cache content.
        NSSet<NSString *> *pressureKeySet = [NSSet setWithArray:pressureKeys];
        for (NSString *key in [domain.textureCache.allKeys copy]) {
            if ([pressureKeySet containsObject:key]) continue;
            [domain.textureCache removeObjectForKey:key];
            [domain.resources removeObjectForKey:key];
        }
        if (domain.textureCache.count != pressureCount) {
            fprintf(stderr, "png handoff pressure cache=%lu expected=%lu\n",
                (unsigned long)domain.textureCache.count, (unsigned long)pressureCount);
            return fail("pressure scene did not leave exactly eight cached images", 46);
        }

        // Negative control: with the candidate lease suppressed, the accepted
        // ninth image is the only evictable key and the scene that follows must
        // decode the same bytes a second time.
        const char *unleasedId = "cjgui-transfer:pressure-ninth-unleased";
        NSString *unleasedIdentity = [NSString stringWithUTF8String:unleasedId];
        NSString *unleasedKey = CjguiComposableImageCacheKey(unleasedIdentity, unleasedIdentity, 0, NULL);
        uint64_t decodesBeforeUnleased = 0, loadsBeforeUnleased = 0, startsBeforeUnleased = 0;
        if (!budgetCounters(session, &loadsBeforeUnleased, &decodesBeforeUnleased, &startsBeforeUnleased)) {
            return fail("domain stats unavailable before the unleased pressure case", 47);
        }
        cjgui_internal_renderer_test_set_png_candidate_lease_enabled(0);
        if (prepare(session, unleasedId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK ||
            !domain.textureCache[unleasedKey] ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, unleasedId, 1) !=
                CJGUI_INTERNAL_RENDERER_OK) {
            return fail("unleased ninth image could not be prepared and accepted", 48);
        }
        BOOL unleasedEvicted = domain.textureCache[unleasedKey] == nil &&
            CjguiComposableImageDomainBoundTexture(domain, unleasedKey) == nil;
        if (!unleasedEvicted) {
            return fail("unleased ninth image was not evicted by the accepted-path prune", 49);
        }
        if (!commitTransferImageScene(session, 200, 7000, unleasedId, small)) {
            return fail("scene declaring the unleased ninth image was rejected", 50);
        }
        // The setter must re-admit synchronously when the handoff is missing.
        // Its own lease is suppressed in this negative control, so no texture
        // reaches the staged node; an unbudgeted generic loader is forbidden.
        id<MTLTexture> unleasedStaged = committedTextureForKey(session, unleasedKey);
        uint64_t decodesAfterUnleased = 0, loadsAfterUnleased = 0, startsAfterUnleased = 0;
        if (!budgetCounters(session, &loadsAfterUnleased, &decodesAfterUnleased, &startsAfterUnleased) ||
            loadsAfterUnleased != loadsBeforeUnleased || unleasedStaged ||
            decodesAfterUnleased != decodesBeforeUnleased ||
            startsAfterUnleased != startsBeforeUnleased + 2) {
            fprintf(stderr, "png handoff unleased decode_starts=%llu/%llu completions=%llu/%llu loads=%llu/%llu staged=%p\n",
                (unsigned long long)startsBeforeUnleased, (unsigned long long)startsAfterUnleased,
                (unsigned long long)decodesBeforeUnleased, (unsigned long long)decodesAfterUnleased,
                (unsigned long long)loadsBeforeUnleased, (unsigned long long)loadsAfterUnleased,
                (__bridge void *)unleasedStaged);
            return fail("unleased pressure case bypassed admission or retained a texture", 52);
        }
        fprintf(stdout,
                "png_handoff unleased=evicted_no_generic_fallback decode_starts=%llu->%llu completions=%llu->%llu loads=%llu->%llu staged_texture=%s\n",
                (unsigned long long)startsBeforeUnleased, (unsigned long long)startsAfterUnleased,
                (unsigned long long)decodesBeforeUnleased, (unsigned long long)decodesAfterUnleased,
                (unsigned long long)loadsBeforeUnleased, (unsigned long long)loadsAfterUnleased,
                unleasedStaged ? "late" : "absent_until_completion");

        // Fixed branch: the same pressure, with the candidate lease holding the
        // prepared texture until the scene that owns it is staged.
        cjgui_internal_renderer_test_set_png_candidate_lease_enabled(1);
        const char *ninthId = "cjgui-transfer:pressure-ninth";
        NSString *ninthIdentity = [NSString stringWithUTF8String:ninthId];
        NSString *ninthKey = CjguiComposableImageCacheKey(ninthIdentity, ninthIdentity, 0, NULL);
        uint64_t decodesBeforeNinth = 0, loadsBeforeNinth = 0, startsBeforeNinth = 0;
        if (!budgetCounters(session, &loadsBeforeNinth, &decodesBeforeNinth, &startsBeforeNinth)) {
            return fail("domain stats unavailable before the leased pressure case", 53);
        }
        if (prepare(session, ninthId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("ninth transfer image could not be prepared under pressure", 54);
        }
        id<MTLTexture> preparedNinth = domain.textureCache[ninthKey];
        if (!preparedNinth ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, ninthId, 1) !=
                CJGUI_INTERNAL_RENDERER_OK) {
            return fail("ninth transfer image was not admitted", 55);
        }
        if (domain.textureCache[ninthKey] != preparedNinth ||
            !domain.resources[ninthKey] || domain.resources[ninthKey].candidateLeaseCount != 1) {
            fprintf(stderr, "png handoff accepted texture=%p cache=%p lease=%u\n", (__bridge void *)preparedNinth,
                (__bridge void *)domain.textureCache[ninthKey],
                domain.resources[ninthKey] ? domain.resources[ninthKey].candidateLeaseCount : 0);
            return fail("accepted transfer image did not survive the cache prune before staging", 56);
        }
        if (!commitTransferImageScene(session, 300, 8000, ninthId, small)) {
            return fail("scene declaring the leased ninth image was rejected", 57);
        }
        uint64_t decodesAfterNinth = 0, loadsAfterNinth = 0, startsAfterNinth = 0;
        if (!budgetCounters(session, &loadsAfterNinth, &decodesAfterNinth, &startsAfterNinth)) {
            return fail("domain stats unavailable after the leased pressure case", 58);
        }
        id<MTLTexture> stagedNinth = committedTextureForKey(session, ninthKey);
        if (decodesAfterNinth != decodesBeforeNinth || loadsAfterNinth != loadsBeforeNinth ||
            startsAfterNinth != startsBeforeNinth + 1 ||
            stagedNinth != preparedNinth || !decodedPixelsMatchFixture(device, stagedNinth) ||
            domain.resources[ninthKey].candidateLeaseCount != 0) {
            fprintf(stderr, "png handoff leased decode_starts=%llu->%llu completions=%llu->%llu loads=%llu->%llu texture=%p/%p lease=%u\n",
                (unsigned long long)startsBeforeNinth, (unsigned long long)startsAfterNinth,
                (unsigned long long)decodesBeforeNinth, (unsigned long long)decodesAfterNinth,
                (unsigned long long)loadsBeforeNinth, (unsigned long long)loadsAfterNinth,
                (__bridge void *)preparedNinth, (__bridge void *)stagedNinth,
                domain.resources[ninthKey] ? domain.resources[ninthKey].candidateLeaseCount : 0);
            return fail("leased pressure case did not hand the prepared texture to the scene", 59);
        }
        fprintf(stdout,
                "png_handoff leased=one_decode_candidate_owns_it decode_starts=%llu->%llu loads=%llu lease_after_stage=%u\n",
                (unsigned long long)startsBeforeNinth, (unsigned long long)startsAfterNinth,
                (unsigned long long)loadsAfterNinth,
                domain.resources[ninthKey].candidateLeaseCount);

        // ---- Cold re-display after every hold is gone ----
        // Drop the accepted node and the whole reusable entry, then re-declare
        // the SAME offer: the bytes must be re-admitted and re-decoded by the
        // bounded path, with no live texture to hide behind.
        if (!commitTransferImageScene(session, 301, 8001, "cjgui-transfer:pressure-0", small)) {
            return fail("scene without the ninth image could not be committed", 61);
        }
        preparedNinth = nil;
        stagedNinth = nil;
        if (committedTextureForKey(session, ninthKey) ||
            CjguiComposableImageDomainBoundTexture(domain, ninthKey) ||
            domain.textureCache[ninthKey] || domain.resources[ninthKey]) {
            return fail("cold re-display started from a surviving texture or record", 62);
        }
        // Snapshot AFTER the scene without the ninth is committed, so the only
        // decode this measurement may see is the re-declaration itself.
        uint64_t decodesBeforeCold = 0, loadsBeforeCold = 0, startsBeforeCold = 0;
        if (!budgetCounters(session, &loadsBeforeCold, &decodesBeforeCold, &startsBeforeCold)) {
            return fail("domain stats unavailable before the cold re-display", 60);
        }
        if (!commitTransferImageScene(session, 302, 8002, ninthId, small)) {
            return fail("cold re-declaration of the same offer was rejected", 63);
        }
        uint64_t decodesAfterCold = 0, loadsAfterCold = 0, startsAfterCold = 0;
        if (!budgetCounters(session, &loadsAfterCold, &decodesAfterCold, &startsAfterCold)) {
            return fail("domain stats unavailable after the cold re-display", 64);
        }
        id<MTLTexture> coldTexture = committedTextureForKey(session, ninthKey);
        if (startsAfterCold != startsBeforeCold + 1 || loadsAfterCold != loadsBeforeCold ||
            decodesAfterCold != decodesBeforeCold ||
            !coldTexture || !decodedPixelsMatchFixture(device, coldTexture) ||
            !domain.resources[ninthKey] ||
            ![domain.resources[ninthKey].encodedData isEqualToData:small]) {
            fprintf(stderr, "png handoff cold decode_starts=%llu->%llu loads=%llu->%llu texture=%p\n",
                (unsigned long long)startsBeforeCold, (unsigned long long)startsAfterCold,
                (unsigned long long)loadsBeforeCold, (unsigned long long)loadsAfterCold, (__bridge void *)coldTexture);
            return fail("cold re-display did not re-admit and re-decode the immutable offer", 65);
        }
        coldTexture = nil;
        fprintf(stdout,
                "png_handoff cold_redisplay=readmitted_and_decoded decode_starts=%llu->%llu loads=%llu completions=%llu\n",
                (unsigned long long)startsBeforeCold, (unsigned long long)startsAfterCold,
                (unsigned long long)loadsAfterCold, (unsigned long long)decodesAfterCold);

        // Two sessions may prepare the SAME immutable transfer key before
        // either finishes. A's accepted handoff must not depend on B's later
        // cancellation; the candidate must inherit the exact prepared texture.
        sourceSession = [[CJGuiInternalSession alloc] init];
        if (!sourceSession) return fail("second source session initialization failed", 66);
        sourceSession.app = app;
        sourceSession.device = device;
        sourceSession.rendererSessionToken = 2;
        sourceSession.sessionGeneration = 3;
        sourceSession.composableImageDomain = domain;
        domain.sessionCount = 2;
        gCjguiSessions[1] = sourceSession;
        gCjguiSessionOccupied[1] = YES;
        const char *interleavedId = "cjgui-transfer:interleaved-two-window";
        NSString *interleavedIdentity = [NSString stringWithUTF8String:interleavedId];
        NSString *interleavedKey = CjguiComposableImageCacheKey(interleavedIdentity, interleavedIdentity, 0, NULL);
        if (prepare(session, interleavedId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK ||
            prepare(sourceSession, interleavedId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("two-window preparation of one immutable offer failed", 66);
        }
        id<MTLTexture> interleavedPrepared = domain.textureCache[interleavedKey];
        uint64_t interleavedStarts = 0, interleavedLoads = 0;
        if (!interleavedPrepared || !budgetCounters(session, &interleavedLoads, NULL, &interleavedStarts) ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, interleavedId, 1) !=
                CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_finish_composable_png_transfer(2, interleavedId, 0) !=
                CJGUI_INTERNAL_RENDERER_OK ||
            !domain.resources[interleavedKey] || !domain.textureCache[interleavedKey]) {
            return fail("other window's cancellation removed accepted PNG handoff", 67);
        }
        if (!commitTransferImageScene(session, 303, 8003, interleavedId, small)) {
            return fail("surviving two-window PNG candidate was rejected", 68);
        }
        uint64_t interleavedStartsAfter = 0, interleavedLoadsAfter = 0;
        if (!budgetCounters(session, &interleavedLoadsAfter, NULL, &interleavedStartsAfter) ||
            committedTextureForKey(session, interleavedKey) != interleavedPrepared ||
            interleavedStartsAfter != interleavedStarts || interleavedLoadsAfter != interleavedLoads) {
            return fail("surviving two-window PNG candidate decoded again", 69);
        }
        if (prepare(sourceSession, interleavedId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_finish_composable_png_transfer(2, interleavedId, 1) !=
                CJGUI_INTERNAL_RENDERER_OK ||
            domain.resources[interleavedKey].candidateLeaseCount != 1 ||
            cjgui_internal_renderer_discard_composable_scene_candidate(2) != CJGUI_INTERNAL_RENDERER_OK ||
            committedTextureForKey(session, interleavedKey) != interleavedPrepared) {
            return fail("A's accepted node prematurely settled B's independent candidate lease", 76);
        }
        fprintf(stdout, "png_handoff two_window_cancel=survivor_reused decode_starts=%llu->%llu loads=%llu->%llu\n",
                (unsigned long long)interleavedStarts, (unsigned long long)interleavedStartsAfter,
                (unsigned long long)interleavedLoads, (unsigned long long)interleavedLoadsAfter);
        if (cjgui_internal_renderer_destroy(2) != CJGUI_INTERNAL_RENDERER_OK || domain.sessionCount != 1 ||
            committedTextureForKey(session, interleavedKey) != interleavedPrepared) {
            return fail("closing cancelled peer changed survivor's accepted texture", 70);
        }

        // No dictionary surgery: a normal accepted replacement and the
        // production orphan-prune path must relinquish the sole texture. The
        // nested autorelease pool also removes the probe's temporary loader
        // result, so this is a real cold re-display rather than a warm object
        // hidden behind an empty cache entry.
        const char *retiredId = "cjgui-transfer:fully-retired-cold";
        NSString *retiredIdentity = [NSString stringWithUTF8String:retiredId];
        NSString *retiredKey = CjguiComposableImageCacheKey(retiredIdentity, retiredIdentity, 0, NULL);
        __weak id<MTLTexture> retiredTexture = nil;
        NSUInteger liveBeforeRetire = CjguiComposableImageConservativeLiveBytes(domain);
        @autoreleasepool {
            if (prepare(session, retiredId, small, &width, &height) != CJGUI_INTERNAL_RENDERER_OK ||
                cjgui_internal_renderer_finish_composable_png_transfer(1, retiredId, 1) !=
                    CJGUI_INTERNAL_RENDERER_OK ||
                !commitTransferImageScene(session, 304, 8004, retiredId, small)) {
                return fail("fully retired cold offer could not reach accepted", 71);
            }
            retiredTexture = committedTextureForKey(session, retiredKey);
            if (!retiredTexture || !commitTransferImageScene(session, 305, 8005,
                    "cjgui-transfer:pressure-0", small) ||
                domain.resources[retiredKey] || domain.textureCache[retiredKey]) {
                return fail("accepted replacement retained cold offer ownership", 72);
            }
        }
        NSUInteger liveAfterRetire = CjguiComposableImageConservativeLiveBytes(domain);
        if (retiredTexture) {
            fprintf(stderr, "png cold retire texture=%p live=%lu->%lu\n",
                (__bridge void *)retiredTexture, (unsigned long)liveBeforeRetire,
                (unsigned long)liveAfterRetire);
            return fail("fully released cold offer retained its decoded allocation", 73);
        }
        uint64_t fullyColdStarts = 0, fullyColdLoads = 0;
        if (!budgetCounters(session, &fullyColdLoads, NULL, &fullyColdStarts) ||
            !commitTransferImageScene(session, 306, 8006, retiredId, small)) {
            return fail("fully retired cold offer could not be re-admitted", 74);
        }
        uint64_t fullyColdStartsAfter = 0, fullyColdLoadsAfter = 0;
        if (!budgetCounters(session, &fullyColdLoadsAfter, NULL, &fullyColdStartsAfter) ||
            fullyColdStartsAfter != fullyColdStarts + 1 || fullyColdLoadsAfter != fullyColdLoads ||
            !decodedPixelsMatchFixture(device, committedTextureForKey(session, retiredKey))) {
            return fail("fully retired cold offer bypassed bounded re-decode", 75);
        }
        fprintf(stdout, "png_handoff fully_released_cold=readmitted decode_starts=%llu->%llu "
                "loads=%llu->%llu live_bytes=%lu->%lu\n",
                (unsigned long long)fullyColdStarts, (unsigned long long)fullyColdStartsAfter,
                (unsigned long long)fullyColdLoads, (unsigned long long)fullyColdLoadsAfter,
                (unsigned long)liveBeforeRetire, (unsigned long)liveAfterRetire);

        const char *cancelId = "cjgui-transfer:budget-cancel-3x2";
        status = prepare(session, cancelId, small, &width, &height);
        if (status != CJGUI_INTERNAL_RENDERER_OK || width != 3 || height != 2 ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, cancelId, 0) !=
                CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_finish_composable_png_transfer(1, cancelId, 0) !=
                CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED) {
            return fail("PNG cancellation did not release exactly one pending preparation", 23);
        }
        NSString *cancelIdentity = [NSString stringWithUTF8String:cancelId];
        NSString *cancelKey = CjguiComposableImageCacheKey(cancelIdentity, cancelIdentity, 0, NULL);
        if (domain.textureCache[cancelKey] || domain.resources[cancelKey]) {
            return fail("cancelled unbound PNG remained in the domain cache", 24);
        }
        fprintf(stdout, "png_budget cancel=released second_finish=data_transfer_rejected\n");

        firstTexture = nil;
        smallResource = nil;
        session.composableNodes = nil;
        NSHashTable<id<MTLTexture>> *weakTextures = domain.textureLedger;
        status = cjgui_internal_renderer_destroy(1);
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return fail("closing target session failed", 25);
        }
        if (!domain.destroyed || domain.sessionCount != 0 || domain.textureCache.count != 0 ||
            domain.resources.count != 0 || domain.pendingKeys.count != 0 || domain.loaders.count != 0) {
            return fail("closing the last session did not clear image budget ownership", 21);
        }
        if (cjgui_internal_renderer_finish_composable_png_transfer(1, cancelId, 1) !=
            CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            return fail("late PNG completion after target close was not rejected", 26);
        }
        fprintf(stdout, "png_budget close=domain_destroyed cache=0 records=0 weak_ledger_after_clear=%lu\n",
                (unsigned long)weakTextures.allObjects.count);
    }
    return 0;
}
