package cjgui_file_browser_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}
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
    let layoutKind: String
    private var entries = ArrayList<FileBrowserEntry>()
    var selectedPath: String
    var selectedKind: String
    var detailTitle: String
    var detailPreview: String
    var expandedPath: String
    var focusedPane: String
    var filterText: String

    init() {
        this.demoName = "file_browser"
        this.layoutKind = "tree_detail_split"
        this.selectedPath = "/workspace"
        this.selectedKind = "folder"
        this.detailTitle = "workspace"
        this.detailPreview = "3 items"
        this.expandedPath = "/workspace"
        this.focusedPane = "tree"
        this.filterText = ""
        entries.add(FileBrowserEntry("/workspace", "workspace", "folder"))
        entries.add(FileBrowserEntry("/workspace/src", "src", "folder"))
        entries.add(FileBrowserEntry("/workspace/src/main.cj", "main.cj", "file"))
    }

    func expand(path: String) {
        expandedPath = path
        focusedPane = "tree"
    }

    func applyFilter(query: String) {
        filterText = query
        focusedPane = "tree_filter"
    }

    func selectEntry(path: String, kind: String) {
        selectedPath = path
        selectedKind = kind
        focusedPane = "tree"
    }

    func refreshDetail(title: String, preview: String) {
        detailTitle = title
        detailPreview = preview
        focusedPane = "detail_pane"
    }

    func moveFocus(target: String) {
        focusedPane = target
    }

    func itemCount(): Int64 {
        return entries.size
    }

    func businessState(): String {
        return "items=${entries.size};expanded=${expandedPath};selected=${selectedPath}:${selectedKind};detail=${detailTitle};filter=${filterText};focus=${focusedPane}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${layoutKind};${businessState()}"
    }
}

main(): Int64 {
    let browser = FileBrowserState()
    let before = browser.businessState()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("file_browser", before)
    browser.expand("/workspace/src")
    sharedTrace.recordAction("file_browser.expand_folder", browser.businessState())
    browser.applyFilter("main")
    sharedTrace.recordAction("file_browser.filter_entries", browser.businessState())
    browser.selectEntry("/workspace/src/main.cj", "file")
    sharedTrace.recordAction("file_browser.select_file", browser.businessState())
    browser.refreshDetail("main.cj", "package cjgui_file_browser_demo")
    sharedTrace.recordAction("file_browser.refresh_detail", browser.businessState())
    browser.moveFocus("detail_pane")
    let after = browser.businessState()
    sharedTrace.recordAction("file_browser.move_focus", after)
    let summary = browser.summary()
    let stateReadbackOk = before == "items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree" &&
        after == "items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane" &&
        browser.itemCount() == 3 &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus" &&
        sharedTrace.writes() == 5 &&
        summary == "demo=file_browser;layout=tree_detail_split;items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, summary, stateReadbackOk)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "file_browser" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=file_browser;readback=true;writes=5;actions=file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus;before=items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree;after=items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane;summary=demo=file_browser;layout=tree_detail_split;items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"

    println("cjgui file browser demo app: demo=file_browser")
    println("cjgui file browser demo app: status_before=not_started")
    println("cjgui file browser demo app: status_after=runnable")
    println("cjgui file browser demo app: layout=tree_detail_split")
    println("cjgui file browser demo app: interaction=expand_folder,filter_entries,select_file,refresh_detail,move_focus")
    println("cjgui file browser demo app: state_before=${before}")
    println("cjgui file browser demo app: state_after=${after}")
    println("cjgui file browser demo app: state_readback=${readbackOk}")
    println("cjgui file browser demo app: public_api_consumed=true")
    println("cjgui file browser demo app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui file browser demo app: public_api_output=${apiOutput.summary}")
    println("cjgui file browser demo app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui file browser demo app: shared_support_output=${sharedTrace.summary()}")

    if (readbackOk) {
        return 0
    }
    return 1
}
