// H2-1（N3）：滚动活动调度/接管/准入的确定性反例。
//
// 判据钉的是 Astra 裁决里"可区分实验"的形状，不是实现细节：
//   * fling 只有携带**当前**释放票据才能启动活动；票据缺失/过期具名拒绝。
//   * 无手势的显式定位（by:/step）是接管：活动停止 + 票据清零，迟后 END
//     不能重启惯性。
//   * 空白接管意图终结活动并发放新票据，且不得被当成位移意图。
//   * reveal 即使目标与 accepted 相同也接管；同一 reveal 的重试不重复接管。
//   * 一个候选里两个 scrollArea 共享同一 mutable viewport → 准入处具名拒绝，
//     拒绝后不留下任何所有权。
//   * changed 与 active 分开交付：重复时刻 (false,true)，停止后 active=false。
package cjgui

import std.collection.*
import std.time.*

private func h2Ms(count: Int64): Duration {
    return Duration.millisecond * count
}

private func h2Viewport(content: Int64, viewport: Int64, offset: Int64): CjguiComposableUiScrollViewport {
    let scroll = CjguiComposableUiScrollViewport()
    scroll.setScrollPhysicsPolicy(CjguiComposableUiScrollPhysicsPolicy.ExperimentalExponential)
    scroll.stageExtents(content, viewport, offset)
    scroll.commitStagedExtents()
    return scroll
}

/// 一个已接受场景：滚动区 nodeId=3（identity "h2-scroll"）绑定 viewport，
/// 两个正文节点 77/78 的裁剪链都挂在这个滚动区上（reveal 的祖先解析据此工作）。
private func h2Window(viewport: CjguiComposableUiScrollViewport): CjguiComposableUiWindow {
    let window = CjguiComposableUiWindow()
    let owners = ArrayList<String>()
    owners.add("h2-scroll")
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    nodes.add(CjguiComposableUiLayoutNode(3, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "h2-scroll",
        scrollViewport: Some(viewport)))
    nodes.add(CjguiComposableUiLayoutNode(77, 1, "h2-row-77", clipOwners: owners))
    nodes.add(CjguiComposableUiLayoutNode(78, 1, "h2-row-78", clipOwners: owners))
    window.acceptScene(nodes)
    window.acceptBinding(viewport, 3)
    return window
}

/// 释放票据是 fling 的启动权：缺失、过期都具名拒绝，只有当前票据能启动活动。
@Test
func ohosFlingAdmissionRequiresTheCurrentReleaseTicket(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let node = window.sceneNode(3)

    @Assert(window.ticket(), 0u64)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 0u64), false)
    @Assert(window.lastNativeFailure, "inertia_release_ticket_stale")
    @Assert(viewport.isInertialScrollActive(), false)
    @Assert(window.hasActiveWindowActivities(), false)

    // 新手势 BEGIN 把票据换成 8：仍带 7 的迟后 END 不得启动。
    window.issueTicket(8u64)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 7u64), false)
    @Assert(window.lastNativeFailure, "inertia_release_ticket_stale")
    @Assert(viewport.isInertialScrollActive(), false)

    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 8u64), true)
    @Assert(viewport.isInertialScrollActive(), true)
    @Assert(window.hasActiveWindowActivities(), true)
    window.stopWindowActivities()
}

/// 正常触摸 MOVE 延续 BEGIN 的启动权；不能把它当成无手势的显式定位。
/// normal thermo 的 native END velocity=0.051，但原窗口只接受了 drag 的 100vp。
@Test
func ohosCurrentGestureMovesPreserveTheReleaseForInertia(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let node = window.sceneNode(3)
    @Assert(window.routeScrollIntent(HarnessPointerEvent(30u32, 8u64), node, 3, "takeover:", true), false)
    @Assert(window.routeScrollIntent(HarnessPointerEvent(30u32, 8u64), node, 3, "by:40", true), true)
    @Assert(window.ticket(), 8u64)
    @Assert(viewport.offset(), 40)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 8u64), true)
    @Assert(viewport.isInertialScrollActive(), true)
    @Assert(window.ticket(), 0u64)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 8u64), false)
    @Assert(window.lastNativeFailure, "inertia_release_ticket_stale")
    @Assert(window.applyViewportScrollStep(node, "by:5", 8u64), false)
    @Assert(window.lastNativeFailure, "scroll_move_gesture_stale")
    @Assert(viewport.offset(), 40)
    window.stopWindowActivities()
}

@Test
func ohosOldGestureMoveCannotStealTheNewRelease(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let node = window.sceneNode(3)
    window.issueTicket(9u64)
    @Assert(window.applyViewportScrollStep(node, "by:40", 8u64), false)
    @Assert(window.lastNativeFailure, "scroll_move_gesture_stale")
    @Assert(viewport.offset(), 0)
    @Assert(window.ticket(), 9u64)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 9u64), true)
    window.stopWindowActivities()
}

/// 显式定位是真实接管：活动停止、票据清零，同一手势的迟后 END 失去启动权。
@Test
func ohosExplicitScrollIntentTakesOverAndInvalidatesTheTicket(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let node = window.sceneNode(3)

    window.issueTicket(8u64)
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 8u64), true)
    @Assert(viewport.isInertialScrollActive(), true)

    @Assert(window.applyViewportScrollStep(node, "by:40", 0u64), true)
    @Assert(viewport.isInertialScrollActive(), false)
    @Assert(window.ticket(), 0u64)
    @Assert(viewport.offset(), 40)

    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 8u64), false)
    @Assert(window.lastNativeFailure, "inertia_release_ticket_stale")
    @Assert(viewport.isInertialScrollActive(), false)
    @Assert(viewport.offset(), 40)
}

/// 停机与显式接管都收回未启动的释放权。
@Test
func ohosStopAndExplicitTakeoverInvalidatePendingReleases(): Unit {
    let stopped = h2Viewport(1000, 100, 0)
    let stopWindow = h2Window(stopped)
    stopWindow.issueTicket(5u64)
    stopWindow.stopWindowActivities()
    @Assert(stopWindow.ticket(), 0u64)
    @Assert(stopWindow.applyViewportScrollStep(stopWindow.sceneNode(3), "fling:1.0", 5u64), false)
    @Assert(stopWindow.lastNativeFailure, "inertia_release_ticket_stale")
    @Assert(stopped.isInertialScrollActive(), false)

    let taken = h2Viewport(1000, 100, 0)
    let takeWindow = h2Window(taken)
    takeWindow.issueTicket(6u64)
    @Assert(taken.beginInertialScroll(1.0, MonoTime.now()), true)
    takeWindow.takeOverScrollActivity(taken)
    @Assert(taken.isInertialScrollActive(), false)
    @Assert(takeWindow.ticket(), 0u64)
    @Assert(takeWindow.applyViewportScrollStep(takeWindow.sceneNode(3), "fling:1.0", 6u64), false)
}

/// 空白/只读内容上的新触摸不产生指针事件，宿主入队 `takeover:` 意图：窗口按冻结
/// 绑定终结活动、发放新票据，并且不把这条意图当位移送进 step 解析。
@Test
func ohosBlankAreaTakeoverIntentStopsInertiaAndIssuesTheTicket(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let node = window.sceneNode(3)

    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), true)
    window.issueTicket(4u64)
    @Assert(window.routeScrollIntent(HarnessPointerEvent(30u32, 9u64), node, 3, "takeover:", true),
        false)
    @Assert(viewport.isInertialScrollActive(), false)
    @Assert(window.ticket(), 9u64)
    @Assert(window.revealTakeoverNodeId(), -1)
    // 新票据能启动这次释放。
    @Assert(window.applyViewportScrollStep(node, "fling:1.0", 9u64), true)

    // 负控：真实位移意图不走接管分支，而是按位移判决（并因此接管、清零票据）。
    window.stopWindowActivities()
    window.issueTicket(10u64)
    @Assert(window.routeScrollIntent(HarnessPointerEvent(30u32, 0u64), node, 3, "by:25", true), true)
    @Assert(window.ticket(), 0u64)
    @Assert(viewport.offset(), 25)

    // 负控：绑定未就绪（身份不匹配）时既不移位也不接管。
    window.issueTicket(12u64)
    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), true)
    @Assert(window.routeScrollIntent(HarnessPointerEvent(30u32, 13u64), node, 3, "takeover:", false),
        false)
    @Assert(window.ticket(), 12u64)
    @Assert(viewport.isInertialScrollActive(), true)
    window.stopWindowActivities()
}

/// reveal 的接管不依赖"是否产生新 offset"：目标与 accepted 相同也要终结活动；
/// 同一 reveal 的重试（中间没有新 BEGIN/新接受）不得误杀新手势的活动。
@Test
func ohosRevealTakesOverSameValueActivityWithoutRekillingRetries(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    let target = window.sceneNode(77)

    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), true)
    window.issueTicket(21u64)
    window.revealTakeoverGuard(77, target)
    @Assert(viewport.isInertialScrollActive(), false)
    @Assert(window.ticket(), 0u64)
    @Assert(window.revealTakeoverNodeId(), 77)

    // 同一 reveal 的重试：不重复接管，新手势的活动活着。
    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), true)
    window.revealTakeoverGuard(77, target)
    @Assert(viewport.isInertialScrollActive(), true)

    // 换一个节点：接管照常。
    window.revealTakeoverGuard(78, window.sceneNode(78))
    @Assert(viewport.isInertialScrollActive(), false)

    // 新接受之后守卫复位：同一节点重新接管。
    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), true)
    window.noteAcceptedScene()
    window.revealTakeoverGuard(77, target)
    @Assert(viewport.isInertialScrollActive(), false)
}

/// 歧义绑定在**准入**处拒绝：一个候选里两个独立 scrollArea 共享同一 mutable
/// viewport 时，候选回滚且不留下任何所有权；两个不同 viewport 是正常通过的正控；
/// 跨窗口共享仍按原规则具名拒绝。
@Test
func ohosDuplicateViewportBindingIsRefusedAtAdmission(): Unit {
    let window = CjguiComposableUiWindow()
    let shared = CjguiComposableUiScrollViewport()
    let kids = ArrayList<CjguiComposableUiNode>()
    kids.add(CjguiComposableUiNode(scrollViewport: Some(shared)))
    kids.add(CjguiComposableUiNode(scrollViewport: Some(shared)))
    @Assert(window.validateCandidateViewStateOwnership(CjguiComposableUiNode(children: kids),
        ArrayList<Int64>()), "scroll_viewport_duplicate_binding")
    window.discardStagedViewStateOwnership()
    @Assert(window.stagedViewportCount(), 0)
    @Assert(shared.ownerWindowToken(), 0)

    // 正控：两个不同 viewport 通过准入并都被 staged，发布后归本窗口。
    let first = CjguiComposableUiScrollViewport()
    let second = CjguiComposableUiScrollViewport()
    let distinct = ArrayList<CjguiComposableUiNode>()
    distinct.add(CjguiComposableUiNode(scrollViewport: Some(first)))
    distinct.add(CjguiComposableUiNode(scrollViewport: Some(second)))
    @Assert(window.validateCandidateViewStateOwnership(CjguiComposableUiNode(children: distinct),
        ArrayList<Int64>()), "")
    @Assert(window.stagedViewportCount(), 2)
    window.commitCandidateViewStateOwnership()
    @Assert(first.ownerWindowToken(), window.instanceToken)
    @Assert(second.ownerWindowToken(), window.instanceToken)
    @Assert(window.stagedViewportCount(), 0)

    // 跨窗口共享仍然具名拒绝（本 harness 的改动没有放宽原规则）。
    let elsewhere = CjguiComposableUiScrollViewport()
    @Assert(elsewhere.claimOwner(777), true)
    @Assert(window.validateCandidateViewStateOwnership(
        CjguiComposableUiNode(scrollViewport: Some(elsewhere)), ArrayList<Int64>()),
        "cross_window_view_state_shared:scroll")
    @Assert(elsewhere.ownerWindowToken(), 777)
}

/// 窗口是活动的唯一推进者：changed 与 active 分开交付，重复时刻不白刷但保持唤醒，
/// 截止之后活动结束。
@Test
func ohosWindowStepSeparatesChangedFromActive(): Unit {
    let viewport = h2Viewport(1000, 100, 0)
    let window = h2Window(viewport)
    @Assert(window.hasActiveWindowActivities(), false)

    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(1.0, start), true)
    @Assert(window.hasActiveWindowActivities(), true)

    let quiet = window.stepWindowActivities(start)
    @Assert(quiet.changed, false)
    @Assert(quiet.active, true)

    let moved = window.stepWindowActivities(start + h2Ms(50))
    @Assert(moved.changed, true)

    let settled = window.stepWindowActivities(start + h2Ms(2600))
    @Assert(settled.active, false)
    @Assert(window.hasActiveWindowActivities(), false)

    // 停机后再推一次：没有活动就是 (false,false)，宿主据此不再安排唤醒。
    let idle = window.stepWindowActivities(start + h2Ms(2700))
    @Assert(idle.changed, false)
    @Assert(idle.active, false)
}
