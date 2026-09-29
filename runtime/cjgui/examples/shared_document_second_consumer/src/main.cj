package cjgui_shared_document_second_consumer

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*

private let PRIMARY_DOCUMENT_ID: Int64 = 8101
private let SECONDARY_DOCUMENT_ID: Int64 = 8102
private let READ_ONLY_ARCHIVE_ID: Int64 = 8199

private func documents(): ArrayList<CjguiTextDocument> {
    return ArrayList<CjguiTextDocument>([
        CjguiTextDocument(PRIMARY_DOCUMENT_ID, "北区交接文档", "第一行：在场值班员\n第二行：等待复核🙂"),
        CjguiTextDocument(SECONDARY_DOCUMENT_ID, "南区复盘笔记", "这是独立无界面消费者创建的第二份文档。"),
        CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，不授予远程内容读取或替换。")
    ])
}

/// The two content documents are the only snapshot-readable resources. The
/// read-only archive stays outside every SNAPSHOT_* scope, so a lease can never
/// freeze it even though it remains discoverable.
private func authorization(): CjguiSharedOperationExternalAuthorization {
    return authorizationFor("共享文档第二消费者 Agent",
        "cjgui-shared-document-second-consumer-20260912")
}

/// Same scopes, explicit identity: the control channel's `regrant` installs a
/// replacement credential through the host's own lifecycle (close -> grant ->
/// reinstall provider -> restart), so the acceptance exercises the real socket
/// rather than a direct core call.
private func authorizationFor(
    caller: String, capability: String): CjguiSharedOperationExternalAuthorization {
    let contentTargets = ArrayList<Int64>([PRIMARY_DOCUMENT_ID, SECONDARY_DOCUMENT_ID])
    return CjguiSharedOperationExternalAuthorization(
        caller,
        capability,
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("READ_RANGE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("SELECT_DOCUMENT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("INSERT_TEXT", contentTargets, false),
            CjguiSharedOperationExternalActionScope("DELETE_RANGE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("REPLACE_RANGE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_ACQUIRE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_READ", contentTargets, false),
            CjguiSharedOperationExternalActionScope("SNAPSHOT_RELEASE", contentTargets, false)
        ])
    )
}

/// Parsed command line. `maxClients < 0` means "run until closed"; the
/// snapshot acceptance drives `exit` through the control file instead.
private class ConsumerOptions {
    let maxClients: Int64
    let leaseTtlMs: Int64
    let controlPath: String
    let eventsPath: String

    init(maxClients: Int64, leaseTtlMs: Int64, controlPath: String, eventsPath: String) {
        this.maxClients = maxClients
        this.leaseTtlMs = leaseTtlMs
        this.controlPath = controlPath
        this.eventsPath = eventsPath
    }
}

private func optionsFromArguments(args: Array<String>): ?ConsumerOptions {
    var maxClients: Int64 = -1
    var leaseTtlMs: Int64 = 0
    var controlPath = ""
    var eventsPath = ""
    var index = 0
    while (index < args.size) {
        let option = args[index]
        if (option == "--max-clients") {
            if (index + 1 >= args.size) { return None }
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0 && value <= 1024) {
                    maxClients = value
                    index += 2
                    continue
                }
            }
            return None
        }
        if (option == "--lease-ttl-ms") {
            if (index + 1 >= args.size) { return None }
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0) {
                    leaseTtlMs = value
                    index += 2
                    continue
                }
            }
            return None
        }
        if (option == "--control") {
            if (index + 1 >= args.size || args[index + 1].size == 0) { return None }
            controlPath = args[index + 1]
            index += 2
            continue
        }
        if (option == "--events") {
            if (index + 1 >= args.size || args[index + 1].size == 0) { return None }
            eventsPath = args[index + 1]
            index += 2
            continue
        }
        return None
    }
    return Some(ConsumerOptions(maxClients, leaseTtlMs, controlPath, eventsPath))
}

private func usage(): Int64 {
    let error = getStdErr()
    error.writeln("usage: main [--max-clients POSITIVE_COUNT] [--lease-ttl-ms POSITIVE_MS] [--control PATH] [--events PATH]")
    error.writeln("discover the private endpoint and capability from the emitted descriptor; do not reconstruct either")
    error.flush()
    return 2
}

/// Deterministic control/event channel for a real socket acceptance.
///
/// The control file is an append-only command log; the app consumes only NEW
/// complete lines, tracked by byte offset, so a line the writer is still
/// composing is left for the next poll. Each executed command appends exactly
/// one receipt line to the events file, `EVENT control <command> <ok|reason>`,
/// where the reason is what the owner API reported (or `ok` when it applied).
private class ConsumerControlChannel {
    private let controlPath: String
    private let eventsPath: String
    private var consumedBytes: Int64 = 0

    init(controlPath: String, eventsPath: String) {
        this.controlPath = controlPath
        this.eventsPath = eventsPath
    }

    func isEnabled(): Bool {
        return this.controlPath.size > 0
    }

    /// Executes every complete new command; returns true when `exit` was
    /// consumed so the pump loop can end cleanly.
    func poll(connection: CjguiSharedOperationExternalConnection,
        workspace: CjguiTextDocumentWorkspace,
        provider: CjguiTextDocumentSnapshotProvider,
        limits: CjguiSharedOperationSnapshotLeaseLimits): Bool {
        let pending = this.takeCompleteCommandText()
        if (pending.size == 0) { return false }
        var exitRequested = false
        for (raw in pending.split("\n", removeEmpty: true)) {
            let command = raw.trimAscii()
            if (command.size == 0) { continue }
            let reason = this.execute(command, connection, workspace, provider, limits)
            this.record(command, reason)
            if (command == "exit") { exitRequested = true }
        }
        return exitRequested
    }

    /// Everything up to and including the last newline that is beyond the
    /// already-consumed offset. A trailing partial line is never parsed.
    private func takeCompleteCommandText(): String {
        if (!exists(this.controlPath)) { return "" }
        var bytes = Array<Byte>()
        try {
            bytes = File.readFrom(this.controlPath)
        } catch (_) {
            return ""
        }
        let size = Int64(bytes.size)
        if (size <= this.consumedBytes) { return "" }
        var lastNewline: Int64 = -1
        var cursor = size - 1
        while (cursor >= this.consumedBytes) {
            if (bytes[cursor] == b'\n') {
                lastNewline = cursor
                break
            }
            cursor -= 1
        }
        if (lastNewline < 0) { return "" }
        let length = lastNewline + 1 - this.consumedBytes
        let chunk = String.fromUtf8(bytes.slice(this.consumedBytes, length))
        this.consumedBytes = lastNewline + 1
        return chunk
    }

    private func execute(command: String, connection: CjguiSharedOperationExternalConnection,
        workspace: CjguiTextDocumentWorkspace,
        provider: CjguiTextDocumentSnapshotProvider,
        limits: CjguiSharedOperationSnapshotLeaseLimits): String {
        if (command == "exit") { return "ok" }
        if (command == "revoke") {
            let _ = connection.revokeAuthorization()
            return "ok"
        }
        if (command.startsWith("regrant ")) {
            let fields = command.split(" ")
            if (fields.size != 3 || fields[1].size == 0 || fields[2].size == 0) {
                return "invalid_request"
            }
            return regrant(connection, provider, limits, fields[1], fields[2])
        }
        if (command == "workspace") {
            let _ = connection.invalidateSnapshotWorkspace(reason: "snapshot_workspace_changed")
            return "ok"
        }
        if (command.startsWith("close ")) {
            let fields = command.split(" ")
            if (fields.size != 2) { return "invalid_request" }
            if (let Some(documentId) <- Int64.tryParse(fields[1])) {
                let outcome = workspace.closeDocumentFromHuman(documentId)
                if (!outcome.applied) { return outcome.reason }
                // The document is definitively closed: end every lease of THIS
                // resource instance now, so a holder learns a named reason
                // instead of racing the resource's next liveness probe.
                let _ = connection.invalidateSnapshotResource(documentId,
                    provider.resourceInstanceId(documentId), "snapshot_resource_closed")
                return "ok"
            }
        }
        return "invalid_request"
    }

    /// The host's own re-authorization lifecycle, driven through the real
    /// endpoint: stop the old transport (every lease of the old grant becomes
    /// terminal and the old descriptor goes away), install the replacement
    /// credential -- the core refuses a credential this connection already
    /// revoked, by name -- reinstall the provider's lease table and republish.
    /// A refused regrant leaves the endpoint down; it is never silently
    /// half-authorized.
    private func regrant(connection: CjguiSharedOperationExternalConnection,
        provider: CjguiTextDocumentSnapshotProvider,
        limits: CjguiSharedOperationSnapshotLeaseLimits,
        capability: String, caller: String): String {
        connection.close()
        if (!connection.grantAuthorization(authorizationFor(caller, capability))) {
            let refusal = connection.lastGrantRefusalReason()
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_REGRANT REFUSED ${refusal}")
            getStdOut().flush()
            return refusal
        }
        if (!connection.enableSnapshotReads(provider, limits: limits)) {
            let refusal = connection.lastSnapshotEnableRefusalReason()
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_REGRANT REFUSED ${refusal}")
            getStdOut().flush()
            return refusal
        }
        if (!connection.start()) {
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_REGRANT REFUSED endpoint_start_failed")
            getStdOut().flush()
            return "endpoint_start_failed"
        }
        publishReady(connection, "CJGUI_SHARED_DOCUMENT_REGRANT")
        return "ok"
    }

    private func record(command: String, reason: String): Unit {
        if (this.eventsPath.size == 0) { return }
        let line = "EVENT control ${command} ${reason}\n"
        try {
            File.appendTo(this.eventsPath, line.toArray())
        } catch (_) {
            // A receipt the acceptance cannot read is reported by its timeout,
            // never by silently re-labelling the command's outcome.
        }
    }
}

private func startFailure(connection: CjguiSharedOperationExternalConnection, message: String): Int64 {
    let error = getStdErr()
    error.writeln("shared document second consumer: ${message}")
    error.flush()
    connection.close()
    return 1
}

/// Emit the discovery block for the CURRENT endpoint. Used at startup and after
/// a `regrant`, so a holder always learns the descriptor from the host instead
/// of reconstructing an endpoint or capability. `prefix` keeps the two
/// publications distinguishable in one run's stdout.
private func publishReady(connection: CjguiSharedOperationExternalConnection,
    prefix: String): Bool {
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("${prefix} DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("${prefix} PROTOCOL ${info.protocol}")
        output.writeln("${prefix} ACTION_COUNT ${info.actions.size}")
        output.flush()
        return true
    }
    return false
}

private func run(options: ConsumerOptions): Int64 {
    let workspace = CjguiTextDocumentWorkspace(documents())
    let provider = CjguiTextDocumentSnapshotProvider(workspace)
    let connection = CjguiSharedOperationExternalConnection(workspace, authorization(), workspace)
    // A short TTL makes real no-traffic expiry observable inside an acceptance
    // run; the same value is the ceiling, so every lease shares one deadline.
    let snapshotLimits = if (options.leaseTtlMs > 0) {
        CjguiSharedOperationSnapshotLeaseLimits(defaultTtlMs: options.leaseTtlMs,
            maxTtlMs: options.leaseTtlMs)
    } else {
        CjguiSharedOperationSnapshotLeaseLimits()
    }
    if (!connection.enableRangeReads(workspace)) {
        return startFailure(connection, "bounded range read installation failed")
    }
    if (!connection.enableSnapshotReads(provider, limits: snapshotLimits)) {
        return startFailure(connection, "fixed-snapshot provider installation failed")
    }
    if (!connection.start()) {
        return startFailure(connection, "external connection start failed")
    }
    if (!publishReady(connection, "CJGUI_SHARED_DOCUMENT_READY")) {
        return startFailure(connection, "descriptor unavailable")
    }
    let control = ConsumerControlChannel(options.controlPath, options.eventsPath)
    var served: Int64 = 0
    var exitRequested = false
    while (!exitRequested && (options.maxClients < 0 || served < options.maxClients)) {
        if (connection.pump(50u32)) { served += 1 }
        if (control.isEnabled()) {
            exitRequested = control.poll(connection, workspace, provider, snapshotLimits)
        }
    }
    connection.close()
    // Resource-convergence facts: a clean shutdown leaves no active lease and
    // no live provider handle inside this process.
    let output = getStdOut()
    output.writeln("CJGUI_SHARED_DOCUMENT_LEASE_DIAG ${connection.snapshotLeaseDiagnostics()}")
    output.writeln("CJGUI_SHARED_DOCUMENT_HANDLES ${provider.liveHandleCount()}")
    output.flush()
    return 0
}

main(args: Array<String>): Int64 {
    if (let Some(options) <- optionsFromArguments(args)) { return run(options) }
    return usage()
}
