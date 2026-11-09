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

// R6：layoutDiagnostic 必须属于“当前”候选尝试。前一次裁剪超限失败留下
// 诊断链后，下一次在布局之前就失败（participant_begin 拒绝）的候选不能再
// 把旧裁剪链当成自己的原因；随后的正常候选诊断为空。
private class DiagnosticClipThenRefuseController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    // mode 0 健康（窗口以健康树启动），1 裁剪超限，2 participant 拒绝，3 恢复健康。
    public var mode: Int64 = 0
    public var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        if (mode == 1) {
            var node = cjguiComposableText(8181, "diag-clip-leaf", "leaf", CjguiComposableUiStyle())
            var level: Int64 = 0
            while (level < 5) {
                let parent = cjguiComposableVertical(8190 + level, "diag-clip-${level}",
                    CjguiComposableUiStyle(growX: 1, fixedHeight: 60, clipsContent: true))
                parent.add(node)
                node = parent
                level += 1
            }
            return node
        }
        let root = cjguiComposableVertical(8170, "diag-plain-root", CjguiComposableUiStyle())
        root.add(cjguiComposableText(8171, "diag-plain-text", "ok", CjguiComposableUiStyle()))
        return root
    }
    public func beginSceneRefresh(): Bool { return mode != 2 }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
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

@Test
func layoutDiagnosticBelongsToCurrentCandidateAttempt(): Unit {
    let controller = DiagnosticClipThenRefuseController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    // 尝试 1：裁剪链超过容量，场景回滚并发布本候选的裁剪诊断。
    controller.mode = 1
    controller.revision += 1
    @Assert(window.refresh(), false)
    @Assert(window.lastCandidateLayoutDiagnostic().size > 0, true)
    // 尝试 2：participant_begin 在布局之前拒绝。当前失败没有布局诊断，
    // 旧裁剪链不能作为本次失败的原因被重复报告。
    controller.mode = 2
    controller.revision += 1
    @Assert(window.refresh(), false)
    @Assert(window.lastCandidateLayoutDiagnostic(), "")
    // 尝试 3：正常候选通过，诊断保持为空。
    controller.mode = 3
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.lastCandidateLayoutDiagnostic(), "")
    window.close()
}
