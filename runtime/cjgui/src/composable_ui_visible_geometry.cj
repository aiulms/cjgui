package cjgui

import std.math.*

// The platform supplies one surface/occlusion band. Accepted clip geometry is
// intersected with that same fact for reveal and continuous edge activity.
func cjguiAcceptedVisibleIntersection(surface: CjguiComposableUiRect,
    acceptedClip: CjguiComposableUiRect): CjguiComposableUiRect {
    let left = max(surface.x, acceptedClip.x)
    let top = max(surface.y, acceptedClip.y)
    let right = min(surface.x + surface.width, acceptedClip.x + acceptedClip.width)
    let bottom = min(surface.y + surface.height, acceptedClip.y + acceptedClip.height)
    return CjguiComposableUiRect(left, top, max(right - left, 0), max(bottom - top, 0))
}

func cjguiAcceptedActiveEndRect(left: Float64, top: Float64,
    right: Float64, bottom: Float64): CjguiComposableUiRect {
    let x = Int64(floor(left))
    let y = Int64(floor(top))
    return CjguiComposableUiRect(x, y, max(Int64(ceil(right)) - x, 1),
        max(Int64(ceil(bottom)) - y, 1))
}

// Captured drag coordinates can leave the surface or land in paragraph spacing.
// Resolve against the current accepted visible rectangles, not the old start node.
func cjguiAcceptedTextDragPoint(x: Int64, y: Int64,
    rectangles: Array<CjguiComposableUiRect>): (Int64, Int64) {
    var bestX = x
    var bestY = y
    var bestDistance: Int64 = Int64.Max
    for (rect in rectangles) {
        if (rect.width <= 0 || rect.height <= 0) { continue }
        let px = min(max(x, rect.x), rect.x + rect.width - 1)
        let py = min(max(y, rect.y), rect.y + rect.height - 1)
        let distance = abs(px - x) + abs(py - y)
        if (distance < bestDistance) {
            bestDistance = distance
            bestX = px
            bestY = py
        }
    }
    return (bestX, bestY)
}

// Keep an accepted TEXT source reachable at the viewport edge. Parent content
// can include unrelated controls before/after that source; scrolling through
// those controls must not retire the last layout needed by the captured UP.
func cjguiAcceptedTextEdgeScrollDistance(direction: Int64, requested: Int64,
    viewport: CjguiComposableUiRect, rectangles: Array<CjguiComposableUiRect>): Int64 {
    if (requested <= 0 || viewport.height <= 0 || rectangles.size == 0) { return 0 }
    var first: Int64 = Int64.Max
    var last: Int64 = Int64.Min
    for (rect in rectangles) {
        if (rect.width > 0 && rect.height > 0) {
            first = min(first, rect.y)
            last = max(last, rect.y + rect.height)
        }
    }
    if (first == Int64.Max) { return 0 }
    let room = if (direction < 0) { viewport.y + viewport.height - 1 - first }
        else { last - viewport.y - 1 }
    return min(requested, max(room, 0))
}
