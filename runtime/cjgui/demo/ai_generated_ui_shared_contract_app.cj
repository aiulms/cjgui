package cjgui_ai_generated_ui_shared_contract_demo

import cjgui.*
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

    func buildAiOutput(): CjguiExperimentalAiGeneratedUiDemoOutput {
        return cjguiExperimentalBuildAiGeneratedUiDemoOutput(
            componentIds.size,
            accepted,
            acceptedScreen,
            diffSummary,
            explainText,
            focusTarget,
            layoutKind,
            styleToken
        )
    }

    func buildSharedContractOutput(
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): CjguiExperimentalSharedLayoutStyleInputFocusContractOutput {
        return cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(
            layoutBefore,
            layoutMode,
            styleBefore,
            styleToken,
            inputBefore,
            inputText,
            focusBefore,
            focusTarget,
            interactionTrace,
            readbackOk
        )
    }

    func buildIntegrationOutput(
        aiOutput: CjguiExperimentalAiGeneratedUiDemoOutput,
        sharedOutput: CjguiExperimentalSharedLayoutStyleInputFocusContractOutput,
        layoutBefore: String,
        styleBefore: String,
        inputBefore: String,
        focusBefore: String,
        readbackOk: Bool
    ): CjguiExperimentalAiGeneratedUiSharedContractOutput {
        return cjguiExperimentalBuildAiGeneratedUiSharedContractOutput(
            acceptedScreen,
            componentIds.size,
            diffSummary,
            explainText,
            layoutBefore,
            layoutMode,
            styleBefore,
            styleToken,
            inputBefore,
            inputText,
            focusBefore,
            focusTarget,
            aiOutput.summary,
            sharedOutput.summary,
            readbackOk
        )
    }
}

main(): Int64 {
    let contract = AiGeneratedUiSharedContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layoutMode
    let styleBefore = contract.styleToken
    let inputBefore = contract.inputText
    let focusBefore = contract.focusTarget

    contract.generateSpec()
    contract.previewDiff("added_username_field,enabled_save_button")
    contract.explain("owner accepted generated settings form refresh")
    contract.acceptRefresh("settings_profile_form")
    contract.moveFocus("save_button")

    let after = contract.businessState()
    let readbackOk = before == "components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card" &&
        after == "components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button" &&
        contract.componentCount() == 4 &&
        contract.interactionTrace == "generate_spec,preview_diff,explain_changes,accept_refresh,move_focus"
    let aiOutput = contract.buildAiOutput()
    let sharedOutput = contract.buildSharedContractOutput(
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let integrationOutput = contract.buildIntegrationOutput(
        aiOutput,
        sharedOutput,
        layoutBefore,
        styleBefore,
        inputBefore,
        focusBefore,
        readbackOk
    )
    let outputOk = readbackOk &&
        aiOutput.demoName == "ai_generated_ui" &&
        aiOutput.componentCount == 4 &&
        aiOutput.accepted &&
        aiOutput.acceptedScreen == "settings_profile_form" &&
        aiOutput.diffSummary == "added_username_field,enabled_save_button" &&
        aiOutput.explainText == "owner accepted generated settings form refresh" &&
        aiOutput.focusTarget == "save_button" &&
        aiOutput.layoutKind == "ai_form_preview" &&
        aiOutput.styleToken == "sage_panel" &&
        sharedOutput.contractName == "shared_layout_style_input_focus" &&
        sharedOutput.layoutBefore == "single_column" &&
        sharedOutput.layoutAfter == "split_detail" &&
        sharedOutput.styleBefore == "neutral_wireframe" &&
        sharedOutput.styleAfter == "sage_panel" &&
        sharedOutput.inputBefore == "<empty>" &&
        sharedOutput.inputAfter == "username" &&
        sharedOutput.focusBefore == "preview_card" &&
        sharedOutput.focusAfter == "save_button" &&
        integrationOutput.contractName == "ai_generated_ui_shared_contract" &&
        integrationOutput.componentCount == 4 &&
        integrationOutput.acceptedScreen == "settings_profile_form" &&
        integrationOutput.layoutAfter == "split_detail" &&
        integrationOutput.styleAfter == "sage_panel" &&
        integrationOutput.inputAfter == "username" &&
        integrationOutput.focusAfter == "save_button" &&
        integrationOutput.readbackOk &&
        integrationOutput.summary == "contract=ai_generated_ui_shared_contract;screen=settings_profile_form;components=4;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;ai_summary=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel;shared_contract=contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;readback=true;readback=true"

    println("cjgui ai-generated-ui shared contract app: demo=ai_generated_ui_shared_contract")
    println("cjgui ai-generated-ui shared contract app: status_before=not_started")
    println("cjgui ai-generated-ui shared contract app: status_after=runnable")
    println("cjgui ai-generated-ui shared contract app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus")
    println("cjgui ai-generated-ui shared contract app: state_before=${before}")
    println("cjgui ai-generated-ui shared contract app: state_after=${after}")
    println("cjgui ai-generated-ui shared contract app: state_readback=${readbackOk}")
    println("cjgui ai-generated-ui shared contract app: public_api_consumed=true")
    println("cjgui ai-generated-ui shared contract app: public_api_name=cjguiExperimentalBuildAiGeneratedUiSharedContractOutput")
    println("cjgui ai-generated-ui shared contract app: public_api_output=${integrationOutput.summary}")

    if (outputOk) {
        return 0
    }
    return 1
}
