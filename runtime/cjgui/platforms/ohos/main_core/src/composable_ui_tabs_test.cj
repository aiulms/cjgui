// Public tab container tests.
//
// What is pinned here:
//   * the container presents exactly ONE page: the active page gets the body
//     rect below the title row, and every other page keeps its identity in the
//     accepted scene with an EMPTY rect and no measured subtree (hiding is not
//     deletion, and a hidden page pays no text measurement);
//   * the active page is WINDOW view state: the declaration only seeds a new
//     instance, and a page that disappears from the description cannot leave the
//     container pointing at nothing.
package cjgui

import std.collection.*

private class TabsTestController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    private let advancedEnabled: Bool
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState, advancedEnabled!: Bool = true) {
        this.state = state
        this.advancedEnabled = advancedEnabled
    }

    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("tabs-test")
        let basic = cjguiComposableVertical(611, "tabs-basic-content", CjguiComposableUiStyle(gap: 4))
        basic.add(cjguiComposableText(501, "tabs-basic-line", "基本行", CjguiComposableUiStyle(fontSize: 13.0)))
        let advanced = cjguiComposableVertical(612, "tabs-advanced-content", CjguiComposableUiStyle(gap: 4))
        advanced.add(cjguiComposableText(502, "tabs-advanced-line", "高级行",
            CjguiComposableUiStyle(fontSize: 13.0)))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
        pages.add(CjguiComposableUiTabPage("advanced", "高级", advanced, enabled: advancedEnabled))
        return cjguiComposableTabs(scope, "tabs-root", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
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

private func tabsAcceptedNode(window: CjguiComposableUiWindow, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private func tabsStartWindow(state: CjguiComposableUiTabsState): CjguiComposableUiWindow {
    let controller = TabsTestController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    return window
}

@Test
func tabsPresentExactlyOnePageAndKeepTheOtherHidden(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    @Assert(state.activeKey(), "basic")
    let window = tabsStartWindow(state)
    // The active page is laid out below the 24pt title row and fills the body.
    let active = tabsAcceptedNode(window, "tabs-basic-line")
    @Assert(active.nodeId > 0, true)
    @Assert(active.bounds.y >= 24, true)
    @Assert(active.bounds.height > 0, true)
    // The HIDDEN page is still an accepted instance: same identity, empty rect,
    // inactive marker, and its text node is not part of this solve at all.
    let hiddenPage = tabsAcceptedNode(window, "tabs-advanced-content")
    @Assert(hiddenPage.nodeId > 0, true)
    @Assert(hiddenPage.tabsPageKey, "advanced")
    @Assert(hiddenPage.tabsPageActive, false)
    @Assert(hiddenPage.bounds.width, 0)
    @Assert(hiddenPage.bounds.height, 0)
    @Assert(tabsAcceptedNode(window, "tabs-advanced-line").nodeId, -1)
    // The title row is on top and both titles are addressable.
    let titles = tabsAcceptedNode(window, "tabs-root-titles")
    @Assert(titles.nodeId > 0, true)
    @Assert(titles.bounds.height, 24)
    @Assert(tabsAcceptedNode(window, "tabs-root-tab-basic").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-root-tab-advanced").nodeId > 0, true)
    // The activation intent the window applies needs exactly these facts on the
    // accepted title: framework-owned kind, the shared view state, the stable
    // page key, and a title that can actually be activated.
    let advancedTitle = tabsAcceptedNode(window, "tabs-root-tab-advanced")
    @Assert(advancedTitle.isTabTitle(), true)
    @Assert(advancedTitle.tabsPageKey, "advanced")
    @Assert(advancedTitle.tabsState.isSome(), true)
    @Assert(advancedTitle.isEnabled, true)
    @Assert(advancedTitle.canReceiveInput(), true)
    // Native focus traversal reaches a title as an ordinary focusable control, so
    // Tab/Shift-Tab can move between titles; a DISABLED title is skipped by the
    // same rule the traversal consumes.
    @Assert(advancedTitle.canReceiveFocus(), true)
    window.close()
}

@Test
func tabsStateMovesTheActivePageAndHidesTheOldOne(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    @Assert(state.select("advanced"), true)
    @Assert(state.select("advanced"), false)
    @Assert(state.select(""), false)
    let window = tabsStartWindow(state)
    let nowActive = tabsAcceptedNode(window, "tabs-advanced-line")
    @Assert(nowActive.nodeId > 0, true)
    @Assert(nowActive.bounds.height > 0, true)
    // The page that WAS active keeps its identity and becomes the hidden one.
    @Assert(tabsAcceptedNode(window, "tabs-basic-line").nodeId, -1)
    let hiddenPage = tabsAcceptedNode(window, "tabs-basic-content")
    @Assert(hiddenPage.nodeId > 0, true)
    @Assert(hiddenPage.tabsPageKey, "basic")
    @Assert(hiddenPage.bounds.height, 0)
    @Assert(hiddenPage.tabsPageActive, false)
    window.close()
}

/// A page that disappears from the description must not leave the container
/// pointing at nothing, and a surviving page keeps the person's selection.
@Test
func tabsStateReconcilesTheActivePageWithTheDescription(): Unit {
    let state = CjguiComposableUiTabsState("advanced")
    let surviving = ArrayList<String>(["basic", "advanced"])
    @Assert(state.reconcile(surviving, "basic"), false)
    @Assert(state.activeKey(), "advanced")
    let onlyBasic = ArrayList<String>(["basic"])
    @Assert(state.reconcile(onlyBasic, "basic"), true)
    @Assert(state.activeKey(), "basic")
    // The declaration may not silently move an existing selection back.
    @Assert(state.reconcile(surviving, "advanced"), false)
    @Assert(state.activeKey(), "basic")
}

/// A DISABLED page title is skipped by the very rules native focus traversal and
/// the framework activation intent consume: it is neither interactive nor
/// focusable, so Tab/Shift-Tab never lands on it and it can never be activated -
/// while its enabled sibling stays reachable.
@Test
func disabledTabTitleIsNotFocusableOrActivatable(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsTestController(state, advancedEnabled: false)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let enabledTitle = tabsAcceptedNode(window, "tabs-root-tab-basic")
    let disabledTitle = tabsAcceptedNode(window, "tabs-root-tab-advanced")
    @Assert(enabledTitle.nodeId > 0, true)
    @Assert(disabledTitle.nodeId > 0, true)
    // The enabled title is an ordinary control...
    @Assert(enabledTitle.isEnabled, true)
    @Assert(enabledTitle.canReceiveInput(), true)
    @Assert(enabledTitle.canReceiveFocus(), true)
    // ...the disabled one is not, which is exactly what traversal reads.
    @Assert(disabledTitle.isEnabled, false)
    @Assert(disabledTitle.canReceiveInput(), false)
    @Assert(disabledTitle.canReceiveFocus(), false)
    window.close()
}

/// A controller whose NEXT build can be made invalid (two declarations sharing
/// one node id), so a tab switch can be attempted and REJECTED. The accepted
/// scene must then keep the OLD page rather than publishing a half-switched one.
private class TabsRejectingController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    var duplicateNodeId: Bool = false
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState) {
        this.state = state
    }
    public func select(page: String): Bool {
        if (!state.select(page)) {
            return false
        }
        revision += 1
        return true
    }
    public func bumpRevision(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("tabs-reject")
        let basic = cjguiComposableVertical(611, "tabs-basic-content", CjguiComposableUiStyle(gap: 4))
        basic.add(cjguiComposableText(501, "tabs-basic-line", "基本行", CjguiComposableUiStyle(fontSize: 13.0)))
        let advanced = cjguiComposableVertical(612, "tabs-advanced-content", CjguiComposableUiStyle(gap: 4))
        advanced.add(cjguiComposableText(502, "tabs-advanced-line", "高级行",
            CjguiComposableUiStyle(fontSize: 13.0)))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
        pages.add(CjguiComposableUiTabPage("advanced", "高级", advanced))
        let tabs = cjguiComposableTabs(scope, "tabs-root", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
        if (duplicateNodeId) {
            // The SAME numeric id twice: the window refuses the whole candidate.
            let root = cjguiComposableVertical(1, "tabs-reject-root", CjguiComposableUiStyle(gap: 4))
            root.add(tabs)
            // The duplicate id must be one that is REALLY laid out: a hidden
            // page's node is never in the accepted scene, so colliding with it
            // would not be observable. The ADVANCED line is the active page here.
            root.add(cjguiComposableText(502, "tabs-reject-duplicate", "重复", CjguiComposableUiStyle()))
            return root
        }
        return tabs
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

/// A page switch goes through the SAME scene transaction as any other change: when
/// the candidate scene is refused, the accepted scene keeps the page a person was
/// already looking at instead of publishing a half-switched one.
@Test
func rejectedSceneKeepsThePreviouslyAcceptedTabPage(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsRejectingController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    // The accepted scene shows the declared initial page.
    @Assert(tabsAcceptedNode(window, "tabs-basic-line").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-advanced-line").nodeId, -1)

    // A person switches the page AND the next declaration is invalid.
    controller.duplicateNodeId = true
    @Assert(controller.select("advanced"), true)
    // `refresh()` returns whether the pass ran; the CANDIDATE outcome is what
    // matters, and it is reported through the window's failure fact.
    let _ = window.refresh()
    @Assert(window.windowProgress().lastNativeFailure, "duplicate_node_id")
    // The accepted scene still shows the OLD page: the switch did not half-apply.
    @Assert(tabsAcceptedNode(window, "tabs-basic-line").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-advanced-line").nodeId, -1)

    // Once the declaration is legal again, the pending switch is presented.
    controller.duplicateNodeId = false
    controller.bumpRevision()
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    @Assert(tabsAcceptedNode(window, "tabs-advanced-line").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-basic-line").nodeId, -1)
    window.close()
}

/// Hidden pages must not produce paint work. The window submits exactly the
/// accepted (laid-out) nodes, so the submitted SET is the paint set: it must
/// contain the active page's content, exactly one zero-area node for the hidden
/// page, and NOT a single node of the hidden page's subtree.
@Test
func hiddenPageContributesNoPaintableNodes(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsTestController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let nodes = window.acceptedSceneNodes()
    // The active page's line is submitted and paintable.
    let activeLine = tabsAcceptedNode(window, "tabs-basic-line")
    @Assert(activeLine.nodeId > 0, true)
    @Assert(activeLine.bounds.height > 0, true)
    // NO node of the hidden page's subtree is submitted at all.
    @Assert(tabsAcceptedNode(window, "tabs-advanced-line").nodeId, -1)
    var hiddenPageNodes = 0
    var hasArea = false
    for (node in nodes) {
        if (node.tabsPageKey == "advanced" && !node.isTabTitle()) {
            hiddenPageNodes += 1
            if (node.bounds.width > 0 || node.bounds.height > 0) {
                hasArea = true
            }
        }
    }
    @Assert(hiddenPageNodes, 1)
    @Assert(hasArea, false)
    window.close()
}

/// Tabs measurement participates in the scroll viewport's accepted scene
/// transaction. A rejected short-page candidate must not shrink the accepted
/// long-page extent or its accepted offset; the later legal switch must do both.
private class TabsExtentRejectingController <: CjguiComposableUiController {
    let state = CjguiComposableUiTabsState("short")
    let viewport = CjguiComposableUiScrollViewport()
    var duplicateNodeId = false
    private var revision: Int64 = 1

    public func select(page: String): Bool {
        if (!state.select(page)) { return false }
        revision += 1
        return true
    }
    public func bump(): Unit { revision += 1 }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("tabs-extent")
        let shortPage = cjguiComposableVertical(501, "extent-short-page", CjguiComposableUiStyle())
        shortPage.add(cjguiComposableText(502, "extent-short-line", "短页",
            CjguiComposableUiStyle(fixedHeight: 24)))
        let longPage = cjguiComposableVertical(601, "extent-long-page", CjguiComposableUiStyle(gap: 4))
        var index: Int64 = 0
        while (index < 16) {
            longPage.add(cjguiComposableText(602 + index, "extent-long-line-${index}", "长页 ${index}",
                CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("short", "短", shortPage))
        pages.add(CjguiComposableUiTabPage("long", "长", longPage))
        let tabs = cjguiComposableTabs(scope, "extent-tabs", pages, state,
            CjguiComposableUiStyle(growX: 1, gap: 4), titleHeight: 24)
        let content = cjguiComposableVertical(700, "extent-content", CjguiComposableUiStyle())
        content.add(tabs)
        if (duplicateNodeId) {
            // This collides with the active SHORT page after the switch, after
            // the candidate has already measured a smaller content extent.
            content.add(cjguiComposableText(502, "extent-duplicate", "重复", CjguiComposableUiStyle()))
        }
        let scroll = cjguiComposableScrollArea(701, "extent-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
        scroll.add(content)
        return scroll
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

@Test
func rejectedTabSwitchRetainsAcceptedViewportExtentAndOffset(): Unit {
    let controller = TabsExtentRejectingController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI tabs extent", 324u32, 204u32))
    @Assert(window.start(), true)
    let shortExtent = controller.viewport.contentExtent()
    @Assert(tabsAcceptedNode(window, "extent-short-line").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "extent-long-line-0").nodeId, -1)
    @Assert(controller.select("long"), true)
    @Assert(window.refresh(), true)
    let longExtent = controller.viewport.contentExtent()
    @Assert(longExtent > shortExtent, true)
    @Assert(controller.viewport.maximumOffset() > 0, true)
    @Assert(tabsAcceptedNode(window, "extent-short-line").nodeId, -1)
    @Assert(tabsAcceptedNode(window, "extent-long-line-0").nodeId > 0, true)
    @Assert(controller.viewport.requestOffset(100), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let longOffset = controller.viewport.acceptedOffset()
    @Assert(longOffset > 0, true)

    controller.duplicateNodeId = true
    @Assert(controller.select("short"), true)
    let _ = window.refresh()
    @Assert(window.windowProgress().lastNativeFailure, "duplicate_node_id")
    @Assert(controller.viewport.contentExtent(), longExtent)
    @Assert(controller.viewport.acceptedOffset(), longOffset)
    @Assert(tabsAcceptedNode(window, "extent-long-line-0").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "extent-short-line").nodeId, -1)

    controller.duplicateNodeId = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    @Assert(controller.viewport.contentExtent(), shortExtent)
    @Assert(controller.viewport.acceptedOffset(), 0)
    @Assert(tabsAcceptedNode(window, "extent-short-line").nodeId > 0, true)
    @Assert(tabsAcceptedNode(window, "extent-long-line-0").nodeId, -1)
    window.close()
}

// --- B2: hidden-page focus continuation -------------------------------------

private class TabsPageFocusController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    let scope = CjguiComposableUiIdentityScope("tabs-page-focus")
    var basicValue: String = "基本值"
    var basicSecondValue: String = "第二字段"
    var advancedValue: String = "高级值"
    var advancedEnabled: Bool = true
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState) {
        this.state = state
    }
    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        // TWO editors on the basic page: the generic "next focusable" continuation
        // lands on the FIRST one, so restoring the SECOND one proves the page
        // bookmark really wins over the continuation rule.
        let basic = cjguiComposableVertical(611, "tabs-page-focus-basic", CjguiComposableUiStyle(gap: 4))
        basic.add(CjguiComposableUiNode(501, "tabs-page-focus-basic-input", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "基本", basicValue, "", 8101, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("basic-input")))
        basic.add(CjguiComposableUiNode(503, "tabs-page-focus-basic-second", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "第二", basicSecondValue, "", 8103, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("basic-second")))
        let advanced = cjguiComposableVertical(612, "tabs-page-focus-advanced", CjguiComposableUiStyle(gap: 4))
        advanced.add(CjguiComposableUiNode(502, "tabs-page-focus-advanced-input", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "高级", advancedValue, "", 8102, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("advanced-input")))
        // Padding rows make the advanced page LONGER than the basic one, so the
        // generic "next focusable at the previous index" continuation cannot
        // accidentally land on the basic page's second editor.
        var pad: Int64 = 0
        while (pad < 6) {
            advanced.add(cjguiComposableText(520 + pad, "tabs-page-focus-advanced-pad-${pad}", "补充${pad}",
                CjguiComposableUiStyle(fixedHeight: 20)))
            pad += 1
        }
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
        pages.add(CjguiComposableUiTabPage("advanced", "高级", advanced, enabled: advancedEnabled))
        return cjguiComposableTabs(scope, "tabs-page-focus-root", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
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

/// B2: switching away from a page and back presents the person's OWN valid focus
/// again. The generic continuation would land on the page's FIRST focusable node,
/// so restoring the SECOND editor proves the bookmark is what decides.
@Test
func switchingBackToAPageRestoresItsValidFocus(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsPageFocusController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let firstInput = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    let secondInput = tabsAcceptedNode(window, "tabs-page-focus-basic-second")
    @Assert(firstInput.nodeId > 0, true)
    @Assert(secondInput.nodeId > 0, true)
    @Assert(secondInput.canReceiveFocus(), true)
    // A person focuses the FIRST editor of the basic page. The generic
    // continuation, by contrast, lands on the SECOND one after the round trip
    // (measured with the restore disabled), so the assertion below is decided by
    // the page bookmark and not by the continuation rule.
    @Assert(window.focusScopedNode(controller.scope, "basic-input"), true)
    let afterFocus = window.testPageFocusBookmarkTrace()
    @Assert(afterFocus.contains("page=basic"), true)
    @Assert(afterFocus.contains("node=${firstInput.nodeId}"), true)
    // The person switches to the advanced page.
    @Assert(state.select("advanced"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("page=advanced"), true)
    // Switching BACK restores the basic page's OWN recorded editor.
    @Assert(state.select("basic"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${firstInput.nodeId}"), true)
    // ...and NOT the editor the generic continuation would have chosen.
    @Assert(firstInput.nodeId != secondInput.nodeId, true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${secondInput.nodeId}"), false)
    let restored = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    @Assert(restored.nodeId, firstInput.nodeId)
    @Assert(restored.canReceiveFocus(), true)
    window.close()
}

/// B2: a background business write on a HIDDEN page never moves the focus, and a
/// bookmark is a position only: the accepted node still carries the owner's
/// CURRENT value rather than a replayed old one. The person's focus is the page's
/// FIRST editor while the owner rewrites the SECOND one, so the restore below is
/// decided by the page bookmark and not by the generic "next focusable" rule.
@Test
func aHiddenPageWriteDoesNotMoveFocusAndNeverReplaysAValue(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsPageFocusController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let firstInput = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    let secondInput = tabsAcceptedNode(window, "tabs-page-focus-basic-second")
    @Assert(firstInput.nodeId > 0, true)
    @Assert(secondInput.nodeId > 0, true)
    @Assert(firstInput.nodeId != secondInput.nodeId, true)
    @Assert(window.focusScopedNode(controller.scope, "basic-input"), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("page=basic"), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("node=${firstInput.nodeId}"), true)
    @Assert(state.select("advanced"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let advancedInput = tabsAcceptedNode(window, "tabs-page-focus-advanced-input")
    @Assert(advancedInput.nodeId > 0, true)
    let focusedBefore = window.testPageFocusBookmarkTrace()
    @Assert(focusedBefore.contains("focused=${advancedInput.nodeId}"), true)
    // The owner rewrites the OTHER editor of the HIDDEN basic page while the
    // person is on advanced.
    controller.basicSecondValue = "外部改写后的值"
    controller.bump()
    @Assert(window.refresh(), true)
    // The write alone changed no page, so the focus did not move.
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${advancedInput.nodeId}"), true)
    // Switching back restores the person's OWN editor (the bookmark), not the
    // editor the generic continuation would have chosen, and reads the owner's
    // CURRENT value.
    @Assert(state.select("basic"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${firstInput.nodeId}"), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${secondInput.nodeId}"), false)
    let restoredSecond = tabsAcceptedNode(window, "tabs-page-focus-basic-second")
    @Assert(restoredSecond.nodeId > 0, true)
    @Assert(restoredSecond.value, "外部改写后的值")
    window.close()
}

/// B2: a person's SELECTION place in a page is view state that survives being
/// hidden - not only the FIRST time they come back. The generic focus projection
/// resets the projected selection while restoring, so a restore that does not
/// re-record the place silently drops it on the SECOND round trip.
@Test
func pageSelectionBookmarkSurvivesRepeatedPageRoundTrips(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsPageFocusController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let firstInput = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    @Assert(firstInput.nodeId > 0, true)
    // "基本值" is three UTF-16 code units despite occupying nine UTF-8 bytes.
    @Assert(firstInput.value.size, 9)
    @Assert(window.focusScopedNode(controller.scope, "basic-input"), true)
    @Assert(window.testRememberFocusedSelection(1, 2), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${firstInput.nodeId} sel=1-2"), true)
    // Leave the page and return: the place is presented again.
    @Assert(state.select("advanced"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(state.select("basic"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let firstReturn = window.testPageFocusBookmarkTrace()
    @Assert(firstReturn.contains("focused=${firstInput.nodeId} sel=1-2"), true)
    // A SECOND round trip must present the SAME place.
    @Assert(state.select("advanced"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(state.select("basic"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let secondReturn = window.testPageFocusBookmarkTrace()
    @Assert(secondReturn.contains("focused=${firstInput.nodeId} sel=1-2"), true)
    window.close()
}

/// B2: when the owner SHRINKS the value of a hidden page, the stale selection in
/// the bookmark is bounded by the value the owner has NOW. The position is a view
/// fact; the value itself is never replayed.
@Test
func hiddenOwnerWriteBoundsTheRestoredSelectionToTheCurrentValue(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsPageFocusController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let firstInput = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    @Assert(firstInput.nodeId > 0, true)
    @Assert(firstInput.value.size, 9)
    @Assert(window.focusScopedNode(controller.scope, "basic-input"), true)
    @Assert(window.testRememberFocusedSelection(1, 2), true)
    @Assert(state.select("advanced"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let advancedInput = tabsAcceptedNode(window, "tabs-page-focus-advanced-input")
    @Assert(advancedInput.nodeId > 0, true)
    // The owner shrinks the HIDDEN basic editor to one UTF-16 code unit.
    controller.basicValue = "新"
    controller.bump()
    @Assert(window.refresh(), true)
    // The hidden write did not move the person's focus.
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${advancedInput.nodeId}"), true)
    // Returning presents the owner's SMALLER value and a position inside it.
    @Assert(state.select("basic"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let restored = tabsAcceptedNode(window, "tabs-page-focus-basic-input")
    @Assert(restored.value, "新")
    let trace = window.testPageFocusBookmarkTrace()
    @Assert(trace.contains("focused=${firstInput.nodeId} sel=1-1"), true)
    window.close()
}

private class NestedPageFocusController <: CjguiComposableUiController {
    let outerScope = CjguiComposableUiIdentityScope("nested-page-outer")
    let innerScope = CjguiComposableUiIdentityScope("nested-page-inner")
    let outerState = CjguiComposableUiTabsState("outer")
    let innerState = CjguiComposableUiTabsState("inner")

    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let innerBody = cjguiComposableVertical(9101, "nested-inner-body", CjguiComposableUiStyle(gap: 4))
        innerBody.add(CjguiComposableUiNode(9102, "nested-inner-editor", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "内层", "内层值", "", 9102, CjguiComposableUiStyle(fixedHeight: 24),
            identity: innerScope.local("editor")))
        let innerPages = ArrayList<CjguiComposableUiTabPage>()
        innerPages.add(CjguiComposableUiTabPage("inner", "内层页", innerBody))
        let outerBody = cjguiComposableVertical(9103, "nested-outer-body", CjguiComposableUiStyle(gap: 4))
        outerBody.add(cjguiComposableTabs(innerScope, "nested-inner-tabs", innerPages, innerState,
            CjguiComposableUiStyle(fixedHeight: 80), titleHeight: 24))
        outerBody.add(CjguiComposableUiNode(9104, "nested-outer-editor", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "外层", "外层值", "", 9104, CjguiComposableUiStyle(fixedHeight: 24),
            identity: outerScope.local("editor")))
        let outerPages = ArrayList<CjguiComposableUiTabPage>()
        outerPages.add(CjguiComposableUiTabPage("outer", "外层页", outerBody))
        return cjguiComposableTabs(outerScope, "nested-outer-tabs", outerPages, outerState,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
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

@Test
func nestedPageBookmarkUsesAcceptedAncestorsForAnOuterEditorAfterInnerPage(): Unit {
    let controller = NestedPageFocusController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.focusScopedNode(controller.innerScope, "editor"), true)
    let innerTrace = window.testPageFocusBookmarkTrace()
    @Assert(innerTrace.contains("page=inner"), true)
    @Assert(window.focusScopedNode(controller.outerScope, "editor"), true)
    let outerTrace = window.testPageFocusBookmarkTrace()
    let outerEditor = tabsAcceptedNode(window, "nested-outer-editor")
    @Assert(outerTrace.contains("page=outer"), true)
    @Assert(outerTrace.contains("focused=${outerEditor.nodeId}"), true)
    window.close()
}

// --- B1: tab TITLE keyboard rules -------------------------------------------

private class TabsThreePageController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    let scope = CjguiComposableUiIdentityScope("tabs-three")
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState) {
        this.state = state
    }
    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本",
            cjguiComposableText(501, "tabs-three-basic-line", "基本行", CjguiComposableUiStyle())))
        // The MIDDLE title is disabled, so a real move must skip it.
        pages.add(CjguiComposableUiTabPage("advanced", "高级",
            cjguiComposableText(502, "tabs-three-advanced-line", "高级行", CjguiComposableUiStyle()),
            enabled: false))
        pages.add(CjguiComposableUiTabPage("notes", "备注",
            cjguiComposableText(503, "tabs-three-notes-line", "备注行", CjguiComposableUiStyle())))
        return cjguiComposableTabs(scope, "tabs-three-root", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
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

/// B1: a real move skips the DISABLED middle title and lands on the next ENABLED
/// one; going back returns to the start. The page never changes on an arrow.
@Test
func tabTitleArrowSkipsDisabledAndKeepsThePage(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsThreePageController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let basicTitle = tabsAcceptedNode(window, "tabs-three-root-tab-basic")
    let advancedTitle = tabsAcceptedNode(window, "tabs-three-root-tab-advanced")
    let notesTitle = tabsAcceptedNode(window, "tabs-three-root-tab-notes")
    @Assert(basicTitle.nodeId > 0, true)
    @Assert(advancedTitle.nodeId > 0, true)
    @Assert(notesTitle.nodeId > 0, true)
    @Assert(advancedTitle.isEnabled, false)
    // Right from basic skips the disabled advanced title and reaches notes.
    @Assert(window.testNavigateTabTitle(basicTitle.nodeId, "right"), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${notesTitle.nodeId}"), true)
    // Left from notes returns to the start.
    @Assert(window.testNavigateTabTitle(notesTitle.nodeId, "left"), true)
    @Assert(window.testPageFocusBookmarkTrace().contains("focused=${basicTitle.nodeId}"), true)
    // No arrow ever switched the page.
    @Assert(state.activeKey(), "basic")
    window.close()
}

/// B1: Left/Right move the TITLE focus inside ONE accepted tab group, skipping
/// disabled titles and clamping at both ends. They never switch a page: that
/// stays the ACTIVATE interaction (Enter/Space, AXPress, pointer).
@Test
func tabTitleArrowsMoveFocusInsideTheGroupOnly(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsTestController(state, advancedEnabled: false)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let basicTitle = tabsAcceptedNode(window, "tabs-root-tab-basic")
    let advancedTitle = tabsAcceptedNode(window, "tabs-root-tab-advanced")
    @Assert(basicTitle.nodeId > 0, true)
    @Assert(advancedTitle.nodeId > 0, true)
    @Assert(advancedTitle.isEnabled, false)
    // The disabled title can never receive the keyboard.
    @Assert(window.testNavigateTabTitle(advancedTitle.nodeId, "right"), false)
    @Assert(window.testNavigateTabTitle(advancedTitle.nodeId, "left"), false)
    // From the only ENABLED title, both ends clamp: nothing moves and no page
    // switches.
    @Assert(window.testNavigateTabTitle(basicTitle.nodeId, "right"), false)
    @Assert(window.testNavigateTabTitle(basicTitle.nodeId, "left"), false)
    @Assert(state.activeKey(), "basic")
    // A non-title node is never a navigation target for this rule.
    @Assert(window.testNavigateTabTitle(-1, "right"), false)
    window.close()
}

/// B1: the ACTIVATE decision for a tab title is the ordinary page switch, and an
/// already-active or disabled title is consumed/refused without inventing a page.
@Test
func tabTitleActivationSwitchesTheAcceptedPage(): Unit {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsTestController(state)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let basicTitle = tabsAcceptedNode(window, "tabs-root-tab-basic")
    let advancedTitle = tabsAcceptedNode(window, "tabs-root-tab-advanced")
    // The active title is consumed without a change.
    @Assert(window.testActivateTabTitle(basicTitle.nodeId), true)
    @Assert(state.activeKey(), "basic")
    // The other title selects its page...
    @Assert(window.testActivateTabTitle(advancedTitle.nodeId), true)
    @Assert(state.activeKey(), "advanced")
    // ...and the next accepted scene really presents it.
    controller.bump()
    @Assert(window.refresh(), true)
    let advancedLine = tabsAcceptedNode(window, "tabs-advanced-line")
    @Assert(advancedLine.nodeId > 0, true)
    @Assert(advancedLine.bounds.height > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-basic-line").bounds.height, 0)
    window.close()
}

/// Two INDEPENDENT tab containers that deliberately share the same page keys and
/// titles. The group must be resolved by the accepted container INSTANCE (its view
/// state object), never by title text or page key, so one group's title can never
/// move the other one. The right group can also drop its advanced page, which is
/// how a stale title identity is produced.
private class TabsTwinGroupController <: CjguiComposableUiController {
    let leftState: CjguiComposableUiTabsState
    let rightState: CjguiComposableUiTabsState
    let leftScope = CjguiComposableUiIdentityScope("tabs-twin-left")
    let rightScope = CjguiComposableUiIdentityScope("tabs-twin-right")
    var rightAdvancedPresent: Bool = true
    private var revision: Int64 = 1

    init(leftState: CjguiComposableUiTabsState, rightState: CjguiComposableUiTabsState) {
        this.leftState = leftState
        this.rightState = rightState
    }
    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(630, "tabs-twin-root", CjguiComposableUiStyle(gap: 4))
        // Each page's content is its OWN container, so the page root's semantic id
        // is distinct from the line inside it: a hidden page keeps its root (empty
        // rect) while its subtree is really absent.
        let leftPages = ArrayList<CjguiComposableUiTabPage>()
        let leftBasic = cjguiComposableVertical(631, "tabs-twin-left-basic-content", CjguiComposableUiStyle())
        leftBasic.add(cjguiComposableText(635, "tabs-twin-left-basic-line", "基本行", CjguiComposableUiStyle()))
        leftPages.add(CjguiComposableUiTabPage("basic", "基本", leftBasic))
        let leftAdvanced = cjguiComposableVertical(632, "tabs-twin-left-advanced-content", CjguiComposableUiStyle())
        leftAdvanced.add(cjguiComposableText(636, "tabs-twin-left-advanced-line", "高级行", CjguiComposableUiStyle()))
        leftPages.add(CjguiComposableUiTabPage("advanced", "高级", leftAdvanced))
        root.add(cjguiComposableTabs(leftScope, "tabs-twin-left", leftPages, leftState,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24))
        let rightPages = ArrayList<CjguiComposableUiTabPage>()
        let rightBasic = cjguiComposableVertical(633, "tabs-twin-right-basic-content", CjguiComposableUiStyle())
        rightBasic.add(cjguiComposableText(637, "tabs-twin-right-basic-line", "基本行", CjguiComposableUiStyle()))
        rightPages.add(CjguiComposableUiTabPage("basic", "基本", rightBasic))
        if (rightAdvancedPresent) {
            let rightAdvanced = cjguiComposableVertical(634, "tabs-twin-right-advanced-content", CjguiComposableUiStyle())
            rightAdvanced.add(cjguiComposableText(638, "tabs-twin-right-advanced-line", "高级行", CjguiComposableUiStyle()))
            rightPages.add(CjguiComposableUiTabPage("advanced", "高级", rightAdvanced))
        }
        root.add(cjguiComposableTabs(rightScope, "tabs-twin-right", rightPages, rightState,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24))
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

/// B1: two tab groups with the SAME page keys and titles must not cross-route.
/// The group is the accepted container instance, so activating (or arrowing
/// inside) one group leaves the other group's page and focus untouched.
@Test
func twinTabGroupsWithSamePageKeysDoNotCrossRoute(): Unit {
    let leftState = CjguiComposableUiTabsState("basic")
    let rightState = CjguiComposableUiTabsState("basic")
    let controller = TabsTwinGroupController(leftState, rightState)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let leftBasic = tabsAcceptedNode(window, "tabs-twin-left-tab-basic")
    let leftAdvanced = tabsAcceptedNode(window, "tabs-twin-left-tab-advanced")
    let rightBasic = tabsAcceptedNode(window, "tabs-twin-right-tab-basic")
    let rightAdvanced = tabsAcceptedNode(window, "tabs-twin-right-tab-advanced")
    @Assert(leftBasic.nodeId > 0, true)
    @Assert(rightBasic.nodeId > 0, true)
    @Assert(leftAdvanced.nodeId > 0, true)
    @Assert(rightAdvanced.nodeId > 0, true)
    // Same page keys and titles, but DIFFERENT identities.
    @Assert(leftBasic.nodeId != rightBasic.nodeId, true)
    @Assert(leftAdvanced.nodeId != rightAdvanced.nodeId, true)

    // Activating the LEFT group's advanced title switches ONLY the left group.
    @Assert(window.testActivateTabTitle(leftAdvanced.nodeId), true)
    @Assert(leftState.activeKey(), "advanced")
    @Assert(rightState.activeKey(), "basic")
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-left-advanced-line").bounds.height > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-left-basic-line").nodeId, -1)
    @Assert(tabsAcceptedNode(window, "tabs-twin-right-basic-line").bounds.height > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-right-advanced-line").nodeId, -1)

    // Activating the RIGHT group's advanced title switches only the right group.
    @Assert(window.testActivateTabTitle(rightAdvanced.nodeId), true)
    @Assert(rightState.activeKey(), "advanced")
    @Assert(leftState.activeKey(), "advanced")
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-right-advanced-line").bounds.height > 0, true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-left-advanced-line").bounds.height > 0, true)

    // Arrow navigation stays inside the group whose title received it, and the
    // title identity survived the page switches.
    let leftAdvancedNow = tabsAcceptedNode(window, "tabs-twin-left-tab-advanced")
    @Assert(leftAdvancedNow.nodeId, leftAdvanced.nodeId)
    @Assert(window.testNavigateTabTitle(leftAdvancedNow.nodeId, "left"), true)
    let trace = window.testPageFocusBookmarkTrace()
    @Assert(trace.contains("focused=${leftBasic.nodeId}"), true)
    @Assert(trace.contains("focused=${rightBasic.nodeId}"), false)
    window.close()
}

/// B1: a title whose page was REMOVED from the declaration is a stale identity.
/// It must fail closed instead of routing into whatever now shares its id or page
/// key, and the surviving group must still switch legally afterwards.
@Test
func staleTabTitleFailsClosedAfterItsPageIsRemoved(): Unit {
    let leftState = CjguiComposableUiTabsState("basic")
    let rightState = CjguiComposableUiTabsState("basic")
    let controller = TabsTwinGroupController(leftState, rightState)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let rightAdvanced = tabsAcceptedNode(window, "tabs-twin-right-tab-advanced")
    @Assert(rightAdvanced.nodeId > 0, true)
    // The right group's advanced page disappears from the declaration.
    controller.rightAdvancedPresent = false
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(tabsAcceptedNode(window, "tabs-twin-right-tab-advanced").nodeId, -1)
    @Assert(rightState.activeKey(), "basic")
    // The stale identity moves nothing, in either group.
    @Assert(window.testActivateTabTitle(rightAdvanced.nodeId), false)
    @Assert(rightState.activeKey(), "basic")
    @Assert(leftState.activeKey(), "basic")
    @Assert(window.testNavigateTabTitle(rightAdvanced.nodeId, "left"), false)
    // The surviving group still routes legally.
    let leftAdvanced = tabsAcceptedNode(window, "tabs-twin-left-tab-advanced")
    @Assert(leftAdvanced.nodeId > 0, true)
    @Assert(window.testActivateTabTitle(leftAdvanced.nodeId), true)
    @Assert(leftState.activeKey(), "advanced")
    @Assert(rightState.activeKey(), "basic")
    window.close()
}
