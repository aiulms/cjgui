package cjgui

import std.collection.*

private let scopeCommandStyle = CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 30)

private func scopedToolbarCommands(scope: CjguiComposableUiIdentityScope, suffix: String,
    checked: Bool, reordered!: Bool = false): ArrayList<CjguiComposableUiCommand> {
    let toggle = CjguiComposableUiCommand("scope.${suffix}.toggle",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "切换 ${suffix}", "Scope", 0, true, checked)
    let reset = CjguiComposableUiCommand("scope.${suffix}.reset",
        CjguiComposableUiNodeReference.scoped(scope, "reset"), "重置 ${suffix}", "Scope", 1, false, false)
    let search = CjguiComposableUiCommand("scope.${suffix}.search",
        CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索 ${suffix}", "Scope", 2, true, false)
    let commands = ArrayList<CjguiComposableUiCommand>()
    if (reordered) {
        commands.add(reset)
        commands.add(toggle)
    } else {
        commands.add(toggle)
        commands.add(reset)
    }
    commands.add(search)
    return commands
}

private func scopedToolbarMetadata(suffix: String): ArrayList<CjguiCommandToolbarMetadata> {
    return ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("scope.${suffix}.toggle", "TOGGLE_${suffix}", 9300, detail: "切换 ${suffix}"),
        CjguiCommandToolbarMetadata("scope.${suffix}.reset", "RESET_${suffix}", 9300, detail: "重置 ${suffix}"),
        CjguiCommandToolbarMetadata("scope.${suffix}.search", "SEARCH_${suffix}", 9300, detail: "搜索 ${suffix}")
    ])
}

private func scopedToolbarInstance(scope: CjguiComposableUiIdentityScope, suffix: String,
    checked: Bool, reordered!: Bool = false): CjguiComposableUiNode {
    let card = cjguiComposableVertical(-1, "scope-card-${suffix}",
        CjguiComposableUiStyle(gap: 4), identity: Some(scope.local("card")))
    card.add(cjguiComposableButton(-1, "scope-control-${suffix}", "control ${suffix}", "TOGGLE_${suffix}",
        9300, scopeCommandStyle, identity: Some(scope.local("control"))))
    card.add(cjguiComposableButton(-1, "scope-reset-${suffix}", "reset ${suffix}", "RESET_${suffix}",
        9300, scopeCommandStyle, identity: Some(scope.local("reset"))))
    let placement = cjguiCommandToolbarPlacement(scopedToolbarCommands(scope, suffix, checked, reordered: reordered),
        scopedToolbarMetadata(suffix), searchCommandId: "scope.${suffix}.search")
    card.add(cjguiComposableCommandToolbar(scope, "scope-actions-${suffix}", placement,
        searchLabel: "搜索 ${suffix}", searchActionName: "SEARCH_${suffix}", searchResourceId: 9300))
    return card
}

private func scopedNodeBySemantic(root: CjguiComposableUiNode, semanticId: String): ?CjguiComposableUiNode {
    if (root.semanticId == semanticId) {
        return Some(root)
    }
    for (child in root.children()) {
        if (let Some(found) <- scopedNodeBySemantic(child, semanticId)) {
            return Some(found)
        }
    }
    return None
}

@Test
func commandToolbarPlacementAcceptsScopedTargetsAndActivationBridge(): Unit {
    let scope = CjguiComposableUiIdentityScope("placement-scope")
    let commands = scopedToolbarCommands(scope, "a", true)
    let placement = cjguiCommandToolbarPlacement(commands, scopedToolbarMetadata("a"),
        searchCommandId: "scope.a.search")
    @Assert(placement.items.size, 2)
    @Assert(placement.searchNodeBase, -1)
    @Assert(placement.searchCommandId, "scope.a.search")
    @Assert(placement.items[0].nodeBase, -1)
    @Assert(placement.items[0].targetReference.scopedIdentity().isSome(), true)
    @Assert(placement.items[1].targetReference.scopedIdentity().isSome(), true)
    let action = cjguiCommandToolbarActivationAction(placement.items[0].commandId)
    @Assert(action.startsWith(CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX), true)
    @Assert(cjguiCommandToolbarCommandId(action).getOrThrow(), "scope.a.toggle")
    @Assert(cjguiCommandToolbarCommandId("TOGGLE_A").isNone(), true)

    // Manual placements remain valid and keep the numeric target.
    let manualCommand = CjguiComposableUiCommand("scope.manual", 310, CjguiComposableUiShortcut("m"))
    let manualPlacement = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([manualCommand]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.manual", "TOGGLE_MANUAL", 9300, detail: "manual")
        ]))
    @Assert(manualPlacement.items.size, 1)
    @Assert(manualPlacement.items[0].nodeBase, 310)
    @Assert(manualPlacement.items[0].targetReference.manualNodeId(), 310)
    let manualBar = cjguiComposableCommandToolbar(300, "manual-bar", manualPlacement)
    @Assert(manualBar.children()[0].actionName, "TOGGLE_MANUAL")
    var manualRejected = false
    try {
        let manual = cjguiCommandToolbarPlacement(commands, scopedToolbarMetadata("a"),
            searchCommandId: "scope.a.search")
        let _ = cjguiComposableCommandToolbar(300, "manual-scope", manual)
    } catch (error: IllegalArgumentException) {
        manualRejected = error.message.contains("scoped toolbar composer")
    }
    @Assert(manualRejected, true)
}

@Test
func scopedToolbarMountsTwoInstancesAndReorderKeepsTargetIdentity(): Unit {
    let scopeA = CjguiComposableUiIdentityScope("scope-instance-a")
    let scopeB = CjguiComposableUiIdentityScope("scope-instance-b")
    let registry = CjguiComposableUiIdentityRegistry()
    let root = cjguiComposableVertical(100, "scope-root", CjguiComposableUiStyle())
    root.add(scopedToolbarInstance(scopeA, "a", true))
    root.add(scopedToolbarInstance(scopeB, "b", false))
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(root), "")
    @Assert(registry.prepareCandidate(), true)
    let controlA = scopedNodeBySemantic(root, "scope-control-a").getOrThrow().nodeId
    let controlB = scopedNodeBySemantic(root, "scope-control-b").getOrThrow().nodeId
    @Assert(controlA > 0, true)
    @Assert(controlB > 0, true)
    @Assert(controlA != controlB, true)
    @Assert(registry.candidateNodeIdForReference(
        CjguiComposableUiNodeReference.scoped(scopeA, "control")), controlA)
    @Assert(registry.candidateNodeIdForReference(
        CjguiComposableUiNodeReference.scoped(scopeB, "control")), controlB)
    // The two mounts use the same local keys but independent identities.
    @Assert(scopedNodeBySemantic(root, "scope-actions-a").isSome(), true)
    @Assert(scopedNodeBySemantic(root, "scope-actions-b").isSome(), true)

    // Reordering the declaration list must not move a command to a sibling
    // target: each reference resolves through its own scope and local key.
    let reorderedRoot = cjguiComposableVertical(100, "scope-root-reordered", CjguiComposableUiStyle())
    reorderedRoot.add(scopedToolbarInstance(scopeA, "a", true, reordered: true))
    let reorderedRegistry = CjguiComposableUiIdentityRegistry()
    @Assert(reorderedRegistry.beginCandidate(), true)
    @Assert(reorderedRegistry.resolveCandidate(reorderedRoot), "")
    @Assert(reorderedRegistry.prepareCandidate(), true)
    let reorderedControlA = scopedNodeBySemantic(reorderedRoot, "scope-control-a").getOrThrow().nodeId
    @Assert(reorderedRegistry.candidateNodeIdForReference(
        CjguiComposableUiNodeReference.scoped(scopeA, "control")), reorderedControlA)
    let resetCommand = scopedToolbarCommands(scopeA, "a", true, reordered: true)[0]
    @Assert(resetCommand.id, "scope.a.reset")
    @Assert(reorderedRegistry.candidateNodeIdForReference(resetCommand.targetReference),
        scopedNodeBySemantic(reorderedRoot, "scope-reset-a").getOrThrow().nodeId)
}

@Test
func searchCommandStateReachesPlacementAndButtonWithoutSelfActivation(): Unit {
    let scope = CjguiComposableUiIdentityScope("search-state-scope")
    let toggle = CjguiComposableUiCommand("scope.search-state.toggle",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "切换", "Scope", 0, true, false)
    let disabledSearch = CjguiComposableUiCommand("scope.search-state.search",
        CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索", "Scope", 1, false, false)
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("scope.search-state.toggle", "TOGGLE_STATE", 9300),
        CjguiCommandToolbarMetadata("scope.search-state.search", "SEARCH_STATE", 9300,
            disabledReason: "搜索入口由声明关闭")
    ])
    let placement = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([toggle, disabledSearch]), metadata,
        searchCommandId: "scope.search-state.search")
    @Assert(placement.items.size, 1)
    @Assert(placement.searchCommandId, "scope.search-state.search")
    let search = placement.searchItem.getOrThrow()
    @Assert(search.enabled, false)
    @Assert(search.disabledReason, "搜索入口由声明关闭")
    let bar = cjguiComposableCommandToolbar(scope, "search-state-bar", placement,
        searchLabel: "搜索", searchActionName: "SEARCH_STATE", searchResourceId: 9300)
    let button = scopedNodeBySemantic(bar, "search-state-bar-search").getOrThrow()
    @Assert(button.isEnabled, false)
    @Assert(button.actionName, "SEARCH_STATE")
    @Assert(cjguiCommandToolbarCommandId(button.actionName).isNone(), true)

    // The same declaration, enabled, reaches the same button.
    let enabledSearch = CjguiComposableUiCommand("scope.search-state.search",
        CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索", "Scope", 1, true, false)
    let enabledPlacement = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([toggle, enabledSearch]), metadata,
        searchCommandId: "scope.search-state.search")
    let enabledBar = cjguiComposableCommandToolbar(scope, "search-state-enabled", enabledPlacement,
        searchLabel: "搜索", searchActionName: "SEARCH_STATE", searchResourceId: 9300)
    @Assert(scopedNodeBySemantic(enabledBar, "search-state-enabled-search").getOrThrow().isEnabled, true)

    // Removing the declaration removes the search button rather than leaving a
    // default-enabled entry behind.
    let removed = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([toggle]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.search-state.toggle", "TOGGLE_STATE", 9300)
        ]), searchCommandId: "scope.search-state.search")
    @Assert(removed.searchCommandId, "")
    @Assert(removed.searchItem.isNone(), true)
    let removedBar = cjguiComposableCommandToolbar(scope, "search-state-removed", removed,
        searchLabel: "搜索", searchActionName: "SEARCH_STATE", searchResourceId: 9300)
    @Assert(removedBar.children().size, 1)

    // A search action routed back through the activation bridge would make
    // invokeCommand re-enter the same button; reject the declaration instead.
    var rejected = false
    try {
        let badMetadata = ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.search-state.toggle", "TOGGLE_STATE", 9300),
            CjguiCommandToolbarMetadata("scope.search-state.search",
                cjguiCommandToolbarActivationAction("scope.search-state.search"), 9300)
        ])
        let _ = cjguiCommandToolbarPlacement(
            ArrayList<CjguiComposableUiCommand>([toggle, disabledSearch]), badMetadata,
            searchCommandId: "scope.search-state.search")
    } catch (error: IllegalArgumentException) {
        rejected = error.message.contains("owner action")
    }
    @Assert(rejected, true)

    // The legacy numeric path keeps its manual slot and now carries the same
    // search declaration state instead of forcing an enabled button.
    let manualDisabledSearch = CjguiComposableUiCommand("scope.manual.search",
        CjguiComposableUiNodeReference.manual(305), "搜索", "Scope", 1, false, false)
    let manualPlacement = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([manualDisabledSearch]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.manual.search", "SEARCH_MANUAL", 9300)
        ]), searchCommandId: "scope.manual.search")
    @Assert(manualPlacement.searchNodeBase, 305)
    @Assert(manualPlacement.searchItem.getOrThrow().enabled, false)
    let manualBar = cjguiComposableCommandToolbar(300, "manual-search-bar", manualPlacement)
    let manualButton = scopedNodeBySemantic(manualBar, "manual-search-bar-search").getOrThrow()
    @Assert(manualButton.isEnabled, false)
    @Assert(manualButton.actionName, "SEARCH_MANUAL")
}

@Test
func emptyCommandCollectionProjectsAndPaletteKeepsQueryAndHighlight(): Unit {
    let empty = cjguiCommandToolbarPlacement(ArrayList<CjguiComposableUiCommand>(),
        ArrayList<CjguiCommandToolbarMetadata>())
    @Assert(empty.items.size, 0)
    @Assert(empty.searchCommandId, "")
    let manualEmpty = cjguiComposableCommandToolbar(390, "empty-manual-bar", empty)
    @Assert(manualEmpty.children().size, 0)
    let scope = CjguiComposableUiIdentityScope("dynamic-collection-scope")
    let scopedEmpty = cjguiComposableCommandToolbar(scope, "empty-scoped-bar", empty)
    @Assert(scopedEmpty.children().size, 0)

    let commands = scopedToolbarCommands(scope, "a", false)
    let placement = cjguiCommandToolbarPlacement(commands, scopedToolbarMetadata("a"),
        searchCommandId: "scope.a.search")
    let target = CjguiComposableUiNodeReference.scoped(scope, "control")
    let panel = CjguiSearchableSelectionPanel("dynamic-panel")
    panel.open("命令", cjguiCommandPaletteItems(placement), target)
    // The search command is the toolbar button, not a palette row.
    @Assert(panel.resultCount(), 2)
    panel.setQuery("a")
    panel.moveHighlight("down")
    let kept = panel.highlightedKey()
    @Assert(kept, "scope-a-reset")
    let before = panel.revision()
    panel.updateItems(cjguiCommandPaletteItems(placement))
    @Assert(panel.revision(), before)

    // Reordering the collection keeps the query and the still-valid highlight.
    let reordered = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([commands[1], commands[0]]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.a.toggle", "TOGGLE_A", 9300),
            CjguiCommandToolbarMetadata("scope.a.reset", "RESET_A", 9300)
        ]), searchCommandId: "scope.a.search")
    panel.updateItems(cjguiCommandPaletteItems(reordered))
    @Assert(panel.revision() > before, true)
    @Assert(panel.query(), "a")
    @Assert(panel.highlightedKey(), kept)
    @Assert(panel.resultCount(), 2)

    // Removing the highlighted row falls back to a remaining result while the
    // query stays untouched.
    let trimmed = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([commands[0]]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.a.toggle", "TOGGLE_A", 9300)
        ]), searchCommandId: "scope.a.search")
    @Assert(trimmed.searchCommandId, "")
    panel.updateItems(cjguiCommandPaletteItems(trimmed))
    @Assert(panel.query(), "a")
    @Assert(panel.resultCount(), 1)
    @Assert(panel.highlightedKey(), "scope-a-toggle")

    // An empty collection keeps the panel open, refuses confirmation and stays
    // cancellable; the query is retained until the panel is reopened.
    panel.updateItems(ArrayList<CjguiSearchableSelectionItem>())
    @Assert(panel.resultCount(), 0)
    @Assert(panel.isOpen(), true)
    @Assert(panel.requestConfirm(), false)
    panel.cancel()
    @Assert(panel.isOpen(), false)

    panel.open("命令", cjguiCommandPaletteItems(placement), target)
    panel.setQuery("a")
    @Assert(panel.resultCount(), 2)
    panel.updateItems(cjguiCommandPaletteItems(trimmed))
    @Assert(panel.resultCount(), 1)
    @Assert(panel.query(), "a")
    panel.cancel()

    let emptyPanel = CjguiSearchableSelectionPanel("empty-only-panel")
    emptyPanel.open("空命令", ArrayList<CjguiSearchableSelectionItem>(), target)
    @Assert(emptyPanel.resultCount(), 0)
    @Assert(emptyPanel.requestConfirm(), false)
    emptyPanel.cancel()
    @Assert(emptyPanel.isOpen(), false)
}

@Test
func disabledScopedCommandStaysDeclaredButInertInToolbarAndPalette(): Unit {
    let scope = CjguiComposableUiIdentityScope("disabled-scope")
    let enabled = CjguiComposableUiCommand("scope.enabled",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "启用", "Scope", 0, true, false)
    let disabled = CjguiComposableUiCommand("scope.disabled",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "禁用", "Scope", 1, false, false)
    let placement = cjguiCommandToolbarPlacement(
        ArrayList<CjguiComposableUiCommand>([enabled, disabled]),
        ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("scope.enabled", "TOGGLE_ENABLED", 9300),
            CjguiCommandToolbarMetadata("scope.disabled", "TOGGLE_DISABLED", 9300)
        ]))
    @Assert(placement.items.size, 2)
    @Assert(placement.items[0].enabled, true)
    @Assert(placement.items[1].enabled, false)
    // A disabled declaration is still projected so its state is visible; the
    // invocation gate, not the projection, is what refuses execution.
    let palette = cjguiCommandPaletteItems(placement)
    @Assert(palette.size, 2)
    @Assert(palette[0].isEnabled, true)
    @Assert(palette[1].isEnabled, false)
}
