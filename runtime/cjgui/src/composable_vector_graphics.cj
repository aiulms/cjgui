package cjgui

// Public, platform-free vector description.  This file owns only immutable
// value facts; scene admission, layout scaling, hit testing and platform upload
// remain owners elsewhere in the framework.

public let CJGUI_COMPOSABLE_UI_VECTOR_LINE: Int64 = 1
public let CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE: Int64 = 2
public let CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE: Int64 = 3
public let CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON: Int64 = 4
public let CJGUI_COMPOSABLE_UI_VECTOR_MAX_POINTS: Int64 = 12

public let CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT: Int64 = 1
public let CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND: Int64 = 2
public let CJGUI_COMPOSABLE_UI_VECTOR_CAP_SQUARE: Int64 = 3
public let CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER: Int64 = 1
public let CJGUI_COMPOSABLE_UI_VECTOR_JOIN_BEVEL: Int64 = 2
public let CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND: Int64 = 3

public let CJGUI_COMPOSABLE_UI_VECTOR_VALID: Int64 = 0
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_NUMBER: Int64 = 1
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_COLOR: Int64 = 2
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_STROKE: Int64 = 3
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_CAP: Int64 = 4
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_JOIN: Int64 = 5
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_VIEWBOX: Int64 = 6
public let CJGUI_COMPOSABLE_UI_VECTOR_INVALID_POINT_COUNT: Int64 = 7
public let CJGUI_COMPOSABLE_UI_VECTOR_POINT_OUTSIDE_VIEWBOX: Int64 = 8
public let CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE: Int64 = 9
public let CJGUI_COMPOSABLE_UI_VECTOR_SELF_INTERSECTION: Int64 = 10
public let CJGUI_COMPOSABLE_UI_VECTOR_INVISIBLE: Int64 = 11

private let CJGUI_COMPOSABLE_UI_VECTOR_FINITE_LIMIT: Float64 = 1.0e308

public struct CjguiComposableUiVectorPoint {
    public let x: Float64
    public let y: Float64

    public init(x: Float64, y: Float64) {
        this.x = x
        this.y = y
    }
}

public struct CjguiComposableUiVectorColor {
    public let red: Float64
    public let green: Float64
    public let blue: Float64
    public let alpha: Float64

    public init(red: Float64, green: Float64, blue: Float64, alpha: Float64) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }

    public static func validate(color: CjguiComposableUiVectorColor): CjguiComposableUiVectorValidation {
        if (!vectorFinite(color.red) || !vectorFinite(color.green) ||
            !vectorFinite(color.blue) || !vectorFinite(color.alpha)) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_NUMBER)
        }
        if (color.red < 0.0 || color.red > 1.0 || color.green < 0.0 || color.green > 1.0 ||
            color.blue < 0.0 || color.blue > 1.0 || color.alpha < 0.0 || color.alpha > 1.0) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_COLOR)
        }
        return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
    }
}

public struct CjguiComposableUiVectorPaint {
    public let fill: ?CjguiComposableUiVectorColor
    public let stroke: ?CjguiComposableUiVectorColor
    public let strokeWidth: Float64
    public let cap: Int64
    public let join: Int64

    public init(fill: ?CjguiComposableUiVectorColor, stroke: ?CjguiComposableUiVectorColor,
        strokeWidth: Float64, cap: Int64, join: Int64) {
        this.fill = fill
        this.stroke = stroke
        this.strokeWidth = strokeWidth
        this.cap = cap
        this.join = join
    }

    public static func validate(paint: CjguiComposableUiVectorPaint): CjguiComposableUiVectorValidation {
        if (!vectorFinite(paint.strokeWidth) || paint.strokeWidth < 0.0) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_STROKE)
        }
        if (paint.cap < CJGUI_COMPOSABLE_UI_VECTOR_CAP_BUTT ||
            paint.cap > CJGUI_COMPOSABLE_UI_VECTOR_CAP_SQUARE) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_CAP)
        }
        if (paint.join < CJGUI_COMPOSABLE_UI_VECTOR_JOIN_MITER ||
            paint.join > CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_JOIN)
        }
        var fillVisible = false
        if (let Some(fill) <- paint.fill) {
            let result = CjguiComposableUiVectorColor.validate(fill)
            if (!result.accepted) { return result }
            fillVisible = fill.alpha > 0.0
        }
        var strokeVisible = false
        if (let Some(stroke) <- paint.stroke) {
            let result = CjguiComposableUiVectorColor.validate(stroke)
            if (!result.accepted) { return result }
            strokeVisible = stroke.alpha > 0.0
        }
        if (strokeVisible && paint.strokeWidth <= 0.0) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_STROKE)
        }
        if (!fillVisible && !strokeVisible) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVISIBLE)
        }
        return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
    }
}

private func vectorPaintHasVisibleStroke(paint: CjguiComposableUiVectorPaint): Bool {
    if (let Some(stroke) <- paint.stroke) {
        return stroke.alpha > 0.0 && paint.strokeWidth > 0.0
    }
    return false
}

public struct CjguiComposableUiVectorValidation {
    public let accepted: Bool
    public let reasonCode: Int64

    public init(accepted: Bool, reasonCode: Int64) {
        this.accepted = accepted
        this.reasonCode = reasonCode
    }
}

public struct CjguiComposableUiVectorGeometry {
    public let kind: Int64
    public let points: Array<CjguiComposableUiVectorPoint>
    public let center: CjguiComposableUiVectorPoint
    public let radiusX: Float64
    public let radiusY: Float64
    public let viewBoxWidth: Float64
    public let viewBoxHeight: Float64
    public let paint: CjguiComposableUiVectorPaint

    private init(kind: Int64, points: Array<CjguiComposableUiVectorPoint>,
        center: CjguiComposableUiVectorPoint, radiusX: Float64, radiusY: Float64,
        viewBoxWidth: Float64, viewBoxHeight: Float64, paint: CjguiComposableUiVectorPaint) {
        this.kind = kind
        this.points = points
        this.center = center
        this.radiusX = radiusX
        this.radiusY = radiusY
        this.viewBoxWidth = viewBoxWidth
        this.viewBoxHeight = viewBoxHeight
        this.paint = paint
    }

    public static func validate(geometry: CjguiComposableUiVectorGeometry): CjguiComposableUiVectorValidation {
        return validateGeometry(geometry.kind, geometry.viewBoxWidth, geometry.viewBoxHeight,
            geometry.points, geometry.center, geometry.radiusX, geometry.radiusY, geometry.paint)
    }

    public static func line(viewBoxWidth: Float64, viewBoxHeight: Float64,
        start: CjguiComposableUiVectorPoint, end: CjguiComposableUiVectorPoint,
        paint: CjguiComposableUiVectorPaint): ?CjguiComposableUiVectorGeometry {
        let points: Array<CjguiComposableUiVectorPoint> = [start, end]
        let validation = validateGeometry(CJGUI_COMPOSABLE_UI_VECTOR_LINE, viewBoxWidth, viewBoxHeight,
            points, CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, paint)
        if (!validation.accepted) { return None }
        return Some(CjguiComposableUiVectorGeometry(CJGUI_COMPOSABLE_UI_VECTOR_LINE, points,
            CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, viewBoxWidth, viewBoxHeight, paint))
    }

    public static func polyline(viewBoxWidth: Float64, viewBoxHeight: Float64,
        points: Array<CjguiComposableUiVectorPoint>, paint: CjguiComposableUiVectorPaint): ?CjguiComposableUiVectorGeometry {
        let validation = validateGeometry(CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE, viewBoxWidth, viewBoxHeight,
            points, CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, paint)
        if (!validation.accepted) { return None }
        return Some(CjguiComposableUiVectorGeometry(CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE, points,
            CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, viewBoxWidth, viewBoxHeight, paint))
    }

    public static func ellipse(viewBoxWidth: Float64, viewBoxHeight: Float64,
        center: CjguiComposableUiVectorPoint, radiusX: Float64, radiusY: Float64,
        paint: CjguiComposableUiVectorPaint): ?CjguiComposableUiVectorGeometry {
        let points: Array<CjguiComposableUiVectorPoint> = [center]
        let validation = validateGeometry(CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE, viewBoxWidth, viewBoxHeight,
            points, center, radiusX, radiusY, paint)
        if (!validation.accepted) { return None }
        return Some(CjguiComposableUiVectorGeometry(CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE, points,
            center, radiusX, radiusY, viewBoxWidth, viewBoxHeight, paint))
    }

    public static func simplePolygon(viewBoxWidth: Float64, viewBoxHeight: Float64,
        points: Array<CjguiComposableUiVectorPoint>, paint: CjguiComposableUiVectorPaint): ?CjguiComposableUiVectorGeometry {
        let validation = validateGeometry(CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON, viewBoxWidth, viewBoxHeight,
            points, CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, paint)
        if (!validation.accepted) { return None }
        return Some(CjguiComposableUiVectorGeometry(CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON, points,
            CjguiComposableUiVectorPoint(0.0, 0.0), 0.0, 0.0, viewBoxWidth, viewBoxHeight, paint))
    }
}

private func vectorFinite(value: Float64): Bool {
    return value == value && value > -CJGUI_COMPOSABLE_UI_VECTOR_FINITE_LIMIT &&
        value < CJGUI_COMPOSABLE_UI_VECTOR_FINITE_LIMIT
}

private func vectorPointInViewBox(point: CjguiComposableUiVectorPoint,
    viewBoxWidth: Float64, viewBoxHeight: Float64): Bool {
    return vectorFinite(point.x) && vectorFinite(point.y) && point.x >= 0.0 && point.y >= 0.0 &&
        point.x <= viewBoxWidth && point.y <= viewBoxHeight
}

private func vectorCross(a: CjguiComposableUiVectorPoint, b: CjguiComposableUiVectorPoint,
    c: CjguiComposableUiVectorPoint): Float64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

private func vectorSamePoint(a: CjguiComposableUiVectorPoint, b: CjguiComposableUiVectorPoint): Bool {
    return a.x == b.x && a.y == b.y
}

private func vectorBetween(value: Float64, first: Float64, second: Float64): Bool {
    let low = if (first < second) { first } else { second }
    let high = if (first > second) { first } else { second }
    return value >= low && value <= high
}

private func vectorSegmentsIntersect(a: CjguiComposableUiVectorPoint, b: CjguiComposableUiVectorPoint,
    c: CjguiComposableUiVectorPoint, d: CjguiComposableUiVectorPoint): Bool {
    let abC = vectorCross(a, b, c)
    let abD = vectorCross(a, b, d)
    let cdA = vectorCross(c, d, a)
    let cdB = vectorCross(c, d, b)
    if (abC == 0.0 && vectorBetween(c.x, a.x, b.x) && vectorBetween(c.y, a.y, b.y)) { return true }
    if (abD == 0.0 && vectorBetween(d.x, a.x, b.x) && vectorBetween(d.y, a.y, b.y)) { return true }
    if (cdA == 0.0 && vectorBetween(a.x, c.x, d.x) && vectorBetween(a.y, c.y, d.y)) { return true }
    if (cdB == 0.0 && vectorBetween(b.x, c.x, d.x) && vectorBetween(b.y, c.y, d.y)) { return true }
    return ((abC > 0.0 && abD < 0.0) || (abC < 0.0 && abD > 0.0)) &&
        ((cdA > 0.0 && cdB < 0.0) || (cdA < 0.0 && cdB > 0.0))
}

private func validateGeometry(kind: Int64, viewBoxWidth: Float64, viewBoxHeight: Float64,
    points: Array<CjguiComposableUiVectorPoint>, center: CjguiComposableUiVectorPoint,
    radiusX: Float64, radiusY: Float64, paint: CjguiComposableUiVectorPaint): CjguiComposableUiVectorValidation {
    if (!vectorFinite(viewBoxWidth) || !vectorFinite(viewBoxHeight) ||
        viewBoxWidth <= 0.0 || viewBoxHeight <= 0.0) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_VIEWBOX)
    }
    let paintResult = CjguiComposableUiVectorPaint.validate(paint)
    if (!paintResult.accepted) { return paintResult }
    if (kind != CJGUI_COMPOSABLE_UI_VECTOR_LINE && kind != CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE &&
        kind != CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE && kind != CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_POINT_COUNT)
    }
    // Lines have no fill region. Requiring an actual visible stroke prevents
    // a valid-looking declaration from reaching the renderer as an empty
    // shape, and makes this public failure explicit rather than implicit.
    if ((kind == CJGUI_COMPOSABLE_UI_VECTOR_LINE || kind == CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE) &&
        !vectorPaintHasVisibleStroke(paint)) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_STROKE)
    }
    if (kind == CJGUI_COMPOSABLE_UI_VECTOR_ELLIPSE) {
        if (!vectorFinite(radiusX) || !vectorFinite(radiusY) || radiusX <= 0.0 || radiusY <= 0.0 ||
            !vectorPointInViewBox(center, viewBoxWidth, viewBoxHeight) ||
            center.x - radiusX < 0.0 || center.y - radiusY < 0.0 ||
            center.x + radiusX > viewBoxWidth || center.y + radiusY > viewBoxHeight) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE)
        }
        return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
    }
    let minimumPoints = if (kind == CJGUI_COMPOSABLE_UI_VECTOR_SIMPLE_POLYGON) { 3 } else { 2 }
    if (points.size < minimumPoints || points.size > CJGUI_COMPOSABLE_UI_VECTOR_MAX_POINTS) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_POINT_COUNT)
    }
    if (kind == CJGUI_COMPOSABLE_UI_VECTOR_LINE && points.size != 2) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_INVALID_POINT_COUNT)
    }
    var index = 0
    while (index < points.size) {
        if (!vectorPointInViewBox(points[index], viewBoxWidth, viewBoxHeight)) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_POINT_OUTSIDE_VIEWBOX)
        }
        if (index > 0 && vectorSamePoint(points[index - 1], points[index])) {
            return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE)
        }
        index += 1
    }
    if (kind == CJGUI_COMPOSABLE_UI_VECTOR_LINE && vectorSamePoint(points[0], points[1])) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE)
    }
    if (kind == CJGUI_COMPOSABLE_UI_VECTOR_LINE) {
        return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
    }
    if (kind == CJGUI_COMPOSABLE_UI_VECTOR_POLYLINE) {
        return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
    }
    if (vectorSamePoint(points[0], points[points.size - 1])) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE)
    }
    var signedArea = 0.0
    index = 0
    while (index < points.size) {
        let next = if (index + 1 == points.size) { 0 } else { index + 1 }
        signedArea += points[index].x * points[next].y - points[next].x * points[index].y
        index += 1
    }
    if (signedArea == 0.0) {
        return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_DEGENERATE)
    }
    index = 0
    while (index < points.size) {
        var other = index + 1
        while (other < points.size) {
            let adjacent = other == index + 1 || (index == 0 && other == points.size - 1)
            if (!adjacent) {
                let nextIndex = if (index + 1 == points.size) { 0 } else { index + 1 }
                let nextOther = if (other + 1 == points.size) { 0 } else { other + 1 }
                if (vectorSegmentsIntersect(points[index], points[nextIndex], points[other], points[nextOther])) {
                    return CjguiComposableUiVectorValidation(false, CJGUI_COMPOSABLE_UI_VECTOR_SELF_INTERSECTION)
                }
            }
            other += 1
        }
        index += 1
    }
    return CjguiComposableUiVectorValidation(true, CJGUI_COMPOSABLE_UI_VECTOR_VALID)
}

// `CjguiComposableUiNode.value` is already an immutable, owned string copied
// at the native boundary. This compact numeric payload keeps the public value
// types platform-free while allowing the existing scene transaction to carry
// bounded geometry without a new pointer-bearing ABI. It is package-private:
// consumers construct Geometry and the component helper below, never this
// transport representation.
private func vectorPayloadColor(color: ?CjguiComposableUiVectorColor): String {
    if (let Some(value) <- color) {
        return "${value.red};${value.green};${value.blue};${value.alpha}"
    }
    return "0.0;0.0;0.0;0.0"
}

func cjguiComposableUiVectorNativePayload(geometry: CjguiComposableUiVectorGeometry): String {
    var payload = "cg1;${geometry.kind};${geometry.viewBoxWidth};${geometry.viewBoxHeight};${geometry.paint.strokeWidth};${geometry.paint.cap};${geometry.paint.join};${vectorPayloadColor(geometry.paint.fill)};${vectorPayloadColor(geometry.paint.stroke)};${geometry.center.x};${geometry.center.y};${geometry.radiusX};${geometry.radiusY};${geometry.points.size}"
    for (point in geometry.points) {
        payload += ";${point.x};${point.y}"
    }
    return payload
}
