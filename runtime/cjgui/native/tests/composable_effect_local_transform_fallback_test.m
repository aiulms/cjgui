// The local effect fast path may only rebase translation. A group containing
// any non-unit scale or nonzero rotation must use the generic path, whose
// output bounds, private paint inputs and cache identity include the transform.
// This fixture uses two non-image paint nodes, so the IMAGE exclusion in the
// local path cannot mask the behavior under test.
#define main previousLocalTranslationFixtureMain
#import "composable_effect_local_translation_production_test.m"
#undef main

static BOOL transformIsRed(LocalTranslationPixel pixel) {
    return pixel.red > 150 && pixel.green < 110 && pixel.blue < 110;
}

static BOOL transformSubmit(uint64_t session, uint64_t version,
        double translateX, double translateY,
        double scaleX, double scaleY, double rotateDegrees) {
    localTranslationCapturedDrawable = nil;
    localTranslationLastVersion = version;
    localTranslationLastSubmitStage = "transform_configure";
    CjguiInternalRendererComposableNode nodes[2];
    nodes[0] = localTranslationNode(version, 9101, CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        100, 100, 40, 40, 420);
    nodes[0].effectGroupPresent = 1;
    nodes[0].effectGroupSubtreeCount = 2;
    nodes[0].effectGroupOpacity = 1.0;
    nodes[1] = localTranslationNode(version, 9102, CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        100, 100, 40, 40, 420);
    nodes[1].fillRed = 1.0;
    nodes[1].fillAlpha = 1.0;
    nodes[1].rotateDegrees = rotateDegrees;

    localTranslationLastSubmitStatus = cjgui_internal_renderer_configure_composable_scene(
        session, version, 2);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    for (uint32_t index = 0; index < 2; index++) {
        localTranslationLastSubmitNodeIndex = index;
        localTranslationLastSubmitStage = "transform_set_node";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_node(
            session, index, &nodes[index], "", "", "", "", 0);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
        CjguiInternalRendererComposableGeometry geometry = {0};
        geometry.nodeId = nodes[index].nodeId;
        geometry.clipCount = 1;
        geometry.translateX = translateX;
        geometry.translateY = translateY;
        // The root is layout only. The child carries the paint transform, so
        // its group remains mixed: identity support plus transformed paint.
        geometry.scaleX = index == 1 ? scaleX : 1.0;
        geometry.scaleY = index == 1 ? scaleY : 1.0;
        localTranslationLastSubmitStage = "transform_set_geometry";
        localTranslationLastSubmitStatus = cjgui_internal_renderer_set_composable_scene_geometry(
            session, version, index, &geometry);
        if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    }
    localTranslationLastSubmitStage = "transform_stage_background";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_stage_window_background(
        session, version, 0, 1);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    localTranslationSampleX = 120.0 + translateX;
    localTranslationSampleY = 120.0 + translateY;
    localTranslationLastSubmitStage = "transform_request_pixel";
    localTranslationLastSubmitStatus =
        cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
            session, localTranslationSampleX, localTranslationSampleY);
    if (localTranslationLastSubmitStatus != CJGUI_INTERNAL_RENDERER_OK) return NO;
    localTranslationCapturedDrawable = nil;
    CjguiInternalRendererFrameObservation frame = {0};
    localTranslationLastSubmitStage = "transform_present";
    localTranslationLastSubmitStatus = cjgui_internal_renderer_present_composable_scene(
        session, &frame);
    return localTranslationLastSubmitStatus == CJGUI_INTERNAL_RENDERER_OK &&
        localTranslationCapturedDrawable != nil;
}

static BOOL transformCapture(uint64_t session, LocalTranslationReadback *out,
        const char *label) {
    if (!localTranslationReadbackNow(session, out)) {
        fprintf(stderr, "LOCAL_TRANSFORM_FALLBACK_FAIL %s_readback stage=%s status=%u\n",
            label, localTranslationLastSubmitStage, (unsigned)localTranslationLastSubmitStatus);
        return NO;
    }
    return YES;
}

static BOOL transformExpectLocal(CJGuiInternalSession *ctx, const char *label,
        uint32_t expectedWidth, uint32_t expectedHeight) {
    CJGuiInternalComposableEffectTarget *target = ctx.view.composableNodes.firstObject.effectTarget;
    BOOL ok = target && target.localForeground && target.pixelWidth == expectedWidth &&
        target.pixelHeight == expectedHeight;
    printf("LOCAL_TRANSFORM_FALLBACK_STATE %s local=%d target=%ux%u expected=%ux%u\n",
        label, target ? target.localForeground : -1,
        target ? target.pixelWidth : 0u, target ? target.pixelHeight : 0u,
        expectedWidth, expectedHeight);
    return localTranslationRequire(ok, label);
}

static BOOL transformExpectGeneric(CJGuiInternalSession *ctx, const char *label,
        uint32_t minWidth, uint32_t maxWidth, uint32_t minHeight, uint32_t maxHeight,
        uint32_t bodyPixelX) {
    CJGuiInternalComposableEffectTarget *target = ctx.view.composableNodes.firstObject.effectTarget;
    BOOL ok = target && !target.localForeground &&
        target.pixelWidth >= minWidth && target.pixelWidth <= maxWidth &&
        target.pixelHeight >= minHeight && target.pixelHeight <= maxHeight &&
        target.pixelX < bodyPixelX;
    printf("LOCAL_TRANSFORM_FALLBACK_STATE %s local=%d target=%ux%u at=%u,%u "
           "range=%u..%ux%u..%u body_x=%u\n",
        label, target ? target.localForeground : -1,
        target ? target.pixelWidth : 0u, target ? target.pixelHeight : 0u,
        target ? target.pixelX : 0u, target ? target.pixelY : 0u,
        minWidth, maxWidth, minHeight, maxHeight, bodyPixelX);
    return localTranslationRequire(ok, label);
}

static BOOL transformStats(uint64_t session, const char *label,
        CjguiInternalRendererEffectStats *out) {
    if (!localTranslationStats(session, out)) {
        fprintf(stderr, "LOCAL_TRANSFORM_FALLBACK_FAIL %s_stats\n", label);
        return NO;
    }
    return YES;
}

static BOOL transformExpectStats(const char *label,
        CjguiInternalRendererEffectStats before, CjguiInternalRendererEffectStats after,
        uint64_t allocations, uint64_t redraws, uint64_t reuses) {
    BOOL ok = after.targetAllocations == before.targetAllocations + allocations &&
        after.contentRedraws == before.contentRedraws + redraws &&
        after.targetReuses == before.targetReuses + reuses;
    printf("LOCAL_TRANSFORM_FALLBACK_STATS %s alloc=%llu->%llu redraw=%llu->%llu "
           "reuse=%llu->%llu expect=+%llu,+%llu,+%llu\n",
        label, (unsigned long long)before.targetAllocations,
        (unsigned long long)after.targetAllocations,
        (unsigned long long)before.contentRedraws,
        (unsigned long long)after.contentRedraws,
        (unsigned long long)before.targetReuses,
        (unsigned long long)after.targetReuses,
        (unsigned long long)allocations, (unsigned long long)redraws,
        (unsigned long long)reuses);
    return localTranslationRequire(ok, label);
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
        CjguiInternalRendererEffectStats before = {0}, after = {0};
        LocalTranslationReadback identity = {0}, transformed = {0}, rotated = {0};
        LocalTranslationReadback restored = {0}, moved = {0};
        BOOL failed = NO;

        // 1. Identity translation stays on the local fast path.
        failed |= !transformSubmit(session, 1, 0.0, 0.0, 1.0, 1.0, 0.0);
        failed |= !transformCapture(session, &identity, "identity");
        failed |= !transformStats(session, "identity", &before);
        double pointScale = identity.drawableWidth / MAX(1.0, pointSize.width);
        uint32_t bodyPixels = (uint32_t)llround(40.0 * pointScale);
        uint32_t bodyPixelX = (uint32_t)llround(100.0 * pointScale);
        failed |= !transformExpectStats("identity", (CjguiInternalRendererEffectStats){0},
            before, 1, 1, 0);
        failed |= !transformExpectLocal(ctx, "identity_stays_local", bodyPixels, bodyPixels);
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&identity, 120.0, 120.0, pointSize)),
            "identity_center_is_painted");
        failed |= !localHomeWaitCurrentTarget(ctx);

        // 2. Non-uniform scale 2x/0.5x plus 45 degrees. macOS scales the point
        //    first and rotates second, so the painted 40x40 body occupies a
        //    thin 45-degree parallelogram whose corner reaches (139,151).
        //    Rotate-then-scale would instead cover (157,120). The separate
        //    points therefore distinguish the composition order, not just the
        //    presence of a transform.
        failed |= !transformSubmit(session, 2, 0.0, 0.0, 2.0, 0.5, 45.0);
        failed |= !transformCapture(session, &transformed, "transformed");
        failed |= !transformStats(session, "transformed", &after);
        uint32_t hull45 = (uint32_t)llround(2.0 * hypot(20.0 * 2.0, 20.0 * 0.5) * pointScale);
        failed |= !transformExpectStats("transformed", before, after, 1, 1, 0);
        failed |= !transformExpectGeneric(ctx, "scale_rotate_leaves_local_path",
            hull45 - 2, hull45 + 2, hull45 - 2, hull45 + 2, bodyPixelX);
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&transformed, 120.0, 120.0, pointSize)),
            "transformed_center_is_painted");
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&transformed, 139.0, 151.0, pointSize)),
            "scale_then_rotate_corner_outside_body_is_painted");
        failed |= !localTranslationRequire(
            !transformIsRed(localTranslationPixelAt(&transformed, 157.0, 120.0, pointSize)),
            "rotate_then_scale_only_point_is_not_painted");
        failed |= !localHomeWaitCurrentTarget(ctx);

        // 3. A second dynamic transform (3x/0.5x, 90 degrees) must also leave
        //    the local path and use the new transform for rendering. Its painted
        //    rectangle is 20 wide by 120 tall; the opposite order would be
        //    120 wide by 20 tall, so the sampled points swap.
        before = after;
        failed |= !transformSubmit(session, 3, 0.0, 0.0, 3.0, 0.5, 90.0);
        failed |= !transformCapture(session, &rotated, "rotated");
        failed |= !transformStats(session, "rotated", &after);
        uint32_t hull90 = (uint32_t)llround(2.0 * hypot(20.0 * 3.0, 20.0 * 0.5) * pointScale);
        failed |= !transformExpectStats("rotated", before, after, 1, 1, 0);
        failed |= !transformExpectGeneric(ctx, "second_transform_leaves_local_path",
            hull90 - 2, hull90 + 2, hull90 - 2, hull90 + 2, bodyPixelX);
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&rotated, 120.0, 175.0, pointSize)),
            "scale_then_rotate_vertical_extent_is_painted");
        failed |= !localTranslationRequire(
            !transformIsRed(localTranslationPixelAt(&rotated, 170.0, 120.0, pointSize)),
            "rotate_then_scale_horizontal_extent_is_not_painted");
        failed |= !localHomeWaitCurrentTarget(ctx);

        // 4. Restoring identity must resume the local fast path at the new
        //    placement. The previous generic target cannot be reused.
        before = after;
        failed |= !transformSubmit(session, 4, 25.0, 0.0, 1.0, 1.0, 0.0);
        failed |= !transformCapture(session, &restored, "restored");
        failed |= !transformStats(session, "restored", &after);
        failed |= !transformExpectStats("restored", before, after, 1, 1, 0);
        failed |= !transformExpectLocal(ctx, "identity_resumes_local_path", bodyPixels, bodyPixels);
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&restored, 145.0, 120.0, pointSize)),
            "restored_center_is_painted_at_translation");
        failed |= !localTranslationRequire(
            !transformIsRed(localTranslationPixelAt(&restored, 120.0, 120.0, pointSize)),
            "restored_paint_left_the_old_placement");
        failed |= !localHomeWaitCurrentTarget(ctx);
        CJGuiInternalComposableEffectTarget *restoredTarget =
            ctx.view.composableNodes.firstObject.effectTarget;

        // 5. Pure translation after recovery still reuses the completed local
        //    texture; this is the positive control that keeps the fast path.
        before = after;
        failed |= !transformSubmit(session, 5, 57.0, 0.0, 1.0, 1.0, 0.0);
        failed |= !transformCapture(session, &moved, "moved");
        failed |= !transformStats(session, "moved", &after);
        failed |= !transformExpectStats("moved", before, after, 0, 0, 1);
        failed |= !localTranslationRequire(
            ctx.view.composableNodes.firstObject.effectTarget == restoredTarget,
            "translation_reuses_completed_local_target");
        failed |= !localTranslationRequire(
            moved.targetWidth == restored.targetWidth &&
            moved.targetHeight == restored.targetHeight &&
            moved.targetRowBytes == restored.targetRowBytes &&
            moved.targetBGRA && restored.targetBGRA &&
            memcmp(moved.targetBGRA, restored.targetBGRA,
                moved.targetRowBytes * moved.targetHeight) == 0,
            "translation_keeps_local_texture_pixels");
        failed |= !localTranslationRequire(
            transformIsRed(localTranslationPixelAt(&moved, 177.0, 120.0, pointSize)) &&
            !transformIsRed(localTranslationPixelAt(&moved, 145.0, 120.0, pointSize)),
            "translation_moves_local_texture_placement");

        printf("LOCAL_TRANSFORM_FALLBACK_DIAG point_scale=%.3f identity=%ux%u "
               "scale45=%ux%u at=%u,%u scale90=%ux%u at=%u,%u restored=%ux%u\n",
            pointScale, (unsigned)identity.targetWidth, (unsigned)identity.targetHeight,
            (unsigned)transformed.targetWidth, (unsigned)transformed.targetHeight,
            (unsigned)transformed.targetPixelX, (unsigned)transformed.targetPixelY,
            (unsigned)rotated.targetWidth, (unsigned)rotated.targetHeight,
            (unsigned)rotated.targetPixelX, (unsigned)rotated.targetPixelY,
            (unsigned)restored.targetWidth, (unsigned)restored.targetHeight);

        free(identity.drawableBGRA); free(identity.targetBGRA);
        free(transformed.drawableBGRA); free(transformed.targetBGRA);
        free(rotated.drawableBGRA); free(rotated.targetBGRA);
        free(restored.drawableBGRA); free(restored.targetBGRA);
        free(moved.drawableBGRA); free(moved.targetBGRA);
        method_setImplementation(method, localTranslationOriginalNextDrawable);
        localTranslationCapturedDrawable = nil;
        localTranslationProbeLayer = nil;
        cjgui_internal_renderer_destroy(session);
        return failed ? 1 : 0;
    }
}
