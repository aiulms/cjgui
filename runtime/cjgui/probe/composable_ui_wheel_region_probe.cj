// B（2026-09-28）透明滚轮列的窗口级消费探针。
//
// 反例（B 复核）：滚轮路由与 accepted 输入投影对"声明滚轮资格的普通容器"只做了
// 一半 —— native `scrollNodeContainingPoint` 认 `wheelScrollable`，Cangjie 侧
// `resolveInput` 仍按节点类型解析，于是事件在到达控制器前就被丢掉；同时透明
// VERTICAL/HORIZONTAL 的"视觉中性"快路径假定没有输入行为，声明资格后位移/裁剪
// 变化不再更新 native 已接受节点，滚轮区域停在旧几何。
//
// 本探针是一个独立普通消费者：唯一真值是几个普通容器，不依赖产品、不依赖
// Markdown，也不经过桌面输入。它用真实窗口 + native 只读钩子逐步断言：
//   1 基线：资格 false 时列不是滚轮所有者（对照），兄弟几何记录在案；
//   2 资格 false→true：普通容器（非 SCROLL_AREA）成为滚轮所有者，native 节点重投；
//   3 位移：offsetY 变化后新位置响应、旧位置失效，兄弟矩形不变（不被平移重排）；
//   4 裁剪：高度变化后 Rect 与 Clip 同步跟随，越出者不再响应；
//   5 拒绝候选：同 id 同类型撞号 → 具名 duplicate_node_id，已接受事实保持上一笔；
//   6 无变化刷新不重投（native 更新计数不增长）；
//   7 SCROLL 意图按声明解析：控制器收到 nodeId=2 的滚轮事件（普通容器），
//     未声明资格的兄弟节点收不到。
package cjgui

foreign {
    func cjgui_internal_renderer_test_composable_scene_update_stats(session: UInt64,
        outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>): Int32
    func cjgui_internal_renderer_test_composable_scroll_owner_at_point(session: UInt64, x: Float64, y: Float64,
        outNodeId: CPointer<UInt64>, outIsScrollArea: CPointer<UInt32>,
        outWheelScrollable: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_test_enqueue_composable_event(session: UInt64, nodeIndex: UInt32,
        eventKind: UInt32, text: CString): Int32
}

private class WheelColumnController <: CjguiComposableUiController {
    public var eligible = false
    public var offsetY: Int64 = 0
    public var columnHeight: Int64 = 200
    public var duplicate = false
    public var revision: Int64 = 0
    public var scrollEvents: Int64 = 0
    public var lastScrollNodeId: Int64 = -1
    public var lastScrollText = "-"

    public func uiSceneVersion(): Int64 {
        return 1 + this.revision
    }

    public func markChanged(): Unit {
        this.revision += 1
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableHorizontal(1, "wheel-root",
            CjguiComposableUiStyle(fixedWidth: 500, fixedHeight: 320))
        // 滚轮列：透明普通容器，只有声明与位移，没有底色/边框/效果组 ——
        // 正是"视觉中性"快路径会错误跳过的形状。
        let column = cjguiComposableHorizontal(2, "wheel-column",
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: this.columnHeight, offsetY: this.offsetY,
                wheelScrollable: this.eligible, clipsContent: true))
        column.add(cjguiComposableVertical(3, "wheel-list", CjguiComposableUiStyle(fixedHeight: 400)))
        if (this.duplicate) {
            // 同 id 同类型：候选必须具名拒绝，已接受场景保持上一笔事实。
            column.add(cjguiComposableVertical(3, "wheel-list-duplicate",
                CjguiComposableUiStyle(fixedHeight: 12)))
        }
        root.add(column)
        root.add(cjguiComposableVertical(4, "wheel-sibling",
            CjguiComposableUiStyle(background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), fixedWidth: 120,
                fixedHeight: 80)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_SCROLL) {
            this.scrollEvents += 1
            this.lastScrollNodeId = event.node.nodeId
            this.lastScrollText = event.text
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private class WheelProbeRect {
    public var x: Int64 = -1
    public var y: Int64 = -1
    public var width: Int64 = -1
    public var height: Int64 = -1

    public func matches(x: Int64, y: Int64, width: Int64, height: Int64): Bool {
        return this.x == x && this.y == y && this.width == width && this.height == height
    }

    public func text(): String {
        return "[${this.x},${this.y},${this.width},${this.height}]"
    }
}

private class WheelProbeOwner {
    public var nodeId: UInt64 = 0u64
    public var isScrollArea: UInt32 = 0u32
    public var wheelScrollable: UInt32 = 0u32
}

private func wheelUpdateCount(window: CjguiComposableUiWindow): UInt64 {
    var committed: UInt32 = 0u32
    var updates: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_scene_update_stats(
        window.testSessionToken(), inout committed, inout updates) }
    if (status != 0) {
        return 0
    }
    return updates
}

private func wheelOwnerAt(window: CjguiComposableUiWindow, x: Float64, y: Float64): WheelProbeOwner {
    let owner = WheelProbeOwner()
    var nodeId: UInt64 = 0u64
    var isScrollArea: UInt32 = 0u32
    var wheelScrollable: UInt32 = 0u32
    let status = unsafe { cjgui_internal_renderer_test_composable_scroll_owner_at_point(
        window.testSessionToken(), x, y, inout nodeId, inout isScrollArea, inout wheelScrollable) }
    if (status != 0) {
        owner.nodeId = 0xFFFF_FFFF_FFFF_FFFFu64
        return owner
    }
    owner.nodeId = nodeId
    owner.isScrollArea = isScrollArea
    owner.wheelScrollable = wheelScrollable
    return owner
}

private func wheelRect(window: CjguiComposableUiWindow, nodeId: Int64): WheelProbeRect {
    let rect = WheelProbeRect()
    if (let Some(value) <- window.nodeRect(nodeId)) {
        rect.x = value[0]
        rect.y = value[1]
        rect.width = value[2]
        rect.height = value[3]
    }
    return rect
}

main(): Int64 {
    let controller = WheelColumnController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_WHEEL_REGION_PROBE start=false")
        return 1
    }
    var ok = true

    // ---- 1 基线：未声明资格时列不是滚轮所有者（对照），兄弟几何记录在案 ----
    controller.markChanged()
    let _ = window.refresh()
    let columnBase = wheelRect(window, 2)
    let siblingBase = wheelRect(window, 4)
    let ownerOff = wheelOwnerAt(window, 100.0, 100.0)
    let baselineOwnerIsNone = ownerOff.nodeId == 0u64
    let baselineGeometry = columnBase.matches(0, 0, 200, 200) && siblingBase.matches(200, 0, 120, 80)
    println("CJGUI_WHEEL_REGION_BASELINE column=${columnBase.text()} sibling=${siblingBase.text()} " +
        "owner=${ownerOff.nodeId} geometry=${baselineGeometry} owner_none=${baselineOwnerIsNone}")
    ok = baselineGeometry && baselineOwnerIsNone && ok

    // ---- 2 资格 false→true：普通容器直接持有滚轮，native 节点重投 ----
    let updatesBeforeEligible = wheelUpdateCount(window)
    controller.eligible = true
    controller.markChanged()
    let _ = window.refresh()
    let updatesAfterEligible = wheelUpdateCount(window)
    let ownerOn = wheelOwnerAt(window, 100.0, 100.0)
    let eligibleRestaged = updatesAfterEligible > updatesBeforeEligible
    let eligibleOwner = ownerOn.nodeId == 2u64 && ownerOn.isScrollArea == 0u32 && ownerOn.wheelScrollable == 1u32
    println("CJGUI_WHEEL_REGION_ELIGIBLE owner=${ownerOn.nodeId} is_scroll_area=${ownerOn.isScrollArea} " +
        "wheel=${ownerOn.wheelScrollable} updates=${updatesBeforeEligible}->${updatesAfterEligible} " +
        "restaged=${eligibleRestaged} owner_ok=${eligibleOwner}")
    ok = eligibleOwner && eligibleRestaged && ok

    // ---- 3 位移：新位置响应、旧位置失效、兄弟不被平移重排 ----
    let updatesBeforeMove = wheelUpdateCount(window)
    controller.offsetY = 40
    controller.markChanged()
    let _ = window.refresh()
    let updatesAfterMove = wheelUpdateCount(window)
    let columnMoved = wheelRect(window, 2)
    let siblingMoved = wheelRect(window, 4)
    let ownerAtNew = wheelOwnerAt(window, 100.0, 140.0)
    let ownerAtOld = wheelOwnerAt(window, 100.0, 10.0)
    let moveRestaged = updatesAfterMove > updatesBeforeMove
    let movedFine = columnMoved.matches(0, 40, 200, 200)
    let siblingKept = siblingMoved.matches(siblingBase.x, siblingBase.y, siblingBase.width, siblingBase.height)
    let newResponds = ownerAtNew.nodeId == 2u64
    let oldQuiet = ownerAtOld.nodeId == 0u64
    println("CJGUI_WHEEL_REGION_MOVED column=${columnMoved.text()} sibling=${siblingMoved.text()} " +
        "new_owner=${ownerAtNew.nodeId} old_owner=${ownerAtOld.nodeId} " +
        "updates=${updatesBeforeMove}->${updatesAfterMove} restaged=${moveRestaged} " +
        "moved=${movedFine} sibling_kept=${siblingKept} new_ok=${newResponds} old_quiet=${oldQuiet}")
    ok = movedFine && siblingKept && newResponds && oldQuiet && moveRestaged && ok

    // ---- 4 裁剪：高度变化后 Rect/Clip 同步跟随，越出者不再响应 ----
    let updatesBeforeClip = wheelUpdateCount(window)
    controller.columnHeight = 120
    controller.markChanged()
    let _ = window.refresh()
    let updatesAfterClip = wheelUpdateCount(window)
    let columnClipped = wheelRect(window, 2)
    var clipHeight: Int64 = -1
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 2) {
            clipHeight = node.clip.height
        }
    }
    let ownerInside = wheelOwnerAt(window, 100.0, 100.0)
    let ownerOutside = wheelOwnerAt(window, 100.0, 170.0)
    let clipRestaged = updatesAfterClip > updatesBeforeClip
    let clipFine = columnClipped.matches(0, 40, 200, 120) && clipHeight == 120
    let insideOk = ownerInside.nodeId == 2u64
    let outsideQuiet = ownerOutside.nodeId == 0u64
    println("CJGUI_WHEEL_REGION_CLIPPED column=${columnClipped.text()} clip_height=${clipHeight} " +
        "inside=${ownerInside.nodeId} outside=${ownerOutside.nodeId} " +
        "updates=${updatesBeforeClip}->${updatesAfterClip} restaged=${clipRestaged} clip_ok=${clipFine} " +
        "inside_ok=${insideOk} outside_quiet=${outsideQuiet}")
    ok = clipFine && insideOk && outsideQuiet && clipRestaged && ok

    // ---- 5 拒绝候选保持旧事实 ----
    let acceptedBeforeRefusal = wheelRect(window, 2)
    controller.duplicate = true
    controller.columnHeight = 200
    controller.markChanged()
    let _ = window.refresh()
    let refusal = window.windowProgress().lastNativeFailure
    let acceptedAfterRefusal = wheelRect(window, 2)
    let ownerAfterRefusal = wheelOwnerAt(window, 100.0, 100.0)
    let refusalKeptFacts = acceptedAfterRefusal.matches(acceptedBeforeRefusal.x, acceptedBeforeRefusal.y,
        acceptedBeforeRefusal.width, acceptedBeforeRefusal.height) && ownerAfterRefusal.nodeId == 2u64
    println("CJGUI_WHEEL_REGION_REFUSED reason='${refusal}' accepted_before=${acceptedBeforeRefusal.text()} " +
        "accepted_after=${acceptedAfterRefusal.text()} owner=${ownerAfterRefusal.nodeId} kept=${refusalKeptFacts}")
    ok = refusal == "duplicate_node_id" && refusalKeptFacts && ok
    controller.duplicate = false
    controller.markChanged()
    let _ = window.refresh()

    // ---- 6 无变化刷新不重投（对照，证明 2/3/4 的增量真的来自声明变化） ----
    let updatesIdleBefore = wheelUpdateCount(window)
    let _ = window.refresh()
    let updatesIdleAfter = wheelUpdateCount(window)
    let idleQuiet = updatesIdleAfter == updatesIdleBefore
    println("CJGUI_WHEEL_REGION_IDLE updates=${updatesIdleBefore}->${updatesIdleAfter} quiet=${idleQuiet}")
    ok = idleQuiet && ok

    // ---- 7 SCROLL 意图按声明解析 ----
    // node index = accepted 场景顺序：root(0) column(1) list(2) sibling(3)。
    var columnIndex: UInt32 = 0u32
    var siblingIndex: UInt32 = 0u32
    var foundColumn = false
    var foundSibling = false
    var sceneIndex: UInt32 = 0u32
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 2) {
            columnIndex = sceneIndex
            foundColumn = true
        }
        if (node.nodeId == 4) {
            siblingIndex = sceneIndex
            foundSibling = true
        }
        sceneIndex += 1
    }
    let wheelText = unsafe { LibC.mallocCString("next") }
    var enqueueStatus: Int32 = -1
    if (foundColumn) {
        enqueueStatus = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(
            window.testSessionToken(), columnIndex, 30u32, wheelText) }
    }
    let _ = window.pump(200u32)
    let columnDelivered = controller.lastScrollNodeId == 2 && controller.scrollEvents == 1
    let eventsAfterColumn = controller.scrollEvents
    var siblingEnqueue: Int32 = -1
    if (foundSibling) {
        siblingEnqueue = unsafe { cjgui_internal_renderer_test_enqueue_composable_event(
            window.testSessionToken(), siblingIndex, 30u32, wheelText) }
    }
    let _ = window.pump(200u32)
    let siblingNotDelivered = controller.scrollEvents == eventsAfterColumn
    println("CJGUI_WHEEL_REGION_DISPATCH column_index=${columnIndex} sibling_index=${siblingIndex} " +
        "enqueue=${enqueueStatus} last_node=${controller.lastScrollNodeId} text='${controller.lastScrollText}' " +
        "events=${controller.scrollEvents} sibling_enqueue=${siblingEnqueue} sibling_quiet=${siblingNotDelivered}")
    ok = foundColumn && foundSibling && columnDelivered && siblingNotDelivered && ok

    println("CJGUI_WHEEL_REGION_PROBE passed=${ok}")
    window.close()
    return if (ok) { 0 } else { 1 }
}
