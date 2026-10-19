// Production-path fixture preserving the original allocation RED evidence
// while asserting local-coordinate effect-row reuse after real GPU completion.
// The translated masked row must render the same local pixels at its new
// screen position. No backdrop or nested effect group is present.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <objc/runtime.h>

static CAMetalLayer *localTranslationProbeLayer;
static id<CAMetalDrawable> localTranslationCapturedDrawable;
static IMP localTranslationOriginalNextDrawable;
static CjguiInternalRendererStatus localTranslationLastSubmitStatus = CJGUI_INTERNAL_RENDERER_OK;
static const char *localTranslationLastSubmitStage = "none";
static uint64_t localTranslationLastVersion = 0;
static uint32_t localTranslationLastSubmitNodeIndex = UINT32_MAX;
static double localTranslationSampleX = 76.0, localTranslationSampleY = 90.0;
static uint8_t localTranslationSampleBGRA[4] = {0};
static double localHomeTitleExtraY = 0.0;

static id localTranslationCaptureNextDrawable(id receiver, SEL selector) {
    id drawable = ((id (*)(id, SEL))localTranslationOriginalNextDrawable)(receiver, selector);
    if (receiver == localTranslationProbeLayer) localTranslationCapturedDrawable = drawable;
    return drawable;
}

typedef struct {
    uint8_t *drawableBGRA;
    uint8_t *targetBGRA;
    NSUInteger drawableWidth;
    NSUInteger drawableHeight;
    NSUInteger drawableRowBytes;
    NSUInteger targetWidth;
    NSUInteger targetHeight;
    NSUInteger targetRowBytes;
    uint32_t targetPixelX;
    uint32_t targetPixelY;
} LocalTranslationReadback;

typedef struct {
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t alpha;
} LocalTranslationPixel;

static BOOL localTranslationRequire(BOOL condition, const char *name) {
    if (!condition) fprintf(stderr, "LOCAL_EFFECT_TRANSLATION_FAIL %s\n", name);
    return condition;
}

static CjguiInternalRendererComposableNode localTranslationNode(
        uint64_t version, uint64_t nodeId, uint32_t kind,
        double x, double y, double width, double height, int64_t clipWidth) {
    CjguiInternalRendererComposableNode node = {0};
    node.projectionVersion = version;
    node.nodeId = nodeId;
    node.resourceId = -1;
    node.nodeKind = kind;
    node.x = x; node.y = y; node.width = width; node.height = height;
    node.clipX = 0; node.clipY = 0; node.clipWidth = clipWidth; node.clipHeight = 320;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = clipWidth; node.clip0Height = 320;
    node.effectGroupSubtreeCount = 1;
    return node;
}

static BOOL localTranslationSubmit(uint64_t session, uint64_t version, double translateY,
                                   int64_t groupClipWidth, BOOL redContent,
                                   float maskStartAlpha, float maskEndAlpha) {
    localTranslationLastVersion = version;
    localTranslationSampleX = 76.0;
    localTranslationSampleY = 90.0 + translateY;
    localTranslationLastSubmitStage = "configure";
    CjguiInternalRendererComposableNode nodes[2];
    nodes[0] = localTranslationNode(version, 7001,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL, 40, 50, 220, 100, groupClipWidth);
    nodes[0].effectGroupPresent = 1;
    nodes[0].effectGroupSubtreeCount = 2;
    nodes[0].effectGroupOpacity = 1.0;
    nodes[0].effectMaskPresent = 1;
    nodes[0].effectMaskStopCount = 2;
    nodes[0].effectMaskEndX = 1.0;
    nodes[0].effectMaskStop0Position = 0.0;
    nodes[0].effectMaskStop1Position = 1.0;
    nodes[0].effectMaskStop0Alpha = maskStartAlpha;
    nodes[0].effectMaskStop1Alpha = maskEndAlpha;

    nodes[1] = localTranslationNode(version, 7002,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL, 64, 78, 120, 24, 420);
    nodes[1].fillRed = redContent ? 1.0 : 0.0;
    nodes[1].fillGreen = redContent ? 0.0 : 1.0;
    nodes[1].fillBlue = 0.0;
    nodes[1].fillAlpha = 1.0;

    localTranslationLastSubmitStatus = cjgui_internal_renderer_configure_composable_scene(session, version, 2);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    for (uint32_t index = 0; index < 2; index++) {
        localTranslationLastSubmitStage = "set_node";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_node(session, index,
            &nodes[index], "", "", "", "", 0);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
        CjguiInternalRendererComposableGeometry geometry = {0};
        geometry.nodeId = nodes[index].nodeId;
        geometry.clipCount = 1;
        geometry.translateY = translateY;
        localTranslationLastSubmitStage = "set_geometry";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_geometry(
            session, version, index, &geometry);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    }
    localTranslationLastSubmitStage = "stage_background";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    localTranslationLastSubmitStage = "request_pixel";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
        session, localTranslationSampleX, localTranslationSampleY);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    localTranslationCapturedDrawable = nil;
    CjguiInternalRendererFrameObservation frame = {0};
    localTranslationLastSubmitStage = "present";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK || !localTranslationCapturedDrawable) return NO;
    localTranslationLastSubmitStage = "pixel_readback";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_test_composable_drawable_pixel(session,
        &localTranslationSampleBGRA[0], &localTranslationSampleBGRA[1],
        &localTranslationSampleBGRA[2], &localTranslationSampleBGRA[3]);
    return localTranslationLastSubmitStatus == CJGUI_INTERNAL_RENDERER_OK;
}

static BOOL localTranslationReadbackNow(uint64_t session, LocalTranslationReadback *out) {
    memset(out, 0, sizeof(*out));
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !localTranslationCapturedDrawable || ctx.view.composableNodes.count < 2) return NO;
    CJGuiInternalComposableSceneNode *group = ctx.view.composableNodes[0];
    CJGuiInternalComposableEffectTarget *target = group.effectTarget;
    id<MTLTexture> drawable = localTranslationCapturedDrawable.texture;
    if (!target || !target.resolvedTexture || !drawable) return NO;

    out->drawableWidth = drawable.width;
    out->drawableHeight = drawable.height;
    out->drawableRowBytes = ((out->drawableWidth * 4u + 255u) / 256u) * 256u;
    out->targetWidth = target.pixelWidth;
    out->targetHeight = target.pixelHeight;
    out->targetRowBytes = ((out->targetWidth * 4u + 255u) / 256u) * 256u;
    out->targetPixelX = target.pixelX;
    out->targetPixelY = target.pixelY;
    NSUInteger drawableLength = out->drawableRowBytes * out->drawableHeight;
    NSUInteger targetLength = out->targetRowBytes * out->targetHeight;
    id<MTLBuffer> drawableBuffer = [ctx.device newBufferWithLength:drawableLength
        options:MTLResourceStorageModeShared];
    id<MTLBuffer> targetBuffer = [ctx.device newBufferWithLength:targetLength
        options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> command = [ctx.view.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> blit = command ? [command blitCommandEncoder] : nil;
    if (!drawableBuffer || !targetBuffer || !blit) return NO;
    [blit copyFromTexture:drawable sourceSlice:0 sourceLevel:0
        sourceOrigin:MTLOriginMake(0, 0, 0)
        sourceSize:MTLSizeMake(out->drawableWidth, out->drawableHeight, 1)
        toBuffer:drawableBuffer destinationOffset:0 destinationBytesPerRow:out->drawableRowBytes
        destinationBytesPerImage:drawableLength];
    [blit copyFromTexture:target.resolvedTexture sourceSlice:0 sourceLevel:0
        sourceOrigin:MTLOriginMake(0, 0, 0)
        sourceSize:MTLSizeMake(out->targetWidth, out->targetHeight, 1)
        toBuffer:targetBuffer destinationOffset:0 destinationBytesPerRow:out->targetRowBytes
        destinationBytesPerImage:targetLength];
    [blit endEncoding];
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return NO;
    out->drawableBGRA = malloc(drawableLength);
    out->targetBGRA = malloc(targetLength);
    if (!out->drawableBGRA || !out->targetBGRA) return NO;
    memcpy(out->drawableBGRA, drawableBuffer.contents, drawableLength);
    memcpy(out->targetBGRA, targetBuffer.contents, targetLength);
    double pointScaleX = out->drawableWidth / MAX(1.0, ctx.view.bounds.size.width);
    double pointScaleY = out->drawableHeight / MAX(1.0, ctx.view.bounds.size.height);
    NSUInteger sx = MIN(out->drawableWidth - 1,
        (NSUInteger)MAX(0.0, floor(localTranslationSampleX * pointScaleX)));
    NSUInteger sy = MIN(out->drawableHeight - 1,
        (NSUInteger)MAX(0.0, floor(localTranslationSampleY * pointScaleY)));
    const uint8_t *pixels = out->drawableBGRA;
    const uint8_t *atPoint = pixels + sy * out->drawableRowBytes + sx * 4;
    const uint8_t *verticallyMirrored = pixels + (out->drawableHeight - 1 - sy) * out->drawableRowBytes + sx * 4;
    NSUInteger hx = MIN(out->drawableWidth - 1,
        (NSUInteger)MAX(0.0, floor(170.0 * pointScaleX)));
    const uint8_t *highGradientPoint = pixels + sy * out->drawableRowBytes + hx * 4;
    printf("LOCAL_EFFECT_TRANSLATION_DIAG version=%llu submit_stage=%s submit_status=%u captured=%d "
           "points=%.1fx%.1f bounds=%.2fx%.2f drawable=%lux%lu layerScale=%.3f currentScale=%.3f "
           "targetROI=%u,%u,%u,%u targetScale=%.3f,%.3f "
           "mask=present:%u stops:%u rect=%.3f,%.3f,%.3f,%.3f axis=%.3f,%.3f->%.3f,%.3f "
           "positions=%.3f,%.3f alpha=%.3f,%.3f clip=%lld,%lld,%lld,%lld "
           "selectedBGRA=%u,%u,%u,%u flippedBGRA=%u,%u,%u,%u\n",
        (unsigned long long)localTranslationLastVersion, localTranslationLastSubmitStage,
        (unsigned)localTranslationLastSubmitStatus, localTranslationCapturedDrawable != nil,
        localTranslationSampleX, localTranslationSampleY,
        ctx.view.bounds.size.width, ctx.view.bounds.size.height,
        (unsigned long)out->drawableWidth, (unsigned long)out->drawableHeight,
        (double)ctx.view.metalLayer.contentsScale, (double)[ctx.view currentBackingScale],
        out->targetPixelX, out->targetPixelY, (uint32_t)out->targetWidth, (uint32_t)out->targetHeight,
        out->targetWidth / MAX(1.0, (double)group.node.width),
        out->targetHeight / MAX(1.0, (double)group.node.height),
        group.node.effectMaskPresent, group.node.effectMaskStopCount,
        group.node.x + group.geometry.translateX, group.node.y + group.geometry.translateY,
        (double)group.node.width, (double)group.node.height,
        group.node.effectMaskStartX, group.node.effectMaskStartY,
        group.node.effectMaskEndX, group.node.effectMaskEndY,
        group.node.effectMaskStop0Position, group.node.effectMaskStop1Position,
        group.node.effectMaskStop0Alpha, group.node.effectMaskStop1Alpha,
        (long long)group.node.clipX, (long long)group.node.clipY,
        (long long)group.node.clipWidth, (long long)group.node.clipHeight,
        localTranslationSampleBGRA[0], localTranslationSampleBGRA[1],
        localTranslationSampleBGRA[2], localTranslationSampleBGRA[3],
        atPoint[0], atPoint[1], atPoint[2], atPoint[3]);
    printf("LOCAL_EFFECT_TRANSLATION_DIAG_COLOR x=%.1f y=%.1f directBGRA=%u,%u,%u,%u "
           "index=%lu,%lu verticallyMirroredBGRA=%u,%u,%u,%u index=%lu,%lu\n",
        localTranslationSampleX, localTranslationSampleY,
        atPoint[0], atPoint[1], atPoint[2], atPoint[3], (unsigned long)sx, (unsigned long)sy,
        verticallyMirrored[0], verticallyMirrored[1], verticallyMirrored[2], verticallyMirrored[3],
        (unsigned long)sx, (unsigned long)(out->drawableHeight - 1 - sy));
    printf("LOCAL_EFFECT_TRANSLATION_DIAG_GRADIENT x=76.0,170.0 y=%.1f lowBGRA=%u,%u,%u,%u "
           "highBGRA=%u,%u,%u,%u index=%lu,%lu scale=%.3f,%.3f\n",
        localTranslationSampleY,
        atPoint[0], atPoint[1], atPoint[2], atPoint[3],
        highGradientPoint[0], highGradientPoint[1], highGradientPoint[2], highGradientPoint[3],
        (unsigned long)sx, (unsigned long)hx, pointScaleX, pointScaleY);
    localTranslationCapturedDrawable = nil;
    return YES;
}

static BOOL localTranslationStats(uint64_t session, CjguiInternalRendererEffectStats *stats) {
    memset(stats, 0, sizeof(*stats));
    return cjgui_internal_renderer_test_composable_effect_stats(session, stats) ==
        CJGUI_INTERNAL_RENDERER_OK;
}

static LocalTranslationPixel localTranslationPixelAt(const LocalTranslationReadback *image,
                                      double pointX, double pointY, NSSize pointSize) {
    LocalTranslationPixel result = {0};
    if (!image || !image->drawableBGRA || image->drawableWidth == 0 || image->drawableHeight == 0) return result;
    double scaleX = image->drawableWidth / MAX(1.0, pointSize.width);
    double scaleY = image->drawableHeight / MAX(1.0, pointSize.height);
    NSUInteger x = MIN(image->drawableWidth - 1, (NSUInteger)MAX(0.0, floor(pointX * scaleX)));
    NSUInteger y = MIN(image->drawableHeight - 1, (NSUInteger)MAX(0.0, floor(pointY * scaleY)));
    const uint8_t *pixel = image->drawableBGRA + y * image->drawableRowBytes + x * 4;
    result.blue = pixel[0]; result.green = pixel[1];
    result.red = pixel[2]; result.alpha = pixel[3];
    return result;
}

static uint64_t localTranslationGreenPixelsInRect(const LocalTranslationReadback *image,
                                                  NSRect rect, NSSize pointSize) {
    if (!image || !image->drawableBGRA || image->drawableWidth == 0 || image->drawableHeight == 0) return 0;
    double scaleX = image->drawableWidth / MAX(1.0, pointSize.width);
    double scaleY = image->drawableHeight / MAX(1.0, pointSize.height);
    NSUInteger x0 = MIN(image->drawableWidth, (NSUInteger)MAX(0.0, floor(NSMinX(rect) * scaleX)));
    NSUInteger y0 = MIN(image->drawableHeight, (NSUInteger)MAX(0.0, floor(NSMinY(rect) * scaleY)));
    NSUInteger x1 = MIN(image->drawableWidth, (NSUInteger)MAX(0.0, ceil(NSMaxX(rect) * scaleX)));
    NSUInteger y1 = MIN(image->drawableHeight, (NSUInteger)MAX(0.0, ceil(NSMaxY(rect) * scaleY)));
    uint64_t count = 0;
    const uint8_t *pixels = image->drawableBGRA;
    for (NSUInteger y = y0; y < y1; y++) {
        for (NSUInteger x = x0; x < x1; x++) {
            const uint8_t *pixel = pixels + y * image->drawableRowBytes + x * 4;
            if (pixel[1] > 24 && pixel[1] > pixel[0] * 2 && pixel[1] > pixel[2] * 2) count++;
        }
    }
    return count;
}

static BOOL localTranslationExpectOneNewTarget(uint64_t session, uint64_t version,
        double translateY, int64_t groupClipWidth, BOOL redContent,
        float maskStartAlpha, float maskEndAlpha,
        CjguiInternalRendererEffectStats before, CjguiInternalRendererEffectStats *after,
        LocalTranslationReadback *readback, const char *label) {
    if (!localTranslationSubmit(session, version, translateY, groupClipWidth, redContent,
        maskStartAlpha, maskEndAlpha) || !localTranslationReadbackNow(session, readback) ||
        !localTranslationStats(session, after)) {
        CJGuiInternalSession *ctx = CjguiLookupSession(session);
        fprintf(stderr, "LOCAL_EFFECT_TRANSLATION_FAIL %s_submit_readback "
            "version=%llu stage=%s status=%u captured=%d view=%.2fx%.2f drawable=%.0fx%.0f "
            "layerScale=%.3f currentScale=%.3f\n",
            label, (unsigned long long)version, localTranslationLastSubmitStage,
            (unsigned)localTranslationLastSubmitStatus, localTranslationCapturedDrawable != nil,
            ctx.view.bounds.size.width, ctx.view.bounds.size.height,
            ctx.view.metalLayer.drawableSize.width, ctx.view.metalLayer.drawableSize.height,
            (double)ctx.view.metalLayer.contentsScale, (double)[ctx.view currentBackingScale]);
        return NO;
    }
    BOOL ok = after->targetAllocations == before.targetAllocations + 1 &&
        after->contentRedraws == before.contentRedraws + 1 &&
        after->targetReuses == before.targetReuses &&
        after->targetCurrentBytes > 0;
    fprintf(stdout,
        "LOCAL_EFFECT_TRANSLATION_FACT %s alloc=%llu->%llu redraw=%llu->%llu reuse=%llu->%llu bytes=%llu\n",
        label, (unsigned long long)before.targetAllocations,
        (unsigned long long)after->targetAllocations,
        (unsigned long long)before.contentRedraws,
        (unsigned long long)after->contentRedraws,
        (unsigned long long)before.targetReuses,
        (unsigned long long)after->targetReuses,
        (unsigned long long)after->targetCurrentBytes);
    return localTranslationRequire(ok, label);
}

// This native-only fixture is the caller/owner of its private renderer session.
// Consume only the resize event that the backing-properties notification really
// placed at the FIFO head; do not clear the queue or fabricate an acknowledgement.
// This proves native component resize invalidation, not Cangjie owner dispatch.
static BOOL localTranslationConsumeNativeResize(uint64_t session, uint64_t expectedResizeVersion) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || ctx.destroyed) return NO;
    uint64_t generation = ctx.sessionGeneration;
    uint64_t serialBefore = ctx.inputDequeueSerial;
    uint64_t resizeBefore = ctx.resizeVersion;
    NSUInteger pendingBefore = ctx.pendingInteractions.count;
    CJGuiInternalQueuedInteraction *head = ctx.pendingInteractions.firstObject;
    if (!head || head.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED ||
        pendingBefore != 1 || resizeBefore != expectedResizeVersion) {
        fprintf(stderr,
            "LOCAL_EFFECT_TRANSLATION_RESIZE kind=%u generation=%llu resize=%llu expected=%llu "
            "serial=%llu pending=%lu consumed=0\n",
            head ? head.kind : 0u, (unsigned long long)generation,
            (unsigned long long)resizeBefore, (unsigned long long)expectedResizeVersion,
            (unsigned long long)serialBefore, (unsigned long)pendingBefore);
        return NO;
    }

    CjguiInternalRendererEvent event = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(session, 0, &event);
    uint64_t serialAfter = ctx.inputDequeueSerial;
    NSUInteger pendingAfter = ctx.pendingInteractions.count;
    BOOL accepted = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED &&
        serialAfter == serialBefore + 1 && ctx.sessionGeneration == generation &&
        ctx.resizeVersion == expectedResizeVersion && pendingAfter == 0;
    printf("LOCAL_EFFECT_TRANSLATION_RESIZE kind=%u status=%u generation=%llu "
           "serial=%llu->%llu projection=%llu node=%llu resource=%lld nodeKind=%u "
           "resize=%llu expected=%llu pending=%lu->%lu scope=native_component_resize accepted=%d\n",
        event.kind, (unsigned)status, (unsigned long long)generation,
        (unsigned long long)serialBefore, (unsigned long long)serialAfter,
        (unsigned long long)event.projectionVersion, (unsigned long long)event.nodeId,
        (long long)event.resourceId, event.nodeKind,
        (unsigned long long)ctx.resizeVersion, (unsigned long long)expectedResizeVersion,
        (unsigned long)pendingBefore, (unsigned long)pendingAfter, accepted);
    return localTranslationRequire(accepted, "native_component_consumes_original_resize_before_scene6");
}

@interface CJGuiEffectCompletionGateQueue : NSObject
@property(nonatomic,strong) id<MTLCommandQueue> queue;
@property(nonatomic,strong) id<MTLSharedEvent> gate;
@property(nonatomic,assign) uint64_t nextValue;
@end
@implementation CJGuiEffectCompletionGateQueue
- (id<MTLCommandBuffer>)commandBuffer {
    id<MTLCommandBuffer> buffer = [self.queue commandBuffer];
    uint64_t value = ++self.nextValue;
    [buffer encodeWaitForEvent:self.gate value:value];
    return buffer;
}
@end

static CjguiInternalRendererComposableNode localHomeNode(uint64_t version, uint64_t nodeId,
        int64_t resourceId, uint32_t kind, int64_t x, int64_t y, int64_t width, int64_t height) {
    CjguiInternalRendererComposableNode node = {0};
    node.projectionVersion = version; node.nodeId = nodeId; node.resourceId = resourceId;
    node.nodeKind = kind; node.x = x; node.y = y; node.width = width; node.height = height;
    node.clipX = 40; node.clipY = 50; node.clipWidth = 340; node.clipHeight = 200;
    node.clipCornerRadius = 20.0; node.clipConstraintCount = 1;
    node.clip0X = 40; node.clip0Y = 50; node.clip0Width = 340; node.clip0Height = 200;
    node.clip0CornerRadius = 20.0;
    node.effectGroupSubtreeCount = 1;
    return node;
}

// Four-node shape/paint structure mirrors a real Home row: one rounded,
// masked background group with title, time and summary button text. Every
// descendant carries the row's inherited rounded aperture constraint.
static BOOL localHomeSubmitFailed(uint64_t version) {
    fprintf(stderr, "HOME_SUBMIT_REFUSED version=%llu stage=%s node=%u status=%u captured=%d\n",
        (unsigned long long)version,
        localTranslationLastSubmitStage ?: "unknown",
        localTranslationLastSubmitNodeIndex,
        (unsigned)localTranslationLastSubmitStatus,
        localTranslationCapturedDrawable != nil);
    return NO;
}

static BOOL localHomeSubmit(uint64_t session, uint64_t version, double translateX, double translateY,
        const char *title, const char *time, const char *summary, int64_t resourceBase,
        float maskMiddleAlpha, float maskEndAlpha, BOOL includeVector,
        NSInteger omittedNode, BOOL requestPixelProbe) {
    localTranslationCapturedDrawable = nil;
    localTranslationLastVersion = version;
    localTranslationLastSubmitStage = "home_session";
    localTranslationLastSubmitStatus = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    localTranslationLastSubmitNodeIndex = UINT32_MAX;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || ctx.destroyed) {
        localTranslationLastSubmitStage = "home_session";
        localTranslationLastSubmitStatus = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        return localHomeSubmitFailed(version);
    }
    uint32_t count = includeVector ? 5u : 4u;
    CjguiInternalRendererComposableNode nodes[5] = {0};
    nodes[0] = localHomeNode(version, 7701, resourceBase, CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        52, 82, 316, 54);
    nodes[0].effectGroupPresent = 1; nodes[0].effectGroupSubtreeCount = count;
    nodes[0].effectGroupOpacity = 1.0; nodes[0].cornerRadius = 10.0;
    nodes[0].fillRed = 0.16; nodes[0].fillGreen = 0.32; nodes[0].fillBlue = 0.78; nodes[0].fillAlpha = 0.45;
    nodes[0].effectMaskPresent = 1; nodes[0].effectMaskStopCount = 3;
    nodes[0].effectMaskEndX = 1.0;
    nodes[0].effectMaskStop0Position = 0.0; nodes[0].effectMaskStop0Alpha = 1.0;
    nodes[0].effectMaskStop1Position = 0.45; nodes[0].effectMaskStop1Alpha = maskMiddleAlpha;
    nodes[0].effectMaskStop2Position = 1.0; nodes[0].effectMaskStop2Alpha = maskEndAlpha;
    nodes[1] = localHomeNode(version, 7702, resourceBase + 1,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 64, 82, 198, 30);
    nodes[2] = localHomeNode(version, 7703, resourceBase + 2,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 270, 82, 92, 30);
    nodes[3] = localHomeNode(version, 7704, resourceBase + 3,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 64, 112, 286, 24);
    const char *labels[5] = {"", title ?: "", time ?: "", summary ?: "", ""};
    for (uint32_t index = 1; index < count; index++) {
        nodes[index].textAlpha = 1.0; nodes[index].textRed = 0.96;
        nodes[index].textGreen = 0.97; nodes[index].textBlue = 0.99;
        nodes[index].fontSize = index == 1 ? 13.0 : 11.0;
        nodes[index].fontWeight = index == 1 ? 500u : 400u;
    }
    if (includeVector) {
        nodes[4] = localHomeNode(version, 7705, resourceBase + 4,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC, 56, 101, 12, 12);
        nodes[4].fillAlpha = 1.0;
    }

    localTranslationLastVersion = version;
    localTranslationLastSubmitStage = "home_configure";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_configure_composable_scene(session, version, count);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return localHomeSubmitFailed(version);
    for (uint32_t index = 0; index < count; index++) {
        if ((NSInteger)index == omittedNode) continue;
        // Serialized public ellipse fixture from composable_vector_graphics_native_probe.cj:
        // ellipse(120,80, center(60,40), radii(34,24)), fill(.92,.12,.18,.82),
        // stroke(.10,.68,.94,1), width=3, round cap/join.
        const char *value = index < 4 ? labels[index] :
            "cg1;3;120;80;3;2;3;0.92;0.12;0.18;0.82;0.10;0.68;0.94;1;60;40;34;24;1;60;40";
        localTranslationLastSubmitNodeIndex = index;
        localTranslationLastSubmitStage = "home_set_node";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_node(session,
            index, &nodes[index], index > 0 && index < 4 ? value : "", value, "", "", 0);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return localHomeSubmitFailed(version);
        CjguiInternalRendererComposableGeometry geometry = {0};
        geometry.nodeId = nodes[index].nodeId; geometry.clipCount = 1;
        geometry.translateX = translateX;
        geometry.translateY = translateY + (index == 1 ? localHomeTitleExtraY : 0.0);
        localTranslationLastSubmitStage = "home_set_geometry";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_geometry(
            session, version, index, &geometry);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return localHomeSubmitFailed(version);
    }
    localTranslationLastSubmitStage = "home_stage_background";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return localHomeSubmitFailed(version);
    if (requestPixelProbe) {
        localTranslationSampleX = 180.0 + translateX;
        localTranslationSampleY = 109.0 + translateY;
        localTranslationLastSubmitStage = "home_request_pixel";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
            session, localTranslationSampleX, localTranslationSampleY);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return localHomeSubmitFailed(version);
    }
    localTranslationCapturedDrawable = nil;
    CjguiInternalRendererFrameObservation frame = {0};
    localTranslationLastSubmitStage = "home_present";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK || !localTranslationCapturedDrawable)
        return localHomeSubmitFailed(version);
    if (!requestPixelProbe) return YES;
    localTranslationLastSubmitStage = "home_pixel_readback";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_test_composable_drawable_pixel(session,
        &localTranslationSampleBGRA[0], &localTranslationSampleBGRA[1],
        &localTranslationSampleBGRA[2], &localTranslationSampleBGRA[3]);
    return localTranslationLastSubmitStatus == CJGUI_INTERNAL_RENDERER_OK || localHomeSubmitFailed(version);
}

static BOOL localHomeCheckDelta(const char *name, CjguiInternalRendererEffectStats before,
        CjguiInternalRendererEffectStats after, uint64_t allocations, uint64_t redraws, uint64_t reuses) {
    BOOL ok = after.targetAllocations == before.targetAllocations + allocations &&
        after.contentRedraws == before.contentRedraws + redraws &&
        after.targetReuses == before.targetReuses + reuses;
    fprintf(stderr, "HOME_EFFECT_PHASE name=%s alloc=%llu->%llu redraw=%llu->%llu reuse=%llu->%llu result=%s\n",
        name, (unsigned long long)before.targetAllocations, (unsigned long long)after.targetAllocations,
        (unsigned long long)before.contentRedraws, (unsigned long long)after.contentRedraws,
        (unsigned long long)before.targetReuses, (unsigned long long)after.targetReuses, ok ? "PASS" : "FAIL");
    return localTranslationRequire(ok, name);
}

static BOOL localHomeSameImage(const LocalTranslationReadback *a, const LocalTranslationReadback *b) {
    return a && b && a->drawableBGRA && b->drawableBGRA &&
        a->drawableWidth == b->drawableWidth && a->drawableHeight == b->drawableHeight &&
        a->drawableRowBytes == b->drawableRowBytes &&
        memcmp(a->drawableBGRA, b->drawableBGRA, a->drawableRowBytes * a->drawableHeight) == 0;
}

static uint64_t localHomePixelsDifferentFromSample(const LocalTranslationReadback *image,
        NSRect rect, NSSize pointSize, NSUInteger sampleX, NSUInteger sampleY) {
    if (!image || !image->drawableBGRA || !image->drawableWidth || !image->drawableHeight) return 0;
    if (sampleX >= image->drawableWidth || sampleY >= image->drawableHeight) return 0;
    double sx = image->drawableWidth / MAX(1.0, pointSize.width);
    double sy = image->drawableHeight / MAX(1.0, pointSize.height);
    NSUInteger x0 = MIN(image->drawableWidth, (NSUInteger)MAX(0.0, floor(NSMinX(rect) * sx)));
    NSUInteger y0 = MIN(image->drawableHeight, (NSUInteger)MAX(0.0, floor(NSMinY(rect) * sy)));
    NSUInteger x1 = MIN(image->drawableWidth, (NSUInteger)MAX(0.0, ceil(NSMaxX(rect) * sx)));
    NSUInteger y1 = MIN(image->drawableHeight, (NSUInteger)MAX(0.0, ceil(NSMaxY(rect) * sy)));
    const uint8_t *sample = image->drawableBGRA + sampleY * image->drawableRowBytes + sampleX * 4;
    uint64_t count = 0;
    for (NSUInteger y = y0; y < y1; y++) for (NSUInteger x = x0; x < x1; x++) {
        const uint8_t *p = image->drawableBGRA + y * image->drawableRowBytes + x * 4;
        if (memcmp(p, sample, 4) != 0) count++;
    }
    return count;
}

static void localHomeReleaseImage(LocalTranslationReadback *image) {
    if (!image) return;
    free(image->drawableBGRA); free(image->targetBGRA);
    memset(image, 0, sizeof(*image));
}

static BOOL localHomeWaitCurrentTarget(CJGuiInternalSession *ctx) {
    if (!ctx || ctx.view.composableNodes.count == 0) return NO;
    CJGuiInternalComposableEffectTarget *target = ctx.view.composableNodes.firstObject.effectTarget;
    for (NSUInteger attempt = 0; attempt < 1000 && target && !target.gpuCompleted; attempt++) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }
    return target && target.gpuCompleted;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth = 420, .windowHeight = 320,
                                               .clearColorAlpha = 1};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK || !session) return 2;
        CJGuiInternalSession *ctx = CjguiLookupSession(session);
        localTranslationProbeLayer = ctx.view.metalLayer;
        Method method = class_getInstanceMethod(CAMetalLayer.class, @selector(nextDrawable));
        localTranslationOriginalNextDrawable = method_setImplementation(method,
            (IMP)localTranslationCaptureNextDrawable);

        const NSSize pointSize = ctx.view.bounds.size;
        CjguiInternalRendererEffectStats baseStats = {0}, movedStats = {0};
        CjguiInternalRendererEffectStats maskBefore = {0}, maskAfter = {0};
        CjguiInternalRendererEffectStats contentBefore = {0}, contentAfter = {0};
        CjguiInternalRendererEffectStats clipBefore = {0}, clipAfter = {0};
        CjguiInternalRendererEffectStats scaleBefore = {0}, scaleAfter = {0};
        LocalTranslationReadback baseline = {0}, moved = {0}, flatMask = {0};
        LocalTranslationReadback changedContent = {0}, clipped = {0}, scaled = {0};
        BOOL failed = NO;

        failed |= !localTranslationSubmit(session, 1, 0.0, 420, NO, 0.15f, 0.90f);
        failed |= !localTranslationReadbackNow(session, &baseline);
        failed |= !localTranslationStats(session, &baseStats);
        failed |= !localTranslationRequire(baseStats.targetAllocations == 1 &&
            baseStats.contentRedraws == 1 && baseStats.targetReuses == 0,
            "baseline_allocates_and_encodes_once");
        failed |= !localTranslationRequire(
            localTranslationPixelAt(&baseline, 76, 90, pointSize).red >
            localTranslationPixelAt(&baseline, 170, 90, pointSize).red + 18,
            "baseline_linear_mask_is_visible_in_drawable");
        failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
            "baseline_target_real_gpu_completion_before_translation");

        // Preserve the earlier allocation/redraw RED as its own evidence. The
        // current GREEN path waits for the original target's real completion,
        // then requires placement-only reuse of that immutable raster target.
        CJGuiInternalComposableSceneNode *baselineGroup = ctx.view.composableNodes.firstObject;
        CJGuiInternalComposableEffectTarget *baselineTarget = baselineGroup.effectTarget;
        uint32_t baselineTargetX = baselineTarget.pixelX, baselineTargetY = baselineTarget.pixelY;
        uint32_t baselinePlacementX = baselineGroup.effectPlacementPixelX;
        uint32_t baselinePlacementY = baselineGroup.effectPlacementPixelY;
        failed |= !localTranslationSubmit(session, 2, 32.0, 420, NO, 0.15f, 0.90f);
        failed |= !localTranslationReadbackNow(session, &moved);
        failed |= !localTranslationStats(session, &movedStats);
        CJGuiInternalComposableSceneNode *movedGroup = ctx.view.composableNodes.firstObject;
        failed |= !localTranslationRequire(movedStats.targetAllocations == baseStats.targetAllocations &&
            movedStats.contentRedraws == baseStats.contentRedraws &&
            movedStats.targetReuses == baseStats.targetReuses + 1 && baselineTarget &&
            movedGroup.effectTarget == baselineTarget &&
            baselineTarget.pixelX == baselineTargetX && baselineTarget.pixelY == baselineTargetY &&
            (movedGroup.effectPlacementPixelX != baselinePlacementX ||
             movedGroup.effectPlacementPixelY != baselinePlacementY),
            "common_translation_reuses_completed_immutable_target_and_moves_scene_placement");
        failed |= !localTranslationRequire(baseline.targetBGRA && moved.targetBGRA &&
            baseline.targetWidth == moved.targetWidth &&
            baseline.targetHeight == moved.targetHeight &&
            memcmp(baseline.targetBGRA, moved.targetBGRA,
                baseline.targetRowBytes * baseline.targetHeight) == 0,
            "translated_target_pixels_are_locally_identical");
        failed |= !localTranslationRequire(
            localTranslationGreenPixelsInRect(&baseline, NSMakeRect(62, 76, 124, 26), pointSize) > 0 &&
            localTranslationGreenPixelsInRect(&moved, NSMakeRect(62, 76, 124, 26), pointSize) == 0 &&
            localTranslationGreenPixelsInRect(&moved, NSMakeRect(62, 108, 124, 26), pointSize) > 0,
            "translated_masked_pixels_move_without_ghost");

        failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
            "translated_target_real_gpu_completion_before_mask_only_reuse");
        failed |= !localTranslationStats(session, &maskBefore);
        failed |= !localTranslationSubmit(session, 3, 32.0, 420, NO, 0.50f, 0.50f);
        failed |= !localTranslationReadbackNow(session, &flatMask);
        failed |= !localTranslationStats(session, &maskAfter);
        failed |= !localTranslationRequire(maskAfter.targetAllocations == maskBefore.targetAllocations &&
            maskAfter.contentRedraws == maskBefore.contentRedraws &&
            maskAfter.targetReuses == maskBefore.targetReuses + 1,
            "mask_change_reuses_content_target");
        failed |= !localTranslationRequire(
            localTranslationPixelAt(&moved, 76, 122, pointSize).red >
                localTranslationPixelAt(&flatMask, 76, 122, pointSize).red + 12 &&
            abs((int)localTranslationPixelAt(&flatMask, 76, 122, pointSize).red -
                (int)localTranslationPixelAt(&flatMask, 170, 122, pointSize).red) <= 8,
            "mask_change_updates_composite_without_stale_mask");

        failed |= !localTranslationStats(session, &contentBefore);
        failed |= !localTranslationExpectOneNewTarget(session, 4, 32.0, 420, YES,
            0.50f, 0.50f, contentBefore, &contentAfter, &changedContent,
            "content_change_invalidates_target");

        failed |= !localTranslationStats(session, &clipBefore);
        failed |= !localTranslationExpectOneNewTarget(session, 5, 32.0, 100, YES,
            0.50f, 0.50f, clipBefore, &clipAfter, &clipped,
            "group_clip_change_invalidates_target");
        failed |= !localTranslationRequire(
            localTranslationGreenPixelsInRect(&clipped, NSMakeRect(166, 108, 22, 26), pointSize) == 0,
            "group_clip_still_clips_composite_pixels");

        failed |= !localTranslationStats(session, &scaleBefore);
        uint64_t scaleRevision = 0;
        double oldScale = 0.0, newScale = 0.0;
        uint32_t pixelWidth = 0, pixelHeight = 0;
        CjguiInternalRendererStatus scaleToggleStatus =
            cjgui_internal_renderer_test_toggle_composable_backing_scale(session, &scaleRevision,
                &oldScale, &newScale, &pixelWidth, &pixelHeight);
        BOOL scaleChanged = scaleToggleStatus == CJGUI_INTERNAL_RENDERER_OK && oldScale != newScale;
        failed |= !localTranslationRequire(scaleChanged, "controlled_backing_scale_change");
        printf("LOCAL_EFFECT_TRANSLATION_SCALE revision=%llu old=%.3f new=%.3f drawable=%ux%u "
               "status=%u view=%.2fx%.2f layerScale=%.3f currentScale=%.3f\n",
            (unsigned long long)scaleRevision, oldScale, newScale, pixelWidth, pixelHeight,
            (unsigned)scaleToggleStatus,
            ctx.view.bounds.size.width, ctx.view.bounds.size.height,
            (double)ctx.view.metalLayer.contentsScale, (double)[ctx.view currentBackingScale]);
        BOOL resizeConsumed = scaleChanged && localTranslationConsumeNativeResize(session, scaleRevision);
        BOOL scaleFrameAttempted = NO;
        if (resizeConsumed) {
            scaleFrameAttempted = YES;
            failed |= !localTranslationExpectOneNewTarget(session, 6, 32.0, 100, YES,
                0.50f, 0.50f, scaleBefore, &scaleAfter, &scaled,
                "dpi_change_invalidates_target");
        } else {
            failed |= !localTranslationRequire(NO, "dpi_frame_skipped_without_original_resize_consumption");
        }

        printf("LOCAL_EFFECT_TRANSLATION_RESULT failures=%d frames=%u dpi_frame_attempted=%d "
               "scope=native_component_resize backdrop=absent nested_groups=absent "
               "baseline_alloc=%llu moved_alloc=%llu moved_reuse=%llu moved_redraw=%llu "
               "target_pixels_equal=%d scale=%.3f->%.3f physical_display=not_measured\n",
            failed ? 1 : 0, scaleFrameAttempted ? 6u : 5u, scaleFrameAttempted,
            (unsigned long long)baseStats.targetAllocations,
            (unsigned long long)movedStats.targetAllocations,
            (unsigned long long)movedStats.targetReuses,
            (unsigned long long)movedStats.contentRedraws,
            baseline.targetBGRA && moved.targetBGRA &&
            baseline.targetWidth == moved.targetWidth && baseline.targetHeight == moved.targetHeight &&
            memcmp(baseline.targetBGRA, moved.targetBGRA,
                baseline.targetRowBytes * baseline.targetHeight) == 0, oldScale, newScale);

        // Release the first compact fixture's six CPU snapshots before the
        // Home-equivalent cases. The test retains at most one comparison pair.
        LocalTranslationReadback *initialSnapshots[] = {
            &baseline, &moved, &flatMask, &changedContent, &clipped, &scaled
        };
        for (NSUInteger index = 0; index < sizeof(initialSnapshots) / sizeof(initialSnapshots[0]); index++) {
            free(initialSnapshots[index]->drawableBGRA); initialSnapshots[index]->drawableBGRA = NULL;
            free(initialSnapshots[index]->targetBGRA); initialSnapshots[index]->targetBGRA = NULL;
        }

        // Real Home row aperture shape: rounded background, mask, title/time/
        // summary text and inherited rounded viewport clip. The expected local
        // integer move is the current GREEN assertion; the earlier generic
        // allocation RED remains preserved in its original first-run log.
        const uint64_t homeBaseVersion = 7;
        const int64_t homeResourceBase = 8000;
        CjguiInternalRendererEffectStats homeBefore = {0}, homeStats = {0};
        LocalTranslationReadback homeBase = {0}, homeMoved = {0}, homePhase = {0};
        LocalTranslationReadback homeEdge = {0}, homeEdgeFull = {0};
        LocalTranslationReadback homeRound = {0}, homeRoundFull = {0};
        LocalTranslationReadback homeContent = {0}, homeResource = {0}, homeMask = {0}, homeMsaa = {0};
        failed |= !localTranslationStats(session, &homeBefore);
        failed |= !localTranslationRequire(localHomeSubmit(session, homeBaseVersion, 0, 0,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_baseline_submit");
        failed |= !localTranslationReadbackNow(session, &homeBase);
        failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx), "home_baseline_gpu_write_completed");
        failed |= !localTranslationStats(session, &homeStats);
        failed |= !localHomeCheckDelta("home_baseline_target", homeBefore, homeStats, 1, 1, 0);

        CjguiInternalRendererEffectStats beforeMove = homeStats, afterMove = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 8, 0, 32,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_integer_translation_submit");
        failed |= !localTranslationReadbackNow(session, &homeMoved);
        failed |= !localTranslationStats(session, &afterMove);
        failed |= !localHomeCheckDelta("home_integer_device_translation_expected_local_reuse",
            beforeMove, afterMove, 0, 0, 1);
        failed |= !localTranslationRequire(homeBase.targetBGRA && homeMoved.targetBGRA &&
            homeBase.targetWidth == homeMoved.targetWidth && homeBase.targetHeight == homeMoved.targetHeight &&
            memcmp(homeBase.targetBGRA, homeMoved.targetBGRA,
                homeBase.targetRowBytes * homeBase.targetHeight) == 0,
            "home_integer_translation_local_pixels_identical");
        // Compare the old-only 30pt strip: the former 48pt rectangles
        // overlapped by 16pt, and clear BGRA itself passed the old bright test.
        uint64_t homeOldOnlyBaselineChanges = localHomePixelsDifferentFromSample(
            &homeBase, NSMakeRect(56, 84, 310, 30), pointSize, 0, 0);
        uint64_t homeOldOnlyAfterMoveChanges = localHomePixelsDifferentFromSample(
            &homeMoved, NSMakeRect(56, 84, 310, 30), pointSize, 0, 0);
        uint64_t homeMovedRegionChanges = localHomePixelsDifferentFromSample(
            &homeMoved, NSMakeRect(56, 116, 310, 48), pointSize, 0, 0);
        failed |= !localTranslationRequire(homeOldOnlyBaselineChanges > 0 &&
            homeOldOnlyAfterMoveChanges == 0 && homeMovedRegionChanges > 0,
            "home_old_only_strip_returns_to_actual_clear_and_row_moves");
        localHomeReleaseImage(&homeBase); localHomeReleaseImage(&homeMoved);
        localHomeReleaseImage(&homeBase); localHomeReleaseImage(&homeMoved);

        CjguiInternalRendererEffectStats beforePhase = afterMove, afterPhase = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 9, 0, 32.25,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_fractional_phase_submit");
        failed |= !localTranslationReadbackNow(session, &homePhase);
        failed |= !localTranslationStats(session, &afterPhase);
        failed |= !localHomeCheckDelta("home_fractional_placement_reuses_local_content",
            beforePhase, afterPhase, 0, 0, 1);
        localHomeReleaseImage(&homePhase);

        CjguiInternalRendererEffectStats beforePhaseReset = afterPhase, afterPhaseReset = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 10, 0, 32,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_fractional_phase_reset_submit");
        failed |= !localTranslationReadbackNow(session, &homePhase);
        failed |= !localTranslationStats(session, &afterPhaseReset);
        failed |= !localHomeCheckDelta("home_return_placement_reuses_local_content",
            beforePhaseReset, afterPhaseReset, 0, 0, 1);
        localHomeReleaseImage(&homePhase);

        localHomeTitleExtraY = 4.0;
        CjguiInternalRendererEffectStats beforeChildMove = afterPhaseReset, afterChildMove = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 11, 0, 32,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_child_only_geometry_change_submit");
        localHomeTitleExtraY = 0.0;
        LocalTranslationReadback homeChildMoved = {0};
        failed |= !localTranslationReadbackNow(session, &homeChildMoved);
        failed |= !localTranslationStats(session, &afterChildMove);
        failed |= !localHomeCheckDelta("home_child_only_move_invalidates_local_content",
            beforeChildMove, afterChildMove, 1, 1, 0);
        localHomeReleaseImage(&homeChildMoved);

        CjguiInternalRendererEffectStats beforeEdge = afterChildMove, afterEdge = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 12, 0, 135,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase,
            1.0f, 0.55f, NO, -1, YES), "home_aperture_edge_submit");
        failed |= !localTranslationReadbackNow(session, &homeEdge);
        failed |= !localTranslationStats(session, &afterEdge);
        failed |= !localHomeCheckDelta("home_aperture_intersection_falls_back_generic",
            beforeEdge, afterEdge, 1, 1, 0);
        LocalTranslationPixel edgeInside = localTranslationPixelAt(&homeEdge, 180, 240, pointSize);
        LocalTranslationPixel edgeOutside = localTranslationPixelAt(&homeEdge, 180, 256, pointSize);
        failed |= !localTranslationRequire(edgeInside.red + 20 < edgeOutside.red,
            "home_aperture_edge_clips_row_background");
        failed |= !localTranslationRequire(localHomeSubmit(session, 13, 0, 135,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase + 100,
            1.0f, 0.55f, NO, -1, YES), "home_aperture_full_redraw_reference_submit");
        failed |= !localTranslationReadbackNow(session, &homeEdgeFull);
        failed |= !localTranslationStats(session, &homeStats);
        failed |= !localHomeCheckDelta("home_aperture_reference_forces_fresh_resources",
            afterEdge, homeStats, 1, 1, 0);
        failed |= !localTranslationRequire(localHomeSameImage(&homeEdge, &homeEdgeFull),
            "home_aperture_fallback_matches_fresh_full_redraw_pixel_for_pixel");
        localHomeReleaseImage(&homeEdge); localHomeReleaseImage(&homeEdgeFull);

        CjguiInternalRendererEffectStats beforeRound = homeStats, afterRound = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 14, -18, -18,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase + 100,
            1.0f, 0.55f, NO, -1, YES), "home_rounded_aperture_corner_submit");
        failed |= !localTranslationReadbackNow(session, &homeRound);
        failed |= !localTranslationStats(session, &afterRound);
        failed |= !localHomeCheckDelta("home_rounded_aperture_intersection_falls_back_generic",
            beforeRound, afterRound, 1, 1, 0);
        failed |= !localTranslationRequire(localHomeSubmit(session, 15, -18, -18,
            "Daily notes", "10:42", "Review the latest project changes", homeResourceBase + 200,
            1.0f, 0.55f, NO, -1, YES), "home_rounded_aperture_full_redraw_reference_submit");
        failed |= !localTranslationReadbackNow(session, &homeRoundFull);
        failed |= !localTranslationStats(session, &homeStats);
        failed |= !localHomeCheckDelta("home_rounded_reference_forces_fresh_resources",
            afterRound, homeStats, 1, 1, 0);
        failed |= !localTranslationRequire(localHomeSameImage(&homeRound, &homeRoundFull),
            "home_rounded_clip_fallback_matches_fresh_full_redraw_pixel_for_pixel");
        localHomeReleaseImage(&homeRound); localHomeReleaseImage(&homeRoundFull);

        CjguiInternalRendererEffectStats beforeContent = homeStats, afterContent = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 16, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 200,
            1.0f, 0.55f, NO, -1, YES), "home_same_slot_content_change_submit");
        failed |= !localTranslationReadbackNow(session, &homeContent);
        failed |= !localTranslationStats(session, &afterContent);
        failed |= !localHomeCheckDelta("home_same_slot_text_content_invalidates",
            beforeContent, afterContent, 1, 1, 0);
        localHomeReleaseImage(&homeContent);

        CjguiInternalRendererEffectStats beforeResource = afterContent, afterResource = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 17, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 300,
            1.0f, 0.55f, NO, -1, YES), "home_same_slot_resource_change_submit");
        failed |= !localTranslationReadbackNow(session, &homeResource);
        failed |= !localTranslationStats(session, &afterResource);
        failed |= !localHomeCheckDelta("home_same_slot_resource_identity_invalidates",
            beforeResource, afterResource, 1, 1, 0);
        failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx), "home_resource_generation_gpu_completed");

        CjguiInternalRendererEffectStats beforeMask = afterResource, afterMask = {0};
        failed |= !localTranslationRequire(localHomeSubmit(session, 18, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 300,
            0.50f, 0.20f, NO, -1, YES), "home_mask_only_change_submit");
        failed |= !localTranslationReadbackNow(session, &homeMask);
        failed |= !localTranslationStats(session, &afterMask);
        failed |= !localHomeCheckDelta("home_mask_only_reuses_local_content",
            beforeMask, afterMask, 0, 0, 1);
        failed |= !localTranslationRequire(homeResource.targetBGRA && homeMask.targetBGRA &&
            memcmp(homeResource.targetBGRA, homeMask.targetBGRA,
                homeResource.targetRowBytes * homeResource.targetHeight) == 0 &&
            !localHomeSameImage(&homeResource, &homeMask),
            "home_mask_changes_composite_without_content_reraster");
        localHomeReleaseImage(&homeResource); localHomeReleaseImage(&homeMask);

        CjguiInternalRendererEffectStats beforeMsaa = afterMask, afterMsaa = {0};
        BOOL homeMsaaAccepted = localHomeSubmit(session, 19, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 300,
            0.50f, 0.20f, YES, -1, YES);
        failed |= !localTranslationRequire(homeMsaaAccepted, "home_msaa_control_submit");
        BOOL homeMsaaReady = homeMsaaAccepted;
        if (homeMsaaAccepted) {
            homeMsaaReady &= localTranslationReadbackNow(session, &homeMsaa);
            homeMsaaReady &= localTranslationStats(session, &afterMsaa);
            homeMsaaReady &= localHomeCheckDelta("home_msaa_format_change_invalidates",
                beforeMsaa, afterMsaa, 1, 1, 0);
            homeMsaaReady &= localTranslationRequire(ctx.view.testComposableRenderSampleCount == 4,
                "home_vector_control_uses_real_four_sample_pipeline");
            homeMsaaReady &= localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "home_msaa_generation_gpu_completed");
        } else {
            fprintf(stderr, "HOME_CONTROLS_SKIPPED prerequisite=home_msaa_control_submit\n");
        }

        id<MTLCommandQueue> realQueue = ctx.view.commandQueue;
        if (homeMsaaReady) {
        uint64_t acceptedBeforeIncomplete = ctx.composableSceneVersion;
        BOOL incompleteSubmitted = localHomeSubmit(session, 20, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 300,
            0.50f, 0.20f, YES, 3, NO);
        failed |= !localTranslationRequire(!incompleteSubmitted &&
            ctx.composableSceneVersion == acceptedBeforeIncomplete,
            "home_incomplete_candidate_never_replaces_accepted_scene");

        uint64_t acceptedBeforeFailure = ctx.composableSceneVersion;
        CJGuiInternalComposableSceneNode *acceptedTargetNode = ctx.view.composableNodes.firstObject;
        CJGuiInternalComposableEffectTarget *acceptedTarget = acceptedTargetNode.effectTarget;
        failed |= !localTranslationRequire(
            cjgui_internal_renderer_test_fail_next_composable_main_encoder_after_effects(session) ==
                CJGUI_INTERNAL_RENDERER_OK,
            "home_candidate_failure_hook_armed");
        BOOL failedCandidateSubmitted = localHomeSubmit(session, 21, -18, -18,
            "Candidate must fail", "10:42", "Review the latest project changes", homeResourceBase + 400,
            0.50f, 0.20f, YES, -1, NO);
        failed |= !localTranslationRequire(!failedCandidateSubmitted &&
            localTranslationLastSubmitStatus == CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE &&
            ctx.composableSceneVersion == acceptedBeforeFailure &&
            ctx.view.composableNodes.firstObject.effectTarget == acceptedTarget,
            "home_failed_candidate_preserves_previous_accepted_generation");

        CjguiInternalRendererEffectStats beforeRecovery = {0}, afterRecovery = {0};
        failed |= !localTranslationStats(session, &beforeRecovery);
        failed |= !localTranslationRequire(localHomeSubmit(session, 22, -18, -18,
            "Daily notes revised", "10:42", "Review the latest project changes", homeResourceBase + 300,
            0.50f, 0.20f, YES, -1, YES), "home_original_generation_reaccepted_after_failed_candidate");
        LocalTranslationReadback homeRecovered = {0};
        failed |= !localTranslationReadbackNow(session, &homeRecovered);
        failed |= !localTranslationStats(session, &afterRecovery);
        failed |= !localHomeCheckDelta("home_failure_keeps_completed_cache_generation",
            beforeRecovery, afterRecovery, 0, 0, 1);
        failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget == acceptedTarget &&
            localHomeSameImage(&homeMsaa, &homeRecovered),
            "home_failed_candidate_keeps_old_generation_and_pixels");
        localHomeReleaseImage(&homeMsaa); localHomeReleaseImage(&homeRecovered);

        // Delay actual GPU completion with a real shared-event wait on the same
        // command queue. The first target is genuinely in flight when the next
        // common translation is considered; no target flag is manually edited.
        CJGuiEffectCompletionGateQueue *completionGate = [CJGuiEffectCompletionGateQueue new];
        completionGate.queue = realQueue; completionGate.gate = [ctx.device newSharedEvent];
        BOOL gateReady = completionGate.gate != nil;
        failed |= !localTranslationRequire(gateReady, "home_real_gpu_completion_gate_available");
        if (gateReady) {
            ctx.view.commandQueue = (id<MTLCommandQueue>)completionGate;
            CjguiInternalRendererEffectStats beforePending = {0}, afterPendingFirst = {0}, afterPendingMove = {0};
            failed |= !localTranslationStats(session, &beforePending);
            failed |= !localTranslationRequire(localHomeSubmit(session, 23, 0, 0,
                "Pending generation", "10:42", "Review the latest project changes", homeResourceBase + 500,
                1.0f, 0.55f, NO, -1, NO), "home_pending_first_frame_submit");
            CJGuiInternalComposableEffectTarget *pendingTarget = ctx.view.composableNodes.firstObject.effectTarget;
            failed |= !localTranslationRequire(pendingTarget && !pendingTarget.gpuCompleted,
                "home_first_target_is_actually_uncompleted");
            failed |= !localTranslationStats(session, &afterPendingFirst);
            failed |= !localHomeCheckDelta("home_pending_first_target_allocates",
                beforePending, afterPendingFirst, 1, 1, 0);
            failed |= !localTranslationRequire(localHomeSubmit(session, 24, 0, 32,
                "Pending generation", "10:42", "Review the latest project changes", homeResourceBase + 500,
                1.0f, 0.55f, NO, -1, NO), "home_pending_translation_submit");
            failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget != pendingTarget,
                "home_uncompleted_generation_is_not_reused");
            failed |= !localTranslationStats(session, &afterPendingMove);
            failed |= !localHomeCheckDelta("home_pending_translation_requires_new_generation",
                afterPendingFirst, afterPendingMove, 1, 1, 0);
            completionGate.gate.signaledValue = completionGate.nextValue;
            ctx.view.commandQueue = realQueue;
            CJGuiInternalComposableEffectTarget *completedTarget = ctx.view.composableNodes.firstObject.effectTarget;
            for (NSUInteger attempt = 0; attempt < 1000 && completedTarget && !completedTarget.gpuCompleted; attempt++) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                    beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
            }
            failed |= !localTranslationRequire(pendingTarget.gpuCompleted && completedTarget.gpuCompleted,
                "home_pending_generations_publish_real_gpu_completion");
            LocalTranslationReadback pendingReadback = {0};
            failed |= !localTranslationReadbackNow(session, &pendingReadback);
            localHomeReleaseImage(&pendingReadback);
            completionGate = nil;
        }
        } else {
            fprintf(stderr, "HOME_CONTROLS_SKIPPED prerequisite=home_msaa_positive_control\n");
        }
        ctx.view.commandQueue = realQueue;

        // At the end of this one serialized native window run, return to a
        // real 2x backing scale and distinguish phase from pixel extent. No
        // additional window, parallel readback, or synthetic resize event.
        uint64_t phase2ResizeRevision = 0;
        double phase2OldScale = 0.0, phase2NewScale = 0.0;
        uint32_t phase2DrawableWidth = 0, phase2DrawableHeight = 0;
        CjguiInternalRendererStatus phase2ToggleStatus =
            cjgui_internal_renderer_test_toggle_composable_backing_scale(session, &phase2ResizeRevision,
                &phase2OldScale, &phase2NewScale, &phase2DrawableWidth, &phase2DrawableHeight);
        BOOL phase2ScaleReturned = phase2ToggleStatus == CJGUI_INTERNAL_RENDERER_OK &&
            phase2OldScale != phase2NewScale && fabs(phase2NewScale - 2.0) < 0.001 &&
            phase2DrawableWidth == 840 && phase2DrawableHeight == 640;
        failed |= !localTranslationRequire(phase2ScaleReturned, "phase2_control_returns_to_real_2x_backing");
        BOOL phase2ResizeConsumed = phase2ScaleReturned &&
            localTranslationConsumeNativeResize(session, phase2ResizeRevision);
        failed |= !localTranslationRequire(phase2ResizeConsumed,
            "phase2_control_consumes_original_2x_resize_event");
        if (phase2ResizeConsumed) {
            const int64_t phase2ResourceBase = homeResourceBase + 600;
            CjguiInternalRendererEffectStats phase2Before = {0}, phase2At125 = {0}, phase2At375 = {0};
            CjguiInternalRendererEffectStats phase2At0 = {0}, phase2AtHalf = {0}, phase2At625 = {0};
            LocalTranslationReadback phase2BaseImage = {0}, phase2HalfImage = {0};
            CJGuiInternalComposableEffectTarget *phase2BaseTarget = nil;
            CJGuiInternalComposableEffectTarget *phase2At125Target = nil;
            CJGuiInternalComposableEffectTarget *phase2At375Target = nil;
            CJGuiInternalComposableEffectTarget *phase2At0Target = nil;
            CJGuiInternalComposableEffectTarget *phase2AtHalfTarget = nil;
            failed |= !localTranslationStats(session, &phase2Before);
            failed |= !localTranslationRequire(localHomeSubmit(session, 25, 0, 0,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_integer_origin_submit");
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_integer_origin_real_gpu_completion");
            failed |= !localTranslationStats(session, &phase2At0);
            failed |= !localHomeCheckDelta("phase2_integer_origin_target",
                phase2Before, phase2At0, 1, 1, 0);

            CjguiInternalRendererEffectStats before125 = phase2At0;
            failed |= !localTranslationRequire(localHomeSubmit(session, 26, 0, 0.125,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_fraction_125_submit");
            phase2At125Target = ctx.view.composableNodes.firstObject.effectTarget;
            failed |= !localTranslationStats(session, &phase2At125);
            failed |= !localHomeCheckDelta("phase2_fraction_125_reuses_local_content",
                before125, phase2At125, 0, 0, 1);
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_fraction_125_real_gpu_completion");

            CjguiInternalRendererEffectStats before375 = phase2At125;
            failed |= !localTranslationRequire(localHomeSubmit(session, 27, 0, 0.375,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_fraction_375_submit");
            phase2At375Target = ctx.view.composableNodes.firstObject.effectTarget;
            failed |= !localTranslationStats(session, &phase2At375);
            failed |= !localHomeCheckDelta("phase2_fraction_375_same_extent_reuses_local_content",
                before375, phase2At375, 0, 0, 1);
            BOOL phase2EqualExtentReuse = phase2At125Target && phase2At375Target &&
                phase2At125Target == phase2At375Target &&
                phase2At125Target.pixelWidth == phase2At375Target.pixelWidth &&
                phase2At125Target.pixelHeight == phase2At375Target.pixelHeight;
            failed |= !localTranslationRequire(phase2EqualExtentReuse,
                "phase2_distinct_nonzero_placements_keep_same_completed_target_and_extent");
            fprintf(stderr, "HOME_EFFECT_SCALE2_PHASE_EXTENT phase=.125 extent=%ux%u phase=.375 extent=%ux%u "
                "same_extent_reuse=%d\n",
                phase2At125Target.pixelWidth, phase2At125Target.pixelHeight,
                phase2At375Target.pixelWidth, phase2At375Target.pixelHeight,
                phase2EqualExtentReuse);
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_fraction_375_real_gpu_completion");

            CjguiInternalRendererEffectStats beforeReturn0 = phase2At375;
            failed |= !localTranslationRequire(localHomeSubmit(session, 28, 0, 0,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, YES), "phase2_return_to_integer_origin_submit");
            failed |= !localTranslationReadbackNow(session, &phase2BaseImage);
            failed |= !localTranslationStats(session, &phase2At0);
            failed |= !localHomeCheckDelta("phase2_return_to_integer_origin_reuses_local_content",
                beforeReturn0, phase2At0, 0, 0, 1);
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_integer_origin_refresh_real_gpu_completion");
            phase2At0Target = ctx.view.composableNodes.firstObject.effectTarget;
            uint32_t phase2TargetX = phase2At0Target.pixelX, phase2TargetY = phase2At0Target.pixelY;
            uint32_t phase2PlacementX = ctx.view.composableNodes.firstObject.effectPlacementPixelX;
            uint32_t phase2PlacementY = ctx.view.composableNodes.firstObject.effectPlacementPixelY;

            CjguiInternalRendererEffectStats beforeHalf = phase2At0;
            failed |= !localTranslationRequire(localHomeSubmit(session, 29, 0, 0.5,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, YES), "phase2_one_device_pixel_translation_submit");
            failed |= !localTranslationReadbackNow(session, &phase2HalfImage);
            failed |= !localTranslationStats(session, &phase2AtHalf);
            CJGuiInternalComposableSceneNode *phase2HalfGroup = ctx.view.composableNodes.firstObject;
            phase2AtHalfTarget = phase2HalfGroup.effectTarget;
            failed |= !localHomeCheckDelta("phase2_half_point_one_device_pixel_reuses",
                beforeHalf, phase2AtHalf, 0, 0, 1);
            BOOL phase2HalfPixelReuse = phase2At0Target && phase2AtHalfTarget == phase2At0Target &&
                phase2AtHalfTarget.pixelX == phase2TargetX && phase2AtHalfTarget.pixelY == phase2TargetY &&
                phase2HalfGroup.effectPlacementPixelX == phase2PlacementX &&
                phase2HalfGroup.effectPlacementPixelY == phase2PlacementY + 1 &&
                phase2BaseImage.targetBGRA && phase2HalfImage.targetBGRA &&
                phase2BaseImage.targetWidth == phase2HalfImage.targetWidth &&
                phase2BaseImage.targetHeight == phase2HalfImage.targetHeight &&
                phase2BaseImage.targetRowBytes == phase2HalfImage.targetRowBytes &&
                memcmp(phase2BaseImage.targetBGRA, phase2HalfImage.targetBGRA,
                    phase2BaseImage.targetRowBytes * phase2BaseImage.targetHeight) == 0;
            failed |= !localTranslationRequire(phase2HalfPixelReuse,
                "phase2_one_device_pixel_moves_placement_only_and_keeps_target_bytes");
            fprintf(stderr, "HOME_EFFECT_SCALE2_PIXEL_MOVE scale=2.000 logical_delta=0.500 physical_delta=1 "
                "placementY=%u->%u target_same=%d local_bytes_equal=%d\n",
                phase2PlacementY, phase2HalfGroup.effectPlacementPixelY,
                phase2AtHalfTarget == phase2At0Target,
                phase2BaseImage.targetBGRA && phase2HalfImage.targetBGRA &&
                phase2BaseImage.targetWidth == phase2HalfImage.targetWidth &&
                phase2BaseImage.targetHeight == phase2HalfImage.targetHeight &&
                phase2BaseImage.targetRowBytes == phase2HalfImage.targetRowBytes &&
                memcmp(phase2BaseImage.targetBGRA, phase2HalfImage.targetBGRA,
                    phase2BaseImage.targetRowBytes * phase2BaseImage.targetHeight) == 0);
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_half_point_target_real_gpu_completion");

            CjguiInternalRendererEffectStats before625 = phase2AtHalf;
            failed |= !localTranslationRequire(localHomeSubmit(session, 30, 0, 0.625,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_one_eighth_point_phase_change_submit");
            failed |= !localTranslationStats(session, &phase2At625);
            failed |= !localHomeCheckDelta("phase2_one_eighth_point_placement_reuses_local_content",
                before625, phase2At625, 0, 0, 1);
            failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget == phase2AtHalfTarget,
                "phase2_one_eighth_point_moves_composition_and_preserves_completed_content");
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_one_eighth_point_target_real_gpu_completion");
            // A normal Home scroll exposed 108/109-pixel target oscillation
            // for the identical 54-point row. This non-dyadic translation
            // makes the world-space union height 54.000000000000014 even
            // though its local GPU quads and complete text are unchanged.
            CjguiInternalRendererEffectStats noisyBefore = phase2At625, noisyAfter = {0};
            failed |= !localTranslationRequire(localHomeSubmit(session, 31, 0, 12.6191883756611,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_nondyadic_translation_submit");
            failed |= !localTranslationStats(session, &noisyAfter);
            failed |= !localHomeCheckDelta("phase2_nondyadic_extent_reuses_completed_content",
                noisyBefore, noisyAfter, 0, 0, 1);
            failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget == phase2AtHalfTarget &&
                ctx.view.composableNodes.firstObject.effectTarget.pixelHeight == 108,
                "phase2_nondyadic_translation_keeps_108_pixel_target");
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_nondyadic_target_real_gpu_completion");
            LocalTranslationReadback noisyReturnImage = {0};
            failed |= !localTranslationRequire(localHomeSubmit(session, 32, 0, 0,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, YES), "phase2_nondyadic_return_submit");
            failed |= !localTranslationReadbackNow(session, &noisyReturnImage);
            failed |= !localTranslationRequire(localHomeSameImage(&phase2BaseImage, &noisyReturnImage),
                "phase2_nondyadic_return_preserves_full_drawable_and_target_pixels");
            localHomeReleaseImage(&noisyReturnImage);
            // A real fractional child extension must still enlarge content;
            // snapping every local extent to an integer would crop this row.
            localHomeTitleExtraY = 24.125;
            failed |= !localTranslationRequire(localHomeSubmit(session, 33, 0, 0,
                "Daily notes revised", "10:42", "Review the latest project changes", phase2ResourceBase,
                0.50f, 0.20f, NO, -1, NO), "phase2_real_fractional_extent_submit");
            localHomeTitleExtraY = 0.0;
            failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget != phase2AtHalfTarget &&
                ctx.view.composableNodes.firstObject.effectTarget.pixelHeight == 109,
                "phase2_real_fractional_extent_keeps_required_109th_pixel");
            failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),
                "phase2_real_fractional_extent_gpu_completed");
            printf("HOME_EFFECT_SCALE2_RESULT returned=%.3f drawable=%ux%u fractions=.125,.375 equal_extent=1 "
                   "half_point_device_delta=1 phase_delta=.125 checks=assertions\n",
                phase2NewScale, phase2DrawableWidth, phase2DrawableHeight);
            localHomeReleaseImage(&phase2BaseImage); localHomeReleaseImage(&phase2HalfImage);
        } else {
            fprintf(stderr, "HOME_EFFECT_SCALE2_CONTROLS_SKIPPED status=%u old=%.3f new=%.3f drawable=%ux%u\n",
                (unsigned)phase2ToggleStatus, phase2OldScale, phase2NewScale,
                phase2DrawableWidth, phase2DrawableHeight);
        }

        printf("HOME_EFFECT_LOCAL_RESULT failures=%d scope=renderer_component fixture=home_row "
               "aperture=340x200 rounded=20 row=316x54 text=title,time,summary "
               "cases=integer_move,phase,rect_clip,rounded_clip,content,resource,mask,msaa,incomplete,encode_failure,gpu_pending,scale2_phase_extent,scale2_one_pixel\n",
            failed ? 1 : 0);

        localHomeReleaseImage(&homeBase); localHomeReleaseImage(&homeMoved);
        localHomeReleaseImage(&homePhase); localHomeReleaseImage(&homeEdge);
        localHomeReleaseImage(&homeEdgeFull); localHomeReleaseImage(&homeRound);
        localHomeReleaseImage(&homeRoundFull); localHomeReleaseImage(&homeContent);
        localHomeReleaseImage(&homeResource); localHomeReleaseImage(&homeMask);
        localHomeReleaseImage(&homeMsaa);

        LocalTranslationReadback *snapshots[] = {
            &baseline, &moved, &flatMask, &changedContent, &clipped, &scaled
        };
        for (NSUInteger index = 0; index < sizeof(snapshots) / sizeof(snapshots[0]); index++) {
            free(snapshots[index]->drawableBGRA);
            free(snapshots[index]->targetBGRA);
        }
        method_setImplementation(method, localTranslationOriginalNextDrawable);
        localTranslationCapturedDrawable = nil;
        localTranslationProbeLayer = nil;
        cjgui_internal_renderer_destroy(session);
        return failed ? 1 : 0;
    }
}
