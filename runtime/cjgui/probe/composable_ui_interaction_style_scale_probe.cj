package cjgui

import std.time.*

// This probe uses the native FIFO seam only to deliver a copied hover identity.
// The scene, interaction-style declaration, COW staging and timing all remain
// the ordinary Cangjie window path.
foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_measurement_count(
        session: UInt64, outMeasurementCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
}

private class InteractionStyleScaleController <: CjguiComposableUiController {
    private let controlCount: Int64

    init(controlCount: Int64) {
        this.controlCount = controlCount
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9100, "interaction-scale-root",
            CjguiComposableUiStyle(fixedWidth: 360, gap: 0))
        let interaction = CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.30, 0.58, 0.94, 1.0)),
                border: Some(CjguiComposableUiColor(0.62, 0.84, 1.0, 1.0))))
        var index: Int64 = 0
        while (index < controlCount) {
            root.add(cjguiComposableButton(9200 + index, "interaction-scale-${index}", "Action ${index}", "ACT", index,
                CjguiComposableUiStyle(fixedHeight: 24, background: CjguiComposableUiColor(0.10, 0.12, 0.16, 1.0),
                    border: CjguiComposableUiColor(0.18, 0.22, 0.30, 1.0)), interactionStyle: interaction))
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
}

private class InteractionStyleScaleNativeCounters {
    let status: Int32
    let committedNodes: UInt32
    let nodeUpdates: UInt64
    let measurements: UInt32
    let configureMicros: UInt64
    let setMicros: UInt64
    let commitMicros: UInt64

    init(status: Int32, committedNodes: UInt32, nodeUpdates: UInt64, measurements: UInt32, configureMicros: UInt64,
        setMicros: UInt64, commitMicros: UInt64) {
        this.status = status
        this.committedNodes = committedNodes
        this.nodeUpdates = nodeUpdates
        this.measurements = measurements
        this.configureMicros = configureMicros
        this.setMicros = setMicros
        this.commitMicros = commitMicros
    }
}

private func nativeCounters(session: UInt64): InteractionStyleScaleNativeCounters {
    var committed: UInt32 = 0u32
    var updates: UInt64 = 0u64
    var measurements: UInt32 = 0u32
    var clones: UInt64 = 0u64
    var allocations: UInt64 = 0u64
    var configureMicros: UInt64 = 0u64
    var setMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    let sceneStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(session, inout committed, inout updates)
    }
    let measurementStatus = unsafe {
        cjgui_internal_renderer_test_composable_measurement_count(session, inout measurements)
    }
    let submissionStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_submission_stats(session, inout clones, inout allocations,
            inout configureMicros, inout setMicros, inout commitMicros)
    }
    return InteractionStyleScaleNativeCounters(if (sceneStatus == 0 && measurementStatus == 0 && submissionStatus == 0) {
        0
    } else {
        -1
    }, committed, updates, measurements, configureMicros, setMicros, commitMicros)
}

private func enqueue(session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString): Bool {
    return unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, nodeIndex, eventKind, text) } == 0
}

private func runScale(controlCount: Int64): Bool {
    let window = CjguiComposableUiWindow(InteractionStyleScaleController(controlCount))
    if (!window.start()) {
        println("CJGUI_INTERACTION_STYLE_SCALE_FAIL controls=${controlCount} reason=start")
        return false
    }
    let session = window.testSessionToken()
    let emptyText = unsafe { LibC.mallocCString("") }
    var activeIndex: Int64 = 1
    if (!enqueue(session, UInt32(activeIndex), 43u32, emptyText) || !window.pump(0u32).isOpen) {
        unsafe { LibC.free(emptyText) }
        window.close()
        println("CJGUI_INTERACTION_STYLE_SCALE_FAIL controls=${controlCount} reason=warmup")
        return false
    }
    var valid = true
    var sample: Int64 = 0
    while (sample < 30) {
        let nextIndex = if (activeIndex >= controlCount) { 1 } else { activeIndex + 1 }
        let before = window.windowProjection()
        let nativeBefore = nativeCounters(session)
        let started = MonoTime.now()
        let left = enqueue(session, UInt32(activeIndex), 44u32, emptyText)
        let entered = enqueue(session, UInt32(nextIndex), 43u32, emptyText)
        let turn = window.pump(0u32)
        let elapsed = MonoTime.now() - started
        let after = window.windowProjection()
        let nativeAfter = nativeCounters(session)
        let timing = window.testRefreshTiming()
        let buildDelta = after.buildPassCount - before.buildPassCount
        let layoutDelta = after.layoutPassCount - before.layoutPassCount
        let submitDelta = after.nativeSubmissionCount - before.nativeSubmissionCount
        let updateDelta = nativeAfter.nodeUpdates - nativeBefore.nodeUpdates
        let measurementDelta = Int64(nativeAfter.measurements) - Int64(nativeBefore.measurements)
        let configureDelta = nativeAfter.configureMicros - nativeBefore.configureMicros
        let setDelta = nativeAfter.setMicros - nativeBefore.setMicros
        let commitDelta = nativeAfter.commitMicros - nativeBefore.commitMicros
        let sampleValid = left && entered && turn.isOpen && !turn.didApplyHumanAction && nativeBefore.status == 0 &&
            nativeAfter.status == 0 && nativeBefore.committedNodes == UInt32(controlCount + 1) &&
            nativeAfter.committedNodes == UInt32(controlCount + 1) && buildDelta == 0 && layoutDelta == 0 &&
            submitDelta == 1 && updateDelta == 2u64 && measurementDelta == 0
        println("CJGUI_INTERACTION_STYLE_SCALE_SAMPLE controls=${controlCount} sample=${sample + 1} pump_ns=${elapsed.toNanoseconds()} interaction_resolve_ns=${timing.interactionPaintResolutionNanoseconds} interaction_compare_ns=${timing.interactionPaintComparisonNanoseconds} native_stage_submit_ns=${timing.nativeStageAndSubmitNanoseconds} native_configure_us=${configureDelta} native_set_us=${setDelta} native_commit_us=${commitDelta} build_delta=${buildDelta} layout_delta=${layoutDelta} submit_delta=${submitDelta} node_update_delta=${updateDelta} measurement_delta=${measurementDelta} valid=${sampleValid}")
        valid = valid && sampleValid
        activeIndex = nextIndex
        sample += 1
    }
    unsafe { LibC.free(emptyText) }
    window.close()
    println("CJGUI_INTERACTION_STYLE_SCALE_RESULT controls=${controlCount} samples=30 valid=${valid}")
    return valid
}

main(): Int64 {
    let small = runScale(8)
    let medium = runScale(128)
    let nearLimit = runScale(960)
    let passed = small && medium && nearLimit
    println("CJGUI_INTERACTION_STYLE_SCALE_PROBE small=${small} medium=${medium} near_limit=${nearLimit} passed=${passed}")
    return if (passed) { 0 } else { 1 }
}
