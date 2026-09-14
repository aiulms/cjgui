package cjgui_backup_rule_config_consumer

import cjgui_backup_rule_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*

private let CAPABILITY_VARIABLE = "CJGUI_BACKUP_RULE_CAPABILITY"

private class ConsumerArguments {
    let maxClients: Int64
    let humanLabel: String
    let grantsExternalApply: Bool
    init(maxClients: Int64, humanLabel: String, grantsExternalApply: Bool) {
        this.maxClients = maxClients; this.humanLabel = humanLabel; this.grantsExternalApply = grantsExternalApply
    }
}

private func parseArguments(args: Array<String>): ?ConsumerArguments {
    var maxClients: Int64 = -1
    var humanLabel = ""
    var grantsExternalApply = false
    var index: Int64 = 0
    while (index < args.size) {
        if (args[index] == "--grant-apply") {
            if (grantsExternalApply) { return None }
            grantsExternalApply = true; index += 1
        } else {
            if (index + 1 >= args.size) { return None }
            if (args[index] == "--max-clients") {
                if (maxClients >= 0) { return None }
                if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                    if (value > 0 && value <= 1024) { maxClients = value } else { return None }
                } else { return None }
            } else if (args[index] == "--human-label") {
                if (humanLabel.size > 0 || args[index + 1].size == 0 || args[index + 1].size > 128) { return None }
                humanLabel = args[index + 1]
            } else { return None }
            index += 2
        }
    }
    return Some(ConsumerArguments(maxClients, humanLabel, grantsExternalApply))
}

private func capabilityFromTrustedIngress(): ?String {
    if (let Some(capability) <- getVariable(CAPABILITY_VARIABLE)) {
        if (capability.size > 0) { return Some(capability) }
    }
    return None
}

private func authorization(capability: String, grantsExternalApply: Bool): CjguiSharedOperationExternalAuthorization {
    let editableText = ArrayList<Int64>([
        CjguiBackupRuleEditingDomain.ruleLabelResourceId,
        CjguiBackupRuleEditingDomain.retentionCountResourceId,
        CjguiBackupRuleEditingDomain.excludedTypeResourceId
    ])
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([
            CjguiBackupRuleEditingDomain.configurationResourceId,
            CjguiBackupRuleEditingDomain.ruleLabelResourceId,
            CjguiBackupRuleEditingDomain.enabledResourceId,
            CjguiBackupRuleEditingDomain.retentionCountResourceId,
            CjguiBackupRuleEditingDomain.excludedTypeResourceId
        ]), false),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", editableText, false),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", ArrayList<Int64>([CjguiBackupRuleEditingDomain.enabledResourceId]), false)
    ])
    if (grantsExternalApply) {
        scopes.add(CjguiSharedOperationExternalActionScope("APPLY_DRAFT", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false))
        scopes.add(CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false))
        scopes.add(CjguiSharedOperationExternalActionScope("APPLY_BACKUP_RULE", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false))
        scopes.add(CjguiSharedOperationExternalActionScope("SET_RULE_LABEL", ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]), false))
    }
    return CjguiSharedOperationExternalAuthorization("备份规则独立调用者", capability, scopes)
}

private func applyHumanLabel(domain: CjguiBackupRuleEditingDomain, label: String): Bool {
    if (label.size == 0) { return true }
    return domain.executeFromHuman(CjguiSharedOperationActionInvocation(
        "SET_RULE_LABEL", 0, ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string(label))])
    )).applied
}

private func runConsumer(options: ConsumerArguments, capability: String): Int64 {
    let domain = CjguiBackupRuleEditingDomain()
    if (!applyHumanLabel(domain, options.humanLabel)) { return 1 }
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(capability, options.grantsExternalApply))
    if (!connection.start()) { return 1 }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_BACKUP_RULE_READY DESCRIPTOR_PATH_UTF8_HEX ${info.descriptorPath.size} ${CjguiSharedOperationFrame.encodeUtf8Hex(info.descriptorPath)}")
        output.flush()
    } else { connection.close(); return 1 }
    var servedClients: Int64 = 0
    while (options.maxClients < 0 || servedClients < options.maxClients) {
        if (connection.pump(50u32)) { servedClients += 1 }
    }
    connection.close(); return 0
}

main(args: Array<String>): Int64 {
    if (let Some(options) <- parseArguments(args)) {
        if (let Some(capability) <- capabilityFromTrustedIngress()) { return runConsumer(options, capability) }
    }
    let error = getStdErr()
    error.writeln("usage: set ${CAPABILITY_VARIABLE}, then main [--human-label LABEL] [--grant-apply] [--max-clients POSITIVE_COUNT]")
    error.flush(); return 2
}
