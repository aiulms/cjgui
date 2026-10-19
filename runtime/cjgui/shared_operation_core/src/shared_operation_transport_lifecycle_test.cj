package cjgui_shared_operation_core

import std.collection.*
import std.collection.concurrent.*
import std.env.*
import std.fs.*
import std.net.*
import std.sync.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func lifecycleAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "生命周期验收调用者",
        "lifecycle-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([901]), false)
            ]
        )
    )
}

private class WaitingLifecycleGate <: CjguiSharedOperationOwnerWriteGate {
    var ready: Bool = false
    var terminal: Bool = false
    public func admitOwnerWrite(invocation: CjguiSharedOperationActionInvocation,
        previous: ?CjguiSharedOperationOwnerWriteAdmission): CjguiSharedOperationOwnerWriteAdmission {
        return CjguiSharedOperationOwnerWriteAdmission(
            if (terminal) { CjguiSharedOperationOwnerWriteAdmissionKind.TerminalRefusal }
            else if (ready) { CjguiSharedOperationOwnerWriteAdmissionKind.Ready }
            else { CjguiSharedOperationOwnerWriteAdmissionKind.WaitOriginal },
            ownerKey: "owner:901", predecessor: 17u64, binding: 11, reason: "original_predecessor_failed")
    }
}

@Test
func originalWaitingLeaseKeepsChargeAndCancellation(): Unit {
    let state = CjguiSharedOperationIoState()
    let request = CjguiSharedOperationPendingClientRequest(lifecycleSetMarkedPayload())
    let lease = state.tryQueueRequest(request).getOrThrow()
    @Assert(state.readyBatch(0u32).size, 1)
    @Assert(request.isWaitingForOwner(), true)
    @Assert(state.diagnostics().queuedRequestBytes, request.payload.size)
    @Assert(state.diagnostics().readyRequestCount, 1)
    @Assert(state.readyBatch(0u32).size, 1)
    @Assert(request.cancelIfUnclaimed(), true)
    @Assert(request.claimForOwner(), false)
    state.releaseReadyCharge(lease)
    state.releaseReadyCharge(lease)
    @Assert(state.diagnostics().queuedRequestBytes, 0)
    @Assert(state.diagnostics().readyRequestCount, 0)
    state.stop()
}

@Test
func originalWaitingPublicWriteLetsReadPassThenExecutesOnce(): Unit {
    let list = lifecycleList()
    let gate = WaitingLifecycleGate()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    @Assert(connection.enableOwnerWriteAdmission(gate), true)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        let writer = spawn { => requestLifecyclePayload(path, lifecycleSetMarkedPayload()) }
        let queued = MonoTime.now()
        while (connection.transportDiagnostics().getOrThrow().readyRequestCount == 0 &&
            (MonoTime.now() - queued).toMilliseconds() < 80) { sleep(Duration.millisecond) }
        @Assert(connection.pump(0u32), false)
        @Assert(list.snapshot().version, 0)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes > 0, true)
        let reader = spawn { => requestLifecycleContext(path) }
        let until = MonoTime.now()
        while (!connection.pump(0u32) && (MonoTime.now() - until).toMilliseconds() < 80) {
            sleep(Duration.millisecond)
        }
        @Assert(reader.get().contains("KIND SNAPSHOT"), true)
        @Assert(list.snapshot().version, 0)
        gate.ready = true
        @Assert(connection.pump(0u32), true)
        @Assert(writer.get().contains("APPLIED true"), true)
        @Assert(list.snapshot().version, 1)
        @Assert(connection.pump(0u32), false)
        @Assert(list.snapshot().version, 1)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
        @Assert(connection.transportDiagnostics().getOrThrow().readyRequestCount, 0)
    } finally { connection.close() }
}

@Test
func originalWaitingPublicWriteExpiresWithoutOwnerCallback(): Unit {
    let list = lifecycleList()
    let gate = WaitingLifecycleGate()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    let _ = connection.enableOwnerWriteAdmission(gate)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        let writer = spawn { => requestLifecyclePayloadWithTimeout(path, lifecycleSetMarkedPayload(), 600) }
        let started = MonoTime.now()
        while ((MonoTime.now() - started).toMilliseconds() < 280) {
            @Assert(connection.pump(0u32), false)
            sleep(Duration.millisecond * 4)
        }
        gate.ready = true
        @Assert(connection.pump(0u32), false)
        @Assert(writer.get().contains("owner_busy"), true)
        @Assert(list.snapshot().version, 0)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
    } finally { connection.close() }
}

private func lifecycleList(): CjguiSharedOperationList {
    return CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>([CjguiSharedOperationRecord(901, "多字节\n标题", false)])
    )
}

private func awaitLifecycleReadyCount(connection: CjguiSharedOperationExternalConnection, count: Int64): Unit {
    let started = MonoTime.now()
    while (connection.transportDiagnostics().getOrThrow().readyRequestCount < count &&
        (MonoTime.now() - started).toMilliseconds() < 80) { sleep(Duration.millisecond) }
    @Assert(connection.transportDiagnostics().getOrThrow().readyRequestCount, count)
}

@Test
func originalWaitingPublicWriteTerminalAndRevocationNeverExecute(): Unit {
    for (revoked in [false, true]) {
        let list = lifecycleList()
        let gate = WaitingLifecycleGate()
        let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
        let _ = connection.enableOwnerWriteAdmission(gate)
        @Assert(connection.start(), true)
        try {
            let path = connection.connectionInfo().getOrThrow().socketPath
            let writer = spawn { => requestLifecyclePayload(path, lifecycleSetMarkedPayload()) }
            awaitLifecycleReadyCount(connection, 1)
            @Assert(connection.pump(0u32), false)
            if (revoked) { let _ = connection.revokeAuthorization() } else { gate.terminal = true }
            @Assert(connection.pump(0u32), true)
            let response = writer.get()
            @Assert(response.contains("APPLIED true"), false)
            @Assert(response.contains(if (revoked) { "authorization_revoked" } else { "original_predecessor_failed" }), true)
            @Assert(list.snapshot().version, 0)
            @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
            @Assert(connection.transportDiagnostics().getOrThrow().readyRequestCount, 0)
        } finally { connection.close() }
    }
}

@Test
func originalWaitingPublicWriteKeepsExpectedVersionAfterHumanAdvance(): Unit {
    let list = lifecycleList()
    let gate = WaitingLifecycleGate()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    let _ = connection.enableOwnerWriteAdmission(gate)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        let writer = spawn { => requestLifecyclePayload(path, lifecycleSetMarkedPayload()) }
        awaitLifecycleReadyCount(connection, 1)
        @Assert(connection.pump(0u32), false)
        let _ = list.setMarkedFromHuman(901, true)
        @Assert(list.snapshot().version, 1)
        gate.ready = true
        @Assert(connection.pump(0u32), true)
        let response = writer.get()
        @Assert(response.contains("APPLIED false"), true)
        @Assert(response.contains("CONFLICT true"), true)
        @Assert(list.snapshot().version, 1)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
    } finally { connection.close() }
}

@Test
func originalWaitingPublicWriteCloseReleasesOriginalLease(): Unit {
    let list = lifecycleList()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    let _ = connection.enableOwnerWriteAdmission(WaitingLifecycleGate())
    @Assert(connection.start(), true)
    let path = connection.connectionInfo().getOrThrow().socketPath
    let writer = spawn { => requestLifecyclePayload(path, lifecycleSetMarkedPayload()) }
    awaitLifecycleReadyCount(connection, 1)
    @Assert(connection.pump(0u32), false)
    connection.close()
    @Assert(writer.get().contains("APPLIED true"), false)
    @Assert(connection.pump(0u32), false)
    @Assert(list.snapshot().version, 0)
    @Assert(connection.transportDiagnostics().isNone(), true)
}

@Test
func acceptedPublicWritePeerCloseCannotReplayOwnerTransaction(): Unit {
    let list = lifecycleList()
    let gate = WaitingLifecycleGate()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    let _ = connection.enableOwnerWriteAdmission(gate)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        try (client = UnixSocket(path)) {
            client.connect()
            client.write(CjguiSharedOperationFrame.encode(lifecycleSetMarkedPayload()))
            awaitLifecycleReadyCount(connection, 1)
            @Assert(connection.pump(0u32), false)
        }
        gate.ready = true
        @Assert(connection.pump(0u32), true)
        @Assert(list.snapshot().version, 1)
        @Assert(connection.pump(0u32), false)
        @Assert(list.snapshot().version, 1)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
    } finally { connection.close() }
}

private class TwoOwnerLifecycleDomain <: CjguiSharedOperationDomain & CjguiSharedOperationOwnerWriteGate {
    let first = lifecycleList()
    let second = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(902, "independent owner", false)]))
    let executions = ArrayList<Int64>()
    var ready: Bool = false
    public func resourceType(): String { return "two_owner_lifecycle" }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> { return first.actionDescriptors() }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>(first.contextSnapshot().resources)
        for (resource in second.contextSnapshot().resources) { resources.add(resource) }
        return CjguiSharedOperationContextSnapshot(first.version() + second.version(), "two owners", resourceType(), resources)
    }
    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return first.executeFromHuman(invocation)
    }
    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let target = invocation.targetResourceIds[0]
        executions.add(target)
        return if (target == 901) { first.executeFromExternal(invocation) } else { second.executeFromExternal(invocation) }
    }
    public func admitOwnerWrite(invocation: CjguiSharedOperationActionInvocation,
        previous: ?CjguiSharedOperationOwnerWriteAdmission): CjguiSharedOperationOwnerWriteAdmission {
        let target = invocation.targetResourceIds[0]
        return CjguiSharedOperationOwnerWriteAdmission(
            if (target == 901 && !ready) { CjguiSharedOperationOwnerWriteAdmissionKind.WaitOriginal }
            else { CjguiSharedOperationOwnerWriteAdmissionKind.Ready },
            ownerKey: "owner:${target}", predecessor: if (target == 901) { 17u64 } else { 0u64 }, binding: target)
    }
}

@Test
func originalWaitingOwnerWritesKeepFifoWhileOtherOwnerAndReadAdvance(): Unit {
    let domain = TwoOwnerLifecycleDomain()
    let authorization = CjguiSharedOperationExternalAuthorization("two owners", "lifecycle-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([901,902]), false)]))
    let connection = CjguiSharedOperationExternalConnection(domain, authorization)
    let _ = connection.enableOwnerWriteAdmission(domain)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        let first = spawn { => requestLifecyclePayload(path, lifecycleSetMarkedPayload()) }
        awaitLifecycleReadyCount(connection, 1)
        @Assert(connection.pump(0u32), false)
        let successorPayload = lifecycleSetMarkedPayload().replace("INVOKE 0", "INVOKE 1").replace("BOOLEAN 1", "BOOLEAN 0")
        let successor = spawn { => requestLifecyclePayload(path, successorPayload) }
        awaitLifecycleReadyCount(connection, 2)
        @Assert(connection.pump(0u32), false)
        let unrelatedPayload = lifecycleSetMarkedPayload().replace("ID 901", "ID 902")
        let unrelated = spawn { => requestLifecyclePayload(path, unrelatedPayload) }
        awaitLifecycleReadyCount(connection, 3)
        @Assert(connection.pump(0u32), true)
        @Assert(unrelated.get().contains("APPLIED true"), true)
        @Assert(domain.first.version(), 0)
        @Assert(domain.second.version(), 1)
        let read = spawn { => requestLifecycleContext(path) }
        awaitLifecycleReadyCount(connection, 3)
        @Assert(connection.pump(0u32), true)
        @Assert(read.get().contains("KIND SNAPSHOT"), true)
        domain.ready = true
        @Assert(connection.pump(0u32), true)
        @Assert(first.get().contains("VERSION_AFTER 1"), true)
        @Assert(connection.pump(0u32), true)
        @Assert(successor.get().contains("VERSION_AFTER 2"), true)
        @Assert(domain.executions.toArray(), [902,901,901])
        @Assert(domain.first.version(), 2)
        @Assert(connection.transportDiagnostics().getOrThrow().queuedRequestBytes, 0)
        @Assert(connection.transportDiagnostics().getOrThrow().readyRequestCount, 0)
    } finally { connection.close() }
}

private func lifecycleContextPayload(): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH lifecycle-capability\nGET_CONTEXT 0"
}

private func lifecycleSetMarkedPayload(): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH lifecycle-capability\nINVOKE 0 SET_MARKED 1 1\nID 901\nARG isMarked BOOLEAN 1"
}

private func lifecyclePaddedPayload(paddingBytes: Int64): String {
    return lifecycleContextPayload() + "\nPAD " +
        String.fromUtf8(Array<Byte>(paddingBytes, repeat: 120))
}

private func largeLifecycleList(): CjguiSharedOperationList {
    let records = ArrayList<CjguiSharedOperationRecord>()
    // The wire body hex-encodes this text, producing a multi-megabyte but
    // still protocol-bounded snapshot.  It makes socket write behavior part
    // of the lifecycle test instead of assuming a tiny response is enough.
    let title = String.fromUtf8(Array<Byte>(8192, repeat: 120))
    var index = 0
    while (index < 160) {
        // A list record projects its title both as resource name and field,
        // so 160 x 8 KiB stays below the 8 MiB response ceiling while still
        // exceeding ordinary local socket buffers by orders of magnitude.
        records.add(CjguiSharedOperationRecord(Int64(2000 + index), title, false))
        index += 1
    }
    return CjguiSharedOperationList(records)
}

private func oversizedLifecycleList(): CjguiSharedOperationList {
    let records = ArrayList<CjguiSharedOperationRecord>()
    // Each record serializes its title as both a resource name and a field.
    // 300 such 8 KiB records crosses the 8 MiB snapshot ceiling without
    // relying on malformed tokens or an oversized individual string.
    let title = String.fromUtf8(Array<Byte>(8192, repeat: 120))
    var index = 0
    while (index < 300) {
        records.add(CjguiSharedOperationRecord(Int64(3000 + index), title, false))
        index += 1
    }
    return CjguiSharedOperationList(records)
}

private func largeLifecycleAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "大响应生命周期调用者",
        "large-lifecycle-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
}

private func largeLifecycleContextPayload(): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH large-lifecycle-capability\nGET_CONTEXT 0"
}

private class OwnerStateLifecycleDomain <: CjguiSharedOperationDomain {
    private let ownerState: String

    init(ownerState: String) { this.ownerState = ownerState }

    public func resourceType(): String { return "owner_state" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        if (ownerState.size == 0) {
            // Keep compiling the pre-ownerState constructor form used by old owners.
            return CjguiSharedOperationContextSnapshot(1, "状态快照", resourceType(),
                ArrayList<CjguiSharedOperationResource>())
        }
        return CjguiSharedOperationContextSnapshot(1, "状态快照", resourceType(),
            ArrayList<CjguiSharedOperationResource>(), ownerState: ownerState)
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 1, 1, "unsupported")
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 1, 1, "unsupported")
    }
}

private func ownerStateLifecycleAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization("owner-state-client", "owner-state-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ]))
}

private func ownerStateLifecycleRequest(): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH owner-state-capability\nGET_CONTEXT 0"
}

@Test
func publicGetContextKeepsLegacyEmptyOwnerStateSnapshotCompatible(): Unit {
    let connection = CjguiSharedOperationExternalConnection(OwnerStateLifecycleDomain(""),
        ownerStateLifecycleAuthorization())
    let response = connection.dispatchPayload(ownerStateLifecycleRequest())

    @Assert(response.contains("KIND SNAPSHOT"), true)
    @Assert(response.contains("OWNER_STATE_UTF8_HEX"), false)
    @Assert(response.contains("PROTOCOL CJGUI_SHARED_OPERATION/2"), true)
}

@Test
func publicGetContextReadsOwnerStateAsExactUtf8Bytes(): Unit {
    let ownerState = "模式=预览🙂"
    let connection = CjguiSharedOperationExternalConnection(OwnerStateLifecycleDomain(ownerState),
        ownerStateLifecycleAuthorization())
    let response = connection.dispatchPayload(ownerStateLifecycleRequest())

    @Assert(response.contains("OWNER_STATE_UTF8_HEX ${ownerState.toArray().size} E6A8A1E5BC8F3DE9A284E8A788F09F9982"), true)
    @Assert(response.contains("ERROR invalid_snapshot"), false)
}

@Test
func publicGetContextNamesOwnerStateStringLimitRejection(): Unit {
    let ownerState = String.fromUtf8(Array<Byte>(64 * 1024 + 1, repeat: 120))
    let connection = CjguiSharedOperationExternalConnection(OwnerStateLifecycleDomain(ownerState),
        ownerStateLifecycleAuthorization())
    let response = connection.dispatchPayload(ownerStateLifecycleRequest())

    @Assert(response.contains("ERROR invalid_snapshot"), true)
    @Assert(response.contains("response_too_large"), false)
}

@Test
func genericTransportClassifiesActualOversizedSnapshot(): Unit {
    let connection = CjguiSharedOperationExternalConnection(oversizedLifecycleList(), largeLifecycleAuthorization())
    let response = connection.dispatchPayload(largeLifecycleContextPayload())

    @Assert(response.contains("ERROR response_too_large"), true)
    @Assert(response.contains("invalid_snapshot"), false)
}

private func readOneLifecycleFrame(client: UnixSocket): String {
    let decoder = CjguiSharedOperationFrameAccumulator()
    while (true) {
        let buffer = Array<Byte>(4096, repeat: 0)
        let count = client.read(buffer)
        if (count <= 0) {
            return ""
        }
        let frame = decoder.append(buffer, count)
        if (frame.isMalformed) {
            return ""
        }
        if (frame.isComplete) {
            return frame.payload
        }
    }
    return ""
}

private func requestLifecyclePayload(socketPath: String, payload: String): String {
    return requestLifecyclePayloadWithTimeout(socketPath, payload, 240)
}

private func requestLifecyclePayloadWithTimeout(socketPath: String, payload: String, readTimeoutMs: Int64): String {
    var response = ""
    try (client = UnixSocket(socketPath)) {
        client.connect()
        client.readTimeout = Some(Duration.millisecond * readTimeoutMs)
        client.write(CjguiSharedOperationFrame.encode(payload))
        response = readOneLifecycleFrame(client)
    } catch (_) {
    }
    return response
}

private func sendLifecyclePayloadWithoutReading(socketPath: String, payload: String, sent: Barrier): Unit {
    try (client = UnixSocket(socketPath)) {
        client.connect()
        client.write(CjguiSharedOperationFrame.encode(payload))
        sent.wait()
        sleep(Duration.millisecond * 800)
    } catch (_) {
        sent.wait()
    }
}

private func requestLifecycleContext(socketPath: String): String {
    return requestLifecyclePayload(socketPath, lifecycleContextPayload())
}

private func sendLifecyclePayloadThenRead(socketPath: String, payload: String, sent: Barrier): String {
    var response = ""
    try (client = UnixSocket(socketPath)) {
        client.connect()
        client.readTimeout = Some(Duration.millisecond * 800)
        client.write(CjguiSharedOperationFrame.encode(payload))
        sent.wait()
        response = readOneLifecycleFrame(client)
    } catch (_) {
        // Do not leave the test owner blocked if a socket setup failed before
        // its peer reached the common post-write point.
        sent.wait()
    }
    return response
}

@Test
func genericTransportFramesUnicodeAndOwnsIndependentPrivateEndpoints(): Unit {
    let payload = "GET_CONTEXT 多字节\n"
    let frame = CjguiSharedOperationFrame.encode(payload)
    let decoder = CjguiSharedOperationFrameAccumulator()
    let first = decoder.append(frame.slice(0, 5), 5)
    @Assert(first.isComplete, false)
    @Assert(first.isMalformed, false)
    let complete = decoder.append(frame.slice(5, frame.size - 5), frame.size - 5)
    @Assert(complete.isComplete, true)
    @Assert(complete.payload, payload)

    let malformed = CjguiSharedOperationFrameAccumulator().append("not-a-frame\n".toArray(), 12)
    @Assert(malformed.isMalformed, true)
    @Assert(malformed.reason, "invalid_frame_header")

    let invalid = CjguiSharedOperationExternalConnection(
        lifecycleList(),
        CjguiSharedOperationExternalAuthorization(
            "bad", "has whitespace", ArrayList<CjguiSharedOperationExternalActionScope>()
        )
    )
    @Assert(invalid.start(), false)

    let firstConnection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    let secondConnection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    @Assert(firstConnection.start(), true)
    @Assert(secondConnection.start(), true)
    if (let Some(firstInfo) <- firstConnection.connectionInfo()) {
        if (let Some(secondInfo) <- secondConnection.connectionInfo()) {
            @Assert(firstInfo.socketPath == secondInfo.socketPath, false)
            @Assert(firstInfo.descriptorPath == secondInfo.descriptorPath, false)
            @Assert(exists(firstInfo.socketPath), true)
            @Assert(exists(firstInfo.descriptorPath), true)
            let descriptor = String.fromUtf8(File.readFrom(firstInfo.descriptorPath))
            @Assert(descriptor.contains("PROTOCOL CJGUI_SHARED_OPERATION/2"), true)
            @Assert(descriptor.contains("ACTION GET_CONTEXT"), true)
            @Assert(descriptor.contains("ACTION SET_MARKED"), true)
            firstConnection.close()
            @Assert(exists(firstInfo.socketPath), false)
            @Assert(exists(firstInfo.descriptorPath), false)
            secondConnection.close()
            @Assert(exists(secondInfo.socketPath), false)
            @Assert(exists(secondInfo.descriptorPath), false)
            return
        }
    }
    firstConnection.close()
    secondConnection.close()
    @Assert(false, true)
}

/// A peer can legally connect and send only a prefix of its length header.
/// Such a peer must use an I/O worker budget, never the caller that owns a
/// window/event loop. The pre-fairness transport synchronously waited for its
/// 128 ms read timeout here.
@Test
func genericTransportReturnsToWindowPumpBeforeSlowFragmentDeadline(): Unit {
    let connection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(info) <- connection.connectionInfo()) {
        let prefixWasSent = Barrier(2)
        let slowClient = spawn { =>
            try (client = UnixSocket(info.socketPath)) {
                client.connect()
                let frame = CjguiSharedOperationFrame.encode(lifecycleContextPayload())
                client.write(frame.slice(0, 3))
                prefixWasSent.wait()
                sleep(Duration.millisecond * 180)
            } catch (_) {
            }
        }
        prefixWasSent.wait()

        let started = MonoTime.now()
        let _ = connection.pump(1u32)
        let elapsed = MonoTime.now() - started

        slowClient.get()
        connection.close()
        @Assert(elapsed.toMilliseconds() < 80, true)
        return
    }
    connection.close()
    @Assert(false, true)
}

/// One incomplete peer must not prevent another complete authorized request
/// from reaching the window-owned dispatcher. This is an actual UDS exchange,
/// rather than a synthetic queue assertion.
@Test
func genericTransportServesCompletePeerWhileAnotherPeerStallsMidFrame(): Unit {
    let connection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(info) <- connection.connectionInfo()) {
        let prefixWasSent = Barrier(2)
        let slowClient = spawn { =>
            try (client = UnixSocket(info.socketPath)) {
                client.connect()
                let frame = CjguiSharedOperationFrame.encode(lifecycleContextPayload())
                client.write(frame.slice(0, 3))
                prefixWasSent.wait()
                sleep(Duration.millisecond * 220)
            } catch (_) {
            }
        }
        prefixWasSent.wait()
        let completeClient = spawn { => requestLifecycleContext(info.socketPath) }

        let started = MonoTime.now()
        var completed: ?String = None
        while ((MonoTime.now() - started).toMilliseconds() < 80) {
            let _ = connection.pump(1u32)
            if (let Some(response) <- completeClient.tryGet()) {
                completed = Some(response)
                break
            }
            sleep(Duration.millisecond)
        }

        connection.close()
        slowClient.get()
        let response = completeClient.get()
        @Assert(completed.isSome(), true)
        @Assert(response.contains("KIND SNAPSHOT"), true)
        return
    }
    connection.close()
    @Assert(false, true)
}

/// Finite headless consumers count a request once their owner has dispatched
/// it, then revoke the private endpoint. Closing at that boundary must not
/// truncate the just-published response while its I/O worker wakes up.
@Test
func genericTransportDeliversDispatchedResponseDuringBoundedClose(): Unit {
    let connection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(info) <- connection.connectionInfo()) {
        let client = spawn { => requestLifecycleContext(info.socketPath) }
        let started = MonoTime.now()
        var dispatched = false
        while ((MonoTime.now() - started).toMilliseconds() < 160) {
            if (connection.pump(5u32)) {
                dispatched = true
                break
            }
        }
        connection.close()
        let response = client.get()
        @Assert(dispatched, true)
        @Assert(response.contains("KIND SNAPSHOT"), true)
        return
    }
    connection.close()
    @Assert(false, true)
}

/// The 64 ms shutdown grace is a ceiling for a real, finite receiver, not
/// permission for an unread response to pin the owner.  A multi-megabyte
/// normal reply must finish when its peer drains it; an equivalent non-reader
/// may finish immediately if the local kernel already accepted all bytes, but
/// must never make `close` wait for the 512 ms writer deadline.
@Test
func genericTransportSeparatesLargeReceiverCompletionFromNonReaderClose(): Unit {
    let normalConnection = CjguiSharedOperationExternalConnection(largeLifecycleList(), largeLifecycleAuthorization())
    @Assert(normalConnection.start(), true)
    if (let Some(info) <- normalConnection.connectionInfo()) {
        let normalClient = spawn { =>
            requestLifecyclePayloadWithTimeout(info.socketPath, largeLifecycleContextPayload(), 3000)
        }
        let started = MonoTime.now()
        var dispatched = false
        while ((MonoTime.now() - started).toMilliseconds() < 1200) {
            if (normalConnection.pump(5u32)) {
                dispatched = true
                break
            }
        }
        let normalResponse = normalClient.get()
        normalConnection.close()
        @Assert(dispatched, true)
        @Assert(normalResponse.contains("KIND SNAPSHOT"), true)

        let nonReaderConnection = CjguiSharedOperationExternalConnection(largeLifecycleList(), largeLifecycleAuthorization())
        @Assert(nonReaderConnection.start(), true)
        if (let Some(nonReaderInfo) <- nonReaderConnection.connectionInfo()) {
            let sent = Barrier(2)
            let nonReader = spawn { =>
                sendLifecyclePayloadWithoutReading(nonReaderInfo.socketPath, largeLifecycleContextPayload(), sent)
            }
            sent.wait()
            let ownerStarted = MonoTime.now()
            var nonReaderDispatched = false
            while ((MonoTime.now() - ownerStarted).toMilliseconds() < 1200) {
                if (nonReaderConnection.pump(5u32)) {
                    nonReaderDispatched = true
                    break
                }
            }
            let closeStarted = MonoTime.now()
            nonReaderConnection.close()
            let closeElapsedMs = (MonoTime.now() - closeStarted).toMilliseconds()
            nonReader.get()
            @Assert(nonReaderDispatched, true)
            @Assert(closeElapsedMs < 180, true)
            return
        }
        nonReaderConnection.close()
    }
    normalConnection.close()
    @Assert(false, true)
}

/// Four workers can all hold complete, still-unclaimed mutating requests
/// while the owner is paused. Their wait may be bounded, but expiry must win
/// atomically over a later owner claim: once expired, those requests cannot
/// mutate the domain when the owner resumes, and a normal peer can recover.
@Test
func genericTransportExpiresUnclaimedRequestsWithoutLateMutation(): Unit {
    let list = lifecycleList()
    let connection = CjguiSharedOperationExternalConnection(list, lifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(info) <- connection.connectionInfo()) {
        let sent = Barrier(5)
        let first = spawn { => sendLifecyclePayloadThenRead(info.socketPath, lifecycleSetMarkedPayload(), sent) }
        let second = spawn { => sendLifecyclePayloadThenRead(info.socketPath, lifecycleSetMarkedPayload(), sent) }
        let third = spawn { => sendLifecyclePayloadThenRead(info.socketPath, lifecycleSetMarkedPayload(), sent) }
        let fourth = spawn { => sendLifecyclePayloadThenRead(info.socketPath, lifecycleSetMarkedPayload(), sent) }
        sent.wait()
        sleep(Duration.millisecond * 300)

        if (let Some(diagnostics) <- connection.transportDiagnostics()) {
            // The retained task handles and workers actually executing the
            // transport loop are distinct facts. Both must be observable.
            @Assert(diagnostics.retainedWorkerCount, 5)
            @Assert(diagnostics.activeIoWorkerCount, 5)
            @Assert(diagnostics.readyRequestHighWater >= 4, true)
            @Assert(diagnostics.readyRequestBytesHighWater > 0, true)
            // Expired requests remain physical queue tombstones until the
            // owner drains them. Their bytes must continue to count against
            // the ready-queue budget; otherwise new requests can exceed the
            // advertised 16 MiB while diagnostics falsely show zero.
            @Assert(diagnostics.queuedRequestBytes > 0, true)
        } else {
            connection.close()
            let _ = first.get(); let _ = second.get(); let _ = third.get(); let _ = fourth.get()
            @Assert(false, true)
        }

        let normal = spawn { => requestLifecycleContext(info.socketPath) }
        let started = MonoTime.now()
        var normalResponse = ""
        while ((MonoTime.now() - started).toMilliseconds() < 240) {
            let _ = connection.pump(5u32)
            if (let Some(response) <- normal.tryGet()) {
                normalResponse = response
                break
            }
        }

        connection.close()
        let _ = first.get(); let _ = second.get(); let _ = third.get(); let _ = fourth.get()
        let normalAfterClose = normal.get()
        @Assert(normalResponse.contains("KIND SNAPSHOT") || normalAfterClose.contains("KIND SNAPSHOT"), true)
        @Assert(list.snapshot().version, 0)
        @Assert(list.snapshot().recordAt(0).isMarked, false)
        return
    }
    connection.close()
    @Assert(false, true)
}

/// The worker's cancellation poll is not the deadline authority. If the
/// worker is delayed, an owner that arrives after the absolute unclaimed
/// deadline must still refuse to claim the request rather than perform a
/// late domain mutation.
@Test
func genericTransportOwnerClaimHonorsAbsoluteReadyDeadline(): Unit {
    let request = CjguiSharedOperationPendingClientRequest(lifecycleContextPayload())
    sleep(Duration.millisecond * 260)
    @Assert(request.claimForOwner(), false)
}

/// An expired request's tombstone still owns its payload bytes until the
/// owner drains it. The deterministic core queue test uses three actual
/// bounded frame payloads: a newly-arrived fourth frame must be rejected
/// while their bytes remain physical tombstones, then accepted after a drain.
@Test
func genericTransportKeepsExpiredPayloadBytesUntilOwnerDrain(): Unit {
    let state = CjguiSharedOperationIoState()
    let first = CjguiSharedOperationPendingClientRequest(lifecyclePaddedPayload(5 * 1024 * 1024))
    let second = CjguiSharedOperationPendingClientRequest(lifecyclePaddedPayload(5 * 1024 * 1024))
    let third = CjguiSharedOperationPendingClientRequest(lifecyclePaddedPayload(5 * 1024 * 1024))
    let fourth = CjguiSharedOperationPendingClientRequest(lifecyclePaddedPayload(2 * 1024 * 1024))
    if (let Some(firstLease) <- state.tryQueueRequest(first)) {
        if (let Some(secondLease) <- state.tryQueueRequest(second)) {
            if (let Some(thirdLease) <- state.tryQueueRequest(third)) {
                @Assert(first.cancelIfUnclaimed(), true)
                @Assert(second.cancelIfUnclaimed(), true)
                @Assert(third.cancelIfUnclaimed(), true)
                state.expirePendingRequest(firstLease)
                state.expirePendingRequest(secondLease)
                state.expirePendingRequest(thirdLease)
                @Assert(state.diagnostics().queuedRequestBytes > 15 * 1024 * 1024, true)
                @Assert(state.tryQueueRequest(fourth).isSome(), false)
                let _ = state.takeReadyRequest(0u32)
                @Assert(state.tryQueueRequest(fourth).isSome(), true)
                state.stop()
                return
            }
        }
    }
    state.stop()
    @Assert(false, true)
}

/// A bounded close observation is not a join guarantee.  With no worker that
/// has entered, it is immediately converged; callers must still rely on the
/// distinct I/O state identity if a busy worker outlives the time slice.
@Test
func genericTransportReportsBoundedWorkerExitObservation(): Unit {
    let state = CjguiSharedOperationIoState()
    @Assert(state.waitForWorkersToExit(0), true)
    state.stop()
    @Assert(state.waitForWorkersToExit(0), true)
}

/// One owner object can close and reopen in the same process.  The fresh
/// endpoint must not reuse either old path, and its worker state must be
/// fully established before it serves a normal public request.
@Test
func genericTransportRestartsSameProcessWithFreshWorkerState(): Unit {
    let connection = CjguiSharedOperationExternalConnection(lifecycleList(), lifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(firstInfo) <- connection.connectionInfo()) {
        var firstWorkersReady = false
        let firstStarted = MonoTime.now()
        while ((MonoTime.now() - firstStarted).toMilliseconds() < 80) {
            if (let Some(diagnostics) <- connection.transportDiagnostics()) {
                if (diagnostics.retainedWorkerCount == 5 && diagnostics.activeIoWorkerCount == 5) {
                    firstWorkersReady = true
                    break
                }
            }
            sleep(Duration.millisecond)
        }
        connection.close()
        @Assert(firstWorkersReady, true)
        @Assert(exists(firstInfo.socketPath), false)
        @Assert(exists(firstInfo.descriptorPath), false)

        @Assert(connection.start(), true)
        if (let Some(secondInfo) <- connection.connectionInfo()) {
            let client = spawn { => requestLifecycleContext(secondInfo.socketPath) }
            let started = MonoTime.now()
            var dispatched = false
            while ((MonoTime.now() - started).toMilliseconds() < 160) {
                if (connection.pump(5u32)) {
                    dispatched = true
                    break
                }
            }
            let response = client.get()
            connection.close()
            @Assert(firstInfo.socketPath == secondInfo.socketPath, false)
            @Assert(firstInfo.descriptorPath == secondInfo.descriptorPath, false)
            @Assert(dispatched, true)
            @Assert(response.contains("KIND SNAPSHOT"), true)
            @Assert(exists(secondInfo.socketPath), false)
            @Assert(exists(secondInfo.descriptorPath), false)
            return
        }
    }
    connection.close()
    @Assert(false, true)
}

/// A receiver can be descheduled after a prefix without exhausting the
/// advertised 512 ms frame-write budget. No request or partial response is
/// retried: this single framed response must either arrive exactly or fail.
@Test
func genericTransportHonorsWholeWriteBudgetForBriefReceiverSchedulingGap(): Unit {
    let connection = CjguiSharedOperationExternalConnection(largeLifecycleList(), largeLifecycleAuthorization())
    @Assert(connection.start(), true)
    if (let Some(info) <- connection.connectionInfo()) {
        // Freeze a complete ordinary response from this unchanged read-only
        // domain, then require every byte of the paused receiver's frame.
        let immediate = spawn { =>
            requestLifecyclePayloadWithTimeout(info.socketPath, largeLifecycleContextPayload(), 3000)
        }
        var immediateDispatched = false
        let immediateStarted = MonoTime.now()
        while ((MonoTime.now() - immediateStarted).toMilliseconds() < 1200) {
            if (connection.pump(5u32)) { immediateDispatched = true; break }
        }
        let expected = immediate.get()
        @Assert(immediateDispatched, true)
        @Assert(expected.contains("KIND SNAPSHOT"), true)
        @Assert(expected.size > 4 * 1024 * 1024, true)
        let receiver = spawn { =>
            var response = ""
            try (client = UnixSocket(info.socketPath)) {
                client.connect()
                client.readTimeout = Some(Duration.second * 3)
                client.write(CjguiSharedOperationFrame.encode(largeLifecycleContextPayload()))
                let decoder = CjguiSharedOperationFrameAccumulator()
                let buffer = Array<Byte>(4096, repeat: 0)
                var paused = false
                while (true) {
                    let count = client.read(buffer)
                    if (count <= 0) { break }
                    let result = decoder.append(buffer, count)
                    if (result.isComplete) { response = result.payload; break }
                    if (result.isMalformed) { break }
                    if (!paused) {
                        paused = true
                        sleep(Duration.millisecond * 40)
                    }
                }
            } catch (_: Exception) {}
            response
        }
        let started = MonoTime.now()
        var dispatched = false
        while ((MonoTime.now() - started).toMilliseconds() < 1200) {
            if (connection.pump(5u32)) { dispatched = true; break }
        }
        let response = receiver.get()
        connection.close()
        @Assert(dispatched, true)
        @Assert(response.contains("KIND SNAPSHOT"), true)
        @Assert(response, expected)
        @Assert(response.endsWith("END"), true)
        return
    }
    connection.close()
    @Assert(false, true)
}

// True transport controls for request-level diagnostics, independent of the
// original GiB stall. The provider barrier is an explicit test cause.
private class DiagnosticReadLifecycleDomain <: CjguiSharedOperationDomain & CjguiSharedOperationRangeReadDomain {
    let list = lifecycleList()
    let entered = Barrier(2)
    let released = Barrier(2)
    var hold: Bool = false
    private let callLock = Mutex()
    private var calls: Int64 = 0
    func callCount(): Int64 { return synchronized(callLock) { calls } }
    public func resourceType(): String { return list.resourceType() }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot { return list.contextSnapshot() }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> { return list.actionDescriptors() }
    public func executeFromHuman(i: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return list.executeFromHuman(i) }
    public func executeFromExternal(i: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return list.executeFromExternal(i) }
    public func readRangeFromExternal(resourceId: Int64, start: Int64, end: Int64, expectedVersion: Int64): CjguiSharedOperationRangeRead {
        synchronized(callLock) { calls += 1 }
        if (hold) { entered.wait(); released.wait() }
        return CjguiSharedOperationRangeRead(true, false, resourceId, 4, start, end, "X", "available")
    }
}
private func diagnosticReadConnection(d: DiagnosticReadLifecycleDomain): CjguiSharedOperationExternalConnection {
    let auth = CjguiSharedOperationExternalAuthorization("diagnostic-read", "lifecycle-read-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([901]), false)]))
    let c = CjguiSharedOperationExternalConnection(d, auth)
    let _ = c.enableRangeReads(d)
    return c
}
private func diagnosticReadPayload(): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH lifecycle-read-capability\nREAD_RANGE 901 0 1 4"
}
@Test
func requestReadUnclaimedNeverCallsProvider(): Unit {
    let d = DiagnosticReadLifecycleDomain(); let c = diagnosticReadConnection(d)
    @Assert(c.start(), true)
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let client = spawn { => requestLifecyclePayloadWithTimeout(path, diagnosticReadPayload(), 1000) }
        awaitLifecycleReadyCount(c, 1)
        sleep(Duration.millisecond * 280)
        @Assert(client.get().contains("ERROR owner_busy"), true)
        @Assert(d.callCount(), 0)
        @Assert(c.pump(0u32), false)
        @Assert(d.callCount(), 0)
    } finally { c.close() }
}
@Test
func requestReadClaimedProviderCrossesDeadlineOnce(): Unit {
    let d = DiagnosticReadLifecycleDomain(); d.hold = true
    let c = diagnosticReadConnection(d); @Assert(c.start(), true)
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let client = spawn { => requestLifecyclePayloadWithTimeout(path, diagnosticReadPayload(), 1000) }
        awaitLifecycleReadyCount(c, 1)
        let release = spawn { => d.entered.wait(); sleep(Duration.millisecond * 280); d.released.wait() }
        @Assert(c.pump(0u32), true)
        release.get()
        let response = client.get()
        @Assert(response.contains("KIND RANGE"), true)
        @Assert(response.contains("ERROR owner_busy"), false)
        @Assert(d.callCount(), 1)
        @Assert(c.pump(0u32), false)
    } finally { c.close() }
}
@Test
func requestReadPredecessorHoldsOwnerWhileNextExpires(): Unit {
    let d = DiagnosticReadLifecycleDomain(); d.hold = true
    let c = diagnosticReadConnection(d); @Assert(c.start(), true)
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let first = spawn { => requestLifecyclePayloadWithTimeout(path, diagnosticReadPayload(), 1200) }
        awaitLifecycleReadyCount(c, 1)
        let release = spawn { =>
            d.entered.wait()
            let second = requestLifecyclePayloadWithTimeout(path, diagnosticReadPayload(), 1000)
            d.released.wait()
            second
        }
        @Assert(c.pump(0u32), true)
        @Assert(release.get().contains("ERROR owner_busy"), true)
        @Assert(first.get().contains("KIND RANGE"), true)
        @Assert(d.callCount(), 1)
        @Assert(c.pump(0u32), false)
        @Assert(d.callCount(), 1)
    } finally { c.close() }
}

@Test
func requestResponseCannotPublishAgainAfterFirstTake(): Unit {
    let request = CjguiSharedOperationPendingClientRequest(lifecycleContextPayload())
    @Assert(request.claimForOwner(), true)
    @Assert(request.complete("first"), true)
    @Assert(request.waitForResponse().getOrThrow(), "first")
    @Assert(request.complete("second"), false)
    @Assert(request.hasPublishedResponse(), true)
}
@Test
func requestResponseCancellationRetainsSingleDecision(): Unit {
    let before = CjguiSharedOperationPendingClientRequest(lifecycleContextPayload())
    @Assert(before.claimForOwner(), true); before.cancel()
    @Assert(before.complete("never"), false)
    let after = CjguiSharedOperationPendingClientRequest(lifecycleContextPayload())
    @Assert(after.claimForOwner(), true); @Assert(after.complete("first"), true); after.cancel()
    @Assert(after.complete("second"), false)
    @Assert(after.waitForResponse().getOrThrow(), "first")
}

private class DetachedLifecycleDomain <: CjguiSharedOperationDomain & CjguiSharedOperationRangeReadDomain {
    let list = lifecycleList()
    let document: CjguiTextDocument
    private let callLock = Mutex()
    private var calls: Int64 = 0
    var bad: Bool = false
    init(body: String) { document = CjguiTextDocument(901, "detached", body) }
    func callCount(): Int64 { return synchronized(callLock) { calls } }
    public func resourceType(): String { return list.resourceType() }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot { return list.contextSnapshot() }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> { return list.actionDescriptors() }
    public func executeFromHuman(i: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return list.executeFromHuman(i) }
    public func executeFromExternal(i: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return list.executeFromExternal(i) }
    public func readRangeFromExternal(resource: Int64, start: Int64, end: Int64, version: Int64): CjguiSharedOperationRangeRead {
        synchronized(callLock) { calls += 1 }
        if (bad) { return CjguiSharedOperationRangeRead(true, false, resource, -1, start, end, "X", "invalid") }
        let read = document.readRangeFromExternal(CjguiTextDocumentRange(start, end), version)
        return CjguiSharedOperationRangeRead(read.isAvailable, read.isVersionConflict, resource, read.version,
            read.range.start, read.range.end, read.content, read.reason)
    }
}
private func detachedLifecycleConnection(d: DetachedLifecycleDomain): CjguiSharedOperationExternalConnection {
    let auth = CjguiSharedOperationExternalAuthorization("detached-test", "lifecycle-read-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([901]), false)]))
    let c = CjguiSharedOperationExternalConnection(d, auth); let _ = c.enableRangeReads(d); return c
}
private func detachedLifecyclePayload(end: Int64, version!: Int64 = 0, resource!: Int64 = 901): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH lifecycle-read-capability\nREAD_RANGE ${resource} 0 ${end} ${version}"
}
private class HeldDetachedEncoding <: CjguiDetachedReadEncodingProbe {
    let entered = Barrier(2)
    let released = Barrier(2)
    private let lock = Mutex()
    private var used = false
    public func beforeEncoding(lease: Int64): Unit {
        let hold = synchronized(lock) { if (used) { false } else { used = true; true } }
        if (hold) { entered.wait(); released.wait() }
    }
}
private class FailedDetachedEncoding <: CjguiDetachedReadEncodingProbe {
    private let lock = Mutex()
    private var used = false
    public func beforeEncoding(lease: Int64): Unit {
        let fail = synchronized(lock) { if (used) { false } else { used = true; true } }
        if (fail) { throw Exception("controlled_encoder_failure") }
    }
}
private func awaitDetachedAccountingZero(c: CjguiSharedOperationExternalConnection): Unit {
    let started = MonoTime.now()
    while (c.detachedReadAccounting()[1] != 0 && (MonoTime.now() - started).toMilliseconds() < 250) {
        sleep(Duration.millisecond)
    }
    @Assert(c.detachedReadAccounting()[1], 0)
}

@Test
func detachedReadOwnerReturnsBeforeEncodingAndKeepsVersion(): Unit {
    let text = String.fromUtf8(Array<Byte>(65536, repeat: b'X'))
    let d = DetachedLifecycleDomain(text); let probe = HeldDetachedEncoding()
    let c = detachedLifecycleConnection(d)
    let enabled = getVariable("CJGUI_TEST_DETACHED_READ_DISABLE").isNone()
    @Assert(c.configureDetachedReadCounter(enabled, Some(probe)), true)
    @Assert(c.start(), true)
    let commands = ArrayBlockingQueue<Int64>(8); let answers = ArrayBlockingQueue<Bool>(8)
    // One established owner dispatches both reads and the real document edit.
    let owner = spawn { =>
        var running = true
        while (running) {
            if (let Some(command) <- commands.remove(Duration.second * 2)) {
                if (command == 0) { running = false }
                else if (command == 1) { let _ = answers.tryAdd(c.pump(0u32)) }
                else if (command == 2) {
                    let edit = d.document.replaceRangeFromExternal(CjguiTextDocumentRange(0, 1), "Y", 0)
                    let _ = answers.tryAdd(edit.applied && edit.versionAfter == 1)
                }
            } else { running = false }
        }
    }
    var entered = false; var released = false
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let first = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(65536), 1500) }
        awaitLifecycleReadyCount(c, 1); let _ = commands.tryAdd(1)
        probe.entered.wait(); entered = true
        let returned = answers.remove(Duration.millisecond * 80)
        // Withdrawal leaves the owner inside the SAME formatter/barrier.
        @Assert(returned.isSome(), true)
        @Assert(returned.getOrThrow(), true)
        @Assert(d.callCount(), 1)
        @Assert(c.detachedReadAccounting()[1] > 0, true)
        let _ = commands.tryAdd(2); @Assert(answers.remove(Duration.second).getOrThrow(), true)
        let second = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(65536, version: 1), 1000) }
        awaitLifecycleReadyCount(c, 1); let _ = commands.tryAdd(1)
        @Assert(answers.remove(Duration.second).getOrThrow(), true)
        let now = second.get()
        @Assert(now.contains("VERSION 1\n"), true)
        @Assert(now.contains("CONTENT_UTF8_HEX 65536 59" + CjguiSharedOperationFrame.encodeUtf8Hex(text[1..])), true)
        probe.released.wait(); released = true
        let old = first.get()
        @Assert(old.contains("VERSION 0\n"), true)
        @Assert(old.contains("CONTENT_UTF8_HEX 65536 " + CjguiSharedOperationFrame.encodeUtf8Hex(text)), true)
        @Assert(d.callCount(), 2)
        @Assert(d.document.snapshot().version, 1)
        awaitDetachedAccountingZero(c)
    } finally {
        if (entered && !released) { probe.released.wait() }
        let _ = commands.tryAdd(0); owner.get(); c.close()
    }
}

@Test
func detachedReadWireEqualsSynchronousKernelAndRejectsBadResults(): Unit {
    for (body in ["", "Hi中😀", String.fromUtf8(Array<Byte>(65536, repeat: b'X'))]) {
        let d = DetachedLifecycleDomain(body); let c = detachedLifecycleConnection(d)
        let payload = detachedLifecyclePayload(body.size)
        let direct = c.dispatchPayload(payload)
        @Assert(c.start(), true)
        try {
            let path = c.connectionInfo().getOrThrow().socketPath
            let peer = spawn { => requestLifecyclePayloadWithTimeout(path, payload, 1000) }
            awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
            @Assert(peer.get(), direct); @Assert(d.callCount(), 2)
            awaitDetachedAccountingZero(c)
            let stalePayload = detachedLifecyclePayload(body.size, version: 7)
            let staleDirect = c.dispatchPayload(stalePayload)
            let stalePeer = spawn { => requestLifecyclePayloadWithTimeout(path, stalePayload, 1000) }
            awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
            @Assert(stalePeer.get(), staleDirect); awaitDetachedAccountingZero(c)
            d.bad = true
            let invalidDirect = c.dispatchPayload(payload)
            let invalidPeer = spawn { => requestLifecyclePayloadWithTimeout(path, payload, 1000) }
            awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
            @Assert(invalidPeer.get(), invalidDirect)
            @Assert(invalidDirect.contains("ERROR invalid_range"), true); awaitDetachedAccountingZero(c)
            let calls = d.callCount()
            @Assert(c.dispatchPayload(detachedLifecyclePayload(body.size, resource: 902)).contains("unauthorized_resource"), true)
            @Assert(c.dispatchPayload(detachedLifecyclePayload(65537)).contains("invalid_request"), true)
            @Assert(d.callCount(), calls)
        } finally { c.close() }
    }
}

@Test
func detachedReadCapacityRefusesBeforeProviderAndEncoderFailureKeepsWorkers(): Unit {
    let d = DetachedLifecycleDomain("X"); let c = detachedLifecycleConnection(d)
    @Assert(c.configureDetachedReadCapacity(0), true); @Assert(c.start(), true)
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let peer = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(1), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        @Assert(peer.get().contains("ERROR range_read_capacity"), true); @Assert(d.callCount(), 0)
    } finally { c.close() }
    @Assert(c.configureDetachedReadCapacity(8 * 1024 * 1024), true)
    @Assert(c.configureDetachedReadCounter(true, Some(FailedDetachedEncoding())), true)
    @Assert(c.start(), true)
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        for (i in 0..2) {
            let peer = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(1), 1000) }
            awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
            @Assert(peer.get().contains(if (i == 0) { "ERROR range_encoding_failed" } else { "KIND RANGE" }), true)
            awaitDetachedAccountingZero(c)
            @Assert(c.transportDiagnostics().getOrThrow().retainedWorkerCount, 5)
            @Assert(c.transportDiagnostics().getOrThrow().activeIoWorkerCount, 5)
        }
        @Assert(d.callCount(), 2)
    } finally { c.close() }
}

@Test
func detachedReadCloseWhileEncodingRetainsBudgetAcrossRestart(): Unit {
    let body = String.fromUtf8(Array<Byte>(65536, repeat: b'X'))
    let d = DetachedLifecycleDomain(body); let probe = HeldDetachedEncoding(); let c = detachedLifecycleConnection(d)
    @Assert(c.configureDetachedReadCounter(true, Some(probe)), true); @Assert(c.start(), true)
    var entered = false; var released = false
    try {
        let oldInfo = c.connectionInfo().getOrThrow()
        let old = spawn { => requestLifecyclePayloadWithTimeout(oldInfo.socketPath, detachedLifecyclePayload(65536), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        probe.entered.wait(); entered = true
        let held = c.detachedReadAccounting()[1]; @Assert(held > 0, true)
        let start = MonoTime.now(); c.close()
        @Assert((MonoTime.now() - start).toMilliseconds() < 400, true)
        @Assert(c.detachedReadAccounting()[1], held)
        @Assert(c.configureDetachedReadCapacity(0), false)
        @Assert(c.configureDetachedReadCounter(true, None), true); @Assert(c.start(), true)
        let newInfo = c.connectionInfo().getOrThrow(); @Assert(newInfo.socketPath != oldInfo.socketPath, true)
        let fresh = spawn { => requestLifecyclePayloadWithTimeout(newInfo.socketPath, detachedLifecyclePayload(65536), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        @Assert(fresh.get().contains("KIND RANGE"), true)
        @Assert(c.detachedReadAccounting()[1] >= held, true)
        probe.released.wait(); released = true
        @Assert(old.get().contains("KIND RANGE"), false)
        awaitDetachedAccountingZero(c)
        @Assert(d.callCount(), 2)
    } finally {
        if (entered && !released) { probe.released.wait() }
        c.close()
    }
}

private class QueuedDetachedEncoding <: CjguiDetachedReadEncodingProbe & CjguiDetachedReadBeforeTakeProbe {
    let entered = Barrier(2)
    let released = Barrier(2)
    public func beforeEncoding(lease: Int64): Unit { }
    public func beforeResponseTake(lease: Int64): Unit { entered.wait(); released.wait() }
}
@Test
func detachedReadCloseQueuedResponseReleasesOnlyWhenWorkerDropsIt(): Unit {
    let d = DetachedLifecycleDomain("X"); let probe = QueuedDetachedEncoding(); let c = detachedLifecycleConnection(d)
    @Assert(c.configureDetachedReadCounter(true, Some(probe)), true); @Assert(c.start(), true)
    var entered = false; var released = false
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let peer = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(1), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        probe.entered.wait(); entered = true
        let held = c.detachedReadAccounting()[1]; @Assert(held > 0, true)
        c.close(); @Assert(c.detachedReadAccounting()[1], held)
        probe.released.wait(); released = true
        @Assert(peer.get().contains("KIND RANGE"), false)
        awaitDetachedAccountingZero(c)
        @Assert(c.detachedReadAccounting()[5], 1)
    } finally { if (entered && !released) { probe.released.wait() }; c.close() }
}
@Test
func detachedReadCloseWhileProviderStillOwnsReservation(): Unit {
    let d = DiagnosticReadLifecycleDomain(); d.hold = true; let c = diagnosticReadConnection(d)
    @Assert(c.start(), true)
    var entered = false; var released = false
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let peer = spawn { => requestLifecyclePayloadWithTimeout(path, diagnosticReadPayload(), 1000) }
        awaitLifecycleReadyCount(c, 1)
        let owner = spawn { => c.pump(0u32) }
        d.entered.wait(); entered = true
        let held = c.detachedReadAccounting()[1]; @Assert(held > 0, true)
        c.close(); @Assert(c.detachedReadAccounting()[1], held)
        d.released.wait(); released = true; let _ = owner.get()
        @Assert(peer.get().contains("KIND RANGE"), false)
        awaitDetachedAccountingZero(c); @Assert(d.callCount(), 1)
    } finally { if (entered && !released) { d.released.wait() }; c.close() }
}
@Test
func detachedReadPeerDisconnectReturnsBudgetAndPreservesWorkerPool(): Unit {
    let d = DetachedLifecycleDomain("X"); let probe = HeldDetachedEncoding(); let c = detachedLifecycleConnection(d)
    @Assert(c.configureDetachedReadCounter(true, Some(probe)), true); @Assert(c.start(), true)
    let disconnect = Barrier(2)
    var entered = false; var released = false
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let peer = spawn { =>
            try (client = UnixSocket(path)) { client.connect(); client.write(CjguiSharedOperationFrame.encode(detachedLifecyclePayload(1))); disconnect.wait() }
        }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        probe.entered.wait(); entered = true; disconnect.wait(); peer.get()
        probe.released.wait(); released = true; awaitDetachedAccountingZero(c)
        @Assert(c.transportDiagnostics().getOrThrow().retainedWorkerCount, 5)
        let next = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(1), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        @Assert(next.get().contains("KIND RANGE"), true); awaitDetachedAccountingZero(c)
        @Assert(c.transportDiagnostics().getOrThrow().activeIoWorkerCount, 5)
        @Assert(d.callCount(), 2)
    } finally { if (entered && !released) { probe.released.wait() }; c.close() }
}

@Test
func detachedReadQueuedEmptyWireRetainsItsInFlightReservation(): Unit {
    let d = DetachedLifecycleDomain(""); let probe = QueuedDetachedEncoding(); let c = detachedLifecycleConnection(d)
    @Assert(c.configureDetachedReadCounter(true, Some(probe)), true); @Assert(c.start(), true)
    var entered = false; var released = false
    try {
        let path = c.connectionInfo().getOrThrow().socketPath
        let peer = spawn { => requestLifecyclePayloadWithTimeout(path, detachedLifecyclePayload(0), 1000) }
        awaitLifecycleReadyCount(c, 1); @Assert(c.pump(0u32), true)
        probe.entered.wait(); entered = true
        @Assert(c.detachedReadAccounting()[1] > 0, true)
        c.close(); @Assert(c.detachedReadAccounting()[1] > 0, true)
        probe.released.wait(); released = true
        @Assert(peer.get().contains("KIND RANGE"), false)
        awaitDetachedAccountingZero(c)
    } finally { if (entered && !released) { probe.released.wait() }; c.close() }
}
