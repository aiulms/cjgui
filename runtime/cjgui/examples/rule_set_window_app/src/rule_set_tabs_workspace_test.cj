// The rule-set window's detail pane is a REAL multi-page workspace built through
// the public tab container: "基本" holds the draft fields, "保留策略" the file and
// retention work. The shipping window and this test build the SAME tree through
// `ruleDetailTabWorkspace`, so the contract below is about shipped composition -
// exactly one page presented, the other page keeping its identity, and the ACTIVE
// page being window view state rather than a business value.
package cjgui_rule_set_window_app

import cjgui.*
import std.unittest.*
import std.unittest.testmacro.*

// The window's scene contract is asynchronous: request a refresh, then pump the
// normal host turns until the accepted scene reaches the target. No test may
// treat the old synchronous `refresh()` return value as the acceptance fact.
//
// Cleanup closes the window, not the Host: Host.close() calls the
// process-global stopApplicationLoop, and a following native window in the same
// test process aborts the renderer bridge (runtime lifecycle defect in this
// frozen tree). No external connection is attached here.
private func pumpTabSceneAccepted(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    atLeast!: Int64 = 1): Bool {
    let _ = window.refresh()
    var turns: Int64 = 0
    while (turns < 128) {
        let progress = window.windowProgress()
        if (progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none") {
            return true
        }
        if (!host.isOpen()) {
            break
        }
        let _ = host.pumpOneTurn()
        turns += 1
    }
    let progress = window.windowProgress()
    return progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none"
}

private func pumpTabNextScene(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow): Bool {
    return pumpTabSceneAccepted(host, window, atLeast: window.windowProgress().acceptedSceneVersion + 1)
}

private class RuleDetailTabsController <: CjguiComposableUiController {
    let tabs: CjguiComposableUiTabsState
    private var revision: Int64 = 1

    init(tabs: CjguiComposableUiTabsState) {
        this.tabs = tabs
    }

    public func select(page: String): Bool {
        if (!tabs.select(page)) {
            return false
        }
        revision += 1
        return true
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let basic = cjguiComposableVertical(60, "rule-detail-basic", CjguiComposableUiStyle(gap: 8, growX: 1))
        basic.add(cjguiComposableTextInput(391, "draft-title", "标题", "草稿标题", -1,
            CjguiComposableUiStyle(fixedHeight: 30)))
        let retention = cjguiComposableVertical(61, "rule-detail-retention",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        retention.add(cjguiComposableTextInput(390, "file-path", "文件路径", "", -1,
            CjguiComposableUiStyle(fixedHeight: 30)))
        return ruleDetailTabWorkspace(tabs, basic, retention)
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

private func detailNode(window: CjguiComposableUiWindow, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

@Test
func ruleWindowDetailPaneIsAPublicTabWorkspace(): Unit {
    let tabs = CjguiComposableUiTabsState("basic")
    let controller = RuleDetailTabsController(tabs)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Detail tabs", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpTabSceneAccepted(host, window), true)

        // The container is really in the accepted scene, with both page titles.
        let container = detailNode(window, "rule-detail-tabs")
        @Assert(container.nodeId > 0, true)
        @Assert(container.isTabsContainer(), true)
        @Assert(detailNode(window, "rule-detail-tabs-titles").nodeId > 0, true)
        @Assert(detailNode(window, "rule-detail-tabs-tab-basic").nodeId > 0, true)
        @Assert(detailNode(window, "rule-detail-tabs-tab-retention").nodeId > 0, true)

        // "基本" is the declared initial page: its content is laid out, while the
        // other page keeps its identity with an EMPTY rect and no measured subtree.
        @Assert(detailNode(window, "rule-detail-basic").tabsPageActive, true)
        @Assert(detailNode(window, "draft-title").nodeId > 0, true)
        let hidden = detailNode(window, "rule-detail-retention")
        @Assert(hidden.nodeId > 0, true)
        @Assert(hidden.tabsPageActive, false)
        @Assert(hidden.bounds.height, 0)
        @Assert(detailNode(window, "file-path").nodeId, -1)

        // Switching the page moves WINDOW view state, and the next commit presents
        // the other page from the SAME container instance.
        @Assert(controller.select("retention"), true)
        @Assert(pumpTabNextScene(host, window), true)
        @Assert(detailNode(window, "file-path").nodeId > 0, true)
        @Assert(detailNode(window, "rule-detail-retention").tabsPageActive, true)
        @Assert(detailNode(window, "rule-detail-basic").bounds.height, 0)
        @Assert(detailNode(window, "rule-detail-tabs").nodeId, container.nodeId)
        // The hidden page's field identity survived the switch.
        @Assert(detailNode(window, "draft-title").nodeId, -1)
        @Assert(controller.select("basic"), true)
        @Assert(pumpTabNextScene(host, window), true)
        @Assert(detailNode(window, "draft-title").nodeId > 0, true)
    } finally {
        window.close()
    }
}
