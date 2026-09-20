package cjgui

import cjgui_shared_operation_core.*

// Probe-only native seams. These are compiled only by the local runner with
// CJGUI_INTERNAL_TESTING; no production Cangjie surface exposes them.
foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_set_composable_scene_node_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_send_composable_key(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, outFocusedNodeId: CPointer<UInt64>
    ): Int32
}

// A normal composable window with many independently scoped, focusable
// controls.  Updating one value still exercises the real declared-tree,
// candidate, layout and native staging path for the remaining scopes.
private class ComplexSceneScopeTimingController <: CjguiComposableUiController {
    private let scopeCount: Int64
    private var revision: Int64
    private var localValue: String

    init(scopeCount: Int64) {
        this.scopeCount = scopeCount
        this.revision = 1
        this.localValue = "initial"
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(980000, "complex-scope-root", CjguiComposableUiStyle(padding: 2, gap: 0))
        var index: Int64 = 0
        while (index < scopeCount) {
            let group = cjguiComposableVertical(980001 + index * 2, "complex-scope-group-${index}",
                CjguiComposableUiStyle(fixedHeight: 24), inputScopeId: "complex-scope-${index}")
            group.add(
                cjguiComposableTextInput(980002 + index * 2, "complex-scope-input-${index}", "Field",
                    if (index == 0) {
                        localValue
                    } else {
                        "stable-${index}"
                    }, 10000 + index, CjguiComposableUiStyle(fixedHeight: 22)))
            root.add(group)
            index += 1
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
    public func advance(): Unit {
        localValue = if (localValue == "local-a") {
            "local-b"
        } else {
            "local-a"
        }
        revision += 1
    }
}

private func emitSample(scopeCount: Int64, sample: Int64, timing: CjguiComposableUiRefreshTiming): Unit {
    println(
        "CJGUI_COMPLEX_SCOPE_SAMPLE scopes=${scopeCount} sample=${sample} build_ns=${timing.buildNanoseconds} identity_ns=${timing.identityResolutionNanoseconds} clone_ns=${timing.candidateCloneNanoseconds} layout_ns=${timing.layoutNanoseconds} compare_ns=${timing.sameSceneComparisonNanoseconds} stage_submit_ns=${timing.nativeStageAndSubmitNanoseconds} nodes=${timing.candidateNodeCount}")
}

private func runScenario(scopeCount: Int64): Bool {
    let controller = ComplexSceneScopeTimingController(scopeCount)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        window.close();
        return false
    }
    let expectedNodes = 1 + scopeCount * 2
    var sample: Int64 = 0
    while (sample < 30) {
        controller.advance()
        if (!window.refresh()) {
            window.close();
            return false
        }
        let timing = window.testRefreshTiming()
        if (timing.candidateNodeCount != expectedNodes || timing.buildNanoseconds < 0 ||
            timing.identityResolutionNanoseconds < 0 || timing.candidateCloneNanoseconds < 0 ||
            timing.layoutNanoseconds < 0 || timing.sameSceneComparisonNanoseconds < 0 ||
            timing.nativeStageAndSubmitNanoseconds < 0) {
            window.close()
            return false
        }
        emitSample(scopeCount, sample, timing)
        sample += 1
    }
    let before = window.windowProjection()
    let idleAccepted = window.refreshIfNeeded()
    let after = window.windowProjection()
    println(
        "CJGUI_COMPLEX_SCOPE_IDLE scopes=${scopeCount} accepted=${idleAccepted} build_delta=${after.buildPassCount - before.buildPassCount} layout_delta=${after.layoutPassCount - before.layoutPassCount} submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount}")
    let valid = before.nodes.size == expectedNodes && after.nodes.size == expectedNodes && after.buildPassCount == before
        .buildPassCount && after.layoutPassCount == before.layoutPassCount && after.nativeSubmissionCount == before
        .nativeSubmissionCount
    window.close()
    return valid
}

// This is a semantic regression, not a numeric-table unit test.  It keeps a
// focused stable scope across deletion/reordering of the first scope, queues a
// stale event from the prior native generation, and forces one node staging
// failure before retrying the same candidate.  Empty and repeated symbolic
// scopes are covered by the same scene.
private class ScopeGenerationRegressionController <: CjguiComposableUiController {
    private var mode: Int64
    private var revision: Int64

    init() {
        this.mode = 0
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(981000, "scope-generation-root", CjguiComposableUiStyle(padding: 2, gap: 2))
        if (mode == 0) {
            let prefix = cjguiComposableVertical(981001, "scope-prefix", CjguiComposableUiStyle(fixedHeight: 24),
                inputScopeId: "prefix")
            prefix.add(cjguiComposableButton(981002, "scope-prefix-button", "prefix", "PREFIX", 42,
                CjguiComposableUiStyle(fixedHeight: 20)))
            root.add(prefix)
        }
        let stable = cjguiComposableVertical(981003, "scope-stable", CjguiComposableUiStyle(fixedHeight: 48),
            inputScopeId: "stable")
        stable.add(cjguiComposableButton(981004, "scope-stable-first", "stable first", "STABLE_FIRST", 42,
            CjguiComposableUiStyle(fixedHeight: 20)))
        stable.add(cjguiComposableButton(981005, "scope-stable-second", "stable second", "STABLE_SECOND", 42,
            CjguiComposableUiStyle(fixedHeight: 20)))
        let empty = cjguiComposableVertical(981006, "scope-empty", CjguiComposableUiStyle(fixedHeight: 24))
        empty.add(cjguiComposableButton(981007, "scope-empty-button", "empty", "EMPTY", 42,
            CjguiComposableUiStyle(fixedHeight: 20)))
        let repeated = cjguiComposableVertical(981008, "scope-repeated", CjguiComposableUiStyle(fixedHeight: 24),
            inputScopeId: "stable")
        repeated.add(cjguiComposableButton(981009, "scope-repeated-button", "repeated", "REPEATED", 42,
            CjguiComposableUiStyle(fixedHeight: 20)))
        if (mode == 2) {
            // Reorder the repeated declaration ahead of the stable group. The
            // symbolic scope is still one domain, but every native index moves.
            root.add(repeated)
            root.add(stable)
            root.add(empty)
        } else {
            root.add(stable)
            root.add(empty)
            root.add(repeated)
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
    public func deleteFirstAndReorder(): Unit {
        mode = 1
        revision += 1
    }
    public func reorderRepeatedScope(): Unit {
        mode = 2
        revision += 1
    }
}

private func enqueueScopeRegressionEvent(session: UInt64): Bool {
    let nativeText = unsafe { LibC.mallocCString("shortcut:scope-generation") }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(session, 0u32, 34u32, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func runScopeGenerationRegression(): Bool {
    // Explicitly lock down the empty/repeated/first-seen rules independently
    // of native pixels before exercising the actual window transaction.
    let table = CjguiComposableUiNativeInputScopeTable()
    if (table.codeFor("") != 0u64 || table.codeFor("stable") != 1u64 || table.codeFor("stable") != 1u64 ||
        table.codeFor("prefix") != 2u64 || table.codeFor("") != 0u64) {
        return false
    }
    let controller = ScopeGenerationRegressionController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        window.close()
        return false
    }
    let initial = window.displayedSceneVersion()
    if (initial <= 0 || internalRendererFocusComposableNode(window.testSessionToken(), 981004) !=
        CJGUI_INTERNAL_RENDERER_OK) {
        window.close()
        return false
    }
    // The old native scene owns this event. It must be rejected after the
    // deletion/reorder commits a new Cangjie scene.
    if (!enqueueScopeRegressionEvent(window.testSessionToken())) {
        window.close()
        return false
    }
    controller.deleteFirstAndReorder()
    if (!window.refresh()) {
        window.close()
        return false
    }
    let stale = window.pump(0u32)
    var focusedAfterRemap: UInt64 = 0u64
    let tabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(window.testSessionToken(), 48u16, 0u64,
            inout focusedAfterRemap)
    }
    let remapValid = !stale.didApplyHumanAction && tabStatus == CJGUI_INTERNAL_RENDERER_OK &&
        focusedAfterRemap == 981005 && window.displayedSceneVersion() > initial
    if (!remapValid) {
        window.close()
        return false
    }
    // A failed candidate must not publish its new compact scope table. The
    // retry must then accept the same candidate with fresh generation metadata.
    controller.reorderRepeatedScope()
    let acceptedBeforeFailure = window.displayedSceneVersion()
    let forced = unsafe {
        cjgui_internal_renderer_test_set_composable_scene_node_failures(window.testSessionToken(), 1u32)
    }
    let failed = window.refresh()
    let retained = window.displayedSceneVersion() == acceptedBeforeFailure
    let recovered = window.refresh()
    let postRetryFocus = internalRendererFocusComposableNode(window.testSessionToken(), 981009)
    var retryFocused: UInt64 = 0u64
    let retryTabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(window.testSessionToken(), 48u16, 0u64,
            inout retryFocused)
    }
    let retryValid = forced == CJGUI_INTERNAL_RENDERER_OK && !failed && retained && recovered &&
        postRetryFocus == CJGUI_INTERNAL_RENDERER_OK && retryTabStatus == CJGUI_INTERNAL_RENDERER_OK &&
        retryFocused == 981004 && window.displayedSceneVersion() > acceptedBeforeFailure
    println("CJGUI_SCOPE_GENERATION_REGRESSION remap=${remapValid} stale_rejected=${!stale.didApplyHumanAction} empty_scope=true repeated_scope=true failure_retained=${retained} retry_recovered=${retryValid} initial=${initial} after_remap=${acceptedBeforeFailure} final=${window.displayedSceneVersion()}")
    window.close()
    return retryValid
}

main(args: Array<String>): Int64 {
    if (args.size != 0) {
        return 2
    }
    for (scopeCount in [16, 128, 480]) {
        if (!runScenario(scopeCount)) {
            return 3
        }
    }
    if (!runScopeGenerationRegression()) {
        return 4
    }
    println("cjgui complex scope timing probe: passed")
    return 0
}
