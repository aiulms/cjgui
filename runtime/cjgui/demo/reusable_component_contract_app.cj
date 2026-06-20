package cjgui_reusable_component_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness, CjguiExperimentalDemoCommitResult}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness, CjguiExperimentalDemoRunResult}
import cjgui.demo_support.{CjguiExperimentalDemoRunResultReporter}

// 中文维护注释：这是独立 reusable component contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证同一组件合同能复用到 Todo、FileBrowser 与 AI-generated UI 三条业务流。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class ReusableComponentContractState {
    let contractName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    var componentCount: Int64
    var componentKinds: String
    var reusedDemoCount: Int64
    var reusedDemos: String
    var todoTitle: String
    var fileSelection: String
    var aiAcceptedScreen: String

    init() {
        this.contractName = "reusable_component_contract"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "reusable_component_contract",
            "components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input",
            "single_column",
            "neutral_list",
            "<empty>",
            "todo_input"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "reusable_component_contract",
            "components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("reusable_component_contract")
        this.componentCount = 1
        this.componentKinds = "task_row"
        this.reusedDemoCount = 1
        this.reusedDemos = "todo"
        this.todoTitle = "<empty>"
        this.fileSelection = "<none>"
        this.aiAcceptedScreen = "<none>"
    }

    private func appendComponent(kind: String, demo: String) {
        componentKinds = "${componentKinds},${kind}"
        reusedDemos = "${reusedDemos},${demo}"
        componentCount += 1
        reusedDemoCount += 1
    }

    func attachFileBrowserRow() {
        appendComponent("file_row", "file_browser")
        componentSession.recordComponentAction("file_row", "register_file_row", businessState())
    }

    func attachAiGeneratedForm() {
        appendComponent("ai_form", "ai_generated_ui")
        componentSession.recordComponentAction("ai_form", "register_ai_form", businessState())
    }

    func runTodoAdd(title: String) {
        todoTitle = title
        componentSession.applyLayout("todo_list")
        componentSession.applyStyle("task_row_active")
        componentSession.typeInput(title)
        componentSession.moveFocus("todo_first_item")
        componentSession.recordComponentAction("task_row", "todo_add", businessState())
    }

    func runFileSelect(path: String) {
        fileSelection = path
        componentSession.applyLayout("split_detail")
        componentSession.applyStyle("file_row_selected")
        componentSession.typeInput("filter:src")
        componentSession.moveFocus("file_detail_pane")
        componentSession.recordComponentAction("file_row", "file_select", businessState())
    }

    func runAiAccept(screen: String) {
        aiAcceptedScreen = screen
        componentSession.applyLayout("split_detail")
        componentSession.applyStyle("sage_panel")
        componentSession.typeInput("filter:src,username")
        componentSession.moveFocus("save_button")
        componentSession.recordComponentAction("ai_form", "ai_accept", businessState())
    }

    func businessState(): String {
        return "components=${componentCount};demos=${reusedDemos};todo=${todoTitle};file=${fileSelection};ai=${aiAcceptedScreen};layout=${componentSession.layout()};style=${componentSession.style()};input=${componentSession.textInput()};focus=${componentSession.focus()}"
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
        return "contract=reusable_component_contract;components=${componentKinds};reused_count=${reusedDemoCount};reused=${reusedDemos};component_count=${componentCount};layout=${layoutBefore}->${componentSession.layout()};style=${styleBefore}->${componentSession.style()};input=${inputBefore}->${componentSession.textInput()};focus=${focusBefore}->${componentSession.focus()};readback=${readbackOk};before=${beforeState};after=${afterState}"
    }

    func sharedUiState(): String {
        return componentSession.uiStateSummary()
    }

    func layout(): String {
        return componentSession.layout()
    }

    func style(): String {
        return componentSession.style()
    }

    func textInput(): String {
        return componentSession.textInput()
    }

    func focus(): String {
        return componentSession.focus()
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


}

main(): Int64 {
    let contract = ReusableComponentContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layout()
    let styleBefore = contract.style()
    let inputBefore = contract.textInput()
    let focusBefore = contract.focus()

    contract.attachFileBrowserRow()
    contract.attachAiGeneratedForm()
    contract.runTodoAdd("buy_milk")
    contract.runFileSelect("src/main.cj")
    contract.runAiAccept("settings_profile_form")

    let after = contract.businessState()
    let readbackOk = before == "components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input" &&
        after == "components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button" &&
        contract.componentKinds == "task_row,file_row,ai_form" &&
        contract.reusedDemoCount == 3 &&
        contract.sharedUiState() == "layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button" &&
        contract.sharedBefore() == before &&
        contract.sharedAfter() == after &&
        contract.sharedActions() == "register_file_row,register_ai_form,todo_add,file_select,ai_accept" &&
        contract.sharedWrites() == 5 &&
        contract.sharedComponentActions() == "file_row:register_file_row,ai_form:register_ai_form,task_row:todo_add,file_row:file_select,ai_form:ai_accept"
    let domainSummary = contract.domainSummary(
        before,
        after,
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let apiOutput = contract.buildSharedOutput(domainSummary, readbackOk)
    let commitResult = contract.commitHarness.commitComponentAction(
        "ai_form",
        "reusable_component_contract.commit_reuse_flow",
        after
    )
    let commitReadbackOk = readbackOk &&
        apiOutput.demoName == "reusable_component_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "register_file_row,register_ai_form,todo_add,file_select,ai_accept" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=reusable_component_contract;readback=true;writes=5;actions=register_file_row,register_ai_form,todo_add,file_select,ai_accept;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button;summary=contract=reusable_component_contract;components=task_row,file_row,ai_form;reused_count=3;reused=todo,file_browser,ai_generated_ui;component_count=3;layout=single_column->split_detail;style=neutral_list->sage_panel;input=<empty>->filter:src,username;focus=todo_input->save_button;readback=true;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button" &&
        contract.commitHarness.resultMatches(
            commitResult,
            "ai_form",
            "reusable_component_contract.commit_reuse_flow",
            before,
            after
        )
    let runResult = contract.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        contract.componentSession,
        commitResult,
        commitReadbackOk
    )
    let runReporter = CjguiExperimentalDemoRunResultReporter("cjgui reusable component contract app")
    let outputOk = commitReadbackOk && runResult.runnable

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
    println("cjgui reusable component contract app: public_api_name=CjguiExperimentalDemoComponentActionSession")
    println("cjgui reusable component contract app: public_api_output=${apiOutput.summary}")
    println("cjgui reusable component contract app: shared_support=CjguiExperimentalDemoComponentActionSession")
    println("cjgui reusable component contract app: shared_support_output=${contract.sharedSupportOutput()}")
    println("cjgui reusable component contract app: shared_state_core=${contract.sharedUiState()}")
    println("cjgui reusable component contract app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession")
    println("cjgui reusable component contract app: shared_component_action_output=${contract.sharedComponentActionSummary()}")
    println("cjgui reusable component contract app: shared_commit_harness=CjguiExperimentalDemoCommitHarness")
    println("cjgui reusable component contract app: shared_commit_output=${commitResult.summary}")
    println("cjgui reusable component contract app: shared_commit_readback=${contract.commitHarness.readback()}")
    println("cjgui reusable component contract app: shared_commit_rollback_boundary=${contract.commitHarness.rollbackBoundary()}")
    println("cjgui reusable component contract app: shared_commit_not_published=${commitResult.notPublished}")
    runReporter.printRunResult(runResult)

    if (outputOk) {
        return 0
    }
    return 1
}
