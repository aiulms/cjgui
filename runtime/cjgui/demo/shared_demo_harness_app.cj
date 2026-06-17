package cjgui_shared_demo_harness_demo

import cjgui.*
import std.collection.*

// 中文维护注释：这是独立 shared demo harness demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能立即服务一个 Todo 业务流，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedDemoHarnessState {
    let harnessName: String
    let servedDemo: String
    private var actions = ArrayList<String>()
    var itemCount: Int64
    var firstTitle: String
    var firstDone: Bool
    var focusTarget: String
    var styleToken: String
    var interactionTrace: String

    init() {
        this.harnessName = "shared_demo_harness"
        this.servedDemo = "todo"
        this.itemCount = 0
        this.firstTitle = "<none>"
        this.firstDone = false
        this.focusTarget = "todo_input"
        this.styleToken = "neutral_list"
        this.interactionTrace = "idle"
    }

    func runTodoAddComplete(title: String) {
        actions.add("add_todo")
        itemCount = 1
        firstTitle = title
        firstDone = false
        focusTarget = "todo_first_item"
        styleToken = "active_list"

        actions.add("complete_todo")
        firstDone = true
        focusTarget = "todo_first_item"
        styleToken = "completed_accent"
        interactionTrace = "add_todo,complete_todo"
    }

    func actionCount(): Int64 {
        return actions.size
    }

    func businessState(): String {
        return "items=${itemCount};first=${firstTitle};first_done=${firstDone};focus=${focusTarget};style=${styleToken}"
    }

    func buildHarnessOutput(
        beforeState: String,
        afterState: String,
        readbackOk: Bool
    ): CjguiExperimentalSharedDemoHarnessOutput {
        return cjguiExperimentalBuildSharedDemoHarnessOutput(
            servedDemo,
            actions.size,
            beforeState,
            afterState,
            interactionTrace,
            focusTarget,
            styleToken,
            readbackOk
        )
    }
}

main(): Int64 {
    let harness = SharedDemoHarnessState()
    let before = harness.businessState()
    harness.runTodoAddComplete("Write shared CJGUI harness")
    let after = harness.businessState()
    let readbackOk = before == "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list" &&
        after == "items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent" &&
        harness.actionCount() == 2
    let apiOutput = harness.buildHarnessOutput(before, after, readbackOk)
    let outputOk = readbackOk &&
        apiOutput.harnessName == "shared_demo_harness" &&
        apiOutput.servedDemo == "todo" &&
        apiOutput.actionCount == 2 &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.interactionTrace == "add_todo,complete_todo" &&
        apiOutput.focusTarget == "todo_first_item" &&
        apiOutput.styleToken == "completed_accent" &&
        apiOutput.readbackOk &&
        apiOutput.summary == "harness=shared_demo_harness;served=todo;actions=2;before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list;after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent;interaction=add_todo,complete_todo;focus=todo_first_item;style=completed_accent;readback=true"

    println("cjgui shared demo harness app: demo=shared_demo_harness")
    println("cjgui shared demo harness app: status_before=not_started")
    println("cjgui shared demo harness app: status_after=runnable")
    println("cjgui shared demo harness app: served_demo=todo")
    println("cjgui shared demo harness app: interaction=run_todo_add_complete")
    println("cjgui shared demo harness app: state_before=${before}")
    println("cjgui shared demo harness app: state_after=${after}")
    println("cjgui shared demo harness app: state_readback=${readbackOk}")
    println("cjgui shared demo harness app: public_api_consumed=true")
    println("cjgui shared demo harness app: public_api_name=cjguiExperimentalBuildSharedDemoHarnessOutput")
    println("cjgui shared demo harness app: public_api_output=${apiOutput.summary}")

    if (outputOk) {
        return 0
    }
    return 1
}
