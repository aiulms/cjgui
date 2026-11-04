package cjgui

import std.time.*

private class TooltipReturnOwner <: CjguiComposableUiController {
    let viewport = CjguiComposableUiScrollViewport()
    let tooltip = CjguiTooltip("keyboard-tip", "keyboard-tip")
    var revision: Int64 = 1
    var dialogOpen: Bool = false
    var nonmodalPopup: Bool = false
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let scroll = cjguiComposableScrollArea(9701, "tooltip-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true))
        let content = cjguiComposableVertical(9702, "tooltip-content", CjguiComposableUiStyle())
        let button = cjguiComposableButton(9703, "tooltip-anchor", "help", "HELP", 1,
            CjguiComposableUiStyle(fixedHeight: 30))
        let _ = tooltip.bind(button, "help", reference: CjguiComposableUiNodeReference.manual(9703))
        content.add(button)
        for (index in 0..20) {
            content.add(cjguiComposableText(9710 + index, "tooltip-row-${index}", "row ${index}",
                CjguiComposableUiStyle(fixedHeight: 40)))
        }
        scroll.add(content)
        if (!dialogOpen) { return tooltip.attachTo(scroll) }
        let host = cjguiComposableLayerHost(9800, "return-dialog-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(scroll)
        let dialog = if (nonmodalPopup) {
            CjguiComposableUiNode(9801, "return-dialog", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
                CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 100), layerId: "return-dialog-layer",
                layerKind: "popup", layerOwnerSemanticId: "tooltip-anchor", layerAnchorNodeId: 9703,
                layerInitialFocusNodeId: 9802)
        } else {
            cjguiComposableDialogLayer(9801, "return-dialog", "return-dialog-layer",
                "tooltip-anchor", 9703, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 100),
                initialFocusNodeId: 9802)
        }
        dialog.add(cjguiComposableButton(9802, "return-dialog-action", "Close", "CLOSE", -1,
            CjguiComposableUiStyle(fixedHeight: 30)))
        host.add(dialog)
        return host
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func tooltipTurn(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget): Unit {
    @Assert(budget.begin(), true)
    try {
        let _ = window.refreshIfNeeded()
        let _ = window.pump(0u32)
        let _ = budget.finishScheduling()
    } finally { budget.end() }
}

private func tooltipAwaitScene(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget,
    minimum: Int64): Unit {
    let deadline = MonoTime.now() + 5 * Duration.second
    var turns: Int64 = 0
    while (window.isOpen() && window.windowProgress().acceptedSceneVersion < minimum &&
        window.windowProgress().pendingRefreshReason != "refresh_modal_return_prepare_refused" &&
        turns < 240 && MonoTime.now() < deadline) {
        tooltipTurn(window, budget)
        turns += 1
    }
}

@When[os == "macOS"]
@Test
func tooltipDismissWithClippedAnchorKeepsScrollFocusAndAccepts(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = TooltipReturnOwner()
        let window = CjguiComposableUiWindow(owner,
            configuration: CjguiMacosApplicationWindowConfiguration("tooltip clipped return", 480u32, 320u32))
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            tooltipAwaitScene(window, budget, 1)
            @Assert(window.windowProgress().acceptedSceneVersion >= 1, true)
            owner.tooltip.show(CjguiComposableUiNodeReference.manual(9703))
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, 2)
            @Assert(window.windowProgress().acceptedSceneVersion >= 2, true)
            @Assert(window.hasAcceptedLayer(owner.tooltip.layer()), true)
            @Assert(window.focusAcceptedNodeById(9701), true)
            let previous = window.windowProgress().acceptedSceneVersion
            @Assert(owner.viewport.requestOffset(120), true)
            @Assert(owner.viewport.acceptedOffset(), 0)
            owner.tooltip.hide()
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, previous + 1)
            let progress = window.windowProgress()
            println("TOOLTIP_RETURN_ACCEPTED before=${previous} after=${progress.acceptedSceneVersion} " +
                "pending=${progress.pendingRefreshReason} failure=${progress.lastNativeFailure} " +
                "viewport=${owner.viewport.offset()} accepted=${owner.viewport.acceptedOffset()}")
            @Assert(progress.acceptedSceneVersion > previous, true)
            @Assert(owner.viewport.acceptedOffset(), 120)
            @Assert(window.hasAcceptedLayer(owner.tooltip.layer()), false)
        } finally { budget.end(); window.close() }
    })
}

@When[os == "macOS"]
@Test
func tooltipFixKeepsInteractiveModalFocusReturn(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = TooltipReturnOwner()
        let window = CjguiComposableUiWindow(owner,
            configuration: CjguiMacosApplicationWindowConfiguration("interactive modal return", 480u32, 320u32))
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            tooltipAwaitScene(window, budget, 1)
            @Assert(window.windowProgress().acceptedSceneVersion >= 1, true)
            @Assert(window.focusAcceptedNodeById(9703), true)
            owner.dialogOpen = true
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, 2)
            @Assert(window.windowProgress().acceptedSceneVersion >= 2, true)
            @Assert(window.windowProgress().focusedControlId, "return-dialog-action")
            owner.dialogOpen = false
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, 3)
            @Assert(window.windowProgress().acceptedSceneVersion >= 3, true)
            @Assert(window.windowProgress().focusedControlId, "tooltip-anchor")
        } finally { budget.end(); window.close() }
    })
}

@When[os == "macOS"]
@Test
func tooltipFixKeepsInteractivePopupFocusReturn(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = TooltipReturnOwner()
        owner.nonmodalPopup = true
        let window = CjguiComposableUiWindow(owner,
            configuration: CjguiMacosApplicationWindowConfiguration("interactive popup return", 480u32, 320u32))
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            tooltipAwaitScene(window, budget, 1)
            @Assert(window.windowProgress().acceptedSceneVersion >= 1, true)
            @Assert(window.focusAcceptedNodeById(9703), true)
            owner.dialogOpen = true
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, 2)
            @Assert(window.windowProgress().acceptedSceneVersion >= 2, true)
            @Assert(window.hasAcceptedLayer("return-dialog-layer"), true)
            @Assert(window.windowProgress().focusedControlId, "return-dialog-action")
            owner.dialogOpen = false
            owner.revision += 1
            window.requestRefresh()
            tooltipAwaitScene(window, budget, 3)
            @Assert(window.windowProgress().acceptedSceneVersion >= 3, true)
            @Assert(window.hasAcceptedLayer("return-dialog-layer"), false)
            @Assert(window.windowProgress().focusedControlId, "tooltip-anchor")
        } finally { budget.end(); window.close() }
    })
}
