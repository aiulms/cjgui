package cjgui

import std.collection.*
import std.math.*
import std.time.*

private class PositionOriginWindowController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    var window: ?CjguiComposableUiWindow = None
    var revision: Int64 = 1
    var acceptedBase: Int64 = 200
    var candidateBase: Int64 = 200
    var requestRebase: Bool = false
    var rejectCandidate: Bool = false
    var ticket: ?CjguiComposableUiPositionOriginTicket = None
    var stageResult: String = "none"
    var duplicateResult: String = "none"
    var conflictResult: String = "none"
    let key: String = "semantic:origin-window-moving"

    public func beginSceneRefresh(): Bool {
        candidateBase = acceptedBase
        if (requestRebase) {
            if (let Some(host) <- window) {
                if (let Some(value) <- ticket) {
                    stageResult = host.stageNodeTranslationOriginRebase(value, 0.0, 58.0)
                    duplicateResult = host.stageNodeTranslationOriginRebase(value, 0.0, 58.0)
                    conflictResult = host.stageNodeTranslationOriginRebase(value, 0.0, 59.0)
                    if (stageResult == "staged") { candidateBase = acceptedBase - 58 }
                }
            }
        }
        return true
    }
    public func prepareSceneRefresh(): Bool { return !rejectCandidate }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func commitSceneRefresh(): Unit {
        acceptedBase = candidateBase
        requestRebase = false
    }
    public func rollbackSceneRefresh(): Unit { candidateBase = acceptedBase }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9970, "origin-window-root", CjguiComposableUiStyle())
        root.add(cjguiComposableVertical(9971, "origin-window-spacer",
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: candidateBase)))
        let moving = cjguiComposableVertical(9972, "origin-window-moving",
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 32))
        moving.add(cjguiComposableText(9973, "origin-window-text", "Frozen owner",
            CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 24)))
        root.add(moving)
        return root
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

private func originWindowState(window: CjguiComposableUiWindow, key: String): CjguiComposableUiPositionStatus {
    return window.animatedNodeTranslation(key) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(-999.0, -999.0), CjguiComposableUiPositionValue(-999.0, -999.0),
        CjguiComposableUiAnimationBinding(-1), "", -1, -1, false)
}

@Test
func fPositionOriginWindowRejectRetryAndFullCandidatePublishAtomically(): Unit {
    let controller = PositionOriginWindowController()
    let window = CjguiComposableUiWindow(controller)
    controller.window = Some(window)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let start = MonoTime.now()
        @Assert(window.animateNodeTranslation(controller.key, 0.0, -174.0,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
                easing: CjguiComposableUiAnimationEasing.LINEAR), atTime: start), true)
        let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 400)
        let before = originWindowState(window, controller.key)
        let oldY = (window.nodeRect(9972) ?? (0, -999, 0, 0))[1]
        controller.ticket = before.originTicket
        @Assert(controller.ticket.isSome(), true)
        if (let Some(ticket) <- controller.ticket) {
            @Assert(window.stageNodeTranslationOriginRebase(ticket, 0.0, 58.0), "candidate_required")
        }
        controller.requestRebase = true
        controller.rejectCandidate = true
        controller.revision += 1
        @Assert(window.refresh(), false)
        @Assert(controller.stageResult, "staged")
        @Assert(controller.duplicateResult, "staged")
        @Assert(controller.conflictResult, "candidate_conflict")
        @Assert(controller.acceptedBase, 200)
        @Assert(originWindowState(window, controller.key).presented.y, before.presented.y)
        @Assert(originWindowState(window, controller.key).target.y, before.target.y)
        @Assert((window.nodeRect(9972) ?? (0, -999, 0, 0))[1], oldY)
        controller.rejectCandidate = false
        @Assert(window.refresh(), true)
        let after = originWindowState(window, controller.key)
        let newY = (window.nodeRect(9972) ?? (0, -999, 0, 0))[1]
        @Assert(controller.acceptedBase, 142)
        @Assert(abs(after.presented.y - before.presented.y - 58.0) < 1.0e-8, true)
        @Assert(after.target.y, before.target.y + 58.0)
        @Assert(abs(Float64(newY) + after.presented.y - Float64(oldY) - before.presented.y) < 1.0e-8, true)
        controller.requestRebase = true
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(controller.stageResult, "accepted_scene_stale")
        @Assert(originWindowState(window, controller.key).presented.y, after.presented.y)
        @Assert(controller.acceptedBase, 142)
    } finally { window.close() }
}

@Test
func fPositionOriginWindowPendingRetargetAndAckUseExactlyOneCompensation(): Unit {
    let controller = PositionOriginWindowController()
    let window = CjguiComposableUiWindow(controller)
    controller.window = Some(window)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let start = MonoTime.now()
        let spec = CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
            easing: CjguiComposableUiAnimationEasing.LINEAR)
        @Assert(window.animateNodeTranslation(controller.key, 0.0, -174.0, spec: spec, atTime: start), true)
        let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 400)
        let before = originWindowState(window, controller.key)
        controller.ticket = before.originTicket
        controller.requestRebase = true
        controller.revision += 1
        // Only the TESTING native sidecar can hold an actual present ticket.
        if (!window.testHoldNextComposablePresent()) { return }
        @Assert(window.refresh(), false)
        @Assert(controller.stageResult, "staged")
        @Assert(controller.acceptedBase, 200)
        @Assert(window.cancelNodeTranslationAnimation(controller.key), false)
        @Assert(window.stopNodeTranslationAnimation(controller.key, atTime: start), false)
        @Assert(window.animateNodeTranslation(controller.key, 0.0, 40.0, spec: spec,
            atTime: start + Duration.millisecond * 400), true)
        @Assert(originWindowState(window, controller.key).presented.y, before.presented.y)
        @Assert(window.testResolvePendingComposablePresent(), true)
        let _ = window.refreshIfNeeded()
        let after = originWindowState(window, controller.key)
        @Assert(controller.acceptedBase, 142)
        @Assert(abs(after.presented.y - before.presented.y - 58.0) < 1.0e-8, true)
        @Assert(after.target.y, 98.0)
        let _ = window.refreshIfNeeded()
        @Assert(originWindowState(window, controller.key).presented.y, after.presented.y)
        @Assert(originWindowState(window, controller.key).target.y, 98.0)
    } finally { window.close() }
}
