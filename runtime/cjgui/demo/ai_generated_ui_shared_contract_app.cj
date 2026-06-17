package cjgui_ai_generated_ui_shared_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}
import std.collection.*

// 中文维护注释：这是独立 AI-generated UI shared contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 AI-generated UI accept refresh 能写入 shared layout/style/input/focus contract，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class AiGeneratedUiSharedContractState {
    let contractName: String
    let layoutKind: String
    private var componentIds = ArrayList<String>()
    var accepted: Bool
    var acceptedScreen: String
    var diffSummary: String
    var explainText: String
    var layoutMode: String
    var styleToken: String
    var inputText: String
    var focusTarget: String
    var interactionTrace: String

    init() {
        this.contractName = "ai_generated_ui_shared_contract"
        this.layoutKind = "ai_form_preview"
        this.accepted = false
        this.acceptedScreen = "draft_settings_form"
        this.diffSummary = "pending_review"
        this.explainText = "awaiting owner review"
        this.layoutMode = "single_column"
        this.styleToken = "neutral_wireframe"
        this.inputText = "<empty>"
        this.focusTarget = "preview_card"
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
        focusTarget = "diff_panel"
        appendInteraction("preview_diff")
    }

    func explain(text: String) {
        explainText = text
        focusTarget = "explain_panel"
        appendInteraction("explain_changes")
    }

    func acceptRefresh(screen: String) {
        accepted = true
        acceptedScreen = screen
        componentIds.add("username_field")
        componentIds.add("save_button")
        layoutMode = "split_detail"
        styleToken = "sage_panel"
        inputText = "username"
        focusTarget = "generated_form"
        appendInteraction("accept_refresh")
    }

    func moveFocus(target: String) {
        focusTarget = target
        appendInteraction("move_focus")
    }

    func componentCount(): Int64 {
        return componentIds.size
    }

    func businessState(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};layout=${layoutMode};style=${styleToken};input=${inputText};focus=${focusTarget}"
    }

    func domainSummary(
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): String {
        return "contract=ai_generated_ui_shared_contract;screen=${acceptedScreen};components=${componentIds.size};diff=${diffSummary};explain=${explainText};layout=${layoutBefore}->${layoutMode};style=${styleBefore}->${styleToken};input=${inputBefore}->${inputText};focus=${focusBefore}->${focusTarget};layout_kind=${layoutKind};readback=${readbackOk}"
    }
}

main(): Int64 {
    let contract = AiGeneratedUiSharedContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layoutMode
    let styleBefore = contract.styleToken
    let inputBefore = contract.inputText
    let focusBefore = contract.focusTarget
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

    if (outputOk) {
        return 0
    }
    return 1
}
