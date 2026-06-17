package cjgui_ai_generated_ui_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}
import std.collection.*

// 中文维护注释：这是独立 AI-generated UI demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 AI 生成 UI 的 preview / diff / explain / accept refresh 被 demo-host 状态真实消费。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不提交 renderer，不调用 native bridge。

class AiGeneratedUiState {
    let demoName: String
    let layoutKind: String
    private var componentIds = ArrayList<String>()
    var accepted: Bool
    var acceptedScreen: String
    var diffSummary: String
    var explainText: String
    var focusTarget: String
    var styleToken: String

    init() {
        this.demoName = "ai_generated_ui"
        this.layoutKind = "ai_form_preview"
        this.accepted = false
        this.acceptedScreen = "draft_settings_form"
        this.diffSummary = "pending_review"
        this.explainText = "awaiting owner review"
        this.focusTarget = "preview_card"
        this.styleToken = "neutral_wireframe"
        componentIds.add("title")
        componentIds.add("theme_toggle")
    }

    func previewDiff(summary: String) {
        diffSummary = summary
        focusTarget = "diff_panel"
    }

    func explain(text: String) {
        explainText = text
        focusTarget = "explain_panel"
    }

    func acceptAndRefresh(screen: String, style: String) {
        accepted = true
        acceptedScreen = screen
        styleToken = style
        componentIds.add("username_field")
        componentIds.add("save_button")
        focusTarget = "generated_form"
    }

    func moveFocus(target: String) {
        focusTarget = target
    }

    func componentCount(): Int64 {
        return componentIds.size
    }

    func businessState(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};diff=${diffSummary};focus=${focusTarget};style=${styleToken}"
    }

    func domainSummary(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};diff=${diffSummary};explain=${explainText};focus=${focusTarget};layout=${layoutKind};style=${styleToken}"
    }
}

main(): Int64 {
    let generatedUi = AiGeneratedUiState()
    let before = generatedUi.businessState()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("ai_generated_ui", before)
    generatedUi.previewDiff("added_username_field,enabled_save_button")
    sharedTrace.recordAction("ai_generated_ui.preview_diff", generatedUi.businessState())
    generatedUi.explain("owner accepted generated settings form refresh")
    sharedTrace.recordAction("ai_generated_ui.explain_changes", generatedUi.businessState())
    generatedUi.acceptAndRefresh("settings_profile_form", "sage_panel")
    sharedTrace.recordAction("ai_generated_ui.accept_refresh", generatedUi.businessState())
    generatedUi.moveFocus("save_button")
    let after = generatedUi.businessState()
    sharedTrace.recordAction("ai_generated_ui.move_focus", after)
    let stateReadbackOk = before == "components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe" &&
        after == "components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel" &&
        generatedUi.componentCount() == 4 &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus" &&
        sharedTrace.writes() == 4
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, generatedUi.domainSummary(), stateReadbackOk)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "ai_generated_ui" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == generatedUi.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=ai_generated_ui;readback=true;writes=4;actions=ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus;before=components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe;after=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel;summary=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel"

    println("cjgui ai generated ui demo app: demo=ai_generated_ui")
    println("cjgui ai generated ui demo app: status_before=not_started")
    println("cjgui ai generated ui demo app: status_after=runnable")
    println("cjgui ai generated ui demo app: layout=ai_form_preview")
    println("cjgui ai generated ui demo app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus")
    println("cjgui ai generated ui demo app: state_before=${before}")
    println("cjgui ai generated ui demo app: state_after=${after}")
    println("cjgui ai generated ui demo app: state_readback=${readbackOk}")
    println("cjgui ai generated ui demo app: public_api_consumed=true")
    println("cjgui ai generated ui demo app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui ai generated ui demo app: public_api_output=${apiOutput.summary}")
    println("cjgui ai generated ui demo app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui ai generated ui demo app: shared_support_output=${sharedTrace.summary()}")

    if (readbackOk) {
        return 0
    }
    return 1
}
