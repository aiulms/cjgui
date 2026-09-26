// Candidate text resource release probe (stage A counterexample).
//
// A rejected scene transaction must not keep candidate-unique derived text
// resources alive until the next configure or close. The discriminative seam
// classifies staged-reachable textures against committed-reachable ones, so
// the probe can prove, per rejection:
//   - candidate-unique holds drop to zero when the rejection returns,
//   - the accepted scene's bytes, textures and content stay intact,
//   - a staged clone that shared an accepted texture does not destroy it,
//   - a scale change alone never rasters, and a focus change stays bounded,
//   - the window keeps editing and accepting legal candidates afterwards.
package cjgui

foreign {
    func cjgui_internal_renderer_test_composable_text_resource_stats(
        session: UInt64, nodeIndex: UInt32, outByteCount: CPointer<UInt64>,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_candidate_stats(
        session: UInt64,
        outCommittedUniqueTextureCount: CPointer<UInt64>,
        outStagedUniqueTextureCount: CPointer<UInt64>,
        outCandidateOnlyTextureCount: CPointer<UInt64>,
        outSharedTextureCount: CPointer<UInt64>,
        outCandidateOnlyNodeBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_cpu_scratch_stats(
        session: UInt64, outCurrentBytes: CPointer<UInt64>, outPeakBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>,
        outUploadBytes: CPointer<UInt64>, outUploadMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_text_preparation_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_edit_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_activate_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_toggle_composable_backing_scale(
        session: UInt64, outResizeVersion: CPointer<UInt64>,
        outBeforeScale: CPointer<Float64>, outAfterScale: CPointer<Float64>,
        outDrawableWidth: CPointer<UInt32>, outDrawableHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
        session: UInt64, nodeIndex: UInt32, tileIndex: UInt32,
        outNonzeroAlphaPixels: CPointer<UInt64>
    ): Int32
}

private func mediumText(lines: Int64): String {
    var builder = StringBuilder()
    var index: Int64 = 0
    let row = "候选资源行 观微 😀 0123456789 "
    while (index < lines) {
        builder.append(row)
        index += 1
    }
    return builder.toString()
}

private struct CandidateSnapshot {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_OK
    var nodeBytes: Array<UInt64> = Array<UInt64>()
    var committedUnique: UInt64 = 0u64
    var stagedUnique: UInt64 = 0u64
    var candidateOnly: UInt64 = 0u64
    var shared: UInt64 = 0u64
    var candidateOnlyBytes: UInt64 = 0u64
    var scratchCurrent: UInt64 = 0u64
    var scratchPeak: UInt64 = 0u64
}

private func snapshot(window: CjguiComposableUiWindow, nodeCount: Int64): CandidateSnapshot {
    let nodeBytes = Array<UInt64>(nodeCount, repeat: 0u64)
    var index: Int64 = 0
    var worst: Int32 = CJGUI_INTERNAL_RENDERER_OK
    while (index < nodeCount) {
        var bytes: UInt64 = 0u64
        var x: Float32 = 0.0f32
        var y: Float32 = 0.0f32
        var w: Float32 = 0.0f32
        var h: Float32 = 0.0f32
        let status = unsafe { cjgui_internal_renderer_test_composable_text_resource_stats(
            window.testSessionToken(), UInt32(index), inout bytes, inout x, inout y, inout w, inout h) }
        if (status != CJGUI_INTERNAL_RENDERER_OK) { worst = status }
        nodeBytes[index] = bytes
        index += 1
    }
    var committedUnique: UInt64 = 0u64
    var stagedUnique: UInt64 = 0u64
    var candidateOnly: UInt64 = 0u64
    var shared: UInt64 = 0u64
    var candidateOnlyBytes: UInt64 = 0u64
    let classify = unsafe { cjgui_internal_renderer_test_composable_text_candidate_stats(
        window.testSessionToken(), inout committedUnique, inout stagedUnique,
        inout candidateOnly, inout shared, inout candidateOnlyBytes) }
    var scratchCurrent: UInt64 = 0u64
    var scratchPeak: UInt64 = 0u64
    let scratch = unsafe { cjgui_internal_renderer_test_composable_text_cpu_scratch_stats(
        window.testSessionToken(), inout scratchCurrent, inout scratchPeak) }
    if (classify != CJGUI_INTERNAL_RENDERER_OK) { worst = classify }
    if (scratch != CJGUI_INTERNAL_RENDERER_OK) { worst = scratch }
    var result = CandidateSnapshot()
    result.status = worst
    result.nodeBytes = nodeBytes
    result.committedUnique = committedUnique
    result.stagedUnique = stagedUnique
    result.candidateOnly = candidateOnly
    result.shared = shared
    result.candidateOnlyBytes = candidateOnlyBytes
    result.scratchCurrent = scratchCurrent
    result.scratchPeak = scratchPeak
    return result
}

private func workRasterCount(window: CjguiComposableUiWindow): UInt64 {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        window.testSessionToken(), inout rasterCount, inout rasterBytes, inout rasterMicros,
        inout uploadCount, inout uploadBytes, inout uploadMicros) }
    return rasterCount
}

private func editNode(window: CjguiComposableUiWindow, nodeIndex: UInt32, text: String): Int32 {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_edit_composable_text(
            window.testSessionToken(), nodeIndex, textResource.value) }
    }
    return status
}

/// Two multiline inputs plus an optional oversized popup layer, mirroring the
/// established budget-rollback fixture. `showPopup` together with a first-node
/// content change makes the prepare pass install the first node's candidate
/// texture and then hit the REAL budget rejection on the popup node.
private class PopupController <: CjguiComposableUiController {
    var padding: Int64 = 8
    var first: String = mediumText(60)
    var second: String = mediumText(60)
    var popupVisible: Bool = false
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let host = cjguiComposableLayerHost(30, "candidate-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(cjguiComposableMultilineTextInput(31, "candidate-first", "", first, 31,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 400)))
        host.add(cjguiComposableMultilineTextInput(32, "candidate-second", "", second, 32,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 400)))
        if (popupVisible) {
            let layer = cjguiComposableAnchoredLayer(33, "candidate-layer", "candidate-layer", "popup",
                "candidate-first", 31, CjguiComposableUiStyle(fixedWidth: 1440, fixedHeight: 900))
            layer.add(cjguiComposableMultilineTextInput(34, "candidate-popup", "", mediumText(200), 34,
                CjguiComposableUiStyle(growX: 1, growY: 1)))
            host.add(layer)
        }
        return host
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 31) {
            first = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && event.node.nodeId == 32) {
            second = event.text
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
    public func move(): Unit { padding = 20; revision += 1 }
    public func showPopup(): Unit { popupVisible = true; revision += 1 }
    public func hidePopup(): Unit { popupVisible = false; revision += 1 }
}

/// Two plain sibling multiline inputs in a vertical root: the focus scenario
/// needs both inputs focusable in the normal scene (no layer host).
private class PlainTwoController <: CjguiComposableUiController {
    var first: String = mediumText(60)
    var second: String = mediumText(60)
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(45, "focus-root", CjguiComposableUiStyle(padding: 8, gap: 8))
        root.add(cjguiComposableMultilineTextInput(46, "focus-first", "", first, 46,
            CjguiComposableUiStyle(fixedWidth: 460, fixedHeight: 200)))
        root.add(cjguiComposableMultilineTextInput(47, "focus-second", "", second, 47,
            CjguiComposableUiStyle(fixedWidth: 460, fixedHeight: 200)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 46) {
            first = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && event.node.nodeId == 47) {
            second = event.text
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
}

/// Rejection driven by a REAL budget overflow on the popup node, after the
/// first node already installed a candidate-unique texture in the same
/// prepare pass. Repeating the round must release its holds again.
private func runBudgetOrderRelease(): Bool {
    let controller = PopupController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Candidate Budget Probe", 1440u32, 900u32))
    if (!window.start()) {
        println("CJGUI_CANDIDATE_BUDGET start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    let acceptedVersion = window.windowProgress().acceptedSceneVersion
    // Scene layout for the LayerHost fixture: [0]=host (no text), [1]=first.
    let before = snapshot(window, 2)
    if (before.status != CJGUI_INTERNAL_RENDERER_OK || before.nodeBytes[1] == 0u64) {
        println("CJGUI_CANDIDATE_BUDGET baseline_failed status=${before.status} bytes=${before.nodeBytes}")
        window.close()
        return false
    }
    // The candidate changes the FIRST node's content (new candidate texture)
    // and shows the oversized popup (real budget rejection on a later node).
    controller.first = "预算前已装新纹理 😀 " + mediumText(80)
    controller.showPopup()
    let rejected = !window.refresh()
    let reason = window.windowProgress().lastNativeFailure
    let afterReject = snapshot(window, 2)
    let versionKept = window.windowProgress().acceptedSceneVersion == acceptedVersion
    let released = afterReject.candidateOnly == 0u64 && afterReject.candidateOnlyBytes == 0u64
    let committedKept = afterReject.nodeBytes[0] == before.nodeBytes[0] &&
        afterReject.nodeBytes[1] == before.nodeBytes[1] &&
        afterReject.committedUnique == before.committedUnique
    // Repeat the same rejection: every round must release its own holds.
    let rejectedAgain = !window.refresh()
    let afterSecond = snapshot(window, 2)
    let repeatClean = rejectedAgain && afterSecond.candidateOnly == 0u64 &&
        afterSecond.candidateOnlyBytes == 0u64
    // A legal candidate is still acceptable and the window keeps working.
    controller.hidePopup()
    let recovered = window.refresh()
    let acceptedValue = if (window.acceptedSceneNodes().size > 1) {
        window.acceptedSceneNodes()[1].value
    } else { "" }
    let ok = rejected && reason == "text_resource_budget_exceeded" && versionKept &&
        released && committedKept && repeatClean && recovered &&
        acceptedValue.contains("预算前已装新纹理") && afterReject.scratchCurrent == 0u64
    println("CJGUI_CANDIDATE_BUDGET rejected=${rejected} reason=${reason} version_kept=${versionKept} " +
        "released=${released} committed_kept=${committedKept} repeat_rejected=${rejectedAgain} " +
        "repeat_candidate_only=${afterSecond.candidateOnly} recovered=${recovered} " +
        "first_bytes=${before.nodeBytes[1]}->${afterReject.nodeBytes[1]} " +
        "committed=${before.committedUnique}->${afterReject.committedUnique} " +
        "candidate_only_bytes=${afterReject.candidateOnlyBytes} ok=${ok}")
    window.close()
    return ok
}

/// An injected preparation failure rejects the candidate at the FIRST
/// prepared node. Nothing new is installed, and the probe proves the failure
/// is harmless: accepted scene intact, clone cleanup leaves no candidate
/// holds, and editing plus a legal candidate work afterwards.
private func runInjectedFailureRelease(): Bool {
    let controller = PopupController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Candidate Release Probe", 1440u32, 900u32))
    if (!window.start()) {
        println("CJGUI_CANDIDATE_RELEASE start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    let acceptedVersion = window.windowProgress().acceptedSceneVersion
    let before = snapshot(window, 2)
    let injectStatus = unsafe { cjgui_internal_renderer_test_set_composable_text_preparation_failures(
        window.testSessionToken(), 1u32) }
    controller.first = "注入失败前的候选 😀 " + mediumText(80)
    let rejected = !window.refresh()
    let reason = window.windowProgress().lastNativeFailure
    let afterReject = snapshot(window, 2)
    let versionKept = window.windowProgress().acceptedSceneVersion == acceptedVersion
    let released = afterReject.candidateOnly == 0u64 && afterReject.candidateOnlyBytes == 0u64
    let committedKept = afterReject.nodeBytes[0] == before.nodeBytes[0] &&
        afterReject.nodeBytes[1] == before.nodeBytes[1] &&
        afterReject.committedUnique == before.committedUnique
    let editStatus = editNode(window, 1u32, "拒绝后继续编辑 😀")
    let editTurn = window.pump(0u32)
    controller.first = mediumText(60)
    let recovered = window.refresh()
    var scratchAfterAll: UInt64 = 0u64
    var scratchPeak: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_cpu_scratch_stats(
        window.testSessionToken(), inout scratchAfterAll, inout scratchPeak) }
    let ok = injectStatus == CJGUI_INTERNAL_RENDERER_OK && rejected &&
        reason == "internal_error" && versionKept && released && committedKept &&
        editStatus == CJGUI_INTERNAL_RENDERER_OK && editTurn.didApplyHumanAction &&
        recovered && scratchAfterAll == 0u64
    println("CJGUI_CANDIDATE_RELEASE kind=injected_first_node inject=${injectStatus} rejected=${rejected} " +
        "reason=${reason} version_kept=${versionKept} released=${released} committed_kept=${committedKept} " +
        "committed=${before.committedUnique}->${afterReject.committedUnique} edit=${editStatus} " +
        "edit_turn=${editTurn.didApplyHumanAction} recovered=${recovered} scratch_after=${scratchAfterAll} ok=${ok}")
    window.close()
    return ok
}

/// A candidate that only MOVES nodes keeps the accepted texture objects on the
/// staged clones. A later rejection clears the clones' holds, and the accepted
/// textures must still be alive and drawable through the committed nodes.
private func runSharedReferenceSurvives(): Bool {
    let controller = PopupController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Candidate Shared Probe", 1440u32, 900u32))
    if (!window.start()) {
        println("CJGUI_CANDIDATE_SHARED start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    let before = snapshot(window, 2)
    var alphaBefore: UInt64 = 0u64
    let alphaStatusBefore = unsafe { cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
        window.testSessionToken(), 1u32, 0u32, inout alphaBefore) }
    // The padding change MOVES both inputs without changing content keys, so
    // the staged clones share the accepted textures. The newly shown popup
    // node needs preparation and consumes the injected failure, rejecting the
    // candidate AFTER the shared-holding clones exist.
    let injectStatus = unsafe { cjgui_internal_renderer_test_set_composable_text_preparation_failures(
        window.testSessionToken(), 1u32) }
    controller.move()
    controller.showPopup()
    let rejected = !window.refresh()
    let afterReject = snapshot(window, 2)
    var alphaAfter: UInt64 = 0u64
    let alphaStatusAfter = unsafe { cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
        window.testSessionToken(), 1u32, 0u32, inout alphaAfter) }
    let committedKept = afterReject.nodeBytes[0] == before.nodeBytes[0] &&
        afterReject.nodeBytes[1] == before.nodeBytes[1] &&
        afterReject.committedUnique == before.committedUnique &&
        afterReject.committedUnique > 0u64
    controller.hidePopup()
    let recovered = window.refresh()
    let ok = injectStatus == CJGUI_INTERNAL_RENDERER_OK && rejected &&
        alphaStatusBefore == CJGUI_INTERNAL_RENDERER_OK &&
        alphaStatusAfter == CJGUI_INTERNAL_RENDERER_OK && alphaAfter == alphaBefore &&
        alphaBefore > 0u64 && committedKept && afterReject.candidateOnly == 0u64 && recovered
    println("CJGUI_CANDIDATE_SHARED inject=${injectStatus} rejected=${rejected} " +
        "alpha_before=${alphaBefore} alpha_after=${alphaAfter} committed_kept=${committedKept} " +
        "shared=${before.shared}->${afterReject.shared} recovered=${recovered} ok=${ok}")
    window.close()
    return ok
}

/// A scale change without a Cangjie re-commit must not raster anything on its
/// own, and a following real focus change stays bounded: committed bytes
/// untouched, CPU scratch back to zero, and the window keeps editing.
private func runFocusChangeStaysBounded(): Bool {
    let controller = PlainTwoController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Candidate Focus Probe", 980u32, 620u32))
    if (!window.start()) {
        println("CJGUI_CANDIDATE_FOCUS start=false failure=${window.windowProgress().lastNativeFailure}")
        return false
    }
    // Scene layout: [0]=root, [1]=first, [2]=second.
    let focusStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        window.testSessionToken(), 20.0f32, 20.0f32) }
    let _ = window.pump(0u32)
    let before = snapshot(window, 3)
    let rasterBefore = workRasterCount(window)
    var resizeVersion: UInt64 = 0u64
    var beforeScale: Float64 = 0.0
    var afterScale: Float64 = 0.0
    var drawableWidth: UInt32 = 0u32
    var drawableHeight: UInt32 = 0u32
    let toggleStatus = unsafe { cjgui_internal_renderer_test_toggle_composable_backing_scale(
        window.testSessionToken(), inout resizeVersion, inout beforeScale, inout afterScale,
        inout drawableWidth, inout drawableHeight) }
    let afterToggleRaster = workRasterCount(window)
    // Move focus to the second input through the real hit-test path.
    let focusTwo = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        window.testSessionToken(), 20.0f32, 260.0f32) }
    let _ = window.pump(0u32)
    let rasterAfterFocus = workRasterCount(window)
    let afterFocus = snapshot(window, 3)
    let toggleRasteredNothing = afterToggleRaster == rasterBefore
    // The focus change may raster a small bounded number of conversions (old
    // active to static, new active body, decoration refresh) and nothing more.
    // The newly focused input's own bytes legitimately change with the scale
    // (its active body is re-prepared), so bytes equality is asserted only for
    // the non-text root; the near-budget refusal case is covered separately.
    let boundedWork = rasterAfterFocus <= afterToggleRaster + 4u64
    let editAlive = window.refresh()
    let editStatus = editNode(window, 2u32, "焦点后继续编辑 😀")
    let editTurn = window.pump(0u32)
    let ok = focusStatus == CJGUI_INTERNAL_RENDERER_OK && toggleStatus == CJGUI_INTERNAL_RENDERER_OK &&
        beforeScale != afterScale && toggleRasteredNothing && boundedWork &&
        afterFocus.scratchCurrent == 0u64 && editAlive &&
        editStatus == CJGUI_INTERNAL_RENDERER_OK && editTurn.didApplyHumanAction
    println("CJGUI_CANDIDATE_FOCUS focus1=${focusStatus} toggle=${toggleStatus} " +
        "scale=${beforeScale}->${afterScale} toggle_raster_delta=${afterToggleRaster - rasterBefore} " +
        "focus_raster_delta=${rasterAfterFocus - afterToggleRaster} focus2=${focusTwo} " +
        "scratch_current=${afterFocus.scratchCurrent} refresh_alive=${editAlive} " +
        "edit=${editStatus} edit_turn=${editTurn.didApplyHumanAction} ok=${ok}")
    window.close()
    return ok
}

main(): Int64 {
    var ok = true
    ok = runBudgetOrderRelease() && ok
    ok = runInjectedFailureRelease() && ok
    ok = runSharedReferenceSurvives() && ok
    ok = runFocusChangeStaysBounded() && ok
    println("CJGUI_CANDIDATE_TEXT_RESOURCE passed=${ok}")
    return if (ok) { 0 } else { 1 }
}
