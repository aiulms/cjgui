#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#include <sys/stat.h>

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

static BOOL wait_transfer_event(uint64_t session, uint32_t expectedKind,
                                uint64_t expectedId, CjguiInternalRendererEvent *out) {
    for (NSUInteger spin = 0; spin < 120; spin++) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        CjguiInternalRendererEvent event = {0};
        if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) return NO;
        if (event.kind == expectedKind && (expectedId == 0 || event.dataTransferEventId == expectedId)) {
            if (out) *out = event;
            return YES;
        }
    }
    return NO;
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
        if (require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,
                    "create")) return 1;

        int result = 1;
        NSWindow *firstWindow = nil;
        NSWindow *secondWindow = nil;
        NSString *filePath = nil;
        NSString *oversizedPath = nil;
        NSString *fifoPath = nil;
        NSString *replacementPath = nil;
        NSMutableData *oversized = nil;
        uint64_t secondSession = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
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
                    secondSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN && secondWindow != nil &&
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
            require(cjgui_internal_renderer_stage_window_background(session, 1, 0, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "stage_window_background") ||
            require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                    "present")) goto cleanup;

        // A layout/encoding duration is not a native submission timeline.
        // This RED check requires an exact frame and monotonic present/commit
        // boundary, then a separately reported Metal completion callback.
        CjguiInternalRendererSubmissionTimeline submission = {0};
        if (require(cjgui_internal_renderer_test_submission_timeline(session, frame.frameIndex,
                    &submission) == CJGUI_INTERNAL_RENDERER_OK, "submission_timeline") ||
            require(submission.frameIndex == frame.frameIndex && submission.sceneVersion == 1 &&
                    submission.stageBeginMicros > 0 &&
                    submission.stageBeginMicros <= submission.encodeEndMicros &&
                    submission.encodeEndMicros <= submission.presentCallMicros &&
                    submission.presentCallMicros <= submission.commitCallBeginMicros &&
                    submission.commitCallBeginMicros <= submission.commitCallMicros,
                    "submission_phase_order")) goto cleanup;
        for (NSUInteger spin = 0; spin < 120 && submission.completedMicros == 0; spin++) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            if (require(cjgui_internal_renderer_test_submission_timeline(session, frame.frameIndex,
                        &submission) == CJGUI_INTERNAL_RENDERER_OK, "completion_timeline")) goto cleanup;
        }
        if (require(submission.scheduledMicros >= submission.commitCallMicros &&
                    submission.completedMicros >= submission.scheduledMicros &&
                    submission.completionStatus == MTLCommandBufferStatusCompleted,
                    "submission_completed_order")) goto cleanup;

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
            require(cjgui_internal_renderer_stage_window_background(session, 2, 0, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "rebind_stage_window_background") ||
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
        // The AppKit source gesture owns the desktop pointer until mouse-up.
        // File-adapter runs may isolate it from a stale OS drag session while
        // retaining the ordinary source-drag check in the default probe.
        if (!getenv("CJGUI_DATA_TRANSFER_SKIP_SOURCE_DRAG")) {
            uint32_t dragTrace = 0;
            CjguiInternalRendererStatus dragStatus =
                cjgui_internal_renderer_test_trace_composable_data_transfer_drag(
                    session, 48.0f, 36.0f, 56.0f, 36.0f, &dragTrace);
            if (dragStatus != CJGUI_INTERNAL_RENDERER_OK) {
                fprintf(stderr, "CJGUI_DATA_TRANSFER_NATIVE_PROBE drag_status=%d trace=%u\n", dragStatus, dragTrace);
            }
            if (require(dragStatus == CJGUI_INTERNAL_RENDERER_OK, "system_drag_source") ||
                require((dragTrace & 15u) == 15u, "system_drag_trace")) goto cleanup;
        }

        // A Finder-style URL reaches the same accepted PNG target and yields
        // immutable bytes under one identity after an asynchronous BEGIN.
        CjguiInternalRendererComposableNode pngNode = scene_node(202, 7002);
        pngNode.projectionVersion = 3;
        CjguiInternalRendererComposableDataTransferItem pngTarget = target;
        pngTarget.projectionVersion = 3;
        pngTarget.maximumPayloadBytes = 512u * 1024u;
        pngTarget.bindingEpoch = 123;
        pngTarget.localPngFileAllowed = 1;
        pngTarget.expectedOwnerVersion = 7;
        if (require(cjgui_internal_renderer_configure_composable_scene(session, 3, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "file_scene") ||
            require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &pngNode,
                    "png-file-target", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "file_node") ||
            require(cjgui_internal_renderer_configure_composable_data_transfer(session, 3, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "file_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(session, 0, &pngTarget,
                    "image/png", "", "", "") == CJGUI_INTERNAL_RENDERER_OK, "file_declaration") ||
            require(cjgui_internal_renderer_stage_window_background(session, 3, 0, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "file_background")) goto cleanup;
        CjguiInternalRendererStatus filePresentStatus =
            cjgui_internal_renderer_present_composable_scene(session, &frame);
        if (filePresentStatus != CJGUI_INTERNAL_RENDERER_OK)
            fprintf(stderr, "CJGUI_DATA_TRANSFER_NATIVE_PROBE file_present_status=%d\n", filePresentStatus);
        if (require(filePresentStatus == CJGUI_INTERNAL_RENDERER_OK, "file_present")) goto cleanup;
        filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CJGUI 文件 PNG test.png"];
        // The preceding source gesture can leave a press/hover edge in the
        // same FIFO; drain it before attributing this new file operation.
        for (NSUInteger drain = 0; drain < 64; drain++) {
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
        }
        if (require(cjgui_internal_renderer_test_write_solid_image_fixture(filePath.UTF8String,
                    25, 100, 180, 255) == CJGUI_INTERNAL_RENDERER_OK, "file_fixture") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "file_paste_begin") ||
            require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN &&
                    event.nodeId == 202 && event.dataTransferEventId > 0 &&
                    event.recordIndex == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE,
                    "file_begin_identity")) goto cleanup;
        uint64_t fileEventId = event.dataTransferEventId;
        const uint64_t firstFileDelivery =
            cjgui_internal_renderer_data_transfer_event_delivery_ordinal(session);
        if (require(firstFileDelivery > 0, "file_delivery_ordinal")) goto cleanup;
        BOOL fileCompleted = NO;
        for (NSUInteger spin = 0; spin < 120 && !fileCompleted; spin++) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE &&
                event.dataTransferEventId == fileEventId) fileCompleted = YES;
        }
        if (require(fileCompleted, "file_paste_completed") ||
            require(cjgui_internal_renderer_data_transfer_event_delivery_ordinal(session) ==
                    firstFileDelivery, "file_completion_same_delivery_ordinal") ||
            require(event.bindingEpoch == 123 &&
                    cjgui_internal_renderer_data_transfer_event_expected_owner_version(session) == 7,
                    "file_capture_owner_identity") ||
            require(cjgui_internal_renderer_data_transfer_event_binary_size(session, fileEventId) > 0,
                    "file_png_bytes")) goto cleanup;

        // A named pipe has no writer. Its open must not occupy the shared
        // reader queue and prevent a different window from accepting a real
        // local PNG. This is a production file URL, not a fake reader result.
        fifoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CJGUI blocked named pipe.png"];
        (void)unlink(fifoPath.fileSystemRepresentation);
        if (require(mkfifo(fifoPath.fileSystemRepresentation, 0600) == 0, "fifo_fixture")) goto cleanup;
        CjguiInternalRendererComposableNode otherNode = pngNode;
        CjguiInternalRendererComposableDataTransferItem otherTarget = pngTarget;
        if (require(cjgui_internal_renderer_configure_composable_scene(secondSession, 3, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "other_file_scene") ||
            require(cjgui_internal_renderer_set_composable_scene_node(secondSession, 0, &otherNode,
                    "other-png-target", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                    "other_file_node") ||
            require(cjgui_internal_renderer_configure_composable_data_transfer(secondSession, 3, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "other_file_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(secondSession, 0,
                    &otherTarget, "image/png", "", "", "") == CJGUI_INTERNAL_RENDERER_OK,
                    "other_file_declaration") ||
            require(cjgui_internal_renderer_stage_window_background(secondSession, 3, 0, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "other_file_background") ||
            require(cjgui_internal_renderer_present_composable_scene(secondSession, &frame) ==
                    CJGUI_INTERNAL_RENDERER_OK, "other_file_present") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    fifoPath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "fifo_capture") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "fifo_begin")) goto cleanup;
        const uint64_t fifoId = event.dataTransferEventId;
        if (require(cjgui_internal_renderer_test_composable_file_transfer(secondSession, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "other_file_capture") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "other_file_begin")) goto cleanup;
        const uint64_t otherFileId = event.dataTransferEventId;
        if (require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED,
                    fifoId, &event) &&
                    strcmp(cjgui_internal_renderer_form_event_text(session), "file_not_regular") == 0,
                    "fifo_named_rejection") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE,
                    otherFileId, &event), "other_window_after_fifo")) goto cleanup;
        (void)unlink(fifoPath.fileSystemRepresentation);
        fifoPath = nil;
        if (require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 3) == CJGUI_INTERNAL_RENDERER_OK, "file_mixed_capture") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event) &&
                    strcmp(cjgui_internal_renderer_data_transfer_event_source_kind(session),
                           "local_file_url") == 0,
                    "file_mixed_prefers_url")) goto cleanup;
        const uint64_t mixedFileId = event.dataTransferEventId;
        if (require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE,
                    mixedFileId, &event) &&
                    strcmp(cjgui_internal_renderer_data_transfer_event_source_kind(session),
                           "local_file_url") == 0,
                    "file_mixed_single_completion")) goto cleanup;
        if (require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                    event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE,
                    "file_mixed_no_second_accept")) goto cleanup;
        if (require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 1) == CJGUI_INTERNAL_RENDERER_OK, "file_drop_begin") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "file_drop_begin_event")) goto cleanup;
        fileEventId = event.dataTransferEventId;
        if (require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_DROP, fileEventId, &event),
                    "file_drop_completed") ||
            require(event.bindingEpoch == 123 &&
                    cjgui_internal_renderer_data_transfer_event_expected_owner_version(session) == 7,
                    "file_drop_capture_identity")) goto cleanup;
        if (require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 2) == CJGUI_INTERNAL_RENDERER_OK, "file_multi_capture") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED, 0, &event) &&
                    strcmp(cjgui_internal_renderer_form_event_text(session),
                           "file_multiple_items_unsupported") == 0,
                    "file_multi_rejected")) goto cleanup;
        oversizedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CJGUI large.png"];
        oversized = [NSMutableData dataWithLength:512u * 1024u + 1u];
        if (require([oversized writeToFile:oversizedPath atomically:YES], "file_oversize_fixture") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    oversizedPath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "file_oversize_begin") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "file_oversize_begin_event")) goto cleanup;
        fileEventId = event.dataTransferEventId;
        if (require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED,
                    fileEventId, &event) &&
                    strcmp(cjgui_internal_renderer_form_event_text(session),
                           "file_payload_too_large") == 0,
                    "file_oversize_rejected")) goto cleanup;

        // The reader is held before opening. Rebinding can accept a new
        // target while the captured operation still keeps its old epoch and
        // owner CAS baseline; the Cangjie consumer must cancel that terminal.
        if (require(cjgui_internal_renderer_test_hold_next_file_read(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "hold_reader") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "held_capture") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN,
                    0, &event), "held_begin")) goto cleanup;
        const uint64_t heldId = event.dataTransferEventId;
        if (require(cjgui_internal_renderer_test_wait_file_read_entered(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_worker_entered")) goto cleanup;
        CjguiInternalRendererComposableNode reboundPngNode = pngNode;
        reboundPngNode.projectionVersion = 4;
        CjguiInternalRendererComposableDataTransferItem reboundPngTarget = pngTarget;
        reboundPngTarget.projectionVersion = 4;
        reboundPngTarget.bindingEpoch = 124;
        reboundPngTarget.expectedOwnerVersion = 8;
        if (require(cjgui_internal_renderer_configure_composable_scene(session, 4, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_rebind_scene") ||
            require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &reboundPngNode,
                    "png-file-target", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "held_rebind_node") ||
            require(cjgui_internal_renderer_configure_composable_data_transfer(session, 4, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_rebind_transfer") ||
            require(cjgui_internal_renderer_set_composable_data_transfer_item(session, 0,
                    &reboundPngTarget, "image/png", "", "", "") ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_rebind_item") ||
            require(cjgui_internal_renderer_stage_window_background(session, 4, 0, 1) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_rebind_background") ||
            require(cjgui_internal_renderer_present_composable_scene(session, &frame) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_rebind_present") ||
            require(cjgui_internal_renderer_test_release_file_read(session) ==
                    CJGUI_INTERNAL_RENDERER_OK, "held_reader_release") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE,
                    heldId, &event), "held_terminal") ||
            require(event.bindingEpoch == 123 &&
                    cjgui_internal_renderer_data_transfer_event_expected_owner_version(session) == 7,
                    "held_terminal_keeps_capture")) goto cleanup;

        // Pause after the first real read. A mutation of the opened inode or
        // the captured pathname must reject the immutable byte offer before
        // it can reach an owner; the worker closes its fd on every exit.
        if (require(cjgui_internal_renderer_test_hold_next_file_after_first_read(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "truncate_hold") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(secondSession, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "truncate_capture") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "truncate_begin")) goto cleanup;
        const uint64_t truncateId = event.dataTransferEventId;
        if (require(cjgui_internal_renderer_test_wait_file_read_entered(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "truncate_first_read") ||
            require(truncate(filePath.fileSystemRepresentation, 0) == 0, "truncate_during_read") ||
            require(cjgui_internal_renderer_test_release_file_read(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "truncate_release") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED,
                    truncateId, &event) &&
                    strcmp(cjgui_internal_renderer_form_event_text(secondSession),
                           "file_changed_during_read") == 0, "truncate_rejected") ||
            require(cjgui_internal_renderer_test_write_solid_image_fixture(filePath.UTF8String,
                    25, 100, 180, 255) == CJGUI_INTERNAL_RENDERER_OK,
                    "restore_after_truncate")) goto cleanup;

        if (require(cjgui_internal_renderer_test_hold_next_file_after_first_read(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "replace_hold") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(secondSession, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "replace_capture") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "replace_begin")) goto cleanup;
        const uint64_t replaceId = event.dataTransferEventId;
        replacementPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CJGUI replacement image.png"];
        if (require(cjgui_internal_renderer_test_wait_file_read_entered(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "replace_first_read") ||
            require(cjgui_internal_renderer_test_write_solid_image_fixture(replacementPath.UTF8String,
                    190, 50, 30, 255) == CJGUI_INTERNAL_RENDERER_OK, "replacement_fixture") ||
            require(rename(replacementPath.fileSystemRepresentation, filePath.fileSystemRepresentation) == 0,
                    "replace_during_read") ||
            require(cjgui_internal_renderer_test_release_file_read(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "replace_release") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_REJECTED,
                    replaceId, &event) &&
                    strcmp(cjgui_internal_renderer_form_event_text(secondSession),
                           "file_changed_during_read") == 0, "replace_rejected")) goto cleanup;

        if (require(cjgui_internal_renderer_test_hold_next_file_after_first_read(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "close_hold") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(secondSession, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "close_capture") ||
            require(wait_transfer_event(secondSession,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "close_begin") ||
            require(cjgui_internal_renderer_test_wait_file_read_entered(secondSession) ==
                    CJGUI_INTERNAL_RENDERER_OK, "close_first_read") ||
            require(cjgui_internal_renderer_destroy(secondSession) == CJGUI_INTERNAL_RENDERER_OK,
                    "close_during_read")) goto cleanup;
        secondSession = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
        uint32_t openDescriptors = UINT32_MAX, acquiredScopes = UINT32_MAX;
        for (NSUInteger spin = 0; spin < 120; spin++) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            if (cjgui_internal_renderer_test_file_read_resources(&openDescriptors, &acquiredScopes) ==
                    CJGUI_INTERNAL_RENDERER_OK && openDescriptors == 0 && acquiredScopes == 0) break;
        }
        if (require(openDescriptors == 0 && acquiredScopes == 0, "closed_read_resources_released") ||
            require(cjgui_internal_renderer_test_composable_file_transfer(session, 202,
                    filePath.UTF8String, 0) == CJGUI_INTERNAL_RENDERER_OK, "other_after_close_capture") ||
            require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FILE_TRANSFER_BEGIN, 0, &event),
                    "other_after_close_begin")) goto cleanup;
        const uint64_t afterCloseId = event.dataTransferEventId;
        if (require(wait_transfer_event(session,
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DATA_TRANSFER_PASTE,
                    afterCloseId, &event), "other_after_close_accepted")) goto cleanup;
        [[NSFileManager defaultManager] removeItemAtPath:oversizedPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

        result = 0;
        fprintf(stdout, "CJGUI_DATA_TRANSFER_NATIVE_PROBE copy_paste_controlled_drop_bounded_cancel passed=1\n");

    cleanup:
        if (fifoPath) (void)unlink(fifoPath.fileSystemRepresentation);
        if (replacementPath) (void)unlink(replacementPath.fileSystemRepresentation);
        if (secondSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            (void)cjgui_internal_renderer_destroy(secondSession);
        }
        (void)cjgui_internal_renderer_destroy(session);
        return result;
    }
}
