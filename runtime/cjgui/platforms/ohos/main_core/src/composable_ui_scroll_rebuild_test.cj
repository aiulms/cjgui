package cjgui

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_wheel(
        session: UInt64, nodeId: UInt64, deltaY: Float64, phase: UInt32, momentum: UInt32): Int32
    func cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
        session: UInt64, nodeId: UInt64): Int32
    func cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_scroll_owner_at_point(session: UInt64, x: Float64, y: Float64,
        owner: CPointer<UInt64>, isScroll: CPointer<UInt32>, wheel: CPointer<UInt32>): Int32
}

private class ScrollRebuildController <: CjguiComposableUiController {
    let viewport = CjguiComposableUiScrollViewport()
    let outerViewport = CjguiComposableUiScrollViewport()
    var revision: Int64 = 1
    var light = false
    var help = false
    var nested = false
    var prependHeight: Int64 = 0
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let theme = if (light) { CjguiComposableUiTheme.paperLight() } else {
            CjguiComposableUiTheme.beaconDark()
        }
        let layers = cjguiComposableLayerHost(9700, "rebuild-layers",
            CjguiComposableUiStyle(growX: 1, growY: 1))
        let scroll = cjguiComposableScrollArea(9701, "rebuild-scroll", viewport,
            if (nested) { CjguiComposableUiStyle(growX: 1, fixedHeight: 220, clipsContent: true) }
            else { CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true) })
        let content = cjguiComposableVertical(9702, "rebuild-content", theme.page)
        if (prependHeight > 0) {
            content.add(cjguiComposableVertical(9705, "rebuild-owner-prefix",
                CjguiComposableUiStyle(fixedHeight: prependHeight)))
        }
        content.add(cjguiComposableButton(9703, "rebuild-theme", "theme", "THEME", -1, theme.primaryAction))
        content.add(cjguiComposableButton(9704, "rebuild-open-help", "help", "HELP", -1, theme.primaryAction))
        for (index in 0..18) {
            content.add(cjguiComposableText(9710 + index, "rebuild-row-${index}",
                "row ${index} 中文👩🏽‍💻", CjguiComposableUiStyle(fixedHeight: 40,
                    textColor: theme.body.textColor, fontSize: 14.0)))
        }
        scroll.add(content)
        if (nested) {
            let outer = cjguiComposableScrollArea(9601, "rebuild-outer-scroll", outerViewport,
                CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true))
            let outerContent = cjguiComposableVertical(9602, "rebuild-outer-content",
                CjguiComposableUiStyle(growX: 1, fixedHeight: 1000))
            outerContent.add(scroll)
            outerContent.add(cjguiComposableVertical(9603, "rebuild-outer-tail",
                CjguiComposableUiStyle(fixedHeight: 780)))
            outer.add(outerContent)
            layers.add(outer)
        } else { layers.add(scroll) }
        if (help) {
            let dialog = cjguiComposableDialogLayer(9800, "rebuild-help", "rebuild-help-layer",
                "rebuild-layers", -1, CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 120))
            dialog.add(cjguiComposableText(9801, "rebuild-help-text", "help", theme.body))
            dialog.add(cjguiComposableButton(9802, "rebuild-close-help", "return", "RETURN", -1,
                theme.primaryAction))
            layers.add(dialog)
        }
        return layers
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (event.node.actionName == "THEME") { light = !light }
            else if (event.node.actionName == "HELP") { help = true }
            else if (event.node.actionName == "RETURN") { help = false }
            else { return CjguiComposableUiDispatchResult(false) }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func scrollLayerHostNestedRebuildKeepsWheelAndOwnerReflowRevealsFocus(): Unit {
    let controller = ScrollRebuildController()
    controller.nested = true
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("nested scroll rebuild fixture", 480u32, 320u32))
    try {
        @Assert(window.start(), true)
        finishScrollRebuildScene(window, 1)
        pressScrollRebuildAction(window, 9703u64)
        @Assert(window.acceptedScrollBindingCount(), 2)
        @Assert(window.windowProgress().focusedControlId, "rebuild-theme")
        for (node in [9701u64, 9601u64]) {
            let viewport = if (node == 9701u64) { controller.viewport } else { controller.outerViewport }
            let before = viewport.offset()
            let scene = window.windowProgress().acceptedSceneVersion
            @Assert(unsafe { cjgui_internal_renderer_test_enqueue_composable_wheel(
                window.testSessionToken(), node, -20.0, 1u32, 0u32) }, 0)
            let _ = window.pump(0u32)
            finishScrollRebuildScene(window, scene + 1)
            @Assert(viewport.acceptedOffset(), before + 20)
            @Assert(window.windowProgress().focusedControlId, "rebuild-theme")
        }
        // An explicit focus still reveals through the SAME public planner.
        @Assert(window.focusAcceptedNodeById(9703), true)
        finishScrollRebuildScene(window, window.windowProgress().acceptedSceneVersion)
        let beforeOffset = controller.viewport.acceptedOffset()
        let beforeScene = window.windowProgress().acceptedSceneVersion
        controller.prependHeight = 500
        controller.revision += 1
        let _ = window.refreshIfNeeded()
        finishScrollRebuildScene(window, beforeScene + 1)
        @Assert(controller.viewport.acceptedOffset() > beforeOffset + 200, true)
        @Assert(window.windowProgress().focusedControlId, "rebuild-theme")
        var found = false
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == 9703) {
                found = true
                @Assert(node.clip.height, node.bounds.height)
            }
        }
        @Assert(found, true)
        println("SCROLL_REBUILD_NESTED inner=${controller.viewport.acceptedOffset()} " +
            "outer=${controller.outerViewport.acceptedOffset()} owner_reflow_visible=true focus=retained")
    } finally { window.close() }
}

private func pressScrollRebuildAction(window: CjguiComposableUiWindow, node: UInt64): Unit {
    let before = window.windowProgress().acceptedSceneVersion
    @Assert(unsafe { cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
        window.testSessionToken(), node) }, 0i32)
    @Assert(unsafe { cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(
        window.testSessionToken()) }, 0i32)
    let _ = window.pump(0u32)
    finishScrollRebuildScene(window, before + 1)
}

private func finishScrollRebuildScene(window: CjguiComposableUiWindow, minimum: Int64): Unit {
    var turns = 0
    while (window.isOpen() && (window.windowProgress().acceptedSceneVersion < minimum ||
            window.ownerIdleWaitAllowance(UInt32.Max) != UInt32.Max) && turns < 240) {
        // The ordinary host advances pending layout/drawable preparation
        // before draining input. Window.pump alone only drains that input.
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window)
        turns += 1
    }
    if (window.windowProgress().acceptedSceneVersion < minimum ||
        window.ownerIdleWaitAllowance(UInt32.Max) != UInt32.Max) {
        let progress = window.windowProgress()
        println("SCROLL_REBUILD_UNREADY turns=${turns} accepted=${progress.acceptedSceneVersion} " +
            "minimum=${minimum} pending=${progress.pendingRefreshReason} failure=${progress.lastNativeFailure} " +
            "native=${window.nativeStatus()}")
    }
    @Assert(window.windowProgress().acceptedSceneVersion >= minimum, true)
    @Assert(window.ownerIdleWaitAllowance(UInt32.Max), UInt32.Max)
}

@Test
func scrollLayerHostKeepsAcceptedViewportAfterPaintAndHelpRebuild(): Unit {
    let controller = ScrollRebuildController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("scroll rebuild fixture", 480u32, 320u32))
    try {
        @Assert(window.start(), true)
        finishScrollRebuildScene(window, 1)
        window.testSetSceneWriteTrace(true)
        @Assert(window.acceptedScrollBindingCount(), 1)
        for (stage in 0..3) {
            if (stage == 1) {
                pressScrollRebuildAction(window, 9703u64)
                @Assert(controller.light, true)
            }
            if (stage == 2) {
                pressScrollRebuildAction(window, 9704u64)
                @Assert(controller.help, true)
                pressScrollRebuildAction(window, 9802u64)
                @Assert(controller.help, false)
            }
            @Assert(window.windowProgress().lastNativeFailure, "none")
            @Assert(window.acceptedScrollBindingCount(), 1)
            @Assert(controller.viewport.ownerWindowToken() != 0, true)
            var owner = 0u64; var isScroll = 0u32; var wheel = 0u32
            let ownerStatus = unsafe { cjgui_internal_renderer_test_composable_scroll_owner_at_point(
                window.testSessionToken(), 240.0, 160.0, inout owner, inout isScroll, inout wheel) }
            @Assert(ownerStatus, 0)
            @Assert(owner, 9701u64)
            let before = controller.viewport.acceptedOffset()
            let wheelScene = window.windowProgress().acceptedSceneVersion
            let status = unsafe { cjgui_internal_renderer_test_enqueue_composable_wheel(
                window.testSessionToken(), 9701u64, -20.0, 1u32, 0u32) }
            @Assert(status, 0)
            @Assert(window.pump(0u32).isOpen, true)
            finishScrollRebuildScene(window, wheelScene + 1)
            println("SCROLL_REBUILD stage=${stage} binding=${window.acceptedScrollBindingCount()} " +
                "owner=${controller.viewport.ownerWindowToken()} before=${before} " +
                "requested=${controller.viewport.offset()} accepted=${controller.viewport.acceptedOffset()} " +
                "failure=${window.windowProgress().lastNativeFailure}")
            @Assert(controller.viewport.acceptedOffset(), before + 20)
        }
    } finally { window.close() }
}
