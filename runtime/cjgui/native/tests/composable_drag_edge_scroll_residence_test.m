// 越界拖选的持续滚动（驻留）。
//
// 现状：edge-scroll 只在 `mouseDragged:` / `updatePointerCaptureAtPoint:` 里被调用，也就是**只有
// 拖动事件到达时才滚动**。指针停在带外不动 ⇒ 没有事件 ⇒ 不再滚动，直到松开或再次移动才跳一下
// ——用户视频里的"越界拖选不持续滚动，松开后才跳动"。
//
// 本夹具只用真实 session/overlay/指针捕获路径（不显示窗口、不合成系统输入）回答三件事：
//   1. 事件驱动的那一次滚动仍然发生（既有能力未丢）；
//   2. 指针静止在带外时，按时间推进的每一次 tick 都继续走**同一条**滚动通道；
//   3. 松开、取消或指针回到带内后**停止**，且不为没 tick 过的时间补放积压。
// 时钟由测试显式推进（`testDragEdgeScrollClockActive`），因此不依赖主队列时序。
#define CJGUI_CARET_AFTER_INPUT_FIXTURE 1
#import "composable_installed_range_prefix_test.m"

static NSUInteger DragEdgeScrollCount(CJGuiInternalSession *ctx) {
    NSUInteger count = 0;
    for (CJGuiInternalQueuedInteraction *queued in ctx.pendingInteractions) {
        if (queued.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL) count += 1;
    }
    return count;
}

static NSUInteger DragEdgePointerUpdateCount(CJGuiInternalSession *ctx) {
    NSUInteger count = 0;
    for (CJGuiInternalQueuedInteraction *queued in ctx.pendingInteractions) {
        if (queued.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) count += 1;
    }
    return count;
}

static CJGuiInternalQueuedInteraction *DragEdgeLastScroll(CJGuiInternalSession *ctx) {
    for (CJGuiInternalQueuedInteraction *queued in [ctx.pendingInteractions reverseObjectEnumerator]) {
        if (queued.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL) return queued;
    }
    return nil;
}

static CJGuiInternalComposableSceneNode *DragEdgeScrollFindNode(SourceInstallOverlay *overlay,
    uint64_t nodeId) {
    for (CJGuiInternalComposableSceneNode *node in overlay.nodes) {
        if (node.node.nodeId == nodeId) return node;
    }
    return nil;
}

/// One scroll area (id 900) holding one interactive presentation TEXT node (id 401): the shape the
/// product's source mode presents to pointer capture.
static SourceInstallOverlay *DragEdgeScrollFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay = [[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 500) session:ctx];
    overlay.testWindow = [[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0, 0, 680, 500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window = (NSWindow *)overlay.testWindow;
    ctx.composableSceneOverlay = overlay;
    overlay.inputProxy.delegate = nil;
    SourceInstallProxy *proxy = [[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay = overlay;
    proxy.delegate = overlay;
    proxy.layoutManager.allowsNonContiguousLayout = YES;
    proxy.layoutManager.backgroundLayoutEnabled = NO;
    overlay.inputProxy = proxy;
    overlay.inputScrollProxy.documentView = proxy;
    overlay.testWindow.contentView = overlay;

    NSMutableString *body = [NSMutableString string];
    for (NSUInteger i = 0; i < 200; i++) [body appendString:@"line\n"];

    CJGuiInternalComposableSceneNode *scroll = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode scrollRaw = {0};
    scrollRaw.nodeId = 900;
    scrollRaw.resourceId = 2;
    scrollRaw.projectionVersion = 1;
    scrollRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    scrollRaw.width = 680;
    scrollRaw.height = 500;
    scrollRaw.clipWidth = 680;
    scrollRaw.clipHeight = 500;
    scrollRaw.wheelScrollable = 1;
    scroll.node = scrollRaw;
    scroll.index = 0;
    scroll.value = @"";
    scroll.styleRunsSignature = @"";
    scroll.textTextureCacheKey = @"";

    CJGuiInternalComposableSceneNode *text = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode textRaw = {0};
    textRaw.nodeId = 401;
    textRaw.resourceId = 1;
    textRaw.projectionVersion = 1;
    textRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    textRaw.width = 660;
    textRaw.height = 480;
    textRaw.clipWidth = 680;
    textRaw.clipHeight = 500;
    textRaw.fontSize = 13;
    textRaw.textAlpha = 1;
    textRaw.isInteractive = 1;
    text.node = textRaw;
    text.index = 1;
    text.value = body;
    text.styleRunsSignature = @"";
    text.textTextureCacheKey = @"";

    ctx.stagedComposableNodes = [NSMutableArray arrayWithObjects:scroll, text, nil];
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;

    uint64_t token = CjguiAllocateSession(ctx);
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    [overlay.inputProxy setString:body];
    [overlay.inputProxy setSelectedRange:NSMakeRange(0, 0)];
    [overlay refreshGpuTextForActiveInput];
    return overlay;
}

static void DragEdgeScrollResidenceFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = DragEdgeScrollFixture(device);
    CHECK(overlay != nil, "drag_edge_scroll_fixture");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    CJGuiInternalComposableSceneNode *text = DragEdgeScrollFindNode(overlay, 401);
    CHECK(text != nil, "drag_edge_scroll_text_node_present");
    // The deterministic clock owns the cadence; the real main-queue timer stays out of the way.
    overlay.testDragEdgeScrollClockActive = YES;
    [ctx.pendingInteractions removeAllObjects];

    NSPoint inside = NSMakePoint(300.0, 200.0);
    CHECK([overlay beginPointerCaptureForNode:text atPoint:inside], "drag_edge_scroll_capture_begins");
    // Capture focuses the actual node and installs its font. Measure that
    // accepted text's line height rather than the proxy's pre-focus default.
    CGFloat lineHeight = MAX(1.0,
        [overlay.inputProxy.layoutManager defaultLineHeightForFont:overlay.inputProxy.font]);
    NSPoint belowBand = NSMakePoint(300.0, 500.0 - MIN(lineHeight, 500.0 / 3.0) + 0.1);
    NSUInteger afterBegin = DragEdgeScrollCount(ctx);
    CHECK(afterBegin == 0, "drag_edge_scroll_no_scroll_inside_the_band");

    // 1. The event-driven scroll still happens exactly once for the drag event that leaves the band.
    (void)[overlay updatePointerCaptureAtPoint:belowBand];
    NSUInteger afterEvent = DragEdgeScrollCount(ctx);
    CHECK(afterEvent == 1, "drag_edge_scroll_event_scrolls_once");
    CHECK(overlay.dragEdgeScrollActive, "drag_edge_scroll_residence_armed");
    NSArray<NSString *> *fields = [DragEdgeLastScroll(ctx).formText componentsSeparatedByString:@"|"];
    CGFloat expectedDelta = 0.0;
    CHECK([overlay pointerCaptureEdgeScrollTargetForNode:text atPoint:belowBand
        outScrollIndex:NULL outDelta:&expectedDelta], "drag_edge_scroll_actual_distance_resolves");
    CHECK(fields.count == 6 && [fields[3] isEqualToString:@"1"],
        "drag_edge_scroll_distance_is_precise_logical_points");
    CHECK(fields.count == 6 && fabs(fields[2].doubleValue - expectedDelta) < 1e-12 &&
        expectedDelta < 0.0 && fabs(expectedDelta) < 1.0,
        "drag_edge_scroll_subpixel_distance_and_sign_are_preserved");
    CGFloat farDelta = 0.0;
    CHECK([overlay pointerCaptureEdgeScrollTargetForNode:text atPoint:NSMakePoint(300.0, 900.0)
        outScrollIndex:NULL outDelta:&farDelta] && fabs(farDelta + 3.0 * lineHeight) < 1e-12,
        "drag_edge_scroll_three_row_cap_converts_to_current_line_points");

    // Timer opportunities cannot send another wheel before the previous
    // requested viewport has actually been accepted.
    [overlay advanceDragEdgeScrollAtMicros:1000000ull];
    [overlay advanceDragEdgeScrollAtMicros:2000000ull];
    CHECK(DragEdgeScrollCount(ctx) == afterEvent,
        "timer_waits_for_real_viewport_acceptance");
    CHECK(DragEdgePointerUpdateCount(ctx) == 1,
        "physical_update_is_not_repeated_before_scroll_acceptance");

    // A validated subpixel wheel can leave the real requested and accepted
    // offset equal. It owns no new projection/selection obligation. Its
    // framework ACK reopens the next tick so the same binding can accumulate
    // the fraction; a real directional bound keeps the existing phase-1 stop.
    CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        overlay.pointerCaptureGestureEpoch, 900, 2, 71, 19, 1, 1, 0,
        ctx.composableSceneVersion, 4) == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        overlay.dragEdgeScrollActive && overlay.dragEdgeScrollPhase == 1,
        "drag_edge_scroll_fraction_ack_cannot_skip_real_pending_viewport");
    CjguiInternalRendererStatus fractionAck = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, overlay.pointerCaptureGestureEpoch, 900, 2,
        71, 19, 1, 0, 0, ctx.composableSceneVersion, 4);
    CHECK(fractionAck == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollActive &&
        overlay.dragEdgeScrollPhase == 0,
        "drag_edge_scroll_consumed_subpixel_ack_reopens_residence");
    [overlay advanceDragEdgeScrollAtMicros:3000000ull];
    CHECK(DragEdgeScrollCount(ctx) == afterEvent + 1 && overlay.dragEdgeScrollPhase == 1,
        "drag_edge_scroll_subpixel_remainder_gets_next_real_tick");
    CHECK(DragEdgePointerUpdateCount(ctx) == 1,
        "drag_edge_scroll_no_rehit_for_unmoved_viewport");
    CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        overlay.pointerCaptureGestureEpoch, 900, 2, 71, 19, 1, 0, 0,
        ctx.composableSceneVersion, 1) == CJGUI_INTERNAL_RENDERER_OK &&
        !overlay.dragEdgeScrollActive, "drag_edge_scroll_real_bound_ack_stops_residence");

    // 3. Release stops it, and no backlog is replayed for time that was never ticked.
    [overlay endPointerCaptureAtPoint:belowBand cancelled:NO];
    CHECK(!overlay.dragEdgeScrollActive, "drag_edge_scroll_release_disarms");
    CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        overlay.pointerCaptureGestureEpoch, 900, 2, 71, 19, 1, 0, 0,
        ctx.composableSceneVersion, 4) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "drag_edge_scroll_late_fraction_ack_after_up_is_refused");
    [ctx.pendingInteractions removeAllObjects];
    [overlay advanceDragEdgeScrollAtMicros:4000000ull];
    [overlay advanceDragEdgeScrollAtMicros:5000000ull];
    CHECK(DragEdgeScrollCount(ctx) == 0 && DragEdgePointerUpdateCount(ctx) == 0,
        "drag_edge_scroll_release_leaves_no_backlog");

    // 4. Coming back inside the band also stops the residence (no scroll while the pointer is in view).
    CHECK([overlay beginPointerCaptureForNode:text atPoint:inside], "drag_edge_scroll_recapture_begins");
    [ctx.pendingInteractions removeAllObjects];
    (void)[overlay updatePointerCaptureAtPoint:belowBand];
    CHECK(DragEdgeScrollCount(ctx) == 1, "drag_edge_scroll_second_gesture_event_scrolls");
    (void)[overlay updatePointerCaptureAtPoint:inside];
    CHECK(!overlay.dragEdgeScrollActive, "drag_edge_scroll_return_inside_disarms");
    [ctx.pendingInteractions removeAllObjects];
    [overlay advanceDragEdgeScrollAtMicros:6000000ull];
    CHECK(DragEdgeScrollCount(ctx) == 0, "drag_edge_scroll_inside_the_band_never_ticks");

    // 5. Cancel is a stop as well (platform loss / explicit cancel share this path).
    (void)[overlay updatePointerCaptureAtPoint:belowBand];
    CHECK(overlay.dragEdgeScrollActive, "drag_edge_scroll_third_gesture_arms");
    [overlay cancelPointerCaptureForPlatformLoss];
    CHECK(!overlay.dragEdgeScrollActive, "drag_edge_scroll_platform_loss_disarms");
    [ctx.pendingInteractions removeAllObjects];
    [overlay advanceDragEdgeScrollAtMicros:7000000ull];
    CHECK(DragEdgeScrollCount(ctx) == 0, "drag_edge_scroll_cancel_leaves_no_backlog");

    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void DragEdgeScrollTerminalCandidateFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = DragEdgeScrollFixture(device);
    CHECK(overlay != nil, "drag_edge_phase5_fixture");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    CJGuiInternalComposableSceneNode *text = DragEdgeScrollFindNode(overlay, 401);
    overlay.testDragEdgeScrollClockActive = YES;
    [ctx.pendingInteractions removeAllObjects];
    CHECK([overlay beginPointerCaptureForNode:text atPoint:NSMakePoint(300, 200)],
        "drag_edge_phase5_capture_begins");
    uint64_t gesture = overlay.pointerCaptureGestureEpoch;
    NSPoint outside = NSMakePoint(300, 500 - 4.0);
    (void)[overlay updatePointerCaptureAtPoint:outside];
    CHECK(overlay.dragEdgeScrollPhase == 1 && overlay.pointerCaptureActive,
        "drag_edge_phase5_real_pointer_update_arms_request");

    const uint64_t identity = 19, binding = 71, scene = ctx.composableSceneVersion;
    const int64_t node = 900, resource = 2;
    const int64_t generationA = 21, requestedA = 120, acceptedA = 100;
    CjguiInternalRendererStatus requestA = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity,
        generationA, requestedA, acceptedA, scene, 1);
    CHECK(requestA == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollPhase == 2,
        "drag_edge_phase5_original_request_is_pending");

#define CHECK_PHASE5_MISMATCH_ZERO_EFFECT(name, g, n, r, b, i, gen, req, acc, sc) do { \
    CjguiInternalRendererStatus mismatch = cjgui_internal_renderer_ack_drag_edge_viewport( \
        ctx.rendererSessionToken, (g), (n), (r), (b), (i), (gen), (req), (acc), (sc), 5); \
    CHECK(mismatch == CJGUI_INTERNAL_RENDERER_SCENE_STALE && \
        overlay.dragEdgeScrollPhase == 2 && overlay.dragEdgeScrollRequestGeneration == generationA && \
        overlay.dragEdgeScrollExpectedOffset == requestedA && overlay.dragEdgeScrollActive && \
        overlay.pointerCaptureActive, (name)); \
} while (0)

    CjguiInternalRendererStatus wrongIdentity = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity + 1,
        generationA, requestedA, acceptedA, scene, 5);
    CHECK(wrongIdentity == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        overlay.dragEdgeScrollPhase == 2 && overlay.dragEdgeScrollRequestGeneration == generationA &&
        overlay.dragEdgeScrollExpectedOffset == requestedA && overlay.dragEdgeScrollActive &&
        overlay.pointerCaptureActive,
        "drag_edge_phase5_wrong_viewport_has_zero_effect");
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_gesture_has_zero_effect",
        gesture + 1, node, resource, binding, identity, generationA, requestedA, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_binding_has_zero_effect",
        gesture, node, resource, binding + 1, identity, generationA, requestedA, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_node_has_zero_effect",
        gesture, node + 1, resource, binding, identity, generationA, requestedA, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_resource_has_zero_effect",
        gesture, node, resource + 1, binding, identity, generationA, requestedA, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_request_generation_has_zero_effect",
        gesture, node, resource, binding, identity, generationA + 1, requestedA, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_requested_offset_has_zero_effect",
        gesture, node, resource, binding, identity, generationA, requestedA + 1, acceptedA, scene);
    CHECK_PHASE5_MISMATCH_ZERO_EFFECT("drag_edge_phase5_wrong_scene_has_zero_effect",
        gesture, node, resource, binding, identity, generationA, requestedA, acceptedA, scene + 1);

    // A phase-5 candidate must prove every part of the same resident request.
    // A wrong accepted base may neither stop nor rewrite that request.
    CjguiInternalRendererStatus wrongBase = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity,
        generationA, requestedA, acceptedA + 1, scene, 5);
    CHECK(wrongBase == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        overlay.dragEdgeScrollPhase == 2 && overlay.dragEdgeScrollRequestGeneration == generationA &&
        overlay.dragEdgeScrollExpectedOffset == requestedA && overlay.dragEdgeScrollActive &&
        overlay.pointerCaptureActive,
        "drag_edge_phase5_wrong_original_offset_has_zero_effect");

    NSUInteger interactionsBeforeTerminal = ctx.pendingInteractions.count;
    CjguiInternalRendererStatus terminalA = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity,
        generationA, requestedA, acceptedA, scene, 5);
    CHECK(terminalA == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollPhase == 0 &&
        !overlay.dragEdgeScrollActive && overlay.pointerCaptureActive &&
        overlay.dragEdgeScrollRequestGeneration == 0 && overlay.dragEdgeScrollExpectedOffset == 0 &&
        overlay.dragEdgeScrollRequestAcceptedOffset == 0 && overlay.dragEdgeScrollRequestSceneVersion == 0 &&
        ctx.pendingInteractions.count == interactionsBeforeTerminal,
        "drag_edge_phase5_stops_residence_without_releasing_capture_or_replaying_input");

    (void)[overlay updatePointerCaptureAtPoint:outside];
    CHECK(overlay.dragEdgeScrollPhase == 1 && overlay.dragEdgeScrollActive &&
        overlay.pointerCaptureActive,
        "drag_edge_phase5_only_real_move_restarts_residence");
    const int64_t generationB = 22, requestedB = 160, acceptedB = 120;
    CjguiInternalRendererStatus requestB = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity,
        generationB, requestedB, acceptedB, scene, 1);
    CHECK(requestB == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollPhase == 2,
        "drag_edge_phase5_newer_request_is_pending");
    CjguiInternalRendererStatus lateA = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, node, resource, binding, identity,
        generationA, requestedA, acceptedA, scene, 5);
    CHECK(lateA == CJGUI_INTERNAL_RENDERER_SCENE_STALE && overlay.dragEdgeScrollPhase == 2 &&
        overlay.dragEdgeScrollRequestGeneration == generationB &&
        overlay.dragEdgeScrollExpectedOffset == requestedB && overlay.dragEdgeScrollActive &&
        overlay.pointerCaptureActive,
        "drag_edge_phase5_late_old_ticket_cannot_change_new_request");

    [overlay endPointerCaptureAtPoint:outside cancelled:NO];
    CHECK(!overlay.dragEdgeScrollActive && !overlay.pointerCaptureActive,
        "drag_edge_phase5_only_real_up_stops_capture");
#undef CHECK_PHASE5_MISMATCH_ZERO_EFFECT
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 2;
    DragEdgeScrollResidenceFixture(device);
    if (getenv("CJGUI_DRAG_EDGE_PHASE5_REGRESSION"))
        DragEdgeScrollTerminalCandidateFixture(device);
    fprintf(stderr, "drag_edge_scroll_residence failures=%d\n", failures);
    return failures ? 1 : 0;
} }
