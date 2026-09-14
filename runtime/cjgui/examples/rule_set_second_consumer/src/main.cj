package cjgui_rule_set_second_consumer

import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*

private let capabilityVariable = "CJGUI_RULE_SET_SECOND_CONSUMER_CAPABILITY"

private func maxClientsFromArguments(args: Array<String>): ?Int64 {
    if (args.size == 2 && args[0] == "--max-clients") {
        if (let Some(value) <- Int64.tryParse(args[1])) { if (value > 0 && value <= 64) { return Some(value) } }
    }
    return None
}

private func authorization(capability: String): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "规则集独立消费者", capability,
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
            CjguiSharedOperationExternalActionScope("CREATE_RECORD", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
            CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
            CjguiSharedOperationExternalActionScope("BATCH_SET_ENABLED", all, true),
            CjguiSharedOperationExternalActionScope("UNDO", all, true)
        ])
    )
}

private func runConsumer(capability: String, maxClients: Int64): Int64 {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(capability), domain)
    if (!connection.start()) { getStdErr().writeln("rule-set second consumer: connection start failed"); return 1 }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_RULE_SET_READY_V1 DESCRIPTOR_PATH_UTF8_HEX ${info.descriptorPath.size} ${CjguiSharedOperationFrame.encodeUtf8Hex(info.descriptorPath)}")
        output.flush()
    } else { connection.close(); return 1 }
    var served: Int64 = 0
    while (served < maxClients) { if (connection.pump(50u32)) { served += 1 } }
    connection.close(); return 0
}

// Test-only orchestration uses two independent OS processes, but each process
// reaches persistence solely through the production domain methods below. The
// gate synchronizes their save attempts; it neither creates nor clears the
// domain's adjacent lease directory.
private func waitForSaveRaceGate(): Unit {
    if (let Some(readyPath) <- getVariable("CJGUI_RULE_SET_SAVE_RACE_READY")) {
        if (readyPath.size > 0) { File.writeTo(Path(readyPath), "ready".toArray()) }
    }
    if (let Some(gatePath) <- getVariable("CJGUI_RULE_SET_SAVE_RACE_GATE")) {
        while (gatePath.size > 0 && exists(gatePath)) { sleep(Duration.millisecond) }
    }
}

private func seedSave(path: String): Int64 {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let created = domain.createRecordFromHuman("种子规则", true, 7, "cache", "race-seed")
    let saved = if (created.applied) { domain.saveAsFromHuman(path) }
        else { CjguiSharedOperationActionResult(false, false, 0, 0, created.reason) }
    getStdOut().writeln("SAVE_RESULT ${saved.reason}")
    return if (saved.applied) { 0 } else { 3 }
}

private func raceSave(path: String, label: String): Int64 {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    if (!domain.openFromHuman(path).applied) { getStdOut().writeln("SAVE_RESULT open_failed"); return 3 }
    if (!domain.createRecordFromHuman(label, true, 7, "cache", "race-${label}").applied) { getStdOut().writeln("SAVE_RESULT create_failed"); return 3 }
    waitForSaveRaceGate()
    let saved = domain.saveFromHuman()
    getStdOut().writeln("SAVE_RESULT ${saved.reason}")
    return if (saved.applied || saved.reason == "save_in_progress" || saved.reason == "external_file_conflict") { 0 } else { 3 }
}

main(args: Array<String>): Int64 {
    if (args.size == 2 && args[0] == "--seed-save") { return seedSave(args[1]) }
    if (args.size == 3 && args[0] == "--save-race") { return raceSave(args[1], args[2]) }
    if (let Some(maxClients) <- maxClientsFromArguments(args)) {
        if (let Some(capability) <- getVariable(capabilityVariable)) { if (capability.size > 0) { return runConsumer(capability, maxClients) } }
    }
    getStdErr().writeln("usage: --seed-save PATH | --save-race PATH LABEL | set ${capabilityVariable}, then main --max-clients POSITIVE_COUNT")
    return 2
}
