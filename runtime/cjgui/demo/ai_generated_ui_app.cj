package cjgui_ai_generated_ui_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoProofReporter}
import cjgui.demo_support.{CjguiExperimentalDemoRunResultReporter}
import std.collection.*

// 中文维护注释：这是独立 AI-generated UI demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 AI 生成 UI 的 preview / diff / explain / accept refresh 被 demo-host 状态真实消费。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不提交 renderer，不调用 native bridge。

class AiGeneratedUiState {
    let demoName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    private var componentIds = ArrayList<String>()
    var accepted: Bool
    var acceptedScreen: String
    var diffSummary: String
    var explainText: String

    init() {
        this.demoName = "ai_generated_ui"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "ai_generated_ui",
            "components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe",
            "ai_form_preview",
            "neutral_wireframe",
            "<empty>",
            "preview_card"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "ai_generated_ui",
            "components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("ai_generated_ui")
        this.accepted = false
        this.acceptedScreen = "draft_settings_form"
        this.diffSummary = "pending_review"
        this.explainText = "awaiting owner review"
        componentIds.add("title")
        componentIds.add("theme_toggle")
    }

    func previewDiff(summary: String) {
        diffSummary = summary
        componentSession.moveFocus("diff_panel")
        componentSession.recordComponentAction("diff_panel", "ai_generated_ui.preview_diff", businessState())
    }

    func explain(text: String) {
        explainText = text
        componentSession.moveFocus("explain_panel")
        componentSession.recordComponentAction("explain_panel", "ai_generated_ui.explain_changes", businessState())
    }

    func acceptAndRefresh(screen: String, style: String) {
        accepted = true
        acceptedScreen = screen
        componentSession.applyStyle(style)
        componentIds.add("username_field")
        componentIds.add("save_button")
        componentSession.moveFocus("generated_form")
        componentSession.recordComponentAction("generated_form", "ai_generated_ui.accept_refresh", businessState())
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentAction(target, "ai_generated_ui.move_focus", businessState())
    }

    func componentCount(): Int64 {
        return componentIds.size
    }

    func businessState(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};diff=${diffSummary};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func domainSummary(): String {
        return "components=${componentIds.size};accepted=${accepted};screen=${acceptedScreen};diff=${diffSummary};explain=${explainText};focus=${componentSession.focus()};layout=${componentSession.layout()};style=${componentSession.style()}"
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
    let generatedUi = AiGeneratedUiState()
    let before = generatedUi.businessState()
    generatedUi.previewDiff("added_username_field,enabled_save_button")
    generatedUi.explain("owner accepted generated settings form refresh")
    generatedUi.acceptAndRefresh("settings_profile_form", "sage_panel")
    generatedUi.moveFocus("save_button")
    let after = generatedUi.businessState()
    let stateReadbackOk = before == "components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe" &&
        after == "components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel" &&
        generatedUi.componentCount() == 4 &&
        generatedUi.sharedUiState() == "layout=ai_form_preview;style=sage_panel;input=<empty>;focus=save_button" &&
        generatedUi.sharedBefore() == before &&
        generatedUi.sharedAfter() == after &&
        generatedUi.sharedActions() == "ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus" &&
        generatedUi.sharedWrites() == 4 &&
        generatedUi.sharedComponentActions() == "diff_panel:ai_generated_ui.preview_diff,explain_panel:ai_generated_ui.explain_changes,generated_form:ai_generated_ui.accept_refresh,save_button:ai_generated_ui.move_focus"
    let apiOutput = generatedUi.buildSharedOutput(generatedUi.domainSummary(), stateReadbackOk)
    let commitResult = generatedUi.commitHarness.commitComponentAction(
        "save_button",
        "ai_generated_ui.commit_accept_refresh",
        after
    )
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "ai_generated_ui" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == generatedUi.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=ai_generated_ui;readback=true;writes=4;actions=ai_generated_ui.preview_diff,ai_generated_ui.explain_changes,ai_generated_ui.accept_refresh,ai_generated_ui.move_focus;before=components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe;after=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel;summary=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel" &&
        generatedUi.commitHarness.resultMatches(
            commitResult,
            "save_button",
            "ai_generated_ui.commit_accept_refresh",
            before,
            after
        )
    let runResult = generatedUi.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        generatedUi.componentSession,
        commitResult,
        commitReadbackOk
    )
    let proofReporter = CjguiExperimentalDemoProofReporter("cjgui ai generated ui demo app")
    let runReporter = CjguiExperimentalDemoRunResultReporter("cjgui ai generated ui demo app")
    let readbackOk = commitReadbackOk && runResult.runnable

    println("cjgui ai generated ui demo app: demo=ai_generated_ui")
    println("cjgui ai generated ui demo app: status_before=not_started")
    println("cjgui ai generated ui demo app: status_after=runnable")
    println("cjgui ai generated ui demo app: layout=ai_form_preview")
    println("cjgui ai generated ui demo app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus")
    println("cjgui ai generated ui demo app: state_before=${before}")
    println("cjgui ai generated ui demo app: state_after=${after}")
    println("cjgui ai generated ui demo app: state_readback=${readbackOk}")
    proofReporter.printSharedPrimitiveProof(apiOutput, generatedUi.componentSession, commitResult, generatedUi.commitHarness)
    runReporter.printRunResult(runResult)

    if (readbackOk) {
        return 0
    }
    return 1
}
