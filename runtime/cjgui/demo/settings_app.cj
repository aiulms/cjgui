package cjgui_settings_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}

// 中文维护注释：这是独立 Settings demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 Settings demo 消费 CJGUI experimental 非 Bool public API，并执行 owner-local 状态写入读回。
// Stop-line: 只做 demo-host in-memory 状态，不调用 native bridge，不提交 renderer。

class SettingsPanelState {
    let demoName: String
    let layoutKind: String
    let controlsSummary: String
    var selectedTheme: String
    var usernameValue: String
    var focusTarget: String
    var autoSaveEnabled: Bool

    init() {
        this.demoName = "settings"
        this.layoutKind = "sectioned_form"
        this.controlsSummary = "toggle:auto_save,select:theme,text:username"
        this.selectedTheme = "light"
        this.usernameValue = "owner"
        this.focusTarget = "username_field"
        this.autoSaveEnabled = false
    }

    func toggleAutoSave() {
        autoSaveEnabled = !autoSaveEnabled
    }

    func selectTheme(theme: String) {
        selectedTheme = theme
    }

    func updateUsername(username: String) {
        usernameValue = username
    }

    func moveFocus(target: String) {
        focusTarget = target
    }

    func businessState(): String {
        return "autosave=${autoSaveEnabled};theme=${selectedTheme};username=${usernameValue};focus=${focusTarget}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${layoutKind};controls=${controlsSummary};${businessState()}"
    }

}

main(): Int64 {
    let panel = SettingsPanelState()
    let before = panel.businessState()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("settings", before)
    panel.toggleAutoSave()
    sharedTrace.recordAction("settings.toggle_auto_save", panel.businessState())
    panel.selectTheme("dark")
    sharedTrace.recordAction("settings.select_theme", panel.businessState())
    panel.updateUsername("owner-updated")
    sharedTrace.recordAction("settings.update_username", panel.businessState())
    panel.moveFocus("theme_select")
    let after = panel.businessState()
    sharedTrace.recordAction("settings.move_focus", after)
    let summary = panel.summary()
    let stateReadbackOk = before == "autosave=false;theme=light;username=owner;focus=username_field" &&
        after == "autosave=true;theme=dark;username=owner-updated;focus=theme_select" &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus" &&
        sharedTrace.writes() == 4 &&
        summary == "demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select"
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, summary, stateReadbackOk)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "settings" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=settings;readback=true;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select;summary=demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select"

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
    println("cjgui settings demo app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui settings demo app: public_api_output=${apiOutput.summary}")
    println("cjgui settings demo app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui settings demo app: shared_support_output=${sharedTrace.summary()}")
    println("cjgui settings demo app: public_api_available=true")

    if (readbackOk) {
        return 0
    }
    return 1
}
