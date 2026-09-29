#import <AppKit/AppKit.h>
#import "../cjgui_internal_renderer.h"

static int check(BOOL ok, const char *what) {
    if (ok) return 0;
    fprintf(stderr, "geometry progress: FAIL %s\n", what);
    return 1;
}

static CjguiInternalRendererStatus submit(uint64_t session, uint64_t version,
                                          CjguiInternalRendererFrameObservation *frame) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 100;
    node.projectionVersion = version;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    node.width = 80; node.height = 40;
    node.clipWidth = 600; node.clipHeight = 400;
    node.fillRed = 0.2; node.fillGreen = 0.4; node.fillBlue = 0.6;
    node.fillAlpha = 1.0; node.textAlpha = 1.0;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node, "geometry", "", "", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return cjgui_internal_renderer_present_composable_scene(session, frame);
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth = 320, .windowHeight = 180,
            .clearColorRed = 0.08, .clearColorGreen = 0.1, .clearColorBlue = 0.12,
            .clearColorAlpha = 1.0};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (check(status == CJGUI_INTERNAL_RENDERER_OK && session != 0, "create")) return 1;
        NSWindow *firstWindow = NSApp.windows.lastObject;
        CjguiInternalRendererFrameObservation frame = {0};
        CjguiInternalRendererComposableDisplayProgress before = {0}, changed = {0}, recovered = {0};
        if (check(submit(session, 1, &frame) == CJGUI_INTERNAL_RENDERER_OK, "first_submit") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &before) == CJGUI_INTERNAL_RENDERER_OK,
                  "first_progress") ||
            check(before.submittedSceneVersion == 1 && before.submittedFrameIndex == frame.frameIndex &&
                  before.submittedFrameIndex > 0 && before.currentPointWidth == before.submittedPointWidth &&
                  before.currentPointHeight == before.submittedPointHeight &&
                  before.currentDrawableWidthPixels == before.submittedDrawableWidthPixels &&
                  before.currentBackingScale == before.submittedBackingScale,
                  "first_current_and_committed_same_version")) return 1;
        CjguiInternalRendererStatus otherStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t other = cjgui_internal_renderer_create(&config, &otherStatus);
        CjguiInternalRendererFrameObservation otherFrame = {0};
        CjguiInternalRendererComposableDisplayProgress otherBefore = {0}, otherAfter = {0};
        if (check(otherStatus == CJGUI_INTERNAL_RENDERER_OK && other != 0 && other != session, "other_create") ||
            check(submit(other, 1, &otherFrame) == CJGUI_INTERNAL_RENDERER_OK, "other_submit") ||
            check(cjgui_internal_renderer_composable_display_progress(other, &otherBefore) == CJGUI_INTERNAL_RENDERER_OK,
                  "other_progress")) return 1;
        uint64_t revision = 0;
        double oldScale = 0, newScale = 0;
        uint32_t pixelWidth = 0, pixelHeight = 0;
        if (check(cjgui_internal_renderer_test_toggle_composable_backing_scale(session, &revision,
                &oldScale, &newScale, &pixelWidth, &pixelHeight) == CJGUI_INTERNAL_RENDERER_OK,
                "backing_notification") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &changed) == CJGUI_INTERNAL_RENDERER_OK,
                  "changed_progress") ||
            check(changed.currentGeometryRevision > before.currentGeometryRevision &&
                  changed.currentBackingScale == newScale && changed.currentBackingScale != before.currentBackingScale &&
                  changed.currentPointWidth == before.currentPointWidth &&
                  changed.currentDrawableWidthPixels == pixelWidth &&
                  changed.submittedBackingScale == before.submittedBackingScale &&
                  changed.submittedGeometryRevision == before.submittedGeometryRevision &&
                  changed.submittedFrameIndex == before.submittedFrameIndex,
                  "current_changed_committed_old")) return 1;
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidChangeBackingPropertiesNotification
                                                            object:firstWindow];
        CjguiInternalRendererComposableDisplayProgress duplicate = {0};
        if (check(cjgui_internal_renderer_composable_display_progress(session, &duplicate) == CJGUI_INTERNAL_RENDERER_OK &&
                  duplicate.currentGeometryRevision == changed.currentGeometryRevision,
                  "duplicate_same_scale_no_revision") ||
            check(cjgui_internal_renderer_composable_display_progress(other, &otherAfter) == CJGUI_INTERNAL_RENDERER_OK &&
                  otherAfter.currentGeometryRevision == otherBefore.currentGeometryRevision &&
                  otherAfter.submittedFrameIndex == otherBefore.submittedFrameIndex,
                  "other_window_isolated")) return 1;
        if (check(cjgui_internal_renderer_test_set_composable_present_failures(session, 1) == CJGUI_INTERNAL_RENDERER_OK,
                  "arm_present_failure") ||
            check(submit(session, 2, &frame) != CJGUI_INTERNAL_RENDERER_OK, "forced_present_failure") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &duplicate) == CJGUI_INTERNAL_RENDERER_OK &&
                  duplicate.currentBackingScale == newScale &&
                  duplicate.submittedBackingScale == before.submittedBackingScale &&
                  duplicate.submittedFrameIndex == before.submittedFrameIndex,
                  "failed_redraw_keeps_old_commit")) return 1;
        if (check(submit(session, 3, &frame) == CJGUI_INTERNAL_RENDERER_OK, "recovery_submit") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &recovered) == CJGUI_INTERNAL_RENDERER_OK &&
                  recovered.submittedSceneVersion == 3 && recovered.submittedFrameIndex == frame.frameIndex &&
                  recovered.submittedBackingScale == newScale &&
                  recovered.submittedGeometryRevision == recovered.currentGeometryRevision,
                  "recovered_same_version")) return 1;
        uint32_t actualWidth = 0, actualHeight = 0;
        if (check(cjgui_internal_renderer_test_set_composable_content_size(session, 337, 191,
                &actualWidth, &actualHeight) == CJGUI_INTERNAL_RENDERER_OK, "resize") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &changed) == CJGUI_INTERNAL_RENDERER_OK &&
                  changed.currentPointWidth == actualWidth && changed.currentPointHeight == actualHeight &&
                  changed.submittedPointWidth == recovered.submittedPointWidth &&
                  changed.currentGeometryRevision > recovered.currentGeometryRevision,
                  "resize_current_ahead")) return 1;
        if (check(submit(session, 4, &frame) == CJGUI_INTERNAL_RENDERER_OK, "resize_submit") ||
            check(cjgui_internal_renderer_composable_display_progress(session, &recovered) == CJGUI_INTERNAL_RENDERER_OK &&
                  recovered.submittedPointWidth == actualWidth &&
                  recovered.submittedDrawableWidthPixels == recovered.currentDrawableWidthPixels &&
                  recovered.submittedGeometryRevision == recovered.currentGeometryRevision,
                  "resize_submitted_same_version")) return 1;
        fprintf(stdout, "geometry_progress initial=%gx%g@%g/%ux%u scale_after=%g/%ux%u "
                        "revisions=%llu,%llu,%llu frames=%llu,%llu two_window_isolated=true\n",
                before.currentPointWidth, before.currentPointHeight, before.currentBackingScale,
                before.currentDrawableWidthPixels, before.currentDrawableHeightPixels,
                newScale, pixelWidth, pixelHeight,
                (unsigned long long)before.currentGeometryRevision,
                (unsigned long long)changed.currentGeometryRevision,
                (unsigned long long)recovered.currentGeometryRevision,
                (unsigned long long)before.submittedFrameIndex,
                (unsigned long long)recovered.submittedFrameIndex);
        if (check(cjgui_internal_renderer_destroy(other) == CJGUI_INTERNAL_RENDERER_OK, "other_close") ||
            check(cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK, "close")) return 1;
        return 0;
    }
}
