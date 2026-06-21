package cjgui_reusable_component_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoComponentActionRouteCatalog}
import cjgui.demo_support.{CjguiExperimentalDemoCommitActionRouteCatalog}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoCommitReadbackExpectation}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import cjgui.demo_support.{CjguiExperimentalDemoReusableComponentEvidence}
import cjgui.demo_support.{CjguiExperimentalDemoComponentInteractionEvidence, CjguiExperimentalDemoStateReadbackEvidence}

// 中文维护注释：这是独立 reusable component contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证同一组件合同能复用到 Todo、FileBrowser 与 AI-generated UI 三条业务流。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class ReusableComponentContractState {
    let contractName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let routeCatalog: CjguiExperimentalDemoComponentActionRouteCatalog
    let commitRouteCatalog: CjguiExperimentalDemoCommitActionRouteCatalog
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
        this.routeCatalog = CjguiExperimentalDemoComponentActionRouteCatalog()
        this.commitRouteCatalog = CjguiExperimentalDemoCommitActionRouteCatalog()
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
        componentSession.recordComponentActionRoute(
            routeCatalog.reusableComponentContractRegisterFileRow(),
            businessState()
        )
    }

    func attachAiGeneratedForm() {
        appendComponent("ai_form", "ai_generated_ui")
        componentSession.recordComponentActionRoute(
            routeCatalog.reusableComponentContractRegisterAiForm(),
            businessState()
        )
    }

    func runTodoAdd(title: String) {
        todoTitle = title
        componentSession.applyLayout("todo_list")
        componentSession.applyStyle("task_row_active")
        componentSession.typeInput(title)
        componentSession.moveFocus("todo_first_item")
        componentSession.recordComponentActionRoute(
            routeCatalog.reusableComponentContractTodoAdd(),
            businessState()
        )
    }

    func runFileSelect(path: String) {
        fileSelection = path
        componentSession.applyLayout("split_detail")
        componentSession.applyStyle("file_row_selected")
        componentSession.typeInput("filter:src")
        componentSession.moveFocus("file_detail_pane")
        componentSession.recordComponentActionRoute(
            routeCatalog.reusableComponentContractFileSelect(),
            businessState()
        )
    }

    func runAiAccept(screen: String) {
        aiAcceptedScreen = screen
        componentSession.applyLayout("split_detail")
        componentSession.applyStyle("sage_panel")
        componentSession.typeInput("filter:src,username")
        componentSession.moveFocus("save_button")
        componentSession.recordComponentActionRoute(
            routeCatalog.reusableComponentContractAiAccept(),
            businessState()
        )
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
    let commitRoute = contract.commitRouteCatalog.reusableComponentContractCommitReuseFlow()
    let commitResult = contract.commitHarness.commitComponentActionRoute(commitRoute, after)
    let commitExpectation = CjguiExperimentalDemoCommitReadbackExpectation(
        before,
        after,
        "register_file_row,register_ai_form,todo_add,file_select,ai_accept",
        5,
        domainSummary,
        "demo=reusable_component_contract;readback=true;writes=5;actions=register_file_row,register_ai_form,todo_add,file_select,ai_accept;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button;summary=contract=reusable_component_contract;components=task_row,file_row,ai_form;reused_count=3;reused=todo,file_browser,ai_generated_ui;component_count=3;layout=single_column->split_detail;style=neutral_list->sage_panel;input=<empty>->filter:src,username;focus=todo_input->save_button;readback=true;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button",
        readbackOk
    )
    let commitAssertion = contract.commitHarness.assertCommitReadbackRoute(
        commitResult,
        commitRoute,
        apiOutput,
        commitExpectation
    )
    let commitReadbackOk = commitAssertion.isSatisfied()
    let runResult = contract.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        contract.componentSession,
        commitResult,
        commitReadbackOk
    )
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui reusable component contract app")
    let outputOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder("reusable_component_contract", "not_started", "runnable")
    evidenceBuilder.addReusableComponentEvidence(
        CjguiExperimentalDemoReusableComponentEvidence("todo,file_browser,ai_generated_ui", "task_row,file_row,ai_form")
    )
    evidenceBuilder.addInteractionEvidence(
        CjguiExperimentalDemoComponentInteractionEvidence("register_file_row,register_ai_form,todo_add,file_select,ai_accept")
    )
    evidenceBuilder.addStateReadbackEvidence(CjguiExperimentalDemoStateReadbackEvidence(before, after, readbackOk))

    let evidenceSection = evidenceBuilder.buildSection(
        apiOutput,
        contract.componentSession,
        commitResult,
        contract.commitHarness,
        runResult
    )
    evidencePresenter.printEvidenceSection(evidenceSection)

    if (outputOk) {
        return 0
    }
    return 1
}
