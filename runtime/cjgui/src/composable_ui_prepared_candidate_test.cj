package cjgui

import std.collection.*

foreign {
    func cjgui_internal_renderer_test_composable_selection(
        session: UInt64, outSelectionStart: CPointer<UInt32>, outSelectionEnd: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_source_proxy_preparation_state(
        session: UInt64, requestId: UInt64, nodeId: UInt64, resourceId: UInt32, nodeKind: UInt32,
        expectedValue: CString, selectionStart: UInt32, selectionEnd: UInt32,
        outState: CPointer<UInt8>, outSessionGeneration: CPointer<UInt64>,
        outBindingEpoch: CPointer<UInt64>, outSceneVersion: CPointer<UInt64>,
        outActualRequestId: CPointer<UInt64>, outActualSelectionStart: CPointer<UInt32>,
        outActualSelectionEnd: CPointer<UInt32>, outPhase: CPointer<UInt32>,
        outCharacterCursor: CPointer<UInt32>, outTileCursor: CPointer<UInt32>
    ): Int32
}

let PACED_SOURCE_PROXY_ABSENT: UInt8 = 0u8
private let PACED_SOURCE_PROXY_PREPARING_EXACT: UInt8 = 1u8
private let PACED_SOURCE_PROXY_READY_EXACT: UInt8 = 2u8
private let PACED_SOURCE_PROXY_MISMATCH: UInt8 = 3u8

private class PacedCandidateController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    var revision: Int64 = 1
    var value: String = "accepted old body"
    var candidate: String = ""
    var accepted: String = ""
    var builds: Int64 = 0
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    var inputCount: Int64 = 0
    public func uiSceneVersion(): Int64 { return revision }
    public func beginSceneRefresh(): Bool { return true }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        candidate = value
        let root = cjguiComposableVertical(9881, "paced-root", CjguiComposableUiStyle())
        root.add(cjguiComposableText(9882, "paced-body", candidate,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 80)))
        root.add(cjguiComposableButton(9883, "paced-action", "Accepted action", "ACCEPTED_ACTION", 1,
            CjguiComposableUiStyle()))
        return root
    }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func commitSceneRefresh(): Unit { accepted = candidate; commits += 1 }
    public func rollbackSceneRefresh(): Unit { candidate = ""; rollbacks += 1 }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 9883 && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            inputCount += 1
            value = "accepted input while preparing"
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

/// A normal multiline owner-backed scene for the result()/selection-restore
/// boundary regression. The document owner, rather than a copied controller
/// value, remains the source of every candidate body.
private func focusSelectionRestoreFixture(window: CjguiComposableUiWindow): Bool {
    let focused = window.focusAcceptedNodeById(9891)
    if (!focused) {
        let progress = window.windowProgress()
        println("SELECTION_RESTORE_FIXTURE_FOCUS reason=${progress.lastNativeFailure} " +
            "accepted=${progress.acceptedSceneVersion} pending=${progress.pendingRefreshReason}")
    }
    return focused
}

private class SelectionRestorePacedController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let owner: FakeTextOwner
    var revision: Int64 = 1
    var candidate: String = ""
    var accepted: String = ""
    var builds: Int64 = 0
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    var companionHeight: Int64 = 22
    var companion: String = "accepted companion"

    init(owner: FakeTextOwner) { this.owner = owner }

    public func uiSceneVersion(): Int64 { return revision }
    public func beginSceneRefresh(): Bool { return true }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        candidate = owner.text()
        let root = cjguiComposableVertical(9890, "selection-restore-root", CjguiComposableUiStyle())
        root.add(cjguiComposableText(9892, "selection-restore-companion", companion,
            CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: companionHeight)))
        root.add(cjguiComposableMultilineTextInput(9891, "selection-restore-body", "Document", candidate, 9891,
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 180)))
        return root
    }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func commitSceneRefresh(): Unit { accepted = candidate; commits += 1 }
    public func rollbackSceneRefresh(): Unit { candidate = ""; rollbacks += 1 }
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

// Native preparation consumes the same real owner clock as production. A
// candidate may need several bounded turns, but must never rebuild or publish
// its body until preparation and the original acceptance have both completed.
private func finishPacedCandidate(window: CjguiComposableUiWindow,
    budget: CjguiOwnerTurnBudget): Bool {
    var turn: Int64 = 0
    while (turn < 48) {
        if (!budget.begin()) { return false }
        let accepted = window.refreshIfNeeded()
        let _ = window.pump(0u32)
        budget.end()
        if (accepted) { return true }
        if (!budget.hasPreparedWork()) { return false }
        turn += 1
    }
    return false
}

// Use the same owner-turn order as the host: refresh/preparation first, then
// pump so result() and its pending selection restore run in that turn.
private func runPacedOwnerTurn(window: CjguiComposableUiWindow,
    budget: CjguiOwnerTurnBudget): Bool {
    if (!budget.begin()) { return false }
    let _ = window.refreshIfNeeded()
    let _ = window.pump(0u32)
    budget.end()
    return true
}

private func runPacedOwnerTurnWithLivePreparation(window: CjguiComposableUiWindow,
    budget: CjguiOwnerTurnBudget): Bool {
    if (!budget.begin()) { return false }
    let _ = window.refreshIfNeeded()
    let preparingAtPump = budget.hasPreparedWork()
    let _ = window.pump(0u32)
    budget.end()
    return preparingAtPump
}

private func readPacedNativeSelection(window: CjguiComposableUiWindow): (Int32, UInt32, UInt32) {
    var start: UInt32 = 0u32
    var end: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_test_composable_selection(
        window.testSessionToken(), inout start, inout end) }
    return (status, start, end)
}

class PacedSourceProxyPreparationSnapshot {
    let status: Int32
    let state: UInt8
    let sessionGeneration: UInt64
    let bindingEpoch: UInt64
    let sceneVersion: UInt64
    let requestId: UInt64
    let selectionStart: UInt32
    let selectionEnd: UInt32
    let phase: UInt32
    let characterCursor: UInt32
    let tileCursor: UInt32

    init(status: Int32, state: UInt8, sessionGeneration: UInt64, bindingEpoch: UInt64,
        sceneVersion: UInt64, requestId: UInt64, selectionStart: UInt32, selectionEnd: UInt32,
        phase: UInt32, characterCursor: UInt32, tileCursor: UInt32) {
        this.status = status
        this.state = state
        this.sessionGeneration = sessionGeneration
        this.bindingEpoch = bindingEpoch
        this.sceneVersion = sceneVersion
        this.requestId = requestId
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.phase = phase
        this.characterCursor = characterCursor
        this.tileCursor = tileCursor
    }
}

func readPacedSourceProxyPreparation(window: CjguiComposableUiWindow, requestId: Int64,
    expectedValue: String, selectionStart: UInt32, selectionEnd: UInt32,
    nodeId!: UInt64 = 9891u64, resourceId!: UInt32 = 9891u32): PacedSourceProxyPreparationSnapshot {
    var state: UInt8 = PACED_SOURCE_PROXY_ABSENT
    var sessionGeneration: UInt64 = 0u64
    var bindingEpoch: UInt64 = 0u64
    var sceneVersion: UInt64 = 0u64
    var actualRequestId: UInt64 = 0u64
    var actualSelectionStart: UInt32 = 0u32
    var actualSelectionEnd: UInt32 = 0u32
    var phase: UInt32 = 0u32
    var characterCursor: UInt32 = 0u32
    var tileCursor: UInt32 = 0u32
    let cExpectedValue = unsafe { LibC.mallocCString(expectedValue) }
    let status = unsafe {
        cjgui_internal_renderer_test_composable_source_proxy_preparation_state(
            window.testSessionToken(), UInt64(requestId), nodeId, resourceId,
            UInt32(CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT), cExpectedValue,
            selectionStart, selectionEnd, inout state, inout sessionGeneration,
            inout bindingEpoch, inout sceneVersion, inout actualRequestId,
            inout actualSelectionStart, inout actualSelectionEnd, inout phase,
            inout characterCursor, inout tileCursor)
    }
    unsafe { LibC.free(cExpectedValue) }
    return PacedSourceProxyPreparationSnapshot(status, state, sessionGeneration, bindingEpoch,
        sceneVersion, actualRequestId, actualSelectionStart, actualSelectionEnd,
        phase, characterCursor, tileCursor)
}

func assertPacedSourceProxyPreparationIdentity(snapshot: PacedSourceProxyPreparationSnapshot,
    requestId: Int64, selectionStart: UInt32, selectionEnd: UInt32): Unit {
    @Assert(snapshot.status, CJGUI_INTERNAL_RENDERER_OK)
    @Assert(snapshot.state == PACED_SOURCE_PROXY_PREPARING_EXACT ||
        snapshot.state == PACED_SOURCE_PROXY_READY_EXACT, true)
    @Assert(snapshot.sessionGeneration > 0u64, true)
    @Assert(snapshot.bindingEpoch > 0u64, true)
    @Assert(snapshot.sceneVersion > 0u64, true)
    @Assert(snapshot.requestId, UInt64(requestId))
    @Assert(snapshot.selectionStart, selectionStart)
    @Assert(snapshot.selectionEnd, selectionEnd)
}

private func preparePacedSourceProxyWithoutAdopting(window: CjguiComposableUiWindow,
    budget: CjguiOwnerTurnBudget, controller: SelectionRestorePacedController, requestId: Int64,
    expectedValue: String, selectionStart: UInt32, selectionEnd: UInt32,
    nativeBefore: (Int32, UInt32, UInt32)): PacedSourceProxyPreparationSnapshot {
    var snapshot = readPacedSourceProxyPreparation(window, requestId, expectedValue,
        selectionStart, selectionEnd)
    @Assert(snapshot.status, CJGUI_INTERNAL_RENDERER_OK)
    let startedAbsent = snapshot.state == PACED_SOURCE_PROXY_ABSENT
    if (!startedAbsent) {
        assertPacedSourceProxyPreparationIdentity(snapshot, requestId, selectionStart, selectionEnd)
    }
    var turns: Int64 = 0
    while (turns < 48 && snapshot.state != PACED_SOURCE_PROXY_READY_EXACT) {
        let before = snapshot
        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(window.selectionRestoreState(requestId), "pending")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", expectedValue)
        @Assert(controller.builds, 1)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        let nativeWhilePreparing = readPacedNativeSelection(window)
        @Assert(nativeWhilePreparing[0], nativeBefore[0])
        @Assert(nativeWhilePreparing[1], nativeBefore[1])
        @Assert(nativeWhilePreparing[2], nativeBefore[2])
        snapshot = readPacedSourceProxyPreparation(window, requestId, expectedValue,
            selectionStart, selectionEnd)
        assertPacedSourceProxyPreparationIdentity(snapshot, requestId, selectionStart, selectionEnd)
        let advanced = snapshot.state != before.state || snapshot.phase != before.phase ||
            snapshot.characterCursor != before.characterCursor || snapshot.tileCursor != before.tileCursor
        @Assert(advanced, true)
        turns += 1
    }
    if (startedAbsent) { @Assert(turns > 0, true) }
    @Assert(snapshot.state, PACED_SOURCE_PROXY_READY_EXACT)
    @Assert(window.selectionRestoreState(requestId), "pending")
    @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", expectedValue)
    @Assert(controller.builds, 1)
    @Assert(controller.commits, 1)
    @Assert(controller.rollbacks, 0)
    let nativeAfterPreparation = readPacedNativeSelection(window)
    @Assert(nativeAfterPreparation[0], nativeBefore[0])
    @Assert(nativeAfterPreparation[1], nativeBefore[1])
    @Assert(nativeAfterPreparation[2], nativeBefore[2])
    return snapshot
}

@Test
func testPacedCandidateAcceptedNativeInputCancelsPreparationWithoutFreezingFifo(): Unit {
    let controller = PacedCandidateController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        controller.value = "candidate before accepted input"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        @Assert(budget.hasPreparedWork(), true)
        @Assert(window.refreshIfNeeded(), false)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        budget.end()
        let token = window.testSessionToken()
        @Assert(unsafe { cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
            token, 9883u64) }, 0)
        @Assert(unsafe { cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(token) }, 0)
        @Assert(budget.begin(), true)
        let turn = window.pump(0u32)
        budget.end()
        @Assert(turn.didApplyHumanAction, true)
        @Assert(controller.inputCount, 1)
        @Assert(controller.rollbacks, 1)
        @Assert(controller.commits, 1)
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted old body")
        @Assert(finishPacedCandidate(window, budget), true)
        @Assert(budget.hasPreparedWork(), false)
        @Assert(controller.inputCount, 1)
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted input while preparing")
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateNativeFailureKeepsAcceptedBodyAndReleasesCandidate(): Unit {
    let controller = PacedCandidateController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        controller.value = "candidate that will fail"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(unsafe { cjgui_internal_renderer_test_set_composable_present_failures(
            window.testSessionToken(), 1u32) }, 0)
        @Assert(finishPacedCandidate(window, budget), false)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 1)
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted old body")
        window.close()
        @Assert(controller.rollbacks, 1)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateKeepsAcceptedBodyAndBuildsOnlyOnceAcrossOwnerTurns(): Unit {
    let controller = PacedCandidateController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        // This fixture first proves its accepted baseline, then budgets the change under test.
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        let oldScene = window.displayedSceneVersion()
        controller.value = "new frozen candidate"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        @Assert(controller.accepted, "accepted old body")
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted old body")
        @Assert(window.displayedSceneVersion(), oldScene)
        @Assert(finishPacedCandidate(window, budget), true)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.accepted, "new frozen candidate")
        @Assert(window.acceptedNodeText("paced-body") ?? "", "new frozen candidate")
    } finally { budget.end(); window.close() }
}

private class PacedReadyTestWorkCharge {
    var enabled: Bool = true
}

// The real preparation must reach Ready, then the SAME complete owner budget
// must admit the indivisible staging/present/accept tail. The test clock adds
// known work only once the actual native resources are ready; it does not
// manufacture a ready packet, present receipt or source credential.
@Test
func testPacedReadyCandidateRetainsOriginalWhenSubmitBudgetIsSpent(): Unit {
    let controller = PacedCandidateController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    let chargeReadyWork = PacedReadyTestWorkCharge()
    budget.testUseClock({ =>
        let actual = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        return if (chargeReadyWork.enabled && window.testPreparedCandidateReady()) {
            actual + 10000000
        } else { actual }
    })
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        let oldScene = window.displayedSceneVersion()
        controller.value = "ready candidate with spent submit allowance"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        var turn: Int64 = 0
        while (!window.testPreparedCandidateReady() && turn < 48) {
            @Assert(budget.begin(), true)
            @Assert(window.refreshIfNeeded(), false)
            budget.end()
            turn += 1
        }
        @Assert(window.testPreparedCandidateReady(), true)
        @Assert(budget.hasPreparedWork(), true)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        @Assert(window.displayedSceneVersion(), oldScene)
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted old body")
        chargeReadyWork.enabled = false
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), true)
        budget.end()
        @Assert(budget.hasPreparedWork(), false)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)
        @Assert(window.acceptedNodeText("paced-body") ?? "", controller.value)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateOwnerAdvanceRejectsOldPreparationAndCloseReleasesOnce(): Unit {
    let controller = PacedCandidateController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        controller.value = "stale candidate"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        controller.value = "new owner body"
        controller.revision += 1
        @Assert(budget.begin(), true)
        @Assert(window.refreshIfNeeded(), false)
        budget.end()
        @Assert(controller.rollbacks, 1)
        @Assert(controller.commits, 1)
        @Assert(window.acceptedNodeText("paced-body") ?? "", "accepted old body")
        window.close()
        @Assert(controller.rollbacks, 2)
        window.close()
        @Assert(controller.rollbacks, 2)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateResultSelectionRestoreDoesNotCancelExternalOwnerRefresh(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    owner.bumpVersionOnly()
    owner.bumpVersionOnly()
    owner.bumpVersionOnly()
    @Assert(owner.ver, 4)

    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        @Assert(window.focusedNodeIdForTest(), 9891)

        // A normal accepted plain delete advances the owner from v4 to v5.
        session.setSelection16(5, 5)
        let deleted = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
        @Assert(deleted.handled, true)
        @Assert(deleted.wroteOwner, true)
        @Assert(owner.ver, 5)
        @Assert(owner.text(), "row ne\nrow two\n")
        @Assert(session.needsNativeSelectionRestore(), true)

        // An independent owner insertion rebases the caret and requires a
        // native restore against the next accepted multiline projection.
        owner.externalWrite(0, 0, "<agent>\n")
        @Assert(session.refreshMirror(), true)
        @Assert(owner.ver, 6)
        @Assert(session.needsNativeSelectionRestore(), true)
        @Assert(session.selection16()[0], 12)
        @Assert(session.selection16()[1], 12)
        controller.revision += 1
        window.requestRefresh()

        let expected = owner.text()
        var acceptedAndRestored = false
        var turns: Int64 = 0
        while (turns < 48 && !acceptedAndRestored) {
            if (turns == 0) {
                @Assert(runPacedOwnerTurnWithLivePreparation(window, budget), true)
            } else {
                @Assert(runPacedOwnerTurn(window, budget), true)
            }
            acceptedAndRestored = (window.acceptedNodeValue("selection-restore-body") ?? "") == expected &&
                !session.needsNativeSelectionRestore()
            turns += 1
        }

        @Assert(acceptedAndRestored, true)
        @Assert(turns < 48, true)
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", expected)
        @Assert(owner.text(), expected)
        @Assert(owner.ver, 6)
        @Assert(session.selection16()[0], 12)
        @Assert(session.selection16()[1], 12)
        @Assert(session.needsNativeSelectionRestore(), false)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)

        let native = readPacedNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 12u32)
        @Assert(native[2], 12u32)

        // A settled turn must not rebuild, roll back, or repeat the selection
        // restore after the one accepted owner identity has been installed.
        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)
        @Assert(session.needsNativeSelectionRestore(), false)
        let settledNative = readPacedNativeSelection(window)
        @Assert(settledNative[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(settledNative[1], 12u32)
        @Assert(settledNative[2], 12u32)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidatePendingSelectionCanInstallAgainstOldAcceptedScene(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        session.setSelection16(2, 4)
        let requestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 4)
        @Assert(requestId > 0, true)

        // This regression isolates candidate cancellation from the separate
        // cold source-proxy resource phases. Keep the same real request ticket
        // pending until native reports its exact preparation ready; every
        // preparation-only turn uses the ordinary owner/FIFO path.
        let nativeBeforePreparation = readPacedNativeSelection(window)
        @Assert(nativeBeforePreparation[0], CJGUI_INTERNAL_RENDERER_OK)
        let _ = preparePacedSourceProxyWithoutAdopting(window, budget, controller,
            requestId, owner.text(), 2u32, 4u32, nativeBeforePreparation)

        // Change a sibling declaration so E has a live candidate while the
        // same ready native ticket still matches the old accepted text node.
        controller.companion = "candidate companion"
        controller.revision += 1
        window.requestRefresh()
        @Assert(runPacedOwnerTurn(window, budget), true)

        @Assert(window.selectionRestoreState(requestId), "installed")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 1)
        let native = readPacedNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 2u32)
        @Assert(native[2], 4u32)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedColdSelectionRestoreWaitsForExactSourceProxyPreparation(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        session.setSelection16(2, 4)
        let requestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 4)
        @Assert(requestId > 0, true)
        let nativeBefore = readPacedNativeSelection(window)
        @Assert(nativeBefore[0], CJGUI_INTERNAL_RENDERER_OK)

        let absent = readPacedSourceProxyPreparation(window, requestId, owner.text(), 2u32, 4u32)
        @Assert(absent.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(absent.state, PACED_SOURCE_PROXY_ABSENT)

        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(window.selectionRestoreState(requestId), "pending")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        @Assert(controller.builds, 1)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        let first = readPacedSourceProxyPreparation(window, requestId, owner.text(), 2u32, 4u32)
        assertPacedSourceProxyPreparationIdentity(first, requestId, 2u32, 4u32)
        @Assert(first.state, PACED_SOURCE_PROXY_PREPARING_EXACT)
        @Assert(first.phase, 0u32)
        @Assert(first.characterCursor, 0u32)
        @Assert(first.tileCursor, 0u32)
        let nativeAfterFirst = readPacedNativeSelection(window)
        @Assert(nativeAfterFirst[1], nativeBefore[1])
        @Assert(nativeAfterFirst[2], nativeBefore[2])

        // Each normal owner turn advances one actual native preparation unit.
        // Even the unit that sets ready returns pending; adoption is a later
        // call with this same request ID.
        let ready = preparePacedSourceProxyWithoutAdopting(window, budget, controller,
            requestId, owner.text(), 2u32, 4u32, nativeBefore)
        @Assert(ready.state, PACED_SOURCE_PROXY_READY_EXACT)
        @Assert(window.selectionRestoreState(requestId), "pending")
        let nativeBeforeAdopt = readPacedNativeSelection(window)
        @Assert(nativeBeforeAdopt[1], nativeBefore[1])
        @Assert(nativeBeforeAdopt[2], nativeBefore[2])

        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(window.selectionRestoreState(requestId), "installed")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        @Assert(controller.builds, 1)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        let native = readPacedNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 2u32)
        @Assert(native[2], 4u32)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedReadyColdPreparationCannotAdoptAfterSameBodySelectionSupersedesIt(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        session.setSelection16(2, 4)
        let oldRequestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 4)
        @Assert(oldRequestId > 0, true)
        let nativeBefore = readPacedNativeSelection(window)
        @Assert(nativeBefore[0], CJGUI_INTERNAL_RENDERER_OK)
        let oldReady = preparePacedSourceProxyWithoutAdopting(window, budget, controller,
            oldRequestId, owner.text(), 2u32, 4u32, nativeBefore)
        @Assert(oldReady.state, PACED_SOURCE_PROXY_READY_EXACT)
        @Assert(window.selectionRestoreState(oldRequestId), "pending")

        // A same-body new selection revision and request must supersede the
        // ready old preparation before any later legal call can adopt it.
        session.setSelection16(5, 7)
        let newRequestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 5, 7)
        @Assert(newRequestId > oldRequestId, true)
        @Assert(window.selectionRestoreState(oldRequestId), "superseded")
        @Assert(window.selectionRestoreState(newRequestId), "pending")
        let staleOld = readPacedSourceProxyPreparation(window, oldRequestId, owner.text(), 2u32, 4u32)
        @Assert(staleOld.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(staleOld.state, PACED_SOURCE_PROXY_MISMATCH)

        // The first call for the new key retires the old p, then may create
        // the new key's phase-zero preparation in that same bounded call. It
        // cannot adopt the old 2:4 selection or claim the old key was ready.
        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(window.selectionRestoreState(oldRequestId), "superseded")
        @Assert(window.selectionRestoreState(newRequestId), "pending")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        let afterRetire = readPacedSourceProxyPreparation(window, newRequestId, owner.text(), 5u32, 7u32)
        assertPacedSourceProxyPreparationIdentity(afterRetire, newRequestId, 5u32, 7u32)
        @Assert(afterRetire.state, PACED_SOURCE_PROXY_PREPARING_EXACT)
        @Assert(afterRetire.phase, 0u32)
        @Assert(afterRetire.characterCursor, 0u32)
        @Assert(afterRetire.tileCursor, 0u32)
        let nativeAfterRetire = readPacedNativeSelection(window)
        @Assert(nativeAfterRetire[1], nativeBefore[1])
        @Assert(nativeAfterRetire[2], nativeBefore[2])

        let newReady = preparePacedSourceProxyWithoutAdopting(window, budget, controller,
            newRequestId, owner.text(), 5u32, 7u32, nativeBefore)
        @Assert(newReady.state, PACED_SOURCE_PROXY_READY_EXACT)
        @Assert(window.selectionRestoreState(oldRequestId), "superseded")
        @Assert(window.selectionRestoreState(newRequestId), "pending")
        @Assert(runPacedOwnerTurn(window, budget), true)
        @Assert(window.selectionRestoreState(oldRequestId), "superseded")
        @Assert(window.selectionRestoreState(newRequestId), "installed")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        let native = readPacedNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 5u32)
        @Assert(native[2], 7u32)
        @Assert(controller.builds, 1)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidatePendingSelectionWaitsForNewAcceptedBodyWithSameRequestId(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        session.setSelection16(3, 3)
        owner.externalWrite(0, 0, "<agent>\n")
        @Assert(session.refreshMirror(), true)
        @Assert(session.needsNativeSelectionRestore(), true)
        let expected = owner.text()
        let requestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, expected, 11, 11)
        @Assert(requestId > 0, true)
        controller.revision += 1
        window.requestRefresh()

        @Assert(runPacedOwnerTurnWithLivePreparation(window, budget), true)
        // Hold this real preparation while ordinary event/result turns run.
        // Waiting is not an installation attempt: nine turns must keep the
        // same pending id rather than reach the eight-attempt terminal state.
        var turn: Int64 = 0
        while (turn < 9) {
            @Assert(budget.begin(), true)
            let _ = window.pump(0u32)
            budget.end()
            @Assert(window.selectionRestoreState(requestId), "pending")
            @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", "row one\nrow two\n")
            @Assert(budget.hasPreparedWork(), true)
            turn += 1
        }

        var installed = false
        while (turn < 48 && !installed) {
            @Assert(runPacedOwnerTurn(window, budget), true)
            installed = window.selectionRestoreState(requestId) == "installed"
            turn += 1
        }
        @Assert(installed, true)
        @Assert(window.selectionRestoreState(requestId), "installed")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", expected)
        @Assert(session.needsNativeSelectionRestore(), false)
        @Assert(session.selection16()[0], 11)
        @Assert(session.selection16()[1], 11)
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)
        let native = readPacedNativeSelection(window)
        @Assert(native[0], CJGUI_INTERNAL_RENDERER_OK)
        @Assert(native[1], 11u32)
        @Assert(native[2], 11u32)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateSameValueSelectionChangeImmediatelyEndsOldRestoreTicket(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let session = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(focusSelectionRestoreFixture(window), true)
        session.setSelection16(2, 2)
        let requestId = window.requestTextSelectionRestore(9891, 9891,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, owner.text(), 2, 2)
        @Assert(requestId > 0, true)

        // Same text and owner version, but a newer selection identity revokes
        // the old ticket while the unrelated candidate is being prepared.
        session.setSelection16(3, 3)
        controller.companion = "candidate companion"
        controller.revision += 1
        window.requestRefresh()
        @Assert(runPacedOwnerTurnWithLivePreparation(window, budget), true)

        @Assert(window.selectionRestoreState(requestId), "identity_superseded")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 1)
        @Assert(controller.rollbacks, 0)
        @Assert(budget.hasPreparedWork(), true)
    } finally { budget.end(); window.close() }
}

@Test
func testPacedCandidateThinTextGeometryKeepsOriginalAcceptedSemantics(): Unit {
    let owner = FakeTextOwner("row one\nrow two\n")
    let controller = SelectionRestorePacedController(owner)
    controller.companionHeight = 1
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        let _ = window.bindRangeTextSession(9891, "selection-restore-body", owner, owner,
            9891, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(controller.commits, 1)
        window.useOwnerTurnBudget(budget)
        @Assert(window.acceptedNodeText("selection-restore-companion") ?? "", "accepted companion")
        controller.companion = "new thin companion"
        controller.revision += 1
        window.requestRefresh()
        @Assert(finishPacedCandidate(window, budget), true)
        @Assert(window.acceptedNodeText("selection-restore-companion") ?? "", "new thin companion")
        @Assert(window.acceptedNodeValue("selection-restore-body") ?? "", owner.text())
        @Assert(controller.builds, 2)
        @Assert(controller.commits, 2)
        @Assert(controller.rollbacks, 0)
        let bounds = window.acceptedNodeBounds("selection-restore-companion").getOrThrow()
        @Assert(bounds.height, 1)
    } finally { budget.end(); window.close() }
}
