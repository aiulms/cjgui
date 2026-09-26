// 维护注释：本文件是 B2「accepted 文本几何」的 Cangjie 消费入口。
// Truth: 只消费 `cjgui_internal_renderer_text_geometry_caret`（与 `cjgui_internal_renderer_node_rect`
//        同族同形：session → 已接受场景 → nodeId → C 出参 → 具名状态码）；几何取自**已接受场景中
//        **已持留**的排版产物，本文件**不重排、不新建布局、不缓存原生对象**。
// Stop-line: 不返回 pointer / handle / id，不写 runtime_state.cj，不改既有符号。
package cjgui

import std.env.*

foreign func cjgui_internal_renderer_text_geometry_caret(
    session: UInt64, nodeId: Int64, displayByte: Int64, caretWidthPt: Float64,
    outX: CPointer<Float64>, outY: CPointer<Float64>, outWidth: CPointer<Float64>,
    outHeight: CPointer<Float64>
): Int32

/// B2:accepted 文本几何的 caret 矩形(只读,不重排)。
/// 返回 `[x, y, w, h]`(窗口内容逻辑点);失败返回 `None`,由调用方给出具名原因
/// (`stale_layout` / `out_of_coverage` / `unavailable` 等) —— **绝不静默零矩形**。
public func cjguiTextGeometryCaretRect(session: UInt64, nodeId: Int64, displayByte: Int64,
    caretWidthPt: Float64): ?Array<Float64> {
    var x = 0.0
    var y = 0.0
    var w = 0.0
    var h = 0.0
    // foreign 调用须在 unsafe 上下文;`inout` 只接受 CType —— 四个 Float64 标量各为 CType,
    // 故可像既有 `cjgui_internal_renderer_node_rect` 的调用处一样逐个传出。
    let status = unsafe {
        cjgui_internal_renderer_text_geometry_caret(session, nodeId, displayByte, caretWidthPt,
            inout x, inout y, inout w, inout h)
    }
    if (status != 0) {
        return None
    }
    return [x, y, w, h]
}

/// 状态查询(便于调用方在失败时映射具名原因,而无需再算一次矩形)。
public func cjguiTextGeometryCaretStatus(session: UInt64, nodeId: Int64, displayByte: Int64,
    caretWidthPt: Float64): Int32 {
    var x = 0.0
    var y = 0.0
    var w = 0.0
    var h = 0.0
    return unsafe {
        cjgui_internal_renderer_text_geometry_caret(session, nodeId, displayByte, caretWidthPt,
            inout x, inout y, inout w, inout h)
    }
}

/// `cjgui_internal_renderer_*` 状态码 ⇒ 既有具名词表(`pending` / `stale_layout` /
/// `out_of_coverage` / `unavailable`)。契约要求:版本/覆盖不匹配时**保留既有具名 pending**,
/// 绝不静默零矩形。
public func cjguiTextGeometryReasonForStatus(status: Int32): String {
    // 按 `native/cjgui_internal_renderer.h:37-76` 的**真实值**映射(此前的 3/4 是硬编码错误):
    // 17 = NODE_NOT_FOUND(无此 nodeId);18 = GEOMETRY_EMPTY(节点在但无已持留几何 ⇒ pending);
    // 10 = VIEW_INVALIDATED / 11 = INVALID_SESSION(会话或视图无效);99 = INTERNAL_ERROR。
    if (status == 17) {
        return "out_of_coverage"
    }
    if (status == 18) {
        return "pending"
    }
    return "unavailable"
}

foreign func cjgui_internal_renderer_text_line_rect_count(
    session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64, maxRects: Int32
): Int32

foreign func cjgui_internal_renderer_text_line_rect_value(
    session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64, maxRects: Int32,
    index: Int32, component: Int32
): Float64

/// B2/B3:范围 ⇒ **逐行选择框**(选择覆盖层用)。返回每行 `[x, y, w, h]` 的扁平数组。
/// `isPartial=true` 表示被 `maxRects` 截断(不静默少给);失败返回 `None`,具名原因由调用方给出。
public func cjguiTextLineRects(session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64,
    maxRects: Int32): (Int32, Array<Float64>, Bool) {
    let raw = unsafe {
        cjgui_internal_renderer_text_line_rect_count(session, nodeId, startByte, endByte, maxRects)
    }
    if (raw < 0) {
        return (-raw, Array<Float64>(0, repeat: 0.0), false)
    }
    var flat = Array<Float64>(Int64(raw) * 4, repeat: 0.0)
    // 显式 Int32 下标:避免与 Int64 索引混用(编译器实测:invalid binary operator '<' on Int64/Int32)。
    var row = Int32(0)
    while (row < raw) {
        var component = Int32(0)
        while (component < Int32(4)) {
            flat[Int64(row) * 4 + Int64(component)] = unsafe {
                cjgui_internal_renderer_text_line_rect_value(session, nodeId, startByte, endByte,
                    maxRects, row, component)
            }
            component += 1
        }
        row += 1
    }
    return (0, flat, raw == maxRects)
}

