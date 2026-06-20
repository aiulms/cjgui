package cjgui_ai_generated_ui_shared_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import std.collection.*

// 中文维护注释：这是独立 AI-generated UI shared contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 AI-generated UI accept refresh 能写入 shared layout/style/input/focus contract，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class AiGeneratedUiSharedContractState {
    let contractName: String
    let layoutKind: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    private var componentIds = ArrayList<String>()
    var accepted: Bool
    var acceptedScreen: String
    var diffSummary: String
    var explainText: String

    init() {
        this.contractName = "ai_generated_ui_shared_contract"
        this.layoutKind = "ai_form_preview"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "ai_generated_ui_shared_contract",
            "components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card",
            "single_column",
            "neutral_wireframe",
            "<empty>",
            "preview_card"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "ai_generated_ui_shared_contract",
            "components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card"
        )
        this.accepted = false
        this.acceptedScreen = "draft_settings_form"
        this.diffSummary = "pending_review"
        this.explainText = "awaiting owner review"
        componentIds.add("title")
        componentIds.add("theme_toggle")
    }

    func generateSpec() {
        componentSession.recordComponentAction("spec_generator", "generate_spec", businessState())
    }

    func previewDiff(summary: String) {
        diffSummary = summary
        componentSession.moveFocus("diff_panel")
        componentSession.recordComponentAction("diff_panel", "preview_diff", businessState())
    }

    func explain(text: String) {
        explainText = text
        componentSession.moveFocus("explain_panel")
        componentSession.recordComponentAction("explain_panel", "explain_changes", businessState())
    }

    func acceptRefresh(screen: String) {
        accepted = true
        acceptedScreen = screen
        componentIds.add("username_field")
        componentIds.add("save_button")
        componentSession.applyLayout("split_detail")
        componentSession.applyStyle("sage_panel")
        componentSession.typeInput("username")
        componentSession.moveFocus("generated_form")
        componentSession.recordComponentAction("generated_form", "accept_refresh", businessState())
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentAction("save_button", "move_focus", businessState())
    }

    func componentCount(): Int64 {
        return componentIds.size
    }

    func businessState(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};layout=${componentSession.layout()};style=${componentSession.style()};input=${componentSession.textInput()};focus=${componentSession.focus()}"
    }

    func domainSummary(
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): String {
        return "contract=ai_generated_ui_shared_contract;screen=${acceptedScreen};components=${componentIds.size};diff=${diffSummary};explain=${explainText};layout=${layoutBefore}->${componentSession.layout()};style=${styleBefore}->${componentSession.style()};input=${inputBefore}->${componentSession.textInput()};focus=${focusBefore}->${componentSession.focus()};layout_kind=${layoutKind};readback=${readbackOk}"
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
    let contract = AiGeneratedUiSharedContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layout()
    let styleBefore = contract.style()
    let inputBefore = contract.textInput()
    let focusBefore = contract.focus()

    contract.generateSpec()
    contract.previewDiff("added_username_field,enabled_save_button")
    contract.explain("owner accepted generated settings form refresh")
    contract.acceptRefresh("settings_profile_form")
    contract.moveFocus("save_button")

    let after = contract.businessState()
    let readbackOk = before == "components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card" &&
        after == "components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button" &&
        contract.componentCount() == 4 &&
        contract.sharedUiState() == "layout=split_detail;style=sage_panel;input=username;focus=save_button" &&
        contract.sharedBefore() == before &&
        contract.sharedAfter() == after &&
        contract.sharedActions() == "generate_spec,preview_diff,explain_changes,accept_refresh,move_focus" &&
        contract.sharedWrites() == 5 &&
        contract.sharedComponentActions() == "spec_generator:generate_spec,diff_panel:preview_diff,explain_panel:explain_changes,generated_form:accept_refresh,save_button:move_focus"
    let domainSummary = contract.domainSummary(
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let apiOutput = contract.buildSharedOutput(domainSummary, readbackOk)
    let commitResult = contract.commitHarness.commitComponentAction(
        "save_button",
        "ai_generated_ui_shared_contract.commit_accept_refresh",
        after
    )
    let outputOk = readbackOk &&
        apiOutput.demoName == "ai_generated_ui_shared_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "generate_spec,preview_diff,explain_changes,accept_refresh,move_focus" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=ai_generated_ui_shared_contract;readback=true;writes=5;actions=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card;after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button;summary=contract=ai_generated_ui_shared_contract;screen=settings_profile_form;components=4;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;layout_kind=ai_form_preview;readback=true" &&
        contract.commitHarness.resultMatches(
            commitResult,
            "save_button",
            "ai_generated_ui_shared_contract.commit_accept_refresh",
            before,
            after
        )

    println("cjgui ai-generated-ui shared contract app: demo=ai_generated_ui_shared_contract")
    println("cjgui ai-generated-ui shared contract app: status_before=not_started")
    println("cjgui ai-generated-ui shared contract app: status_after=runnable")
    println("cjgui ai-generated-ui shared contract app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus")
    println("cjgui ai-generated-ui shared contract app: state_before=${before}")
    println("cjgui ai-generated-ui shared contract app: state_after=${after}")
    println("cjgui ai-generated-ui shared contract app: state_readback=${readbackOk}")
    println("cjgui ai-generated-ui shared contract app: public_api_consumed=true")
    println("cjgui ai-generated-ui shared contract app: public_api_name=CjguiExperimentalDemoComponentActionSession")
    println("cjgui ai-generated-ui shared contract app: public_api_output=${apiOutput.summary}")
    println("cjgui ai-generated-ui shared contract app: shared_support=CjguiExperimentalDemoComponentActionSession")
    println("cjgui ai-generated-ui shared contract app: shared_support_output=${contract.sharedSupportOutput()}")
    println("cjgui ai-generated-ui shared contract app: shared_state_core=${contract.sharedUiState()}")
    println("cjgui ai-generated-ui shared contract app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession")
    println("cjgui ai-generated-ui shared contract app: shared_component_action_output=${contract.sharedComponentActionSummary()}")
    println("cjgui ai-generated-ui shared contract app: shared_commit_harness=CjguiExperimentalDemoCommitHarness")
    println("cjgui ai-generated-ui shared contract app: shared_commit_output=${commitResult.summary}")
    println("cjgui ai-generated-ui shared contract app: shared_commit_readback=${contract.commitHarness.readback()}")
    println("cjgui ai-generated-ui shared contract app: shared_commit_rollback_boundary=${contract.commitHarness.rollbackBoundary()}")
    println("cjgui ai-generated-ui shared contract app: shared_commit_not_published=${commitResult.notPublished}")

    if (outputOk) {
        return 0
    }
    return 1
}
