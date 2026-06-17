package cjgui_ai_generated_ui_shared_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder, CjguiExperimentalDemoUiStateCore}
import std.collection.*

// 中文维护注释：这是独立 AI-generated UI shared contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 AI-generated UI accept refresh 能写入 shared layout/style/input/focus contract，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class AiGeneratedUiSharedContractState {
    let contractName: String
    let layoutKind: String
    let uiState: CjguiExperimentalDemoUiStateCore
    private var componentIds = ArrayList<String>()
    var accepted: Bool
    var acceptedScreen: String
    var diffSummary: String
    var explainText: String
    var interactionTrace: String

    init() {
        this.contractName = "ai_generated_ui_shared_contract"
        this.layoutKind = "ai_form_preview"
        this.uiState = CjguiExperimentalDemoUiStateCore("single_column", "neutral_wireframe", "<empty>", "preview_card")
        this.accepted = false
        this.acceptedScreen = "draft_settings_form"
        this.diffSummary = "pending_review"
        this.explainText = "awaiting owner review"
        this.interactionTrace = "idle"
        componentIds.add("title")
        componentIds.add("theme_toggle")
    }

    private func appendInteraction(name: String) {
        if (interactionTrace == "idle") {
            interactionTrace = name
        } else {
            interactionTrace = "${interactionTrace},${name}"
        }
    }

    func generateSpec() {
        appendInteraction("generate_spec")
    }

    func previewDiff(summary: String) {
        diffSummary = summary
        uiState.moveFocus("diff_panel")
        appendInteraction("preview_diff")
    }

    func explain(text: String) {
        explainText = text
        uiState.moveFocus("explain_panel")
        appendInteraction("explain_changes")
    }

    func acceptRefresh(screen: String) {
        accepted = true
        acceptedScreen = screen
        componentIds.add("username_field")
        componentIds.add("save_button")
        uiState.applyLayout("split_detail")
        uiState.applyStyle("sage_panel")
        uiState.typeInput("username")
        uiState.moveFocus("generated_form")
        appendInteraction("accept_refresh")
    }

    func moveFocus(target: String) {
        uiState.moveFocus(target)
        appendInteraction("move_focus")
    }

    func componentCount(): Int64 {
        return componentIds.size
    }

    func businessState(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};layout=${uiState.layout()};style=${uiState.style()};input=${uiState.textInput()};focus=${uiState.focus()}"
    }

    func domainSummary(
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): String {
        return "contract=ai_generated_ui_shared_contract;screen=${acceptedScreen};components=${componentIds.size};diff=${diffSummary};explain=${explainText};layout=${layoutBefore}->${uiState.layout()};style=${styleBefore}->${uiState.style()};input=${inputBefore}->${uiState.textInput()};focus=${focusBefore}->${uiState.focus()};layout_kind=${layoutKind};readback=${readbackOk}"
    }

    func sharedUiState(): String {
        return uiState.summary()
    }
}

main(): Int64 {
    let contract = AiGeneratedUiSharedContractState()
    let before = contract.businessState()
    let layoutBefore = contract.uiState.layout()
    let styleBefore = contract.uiState.style()
    let inputBefore = contract.uiState.textInput()
    let focusBefore = contract.uiState.focus()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("ai_generated_ui_shared_contract", before)

    contract.generateSpec()
    sharedTrace.recordAction("generate_spec", contract.businessState())
    contract.previewDiff("added_username_field,enabled_save_button")
    sharedTrace.recordAction("preview_diff", contract.businessState())
    contract.explain("owner accepted generated settings form refresh")
    sharedTrace.recordAction("explain_changes", contract.businessState())
    contract.acceptRefresh("settings_profile_form")
    sharedTrace.recordAction("accept_refresh", contract.businessState())
    contract.moveFocus("save_button")
    sharedTrace.recordAction("move_focus", contract.businessState())

    let after = contract.businessState()
    let readbackOk = before == "components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card" &&
        after == "components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button" &&
        contract.componentCount() == 4 &&
        contract.sharedUiState() == "layout=split_detail;style=sage_panel;input=username;focus=save_button" &&
        contract.interactionTrace == "generate_spec,preview_diff,explain_changes,accept_refresh,move_focus"
    let domainSummary = contract.domainSummary(
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, domainSummary, readbackOk)
    let outputOk = readbackOk &&
        apiOutput.demoName == "ai_generated_ui_shared_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "generate_spec,preview_diff,explain_changes,accept_refresh,move_focus" &&
        apiOutput.writeCount == 5 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=ai_generated_ui_shared_contract;readback=true;writes=5;actions=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card;after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button;summary=contract=ai_generated_ui_shared_contract;screen=settings_profile_form;components=4;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;layout_kind=ai_form_preview;readback=true"

    println("cjgui ai-generated-ui shared contract app: demo=ai_generated_ui_shared_contract")
    println("cjgui ai-generated-ui shared contract app: status_before=not_started")
    println("cjgui ai-generated-ui shared contract app: status_after=runnable")
    println("cjgui ai-generated-ui shared contract app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus")
    println("cjgui ai-generated-ui shared contract app: state_before=${before}")
    println("cjgui ai-generated-ui shared contract app: state_after=${after}")
    println("cjgui ai-generated-ui shared contract app: state_readback=${readbackOk}")
    println("cjgui ai-generated-ui shared contract app: public_api_consumed=true")
    println("cjgui ai-generated-ui shared contract app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui ai-generated-ui shared contract app: public_api_output=${apiOutput.summary}")
    println("cjgui ai-generated-ui shared contract app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui ai-generated-ui shared contract app: shared_support_output=${sharedTrace.summary()}")
    println("cjgui ai-generated-ui shared contract app: shared_state_core=${contract.sharedUiState()}")

    if (outputOk) {
        return 0
    }
    return 1
}
