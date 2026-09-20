package cjgui_ui_only_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*
import std.env.*

private let VECTOR_RECORD_ID: Int64 = 7401

private func vectorColor(red: Float64, green: Float64, blue: Float64, alpha: Float64): CjguiComposableUiVectorColor {
    return CjguiComposableUiVectorColor(red, green, blue, alpha)
}

// Public-only chart/icon consumer. It keeps the chart data in the controller
// and submits ordinary vector nodes; there is no canvas or private renderer
// path in the consumer.
private class VectorChartController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private var ordinaryPointerCount: Int64

    init() {
        this.ordinaryPointerCount = 0
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "vector-chart-root",
            CjguiComposableUiStyle(padding: 12, gap: 6, background: CjguiComposableUiColor(0.04, 0.06, 0.10, 1.0)))
        root.add(cjguiComposableText(2, "vector-chart-title", "纯 UI 矢量图表消费者",
            CjguiComposableUiStyle(fixedHeight: 24)))
        let stroke = CjguiComposableUiVectorPaint(None,
            Some(vectorColor(0.22, 0.74, 0.98, 1.0)), 2.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        let fillStroke = CjguiComposableUiVectorPaint(
            Some(vectorColor(0.22, 0.74, 0.98, 0.22)),
            Some(vectorColor(0.22, 0.74, 0.98, 0.9)), 1.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER)
        let axis = if (let Some(value) <- CjguiComposableUiVectorGeometry.line(
            320.0, 180.0, CjguiComposableUiVectorPoint(16.0, 164.0),
            CjguiComposableUiVectorPoint(304.0, 164.0), stroke)) { value } else { return root }
        let trendPoints: Array<CjguiComposableUiVectorPoint> = [
            CjguiComposableUiVectorPoint(24.0, 140.0),
            CjguiComposableUiVectorPoint(84.0, 124.0),
            CjguiComposableUiVectorPoint(144.0, 132.0),
            CjguiComposableUiVectorPoint(208.0, 88.0),
            CjguiComposableUiVectorPoint(280.0, 56.0)
        ]
        let trend = if (let Some(value) <- CjguiComposableUiVectorGeometry.polyline(
            320.0, 180.0, trendPoints, stroke)) { value } else { return root }
        let areaPoints: Array<CjguiComposableUiVectorPoint> = [
            CjguiComposableUiVectorPoint(24.0, 140.0),
            CjguiComposableUiVectorPoint(84.0, 124.0),
            CjguiComposableUiVectorPoint(144.0, 132.0),
            CjguiComposableUiVectorPoint(208.0, 88.0),
            CjguiComposableUiVectorPoint(280.0, 56.0),
            CjguiComposableUiVectorPoint(280.0, 164.0),
            CjguiComposableUiVectorPoint(24.0, 164.0)
        ]
        let area = if (let Some(value) <- CjguiComposableUiVectorGeometry.simplePolygon(
            320.0, 180.0, areaPoints, fillStroke)) { value } else { return root }
        // `LayerHost` is the existing Cangjie-owned order/identity owner:
        // area, trend and axis share one coordinate plane and paint in that
        // declaration order. No consumer needs a canvas, absolute layout, or
        // native handle merely to compose a chart.
        let chart = cjguiComposableLayerHost(9, "vector-chart-canvas",
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180, clipsContent: true))
        chart.add(cjguiComposableVectorGraphic(10, "vector-chart-area", area,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180)))
        let trendLayer = cjguiComposableAnchoredLayer(11, "vector-chart-trend-layer", "vector-chart-trend-layer",
            "popup", "vector-chart-area", 10, CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180))
        trendLayer.add(cjguiComposableVectorGraphic(12, "vector-chart-trend", trend,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180)))
        chart.add(trendLayer)
        let axisLayer = cjguiComposableAnchoredLayer(13, "vector-chart-axis-layer", "vector-chart-axis-layer",
            "popup", "vector-chart-area", 10, CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180))
        axisLayer.add(cjguiComposableVectorGraphic(14, "vector-chart-axis", axis,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180)))
        chart.add(axisLayer)
        root.add(chart)
        root.add(cjguiComposableText(15, "vector-chart-readback", "line + polyline + simple polygon",
            CjguiComposableUiStyle(fixedHeight: 22), resourceId: 7410,
            fieldId: "chartShapeKinds", displayValueRole: "vector", operationResourceId: 7410))
        root.add(cjguiComposableButton(16, "vector-chart-input", "普通输入",
            "CHART_INPUT", 7411, CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 26)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 16 && event.eventKind == 27) {
            ordinaryPointerCount += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("chart.input", CjguiComposableUiNodeReference.manual(16),
                "图表普通输入", CjguiComposableUiShortcut("i"), "Vector", 0, true, false)
        ])
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func ordinaryInputCount(): Int64 { return ordinaryPointerCount }
}

// Shared-operation consumer: the list owns the durable boolean; the vector
// fill color is only its window projection. Human and external actions both
// end in the same list owner and therefore share version/CAS truth.
private class VectorSharedOperationController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let list: CjguiSharedOperationList
    private var backgroundCountValue: Int64

    init(list: CjguiSharedOperationList) {
        this.list = list
        this.backgroundCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return list.version() + 1 }

    private func marked(): Bool { return list.snapshot().recordAt(0).isMarked }

    private func ellipseGeometry(isMarked: Bool): ?CjguiComposableUiVectorGeometry {
        // The external SET_MARKED write changes the actual geometry center and
        // radius as well as paint. This keeps one durable owner while making
        // hit-test movement independently observable.
        let center = if (isMarked) {
            CjguiComposableUiVectorPoint(130.0, 85.0)
        } else {
            CjguiComposableUiVectorPoint(80.0, 55.0)
        }
        let radiusX = if (isMarked) { 24.0 } else { 42.0 }
        let radiusY = if (isMarked) { 20.0 } else { 30.0 }
        let fill = if (isMarked) {
            vectorColor(0.94, 0.32, 0.18, 0.86)
        } else {
            vectorColor(0.16, 0.52, 0.92, 0.86)
        }
        let stroke = vectorColor(0.98, 0.86, 0.30, 1.0)
        let paint = CjguiComposableUiVectorPaint(Some(fill), Some(stroke), 3.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        return CjguiComposableUiVectorGeometry.ellipse(160.0, 110.0, center, radiusX, radiusY, paint)
    }

    public func buildUi(): CjguiComposableUiNode {
        let isMarked = marked()
        let geometry = if (let Some(value) <- ellipseGeometry(isMarked)) {
            value
        } else {
            return cjguiComposableVertical(20, "vector-shared-empty", CjguiComposableUiStyle())
        }
        let root = cjguiComposableVertical(20, "vector-shared-root", CjguiComposableUiStyle(padding: 12, gap: 6))
        root.add(cjguiComposableText(21, "vector-shared-title", "共同操作矢量对象",
            CjguiComposableUiStyle(fixedHeight: 24)))
        // The background button and vector share one LayerHost. A point that
        // used to hit the old ellipse must fall through to this ordinary
        // component after an external geometry move.
        let canvas = cjguiComposableLayerHost(25, "vector-shared-canvas",
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220, clipsContent: true))
        canvas.add(cjguiComposableButton(26, "vector-shared-background", "shared background",
            "SHARED_BACKGROUND", VECTOR_RECORD_ID, CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220)))
        let graphicLayer = cjguiComposableAnchoredLayer(27, "vector-shared-graphic-layer",
            "vector-shared-graphic-layer", "popup", "vector-shared-background", 26,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220))
        graphicLayer.add(cjguiComposableVectorGraphic(22, "vector-shared-graphic", geometry,
            CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 220),
            interactive: true, actionName: "TOGGLE_VECTOR", resourceId: VECTOR_RECORD_ID,
            operationActionName: "SET_MARKED",
            operationResourceId: VECTOR_RECORD_ID))
        canvas.add(graphicLayer)
        root.add(canvas)
        root.add(cjguiComposableText(23, "vector-shared-state",
            if (isMarked) { "marked=true color=coral" } else { "marked=false color=blue" },
            CjguiComposableUiStyle(fixedHeight: 24), resourceId: VECTOR_RECORD_ID,
            fieldId: "isMarked", displayValueRole: "vector-state", operationResourceId: VECTOR_RECORD_ID))
        root.add(cjguiComposableText(24, "vector-shared-geometry",
            if (isMarked) { "ellipse center=130,85 radius=24,20" } else { "ellipse center=80,55 radius=42,30" },
            CjguiComposableUiStyle(fixedHeight: 24), resourceId: VECTOR_RECORD_ID,
            fieldId: "ellipseGeometry", displayValueRole: "vector-geometry", operationResourceId: VECTOR_RECORD_ID))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_VECTOR") {
            return CjguiComposableUiDispatchResult(list.toggleFromHuman(VECTOR_RECORD_ID).applied)
        }
        if (event.eventKind == 27 && event.node.nodeId == 26) {
            backgroundCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        // The vector is an ordinary pointer target, not a duplicate command
        // surface. The sibling chart below carries the normal command-input
        // proof; keeping this list empty preserves one owner for vector
        // toggles (the shared-operation list).
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func backgroundPointerCount(): Int64 { return backgroundCountValue }
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "cjgui-vector-consumer", "cjgui-vector-consumer-20260914",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([VECTOR_RECORD_ID]), false)
        ]))
}

private func readMarked(list: CjguiSharedOperationList): Bool {
    return list.snapshot().recordAt(0).isMarked
}

private func verifyPublicConsumers(): Int64 {
    let list = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(VECTOR_RECORD_ID, "矢量对象", false)
    ]))
    let chart = VectorChartController()
    let shared = VectorSharedOperationController(list)
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let chartOpen = application.openWindow(chart,
        configuration: CjguiMacosApplicationWindowConfiguration("Vector Chart Consumer", 420u32, 300u32))
    let sharedOpen = application.openWindow(shared,
        configuration: CjguiMacosApplicationWindowConfiguration("Vector Shared Consumer", 420u32, 300u32))
    if (!chartOpen.didOpen || !sharedOpen.didOpen) {
        println("CJGUI_VECTOR_PUBLIC_FAILURE stage=open chart=${chartOpen.reason} shared=${sharedOpen.reason}")
        application.close()
        return 1
    }
    let chartId = if (let Some(value) <- chartOpen.identifier) { value } else { application.close(); return 2 }
    let sharedId = if (let Some(value) <- sharedOpen.identifier) { value } else { application.close(); return 3 }
    let connection = CjguiSharedOperationExternalConnection(list, authorization())
    if (!connection.enableWindowProjectionTargetReads(application) ||
        !application.attachExternalConnection(connection)) {
        println("CJGUI_VECTOR_PUBLIC_FAILURE stage=attach_external")
        application.close(); return 4
    }
    var descriptorPath = ""
    if (let Some(info) <- connection.connectionInfo()) {
        descriptorPath = info.descriptorPath
    } else {
        println("CJGUI_VECTOR_PUBLIC_FAILURE stage=connection_info")
        application.close()
        return 5
    }
    println("CJGUI_VECTOR_PUBLIC_READY DESCRIPTOR_PATH ${descriptorPath} CHART_TARGET ${chartId.value} SHARED_TARGET ${sharedId.value}")
    getStdOut().flush()
    let chartWindow = if (let Some(value) <- application.window(chartId)) { value } else { application.close(); return 8 }
    var turns: Int64 = 0
    var externalApplied = false
    var testVariantMixedInputSameTurn = false
    var testVariantChartPointerApplied = false
    // The normal owner-turn loop, not renderer cost, bounds the UDS rendezvous.
    // A faster GPU submission must not make a valid external client lose its
    // descriptor before it can issue the authorized write.
    let externalWaitStarted = MonoTime.now()
    while (application.isOpen() && !externalApplied &&
        (MonoTime.now() - externalWaitStarted).toMilliseconds() < 3000) {
        // TEST_VARIANT_MIXED_TURN_BEGIN
        let turn = application.pumpOneTurn(turnBudgetMs: 4u32)
        // TEST_VARIANT_MIXED_TURN_END
        if (!turn.isOpen) { application.close(); return 6 }
        externalApplied = readMarked(list)
        turns += 1
    }
    if (!externalApplied) { application.close(); return 7 }
    // Keep the normal pointer sequence behind a bounded readback window so a
    // completed external projection read can reach its client before teardown.
    // The application keeps pumping real owner turns; it never blocks a
    // renderer or transport worker on a raw delay.
    var externalReadbackActions: Int64 = 0
    var externalReadbackTurns: Int64 = 0
    while (application.isOpen() && externalReadbackTurns < 240) {
        let readbackTurn = application.pumpOneTurn(turnBudgetMs: 4u32)
        if (!readbackTurn.isOpen) { application.close(); return 6 }
        externalReadbackActions += readbackTurn.externalActionCount
        externalReadbackTurns += 1
    }
    if (externalReadbackActions == 0) { application.close(); return 7 }
    let sharedWindow = if (let Some(value) <- application.window(sharedId)) { value } else { application.close(); return 8 }
    let externalTurn = application.pumpOneTurn(turnBudgetMs: 4u32)
    // The generated native variant replaces this block to validate its own
    // controlled pointer scenario. The public verifier deliberately performs
    // no synthetic input: an unchanged A readback after an external write is
    // not evidence that a person acted on A.
    // TEST_VARIANT_BEGIN
    let humanAction = false
    let chartPointerApplied = false
    var backgroundProtected = false
    var afterMovedPoint = false
    var geometryMoved = false
    // TEST_VARIANT_END
    let projection = sharedWindow.windowProjection()
    var stateReadback = "missing"
    var geometryReadback = "missing"
    for (field in projection.fieldValues) {
        if (field.fieldId == "isMarked") { stateReadback = field.value.stringValue }
        if (field.fieldId == "ellipseGeometry") { geometryReadback = field.value.stringValue }
    }
    let idleBefore = sharedWindow.windowProjection()
    let idleTurn = application.pumpOneTurn(turnBudgetMs: 4u32)
    let idleAfter = sharedWindow.windowProjection()
    let idleStable = idleTurn.isOpen && idleBefore.sceneVersion == idleAfter.sceneVersion &&
        idleBefore.nativeSubmissionCount == idleAfter.nativeSubmissionCount
    // TEST_VARIANT_RESULT_BEGIN
    let publicOnly = idleStable && stateReadback == "marked=true color=coral" &&
        geometryReadback == "ellipse center=130,85 radius=24,20"
    let passed = externalApplied && externalTurn.isOpen && publicOnly && turns > 0
    println("CJGUI_VECTOR_PUBLIC_RESULT chart=1 external_marked=true external_readback_actions=${externalReadbackActions} human_action=false human_readback=false state_readback=${stateReadback} geometry_readback=${geometryReadback} chart_pointer=${chartPointerApplied} mixed_same_turn=${testVariantMixedInputSameTurn} background_protected=${backgroundProtected} pointer_hit=${afterMovedPoint} geometry_moved=${geometryMoved} idle_stable=${idleStable} public_only=${publicOnly} turns=${turns} passed=${passed}")
    // TEST_VARIANT_RESULT_END
    getStdOut().flush()
    application.close()
    return if (passed) { 0 } else { 9 }
}

// This is a normal public application mode, not a generated test variant.
// It keeps the same chart and shared-object controllers alive until the user
// closes the application, so desktop input can act on the A vector between
// external reads/writes without a private renderer seam or a second owner.
private func runInteractiveVectorConsumer(): Int64 {
    let list = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(VECTOR_RECORD_ID, "矢量对象", false)
    ]))
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let chartOpen = application.openWindow(VectorChartController(),
        configuration: CjguiMacosApplicationWindowConfiguration("Vector Chart Consumer", 420u32, 300u32))
    let sharedOpen = application.openWindow(VectorSharedOperationController(list),
        configuration: CjguiMacosApplicationWindowConfiguration("Vector Shared Consumer", 420u32, 300u32))
    if (!chartOpen.didOpen || !sharedOpen.didOpen) {
        application.close()
        return 1
    }
    let chartId = if (let Some(value) <- chartOpen.identifier) { value } else { application.close(); return 2 }
    let sharedId = if (let Some(value) <- sharedOpen.identifier) { value } else { application.close(); return 3 }
    let connection = CjguiSharedOperationExternalConnection(list, authorization())
    if (!connection.enableWindowProjectionTargetReads(application) || !application.attachExternalConnection(connection)) {
        application.close()
        return 4
    }
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_VECTOR_INTERACTIVE_READY DESCRIPTOR_PATH ${info.descriptorPath} CHART_TARGET ${chartId.value} SHARED_TARGET ${sharedId.value}")
        getStdOut().flush()
    } else {
        application.close()
        return 5
    }
    while (application.isOpen()) {
        let _ = application.pumpOneTurn()
    }
    application.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size != 1) { return 2 }
    if (args[0] == "--verify-vector") { return verifyPublicConsumers() }
    if (args[0] == "--run-vector") { return runInteractiveVectorConsumer() }
    return 2
}
