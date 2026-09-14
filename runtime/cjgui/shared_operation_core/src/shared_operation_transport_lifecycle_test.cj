package cjgui_shared_operation_core

import std.collection.*
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

private func lifecycleList(): CjguiSharedOperationList {
    return CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>([CjguiSharedOperationRecord(901, "多字节\n标题", false)])
    )
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
