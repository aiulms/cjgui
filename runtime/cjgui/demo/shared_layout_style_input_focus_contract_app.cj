package cjgui_shared_layout_style_input_focus_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import cjgui.demo_support.{CjguiExperimentalDemoComponentInteractionEvidence, CjguiExperimentalDemoStateReadbackEvidence}

// 中文维护注释：这是独立 shared layout/style/input/focus contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能表达 layout/style/text input/focus 四类交互合同，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedLayoutStyleInputFocusContractState {
    let contractName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness

    init() {
        this.contractName = "shared_layout_style_input_focus"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "shared_layout_style_input_focus_contract",
            "layout=single_column;style=neutral_list;input=<empty>;focus=todo_input",
            "single_column",
            "neutral_list",
            "<empty>",
            "todo_input"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "shared_layout_style_input_focus_contract",
            "layout=single_column;style=neutral_list;input=<empty>;focus=todo_input"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("shared_layout_style_input_focus_contract")
    }

    func applyLayout(kind: String) {
        componentSession.applyLayout(kind)
        componentSession.recordComponentAction("layout_contract", "shared_layout_style_input_focus.apply_layout", businessState())
    }

    func applyStyle(token: String) {
        componentSession.applyStyle(token)
        componentSession.recordComponentAction("style_contract", "shared_layout_style_input_focus.apply_style", businessState())
    }

    func typeInput(text: String) {
        componentSession.typeInput(text)
        componentSession.recordComponentAction("text_input_contract", "shared_layout_style_input_focus.type_input", businessState())
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentAction("focus_contract", "shared_layout_style_input_focus.move_focus", businessState())
    }

    func businessState(): String {
        return componentSession.uiStateSummary()
    }

    func domainSummary(layoutBefore: String, styleBefore: String, inputBefore: String, focusBefore: String): String {
        return "contract=${contractName};layout=${layoutBefore}->${componentSession.layout()};style=${styleBefore}->${componentSession.style()};input=${inputBefore}->${componentSession.textInput()};focus=${focusBefore}->${componentSession.focus()}"
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
    let contract = SharedLayoutStyleInputFocusContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layout()
    let styleBefore = contract.style()
    let inputBefore = contract.textInput()
    let focusBefore = contract.focus()

    contract.applyLayout("split_detail")
    contract.applyStyle("focus_accent")
    contract.typeInput("main")
    contract.moveFocus("file_filter")

    let after = contract.businessState()
    let layoutAfter = contract.layout()
    let styleAfter = contract.style()
    let inputAfter = contract.textInput()
    let focusAfter = contract.focus()
    let stateReadbackOk = before == "layout=single_column;style=neutral_list;input=<empty>;focus=todo_input" &&
        after == "layout=split_detail;style=focus_accent;input=main;focus=file_filter" &&
        layoutAfter == "split_detail" &&
        styleAfter == "focus_accent" &&
        inputAfter == "main" &&
        focusAfter == "file_filter" &&
        contract.sharedUiState() == "layout=split_detail;style=focus_accent;input=main;focus=file_filter" &&
        contract.sharedBefore() == before &&
        contract.sharedAfter() == after &&
        contract.sharedActions() == "shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus" &&
        contract.sharedWrites() == 4 &&
        contract.sharedComponentActions() == "layout_contract:shared_layout_style_input_focus.apply_layout,style_contract:shared_layout_style_input_focus.apply_style,text_input_contract:shared_layout_style_input_focus.type_input,focus_contract:shared_layout_style_input_focus.move_focus"
    let domainSummary = contract.domainSummary(layoutBefore, styleBefore, inputBefore, focusBefore)
    let apiOutput = contract.buildSharedOutput(domainSummary, stateReadbackOk)
    let commitResult = contract.commitHarness.commitComponentAction(
        "focus_contract",
        "shared_layout_style_input_focus.commit_contract_flow",
        after
    )
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "shared_layout_style_input_focus_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_layout_style_input_focus_contract;readback=true;writes=4;actions=shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus;before=layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=layout=split_detail;style=focus_accent;input=main;focus=file_filter;summary=contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_list->focus_accent;input=<empty>->main;focus=todo_input->file_filter" &&
        contract.commitHarness.resultMatches(
            commitResult,
            "focus_contract",
            "shared_layout_style_input_focus.commit_contract_flow",
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
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui shared layout-style-input-focus contract app")
    let outputOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder(
        "shared_layout_style_input_focus_contract",
        "not_started",
        "runnable"
    )
    evidenceBuilder.addInteractionEvidence(
        CjguiExperimentalDemoComponentInteractionEvidence("apply_layout,apply_style,type_input,move_focus")
    )
    evidenceBuilder.addStateReadbackEvidence(CjguiExperimentalDemoStateReadbackEvidence(before, after, outputOk))

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
