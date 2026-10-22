package cjgui

import std.collection.*

private func contextCommandTestNode(root: CjguiComposableUiNode, semanticId: String): ?CjguiComposableUiNode {
    if (root.semanticId == semanticId) {
        return Some(root)
    }
    for (child in root.children()) {
        if (let Some(found) <- contextCommandTestNode(child, semanticId)) {
            return Some(found)
        }
    }
    return None
}

private func contextCommandTestRequest(requestId: Int64, nodeId: Int64,
    resourceId: Int64): CjguiComposableUiContextMenuRequest {
    let declaration = cjguiComposableButton(nodeId, "context-target-${requestId}", "目标",
        "NOOP", resourceId, CjguiComposableUiStyle(fixedHeight: 30))
    let layout = CjguiComposableUiLayoutNode(declaration, CjguiComposableUiRect(12, 24, 160, 30),
        CjguiComposableUiRect(0, 0, 900, 700), inputScopeId: "")
    return CjguiComposableUiContextMenuRequest(requestId, layout, 3, 20, 30, 0u64, None,
        -1, -1, -1, 0, 0, -1, -1)
}

private func contextCommandTestCommands(scope: CjguiComposableUiIdentityScope,
    suffix: String): ArrayList<CjguiComposableUiCommand> {
    return ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.context.${suffix}.toggle",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "切换${suffix}",
            CjguiComposableUiShortcut("t"), "Scope", 0, true, true),
        CjguiComposableUiCommand("settings.context.${suffix}.reset",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "重置${suffix}",
            "Scope", 1, false, false),
        CjguiComposableUiCommand("settings.context.${suffix}.search",
            CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索${suffix}",
            "Scope", 2, true, false)
    ])
}

private func contextCommandTestMetadata(suffix: String): ArrayList<CjguiCommandToolbarMetadata> {
    return ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.context.${suffix}.toggle", "TOGGLE_${suffix}", 9303),
        CjguiCommandToolbarMetadata("settings.context.${suffix}.reset", "RESET_${suffix}", 9303,
            disabledReason: "该作用域命令当前被外部命令集禁用"),
        CjguiCommandToolbarMetadata("settings.context.${suffix}.search", "SEARCH_${suffix}", 9303)
    ])
}

@Test
func contextCommandProjectionReusesToolbarStateAndExcludesSearch(): Unit {
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.context.apply",
            CjguiComposableUiNodeReference.manual(301), "应用设置",
            CjguiComposableUiShortcut("a"), "Settings", 0, true, true),
        CjguiComposableUiCommand("settings.context.reset",
            CjguiComposableUiNodeReference.manual(302), "恢复已应用值",
            "Settings", 1, false, false),
        CjguiComposableUiCommand("settings.context.search",
            CjguiComposableUiNodeReference.manual(305), "搜索命令",
            CjguiComposableUiShortcut("k"), "View", 0, true, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.context.apply", "APPLY", 9300),
        CjguiCommandToolbarMetadata("settings.context.reset", "RESET", 9300,
            disabledReason: "草稿仍有字段错误"),
        CjguiCommandToolbarMetadata("settings.context.search", "SEARCH_COMMANDS", 9300)
    ])
    let request = contextCommandTestRequest(41, 701, 9300)
    let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
        searchCommandId: "settings.context.search")

    @Assert(projection.requestId, 41)
    @Assert(projection.items.size, 2)
    let apply = projection.items[0]
    @Assert(apply.commandId, "settings.context.apply")
    @Assert(apply.checked, true)
    @Assert(apply.enabled, true)
    @Assert(apply.shortcut, "⌘a")
    @Assert(cjguiCommandItemLabel(apply), "✓ 应用设置  ⌘a")
    let reset = projection.items[1]
    @Assert(reset.enabled, false)
    @Assert(reset.disabledReason, "草稿仍有字段错误")

    // The declaration preserves the command's own target. A request for node
    // 701 can never turn a command bound to 301 into a successful declaration;
    // the window resolves this reference in the accepted scene and rejects the
    // mismatch instead of the projection rewriting it to request.nodeId.
    let declaration = projection.declarationFor("settings.context.apply").getOrThrow()
    @Assert(declaration.manualTargetNodeId(), 301)
    @Assert(declaration.isChecked, true)
    @Assert(declaration.isEnabled, true)
    @Assert(projection.declarationFor("settings.context.reset").isNone(), true)
    @Assert(projection.declarationFor("settings.context.search").isNone(), true)
}

@Test
func contextCommandProjectionKeepsMismatchedScopeTarget(): Unit {
    let scopeA = CjguiComposableUiIdentityScope("settings-request-a")
    let scopeB = CjguiComposableUiIdentityScope("settings-request-b")
    let requestA = contextCommandTestRequest(42, 701, 9303)
    // A request targeting instance A receives instance B's command collection.
    // The projection must keep B's target so accepted resolution rejects it.
    let projection = cjguiContextCommandMenuProjection(requestA,
        contextCommandTestCommands(scopeB, "b"), contextCommandTestMetadata("b"),
        searchCommandId: "settings.context.b.search")
    let declaration = projection.declarationFor("settings.context.b.toggle").getOrThrow()
    @Assert(declaration.manualTargetNodeId(), -1)
    let identity = declaration.targetReference.scopedIdentity().getOrThrow()
    @Assert(identity.canonicalKey(), scopeB.local("control").canonicalKey())
    @Assert(identity.canonicalKey() != scopeA.local("control").canonicalKey(), true)
    @Assert(projection.declarationFor("settings.context.a.toggle").isNone(), true)
}

@Test
func contextCommandActivationCarriesRequestAndExactCommandId(): Unit {
    let action = cjguiContextCommandActivationAction(7, "settings.context:a.toggle")
    @Assert(action, "CJGUICONTEXTCOMMAND:7:settings.context:a.toggle")
    let invocation = cjguiContextCommandInvocation(action).getOrThrow()
    @Assert(invocation.requestId, 7)
    @Assert(invocation.commandId, "settings.context:a.toggle")
    @Assert(cjguiContextCommandInvocation("TOGGLE_A").isNone(), true)
    @Assert(cjguiContextCommandInvocation("CJGUICONTEXTCOMMAND:").isNone(), true)
    @Assert(cjguiContextCommandInvocation("CJGUICONTEXTCOMMAND:0:x").isNone(), true)
    @Assert(cjguiContextCommandInvocation("CJGUICONTEXTCOMMAND:7:").isNone(), true)
    @Assert(cjguiContextCommandInvocation("CJGUICONTEXTCOMMAND:abc:x").isNone(), true)

    var emptyRejected = false
    try {
        let _ = cjguiContextCommandActivationAction(3, "")
    } catch (error: IllegalArgumentException) {
        emptyRejected = error.message.contains("empty")
    }
    @Assert(emptyRejected, true)
    var controlRejected = false
    try {
        let _ = cjguiContextCommandActivationAction(3, "bad id")
    } catch (error: IllegalArgumentException) {
        controlRejected = error.message.contains("control")
    }
    @Assert(controlRejected, true)
}

@Test
func contextCommandMenuLayerUsesPerInstanceIdentityAndSharedProjection(): Unit {
    let scopeA = CjguiComposableUiIdentityScope("settings-instance-a")
    let scopeB = CjguiComposableUiIdentityScope("settings-instance-b")
    let requestA = contextCommandTestRequest(51, 701, 9303)
    let requestB = contextCommandTestRequest(52, 702, 9307)
    let projectionA = cjguiContextCommandMenuProjection(requestA,
        contextCommandTestCommands(scopeA, "a"), contextCommandTestMetadata("a"),
        searchCommandId: "settings.context.a.search")
    let projectionB = cjguiContextCommandMenuProjection(requestB,
        contextCommandTestCommands(scopeB, "b"), contextCommandTestMetadata("b"),
        searchCommandId: "settings.context.b.search")
    @Assert(projectionA.items.size, 2)
    @Assert(projectionB.items.size, 2)
    @Assert(projectionA.items[0].checked, true)
    @Assert(projectionB.items[0].checked, true)

    let layerA = cjguiComposableContextCommandMenuLayer(scopeA.child("context-menu"), "context-menu-a", requestA,
        projectionA, "settings")
    let layerB = cjguiComposableContextCommandMenuLayer(scopeB.child("context-menu"), "context-menu-b", requestB,
        projectionB, "settings")
    @Assert(layerA.layerId(), "context-menu-51")
    @Assert(layerB.layerId(), "context-menu-52")
    @Assert(layerA.layerAnchorNodeId(), 701)
    @Assert(layerB.layerAnchorNodeId(), 702)
    @Assert(layerA.layerAnchorAtPoint(), true)

    let toolbarPlacementA = cjguiCommandToolbarPlacement(contextCommandTestCommands(scopeA, "a"),
        contextCommandTestMetadata("a"), searchCommandId: "settings.context.a.search")
    let toolbarA = cjguiComposableCommandToolbar(scopeA, "context-toolbar-a", toolbarPlacementA)
    let root = cjguiComposableVertical(700, "context-command-identity-root",
        CjguiComposableUiStyle())
    root.add(toolbarA)
    root.add(layerA)
    root.add(layerB)
    let registry = CjguiComposableUiIdentityRegistry()
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(root), "")
    @Assert(registry.prepareCandidate(), true)

    let menuScopeA = scopeA.child("context-menu")
    let menuScopeB = scopeB.child("context-menu")
    let menuA = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeA, "menu"))
    let menuB = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeB, "menu"))
    @Assert(menuA > 0, true)
    @Assert(menuB > 0, true)
    @Assert(menuA != menuB, true)
    @Assert(layerA.nodeId, menuA)
    @Assert(layerB.nodeId, menuB)

    // The menu rows share a component scope with the toolbar. They must still
    // own identities separate from the toolbar's item-<key> buttons.
    let keyA = cjguiCommandToolbarKey("settings.context.a.toggle")
    let keyB = cjguiCommandToolbarKey("settings.context.b.toggle")
    let toolbarItemA = registry.candidateNodeIdForReference(
        CjguiComposableUiNodeReference.scoped(scopeA, "item-${keyA}"))
    let toolbarItemB = registry.candidateNodeIdForReference(
        CjguiComposableUiNodeReference.scoped(scopeB, "item-${keyB}"))
    let itemA = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeA, "item-${keyA}"))
    let itemB = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeB, "item-${keyB}"))
    @Assert(itemA > 0, true)
    @Assert(itemB > 0, true)
    @Assert(itemA != itemB, true)
    @Assert(itemA != menuA, true)
    @Assert(itemA != toolbarItemA, true)
    @Assert(itemB != toolbarItemB, true)

    let reasonKeyA = cjguiCommandToolbarKey("settings.context.a.reset")
    let reasonKeyB = cjguiCommandToolbarKey("settings.context.b.reset")
    let reasonA = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeA, "reason-${reasonKeyA}"))
    let reasonB = registry.candidateNodeIdForReference(CjguiComposableUiNodeReference.scoped(menuScopeB, "reason-${reasonKeyB}"))
    @Assert(reasonA > 0, true)
    @Assert(reasonB > 0, true)
    @Assert(reasonA != reasonB, true)

    let toggleA = contextCommandTestNode(layerA, "context-menu-a-item-${keyA}").getOrThrow()
    let resetA = contextCommandTestNode(layerA, "context-menu-a-item-${reasonKeyA}").getOrThrow()
    let reasonTextA = contextCommandTestNode(layerA, "context-menu-a-reason-${reasonKeyA}").getOrThrow()
    @Assert(toggleA.isEnabled, true)
    @Assert((toggleA.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, true)
    @Assert(toggleA.label, cjguiCommandItemLabel(projectionA.items[0]))
    @Assert(resetA.isEnabled, false)
    @Assert(reasonTextA.value, "不可用：该作用域命令当前被外部命令集禁用")
    @Assert(reasonTextA.nodeId, reasonA)
    @Assert(toggleA.nodeId, itemA)
}

@Test
func contextCommandMenuLayerRejectsEmptyOrMismatchedProjection(): Unit {
    let scope = CjguiComposableUiIdentityScope("context-menu-boundary")
    let request = contextCommandTestRequest(61, 703, 9303)
    var emptyRejected = false
    try {
        let empty = CjguiContextCommandMenuProjection(61,
            ArrayList<CjguiCommandToolbarItem>(), ArrayList<CjguiComposableUiCommand>())
        let _ = cjguiComposableContextCommandMenuLayer(scope, "context-menu-empty", request,
            empty, "settings")
    } catch (error: IllegalArgumentException) {
        emptyRejected = error.message.contains("does not match")
    }
    @Assert(emptyRejected, true)

    let projection = cjguiContextCommandMenuProjection(request,
        contextCommandTestCommands(scope, "c"), contextCommandTestMetadata("c"),
        searchCommandId: "settings.context.c.search")
    var mismatchRejected = false
    try {
        let other = contextCommandTestRequest(62, 704, 9303)
        let _ = cjguiComposableContextCommandMenuLayer(scope, "context-menu-mismatch", other,
            projection, "settings")
    } catch (error: IllegalArgumentException) {
        mismatchRejected = error.message.contains("does not match")
    }
    @Assert(mismatchRejected, true)
}

@Test
func contextCommandMenuRowsExposeFocusPaintAndSkipDisabledRows(): Unit {
    let scope = CjguiComposableUiIdentityScope("context-menu-keyboard")
    let request = contextCommandTestRequest(71, 705, 9303)
    let commands = contextCommandTestCommands(scope, "k")
    let metadata = contextCommandTestMetadata("k")
    let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
        searchCommandId: "settings.context.k.search")
    @Assert(projection.items.size, 2)
    let style = CjguiContextCommandMenuStyle(focusBackground: CjguiComposableUiColor(0.2, 0.3, 0.45, 1.0),
        focusBorder: CjguiComposableUiColor(0.6, 0.75, 0.95, 1.0))
    let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-k",
        request, projection, "settings", style: style)
    let toggleKey = cjguiCommandToolbarKey("settings.context.k.toggle")
    let resetKey = cjguiCommandToolbarKey("settings.context.k.reset")
    let toggle = contextCommandTestNode(layer, "context-menu-k-item-${toggleKey}").getOrThrow()
    let reset = contextCommandTestNode(layer, "context-menu-k-item-${resetKey}").getOrThrow()
    // The focus paint is an independent interaction channel: checked stays on
    // the owner state and the disabled row is never a keyboard stop.
    @Assert(toggle.isEnabled, true)
    @Assert(reset.isEnabled, false)
    @Assert((toggle.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, true)
    let focusBackground = toggle.interactionStyle.focused.background.getOrThrow()
    @Assert(focusBackground.red, 0.2)
    @Assert(focusBackground.green, 0.3)
    @Assert(focusBackground.blue, 0.45)
    @Assert(focusBackground.alpha, 1.0)
    @Assert(toggle.interactionStyle.focused.border.getOrThrow().blue, 0.95)
    @Assert(contextCommandTestNode(layer, "context-menu-k-close").isNone(), true)
}

@Test
func contextCommandMenuAllDisabledShowsNamedCloseEntry(): Unit {
    let scope = CjguiComposableUiIdentityScope("context-menu-all-disabled")
    let request = contextCommandTestRequest(72, 706, 9303)
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.context.d.toggle",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "切换d",
            CjguiComposableUiShortcut("t"), "Scope", 0, false, true),
        CjguiComposableUiCommand("settings.context.d.reset",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "重置d",
            "Scope", 1, false, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.context.d.toggle", "TOGGLE_D", 9303,
            disabledReason: "外部命令集已禁用"),
        CjguiCommandToolbarMetadata("settings.context.d.reset", "RESET_D", 9303,
            disabledReason: "外部命令集已禁用")
    ])
    let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
    @Assert(projection.declarations.size, 0)
    let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-d",
        request, projection, "settings")
    let close = contextCommandTestNode(layer, "context-menu-d-close").getOrThrow()
    // The previous unnamed 1px routing stop is now a normal, discoverable row.
    // It stays enabled so the layer owns a keyboard stop; activation only ends
    // the presentation layer and never reaches a business command.
    @Assert(close.isEnabled, true)
    @Assert(close.label, "关闭菜单")
    @Assert(close.actionName, cjguiContextCommandMenuCloseAction(72))
    @Assert(cjguiContextCommandMenuCloseRequest(close.actionName).getOrThrow(), 72)
    @Assert(close.interactionStyle.focused.border.isSome(), true)
    let toggleKey = cjguiCommandToolbarKey("settings.context.d.toggle")
    let resetKey = cjguiCommandToolbarKey("settings.context.d.reset")
    @Assert(contextCommandTestNode(layer, "context-menu-d-item-${toggleKey}").getOrThrow().isEnabled, false)
    @Assert(contextCommandTestNode(layer, "context-menu-d-item-${resetKey}").getOrThrow().isEnabled, false)
    // Both disabled command rows use disabledRowHeight: padding*2 + gap +
    // 52 + 52 + gap + close row 34.
    @Assert(layer.style.fixedHeight, 154)
}

@Test
func contextCommandMenuCloseParsingRejectsStaleOrMalformedActions(): Unit {
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTMENUCLOSE:9").getOrThrow(), 9)
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTMENUCLOSE:").isNone(), true)
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTMENUCLOSE:0").isNone(), true)
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTMENUCLOSE:-3").isNone(), true)
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTMENUCLOSE:abc").isNone(), true)
    @Assert(cjguiContextCommandMenuCloseRequest("CJGUICONTEXTCOMMAND:9:x").isNone(), true)
    var zeroRejected = false
    try {
        let _ = cjguiContextCommandMenuCloseAction(0)
    } catch (error: IllegalArgumentException) {
        zeroRejected = true
    }
    @Assert(zeroRejected, true)
}

@Test
func contextCommandMenuConstrainedHeightUsesScrollAreaAndViewport(): Unit {
    let scope = CjguiComposableUiIdentityScope("context-menu-scroll")
    let request = contextCommandTestRequest(73, 707, 9303)
    let projection = cjguiContextCommandMenuProjection(request,
        contextCommandTestCommands(scope, "s"), contextCommandTestMetadata("s"),
        searchCommandId: "settings.context.s.search")
    let viewport = CjguiComposableUiScrollViewport()
    let style = CjguiContextCommandMenuStyle(maxHeight: 60)
    let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-s",
        request, projection, "settings", style: style, scrollViewport: Some(viewport))
    @Assert(layer.style.fixedHeight, 60)
    let scroll = contextCommandTestNode(layer, "context-menu-s-scroll").getOrThrow()
    @Assert(scroll.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    @Assert(scroll.style.fixedHeight, 60)
    @Assert(scroll.scrollViewport.isSome(), true)
    @Assert(scroll.scrollOffset, viewport.offset())
    // All logical rows stay in the declaration; clipping is a scene concern,
    // not a projection that removes the tail items.
    let toggleKey = cjguiCommandToolbarKey("settings.context.s.toggle")
    let resetKey = cjguiCommandToolbarKey("settings.context.s.reset")
    @Assert(contextCommandTestNode(scroll, "context-menu-s-item-${toggleKey}").isSome(), true)
    @Assert(contextCommandTestNode(scroll, "context-menu-s-item-${resetKey}").isSome(), true)
    var missingViewportRejected = false
    try {
        let _ = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-s2",
            request, projection, "settings", style: style)
    } catch (error: IllegalArgumentException) {
        missingViewportRejected = error.message.contains("scroll viewport")
    }
    @Assert(missingViewportRejected, true)
}

@Test
func contextCommandMenuLongLabelsKeepFullSemanticsWithEllipsis(): Unit {
    let scope = CjguiComposableUiIdentityScope("context-menu-long-text")
    let request = contextCommandTestRequest(74, 708, 9303)
    let longLabel = "切换代理实例并同步所有远程策略与本地缓存中的完整设置项"
    let longReason = "当前草稿仍有未提交的字段修改，并且在窄窗口中无法恢复默认值"
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.context.l.toggle",
            CjguiComposableUiNodeReference.scoped(scope, "control"), longLabel, "", 0, true, false),
        CjguiComposableUiCommand("settings.context.l.reset",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "恢复默认", "", 1, false, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.context.l.toggle", "TOGGLE_L", 9303),
        CjguiCommandToolbarMetadata("settings.context.l.reset", "RESET_L", 9303,
            disabledReason: longReason)
    ])
    let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
    let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-l",
        request, projection, "settings", style: CjguiContextCommandMenuStyle(width: 150))
    let toggleKey = cjguiCommandToolbarKey("settings.context.l.toggle")
    let resetKey = cjguiCommandToolbarKey("settings.context.l.reset")
    let item = contextCommandTestNode(layer, "context-menu-l-item-${toggleKey}").getOrThrow()
    let reason = contextCommandTestNode(layer, "context-menu-l-reason-${resetKey}").getOrThrow()
    // Painting may ellipsize, but the node keeps the authored full semantics.
    @Assert(item.label, longLabel)
    @Assert(item.style.textOverflow, "ellipsis")
    @Assert(item.style.textMaxLines, 1)
    @Assert(reason.value, "不可用：${longReason}")
    @Assert(reason.style.textOverflow, "ellipsis")
    @Assert(reason.style.textMaxLines, 1)
}

private func contextCommandTestColorEquals(left: CjguiComposableUiColor,
    right: CjguiComposableUiColor): Bool {
    return left.red == right.red && left.green == right.green && left.blue == right.blue &&
        left.alpha == right.alpha
}

@Test
func contextCommandMenuThemeDerivesPaintAndKeepsExplicitOverrides(): Unit {
    let darkTheme = CjguiComposableUiTheme.beaconDark()
    let dark = CjguiContextCommandMenuStyle.themed(darkTheme, maxHeight: 90)
    let darkDisabled = match (darkTheme.bodyInteraction.disabled.textColor) {
        case Some(value) => value
        case None => darkTheme.body.textColor
    }
    let darkChecked = match (darkTheme.inputInteraction.checked.border) {
        case Some(value) => value
        case None => darkTheme.primaryAction.border
    }
    @Assert(contextCommandTestColorEquals(dark.background, darkTheme.card.background), true)
    @Assert(contextCommandTestColorEquals(dark.textColor, darkTheme.heading.textColor), true)
    @Assert(contextCommandTestColorEquals(dark.disabledTextColor, darkDisabled), true)
    @Assert(contextCommandTestColorEquals(dark.checkedBorder, darkChecked), true)
    @Assert(dark.maxHeight, 90)
    let lightTheme = CjguiComposableUiTheme.paperLight()
    let light = CjguiContextCommandMenuStyle.themed(lightTheme)
    let lightDisabled = match (lightTheme.bodyInteraction.disabled.textColor) {
        case Some(value) => value
        case None => lightTheme.body.textColor
    }
    let lightFocus = match (lightTheme.inputInteraction.focused.border) {
        case Some(value) => value
        case None => lightTheme.primaryAction.border
    }
    @Assert(contextCommandTestColorEquals(light.background, lightTheme.card.background), true)
    @Assert(contextCommandTestColorEquals(light.reasonColor, lightDisabled), true)
    @Assert(contextCommandTestColorEquals(light.focusBorder, lightFocus), true)
    // An explicit style still wins over the theme factory.
    let explicitColor = CjguiComposableUiColor(1.0, 0.0, 1.0, 1.0)
    let explicit = CjguiContextCommandMenuStyle(background: explicitColor)
    @Assert(contextCommandTestColorEquals(explicit.background, explicitColor), true)
    // The layer carries checked and disabled paint into the existing
    // interaction channel rather than inventing a second row state.
    let scope = CjguiComposableUiIdentityScope("context-menu-theme")
    let request = contextCommandTestRequest(75, 709, 9303)
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.context.t.toggle",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "切换", "", 0, true, true),
        CjguiComposableUiCommand("settings.context.t.reset",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "恢复默认", "", 1, false, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.context.t.toggle", "TOGGLE_T", 9303),
        CjguiCommandToolbarMetadata("settings.context.t.reset", "RESET_T", 9303, disabledReason: "不可用原因")
    ])
    let projection = cjguiContextCommandMenuProjection(request, commands, metadata)
    let layer = cjguiComposableContextCommandMenuLayer(scope.child("context-menu"), "context-menu-t",
        request, projection, "settings", style: light)
    let toggleKey = cjguiCommandToolbarKey("settings.context.t.toggle")
    let resetKey = cjguiCommandToolbarKey("settings.context.t.reset")
    let toggle = contextCommandTestNode(layer, "context-menu-t-item-${toggleKey}").getOrThrow()
    let reset = contextCommandTestNode(layer, "context-menu-t-item-${resetKey}").getOrThrow()
    @Assert(contextCommandTestColorEquals(toggle.interactionStyle.checked.border.getOrThrow(),
        light.checkedBorder), true)
    @Assert(contextCommandTestColorEquals(reset.interactionStyle.disabled.textColor.getOrThrow(),
        light.disabledTextColor), true)
    @Assert((toggle.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, true)
}

@Test
func commandToolbarThemeFeedsInteractionWithoutOwningState(): Unit {
    let darkTheme = CjguiComposableUiTheme.beaconDark()
    let style = CjguiCommandToolbarStyle.themed(darkTheme, rowHeight: 30)
    @Assert(style.item.fixedHeight, 30)
    @Assert(contextCommandTestColorEquals(style.item.background, darkTheme.card.background), true)
    @Assert(contextCommandTestColorEquals(style.search.background, darkTheme.input.background), true)
    // The input role paints a disabled background, not a disabled ink; the
    // toolbar keeps that absence instead of inventing a second color.
    @Assert(style.itemInteraction.disabled.textColor.isNone(),
        darkTheme.inputInteraction.disabled.textColor.isNone())
    @Assert(contextCommandTestColorEquals(style.itemInteraction.checked.border.getOrThrow(),
        darkTheme.inputInteraction.checked.border.getOrThrow()), true)
    // The interaction style carries no NORMAL paint, so the base heading text
    // stays readable instead of being replaced by the input's dark ink.
    @Assert(style.itemInteraction.normal.textColor.isNone(), true)
    let scope = CjguiComposableUiIdentityScope("toolbar-theme")
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.tool.theme.on",
            CjguiComposableUiNodeReference.scoped(scope, "control"), "主题命令", "", 0, true, true)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.tool.theme.on", "TOGGLE_THEME", 0)
    ])
    let placement = cjguiCommandToolbarPlacement(commands, metadata)
    let toolbar = cjguiComposableCommandToolbar(scope, "settings-tool-theme", placement,
        style: style, searchLabel: "搜索", searchActionName: "SEARCH", searchResourceId: 0)
    let key = cjguiCommandToolbarKey("settings.tool.theme.on")
    let item = contextCommandTestNode(toolbar, "settings-tool-theme-${key}").getOrThrow()
    @Assert(contextCommandTestColorEquals(item.interactionStyle.checked.border.getOrThrow(),
        darkTheme.inputInteraction.checked.border.getOrThrow()), true)
    @Assert((item.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, true)
}
