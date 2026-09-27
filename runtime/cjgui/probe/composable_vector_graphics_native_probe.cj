package cjgui

// Native seams are test-only transport for real overlay pointer delivery and
// drawable readback.  The controller below uses only the public vector value
// and component APIs; it owns the selected-state projection itself.
foreign {
    func cjgui_internal_renderer_test_activate_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>,
        outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_toggle_composable_backing_scale(
        session: UInt64, outResizeVersion: CPointer<UInt64>, outBeforeScale: CPointer<Float64>,
        outAfterScale: CPointer<Float64>, outDrawableWidth: CPointer<UInt32>, outDrawableHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_stats(
        session: UInt64, outShapeNodeCount: CPointer<UInt32>, outShapeBatchCount: CPointer<UInt32>,
        outTextureDrawCount: CPointer<UInt32>, outShapeVertexBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_batch_stats(
        session: UInt64, outVertexStride: CPointer<UInt32>, outMaxShapeBatchVertexBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_cpu_stats(
        session: UInt64, outEncodeMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_vector_submission_stats(
        session: UInt64, outDrawCount: CPointer<UInt32>, outBufferUploads: CPointer<UInt32>,
        outBufferReuses: CPointer<UInt32>, outBufferUploadBytes: CPointer<UInt64>, outResidentBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_vector_render_stats(
        session: UInt64, outSampleCount: CPointer<UInt8>, outMultisampleAttachmentBytes: CPointer<UInt64>,
        outPipelineBuildCount: CPointer<UInt64>, outGeometryPreparationCount: CPointer<UInt64>,
        outGeometryPreparedBytes: CPointer<UInt64>
    ): Int32
}

private class VectorNativeProbeController <: CjguiComposableUiController {
    private var revision: Int64
    private var selectedCount: Int64
    private var backgroundCount: Int64
    private var frameTint: Float64
    private var capacityPointCount: Int64

    init() {
        this.revision = 1
        this.selectedCount = 0
        this.backgroundCount = 0
        this.frameTint = 0.92
        this.capacityPointCount = 12
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableLayerHost(9700, "vector-native-root",
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 180))
        // The base button deliberately covers the exact eventual vector layer
        // bounds. A point inside that layer's layout rectangle but outside the
        // ellipse must activate this existing normal component, not disappear
        // into a bounding-box vector hit target.
        let base = cjguiComposableVertical(9702, "vector-native-base", CjguiComposableUiStyle())
        base.add(cjguiComposableButton(9704, "vector-native-background", "background",
            "BACKGROUND_ACTION", 7002, CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 180)))
        root.add(base)
        let layer = cjguiComposableAnchoredLayer(9703, "vector-native-layer", "vector-native-layer", "popup",
            "vector-native-root", 9700, CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
        let fill = CjguiComposableUiVectorColor(frameTint, 0.12, 0.18, 0.82)
        let stroke = CjguiComposableUiVectorColor(0.10, 0.68, 0.94, 1.0)
        let paint = CjguiComposableUiVectorPaint(Some(fill), Some(stroke), 3.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        let geometry = if (let Some(value) <- CjguiComposableUiVectorGeometry.ellipse(120.0, 80.0,
            CjguiComposableUiVectorPoint(60.0, 40.0), 34.0, 24.0, paint)) {
            value
        } else {
            // The public factory above is fixed valid data. Keep a plain
            // visible node if an unexpected value-layer regression occurs so
            // the probe fails at its explicit geometry assertions instead of
            // inventing a native fallback.
            return root
        }
        layer.add(cjguiComposableVectorGraphic(9701, "vector-native-ellipse", geometry,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160),
            interactive: true, actionName: "SELECT_VECTOR", resourceId: 7001))
        root.add(layer)

        // Independent layers are the framework's existing painter-order
        // composition primitive. They keep all geometry in one logical
        // 240x160 viewBox without installing a second canvas or layout owner.
        let lineLayer = cjguiComposableAnchoredLayer(9710, "vector-native-line-layer", "vector-native-line-layer",
            "popup", "vector-native-root", 9700, CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
        let linePaint = CjguiComposableUiVectorPaint(None,
            Some(CjguiComposableUiVectorColor(0.10, 0.68, 0.94, 1.0)), 4.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER)
        let line = if (let Some(value) <- CjguiComposableUiVectorGeometry.line(240.0, 160.0,
            CjguiComposableUiVectorPoint(0.5, 20.5), CjguiComposableUiVectorPoint(239.5, 20.5), linePaint)) {
            value
        } else { return root }
        lineLayer.add(cjguiComposableVectorGraphic(9711, "vector-native-line", line,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160)))
        root.add(lineLayer)

        let polylineLayer = cjguiComposableAnchoredLayer(9720, "vector-native-polyline-layer",
            "vector-native-polyline-layer", "popup", "vector-native-root", 9700,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
        let polylinePaint = CjguiComposableUiVectorPaint(None,
            Some(CjguiComposableUiVectorColor(0.12, 0.88, 0.35, 1.0)), 5.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_BEVEL)
        let polyline = if (let Some(value) <- CjguiComposableUiVectorGeometry.polyline(240.0, 160.0, [
            CjguiComposableUiVectorPoint(8.5, 142.5), CjguiComposableUiVectorPoint(60.5, 105.25),
            CjguiComposableUiVectorPoint(120.5, 132.5), CjguiComposableUiVectorPoint(190.5, 98.5),
            CjguiComposableUiVectorPoint(231.5, 130.5)
        ], polylinePaint)) { value } else { return root }
        polylineLayer.add(cjguiComposableVectorGraphic(9721, "vector-native-polyline", polyline,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160)))
        root.add(polylineLayer)

        // This simple concave polygon overlaps only the left portion of the
        // ellipse. Its alpha therefore has an observable ordered composite
        // while the ellipse centre remains an independent interaction target.
        let polygonLayer = cjguiComposableAnchoredLayer(9730, "vector-native-polygon-layer",
            "vector-native-polygon-layer", "popup", "vector-native-root", 9700,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160, clipsContent: true))
        let polygonPaint = CjguiComposableUiVectorPaint(
            Some(CjguiComposableUiVectorColor(0.15, 0.80, 0.92, 0.55)),
            Some(CjguiComposableUiVectorColor(0.98, 0.75, 0.15, 0.85)), 2.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        let polygon = if (let Some(value) <- CjguiComposableUiVectorGeometry.simplePolygon(240.0, 160.0, [
            CjguiComposableUiVectorPoint(50.5, 48.5), CjguiComposableUiVectorPoint(112.5, 48.5),
            CjguiComposableUiVectorPoint(112.5, 68.5), CjguiComposableUiVectorPoint(100.5, 82.5),
            CjguiComposableUiVectorPoint(112.5, 112.5), CjguiComposableUiVectorPoint(50.5, 112.5)
        ], polygonPaint)) { value } else { return root }
        polygonLayer.add(cjguiComposableVectorGraphic(9731, "vector-native-concave-polygon", polygon,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160)))
        root.add(polygonLayer)

        // This public polyline stays within the declared 12-point capacity.
        // The probe switches among 2/6/12 points below and reads actual GPU
        // encoder work; no timing threshold is treated as a product claim.
        let capacityLayer = cjguiComposableAnchoredLayer(9740, "vector-native-capacity-layer",
            "vector-native-capacity-layer", "popup", "vector-native-root", 9700,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160))
        let capacityPoints: Array<CjguiComposableUiVectorPoint> = if (capacityPointCount <= 2) {
            [CjguiComposableUiVectorPoint(8.5, 38.5), CjguiComposableUiVectorPoint(232.5, 32.5)]
        } else if (capacityPointCount <= 6) {
            [CjguiComposableUiVectorPoint(8.5, 38.5), CjguiComposableUiVectorPoint(48.5, 41.5),
                CjguiComposableUiVectorPoint(88.5, 43.5), CjguiComposableUiVectorPoint(128.5, 42.5),
                CjguiComposableUiVectorPoint(168.5, 44.5), CjguiComposableUiVectorPoint(232.5, 32.5)]
        } else {
            [CjguiComposableUiVectorPoint(8.5, 38.5), CjguiComposableUiVectorPoint(28.5, 31.5),
                CjguiComposableUiVectorPoint(48.5, 41.5), CjguiComposableUiVectorPoint(68.5, 30.5),
                CjguiComposableUiVectorPoint(88.5, 43.5), CjguiComposableUiVectorPoint(108.5, 29.5),
                CjguiComposableUiVectorPoint(128.5, 42.5), CjguiComposableUiVectorPoint(148.5, 31.5),
                CjguiComposableUiVectorPoint(168.5, 44.5), CjguiComposableUiVectorPoint(188.5, 30.5),
                CjguiComposableUiVectorPoint(208.5, 40.5), CjguiComposableUiVectorPoint(232.5, 32.5)]
        }
        let capacityPaint = CjguiComposableUiVectorPaint(None,
            Some(CjguiComposableUiVectorColor(0.72, 0.32, 0.94, 0.9)), 3.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        let capacityPolyline = if (let Some(value) <- CjguiComposableUiVectorGeometry.polyline(240.0, 160.0,
            capacityPoints, capacityPaint)) { value } else { return root }
        capacityLayer.add(cjguiComposableVectorGraphic(9741, "vector-native-capacity-polyline", capacityPolyline,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 160)))
        root.add(capacityLayer)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 9701 && event.eventKind == 27) {
            selectedCount += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.nodeId == 9704 && event.eventKind == 27) {
            backgroundCount += 1
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

    public func selected(): Int64 { return selectedCount }
    public func background(): Int64 { return backgroundCount }
    public func requestDrawableFrame(): Unit {
        frameTint = if (frameTint > 0.91) { 0.88 } else { 0.92 }
        revision += 1
    }
    public func setCapacityPointCount(count: Int64): Unit {
        capacityPointCount = count
        revision += 1
    }
}

private func vectorAcceptedGeometryClip(window: CjguiComposableUiWindow): String {
    var result = ""
    var found: Int64 = 0
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "vector-native-ellipse" || node.semanticId == "vector-native-concave-polygon") {
            result += "${node.semanticId}:${node.bounds.x},${node.bounds.y},${node.bounds.width},${node.bounds.height}:" +
                "${node.clip.x},${node.clip.y},${node.clip.width},${node.clip.height};"
            if (node.bounds.width > 0 && node.bounds.height > 0 && node.clip.width > 0 && node.clip.height > 0) {
                found += 1
            }
        }
    }
    return if (found == 2) { result } else { "" }
}

private func readPixel(session: UInt64, x: UInt32, y: UInt32): Array<UInt8> {
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let request = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, x, y) }
    let result = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout blue, inout green, inout red, inout alpha)
    }
    return [UInt8(if (request == CJGUI_INTERNAL_RENDERER_OK && result == CJGUI_INTERNAL_RENDERER_OK) { 1 } else { 0 }),
        red, green, blue, alpha]
}

// Same native probe, but an ordinary form/text scene. Its render-path facts
// prove this branch reaches the drawable without a private MSAA attachment.
private class NormalRenderPathProbeController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9800, "normal-render-path-root",
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 120))
        root.add(cjguiComposableText(9801, "normal-render-path-text", "ordinary text",
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 32)))
        root.add(cjguiComposableButton(9802, "normal-render-path-button", "ordinary button",
            "NORMAL", 9802, CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 40)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(true)
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

main(): Int64 {
    let normalController = NormalRenderPathProbeController()
    let normalWindow = CjguiComposableUiWindow(normalController)
    if (!normalWindow.start()) {
        println("CJGUI_VECTOR_NATIVE_PROBE normal_start=false native_status=${normalWindow.nativeStatus()}")
        return 1
    }
    let normalSession = normalWindow.testSessionToken()
    let normalRefresh = normalWindow.refresh()
    var normalSampleCount: UInt8 = 0u8
    var normalAttachmentBytes: UInt64 = 0u64
    var normalPipelineBuilds: UInt64 = 0u64
    var normalPreparations: UInt64 = 0u64
    var normalPreparedBytes: UInt64 = 0u64
    let normalStats = unsafe { cjgui_internal_renderer_test_composable_vector_render_stats(normalSession,
        inout normalSampleCount, inout normalAttachmentBytes, inout normalPipelineBuilds,
        inout normalPreparations, inout normalPreparedBytes) }
    normalWindow.close()
    let controller = VectorNativeProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_VECTOR_NATIVE_PROBE start=false native_status=${window.nativeStatus()}")
        return 1
    }
    let session = window.testSessionToken()
    // RED/GREEN coverage for an independent open-stroke sample.  It is
    // deliberately requested before the normal refresh below so a test cannot
    // accidentally read an old drawable and call that a line render.
    let lineRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 120u32, 20u32) }
    controller.requestDrawableFrame()
    let lineRefresh = window.refresh()
    var lineBlue: UInt8 = 0u8
    var lineGreen: UInt8 = 0u8
    var lineRed: UInt8 = 0u8
    var lineAlpha: UInt8 = 0u8
    let lineRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout lineBlue, inout lineGreen,
            inout lineRed, inout lineAlpha)
    }
    let polylineRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 190u32, 99u32) }
    controller.requestDrawableFrame()
    let polylineRefresh = window.refresh()
    var polylineBlue: UInt8 = 0u8
    var polylineGreen: UInt8 = 0u8
    var polylineRed: UInt8 = 0u8
    var polylineAlpha: UInt8 = 0u8
    let polylineRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout polylineBlue, inout polylineGreen,
            inout polylineRed, inout polylineAlpha)
    }
    let overlapRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 108u32, 64u32) }
    controller.requestDrawableFrame()
    let overlapRefresh = window.refresh()
    var overlapBlue: UInt8 = 0u8
    var overlapGreen: UInt8 = 0u8
    var overlapRed: UInt8 = 0u8
    var overlapAlpha: UInt8 = 0u8
    let overlapRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout overlapBlue, inout overlapGreen,
            inout overlapRed, inout overlapAlpha)
    }
    // The sample lies in the concave notch: it must retain the ellipse below
    // it. A convex-hull fill or a flattened screenshot would change this to
    // the cyan polygon composite observed at `overlap` above.
    let concaveNotchRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 107u32, 82u32) }
    controller.requestDrawableFrame()
    let concaveNotchRefresh = window.refresh()
    var concaveNotchBlue: UInt8 = 0u8
    var concaveNotchGreen: UInt8 = 0u8
    var concaveNotchRed: UInt8 = 0u8
    var concaveNotchAlpha: UInt8 = 0u8
    let concaveNotchRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout concaveNotchBlue, inout concaveNotchGreen,
            inout concaveNotchRed, inout concaveNotchAlpha)
    }
    // The first capture is requested before an ordinary forced projection;
    // it observes the actual next drawable rather than a cached bitmap.
    let centerRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 120u32, 80u32) }
    controller.requestDrawableFrame()
    let centerRefresh = window.refresh()
    var centerBlue: UInt8 = 0u8
    var centerGreen: UInt8 = 0u8
    var centerRed: UInt8 = 0u8
    var centerAlpha: UInt8 = 0u8
    let centerRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout centerBlue, inout centerGreen,
            inout centerRed, inout centerAlpha)
    }
    let hitStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(session, 120.0f32, 80.0f32) }
    let hitTurn = window.pump(0u32)
    // This point remains inside the vector node's 240x160 layer box, but is
    // outside its ellipse. A rectangle-only hit test would incorrectly route
    // a second SELECT_VECTOR action instead of its real button behind.
    let missStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(session, 18.0f32, 18.0f32) }
    let missTurn = window.pump(0u32)
    controller.setCapacityPointCount(2)
    let smallRefresh = window.refresh()
    var smallNodes: UInt32 = 0u32
    var smallBatches: UInt32 = 0u32
    var smallTextures: UInt32 = 0u32
    var smallVertexBytes: UInt64 = 0u64
    let smallStats = unsafe { cjgui_internal_renderer_test_composable_encoder_stats(session, inout smallNodes,
        inout smallBatches, inout smallTextures, inout smallVertexBytes) }
    var smallVectorDraws: UInt32 = 0u32
    var smallVectorUploads: UInt32 = 0u32
    var smallVectorReuses: UInt32 = 0u32
    var smallVectorUploadBytes: UInt64 = 0u64
    var smallVectorResidentBytes: UInt64 = 0u64
    let smallVectorStats = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout smallVectorDraws, inout smallVectorUploads, inout smallVectorReuses,
        inout smallVectorUploadBytes, inout smallVectorResidentBytes) }
    controller.setCapacityPointCount(6)
    let mediumRefresh = window.refresh()
    var mediumNodes: UInt32 = 0u32
    var mediumBatches: UInt32 = 0u32
    var mediumTextures: UInt32 = 0u32
    var mediumVertexBytes: UInt64 = 0u64
    let mediumStats = unsafe { cjgui_internal_renderer_test_composable_encoder_stats(session, inout mediumNodes,
        inout mediumBatches, inout mediumTextures, inout mediumVertexBytes) }
    var mediumVectorDraws: UInt32 = 0u32
    var mediumVectorUploads: UInt32 = 0u32
    var mediumVectorReuses: UInt32 = 0u32
    var mediumVectorUploadBytes: UInt64 = 0u64
    var mediumVectorResidentBytes: UInt64 = 0u64
    let mediumVectorStats = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout mediumVectorDraws, inout mediumVectorUploads, inout mediumVectorReuses,
        inout mediumVectorUploadBytes, inout mediumVectorResidentBytes) }
    controller.setCapacityPointCount(12)
    let capacityRefresh = window.refresh()
    var capacityNodes: UInt32 = 0u32
    var capacityBatches: UInt32 = 0u32
    var capacityTextures: UInt32 = 0u32
    var capacityVertexBytes: UInt64 = 0u64
    let capacityStats = unsafe { cjgui_internal_renderer_test_composable_encoder_stats(session, inout capacityNodes,
        inout capacityBatches, inout capacityTextures, inout capacityVertexBytes) }
    var capacityVectorDraws: UInt32 = 0u32
    var capacityVectorUploads: UInt32 = 0u32
    var capacityVectorReuses: UInt32 = 0u32
    var capacityVectorUploadBytes: UInt64 = 0u64
    var capacityVectorResidentBytes: UInt64 = 0u64
    let capacityVectorStats = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout capacityVectorDraws, inout capacityVectorUploads, inout capacityVectorReuses,
        inout capacityVectorUploadBytes, inout capacityVectorResidentBytes) }
    var capacityStride: UInt32 = 0u32
    var capacityMaxBatchBytes: UInt64 = 0u64
    let capacityBatchStats = unsafe { cjgui_internal_renderer_test_composable_encoder_batch_stats(session,
        inout capacityStride, inout capacityMaxBatchBytes) }
    var capacityEncodeMicros: UInt64 = 0u64
    let capacityCpuStats = unsafe { cjgui_internal_renderer_test_composable_encoder_cpu_stats(session,
        inout capacityEncodeMicros) }
    var vectorSampleCountBeforeIdle: UInt8 = 0u8
    var vectorAttachmentBytesBeforeIdle: UInt64 = 0u64
    var vectorPipelineBuildsBeforeIdle: UInt64 = 0u64
    var vectorPreparationsBeforeIdle: UInt64 = 0u64
    var vectorPreparedBytesBeforeIdle: UInt64 = 0u64
    let vectorStatsBeforeIdle = unsafe { cjgui_internal_renderer_test_composable_vector_render_stats(session,
        inout vectorSampleCountBeforeIdle, inout vectorAttachmentBytesBeforeIdle, inout vectorPipelineBuildsBeforeIdle,
        inout vectorPreparationsBeforeIdle, inout vectorPreparedBytesBeforeIdle) }
    var idleCommittedBefore: UInt32 = 0u32
    var idleUpdatesBefore: UInt64 = 0u64
    let idleBeforeStats = unsafe { cjgui_internal_renderer_test_composable_scene_update_stats(session,
        inout idleCommittedBefore, inout idleUpdatesBefore) }
    // Same scene version is an idle observation, not a geometry rebuild. The
    // generic window candidate path must retain this exact cached scene.
    let idleRefresh = window.refresh()
    var idleCommittedAfter: UInt32 = 0u32
    var idleUpdatesAfter: UInt64 = 0u64
    let idleAfterStats = unsafe { cjgui_internal_renderer_test_composable_scene_update_stats(session,
        inout idleCommittedAfter, inout idleUpdatesAfter) }
    var vectorSampleCountAfterIdle: UInt8 = 0u8
    var vectorAttachmentBytesAfterIdle: UInt64 = 0u64
    var vectorPipelineBuildsAfterIdle: UInt64 = 0u64
    var vectorPreparationsAfterIdle: UInt64 = 0u64
    var vectorPreparedBytesAfterIdle: UInt64 = 0u64
    let vectorStatsAfterIdle = unsafe { cjgui_internal_renderer_test_composable_vector_render_stats(session,
        inout vectorSampleCountAfterIdle, inout vectorAttachmentBytesAfterIdle, inout vectorPipelineBuildsAfterIdle,
        inout vectorPreparationsAfterIdle, inout vectorPreparedBytesAfterIdle) }
    let scaleGeometryClipBefore = vectorAcceptedGeometryClip(window)
    var scaleOneResize: UInt64 = 0u64
    var scaleOneBefore: Float64 = 0.0
    var scaleOneAfter: Float64 = 0.0
    var scaleOneWidth: UInt32 = 0u32
    var scaleOneHeight: UInt32 = 0u32
    let scaleOneStatus = unsafe { cjgui_internal_renderer_test_toggle_composable_backing_scale(session,
        inout scaleOneResize, inout scaleOneBefore, inout scaleOneAfter, inout scaleOneWidth, inout scaleOneHeight) }
    let scaleOneRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 120u32, 20u32) }
    controller.requestDrawableFrame()
    let scaleOneRefresh = window.refresh()
    var scaleOneBlue: UInt8 = 0u8
    var scaleOneGreen: UInt8 = 0u8
    var scaleOneRed: UInt8 = 0u8
    var scaleOneAlpha: UInt8 = 0u8
    let scaleOneRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout scaleOneBlue, inout scaleOneGreen,
            inout scaleOneRed, inout scaleOneAlpha)
    }
    var scaleOneVectorDraws: UInt32 = 0u32
    var scaleOneVectorUploads: UInt32 = 0u32
    var scaleOneVectorReuses: UInt32 = 0u32
    var scaleOneVectorUploadBytes: UInt64 = 0u64
    var scaleOneVectorResidentBytes: UInt64 = 0u64
    let scaleOneVectorStats = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout scaleOneVectorDraws, inout scaleOneVectorUploads, inout scaleOneVectorReuses,
        inout scaleOneVectorUploadBytes, inout scaleOneVectorResidentBytes) }
    // At 1x, this sample crosses the fractional outer edge of the 4-point
    // line (20.5 +/- 2). It should be neither untouched button background
    // nor fully blue stroke after the normal MSAA resolve.
    let antialiasRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 120u32, 18u32) }
    controller.requestDrawableFrame()
    let antialiasRefresh = window.refresh()
    var antialiasBlue: UInt8 = 0u8
    var antialiasGreen: UInt8 = 0u8
    var antialiasRed: UInt8 = 0u8
    var antialiasAlpha: UInt8 = 0u8
    let antialiasRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout antialiasBlue, inout antialiasGreen,
            inout antialiasRed, inout antialiasAlpha)
    }
    var scaleTwoResize: UInt64 = 0u64
    var scaleTwoBefore: Float64 = 0.0
    var scaleTwoAfter: Float64 = 0.0
    var scaleTwoWidth: UInt32 = 0u32
    var scaleTwoHeight: UInt32 = 0u32
    let scaleTwoStatus = unsafe { cjgui_internal_renderer_test_toggle_composable_backing_scale(session,
        inout scaleTwoResize, inout scaleTwoBefore, inout scaleTwoAfter, inout scaleTwoWidth, inout scaleTwoHeight) }
    let scaleTwoRequest = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 120u32, 20u32) }
    controller.requestDrawableFrame()
    let scaleTwoRefresh = window.refresh()
    var scaleTwoBlue: UInt8 = 0u8
    var scaleTwoGreen: UInt8 = 0u8
    var scaleTwoRed: UInt8 = 0u8
    var scaleTwoAlpha: UInt8 = 0u8
    let scaleTwoRead = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout scaleTwoBlue, inout scaleTwoGreen,
            inout scaleTwoRed, inout scaleTwoAlpha)
    }
    var scaleTwoVectorDraws: UInt32 = 0u32
    var scaleTwoVectorUploads: UInt32 = 0u32
    var scaleTwoVectorReuses: UInt32 = 0u32
    var scaleTwoVectorUploadBytes: UInt64 = 0u64
    var scaleTwoVectorResidentBytes: UInt64 = 0u64
    let scaleTwoVectorStats = unsafe { cjgui_internal_renderer_test_composable_vector_submission_stats(session,
        inout scaleTwoVectorDraws, inout scaleTwoVectorUploads, inout scaleTwoVectorReuses,
        inout scaleTwoVectorUploadBytes, inout scaleTwoVectorResidentBytes) }
    let passed = normalRefresh && normalStats == CJGUI_INTERNAL_RENDERER_OK && normalSampleCount == 1u8 &&
        normalAttachmentBytes == 0u64 && normalPreparations == 0u64 && lineRequest == CJGUI_INTERNAL_RENDERER_OK && lineRefresh &&
        lineRead == CJGUI_INTERNAL_RENDERER_OK && lineRed <= 80u8 && lineGreen >= 120u8 && lineBlue >= 180u8 &&
        lineAlpha >= 180u8 && polylineRequest == CJGUI_INTERNAL_RENDERER_OK && polylineRefresh &&
        polylineRead == CJGUI_INTERNAL_RENDERER_OK && polylineRed <= 80u8 && polylineGreen >= 170u8 &&
        polylineBlue <= 130u8 && polylineAlpha >= 180u8 && overlapRequest == CJGUI_INTERNAL_RENDERER_OK &&
        overlapRefresh && overlapRead == CJGUI_INTERNAL_RENDERER_OK && overlapRed >= 75u8 && overlapRed <= 150u8 &&
        overlapGreen >= 95u8 && overlapGreen <= 170u8 && overlapBlue >= 120u8 && overlapBlue <= 190u8 &&
        overlapAlpha >= 180u8 && concaveNotchRequest == CJGUI_INTERNAL_RENDERER_OK && concaveNotchRefresh &&
        concaveNotchRead == CJGUI_INTERNAL_RENDERER_OK && concaveNotchRed >= 160u8 && concaveNotchGreen <= 90u8 &&
        concaveNotchBlue <= 110u8 && concaveNotchAlpha >= 180u8 &&
        centerRequest == CJGUI_INTERNAL_RENDERER_OK && centerRefresh &&
        centerRead == CJGUI_INTERNAL_RENDERER_OK && centerRed >= 160u8 && centerGreen <= 90u8 &&
        centerBlue <= 110u8 && centerAlpha >= 180u8 && hitStatus == CJGUI_INTERNAL_RENDERER_OK &&
        hitTurn.didApplyHumanAction && controller.selected() == 1 && missStatus == CJGUI_INTERNAL_RENDERER_OK &&
        missTurn.didApplyHumanAction && controller.selected() == 1 && controller.background() == 1 &&
        smallRefresh && smallStats == CJGUI_INTERNAL_RENDERER_OK && smallNodes == 0u32 && smallBatches == 0u32 &&
        smallVertexBytes == 0u64 && smallVectorStats == CJGUI_INTERNAL_RENDERER_OK && smallVectorDraws >= 5u32 &&
        smallVectorUploads == 1u32 && smallVectorReuses + smallVectorUploads == smallVectorDraws && smallVectorUploadBytes > 0u64 &&
        mediumRefresh && mediumStats == CJGUI_INTERNAL_RENDERER_OK && mediumNodes == 0u32 && mediumBatches == 0u32 &&
        mediumVertexBytes == 0u64 && mediumVectorStats == CJGUI_INTERNAL_RENDERER_OK && mediumVectorDraws == smallVectorDraws &&
        mediumVectorUploads == 1u32 && mediumVectorReuses + mediumVectorUploads == mediumVectorDraws &&
        mediumVectorUploadBytes > smallVectorUploadBytes && capacityRefresh && capacityStats == CJGUI_INTERNAL_RENDERER_OK &&
        capacityNodes == 0u32 && capacityBatches == 0u32 && capacityVertexBytes == 0u64 &&
        capacityVectorStats == CJGUI_INTERNAL_RENDERER_OK && capacityVectorDraws == smallVectorDraws &&
        capacityVectorUploads == 1u32 && capacityVectorReuses + capacityVectorUploads == capacityVectorDraws &&
        capacityVectorUploadBytes > mediumVectorUploadBytes && capacityVectorResidentBytes > mediumVectorResidentBytes &&
        capacityBatchStats == CJGUI_INTERNAL_RENDERER_OK && capacityStride > 0u32 && capacityMaxBatchBytes == 0u64 &&
        capacityCpuStats == CJGUI_INTERNAL_RENDERER_OK &&
        idleBeforeStats == CJGUI_INTERNAL_RENDERER_OK && idleRefresh && idleAfterStats == CJGUI_INTERNAL_RENDERER_OK &&
        idleCommittedBefore == idleCommittedAfter && idleUpdatesBefore == idleUpdatesAfter &&
        vectorStatsBeforeIdle == CJGUI_INTERNAL_RENDERER_OK && vectorStatsAfterIdle == CJGUI_INTERNAL_RENDERER_OK &&
        vectorSampleCountBeforeIdle == 4u8 && vectorAttachmentBytesBeforeIdle > 0u64 &&
        vectorSampleCountAfterIdle == 4u8 && vectorAttachmentBytesAfterIdle > 0u64 &&
        vectorPipelineBuildsAfterIdle == vectorPipelineBuildsBeforeIdle &&
        vectorPreparationsAfterIdle == vectorPreparationsBeforeIdle &&
        vectorPreparedBytesAfterIdle == vectorPreparedBytesBeforeIdle &&
        scaleOneStatus == CJGUI_INTERNAL_RENDERER_OK && scaleOneResize > 0u64 && scaleOneBefore != scaleOneAfter &&
        scaleOneWidth > 0u32 && scaleOneHeight > 0u32 && scaleOneRequest == CJGUI_INTERNAL_RENDERER_OK && scaleOneRefresh &&
        scaleOneRead == CJGUI_INTERNAL_RENDERER_OK && scaleOneRed <= 80u8 && scaleOneGreen >= 120u8 && scaleOneBlue >= 180u8 &&
        scaleOneVectorStats == CJGUI_INTERNAL_RENDERER_OK && scaleOneVectorDraws == capacityVectorDraws &&
        scaleOneVectorUploads == 0u32 && scaleOneVectorReuses == scaleOneVectorDraws && scaleOneVectorUploadBytes == 0u64 &&
        scaleOneVectorResidentBytes == capacityVectorResidentBytes &&
        antialiasRequest == CJGUI_INTERNAL_RENDERER_OK && antialiasRefresh && antialiasRead == CJGUI_INTERNAL_RENDERER_OK &&
        antialiasRed > 20u8 && antialiasRed < 26u8 && antialiasGreen > 41u8 && antialiasGreen < 173u8 &&
        antialiasBlue > 51u8 && antialiasBlue < 240u8 && antialiasAlpha >= 180u8 &&
        scaleTwoStatus == CJGUI_INTERNAL_RENDERER_OK && scaleTwoResize > scaleOneResize && scaleTwoBefore != scaleTwoAfter &&
        scaleTwoWidth > 0u32 && scaleTwoHeight > 0u32 && scaleTwoRequest == CJGUI_INTERNAL_RENDERER_OK && scaleTwoRefresh &&
        scaleTwoRead == CJGUI_INTERNAL_RENDERER_OK && scaleTwoRed <= 80u8 && scaleTwoGreen >= 120u8 && scaleTwoBlue >= 180u8 &&
        scaleTwoVectorStats == CJGUI_INTERNAL_RENDERER_OK && scaleTwoVectorDraws == capacityVectorDraws &&
        scaleTwoVectorUploads == 0u32 && scaleTwoVectorReuses == scaleTwoVectorDraws && scaleTwoVectorUploadBytes == 0u64 &&
        scaleTwoVectorResidentBytes == capacityVectorResidentBytes
    let scaleGeometryClipAfter = vectorAcceptedGeometryClip(window)
    let scaleHitStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(session, 120.0f32, 80.0f32) }
    let scaleHitTurn = window.pump(0u32)
    let scaleMissStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(session, 18.0f32, 18.0f32) }
    let scaleMissTurn = window.pump(0u32)
    let scaleConsumption = scaleOneAfter == 1.0 && scaleTwoAfter == 2.0 &&
        scaleGeometryClipBefore.size > 0 && scaleGeometryClipAfter == scaleGeometryClipBefore &&
        scaleHitStatus == CJGUI_INTERNAL_RENDERER_OK && scaleHitTurn.didApplyHumanAction &&
        scaleMissStatus == CJGUI_INTERNAL_RENDERER_OK && scaleMissTurn.didApplyHumanAction &&
        controller.selected() == 2 && controller.background() == 2
    println("CJGUI_VECTOR_SCALE_CONSUMPTION scale=${scaleOneAfter}->${scaleTwoAfter} " +
        "accepted_geometry_clip_stable=${scaleGeometryClipAfter == scaleGeometryClipBefore} " +
        "hit=${scaleHitStatus}/${scaleHitTurn.didApplyHumanAction} " +
        "miss=${scaleMissStatus}/${scaleMissTurn.didApplyHumanAction} " +
        "edge_rgba=${scaleOneRed},${scaleOneGreen},${scaleOneBlue},${scaleOneAlpha}->" +
        "${scaleTwoRed},${scaleTwoGreen},${scaleTwoBlue},${scaleTwoAlpha} passed=${scaleConsumption}")
    println("CJGUI_VECTOR_NATIVE_PROBE line_request=${lineRequest} line_refresh=${lineRefresh} line_read=${lineRead} line_rgba=${lineRed},${lineGreen},${lineBlue},${lineAlpha} polyline_request=${polylineRequest} polyline_refresh=${polylineRefresh} polyline_read=${polylineRead} polyline_rgba=${polylineRed},${polylineGreen},${polylineBlue},${polylineAlpha} overlap_request=${overlapRequest} overlap_refresh=${overlapRefresh} overlap_read=${overlapRead} overlap_rgba=${overlapRed},${overlapGreen},${overlapBlue},${overlapAlpha} notch_request=${concaveNotchRequest} notch_refresh=${concaveNotchRefresh} notch_read=${concaveNotchRead} notch_rgba=${concaveNotchRed},${concaveNotchGreen},${concaveNotchBlue},${concaveNotchAlpha} center_request=${centerRequest} center_refresh=${centerRefresh} center_read=${centerRead} center_rgba=${centerRed},${centerGreen},${centerBlue},${centerAlpha} hit_status=${hitStatus} hit_turn=${hitTurn.didApplyHumanAction} miss_status=${missStatus} miss_turn=${missTurn.didApplyHumanAction} capacity_generic_vertices=${smallVertexBytes}/${mediumVertexBytes}/${capacityVertexBytes} capacity_generic_nodes=${smallNodes}/${mediumNodes}/${capacityNodes} capacity_generic_batches=${smallBatches}/${mediumBatches}/${capacityBatches} capacity_vector_draws=${smallVectorDraws}/${mediumVectorDraws}/${capacityVectorDraws} capacity_vector_uploads=${smallVectorUploads}/${mediumVectorUploads}/${capacityVectorUploads} capacity_vector_upload_bytes=${smallVectorUploadBytes}/${mediumVectorUploadBytes}/${capacityVectorUploadBytes} capacity_vector_resident_bytes=${smallVectorResidentBytes}/${mediumVectorResidentBytes}/${capacityVectorResidentBytes} capacity_stride=${capacityStride} capacity_max_batch_bytes=${capacityMaxBatchBytes} capacity_cpu_us=${capacityEncodeMicros} vector_msaa=${vectorSampleCountBeforeIdle}/${vectorSampleCountAfterIdle} vector_attachment_bytes=${vectorAttachmentBytesBeforeIdle}/${vectorAttachmentBytesAfterIdle} vector_pipeline_builds=${vectorPipelineBuildsBeforeIdle}/${vectorPipelineBuildsAfterIdle} vector_geometry_preparations=${vectorPreparationsBeforeIdle}/${vectorPreparationsAfterIdle} vector_geometry_bytes=${vectorPreparedBytesBeforeIdle}/${vectorPreparedBytesAfterIdle} idle_nodes=${idleCommittedBefore}/${idleCommittedAfter} idle_updates=${idleUpdatesBefore}/${idleUpdatesAfter} scale1_status=${scaleOneStatus} scale1=${scaleOneBefore}->${scaleOneAfter}@${scaleOneWidth}x${scaleOneHeight} scale1_pixel=${scaleOneRed},${scaleOneGreen},${scaleOneBlue},${scaleOneAlpha} scale1_vector=${scaleOneVectorDraws}/${scaleOneVectorUploads}/${scaleOneVectorReuses}/${scaleOneVectorResidentBytes} antialias_pixel=${antialiasRed},${antialiasGreen},${antialiasBlue},${antialiasAlpha} scale2_status=${scaleTwoStatus} scale2=${scaleTwoBefore}->${scaleTwoAfter}@${scaleTwoWidth}x${scaleTwoHeight} scale2_pixel=${scaleTwoRed},${scaleTwoGreen},${scaleTwoBlue},${scaleTwoAlpha} scale2_vector=${scaleTwoVectorDraws}/${scaleTwoVectorUploads}/${scaleTwoVectorReuses}/${scaleTwoVectorResidentBytes} selected=${controller.selected()} background=${controller.background()} passed=${passed && scaleConsumption}")
    println("CJGUI_VECTOR_RENDER_PATH normal_msaa=${normalSampleCount} normal_attachment_bytes=${normalAttachmentBytes} normal_pipeline_builds=${normalPipelineBuilds} normal_geometry_preparations=${normalPreparations} vector_msaa=${vectorSampleCountBeforeIdle}/${vectorSampleCountAfterIdle} vector_attachment_bytes=${vectorAttachmentBytesBeforeIdle}/${vectorAttachmentBytesAfterIdle} vector_pipeline_builds=${vectorPipelineBuildsBeforeIdle}/${vectorPipelineBuildsAfterIdle} vector_geometry_preparations=${vectorPreparationsBeforeIdle}/${vectorPreparationsAfterIdle}")
    window.close()
    return if (passed && scaleConsumption) { 0 } else { 1 }
}
