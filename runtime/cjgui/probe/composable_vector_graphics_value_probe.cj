package cjgui

private func require(condition: Bool, message: String): Bool {
    if (!condition) {
        println("CJGUI_VECTOR_VALUE_PROBE_FAIL ${message}")
    }
    return condition
}

private func color(red: Float64, green: Float64, blue: Float64, alpha: Float64): CjguiComposableUiVectorColor {
    return CjguiComposableUiVectorColor(red, green, blue, alpha)
}

main(): Int64 {
    let fill = color(0.12, 0.24, 0.48, 0.8)
    let stroke = color(0.95, 0.76, 0.18, 1.0)
    let paint = CjguiComposableUiVectorPaint(
        Some(fill), Some(stroke), 2.0,
        CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND,
        CJGUI_COMPOSABLE_UI_VECTOR_JOIN_BEVEL)
    if (!require(CjguiComposableUiVectorPaint.validate(paint).accepted,
        "valid paint accepted")) { return 1 }

    let line = CjguiComposableUiVectorGeometry.line(
        120.0, 90.0,
        CjguiComposableUiVectorPoint(0.0, 0.0),
        CjguiComposableUiVectorPoint(40.5, 18.25), paint)
    if (!require(if (let Some(value) <- line) {
        value.kind == CJGUI_COMPOSABLE_UI_VECTOR_LINE && value.points.size == 2 &&
        value.viewBoxWidth == 120.0 && value.viewBoxHeight == 90.0 &&
        CjguiComposableUiVectorGeometry.validate(value).accepted
    } else { false }, "line factory")) { return 2 }

    let polylinePoints: Array<CjguiComposableUiVectorPoint> = [
        CjguiComposableUiVectorPoint(0.0, 0.0),
        CjguiComposableUiVectorPoint(8.0, 12.0),
        CjguiComposableUiVectorPoint(20.0, 4.0)
    ]
    if (!require(if (let Some(value) <- CjguiComposableUiVectorGeometry.polyline(
        120.0, 90.0, polylinePoints, paint)) {
        value.kind == CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE && value.points.size == 3
    } else { false }, "polyline factory")) { return 3 }

    if (!require(if (let Some(value) <- CjguiComposableUiVectorGeometry.ellipse(
        120.0, 90.0, CjguiComposableUiVectorPoint(24.0, 18.0), 12.0, 8.0, paint)) {
        value.kind == CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE && value.radiusX == 12.0 && value.radiusY == 8.0
    } else { false }, "ellipse factory")) { return 4 }

    let concavePoints: Array<CjguiComposableUiVectorPoint> = [
        CjguiComposableUiVectorPoint(0.0, 0.0),
        CjguiComposableUiVectorPoint(60.0, 0.0),
        CjguiComposableUiVectorPoint(60.0, 20.0),
        CjguiComposableUiVectorPoint(24.0, 20.0),
        CjguiComposableUiVectorPoint(24.0, 54.0),
        CjguiComposableUiVectorPoint(0.0, 54.0)
    ]
    if (!require(if (let Some(value) <- CjguiComposableUiVectorGeometry.simplePolygon(
        120.0, 90.0, concavePoints, paint)) {
        value.kind == CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON && value.points.size == 6
    } else { false }, "concave simple polygon accepted")) { return 5 }

    let tooManyPoints: Array<CjguiComposableUiVectorPoint> = [
        CjguiComposableUiVectorPoint(0.0, 0.0), CjguiComposableUiVectorPoint(1.0, 0.0),
        CjguiComposableUiVectorPoint(2.0, 0.0), CjguiComposableUiVectorPoint(3.0, 0.0),
        CjguiComposableUiVectorPoint(4.0, 0.0), CjguiComposableUiVectorPoint(5.0, 0.0),
        CjguiComposableUiVectorPoint(6.0, 0.0), CjguiComposableUiVectorPoint(7.0, 0.0),
        CjguiComposableUiVectorPoint(8.0, 0.0), CjguiComposableUiVectorPoint(9.0, 0.0),
        CjguiComposableUiVectorPoint(10.0, 0.0), CjguiComposableUiVectorPoint(11.0, 0.0),
        CjguiComposableUiVectorPoint(12.0, 0.0)
    ]
    if (!require(if (let None <- CjguiComposableUiVectorGeometry.polyline(120.0, 90.0, tooManyPoints, paint)) { true } else { false },
        "polyline capacity rejection")) { return 6 }

    let selfIntersectingPoints: Array<CjguiComposableUiVectorPoint> = [
        CjguiComposableUiVectorPoint(0.0, 0.0), CjguiComposableUiVectorPoint(60.0, 60.0),
        CjguiComposableUiVectorPoint(0.0, 60.0), CjguiComposableUiVectorPoint(60.0, 0.0)
    ]
    if (!require(if (let None <- CjguiComposableUiVectorGeometry.simplePolygon(
        120.0, 90.0, selfIntersectingPoints, paint)) { true } else { false },
        "self-intersection rejection")) { return 7 }

    if (!require(if (let None <- CjguiComposableUiVectorGeometry.ellipse(
        120.0, 90.0, CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 5.0, paint)) { true } else { false },
        "degenerate ellipse rejection")) { return 8 }

    if (!require(if (let None <- CjguiComposableUiVectorGeometry.line(
        120.0, 90.0, CjguiComposableUiVectorPoint(0.0, 0.0),
        CjguiComposableUiVectorPoint(121.0, 2.0), paint)) { true } else { false },
        "point outside viewbox rejection")) { return 9 }

    let invalidPaint = CjguiComposableUiVectorPaint(
        Some(color(0.0, 0.0, 1.2, 1.0)), None, 0.0,
        CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT,
        CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER)
    if (!require(!CjguiComposableUiVectorPaint.validate(invalidPaint).accepted,
        "invalid paint rejection")) { return 10 }

    let invisiblePaint = CjguiComposableUiVectorPaint(
        Some(color(0.0, 0.0, 0.0, 0.0)), None, 0.0,
        CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT,
        CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER)
    if (!require(if (let None <- CjguiComposableUiVectorGeometry.line(
        120.0, 90.0, CjguiComposableUiVectorPoint(2.0, 2.0),
        CjguiComposableUiVectorPoint(4.0, 4.0), invisiblePaint)) { true } else { false },
        "invisible paint rejection")) { return 11 }

    // Open geometry has no fill region. It must not accept a visible fill as
    // a substitute for a real positive-width stroke and then silently draw
    // nothing in the GPU path.
    let fillOnlyLinePaint = CjguiComposableUiVectorPaint(
        Some(color(1.0, 0.0, 0.0, 1.0)), None, 0.0,
        CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT,
        CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER)
    if (!require(if (let None <- CjguiComposableUiVectorGeometry.line(
        120.0, 90.0, CjguiComposableUiVectorPoint(2.0, 2.0),
        CjguiComposableUiVectorPoint(40.0, 4.0), fillOnlyLinePaint)) { true } else { false },
        "fill-only line rejection")) { return 12 }

    println("CJGUI_VECTOR_VALUE_PROBE_PASS line=1 polyline=1 ellipse=1 concave_polygon=1 capacity=1 self_intersection=1 degenerate=1 bounds=1 paint=1 invisible=1 open_stroke=1")
    return 0
}
