package cjgui

import cjgui_shared_operation_core.*

// This probe uses an ordinary controller/window refresh.  It keeps assertions
// outside the measured work and consumes the package-only snapshot that the
// performance fixture uses; normal consumers receive no timing API.
private class RefreshTimingProbeController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    private var value: String = "before"

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(990001, "refresh-timing-root", CjguiComposableUiStyle(padding: 8, gap: 4))
        root.add(cjguiComposableText(990002, "refresh-timing-title", "Timing", CjguiComposableUiStyle(fixedHeight: 18)))
        root.add(cjguiComposableTextInput(990003, "refresh-timing-field", "Field", value, 1,
            CjguiComposableUiStyle(fixedHeight: 28)))
        root.add(cjguiComposableButton(990004, "refresh-timing-apply", "Apply", "APPLY", 1,
            CjguiComposableUiStyle(fixedHeight: 28)))
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
    public func advance(): Unit {
        value = "after"
        revision += 1
    }
}

private func hasMeasuredCoreStages(timing: CjguiComposableUiRefreshTiming): Bool {
    return timing.buildNanoseconds > 0 && timing.identityResolutionNanoseconds > 0 &&
        timing.candidateCloneNanoseconds > 0 && timing.layoutNanoseconds > 0 &&
        timing.nativeStageAndSubmitNanoseconds > 0
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = RefreshTimingProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { window.close(); return 3 }
    let initial = window.testRefreshTiming()
    if (!hasMeasuredCoreStages(initial)) { window.close(); return 4 }
    controller.advance()
    if (!window.refresh()) { window.close(); return 5 }
    let local = window.testRefreshTiming()
    let projection = window.windowProjection()
    let valid = hasMeasuredCoreStages(local) && local.candidateNodeCount == projection.nodes.size &&
        local.sameSceneComparisonNanoseconds >= 0 && local.participantPreparationNanoseconds >= 0
    println("CJGUI_REFRESH_TIMING_PROBE build_ns=${local.buildNanoseconds} identity_ns=${local.identityResolutionNanoseconds} clone_ns=${local.candidateCloneNanoseconds} participant_ns=${local.participantPreparationNanoseconds} layout_ns=${local.layoutNanoseconds} compare_ns=${local.sameSceneComparisonNanoseconds} stage_submit_ns=${local.nativeStageAndSubmitNanoseconds} nodes=${local.candidateNodeCount} valid=${valid}")
    window.close()
    return if (valid) { 0 } else { 6 }
}
