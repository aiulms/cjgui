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
        cornerRadius: 3, contentAlignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER,
        contentAlignY: CJGUI_COMPOSABLE_UI_ALIGN_END)
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
    @Assert(overlay.contentAlignX == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(overlay.contentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_END)
    // 2) interaction-state resolution (hover only declares a background)
    let interaction = CjguiComposableUiInteractionStyle(hover: CjguiComposableUiPaintStyle(
        background: Some(CjguiComposableUiColor(0.2, 0.2, 0.2, 1.0))))
    let hovered = interaction.resolve(base, CjguiComposableUiInteractionState.HOVER)
    @Assert(hovered.background.red == 0.2 && hovered.background.alpha == 1.0)
    @Assert(hovered.offsetX == 6 && hovered.offsetY == -9)
    @Assert(hovered.wheelScrollable)
    @Assert(hovered.scrollContentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(hovered.pointerInteractive)
    @Assert(hovered.contentAlignX == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(hovered.contentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_END)
    // 3) the shared copy entry itself
    let copied = cjguiComposableUiStyleWithPaint(base, base.background, base.border, base.textColor,
        base.borderWidth, base.shadow, base.gradient, base.effectGroup)
    @Assert(copied.offsetY == -9 && copied.wheelScrollable && copied.pointerInteractive)
    @Assert(copied.contentAlignX == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(copied.contentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_END)
    // 4) the translation copy used by accepted presentation/transitions
    let translated = cjguiComposableUiStyleWithTranslation(base, 3.0, 4.0)
    @Assert(translated.translateX == 3.0 && translated.translateY == 4.0)
    @Assert(translated.contentAlignX == CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(translated.contentAlignY == CJGUI_COMPOSABLE_UI_ALIGN_END)
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

private func rootMetadataReuseTree(semanticLabel: String, resource!: Int64 = 17,
    field!: String = "metadata-field", action!: String = ""): CjguiComposableUiNode {
    let root = cjguiComposableVertical(7400, "metadata-page", CjguiComposableUiStyle())
    let region = CjguiComposableUiNode(7401, "metadata-region", CJGUI_COMPOSABLE_UI_VERTICAL,
        "", "", action, resource, CjguiComposableUiStyle(fixedHeight: 40),
        fieldId: field, semanticLabel: semanticLabel, layoutReuseKey: "metadata-region-v1")
    region.add(cjguiComposableText(7402, "metadata-text", "内容", CjguiComposableUiStyle(fixedHeight: 20)))
    root.add(region)
    return root
}

@Test
func stableKeyDoesNotReuseChangedRegionRootMetadata(): Unit {
    let cache = CjguiComposableUiLayoutReuseCache()
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(rootMetadataReuseTree("旧标签"), bounds, 1,
        measurer, reuseCache: cache)
    @Assert(first.scene.isValid(), true)
    @Assert(first.scene.nodeForId(7401).semanticLabel, "旧标签")
    let next = CjguiComposableUiLayoutEngine.layoutWithMetrics(rootMetadataReuseTree("新标签"), bounds, 2,
        measurer, reuseCache: cache)
    @Assert(next.scene.isValid(), true)
    @Assert(next.scene.nodeForId(7401).semanticLabel, "新标签")
    @Assert(next.metrics.subtreeReuseHitCount, 0)
    let business = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        rootMetadataReuseTree("新标签", resource: 19, field: "changed-field", action: "OPEN"), bounds, 3,
        measurer, reuseCache: cache)
    @Assert(business.metrics.subtreeReuseHitCount, 0)
    @Assert(business.scene.nodeForId(7401).resourceId, 19)
    @Assert(business.scene.nodeForId(7401).fieldId, "changed-field")
    @Assert(business.scene.nodeForId(7401).actionName, "OPEN")
    let canonical = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        rootMetadataReuseTree("新标签", resource: 19, field: "changed-field", action: "OPEN"), bounds, 3, measurer)
    assertWrappedCanonicalScene(business.scene, canonical.scene)
}

private func assertWrappedCanonicalColor(a: CjguiComposableUiColor, b: CjguiComposableUiColor): Unit {
    @Assert(a.red, b.red)
    @Assert(a.green, b.green)
    @Assert(a.blue, b.blue)
    @Assert(a.alpha, b.alpha)
}

private func assertWrappedCanonicalScene(actual: CjguiComposableUiScene, expected: CjguiComposableUiScene): Unit {
    let left = actual.nodes()
    let right = expected.nodes()
    @Assert(left.size, right.size)
    for (i in 0..left.size) {
        let a = left[i]
        let b = right[i]
        @Assert(a.nodeId, b.nodeId)
        @Assert(a.semanticId, b.semanticId)
        @Assert(a.nodeKind, b.nodeKind)
        @Assert(a.label, b.label)
        @Assert(a.value, b.value)
        @Assert(a.actionName, b.actionName)
        @Assert(a.resourceId, b.resourceId)
        @Assert(a.fieldId, b.fieldId)
        @Assert(a.operationActionName, b.operationActionName)
        @Assert(a.operationResourceId, b.operationResourceId)
        @Assert(a.displayValueRole, b.displayValueRole)
        @Assert(a.imageResourcePath, b.imageResourcePath)
        @Assert(a.imageResourceId, b.imageResourceId)
        @Assert(a.imageResourceVersion, b.imageResourceVersion)
        @Assert(a.imageContentMode, b.imageContentMode)
        @Assert(a.isEnabled, b.isEnabled)
        @Assert(a.isReadOnly, b.isReadOnly)
        @Assert(a.tabInsertsText, b.tabInsertsText)
        @Assert(a.pointerControlRole, b.pointerControlRole)
        @Assert(a.pointerControlAxis, b.pointerControlAxis)
        @Assert(a.pointerControlMinimum, b.pointerControlMinimum)
        @Assert(a.pointerControlMaximum, b.pointerControlMaximum)
        @Assert(a.pointerControlStep, b.pointerControlStep)
        @Assert(a.pointerControlHandleThickness, b.pointerControlHandleThickness)
        @Assert(a.pointerControlFirstSize, b.pointerControlFirstSize)
        @Assert(a.pointerControlSecondMinimum, b.pointerControlSecondMinimum)
        @Assert(a.subtreeNodeCount, b.subtreeNodeCount)
        @Assert(a.clipCornerRadius, b.clipCornerRadius)
        @Assert(a.ownerInteractionState, b.ownerInteractionState)
        @Assert(a.semanticRole, b.semanticRole)
        @Assert(a.semanticLabel, b.semanticLabel)
        @Assert(a.semanticHelp, b.semanticHelp)
        @Assert(a.semanticSelected, b.semanticSelected)
        @Assert(a.semanticExpandable, b.semanticExpandable)
        @Assert(a.semanticExpanded, b.semanticExpanded)
        @Assert(a.semanticLevel, b.semanticLevel)
        @Assert(a.semanticKey, b.semanticKey)
        @Assert(a.semanticParentKey, b.semanticParentKey)
        @Assert(a.semanticIncarnation, b.semanticIncarnation)
        @Assert(a.inputScopeId, b.inputScopeId)
        @Assert(a.layerId, b.layerId)
        @Assert(a.layerKind, b.layerKind)
        @Assert(a.identityKey, b.identityKey)
        @Assert(a.imageTransferOffer.isSome(), b.imageTransferOffer.isSome())
        @Assert(a.bounds.x, b.bounds.x)
        @Assert(a.bounds.y, b.bounds.y)
        @Assert(a.bounds.width, b.bounds.width)
        @Assert(a.bounds.height, b.bounds.height)
        @Assert(a.clip.x, b.clip.x)
        @Assert(a.clip.y, b.clip.y)
        @Assert(a.clip.width, b.clip.width)
        @Assert(a.clip.height, b.clip.height)
        let clipsA = a.clipConstraints()
        let clipsB = b.clipConstraints()
        @Assert(clipsA.size, clipsB.size)
        for (j in 0..clipsA.size) {
            @Assert(clipsA[j].ownerIdentity, clipsB[j].ownerIdentity)
            @Assert(clipsA[j].cornerRadius, clipsB[j].cornerRadius)
            @Assert(clipsA[j].rect.x, clipsB[j].rect.x)
            @Assert(clipsA[j].rect.y, clipsB[j].rect.y)
            @Assert(clipsA[j].rect.width, clipsB[j].rect.width)
            @Assert(clipsA[j].rect.height, clipsB[j].rect.height)
        }
        @Assert(a.textStyleRuns.size, b.textStyleRuns.size)
        for (j in 0..a.textStyleRuns.size) { @Assert(a.textStyleRuns[j].encoded(), b.textStyleRuns[j].encoded()) }
        @Assert(a.style.padding, b.style.padding)
        @Assert(a.style.gap, b.style.gap)
        @Assert(a.style.fixedWidth, b.style.fixedWidth)
        @Assert(a.style.fixedHeight, b.style.fixedHeight)
        @Assert(a.style.growX, b.style.growX)
        @Assert(a.style.growY, b.style.growY)
        @Assert(a.style.borderWidth, b.style.borderWidth)
        @Assert(a.style.cornerRadius, b.style.cornerRadius)
        @Assert(a.style.clipsContent, b.style.clipsContent)
        @Assert(a.style.pointerInteractive, b.style.pointerInteractive)
        @Assert(a.style.fontSize, b.style.fontSize)
        @Assert(a.style.fontWeight, b.style.fontWeight)
        @Assert(a.style.textMaxLines, b.style.textMaxLines)
        @Assert(a.style.textOverflow, b.style.textOverflow)
        @Assert(a.style.letterSpacing, b.style.letterSpacing)
        @Assert(a.style.lineHeight, b.style.lineHeight)
        @Assert(a.style.fontFamily, b.style.fontFamily)
        @Assert(a.style.minWidth, b.style.minWidth)
        @Assert(a.style.maxWidth, b.style.maxWidth)
        @Assert(a.style.idealWidth, b.style.idealWidth)
        @Assert(a.style.minHeight, b.style.minHeight)
        @Assert(a.style.maxHeight, b.style.maxHeight)
        @Assert(a.style.idealHeight, b.style.idealHeight)
        @Assert(a.style.alignX, b.style.alignX)
        @Assert(a.style.alignY, b.style.alignY)
        @Assert(a.style.offsetX, b.style.offsetX)
        @Assert(a.style.offsetY, b.style.offsetY)
        @Assert(a.style.translateX, b.style.translateX)
        @Assert(a.style.translateY, b.style.translateY)
        @Assert(a.style.scaleX, b.style.scaleX)
        @Assert(a.style.scaleY, b.style.scaleY)
        @Assert(a.style.wheelScrollable, b.style.wheelScrollable)
        @Assert(a.style.scrollContentAlignY, b.style.scrollContentAlignY)
        @Assert(a.style.zIndex, b.style.zIndex)
        @Assert(a.style.rotateDegrees, b.style.rotateDegrees)
        assertWrappedCanonicalColor(a.style.background, b.style.background)
        assertWrappedCanonicalColor(a.style.border, b.style.border)
        assertWrappedCanonicalColor(a.style.textColor, b.style.textColor)
        @Assert(a.style.cornerRadii.isSome(), b.style.cornerRadii.isSome())
        @Assert(a.style.shadow.isSome(), b.style.shadow.isSome())
        @Assert(a.style.gradient.isSome(), b.style.gradient.isSome())
        @Assert(a.style.effectGroup.isSome(), b.style.effectGroup.isSome())
        @Assert(a.style.effectRejection.isSome(), b.style.effectRejection.isSome())
        @Assert(a.style.iconTint.isSome(), b.style.iconTint.isSome())
        @Assert(a.declaredStyle.padding, b.declaredStyle.padding)
        @Assert(a.declaredStyle.gap, b.declaredStyle.gap)
        @Assert(a.declaredStyle.fixedWidth, b.declaredStyle.fixedWidth)
        @Assert(a.declaredStyle.fixedHeight, b.declaredStyle.fixedHeight)
        @Assert(a.declaredStyle.growX, b.declaredStyle.growX)
        @Assert(a.declaredStyle.growY, b.declaredStyle.growY)
        @Assert(a.declaredStyle.borderWidth, b.declaredStyle.borderWidth)
        @Assert(a.declaredStyle.cornerRadius, b.declaredStyle.cornerRadius)
        @Assert(a.declaredStyle.clipsContent, b.declaredStyle.clipsContent)
        @Assert(a.declaredStyle.pointerInteractive, b.declaredStyle.pointerInteractive)
        @Assert(a.declaredStyle.fontSize, b.declaredStyle.fontSize)
        @Assert(a.declaredStyle.fontWeight, b.declaredStyle.fontWeight)
        @Assert(a.declaredStyle.textMaxLines, b.declaredStyle.textMaxLines)
        @Assert(a.declaredStyle.textOverflow, b.declaredStyle.textOverflow)
        @Assert(a.declaredStyle.letterSpacing, b.declaredStyle.letterSpacing)
        @Assert(a.declaredStyle.lineHeight, b.declaredStyle.lineHeight)
        @Assert(a.declaredStyle.fontFamily, b.declaredStyle.fontFamily)
        @Assert(a.declaredStyle.minWidth, b.declaredStyle.minWidth)
        @Assert(a.declaredStyle.maxWidth, b.declaredStyle.maxWidth)
        @Assert(a.declaredStyle.idealWidth, b.declaredStyle.idealWidth)
        @Assert(a.declaredStyle.minHeight, b.declaredStyle.minHeight)
        @Assert(a.declaredStyle.maxHeight, b.declaredStyle.maxHeight)
        @Assert(a.declaredStyle.idealHeight, b.declaredStyle.idealHeight)
        @Assert(a.declaredStyle.alignX, b.declaredStyle.alignX)
        @Assert(a.declaredStyle.alignY, b.declaredStyle.alignY)
        @Assert(a.declaredStyle.offsetX, b.declaredStyle.offsetX)
        @Assert(a.declaredStyle.offsetY, b.declaredStyle.offsetY)
        @Assert(a.declaredStyle.translateX, b.declaredStyle.translateX)
        @Assert(a.declaredStyle.translateY, b.declaredStyle.translateY)
        @Assert(a.declaredStyle.scaleX, b.declaredStyle.scaleX)
        @Assert(a.declaredStyle.scaleY, b.declaredStyle.scaleY)
        @Assert(a.declaredStyle.wheelScrollable, b.declaredStyle.wheelScrollable)
        @Assert(a.declaredStyle.scrollContentAlignY, b.declaredStyle.scrollContentAlignY)
        @Assert(a.declaredStyle.zIndex, b.declaredStyle.zIndex)
        @Assert(a.declaredStyle.rotateDegrees, b.declaredStyle.rotateDegrees)
        assertWrappedCanonicalColor(a.declaredStyle.background, b.declaredStyle.background)
        assertWrappedCanonicalColor(a.declaredStyle.border, b.declaredStyle.border)
        assertWrappedCanonicalColor(a.declaredStyle.textColor, b.declaredStyle.textColor)
        @Assert(a.declaredStyle.cornerRadii.isSome(), b.declaredStyle.cornerRadii.isSome())
        @Assert(a.declaredStyle.shadow.isSome(), b.declaredStyle.shadow.isSome())
        @Assert(a.declaredStyle.gradient.isSome(), b.declaredStyle.gradient.isSome())
        @Assert(a.declaredStyle.effectGroup.isSome(), b.declaredStyle.effectGroup.isSome())
        @Assert(a.declaredStyle.effectRejection.isSome(), b.declaredStyle.effectRejection.isSome())
        @Assert(a.declaredStyle.iconTint.isSome(), b.declaredStyle.iconTint.isSome())
        assertWrappedCanonicalPaint(a.interactionStyle.normal, b.interactionStyle.normal)
        assertWrappedCanonicalPaint(a.interactionStyle.hover, b.interactionStyle.hover)
        assertWrappedCanonicalPaint(a.interactionStyle.pressed, b.interactionStyle.pressed)
        assertWrappedCanonicalPaint(a.interactionStyle.focused, b.interactionStyle.focused)
        assertWrappedCanonicalPaint(a.interactionStyle.disabled, b.interactionStyle.disabled)
        assertWrappedCanonicalPaint(a.interactionStyle.selected, b.interactionStyle.selected)
        assertWrappedCanonicalPaint(a.interactionStyle.checked, b.interactionStyle.checked)
    }
}

private func assertWrappedCanonicalPaint(a: CjguiComposableUiPaintStyle, b: CjguiComposableUiPaintStyle): Unit {
    @Assert(a.background.isSome(), b.background.isSome())
    if (let Some(color) <- a.background) { assertWrappedCanonicalColor(color, b.background.getOrThrow()) }
    @Assert(a.border.isSome(), b.border.isSome())
    if (let Some(color) <- a.border) { assertWrappedCanonicalColor(color, b.border.getOrThrow()) }
    @Assert(a.textColor.isSome(), b.textColor.isSome())
    if (let Some(color) <- a.textColor) { assertWrappedCanonicalColor(color, b.textColor.getOrThrow()) }
    @Assert(a.borderWidth, b.borderWidth)
}

private func directClipOwnerTree(parentSemantic: String): CjguiComposableUiNode {
    let parent = cjguiComposableVertical(8600, parentSemantic,
        CjguiComposableUiStyle(clipsContent: true, fixedWidth: 200, fixedHeight: 100))
    let region = cjguiComposableVertical(8601, "direct-region", CjguiComposableUiStyle(fixedHeight: 40),
        layoutReuseKey: "direct-clip-region-v1")
    region.add(cjguiComposableText(8602, "direct-text", "保留", CjguiComposableUiStyle(fixedHeight: 20),
        resourceId: 17, fieldId: "body", displayValueRole: "applied"))
    parent.add(region)
    return parent
}

@Test
func directKeyedRegionDoesNotReuseOldClipOwner(): Unit {
    let cache = CjguiComposableUiLayoutReuseCache()
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(directClipOwnerTree("clip-parent-A"), bounds, 1,
        measurer, reuseCache: cache)
    @Assert(first.scene.isValid(), true)
    let changed = CjguiComposableUiLayoutEngine.layoutWithMetrics(directClipOwnerTree("clip-parent-B"), bounds, 2,
        measurer, reuseCache: cache)
    let canonical = CjguiComposableUiLayoutEngine.layoutWithMetrics(directClipOwnerTree("clip-parent-B"), bounds, 2,
        measurer)
    println("DIRECT_CLIP_OLD changed_valid=${changed.scene.isValid()} error=${changed.scene.layoutError()} " +
        "canonical_valid=${canonical.scene.isValid()} hits=${changed.metrics.subtreeReuseHitCount}")
    @Assert(canonical.scene.isValid(), true)
    @Assert(changed.scene.isValid(), true)
    let got = changed.scene.nodeForId(8602).clipConstraints()
    let expected = canonical.scene.nodeForId(8602).clipConstraints()
    @Assert(got.size, expected.size)
    @Assert(got.size >= 2, true)
    @Assert(expected[expected.size - 1].ownerIdentity, "semantic:clip-parent-B")
    @Assert(got[got.size - 1].ownerIdentity, expected[expected.size - 1].ownerIdentity)
    @Assert(changed.metrics.subtreeReuseHitCount, 0)
    assertWrappedCanonicalScene(changed.scene, canonical.scene)
}

private func contentAlignmentRegionRoot(contentAlignX: Int64, contentAlignY: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(7310, "b-content-root", CjguiComposableUiStyle(gap: 0))
    let region = cjguiComposableVertical(7311, "b-content-region", CjguiComposableUiStyle())
    region.add(cjguiComposableButton(7312, "b-content-button", "深色", "NOOP_ACTION", 0,
        CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 32, contentAlignX: contentAlignX,
            contentAlignY: contentAlignY)))
    root.add(region)
    return root
}

/// 按钮内容对齐是真实声明：同一 cache 下只改 contentAlignX/Y，重放必须失效，
/// 交回的布局节点必须带本次对齐，而不是上一笔的起始对齐。
@Test
func keyedRegionReplayNeverServesStaleButtonContentAlignment(): Unit {
    // Structural signatures walk every declaration; a keyed region would trust
    // the caller's key and intentionally not look at descendant styles.
    let cache = CjguiComposableUiLayoutReuseCache(allowStructuralSignatures: true)
    let measurer = CjguiComposableUiFallbackTextMeasurer()
    let viewport = CjguiComposableUiRect(0, 0, 200, 100)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(contentAlignmentRegionRoot(
        CJGUI_COMPOSABLE_UI_ALIGN_START, CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 1, measurer, reuseCache: cache)
    @Assert(first.scene.isValid(), true)
    @Assert(first.scene.nodeForId(7312).style.contentAlignX, CJGUI_COMPOSABLE_UI_ALIGN_START)
    // Control: an unchanged declaration DOES replay, so the changed case below
    // really exercises the replay path.
    let repeated = CjguiComposableUiLayoutEngine.layoutWithMetrics(contentAlignmentRegionRoot(
        CJGUI_COMPOSABLE_UI_ALIGN_START, CJGUI_COMPOSABLE_UI_ALIGN_START), viewport, 2, measurer, reuseCache: cache)
    @Assert(repeated.scene.isValid(), true)
    @Assert(repeated.metrics.subtreeReuseReplayedNodeCount > 0, true)
    // Alignment-only change: a replayed region would keep start alignment.
    let centered = CjguiComposableUiLayoutEngine.layoutWithMetrics(contentAlignmentRegionRoot(
        CJGUI_COMPOSABLE_UI_ALIGN_CENTER, CJGUI_COMPOSABLE_UI_ALIGN_CENTER), viewport, 3, measurer, reuseCache: cache)
    @Assert(centered.scene.isValid(), true)
    @Assert(centered.metrics.subtreeReuseReplayedNodeCount, 0)
    @Assert(centered.scene.nodeForId(7312).style.contentAlignX, CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    @Assert(centered.scene.nodeForId(7312).style.contentAlignY, CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
}
