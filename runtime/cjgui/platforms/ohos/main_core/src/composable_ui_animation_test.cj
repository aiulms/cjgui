// P2 动效基础（B 包）确定性单测。
//
// 这些测试只驱动纯时间/状态模型，显式传入时间序列，不依赖真实时钟、桌面、
// native 或控制器。覆盖：补间/弹簧推进、改目标从中途反向、变帧间隔与长暂停
// 有界、取消/换绑不落到新实例、停止后无新帧请求、减少动态效果收敛、越界弹簧
// 值被夹在合法域。
package cjgui

import std.collection.*
import std.math.*

private func animTestApprox(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    return abs(actual - expected) <= tolerance
}

private func animTestLinearTween(): CjguiComposableUiAnimationSpec {
    return CjguiComposableUiAnimationSpec.tween(durationMs: 100, easing: CjguiComposableUiAnimationEasing.LINEAR)
}

private func animTestCriticalSpring(): CjguiComposableUiAnimationSpec {
    return CjguiComposableUiAnimationSpec.spring(stiffness: 170.0, dampingRatio: 1.0)
}

private func animTestUnderdampedSpring(): CjguiComposableUiAnimationSpec {
    return CjguiComposableUiAnimationSpec.spring(stiffness: 900.0, dampingRatio: 0.25)
}

/// 既有确定性用例的最小解包：输入都合法，若被拒说明测试假设失效，直接失败。
private func animTestTweened(from: Float64, to: Float64, nowMs: Float64,
    spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.tween()): CjguiComposableUiScalarAnimation {
    match (CjguiComposableUiScalarAnimation.tweened(from, to, nowMs, spec: spec)) {
        case Some(animation) => return animation
        case None => throw Exception("animTestTweened rejected a finite input")
    }
}

private func animTestSprung(from: Float64, to: Float64, nowMs: Float64, velocity!: Float64 = 0.0,
    spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.spring()): CjguiComposableUiScalarAnimation {
    match (CjguiComposableUiScalarAnimation.sprung(from, to, nowMs, velocity: velocity, spec: spec)) {
        case Some(animation) => return animation
        case None => throw Exception("animTestSprung rejected a finite input")
    }
}

@Test
func animationLinearTweenAdvancesByExplicitTime(): Unit {
    let animation = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    @Assert(animation.isActive(), true)
    @Assert(animTestApprox(animation.advanceTo(50.0), 0.5, 0.0001), true)
    @Assert(animTestApprox(animation.advanceTo(100.0), 1.0, 0.0001), true)
    // 到达目标后完成：宿主不再为本通道申请下一帧。
    @Assert(animation.isActive(), false)
    @Assert(animation.isCompleted(), true)
    @Assert(animation.presented(), 1.0)
}

@Test
func animationCriticalSpringSettlesWithoutOvershoot(): Unit {
    let animation = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    var previous = animation.presented()
    var time = 0.0
    var overshootSeen = false
    while (time < 2000.0) {
        time += 16.0
        let value = animation.advanceTo(time)
        if (value > previous + 0.000001) {
            // 临界阻尼单调逼近，不越过目标。
        }
        if (value > 1.0005) {
            overshootSeen = true
        }
        previous = value
    }
    @Assert(overshootSeen, false)
    @Assert(animTestApprox(animation.presented(), 1.0, 0.001), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationTweenRetargetRestartsFromPresentedValue(): Unit {
    let animation = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let midway = animation.advanceTo(50.0)
    @Assert(animTestApprox(midway, 0.5, 0.0001), true)
    // 改目标：从当前呈现值 0.5 反向回到 0，而不是从起点或旧目标重新开始。
    let _ = animation.retarget(0.0, 50.0)
    @Assert(animTestApprox(animation.presented(), 0.5, 0.0001), true)
    // 新补间从 50ms 起算、时长 100ms：75ms 走到 0.375，100ms 走到 0.25，150ms 到 0。
    @Assert(animTestApprox(animation.advanceTo(75.0), 0.375, 0.0001), true)
    @Assert(animTestApprox(animation.advanceTo(100.0), 0.25, 0.0001), true)
    @Assert(animTestApprox(animation.advanceTo(150.0), 0.0, 0.0001), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationSpringRetargetKeepsValueAndVelocity(): Unit {
    let animation = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let midway = animation.advanceTo(40.0)
    @Assert(midway > 0.0, true)
    // 改目标保留当前值与既有速度：呈现值不跳回起点。
    let _ = animation.retarget(0.0, 40.0)
    @Assert(animTestApprox(animation.presented(), midway, 0.0001), true)
    var time = 40.0
    while (time < 3000.0) {
        time += 16.0
        let _ = animation.advanceTo(time)
    }
    @Assert(animTestApprox(animation.presented(), 0.0, 0.001), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationTweenIsInvariantToFrameInterval(): Unit {
    // 同一总时长、不同帧间隔必须得到一致的补间结果（解析推进）。
    let coarse = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let fine = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let _ = coarse.advanceTo(60.0)
    var time = 0.0
    while (time < 60.0) {
        time += 3.0
        let _ = fine.advanceTo(time)
    }
    @Assert(animTestApprox(coarse.presented(), fine.presented(), 0.0001), true)
}

@Test
func animationSpringIsStableAcrossVariableFrameIntervals(): Unit {
    let steady = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let jittery = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    var steadyTime = 0.0
    while (steadyTime < 400.0) {
        steadyTime += 16.0
        let _ = steady.advanceTo(steadyTime)
    }
    let intervals: Array<Float64> = [4.0, 33.0, 9.0, 50.0, 7.0, 21.0, 12.0, 40.0, 6.0, 30.0, 16.0, 8.0, 5.0]
    var jitteryTime = 0.0
    var index = 0
    while (jitteryTime < 400.0) {
        jitteryTime += intervals[index % intervals.size]
        index += 1
        let _ = jittery.advanceTo(jitteryTime)
    }
    // 固定子步积分让变帧间隔的结果保持接近，不会发散。
    @Assert(animTestApprox(steady.presented(), jittery.presented(), 0.02), true)
}

@Test
func animationLongPauseConvergesWithinBounds(): Unit {
    let animation = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let _ = animation.advanceTo(120.0)
    // 超过 MAXIMUM_RESUME_SPAN_MS 的跨度：确定收敛到目标，不拼接瞬态。
    let _ = animation.advanceTo(12120.0)
    @Assert(animation.isActive(), false)
    @Assert(animation.presented(), 1.0)
}

@Test
func animationDriverStopsRequestingFramesAfterSettling(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestLinearTween(), nowMs: 0.0)
    @Assert(driver.hasActive(), true)
    let _ = driver.advance(100.0)
    @Assert(animTestApprox(driver.alphaMultiplierFor("semantic:card", 42), 0.0, 0.0001), true)
    // 停止后：无活动通道，advance 不再报告变化，帧请求收敛。
    @Assert(driver.hasActive(), false)
    @Assert(driver.advance(200.0), false)
    @Assert(driver.activeCount(), 0)
}

@Test
func animationDriverRebindDoesNotLeakOldGeneration(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let _ = driver.advance(60.0)
    let oldValue = driver.alphaMultiplierFor("semantic:row", 10)
    @Assert(oldValue < 1.0, true)
    // 同一 key 换绑到新代际：旧绑定被替换，旧值不再作用于旧代际。
    let _ = driver.animateOpacity("semantic:row", 20, 0.0, spec: animTestCriticalSpring(), nowMs: 60.0)
    @Assert(driver.alphaMultiplierFor("semantic:row", 10), 1.0)
    @Assert(driver.alphaMultiplierFor("semantic:row", 20), 1.0)
    @Assert(driver.presentedFor("semantic:row") != None, true)
}

@Test
func animationDriverSameKeyRebindKeepsContinuity(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let _ = driver.advance(60.0)
    let midway = driver.presentedFor("semantic:row")
    // 同 key、同代际（重排后 nodeId 稳定）改目标：保留当前呈现值，连续过渡。
    let _ = driver.animateOpacity("semantic:row", 10, 1.0, spec: animTestCriticalSpring(), nowMs: 60.0)
    match (midway) {
        case Some(value) => @Assert(animTestApprox(driver.presentedFor("semantic:row") ?? -1.0, value, 0.0001), true)
        case None => @Assert(false, true)
    }
}

@Test
func animationDriverCancelRestoresFullOpacity(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let _ = driver.advance(50.0)
    @Assert(driver.cancel("semantic:card"), true)
    @Assert(driver.alphaMultiplierFor("semantic:card", 42), 1.0)
    @Assert(driver.hasActive(), false)
    @Assert(driver.cancel("semantic:card"), false)
}

@Test
func animationDriverReduceMotionConvergesExistingAndNewAnimations(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let _ = driver.advance(40.0)
    @Assert(driver.hasActive(), true)
    // 偏好从关闭切到开启：活动动画立即确定收敛。
    @Assert(driver.setReduceMotion(true), true)
    @Assert(driver.hasActive(), false)
    @Assert(driver.alphaMultiplierFor("semantic:card", 42), 0.0)
    // 偏好开启期间的新动画不产生中间帧，一步到位。
    let _ = driver.animateOpacity("semantic:other", 43, 0.0, spec: animTestCriticalSpring(), nowMs: 100.0)
    @Assert(driver.alphaMultiplierFor("semantic:other", 43), 0.0)
    @Assert(driver.hasActive(), false)
    @Assert(driver.setReduceMotion(true), false)
}

@Test
func animationDriverClampsSpringOvershootIntoLegalAlphaDomain(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    // 从 1.0 向 0.0 的欠阻尼弹簧会真正越过目标（原始呈现值 < 0）；对外乘子
    // 必须被夹在 [0,1]，避免非法 alpha。目标等于起点时不会起振，因此这个反例
    // 必须有区分力：rawMinimum 必须为负，否则说明弹簧根本没动。
    let _ = driver.animateOpacity("semantic:pulse", 42, 0.0, spec: animTestUnderdampedSpring(), nowMs: 0.0)
    var time = 0.0
    var maximum = 0.0
    var minimum = 1.0
    var rawMinimum = 1.0
    while (time < 2000.0) {
        time += 8.0
        let _ = driver.advance(time)
        let alpha = driver.alphaMultiplierFor("semantic:pulse", 42)
        if (alpha > maximum) {
            maximum = alpha
        }
        if (alpha < minimum) {
            minimum = alpha
        }
        if (let Some(value) <- driver.presentedFor("semantic:pulse")) {
            if (value < rawMinimum) {
                rawMinimum = value
            }
        }
    }
    @Assert(maximum <= 1.0, true)
    @Assert(minimum >= 0.0, true)
    // 过冲确实发生过：原始呈现值一度越过目标 0，才让夹取有意义。
    @Assert(rawMinimum < -0.0001, true)
    @Assert(animTestApprox(driver.presentedFor("semantic:pulse") ?? 2.0, 0.0, 0.001), true)
}

@Test
func animationSpringExtremePublicParametersStayFiniteAndConverge(): Unit {
    // 公开参数域上限：stiffness=10000、dampingRatio=10。显式阻尼在该域、8ms 步长
    // 下会指数发散；隐式阻尼必须让结果有限并按过阻尼单调收敛。
    let spec = CjguiComposableUiAnimationSpec.spring(stiffness: 10000.0, dampingRatio: 10.0)
    let animation = animTestSprung(1.0, 0.0, 0.0, spec: spec)
    var time = 0.0
    var finite = true
    while (time < 2000.0) {
        time += 8.0
        let value = animation.advanceTo(time)
        if (value.isNaN() || abs(value) > 1.0e9) {
            finite = false
        }
    }
    @Assert(finite, true)
    @Assert(animTestApprox(animation.presented(), 0.0, 0.001), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationSpringLowestDampingAtMaximumStiffnessIsBounded(): Unit {
    // 最欠阻尼 + 最大刚度：dt·ω=0.8 仍在半隐式欧拉稳定带内，结果必须有界
    // （显式阻尼下 ratio 越小越危险，这里专门覆盖该边界）。
    let spec = CjguiComposableUiAnimationSpec.spring(stiffness: 10000.0, dampingRatio: 0.05)
    let animation = animTestSprung(1.0, 0.0, 0.0, spec: spec)
    var time = 0.0
    var maximum = 1.0
    while (time < 4000.0) {
        time += 8.0
        let value = animation.advanceTo(time)
        @Assert(value.isNaN(), false)
        if (value > maximum) {
            maximum = value
        }
    }
    @Assert(maximum < 2.0, true)
    @Assert(animTestApprox(animation.presented(), 0.0, 0.005), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationExtremeSpringIsStableAcrossVariableFrameIntervals(): Unit {
    let spec = CjguiComposableUiAnimationSpec.spring(stiffness: 10000.0, dampingRatio: 10.0)
    let steady = animTestSprung(1.0, 0.0, 0.0, spec: spec)
    let jittery = animTestSprung(1.0, 0.0, 0.0, spec: spec)
    var steadyTime = 0.0
    while (steadyTime < 600.0) {
        steadyTime += 8.0
        let _ = steady.advanceTo(steadyTime)
    }
    let intervals: Array<Float64> = [1.0, 300.0, 2.0, 33.0, 5.0, 120.0, 7.0, 16.0, 3.0, 60.0]
    var jitteryTime = 0.0
    var index = 0
    while (jitteryTime < 600.0) {
        jitteryTime += intervals[index % intervals.size]
        index += 1
        let value = jittery.advanceTo(jitteryTime)
        @Assert(value.isNaN(), false)
    }
    // 固定子步让远不相同的帧间隔落在同一稳定轨迹附近。
    @Assert(animTestApprox(steady.presented(), jittery.presented(), 0.05), true)
}

@Test
func animationExtremeSpringRetargetMidFlightStaysFinite(): Unit {
    // 极端参数下中途反向：保留当前值与速度换目标，不得发散。
    let spec = CjguiComposableUiAnimationSpec.spring(stiffness: 10000.0, dampingRatio: 10.0)
    let animation = animTestSprung(1.0, 0.0, 0.0, spec: spec)
    let _ = animation.advanceTo(40.0)
    let _ = animation.retarget(1.0, 40.0)
    var time = 40.0
    while (time < 3000.0) {
        time += 8.0
        let value = animation.advanceTo(time)
        @Assert(value.isNaN(), false)
        @Assert(abs(value) > 1.0e9, false)
    }
    @Assert(animTestApprox(animation.presented(), 1.0, 0.001), true)
    @Assert(animation.isActive(), false)
}

@Test
func animationDriverRespecifiesExistingBinding(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    // 先建立补间绑定，推进到中途（1.0 -> 0.0 的一半）。
    let tween = CjguiComposableUiAnimationSpec.tween(durationMs: 1000, easing: CjguiComposableUiAnimationEasing.LINEAR)
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: tween, nowMs: 0.0)
    let _ = driver.advance(500.0)
    @Assert(animTestApprox(driver.presentedFor("semantic:row") ?? -1.0, 0.5, 0.01), true)
    // 再请求弹簧：必须真正换规格（不能继续沿用补间），同时保留当前呈现值。
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: animTestUnderdampedSpring(), nowMs: 500.0)
    @Assert(animTestApprox(driver.presentedFor("semantic:row") ?? -1.0, 0.5, 0.01), true)
    var time = 500.0
    var rawMinimum = 1.0
    while (time < 2500.0) {
        time += 8.0
        let _ = driver.advance(time)
        if (let Some(value) <- driver.presentedFor("semantic:row")) {
            if (value < rawMinimum) {
                rawMinimum = value
            }
        }
    }
    // 补间不会过冲；换规格后弹簧必须过冲，证明新规格生效。
    @Assert(rawMinimum < -0.0001, true)
    @Assert(animTestApprox(driver.presentedFor("semantic:row") ?? 2.0, 0.0, 0.001), true)
}

@Test
func animationDriverReduceMotionMarksTerminalPresentationPending(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestLinearTween(), nowMs: 0.0)
    let _ = driver.advance(40.0)
    @Assert(driver.hasActive(), true)
    // 减少动态效果：通道立即收敛到终值，但终值尚未提交 → pending 必须为真，
    // 否则 advanceAnimations 会因 inactive/unchanged 而不提交，画面停在中间。
    @Assert(driver.setReduceMotion(true), true)
    @Assert(driver.hasActive(), false)
    @Assert(driver.hasPendingPresentation(), true)
    @Assert(driver.needsTick(), true)
    driver.markPresentationCommitted()
    @Assert(driver.hasPendingPresentation(), false)
    @Assert(driver.needsTick(), false)
}

@Test
func animationDriverZeroDurationTweenCompletesImmediatelyAndStaysPending(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: CjguiComposableUiAnimationSpec.tween(durationMs: 0),
        nowMs: 0.0)
    // 创建即完成：时间通道 inactive，但初值 1.0 与目标 0.0 的差异仍需一次提交。
    @Assert(driver.hasActive(), false)
    @Assert(driver.alphaMultiplierFor("semantic:card", 42), 0.0)
    @Assert(driver.hasPendingPresentation(), true)
    @Assert(driver.needsTick(), true)
}

@Test
func animationDriverPausedRequestsNoTickAndKeepsChannels(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestLinearTween(), nowMs: 0.0)
    driver.markPresentationCommitted()
    driver.setPaused(true)
    // 暂停：不推进、不申请调度机会；时间通道本身仍然活动（状态事实保留）。
    @Assert(driver.needsTick(), false)
    @Assert(driver.advance(50.0), false)
    @Assert(driver.hasActive(), true)
    driver.setPaused(false)
    @Assert(driver.needsTick(), true)
}

@Test
func animationDriverReconcileDropsRemovedAndReboundIdentities(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:keep", 1, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let _ = driver.animateOpacity("semantic:gone", 2, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0)
    let live = HashMap<String, CjguiComposableUiAnimationBinding>()
    live.add("semantic:keep", CjguiComposableUiAnimationBinding(1))
    driver.reconcileAccepted(live)
    @Assert(driver.boundCount(), 1)
    @Assert(driver.presentedFor("semantic:keep") != None, true)
    @Assert(driver.presentedFor("semantic:gone"), None)
    // 同一 key 但代际变了：旧绑定被释放。
    let rebound = HashMap<String, CjguiComposableUiAnimationBinding>()
    rebound.add("semantic:keep", CjguiComposableUiAnimationBinding(99))
    driver.reconcileAccepted(rebound)
    @Assert(driver.boundCount(), 0)
}

@Test
func animationDriverBindsToWindowInstance(): Unit {
    let driver = CjguiComposableUiAnimationDriver(12345)
    @Assert(driver.windowInstanceToken(), 12345)
}

@Test
func animationSpecClampsOutOfDomainParametersDeterministically(): Unit {
    let overlarge = CjguiComposableUiAnimationSpec.tween(durationMs: 999999)
    @Assert(overlarge.durationMs, CjguiComposableUiAnimationSpec.MAXIMUM_DURATION_MS)
    @Assert(overlarge.isValid(), true)
    let invalidEasing = CjguiComposableUiAnimationSpec(kind: CjguiComposableUiAnimationKind.TWEEN, easing: 99)
    @Assert(invalidEasing.easing, CjguiComposableUiAnimationEasing.EASE_OUT)
    @Assert(invalidEasing.isValid(), true)
    let invalidKind = CjguiComposableUiAnimationSpec(kind: 77)
    @Assert(invalidKind.kind, CjguiComposableUiAnimationKind.TWEEN)
}
// ===================== A4：accepted 绑定身份/代际 =====================

private func animTestBinding(nodeId: Int64, resourceId!: Int64 = -1, nodeKind!: Int64 = -1, actionName!: String = "",
    operationActionName!: String = "", operationResourceId!: Int64 = -1, fieldId!: String = ""): CjguiComposableUiAnimationBinding {
    return CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind, actionName: actionName,
        operationActionName: operationActionName, operationResourceId: operationResourceId, fieldId: fieldId)
}

/// 同 key/nodeId/action/kind，只把 resource 从 1 直接换成 2：旧动画必须失效，
/// 新绑定从 1.0 重新起步；旧槽位不再被驱动。
@Test
func animationDriverSameSlotResourceChangeDropsOldAnimation(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:slot", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    let _ = driver.advance(60.0)
    let oldValue = driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 1, nodeKind: CJGUI_COMPOSABLE_UI_BUTTON,
        actionName: "ACT")
    @Assert(oldValue < 1.0, true)
    // 直接同槽换绑 resource 1 -> 2。
    let _ = driver.animateOpacity("semantic:slot", 10, 0.3, spec: animTestCriticalSpring(), nowMs: 60.0, resourceId: 2,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    // 旧 resource 槽位不再被旧动画驱动。
    @Assert(driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT"), 1.0)
    // 新槽位从 1.0 重新起步（不是继承旧中间值）。
    @Assert(animTestApprox(driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 2,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT"), 1.0, 0.0001), true)
    @Assert(animTestApprox(driver.targetFor("semantic:slot") ?? -1.0, 0.3, 0.0001), true)
    @Assert(driver.boundCount(), 1)
}

/// 同 key/nodeId/resource，换 action 或换节点种类同样视为换绑。
@Test
func animationDriverSameSlotActionAndKindChangeDropsOldAnimation(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:slot", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT_A")
    let _ = driver.advance(60.0)
    @Assert(driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT_A") < 1.0, true)
    // 换 action（nodeId/resource/kind 不变）。
    let _ = driver.animateOpacity("semantic:slot", 10, 0.25, spec: animTestCriticalSpring(), nowMs: 60.0, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT_B")
    @Assert(driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT_A"), 1.0)
    // 再换节点种类（nodeId/resource/action 不变）。
    let _ = driver.advance(120.0)
    let _ = driver.animateOpacity("semantic:slot", 10, 0.4, spec: animTestCriticalSpring(), nowMs: 120.0, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_TEXT, actionName: "ACT_B")
    @Assert(driver.alphaMultiplierFor("semantic:slot", 10, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT_B"), 1.0)
    @Assert(driver.boundCount(), 1)
}

/// 纯重排 / 仅文案变化不改槽位身份：同 binding 改目标仍保留当前呈现值，连续过渡。
@Test
func animationDriverSameSlotKeepsContinuityOnReorder(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 3,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    let _ = driver.advance(60.0)
    let midway = driver.presentedFor("semantic:row") ?? -1.0
    @Assert(midway > 0.0 && midway < 1.0, true)
    // 同一槽位身份（nodeId/resource/action/kind 全部一致）改目标。
    let _ = driver.animateOpacity("semantic:row", 10, 1.0, spec: animTestCriticalSpring(), nowMs: 60.0, resourceId: 3,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    @Assert(animTestApprox(driver.presentedFor("semantic:row") ?? -1.0, midway, 0.0001), true)
}

/// reconcile 必须同时释放“活动绑定”与“已收敛残留绑定”的同槽换绑，并保留
/// 纯重排（身份未变）的绑定。
@Test
func animationDriverReconcileDropsSlotChangeForActiveAndConvergedBindings(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    // 活动绑定：resource 1。
    let _ = driver.animateOpacity("semantic:active", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 1,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    // 已收敛残留绑定：resource 5，推到 inactive 但条目仍存在。
    let tween = CjguiComposableUiAnimationSpec.tween(durationMs: 100, easing: CjguiComposableUiAnimationEasing.LINEAR)
    let _ = driver.animateOpacity("semantic:converged", 20, 0.0, spec: tween, nowMs: 0.0, resourceId: 5,
        nodeKind: CJGUI_COMPOSABLE_UI_TEXT, actionName: "")
    let _ = driver.advance(200.0)
    @Assert(driver.boundCount(), 2)
    // 明确区分：活动绑定仍 active，已收敛残留绑定已 inactive。
    @Assert(driver.isActiveFor("semantic:active"), true)
    @Assert(driver.isActiveFor("semantic:converged"), false)
    // accepted 场景同槽换绑：active -> resource 2，converged -> resource 6。
    let live = HashMap<String, CjguiComposableUiAnimationBinding>()
    live.add("semantic:active", animTestBinding(10, resourceId: 2, nodeKind: CJGUI_COMPOSABLE_UI_BUTTON,
        actionName: "ACT"))
    live.add("semantic:converged", animTestBinding(20, resourceId: 6, nodeKind: CJGUI_COMPOSABLE_UI_TEXT))
    driver.reconcileAccepted(live)
    @Assert(driver.boundCount(), 0)
}

/// 身份未变（纯重排/文案变化）的绑定在 reconcile 中必须保留。
@Test
func animationDriverReconcileKeepsSameSlotBinding(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:keep", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 4,
        nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT")
    let live = HashMap<String, CjguiComposableUiAnimationBinding>()
    live.add("semantic:keep", animTestBinding(10, resourceId: 4, nodeKind: CJGUI_COMPOSABLE_UI_BUTTON, actionName: "ACT"))
    driver.reconcileAccepted(live)
    @Assert(driver.boundCount(), 1)
}

/// 业务操作目标（operationResourceId/operationActionName）与业务字段 fieldId
/// 同样是槽位代际：任一变化都是换绑，旧动画失效。
@Test
func animationDriverSameSlotOperationTargetAndFieldChangeDropsOldAnimation(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:field", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 7,
        nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT, actionName: "EDIT", operationActionName: "SET_NAME",
        operationResourceId: 100, fieldId: "name")
    let _ = driver.advance(60.0)
    @Assert(driver.alphaMultiplierFor("semantic:field", 10, resourceId: 7, nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        actionName: "EDIT", operationActionName: "SET_NAME", operationResourceId: 100, fieldId: "name") < 1.0, true)
    // 换业务操作资源（其余不变）。
    let _ = driver.animateOpacity("semantic:field", 10, 0.25, spec: animTestCriticalSpring(), nowMs: 60.0, resourceId: 7,
        nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT, actionName: "EDIT", operationActionName: "SET_NAME",
        operationResourceId: 200, fieldId: "name")
    @Assert(driver.alphaMultiplierFor("semantic:field", 10, resourceId: 7, nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        actionName: "EDIT", operationActionName: "SET_NAME", operationResourceId: 100, fieldId: "name"), 1.0)
    @Assert(driver.alphaMultiplierFor("semantic:field", 10, resourceId: 7, nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        actionName: "EDIT", operationActionName: "SET_NAME", operationResourceId: 200, fieldId: "name") > 0.99, true)
    // 换业务字段（其余不变）。
    let _ = driver.advance(120.0)
    let _ = driver.animateOpacity("semantic:field", 10, 0.4, spec: animTestCriticalSpring(), nowMs: 120.0, resourceId: 7,
        nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT, actionName: "EDIT", operationActionName: "SET_NAME",
        operationResourceId: 200, fieldId: "email")
    @Assert(driver.alphaMultiplierFor("semantic:field", 10, resourceId: 7, nodeKind: CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        actionName: "EDIT", operationActionName: "SET_NAME", operationResourceId: 200, fieldId: "name"), 1.0)
    @Assert(driver.boundCount(), 1)
}

/// 异步改目标必须携带期望 token：accepted 换绑 B 后，携旧 A token 的调用被拒，
/// 不落到新实例；携当前 B token 的调用才生效。
@Test
func animationDriverStaleTokenCallIsRejectedAfterRebind(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let tokenA = animTestBinding(10, resourceId: 1, operationResourceId: 100, fieldId: "name")
    let _ = driver.animateOpacity("semantic:row", 10, 0.0, spec: animTestCriticalSpring(), nowMs: 0.0, resourceId: 1,
        operationResourceId: 100, fieldId: "name")
    let _ = driver.advance(60.0)
    // accepted 换绑到 B：同 key/nodeId，业务操作资源变化。
    let _ = driver.animateOpacity("semantic:row", 10, 0.4, spec: animTestCriticalSpring(), nowMs: 60.0, resourceId: 1,
        operationResourceId: 200, fieldId: "name")
    let tokenB = animTestBinding(10, resourceId: 1, operationResourceId: 200, fieldId: "name")
    // 携 A token 的旧异步调用（参数为当前 B 绑定）：必须拒绝。
    @Assert(driver.animateOpacity("semantic:row", 10, 0.9, spec: animTestCriticalSpring(), nowMs: 60.0,
        resourceId: 1, operationResourceId: 200, fieldId: "name", token: tokenA), false)
    // 携当前 B token：生效。
    @Assert(driver.animateOpacity("semantic:row", 10, 0.9, spec: animTestCriticalSpring(), nowMs: 60.0,
        resourceId: 1, operationResourceId: 200, fieldId: "name", token: tokenB), true)
}

// ===================== A5：公共标量有限性与无效输入拒绝 =====================

/// 对 from/to/velocity/nowMs 分别输入 NaN/±Inf：工厂返回 None（拒绝），不产生
/// 任何“看似成功却被静默改写”的通道。
@Test
func animationScalarRejectsNonFiniteInputs(): Unit {
    let inf = Float64.Inf
    let ninf = -Float64.Inf
    let nan = Float64.NaN
    @Assert(CjguiComposableUiScalarAnimation.tweened(nan, 1.0, 0.0, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(inf, 1.0, 0.0, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(ninf, 1.0, 0.0, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(0.0, inf, 0.0, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(0.0, nan, 0.0, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(0.0, 1.0, inf, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.tweened(0.0, 1.0, nan, spec: animTestLinearTween()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.sprung(0.0, 1.0, 0.0, velocity: inf, spec: animTestCriticalSpring())
        .isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.sprung(0.0, 1.0, 0.0, velocity: nan, spec: animTestCriticalSpring())
        .isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.sprung(0.0, ninf, 0.0, spec: animTestCriticalSpring()).isNone(), true)
}

/// 非有限规格可识别为拒绝；有限越域仍按既有 clamp 语义（不拒绝）。
@Test
func animationSpecRejectsNonFiniteParametersButClampsFiniteOutOfDomain(): Unit {
    let infStiffness = CjguiComposableUiAnimationSpec.spring(stiffness: Float64.Inf, dampingRatio: 1.0)
    @Assert(infStiffness.isRejected(), true)
    @Assert(infStiffness.rejectionReason(), "stiffness_not_finite")
    let nanDamping = CjguiComposableUiAnimationSpec.spring(stiffness: 170.0, dampingRatio: Float64.NaN)
    @Assert(nanDamping.isRejected(), true)
    @Assert(nanDamping.rejectionReason(), "damping_ratio_not_finite")
    // 有限越域：保留既有夹取语义，不算拒绝。
    let clamped = CjguiComposableUiAnimationSpec.spring(stiffness: 99999.0, dampingRatio: 1.0)
    @Assert(clamped.isRejected(), false)
    @Assert(clamped.stiffness, CjguiComposableUiAnimationSpec.MAXIMUM_STIFFNESS)
    // 工厂对非有限规格拒绝。
    @Assert(CjguiComposableUiScalarAnimation.tweened(0.0, 1.0, 0.0, spec: infStiffness).isNone(), true)
}

/// 改目标拒绝：非有限目标/时间、时间倒退都返回假且状态完全不变，后续合法时间点
/// 与未受扰对照一致。
@Test
func animationScalarRetargetRejectsNonFiniteAndTimeRegression(): Unit {
    let animation = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let _ = animation.advanceTo(50.0)
    let presented = animation.presented()
    let target = animation.target()
    let velocity = animation.velocity()
    @Assert(animation.retarget(Float64.Inf, 50.0), false)
    @Assert(animation.retarget(Float64.NaN, 50.0), false)
    @Assert(animation.retarget(-Float64.Inf, 50.0), false)
    @Assert(animation.retarget(0.0, Float64.Inf), false)
    @Assert(animation.retarget(0.0, Float64.NaN), false)
    @Assert(animation.retarget(0.0, 10.0), false)
    @Assert(animation.presented(), presented)
    @Assert(animation.target(), target)
    @Assert(animation.velocity(), velocity)
    let control = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let _ = control.advanceTo(50.0)
    let _ = control.advanceTo(75.0)
    @Assert(animTestApprox(animation.advanceTo(75.0), control.presented(), 0.0001), true)
}

/// 推进拒绝：非有限时间与时间倒退/相等都是 no-op，与未受扰对照一致。
@Test
func animationScalarAdvanceRejectsNonFiniteAndRegression(): Unit {
    let animation = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let _ = animation.advanceTo(50.0)
    let state = animation.presented()
    @Assert(animation.advanceTo(Float64.NaN), state)
    @Assert(animation.advanceTo(Float64.Inf), state)
    @Assert(animation.advanceTo(-Float64.Inf), state)
    @Assert(animation.advanceTo(10.0), state)
    @Assert(animation.advanceTo(50.0), state)
    @Assert(animation.lastTime(), 50.0)
    let control = animTestTweened(0.0, 1.0, 0.0, spec: animTestLinearTween())
    let _ = control.advanceTo(50.0)
    let _ = control.advanceTo(80.0)
    @Assert(animTestApprox(animation.advanceTo(80.0), control.presented(), 0.0001), true)
}

/// settleAt 非有限拒绝且状态不变。
@Test
func animationScalarRejectsNonFiniteSettleAt(): Unit {
    let animation = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let _ = animation.advanceTo(40.0)
    let presented = animation.presented()
    @Assert(animation.settleAt(Float64.NaN), false)
    @Assert(animation.settleAt(Float64.Inf), false)
    @Assert(animation.settleAt(-Float64.Inf), false)
    @Assert(animation.presented(), presented)
    @Assert(animation.isActive(), true)
    @Assert(animation.settleAt(0.25), true)
    @Assert(animation.presented(), 0.25)
    @Assert(animation.isActive(), false)
}

/// 换规格拒绝：非有限输入返回 None，不部分更新；合法输入仍可用。
@Test
func animationScalarRespecifyRejectsNonFiniteInputs(): Unit {
    let base = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let _ = base.advanceTo(40.0)
    @Assert(CjguiComposableUiScalarAnimation.retuned(base.presented(), base.target(), base.velocity(), Float64.NaN,
        animTestUnderdampedSpring()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.retuned(base.presented(), Float64.Inf, base.velocity(), 40.0,
        animTestUnderdampedSpring()).isNone(), true)
    @Assert(CjguiComposableUiScalarAnimation.retuned(base.presented(), base.target(), base.velocity(), 40.0,
        animTestUnderdampedSpring()).isSome(), true)
}

/// 极大有限值补间：稳定 lerp，中点接近 0 且仍 active，终点精确等于目标，全程有限。
@Test
func animationScalarExtremeFiniteTweenMidpointStaysActiveAndExact(): Unit {
    let huge = 1.7e308
    let animation = animTestTweened(-huge, huge, 0.0, spec: animTestLinearTween())
    let atTen = animation.advanceTo(10.0)
    @Assert(CjguiComposableUiScalarAnimation.isFiniteScalar(atTen), true)
    @Assert(animTestApprox(atTen / huge, -0.8, 0.01), true)
    @Assert(animation.isActive(), true)
    let mid = animation.advanceTo(50.0)
    @Assert(CjguiComposableUiScalarAnimation.isFiniteScalar(mid), true)
    @Assert(animTestApprox(mid / huge, 0.0, 0.01), true)
    @Assert(animation.isActive(), true)
    let end = animation.advanceTo(100.0)
    @Assert(end, huge)
    @Assert(animation.isActive(), false)
}

/// 有效超长 spring 帧仍按现有规则有限收敛。
@Test
func animationScalarLongFrameSpringConvergesFinitely(): Unit {
    let spring = animTestSprung(0.0, 1.0, 0.0, spec: animTestCriticalSpring())
    let _ = spring.advanceTo(100.0)
    let _ = spring.advanceTo(100.0 + CjguiComposableUiScalarAnimation.MAXIMUM_RESUME_SPAN_MS + 1.0)
    @Assert(spring.isActive(), false)
    @Assert(animTestApprox(spring.presented(), 1.0, 0.0001), true)
    @Assert(CjguiComposableUiScalarAnimation.isFiniteScalar(spring.target()), true)
}

/// 驱动层：非有限目标在 clamp 之前被拒绝；非有限时间/规格与时间倒退同样拒绝，
/// 既有绑定与呈现值保持不变。
@Test
func animationDriverRejectsInvalidOpacityTargetBeforeClamp(): Unit {
    let driver = CjguiComposableUiAnimationDriver(7)
    let _ = driver.animateOpacity("semantic:card", 42, 0.0, spec: animTestLinearTween(), nowMs: 0.0)
    let _ = driver.advance(50.0)
    let presented = driver.presentedFor("semantic:card") ?? -1.0
    @Assert(driver.animateOpacity("semantic:card", 42, Float64.NaN, spec: animTestLinearTween(), nowMs: 50.0), false)
    @Assert(driver.animateOpacity("semantic:card", 42, Float64.Inf, spec: animTestLinearTween(), nowMs: 50.0), false)
    @Assert(driver.animateOpacity("semantic:card", 42, -Float64.Inf, spec: animTestLinearTween(), nowMs: 50.0),
        false)
    @Assert(driver.animateOpacity("semantic:card", 42, 0.5, spec: animTestLinearTween(), nowMs: Float64.Inf), false)
    let badSpec = CjguiComposableUiAnimationSpec.spring(stiffness: Float64.Inf)
    @Assert(driver.animateOpacity("semantic:card", 42, 0.5, spec: badSpec, nowMs: 50.0), false)
    @Assert(driver.animateOpacity("semantic:card", 42, 0.5, spec: animTestLinearTween(), nowMs: 10.0), false)
    @Assert(animTestApprox(driver.presentedFor("semantic:card") ?? -1.0, presented, 0.0001), true)
}
