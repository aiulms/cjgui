package cjgui_shared_multi_demo_harness_demo

import cjgui.*

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
    var focusTarget: String
    var styleToken: String
    var interactionTrace: String
    var focusRoute: String
    var styleRoute: String

    init() {
        this.harnessName = "shared_multi_demo_harness"
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
        this.focusTarget = "todo_input"
        this.styleToken = "neutral_list"
        this.interactionTrace = "idle"
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

    private func appendAction(name: String) {
        if (interactionTrace == "idle") {
            interactionTrace = name
        } else {
            interactionTrace = "${interactionTrace},${name}"
        }
        actionCount += 1
    }

    private func appendFocus(target: String) {
        focusRoute = "${focusRoute}->${target}"
        focusTarget = target
    }

    private func appendStyle(style: String) {
        styleRoute = "${styleRoute}->${style}"
        styleToken = style
    }

    func runTodoAddComplete(title: String) {
        appendServedDemo("todo")
        appendAction("todo_add")
        todoItemCount = 1
        todoFirstTitle = title
        todoFirstDone = false
        appendFocus("todo_first_item")
        appendStyle("todo_active_list")

        appendAction("todo_complete")
        todoFirstDone = true
        appendFocus("todo_first_item")
        appendStyle("todo_completed_accent")
    }

    func runFileBrowserSelect(query: String, path: String, title: String) {
        appendServedDemo("file_browser")
        appendAction("file_expand")
        fileExpandedPath = "/workspace/src"
        appendFocus("file_tree")

        appendAction("file_filter")
        fileFilterText = query
        appendFocus("file_filter")

        appendAction("file_select")
        fileSelectedPath = path
        fileSelectedKind = "file"
        fileDetailTitle = title
        appendFocus("file_detail_pane")
        appendStyle("split_detail_accent")

        appendAction("file_focus")
        appendFocus("file_detail_pane")
    }

    func businessState(): String {
        return "todo_items=${todoItemCount};todo_first=${todoFirstTitle};todo_done=${todoFirstDone};file_selected=${fileSelectedPath}:${fileSelectedKind};file_filter=${fileFilterText};focus=${focusTarget};style=${styleToken}"
    }

    func buildHarnessOutput(
        beforeState: String,
        afterState: String,
        readbackOk: Bool
    ): CjguiExperimentalSharedMultiDemoHarnessOutput {
        return cjguiExperimentalBuildSharedMultiDemoHarnessOutput(
            servedDemoCount,
            servedDemos,
            actionCount,
            beforeState,
            afterState,
            interactionTrace,
            focusRoute,
            styleRoute,
            readbackOk
        )
    }
}

main(): Int64 {
    let harness = SharedMultiDemoHarnessState()
    let before = harness.businessState()
    harness.runTodoAddComplete("Write shared multi-demo harness")
    harness.runFileBrowserSelect("main", "/workspace/src/main.cj", "main.cj")
    let after = harness.businessState()
    let readbackOk = before == "todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list" &&
        after == "todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent" &&
        harness.servedDemoCount == 2 &&
        harness.servedDemos == "todo,file_browser" &&
        harness.actionCount == 6 &&
        harness.interactionTrace == "todo_add,todo_complete,file_expand,file_filter,file_select,file_focus"
    let apiOutput = harness.buildHarnessOutput(before, after, readbackOk)
    let outputOk = readbackOk &&
        apiOutput.harnessName == "shared_multi_demo_harness" &&
        apiOutput.servedDemoCount == 2 &&
        apiOutput.servedDemos == "todo,file_browser" &&
        apiOutput.actionCount == 6 &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.interactionTrace == "todo_add,todo_complete,file_expand,file_filter,file_select,file_focus" &&
        apiOutput.focusRoute == "todo_input->todo_first_item->todo_first_item->file_tree->file_filter->file_detail_pane->file_detail_pane" &&
        apiOutput.styleRoute == "neutral_list->todo_active_list->todo_completed_accent->split_detail_accent" &&
        apiOutput.readbackOk &&
        apiOutput.summary == "harness=shared_multi_demo_harness;served_count=2;served=todo,file_browser;actions=6;before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list;after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent;interaction=todo_add,todo_complete,file_expand,file_filter,file_select,file_focus;focus_route=todo_input->todo_first_item->todo_first_item->file_tree->file_filter->file_detail_pane->file_detail_pane;style_route=neutral_list->todo_active_list->todo_completed_accent->split_detail_accent;readback=true"

    println("cjgui shared multi-demo harness app: demo=shared_multi_demo_harness")
    println("cjgui shared multi-demo harness app: status_before=not_started")
    println("cjgui shared multi-demo harness app: status_after=runnable")
    println("cjgui shared multi-demo harness app: served_demos=todo,file_browser")
    println("cjgui shared multi-demo harness app: served_demo_count=2")
    println("cjgui shared multi-demo harness app: interaction=run_todo_add_complete,run_file_browser_select")
    println("cjgui shared multi-demo harness app: state_before=${before}")
    println("cjgui shared multi-demo harness app: state_after=${after}")
    println("cjgui shared multi-demo harness app: state_readback=${readbackOk}")
    println("cjgui shared multi-demo harness app: public_api_consumed=true")
    println("cjgui shared multi-demo harness app: public_api_name=cjguiExperimentalBuildSharedMultiDemoHarnessOutput")
    println("cjgui shared multi-demo harness app: public_api_output=${apiOutput.summary}")

    if (outputOk) {
        return 0
    }
    return 1
}
