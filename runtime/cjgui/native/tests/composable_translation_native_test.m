// One accepted geometry drives the production hit, AX and FIFO event paths.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>
#include <math.h>
#include <stdio.h>

static int require(BOOL passed, const char *name) {
    if (passed) return 0;
    fprintf(stderr, "F11_TRANSLATION_RED %s\n", name);
    return 1;
}

static double sampleX = -1.0;
static double sampleY = 1.0;
static uint8_t sampledGreen = 0;

static CjguiInternalRendererStatus submit(uint64_t session, uint64_t version,
    double parentX, double parentY, double childLocalX, double childLocalY,
    BOOL invalidGeometry) {
    CjguiInternalRendererComposableNode root = {0}, child = {0};
    root.nodeId = 100; root.projectionVersion = version; root.resourceId = -1;
    root.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    root.x = 0; root.y = 0; root.width = 60; root.height = 30;
    root.clipX = 0; root.clipY = 0; root.clipWidth = 120; root.clipHeight = 80;
    root.clipConstraintCount = 1;
    root.clip0X = 0; root.clip0Y = 0; root.clip0Width = 120; root.clip0Height = 80;
    root.effectGroupSubtreeCount = 2;
    child.nodeId = 101; child.projectionVersion = version; child.resourceId = -1;
    child.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    child.isInteractive = 1; child.x = 2; child.y = 0; child.width = 20; child.height = 20;
    child.clipX = 0; child.clipY = 0; child.clipWidth = 60; child.clipHeight = 30;
    child.clipConstraintCount = 2;
    child.clip0X = 0; child.clip0Y = 0; child.clip0Width = 120; child.clip0Height = 80;
    child.clip1X = 0; child.clip1Y = 0; child.clip1Width = 60; child.clip1Height = 30;
    child.effectGroupSubtreeCount = 1;
    child.fillRed = 1.0; child.fillGreen = 0.1; child.fillBlue = 0.1;
    child.fillAlpha = 1.0; child.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry rootVisual = {0}, childVisual = {0};
    rootVisual.nodeId = root.nodeId; rootVisual.clipCount = 1;
    rootVisual.translateX = parentX; rootVisual.translateY = parentY;
    childVisual.nodeId = child.nodeId; childVisual.clipCount = 2;
    childVisual.translateX = parentX + childLocalX;
    childVisual.translateY = parentY + childLocalY;
    childVisual.clip1X = parentX; childVisual.clip1Y = parentY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 2);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "", "", "root", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 1, &child, "Go", "", "child", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &rootVisual);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (invalidGeometry) childVisual.translateX = 5000.0;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 1, &childVisual);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (sampleX >= 0.0) {
        status = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
            session, sampleX, sampleY);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    CjguiInternalRendererFrameObservation frame = {0};
    status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status == CJGUI_INTERNAL_RENDERER_OK && sampleX >= 0.0) {
        uint8_t b = 0, g = 0, r = 0, a = 0;
        status = cjgui_internal_renderer_test_composable_drawable_pixel(session, &b, &g, &r, &a);
        if (status == CJGUI_INTERNAL_RENDERER_OK) sampledGreen = g;
    }
    return status;
}

static CjguiInternalRendererStatus submitBackdrop(uint64_t session, uint64_t version,
    double sourceTranslateX, uint8_t outBGRA[4]) {
    CjguiInternalRendererComposableNode nodes[3] = {0};
    CjguiInternalRendererComposableGeometry geometry[3] = {0};
    nodes[0].nodeId = 300; nodes[0].projectionVersion = version; nodes[0].resourceId = -1;
    nodes[0].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[0].x = 0; nodes[0].y = 0; nodes[0].width = 60; nodes[0].height = 80;
    nodes[0].fillRed = 1.0; nodes[0].fillAlpha = 1.0;
    nodes[0].effectGroupSubtreeCount = 1;
    nodes[1].nodeId = 301; nodes[1].projectionVersion = version; nodes[1].resourceId = -1;
    nodes[1].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[1].x = 45; nodes[1].y = 15; nodes[1].width = 50; nodes[1].height = 50;
    nodes[1].effectGroupPresent = 1; nodes[1].effectGroupSubtreeCount = 2;
    nodes[1].effectGroupOpacity = 1.0; nodes[1].effectBackdropBlurRadiusPoints = 4;
    nodes[2].nodeId = 302; nodes[2].projectionVersion = version; nodes[2].resourceId = -1;
    nodes[2].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[2].x = 45; nodes[2].y = 15; nodes[2].width = 50; nodes[2].height = 50;
    nodes[2].effectGroupSubtreeCount = 1;
    for (uint32_t index = 0; index < 3; index++) {
        nodes[index].clipX = 0; nodes[index].clipY = 0;
        nodes[index].clipWidth = 120; nodes[index].clipHeight = 80;
        nodes[index].clipConstraintCount = 1;
        nodes[index].clip0X = 0; nodes[index].clip0Y = 0;
        nodes[index].clip0Width = 120; nodes[index].clip0Height = 80;
        geometry[index].nodeId = nodes[index].nodeId;
        geometry[index].clipCount = 1;
    }
    geometry[0].translateX = sourceTranslateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 3);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    for (uint32_t index = 0; index < 3; index++) {
        status = cjgui_internal_renderer_set_composable_scene_node(session, index, &nodes[index],
            "", "", "", "", 0);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, version,
            index, &geometry[index]);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(session, 60.5, 40.0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return cjgui_internal_renderer_test_composable_drawable_pixel(session,
        &outBGRA[0], &outBGRA[1], &outBGRA[2], &outBGRA[3]);
}

static CjguiInternalRendererStatus submitLongTextWithTransport(uint64_t session, uint64_t version,
    double nodeTranslateY, double clipTranslateY, BOOL preserveActiveLocalText) {
    static NSMutableString *body = nil;
    if (!body) {
        body = [[NSMutableString alloc] init];
        for (NSUInteger row = 0; row < 720; row++)
            [body appendFormat:@"row %04lu 中文🙂\n", (unsigned long)row];
    }
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 990; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    node.x = 0; node.y = 0; node.width = 1000; node.height = 10000;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 1000; node.clipHeight = 400;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 1000; node.clip0Height = 400;
    node.effectGroupSubtreeCount = 1;
    node.isInteractive = 1;
    node.preservesActiveLocalText = preserveActiveLocalText ? 1 : 0;
    node.textAlpha = 1.0; node.textRed = 0.0; node.textGreen = 0.0; node.textBlue = 0.0;
    node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateY = nodeTranslateY; geometry.clip0Y = clipTranslateY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", preserveActiveLocalText ? "" : body.UTF8String, "long text", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus submitLongText(uint64_t session, uint64_t version,
    double nodeTranslateY, double clipTranslateY) {
    return submitLongTextWithTransport(session, version, nodeTranslateY, clipTranslateY, NO);
}

static CjguiInternalRendererStatus submitClippedSingleLineWithTransport(uint64_t session,
    uint64_t version, double translateX, BOOL preserveActiveLocalText) {
    static NSMutableString *body = nil;
    if (!body) {
        body = [[NSMutableString alloc] init];
        for (NSUInteger index = 0; index < 150; index++) [body appendString:@"中"];
    }
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 991; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    node.x = 0; node.y = 0; node.width = 1000; node.height = 40;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 100; node.clipHeight = 40;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 100; node.clip0Height = 40;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.preservesActiveLocalText = preserveActiveLocalText ? 1 : 0;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateX = translateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", preserveActiveLocalText ? "" : body.UTF8String, "single-line", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus submitControl(uint64_t session, uint64_t version,
    uint64_t nodeId, int64_t resourceId, uint32_t kind, double translateX) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = nodeId; node.resourceId = resourceId; node.projectionVersion = version;
    node.nodeKind = kind; node.isInteractive = 1;
    node.width = 20; node.height = 20;
    node.clipWidth = 120; node.clipHeight = 80;
    node.clipConstraintCount = 1;
    node.clip0Width = 120; node.clip0Height = 80;
    node.effectGroupSubtreeCount = 1;
    node.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = nodeId; geometry.clipCount = 1; geometry.translateX = translateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ? "Go" : "", "", "control", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth = 120, .windowHeight = 80,
            .clearColorRed = 0.0, .clearColorGreen = 0.0, .clearColorBlue = 0.0,
            .clearColorAlpha = 1.0};
        CjguiInternalRendererStatus created = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &created);
        if (require(created == CJGUI_INTERNAL_RENDERER_OK && session > 0, "create")) return 1;
        if (require(submit(session, 1, 0.25, 0.5, -0.75, 0.25, NO) == CJGUI_INTERNAL_RENDERER_OK,
            "accepted_nested_submit")) return 2;
        CJGuiInternalSession *ctx = CjguiLookupSession(session);
        CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
        CJGuiInternalComposableSceneNode *child = ctx.composableNodes[1];
        double caretX = 0, caretY = 0, caretWidth = 0, caretHeight = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            &caretX, &caretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK,
            "initial_caret_from_prepared_text")) return 18;
        int32_t rangeCount = cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4);
        double rangeX = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 0);
        double rangeY = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 1);
        if (require(rangeCount > 0, "initial_selection_range_from_prepared_text")) return 21;
        if (require(fabs(NSMinX(CjguiComposableVisualNodeRect(child)) - 1.5) < 0.000001 &&
            fabs(NSMinY(CjguiComposableVisualNodeRect(child)) - 0.75) < 0.000001,
            "nested_exact_rect") ||
            require([overlay nodeAtPoint:NSMakePoint(1.49, 1.0)] == nil &&
                [overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == child,
                "fractional_hit_boundary") ||
            require(CjguiComposablePointInClipChain(1.5, 1.0, child) &&
                !CjguiComposablePointInClipChain(60.26, 1.0, child),
                "ancestor_clip_owner_offset")) return 3;
        [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *ax = overlay.accessibilityActions.lastObject;
        NSRect axRect = [ax accessibilityFrameInParentSpace];
        if (require(fabs(NSMinX(axRect) - 1.5) < 0.000001 &&
            fabs(NSMinY(axRect) - 0.75) < 0.000001,
            "ax_uses_accepted_visual_rect")) return 4;
        if (require(cjgui_internal_renderer_test_activate_composable_point(session, 1.5f, 1.0f) ==
            CJGUI_INTERNAL_RENDERER_OK, "activate_at_fractional_edge")) return 5;
        BOOL sawPrecise = NO;
        for (int i = 0; i < 8; i++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK ||
                cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK)
                return 6;
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) {
                sawPrecise = exact.present == 1 && exact.kind == event.kind && exact.nodeId == 101 &&
                    exact.projectionVersion == 1 && exact.resourceId == -1 &&
                    fabs(exact.x - 1.5) < 0.000001 && fabs(exact.y - 1.0) < 0.000001 &&
                    fabs(exact.translateX + 0.5) < 0.000001 &&
                    fabs(exact.translateY - 0.75) < 0.000001;
                break;
            }
        }
        if (require(sawPrecise, "queued_precise_identity_and_transform")) return 7;
        if (require(submit(session, 2, 0.25, 0.5, 5000.0, 0.25, YES) !=
            CJGUI_INTERNAL_RENDERER_OK, "invalid_native_geometry_rejected") ||
            require(ctx.composableSceneVersion == 1 &&
                [overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == ctx.composableNodes[1],
                "rejected_candidate_keeps_accepted_hit")) return 8;
        double rejectedCaretX = 0, rejectedCaretY = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            &rejectedCaretX, &rejectedCaretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK &&
            fabs(rejectedCaretX - caretX) < 0.000001 && fabs(rejectedCaretY - caretY) < 0.000001,
            "rejected_candidate_keeps_caret")) return 19;
        if (require(cjgui_internal_renderer_test_activate_composable_point(session, 1.5f, 1.0f) ==
            CJGUI_INTERNAL_RENDERER_OK, "queue_button_before_new_acceptance")) return 34;
        if (require(submit(session, 3, 0.25, 0.5, 4.0, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "recovery_submit") ||
            require([overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == nil &&
                [overlay nodeAtPoint:NSMakePoint(6.25, 1.0)] == ctx.composableNodes[1],
                "old_hit_rejected_new_hit_accepted")) return 9;
        BOOL oldButtonEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) continue;
            if (cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK) break;
            oldButtonEvent = event.projectionVersion == 1 && exact.projectionVersion == 1 &&
                exact.nodeId == 101 && exact.resourceId == -1 && fabs(exact.x - 1.5) < 0.000001 &&
                ctx.composableSceneVersion == 3;
            break;
        }
        if (require(oldButtonEvent, "queued_old_button_keeps_frozen_version_and_point")) return 35;
        double movedCaretX = 0, movedCaretY = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            &movedCaretX, &movedCaretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK &&
            fabs(movedCaretX - caretX - 4.75) < 0.000001 &&
            fabs(movedCaretY - caretY) < 0.000001,
            "geometry_cow_retains_caret_and_moves_it_once")) return 20;
        int32_t movedRangeCount = cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4);
        double movedRangeX = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 0);
        double movedRangeY = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 1);
        if (require(movedRangeCount == rangeCount &&
            fabs(movedRangeX - rangeX - 4.75) < 0.000001 &&
            fabs(movedRangeY - rangeY) < 0.000001,
            "selection_range_moves_with_accepted_visual_geometry")) return 22;
        // Restore the fractional edge, then sample adjacent 2x drawable
        // texels. Their centres are 1.25 and 1.75 logical points; the body
        // starts at 1.5. The same accepted geometry decides both pixels.
        sampleX = 1.25;
        if (require(submit(session, 4, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "fractional_pixel_outside_submit")) return 10;
        uint8_t outsideGreen = sampledGreen;
        uint64_t textRasterBefore = ctx.view.testComposableTextRasterCount;
        sampleX = 1.75;
        if (require(submit(session, 5, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "fractional_pixel_inside_submit")) return 11;
        uint8_t insideGreen = sampledGreen;
        if (require(outsideGreen > insideGreen + 80,
            "two_x_adjacent_pixels_straddle_fractional_edge")) {
            fprintf(stderr, "F11_PIXEL outside_g=%u inside_g=%u\n", outsideGreen, insideGreen);
            return 12;
        }
        if (require(textRasterBefore > 0 &&
            ctx.view.testComposableTextRasterCount == textRasterBefore,
            "translation_reuses_text_raster")) return 13;
        sampleX = -1.0;
        if (require(submit(session, 6, 0.0, 0.0, 0.0, 0.0, NO) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == textRasterBefore,
            "translated_to_zero_reuses_full_text_coverage")) return 23;
        uint64_t scaleRevision = 0; double oldScale = 0.0, newScale = 0.0;
        uint32_t pixelWidth = 0, pixelHeight = 0;
        if (require(cjgui_internal_renderer_test_toggle_composable_backing_scale(session,
            &scaleRevision, &oldScale, &newScale, &pixelWidth, &pixelHeight) ==
            CJGUI_INTERNAL_RENDERER_OK && oldScale == 2.0 && newScale == 1.0,
            "controlled_scale_two_to_one")) return 14;
        sampleX = 0.25;
        if (require(submit(session, 7, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "one_x_outside_submit")) return 15;
        uint8_t outsideOneXGreen = sampledGreen;
        sampleX = 2.25;
        if (require(submit(session, 8, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "one_x_inside_submit")) return 16;
        uint8_t insideOneXGreen = sampledGreen;
        if (require(outsideOneXGreen > insideOneXGreen + 80,
            "one_x_pixels_straddle_fractional_edge")) return 17;
        // Keep the quantized ROI and every POD byte unchanged. Moving only
        // accepted visual geometry must invalidate both the group's rendered
        // pixels and an earlier painter sampled by an in-app backdrop.
        CJGuiInternalComposableSceneNode *source = ctx.composableNodes[0];
        CjguiInternalRendererComposableNode sourcePOD = source.node;
        sourcePOD.fillAlpha = 1.0;
        source.node = sourcePOD;
        CGSize cacheDrawable = CGSizeMake(240, 160);
        MTLClearColor cacheClear = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        NSString *groupBefore = CjguiEffectContentSignature(ctx.composableNodes, 0, 2,
            0, 0, 120, 80, NO, NSMakeSize(120, 80), cacheDrawable);
        NSString *backdropBefore = CjguiBackdropSignature(ctx.view, 1, 0, 0, 20, 20,
            0, 20, 4, 2.0f, 2.0f, 6, 6, cacheDrawable, cacheClear);
        CjguiInternalRendererComposableGeometry sourceGeometry = source.geometry;
        sourceGeometry.translateX += 0.125;
        source.geometry = sourceGeometry;
        NSString *groupAfter = CjguiEffectContentSignature(ctx.composableNodes, 0, 2,
            0, 0, 120, 80, NO, NSMakeSize(120, 80), cacheDrawable);
        NSString *backdropAfter = CjguiBackdropSignature(ctx.view, 1, 0, 0, 20, 20,
            0, 20, 4, 2.0f, 2.0f, 6, 6, cacheDrawable, cacheClear);
        if (require(![backdropBefore isEqualToString:backdropAfter],
            "subpixel_backdrop_cache_dependency") ||
            require(![groupBefore isEqualToString:groupAfter],
            "subpixel_group_cache_dependency")) return 24;
        // Production coverage planner: the same long body must remain bounded
        // when only its accepted visual transform (or its clip owner) changes.
        CJGuiInternalComposableSceneNode *longText = [[CJGuiInternalComposableSceneNode alloc] init];
        CjguiInternalRendererComposableNode longValue = {0};
        longValue.nodeId = 990; longValue.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        longValue.width = 1000; longValue.height = 10000;
        longValue.clipWidth = 1000; longValue.clipHeight = 400;
        longValue.clipConstraintCount = 1;
        longValue.clip0Width = 1000; longValue.clip0Height = 400;
        longText.node = longValue;
        CjguiInternalRendererComposableGeometry longGeometry = {0};
        longGeometry.nodeId = 990; longGeometry.clipCount = 1;
        longText.geometry = longGeometry;
        NSRect zeroCoverage = CjguiComposableTextTextureRectForNode(longText);
        longGeometry.translateY = 0.25;
        longText.geometry = longGeometry;
        NSRect translatedCoverage = CjguiComposableTextTextureRectForNode(longText);
        uint64_t boundedBytes = 0;
        NSArray<NSValue *> *boundedTiles = CjguiPlanComposableTextTiles(translatedCoverage,
            CjguiComposableTextNodeLayoutRect(longText), 1.0, &boundedBytes);
        if (require(!NSIsEmptyRect(zeroCoverage) && NSHeight(zeroCoverage) < 500.0 &&
            !NSIsEmptyRect(translatedCoverage) && NSHeight(translatedCoverage) < 500.0 &&
            boundedTiles.count > 0 && boundedBytes <= CjguiComposableTextTextureByteCapacity,
            "translated_long_text_uses_bounded_visible_tiles")) {
            fprintf(stderr, "F11_TEXT_COVERAGE zero=%.1f translated=%.1f tiles=%lu bytes=%llu\n",
                NSHeight(zeroCoverage), NSHeight(translatedCoverage), (unsigned long)boundedTiles.count,
                (unsigned long long)boundedBytes);
            return 26;
        }
        CJGuiInternalComposableSceneNode *memoText = [[CJGuiInternalComposableSceneNode alloc] init];
        CjguiInternalRendererComposableNode memoValue = longValue;
        memoValue.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        memoValue.width = 280; memoValue.height = 1000; memoValue.fontSize = 14;
        memoValue.clipWidth = 280; memoValue.clipHeight = 180;
        memoValue.clip0Width = 280; memoValue.clip0Height = 180;
        memoText.node = memoValue;
        memoText.geometry = longGeometry;
        NSString *memoBody = @"中文🙂 text extent measurement wraps at the accepted width";
        NSRect memoFirst = CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        CjguiInternalRendererComposableGeometry movedMemoGeometry = memoText.geometry;
        movedMemoGeometry.translateY += 0.25;
        memoText.geometry = movedMemoGeometry;
        NSRect memoMoved = CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        if (require(!NSIsEmptyRect(memoFirst) && !NSIsEmptyRect(memoMoved) &&
            memoText.testTextExtentMeasurementCount == 1,
            "text_extent_reused_across_visual_translation")) return 42;
        memoValue.width = 240;
        memoText.node = memoValue;
        (void)CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        if (require(memoText.testTextExtentMeasurementCount == 2,
            "text_extent_invalidates_on_wrap_width")) return 43;
        (void)CjguiComposableTextTextureRectForNodeWithText(memoText, @"中文🙂 changed body");
        if (require(memoText.testTextExtentMeasurementCount == 3,
            "text_extent_invalidates_on_content")) return 44;
        uint8_t oldBackdrop[4] = {0}, movedBackdrop[4] = {0}, stableBackdrop[4] = {0};
        CjguiInternalRendererEffectStats oldStats = {0}, movedStats = {0}, stableStats = {0};
        if (require(submitBackdrop(session, 9, 0.0, oldBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_baseline_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &oldStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_baseline_stats") ||
            require(submitBackdrop(session, 10, 0.75, movedBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_moved_source_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &movedStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_moved_stats") ||
            require(movedStats.backdropPrefixPasses > oldStats.backdropPrefixPasses &&
                abs((int)movedBackdrop[2] - (int)oldBackdrop[2]) >= 3,
                "backdrop_source_move_redraws_pixels") ||
            require(submitBackdrop(session, 11, 0.75, stableBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
                "backdrop_static_source_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &stableStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_static_stats") ||
            require(stableStats.backdropPrefixPasses == movedStats.backdropPrefixPasses &&
                stableStats.backdropCacheHits > movedStats.backdropCacheHits &&
            memcmp(movedBackdrop, stableBackdrop, 4) == 0,
            "backdrop_static_cache_reuses_exact_pixels")) return 25;
        if (require(submitLongText(session, 12, 0.0, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "long_text_initial_accepted")) return 27;
        uint64_t longRasterInitial = ctx.view.testComposableTextRasterCount;
        uint64_t longBytes = ctx.composableNodes[0].textTextureByteCount;
        if (require(longBytes > 0 && longBytes < CjguiComposableTextTextureByteCapacity &&
            ctx.composableNodes[0].textTileTextures.count == 4,
            "long_text_initial_bounded_tiles")) return 28;
        id<MTLTexture> initialTile = ctx.composableNodes[0].textTileTextures.firstObject;
        id<MTLTexture> retainedNextRow = ctx.composableNodes[0].textTileTextures[1];
        uint64_t initialSubmittedFrame = ctx.view.frameIndex;
        NSArray<id<MTLTexture>> *initialSubmission =
            ctx.submittedTextTextures[@(initialSubmittedFrame)];
        CjguiTextSubmissionCompletion *initialCompletion =
            ctx.submittedTextCompletionFlags[@(initialSubmittedFrame)];
        if (require([initialSubmission containsObject:initialTile],
            "submitted_frame_holds_exact_text_tile_generation")) return 40;
        if (require(submitLongText(session, 13, 0.25, 0.0) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == longRasterInitial &&
            ctx.composableNodes[0].textTileTextures.firstObject == initialTile,
            "quarter_point_reuses_tile_identity")) return 29;
        if (require(submitLongText(session, 14, -258.25, 0.0) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == longRasterInitial + 2 &&
            ctx.composableNodes[0].textTileTextures.firstObject == retainedNextRow &&
            ctx.composableNodes[0].textTextureByteCount <= CjguiComposableTextTextureByteCapacity,
            "crossing_grid_rasterizes_only_new_row")) {
            fprintf(stderr, "F11_TILE_CROSS initial=%llu now=%llu first=%p retained=%p count=%lu bytes=%llu\n",
                (unsigned long long)longRasterInitial,
                (unsigned long long)ctx.view.testComposableTextRasterCount,
                ctx.composableNodes[0].textTileTextures.firstObject, retainedNextRow,
                (unsigned long)ctx.composableNodes[0].textTileTextures.count,
                (unsigned long long)ctx.composableNodes[0].textTextureByteCount);
            return 30;
        }
        uint64_t currentAcceptedBytes = ctx.composableNodes[0].textTextureByteCount;
        // The real submitted frame may already have completed while this
        // synchronous owner turn is still running. Wait for that actual Metal
        // fence, then prove a pending generation is charged and a completed
        // one is pruned without requiring the main dispatch queue to drain.
        for (NSUInteger retry = 0; retry < 1000 && !initialCompletion.resourcesReleased; retry++)
            usleep(1000);
        if (require(initialCompletion.resourcesReleased &&
            [initialSubmission containsObject:initialTile] &&
            ![ctx.composableNodes[0].textTileTextures containsObject:initialTile],
            "retired_text_tile_gpu_completion_observed")) return 41;
        (void)CjguiComposableRetainedTextTextureBytes(ctx);
        NSNumber *heldFrame = @(UINT64_MAX - 1u);
        CjguiTextSubmissionCompletion *heldFence = [[CjguiTextSubmissionCompletion alloc] init];
        ctx.submittedTextTextures[heldFrame] = initialSubmission;
        ctx.submittedTextCompletionFlags[heldFrame] = heldFence;
        uint64_t pendingBytes = CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(pendingBytes > currentAcceptedBytes &&
            pendingBytes <= CjguiComposableTextTextureByteCapacity,
            "retired_inflight_text_tile_stays_in_budget_until_completion")) return 51;
        heldFence.resourcesReleased = YES;
        uint64_t completedBytes = CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(completedBytes < pendingBytes &&
            !ctx.submittedTextTextures[heldFrame] &&
            !ctx.submittedTextCompletionFlags[heldFrame],
            "completed_text_tile_retires_before_next_admission")) return 52;
        uint64_t translatedRaster = ctx.view.testComposableTextRasterCount;
        if (require(submitLongText(session, 15, -258.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == translatedRaster,
            "clip_owner_subpoint_motion_reuses_tiles")) return 31;
        if (require(cjgui_internal_renderer_focus_composable_node(session, 990) ==
            CJGUI_INTERNAL_RENDERER_OK &&
            ctx.composableSceneOverlay.activeNodeId == 990,
            "focus_long_text_native_owner")) return 32;
        uint64_t acceptedBeforeFocusedMove = ctx.composableSceneVersion;
        id<MTLTexture> acceptedFocusedTile = ctx.composableNodes[0].textTileTextures.firstObject;
        if (require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
            CJGUI_INTERNAL_RENDERER_OK, "arm_focused_preparation_failure") ||
            require(submitLongText(session, 16, -514.25, 0.5) != CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == acceptedBeforeFocusedMove &&
                ctx.composableNodes[0].textTileTextures.firstObject == acceptedFocusedTile,
                "focused_missing_tile_failure_keeps_accepted_scene") ||
            require(submitLongText(session, 16, -514.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == 16 &&
                ctx.composableNodes[0].textTextureByteCount <= CjguiComposableTextTextureByteCapacity,
                "focused_missing_tile_retry_accepts_complete_coverage")) return 33;
        if (require(submitControl(session, 17, 101, -1,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "button_rebind_baseline") ||
            require(cjgui_internal_renderer_test_activate_composable_point(session, 1.0f, 1.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "queue_before_rebind") ||
            require(submitControl(session, 18, 101, 8,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
                "accept_rebound_button")) return 36;
        BOOL oldReboundEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) continue;
            oldReboundEvent = event.projectionVersion == 17 && event.resourceId == -1 &&
                ctx.composableSceneVersion == 18 && ctx.composableNodes[0].node.resourceId == 8;
            break;
        }
        if (require(oldReboundEvent, "rebind_does_not_retarget_queued_button")) return 37;
        if (require(submitControl(session, 19, 202, 3,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "split_capture_baseline") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 2.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "queue_capture_begin") ||
            require(submitControl(session, 20, 202, 3,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER, 100.25) == CJGUI_INTERNAL_RENDERER_OK,
                "accept_split_translation_before_pump")) return 38;
        BOOL oldCaptureEvent = NO;
        uint64_t capturedGestureEpoch = 0;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) continue;
            if (cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK) break;
            oldCaptureEvent = event.projectionVersion == 19 && exact.projectionVersion == 19 &&
                exact.resourceId == 3 && fabs(exact.translateX) < 0.000001 &&
                fabs(exact.x - 2.0) < 0.000001 && ctx.composableSceneVersion == 20;
            capturedGestureEpoch = event.bindingEpoch;
            break;
        }
        if (require(oldCaptureEvent, "queued_capture_begin_stays_old_projection")) return 39;
        if (require(capturedGestureEpoch != 0, "pointer_begin_has_gesture_epoch") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 2, 105.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "same_gesture_update_after_accept")) return 42;
        BOOL continuedEpoch = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) continue;
            continuedEpoch = event.bindingEpoch == capturedGestureEpoch && event.projectionVersion == 20;
            break;
        }
        if (require(continuedEpoch, "accepted_refresh_keeps_same_pointer_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 3, 105.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "end_first_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 101.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "begin_second_generation")) return 43;
        uint64_t secondGestureEpoch = overlay.pointerCaptureGestureEpoch;
        if (require(secondGestureEpoch != 0 && secondGestureEpoch != capturedGestureEpoch,
                "pointer_generation_not_reused") ||
            require(cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session, capturedGestureEpoch) ==
                CJGUI_INTERNAL_RENDERER_OK && overlay.pointerCaptureActive &&
                overlay.pointerCaptureGestureEpoch == secondGestureEpoch,
                "late_cancel_cannot_clear_new_capture") ||
            require(cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session, secondGestureEpoch) ==
                CJGUI_INTERNAL_RENDERER_OK && !overlay.pointerCaptureActive,
                "matching_cancel_releases_capture")) return 44;
        // The prior generation's terminal and second BEGIN remain in the FIFO
        // after testing native capture cancellation. Settle them before the
        // separate sparse-scene pointer assertion.
        for (int turn = 0; turn < 16; turn++) {
            CjguiInternalRendererEvent ignored = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &ignored) != CJGUI_INTERNAL_RENDERER_OK) break;
        }
        // A sparse accepted scene reuses the node POD captured in scene 20.
        // Its node.projectionVersion remains 20, while a fresh pointer must be
        // stamped with the accepted input scene 21 or the core rejects it.
        CjguiInternalRendererComposableGeometry reusedGeometry = ctx.composableNodes[0].geometry;
        if (require(cjgui_internal_renderer_configure_composable_scene(session, 21, 1) ==
                CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_set_composable_scene_geometry(session, 21, 0, &reusedGeometry) ==
                CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_stage_window_background(session, 21, 0, 1) ==
                CJGUI_INTERNAL_RENDERER_OK,
                "stage_sparse_same_node_projection")) return 45;
        CjguiInternalRendererFrameObservation reusedFrame = {0};
        if (require(cjgui_internal_renderer_present_composable_scene(session, &reusedFrame) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 21 &&
                ctx.composableNodes[0].node.projectionVersion == 20,
                "accept_sparse_scene_preserves_node_pod_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 101.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "sparse_scene_pointer_begin")) return 46;
        BOOL sparseAcceptedEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) continue;
            sparseAcceptedEvent = event.projectionVersion == 21 && event.bindingEpoch != 0;
            break;
        }
        if (require(sparseAcceptedEvent, "sparse_reuse_pointer_uses_accepted_input_version")) return 47;
        [overlay cancelPointerCapture];
        // The actual Cangjie active-input handoff sends an empty staged value
        // and preservesActiveLocalText=1. A translated clip cannot accept new
        // geometry before its newly visible tile is prepared from the native
        // draft, even though the owner and node identity are unchanged.
        if (require(submitLongText(session, 22, -258.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK,
                "preserve_long_text_baseline") ||
            require(cjgui_internal_renderer_focus_composable_node(session, 990) ==
                CJGUI_INTERNAL_RENDERER_OK, "preserve_long_text_focus")) return 48;
        uint64_t preserveAcceptedVersion = ctx.composableSceneVersion;
        id<MTLTexture> preserveAcceptedTile = ctx.composableNodes[0].textTileTextures.firstObject;
        NSString *preserveDraft = [overlay.inputProxy.string copy];
        NSRange preserveSelection = overlay.inputProxy.selectedRange;
        if (require(preserveDraft.length > 0 && preserveAcceptedTile != nil,
                "preserve_baseline_has_native_draft_and_tile") ||
            require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "preserve_arm_tile_failure") ||
            require(submitLongTextWithTransport(session, 23, -514.25, 0.5, YES) !=
                CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == preserveAcceptedVersion &&
                ctx.composableNodes[0].textTileTextures.firstObject == preserveAcceptedTile &&
                [overlay.inputProxy.string isEqualToString:preserveDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, preserveSelection),
                "preserve_missing_tile_rejects_before_acceptance") ||
            require(submitLongTextWithTransport(session, 23, -514.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 23 &&
                [overlay.inputProxy.string isEqualToString:preserveDraft],
            "preserve_retry_accepts_from_same_draft")) return 49;
        uint64_t coveredRaster = ctx.view.testComposableTextRasterCount;
        if (require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "arm_covered_motion_failure") ||
            require(submitLongTextWithTransport(session, 24, -514.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 24 &&
                ctx.view.testComposableTextRasterCount == coveredRaster &&
                ctx.forcedComposableTextPreparationFailures == 1,
                "covered_motion_reuses_tile_without_consuming_failure") ||
            require(submitLongTextWithTransport(session, 25, -770.25, 0.5, YES) !=
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 24,
                "next_uncovered_cell_still_requires_admission") ||
            require(submitLongTextWithTransport(session, 25, -770.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 25,
            "next_uncovered_cell_retries")) return 50;
        // A focused single-line input must obey the same acceptance fence.
        // The initial node-local tile covers 0..512, while the unchanged
        // native draft needs 600..700 after the parent-relative visual move.
        if (require(submitClippedSingleLineWithTransport(session, 26, 0.0, NO) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_baseline") ||
            require(cjgui_internal_renderer_focus_composable_node(session, 991) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_focus")) return 55;
        uint64_t singleAcceptedVersion = ctx.composableSceneVersion;
        id<MTLTexture> singleAcceptedTexture = ctx.composableNodes[0].textTexture;
        NSRect singleAcceptedRect = ctx.composableNodes[0].textTextureRect;
        NSString *singleDraft = [overlay.inputProxy.string copy];
        overlay.inputProxy.selectedRange = NSMakeRange(4, 2);
        NSRange singleSelection = overlay.inputProxy.selectedRange;
        if (require(singleAcceptedTexture != nil && NSMaxX(singleAcceptedRect) < 600.0 &&
                singleDraft.length >= 100 && singleSelection.length == 2,
                "single_line_local_coverage_baseline") ||
            require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_arm_uncovered_failure") ||
            require(submitClippedSingleLineWithTransport(session, 27, -600.0, YES) !=
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == singleAcceptedVersion &&
                ctx.composableNodes[0].textTexture == singleAcceptedTexture &&
                [overlay.inputProxy.string isEqualToString:singleDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, singleSelection),
                "single_line_missing_tile_rejects_before_acceptance") ||
            require(submitClippedSingleLineWithTransport(session, 27, -600.0, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 27 &&
                NSMinX(ctx.composableNodes[0].textTextureRect) <= 600.0 &&
                NSMaxX(ctx.composableNodes[0].textTextureRect) >= 700.0 &&
                [overlay.inputProxy.string isEqualToString:singleDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, singleSelection),
                "single_line_retry_admits_draft_coverage")) return 56;
        uint64_t singleCoveredRaster = ctx.view.testComposableTextRasterCount;
        if (require(submitClippedSingleLineWithTransport(session, 28, -600.25, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.view.testComposableTextRasterCount == singleCoveredRaster,
                "single_line_covered_subpoint_reuses_tile")) return 57;
        uint64_t finalFrame = ctx.view.frameIndex;
        NSNumber *finalKey = @(finalFrame);
        CjguiTextSubmissionCompletion *finalFence = ctx.submittedTextCompletionFlags[finalKey];
        for (NSUInteger retry = 0; retry < 1000 && !finalFence.resourcesReleased; retry++)
            usleep(1000);
        if (require(finalFence && finalFence.resourcesReleased &&
            ctx.submittedTextTextures[finalKey] != nil,
            "actual_gpu_completion_precedes_main_queue_text_retirement")) return 53;
        (void)CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(ctx.submittedTextTextures[finalKey] == nil &&
            ctx.submittedTextCompletionFlags[finalKey] == nil,
            "next_owner_admission_prunes_completed_gpu_generation")) return 54;
        printf("F11_TRANSLATION_NATIVE_PASS rect=1.5,0.75 hit=1.49:no/1.5:101 "
               "clip=60.25 precise_fifo=1.5,1.0@scene1 reject_keeps_scene=1 recovery_scene=3 "
               "scale2_edge_green=%u,%u scale1_edge_green=%u,%u text_rasters=%llu caret_x=%.3f->%.3f "
               "backdrop_red=%u->%u redraw=%llu->%llu hot_hit=%llu\n",
               outsideGreen, insideGreen, outsideOneXGreen, insideOneXGreen,
               (unsigned long long)textRasterBefore, caretX, movedCaretX,
               oldBackdrop[2], movedBackdrop[2],
               (unsigned long long)oldStats.backdropPrefixPasses,
               (unsigned long long)movedStats.backdropPrefixPasses,
               (unsigned long long)stableStats.backdropCacheHits);
        if (require(cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
            "destroy")) return 10;
        return 0;
    }
}
