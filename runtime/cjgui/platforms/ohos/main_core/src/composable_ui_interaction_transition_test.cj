// B1/B2：真实交互状态过渡、最小 RGB/alpha 颜色过渡与框架级共同动效定义。
//
// 这些测试覆盖：
//   * 颜色插值契约公开的插值空间（sRGB 编码分量线性）、透明端点（非预乘）、
//     预乘约定与 alpha 合成；
//   * 可中断颜色通道的逐分量补间、中途反向从当前呈现值续接、非有限输入拒绝；
//   * 动效驱动的交互相应目标同步：首次静止、改目标活动、换绑丢弃、reduce-motion
//     收敛与 retire；
//   * 窗口真实 hover/enter/leave、down/up/cancel 走同一过渡规则（不是瞬切）；
//   * alpha 不变式：样式本色/交互解析 alpha 与 animation alpha 各应用一次，
//     用可判别数字证明动画 alpha 不被双乘；
//   * 框架级共同动效定义的受限域、具名拒绝与 capability 发布。
//
// 颜色过渡的精确中间值由纯模型层（显式毫秒）断言；窗口层负责证明真实交互状态
// 变化确实进入了这条通道，而不是每次瞬切 interaction paint。
package cjgui

import std.collection.*
import std.math.*
import std.time.*

private func interactionApprox(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    return abs(actual - expected) <= tolerance
}

private func interactionLinearTween(durationMs: Int64): CjguiComposableUiAnimationSpec {
    return CjguiComposableUiAnimationSpec.tween(durationMs: durationMs, easing: CjguiComposableUiAnimationEasing.LINEAR)
}

private func interactionPalette(red: Float64, green: Float64, blue: Float64, alpha: Float64): CjguiComposableUiPaintColorSet {
    let color = CjguiComposableUiColor(red, green, blue, alpha)
    return CjguiComposableUiPaintColorSet(color, color, color)
}

private func interactionFindNode(window: CjguiComposableUiWindow, nodeId: Int64): ?CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return Some(node)
        }
    }
    return None
}

/// 一个带 hover/pressed paint 声明的按钮，供窗口级交互过渡回归。
private class InteractionTransitionTestController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    var baseBackgroundRed: Float64 = 0.0
    /// 基色 background alpha 可被用例改写，用于 alpha 不变式断言。
    var baseBackgroundAlpha: Float64 = 1.0
    /// hover 声明的背景 alpha（交互分辨率值，用于 alpha 不变式断言）。
    var hoverBackgroundAlpha: Float64 = 1.0

    public func bump(): Unit {
        revision += 1
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "interaction-root", CjguiComposableUiStyle(gap: 2))
        // base 三个 paint 字段带同一样式本色 alpha；hover 声明三个【完整颜色】
        //（含 alpha），用于验证"交互声明替换完整颜色、缺省字段继承"。
        let base = CjguiComposableUiStyle(background: CjguiComposableUiColor(baseBackgroundRed, 0.0, 0.0, baseBackgroundAlpha),
            border: CjguiComposableUiColor(0.2, 0.2, 0.2, baseBackgroundAlpha),
            textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, baseBackgroundAlpha), fixedWidth: 80, fixedHeight: 30)
        let interaction = CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(1.0, 0.0, 0.0, hoverBackgroundAlpha)),
                border: Some(CjguiComposableUiColor(0.0, 1.0, 0.0, hoverBackgroundAlpha)),
                textColor: Some(CjguiComposableUiColor(0.0, 0.0, 1.0, hoverBackgroundAlpha))),
            pressed: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.0, 0.0, 1.0, 1.0))))
        root.add(cjguiComposableButton(2, "interaction-button", "按钮", "ACT", 1, base, interactionStyle: interaction))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

// ===================== 颜色插值契约与颜色通道 =====================

@Test
func colorTransitionContractPublishesSpaceEndpointAndPremultiplication(): Unit {
    @Assert(CjguiComposableUiColorInterpolation.COLOR_SPACE, "srgb_component_linear")
    @Assert(CjguiComposableUiColorInterpolation.ALPHA_ASSOCIATION, "straight")
    @Assert(CjguiComposableUiColorInterpolation.TRANSPARENT_ENDPOINT, "rgb_independent_of_alpha")
    @Assert(CjguiComposableUiColorInterpolation.ALPHA_COMPOSITION,
        "presented_paint_alpha_times_node_opacity_once")
    let description = CjguiComposableUiColorInterpolation.describe()
    @Assert(description.contains("color_space=srgb_component_linear"), true)
    @Assert(description.contains("alpha_association=straight"), true)
    @Assert(description.contains("transparent_endpoint=rgb_independent_of_alpha"), true)
    @Assert(description.contains("alpha_composition=presented_paint_alpha_times_node_opacity_once"), true)
}

@Test
func colorChannelInterpolatesSrgbComponentsLinearly(): Unit {
    let from = CjguiComposableUiColor(0.0, 0.2, 0.4, 1.0)
    let to = CjguiComposableUiColor(1.0, 0.6, 0.4, 0.0)
    let channel = match (CjguiComposableUiColorChannelAnimation.tweened(from, to, 0.0, spec: interactionLinearTween(100))) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    let mid = channel.advanceTo(50.0)
    // 逐分量线性中点（sRGB 编码分量，不做线性光转换）。
    @Assert(interactionApprox(mid.red, 0.5, 1e-9), true)
    @Assert(interactionApprox(mid.green, 0.4, 1e-9), true)
    @Assert(interactionApprox(mid.blue, 0.4, 1e-9), true)
    @Assert(interactionApprox(mid.alpha, 0.5, 1e-9), true)
}

@Test
func colorChannelInterpolatesStraightAlphaAtTransparentEndpoint(): Unit {
    // 透明红 -> 不透明蓝。非预乘插值的中点 RGB 是 (0.5, 0, 0.5)，alpha=0.5。
    // 若按预乘分量插值，中点 RGB 会被 alpha 乘没为 (0.25, 0, 0.25)。
    let from = CjguiComposableUiColor(1.0, 0.0, 0.0, 0.0)
    let to = CjguiComposableUiColor(0.0, 0.0, 1.0, 1.0)
    let channel = match (CjguiComposableUiColorChannelAnimation.tweened(from, to, 0.0, spec: interactionLinearTween(100))) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    let mid = channel.advanceTo(50.0)
    @Assert(interactionApprox(mid.red, 0.5, 1e-9), true)
    @Assert(interactionApprox(mid.blue, 0.5, 1e-9), true)
    @Assert(interactionApprox(mid.alpha, 0.5, 1e-9), true)
    // 预乘插值会得到 0.25；这里是可判别的反例。
    @Assert(interactionApprox(mid.red, 0.25, 1e-9), false)
}

@Test
func colorChannelRetargetMidFlightContinuesFromPresentedValue(): Unit {
    let black = CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)
    let white = CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
    let channel = match (CjguiComposableUiColorChannelAnimation.tweened(black, white, 0.0,
        spec: interactionLinearTween(1000))) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    let forward = channel.advanceTo(400.0)
    @Assert(interactionApprox(forward.red, 0.4, 1e-9), true)
    // 中途反向：从当前呈现值 0.4 续接回 0，新时长重新计时；不得跳回起点 0。
    @Assert(channel.retarget(black, 400.0), true)
    let reversed = channel.advanceTo(900.0)
    @Assert(interactionApprox(reversed.red, 0.2, 1e-9), true)
    @Assert(reversed.red > 0.0, true)
}

@Test
func colorChannelRejectsNonFiniteInputsWithoutStateChange(): Unit {
    let black = CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)
    @Assert(CjguiComposableUiColorChannelAnimation.tweened(CjguiComposableUiColor(Float64.NaN, 0.0, 0.0, 1.0),
        black, 0.0, spec: interactionLinearTween(100)).isNone(), true)
    @Assert(CjguiComposableUiColorChannelAnimation.tweened(black,
        CjguiComposableUiColor(0.0, Float64.NaN, 0.0, 1.0), 0.0, spec: interactionLinearTween(100)).isNone(), true)
    let channel = match (CjguiComposableUiColorChannelAnimation.tweened(black, CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        0.0, spec: interactionLinearTween(1000))) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    let _ = channel.advanceTo(200.0)
    let state = channel.presentedColor()
    @Assert(channel.retarget(CjguiComposableUiColor(0.0, 0.0, 0.0, Float64.NaN), 300.0), false)
    @Assert(channel.retarget(black, 100.0), false)
    let after = channel.presentedColor()
    @Assert(after.red, state.red)
    @Assert(after.alpha, state.alpha)
}

// ===================== 动效驱动的交互颜色目标同步 =====================

@Test
func animationDriverSyncsInteractionColorWithInterruptibleRetarget(): Unit {
    let driver = CjguiComposableUiAnimationDriver(11)
    let spec = interactionLinearTween(1000)
    let normal = interactionPalette(0.0, 0.0, 0.0, 1.0)
    let hover = interactionPalette(1.0, 0.0, 0.0, 1.0)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec), true)
    @Assert(driver.hasColorBinding("semantic:button"), true)
    // 首次建立即静止：画面就是目标色，不产生中间帧。
    @Assert(driver.hasActive(), false)
    // 状态变化：从当前呈现值续接。
    @Assert(driver.syncInteractionPaint("semantic:button", 2, hover, spec: spec), true)
    @Assert(driver.hasActive(), true)
    @Assert(driver.advance(400.0), true)
    let mid = match (driver.paintColorFor("semantic:button", 2)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(mid.background.red, 0.4, 1e-9), true)
    // 中途反向：目标回到 normal，从 0.4 续接。
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec), true)
    @Assert(driver.advance(900.0), true)
    let reversed = match (driver.paintColorFor("semantic:button", 2)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(reversed.background.red, 0.2, 1e-9), true)
    // 到达目标后静止，不再请求帧。
    @Assert(driver.advance(5000.0), true)
    @Assert(driver.hasActive(), false)
}

@Test
func animationDriverRejectsInvalidInteractionColorTargetKeepingOld(): Unit {
    let driver = CjguiComposableUiAnimationDriver(12)
    let spec = interactionLinearTween(1000)
    let normal = interactionPalette(0.0, 0.0, 0.0, 1.0)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec), true)
    let invalid = interactionPalette(Float64.NaN, 0.0, 0.0, 1.0)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, invalid, spec: spec), false)
    // 空身份 / 负 nodeId 同样是具名拒绝路径（不改变已有绑定）。
    @Assert(driver.syncInteractionPaint("", 2, normal, spec: spec), false)
    @Assert(driver.syncInteractionPaint("semantic:button", -1, normal, spec: spec), false)
    @Assert(driver.colorBoundCount(), 1)
    let presented = match (driver.paintColorFor("semantic:button", 2)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(presented.background.alpha, 1.0, 1e-9), true)
}

@Test
func animationDriverInteractionColorRebindDropsOldSlot(): Unit {
    let driver = CjguiComposableUiAnimationDriver(13)
    let spec = interactionLinearTween(1000)
    let normal = interactionPalette(0.0, 0.0, 0.0, 1.0)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec, resourceId: 1), true)
    // 同 identity/nodeId，直接换 resource：旧颜色过渡必须失效，新槽位从目标色起步。
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec, resourceId: 2), true)
    @Assert(driver.colorBoundCount(), 1)
    @Assert(driver.paintColorFor("semantic:button", 2, resourceId: 1).isNone(), true)
    @Assert(driver.paintColorFor("semantic:button", 2, resourceId: 2).isSome(), true)
}

@Test
func animationDriverReduceMotionConvergesInteractionColorAndReconcileRetires(): Unit {
    let driver = CjguiComposableUiAnimationDriver(14)
    let spec = interactionLinearTween(1000)
    let normal = interactionPalette(0.0, 0.0, 0.0, 1.0)
    let hover = interactionPalette(1.0, 0.0, 0.0, 1.0)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, normal, spec: spec), true)
    @Assert(driver.syncInteractionPaint("semantic:button", 2, hover, spec: spec), true)
    @Assert(driver.hasActive(), true)
    @Assert(driver.setReduceMotion(true), true)
    @Assert(driver.hasActive(), false)
    let converged = match (driver.paintColorFor("semantic:button", 2)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(converged.background.red, 1.0, 1e-9), true)

    // accepted 里该身份消失后，颜色绑定被 retire。
    @Assert(driver.syncInteractionPaint("semantic:button", 2, hover, spec: spec), true)
    @Assert(driver.colorBoundCount(), 1)
    driver.reconcileAccepted(HashMap<String, CjguiComposableUiAnimationBinding>())
    @Assert(driver.colorBoundCount(), 0)
    @Assert(driver.hasColorBinding("semantic:button"), false)
}

// ===================== 窗口级真实交互状态过渡 =====================

@Test
func windowFirstHoverAndThemeRetargetNeedNoPrewarmOrSecondPointerEvent(): Unit {
    let controller = InteractionTransitionTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let nodeId: Int64 = 2
    // The first accepted scene itself establishes the settled normal baseline.
    let baseline = window.testInteractionColorFor(nodeId) ?? interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(baseline.background.red, 0.0, 1e-6), true)
    @Assert(window.needsAnimationTick(), false)
    @Assert(window.testApplyInteractionIntent(43u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let entered = window.testInteractionColorFor(nodeId) ?? interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(entered.background.red, 0.0, 1e-6), true)
    let publicTarget = window.interactionPaintTarget("semantic:interaction-button") ??
        interactionPalette(-1.0, 0.0, 0.0, 1.0)
    let publicPresented = window.interactionPaintPresented("semantic:interaction-button") ??
        interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(publicTarget.background.red, 1.0, 1e-6), true)
    @Assert(interactionApprox(publicPresented.background.red, 0.0, 1e-6), true)
    @Assert(window.interactionPaintActive("semantic:interaction-button"), true)
    @Assert(window.hasActiveAnimations(), true)
    let _ = window.testAdvanceAnimationsAtMs(90.0)
    let mid = window.testInteractionColorFor(nodeId) ?? interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(mid.background.red > 0.0 && mid.background.red < 1.0, true)

    // Reverse before reaching hover and retarget the normal palette without
    // any further pointer event. Both changes must continue from this value.
    @Assert(window.testApplyInteractionIntent(44u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let left = window.testInteractionColorFor(nodeId) ?? interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(left.background.red, mid.background.red, 1e-6), true)
    controller.baseBackgroundRed = 0.6
    controller.bump()
    @Assert(window.refresh(), true)
    let afterThemeNode = interactionFindNode(window, nodeId) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(interactionApprox(afterThemeNode.declaredStyle.background.red, 0.6, 1e-6), true)
    let themeTarget = window.interactionPaintTarget("semantic:interaction-button") ??
        interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(themeTarget.background.red, 0.6, 1e-6), true)
    let themeStart = window.testInteractionColorFor(nodeId) ?? interactionPalette(-1.0, 0.0, 0.0, 1.0)
    @Assert(interactionApprox(themeStart.background.red, mid.background.red, 1e-6), true)
    @Assert(window.hasActiveAnimations(), true)
    let _ = window.testAdvanceAnimationsAtMs(600.0)
    let themed = interactionFindNode(window, nodeId) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(interactionApprox(themed.style.background.red, 0.6, 0.01), true)
    @Assert(interactionApprox(themed.declaredStyle.background.red, 0.6, 1e-6), true)
    @Assert(window.needsAnimationTick(), false)
    @Assert(window.interactionPaintActive("semantic:interaction-button"), false)
    window.close()
}

@Test
func windowInteractionHoverAndLeaveUseInterruptibleTransition(): Unit {
    let controller = InteractionTransitionTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let nodeId: Int64 = 2
    // 建立交互投影基线：交互通道以当前（normal）色静止建立，不产生动画。
    @Assert(window.testRefreshInteractionPaint(), true)
    @Assert(window.hasActiveAnimations(), false)
    let baseline = match (window.testInteractionColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(baseline.background.red, 0.0, 1e-6), true)

    // enter：目标切到 hover 色，但呈现值仍是起点（不是瞬切），通道活动。
    @Assert(window.testApplyInteractionIntent(43u32, nodeId), true)
    @Assert(window.testHoveredInteractionNodeId(), nodeId)
    @Assert(window.testRefreshInteractionPaint(), true)
    let hoverTarget = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(hoverTarget.background.red, 1.0, 1e-6), true)
    @Assert(window.testInteractionTransitionDiagnostic(nodeId).contains("declares=1 bound=1 active=1"), true)
    @Assert(window.hasActiveAnimations(), true)
    let hoverPresented = match (window.testInteractionColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(hoverPresented.background.red, 0.0, 1e-6), true)

    // 推进半个过渡：180ms ease_out 在 90ms 处进度约 0.75，呈现值在起点与终点之间。
    @Assert(window.testAdvanceAnimationsAtMs(90.0), true)
    let midFlight = match (window.testInteractionColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(midFlight.background.red > 0.0, true)
    @Assert(midFlight.background.red < 1.0, true)

    // leave（中途反向）：目标回到 normal，从当前视觉值（约 0.75）续接，未瞬切。
    @Assert(window.testApplyInteractionIntent(44u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let leaveTarget = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(leaveTarget.background.red, 0.0, 1e-6), true)
    @Assert(window.hasActiveAnimations(), true)
    let _ = window.testAdvanceAnimationsAtMs(500.0)
    let settled = match (window.testInteractionColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(settled.background.red, 0.0, 1e-3), true)
    window.close()
}

@Test
func windowInteractionPressUpAndCancelUseSameTransition(): Unit {
    let controller = InteractionTransitionTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let nodeId: Int64 = 2
    @Assert(window.testRefreshInteractionPaint(), true)

    // press-down：目标为 pressed（蓝）。
    @Assert(window.testApplyInteractionIntent(45u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let pressedTarget = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(pressedTarget.background.blue, 1.0, 1e-6), true)
    @Assert(window.hasActiveAnimations(), true)

    // press-up：目标回到 normal。
    @Assert(window.testApplyInteractionIntent(46u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let upTarget = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(upTarget.background.red, 0.0, 1e-6), true)
    @Assert(interactionApprox(upTarget.background.blue, 0.0, 1e-6), true)

    // cancel 走同一路径：再次按下后 cancel 回到 normal。
    @Assert(window.testApplyInteractionIntent(45u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    @Assert(window.testApplyInteractionIntent(47u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let cancelTarget = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(cancelTarget.background.blue, 0.0, 1e-6), true)
    window.close()
}

@Test
func windowInteractionColorRetargetIsNotImmediateSwitch(): Unit {
    // 若 hover/pressed 仍是瞬切，enter 后呈现色应立刻等于 hover 目标；这里必须
    // 观察到"目标已变、呈现值未变、通道活动"，即进入可中断过渡而非瞬切。
    let controller = InteractionTransitionTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let nodeId: Int64 = 2
    @Assert(window.testRefreshInteractionPaint(), true)
    @Assert(window.testApplyInteractionIntent(43u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let presented = match (window.testInteractionColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    let target = match (window.testInteractionTargetColorFor(nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    // 呈现值仍在起点、目标已是 hover：两者不同且通道活动 = 正在过渡。
    @Assert(window.hasActiveAnimations(), true)
    @Assert(interactionApprox(presented.background.red, 0.0, 1e-6), true)
    @Assert(interactionApprox(target.background.red, 1.0, 1e-6), true)
    window.close()
}

// ===================== alpha 不变式 =====================

@Test
func windowFinalAlphaAppliesInteractionAndAnimationExactlyOnce(): Unit {
    // Astra 最终裁决：交互状态声明的是一整个颜色值（含 alpha）——声明 Some(color)
    // 即替换该字段完整颜色，未声明的字段继承 base；最终绘制 alpha = 呈现 alpha ×
    // 节点 opacity，只再乘一次，不额外再乘 base alpha。
    //
    // 判别集：base 三字段 alpha=0.8；hover 三字段完整色 alpha=0.75；节点 opacity=0.5。
    //   * hover 解析后三字段 alpha 均 0.75（完整色替换），RGB 亦为声明值；
    //   * 乘 opacity 后三字段 alpha 均 0.375；
    //     每字段 ≠0.3（0.8×0.75×0.5，错误地再乘 base）且 ≠0.1875（0.75×0.5×0.5，
    //     opacity 双乘）；
    //   * 离开 hover 回到未覆盖 base：三字段继承 alpha 0.8，乘 opacity 0.5 = 0.4。
    let controller = InteractionTransitionTestController()
    controller.baseBackgroundAlpha = 0.8
    controller.hoverBackgroundAlpha = 0.75
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let nodeId: Int64 = 2
    // 用 reduce-motion 让交互过渡与动画都确定收敛，避免依赖真实时钟的中间值。
    @Assert(window.setReduceMotionEnabled(true), true)
    @Assert(window.testRefreshInteractionPaint(), true)

    // 基线：未进入交互，三字段仍是 base alpha 0.8（opacity 尚未施加）。
    let baseline = match (interactionFindNode(window, nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(baseline.style.background.alpha, 0.8, 0.01), true)
    @Assert(interactionApprox(baseline.style.border.alpha, 0.8, 0.01), true)
    @Assert(interactionApprox(baseline.style.textColor.alpha, 0.8, 0.01), true)

    // hover：三字段被完整颜色替换（含 alpha），解析后三字段 alpha 均 0.75。
    @Assert(window.testApplyInteractionIntent(43u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let interacted = match (interactionFindNode(window, nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(interacted.style.background.alpha, 0.75, 0.01), true)
    @Assert(interactionApprox(interacted.style.border.alpha, 0.75, 0.01), true)
    @Assert(interactionApprox(interacted.style.textColor.alpha, 0.75, 0.01), true)
    // 完整颜色替换：RGB 也是 hover 声明值，不是 base。
    @Assert(interactionApprox(interacted.style.background.red, 1.0, 0.01), true)
    @Assert(interactionApprox(interacted.style.border.green, 1.0, 0.01), true)
    @Assert(interactionApprox(interacted.style.textColor.blue, 1.0, 0.01), true)

    // 应用节点 opacity 0.5：三字段 alpha 均 0.375，两个反例都不成立。
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(interacted.identityKey, 0.5, spec: zero, atTime: MonoTime.now()), true)
    let animated = match (interactionFindNode(window, nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(animated.style.background.alpha, 0.375, 0.01), true)
    @Assert(interactionApprox(animated.style.border.alpha, 0.375, 0.01), true)
    @Assert(interactionApprox(animated.style.textColor.alpha, 0.375, 0.01), true)
    @Assert(interactionApprox(animated.style.background.alpha, 0.3, 0.01), false)
    @Assert(interactionApprox(animated.style.border.alpha, 0.3, 0.01), false)
    @Assert(interactionApprox(animated.style.textColor.alpha, 0.3, 0.01), false)
    @Assert(interactionApprox(animated.style.background.alpha, 0.1875, 0.01), false)
    @Assert(interactionApprox(animated.style.border.alpha, 0.1875, 0.01), false)
    @Assert(interactionApprox(animated.style.textColor.alpha, 0.1875, 0.01), false)

    // 离开 hover：三字段回到未覆盖 base（继承 alpha 0.8），乘 opacity 0.5 = 0.4。
    @Assert(window.testApplyInteractionIntent(44u32, nodeId), true)
    @Assert(window.testRefreshInteractionPaint(), true)
    let reverted = match (interactionFindNode(window, nodeId)) {
        case Some(value) => value
        case None =>
            @Assert(false, true)
            return
    }
    @Assert(interactionApprox(reverted.style.background.alpha, 0.4, 0.01), true)
    @Assert(interactionApprox(reverted.style.border.alpha, 0.4, 0.01), true)
    @Assert(interactionApprox(reverted.style.textColor.alpha, 0.4, 0.01), true)
    window.close()
}

// ===================== B2：框架级共同动效定义 =====================

@Test
func frameworkMotionRegistryPublishesBoundedRulesAndCapability(): Unit {
    @Assert(CjguiGeneratedMotionRegistry.supportedRuleNames().size, 3)
    @Assert(CjguiGeneratedMotionRegistry.specFor(CjguiGeneratedMotionRegistry.OPACITY_TRANSITION).isSome(), true)
    @Assert(CjguiGeneratedMotionRegistry.specFor(CjguiGeneratedMotionRegistry.INTERACTION_TRANSITION).isSome(), true)
    @Assert(CjguiGeneratedMotionRegistry.specFor(CjguiGeneratedMotionRegistry.POSITION_TRANSITION).isSome(), true)
    let interaction = CjguiGeneratedMotionRegistry.interactionSpec()
    @Assert(interaction.durationMs, 180)
    @Assert(interaction.easing, CjguiComposableUiAnimationEasing.EASE_OUT)
    let capability = CjguiGeneratedMotionRegistry.capabilityLine()
    @Assert(capability.contains("motion_rule=generated.opacity"), true)
    @Assert(capability.contains("interaction_rule=interaction.state"), true)
    @Assert(capability.contains("position_rule=generated.position"), true)
    @Assert(capability.contains("position_unit=logical_points"), true)
    @Assert(capability.contains("duration_range=40..2000"), true)
    @Assert(capability.contains("easing_tokens=ease_in_out|ease_out"), true)
    @Assert(capability.contains("backend=CjguiComposableUiAnimationSpec.tween"), true)
    @Assert(capability.contains("stability=experimental"), true)
    @Assert(capability.contains("color_space=srgb_component_linear"), true)
}

@Test
func frameworkMotionRuleRefusesUnknownAndIllegalDeclarationsByName(): Unit {
    // 未知规则：具名拒绝，且不发明一个默认规格。
    @Assert(CjguiGeneratedMotionRegistry.specFor("generated.unknown").isNone(), true)
    @Assert(CjguiGeneratedMotionRegistry.rejectionReasonFor("generated.unknown"), "motion_rule_unregistered")
    @Assert(CjguiGeneratedMotionRegistry.motionRuleFor("generated.unknown").isNone(), true)

    // 已注册但越界的声明：具名拒绝，spec 不可得。
    let tooShort = CjguiGeneratedMotionRule("rule", CjguiGeneratedMotionRule.MIN_DURATION_MS - 1,
        CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(tooShort.rejectionReason(), "motion_duration_out_of_range")
    @Assert(tooShort.spec().isNone(), true)
    let tooLong = CjguiGeneratedMotionRule("rule", CjguiGeneratedMotionRule.MAX_DURATION_MS + 1,
        CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(tooLong.rejectionReason(), "motion_duration_out_of_range")
    let unknownEasing = CjguiGeneratedMotionRule("rule", 120, "spring")
    @Assert(unknownEasing.rejectionReason(), "motion_easing_unknown")
    let emptyName = CjguiGeneratedMotionRule("", 120, CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(emptyName.rejectionReason(), "motion_name_empty")

    // 合法边界仍照常接受。
    @Assert(CjguiGeneratedMotionRule("rule", CjguiGeneratedMotionRule.MIN_DURATION_MS,
        CjguiGeneratedMotionRule.TOKEN_EASE_OUT).isAccepted(), true)
    @Assert(CjguiGeneratedMotionRule("rule", CjguiGeneratedMotionRule.MAX_DURATION_MS,
        CjguiGeneratedMotionRule.TOKEN_EASE_IN_OUT).isAccepted(), true)
    let accepted = CjguiGeneratedMotionRule("rule", 160, CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(accepted.spec().isSome(), true)
}
