// D acceptance: this UI-only consumer really CONSUMES the shared definitions —
// one named style, one declared image resource (logical key/version) and the
// window's interaction context — instead of copying colors/paths locally. It runs
// with no server, no descriptor and no Agent, and adding another field or
// condition needs no second (AI-only) definition.
package cjgui_ui_only_starter

import std.collection.*
import std.math.*
import cjgui.*

@Test
func uiOnlyConsumerConsumesSharedStyleImageAndInteractionContext(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2))

    // ONE named style, resolved through the shared catalogue.
    let style = match (controller.namedStyles().forName("catalog_surface")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    @Assert(style.name, "catalog_surface")
    @Assert(style.base.padding, 10)
    @Assert(style.base.gap, 6)

    // ONE image declaration: logical key/version, never a path edited per node.
    let icon = match (controller.imageDeclaration()) {
        case Some(value) => value
        case None => CjguiGeneratedUiImageResourceSpec("", "", 0, "", "")
    }
    @Assert(icon.key, "catalog_icon")
    @Assert(icon.version, 1)
    @Assert(icon.rasterPath, "composable-beacon.png")

    // The built interface really carries both: the surface uses the named style,
    // and the tree mounts the declared image with its logical identity. The
    // consumer returns the SHARED public scroll container as its root, so the
    // surface is asserted on the content node inside that container.
    let root = controller.buildUi()
    @Assert(root.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    @Assert(root.scrollViewport.isSome(), true)
    @Assert(root.children().size, 1)
    let surfaceNode = root.children()[0]
    @Assert(surfaceNode.style.padding, 10)
    @Assert(surfaceNode.style.gap, 6)
    @Assert(cjguiComposableUiColorToken(surfaceNode.style.background), "#0f1a29ff")
    var sawIcon = false
    for (node in CjguiComposableUiLayoutEngine.layout(root,
        CjguiComposableUiRect(0, 0, 320, 480), 1).nodes()) {
        if (node.imageResourceId == "catalog_icon") {
            sawIcon = true
            @Assert(node.imageResourceVersion, 1)
        }
    }
    @Assert(sawIcon, true)

    // The interaction context is a READ: with no window attached it says
    // `unknown` rather than inventing a focused control.
    @Assert(controller.interactionContext(), "unknown|none|0")
}

/// C3/B3 (UI-only): the SAME public tab container, but now through a REAL window.
///
/// The test above only builds the tree in memory, so it cannot show what the
/// workspace does when it is actually presented. This one attaches a real
/// `CjguiComposableUiWindow` and pins the accepted scene: the declared initial
/// page is presented, the OTHER page keeps its identity with an empty rect and
/// its subtree is NOT materialized - and switching the page is window VIEW state
/// that moves no structure version. That is exactly the page-navigation contract
/// the desktop chain has to reach through the tab titles.
@Test
func uiOnlyConsumerPresentsOneWorkspacePageAtATimeInARealWindow(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2))
    let window = CjguiComposableUiWindow(controller)
    controller.attachWindow(window)
    @Assert(window.start(), true)

    // The container and both page limits are really in the accepted scene.
    let container = treeConsumerNode(window, "catalog-workspace")
    @Assert(container.nodeId > 0, true)
    @Assert(container.isTabsContainer(), true)
    @Assert(treeConsumerNode(window, "catalog-workspace-tab-catalog").nodeId > 0, true)
    @Assert(treeConsumerNode(window, "catalog-workspace-tab-rows").nodeId > 0, true)
    @Assert(treeConsumerNode(window, "catalog-workspace-page").tabsPageActive, true)
    @Assert(treeConsumerNode(window, "catalog-rows-page").tabsPageActive, false)
    // The hidden page keeps its identity with an EMPTY rect, and its subtree - the
    // tree list the desktop chain has to reveal - is not materialized at all.
    @Assert(treeConsumerNode(window, "catalog-rows-page").bounds.height, 0)
    @Assert(treeConsumerNode(window, "catalog-tree-list").nodeId, -1)

    // Switching the page is WINDOW view state: it presents the other page and its
    // list, and it moves no structure version.
    let versionBefore = window.windowProgress().acceptedSceneVersion
    @Assert(controller.requestWorkspacePage("rows"), true)
    @Assert(window.refresh(), true)
    @Assert(treeConsumerNode(window, "catalog-rows-page").tabsPageActive, true)
    @Assert(treeConsumerNode(window, "catalog-workspace-page").bounds.height, 0)
    @Assert(treeConsumerNode(window, "catalog-tree-list").nodeId > 0, true)
    @Assert(treeConsumerNode(window, "catalog-details").nodeId, -1)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    @Assert(window.windowProgress().acceptedSceneVersion > versionBefore, true)
    // The container identity survived the switch: this is the same component, not
    // a rebuilt one.
    @Assert(treeConsumerNode(window, "catalog-workspace").nodeId, container.nodeId)

    // Switching back presents the catalog page again, with its own content.
    @Assert(controller.requestWorkspacePage("catalog"), true)
    @Assert(window.refresh(), true)
    @Assert(treeConsumerNode(window, "catalog-workspace-page").tabsPageActive, true)
    @Assert(treeConsumerNode(window, "catalog-details").nodeId > 0, true)
    @Assert(treeConsumerNode(window, "catalog-tree-list").nodeId, -1)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    window.close()
}

/// One accepted node of the UI-only consumer's window, by semantic id. The
/// consumer keeps no numeric node block, so the id is what the public scene
/// publishes.
private func treeConsumerNode(window: CjguiComposableUiWindow,
    semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// A native Tab sends FOCUS (31) for an actionable row. Focus alone must not
/// execute the row's toggle action or mutate the catalogue and selection.
@Test
func uiOnlyTreeFocusDoesNotActivateGroupOrLeaf(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2))
    let window = CjguiComposableUiWindow(controller)
    controller.attachWindow(window)
    @Assert(window.start(), true)
    controller.expandAll()
    @Assert(controller.requestWorkspacePage("rows"), true)
    @Assert(window.refresh(), true)
    let group = treeConsumerNode(window, "catalog-vgroup-domain-0")
    let leaf = treeConsumerNode(window, "catalog-vleaf-domain-0-topic-0-entry-0")
    @Assert(group.nodeId > 0, true)
    @Assert(leaf.nodeId > 0, true)
    let rowsBefore = controller.visibleRowCount()
    let versionBefore = controller.uiSceneVersion()
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(group, 31, "", 0, 0, 1)).didApply, false)
    @Assert(controller.visibleRowCount(), rowsBefore)
    @Assert(controller.uiSceneVersion(), versionBefore)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(leaf, 31, "", 0, 0, 1)).didApply, false)
    @Assert(controller.selectedCount(), 0)
    @Assert(controller.uiSceneVersion(), versionBefore)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(group, 27, "", 0, 0, 1)).didApply, true)
    @Assert(controller.visibleRowCount() < rowsBefore, true)
    window.close()
}

@Test
func uiOnlyTabsMeasureActivePageInsideSharedViewport(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局", "交互"]), 3, 3))
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI tabs viewport", 324u32, 204u32))
    controller.attachWindow(window)
    @Assert(window.start(), true)
    controller.expandAll()
    @Assert(controller.requestWorkspacePage("rows"), true)
    @Assert(window.refresh(), true)
    let target = treeConsumerNode(window, "catalog-vleaf-domain-0-topic-0-entry-2")
    let scroll = treeConsumerNode(window, "catalog-scroll")
    @Assert(target.nodeId > 0, true)
    @Assert(scroll.nodeId > 0, true)
    let viewport = match (scroll.scrollViewport) {
        case Some(value) => value
        case None => CjguiComposableUiScrollViewport()
    }
    @Assert(target.clipConstraints().size >= 2, true)
    @Assert(target.bounds.y + target.bounds.height > scroll.bounds.y + scroll.bounds.height, true)
    // The accepted content extent must include the active page's last row.
    // Before the fix tabs measured as a generic 30pt node while drawing a
    // 220pt list, so this maximum was zero and focus reveal could never move.
    @Assert(viewport.contentExtent() >= target.bounds.y + target.bounds.height - scroll.bounds.y, true)
    @Assert(viewport.maximumOffset() > 0, true)
    let focusRequested = window.focusScopedNode(
        CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child("domain-0-topic-0-entry-2"), "leaf")
    @Assert(focusRequested, false)
    @Assert(window.refresh(), true)
    let revealed = treeConsumerNode(window, "catalog-vleaf-domain-0-topic-0-entry-2")
    @Assert(viewport.acceptedOffset() > 0, true)
    @Assert(revealed.bounds.y + revealed.bounds.height <= scroll.bounds.y + scroll.bounds.height, true)

    window.close()
}

/// E acceptance: the consumer's opt-in large-text parameter still uses one
/// accepted public text node, then the same application-owned controller can
/// perform a normal content interaction without changing that node's identity.
/// The second half keeps the existing tree focus/reveal path in the same
/// consumer fixture, so text size and public tree interaction are observed
/// together rather than by a renderer copy.
@Test
func uiOnlyLargeTextFixtureKeepsAcceptedIdentityAndTreeReveal(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局", "输入"]), 3, 3),
        largeTextFixture: true)
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI large text consumer", 324u32, 204u32))
    controller.attachWindow(window)
    @Assert(window.start(), true)
    let before = treeConsumerNode(window, "catalog-large-details")
    @Assert(before.nodeId > 0, true)
    @Assert(before.identityKey.size > 0, true)
    @Assert(before.value.size > 4000, true)
    @Assert(before.bounds.width > 0, true)
    @Assert(before.bounds.height > 1000, true)
    let identity = before.identityKey
    let value = before.value
    @Assert(controller.renameEntry("domain-0", "大文字验收重命名"), true)
    @Assert(window.refresh(), true)
    let after = treeConsumerNode(window, "catalog-large-details")
    @Assert(after.identityKey, identity)
    @Assert(after.value != value, true)
    @Assert(after.bounds.height > 1000, true)

    // The same consumer's public tree path still reveals an off-screen row.
    controller.expandAll()
    @Assert(controller.requestWorkspacePage("rows"), true)
    @Assert(window.refresh(), true)
    let target = treeConsumerNode(window, "catalog-vleaf-domain-0-topic-0-entry-2")
    let scroll = treeConsumerNode(window, "catalog-scroll")
    @Assert(target.nodeId > 0, true)
    let viewport = match (scroll.scrollViewport) {
        case Some(value) => value
        case None => CjguiComposableUiScrollViewport()
    }
    let focusRequested = window.focusScopedNode(
        CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child("domain-0-topic-0-entry-2"), "leaf")
    @Assert(focusRequested, false)
    @Assert(window.refresh(), true)
    let revealed = treeConsumerNode(window, "catalog-vleaf-domain-0-topic-0-entry-2")
    @Assert(viewport.acceptedOffset() > 0, true)
    @Assert(revealed.bounds.y + revealed.bounds.height <= scroll.bounds.y + scroll.bounds.height, true)
    window.close()
}

/// C3 (UI-only): this consumer's workspace uses the SAME public tab component as
/// the two application consumers - one container, one title per page, and the
/// ACTIVE page decided by shared window view state rather than a local flag.
@Test
func uiOnlyConsumerBuildsItsWorkspaceThroughThePublicTabContainer(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2))
    let root = controller.buildUi()
    let counts = catalogCountTabs(root, CatalogTabCounts())
    @Assert(counts.containerCount, 1)
    @Assert(counts.titleCount, 2)
    @Assert(counts.pageRootCount, 2)
    @Assert(counts.titles[0], "目录")
    @Assert(counts.titles[1], "条目")
    // The declared initial page is the one the shared state reports.
    @Assert(controller.workspaceState().activeKey(), "catalog")
    @Assert(controller.requestWorkspacePage("rows"), true)
    @Assert(controller.workspaceState().activeKey(), "rows")
    @Assert(controller.requestWorkspacePage("rows"), false)
}

private class CatalogTabCounts {
    var containerCount: Int64 = 0
    var titleCount: Int64 = 0
    var pageRootCount: Int64 = 0
    let titles = ArrayList<String>()
}

private func catalogCountTabs(node: CjguiComposableUiNode, counts: CatalogTabCounts): CatalogTabCounts {
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_TABS) {
        counts.containerCount += 1
    }
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE) {
        counts.titleCount += 1
        counts.titles.add(node.label)
    } else if (node.tabsPageKey.size > 0) {
        counts.pageRootCount += 1
    }
    for (child in node.children()) {
        catalogCountTabs(child, counts)
    }
    return counts
}

/// Readability acceptance for the DARK catalog surface: every role the window
/// actually paints - title, body, status, action button, selectable row and page
/// tab title - must resolve its text colour from the shared theme instead of the
/// near-black default, must clear a readable contrast on that surface in BOTH
/// configurations (which differ only in font size), and each interactive role
/// must declare its normal / focused / disabled paint.
///
/// This is the source-level half of the readability check. The desktop chain
/// samples the real window pixels, because a passing style is not a visible
/// image.
@Test
func uiOnlyCatalogRolesStayReadableOnTheDarkSurface(): Unit {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2))
    let surface = match (controller.namedStyles().forName("catalog_surface")) {
        case Some(value) => value.base
        case None => CjguiComposableUiStyle()
    }
    // This surface is a dark blue, so the near-black default text would fail.
    @Assert(relativeLuminance(surface.background) < 0.1, true)

    // Default configuration: every text / row / title role resolves a light
    // foreground on that surface. The ratio is measured, not assumed.
    for (name in ["catalog_title", "catalog_body", "catalog_status", "catalog_row", "catalog_tab_title"]) {
        let role = catalogRole(controller, name)
        @Assert(role.name, name)
        let resting = role.interaction.resolve(role.base, CjguiComposableUiInteractionState.NONE)
        @Assert(contrastRatio(resting.textColor, surface.background) >= 4.5, true)
    }

    // The tab title role really carries its focused and disabled paint, so the
    // shared tabs component can show focus and not only colour the resting state.
    let tabTitle = catalogRole(controller, "catalog_tab_title")
    @Assert(tabTitle.interaction.focused.border.isSome(), true)
    let focusedTitle = tabTitle.interaction.resolve(tabTitle.base, CjguiComposableUiInteractionState.FOCUSED)
    @Assert(contrastRatio(focusedTitle.textColor, surface.background) >= 4.5, true)
    let disabledTitle = tabTitle.interaction.resolve(tabTitle.base, CjguiComposableUiInteractionState.DISABLED)
    // Disabled text is dimmer than the resting text, but never invisible.
    @Assert(relativeLuminance(disabledTitle.textColor) < relativeLuminance(tabTitle.base.textColor), true)
    @Assert(contrastRatio(disabledTitle.textColor, surface.background) >= 3.0, true)

    // The action role is the SHARED primary-action paint - the same entry the two
    // application consumers resolve - so a catalog button is readable and shows
    // focus/disabled states instead of falling back to near-black text on the dark
    // surface. The shared paint measures ~4.4:1 on its own background (recorded
    // here as the floor), and the catalog reuses it rather than forking a palette.
    let action = catalogRole(controller, "catalog_action")
    let sharedAction = CjguiComposableUiTheme.beaconDark().primaryActionInteraction.normal
    let actionResting = action.interaction.resolve(action.base, CjguiComposableUiInteractionState.NONE)
    @Assert(contrastRatio(actionResting.textColor, actionResting.background) >= 4.0, true)
    @Assert(cjguiComposableUiColorToken(actionResting.textColor),
        cjguiComposableUiColorToken(sharedAction.textColor.getOrThrow()))
    @Assert(action.interaction.focused.border.isSome(), true)
    let actionFocus = action.interaction.resolve(action.base, CjguiComposableUiInteractionState.FOCUSED)
    @Assert(contrastRatio(actionFocus.textColor, actionFocus.background) >= 4.0, true)
    let actionDisabled = action.interaction.resolve(action.base, CjguiComposableUiInteractionState.DISABLED)
    @Assert(contrastRatio(actionDisabled.textColor, actionDisabled.background) >= 3.0, true)

    // BOTH configurations are the SAME role: only the font size may differ, so a
    // large-text window cannot silently fall back to a dark foreground.
    let defaultDetails = acceptedDetailStyle(false, "catalog-details")
    let largeDetails = acceptedDetailStyle(true, "catalog-large-details")
    @Assert(cjguiComposableUiColorToken(defaultDetails.textColor),
        cjguiComposableUiColorToken(largeDetails.textColor))
    @Assert(contrastRatio(defaultDetails.textColor, surface.background) >= 4.5, true)
    @Assert(contrastRatio(largeDetails.textColor, surface.background) >= 4.5, true)
    @Assert(largeDetails.fontSize > defaultDetails.fontSize, true)
}

/// One registered role by name, or an explicitly empty placeholder so a missing
/// role fails the name assertion instead of throwing.
private func catalogRole(controller: CatalogController,
    name: String): CjguiComposableUiNamedStyle {
    return match (controller.namedStyles().forName(name)) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
}

/// The accepted detail node's OWN style in one configuration: the same public
/// text node the window presents, not a re-derived copy of the role.
private func acceptedDetailStyle(largeText: Bool, semanticId: String): CjguiComposableUiStyle {
    let controller = CatalogController(CatalogSource(ArrayList<String>(["绘制", "布局"]), 2, 2),
        largeTextFixture: largeText)
    let window = CjguiComposableUiWindow(controller)
    controller.attachWindow(window)
    @Assert(window.start(), true)
    let node = treeConsumerNode(window, semanticId)
    @Assert(node.nodeId > 0, true)
    let style = node.style
    window.close()
    return style
}

/// sRGB relative luminance (WCAG 2.x), so "light text on a dark surface" is a
/// measured relation instead of an eyeballed one.
private func relativeLuminance(color: CjguiComposableUiColor): Float64 {
    return 0.2126 * linearChannel(color.red) + 0.7152 * linearChannel(color.green) +
        0.0722 * linearChannel(color.blue)
}

private func linearChannel(value: Float64): Float64 {
    let clamped = if (value < 0.0) {
        0.0
    } else if (value > 1.0) {
        1.0
    } else {
        value
    }
    if (clamped <= 0.03928) {
        return clamped / 12.92
    }
    return pow((clamped + 0.055) / 1.055, 2.4)
}

/// WCAG contrast ratio between two colours (1.0 .. 21.0).
private func contrastRatio(first: CjguiComposableUiColor, second: CjguiComposableUiColor): Float64 {
    let a = relativeLuminance(first)
    let b = relativeLuminance(second)
    let lighter = if (a > b) { a } else { b }
    let darker = if (a > b) { b } else { a }
    return (lighter + 0.05) / (darker + 0.05)
}
