package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func diagnosticsWorkloadAttemptCurrentCountsAndReopen(): Unit {
    let owner = DiagnosticAcceptedController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    @Assert(window.setWorkloadDiagnostics(true), true)
    let before = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(before.workloadStatus, "enabled")
    @Assert(before.lastAttemptWorkloadResult, "none")
    owner.buttonLabel = "Actual changed node text"
    owner.revision += 1
    @Assert(window.refresh(), true)
    let after = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(after.lastAttemptWorkloadResult, "accepted")
    @Assert(after.lastAttemptNodeWrites > 0, true)
    @Assert(after.lastAttemptNodeWrites, after.nodeWriteCount - before.nodeWriteCount)
    @Assert(after.lastAttemptNodeClones, after.nodeCloneCount - before.nodeCloneCount)
    @Assert(after.lastAttemptNodeAllocations, after.nodeAllocationCount - before.nodeAllocationCount)
    @Assert(after.lastAttemptTextLayoutPreparations,
        after.textLayoutPreparationCount - before.textLayoutPreparationCount)
    @Assert(after.lastAttemptImageDecodeStarts, after.imageDecodeStartCount - before.imageDecodeStartCount)
    let accepted = after.acceptedSceneVersion
    @Assert(window.diagnosticSnapshot(maximumNodes: 1).acceptedSceneVersion, accepted)
    window.close()
    @Assert(window.start(), true)
    @Assert(window.setWorkloadDiagnostics(true), true)
    let reopened = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(reopened.sessionIdentity != after.sessionIdentity, true)
    @Assert(reopened.lastAttemptWorkloadResult, "none")
    @Assert(reopened.lastAttemptNodeWrites, -1)
    window.close()
}

private class DiagnosticAcceptedController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var showSelected: Bool = true
    var buttonLabel: String = "Button"

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "diagnostic-root", CjguiComposableUiStyle())
        if (showSelected) {
            root.add(cjguiComposableButton(2, "diagnostic-button", buttonLabel, "PRESS", 0,
                CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 32)))
        }
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
}

@Test
func diagnosticsAcceptedPaginationRemovalAndReopen(): Unit {
    let owner = DiagnosticAcceptedController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    let first = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(first.status, "ok")
    @Assert(first.nodes.size <= 1, true)
    @Assert(first.totalNodes > 1, true)
    @Assert(first.truncated, true)
    @Assert(first.overlayEnabled, false)
    @Assert(first.submittedSceneVersion, first.acceptedSceneVersion)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
        selectedIdentityKey: "semantic:diagnostic-button")), true)
    let shown = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(shown.overlayEnabled, true)
    @Assert(shown.nativeSubmissionCount, first.nativeSubmissionCount)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
        selectedIdentityKey: "semantic:missing")), false)
    @Assert(window.diagnosticSnapshot(maximumNodes: 8).overlayEnabled, true)

    owner.showSelected = false
    owner.revision += 1
    @Assert(window.refresh(), true)
    let afterRemoval = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(afterRemoval.acceptedSceneVersion > first.acceptedSceneVersion, true)
    @Assert(afterRemoval.overlayEnabled, true)
    @Assert(window.diagnosticSnapshot(maximumNodes: 8,
        expectedSessionIdentity: first.sessionIdentity,
        expectedAcceptedSceneVersion: first.acceptedSceneVersion).status, "stale_accepted")
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(false)), true)
    window.close()
    let closed = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(closed.status, "closed")
    @Assert(closed.nodes.size, 0)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true)), false)

    @Assert(window.start(), true)
    let reopened = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(reopened.status, "ok")
    @Assert(reopened.sessionIdentity != first.sessionIdentity, true)
    @Assert(reopened.overlayEnabled, false)
    window.close()
}

@Test
func diagnosticsTimingIsOptInBoundedAndDoesNotRefresh(): Unit {
    let owner = DiagnosticAcceptedController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)

    let disabled = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(disabled.timingEnabled, false)
    @Assert(disabled.timingStatus, "disabled")
    @Assert(disabled.timingClockSource, "unavailable")
    @Assert(disabled.positionPrepareCount, -1)
    @Assert(disabled.positionQueryCount, -1)
    @Assert(disabled.positionLineBuildCount, -1)
    @Assert(disabled.positionCacheHitCount, -1)

    let accepted = disabled.acceptedSceneVersion
    let submitted = disabled.submittedSceneVersion
    let submissions = disabled.nativeSubmissionCount
    @Assert(window.setTimingDiagnostics(true), true)
    let enabled = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(enabled.timingStatus, "enabled")
    @Assert(enabled.timingClockSource, "mach_continuous_time")
    @Assert(enabled.timingSessionIdentity, enabled.sessionIdentity)
    @Assert(enabled.timingAcceptedSceneVersion, accepted)
    @Assert(enabled.acceptedSceneVersion, accepted)
    @Assert(enabled.submittedSceneVersion, submitted)
    @Assert(enabled.nativeSubmissionCount, submissions)
    @Assert(enabled.timingReadCount > 0, true)

    owner.showSelected = false
    owner.revision += 1
    @Assert(window.refresh(), true)
    let measured = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(measured.timingStatus, "enabled")
    @Assert(measured.timingAcceptedSceneVersion, measured.acceptedSceneVersion)
    @Assert(measured.buildNanoseconds >= 0, true)
    @Assert(measured.layoutNanoseconds >= 0, true)
    @Assert(measured.nativeStageAndSubmitNanoseconds >= 0, true)

    @Assert(window.setTimingDiagnostics(false), true)
    let disabledAgain = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(disabledAgain.timingStatus, "disabled")
    @Assert(disabledAgain.buildNanoseconds, -1)
    @Assert(disabledAgain.layoutNanoseconds, -1)
    @Assert(disabledAgain.nativeStageAndSubmitNanoseconds, -1)
    @Assert(disabledAgain.positionPrepareCount, -1)
    window.close()
}

@Test
func diagnosticsCommandSnapshotIsReadOnlyBoundedAndKeepsReasons(): Unit {
    let owner = DiagnosticCommandController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    // Command declarations bind with an accepted scene refresh, not with the
    // start handshake alone; publish one real revision change.
    owner.revision += 1
    window.requestRefresh()
    var settled = false
    var turns: Int64 = 0
    while (!settled && turns < 80) {
        settled = window.refreshIfNeeded()
        if (!settled) {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        }
        turns += 1
    }
    @Assert(settled, true)
    let page = window.diagnosticCommandSnapshot(maximumCommands: 8)
    @Assert(page.status, "ok")
    @Assert(page.totalCommands, 2)
    @Assert(page.commands.size, 2)
    @Assert(page.truncated, false)
    @Assert(page.acceptedSceneVersion, window.displayedSceneVersion())
    @Assert(page.sessionIdentity, window.liveWindowSessionIdentity().getOrThrow())
    let live = page.commands[0]
    @Assert(live.id, "diag.live")
    @Assert(live.resolution, "resolved")
    @Assert(live.resolvedNodeId, 2)
    @Assert(live.enabled, true)
    @Assert(live.checked, true)
    @Assert(live.shortcut, "shortcut:shift+command+k")
    @Assert(live.acceptedSceneVersion, page.acceptedSceneVersion)
    @Assert(live.unavailableReason, "")
    let disabled = page.commands[1]
    @Assert(disabled.resolution, "resolved")
    @Assert(disabled.enabled, false)
    @Assert(disabled.unavailableReason, "declaration_disabled")
    // The bound is applied without executing anything; the full count stays.
    let bounded = window.diagnosticCommandSnapshot(maximumCommands: 1)
    @Assert(bounded.commands.size, 1)
    @Assert(bounded.totalCommands, 2)
    @Assert(bounded.truncated, true)
    // No command ran: the controller saw no activation.
    @Assert(owner.activations, 0)
    window.close()
    let closed = window.diagnosticCommandSnapshot()
    @Assert(closed.status, "closed")
    @Assert(closed.commands.size, 0)
    @Assert(closed.acceptedSceneVersion, -1)
}

private class DiagnosticCommandController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    var revision: Int64 = 1
    var activations: Int64 = 0

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "diag-command-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "diag-command-button", "Target", "PRESS", 0,
            CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 32)))
        return root
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("diag.live", CjguiComposableUiNodeReference.manual(2), "Live",
                CjguiComposableUiShortcut("k", usesShift: true), "View", 0, true, true),
            CjguiComposableUiCommand("diag.disabled", CjguiComposableUiNodeReference.manual(2), "Disabled",
                "", 0, false, false)
        ])
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27) { activations += 1 }
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
