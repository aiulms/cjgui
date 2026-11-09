// 窗口级动效接缝回归（Astra ①③④⑥）。
//
// 这些测试驱动真实窗口（candidate 解析、layout、native staging 与 present），
// 断言的是窗口真正 accepted 的场景，而不是纯模型：
//   * ① paint alpha 乘子同时作用到 background/border/textColor、shadow.color.alpha
//     与每个 gradient stop 的 alpha；opacity=0 时效果按比例回到底色；
//   * ③ 终值提交：零时长补间与 reduce-motion 收敛都必须在创建/收敛时提交终值，
//     而不是停在中间；提交成功后不再重复提交；
//   * ④ 暂停不请求调度机会；accepted 结构切换时立即清理退役绑定，同 key/id
//     重挂得到正常初值；
//   * ⑥ 手写非法效果在接受 scene 前被具名拒绝，旧的版本/身份/样式保持。
//
// 像素投影由同一个乘子决定（shadow/gradient/文字纹理在 native 端消费缩放后的
// alpha），本文件断言的是窗口接受的 paint 值；像素级采样见 native 探针。
package cjgui

import std.collection.*
import std.math.*
import std.time.*

private func windowAnimApprox(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    return abs(actual - expected) <= tolerance
}

/// 最小 controller：一个可增删的 panel 节点（带 gradient + shadow）与一个文字
/// 节点。`illegalShadow` 打开时给出一个越界的外阴影声明。
private class WindowAnimationTestController <: CjguiComposableUiController & CjguiComposableUiWindowBackgroundProvider {
    private var revision: Int64 = 1
    var panelPresent: Bool = true
    var illegalShadow: Bool = false
    var panelEffectGroupPresent: Bool = false
    var panelEffectGroupOpacity: Float64 = 1.0
    var panelBackdropBlurRadiusPoints: Int64 = 0
    var panelNeutralStyle: Bool = false
    var panelSubtreePresent: Bool = false
    /// A4 同槽换绑：同一 semantic id 节点的 resource/action/业务操作目标/字段/文案
    /// 可在候选里直接改变，手工 nodeId 与节点种类不变。
    var panelResourceId: Int64 = -1
    var panelActionName: String = ""
    var panelOperationActionName: String = ""
    var panelOperationResourceId: Int64 = -1
    var panelFieldId: String = ""
    /// 仅文案变化（不进入槽位判据），用于验证连续性。
    var panelLabel: String = ""
    var windowBackgroundToken: String = CjguiWindowBackgroundPolicy.OPAQUE

    public func candidateWindowBackground(): String {
        return windowBackgroundToken
    }

    public func bump(): Unit {
        revision += 1
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "anim-test-root", CjguiComposableUiStyle(gap: 2))
        if (panelPresent) {
            // 等价于 cjguiComposableVertical(2, "anim-panel", style)，但可显式换绑
            // 槽位字段，同时保持 nodeId 与节点种类不变。
            let panel = CjguiComposableUiNode(2, "anim-panel", CJGUI_COMPOSABLE_UI_VERTICAL, panelLabel, "", panelActionName,
                panelResourceId, if (panelNeutralStyle) {
                    CjguiComposableUiStyle(effectGroup: if (panelEffectGroupPresent) {
                        Some(CjguiComposableUiEffectGroup(opacity: panelEffectGroupOpacity,
                            backdropBlurRadiusPoints: panelBackdropBlurRadiusPoints))
                    } else { None })
                } else {
                    windowAnimPanelStyle(illegalShadow, effectGroup: panelEffectGroupPresent,
                        groupOpacity: panelEffectGroupOpacity, blurRadiusPoints: panelBackdropBlurRadiusPoints)
                },
                operationActionName: panelOperationActionName, operationResourceId: panelOperationResourceId,
                fieldId: panelFieldId)
            if (panelSubtreePresent) {
                panel.add(cjguiComposableText(4, "anim-child", "子节点", CjguiComposableUiStyle(fontSize: 12.0)))
            }
            root.add(panel)
        }
        root.add(cjguiComposableText(3, "anim-label", "文字", CjguiComposableUiStyle(fontSize: 13.0)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// Only the window background changes; the node tree is byte-for-byte equal.
/// It must still reach a native submit, and a malformed candidate keeps the
/// former accepted request and frame. This also exercises explicit clear.
@Test
func windowBackgroundOnlyChangeUsesSceneAcceptanceAndClears(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let initial = window.windowProgress()
    @Assert(initial.windowBackgroundRequested, CjguiWindowBackgroundPolicy.OPAQUE)
    controller.windowBackgroundToken = CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
    controller.bump()
    @Assert(window.refresh(), true)
    let adopted = window.windowProgress()
    @Assert(adopted.windowBackgroundRequested, CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA)
    @Assert(adopted.windowBackgroundFrameIndex > initial.windowBackgroundFrameIndex, true)
    @Assert(adopted.windowBackgroundAcceptedSceneVersion, adopted.acceptedSceneVersion)
    @Assert(adopted.windowBackgroundBackend, "appkit_behind_window")
    if (adopted.windowBackgroundReduceTransparency) {
        @Assert(adopted.windowBackgroundActual, "opaque_fallback")
        @Assert(adopted.windowBackgroundFallbackReason, "reduce_transparency")
    } else {
        @Assert(adopted.windowBackgroundActual, "system_host_installed")
    }
    let acceptedVersion = adopted.acceptedSceneVersion
    let acceptedFrame = adopted.windowBackgroundFrameIndex
    controller.windowBackgroundToken = "invalid_material"
    controller.bump()
    @Assert(window.refresh(), false)
    let refused = window.windowProgress()
    @Assert(refused.acceptedSceneVersion, acceptedVersion)
    @Assert(refused.windowBackgroundFrameIndex, acceptedFrame)
    @Assert(refused.windowBackgroundRequested, CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA)
    controller.windowBackgroundToken = CjguiWindowBackgroundPolicy.OPAQUE
    controller.bump()
    @Assert(window.refresh(), true)
    let cleared = window.windowProgress()
    @Assert(cleared.windowBackgroundRequested, CjguiWindowBackgroundPolicy.OPAQUE)
    @Assert(cleared.windowBackgroundActual, "opaque")
    @Assert(cleared.windowBackgroundFrameIndex > acceptedFrame, true)
    window.close()
}

/// A host appearance offer is staged with the same scene as the material.
/// Rejection retains both the former native appearance and accepted request.
@Test
func windowBackgroundAppearanceChangesWithoutPaintNodesAndRejectsAtomically(): Unit {
    let controller = WindowAnimationTestController()
    controller.windowBackgroundToken = CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let initial = window.windowProgress()
    @Assert(initial.windowBackgroundColorScheme, "dark")
    @Assert(window.offerPlatformColorScheme(CjguiComposableUiColorScheme.Light), true)
    @Assert(window.refreshIfNeeded(), true)
    let light = window.windowProgress()
    @Assert(light.windowBackgroundColorScheme, "light")
    @Assert(light.windowBackgroundFrameIndex > initial.windowBackgroundFrameIndex, true)
    @Assert(light.windowBackgroundAcceptedSceneVersion, light.acceptedSceneVersion)

    controller.windowBackgroundToken = "invalid_material"
    controller.bump()
    @Assert(window.offerPlatformColorScheme(CjguiComposableUiColorScheme.Dark), true)
    @Assert(window.refreshIfNeeded(), false)
    let refused = window.windowProgress()
    @Assert(refused.windowBackgroundColorScheme, "light")
    @Assert(refused.windowBackgroundRequested, CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA)
    @Assert(refused.windowBackgroundFrameIndex, light.windowBackgroundFrameIndex)

    controller.windowBackgroundToken = CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
    controller.bump()
    @Assert(window.refresh(), true)
    let recovered = window.windowProgress()
    @Assert(recovered.windowBackgroundColorScheme, "dark")
    @Assert(recovered.windowBackgroundFrameIndex > light.windowBackgroundFrameIndex, true)
    window.close()
}

/// A transparent layout group still samples and composites a backdrop. A
/// declaration-only blur change must restage its native node even if the
/// group's own fill/border remain absent.
@Test
func windowNeutralEffectGroupBlurChangeRestagesNativeScene(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelNeutralStyle = true
    controller.panelEffectGroupPresent = true
    controller.panelEffectGroupOpacity = 0.4
    controller.panelSubtreePresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().effectSubmittedMode, "none")
    controller.panelBackdropBlurRadiusPoints = 8
    controller.bump()
    @Assert(window.refresh(), true)
    let progress = window.windowProgress()
    @Assert(progress.effectRequestedRadiusPoints, 8)
    @Assert(progress.effectSubmittedMode, "blurred")
    @Assert(progress.effectSubmittedSceneVersion, progress.acceptedSceneVersion)
    window.close()
}

private func windowAnimPanelStyle(illegalShadow: Bool, effectGroup!: Bool = false,
    groupOpacity!: Float64 = 1.0, blurRadiusPoints!: Int64 = 0): CjguiComposableUiStyle {
    let gradient = CjguiComposableUiLinearGradient(
        startX: 0.0,
        startY: 0.0,
        endX: 1.0,
        endY: 0.0,
        stops: [
            CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0)),
            CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(0.0, 0.0, 1.0, 1.0))
        ]
    )
    // 非法声明（offset 超出 [-4096,4096]）必须被共享契约拒绝；合法声明带可见阴影。
    let shadow = if (illegalShadow) {
        CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.8), offsetX: 99999)
    } else {
        CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.8), offsetX: 0, offsetY: 2,
            blurRadius: 8, spread: 0)
    }
    return CjguiComposableUiStyle(background: CjguiComposableUiColor(0.2, 0.3, 0.4, 1.0), fixedHeight: 40,
        gradient: gradient, shadow: shadow,
        effectGroup: if (effectGroup) {
            Some(CjguiComposableUiEffectGroup(opacity: groupOpacity,
                backdropBlurRadiusPoints: blurRadiusPoints))
        } else {
            None
        })
}

/// The accepted request remains blur=8 while a transparent clear forces a
/// committed unblurred fallback. Restoring opaque clear submits blur again;
/// all three facts are read from the normal window progress projection.
@Test
func windowEffectProgressReportsFallbackAndRecoveryWithoutChangingDeclaration(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelEffectGroupPresent = true
    controller.panelBackdropBlurRadiusPoints = 8
    controller.panelSubtreePresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let blurred = window.windowProgress()
    @Assert(blurred.effectIdentity, "root_backdrop")
    @Assert(blurred.effectRequestedRadiusPoints, 8)
    @Assert(blurred.effectSubmittedMode, "blurred")
    @Assert(blurred.effectFallbackReason, "none")
    @Assert(blurred.effectSubmittedSceneVersion, blurred.acceptedSceneVersion)
    @Assert(window.testPresentEffectClear(0.0), true)
    let fallback = window.windowProgress()
    @Assert(fallback.effectRequestedRadiusPoints, 8)
    @Assert(fallback.effectSubmittedMode, "unblurred")
    @Assert(fallback.effectFallbackReason, "non_opaque_clear")
    @Assert(fallback.effectSubmittedFrameIndex > blurred.effectSubmittedFrameIndex, true)
    @Assert(window.testPresentEffectClear(1.0), true)
    let restored = window.windowProgress()
    @Assert(restored.effectRequestedRadiusPoints, 8)
    @Assert(restored.effectSubmittedMode, "blurred")
    @Assert(restored.effectFallbackReason, "none")
    @Assert(restored.effectSubmittedFrameIndex > fallback.effectSubmittedFrameIndex, true)
    window.close()
}

private func windowAnimFindNode(window: CjguiComposableUiWindow, identityKey: String): ?CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.identityKey == identityKey) {
            return Some(node)
        }
    }
    return None
}

/// ① + ③：动态 opacity 乘子必须同时缩放背景/文字、shadow.color.alpha 与每个
/// gradient stop 的 alpha；零时长补间创建即完成，窗口必须立即提交终值。
@Test
func windowAnimationScalesShadowGradientAndCommitsTerminalValue(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    @Assert(windowAnimFindNode(window, key).isSome(), true)

    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    // 零时长补间：通道 inactive；窗口若只看 changed 帧就不会刷新。断言提交已发生。
    @Assert(window.animateNodeOpacity(key, 0.5, spec: zero, atTime: MonoTime.now()), true)
    let half = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(windowAnimApprox(half.style.background.alpha, 0.5, 0.01), true)
    @Assert(windowAnimApprox(half.style.textColor.alpha, 0.5, 0.01), true)
    match (half.style.shadow) {
        case Some(value) => @Assert(windowAnimApprox(value.color.alpha, 0.4, 0.01), true)
        case None => @Assert(false, true)
    }
    match (half.style.gradient) {
        case Some(value) =>
            @Assert(value.stops.size, 2)
            @Assert(windowAnimApprox(value.stops[0].color.alpha, 0.5, 0.01), true)
            @Assert(windowAnimApprox(value.stops[1].color.alpha, 0.5, 0.01), true)
        case None => @Assert(false, true)
    }

    // opacity=0：本体、渐变两端、阴影都按比例消失（阴影被归一为 None，即回到底色）。
    @Assert(window.animateNodeOpacity(key, 0.0, spec: zero, atTime: MonoTime.now()), true)
    let zeroed = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(zeroed.style.background.alpha < 0.001, true)
    @Assert(zeroed.style.textColor.alpha < 0.001, true)
    @Assert(zeroed.style.shadow.isNone(), true)
    match (zeroed.style.gradient) {
        case Some(value) =>
            @Assert(value.stops[0].color.alpha < 0.001, true)
            @Assert(value.stops[1].color.alpha < 0.001, true)
        case None => ()
    }
    window.close()
}

/// ③：reduce-motion 让通道收敛，但驱动必须记录“终值尚未提交”，下一次 advance
/// 即使 changed=false 也要提交；提交成功后不再重复提交。
@Test
func windowReduceMotionCommitsTerminalValueExactlyOnce(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: slow, atTime: MonoTime.now()), true)
    @Assert(window.hasActiveAnimations(), true)

    // 开启减少动态效果：通道立即收敛到终值 0.0。
    @Assert(window.setReduceMotionEnabled(true), true)
    @Assert(window.hasActiveAnimations(), false)
    // 这一次 advance 没有数值变化（changed=false），但终值必须被提交。
    @Assert(window.advanceAnimations(atTime: MonoTime.now()), false)
    let node = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(node.style.background.alpha < 0.001, true)

    // 终值提交成功后，没有活动通道也没有 pending：不再重复提交。
    let submissions = window.windowProjection().nativeSubmissionCount
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    @Assert(window.windowProjection().nativeSubmissionCount, submissions)
    @Assert(window.needsAnimationTick(), false)
    window.close()
}

/// ④：暂停不请求调度机会（needsTick=false），也不推进任何通道；恢复后重新需要。
@Test
func windowPausedAnimationsRequestNoScheduling(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: slow, atTime: MonoTime.now()), true)
    // 建立一次基线提交，随后暂停。
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    window.setAnimationsPaused(true)
    @Assert(window.animationsPaused(), true)
    @Assert(window.needsAnimationTick(), false)
    @Assert(window.advanceAnimations(atTime: MonoTime.now()), false)
    // 暂停期间不重建身份表：绑定数稳定。
    let bindings = window.animationBindingCount()
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    @Assert(window.animationBindingCount(), bindings)
    window.setAnimationsPaused(false)
    @Assert(window.needsAnimationTick(), true)
    window.close()
}

/// ④：accepted 结构成功切换时立即清理退役绑定（不依赖下一动画帧）；同 key/id
/// 重挂得到正常初值，不继承旧透明度。
@Test
func windowAcceptedChangeRetiresBindingsAndRebindStartsFresh(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000)
    @Assert(window.animateNodeOpacity(key, 0.6, spec: slow, atTime: MonoTime.now()), true)
    @Assert(window.animationBindingCount(), 1)

    // 移除节点并提交新的 accepted 结构：绑定必须在这一刻释放。
    controller.panelPresent = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.animationBindingCount(), 0)

    // 同 key/id 重挂：新绑定从 1.0 起步（presented 未推进），不继承 0.6。
    controller.panelPresent = true
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(windowAnimFindNode(window, key).isSome(), true)
    @Assert(window.animateNodeOpacity(key, 0.3, spec: slow, atTime: MonoTime.now()), true)
    @Assert(windowAnimApprox(window.animatedNodeOpacity(key) ?? -1.0, 1.0, 0.001), true)
    window.close()
}

/// ⑥：手写非法效果在接受 scene 前被具名拒绝（与生成侧同一词汇 + 声明路径），
/// 旧的 accepted 版本、身份与样式全部保持；恢复合法后旧控件仍可用。
@Test
func windowRefusesHandwrittenIllegalEffectBeforeAccepting(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let acceptedVersion = window.windowProgress().acceptedSceneVersion
    let legal = windowAnimFindNode(window, "semantic:anim-panel") ?? CjguiComposableUiLayoutNode.missing()
    @Assert(legal.style.shadow.isSome(), true)
    let legalNodeId = legal.nodeId

    controller.illegalShadow = true
    controller.bump()
    @Assert(window.refresh(), false)
    let progress = window.windowProgress()
    @Assert(progress.lastNativeFailure, "shadow_value_invalid")
    @Assert(window.lastRefusedEffectPath(), "/shadow")
    @Assert(progress.acceptedSceneVersion, acceptedVersion)
    let after = windowAnimFindNode(window, "semantic:anim-panel") ?? CjguiComposableUiLayoutNode.missing()
    @Assert(after.nodeId, legalNodeId)
    @Assert(after.style.shadow.isSome(), true)

    // 恢复合法：旧控件仍可用，候选重新被接受。
    controller.illegalShadow = false
    controller.bump()
    @Assert(window.refresh(), true)
    window.close()
}
/// ②：动态文字 alpha 必须保持 paint-only：连续改变 alpha 不改变文本内容、几何
/// 或身份，accepted paint 的 textColor alpha 随目标变化，且 native 不报告失败。
/// native 侧纹理键不再包含动态 alpha（alpha 作为绘制乘子消费），因此不逐帧重建
/// 排版/字形纹理；“栅格化/上传增量为 0”的计数判据由带 -DCJGUI_INTERNAL_TESTING
/// 的 native scale/探针给出（unittest 构建不导出该测试 ABI，无法在此断言）。
@Test
func windowTextAlphaAnimationStaysPaintOnly(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-label"
    let before = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(before.nodeId > 0, true)

    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    var alpha = 0.9
    while (alpha >= 0.3) {
        @Assert(window.animateNodeOpacity(key, alpha, spec: zero, atTime: MonoTime.now()), true)
        alpha -= 0.1
    }
    let after = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    // 内容、几何、身份均不变；只有 paint alpha 改变（不触发布局/测量/命中）。
    @Assert(after.nodeId, before.nodeId)
    @Assert(after.identityKey, key)
    @Assert(after.value, before.value)
    @Assert(after.bounds.width, before.bounds.width)
    @Assert(after.bounds.height, before.bounds.height)
    @Assert(windowAnimApprox(after.style.textColor.alpha, 0.3, 0.02), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    window.close()
}

/// P4: adding or clearing a neutral effect group around an existing node paint
/// animation must not redirect its opacity to the group's descendants.
@Test
func windowNodePaintOpacityRemainsSeparateFromEffectGroupOpacity(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelSubtreePresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let parentKey = "semantic:anim-panel"
    let childKey = "semantic:anim-child"
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0, easing: CjguiComposableUiAnimationEasing.LINEAR)

    @Assert(window.animateNodeOpacity(parentKey, 0.4, spec: zero, atTime: MonoTime.now()), true)
    let initialParent = windowAnimFindNode(window, parentKey) ?? CjguiComposableUiLayoutNode.missing()
    let initialChild = windowAnimFindNode(window, childKey) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(windowAnimApprox(initialParent.style.background.alpha, 0.4, 0.01), true)
    @Assert(windowAnimApprox(initialChild.style.textColor.alpha, 1.0, 0.01), true)

    controller.panelEffectGroupPresent = true
    controller.bump()
    @Assert(window.refresh(), true)
    let groupedParent = windowAnimFindNode(window, parentKey) ?? CjguiComposableUiLayoutNode.missing()
    let groupedChild = windowAnimFindNode(window, childKey) ?? CjguiComposableUiLayoutNode.missing()
    match (groupedParent.style.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 1.0, 0.01), true)
        case None => @Assert(false, true)
    }
    @Assert(windowAnimApprox(groupedParent.style.background.alpha, 0.4, 0.01), true)
    @Assert(windowAnimApprox(groupedChild.style.textColor.alpha, 1.0, 0.01), true)

    controller.panelEffectGroupPresent = false
    controller.bump()
    @Assert(window.refresh(), true)
    let clearedParent = windowAnimFindNode(window, parentKey) ?? CjguiComposableUiLayoutNode.missing()
    let clearedChild = windowAnimFindNode(window, childKey) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(clearedParent.style.effectGroup.isNone(), true)
    @Assert(windowAnimApprox(clearedParent.style.background.alpha, 0.4, 0.01), true)
    @Assert(windowAnimApprox(clearedChild.style.textColor.alpha, 1.0, 0.01), true)
    window.close()
}

/// P4: effect group opacity has its own subtree projection, retargeting,
/// accepted-token refusal, cancellation and scheduling lifetime.
@Test
func windowEffectGroupOpacityAnimatesSubtreeAndCanBeInterruptedStopped(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelSubtreePresent = true
    controller.panelEffectGroupPresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let parentKey = "semantic:anim-panel"
    let childKey = "semantic:anim-child"
    let token = window.acceptedAnimationBindingToken(parentKey) ?? CjguiComposableUiAnimationBinding(-1)
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000, easing: CjguiComposableUiAnimationEasing.LINEAR)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)

    @Assert(window.animateEffectGroupOpacity(parentKey, 0.2, spec: slow, atTime: MonoTime.now(),
        acceptedToken: Some(token)), true)
    @Assert(window.hasActiveAnimations(), true)
    @Assert(window.animateEffectGroupOpacity(parentKey, 0.8, spec: slow, atTime: MonoTime.now(),
        acceptedToken: Some(token)), true)
    @Assert(window.animatedEffectGroupOpacityTarget(parentKey) ?? -1.0, 0.8)
    @Assert(window.animateNodeOpacity(parentKey, 0.6, spec: slow, atTime: MonoTime.now(),
        acceptedToken: Some(token)), true)
    @Assert(window.animatedNodeOpacityTarget(parentKey) ?? -1.0, 0.6)
    @Assert(window.animationBindingCount(), 2)

    // A stale accepted token and a rejected non-finite target cannot disturb
    // the active group's current binding or target.
    let stale = CjguiComposableUiAnimationBinding(token.nodeId, resourceId: token.resourceId,
        nodeKind: token.nodeKind, actionName: token.actionName, operationActionName: token.operationActionName,
        operationResourceId: token.operationResourceId, fieldId: token.fieldId,
        windowInstanceToken: token.windowInstanceToken, acceptedBindingEpoch: token.acceptedBindingEpoch - 1)
    @Assert(window.animateEffectGroupOpacity(parentKey, 0.1, spec: slow, atTime: MonoTime.now(),
        acceptedToken: Some(stale)), false)
    @Assert(window.animateEffectGroupOpacity(parentKey, Float64.NaN, spec: slow, atTime: MonoTime.now()), false)
    @Assert(window.animatedEffectGroupOpacityTarget(parentKey) ?? -1.0, 0.8)
    @Assert(window.animationBindingCount(), 2)

    let zeroed = window.animateEffectGroupOpacity(parentKey, 0.35, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(token))
    @Assert(zeroed, true)
    let parent = windowAnimFindNode(window, parentKey) ?? CjguiComposableUiLayoutNode.missing()
    let child = windowAnimFindNode(window, childKey) ?? CjguiComposableUiLayoutNode.missing()
    match (parent.style.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 0.35, 0.01), true)
        case None => @Assert(false, true)
    }
    // Group opacity is applied once by the isolated group; child paint remains
    // at its accepted value instead of receiving a second alpha multiplier.
    @Assert(windowAnimApprox(child.style.textColor.alpha, 1.0, 0.01), true)

    @Assert(window.cancelEffectGroupOpacityAnimation(parentKey), true)
    @Assert(window.hasActiveAnimations(), true)
    @Assert(window.cancelNodeOpacityAnimation(parentKey), true)
    @Assert(window.hasActiveAnimations(), false)
    @Assert(window.needsAnimationTick(), false)
    let submissions = window.windowProjection().nativeSubmissionCount
    @Assert(window.testAdvanceAnimationsAtMs(1000000.0), false)
    @Assert(window.windowProjection().nativeSubmissionCount, submissions)

    // Accepting removal of the group retires its channel immediately, even
    // while a tween is still active.
    @Assert(window.animateEffectGroupOpacity(parentKey, 0.1, spec: slow, atTime: MonoTime.now(),
        acceptedToken: Some(token)), true)
    @Assert(window.hasActiveAnimations(), true)
    controller.panelEffectGroupPresent = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.animationBindingCount(), 0)
    @Assert(window.hasActiveAnimations(), false)
    @Assert(window.animateEffectGroupOpacity(parentKey, 0.0, spec: slow, atTime: MonoTime.now()), false)
    window.close()
}

/// A group opacity channel is absolute. The value 1 is a real override when
/// the accepted declaration is 0.4, even though the node paint multiplier is 1.
@Test
func windowEffectGroupZeroDurationReachesOpaqueFromDimDeclaration(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelEffectGroupPresent = true
    controller.panelEffectGroupOpacity = 0.4
    controller.panelSubtreePresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let before = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    match (before.style.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 0.4, 0.001), true)
        case None => @Assert(false, true)
    }
    let submissions = window.windowProjection().nativeSubmissionCount
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateEffectGroupOpacity(key, 1.0, spec: zero, atTime: MonoTime.now()), true)
    @Assert(windowAnimApprox(window.animatedEffectGroupOpacity(key) ?? -1.0, 1.0, 0.001), true)
    let after = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    match (after.declaredStyle.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 0.4, 0.001), true)
        case None => @Assert(false, true)
    }
    match (after.style.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 1.0, 0.001), true)
        case None => @Assert(false, true)
    }
    @Assert(window.windowProjection().nativeSubmissionCount > submissions, true)
    @Assert(window.needsAnimationTick(), false)
    let settled = window.windowProjection().nativeSubmissionCount
    @Assert(window.testAdvanceAnimationsAtMs(1000000000000.0), false)
    @Assert(window.windowProjection().nativeSubmissionCount, settled)
    window.close()
}

@Test
func windowEffectGroupTweenReachesOpaqueWithoutChangingNodePaint(): Unit {
    let controller = WindowAnimationTestController()
    controller.panelEffectGroupPresent = true
    controller.panelEffectGroupOpacity = 0.4
    controller.panelSubtreePresent = true
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
        easing: CjguiComposableUiAnimationEasing.LINEAR)
    @Assert(window.animateEffectGroupOpacity(key, 1.0, spec: slow, atTime: MonoTime.now()), true)
    @Assert(window.hasActiveAnimations(), true)
    @Assert(window.testAdvanceAnimationsAtMs(1000000000000.0), false)
    @Assert(windowAnimApprox(window.animatedEffectGroupOpacity(key) ?? -1.0, 1.0, 0.001), true)
    let parent = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    let child = windowAnimFindNode(window, "semantic:anim-child") ?? CjguiComposableUiLayoutNode.missing()
    match (parent.declaredStyle.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 0.4, 0.001), true)
        case None => @Assert(false, true)
    }
    match (parent.style.effectGroup) {
        case Some(group) => @Assert(windowAnimApprox(group.opacity, 1.0, 0.001), true)
        case None => @Assert(false, true)
    }
    @Assert(windowAnimApprox(parent.style.background.alpha, 1.0, 0.001), true)
    @Assert(windowAnimApprox(child.style.textColor.alpha, 1.0, 0.001), true)
    @Assert(window.hasActiveAnimations(), false)
    @Assert(window.needsAnimationTick(), false)
    let settled = window.windowProjection().nativeSubmissionCount
    @Assert(window.testAdvanceAnimationsAtMs(1000000001000.0), false)
    @Assert(window.windowProjection().nativeSubmissionCount, settled)
    window.close()
}
/// A4：accepted 场景在同一 identity 与手工 nodeId 下直接换绑 resource/action 时，
/// 已收敛的残留绑定必须在接受新场景的那一刻被释放；重新绑定只驱动新节点，
/// paint 用的是新绑定值，而不是旧通道遗留的 0.0。
@Test
func windowSameSlotRebindRetiresOldAnimation(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let initial = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    let nodeId = initial.nodeId

    // 旧槽位（resource=-1）零时长补间到 0.0：paint 立即透明，绑定残留为 inactive。
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: zero, atTime: MonoTime.now()), true)
    @Assert(window.animationBindingCount(), 1)
    let zeroed = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(zeroed.style.background.alpha < 0.001, true)

    // 同一 identity/nodeId/节点种类，直接换 resource + action：旧绑定在接受后释放。
    controller.panelResourceId = 2
    controller.panelActionName = "ACT_NEW"
    controller.bump()
    @Assert(window.refresh(), true)
    let rebound = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(rebound.nodeId, nodeId)
    @Assert(window.animationBindingCount(), 0)
    @Assert(rebound.style.background.alpha > 0.999, true)

    // 重新绑定新槽位：零时长到 0.5，paint 用新值（证明旧 0.0 没有落到新实例）。
    @Assert(window.animateNodeOpacity(key, 0.5, spec: zero, atTime: MonoTime.now()), true)
    let refreshed = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(windowAnimApprox(refreshed.style.background.alpha, 0.5, 0.01), true)
    window.close()
}

/// A4：非法候选被拒绝时不改变当前 accepted 场景，也不取消/替换当前动画绑定。
@Test
func windowRejectedCandidateKeepsAnimationBinding(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: zero, atTime: MonoTime.now()), true)
    @Assert(window.animationBindingCount(), 1)
    let acceptedVersion = window.windowProgress().acceptedSceneVersion

    // 非法候选（越界 shadow）：refresh 被拒，accepted 版本与绑定都保持不变。
    controller.illegalShadow = true
    controller.bump()
    @Assert(window.refresh(), false)
    @Assert(window.windowProgress().acceptedSceneVersion, acceptedVersion)
    @Assert(window.animationBindingCount(), 1)
    let held = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(held.style.background.alpha < 0.001, true)

    // 恢复合法：旧绑定仍在，仍可继续驱动；候选重新被接受。
    controller.illegalShadow = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.animationBindingCount(), 1)
    window.close()
}
/// A4：accepted 同一 identity/nodeId 下切换**业务** operationResourceId 再接受 B：
/// 活动绑定被释放；携旧 A token 的异步调用被拒，携新 token 的调用才落到新实例。
@Test
func windowActiveAnimationOperationTargetRebindAndStaleTokenRejected(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    controller.panelOperationResourceId = 100
    controller.bump()
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let before = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    let tokenA = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)

    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: slow, atTime: MonoTime.now()), true)
    @Assert(window.hasActiveAnimations(), true)
    @Assert(window.animationBindingCount(), 1)

    // 接受 B：同一 identity/nodeId，只换业务操作资源。
    controller.panelOperationResourceId = 200
    controller.bump()
    @Assert(window.refresh(), true)
    let after = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(after.nodeId, before.nodeId)
    @Assert(window.animationBindingCount(), 0)
    @Assert(window.hasActiveAnimations(), false)

    // 携旧 A token 的旧异步调用必须被拒，且不建立绑定。
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(key, 0.3, spec: zero, atTime: MonoTime.now(), acceptedToken: Some(tokenA)),
        false)
    @Assert(window.animationBindingCount(), 0)
    // 携当前 B token 的调用生效，paint 使用新绑定的值。
    let tokenB = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(window.animateNodeOpacity(key, 0.3, spec: zero, atTime: MonoTime.now(), acceptedToken: Some(tokenB)), true)
    let bound = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(windowAnimApprox(bound.style.background.alpha, 0.3, 0.01), true)
    window.close()
}

/// A→B→A returns to the seven original content fields, but never to the old
/// accepted generation. A token issued by another window is also never valid.
@Test
func windowBindingEpochRejectsAbaAndCrossWindowTokens(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let tokenA = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(tokenA.acceptedBindingEpoch > 0, true)

    controller.panelOperationResourceId = 42
    controller.bump()
    @Assert(window.refresh(), true)
    let tokenB = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(tokenA.matches(tokenB), false)

    controller.panelOperationResourceId = -1
    controller.bump()
    @Assert(window.refresh(), true)
    let tokenA2 = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(tokenA.sameContent(tokenA2), true)
    @Assert(tokenA.matches(tokenA2), false)
    controller.panelLabel = "same binding, different text"
    controller.bump()
    @Assert(window.refresh(), true)
    let textToken = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(textToken.matches(tokenA2), true)
    controller.illegalShadow = true
    controller.panelOperationResourceId = 77
    controller.bump()
    @Assert(window.refresh(), false)
    let rejectedToken = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(rejectedToken.matches(tokenA2), true)
    controller.illegalShadow = false
    controller.panelOperationResourceId = -1
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(key, 0.3, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(tokenA)), false)
    @Assert(window.animateNodeOpacity(key, 0.3, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(tokenA2)), true)

    let other = CjguiComposableUiWindow(WindowAnimationTestController())
    @Assert(other.start(), true)
    @Assert(other.refresh(), true)
    let otherToken = other.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(otherToken.windowInstanceToken == tokenA2.windowInstanceToken, false)
    @Assert(window.animateNodeOpacity(key, 0.4, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(otherToken)), false)
    controller.panelPresent = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.acceptedAnimationBindingToken(key).isNone(), true)
    controller.panelPresent = true
    controller.bump()
    @Assert(window.refresh(), true)
    let remounted = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(remounted.sameContent(tokenA2), true)
    @Assert(remounted.matches(tokenA2), false)
    other.close()
    window.close()
}

/// A4：非法候选已改变绑定事实（业务操作资源变化）但被拒——拒绝后 A 仍可推进，
/// accepted 版本与绑定不变；只有恢复合法并接受 B 后旧绑定才清除。
@Test
func windowRejectedCandidateWithChangedOperationKeepsActiveBinding(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    controller.panelOperationResourceId = 100
    controller.bump()
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: slow, atTime: MonoTime.now()), true)
    @Assert(window.hasActiveAnimations(), true)
    let acceptedVersion = window.windowProgress().acceptedSceneVersion

    // 候选改变绑定事实（业务操作资源 200）同时携带非法效果：必须整体拒绝。
    controller.panelOperationResourceId = 200
    controller.illegalShadow = true
    controller.bump()
    @Assert(window.refresh(), false)
    @Assert(window.windowProgress().acceptedSceneVersion, acceptedVersion)
    @Assert(window.animationBindingCount(), 1)
    @Assert(window.hasActiveAnimations(), true)
    let heldNode = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(heldNode.operationResourceId, 100)

    // 恢复合法后接受 B：旧绑定此刻才清除。
    controller.illegalShadow = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.animationBindingCount(), 0)
    @Assert(window.hasActiveAnimations(), false)
    window.close()
}

/// A4：仅文案变化真正提交一个新的 accepted 场景，但槽位判据未变——绑定保留、
/// 呈现值连续，不从 1.0 重新起步。
@Test
func windowPureTextChangeKeepsAnimationBindingContinuous(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeOpacity(key, 0.5, spec: zero, atTime: MonoTime.now()), true)
    @Assert(window.animationBindingCount(), 1)
    @Assert(windowAnimApprox(window.animatedNodeOpacity(key) ?? -1.0, 0.5, 0.001), true)
    let beforeVersion = window.windowProgress().acceptedSceneVersion

    // 仅改这一节点的文案：真正提交一个新的 accepted 场景。
    controller.panelLabel = "更新后的文案"
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().acceptedSceneVersion > beforeVersion, true)
    @Assert(window.animationBindingCount(), 1)
    @Assert(windowAnimApprox(window.animatedNodeOpacity(key) ?? -1.0, 0.5, 0.001), true)
    let node = windowAnimFindNode(window, key) ?? CjguiComposableUiLayoutNode.missing()
    @Assert(windowAnimApprox(node.style.background.alpha, 0.5, 0.02), true)
    window.close()
}

/// A4/Astra：暂停中接受换绑，accepted 场景已提交当前投影——pending 被确认，
/// 恢复后不残留无意义的动画 tick。
@Test
func windowPausedAcceptedRebindClearsPendingWithoutStrayTick(): Unit {
    let controller = WindowAnimationTestController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:anim-panel"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 5000)
    @Assert(window.animateNodeOpacity(key, 0.0, spec: slow, atTime: MonoTime.now()), true)
    window.setAnimationsPaused(true)
    @Assert(window.needsAnimationTick(), false)

    // 暂停期间 accepted 换绑：收尾确认 pending，并释放旧绑定。
    controller.panelOperationResourceId = 9
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.animationBindingCount(), 0)
    @Assert(window.advanceAnimations(atTime: MonoTime.now()), false)

    // 恢复后：无绑定、无 pending，不再申请帧。
    window.setAnimationsPaused(false)
    @Assert(window.needsAnimationTick(), false)
    window.close()
}
