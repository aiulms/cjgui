package cjgui_shared_multi_demo_harness_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoProofReporter}
import cjgui.demo_support.{CjguiExperimentalDemoRunResultReporter}
import cjgui.demo_support.{CjguiExperimentalDemoBusinessSnapshotReporter}

// 中文维护注释：这是独立 shared multi-demo harness demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证同一 harness 能服务 Todo 与 FileBrowser 两条业务流，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedMultiDemoHarnessState {
    let harnessName: String
    var servedDemoCount: Int64
    var servedDemos: String
    var actionCount: Int64
    var todoItemCount: Int64
    var todoFirstTitle: String
    var todoFirstDone: Bool
    var fileExpandedPath: String
    var fileSelectedPath: String
    var fileSelectedKind: String
    var fileDetailTitle: String
    var fileFilterText: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    var focusRoute: String
    var styleRoute: String

    init() {
        this.harnessName = "shared_multi_demo_harness"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "shared_multi_demo_harness",
            "todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list",
            "multi_demo_harness",
            "neutral_list",
            "",
            "todo_input"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "shared_multi_demo_harness",
            "todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("shared_multi_demo_harness")
        this.servedDemoCount = 0
        this.servedDemos = ""
        this.actionCount = 0
        this.todoItemCount = 0
        this.todoFirstTitle = "<none>"
        this.todoFirstDone = false
        this.fileExpandedPath = "/workspace"
        this.fileSelectedPath = "/workspace"
        this.fileSelectedKind = "folder"
        this.fileDetailTitle = "workspace"
        this.fileFilterText = ""
        this.focusRoute = "todo_input"
        this.styleRoute = "neutral_list"
    }

    private func appendServedDemo(name: String) {
        if (servedDemos == "") {
            servedDemos = name
        } else {
            servedDemos = "${servedDemos},${name}"
        }
        servedDemoCount += 1
    }

    private func appendAction() {
        actionCount += 1
    }

    private func appendFocus(target: String) {
        focusRoute = "${focusRoute}->${target}"
        componentSession.moveFocus(target)
    }

    private func appendStyle(style: String) {
        styleRoute = "${styleRoute}->${style}"
        componentSession.applyStyle(style)
    }

    func addTodo(title: String) {
        appendServedDemo("todo")
        appendAction()
        todoItemCount = 1
        todoFirstTitle = title
        todoFirstDone = false
        appendFocus("todo_first_item")
        appendStyle("todo_active_list")
        componentSession.recordComponentAction("todo_input", "shared_multi_demo_harness.todo_add", businessState())
    }

    func completeTodo() {
        appendAction()
        todoFirstDone = true
        appendFocus("todo_first_item")
        appendStyle("todo_completed_accent")
        componentSession.recordComponentAction("todo_item", "shared_multi_demo_harness.todo_complete", businessState())
    }

    func expandFileBrowser() {
        appendServedDemo("file_browser")
        appendAction()
        fileExpandedPath = "/workspace/src"
        appendFocus("file_tree")
        componentSession.recordComponentAction("file_tree", "shared_multi_demo_harness.file_expand", businessState())
    }

    func filterFiles(query: String) {
        appendAction()
        fileFilterText = query
        componentSession.typeInput(query)
        appendFocus("file_filter")
        componentSession.recordComponentAction("file_filter", "shared_multi_demo_harness.file_filter", businessState())
    }

    func selectFile(path: String, title: String) {
        appendAction()
        fileSelectedPath = path
        fileSelectedKind = "file"
        fileDetailTitle = title
        appendFocus("file_detail_pane")
        appendStyle("split_detail_accent")
        componentSession.recordComponentAction("file_row", "shared_multi_demo_harness.file_select", businessState())
    }

    func focusFileDetail() {
        appendAction()
        appendFocus("file_detail_pane")
        componentSession.recordComponentAction("file_detail_pane", "shared_multi_demo_harness.file_focus", businessState())
    }

    func businessState(): String {
        return "todo_items=${todoItemCount};todo_first=${todoFirstTitle};todo_done=${todoFirstDone};file_selected=${fileSelectedPath}:${fileSelectedKind};file_filter=${fileFilterText};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func domainSummary(): String {
        return "harness=${harnessName};served_count=${servedDemoCount};served=${servedDemos};actions=${actionCount};focus_route=${focusRoute};style_route=${styleRoute}"
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
    let harness = SharedMultiDemoHarnessState()
    let before = harness.businessState()
    harness.addTodo("Write shared multi-demo harness")
    harness.completeTodo()
    harness.expandFileBrowser()
    harness.filterFiles("main")
    harness.selectFile("/workspace/src/main.cj", "main.cj")
    harness.focusFileDetail()
    let after = harness.businessState()
    let stateReadbackOk = before == "todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list" &&
        after == "todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent" &&
        harness.servedDemoCount == 2 &&
        harness.servedDemos == "todo,file_browser" &&
        harness.actionCount == 6 &&
        harness.sharedUiState() == "layout=multi_demo_harness;style=split_detail_accent;input=main;focus=file_detail_pane" &&
        harness.sharedBefore() == before &&
        harness.sharedAfter() == after &&
        harness.sharedActions() == "shared_multi_demo_harness.todo_add,shared_multi_demo_harness.todo_complete,shared_multi_demo_harness.file_expand,shared_multi_demo_harness.file_filter,shared_multi_demo_harness.file_select,shared_multi_demo_harness.file_focus" &&
        harness.sharedWrites() == 6 &&
        harness.sharedComponentActions() == "todo_input:shared_multi_demo_harness.todo_add,todo_item:shared_multi_demo_harness.todo_complete,file_tree:shared_multi_demo_harness.file_expand,file_filter:shared_multi_demo_harness.file_filter,file_row:shared_multi_demo_harness.file_select,file_detail_pane:shared_multi_demo_harness.file_focus"
    let apiOutput = harness.buildSharedOutput(harness.domainSummary(), stateReadbackOk)
    let commitResult = harness.commitHarness.commitComponentAction(
        "file_detail_pane",
        "shared_multi_demo_harness.commit_multi_flow",
        after
    )
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "shared_multi_demo_harness" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_multi_demo_harness.todo_add,shared_multi_demo_harness.todo_complete,shared_multi_demo_harness.file_expand,shared_multi_demo_harness.file_filter,shared_multi_demo_harness.file_select,shared_multi_demo_harness.file_focus" &&
        apiOutput.writeCount == 6 &&
        apiOutput.domainSummary == harness.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_multi_demo_harness;readback=true;writes=6;actions=shared_multi_demo_harness.todo_add,shared_multi_demo_harness.todo_complete,shared_multi_demo_harness.file_expand,shared_multi_demo_harness.file_filter,shared_multi_demo_harness.file_select,shared_multi_demo_harness.file_focus;before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list;after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent;summary=harness=shared_multi_demo_harness;served_count=2;served=todo,file_browser;actions=6;focus_route=todo_input->todo_first_item->todo_first_item->file_tree->file_filter->file_detail_pane->file_detail_pane;style_route=neutral_list->todo_active_list->todo_completed_accent->split_detail_accent" &&
        harness.commitHarness.resultMatches(
            commitResult,
            "file_detail_pane",
            "shared_multi_demo_harness.commit_multi_flow",
            before,
            after
        )
    let runResult = harness.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        harness.componentSession,
        commitResult,
        commitReadbackOk
    )
    let runReporter = CjguiExperimentalDemoRunResultReporter("cjgui shared multi-demo harness app")
    let proofReporter = CjguiExperimentalDemoProofReporter("cjgui shared multi-demo harness app")
    let businessReporter = CjguiExperimentalDemoBusinessSnapshotReporter("cjgui shared multi-demo harness app")
    let outputOk = commitReadbackOk && runResult.runnable

    println("cjgui shared multi-demo harness app: demo=shared_multi_demo_harness")
    businessReporter.printStatusTransition("not_started", "runnable")
    businessReporter.printTextFact("served_demos", "todo,file_browser")
    businessReporter.printTextFact("served_demo_count", "2")
    businessReporter.printTextFact("interaction", "run_todo_add_complete,run_file_browser_select")
    businessReporter.printTextFact("state_before", before)
    businessReporter.printTextFact("state_after", after)
    businessReporter.printBoolFact("state_readback", outputOk)
    proofReporter.printSharedPrimitiveProof(apiOutput, harness.componentSession, commitResult, harness.commitHarness)
    runReporter.printRunResult(runResult)

    if (outputOk) {
        return 0
    }
    return 1
}
