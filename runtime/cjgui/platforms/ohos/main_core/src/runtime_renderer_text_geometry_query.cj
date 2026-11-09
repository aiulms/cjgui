// accepted 文本位置与兼容几何的 Cangjie 消费入口。查询读取 native 已持留排版，
// 本模块不创建排版或持有原生对象。v1 返回标量 layoutLease/stopId，用于验证同一
// accepted 排版中的实际停靠点；它们不暴露指针，不能跨失效边界继续使用。
// 兼容几何保留既有入口；本模块不写 runtime_state.cj。
// 2026-09-30(M1)：三个查询统一携带 `expectedSceneVersion`（0=兼容旧调用）——
// 身份验证在**单次 native 调用内**完成（Astra Q2：不再“仓颉查旧版本、原生读
// 新节点”）。范围矩形入参为 UTF-8 display byte，native 严格边界检查后精确换算
// UTF-16，越界/劈开标量具名 TEXT_RANGE_INVALID(34)，不钳制洗白。
package cjgui


// affinity 视觉行渲染侧：0=Upstream（软折行边界渲染上一视觉行末）、
// 1=Downstream（下一视觉行首）、2=AUTO（既有自动行为）。
foreign func cjgui_internal_renderer_text_geometry_caret(
    session: UInt64, nodeId: Int64, displayByte: Int64, caretWidthPt: Float64,
    expectedSceneVersion: UInt64, affinity: UInt32,
    outX: CPointer<Float64>, outY: CPointer<Float64>, outWidth: CPointer<Float64>,
    outHeight: CPointer<Float64>
): Int32

let CJGUI_TEXT_AFFINITY_UPSTREAM: UInt32 = 0
let CJGUI_TEXT_AFFINITY_DOWNSTREAM: UInt32 = 1
let CJGUI_TEXT_AFFINITY_AUTO: UInt32 = 2

/// An ephemeral position in one immutable accepted layout. displayByte and
/// affinity are compatibility projections; (layoutLease, stopId) retain the
/// actual line and primary/alternate branch. Re-resolve after layout changes.
public struct CjguiAcceptedTextPosition {
    public let status: Int32
    public let nodeId: Int64
    public let sceneVersion: UInt64
    public let layoutLease: UInt64
    public let stopId: UInt64
    public let displayByte: Int64
    public let affinity: UInt32
    public let platformBranch: UInt32
    public let lineId: UInt64
    public let atBoundary: Bool
    public let x: Float64
    public let y: Float64
    public let height: Float64
    init(status: Int32, nodeId: Int64, scene: UInt64, meta: Array<UInt64>, rect: Array<Float64>) {
        this.status = status
        this.nodeId = nodeId
        this.sceneVersion = scene
        this.layoutLease = meta[0]
        this.stopId = meta[1]
        this.displayByte = Int64(meta[2])
        this.affinity = UInt32(meta[3])
        this.platformBranch = UInt32(meta[4])
        this.lineId = meta[5]
        this.atBoundary = meta[7] != 0
        this.x = rect[0]
        this.y = rect[1]
        this.height = rect[3]
    }
}

foreign func cjgui_internal_renderer_text_position_v1(session: UInt64, nodeId: Int64,
    scene: UInt64, operation: UInt32, displayByte: Int64, affinity: UInt32,
    layoutLease: UInt64, stopId: UInt64, direction: UInt32, x: Float64, y: Float64,
    meta: CPointer<UInt64>, rect: CPointer<Float64>): Int32
foreign func cjgui_internal_renderer_text_position_stats_v1(session: UInt64,
    counts: CPointer<UInt64>): Int32

func cjguiQueryAcceptedPosition(session: UInt64, nodeId: Int64, scene: UInt64,
    operation: UInt32, byte: Int64, affinity: UInt32, lease: UInt64, stop: UInt64,
    forward: Bool, x: Float64, y: Float64): CjguiAcceptedTextPosition {
    let meta = Array<UInt64>(8, repeat: 0u64)
    let rect = Array<Float64>(4, repeat: 0.0)
    let status = unsafe {
        let m = acquireArrayRawData(meta)
        let r = acquireArrayRawData(rect)
        let result = cjgui_internal_renderer_text_position_v1(session, nodeId, scene,
            operation, byte, affinity, lease, stop, if (forward) { 1u32 } else { 0u32 },
            x, y, m.pointer, r.pointer)
        releaseArrayRawData(r)
        releaseArrayRawData(m)
        result
    }
    return CjguiAcceptedTextPosition(status, nodeId, scene, meta, rect)
}

func cjguiAcceptedPositionWorkCounts(session: UInt64): Array<UInt64> {
    let counts = Array<UInt64>(4, repeat: 0u64)
    unsafe {
        let data = acquireArrayRawData(counts)
        let _ = cjgui_internal_renderer_text_position_stats_v1(session, data.pointer)
        releaseArrayRawData(data)
    }
    return counts
}

/// B2:accepted 文本几何的 caret 矩形(只读,不重排)。
/// 返回 `[x, y, w, h]`(窗口内容逻辑点);失败返回 `None`,由调用方给出具名原因
/// (`stale_layout` / `scene_stale` / `out_of_coverage` / `unavailable` 等) —— **绝不静默零矩形**。
public func cjguiTextGeometryCaretRect(session: UInt64, nodeId: Int64, displayByte: Int64,
    caretWidthPt: Float64, expectedSceneVersion: UInt64,
    affinity!: UInt32 = CJGUI_TEXT_AFFINITY_AUTO): ?Array<Float64> {
    var x = 0.0
    var y = 0.0
    var w = 0.0
    var h = 0.0
    // foreign 调用须在 unsafe 上下文;`inout` 只接受 CType —— 四个 Float64 标量各为 CType,
    // 故可像既有 `cjgui_internal_renderer_node_rect` 的调用处一样逐个传出。
    let status = unsafe {
        cjgui_internal_renderer_text_geometry_caret(session, nodeId, displayByte, caretWidthPt,
            expectedSceneVersion, affinity, inout x, inout y, inout w, inout h)
    }
    if (status != 0) {
        return None
    }
    return [x, y, w, h]
}

/// 状态查询(便于调用方在失败时映射具名原因,而无需再算一次矩形)。
public func cjguiTextGeometryCaretStatus(session: UInt64, nodeId: Int64, displayByte: Int64,
    caretWidthPt: Float64, expectedSceneVersion: UInt64,
    affinity!: UInt32 = CJGUI_TEXT_AFFINITY_AUTO): Int32 {
    var x = 0.0
    var y = 0.0
    var w = 0.0
    var h = 0.0
    return unsafe {
        cjgui_internal_renderer_text_geometry_caret(session, nodeId, displayByte, caretWidthPt,
            expectedSceneVersion, affinity, inout x, inout y, inout w, inout h)
    }
}

/// `cjgui_internal_renderer_*` 状态码 ⇒ 既有具名词表(`pending` / `stale_layout` /
/// `out_of_coverage` / `scene_stale` / `invalid_utf8_boundary` / `unavailable`)。契约要求:
/// 版本/覆盖不匹配时**保留具名拒绝**,绝不静默零矩形。
public func cjguiTextGeometryReasonForStatus(status: Int32): String {
    // 按 `native/cjgui_internal_renderer.h` 的**真实值**映射:
    // 17 = NODE_NOT_FOUND(无此 nodeId);18 = GEOMETRY_EMPTY(节点在但无已持留几何 ⇒ pending);
    // 10 = VIEW_INVALIDATED / 11 = INVALID_SESSION(会话或视图无效);
    // 33 = SCENE_STALE(调用方携带的 accepted 场景版本已前进);
    // 34 = TEXT_RANGE_INVALID(范围越界或劈开 UTF-8 标量);
    // 99 = INTERNAL_ERROR。
    if (status == 17) {
        return "out_of_coverage"
    }
    if (status == 18) {
        return "pending"
    }
    if (status == 33) {
        return "scene_stale"
    }
    if (status == 34) {
        return "invalid_utf8_boundary"
    }
    return "unavailable"
}

foreign func cjgui_internal_renderer_text_stop_resolve(
    session: UInt64, nodeId: Int64, displayByte: Int64, branchIn: UInt32,
    expectedSceneVersion: UInt64, outByte: CPointer<UInt32>, outBranch: CPointer<UInt32>,
    outLineFirstChar: CPointer<UInt32>, outLineLength: CPointer<UInt32>, outX: CPointer<Float64>
): Int32

/// 版本化停靠点解析（Astra 正式裁决）：(byte, branch) → accepted 排版内的真实
/// 停靠点（分支/所在行/显示 x）。branchIn：0=Upstream 1=Downstream 2=AUTO
///（primary 优先）。失败具名；返回 (status, byte, branch, lineFirstChar, lineLength, x)。
public func cjguiTextStopResolve(session: UInt64, nodeId: Int64, displayByte: Int64,
    branchIn: UInt32, expectedSceneVersion: UInt64): (Int32, Int64, UInt32, Int64, Int64, Float64) {
    var byte: UInt32 = 0
    var branch: UInt32 = 2
    var lineFirst: UInt32 = 0
    var lineLen: UInt32 = 0
    var x = 0.0
    let status = unsafe {
        cjgui_internal_renderer_text_stop_resolve(session, nodeId, displayByte, branchIn,
            expectedSceneVersion, inout byte, inout branch, inout lineFirst, inout lineLen, inout x)
    }
    return (status, Int64(byte), branch, Int64(lineFirst), Int64(lineLen), x)
}

foreign func cjgui_internal_renderer_text_stop_neighbor(
    session: UInt64, nodeId: Int64, displayByte: Int64, branchIn: UInt32, left: UInt32,
    expectedSceneVersion: UInt64, outByte: CPointer<UInt32>, outBranch: CPointer<UInt32>
): Int32

/// 停靠点视觉邻位（primary+alternate 合并显示序；边缘透传原 (byte, branch)）。
/// 返回 (status, byte, branch)。
public func cjguiTextStopNeighbor(session: UInt64, nodeId: Int64, displayByte: Int64,
    branchIn: UInt32, left: Bool, expectedSceneVersion: UInt64): (Int32, Int64, UInt32) {
    var byte: UInt32 = 0
    var branch: UInt32 = 2
    let status = unsafe {
        cjgui_internal_renderer_text_stop_neighbor(session, nodeId, displayByte, branchIn,
            if (left) { UInt32(1) } else { UInt32(0) }, expectedSceneVersion,
            inout byte, inout branch)
    }
    return (status, Int64(byte), branch)
}

foreign func cjgui_internal_renderer_text_line_rect_count(
    session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64, maxRects: Int32,
    expectedSceneVersion: UInt64
): Int32

foreign func cjgui_internal_renderer_text_line_rect_value(
    session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64, maxRects: Int32,
    index: Int32, component: Int32, expectedSceneVersion: UInt64
): Float64

foreign func cjgui_internal_renderer_text_visual_neighbor(
    session: UInt64, nodeId: Int64, displayByte: Int64, left: UInt32,
    expectedSceneVersion: UInt64, caretAffinity: UInt32,
    outNeighborByte: CPointer<UInt32>, outAffinity: CPointer<UInt32>
): Int32

/// M2:视觉左/右邻位查询（平台插入点几何，落点簇对齐）。返回
/// `(status, neighborByte, affinity)`；邻位=原字节 ⇒ 已证实的可视边界。
public func cjguiTextVisualNeighbor(session: UInt64, nodeId: Int64, displayByte: Int64,
    left: Bool, expectedSceneVersion: UInt64,
    caretAffinity!: UInt32 = CJGUI_TEXT_AFFINITY_AUTO): (Int32, Int64, Int64) {
    var neighborByte: UInt32 = 0
    var affinity: UInt32 = 0
    let status = unsafe {
        cjgui_internal_renderer_text_visual_neighbor(session, nodeId, displayByte,
            if (left) { UInt32(1) } else { UInt32(0) }, expectedSceneVersion, caretAffinity,
            inout neighborByte, inout affinity)
    }
    return (status, Int64(neighborByte), Int64(affinity))
}

/// B2/B3:范围 ⇒ **逐行选择框**(选择覆盖层用)。返回每行 `[x, y, w, h]` 的扁平数组。
/// 入参是 UTF-8 display byte 半开范围 `[startByte, endByte)`;`isPartial=true` 表示被
/// `maxRects` 截断(不静默少给);失败返回具名状态码,原因由调用方映射。
public func cjguiTextLineRects(session: UInt64, nodeId: Int64, startByte: Int64, endByte: Int64,
    maxRects: Int32, expectedSceneVersion: UInt64): (Int32, Array<Float64>, Bool) {
    let raw = unsafe {
        cjgui_internal_renderer_text_line_rect_count(session, nodeId, startByte, endByte, maxRects,
            expectedSceneVersion)
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
                    maxRects, row, component, expectedSceneVersion)
            }
            component += 1
        }
        row += 1
    }
    return (0, flat, raw == maxRects)
}
