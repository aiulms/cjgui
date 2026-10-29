#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

@interface ReadonlyReuseWindow : NSWindow
@end
@implementation ReadonlyReuseWindow
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return 2.0; }
@end

@interface ReadonlyReuseOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) ReadonlyReuseWindow *recordedWindow;
@end
@implementation ReadonlyReuseOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end

static int failures;
#define CHECK(condition, label) do { \
    BOOL ok = (condition); \
    fprintf(stderr, "readonly_reuse_font_query case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static uint64_t nowNs(void) { return cjgui_internal_renderer_owner_clock_ns(); }

static NSData *pixels(id<MTLTexture> texture) {
    if (!texture || texture.pixelFormat != MTLPixelFormatBGRA8Unorm) return nil;
    NSUInteger rowBytes = texture.width * 4;
    NSMutableData *data = [NSMutableData dataWithLength:rowBytes * texture.height];
    [texture getBytes:data.mutableBytes bytesPerRow:rowBytes
        fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return data;
}

static BOOL makeSession(CJGuiInternalSession **outCtx, uint64_t *outToken) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return NO;
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 360, 220)
        device:device commandQueue:[device newCommandQueue]];
    ReadonlyReuseOverlay *overlay = [[ReadonlyReuseOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow = [[ReadonlyReuseWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.releasedWhenClosed = NO;
    overlay.recordedWindow.contentView = overlay;
    ctx.window = overlay.recordedWindow;
    ctx.composableSceneOverlay = overlay;
    ctx.composableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    ctx.stagedComposableSceneVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token) return NO;
    ctx.view.sessionToken = token;

    NSMutableString *body = [NSMutableString string];
    for (NSUInteger i = 0; i < 32; ++i)
        [body appendString:@"Readonly cached text across multiple rows\n"];
    if (body.length < 1024) return NO;
    CJGuiInternalComposableSceneNode *accepted = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 700; raw.resourceId = 7; raw.projectionVersion = 1;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 240; raw.height = 100; raw.clipWidth = 240; raw.clipHeight = 100;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    accepted.node = raw; accepted.value = body; accepted.label = @"readonly cache";
    accepted.semanticId = @"readonly-cache"; accepted.styleRunsSignature = @"";
    accepted.textTextureCacheKey = @"";
    CGFloat scale = MAX(1.0, [ctx.view currentBackingScale]);
    accepted.preparedTextLayout = CjguiPrepareTextNodeLayout(accepted, body, scale, nil, ctx);
    if (!accepted.preparedTextLayout) return NO;
    ctx.composableNodes = [NSMutableArray arrayWithObject:accepted];
    ctx.view.composableNodes = ctx.composableNodes;
    overlay.recordedWindow.contentView = overlay;
    [overlay setNodesFromProjection:ctx.composableNodes];
    id<MTLTexture> texture = CjguiComposableTextTexture(ctx.view, accepted, scale, scale, body,
        CjguiInternalTextWorkReasonUnknown);
    if (!texture || !accepted.textTextureSourceCredential || !accepted.textTextureByteCount) return NO;
    ctx.composableSceneVersion = 1;
    *outCtx = ctx; *outToken = token;
    return YES;
}

static CjguiInternalRendererStatus beginCandidate(CJGuiInternalSession *ctx, uint64_t token,
    uint64_t preparationId, CjguiInternalRendererComposableNode raw, NSString *body) {
    raw.projectionVersion = preparationId + 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = raw.nodeId;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_begin_composable_preparation(
        token, preparationId, ctx.composableSceneVersion, raw.projectionVersion, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &raw,
        &geometry, "readonly cache", body.UTF8String, "readonly-cache", "", "", "", "", "");
}

static CjguiInternalRendererStatus finishCandidate(uint64_t token, uint64_t preparationId,
    BOOL *outReady) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    uint32_t ready = 0;
    for (NSUInteger i = 0; i < 128 && !ready; ++i) {
        status = cjgui_internal_renderer_advance_composable_preparation(token, preparationId,
            nowNs() + 250000000ull, &ready);
        if (status != CJGUI_INTERNAL_RENDERER_OK) break;
        if (!ready) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    }
    *outReady = ready != 0;
    return status;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes.firstObject;
    id<MTLTexture> acceptedTexture = accepted.textTexture ?: accepted.textTileTextures.firstObject;
    CjguiPreparedTextNodeLayout *acceptedLayout = accepted.preparedTextLayout;
    NSTextStorage *acceptedStorage = acceptedLayout.storage;
    NSAttributedString *acceptedStorageSnapshot =
        [[NSAttributedString alloc] initWithAttributedString:acceptedStorage];
    CjguiTextRasterSourceCredential *acceptedCredential = accepted.textTextureSourceCredential;
    NSData *acceptedPixels = pixels(acceptedTexture);
    NSString *acceptedBody = accepted.value;

    CjguiInternalRendererComposableNode same = accepted.node;
    CHECK(beginCandidate(ctx, token, 10, same, acceptedBody) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_same_source_candidate");
    gCjguiComposableFontResolutionTestCount = 0;
    BOOL hitReady = NO;
    CjguiInternalRendererStatus hitStatus = finishCandidate(token, 10, &hitReady);
    uint64_t hitFontQueries = gCjguiComposableFontResolutionTestCount;
    CJGuiInternalComposableSceneNode *hit = ctx.composablePreparation.nodes.firstObject;
    CHECK(hitStatus == CJGUI_INTERNAL_RENDERER_OK && hitReady &&
        ctx.composablePreparation.nodeCursor == 1,
        "same_source_candidate_finishes_real_production_advance");
    CHECK(hitFontQueries == 0, "complete_retained_raster_hit_has_zero_live_font_queries");
    CHECK(hit.textTextureSourceCredential &&
        (hit.textTexture ?: hit.textTileTextures.firstObject) == acceptedTexture,
        "retained_hit_keeps_original_texture_and_credential");
    CHECK(ctx.composablePreparation.textLayoutJob == nil &&
        ctx.composablePreparation.textLayoutPendingInput == nil &&
        ctx.composablePreparation.textLayoutWaitTicket == 0 &&
        ctx.composablePreparation.textLayoutReservedBytes == 0,
        "warm_retained_hit_creates_no_cold_text_job_or_ticket");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 10);

    CjguiInternalRendererComposableNode recolor = accepted.node;
    recolor.textRed = 1; recolor.textGreen = 0; recolor.textBlue = 0;
    CHECK(beginCandidate(ctx, token, 11, recolor, acceptedBody) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_color_changed_candidate");
    BOOL colorReady = NO;
    CjguiInternalRendererStatus colorStatus = finishCandidate(token, 11, &colorReady);
    CJGuiInternalComposableSceneNode *colorCandidate = ctx.composablePreparation.nodes.firstObject;
    NSData *colorPixels = pixels(colorCandidate.textTexture ?: colorCandidate.textTileTextures.firstObject);
    CHECK(colorStatus == CJGUI_INTERNAL_RENDERER_OK && colorReady && colorPixels.length > 0 &&
        acceptedPixels.length == colorPixels.length && ![acceptedPixels isEqualToData:colorPixels],
        "color_change_misses_cache_and_prepares_new_pixels");
    CHECK(accepted.preparedTextLayout == acceptedLayout && acceptedLayout.storage == acceptedStorage &&
        [acceptedStorage isEqualToAttributedString:acceptedStorageSnapshot] &&
        [accepted.value isEqualToString:acceptedBody] && accepted.value == acceptedBody &&
        accepted.textTextureSourceCredential == acceptedCredential &&
        (accepted.textTexture ?: accepted.textTileTextures.firstObject) == acceptedTexture &&
        [pixels(acceptedTexture) isEqualToData:acceptedPixels],
        "color_candidate_preserves_accepted_layout_storage_attributes_body_credential_texture_pixels");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 11);

    NSString *changedBody = @"Changed body is independently prepared\nsecond changed line";
    CjguiInternalRendererComposableNode changed = accepted.node;
    CHECK(beginCandidate(ctx, token, 12, changed, changedBody) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_body_changed_candidate");
    BOOL bodyReady = NO;
    CjguiInternalRendererStatus bodyStatus = finishCandidate(token, 12, &bodyReady);
    CJGuiInternalComposableSceneNode *bodyCandidate = ctx.composablePreparation.nodes.firstObject;
    NSData *bodyPixels = pixels(bodyCandidate.textTexture ?: bodyCandidate.textTileTextures.firstObject);
    CHECK(bodyStatus == CJGUI_INTERNAL_RENDERER_OK && bodyReady && bodyPixels.length > 0 &&
        acceptedPixels.length == bodyPixels.length && ![acceptedPixels isEqualToData:bodyPixels],
        "body_change_misses_cache_and_prepares_new_pixels");
    CHECK(accepted.preparedTextLayout == acceptedLayout && acceptedLayout.storage == acceptedStorage &&
        [acceptedStorage isEqualToAttributedString:acceptedStorageSnapshot] &&
        [accepted.value isEqualToString:acceptedBody] && accepted.value == acceptedBody &&
        accepted.textTextureSourceCredential == acceptedCredential &&
        (accepted.textTexture ?: accepted.textTileTextures.firstObject) == acceptedTexture &&
        [pixels(acceptedTexture) isEqualToData:acceptedPixels],
        "body_candidate_preserves_accepted_layout_storage_attributes_body_credential_texture_pixels");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 12);
    CjguiReleaseSession(token);
    CHECK(cjgui_internal_renderer_occupied_session_count() == 0, "session_resources_reach_terminal_release");
    fprintf(stderr, "readonly_reuse_font_query summary failures=%d hit_font_queries=%llu\n", failures,
        (unsigned long long)hitFontQueries);
    return failures ? 1 : 0;
} }
