package cjgui_file_browser_demo

import cjgui.*
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

    func selectEntry(path: String, kind: String, title: String, preview: String) {
        selectedPath = path
        selectedKind = kind
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

    func buildApiOutput(): CjguiExperimentalFileBrowserDemoOutput {
        return cjguiExperimentalBuildFileBrowserDemoOutput(
            entries.size,
            selectedPath,
            selectedKind,
            detailTitle,
            filterText,
            focusedPane,
            expandedPath,
            layoutKind
        )
    }
}

main(): Int64 {
    let browser = FileBrowserState()
    let before = browser.businessState()
    browser.expand("/workspace/src")
    browser.applyFilter("main")
    browser.selectEntry("/workspace/src/main.cj", "file", "main.cj", "package cjgui_file_browser_demo")
    browser.moveFocus("detail_pane")
    let after = browser.businessState()
    let apiOutput = browser.buildApiOutput()
    let readbackOk = before == "items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree" &&
        after == "items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane" &&
        browser.itemCount() == 3 &&
        apiOutput.demoName == "file_browser" &&
        apiOutput.itemCount == 3 &&
        apiOutput.selectedPath == "/workspace/src/main.cj" &&
        apiOutput.selectedKind == "file" &&
        apiOutput.detailTitle == "main.cj" &&
        apiOutput.filterText == "main" &&
        apiOutput.focusedPane == "detail_pane" &&
        apiOutput.expandedPath == "/workspace/src" &&
        apiOutput.layoutKind == "tree_detail_split" &&
        apiOutput.summary == "items=3;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane;expanded=/workspace/src;layout=tree_detail_split"

    println("cjgui file browser demo app: demo=file_browser")
    println("cjgui file browser demo app: status_before=not_started")
    println("cjgui file browser demo app: status_after=runnable")
    println("cjgui file browser demo app: layout=tree_detail_split")
    println("cjgui file browser demo app: interaction=expand_folder,filter_entries,select_file,refresh_detail,move_focus")
    println("cjgui file browser demo app: state_before=${before}")
    println("cjgui file browser demo app: state_after=${after}")
    println("cjgui file browser demo app: state_readback=${readbackOk}")
    println("cjgui file browser demo app: public_api_consumed=true")
    println("cjgui file browser demo app: public_api_name=cjguiExperimentalBuildFileBrowserDemoOutput")
    println("cjgui file browser demo app: public_api_output=${apiOutput.summary}")

    if (readbackOk) {
        return 0
    }
    return 1
}
