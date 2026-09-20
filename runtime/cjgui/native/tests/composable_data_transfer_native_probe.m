#import <AppKit/AppKit.h>

#import "../cjgui_internal_renderer.h"

// This probe is deliberately below the Cangjie business boundary.  It proves
// that the macOS adapter copies only bounded, declared values into the normal
// renderer FIFO; a Cangjie controller must still validate the accepted scene
// target and invoke its existing owner operation.

static int require(BOOL condition, const char *label) {
    if (condition) return 0;
    fprintf(stderr, "CJGUI_DATA_TRANSFER_NATIVE_PROBE failed=%s\n", label);
    return 1;
}

static CjguiInternalRendererComposableNode scene_node(uint64_t node_id, int64_t resource_id) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = node_id;
    node.projectionVersion = 1;
    node.resourceId = resource_id;
    node.x = node_id == 101 ? 12 : 164;
    node.y = 12;
    node.width = 136;
    node.height = 48;
    node.clipX = 0;
    node.clipY = 0;
    node.clipWidth = 320;
    node.clipHeight = 160;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    node.isInteractive = 1;
    node.fillAlpha = 1.0;
    node.textAlpha = 1.0;
    return node;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {
            .windowWidth = 320,
            .windowHeight = 160,
            .clearColorRed = 0.06,
            .clearColorGreen = 0.08,
            .clearColorBlue = 0.12,
            .clearColorAlpha = 1.0,
        };
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                    "create")) return 1;

        int result = 1;
        NSWindow *firstWindow = nil;
        NSWindow *secondWindow = nil;
        uint64_t secondSession = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        // Two regular application windows with this small configuration fit
        // side by side on the active screen. Keeping their visible frames
        // disjoint is a normal multi-window usability invariant and removes
        // an accidental source-over-target obstruction from desktop drag
        // routing; it is not a drag-delivery assertion.
        firstWindow = NSApp.windows.lastObject;
        if (require(firstWindow != nil, "first_window")) goto cleanup;
        status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        secondSession = cjgui_internal_renderer_create(&config, &status);
        secondWindow = NSApp.windows.lastObject;
        if (require(status == CJGUI_INTERNAL_RENDERER_OK &&
                    secondSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION && secondWindow != nil &&
                    secondWindow != firstWindow,
                    "second_window") ||
            require(!NSIntersectsRect(firstWindow.frame, secondWindow.frame), "disjoint_window_frames")) goto cleanup;

        CjguiInternalRendererFrameObservation frame = {0};
        CjguiInternalRendererComposableDataTransferItem source = {
            .nodeId = 101,
            .projectionVersion = 1,
            .resourceId = 7001,
            .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
            .role = CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_SOURCE,
            .maximumPayloadBytes = 64,
            .sourceId = 9001,
        };
        CjguiInternalRendererComposableDataTransferItem target = {
            .nodeId = 202,
            .projectionVersion = 1,
            .resourceId = 7002,
            .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
            .role = CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_TARGET,
            .maximumPayloadBytes = 64,
            .sourceId = -1,
        };
        CjguiInternalRendererComposableNode source_node = scene_node(101, 7001);
        CjguiInternalRendererComposableNode target_node = scene_node(202, 7002);

        if (require(cjgui_internal_renderer_configure_composable_scene(session, 1, 2) == CJGUI_INTERNAL_RENDERER_OK,
                    "configure_scene") ||
            require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &source_node,
                    "transfer-source", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "set_source_node") ||
            require(cjgui_internal_renderer_set_composable_scene_node(session, 1, &target_node,
                    "transfer-target", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "set_target_node") ||
            require(cjgui_internal_renderer_configure_composable_data_transfer(session, 1, 2) ==
                    CJGUI_INTERNAL_RENDERER_OK, "configure_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(session, 0, &source,
                    "application/vnd.cjgui.native.transfer", "copy payload", "probe_source", "probe-window") == CJGUI_INTERNAL_RENDERER_OK, "set_source_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(session, 1, &target,
                    "application/vnd.cjgui.native.transfer", "", "", "") == CJGUI_INTERNAL_RENDERER_OK, "set_target_transfer") ||
            require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                    "present")) goto cleanup;

        CjguiInternalRendererEvent event = {0};
        if (require(cjgui_internal_renderer_test_composable_data_transfer_copy(session, 101) ==
                    CJGUI_INTERNAL_RENDERER_OK, "explicit_copy") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_COPY &&
                    event.nodeId == 101 && event.resourceId == 7001, "copy_event") ||
            require(strcmp(cjgui_internal_renderer_data_transfer_event_format(session),
                    "application/vnd.cjgui.native.transfer") == 0,
                    "copy_format") ||
            require(strcmp(cjgui_internal_renderer_data_transfer_event_source_kind(session), "probe_source") == 0 &&
                    strcmp(cjgui_internal_renderer_data_transfer_event_source_identity(session), "probe-window") == 0 &&
                    cjgui_internal_renderer_data_transfer_event_source_id(session) == 9001, "copy_source") ||
            require(strcmp(cjgui_internal_renderer_form_event_text(session), "copy payload") == 0, "copy_payload")) goto cleanup;

        if (require(cjgui_internal_renderer_test_composable_data_transfer_paste(session, 202,
                    "external payload") == CJGUI_INTERNAL_RENDERER_OK, "external_paste") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE &&
                    event.nodeId == 202 && event.resourceId == 7002, "paste_event") ||
            require(strcmp(cjgui_internal_renderer_data_transfer_event_format(session),
                    "application/vnd.cjgui.native.transfer") == 0,
                    "paste_format") ||
            require(strcmp(cjgui_internal_renderer_form_event_text(session), "external payload") == 0,
                    "paste_payload")) goto cleanup;

        // This is deliberately a controlled target-callback proof rather
        // than a claim about cross-window system drag delivery. The helper
        // enters the production destination, prepares, then performs a drop
        // using a bounded test pasteboard; its observable boundary is the
        // same native FIFO consumed by Cangjie windows.
        if (require(cjgui_internal_renderer_test_composable_data_transfer_drop(session, 202,
                    "controlled drop") == CJGUI_INTERNAL_RENDERER_OK, "controlled_drop") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_ENTER &&
                    event.nodeId == 202 && event.resourceId == 7002, "controlled_drop_hover_enter") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_DROP &&
                    event.nodeId == 202 && event.resourceId == 7002, "controlled_drop_event") ||
            require(strcmp(cjgui_internal_renderer_data_transfer_event_format(session),
                    "application/vnd.cjgui.native.transfer") == 0 &&
                    strcmp(cjgui_internal_renderer_form_event_text(session), "controlled drop") == 0,
                    "controlled_drop_payload") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_LEAVE &&
                    event.nodeId == 202 && event.resourceId == 7002, "controlled_drop_hover_leave")) goto cleanup;

        // A cancelled platform drag may clear visual hover, but must not queue
        // a DROP/PASTE owner intent. The test bridge invokes production
        // draggingExited after a declared target is entered, so both hover
        // edges must be observable and the following pump must be empty.
        if (require(cjgui_internal_renderer_test_composable_data_transfer_cancel(session) == CJGUI_INTERNAL_RENDERER_OK,
                    "cancel") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_ENTER &&
                    event.nodeId == 202 && event.resourceId == 7002, "cancel_hover_enter") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_LEAVE &&
                    event.nodeId == 202 && event.resourceId == 7002, "cancel_hover_leave") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE, "cancel_no_transfer")) goto cleanup;

        if (require(cjgui_internal_renderer_test_composable_data_transfer_paste(session, 202,
                    "this payload is intentionally longer than the declared 64 byte capacity to ensure the native adapter rejects it") ==
                    CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED, "oversized_rejected")) goto cleanup;

        // Rebinding the accepted scene while a target is hovered must retire
        // that target immediately. The old node cannot receive a later paste
        // or drop, and its preview receives the paired leave once.
        if (require(cjgui_internal_renderer_test_composable_data_transfer_hover_target(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "rebind_hover") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_HOVER_ENTER &&
                    event.nodeId == 202 && event.resourceId == 7002, "rebind_hover_enter")) goto cleanup;
        if (require(cjgui_internal_renderer_test_composable_data_transfer_hover_target(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "repeated_hover") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE, "repeated_hover_not_queued")) goto cleanup;
        CjguiInternalRendererComposableNode rebound_source_node = scene_node(101, 7001);
        rebound_source_node.projectionVersion = 2;
        CjguiInternalRendererComposableDataTransferItem rebound_source = source;
        rebound_source.projectionVersion = 2;
        if (require(cjgui_internal_renderer_configure_composable_scene(session, 2, 1) == CJGUI_INTERNAL_RENDERER_OK,
                    "rebind_configure_scene") ||
            require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &rebound_source_node,
                    "transfer-source", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "rebind_source_node") ||
            require(cjgui_internal_renderer_configure_composable_data_transfer(session, 2, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "rebind_configure_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(session, 0, &rebound_source,
                    "application/vnd.cjgui.native.transfer", "copy payload", "probe_source", "probe-window") ==
                    CJGUI_INTERNAL_RENDERER_OK, "rebind_source_transfer") ||
            require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                    "rebind_present") ||
            require(cjgui_internal_renderer_test_composable_data_transfer_hover_cleared(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "rebind_hover_cleared") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE, "rebind_no_stale_event") ||
            require(cjgui_internal_renderer_test_composable_data_transfer_paste(session, 202, "late target") ==
                    CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED, "rebind_old_target_rejected")) goto cleanup;

        // This must drive the production overlay's mouseDragged branch rather
        // than the older test-mouse helper, whose phase-2 path only cancels a
        // press.  A source-origin drag has no owner mutation at this layer,
        // but it must hit the source, cross the threshold and create an
        // AppKit dragging session before any target callback can occur.
        uint32_t dragTrace = 0;
        CjguiInternalRendererStatus dragStatus =
            cjgui_internal_renderer_test_trace_composable_data_transfer_drag(
                session, 48.0f, 36.0f, 56.0f, 36.0f, &dragTrace);
        if (dragStatus != CJGUI_INTERNAL_RENDERER_OK) {
            fprintf(stderr, "CJGUI_DATA_TRANSFER_NATIVE_PROBE drag_status=%d trace=%u\n", dragStatus, dragTrace);
        }
        if (require(dragStatus == CJGUI_INTERNAL_RENDERER_OK, "system_drag_source") ||
            require((dragTrace & 15u) == 15u, "system_drag_trace")) goto cleanup;

        result = 0;
        fprintf(stdout, "CJGUI_DATA_TRANSFER_NATIVE_PROBE copy_paste_controlled_drop_bounded_cancel passed=1\n");

    cleanup:
        if (secondSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            (void)cjgui_internal_renderer_destroy(secondSession);
        }
        (void)cjgui_internal_renderer_destroy(session);
        return result;
    }
}
