package cjgui_shared_demo_harness_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder, CjguiExperimentalDemoUiStateCore}
import std.collection.*

// 中文维护注释：这是独立 shared demo harness demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能立即服务一个 Todo 业务流，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedDemoHarnessState {
    let harnessName: String
    let servedDemo: String
    private var actions = ArrayList<String>()
    let uiState: CjguiExperimentalDemoUiStateCore
    var itemCount: Int64
    var firstTitle: String
    var firstDone: Bool

    init() {
        this.harnessName = "shared_demo_harness"
        this.servedDemo = "todo"
        this.uiState = CjguiExperimentalDemoUiStateCore("todo_list", "neutral_list", "", "todo_input")
        this.itemCount = 0
        this.firstTitle = "<none>"
        this.firstDone = false
    }

    func addTodo(title: String) {
        actions.add("add_todo")
        itemCount = 1
        firstTitle = title
        firstDone = false
        uiState.typeInput(title)
        uiState.moveFocus("todo_first_item")
        uiState.applyStyle("active_list")
    }

    func completeTodo() {
        actions.add("complete_todo")
        firstDone = true
        uiState.moveFocus("todo_first_item")
        uiState.applyStyle("completed_accent")
    }

    func actionCount(): Int64 {
        return actions.size
    }

    func businessState(): String {
        return "items=${itemCount};first=${firstTitle};first_done=${firstDone};focus=${uiState.focus()};style=${uiState.style()}"
    }

    func domainSummary(): String {
        return "harness=${harnessName};served=${servedDemo};actions=${actions.size};focus=${uiState.focus()};style=${uiState.style()}"
    }

    func sharedUiState(): String {
        return uiState.summary()
    }
}

main(): Int64 {
    let harness = SharedDemoHarnessState()
    let before = harness.businessState()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("shared_demo_harness", before)
    harness.addTodo("Write shared CJGUI harness")
    sharedTrace.recordAction("shared_demo_harness.add_todo", harness.businessState())
    harness.completeTodo()
    let after = harness.businessState()
    sharedTrace.recordAction("shared_demo_harness.complete_todo", after)
    let stateReadbackOk = before == "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list" &&
        after == "items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent" &&
        harness.sharedUiState() == "layout=todo_list;style=completed_accent;input=Write shared CJGUI harness;focus=todo_first_item" &&
        harness.actionCount() == 2 &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        sharedTrace.writes() == 2
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, harness.domainSummary(), stateReadbackOk)
    let outputOk = stateReadbackOk &&
        apiOutput.demoName == "shared_demo_harness" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        apiOutput.writeCount == 2 &&
        apiOutput.domainSummary == harness.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_demo_harness;readback=true;writes=2;actions=shared_demo_harness.add_todo,shared_demo_harness.complete_todo;before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list;after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent;summary=harness=shared_demo_harness;served=todo;actions=2;focus=todo_first_item;style=completed_accent"

    println("cjgui shared demo harness app: demo=shared_demo_harness")
    println("cjgui shared demo harness app: status_before=not_started")
    println("cjgui shared demo harness app: status_after=runnable")
    println("cjgui shared demo harness app: served_demo=todo")
    println("cjgui shared demo harness app: interaction=run_todo_add_complete")
    println("cjgui shared demo harness app: state_before=${before}")
    println("cjgui shared demo harness app: state_after=${after}")
    println("cjgui shared demo harness app: state_readback=${outputOk}")
    println("cjgui shared demo harness app: public_api_consumed=true")
    println("cjgui shared demo harness app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui shared demo harness app: public_api_output=${apiOutput.summary}")
    println("cjgui shared demo harness app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui shared demo harness app: shared_support_output=${sharedTrace.summary()}")
    println("cjgui shared demo harness app: shared_state_core=${harness.sharedUiState()}")

    if (outputOk) {
        return 0
    }
    return 1
}
