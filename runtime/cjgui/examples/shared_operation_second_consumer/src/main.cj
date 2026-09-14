package cjgui_shared_operation_second_consumer

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.time.*

private let READ_ONLY_RECORD_ID: Int64 = 7110
private let WRITABLE_RECORD_ID: Int64 = 7127
private let UNAUTHORIZED_LURE_RECORD_ID: Int64 = 7199
private let LONG_TITLE_RECORD_ID: Int64 = 7201
private let SAME_LOOKING_TITLE = "同名批量任务"
private let CAPABILITY_VARIABLE = "CJGUI_SECOND_CONSUMER_CAPABILITY"

private func buildLongChineseTitle(): String {
    var title = "屏幕外长标题："
    while (title.size < 9 * 1024) {
        title = "${title}中文长期任务内容；"
    }
    return title
}

private func declaredRecords(): ArrayList<CjguiSharedOperationRecord> {
    return ArrayList<CjguiSharedOperationRecord>(
        [
            CjguiSharedOperationRecord(READ_ONLY_RECORD_ID, "只读中文,;|\n第二行", false),
            CjguiSharedOperationRecord(WRITABLE_RECORD_ID, SAME_LOOKING_TITLE, false),
            CjguiSharedOperationRecord(UNAUTHORIZED_LURE_RECORD_ID, SAME_LOOKING_TITLE, false),
            CjguiSharedOperationRecord(LONG_TITLE_RECORD_ID, buildLongChineseTitle(), false)
        ]
    )
}

private func maxClientsFromArguments(args: Array<String>): ?Int64 {
    if (args.size == 0) {
        return Some(-1)
    }
    if (args.size != 2 || args[0] != "--max-clients") {
        return None
    }
    if (let Some(value) <- Int64.tryParse(args[1])) {
        if (value > 0 && value <= 1024) {
            return Some(value)
        }
    }
    return None
}

private func durationMsFromArguments(args: Array<String>): ?Int64 {
    if (args.size == 2 && args[0] == "--duration-ms") {
        if (let Some(value) <- Int64.tryParse(args[1])) {
            // This is a diagnostic run mode, not a daemon-management API.
            // Keep it bounded while allowing the documented ten-minute run.
            if (value > 0 && value <= 15 * 60 * 1000) {
                return Some(value)
            }
        }
    }
    return None
}

private func grantedCapability(): ?String {
    if (let Some(capability) <- getVariable(CAPABILITY_VARIABLE)) {
        if (capability.size > 0) {
            return Some(capability)
        }
    }
    return None
}

private func reportUsage(): Int64 {
    let error = getStdErr()
    error.writeln("usage: set ${CAPABILITY_VARIABLE}, then main [--max-clients POSITIVE_COUNT]")
    error.writeln("the capability is delivered to the already-authorized caller only through the 0600 descriptor")
    error.flush()
    return 2
}

private func runConsumer(capability: String, maxClients: Int64): Int64 {
    let list = CjguiSharedOperationList(declaredRecords())
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>(
        [
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope(
                "SET_MARKED",
                ArrayList<Int64>([WRITABLE_RECORD_ID]),
                false
            )
        ]
    )
    let authorization = CjguiSharedOperationExternalAuthorization(
        "第二消费者验收 Agent",
        capability,
        scopes
    )
    let connection = CjguiSharedOperationExternalConnection(list, authorization)
    if (!connection.start()) {
        let error = getStdErr()
        error.writeln("second consumer: connection start failed")
        error.flush()
        connection.close()
        return 1
    }

    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln(
            "CJGUI_READY_V2 DESCRIPTOR_PATH_UTF8_HEX ${info.descriptorPath.size} ${CjguiSharedOperationFrame.encodeUtf8Hex(info.descriptorPath)}")
        output.flush()
    } else {
        let error = getStdErr()
        error.writeln("second consumer: started without connection discovery")
        error.flush()
        connection.close()
        return 1
    }

    var servedClients: Int64 = 0
    while (maxClients < 0 || servedClients < maxClients) {
        if (connection.pump(50u32)) {
            servedClients += 1
        }
    }
    connection.close()
    return 0
}

/// Uses exactly the normal second-consumer domain and owner pump, but emits
/// local transport counters every five seconds for a bounded benchmark run.
/// It does not add a descriptor command, mutate the list, or expose counters
/// to external clients.
private func runDiagnosticsConsumer(capability: String, durationMs: Int64): Int64 {
    let list = CjguiSharedOperationList(declaredRecords())
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>(
        [
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope(
                "SET_MARKED",
                ArrayList<Int64>([WRITABLE_RECORD_ID]),
                false
            )
        ]
    )
    let authorization = CjguiSharedOperationExternalAuthorization(
        "第二消费者性能基线", capability, scopes
    )
    let connection = CjguiSharedOperationExternalConnection(list, authorization)
    if (!connection.start()) {
        getStdErr().writeln("second consumer diagnostics: connection start failed")
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln(
            "CJGUI_READY_V2 DESCRIPTOR_PATH_UTF8_HEX ${info.descriptorPath.size} ${CjguiSharedOperationFrame.encodeUtf8Hex(info.descriptorPath)}")
        output.flush()
    } else {
        connection.close()
        return 1
    }

    let output = getStdOut()
    let started = MonoTime.now()
    // Give all five spawned loops a short chance to enter before the first
    // sample.  The earlier zero-millisecond snapshot measured only retained
    // futures and could incorrectly show no active loop.
    var nextDiagnosticMs: Int64 = 100
    while ((MonoTime.now() - started).toMilliseconds() < durationMs) {
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        if (elapsedMs >= nextDiagnosticMs) {
            if (let Some(diagnostics) <- connection.transportDiagnostics()) {
                output.writeln(
                    "CJGUI_TRANSPORT_DIAGNOSTICS_V2 ELAPSED_MS ${elapsedMs} " +
                    "RETAINED_WORKERS ${diagnostics.retainedWorkerCount} " +
                    "ACTIVE_IO_WORKERS ${diagnostics.activeIoWorkerCount} " +
                    "ACCEPTED ${diagnostics.acceptedClientCount} " +
                    "ACTIVE ${diagnostics.activeClientCount} " +
                    "READY ${diagnostics.readyRequestCount} " +
                    "READY_BYTES ${diagnostics.queuedRequestBytes} " +
                    "ACCEPTED_HIGH_WATER ${diagnostics.acceptedClientHighWater} " +
                    "READY_HIGH_WATER ${diagnostics.readyRequestHighWater} " +
                    "READY_BYTES_HIGH_WATER ${diagnostics.readyRequestBytesHighWater}"
                )
                output.flush()
            }
            nextDiagnosticMs += 1000
        }
        let _ = connection.pump(10u32)
    }
    connection.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (let Some(durationMs) <- durationMsFromArguments(args)) {
        if (let Some(capability) <- grantedCapability()) {
            return runDiagnosticsConsumer(capability, durationMs)
        }
    }
    if (let Some(maxClients) <- maxClientsFromArguments(args)) {
        if (let Some(capability) <- grantedCapability()) {
            return runConsumer(capability, maxClients)
        }
    }
    return reportUsage()
}
