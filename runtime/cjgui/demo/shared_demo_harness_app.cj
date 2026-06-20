package cjgui_shared_demo_harness_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness, CjguiExperimentalDemoCommitResult}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness, CjguiExperimentalDemoRunResult}
import std.collection.*

// 中文维护注释：这是独立 shared demo harness demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能立即服务一个 Todo 业务流，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedDemoHarnessState {
    let harnessName: String
    let servedDemo: String
    private var actions = ArrayList<String>()
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    var itemCount: Int64
    var firstTitle: String
    var firstDone: Bool

    init() {
        this.harnessName = "shared_demo_harness"
        this.servedDemo = "todo"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "shared_demo_harness",
            "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list",
            "todo_list",
            "neutral_list",
            "",
            "todo_input"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "shared_demo_harness",
            "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("shared_demo_harness")
        this.itemCount = 0
        this.firstTitle = "<none>"
        this.firstDone = false
    }

    func addTodo(title: String) {
        actions.add("add_todo")
        itemCount = 1
        firstTitle = title
        firstDone = false
        componentSession.typeInput(title)
        componentSession.moveFocus("todo_first_item")
        componentSession.applyStyle("active_list")
        componentSession.recordComponentAction("todo_input", "shared_demo_harness.add_todo", businessState())
    }

    func completeTodo() {
        actions.add("complete_todo")
        firstDone = true
        componentSession.moveFocus("todo_first_item")
        componentSession.applyStyle("completed_accent")
        componentSession.recordComponentAction("todo_item", "shared_demo_harness.complete_todo", businessState())
    }

    func actionCount(): Int64 {
        return actions.size
    }

    func businessState(): String {
        return "items=${itemCount};first=${firstTitle};first_done=${firstDone};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func domainSummary(): String {
        return "harness=${harnessName};served=${servedDemo};actions=${actions.size};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func sharedUiState(): String {
        return componentSession.uiStateSummary()
    }

    func sharedSupportOutput(): String {
        return componentSession.traceSummary()
    }

    func sharedComponentActions(): String {
        return componentSession.componentActions()
    }

    func sharedComponentActionSummary(): String {
        return componentSession.componentActionSummary()
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

    func buildRunResult(
        statusBefore: String,
        statusAfter: String,
        output: CjguiExperimentalDemoOutput,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitReadbackOk: Bool
    ): CjguiExperimentalDemoRunResult {
        return runHarness.finishRun(
            statusBefore,
            statusAfter,
            output,
            sharedComponentActionSummary(),
            sharedUiState(),
            commitResult,
            commitReadbackOk
        )
    }

}

main(): Int64 {
    let harness = SharedDemoHarnessState()
    let before = harness.businessState()
    harness.addTodo("Write shared CJGUI harness")
    harness.completeTodo()
    let after = harness.businessState()
    let stateReadbackOk = before == "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list" &&
        after == "items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent" &&
        harness.sharedUiState() == "layout=todo_list;style=completed_accent;input=Write shared CJGUI harness;focus=todo_first_item" &&
        harness.actionCount() == 2 &&
        harness.sharedBefore() == before &&
        harness.sharedAfter() == after &&
        harness.sharedActions() == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        harness.sharedWrites() == 2 &&
        harness.sharedComponentActions() == "todo_input:shared_demo_harness.add_todo,todo_item:shared_demo_harness.complete_todo"
    let apiOutput = harness.buildSharedOutput(harness.domainSummary(), stateReadbackOk)
    let commitResult = harness.commitHarness.commitComponentAction(
        "todo_item",
        "shared_demo_harness.commit_todo_flow",
        after
    )
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "shared_demo_harness" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        apiOutput.writeCount == 2 &&
        apiOutput.domainSummary == harness.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_demo_harness;readback=true;writes=2;actions=shared_demo_harness.add_todo,shared_demo_harness.complete_todo;before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list;after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent;summary=harness=shared_demo_harness;served=todo;actions=2;focus=todo_first_item;style=completed_accent" &&
        harness.commitHarness.resultMatches(
            commitResult,
            "todo_item",
            "shared_demo_harness.commit_todo_flow",
            before,
            after
        )
    let runResult = harness.buildRunResult("not_started", "runnable", apiOutput, commitResult, commitReadbackOk)
    let outputOk = commitReadbackOk && runResult.runnable

    println("cjgui shared demo harness app: demo=shared_demo_harness")
    println("cjgui shared demo harness app: status_before=not_started")
    println("cjgui shared demo harness app: status_after=runnable")
    println("cjgui shared demo harness app: served_demo=todo")
    println("cjgui shared demo harness app: interaction=run_todo_add_complete")
    println("cjgui shared demo harness app: state_before=${before}")
    println("cjgui shared demo harness app: state_after=${after}")
    println("cjgui shared demo harness app: state_readback=${outputOk}")
    println("cjgui shared demo harness app: public_api_consumed=true")
    println("cjgui shared demo harness app: public_api_name=CjguiExperimentalDemoComponentActionSession")
    println("cjgui shared demo harness app: public_api_output=${apiOutput.summary}")
    println("cjgui shared demo harness app: shared_support=CjguiExperimentalDemoComponentActionSession")
    println("cjgui shared demo harness app: shared_support_output=${harness.sharedSupportOutput()}")
    println("cjgui shared demo harness app: shared_state_core=${harness.sharedUiState()}")
    println("cjgui shared demo harness app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession")
    println("cjgui shared demo harness app: shared_component_action_output=${harness.sharedComponentActionSummary()}")
    println("cjgui shared demo harness app: shared_commit_harness=CjguiExperimentalDemoCommitHarness")
    println("cjgui shared demo harness app: shared_commit_output=${commitResult.summary}")
    println("cjgui shared demo harness app: shared_commit_readback=${harness.commitHarness.readback()}")
    println("cjgui shared demo harness app: shared_commit_rollback_boundary=${harness.commitHarness.rollbackBoundary()}")
    println("cjgui shared demo harness app: shared_commit_not_published=${commitResult.notPublished}")
    println("cjgui shared demo harness app: shared_run_harness=CjguiExperimentalDemoRunHarness")
    println("cjgui shared demo harness app: shared_run_result=${runResult.summary}")
    println("cjgui shared demo harness app: shared_run_readback=${runResult.runnable}")
    println("cjgui shared demo harness app: shared_run_not_published=${runResult.notPublished}")

    if (outputOk) {
        return 0
    }
    return 1
}
