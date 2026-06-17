package cjgui_reusable_component_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}

// 中文维护注释：这是独立 reusable component contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证同一组件合同能复用到 Todo、FileBrowser 与 AI-generated UI 三条业务流。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class ReusableComponentContractState {
    let contractName: String
    var componentCount: Int64
    var componentKinds: String
    var reusedDemoCount: Int64
    var reusedDemos: String
    var actionTrace: String
    var todoTitle: String
    var fileSelection: String
    var aiAcceptedScreen: String
    var layoutMode: String
    var styleToken: String
    var inputText: String
    var focusTarget: String

    init() {
        this.contractName = "reusable_component_contract"
        this.componentCount = 1
        this.componentKinds = "task_row"
        this.reusedDemoCount = 1
        this.reusedDemos = "todo"
        this.actionTrace = "idle"
        this.todoTitle = "<empty>"
        this.fileSelection = "<none>"
        this.aiAcceptedScreen = "<none>"
        this.layoutMode = "single_column"
        this.styleToken = "neutral_list"
        this.inputText = "<empty>"
        this.focusTarget = "todo_input"
    }

    private func appendComponent(kind: String, demo: String) {
        componentKinds = "${componentKinds},${kind}"
        reusedDemos = "${reusedDemos},${demo}"
        componentCount += 1
        reusedDemoCount += 1
    }

    private func appendAction(action: String) {
        if (actionTrace == "idle") {
            actionTrace = action
        } else {
            actionTrace = "${actionTrace},${action}"
        }
    }

    func attachFileBrowserRow() {
        appendComponent("file_row", "file_browser")
        appendAction("register_file_row")
    }

    func attachAiGeneratedForm() {
        appendComponent("ai_form", "ai_generated_ui")
        appendAction("register_ai_form")
    }

    func runTodoAdd(title: String) {
        todoTitle = title
        layoutMode = "todo_list"
        styleToken = "task_row_active"
        inputText = title
        focusTarget = "todo_first_item"
        appendAction("todo_add")
    }

    func runFileSelect(path: String) {
        fileSelection = path
        layoutMode = "split_detail"
        styleToken = "file_row_selected"
        inputText = "filter:src"
        focusTarget = "file_detail_pane"
        appendAction("file_select")
    }

    func runAiAccept(screen: String) {
        aiAcceptedScreen = screen
        layoutMode = "split_detail"
        styleToken = "sage_panel"
        inputText = "filter:src,username"
        focusTarget = "save_button"
        appendAction("ai_accept")
    }

    func businessState(): String {
        return "components=${componentCount};demos=${reusedDemos};todo=${todoTitle};file=${fileSelection};ai=${aiAcceptedScreen};layout=${layoutMode};style=${styleToken};input=${inputText};focus=${focusTarget}"
    }

    func domainSummary(
        beforeState: String,
        afterState: String,
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): String {
        return "contract=reusable_component_contract;components=${componentKinds};reused_count=${reusedDemoCount};reused=${reusedDemos};component_count=${componentCount};layout=${layoutBefore}->${layoutMode};style=${styleBefore}->${styleToken};input=${inputBefore}->${inputText};focus=${focusBefore}->${focusTarget};readback=${readbackOk};before=${beforeState};after=${afterState}"
    }
}

main(): Int64 {
    let contract = ReusableComponentContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layoutMode
    let styleBefore = contract.styleToken
    let inputBefore = contract.inputText
    let focusBefore = contract.focusTarget
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("reusable_component_contract", before)

    contract.attachFileBrowserRow()
    sharedTrace.recordAction("register_file_row", contract.businessState())
    contract.attachAiGeneratedForm()
    sharedTrace.recordAction("register_ai_form", contract.businessState())
    contract.runTodoAdd("buy_milk")
    sharedTrace.recordAction("todo_add", contract.businessState())
    contract.runFileSelect("src/main.cj")
    sharedTrace.recordAction("file_select", contract.businessState())
    contract.runAiAccept("settings_profile_form")
    sharedTrace.recordAction("ai_accept", contract.businessState())

    let after = contract.businessState()
    let readbackOk = before == "components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input" &&
        after == "components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button" &&
        contract.componentKinds == "task_row,file_row,ai_form" &&
        contract.reusedDemoCount == 3 &&
        contract.actionTrace == "register_file_row,register_ai_form,todo_add,file_select,ai_accept"
    let domainSummary = contract.domainSummary(
        before,
        after,
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, domainSummary, readbackOk)
    let outputOk = readbackOk &&
        apiOutput.demoName == "reusable_component_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "register_file_row,register_ai_form,todo_add,file_select,ai_accept" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=reusable_component_contract;readback=true;writes=5;actions=register_file_row,register_ai_form,todo_add,file_select,ai_accept;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button;summary=contract=reusable_component_contract;components=task_row,file_row,ai_form;reused_count=3;reused=todo,file_browser,ai_generated_ui;component_count=3;layout=single_column->split_detail;style=neutral_list->sage_panel;input=<empty>->filter:src,username;focus=todo_input->save_button;readback=true;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button"

    println("cjgui reusable component contract app: demo=reusable_component_contract")
    println("cjgui reusable component contract app: status_before=not_started")
    println("cjgui reusable component contract app: status_after=runnable")
    println("cjgui reusable component contract app: reused_demos=todo,file_browser,ai_generated_ui")
    println("cjgui reusable component contract app: component_kinds=task_row,file_row,ai_form")
    println("cjgui reusable component contract app: interaction=register_file_row,register_ai_form,todo_add,file_select,ai_accept")
    println("cjgui reusable component contract app: state_before=${before}")
    println("cjgui reusable component contract app: state_after=${after}")
    println("cjgui reusable component contract app: state_readback=${readbackOk}")
    println("cjgui reusable component contract app: public_api_consumed=true")
    println("cjgui reusable component contract app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui reusable component contract app: public_api_output=${apiOutput.summary}")
    println("cjgui reusable component contract app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui reusable component contract app: shared_support_output=${sharedTrace.summary()}")

    if (outputOk) {
        return 0
    }
    return 1
}
