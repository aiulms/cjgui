package cjgui_todo_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoComponentActionRouteCatalog}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import cjgui.demo_support.{CjguiExperimentalDemoComponentInteractionEvidence}
import cjgui.demo_support.{CjguiExperimentalDemoOwnerLocalWriteReadbackEvidence}
import std.collection.*

// 中文维护注释：这是独立 Todo demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 Todo 消费 CJGUI experimental 非 Bool public API，并保留 owner-local 状态写入读回。
// Stop-line: 不写 runtime_state / renderer_state，不调用 native bridge，不提交 renderer。

class TodoDemoItem {
    let id: Int64
    let title: String
    var isDone: Bool

    init(id: Int64, title: String, isDone: Bool) {
        this.id = id
        this.title = title
        this.isDone = isDone
    }
}

class TodoList {
    private var nextId: Int64 = 1
    private var items = ArrayList<TodoDemoItem>()
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let routeCatalog: CjguiExperimentalDemoComponentActionRouteCatalog
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness

    init() {
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "todo",
            "items=0;first=<none>;first_done=false",
            "todo_list",
            "neutral_list",
            "",
            "todo_input"
        )
        this.routeCatalog = CjguiExperimentalDemoComponentActionRouteCatalog()
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "todo",
            "items=0;first=<none>;first_done=false"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("todo")
    }

    func add(title: String): Int64 {
        let id = nextId
        nextId += 1
        items.add(TodoDemoItem(id, title, false))
        componentSession.typeInput(title)
        componentSession.moveFocus("todo_first_item")
        componentSession.applyStyle("active_list")
        componentSession.recordComponentActionRoute(
            routeCatalog.todoAdd(),
            summary()
        )
        return id
    }

    func complete(id: Int64): Bool {
        for (item in items) {
            if (item.id == id) {
                item.isDone = true
                componentSession.moveFocus("todo_first_item")
                componentSession.applyStyle("completed_accent")
                componentSession.recordComponentActionRoute(
                    routeCatalog.todoComplete(),
                    summary()
                )
                return true
            }
        }
        return false
    }

    func count(): Int64 {
        return items.size
    }

    func firstTitle(): String {
        if (items.size == 0) {
            return "<none>"
        }
        return items[0].title
    }

    func firstDone(): Bool {
        if (items.size == 0) {
            return false
        }
        return items[0].isDone
    }

    func summary(): String {
        if (items.size == 0) {
            return "items=0;first=<none>;first_done=false"
        }
        return "items=${items.size};first=${items[0].title};first_done=${items[0].isDone}"
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
    let todos = TodoList()
    let before = todos.summary()
    let createdId = todos.add("Write first CJGUI todo")
    let afterAdd = todos.summary()
    let completed = todos.complete(createdId)
    let afterComplete = todos.summary()
    let stateReadbackOk = before == "items=0;first=<none>;first_done=false" &&
        afterAdd == "items=1;first=Write first CJGUI todo;first_done=false" &&
        afterComplete == "items=1;first=Write first CJGUI todo;first_done=true" &&
        todos.sharedBefore() == before &&
        todos.sharedAfter() == afterComplete &&
        todos.sharedActions() == "todo.add,todo.complete" &&
        todos.sharedWrites() == 2 &&
        todos.sharedComponentActions() == "todo_input:todo.add,todo_item:todo.complete" &&
        todos.count() == 1 &&
        todos.firstTitle() == "Write first CJGUI todo" &&
        todos.firstDone() &&
        todos.sharedUiState() == "layout=todo_list;style=completed_accent;input=Write first CJGUI todo;focus=todo_first_item" &&
        completed
    let apiOutput = todos.buildSharedOutput(afterComplete, stateReadbackOk)
    let commitResult = todos.commitHarness.commitComponentAction("todo_item", "todo.commit_complete", afterComplete)
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "todo" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == afterComplete &&
        apiOutput.actionTrace == "todo.add,todo.complete" &&
        apiOutput.writeCount == 2 &&
        apiOutput.domainSummary == afterComplete &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=todo;readback=true;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true;summary=items=1;first=Write first CJGUI todo;first_done=true" &&
        todos.commitHarness.resultMatches(commitResult, "todo_item", "todo.commit_complete", before, afterComplete)
    let runResult = todos.runHarness.finishCommittedSessionRun(
        "state_writable",
        "runnable",
        apiOutput,
        todos.componentSession,
        commitResult,
        commitReadbackOk
    )
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui todo demo app")
    let readbackOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder("todo", "state_writable", "runnable")
    evidenceBuilder.addInteractionEvidence(CjguiExperimentalDemoComponentInteractionEvidence("add_todo,complete_todo"))
    evidenceBuilder.addOwnerLocalWriteReadbackEvidence(
        CjguiExperimentalDemoOwnerLocalWriteReadbackEvidence(before, afterAdd, afterComplete, readbackOk)
    )

    let evidenceSection = evidenceBuilder.buildSection(
        apiOutput,
        todos.componentSession,
        commitResult,
        todos.commitHarness,
        runResult
    )
    evidencePresenter.printEvidenceSection(evidenceSection)

    if (readbackOk) {
        return 0
    }
    return 1
}
