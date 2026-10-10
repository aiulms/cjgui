package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// An ordinary consumer with a default ScrollArea and two source fragments.
// Every pointer phase enters the actual native mouse path. The mapped restore
// is a real public request between that phase and another accepted publication.
private class MacRestoreContinuationController <: CjguiComposableUiController &
    CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiSelectionCompletionProvider {
    let owner = SelectionAuthorityTestOwner()
    let viewport = CjguiComposableUiScrollViewport()
    var revision: Int64 = 1
    var hideFirst: Bool = false
    var window: ?CjguiComposableUiWindow = None
    var completion: ?CjguiInstalledSelectionCompletion = None
    var pointerCommits: Int64 = 0
    var terminalPhases: Int64 = 0
    var wantsPassiveOrigin: Bool = false
    var passiveOrigin: ?CjguiComposableUiScrollOriginAnchor = None
    var passiveOriginStage: String = "none"
    let firstText: String
    init(unicodeSource!: Bool = false) {
        firstText = if (unicodeSource) { "中😀ABCDE" } else { "ABCDE" }
        owner.body.data = (firstText + "\nFGHIJ\n").toArray()
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 { return owner.body.ver }
    public func selectionInstallationCompleted(value: CjguiInstalledSelectionCompletion): Unit {
        completion = Some(value)
        if (wantsPassiveOrigin && viewport.acceptedOffset() > 0 && value.targetNodeId == 9172) {
            let binding = CjguiComposableUiScrollOriginBinding("test-authority", owner.body.ver,
                "held-source-map", "origin-A")
            let local = value.sourceSelection.focusByte - Int64(firstText.toArray().size) - 1
            // Freeze the actual ACK re-hit receipt's accepted glyph while the
            // common terminal still owns it. Staging occurs in buildUi after
            // native paint publication; this callback never reenters refresh.
            passiveOrigin = window.getOrThrow().freezeScrollOriginAnchor(viewport, 9172, local,
                "source-selection", binding)
            if (passiveOrigin.isSome()) { wantsPassiveOrigin = false; revision += 1 }
        }
    }
    public func buildUi(): CjguiComposableUiNode {
        if (let Some(origin) <- passiveOrigin) {
            passiveOriginStage = viewport.stageCoordinateOrigin(
                CjguiComposableUiScrollOriginBinding("test-authority", owner.body.ver,
                    "held-source-map", "origin-B"), anchor: Some(origin),
                targetNodeId: 9172, targetLocalByte: origin.localByte)
        }
        let root = cjguiComposableVertical(9170, "restore-capture-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 300))
        let scroll = cjguiComposableScrollArea(9180, "restore-capture-scroll", viewport,
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 220, clipsContent: true))
        let content = cjguiComposableVertical(9181, "restore-capture-content",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 500))
        if (hideFirst) {
            content.add(cjguiComposableVertical(9182, "retired-fragment-spacing",
                CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 50)))
        } else {
            content.add(cjguiComposableText(9171, "first-source-fragment", firstText,
                CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 50, fontSize: 20.0,
                    pointerInteractive: true), resourceId: 9271, fieldId: "source-0-5"))
        }
        content.add(cjguiComposableText(9172, "second-source-fragment", "FGHIJ",
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 50, fontSize: 20.0,
                pointerInteractive: true), resourceId: 9272, fieldId: "source-6-11"))
        content.add(cjguiComposableVertical(9183, "source-content-spacing",
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 400)))
        scroll.add(content); root.add(scroll)
        root.add(cjguiComposableMultilineTextInput(9174, "restore-source-owner", "Owner", owner.body.text(), 9274,
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 60), fieldId: "owned-source"))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            terminalPhases += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind < CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
            event.eventKind > CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) { return CjguiComposableUiDispatchResult(false) }
        let host = window.getOrThrow()
        let target = match (host.nearestVisibleTextNodeAtAcceptedPoint([9171, 9172],
            Float64(event.pointerX), Float64(event.pointerY))) {
            case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
        }
        let (status, local, _) = host.hitTestComposableTextDetailed(target,
            Float64(event.pointerX), Float64(event.pointerY))
        if (status != CJGUI_INTERNAL_RENDERER_OK) { return CjguiComposableUiDispatchResult(false) }
        let base = if (target == 9171) { 0 } else { Int64(firstText.toArray().size) + 1 }
        let focus = base + local
        let before = owner.sourceSelectionSnapshot()
        let anchor = if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN) { focus } else { before.anchorByte }
        let ticket = host.freezeAcceptedSelection(target).getOrThrow()
        let low = if (anchor < base) { 0 } else { anchor - base }
        let high = local
        let applied = host.submitAcceptedSourceSelection(ticket, anchor, focus,
            if (low < high) { low } else { high }, if (low > high) { low } else { high },
            { => pointerCommits += 1 })
        let accepted = match (applied) {
            case CjguiSelectionSubmission.Committed => true
            case CjguiSelectionSubmission.Retained(_) => true
            case CjguiSelectionSubmission.NotAdmitted(_) => false
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) { terminalPhases += 1 }
        return CjguiComposableUiDispatchResult(accepted)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func macRestorePoint(window: CjguiComposableUiWindow, nodeId: Int64): (Float64, Float64) {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return (Float64(node.bounds.x) + 25.0, Float64(node.bounds.y) + Float64(node.bounds.height) / 2.0)
        }
    }
    @Assert(false, true)
    return (0.0, 0.0)
}

private func macRestorePump(window: CjguiComposableUiWindow, ready: () -> Bool): Unit {
    var now = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout now) }
    let deadline = now + 3000000u64
    while (!ready() && now < deadline) {
        let _ = window.pump(0u32)
        let _ = window.refreshIfNeeded()
        let _ = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout now) }
    }
    @Assert(ready(), true)
}

private func macTextMappedRestoreScenario(successor: Int64, sourceCoordinatesAreBytes!: Bool = true,
    unicodeSource!: Bool = false, retireWithoutViewportAck!: Bool = false): Unit {
    let controller = MacRestoreContinuationController(unicodeSource: unicodeSource)
    let originalBody = controller.owner.body.text()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI held source restore", 980u32, 620u32,
            rangeTextEditDeltaDelivery: true))
    controller.window = Some(window)
    try {
        let _ = window.bindRangeTextSession(9174, "held-source-restore", controller.owner, controller.owner,
            9274, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let initial = window.requestTextSelectionRestore(9174, 9274, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,
            controller.owner.body.text(), 0, 0)
        @Assert(initial > 0, true)
        macRestorePump(window, { => window.selectionRestoreState(initial) != "pending" })
        @Assert(window.selectionRestoreState(initial), "installed")
        let (x, y) = macRestorePoint(window, 9171)
        @Assert(unsafe { cjgui_internal_renderer_test_begin_composable_pointer(window.testSessionToken(),
            9171u64, x, y) }, CJGUI_INTERNAL_RENDERER_OK)
        let gesture = unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }
        @Assert(gesture > 0u64, true)
        macRestorePump(window, { => controller.pointerCommits == 1 })
        let (nextX, nextY) = macRestorePoint(window, 9172)
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            2u32, nextX, nextY) }, CJGUI_INTERNAL_RENDERER_OK)
        macRestorePump(window, { => controller.pointerCommits == 2 })
        let installed = controller.completion.getOrThrow()
        @Assert(installed.targetNodeId, 9172)
        let choice = installed.sourceSelection
        let requestedAnchor = if (successor == 3) { choice.focusByte } else { choice.anchorByte }
        let sourceAnchor = if (sourceCoordinatesAreBytes) { requestedAnchor } else {
            cjguiUtf8OffsetToUtf16(originalBody, requestedAnchor).getOrThrow()
        }
        let sourceFocus = if (sourceCoordinatesAreBytes) { choice.focusByte } else {
            cjguiUtf8OffsetToUtf16(originalBody, choice.focusByte).getOrThrow()
        }
        let restore = window.requestAcceptedSelectionRestore(window.freezeAcceptedSelection(9172).getOrThrow(),
            sourceAnchor, sourceFocus, installed.targetSelectionStart16, installed.targetSelectionEnd16,
            { => }, sourceCoordinatesAreBytes: sourceCoordinatesAreBytes)
        @Assert(restore > 0, true)
        if (successor == 1) {
            // A same-value new choice has a distinct authority revision. The
            // pending request must not turn it into the old pointer's choice.
            @Assert(controller.owner.setSourceSelection(choice.version, choice.anchorByte, choice.focusByte), true)
        } else if (successor == 2) {
            let _ = controller.owner.body.applyRangeTextEdit(choice.version, 0, 0, "Q")
        }
        let successorChoice = controller.owner.sourceSelectionSnapshot()
        macRestorePump(window, { => window.selectionRestoreState(restore) != "pending" })
        if (successor == 1 || successor == 2) {
            @Assert(window.selectionRestoreState(restore) != "installed", true)
            @Assert(controller.owner.revision, successorChoice.revision)
            @Assert(controller.owner.anchor, successorChoice.anchorByte)
            @Assert(controller.owner.focus, successorChoice.focusByte)
            controller.hideFirst = true; controller.revision += 1
            @Assert(window.refresh(), true)
            @Assert(window.pointerCaptureActiveForTest(), false)
            @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, 0u64)
            @Assert(controller.owner.body.text(), if (successor == 2) { "Q" + originalBody } else { originalBody })
            println("MAC_TEXT_RESTORE_RETIRED successor=${successor} old_completion_zero_write=true old_gesture_retired=true")
            return
        }
        @Assert(window.selectionRestoreState(restore), "installed")
        @Assert(controller.completion.getOrThrow().transferId != installed.transferId, true)
        @Assert(controller.owner.anchor, requestedAnchor)
        @Assert(controller.owner.focus, choice.focusByte)
        // A virtualized replacement needs a real accepted viewport ACK. A
        // forced cull without that proof must retire this physical gesture.
        controller.hideFirst = retireWithoutViewportAck
        controller.revision += 1
        @Assert(window.refresh(), true)
        if (successor == 3) {
            @Assert(window.pointerCaptureActiveForTest(), false)
            @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, 0u64)
            @Assert(controller.owner.body.text(), originalBody)
            println("MAC_TEXT_RESTORE_NEW_CHOICE installed=true inherited_old_dispatch=false owner_unchanged=true")
            return
        }
        if (retireWithoutViewportAck) {
            @Assert(window.pointerCaptureActiveForTest(), false)
            @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, 0u64)
            @Assert(controller.owner.body.text(), originalBody)
            println("MAC_TEXT_RESTORE_UNPROVED_CULL refused=true owner_unchanged=true viewport_ack=false")
            return
        }
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, gesture)
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            2u32, nextX + 15.0, nextY) }, CJGUI_INTERNAL_RENDERER_OK)
        macRestorePump(window, { => controller.pointerCommits == 3 })
        @Assert(controller.owner.anchor, choice.anchorByte)
        @Assert(controller.owner.body.text(), originalBody)
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            3u32, nextX + 15.0, nextY) }, CJGUI_INTERNAL_RENDERER_OK)
        macRestorePump(window, { => !window.pointerCaptureActiveForTest() })
        @Assert(unsafe { cjgui_internal_renderer_test_pointer_edge_active(window.testSessionToken()) }, 0)
        println("MAC_TEXT_RESTORE_CONTINUATION real_down=true original_gesture=${gesture} mapped_receipt=true owner_unchanged=true up_stops=true")
    } finally { window.close() }
}

@Test
func macTextMappedRestoreKeepsOriginalPointerInstalledReceipt(): Unit { macTextMappedRestoreScenario(0) }

@Test
func macTextRepeatRestoreAfterAcceptedOriginCaptureMigrationRetainsReceipt(): Unit {
    let controller = MacRestoreContinuationController()
    let body = controller.owner.body.text()
    let bindingA = CjguiComposableUiScrollOriginBinding("test-authority", controller.owner.body.ver,
        "held-source-map", "origin-A")
    @Assert(controller.viewport.stageCoordinateOrigin(bindingA), "scroll_origin_initial")
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI repeat held restore", 980u32, 620u32,
            rangeTextEditDeltaDelivery: true))
    controller.window = Some(window)
    try {
        let _ = window.bindRangeTextSession(9174, "held-source-repeat", controller.owner, controller.owner,
            9274, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let initial = window.requestTextSelectionRestore(9174, 9274, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,
            body, 0, 0)
        macRestorePump(window, { => window.selectionRestoreState(initial) != "pending" })
        @Assert(window.selectionRestoreState(initial), "installed")
        let (x, y) = macRestorePoint(window, 9171)
        @Assert(unsafe { cjgui_internal_renderer_test_begin_composable_pointer(window.testSessionToken(),
            9171u64, x, y) }, CJGUI_INTERNAL_RENDERER_OK)
        let gesture = unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }
        macRestorePump(window, { => controller.pointerCommits == 1 })
        let (nextX, nextY) = macRestorePoint(window, 9172)
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            2u32, nextX, nextY) }, CJGUI_INTERNAL_RENDERER_OK)
        macRestorePump(window, { => controller.pointerCommits == 2 })
        // One actual move into the edge starts residence. There is no further
        // physical event between the accepted origin and the repeated restore.
        let (_, scrollY) = macRestorePoint(window, 9180)
        let serialBefore = window.macTextCaptureSerialForTest()
        controller.wantsPassiveOrigin = true
        @Assert(unsafe { cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
            2u32, nextX, scrollY + 125.0) }, CJGUI_INTERNAL_RENDERER_OK)
        macRestorePump(window, { => controller.viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin ==
            "origin-B" && window.macTextCaptureSerialForTest() > serialBefore })
        let receipt = controller.completion.getOrThrow()
        let choice = receipt.sourceSelection
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, gesture)
        println("MAC_TEXT_REPEAT_RESTORE stage=migrated serial=${serialBefore}->${window.macTextCaptureSerialForTest()} " +
            "gesture=${gesture} transfer=${receipt.transferId}")
        let commitsBefore = controller.pointerCommits
        let repeat = window.requestAcceptedSelectionRestore(window.freezeAcceptedSelection(9172).getOrThrow(),
            choice.anchorByte, choice.focusByte, receipt.targetSelectionStart16, receipt.targetSelectionEnd16, { => })
        @Assert(repeat > 0, true)
        macRestorePump(window, { => window.selectionRestoreState(repeat) != "pending" })
        @Assert(window.selectionRestoreState(repeat), "installed")
        @Assert(controller.completion.getOrThrow().transferId != receipt.transferId, true)
        controller.revision += 1
        @Assert(window.refresh(), true)
        let _ = window.pump(0u32)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(unsafe { cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }, gesture)
        @Assert(controller.pointerCommits, commitsBefore)
        @Assert(controller.owner.body.text(), body)
        @Assert(controller.owner.body.writeCalls, 0)
        println("MAC_TEXT_REPEAT_RESTORE stage=repeat original_gesture=true actual_successor=true " +
            "same_choice=true no_new_pointer_event=true owner_zero_write=true")
    } finally { window.close() }
}

@Test
func macTextMappedRestoreSameValueNewChoiceRetiresOldGesture(): Unit { macTextMappedRestoreScenario(1) }

@Test
func macTextMappedRestoreOwnerEditRetiresOldGesture(): Unit { macTextMappedRestoreScenario(2) }

@Test
func macTextMappedRestoreNewDirectedChoiceCannotInheritOldGesture(): Unit { macTextMappedRestoreScenario(3) }

// The normal Pharos SourceMap handoff uses the mirror UTF-16 overload.
@Test
func macTextMappedUtf16RestoreKeepsOriginalPointerInstalledReceipt(): Unit {
    macTextMappedRestoreScenario(0, sourceCoordinatesAreBytes: false)
}
@Test
func macTextMappedUtf16RestoreSameValueNewChoiceRetiresOldGesture(): Unit {
    macTextMappedRestoreScenario(1, sourceCoordinatesAreBytes: false)
}
@Test
func macTextMappedUtf16RestoreOwnerEditRetiresOldGesture(): Unit {
    macTextMappedRestoreScenario(2, sourceCoordinatesAreBytes: false)
}
@Test
func macTextMappedUtf16RestoreNewDirectedChoiceCannotInheritOldGesture(): Unit {
    macTextMappedRestoreScenario(3, sourceCoordinatesAreBytes: false)
}
@Test
func macTextMappedUtf16UnicodeRestoreUsesExactSourceEndpoints(): Unit {
    macTextMappedRestoreScenario(0, sourceCoordinatesAreBytes: false, unicodeSource: true)
}

@Test
func macTextMappedRestoreWithoutViewportAckRefusesUnprovedCull(): Unit {
    macTextMappedRestoreScenario(0, retireWithoutViewportAck: true)
}
@Test
func macTextMappedUtf16RestoreWithoutViewportAckRefusesUnprovedCull(): Unit {
    macTextMappedRestoreScenario(0, sourceCoordinatesAreBytes: false, retireWithoutViewportAck: true)
}
