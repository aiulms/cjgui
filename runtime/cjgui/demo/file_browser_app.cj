package cjgui_file_browser_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import std.collection.*

// 中文维护注释：这是独立 FileBrowser demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 FileBrowser 消费 CJGUI experimental 非 Bool public API，并执行 owner-local 树展开/选择/详情/焦点写入读回。
// Stop-line: 只做 demo-host in-memory 状态，不访问真实文件系统，不调用 native bridge，不提交 renderer。

class FileBrowserEntry {
    let path: String
    let name: String
    let kind: String

    init(path: String, name: String, kind: String) {
        this.path = path
        this.name = name
        this.kind = kind
    }
}

class FileBrowserState {
    let demoName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    private var entries = ArrayList<FileBrowserEntry>()
    var selectedPath: String
    var selectedKind: String
    var detailTitle: String
    var detailPreview: String
    var expandedPath: String

    init() {
        this.demoName = "file_browser"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "file_browser",
            "items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree",
            "tree_detail_split",
            "tree_detail",
            "",
            "tree"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "file_browser",
            "items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("file_browser")
        this.selectedPath = "/workspace"
        this.selectedKind = "folder"
        this.detailTitle = "workspace"
        this.detailPreview = "3 items"
        this.expandedPath = "/workspace"
        entries.add(FileBrowserEntry("/workspace", "workspace", "folder"))
        entries.add(FileBrowserEntry("/workspace/src", "src", "folder"))
        entries.add(FileBrowserEntry("/workspace/src/main.cj", "main.cj", "file"))
    }

    func expand(path: String) {
        expandedPath = path
        componentSession.applyStyle("folder_expanded")
        componentSession.moveFocus("tree")
        componentSession.recordComponentAction("folder_tree", "file_browser.expand_folder", businessState())
    }

    func applyFilter(query: String) {
        componentSession.typeInput(query)
        componentSession.applyStyle("filter_active")
        componentSession.moveFocus("tree_filter")
        componentSession.recordComponentAction("tree_filter", "file_browser.filter_entries", businessState())
    }

    func selectEntry(path: String, kind: String) {
        selectedPath = path
        selectedKind = kind
        componentSession.applyStyle("file_selected")
        componentSession.moveFocus("tree")
        componentSession.recordComponentAction("file_row", "file_browser.select_file", businessState())
    }

    func refreshDetail(title: String, preview: String) {
        detailTitle = title
        detailPreview = preview
        componentSession.applyStyle("detail_ready")
        componentSession.moveFocus("detail_pane")
        componentSession.recordComponentAction("detail_pane", "file_browser.refresh_detail", businessState())
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentAction(target, "file_browser.move_focus", businessState())
    }

    func itemCount(): Int64 {
        return entries.size
    }

    func businessState(): String {
        return "items=${entries.size};expanded=${expandedPath};selected=${selectedPath}:${selectedKind};detail=${detailTitle};filter=${componentSession.textInput()};focus=${componentSession.focus()}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${componentSession.layout()};${businessState()}"
    }

    func sharedUiState(): String {
        return componentSession.uiStateSummary()
    }

    func sharedComponentActions(): String {
        return componentSession.componentActions()
    }

    func sharedActions(): String {
        return componentSession.actions()
    }

    func sharedWrites(): Int64 {
        return componentSession.writes()
    }

    func sharedBefore(): String {
        return componentSession.before()
    }

    func sharedAfter(): String {
        return componentSession.after()
    }

    func buildSharedOutput(domainSummary: String, readbackOk: Bool): CjguiExperimentalDemoOutput {
        return componentSession.buildOutput(domainSummary, readbackOk)
    }


}

main(): Int64 {
    let browser = FileBrowserState()
    let before = browser.businessState()
    browser.expand("/workspace/src")
    browser.applyFilter("main")
    browser.selectEntry("/workspace/src/main.cj", "file")
    browser.refreshDetail("main.cj", "package cjgui_file_browser_demo")
    browser.moveFocus("detail_pane")
    let after = browser.businessState()
    let summary = browser.summary()
    let stateReadbackOk = before == "items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree" &&
        after == "items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane" &&
        browser.itemCount() == 3 &&
        browser.sharedBefore() == before &&
        browser.sharedAfter() == after &&
        browser.sharedActions() == "file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus" &&
        browser.sharedWrites() == 5 &&
        browser.sharedComponentActions() == "folder_tree:file_browser.expand_folder,tree_filter:file_browser.filter_entries,file_row:file_browser.select_file,detail_pane:file_browser.refresh_detail,detail_pane:file_browser.move_focus" &&
        browser.sharedUiState() == "layout=tree_detail_split;style=detail_ready;input=main;focus=detail_pane" &&
        summary == "demo=file_browser;layout=tree_detail_split;items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"
    let apiOutput = browser.buildSharedOutput(summary, stateReadbackOk)
    let commitResult = browser.commitHarness.commitComponentAction("detail_pane", "file_browser.commit_detail", after)
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "file_browser" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=file_browser;readback=true;writes=5;actions=file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus;before=items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree;after=items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane;summary=demo=file_browser;layout=tree_detail_split;items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane" &&
        browser.commitHarness.resultMatches(commitResult, "detail_pane", "file_browser.commit_detail", before, after)
    let runResult = browser.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        browser.componentSession,
        commitResult,
        commitReadbackOk
    )
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui file browser demo app")
    let readbackOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder("file_browser", "not_started", "runnable")
    evidenceBuilder.addLayoutFact("tree_detail_split")
    evidenceBuilder.addInteractionFact("expand_folder,filter_entries,select_file,refresh_detail,move_focus")
    evidenceBuilder.addStateReadbackFacts(before, after, readbackOk)

    let evidenceSection = evidenceBuilder.buildSection(
        apiOutput,
        browser.componentSession,
        commitResult,
        browser.commitHarness,
        runResult
    )
    evidencePresenter.printEvidenceSection(evidenceSection)

    if (readbackOk) {
        return 0
    }
    return 1
}
