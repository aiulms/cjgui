package cjgui_settings_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoCommitResult, CjguiExperimentalDemoOwnerLocalCommitSession}

// 中文维护注释：这是独立 Settings demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 Settings demo 消费 CJGUI experimental 非 Bool public API，并执行 owner-local 状态写入读回。
// Stop-line: 只做 demo-host in-memory 状态，不调用 native bridge，不提交 renderer。

class SettingsPanelState {
    let demoName: String
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitSession: CjguiExperimentalDemoOwnerLocalCommitSession
    let controlsSummary: String
    var selectedTheme: String
    var usernameValue: String
    var autoSaveEnabled: Bool

    init() {
        this.demoName = "settings"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "settings",
            "autosave=false;theme=light;username=owner;focus=username_field",
            "sectioned_form",
            "theme_light",
            "owner",
            "username_field"
        )
        this.commitSession = CjguiExperimentalDemoOwnerLocalCommitSession(
            "settings",
            "autosave=false;theme=light;username=owner;focus=username_field"
        )
        this.controlsSummary = "toggle:auto_save,select:theme,text:username"
        this.selectedTheme = "light"
        this.usernameValue = "owner"
        this.autoSaveEnabled = false
    }

    func toggleAutoSave() {
        autoSaveEnabled = !autoSaveEnabled
        componentSession.recordComponentAction("auto_save_toggle", "settings.toggle_auto_save", businessState())
    }

    func selectTheme(theme: String) {
        selectedTheme = theme
        componentSession.applyStyle("theme_${theme}")
        componentSession.recordComponentAction("theme_select", "settings.select_theme", businessState())
    }

    func updateUsername(username: String) {
        usernameValue = username
        componentSession.typeInput(username)
        componentSession.recordComponentAction("username_field", "settings.update_username", businessState())
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentAction(target, "settings.move_focus", businessState())
    }

    func businessState(): String {
        return "autosave=${autoSaveEnabled};theme=${selectedTheme};username=${usernameValue};focus=${componentSession.focus()}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${componentSession.layout()};controls=${controlsSummary};${businessState()}"
    }

    func sharedUiState(): String {
        return componentSession.uiStateSummary()
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

    func commitSharedState(componentId: String, action: String, afterState: String): CjguiExperimentalDemoCommitResult {
        return commitSession.commitComponentAction(componentId, action, afterState)
    }

    func commitReadback(): String {
        return commitSession.readback()
    }

    func commitRollbackBoundary(): String {
        return commitSession.rollbackBoundary()
    }
}

main(): Int64 {
    let panel = SettingsPanelState()
    let before = panel.businessState()
    panel.toggleAutoSave()
    panel.selectTheme("dark")
    panel.updateUsername("owner-updated")
    panel.moveFocus("theme_select")
    let after = panel.businessState()
    let summary = panel.summary()
    let stateReadbackOk = before == "autosave=false;theme=light;username=owner;focus=username_field" &&
        after == "autosave=true;theme=dark;username=owner-updated;focus=theme_select" &&
        panel.sharedBefore() == before &&
        panel.sharedAfter() == after &&
        panel.sharedActions() == "settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus" &&
        panel.sharedWrites() == 4 &&
        panel.sharedComponentActions() == "auto_save_toggle:settings.toggle_auto_save,theme_select:settings.select_theme,username_field:settings.update_username,theme_select:settings.move_focus" &&
        panel.sharedUiState() == "layout=sectioned_form;style=theme_dark;input=owner-updated;focus=theme_select" &&
        summary == "demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select"
    let apiOutput = panel.buildSharedOutput(summary, stateReadbackOk)
    let commitResult = panel.commitSharedState("theme_select", "settings.commit_preferences", after)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "settings" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=settings;readback=true;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select;summary=demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select" &&
        commitResult.demoName == "settings" &&
        commitResult.componentId == "theme_select" &&
        commitResult.action == "settings.commit_preferences" &&
        commitResult.beforeState == before &&
        commitResult.afterState == after &&
        commitResult.readbackState == after &&
        commitResult.rollbackState == before &&
        commitResult.writeCount == 1 &&
        commitResult.committed &&
        commitResult.readbackOk &&
        commitResult.rollbackAvailable &&
        commitResult.notPublished &&
        panel.commitReadback() == after &&
        panel.commitRollbackBoundary() == before

    println("cjgui settings demo app: demo=settings")
    println("cjgui settings demo app: status_before=scaffolded")
    println("cjgui settings demo app: status_after=runnable")
    println("cjgui settings demo app: main_declared=true")
    println("cjgui settings demo app: deterministic_output=true")
    println("cjgui settings demo app: layout=sectioned_form")
    println("cjgui settings demo app: controls=toggle:auto_save,select:theme,text:username")
    println("cjgui settings demo app: interaction=toggle_auto_save,select_theme,update_username,move_focus")
    println("cjgui settings demo app: state_before=${before}")
    println("cjgui settings demo app: state_after=${after}")
    println("cjgui settings demo app: state_readback=${readbackOk}")
    println("cjgui settings demo app: summary_after=${summary}")
    println("cjgui settings demo app: public_api_consumed=true")
    println("cjgui settings demo app: public_api_name=CjguiExperimentalDemoComponentActionSession")
    println("cjgui settings demo app: public_api_output=${apiOutput.summary}")
    println("cjgui settings demo app: shared_support=CjguiExperimentalDemoComponentActionSession")
    println("cjgui settings demo app: shared_support_output=${panel.sharedSupportOutput()}")
    println("cjgui settings demo app: shared_state_core=${panel.sharedUiState()}")
    println("cjgui settings demo app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession")
    println("cjgui settings demo app: shared_component_action_output=${panel.sharedComponentActionSummary()}")
    println("cjgui settings demo app: shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession")
    println("cjgui settings demo app: shared_commit_output=${commitResult.summary}")
    println("cjgui settings demo app: shared_commit_readback=${panel.commitReadback()}")
    println("cjgui settings demo app: shared_commit_rollback_boundary=${panel.commitRollbackBoundary()}")
    println("cjgui settings demo app: shared_commit_not_published=${commitResult.notPublished}")
    println("cjgui settings demo app: public_api_available=true")

    if (readbackOk) {
        return 0
    }
    return 1
}
