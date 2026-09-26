package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*

foreign {
    func cjgui_internal_renderer_test_composable_text_resource_stats(
        session: UInt64, nodeIndex: UInt32, outByteCount: CPointer<UInt64>,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_tile_stats(
        session: UInt64, nodeIndex: UInt32, tileIndex: UInt32,
        outTileCount: CPointer<UInt32>, outTileBytes: CPointer<UInt64>,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
        session: UInt64, nodeIndex: UInt32, tileIndex: UInt32,
        outNonzeroAlphaPixels: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_selection_rect_stats(
        session: UInt64, nodeIndex: UInt32,
        outRectCount: CPointer<UInt32>, outMinY: CPointer<Float32>, outMaxY: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_content_size(
        session: UInt64, width: UInt32, height: UInt32,
        outActualWidth: CPointer<UInt32>, outActualHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_viewport_size(
        session: UInt64, width: UInt32, height: UInt32,
        outViewWidth: CPointer<UInt32>, outViewHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_toggle_composable_backing_scale(
        session: UInt64, outResizeVersion: CPointer<UInt64>,
        outBeforeScale: CPointer<Float64>, outAfterScale: CPointer<Float64>,
        outDrawableWidth: CPointer<UInt32>, outDrawableHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>,
        outUploadBytes: CPointer<UInt64>, outUploadMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_interval_stats(
        session: UInt64, outStaticDrawWithLayoutMicros: CPointer<UInt64>,
        outNormalizeMicros: CPointer<UInt64>, outTextureCreateMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_projection_timing_stats(
        session: UInt64, outAccessibilityMicros: CPointer<UInt64>,
        outInputMicros: CPointer<UInt64>, outRefreshMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>,
        outCommitMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_present_timing_stats(
        session: UInt64, outNextDrawableMicros: CPointer<UInt64>,
        outCommandBufferMicros: CPointer<UInt64>, outPresentMicros: CPointer<UInt64>,
        outCommitMicros: CPointer<UInt64>, outReadbackWaitMicros: CPointer<UInt64>,
        outReadbackWaited: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_edit_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_activate_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_scroll_composable_multiline(
        session: UInt64, deltaY: Float32, outScrollOffset: CPointer<Float32>,
        outVisibleGlyphCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
}

private class HeavyWindowController <: CjguiComposableUiController {
    private var text: String = longText(100000)
    private var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableMultilineTextInput(41, "heavy-text", "", text, 41,
            CjguiComposableUiStyle(growX: 1, growY: 1))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 41) {
            text = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func updateText(): Unit { text = text + "尾部更新 😀"; revision += 1 }
}

private class ResponsiveWindowController <: CjguiComposableUiController {
    private var value: String = "B初始"
    private var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableTextInput(51, "responsive-field", "B字段", value, 51,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 38))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 51) {
            value = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func ownerValue(): String { return value }
}

private func editResponsive(application: CjguiMacosApplication, window: CjguiComposableUiWindow,
    controller: ResponsiveWindowController, nextValue: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(nextValue) }
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_edit_composable_text(
            window.testSessionToken(), 0u32, textResource.value) }
    }
    var turns: Int64 = 0
    while (turns < 20 && (controller.ownerValue() != nextValue ||
        window.acceptedSceneNodes()[0].value != nextValue)) {
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        turns += 1
    }
    let accepted = window.acceptedSceneNodes()[0].value
    let ok = status == CJGUI_INTERNAL_RENDERER_OK && controller.ownerValue() == nextValue && accepted == nextValue
    println("CJGUI_TWO_WINDOW_B value='${nextValue}' edit_status=${status} turns=${turns} " +
        "owner='${controller.ownerValue()}' accepted='${accepted}' ok=${ok}")
    return ok
}

private func runTwoWindowResponse(): Bool {
    let heavy = HeavyWindowController()
    let responsive = ResponsiveWindowController()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let openedA = application.openWindow(heavy,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Heavy A", 980u32, 620u32))
    let openedB = application.openWindow(responsive,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Responsive B", 320u32, 240u32))
    if (!openedA.didOpen || !openedB.didOpen) { application.close(); return false }
    let identifierA = if (let Some(value) <- openedA.identifier) { value } else { application.close(); return false }
    let identifierB = if (let Some(value) <- openedB.identifier) { value } else { application.close(); return false }
    let windowA = if (let Some(value) <- application.window(identifierA)) { value } else {
        application.close(); return false
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) { value } else {
        application.close(); return false
    }
    let startFocus = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        windowA.testSessionToken(), 20.0f32, 20.0f32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    let beforeSelectionProjection = windowA.windowProjection()
    let beforeSelectionWork = textWork(windowA)
    let selectionStarted = MonoTime.now()
    let selectionStatus = unsafe { cjgui_internal_renderer_test_set_composable_selection(
        windowA.testSessionToken(), 0u32, 0u32, 2u32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    let selectionElapsed = (MonoTime.now() - selectionStarted).toMilliseconds()
    emitCost(windowA, "selection", 0, selectionElapsed, beforeSelectionProjection, beforeSelectionWork)
    let selected = windowA.windowProgress().hasTextSelection &&
        windowA.windowProgress().selectionStart == 0 && windowA.windowProgress().selectionEnd == 2
    let afterSelectionWork = textWork(windowA)
    let selectionReuse = beforeSelectionWork[1] == afterSelectionWork[1] &&
        beforeSelectionWork[2] == afterSelectionWork[2]
    let emojiStatus = unsafe { cjgui_internal_renderer_test_set_composable_selection(
        windowA.testSessionToken(), 0u32, 15u32, 15u32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    let emojiSelection = windowA.windowProgress()
    let emojiWhole = emojiSelection.selectionStart == 14 && emojiSelection.selectionEnd == 16
    let crossStatus = unsafe { cjgui_internal_renderer_test_set_composable_selection(
        windowA.testSessionToken(), 0u32, 100u32, 1500u32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    var tileCount: UInt32 = 0u32
    var firstTileBytes: UInt64 = 0u64
    var firstTileX: Float32 = 0.0f32
    var firstTileY: Float32 = 0.0f32
    var firstTileWidth: Float32 = 0.0f32
    var firstTileHeight: Float32 = 0.0f32
    let seamStatus = unsafe { cjgui_internal_renderer_test_composable_text_tile_stats(
        windowA.testSessionToken(), 0u32, 0u32, inout tileCount, inout firstTileBytes,
        inout firstTileX, inout firstTileY, inout firstTileWidth, inout firstTileHeight) }
    var selectionRectCount: UInt32 = 0u32
    var selectionMinY: Float32 = 0.0f32
    var selectionMaxY: Float32 = 0.0f32
    let selectionRectStatus = unsafe { cjgui_internal_renderer_test_composable_text_selection_rect_stats(
        windowA.testSessionToken(), 0u32, inout selectionRectCount, inout selectionMinY, inout selectionMaxY) }
    let seamY = firstTileY + firstTileHeight
    let crossTileSelection = crossStatus == CJGUI_INTERNAL_RENDERER_OK &&
        windowA.windowProgress().selectionStart == 100 && windowA.windowProgress().selectionEnd == 1500 &&
        seamStatus == CJGUI_INTERNAL_RENDERER_OK && tileCount > 1u32 &&
        selectionRectStatus == CJGUI_INTERNAL_RENDERER_OK && selectionRectCount > 1u32 &&
        selectionMinY < seamY && selectionMaxY > seamY
    println("CJGUI_TEXT_SELECTION emoji_status=${emojiStatus} emoji_utf16_whole=${emojiWhole} " +
        "cross_status=${crossStatus} selection=100..1500 rect_count=${selectionRectCount} " +
        "rect_y=${selectionMinY}..${selectionMaxY} tile_seam_y=${seamY} cross_tile=${crossTileSelection}")
    var offset: Float32 = 0.0f32
    var glyphs: UInt32 = 0u32
    let beforeScrollProjection = windowA.windowProjection()
    let beforeScrollWork = textWork(windowA)
    let scrollStarted = MonoTime.now()
    let scrollStatus = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
        windowA.testSessionToken(), -140.0f32, inout offset, inout glyphs) }
    let scrollElapsed = (MonoTime.now() - scrollStarted).toMilliseconds()
    emitCost(windowA, "scroll", 0, scrollElapsed, beforeScrollProjection, beforeScrollWork)
    let afterScroll = editResponsive(application, windowB, responsive, "B滚动后")
    var resizeVersion: UInt64 = 0u64
    let beforeResizeProjection = windowA.windowProjection()
    let beforeResizeWork = textWork(windowA)
    let resizeStarted = MonoTime.now()
    let resizeStatus = unsafe { cjgui_internal_renderer_test_resize_composable_window(
        windowA.testSessionToken(), inout resizeVersion) }
    let resizeAccepted = windowA.refresh()
    let resizeElapsed = (MonoTime.now() - resizeStarted).toMilliseconds()
    emitCost(windowA, "resize", 0, resizeElapsed, beforeResizeProjection, beforeResizeWork)
    let afterResize = editResponsive(application, windowB, responsive, "B缩放后")
    heavy.updateText()
    let beforeUpdateProjection = windowA.windowProjection()
    let beforeUpdateWork = textWork(windowA)
    let updateStarted = MonoTime.now()
    let updateAccepted = windowA.refresh()
    let updateElapsed = (MonoTime.now() - updateStarted).toMilliseconds()
    emitCost(windowA, "hot_content", 1, updateElapsed, beforeUpdateProjection, beforeUpdateWork)
    let afterUpdate = editResponsive(application, windowB, responsive, "B内容后")
    let workBeforeIdle = textWork(windowA)
    let beforeIdleProjection = windowA.windowProjection()
    let idleStarted = MonoTime.now()
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    let idleElapsed = (MonoTime.now() - idleStarted).toMilliseconds()
    emitCost(windowA, "idle", 1, idleElapsed, beforeIdleProjection, workBeforeIdle)
    let workAfterIdle = textWork(windowA)
    let idle = workBeforeIdle[1] == workAfterIdle[1] && workBeforeIdle[2] == workAfterIdle[2]
    windowA.close()
    let afterClose = editResponsive(application, windowB, responsive, "B关A后")
    let ok = startFocus == CJGUI_INTERNAL_RENDERER_OK && selectionStatus == CJGUI_INTERNAL_RENDERER_OK &&
        selected && selectionReuse && emojiStatus == CJGUI_INTERNAL_RENDERER_OK && emojiWhole &&
        crossTileSelection && scrollStatus == CJGUI_INTERNAL_RENDERER_OK &&
        offset > 0.0f32 && glyphs > 0u32 && resizeStatus == CJGUI_INTERNAL_RENDERER_OK &&
        resizeVersion > 0u64 && resizeAccepted && updateAccepted && afterScroll && afterResize &&
        afterUpdate && idle && afterClose
    println("CJGUI_TWO_WINDOW_RESPONSE focus=${startFocus} selection=${selectionStatus} " +
        "selected=${selected} selection_reuse=${selectionReuse} scroll=${scrollStatus} offset=${offset} " +
        "visible_glyphs=${glyphs} resize=${resizeStatus} resize_version=${resizeVersion} " +
        "update=${updateAccepted} idle_raster=${workBeforeIdle[1]}->${workAfterIdle[1]} " +
        "idle_upload=${workBeforeIdle[2]}->${workAfterIdle[2]} b_after_close=${afterClose} ok=${ok}")
    application.close()
    return ok
}

private class BudgetController <: CjguiComposableUiController {
    private var overlayVisible: Bool = false
    private var revision: Int64 = 1
    private var draft: String = longText(10000)
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let host = cjguiComposableLayerHost(30, "budget-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(cjguiComposableMultilineTextInput(31, "budget-base", "", draft, 31,
            CjguiComposableUiStyle(growX: 1, growY: 1)))
        if (overlayVisible) {
            let layer = cjguiComposableAnchoredLayer(32, "budget-layer", "budget-layer", "popup",
                "budget-base", 31, CjguiComposableUiStyle(fixedWidth: 1440, fixedHeight: 900))
            layer.add(cjguiComposableMultilineTextInput(33, "budget-overlap", "", longText(10000), 33,
                CjguiComposableUiStyle(growX: 1, growY: 1)))
            host.add(layer)
        }
        return host
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 31) {
            draft = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func showOverlay(): Unit { overlayVisible = true; revision += 1 }
    public func hideOverlay(): Unit { overlayVisible = false; revision += 1 }
    public func ownerDraft(): String { return draft }
}

private func runBudgetRollback(): Bool {
    let controller = BudgetController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Text Budget Probe", 1440u32, 900u32))
    if (!window.start()) {
        println("CJGUI_TEXT_BUDGET start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    let acceptedBefore = window.windowProgress().acceptedSceneVersion
    controller.showOverlay()
    let rejected = !window.refresh()
    let rejectionReason = window.windowProgress().lastNativeFailure
    let acceptedAfterReject = window.windowProgress().acceptedSceneVersion
    let retained = window.acceptedSceneNodes().size == 2 &&
        window.acceptedSceneNodes()[1].semanticId == "budget-base"
    let nativeText = unsafe { LibC.mallocCString("拒绝后继续编辑 😀") }
    var editStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        editStatus = unsafe { cjgui_internal_renderer_test_edit_composable_text(
            window.testSessionToken(), 1u32, textResource.value) }
    }
    let editTurn = window.pump(0u32)
    let ownerReadback = controller.ownerDraft()
    controller.hideOverlay()
    let recovered = window.refresh()
    let acceptedValue = if (window.acceptedSceneNodes().size > 1) {
        window.acceptedSceneNodes()[1].value
    } else { "" }
    let ok = rejected && rejectionReason == "text_resource_budget_exceeded" &&
        acceptedAfterReject == acceptedBefore && retained &&
        editStatus == CJGUI_INTERNAL_RENDERER_OK && editTurn.didApplyHumanAction &&
        ownerReadback == "拒绝后继续编辑 😀" && recovered && acceptedValue == ownerReadback &&
        window.windowProgress().lastNativeFailure == "none"
    println("CJGUI_TEXT_BUDGET rejected=${rejected} reason=${rejectionReason} " +
        "accepted_before=${acceptedBefore} accepted_after_reject=${acceptedAfterReject} retained=${retained} " +
        "edit_status=${editStatus} owner='${ownerReadback}' recovered=${recovered} " +
        "accepted_value='${acceptedValue}' ok=${ok}")
    window.close()
    return ok
}

private func runStartupBudgetFailure(): Bool {
    let controller = BudgetController()
    controller.showOverlay()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Budget Startup Probe", 1440u32, 900u32))
    let started = window.start()
    let progress = window.windowProgress()
    let ok = !started && progress.lastNativeFailure == "native_present_text_resource_budget_exceeded" &&
        progress.pendingRefreshReason == "start_native_present_text_resource_budget_exceeded"
    println("CJGUI_TEXT_BUDGET_STARTUP started=${started} native_status=${window.nativeStatus()} " +
        "failure=${progress.lastNativeFailure} pending=${progress.pendingRefreshReason} ok=${ok}")
    if (started) { window.close() }
    return ok
}

private class MovingTextController <: CjguiComposableUiController {
    private var padding: Int64 = 12
    private var caption: String = "稳定文字 观微 😀"
    private var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(20, "moving-root", CjguiComposableUiStyle(padding: padding))
        root.add(cjguiComposableText(21, "moving-text", caption,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 40)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func move(): Unit { padding = 24; revision += 1 }
    public func changeText(): Unit { caption = "内容已更新 观微 😀"; revision += 1 }
}

private func textWork(window: CjguiComposableUiWindow): (Int32, UInt64, UInt64, UInt64, UInt64) {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        window.testSessionToken(), inout rasterCount, inout rasterBytes, inout rasterMicros,
        inout uploadCount, inout uploadBytes, inout uploadMicros) }
    return (status, rasterCount, uploadCount, rasterMicros, uploadMicros)
}

private func projectionTimings(window: CjguiComposableUiWindow): (UInt64, UInt64, UInt64) {
    var axMicros: UInt64 = 0u64
    var inputMicros: UInt64 = 0u64
    var refreshMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
        window.testSessionToken(), inout axMicros, inout inputMicros, inout refreshMicros) }
    return (axMicros, inputMicros, refreshMicros)
}

private func stageTimings(window: CjguiComposableUiWindow): (UInt64, UInt64, UInt64) {
    var clones: UInt64 = 0u64
    var allocs: UInt64 = 0u64
    var configureMicros: UInt64 = 0u64
    var setMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_scene_submission_stats(
        window.testSessionToken(), inout clones, inout allocs, inout configureMicros,
        inout setMicros, inout commitMicros) }
    return (configureMicros, setMicros, commitMicros)
}

private func textIntervals(window: CjguiComposableUiWindow): (Int32, UInt64, UInt64, UInt64) {
    var drawMicros: UInt64 = 0u64
    var normalizeMicros: UInt64 = 0u64
    var createMicros: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_text_interval_stats(
        window.testSessionToken(), inout drawMicros, inout normalizeMicros, inout createMicros) }
    return (status, drawMicros, normalizeMicros, createMicros)
}

private func emitCost(window: CjguiComposableUiWindow, kind: String, ordinal: Int64,
    elapsedMs: Int64, before: CjguiSharedOperationWindowProjection,
    beforeWork: (Int32, UInt64, UInt64, UInt64, UInt64)): Unit {
    let after = window.windowProjection()
    let afterWork = textWork(window)
    let intervals = textIntervals(window)
    let rasterMicrosDelta = afterWork[3] - beforeWork[3]
    let uploadMicrosDelta = afterWork[4] - beforeWork[4]
    let stageAfter = stageTimings(window)
    let projAfter = projectionTimings(window)
    println("CJGUI_TEXT_COST kind=${kind} ordinal=${ordinal} clock=MonoTime elapsed_ms=${elapsedMs} " +
        "build_count=${before.buildPassCount}->${after.buildPassCount} " +
        "layout_count=${before.layoutPassCount}->${after.layoutPassCount} " +
        "native_submit_count=${before.nativeSubmissionCount}->${after.nativeSubmissionCount} " +
        "raster_count=${beforeWork[1]}->${afterWork[1]} upload_count=${beforeWork[2]}->${afterWork[2]} " +
        "last_build_ms=${after.lastBuildElapsedMs} last_layout_ms=${after.lastLayoutElapsedMs} " +
        "last_native_stage_submit_ms=${after.lastNativeStageAndSubmitElapsedMs} " +
        "gpu_completed_frame=${after.observedMetalCompletionFrameIndex} " +
        "intervals_status=${intervals[0]} draw_with_layout_us_total=${intervals[1]} " +
        "normalize_us_total=${intervals[2]} texture_create_us_total=${intervals[3]} " +
        "raster_us_delta=${rasterMicrosDelta} upload_us_delta=${uploadMicrosDelta} " +
        "stage_configure_us_total=${stageAfter[0]} stage_set_us_total=${stageAfter[1]} " +
        "stage_commit_us_total=${stageAfter[2]} " +
        "proj_ax_us_total=${projAfter[0]} proj_input_us_total=${projAfter[1]} " +
        "proj_refresh_us_total=${projAfter[2]}")
}

private func runMovementReuse(): Bool {
    let controller = MovingTextController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Text Reuse Probe", 980u32, 620u32))
    if (!window.start()) {
        println("CJGUI_TEXT_REUSE start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    let before = textWork(window)
    let beforeMoveProjection = window.windowProjection()
    let initialX = window.acceptedSceneNodes()[1].bounds.x
    controller.move()
    let moveStarted = MonoTime.now()
    let moved = window.refresh()
    let moveElapsed = (MonoTime.now() - moveStarted).toMilliseconds()
    emitCost(window, "position", 0, moveElapsed, beforeMoveProjection, before)
    let afterMove = textWork(window)
    let movedX = window.acceptedSceneNodes()[1].bounds.x
    controller.changeText()
    let beforeContentProjection = window.windowProjection()
    let contentStarted = MonoTime.now()
    let changed = window.refresh()
    let contentElapsed = (MonoTime.now() - contentStarted).toMilliseconds()
    emitCost(window, "hot_content", 0, contentElapsed, beforeContentProjection, afterMove)
    let afterContent = textWork(window)
    let updatedValue = window.acceptedSceneNodes()[1].value
    let beforeIdleProjection = window.windowProjection()
    let idleStarted = MonoTime.now()
    let idle = window.refresh()
    let idleElapsed = (MonoTime.now() - idleStarted).toMilliseconds()
    emitCost(window, "forced_same_content_refresh", 0, idleElapsed, beforeIdleProjection, afterContent)
    let afterIdle = textWork(window)
    let ok = before[0] == CJGUI_INTERNAL_RENDERER_OK && afterMove[0] == CJGUI_INTERNAL_RENDERER_OK &&
        afterContent[0] == CJGUI_INTERNAL_RENDERER_OK && afterIdle[0] == CJGUI_INTERNAL_RENDERER_OK &&
        moved && changed && idle && movedX == initialX + 12 &&
        afterMove[1] == before[1] && afterMove[2] == before[2] &&
        afterContent[1] > afterMove[1] && afterContent[2] > afterMove[2] &&
        updatedValue == "内容已更新 观微 😀" &&
        afterIdle[1] == afterContent[1] && afterIdle[2] == afterContent[2]
    println("CJGUI_TEXT_REUSE initial_x=${initialX} moved_x=${movedX} " +
        "raster=${before[1]},${afterMove[1]},${afterContent[1]},${afterIdle[1]} " +
        "upload=${before[2]},${afterMove[2]},${afterContent[2]},${afterIdle[2]} " +
        "accepted_value='${updatedValue}' ok=${ok}")
    window.close()
    return ok
}

private class LargeTextController <: CjguiComposableUiController {
    let multiline: Bool
    let text: String
    init(multiline: Bool, text: String) { this.multiline = multiline; this.text = text }
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let style = CjguiComposableUiStyle(growX: 1, growY: 1)
        if (multiline) {
            return cjguiComposableMultilineTextInput(1, "large-text", "", text, 1, style)
        }
        return cjguiComposableText(1, "large-text", text, style)
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func longText(characters: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < characters) {
        builder.append("行 ${index}: 中文 emoji 😀 and text.\n")
        index += 30
    }
    return builder.toString()
}

private func runSizeRoundTrip(): Bool {
    let text = longText(100000)
    let window = CjguiComposableUiWindow(LargeTextController(true, text),
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Text Size Round Trip", 320u32, 240u32))
    if (!window.start()) { return false }
    var largeWidth: UInt32 = 0u32
    var largeHeight: UInt32 = 0u32
    let growStatus = unsafe { cjgui_internal_renderer_test_set_composable_content_size(
        window.testSessionToken(), 1440u32, 900u32, inout largeWidth, inout largeHeight) }
    let grew = window.refresh()
    var largeBytes: UInt64 = 0u64
    var x: Float32 = 0.0f32
    var y: Float32 = 0.0f32
    var w: Float32 = 0.0f32
    var h: Float32 = 0.0f32
    let largeResource = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
        window.testSessionToken(), 0u32, inout largeBytes, inout x, inout y, inout w, inout h) }
    var controlledWidth: UInt32 = 0u32
    var controlledHeight: UInt32 = 0u32
    let controlledStatus = unsafe { cjgui_internal_renderer_test_set_composable_viewport_size(
        window.testSessionToken(), 1440u32, 900u32, inout controlledWidth, inout controlledHeight) }
    let controlledAccepted = window.refresh()
    var controlledBytes: UInt64 = 0u64
    let controlledResource = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
        window.testSessionToken(), 0u32, inout controlledBytes, inout x, inout y, inout w, inout h) }
    var smallWidth: UInt32 = 0u32
    var smallHeight: UInt32 = 0u32
    let shrinkStatus = unsafe { cjgui_internal_renderer_test_set_composable_content_size(
        window.testSessionToken(), 320u32, 240u32, inout smallWidth, inout smallHeight) }
    let shrank = window.refresh()
    var smallBytes: UInt64 = 0u64
    let smallResource = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
        window.testSessionToken(), 0u32, inout smallBytes, inout x, inout y, inout w, inout h) }
    let retainedText = window.acceptedSceneNodes().size > 0 && window.acceptedSceneNodes()[0].value == text
    let ok = growStatus == CJGUI_INTERNAL_RENDERER_OK && grew &&
        largeResource == CJGUI_INTERNAL_RENDERER_OK && largeWidth == 1440u32 && largeHeight > 0u32 &&
        largeBytes > 0u64 && largeBytes <= 24u64 * 1024u64 * 1024u64 &&
        controlledStatus == CJGUI_INTERNAL_RENDERER_OK && controlledAccepted &&
        controlledResource == CJGUI_INTERNAL_RENDERER_OK &&
        controlledWidth == 1440u32 && controlledHeight == 900u32 &&
        controlledBytes == 1440u64 * 900u64 * 4u64 * 4u64 &&
        shrinkStatus == CJGUI_INTERNAL_RENDERER_OK && shrank &&
        smallResource == CJGUI_INTERNAL_RENDERER_OK && smallWidth == 320u32 && smallHeight == 240u32 &&
        smallBytes > 0u64 && smallBytes < controlledBytes && retainedText
    let session = window.testSessionToken()
    let occupiedBeforeClose = unsafe { cjgui_internal_renderer_occupied_session_count() }
    window.close()
    let occupiedAfterClose = unsafe { cjgui_internal_renderer_occupied_session_count() }
    var retiredBytes: UInt64 = 0u64
    let retiredStatus = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
        session, 0u32, inout retiredBytes, inout x, inout y, inout w, inout h) }
    let released = occupiedBeforeClose > occupiedAfterClose &&
        retiredStatus == CJGUI_INTERNAL_RENDERER_INVALID_SESSION
    println("CJGUI_TEXT_SIZE_ROUND_TRIP kind=controlled requested=320x240->1440x900->320x240 " +
        "actual_window_large=${largeWidth}x${largeHeight} controlled_viewport=${controlledWidth}x${controlledHeight} " +
        "actual_small=${smallWidth}x${smallHeight} bytes_large=${largeBytes} " +
        "bytes_controlled=${controlledBytes} bytes_small=${smallBytes} grow=${grew} " +
        "controlled_accepted=${controlledAccepted} shrink=${shrank} " +
        "accepted_value_retained=${retainedText} occupied=${occupiedBeforeClose}->${occupiedAfterClose} " +
        "retired_status=${retiredStatus} released=${released} ok=${ok && released}")
    return ok && released
}

private func runCase(width: UInt32, height: UInt32, multiline: Bool, characters: Int64): Bool {
    let text = if (multiline) { longText(characters) } else { "正常尺寸短文字 观微 😀" }
    let controller = LargeTextController(multiline, text)
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Large Text Probe", width, height))
    let coldStarted = MonoTime.now()
    let started = window.start()
    let coldElapsed = (MonoTime.now() - coldStarted).toMilliseconds()
    var bytes: UInt64 = 0u64
    var x: Float32 = 0.0f32
    var y: Float32 = 0.0f32
    var textureWidth: Float32 = 0.0f32
    var textureHeight: Float32 = 0.0f32
    let resourceStatus = if (started) {
        unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(window.testSessionToken(),
            0u32, inout bytes, inout x, inout y, inout textureWidth, inout textureHeight) }
    } else { -1i32 }
    if (started) {
        let projection = window.windowProjection()
        let work = textWork(window)
        println("CJGUI_TEXT_COST kind=cold ordinal=0 requested=${width}x${height} multiline=${multiline} " +
            "clock=MonoTime elapsed_ms=${coldElapsed} build_count=${projection.buildPassCount} " +
            "layout_count=${projection.layoutPassCount} native_submit_count=${projection.nativeSubmissionCount} " +
            "raster_count=${work[1]} upload_count=${work[2]} " +
            "last_build_ms=${projection.lastBuildElapsedMs} last_layout_ms=${projection.lastLayoutElapsedMs} " +
            "last_native_stage_submit_ms=${projection.lastNativeStageAndSubmitElapsedMs} " +
            "gpu_completed_frame=${projection.observedMetalCompletionFrameIndex}")
    }
    // AppKit may clamp a requested window to the active screen (1440x900
    // becomes 1440x841 on this host). Report the actual accepted viewport;
    // the exact 1440x900 geometry belongs to a controlled scene probe.
    let acceptedWidth = if (started && window.acceptedSceneNodes().size > 0) {
        window.acceptedSceneNodes()[0].bounds.width
    } else { 0 }
    let acceptedHeight = if (started && window.acceptedSceneNodes().size > 0) {
        window.acceptedSceneNodes()[0].bounds.height
    } else { 0 }
    let accepted = acceptedWidth > 0 && acceptedHeight > 0 &&
        acceptedWidth <= Int64(width) && acceptedHeight <= Int64(height)
    var tileCount: UInt32 = 0u32
    var tileSum: UInt64 = 0u64
    var tileAlphaPixels: UInt64 = 0u64
    var tileStatus = CJGUI_INTERNAL_RENDERER_OK
    var index: UInt32 = 0u32
    var previousBottom: Float32 = y
    while (started && (index == 0u32 || index < tileCount)) {
        var tileBytes: UInt64 = 0u64
        var tileX: Float32 = 0.0f32
        var tileY: Float32 = 0.0f32
        var tileWidth: Float32 = 0.0f32
        var tileHeight: Float32 = 0.0f32
        let status = unsafe { cjgui_internal_renderer_test_composable_text_tile_stats(
            window.testSessionToken(), 0u32, index, inout tileCount, inout tileBytes,
            inout tileX, inout tileY, inout tileWidth, inout tileHeight) }
        var alphaPixels: UInt64 = 0u64
        let alphaStatus = unsafe { cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
            window.testSessionToken(), 0u32, index, inout alphaPixels) }
        if (status != CJGUI_INTERNAL_RENDERER_OK || tileBytes == 0u64 ||
            tileBytes > 8u64 * 1024u64 * 1024u64 || tileX != x || tileWidth != textureWidth ||
            tileY != previousBottom || alphaStatus != CJGUI_INTERNAL_RENDERER_OK || alphaPixels == 0u64) {
            tileStatus = if (status == CJGUI_INTERNAL_RENDERER_OK) { -1i32 } else { status }
            break
        }
        previousBottom = tileY + tileHeight
        tileSum += tileBytes
        tileAlphaPixels += alphaPixels
        index += 1u32
    }
    let ok = started && accepted && resourceStatus == CJGUI_INTERNAL_RENDERER_OK &&
        bytes > 0u64 && bytes <= 24u64 * 1024u64 * 1024u64 && tileStatus == CJGUI_INTERNAL_RENDERER_OK &&
        tileSum == bytes && previousBottom == y + textureHeight &&
        (multiline && tileCount > 1u32 || !multiline && tileCount == 1u32) &&
        (multiline || textureHeight < Float32(height) / 2.0f32)
    println("CJGUI_LARGE_TEXT_WINDOW width=${width} height=${height} multiline=${multiline} " +
        "characters=${characters} started=${started} accepted=${accepted} " +
        "accepted_size=${acceptedWidth}x${acceptedHeight} native_status=${window.nativeStatus()} " +
        "failure=${window.windowProgress().lastNativeFailure} resource_status=${resourceStatus} bytes=${bytes} " +
        "texture=${x},${y},${textureWidth},${textureHeight} tiles=${tileCount} " +
        "tile_sum=${tileSum} tile_alpha_pixels=${tileAlphaPixels} tile_status=${tileStatus} ok=${ok}")
    var scaleOk = true
    if (started && multiline) {
        var revision: UInt64 = 0u64
        var beforeScale: Float64 = 0.0
        var afterScale: Float64 = 0.0
        var drawableWidth: UInt32 = 0u32
        var drawableHeight: UInt32 = 0u32
        let toggleStatus = unsafe { cjgui_internal_renderer_test_toggle_composable_backing_scale(
            window.testSessionToken(), inout revision, inout beforeScale, inout afterScale,
            inout drawableWidth, inout drawableHeight) }
        let refreshed = window.refresh()
        var afterBytes: UInt64 = 0u64
        var afterX: Float32 = 0.0f32
        var afterY: Float32 = 0.0f32
        var afterWidth: Float32 = 0.0f32
        var afterHeight: Float32 = 0.0f32
        let afterStatus = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
            window.testSessionToken(), 0u32, inout afterBytes,
            inout afterX, inout afterY, inout afterWidth, inout afterHeight) }
        scaleOk = toggleStatus == CJGUI_INTERNAL_RENDERER_OK && refreshed &&
            afterStatus == CJGUI_INTERNAL_RENDERER_OK && beforeScale != afterScale &&
            afterWidth == textureWidth && afterHeight == textureHeight &&
            (afterScale < beforeScale && afterBytes < bytes || afterScale > beforeScale && afterBytes > bytes)
        println("CJGUI_LARGE_TEXT_SCALE width=${width} height=${height} " +
            "kind=controlled before=${beforeScale} after=${afterScale} drawable=${drawableWidth}x${drawableHeight} " +
            "before_bytes=${bytes} after_bytes=${afterBytes} refreshed=${refreshed} " +
            "native_status=${window.nativeStatus()} ok=${scaleOk}")
    }
    if (started) { window.close() }
    return ok && scaleOk
}

main(): Int64 {
    var ok = true
    ok = runCase(320u32, 240u32, false, 0) && ok
    ok = runCase(980u32, 620u32, false, 0) && ok
    ok = runCase(1440u32, 900u32, false, 0) && ok
    ok = runCase(980u32, 620u32, true, 10000) && ok
    ok = runCase(1440u32, 900u32, true, 100000) && ok
    ok = runSizeRoundTrip() && ok
    ok = runMovementReuse() && ok
    ok = runBudgetRollback() && ok
    ok = runStartupBudgetFailure() && ok
    ok = runTwoWindowResponse() && ok
    println("CJGUI_LARGE_TEXT_WINDOW passed=${ok}")
    return if (ok) { 0 } else { 1 }
}
