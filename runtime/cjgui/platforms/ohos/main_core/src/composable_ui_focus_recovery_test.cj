package cjgui

import std.collection.*

private class ProductionFocusRecoveryController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var resourceId: Int64 = 9901
    var includeCommand: Bool = false
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9900, "focus-recovery-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(9901, "focus-recovery-editor", "Editor", "draft", resourceId,
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 36)))
        if (includeCommand) {
            root.add(cjguiComposableButton(9902, "focus-recovery-command", "Command", "COMMAND", 9902,
                CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 30)))
        }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(includeCommand && event.node.nodeId == 9902)
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

@Test
func productionBoundCommandPreservesItsExistingTextFocus(): Unit {
    let controller = ProductionFocusRecoveryController()
    controller.includeCommand = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let statuses = ArrayList<Int32>()
    statuses.add(CJGUI_INTERNAL_RENDERER_OK)
    window.setFocusNativeStatusesForTest(statuses)
    @Assert(window.focusAcceptedSemanticNode("focus-recovery-editor"), true)
    @Assert(window.focusedNodeIdForTest(), 9901)
    @Assert(window.declareCommand(CjguiComposableUiCommand("focus-command", 9902,
        CjguiComposableUiShortcut("z"))), true)
    @Assert(window.invokeCommand("focus-command"), true)
    @Assert(window.focusedNodeIdForTest(), 9901)
    window.close()
}

@Test
func semanticFocusRetriesNativeFailureThenSettlesOnRecovery(): Unit {
    @Assert(cjguiFocusNativeFailureIsRetryable(CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD), true)
    @Assert(cjguiFocusNativeFailureIsRetryable(CJGUI_INTERNAL_RENDERER_INVALID_SESSION), false)
    var attempts = cjguiFocusNextAttemptCount(0, false)
    @Assert(attempts, 1)
    @Assert(cjguiFocusRetryAllowed(attempts, false), true)

    attempts = cjguiFocusNextAttemptCount(attempts, false)
    @Assert(attempts, 2)
    @Assert(cjguiFocusRetryAllowed(attempts, false), true)

    attempts = cjguiFocusNextAttemptCount(attempts, false)
    @Assert(attempts, 3)
    @Assert(cjguiFocusRetryAllowed(attempts, false), false)

    // A later native success clears the retained failure count and closes the
    // pending request; the successful attempt never schedules another retry.
    attempts = cjguiFocusNextAttemptCount(attempts, true)
    @Assert(attempts, 0)
    @Assert(cjguiFocusRetryAllowed(attempts, true), false)
}

@Test
func semanticFocusRequiresPositiveIntersectionAcrossEveryAncestorClip(): Unit {
    let target = CjguiComposableUiRect(30, 30, 40, 20)
    let clips = ArrayList<CjguiComposableUiClipConstraint>()
    clips.add(CjguiComposableUiClipConstraint(CjguiComposableUiRect(20, 20, 100, 100)))
    clips.add(CjguiComposableUiClipConstraint(CjguiComposableUiRect(0, 0, 25, 25)))

    let hidden = cjguiFocusVisibleIntersection(target, clips)
    @Assert(hidden.width, 0)
    @Assert(hidden.height, 0)

    let _ = clips.remove(at: 1)
    clips.add(CjguiComposableUiClipConstraint(CjguiComposableUiRect(40, 35, 30, 30)))
    let partiallyVisible = cjguiFocusVisibleIntersection(target, clips)
    @Assert(partiallyVisible.width, 30)
    @Assert(partiallyVisible.height, 15)
}

@Test
func semanticFocusRejectsAcceptedBindingAba(): Unit {
    let requestEpoch: UInt64 = 41u64
    let replacementEpoch: UInt64 = 42u64
    let restoredTextEpoch: UInt64 = 43u64
    @Assert(cjguiFocusBindingEpochMatches(requestEpoch, replacementEpoch), false)
    @Assert(cjguiFocusBindingEpochMatches(requestEpoch, restoredTextEpoch), false)
    @Assert(cjguiFocusBindingEpochMatches(requestEpoch, requestEpoch), true)
}

@Test
func productionSemanticFocusRetainsNativeFailureAndSettlesOnAcceptedRefresh(): Unit {
    let window = CjguiComposableUiWindow(ProductionFocusRecoveryController())
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)

    let statuses = ArrayList<Int32>()
    statuses.add(CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD)
    statuses.add(CJGUI_INTERNAL_RENDERER_OK)
    window.setFocusNativeStatusesForTest(statuses)

    @Assert(window.focusAcceptedSemanticNode("focus-recovery-editor"), false)
    @Assert(window.hasPendingSemanticFocusForTest(), true)
    @Assert(window.focusNativeCallsForTest(), 1)
    @Assert(window.focusedNodeIdForTest(), -1)

    @Assert(window.refresh(), true)
    @Assert(window.hasPendingSemanticFocusForTest(), false)
    @Assert(window.focusNativeCallsForTest(), 2)
    @Assert(window.focusedNodeIdForTest() > 0, true)
    window.close()
}

@Test
func productionPendingSemanticFocusRejectsAcceptedBindingAba(): Unit {
    let controller = ProductionFocusRecoveryController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)

    let statuses = ArrayList<Int32>()
    statuses.add(CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD)
    statuses.add(CJGUI_INTERNAL_RENDERER_OK)
    window.setFocusNativeStatusesForTest(statuses)
    @Assert(window.focusAcceptedSemanticNode("focus-recovery-editor"), false)
    @Assert(window.hasPendingSemanticFocusForTest(), true)
    @Assert(window.focusNativeCallsForTest(), 1)

    controller.resourceId = 9902
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.hasPendingSemanticFocusForTest(), false)
    @Assert(window.focusNativeCallsForTest(), 1)
    @Assert(window.focusedNodeIdForTest(), -1)
    window.close()
}
