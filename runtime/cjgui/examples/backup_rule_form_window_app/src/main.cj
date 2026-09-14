package cjgui_backup_rule_form_window_app

import cjgui.CjguiSharedEditingFormWindow
import cjgui_backup_rule_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

foreign func cjgui_shared_operation_window_app_finish(): Unit

private func finishNativeLauncher() { unsafe { cjgui_shared_operation_window_app_finish() } }

private func authorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "独立表单验收 Agent", "cjgui-backup-rule-form-agent-20260912",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([
                CjguiBackupRuleEditingDomain.configurationResourceId,
                CjguiBackupRuleEditingDomain.ruleLabelResourceId,
                CjguiBackupRuleEditingDomain.enabledResourceId,
                CjguiBackupRuleEditingDomain.retentionCountResourceId,
                CjguiBackupRuleEditingDomain.excludedTypeResourceId
            ]), false),
            CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", ArrayList<Int64>([
                CjguiBackupRuleEditingDomain.ruleLabelResourceId,
                CjguiBackupRuleEditingDomain.retentionCountResourceId,
                CjguiBackupRuleEditingDomain.excludedTypeResourceId
            ]), false),
            CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", ArrayList<Int64>([CjguiBackupRuleEditingDomain.enabledResourceId]), false),
            CjguiSharedOperationExternalActionScope("APPLY_DRAFT", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false),
            CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false)
        ])
    )
}

private func runBackupRuleFormApp(): Int32 {
    let domain = CjguiBackupRuleEditingDomain()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization())
    let window = CjguiSharedEditingFormWindow(domain)
    if (!window.start() || !connection.start()) {
        window.close(); connection.close(); finishNativeLauncher(); return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_BACKUP_RULE_FORM_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_BACKUP_RULE_FORM_READY PROTOCOL ${info.protocol}")
        output.flush()
    }
    while (window.isOpen()) {
        let _ = connection.pump(1u32)
        let _ = window.pump(16u32)
        sleep(Duration.millisecond * 16)
    }
    connection.close()
    finishNativeLauncher()
    return 0
}

main(): Int64 { return Int64(runBackupRuleFormApp()) }
