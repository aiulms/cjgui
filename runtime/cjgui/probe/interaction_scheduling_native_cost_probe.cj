package cjgui

import std.collection.*

// This standalone probe keeps the measured path inside one ordinary
// CjguiComposableUiWindow.  It does not use the public operation transport:
// the native FIFO seam only delivers the same copied hover identities that
// AppKit input would deliver to the interaction repaint path.
private let SAMPLE_COUNT: Int64 = 30

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
    // Deliberately introduced before its native counterpart: the RED build
    // proves this probe cannot keep treating the remainder of Cangjie timing
    // as drawable wait.  The native seam reports only per-frame scalar spans.
    func cjgui_internal_renderer_test_composable_present_timing_stats(
        session: UInt64, outNextDrawableMicros: CPointer<UInt64>, outCommandBufferMicros: CPointer<UInt64>,
        outPresentMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>,
        outReadbackWaitMicros: CPointer<UInt64>, outReadbackWaited: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_cpu_stats(
        session: UInt64, outEncodeMicros: CPointer<UInt64>
    ): Int32
}

private class NativeCostCounters {
    let status: Int32
    let configureMicros: UInt64
    let setMicros: UInt64
    let commitMicros: UInt64

    init(status: Int32, configureMicros: UInt64, setMicros: UInt64, commitMicros: UInt64) {
        this.status = status
        this.configureMicros = configureMicros
        this.setMicros = setMicros
        this.commitMicros = commitMicros
    }
}

private class NativePresentTiming {
    let status: Int32
    let nextDrawableMicros: UInt64
    let commandBufferMicros: UInt64
    let presentMicros: UInt64
    let commitMicros: UInt64
    let readbackWaitMicros: UInt64
    let readbackWaited: UInt8

    init(status: Int32, nextDrawableMicros: UInt64, commandBufferMicros: UInt64, presentMicros: UInt64,
        commitMicros: UInt64, readbackWaitMicros: UInt64, readbackWaited: UInt8) {
        this.status = status
        this.nextDrawableMicros = nextDrawableMicros
        this.commandBufferMicros = commandBufferMicros
        this.presentMicros = presentMicros
        this.commitMicros = commitMicros
        this.readbackWaitMicros = readbackWaitMicros
        this.readbackWaited = readbackWaited
    }
}

private func nativeCostCounters(session: UInt64): NativeCostCounters {
    var clones: UInt64 = 0u64
    var allocations: UInt64 = 0u64
    var configureMicros: UInt64 = 0u64
    var setMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_scene_submission_stats(session, inout clones, inout allocations,
            inout configureMicros, inout setMicros, inout commitMicros)
    }
    return NativeCostCounters(status, configureMicros, setMicros, commitMicros)
}

private func nativePresentTiming(session: UInt64): NativePresentTiming {
    var nextDrawableMicros: UInt64 = 0u64
    var commandBufferMicros: UInt64 = 0u64
    var presentMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    var readbackWaitMicros: UInt64 = 0u64
    var readbackWaited: UInt8 = 0u8
    let status = unsafe {
        cjgui_internal_renderer_test_composable_present_timing_stats(session, inout nextDrawableMicros,
            inout commandBufferMicros, inout presentMicros, inout commitMicros, inout readbackWaitMicros,
            inout readbackWaited)
    }
    return NativePresentTiming(status, nextDrawableMicros, commandBufferMicros, presentMicros, commitMicros,
        readbackWaitMicros, readbackWaited)
}

private func nativeEncoderCpuMicros(session: UInt64): (Int32, UInt64) {
    var micros: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_encoder_cpu_stats(session, inout micros) }
    return (status, micros)
}

private class InteractionCostController <: CjguiComposableUiController {
    // The requested node count includes the root.  The remaining nodes are
    // buttons so every sample changes exactly two interaction paints.
    private let nodeCount: Int64

    init(nodeCount: Int64) {
        this.nodeCount = nodeCount
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9700, "native-cost-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 16000, gap: 0))
        let interaction = CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.30, 0.58, 0.94, 1.0)),
                border: Some(CjguiComposableUiColor(0.62, 0.84, 1.0, 1.0))))
        var index: Int64 = 1
        while (index < nodeCount) {
            root.add(cjguiComposableButton(9700 + index, "native-cost-${index}", "Action ${index}", "ACT", index,
                CjguiComposableUiStyle(fixedHeight: 18,
                    background: CjguiComposableUiColor(0.10, 0.12, 0.16, 1.0),
                    border: CjguiComposableUiColor(0.18, 0.22, 0.30, 1.0)),
                interactionStyle: interaction))
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

private func enqueue(session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString): Bool {
    return unsafe { cjgui_internal_renderer_test_enqueue_composable_event(session, nodeIndex, eventKind, text) } ==
        CJGUI_INTERNAL_RENDERER_OK
}

private func runNodeCount(nodeCount: Int64): Bool {
    let window = CjguiComposableUiWindow(InteractionCostController(nodeCount))
    if (!window.start()) {
        println("CJGUI_NATIVE_COST_RESULT nodes=${nodeCount} samples=0 valid=false reason=start")
        window.close()
        return false
    }
    let session = window.testSessionToken()
    let emptyText = unsafe { LibC.mallocCString("") }
    // Establish one accepted hover before the measured transitions.  Keeping
    // this outside the sample count prevents first-frame setup from entering
    // the reported interaction-resolution/compare distributions.
    if (!enqueue(session, 1u32, 43u32, emptyText) || !window.pump(0u32).isOpen) {
        unsafe { LibC.free(emptyText) }
        window.close()
        println("CJGUI_NATIVE_COST_RESULT nodes=${nodeCount} samples=0 valid=false reason=warmup")
        return false
    }

    var activeIndex: Int64 = 1
    var valid = true
    var sample: Int64 = 1
    while (sample <= SAMPLE_COUNT) {
        let nextIndex = if (activeIndex + 1 >= nodeCount) { 1 } else { activeIndex + 1 }
        let before = nativeCostCounters(session)
        let left = enqueue(session, UInt32(activeIndex), 44u32, emptyText)
        let entered = enqueue(session, UInt32(nextIndex), 43u32, emptyText)
        let turn = window.pump(0u32)
        let after = nativeCostCounters(session)
        let present = nativePresentTiming(session)
        let (encoderStatus, encoderMicros) = nativeEncoderCpuMicros(session)
        let timing = window.testRefreshTiming()
        let projection = window.windowProjection()
        let configureDelta = after.configureMicros - before.configureMicros
        let setDelta = after.setMicros - before.setMicros
        let commitDelta = after.commitMicros - before.commitMicros
        let nativeSplitNs = Int64(configureDelta + setDelta + commitDelta) * 1000
        // The remaining stage interval includes native staging/present work
        // that this scalar seam cannot split further: call it
        // native stage/present/drawable wait. It is deliberately not a
        // completed-frame or physical-presentation duration.
        let residualNs = if (timing.nativeStageAndSubmitNanoseconds >= nativeSplitNs) {
            timing.nativeStageAndSubmitNanoseconds - nativeSplitNs
        } else {
            0
        }
        let sampleValid = left && entered && turn.isOpen && before.status == CJGUI_INTERNAL_RENDERER_OK &&
            after.status == CJGUI_INTERNAL_RENDERER_OK && present.status == CJGUI_INTERNAL_RENDERER_OK &&
            encoderStatus == CJGUI_INTERNAL_RENDERER_OK &&
            projection.nodes.size == nodeCount &&
            timing.candidateNodeCount == nodeCount && timing.interactionPaintResolutionNanoseconds >= 0 &&
            // MonoTime has a finite resolution: a completed comparison can be
            // reported as 0 ns on a small scene.  Preserve that measurement
            // rather than treating it as an absent comparison.
            timing.interactionPaintComparisonNanoseconds >= 0 && timing.nativeStageAndSubmitNanoseconds >= 0 &&
            configureDelta >= 0u64 && setDelta >= 0u64 && commitDelta >= 0u64 && residualNs >= 0 &&
            projection.nativeSubmissionCount > 0
        println("CJGUI_NATIVE_COST_SAMPLE nodes=${nodeCount} sample=${sample} valid=${sampleValid} interaction_resolution_ns=${timing.interactionPaintResolutionNanoseconds} interaction_compare_ns=${timing.interactionPaintComparisonNanoseconds} native_configure_us=${configureDelta} native_set_us=${setDelta} native_commit_us=${commitDelta} native_stage_submit_ns=${timing.nativeStageAndSubmitNanoseconds} native_residual_ns=${residualNs} native_next_drawable_us=${present.nextDrawableMicros} native_command_buffer_us=${present.commandBufferMicros} native_encoder_cpu_us=${encoderMicros} native_present_us=${present.presentMicros} native_commit_call_us=${present.commitMicros} native_readback_wait_us=${present.readbackWaitMicros} native_readback_waited=${present.readbackWaited}")
        valid = valid && sampleValid
        activeIndex = nextIndex
        sample += 1
    }
    unsafe { LibC.free(emptyText) }
    window.close()
    println("CJGUI_NATIVE_COST_RESULT nodes=${nodeCount} samples=${SAMPLE_COUNT} valid=${valid}")
    return valid
}

main(): Int64 {
    let small = runNodeCount(8)
    let medium = runNodeCount(128)
    let large = runNodeCount(960)
    let passed = small && medium && large
    println("CJGUI_NATIVE_COST_SUMMARY nodes=8,128,960 samples_per_node=30 small=${small} medium=${medium} large=${large} valid=${passed}")
    return if (passed) { 0 } else { 1 }
}
