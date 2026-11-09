// B(2026-09-28) 声明完整性回归：offsetX/Y、wheelScrollable、scrollContentAlignY 与
// pointerInteractive 是真实声明，不是 paint 附属品。
//
// 反例来自首页返工复核：paint-only 重建（命名样式 overlay、交互态解析、窗口 opacity
// 乘子、颜色过渡）逐字段构造新样式时丢掉了新声明；appendStyle/sameStyle 缺席使缓存
// 签名与 scene 判等对它们失明；布局复用缓存的签名在 offset 应用前生成，重放会交回
// 上一笔 offset 的几何。
package cjgui

import std.collection.*

private func declarationBaseStyle(): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        border: CjguiComposableUiColor(0.7, 0.7, 0.7, 1.0), padding: 4, gap: 2,
        fixedWidth: 120, fixedHeight: 40, offsetX: 6, offsetY: -9, wheelScrollable: true,
        scrollContentAlignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER, pointerInteractive: true, clipsContent: true,
        cornerRadius: 3)
}

@Test
func paintOnlyRebuildsPreserveEveryNonPaintDeclaration(): Unit {
    let base = declarationBaseStyle()
    // 1) named-style paint overlay
    let overlay = cjguiComposableUiPaintOverlay(base,
        CjguiComposableUiStyle(background: CjguiComposableUiColor(0.1, 0.2, 0.3, 1.0),
            border: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0),
            textColor: CjguiComposableUiColor(0.9, 0.9, 0.9, 1.0), borderWidth: 2))
    @Assert(overlay.background.red == 0.1 && overlay.background.blue == 0.3)
    @Assert(overlay.borderWidth == 2)
    @Assert(overlay.offsetX == 6)
    @Assert(overlay.offsetY == -9)
    @Assert(overlay.wheelScrollable)
    @Assert(overlay.scrollContentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(overlay.pointerInteractive)
    @Assert(overlay.clipsContent && overlay.cornerRadius == 3)
    // 2) interaction-state resolution (hover only declares a background)
    let interaction = CjguiComposableUiInteractionStyle(hover: CjguiComposableUiPaintStyle(
        background: Some(CjguiComposableUiColor(0.2, 0.2, 0.2, 1.0))))
    let hovered = interaction.resolve(base, CjguiComposableUiInteractionState.HOVER)
    @Assert(hovered.background.red == 0.2 && hovered.background.alpha == 1.0)
    @Assert(hovered.offsetX == 6 && hovered.offsetY == -9)
    @Assert(hovered.wheelScrollable)
    @Assert(hovered.scrollContentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(hovered.pointerInteractive)
    // 3) the shared copy entry itself
    let copied = cjguiComposableUiStyleWithPaint(base, base.background, base.border, base.textColor,
        base.borderWidth, base.shadow, base.gradient, base.effectGroup)
    @Assert(copied.offsetY == -9 && copied.wheelScrollable && copied.pointerInteractive)
}

/// 透明 VERTICAL/HORIZONTAL 的“视觉中性”快路径只有在不携带输入/位移时才允许跳过；
/// 声明滚轮资格或位移后，bounds/clip/声明变化必须进入 accepted 输入投影。
@Test
func neutralGroupShortcutIsRefusedForInputOrDisplacementDeclarations(): Unit {
    let plain = CjguiComposableUiStyle()
    @Assert(!cjguiComposableUiGroupCarriesInputOrDisplacement(plain))
    @Assert(cjguiComposableUiGroupCarriesInputOrDisplacement(CjguiComposableUiStyle(wheelScrollable: true)))
    @Assert(cjguiComposableUiGroupCarriesInputOrDisplacement(CjguiComposableUiStyle(offsetY: 3)))
    @Assert(cjguiComposableUiGroupCarriesInputOrDisplacement(CjguiComposableUiStyle(offsetX: -3)))
    @Assert(cjguiComposableUiGroupCarriesInputOrDisplacement(CjguiComposableUiStyle(pointerInteractive: true)))
}

/// 滚轮意图按声明解析，不按节点类型：普通容器声明 wheelScrollable 后必须能在
/// accepted 投影里解析出同一身份；未声明的容器仍然被拒（不因此获得点击/焦点资格）。
@Test
func wheelIntentResolvesByDeclarationNotByNodeKind(): Unit {
    let root = cjguiComposableVertical(7400, "b-wheel-root", CjguiComposableUiStyle())
    root.add(cjguiComposableHorizontal(7401, "b-wheel-column",
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 60, wheelScrollable: true)))
    root.add(cjguiComposableHorizontal(7402, "b-wheel-plain",
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 60)))
    root.add(cjguiComposableScrollArea(7403, "b-wheel-scroll", 0,
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 60)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 200, 200), 1)
    @Assert(scene.isValid(), true)
    // Declared eligibility: the plain HORIZONTAL answers the SCROLL intent.
    let eligible = scene.resolveWheelTarget(7401, -1, CJGUI_COMPOSABLE_UI_HORIZONTAL, 1)
    @Assert(eligible.nodeId, 7401)
    // Control: a container without the declaration is still refused.
    let plain = scene.resolveWheelTarget(7402, -1, CJGUI_COMPOSABLE_UI_HORIZONTAL, 1)
    @Assert(plain.nodeId, -1)
    // A scroll area keeps answering through its kind.
    let scroll = scene.resolveWheelTarget(7403, -1, CJGUI_COMPOSABLE_UI_SCROLL_AREA, 1)
    @Assert(scroll.nodeId, 7403)
    // Stale projection version and wrong identity are still refused.
    @Assert(scene.resolveWheelTarget(7401, -1, CJGUI_COMPOSABLE_UI_HORIZONTAL, 2).nodeId, -1)
    @Assert(scene.resolveWheelTarget(7401, 7, CJGUI_COMPOSABLE_UI_HORIZONTAL, 1).nodeId, -1)
    // The wheel declaration must NOT silently turn the container into a
    // click/keyboard/focus input target.
    @Assert(scene.resolveInput(7401, -1, CJGUI_COMPOSABLE_UI_HORIZONTAL, 1).nodeId, -1)
    @Assert(scene.nodeForId(7401).canReceiveInput(), false)
    @Assert(scene.nodeForId(7401).canReceiveFocus(), false)
}

private func keyedRegionRoot(offsetY: Int64, wheel: Bool, alignment: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(7300, "b-cache-root", CjguiComposableUiStyle(gap: 0))
    let region = cjguiComposableVertical(7301, "b-cache-region",
        CjguiComposableUiStyle(offsetY: offsetY, wheelScrollable: wheel, scrollContentAlignY: alignment),
        layoutReuseKey: "b-region-v1")
    region.add(cjguiComposableText(7302, "b-cache-label", "内容",
        CjguiComposableUiStyle(fixedHeight: 20)))
    root.add(region)
    return root
}

/// 同一 cache、仅改 offset/对齐：重放必须失效，交回的是新几何而不是上一笔布局。
@Test
func keyedRegionReplayNeverServesAStaleOffsetOrAlignment(): Unit {
    let cache = CjguiComposableUiLayoutReuseCache()
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let viewport = CjguiComposableUiRect(0, 0, 200, 100)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(0, false,
        CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 1, measurer, reuseCache: cache)
    @Assert(first.scene.isValid())
    @Assert(first.scene.nodeForId(7301).bounds.y == 0)
    // Control: an unchanged declaration DOES replay, so the counterexample
    // below is really exercising the replay path.
    let repeated = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(0, false,
        CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 2, measurer, reuseCache: cache)
    @Assert(repeated.scene.isValid())
    @Assert(repeated.metrics.subtreeReuseReplayedNodeCount > 0)
    @Assert(repeated.scene.nodeForId(7301).bounds.y == 0)
    // Offset-only change: a replayed region would keep y=0.
    let moved = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(9, false,
        CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 3, measurer, reuseCache: cache)
    @Assert(moved.scene.isValid())
    @Assert(moved.scene.nodeForId(7301).bounds.y == 9)
    @Assert(moved.scene.nodeForId(7302).bounds.y == 9)
    @Assert(moved.metrics.subtreeReuseReplayedNodeCount == 0)
    // Wheel-only change: the replayed node must not keep the pre-eligibility
    // declaration, or the accepted input projection never learns the region
    // routes the wheel.
    let wheeled = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(9, true,
        CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 4, measurer, reuseCache: cache)
    @Assert(wheeled.scene.isValid())
    @Assert(wheeled.scene.nodeForId(7301).style.wheelScrollable)
    @Assert(wheeled.metrics.subtreeReuseReplayedNodeCount == 0)
}

/// 短内容对齐也参与几何：同一 cache 下只改 scrollContentAlignY，重放必须失效，
/// 滚动区内容位置必须来自本次声明。
@Test
func keyedRegionReplayNeverServesAStaleShortContentAlignment(): Unit {
    let cache = CjguiComposableUiLayoutReuseCache()
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let viewport = CjguiComposableUiRect(0, 0, 200, 100)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(0, false,
        CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 1, measurer, reuseCache: cache)
    @Assert(first.scene.isValid())
    let aligned = CjguiComposableUiLayoutEngine.layoutWithMetrics(keyedRegionRoot(0, false,
        CJGUI_COMPOSABLE_UI_ALIGN_CENTER), viewport, 2, measurer, reuseCache: cache)
    @Assert(aligned.scene.isValid())
    @Assert(aligned.scene.nodeForId(7301).style.scrollContentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(aligned.metrics.subtreeReuseReplayedNodeCount == 0)
}
