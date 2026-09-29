package cjgui

// Test-only scalar seams. The controller below remains an ordinary public
// vector consumer; these counters make cache and submission ownership visible
// without exporting Metal or native cache objects into the framework API.
foreign {
    func cjgui_internal_renderer_test_composable_encoder_stats(
        session: UInt64, outShapeNodeCount: CPointer<UInt32>, outShapeBatchCount: CPointer<UInt32>,
        outTextureDrawCount: CPointer<UInt32>, outShapeVertexBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_cpu_stats(
        session: UInt64, outEncodeMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_vector_submission_stats(
        session: UInt64, outDrawCount: CPointer<UInt32>, outBufferUploads: CPointer<UInt32>,
        outBufferReuses: CPointer<UInt32>, outBufferUploadBytes: CPointer<UInt64>, outResidentBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_clone_labels(
        session: UInt64, outBuffer: CPointer<UInt8>, capacity: UInt32, outWritten: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_vector_render_stats(
        session: UInt64, outSampleCount: CPointer<UInt8>, outMultisampleAttachmentBytes: CPointer<UInt64>,
        outPipelineBuildCount: CPointer<UInt64>, outGeometryPreparationCount: CPointer<UInt64>,
        outGeometryPreparedBytes: CPointer<UInt64>
    ): Int32
}

private class VectorGeometryCacheScaleController <: CjguiComposableUiController {
    private let objectCount: Int64
    private var revision: Int64
    private var localTint: Float64

    init(objectCount: Int64) {
        this.objectCount = objectCount
        this.revision = 1
        this.localTint = 0.20
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(880000, "vector-cache-scale-root-${objectCount}",
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
        var groupIndex: Int64 = 0
        var index: Int64 = 0
        // LayerHost intentionally bounds direct painter children. Compose
        // eight of those hosts through the normal vertical owner so all 480
        // values stay below the 1,024 native scene limit and none are silently
        // collapsed by one host's local layer capacity.
        while (index < objectCount) {
            let groupId = 900000 + groupIndex
            let groupKey = "vector-cache-scale-group-${objectCount}-${groupIndex}"
            let group = cjguiComposableLayerHost(groupId, groupKey,
                CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 2))
            var inGroup: Int64 = 0
            while (inGroup < 8 && index < objectCount) {
            // All accepted objects share geometry but own independent public
            // values. The local color change below targets index zero only;
            // it must neither reprepare other paths nor recreate their cache.
            let tint = if (index == 0) { localTint } else { 0.20 + Float64(index % 5) * 0.01 }
            let fill = CjguiComposableUiVectorColor(tint, 0.45, 0.84, 0.62)
            let stroke = CjguiComposableUiVectorColor(0.08, 0.20, 0.42, 0.90)
            let paint = CjguiComposableUiVectorPaint(Some(fill), Some(stroke), 1.5,
                CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
            let centerX = 18.0 + Float64((index * 17) % 204)
            let centerY = 18.0 + Float64((index * 11) % 124)
            let geometry = if (let Some(value) <- CjguiComposableUiVectorGeometry.ellipse(240.0, 160.0,
                CjguiComposableUiVectorPoint(centerX, centerY), 7.0, 5.0, paint)) { value } else { return root }
            let layer = cjguiComposableAnchoredLayer(880001 + index * 2, "vector-cache-scale-layer-${index}",
                "vector-cache-scale-layer-${index}", "popup", groupKey, groupId,
                CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
            layer.add(cjguiComposableVectorGraphic(880002 + index * 2, "vector-cache-scale-${index}", geometry,
                CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160)))
                group.add(layer)
                index += 1
                inGroup += 1
            }
            root.add(group)
            groupIndex += 1
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
    public func advanceLocalPaint(): Unit {
        localTint = if (localTint > 0.21) { 0.20 } else { 0.24 }
        revision += 1
    }
}

private func renderStats(session: UInt64): Array<UInt64> {
    var sampleCount: UInt8 = 0u8
    var attachmentBytes: UInt64 = 0u64
    var pipelineBuilds: UInt64 = 0u64
    var preparations: UInt64 = 0u64
    var preparedBytes: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_vector_render_stats(session,
        inout sampleCount, inout attachmentBytes, inout pipelineBuilds, inout preparations, inout preparedBytes) }
    return [UInt64(status), UInt64(sampleCount), attachmentBytes, pipelineBuilds, preparations, preparedBytes]
}

private func submissionStats(session: UInt64): Array<UInt64> {
    var clones: UInt64 = 0u64
    var allocations: UInt64 = 0u64
    var configureMicros: UInt64 = 0u64
    var setMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_scene_submission_stats(session,
        inout clones, inout allocations, inout configureMicros, inout setMicros, inout commitMicros) }
    return [UInt64(status), clones, allocations, configureMicros, setMicros, commitMicros]
}

private func vectorSubmissionStats(session: UInt64): Array<UInt64> {
    var drawCount: UInt32 = 0u32
    var bufferUploads: UInt32 = 0u32
    var bufferReuses: UInt32 = 0u32
    var uploadBytes: UInt64 = 0u64
    var residentBytes: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout drawCount, inout bufferUploads, inout bufferReuses, inout uploadBytes, inout residentBytes) }
    return [UInt64(status), UInt64(drawCount), UInt64(bufferUploads), UInt64(bufferReuses), uploadBytes, residentBytes]
}

private func runScale(objectCount: Int64): Bool {
    let controller = VectorGeometryCacheScaleController(objectCount)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return false
    }
    let session = window.testSessionToken()
    let beforeRender = renderStats(session)
    let beforeSubmission = submissionStats(session)
    let beforeVectorSubmission = vectorSubmissionStats(session)
    var sample: Int64 = 0
    var valid = beforeRender[0] == 0u64 && beforeRender[1] == 4u64 && beforeRender[2] > 0u64 &&
        beforeRender[4] >= UInt64(objectCount) && beforeRender[5] > 0u64 && beforeSubmission[0] == 0u64
    while (sample < 30) {
        // The first two samples are traced: the trace names every replaced
        // node and the first field that disagreed, which is the per-reason
        // record this tier needs.
        window.testSetSceneWriteTrace(sample < 2)
        controller.advanceLocalPaint()
        let refreshed = window.refresh()
        let timing = window.testRefreshTiming()
        valid = valid && refreshed && timing.candidateNodeCount == 1 + (objectCount + 7) / 8 + objectCount * 2 &&
            timing.buildNanoseconds >= 0 && timing.layoutNanoseconds >= 0 && timing.nativeStageAndSubmitNanoseconds >= 0
        println("CJGUI_VECTOR_SCALE_SAMPLE objects=${objectCount} sample=${sample} build_ns=${timing.buildNanoseconds} layout_ns=${timing.layoutNanoseconds} stage_submit_ns=${timing.nativeStageAndSubmitNanoseconds} nodes=${timing.candidateNodeCount}")
        sample += 1
    }
    let afterRender = renderStats(session)
    let afterSubmission = submissionStats(session)
    let afterVectorSubmission = vectorSubmissionStats(session)
    var shapeNodes: UInt32 = 0u32
    var shapeBatches: UInt32 = 0u32
    var textures: UInt32 = 0u32
    var vertexBytes: UInt64 = 0u64
    let encoderStatus = unsafe { cjgui_internal_renderer_test_composable_encoder_stats(session,
        inout shapeNodes, inout shapeBatches, inout textures, inout vertexBytes) }
    var encodeMicros: UInt64 = 0u64
    let cpuStatus = unsafe { cjgui_internal_renderer_test_composable_encoder_cpu_stats(session, inout encodeMicros) }
    let idleBefore = window.windowProjection()
    let idleAccepted = window.refreshIfNeeded()
    let idleAfter = window.windowProjection()
    valid = valid && afterRender[0] == 0u64 && afterRender[1] == 4u64 &&
        afterRender[3] == beforeRender[3] && afterRender[4] == beforeRender[4] && afterRender[5] == beforeRender[5] &&
        afterSubmission[0] == 0u64 && afterSubmission[1] - beforeSubmission[1] == 30u64 &&
        afterSubmission[2] - beforeSubmission[2] == 30u64 && encoderStatus == CJGUI_INTERNAL_RENDERER_OK &&
        // This is a vector-only scene. The legacy renderer expands every
        // triangle into 176-byte generic vertices and splits them at 4 KiB.
        // The resident buffer path must draw each vector once, upload on the
        // initial topology only, then reuse every buffer through 30 paint
        // updates without reclaiming accepted resident bytes.
        cpuStatus == CJGUI_INTERNAL_RENDERER_OK && shapeBatches <= UInt32(objectCount) && vertexBytes == 0u64 &&
        beforeVectorSubmission[0] == 0u64 && beforeVectorSubmission[1] == UInt64(objectCount) &&
        beforeVectorSubmission[2] == UInt64(objectCount) && beforeVectorSubmission[4] > 0u64 &&
        afterVectorSubmission[0] == 0u64 && afterVectorSubmission[1] == UInt64(objectCount) &&
        afterVectorSubmission[2] == 0u64 && afterVectorSubmission[3] == UInt64(objectCount) &&
        afterVectorSubmission[4] == 0u64 && afterVectorSubmission[5] == beforeVectorSubmission[5] &&
        idleAfter.nativeSubmissionCount == idleBefore.nativeSubmissionCount
    // Which nodes did those clones actually copy? A distinct-label count names
    // them, so a per-refresh rewrite of untouched structure is visible instead
    // of hiding behind one aggregate number.
    let labelCapacity: UInt32 = 8192u32
    let labelBuffer = Array<UInt8>(Int64(labelCapacity), repeat: 0u8)
    var labelWritten: UInt32 = 0u32
    var labelStatus: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    unsafe {
        let labelHandle = acquireArrayRawData(labelBuffer)
        labelStatus = cjgui_internal_renderer_test_composable_scene_clone_labels(session,
            labelHandle.pointer, labelCapacity, inout labelWritten)
        releaseArrayRawData(labelHandle)
    }
    let cloneLabels = if (labelStatus == CJGUI_INTERNAL_RENDERER_OK && labelWritten > 0u32) {
        String.fromUtf8(labelBuffer[..Int64(labelWritten)])
    } else {
        ""
    }
    println("CJGUI_VECTOR_SCALE_CLONES objects=${objectCount} status=${labelStatus} before=${beforeSubmission[1]} after=${afterSubmission[1]} labels=[${cloneLabels}]")
    println("CJGUI_VECTOR_SCALE_RESULT objects=${objectCount} samples=30 msaa=${afterRender[1]} attachment_bytes=${afterRender[2]} geometry_preparations=${beforeRender[4]}/${afterRender[4]} geometry_bytes=${beforeRender[5]}/${afterRender[5]} pipeline_builds=${beforeRender[3]}/${afterRender[3]} clones=${beforeSubmission[1]}/${afterSubmission[1]} allocations=${beforeSubmission[2]}/${afterSubmission[2]} generic_nodes=${shapeNodes} generic_batches=${shapeBatches} generic_vertex_bytes=${vertexBytes} vector_draws=${beforeVectorSubmission[1]}/${afterVectorSubmission[1]} vector_uploads=${beforeVectorSubmission[2]}/${afterVectorSubmission[2]} vector_reuses=${beforeVectorSubmission[3]}/${afterVectorSubmission[3]} vector_upload_bytes=${beforeVectorSubmission[4]}/${afterVectorSubmission[4]} vector_resident_bytes=${beforeVectorSubmission[5]}/${afterVectorSubmission[5]} encoder_cpu_us=${encodeMicros} idle_submission_delta=${idleAfter.nativeSubmissionCount - idleBefore.nativeSubmissionCount} passed=${valid}")
    window.close()
    return valid
}

main(): Int64 {
    // Every tier runs to completion. The earlier probe short-circuited after a
    // first-tier failure, so 128 and 480 were never actually measured.
    let tier16 = runScale(16)
    let tier128 = runScale(128)
    let tier480 = runScale(480)
    let passed = tier16 && tier128 && tier480
    println("CJGUI_VECTOR_SCALE_PROBE passed=${passed} tiers=16:${tier16},128:${tier128},480:${tier480}")
    return if (passed) { 0 } else { 1 }
}
