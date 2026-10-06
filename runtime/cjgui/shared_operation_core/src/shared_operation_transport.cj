package cjgui_shared_operation_core

import std.collection.*
import std.collection.concurrent.*
import std.convert.*
import std.env.*
import std.fs.*
import std.net.*
import std.posix.*
import std.random.*
import std.sync.*
import std.time.*

private const CJGUI_SHARED_OPERATION_PROTOCOL: String = "CJGUI_SHARED_OPERATION/2"
private const CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES: Int64 = 8 * 1024 * 1024
// Generated-UI payloads (capability descriptions, accepted structures and
// candidates) are bounded separately from the frame limit.
private const CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES: Int64 = 256 * 1024
private const CJGUI_SHARED_OPERATION_MAX_HEADER_BYTES: Int64 = 12
private const CJGUI_SHARED_OPERATION_MAX_TARGETS: Int64 = 1024
private const CJGUI_SHARED_OPERATION_MAX_STRING_BYTES: Int64 = 64 * 1024
private const CJGUI_SHARED_OPERATION_IO_WORKER_COUNT: Int64 = 4

// E1 bounded revocation history: how many revoked credentials one connection
// keeps refusing to re-grant. Beyond this the oldest fingerprint is evicted
// and counted (`revoked_credential_evictions`) rather than silently forgotten.
private const CJGUI_SHARED_OPERATION_REVOKED_CREDENTIAL_CAPACITY: Int64 = 8

// FNV-1a (32-bit, masked so UInt64 arithmetic cannot overflow) over the
// capability's UTF-8 bytes plus its length. This identifies a revoked
// credential WITHOUT keeping the secret text alive in a second place (the live
// authorization still holds the current one). The fingerprint is not a secret
// and makes no cryptographic claim: a collision can only refuse an unrelated
// credential -- fail-closed -- never admit a revoked one.
private func sharedOperationCredentialFingerprint(capability: String): String {
    let bytes = capability.toArray()
    var hash: UInt64 = 0x811c9dc5
    for (byte in bytes) {
        hash = hash ^ UInt64(byte)
        hash = (hash * 0x01000193) & 0xFFFFFFFF
    }
    hash = hash ^ UInt64(bytes.size)
    return sharedOperationHex16(hash)
}

// Endpoint INSTANCE identity: one random nonce per connection object plus a
// process-local sequence. Two transports in one process cannot collide, and a
// restarted process cannot reuse an old instance by starting its counter at the
// same value. It is an identity, never an authorization credential: the
// capability stays the only thing that authorizes a call.
private let CJGUI_SHARED_OPERATION_INSTANCE_LOCK = Mutex()
private var CJGUI_SHARED_OPERATION_INSTANCE_SEQUENCE: Int64 = 0

private func sharedOperationHex16(value: UInt64): String {
    let digits = "0123456789abcdef"
    let builder = StringBuilder()
    var shift = 60
    while (shift >= 0) {
        let nibble = Int64((value >> UInt64(shift)) & 0xF)
        builder.append(digits[nibble..(nibble + 1)])
        shift -= 4
    }
    return builder.toString()
}

private func nextEndpointInstance(): String {
    return synchronized(CJGUI_SHARED_OPERATION_INSTANCE_LOCK) {
        CJGUI_SHARED_OPERATION_INSTANCE_SEQUENCE += 1
        // A random 64-bit value is formatted as UNSIGNED: converting the raw
        // value to Int64 would overflow for half of the values.
        let sequence = UInt64(CJGUI_SHARED_OPERATION_INSTANCE_SEQUENCE)
        return "${sharedOperationHex16(Random().nextUInt64())}${sharedOperationHex16(sequence)}"
    }
}
private const CJGUI_SHARED_OPERATION_MAX_QUEUED_CLIENTS: Int64 = 8
private const CJGUI_SHARED_OPERATION_MAX_READY_REQUESTS: Int64 = 8
private const CJGUI_SHARED_OPERATION_MAX_READY_REQUEST_BYTES: Int64 = 16 * 1024 * 1024
private const CJGUI_SHARED_OPERATION_READ_DEADLINE_MS: Int64 = 160
// A complete request may wait for the owner only while it has not been
// claimed. Once claimed, the owner either executes it exactly once or a
// later connection close records that the response may be lost.
private const CJGUI_SHARED_OPERATION_READY_WAIT_DEADLINE_MS: Int64 = 256
private const CJGUI_SHARED_OPERATION_WRITE_DEADLINE_MS: Int64 = 512
private const CJGUI_SHARED_OPERATION_IO_SLICE_MS: Int64 = 8
// Shutdown never lets a peer hold the application indefinitely. It gives a
// response already dispatched by the true owner a small chance to reach the
// local kernel before the private endpoint is revoked.
private const CJGUI_SHARED_OPERATION_CLOSE_RESPONSE_GRACE_MS: Int64 = 64

/// Experimental bounded UTF-8 frame used by the local transport. A frame is
/// one decimal byte length, a newline and exactly that many UTF-8 bytes.
public class CjguiSharedOperationFrame {
    public static func encode(payload: String): Array<Byte> {
        if (payload.size <= 0 || payload.size > CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES) {
            throw IllegalArgumentException("invalid_frame_payload_size")
        }
        return "${payload.size}\n${payload}".toArray()
    }

    public static func encodeUtf8Hex(value: String): String {
        return encodeUtf8HexValue(value)
    }
}

/// Experimental bounded incremental frame parser. Socket fragmentation cannot
/// split or reinterpret a Unicode payload because conversion happens only when
/// the complete declared byte sequence has arrived.
public class CjguiSharedOperationFrameRead {
    public let isComplete: Bool
    public let isMalformed: Bool
    public let payload: String
    public let reason: String

    public init(isComplete: Bool, isMalformed: Bool, payload: String, reason: String) {
        this.isComplete = isComplete
        this.isMalformed = isMalformed
        this.payload = payload
        this.reason = reason
    }
}

/// Read-only, process-local transport counters for bounded-load diagnosis.
/// They are deliberately not part of the private descriptor or application
/// snapshot: callers cannot use them to infer domain truth or control I/O.
public class CjguiSharedOperationTransportDiagnostics {
    /// Futures retained by this start's I/O state. This is lifecycle
    /// ownership, not a claim that every loop is currently executing.
    public let retainedWorkerCount: Int64
    /// Transport loops that entered and have not yet observed shutdown.
    /// This is an owner-local loop count, not an operating-system thread
    /// count; process sampling remains responsible for the latter.
    public let activeIoWorkerCount: Int64
    public let acceptedClientCount: Int64
    public let activeClientCount: Int64
    public let readyRequestCount: Int64
    public let queuedRequestBytes: Int64
    public let acceptedClientHighWater: Int64
    public let readyRequestHighWater: Int64
    public let readyRequestBytesHighWater: Int64

    public init(
        retainedWorkerCount: Int64,
        activeIoWorkerCount: Int64,
        acceptedClientCount: Int64,
        activeClientCount: Int64,
        readyRequestCount: Int64,
        queuedRequestBytes: Int64,
        acceptedClientHighWater: Int64,
        readyRequestHighWater: Int64,
        readyRequestBytesHighWater: Int64
    ) {
        this.retainedWorkerCount = retainedWorkerCount
        this.activeIoWorkerCount = activeIoWorkerCount
        this.acceptedClientCount = acceptedClientCount
        this.activeClientCount = activeClientCount
        this.readyRequestCount = readyRequestCount
        this.queuedRequestBytes = queuedRequestBytes
        this.acceptedClientHighWater = acceptedClientHighWater
        this.readyRequestHighWater = readyRequestHighWater
        this.readyRequestBytesHighWater = readyRequestBytesHighWater
    }
}

public class CjguiSharedOperationFrameAccumulator {
    private let bytes: ArrayList<Byte>
    private var terminalRead: ?CjguiSharedOperationFrameRead

    public init() {
        this.bytes = ArrayList<Byte>()
        this.terminalRead = None
    }

    public func append(chunk: Array<Byte>, size: Int64): CjguiSharedOperationFrameRead {
        if (let Some(previous) <- terminalRead) {
            if (size == 0) {
                return previous
            }
            return malformed("trailing_data")
        }
        if (size < 0 || size > chunk.size) {
            return malformed("invalid_chunk")
        }
        if (size > 0) {
            bytes.add(all: chunk.slice(0, size))
        }
        if (bytes.size > CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES + CJGUI_SHARED_OPERATION_MAX_HEADER_BYTES) {
            return malformed("frame_too_large")
        }
        let headerEnd = findHeaderEnd()
        if (headerEnd < 0) {
            if (bytes.size > CJGUI_SHARED_OPERATION_MAX_HEADER_BYTES) {
                return malformed("invalid_frame_header")
            }
            return waiting()
        }
        if (headerEnd == 0 || headerEnd > CJGUI_SHARED_OPERATION_MAX_HEADER_BYTES) {
            return malformed("invalid_frame_header")
        }
        if (let Some(payloadSize) <- parsePayloadSize(headerEnd)) {
            let frameSize = headerEnd + 1 + payloadSize
            if (bytes.size < frameSize) {
                return waiting()
            }
            if (bytes.size > frameSize) {
                return malformed("trailing_data")
            }
            try {
                let payload = String.fromUtf8(bytes.toArray().slice(headerEnd + 1, payloadSize))
                let result = CjguiSharedOperationFrameRead(true, false, payload, "")
                terminalRead = Some(result)
                return result
            } catch (_) {
                return malformed("invalid_utf8")
            }
        }
        return malformed("invalid_frame_header")
    }

    private func findHeaderEnd(): Int64 {
        var index = 0
        while (index < bytes.size) {
            if (bytes[index] == b'\n') {
                return index
            }
            index += 1
        }
        return -1
    }

    private func parsePayloadSize(headerEnd: Int64): ?Int64 {
        var value = 0
        var index = 0
        while (index < headerEnd) {
            let valueByte = bytes[index]
            if (valueByte < b'0' || valueByte > b'9') {
                return None
            }
            let digit = Int64(valueByte) - Int64(b'0')
            if (value > (CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES - digit) / 10) {
                return None
            }
            value = value * 10 + digit
            index += 1
        }
        if (value <= 0 || value > CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES) {
            return None
        }
        return Some(value)
    }

    private func waiting(): CjguiSharedOperationFrameRead {
        return CjguiSharedOperationFrameRead(false, false, "", "")
    }

    private func malformed(reason: String): CjguiSharedOperationFrameRead {
        let result = CjguiSharedOperationFrameRead(false, true, "", reason)
        terminalRead = Some(result)
        return result
    }
}

private class CjguiSharedOperationSnapshotBody {
    let isAvailable: Bool
    let body: String
    let failureReason: String

    init(isAvailable: Bool, body: String, failureReason!: String = "invalid_snapshot") {
        this.isAvailable = isAvailable
        this.body = body
        this.failureReason = if (isAvailable) {
            ""
        } else {
            failureReason
        }
    }
}

/// Snapshot serialization can legitimately contain a large, authorized
/// collection. Keep its wire-size guard while avoiding quadratic copies of
/// every already-emitted line.
private class CjguiSharedOperationBoundedTextBuilder {
    private let builder: StringBuilder
    private var byteCount: Int64

    init() {
        this.builder = StringBuilder()
        this.byteCount = 0
    }

    func append(value: String): Bool {
        if (value.size < 0 || byteCount > CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES - 512 - value.size) {
            return false
        }
        builder.append(value)
        byteCount += value.size
        return true
    }

    func toString(): String {
        return builder.toString()
    }
}

/// A complete peer request waits here until the window-owning thread has run
/// the real domain handler. Socket workers only move bounded bytes and never
/// obtain a second domain or UI owner.
internal class CjguiSharedOperationPendingClientRequest {
    let payload: String
    private let responseQueue: ArrayBlockingQueue<String>
    private let lifecycleLock: Mutex
    // A complete frame creates this object immediately before it enters the
    // ready queue.  The owner checks this monotonic origin under the same
    // lock as its claim so a delayed worker cannot extend an unclaimed
    // request beyond the advertised absolute deadline.
    private let readyDeadlineStarted: MonoTime
    // waiting -> claimed -> cancelled is guarded as one transition. A
    // timeout may cancel only `waiting`; it can never race an owner into a
    // late mutation after reporting the request as expired.
    private var lifecycle: Int64
    private var responsePublished: Bool

    init(payload: String) {
        this.payload = payload
        this.responseQueue = ArrayBlockingQueue<String>(1)
        this.lifecycleLock = Mutex()
        this.readyDeadlineStarted = MonoTime.now()
        this.lifecycle = 0
        this.responsePublished = false
    }

    func claimForOwner(): Bool {
        return synchronized(lifecycleLock) {
            if (lifecycle == 0) {
                if ((MonoTime.now() - readyDeadlineStarted).toMilliseconds() >=
                    CJGUI_SHARED_OPERATION_READY_WAIT_DEADLINE_MS) {
                    lifecycle = 2
                    false
                } else {
                    lifecycle = 1
                    true
                }
            } else {
                false
            }
        }
    }

    func cancelIfUnclaimed(): Bool {
        return synchronized(lifecycleLock) {
            if (lifecycle == 0) {
                lifecycle = 2
                true
            } else {
                false
            }
        }
    }

    func complete(response: String): Bool {
        return synchronized(lifecycleLock) {
            if (lifecycle == 1) {
                if (responseQueue.tryAdd(response)) {
                    responsePublished = true
                    true
                } else {
                    false
                }
            } else {
                false
            }
        }
    }

    func cancel(): Unit {
        synchronized(lifecycleLock) {
            lifecycle = 2
        }
    }

    func isWaitingForOwner(): Bool {
        return synchronized(lifecycleLock) {
            lifecycle == 0
        }
    }

    func isCancelled(): Bool {
        return synchronized(lifecycleLock) {
            lifecycle == 2
        }
    }

    func waitForResponse(): ?String {
        return responseQueue.remove(Duration.millisecond * CJGUI_SHARED_OPERATION_IO_SLICE_MS)
    }

    func hasPublishedResponse(): Bool {
        return synchronized(lifecycleLock) {
            responsePublished
        }
    }
}

internal class CjguiSharedOperationAcceptedClient {
    let client: StreamingSocket

    init(client: StreamingSocket) {
        this.client = client
    }
}

private class CjguiSharedOperationActiveClient {
    let leaseId: Int64
    let client: StreamingSocket

    init(leaseId: Int64, client: StreamingSocket) {
        this.leaseId = leaseId
        this.client = client
    }
}

private class CjguiSharedOperationPendingClientLease {
    let leaseId: Int64
    let request: CjguiSharedOperationPendingClientRequest

    init(leaseId: Int64, request: CjguiSharedOperationPendingClientRequest) {
        this.leaseId = leaseId
        this.request = request
    }
}

private class CjguiSharedOperationClientRead {
    let isComplete: Bool
    let payload: String
    let reason: String

    init(isComplete: Bool, payload: String, reason: String) {
        this.isComplete = isComplete
        this.payload = payload
        this.reason = reason
    }
}

/// Each start receives a distinct state object. Old I/O workers can only
/// finish or release their own state after close; they can never consume a
/// socket from a later descriptor/session.
internal class CjguiSharedOperationIoState {
    private let lock: Mutex
    private var running: Bool
    private var queuedRequestBytes: Int64
    private var nextLeaseId: Int64
    private var acceptedClientCount: Int64
    private var readyRequestCount: Int64
    private var acceptedClientHighWater: Int64
    private var readyRequestHighWater: Int64
    private var readyRequestBytesHighWater: Int64
    private var activeIoWorkerCount: Int64
    private let acceptedClients: ArrayBlockingQueue<CjguiSharedOperationAcceptedClient>
    private let readyRequests: ArrayBlockingQueue<CjguiSharedOperationPendingClientRequest>
    private let activeClients: ArrayList<CjguiSharedOperationActiveClient>
    private let pendingRequests: ArrayList<CjguiSharedOperationPendingClientLease>
    private let workers: ArrayList<Future<Unit>>

    init() {
        this.lock = Mutex()
        this.running = true
        this.queuedRequestBytes = 0
        this.nextLeaseId = 1
        this.acceptedClientCount = 0
        this.readyRequestCount = 0
        this.acceptedClientHighWater = 0
        this.readyRequestHighWater = 0
        this.readyRequestBytesHighWater = 0
        this.activeIoWorkerCount = 0
        this.acceptedClients = ArrayBlockingQueue<CjguiSharedOperationAcceptedClient>(
            CJGUI_SHARED_OPERATION_MAX_QUEUED_CLIENTS)
        this.readyRequests = ArrayBlockingQueue<CjguiSharedOperationPendingClientRequest>(
            CJGUI_SHARED_OPERATION_MAX_READY_REQUESTS)
        this.activeClients = ArrayList<CjguiSharedOperationActiveClient>()
        this.pendingRequests = ArrayList<CjguiSharedOperationPendingClientLease>()
        this.workers = ArrayList<Future<Unit>>()
    }

    func retainWorker(worker: Future<Unit>): Unit {
        synchronized(lock) {
            workers.add(worker)
        }
    }

    func tryEnterWorker(): Bool {
        return synchronized(lock) {
            if (!running) {
                false
            } else {
                activeIoWorkerCount += 1
                true
            }
        }
    }

    func workerExited(): Unit {
        synchronized(lock) {
            activeIoWorkerCount -= 1
            if (activeIoWorkerCount < 0) {
                activeIoWorkerCount = 0
            }
        }
    }

    func isRunning(): Bool {
        return synchronized(lock) {
            running
        }
    }

    func tryAccept(client: StreamingSocket): Bool {
        if (!isRunning()) {
            return false
        }
        if (!acceptedClients.tryAdd(CjguiSharedOperationAcceptedClient(client))) {
            return false
        }
        synchronized(lock) {
            acceptedClientCount += 1
            if (acceptedClientCount > acceptedClientHighWater) {
                acceptedClientHighWater = acceptedClientCount
            }
        }
        return true
    }

    func takeAcceptedClient(): ?CjguiSharedOperationAcceptedClient {
        let accepted = acceptedClients.remove(Duration.millisecond * CJGUI_SHARED_OPERATION_IO_SLICE_MS)
        if (accepted.isSome()) {
            synchronized(lock) {
                acceptedClientCount -= 1
                if (acceptedClientCount < 0) {
                    acceptedClientCount = 0
                }
            }
        }
        return accepted
    }

    func activateClient(client: StreamingSocket): ?Int64 {
        return synchronized(lock) {
            if (!running) {
                None
            } else {
                let leaseId = nextLeaseId
                nextLeaseId += 1
                activeClients.add(CjguiSharedOperationActiveClient(leaseId, client))
                Some(leaseId)
            }
        }
    }

    func deactivateClient(leaseId: Int64): Unit {
        synchronized(lock) {
            var index = 0
            while (index < activeClients.size) {
                if (activeClients[index].leaseId == leaseId) {
                    let _ = activeClients.remove(at: index)
                    return
                }
                index += 1
            }
        }
    }

    func tryQueueRequest(request: CjguiSharedOperationPendingClientRequest): ?Int64 {
        return synchronized(lock) {
            if (!running || request.payload.size > CJGUI_SHARED_OPERATION_MAX_READY_REQUEST_BYTES ||
                queuedRequestBytes > CJGUI_SHARED_OPERATION_MAX_READY_REQUEST_BYTES - request.payload.size) {
                None
            } else {
                let next = nextLeaseId
                nextLeaseId += 1
                if (!readyRequests.tryAdd(request)) {
                    return None
                }
                queuedRequestBytes += request.payload.size
                readyRequestCount += 1
                if (readyRequestCount > readyRequestHighWater) {
                    readyRequestHighWater = readyRequestCount
                }
                if (queuedRequestBytes > readyRequestBytesHighWater) {
                    readyRequestBytesHighWater = queuedRequestBytes
                }
                pendingRequests.add(CjguiSharedOperationPendingClientLease(next, request))
                Some(next)
            }
        }
    }

    func takeReadyRequest(timeoutMs: UInt32): ?CjguiSharedOperationPendingClientRequest {
        let request = if (timeoutMs == 0u32) {
            readyRequests.tryRemove()
        } else {
            readyRequests.remove(Duration.millisecond * Int64(timeoutMs))
        }
        if (let Some(ready) <- request) {
            synchronized(lock) {
                queuedRequestBytes -= ready.payload.size
                if (queuedRequestBytes < 0) {
                    queuedRequestBytes = 0
                }
                readyRequestCount -= 1
                if (readyRequestCount < 0) {
                    readyRequestCount = 0
                }
            }
            return Some(ready)
        }
        return None
    }

    func finishPendingRequest(leaseId: Int64): Unit {
        synchronized(lock) {
            var index = 0
            while (index < pendingRequests.size) {
                if (pendingRequests[index].leaseId == leaseId) {
                    let _ = pendingRequests.remove(at: index)
                    return
                }
                index += 1
            }
        }
    }

    func diagnostics(): CjguiSharedOperationTransportDiagnostics {
        return synchronized(lock) {
            CjguiSharedOperationTransportDiagnostics(
                workers.size,
                activeIoWorkerCount,
                acceptedClientCount,
                activeClients.size,
                readyRequestCount,
                queuedRequestBytes,
                acceptedClientHighWater,
                readyRequestHighWater,
                readyRequestBytesHighWater
            )
        }
    }

    /// Removes accounting for an unclaimed request that has timed out. Its
    /// queue slot is left as a cancelled tombstone until the owner drains it;
    /// ArrayBlockingQueue has no safe arbitrary removal, and a later owner
    /// must observe that tombstone rather than execute it.
    func expirePendingRequest(leaseId: Int64): Unit {
        discardPendingRequest(leaseId)
    }

    /// A headless finite consumer may close immediately after its final
    /// `pump` returns. That pump has dispatched a real domain action but its
    /// worker can still be between the response queue and the socket. Give
    /// only those already-published responses a bounded grace; incomplete
    /// peers and requests not yet dispatched are still cancelled by `stop`.
    func waitForPublishedResponses(timeoutMs: Int64): Unit {
        let started = MonoTime.now()
        while ((MonoTime.now() - started).toMilliseconds() < timeoutMs) {
            let hasPublished = synchronized(lock) {
                var found = false
                for (pending in pendingRequests) {
                    if (pending.request.hasPublishedResponse()) {
                        found = true
                        break
                    }
                }
                found
            }
            if (!hasPublished) {
                return
            }
            sleep(Duration.millisecond)
        }
    }

    /// Shutdown first revokes the endpoint and active sockets, then observes
    /// whether the fixed loops leave their *own* state within one bounded I/O
    /// slice window. A false result is not a join failure or a reason to
    /// block the window: a later start has a distinct state object and cannot
    /// be served or polluted by a delayed old loop.
    func waitForWorkersToExit(timeoutMs: Int64): Bool {
        let started = MonoTime.now()
        var hasActiveWorkers = synchronized(lock) {
            activeIoWorkerCount > 0
        }
        while (hasActiveWorkers && (MonoTime.now() - started).toMilliseconds() < timeoutMs) {
            sleep(Duration.millisecond)
            hasActiveWorkers = synchronized(lock) {
                activeIoWorkerCount > 0
            }
        }
        return !hasActiveWorkers
    }

    private func discardPendingRequest(leaseId: Int64): Unit {
        synchronized(lock) {
            var index = 0
            while (index < pendingRequests.size) {
                if (pendingRequests[index].leaseId == leaseId) {
                    let _ = pendingRequests.remove(at: index)
                    return
                }
                index += 1
            }
        }
    }

    func stop(): Unit {
        let clientsToClose = ArrayList<StreamingSocket>()
        let requestsToCancel = ArrayList<CjguiSharedOperationPendingClientRequest>()
        synchronized(lock) {
            running = false
            for (active in activeClients) {
                clientsToClose.add(active.client)
            }
            while (activeClients.size > 0) {
                let _ = activeClients.remove(at: activeClients.size - 1)
            }
            for (pending in pendingRequests) {
                requestsToCancel.add(pending.request)
            }
            while (pendingRequests.size > 0) {
                let _ = pendingRequests.remove(at: pendingRequests.size - 1)
            }
            queuedRequestBytes = 0
            acceptedClientCount = 0
            readyRequestCount = 0
        }
        for (request in requestsToCancel) {
            request.cancel()
        }
        while (let Some(accepted) <- acceptedClients.tryRemove()) {
            closeClientQuietly(accepted.client)
        }
        while (let Some(ready) <- readyRequests.tryRemove()) {
            ready.cancel()
        }
        for (client in clientsToClose) {
            closeClientQuietly(client)
        }
    }
}

private func closeClientQuietly(client: StreamingSocket): Unit {
    try {
        client.close()
    } catch (_) {
    }
}

/// Experimental private-descriptor local transport for a registered
/// application domain. Unix platforms use a private Unix socket; Windows uses
/// a loopback-only TCP endpoint. Contract validation and authorization remain
/// shared, and actual actions are always delegated to the domain's handlers.
public class CjguiSharedOperationExternalConnection {
    public var socketPath: String
    private let domain: CjguiSharedOperationDomain
    private let changeDomain: ?CjguiSharedOperationChangeDomain
    private var targetedContextDomain: ?CjguiSharedOperationTargetedContextDomain
    private var rangeReadDomain: ?CjguiSharedOperationRangeReadDomain
    private let windowProjectionProvider: ?CjguiSharedOperationWindowProjectionProvider
    private var windowProjectionTargetProvider: ?CjguiSharedOperationWindowProjectionTargetProvider
    private var generatedUiProvider: ?CjguiSharedOperationGeneratedUiProvider
    private var treeSelectionProvider: ?CjguiSharedOperationTreeSelectionProvider
    private var windowProgressProvider: ?CjguiSharedOperationWindowProgressProvider
    private var windowProgressTargetProvider: ?CjguiSharedOperationWindowProgressTargetProvider
    private var transferReceiptProvider: ?CjguiSharedOperationTransferReceiptProvider
    private var positionMotionProvider: ?CjguiSharedOperationPositionMotionProvider
    // Fixed-snapshot leases (E1). The table is owned here and touched ONLY on
    // the owner thread; the provider is the application's immutable-version
    // port. `authorizationEpoch` is the framework-owned grant generation:
    // revoking bumps it, and every lease bound to an older epoch is terminal.
    private var snapshotProvider: ?CjguiSharedOperationSnapshotProvider
    private var snapshotLeases: ?CjguiSharedOperationSnapshotLeaseTable
    private var snapshotLimits: CjguiSharedOperationSnapshotLeaseLimits
    private var snapshotClock: ?CjguiSharedOperationSnapshotClock
    private var authorizationEpoch: Int64
    private var authorization: CjguiSharedOperationExternalAuthorization
    /// E1: an explicitly revoked authorization stays DEAD until the owner
    /// grants a new one. While true, no payload from the old capability is
    /// dispatched at all (no read/acquire/write, no provider call); only
    /// `grantAuthorization` clears it together with a new epoch.
    private var authorizationRevoked: Bool
    /// Named refusal of the most recent grantAuthorization attempt (""=ok).
    private var lastGrantRefusal: String = ""
    /// E1 multi-round isolation: fingerprints of the credentials this
    /// connection lifetime has revoked, newest first. Re-granting ANY of them
    /// is refused by name (`authorization_credential_recycled`) -- remembering
    /// only the most recent revoke let A->revoke->grantB->revokeB->grantA
    /// install A back. BOUNDED by design (see `retainRevokedCredential`): the
    /// policy is "the last N revoked credentials stay dead, and evictions are
    /// counted and reported", not "permanent isolation we cannot back".
    /// Fingerprints, never the secret text: a collision can only refuse a
    /// credential, never admit a revoked one.
    private var revokedCredentialFingerprints: ArrayList<String>
    /// How many revoked fingerprints were dropped at capacity. Non-zero means
    /// the endpoint must NOT claim unbounded isolation; diagnostics say so.
    private var revokedCredentialEvictions: Int64
    /// Named refusal of the most recent `enableSnapshotReads` attempt (""=ok).
    private var lastSnapshotEnableRefusal: String = ""
    private let transportLock: Mutex
    /// Test-only ready-queue observation (see CjguiSharedOperationReadyRequestObserver).
    private var testReadyRequestObserver: ?CjguiSharedOperationReadyRequestObserver
    private var readyRequestSequence: Int64
    private var server: ?ServerSocket
    private var ioState: ?CjguiSharedOperationIoState
    private var privateDirectory: ?Path
    private var descriptorPath: String
    private var ownsSocketPath: Bool
    private var ownsDescriptorPath: Bool
    // A successful INVOKE is the only transport event that asks the optional
    // UI owner to refresh. GET_CONTEXT/GET_CHANGES/READ_RANGE remain pure
    // reads, so polling a window projection cannot manufacture a new scene.
    private var windowRefreshRequested: Bool
    // Identity of the currently bound endpoint. It is bumped on every
    // successful bind so a client that reconnects to a restarted endpoint can
    // tell "my ticket is gone because the endpoint was replaced" from "my ticket
    // was rejected". A process-local counter alone is not an identity, so the
    // descriptor carries it together with the endpoint's own socket path.
    private var endpointGeneration: Int64
    // Instance identity of this connection object (see nextEndpointInstance).
    private let endpointInstanceValue: String

    public init(
        domain: CjguiSharedOperationDomain,
        authorization: CjguiSharedOperationExternalAuthorization
    ) {
        this.socketPath = ""
        this.domain = domain
        this.changeDomain = None
        this.targetedContextDomain = None
        this.rangeReadDomain = None
        this.snapshotProvider = None
        this.snapshotLeases = None
        this.snapshotLimits = CjguiSharedOperationSnapshotLeaseLimits()
        this.snapshotClock = None
        this.authorizationEpoch = 1
        this.authorizationRevoked = false
        this.revokedCredentialFingerprints = ArrayList<String>()
        this.revokedCredentialEvictions = 0
        this.windowProjectionProvider = None
        this.windowProjectionTargetProvider = None
        this.generatedUiProvider = None
        this.treeSelectionProvider = None
        this.windowProgressProvider = None
        this.windowProgressTargetProvider = None
        this.transferReceiptProvider = None
        this.positionMotionProvider = None
        this.authorization = authorization
        this.transportLock = Mutex()
        this.server = None
        this.ioState = None
        this.privateDirectory = None
        this.descriptorPath = ""
        this.ownsSocketPath = false
        this.ownsDescriptorPath = false
        this.windowRefreshRequested = false
        this.endpointGeneration = 0
        this.endpointInstanceValue = nextEndpointInstance()
        this.testReadyRequestObserver = None
        this.readyRequestSequence = 0
    }

    /// Supplies optional bounded-change capability without requiring every
    /// shared-operation consumer to implement a second state projection.
    public init(
        domain: CjguiSharedOperationDomain,
        authorization: CjguiSharedOperationExternalAuthorization,
        changeDomain: CjguiSharedOperationChangeDomain
    ) {
        this.socketPath = ""
        this.domain = domain
        this.changeDomain = Some(changeDomain)
        this.targetedContextDomain = None
        this.rangeReadDomain = None
        this.snapshotProvider = None
        this.snapshotLeases = None
        this.snapshotLimits = CjguiSharedOperationSnapshotLeaseLimits()
        this.snapshotClock = None
        this.authorizationEpoch = 1
        this.authorizationRevoked = false
        this.revokedCredentialFingerprints = ArrayList<String>()
        this.revokedCredentialEvictions = 0
        this.windowProjectionProvider = None
        this.windowProjectionTargetProvider = None
        this.generatedUiProvider = None
        this.treeSelectionProvider = None
        this.windowProgressProvider = None
        this.windowProgressTargetProvider = None
        this.transferReceiptProvider = None
        this.positionMotionProvider = None
        this.authorization = authorization
        this.transportLock = Mutex()
        this.server = None
        this.ioState = None
        this.privateDirectory = None
        this.descriptorPath = ""
        this.ownsSocketPath = false
        this.ownsDescriptorPath = false
        this.windowRefreshRequested = false
        this.endpointGeneration = 0
        this.endpointInstanceValue = nextEndpointInstance()
        this.testReadyRequestObserver = None
        this.readyRequestSequence = 0
    }

    /// A live window may add a derived, read-only projection to the ordinary
    /// domain snapshot. Supplying this optional provider is the only way a
    /// connection can claim that a window is active.
    public init(
        domain: CjguiSharedOperationDomain,
        authorization: CjguiSharedOperationExternalAuthorization,
        windowProjectionProvider: CjguiSharedOperationWindowProjectionProvider
    ) {
        this.socketPath = ""
        this.domain = domain
        this.changeDomain = None
        this.targetedContextDomain = None
        this.rangeReadDomain = None
        this.snapshotProvider = None
        this.snapshotLeases = None
        this.snapshotLimits = CjguiSharedOperationSnapshotLeaseLimits()
        this.snapshotClock = None
        this.authorizationEpoch = 1
        this.authorizationRevoked = false
        this.revokedCredentialFingerprints = ArrayList<String>()
        this.revokedCredentialEvictions = 0
        this.windowProjectionProvider = Some(windowProjectionProvider)
        this.windowProjectionTargetProvider = None
        this.generatedUiProvider = None
        this.treeSelectionProvider = None
        this.windowProgressProvider = None
        this.windowProgressTargetProvider = None
        this.transferReceiptProvider = None
        this.positionMotionProvider = None
        this.authorization = authorization
        this.transportLock = Mutex()
        this.server = None
        this.ioState = None
        this.privateDirectory = None
        this.descriptorPath = ""
        this.ownsSocketPath = false
        this.ownsDescriptorPath = false
        this.windowRefreshRequested = false
        this.endpointGeneration = 0
        this.endpointInstanceValue = nextEndpointInstance()
        this.testReadyRequestObserver = None
        this.readyRequestSequence = 0
    }

    /// Combines optional bounded changes and an optional active-window
    /// projection without making either capability mandatory for headless
    /// consumers.
    public init(
        domain: CjguiSharedOperationDomain,
        authorization: CjguiSharedOperationExternalAuthorization,
        changeDomain: CjguiSharedOperationChangeDomain,
        windowProjectionProvider: CjguiSharedOperationWindowProjectionProvider
    ) {
        this.socketPath = ""
        this.domain = domain
        this.changeDomain = Some(changeDomain)
        this.targetedContextDomain = None
        this.rangeReadDomain = None
        this.snapshotProvider = None
        this.snapshotLeases = None
        this.snapshotLimits = CjguiSharedOperationSnapshotLeaseLimits()
        this.snapshotClock = None
        this.authorizationEpoch = 1
        this.authorizationRevoked = false
        this.revokedCredentialFingerprints = ArrayList<String>()
        this.revokedCredentialEvictions = 0
        this.windowProjectionProvider = Some(windowProjectionProvider)
        this.windowProjectionTargetProvider = None
        this.generatedUiProvider = None
        this.treeSelectionProvider = None
        this.windowProgressProvider = None
        this.windowProgressTargetProvider = None
        this.transferReceiptProvider = None
        this.positionMotionProvider = None
        this.authorization = authorization
        this.transportLock = Mutex()
        this.server = None
        this.ioState = None
        this.privateDirectory = None
        this.descriptorPath = ""
        this.ownsSocketPath = false
        this.ownsDescriptorPath = false
        this.windowRefreshRequested = false
        this.endpointGeneration = 0
        this.endpointInstanceValue = nextEndpointInstance()
        this.testReadyRequestObserver = None
        this.readyRequestSequence = 0
    }

    public func start(): Bool {
        return synchronized(transportLock) {
            startUnlocked()
        }
    }

    /// Enables a separately declared bounded-range capability before the
    /// connection descriptor is created. This preserves the existing domain
    /// contract for consumers that do not expose document text.
    public func enableRangeReads(domain: CjguiSharedOperationRangeReadDomain): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            rangeReadDomain = Some(domain)
            return true
        }
    }

    /// Enables fixed-snapshot leases before the descriptor is created. Without
    /// this call the endpoint does not declare SNAPSHOT_* at all, so a client
    /// that asks for it gets the unchanged `invalid_request` surface instead of
    /// a half-working lease. The provider supplies immutable handles; the
    /// framework owns tokens, TTL, limits and accounting.
    public func enableSnapshotReads(
        provider: CjguiSharedOperationSnapshotProvider,
        limits!: CjguiSharedOperationSnapshotLeaseLimits = CjguiSharedOperationSnapshotLeaseLimits(),
        clock!: CjguiSharedOperationSnapshotClock = CjguiSharedOperationSnapshotSystemClock()
    ): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            // E1: installing a fresh table REPLACES the old one, so anything
            // the old table still holds would lose its owner silently: a
            // `cleanup_pending` handle whose release kept failing is a real
            // resource, and a lease that is still active means the old table
            // is still the authority for live tokens. Refuse by name and keep
            // the old table; the owner retries cleanup (or converges its
            // leases) and reinstalls afterwards.
            if (let Some(oldTable) <- snapshotLeases) {
                if (oldTable.cleanupPendingCount() > 0 || oldTable.activeCount() > 0) {
                    lastSnapshotEnableRefusal = "snapshot_reinstall_pending_cleanup"
                    return false
                }
            }
            snapshotProvider = Some(provider)
            snapshotLimits = limits
            snapshotClock = Some(clock)
            snapshotLeases = Some(CjguiSharedOperationSnapshotLeaseTable(limits, clock))
            lastSnapshotEnableRefusal = ""
            return true
        }
    }

    /// Provider-driven invalidation: the resource instance closed, was
    /// replaced, or its workspace ended. Called by the application on the
    /// owner thread; every matching lease becomes terminal with a named reason
    /// and its handle is released.
    public func invalidateSnapshotResource(resourceId: Int64, resourceInstanceId: String,
        reason: String): Int64 {
        return synchronized(transportLock) {
            let effective = if (isSafeLeaseReason(reason)) { reason } else { "snapshot_resource_closed" }
            return match (snapshotLeases) {
                case Some(table) => table.invalidateResource(resourceId, resourceInstanceId, effective)
                case None => 0
            }
        }
    }

    /// Framework-owned authorization lifecycle. Revocation is REAL: the flag
    /// set below stays until an explicit `grantAuthorization`, so the revoked
    /// caller's AUTH cannot read/acquire/write anything and the provider is
    /// never called on its behalf -- bumping the epoch alone would let the old
    /// AUTH acquire a fresh grant immediately, which is exactly the hole this
    /// closes. Existing leases of older epochs are terminal and their tokens
    /// never revive. The revoked capability itself is retained (bounded, see
    /// `retainRevokedCredential`) so no LATER grant round can install it back.
    public func revokeAuthorization(): Int64 {
        return synchronized(transportLock) {
            authorizationRevoked = true
            retainRevokedCredential(authorization.capabilityForGrantedCaller())
            authorizationEpoch += 1
            return match (snapshotLeases) {
                case Some(table) => table.invalidateEpochsBefore(authorizationEpoch, "authorization_revoked")
                case None => 0
            }
        }
    }

    /// Explicit re-authorization after a revoke: installs a NEW capability and
    /// a NEW grant epoch; the revoked flag clears only here, and old tokens
    /// stay terminal forever. The replacement must be a credential this
    /// connection never revoked: re-granting one is refused by name
    /// (`authorization_credential_recycled`) because installing it back would
    /// hand the revoked caller its access again -- no matter how many grant
    /// rounds happened in between. A replacement without a usable capability
    /// is likewise refused rather than silently leaving the endpoint
    /// half-authorized.
    public func grantAuthorization(
        replacement: CjguiSharedOperationExternalAuthorization): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            if (isRevokedCredential(replacement.capabilityForGrantedCaller())) {
                lastGrantRefusal = "authorization_credential_recycled"
                return false
            }
            let saved = this.authorization
            this.authorization = replacement
            if (!hasSafeAuthorization()) {
                this.authorization = saved
                lastGrantRefusal = "authorization_invalid"
                return false
            }
            authorizationRevoked = false
            lastGrantRefusal = ""
            authorizationEpoch += 1
            if (let Some(table) <- snapshotLeases) {
                let _ = table.invalidateEpochsBefore(authorizationEpoch, "authorization_revoked")
            }
            return true
        }
    }

    /// Remember one revoked credential's fingerprint. Capacity policy: the last
    /// `CJGUI_SHARED_OPERATION_REVOKED_CREDENTIAL_CAPACITY` revoked credentials
    /// stay dead; past that the oldest is evicted and COUNTED
    /// (`revokedCredentialEvictionCount`), because a bounded structure cannot
    /// promise permanent isolation and claiming it would be a lie. A repeated
    /// revoke of the same credential moves it to the front instead of adding a
    /// duplicate, so a small capacity covers long alternating histories.
    private func retainRevokedCredential(capability: String): Unit {
        if (capability == "") {
            return
        }
        let fingerprint = sharedOperationCredentialFingerprint(capability)
        var index: Int64 = 0
        while (index < Int64(revokedCredentialFingerprints.size)) {
            if (revokedCredentialFingerprints[index] == fingerprint) {
                revokedCredentialFingerprints.remove(at: index)
                revokedCredentialFingerprints.add(fingerprint, at: 0)
                return
            }
            index += 1
        }
        if (Int64(revokedCredentialFingerprints.size) >=
            CJGUI_SHARED_OPERATION_REVOKED_CREDENTIAL_CAPACITY) {
            revokedCredentialFingerprints.remove(at: Int64(revokedCredentialFingerprints.size) - 1)
            revokedCredentialEvictions += 1
        }
        revokedCredentialFingerprints.add(fingerprint, at: 0)
    }

    private func isRevokedCredential(capability: String): Bool {
        if (capability == "") {
            return false
        }
        let fingerprint = sharedOperationCredentialFingerprint(capability)
        for (retainedFingerprint in revokedCredentialFingerprints) {
            if (retainedFingerprint == fingerprint) {
                return true
            }
        }
        return false
    }

    /// Bounded-history observation for owners/tests: how many revoked
    /// credentials this endpoint still remembers, and how many it dropped at
    /// capacity. A non-zero eviction count is the endpoint saying out loud
    /// that its isolation is bounded, not permanent.
    public func revokedCredentialRetentionCount(): Int64 {
        return synchronized(transportLock) { Int64(revokedCredentialFingerprints.size) }
    }

    public func revokedCredentialEvictionCount(): Int64 {
        return synchronized(transportLock) { revokedCredentialEvictions }
    }

    public func revokedCredentialRetentionCapacity(): Int64 {
        return CJGUI_SHARED_OPERATION_REVOKED_CREDENTIAL_CAPACITY
    }

    /// Named reason the last `grantAuthorization` refused ("" on success).
    /// Owners and tests read this instead of guessing from a bare false.
    public func lastGrantRefusalReason(): String {
        return synchronized(transportLock) { lastGrantRefusal }
    }

    /// Named reason the last `enableSnapshotReads` refused ("" on success).
    public func lastSnapshotEnableRefusalReason(): String {
        return synchronized(transportLock) { lastSnapshotEnableRefusal }
    }

    /// Workspace lifecycle end: every lease of this endpoint becomes terminal.
    public func invalidateSnapshotWorkspace(reason!: String = "snapshot_workspace_changed"): Int64 {
        return synchronized(transportLock) {
            return match (snapshotLeases) {
                case Some(table) => table.invalidateAll(reason)
                case None => 0
            }
        }
    }

    /// Diagnostics for tests and owners: active leases, retained records and
    /// deferred cleanups. No lease content is disclosed.
    public func snapshotLeaseDiagnostics(): String {
        return synchronized(transportLock) {
            let revokedSummary = "revoked_credential_retained=${revokedCredentialFingerprints.size} " +
                "revoked_credential_evictions=${revokedCredentialEvictions}"
            return match (snapshotLeases) {
                case Some(table) => "active=${table.activeCount()} records=${table.retainedRecordCount()} " +
                    "cleanup_pending=${table.cleanupPendingCount()} epoch=${authorizationEpoch} " +
                    "authorization_revoked=${authorizationRevoked} ${revokedSummary}"
                case None => "active=0 records=0 cleanup_pending=0 epoch=${authorizationEpoch} " +
                    "authorization_revoked=${authorizationRevoked} provider=absent ${revokedSummary}"
            }
        }
    }

    /// Opts a domain into a genuine owner-selected context projection for an
    /// explicit target list.  Full GET_CONTEXT continues to call the stable
    /// domain snapshot and never gains a hidden partial-result behavior.
    public func enableTargetedContextReads(domain: CjguiSharedOperationTargetedContextDomain): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            targetedContextDomain = Some(domain)
            return true
        }
    }

    /// Enables a compact read-only progress endpoint before the descriptor is
    /// published.  It is separate from GET_CONTEXT so a caller cannot acquire
    /// component/resource projection data merely by observing frame progress.
    public func enableWindowProgressReads(provider: CjguiSharedOperationWindowProgressProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            windowProgressProvider = Some(provider)
            return true
        }
    }

    /// One bounded receipt projection on the existing authorized window read
    /// channel. Enabling it never gives the transport an owner mutation path.
    public func enableTransferReceiptReads(provider: CjguiSharedOperationTransferReceiptProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) { return false }
            transferReceiptProvider = Some(provider)
            return true
        }
    }

    /// Opt-in position motion uses its own read, set and clear grants. The
    /// provider resolves only host-exposed accepted targets on the owner turn.
    public func enablePositionMotion(provider: CjguiSharedOperationPositionMotionProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) { return false }
            positionMotionProvider = Some(provider)
            return true
        }
    }

    /// Enables target-bound narrow progress and interaction reads before the
    /// descriptor is published. It complements the projection target catalog
    /// rather than selecting an arbitrary current window.
    public func enableWindowProgressTargetReads(provider: CjguiSharedOperationWindowProgressTargetProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            windowProgressTargetProvider = Some(provider)
            return true
        }
    }

    /// Enables explicit multi-window discovery and target-bound context
    /// reads before the descriptor is published. The domain and its existing
    /// GET_CONTEXT resource authorization remain the sole source of business
    /// content visibility; this capability only chooses one live projection.
    public func enableWindowProjectionTargetReads(provider: CjguiSharedOperationWindowProjectionTargetProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            windowProjectionTargetProvider = Some(provider)
            return true
        }
    }

    /// Enables the generated-UI structure entry points (capability query,
    /// accepted-structure read and candidate submission) before the descriptor
    /// is published. The application owns the structure holder, fields and
    /// actions behind the provider; this connection only authorizes and
    /// forwards bounded payloads.
    /// Test-only: observe the moment each public request becomes ready for the
    /// owner. It adds no protocol surface and is only used by bounded latency
    /// probes that need the real ready-queue entry on the host's monotonic clock.
    public func enableTestReadyRequestObserver(
        observer: CjguiSharedOperationReadyRequestObserver): Bool {
        testReadyRequestObserver = observer
        return true
    }

    public func enableGeneratedUiProvider(provider: CjguiSharedOperationGeneratedUiProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            generatedUiProvider = Some(provider)
            return true
        }
    }

    /// Enables the shared tree/collection selection entry points (snapshot
    /// read and human-equivalent selection updates) before the descriptor is
    /// published. The window's own selection object stays the single owner.
    public func enableTreeSelectionProvider(provider: CjguiSharedOperationTreeSelectionProvider): Bool {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                return false
            }
            treeSelectionProvider = Some(provider)
            return true
        }
    }

    /// Monotonic identity of the endpoint this transport is serving (0 before
    /// the first successful bind). Every generated-UI reply carries it, so a
    /// client can invalidate cached tickets when the endpoint changed.
    /// Opaque, non-authorizing identity of THIS endpoint instance: the instance
    /// nonce plus the current bind generation. A client carries it with every
    /// ticket and observation anchor, so a restarted endpoint with the same bind
    /// count can never be mistaken for the old one.
    public func endpointIdentity(): String {
        return synchronized(transportLock) {
            "${endpointInstanceValue}-${endpointGeneration}"
        }
    }

    public func endpointEpoch(): Int64 {
        return synchronized(transportLock) {
            endpointGeneration
        }
    }

    /// The raw instance nonce exactly as published in the descriptor's
    /// ENDPOINT_INSTANCE field. Lease requests echo this value together with
    /// endpointEpoch(); endpointIdentity() is the composite form and does not
    /// satisfy the acquire field.
    public func endpointInstance(): String {
        return synchronized(transportLock) {
            endpointInstanceValue
        }
    }

    public func connectionInfo(): ?CjguiSharedOperationConnectionInfo {
        return synchronized(transportLock) {
            if (let Some(_) <- server) {
                Some(
                    CjguiSharedOperationConnectionInfo(
                        CJGUI_SHARED_OPERATION_PROTOCOL,
                        descriptorPath,
                        socketPath,
                        authorization.callerId,
                        authorization.capabilityForGrantedCaller(),
                        authorization.actionScopes(),
                        visibleActions()
                    )
                )
            } else {
                None
            }
        }
    }

    /// Returns local I/O counters for an owner-side diagnostic or benchmark.
    /// They describe this transient transport only, never domain state, and
    /// are unavailable after the endpoint is closed.
    public func transportDiagnostics(): ?CjguiSharedOperationTransportDiagnostics {
        let activeState = synchronized(transportLock) {
            ioState
        }
        if (let Some(state) <- activeState) {
            return Some(state.diagnostics())
        }
        return None
    }

    /// Services at most one complete framed request already read by the fixed
    /// I/O workers. Domain and window work remain on the caller's established
    /// thread; a slow socket cannot occupy that thread.
    public func pump(timeoutMs: UInt32): Bool {
        // Owner-thread maintenance beat (E1): hard-deadline expiry, deferred
        // cleanup retries and terminal-window recycling run every turn even
        // when no client sends anything, so an idle endpoint still reclaims
        // its leases. The table is owner-only by contract; this is that owner.
        synchronized(transportLock) {
            if (let Some(table) <- snapshotLeases) {
                let _ = table.purgeExpired()
            }
        }
        let activeState = synchronized(transportLock) {
            ioState
        }
        if (let Some(state) <- activeState) {
            let started = MonoTime.now()
            while (state.isRunning()) {
                let elapsedMs = (MonoTime.now() - started).toMilliseconds()
                if (timeoutMs > 0u32 && elapsedMs >= Int64(timeoutMs)) {
                    return false
                }
                let remainingMs: UInt32 = if (timeoutMs == 0u32) {
                    0u32
                } else {
                    UInt32(Int64(timeoutMs) - elapsedMs)
                }
                if (let Some(request) <- state.takeReadyRequest(remainingMs)) {
                    // A ready queue may contain an expired tombstone. Drain
                    // it without treating the cancelled request as served;
                    // the next request still gets the original caller's
                    // bounded wait budget.
                    if (!request.claimForOwner()) {
                        continue
                    }
                    // Authorization and version checks intentionally happen
                    // here, at execution time, rather than when an I/O
                    // worker queued a syntactically complete request.
                    let _ = request.complete(dispatchPayload(request.payload))
                    return true
                }
                return false
            }
            return false
        }
        return false
    }

    /// Serves a bounded burst before a window owner consumes its coalesced
    /// refresh signal. This prevents a serial external batch from forcing one
    /// native frame per record while preserving an explicit upper bound on UI
    /// time spent away from local input.
    public func pumpBurst(maximumClients: UInt32, firstTimeoutMs: UInt32, subsequentTimeoutMs: UInt32): UInt32 {
        if (maximumClients == 0u32 || !pump(firstTimeoutMs)) {
            return 0u32
        }
        var served = 1u32
        while (served < maximumClients) {
            if (!pump(subsequentTimeoutMs)) {
                break
            }
            served += 1u32
        }
        return served
    }

    /// Consumes one successful external-mutation signal for a live window.
    /// It is intentionally independent of `pump`'s “client served” result:
    /// a completed GET must not request a build/layout/submission.
    public func consumeWindowRefreshRequest(): Bool {
        return synchronized(transportLock) {
            let requested = windowRefreshRequested
            windowRefreshRequested = false
            return requested
        }
    }

    public func close() {
        let _ = synchronized(transportLock) {
            if (let Some(activeIoState) <- ioState) {
                activeIoState.waitForPublishedResponses(CJGUI_SHARED_OPERATION_CLOSE_RESPONSE_GRACE_MS)
            }
            cleanupOwnedTransport()
            // E1: after the transport is down there is no owner pump any more,
            // so THIS is the last owner-safe point. Bounded drain of deferred
            // releases: a fixed number of sweeps with tiny spacing. A handle
            // that still fails stays counted and answerable through
            // `snapshotLeaseDiagnostics` -- never silently zeroed, never an
            // unbounded wait.
            if (let Some(table) <- snapshotLeases) {
                if (table.deferredCleanupCount() > 0) {
                    var sweep = 0
                    while (sweep < 3 && table.retryDeferredCleanupOnce() > 0) {
                        sweep += 1
                        if (sweep < 3) {
                            sleep(Duration.millisecond * 25)
                        }
                    }
                }
            }
        }
    }

    /// Exposes the same authorization and declaration checks as the socket for
    /// another local transport implementation; it is not a privileged bypass.
    public func dispatchPayload(payload: String): String {
        if (synchronized(transportLock) { authorizationRevoked }) {
            // A revoked authorization is dead, not paused: nothing from the
            // old capability is dispatched and no provider is touched.
            return errorPayload("authorization_revoked")
        }
        if (!hasSafeAuthorization()) {
            return errorPayload("unauthorized_caller")
        }
        if (payload.size <= 0 || payload.size > CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES) {
            return errorPayload("invalid_request")
        }
        let lines = payload.split("\n")
        if (lines.size < 3 || lines[0] != "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}") {
            return errorPayload("invalid_request")
        }
        let authorizationFields = lines[1].split(" ")
        if (authorizationFields.size != 2 || authorizationFields[0] != "AUTH") {
            return errorPayload("invalid_request")
        }
        if (!authorization.matchesCapability(authorizationFields[1])) {
            return errorPayload("unauthorized_caller")
        }
        if (lines[2].startsWith("GET_CONTEXT ")) {
            return dispatchContextRead(lines)
        }
        if (lines[2].startsWith("GET_CHANGES ")) {
            return dispatchChangesRead(lines)
        }
        if (lines[2].startsWith("GET_WINDOW_PROGRESS ")) {
            return dispatchWindowProgressTargetRead(lines)
        }
        if (lines[2] == "GET_WINDOW_PROGRESS") {
            return dispatchWindowProgressRead(lines)
        }
        if (lines[2].startsWith("GET_NODE_TRANSLATION ")) {
            return dispatchPositionMotionRead(lines)
        }
        if (lines[2].startsWith("SET_NODE_TRANSLATION ")) {
            return dispatchPositionMotionSet(lines)
        }
        if (lines[2].startsWith("CLEAR_NODE_TRANSLATION ")) {
            return dispatchPositionMotionClear(lines)
        }
        if (lines[2].startsWith("GET_TRANSFER_RECEIPT_CHANGES ")) {
            return dispatchTransferReceiptChangesRead(lines)
        }
        if (lines[2].startsWith("GET_TRANSFER_RECEIPT ")) {
            return dispatchTransferReceiptRead(lines)
        }
        if (lines[2] == "GET_WINDOW_TARGETS") {
            return dispatchWindowProjectionTargetsRead(lines)
        }
        if (lines[2].startsWith("GET_WINDOW_CONTEXT ")) {
            return dispatchWindowProjectionContextRead(lines)
        }
        if (lines[2].startsWith("GET_WINDOW_INTERACTION ")) {
            return dispatchWindowInteractionTargetRead(lines)
        }
        if (lines[2] == "GET_WINDOW_INTERACTION") {
            return dispatchWindowInteractionRead(lines)
        }
        if (lines[2].startsWith("READ_RANGE ")) {
            return dispatchRangeRead(lines)
        }
        if (lines[2].startsWith("SNAPSHOT_ACQUIRE ")) {
            return dispatchSnapshotAcquire(lines)
        }
        if (lines[2].startsWith("SNAPSHOT_READ ")) {
            return dispatchSnapshotRead(lines)
        }
        if (lines[2].startsWith("SNAPSHOT_RELEASE ")) {
            return dispatchSnapshotRelease(lines)
        }
        if (lines[2] == "GET_GENERATED_UI_CAPABILITIES") {
            return dispatchGeneratedUiCapabilities(lines)
        }
        if (lines[2] == "GET_GENERATED_UI_STRUCTURE") {
            return dispatchGeneratedUiStructure(lines)
        }
        if (lines[2] == "GET_GENERATED_UI_FIELDS") {
            return dispatchGeneratedUiFields(lines)
        }
        if (lines[2] == "GET_GENERATED_UI_INSTANCES") {
            return dispatchGeneratedUiInstances(lines)
        }
        if (lines[2].startsWith("GET_GENERATED_UI_CANDIDATE ")) {
            return dispatchGeneratedUiCandidate(lines)
        }
        if (lines[2] == "GET_GENERATED_UI_SNAPSHOT") {
            return dispatchGeneratedUiSnapshot(lines)
        }
        if (lines[2].startsWith("GET_GENERATED_UI_CHANGES ")) {
            return dispatchGeneratedUiChanges(lines)
        }
        if (lines[2].startsWith("GET_GENERATED_UI_SECTION ")) {
            return dispatchGeneratedUiSection(lines)
        }
        if (lines[2] == "GET_TREE_SELECTION") {
            return dispatchTreeSelectionRead(lines)
        }
        if (lines[2].startsWith("UPDATE_TREE_SELECTION ")) {
            return dispatchTreeSelectionUpdate(lines)
        }
        if (lines[2].startsWith("SUBMIT_GENERATED_UI ")) {
            return dispatchGeneratedUiSubmit(lines)
        }
        if (lines[2].startsWith("INVOKE ")) {
            return dispatchInvocation(lines)
        }
        return errorPayload("invalid_request")
    }

    private func startUnlocked(): Bool {
        if (let Some(_) <- server) {
            return true
        }
        if (!hasSafeAuthorization()) {
            return false
        }
        cleanupOwnedTransport()
        return startPlatformTransportUnlocked()
    }

    @When[os != "Windows"]
    private func startPlatformTransportUnlocked(): Bool {
        try {
            let directory = Directory.createTemp("/tmp")
            if (chmod(directory.toString(), 0o700u32) != 0) {
                let _ = removeIfExists(directory, recursive: false)
                return false
            }
            privateDirectory = Some(directory)
            let newSocketPath = directory.join("shared-operation.sock").toString()
            let newDescriptorPath = directory.join("connection.cjgui").toString()
            let boundServer = UnixServerSocket(bindAt: newSocketPath)
            boundServer.bind()
            endpointGeneration += 1
            socketPath = newSocketPath
            descriptorPath = newDescriptorPath
            ownsSocketPath = true
            server = Some(boundServer)
            if (chmod(socketPath, 0o600u32) != 0) {
                cleanupOwnedTransport()
                return false
            }
            if (let Some(payload) <- descriptorPayload()) {
                try (descriptor = File.create(descriptorPath)) {
                    ownsDescriptorPath = true
                    descriptor.write(payload.toArray())
                }
            } else {
                cleanupOwnedTransport()
                return false
            }
            if (chmod(descriptorPath, 0o600u32) != 0) {
                cleanupOwnedTransport()
                return false
            }
            let newIoState = CjguiSharedOperationIoState()
            ioState = Some(newIoState)
            startIoWorkers(boundServer, newIoState)
            return true
        } catch (_) {
            cleanupOwnedTransport()
            return false
        }
    }

    @When[os == "Windows"]
    private func startPlatformTransportUnlocked(): Bool {
        try {
            let tempRoot = getVariable("TEMP").getOrThrow()
            let directory = Directory.createTemp(tempRoot)
            privateDirectory = Some(directory)
            let newDescriptorPath = directory.join("connection.cjgui").toString()
            let boundServer = TcpServerSocket(bindAt: IPSocketAddress("127.0.0.1", 0))
            boundServer.bind()
            let localAddress = (boundServer.localAddress as IPSocketAddress).getOrThrow()
            let newEndpoint = "tcp://127.0.0.1:${localAddress.port}"
            endpointGeneration += 1
            socketPath = newEndpoint
            descriptorPath = newDescriptorPath
            ownsSocketPath = false
            server = Some(boundServer)
            if (let Some(payload) <- descriptorPayload()) {
                try (descriptor = File.create(descriptorPath)) {
                    ownsDescriptorPath = true
                    descriptor.write(payload.toArray())
                }
            } else {
                cleanupOwnedTransport()
                return false
            }
            let newIoState = CjguiSharedOperationIoState()
            ioState = Some(newIoState)
            startIoWorkers(boundServer, newIoState)
            return true
        } catch (_) {
            cleanupOwnedTransport()
            return false
        }
    }

    private func cleanupOwnedTransport() {
        if (let Some(activeIoState) <- ioState) {
            activeIoState.stop()
            // A bounded false leaves no shared endpoint or state for a later
            // generation.  Do not turn close into an unbounded worker join.
            let _ = activeIoState.waitForWorkersToExit(CJGUI_SHARED_OPERATION_CLOSE_RESPONSE_GRACE_MS)
        }
        ioState = None
        if (let Some(activeServer) <- server) {
            try {
                activeServer.close()
            } catch (_) {
            }
        }
        server = None
        // Endpoint shutdown converges every fixed-snapshot lease: the framework owns the
        // tokens, so it must not leave an application handle alive after the socket is gone.
        // A handle that fails to release lands in `cleanup_pending` and is retried by the next
        // owner maintenance, never silently dropped.
        if (let Some(table) <- snapshotLeases) {
            let _ = table.invalidateAll("snapshot_endpoint_closed")
            // Close is itself a maintenance point: a release that failed during
            // convergence is retried here once, and anything still pending keeps
            // its `cleanup_pending` accounting for the next owner beat -- it is
            // never silently dropped or reported as zero.
            let _ = table.purgeExpired()
        }
        if (ownsDescriptorPath && descriptorPath != "") {
            try {
                let _ = removeIfExists(Path(descriptorPath), recursive: false)
            } catch (_) {
            }
        }
        if (ownsSocketPath && socketPath != "") {
            try {
                let _ = removeIfExists(Path(socketPath), recursive: false)
            } catch (_) {
            }
        }
        if (let Some(directory) <- privateDirectory) {
            try {
                let _ = removeIfExists(directory, recursive: false)
            } catch (_) {
            }
        }
        privateDirectory = None
        descriptorPath = ""
        socketPath = ""
        ownsDescriptorPath = false
        ownsSocketPath = false
    }

    private func startIoWorkers(server: ServerSocket, state: CjguiSharedOperationIoState): Unit {
        state.retainWorker(spawn {=> acceptClients(server, state)})
        var workerIndex = 0
        while (workerIndex < CJGUI_SHARED_OPERATION_IO_WORKER_COUNT) {
            state.retainWorker(spawn {=> serveQueuedClients(state)})
            workerIndex += 1
        }
    }

    private func acceptClients(server: ServerSocket, state: CjguiSharedOperationIoState): Unit {
        if (!state.tryEnterWorker()) {
            return
        }
        while (state.isRunning()) {
            try {
                let client = server.accept(timeout: Some(Duration.millisecond * CJGUI_SHARED_OPERATION_IO_SLICE_MS))
                if (!state.tryAccept(client)) {
                    let _ = writeFrameWithDeadline(
                        client,
                        CjguiSharedOperationFrame.encode(errorPayload("server_busy")),
                        state
                    )
                    closeClientQuietly(client)
                }
            } catch (_: SocketTimeoutException) {
            } catch (_) {
                if (state.isRunning()) {
                    sleep(Duration.millisecond)
                }
            }
        }
        state.workerExited()
    }

    private func serveQueuedClients(state: CjguiSharedOperationIoState): Unit {
        if (!state.tryEnterWorker()) {
            return
        }
        while (state.isRunning()) {
            if (let Some(accepted) <- state.takeAcceptedClient()) {
                serveQueuedClient(accepted.client, state)
            }
        }
        state.workerExited()
    }

    private func serveQueuedClient(client: StreamingSocket, state: CjguiSharedOperationIoState): Unit {
        if (let Some(clientLeaseId) <- state.activateClient(client)) {
            let read = readClientFrame(client, state)
            if (read.isComplete) {
                let request = CjguiSharedOperationPendingClientRequest(read.payload)
                if (let Some(requestLeaseId) <- state.tryQueueRequest(request)) {
                    if (let Some(observer) <- testReadyRequestObserver) {
                        readyRequestSequence += 1
                        observer.readyRequestQueued(readyRequestSequence, MonoTime.now())
                    }
                    let waitingStarted = MonoTime.now()
                    while (state.isRunning() && request.isWaitingForOwner()) {
                        if ((MonoTime.now() - waitingStarted).toMilliseconds() >=
                            CJGUI_SHARED_OPERATION_READY_WAIT_DEADLINE_MS) {
                            if (request.cancelIfUnclaimed()) {
                                state.expirePendingRequest(requestLeaseId)
                            }
                            break
                        }
                        sleep(Duration.millisecond)
                    }
                    var response: ?String = None
                    while (state.isRunning() && !request.isCancelled()) {
                        if (let Some(nextResponse) <- request.waitForResponse()) {
                            response = Some(nextResponse)
                            break
                        }
                    }
                    if (let Some(payload) <- response) {
                        let _ = writeFrameWithDeadline(client, CjguiSharedOperationFrame.encode(payload), state)
                    } else {
                        // The owner did not claim the request within the bounded
                        // ready wait (or the endpoint stopped): name the outcome
                        // instead of leaving the peer with a bare connection
                        // close. A busy owner is a RETRYABLE condition, and a
                        // named owner_busy frame lets a client tell it apart from
                        // a crashed endpoint.
                        if (state.isRunning()) {
                            let _ = writeFrameWithDeadline(
                                client,
                                CjguiSharedOperationFrame.encode(errorPayload("owner_busy")),
                                state
                            )
                        }
                    }
                    state.finishPendingRequest(requestLeaseId)
                } else {
                    let _ = writeFrameWithDeadline(
                        client,
                        CjguiSharedOperationFrame.encode(errorPayload("server_busy")),
                        state
                    )
                }
            } else if (read.reason.size > 0 && state.isRunning()) {
                let _ = writeFrameWithDeadline(
                    client,
                    CjguiSharedOperationFrame.encode(errorPayload(read.reason)),
                    state
                )
            }
            state.deactivateClient(clientLeaseId)
        }
        closeClientQuietly(client)
    }

    private func readClientFrame(client: StreamingSocket, state: CjguiSharedOperationIoState): CjguiSharedOperationClientRead {
        let decoder = CjguiSharedOperationFrameAccumulator()
        let started = MonoTime.now()
        while (state.isRunning()) {
            let elapsedMs = (MonoTime.now() - started).toMilliseconds()
            let remainingMs = CJGUI_SHARED_OPERATION_READ_DEADLINE_MS - elapsedMs
            if (remainingMs <= 0) {
                return CjguiSharedOperationClientRead(false, "", "request_timeout")
            }
            let buffer = Array<Byte>(4096, repeat: 0)
            client.readTimeout = Some(Duration.millisecond * min(CJGUI_SHARED_OPERATION_IO_SLICE_MS, remainingMs))
            try {
                let read = client.read(buffer)
                if (read <= 0) {
                    return CjguiSharedOperationClientRead(false, "", "")
                }
                let frame = decoder.append(buffer, read)
                if (frame.isMalformed) {
                    return CjguiSharedOperationClientRead(false, "", frame.reason)
                }
                if (frame.isComplete) {
                    return CjguiSharedOperationClientRead(true, frame.payload, "")
                }
            } catch (_: SocketTimeoutException) {
            } catch (_) {
                return CjguiSharedOperationClientRead(false, "", "")
            }
        }
        return CjguiSharedOperationClientRead(false, "", "")
    }

    /// A worker uses the remaining wall-clock budget for each actual write.
    /// Completion means only the kernel accepted the stream bytes; a peer that
    /// closes after a successful domain action is not retried automatically.
    private func writeFrameWithDeadline(
        client: StreamingSocket,
        frame: Array<Byte>,
        state: CjguiSharedOperationIoState
    ): Bool {
        var offset: Int64 = 0
        let chunkSize: Int64 = 16 * 1024
        let started = MonoTime.now()
        while (offset < frame.size && state.isRunning()) {
            let elapsedMs = (MonoTime.now() - started).toMilliseconds()
            let remainingMs = CJGUI_SHARED_OPERATION_WRITE_DEADLINE_MS - elapsedMs
            if (remainingMs <= 0) {
                return false
            }
            let count = min(chunkSize, frame.size - offset)
            client.writeTimeout = Some(Duration.millisecond * min(CJGUI_SHARED_OPERATION_IO_SLICE_MS, remainingMs))
            try {
                client.write(frame.slice(offset, count))
                offset += count
            } catch (_: SocketTimeoutException) {
                // StreamingSocket.write reports no byte count.  A timed-out call
                // therefore cannot prove that this slice transferred zero
                // bytes; retrying the same offset could duplicate a suffix
                // and corrupt the framed stream.  Close this one-shot peer
                // instead of guessing its progress.
                return false
            } catch (_) {
                return false
            }
        }
        return offset == frame.size
    }

    private func dispatchContextRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_CONTEXT")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (command.size != 2 || command[0] != "GET_CONTEXT") {
            return errorPayload("invalid_request")
        }
        if (let Some(targetCount) <- Int64.tryParse(command[1])) {
            if (targetCount < 0 || targetCount > CJGUI_SHARED_OPERATION_MAX_TARGETS || lines.size != 3 + targetCount) {
                return errorPayload("invalid_request")
            }
            let targets = ArrayList<Int64>()
            var index = 3
            while (index < lines.size) {
                let fields = lines[index].split(" ")
                if (fields.size != 2 || fields[0] != "ID") {
                    return errorPayload("invalid_request")
                }
                if (let Some(resourceId) <- Int64.tryParse(fields[1])) {
                    if (!authorization.permitsResource("GET_CONTEXT", resourceId)) {
                        return errorPayload("unauthorized_resource")
                    }
                    if (containsId(targets, resourceId)) {
                        return errorPayload("invalid_request")
                    }
                    targets.add(resourceId)
                } else {
                    return errorPayload("invalid_request")
                }
                index += 1
            }
            if (targetCount == 0 && !authorization.allowsAllResources("GET_CONTEXT")) {
                // No caller target remains a complete compatible context
                // read even when authorization is a finite set.  Filtering is
                // applied by snapshotBody; coercing it into an explicit target
                // would incorrectly select the optional targeted owner path.
                return snapshotPayload(targets, false)
            }
            return snapshotPayload(targets, targetCount > 0)
        }
        return errorPayload("invalid_request")
    }

    private func dispatchChangesRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_CHANGES")) {
            return errorPayload("unauthorized_action")
        }
        if (let None <- changeDomain) {
            return errorPayload("changes_unavailable")
        }
        let command = lines[2].split(" ")
        if ((command.size != 3 && command.size != 4) || command[0] != "GET_CHANGES") {
            return errorPayload("invalid_request")
        }
        if (let Some(sinceVersion) <- Int64.tryParse(command[1])) {
            let expectedStreamIdentity = if (command.size == 4) {
                command[2]
            } else {
                ""
            }
            let targetCountText = if (command.size == 4) {
                command[3]
            } else {
                command[2]
            }
            if (expectedStreamIdentity.size > 128 || (expectedStreamIdentity.size > 0 &&
                !isSafeIdentifier(expectedStreamIdentity))) {
                return errorPayload("invalid_request")
            }
            if (let Some(targetCount) <- Int64.tryParse(targetCountText)) {
                if (sinceVersion < 0 || targetCount < 0 || targetCount > CJGUI_SHARED_OPERATION_MAX_TARGETS ||
                    lines.size != 3 + targetCount) {
                    return errorPayload("invalid_request")
                }
                let targets = ArrayList<Int64>()
                var index = 3
                while (index < lines.size) {
                    let fields = lines[index].split(" ")
                    if (fields.size != 2 || fields[0] != "ID") {
                        return errorPayload("invalid_request")
                    }
                    if (let Some(resourceId) <- Int64.tryParse(fields[1])) {
                        if (!authorization.permitsResource("GET_CHANGES", resourceId)) {
                            return errorPayload("unauthorized_resource")
                        }
                        if (containsId(targets, resourceId)) {
                            return errorPayload("invalid_request")
                        }
                        targets.add(resourceId)
                    } else {
                        return errorPayload("invalid_request")
                    }
                    index += 1
                }
                if (targetCount == 0 && !authorization.allowsAllResources("GET_CHANGES")) {
                    for (resourceId in authorization.allowedResourceIds("GET_CHANGES")) {
                        targets.add(resourceId)
                    }
                }
                if (let Some(provider) <- changeDomain) {
                    return changesPayload(provider.changesSince(sinceVersion, targets, expectedStreamIdentity), targets,
                        targetCount > 0 || !authorization.allowsAllResources("GET_CHANGES"))
                }
            }
        }
        return errorPayload("invalid_request")
    }

    private func dispatchRangeRead(lines: Array<String>): String {
        if (!authorization.permitsAction("READ_RANGE")) {
            return errorPayload("unauthorized_action")
        }
        if (let None <- rangeReadDomain) {
            return errorPayload("range_read_unavailable")
        }
        let command = lines[2].split(" ")
        if (command.size != 5 || command[0] != "READ_RANGE" || lines.size != 3) {
            return errorPayload("invalid_request")
        }
        if (let Some(resourceId) <- Int64.tryParse(command[1])) {
            if (let Some(start) <- Int64.tryParse(command[2])) {
                if (let Some(end) <- Int64.tryParse(command[3])) {
                    if (let Some(expectedVersion) <- Int64.tryParse(command[4])) {
                        if (resourceId < 0 || start < 0 || end < start || expectedVersion < 0 || end - start >
                            CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
                            return errorPayload("invalid_request")
                        }
                        if (!authorization.permitsResource("READ_RANGE", resourceId)) {
                            return errorPayload("unauthorized_resource")
                        }
                        if (let Some(provider) <- rangeReadDomain) {
                            return rangeReadPayload(
                                provider.readRangeFromExternal(resourceId, start, end, expectedVersion),
                                resourceId,
                                start,
                                end
                            )
                        }
                    }
                }
            }
        }
        return errorPayload("invalid_request")
    }

    // -----------------------------------------------------------------------
    // Fixed-snapshot leases (E1). Owner-only: every handler runs on the owner
    // thread, so the lease table is never touched by an I/O worker.
    // -----------------------------------------------------------------------

    /// `SNAPSHOT_ACQUIRE <endpointInstance> <bindGeneration> <requestId>
    ///  <resourceId> <resourceInstanceId|-> <expectedVersion|ANY> <ttlMs>`
    ///
    /// The endpoint instance and bind generation are echoed by the client so a
    /// restarted endpoint cannot hand an old client a lease on a different
    /// object that happens to reuse the resource id.
    private func dispatchSnapshotAcquire(lines: Array<String>): String {
        if (!authorization.permitsAction("SNAPSHOT_ACQUIRE")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (command.size != 8 || command[0] != "SNAPSHOT_ACQUIRE" || lines.size != 3) {
            return errorPayload("invalid_request")
        }
        let expectedEndpoint = command[1]
        // `-` is the "absent" sentinel for BOTH optional fields. Forwarding a literal "-"
        // as the request id made every un-identified acquire share one idempotency key, so a
        // second acquire silently replayed the first lease instead of taking a new snapshot.
        let requestId = if (command[3] == "-") { "" } else { command[3] }
        let resourceInstanceId = if (command[5] == "-") { "" } else { command[5] }
        if (!isSafeOpaqueIdentity(expectedEndpoint, 64) ||
            (requestId != "" && !isSafeOpaqueIdentity(requestId, 64)) ||
            (resourceInstanceId != "" && !isSafeOpaqueIdentity(resourceInstanceId, 64))) {
            return errorPayload("invalid_request")
        }
        if (let Some(bindGeneration) <- Int64.tryParse(command[2])) {
            if (let Some(resourceId) <- Int64.tryParse(command[4])) {
                let expectedVersion = if (command[6] == "ANY") {
                    -1
                } else {
                    match (Int64.tryParse(command[6])) {
                        case Some(parsed) => parsed
                        case None => return errorPayload("invalid_request")
                    }
                }
                if (let Some(ttlMs) <- Int64.tryParse(command[7])) {
                    if (bindGeneration < 0 || resourceId < 0 || expectedVersion < -1 || ttlMs < 0) {
                        return errorPayload("invalid_request")
                    }
                    if (!authorization.permitsResource("SNAPSHOT_ACQUIRE", resourceId)) {
                        return errorPayload("unauthorized_resource")
                    }
                    // Endpoint identity: a lease request addressed to another
                    // endpoint instance is refused before any provider call.
                    if (expectedEndpoint != this.endpointInstanceValue) {
                        return errorPayload("snapshot_endpoint_changed")
                    }
                    if (let Some(table) <- snapshotLeases) {
                        // Owner maintenance: an idle endpoint still expires leases.
                        let _ = table.purgeExpired()
                        if (let Some(provider) <- snapshotProvider) {
                            let outcome = table.acquire(provider, this.endpointInstanceValue,
                                bindGeneration, "grant-${this.authorizationEpoch}",
                                this.authorizationEpoch, "SNAPSHOT_READ", requestId, resourceId,
                                resourceInstanceId, expectedVersion, ttlMs)
                            if (let Some(description) <- outcome.description) {
                                return snapshotLeasePayload(description)
                            }
                            return errorPayload(outcome.refusal)
                        }
                    }
                    return errorPayload("snapshot_unavailable")
                }
            }
        }
        return errorPayload("invalid_request")
    }

    /// `SNAPSHOT_READ <token> <start> <end>`
    private func dispatchSnapshotRead(lines: Array<String>): String {
        if (!authorization.permitsAction("SNAPSHOT_READ")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (command.size != 4 || command[0] != "SNAPSHOT_READ" || lines.size != 3) {
            return errorPayload("invalid_request")
        }
        if (!isSafeOpaqueIdentity(command[1], 256)) {
            return errorPayload("invalid_request")
        }
        if (let Some(start) <- Int64.tryParse(command[2])) {
            if (let Some(end) <- Int64.tryParse(command[3])) {
                if (start < 0 || end < start || end - start > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
                    return errorPayload("invalid_request")
                }
                if (let Some(table) <- snapshotLeases) {
                    // The resource-level authorization for a snapshot read is
                    // checked AFTER the token is resolved, because a snapshot
                    // read names no resource. The lease itself binds the
                    // resource scope that was authorized at acquire time.
                    let read = table.read(command[1], start, end, this.endpointInstanceValue,
                        this.endpointBindGenerationForLeases(), this.authorizationEpoch)
                    if (read.isAvailable) {
                        if (!authorization.permitsResource("SNAPSHOT_READ", read.resourceId)) {
                            return errorPayload("unauthorized_resource")
                        }
                    }
                    return rangeReadPayload(read, read.resourceId, start, end)
                }
                return errorPayload("snapshot_unavailable")
            }
        }
        return errorPayload("invalid_request")
    }

    /// `SNAPSHOT_RELEASE <token>`
    private func dispatchSnapshotRelease(lines: Array<String>): String {
        if (!authorization.permitsAction("SNAPSHOT_RELEASE")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (command.size != 2 || command[0] != "SNAPSHOT_RELEASE" || lines.size != 3) {
            return errorPayload("invalid_request")
        }
        if (!isSafeOpaqueIdentity(command[1], 256)) {
            return errorPayload("invalid_request")
        }
        if (let Some(table) <- snapshotLeases) {
            let reason = table.release(command[1], this.endpointInstanceValue,
                this.endpointBindGenerationForLeases(), this.authorizationEpoch)
            if (reason == "snapshot_unknown" || reason == "snapshot_endpoint_changed") {
                return errorPayload(reason)
            }
            return snapshotReleasePayload(command[1], reason)
        }
        return errorPayload("snapshot_unavailable")
    }

    /// Bind generation as the lease table must compare it. The connection's
    /// generation is bumped on every successful bind; leases record the value
    /// of the bind they were taken under.
    private func endpointBindGenerationForLeases(): Int64 {
        return this.endpointGeneration
    }

    private func snapshotLeasePayload(
        description: CjguiSharedOperationSnapshotLeaseDescription): String {
        if (!isBoundedPayload("") || description.token.size > 256 ||
            !isSafeLeaseReason(description.resourceInstanceId)) {
            return errorPayload("invalid_range")
        }
        let builder = CjguiSharedOperationBoundedTextBuilder()
        builder.append("PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\n")
        builder.append("KIND SNAPSHOT_LEASE\n")
        builder.append("TOKEN ${description.token}\n")
        builder.append("ENDPOINT_INSTANCE ${description.endpointInstance}\n")
        builder.append("ENDPOINT_BIND_GENERATION ${description.bindGeneration}\n")
        builder.append("RESOURCE ${description.resourceId}\n")
        builder.append("RESOURCE_INSTANCE ${description.resourceInstanceId}\n")
        builder.append("VERSION ${description.version}\n")
        builder.append("BYTE_LENGTH ${description.byteLength}\n")
        builder.append("TTL_MS ${description.grantedTtlMs}\n")
        builder.append("REMAINING_MS ${description.remainingTtlMs}\n")
        builder.append("MAX_READ_BYTES ${description.maxReadBytes}\n")
        builder.append("RESERVED_RESIDENT_BYTES ${description.reservedResidentBytes}\n")
        builder.append("RESERVED_BACKING_BYTES ${description.reservedBackingBytes}\n")
        builder.append("END")
        return builder.toString()
    }

    private func snapshotReleasePayload(token: String, reason: String): String {
        let builder = CjguiSharedOperationBoundedTextBuilder()
        builder.append("PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\n")
        builder.append("KIND SNAPSHOT_RELEASE\n")
        builder.append("TOKEN ${token}\n")
        builder.append("REASON ${reason}\n")
        builder.append("END")
        return builder.toString()
    }

    private func dispatchWindowProgressRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_PROGRESS")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_WINDOW_PROGRESS") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- windowProgressProvider) {
            return windowProgressPayload(provider.windowProgress())
        }
        return errorPayload("window_progress_unavailable")
    }

    private func positionMotionFactPayload(fact: CjguiSharedOperationPositionMotionFact): String {
        if (fact.nodeId < 0 || !isSafeOpaqueIdentity(fact.sessionIdentity, 64) ||
            !sharedOperationSafeOpaqueToken(fact.casToken) ||
            !isSafeIdentifier(fact.requestedMode) || !isSafeWindowDiagnostic(fact.lastFailure) ||
            fact.acceptedSceneVersion <= 0 ||
            !sharedOperationPositionFinite(fact.requestedX) || !sharedOperationPositionFinite(fact.requestedY) ||
            !sharedOperationPositionFinite(fact.presentedX) || !sharedOperationPositionFinite(fact.presentedY) ||
            !sharedOperationPositionFinite(fact.declaredX) || !sharedOperationPositionFinite(fact.declaredY)) {
            return errorPayload("position_motion_fact_invalid")
        }
        return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND NODE_TRANSLATION\n" +
            "NODE_ID ${fact.nodeId}\nRESOURCE_ID ${fact.resourceId}\nSESSION ${fact.sessionIdentity}\n" +
            "CAS ${fact.casToken}\nREQUEST_REVISION ${fact.requestRevision}\n" +
            "ACCEPTED_REQUEST_REVISION ${fact.acceptedRequestRevision}\n" +
            "REQUESTED_MODE ${fact.requestedMode}\nREQUESTED ${fact.requestedX} ${fact.requestedY}\n" +
            "PRESENTED ${fact.presentedX} ${fact.presentedY}\n" +
            "DECLARED ${fact.declaredX} ${fact.declaredY}\n" +
            "SCENE ${fact.acceptedSceneVersion}\nFRAME ${fact.submittedFrameIndex}\n" +
            "ACTIVE ${if (fact.active) { 1 } else { 0 }}\n" +
            "PENDING ${if (fact.pending) { 1 } else { 0 }}\n" +
            "FAILURE ${fact.lastFailure}\nEND"
    }

    private func positionMotionDecisionPayload(result: CjguiSharedOperationPositionMotionDecision): String {
        if (!isSafeWindowDiagnostic(result.reason)) { return errorPayload("position_motion_decision_invalid") }
        let factLines = match (result.fact) {
            case Some(fact) =>
                "NODE_ID ${fact.nodeId}\nREQUEST_REVISION ${fact.requestRevision}\n" +
                "ACCEPTED_REQUEST_REVISION ${fact.acceptedRequestRevision}\n" +
                "SCENE ${fact.acceptedSceneVersion}\nFRAME ${fact.submittedFrameIndex}\n" +
                "CAS ${fact.casToken}\nPENDING ${if (fact.pending) { 1 } else { 0 }}\n"
            case None => ""
        }
        return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND NODE_TRANSLATION_DECISION\n" +
            "ADMITTED ${if (result.admitted) { 1 } else { 0 }}\nREASON ${result.reason}\n${factLines}END"
    }

    private func dispatchPositionMotionRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_NODE_TRANSLATION")) { return errorPayload("unauthorized_action") }
        if (lines.size != 3) { return errorPayload("invalid_request") }
        let command = lines[2].split(" ")
        if (let Some(provider) <- positionMotionProvider) {
            if (command.size == 2 && command[1] == "LIST") {
                let targets = provider.positionMotionTargets()
                if (targets.size > 32) { return errorPayload("position_motion_capacity") }
                let builder = CjguiSharedOperationBoundedTextBuilder()
                if (!builder.append("PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND NODE_TRANSLATION_TARGETS\n")) {
                    return errorPayload("response_too_large")
                }
                var visible = 0
                for (nodeId in targets) {
                    if (let Some(fact) <- provider.positionMotionRead(nodeId)) {
                        if (fact.resourceId < 0 || authorization.permitsResource("GET_NODE_TRANSLATION", fact.resourceId)) {
                            if (!builder.append("TARGET ${fact.nodeId} ${fact.resourceId}\n")) {
                                return errorPayload("response_too_large")
                            }
                            visible += 1
                        }
                    }
                }
                if (!builder.append("COUNT ${visible}\nEND")) { return errorPayload("response_too_large") }
                return builder.toString()
            }
            if (command.size == 3 && command[1] == "READ" && isSafeInteger(command[2])) {
                if (let Some(nodeId) <- Int64.tryParse(command[2])) {
                    if (let Some(fact) <- provider.positionMotionRead(nodeId)) {
                        if (fact.resourceId >= 0 &&
                            !authorization.permitsResource("GET_NODE_TRANSLATION", fact.resourceId)) {
                            return errorPayload("unauthorized_resource")
                        }
                        return positionMotionFactPayload(fact)
                    }
                    return errorPayload("position_target_unavailable")
                }
            }
            return errorPayload("invalid_request")
        }
        return errorPayload("position_motion_unavailable")
    }

    private func dispatchPositionMotionSet(lines: Array<String>): String {
        if (!authorization.permitsAction("SET_NODE_TRANSLATION")) { return errorPayload("unauthorized_action") }
        if (lines.size != 3) { return errorPayload("invalid_request") }
        let command = lines[2].split(" ")
        if (command.size != 6 || !isSafeInteger(command[1]) ||
            !sharedOperationSafeOpaqueToken(command[2]) || !sharedOperationSafeMotionReference(command[5])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- positionMotionProvider) {
            if (let Some(nodeId) <- Int64.tryParse(command[1])) {
                if (let Some(x) <- Float64.tryParse(command[3])) {
                    if (let Some(y) <- Float64.tryParse(command[4])) {
                        if (let Some(fact) <- provider.positionMotionRead(nodeId)) {
                            if (fact.resourceId >= 0 &&
                                !authorization.permitsResource("SET_NODE_TRANSLATION", fact.resourceId)) {
                                return errorPayload("unauthorized_resource")
                            }
                            return positionMotionDecisionPayload(provider.positionMotionSet(nodeId,
                                command[2], x, y, command[5]))
                        }
                        return errorPayload("position_target_unavailable")
                    }
                }
            }
        } else { return errorPayload("position_motion_unavailable") }
        return errorPayload("invalid_request")
    }

    private func dispatchPositionMotionClear(lines: Array<String>): String {
        if (!authorization.permitsAction("CLEAR_NODE_TRANSLATION")) { return errorPayload("unauthorized_action") }
        if (lines.size != 3) { return errorPayload("invalid_request") }
        let command = lines[2].split(" ")
        if (command.size != 3 || !isSafeInteger(command[1]) || !sharedOperationSafeOpaqueToken(command[2])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- positionMotionProvider) {
            if (let Some(nodeId) <- Int64.tryParse(command[1])) {
                if (let Some(fact) <- provider.positionMotionRead(nodeId)) {
                    if (fact.resourceId >= 0 &&
                        !authorization.permitsResource("CLEAR_NODE_TRANSLATION", fact.resourceId)) {
                        return errorPayload("unauthorized_resource")
                    }
                    return positionMotionDecisionPayload(provider.positionMotionClear(nodeId, command[2]))
                }
                return errorPayload("position_target_unavailable")
            }
        } else { return errorPayload("position_motion_unavailable") }
        return errorPayload("invalid_request")
    }

    private func dispatchWindowProgressTargetRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_PROGRESS")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (lines.size != 3 || command.size != 2 || command[0] != "GET_WINDOW_PROGRESS" || !isSafeIdentifier(command[1])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- windowProgressTargetProvider) {
            if (let Some(progress) <- provider.windowProgressForTarget(command[1])) {
                return windowProgressPayload(progress, windowTarget: command[1])
            }
            return errorPayload("unknown_window_target")
        }
        return errorPayload("window_progress_target_unavailable")
    }

    private func dispatchTransferReceiptRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_PROGRESS")) { return errorPayload("unauthorized_action") }
        let fields = lines[2].split(" ")
        if (lines.size != 3 || fields.size != 3 || !isSafeIdentifier(fields[1])) {
            return errorPayload("invalid_request")
        }
        if (let Some(eventId) <- UInt64.tryParse(fields[2])) {
            if (eventId == 0u64) { return errorPayload("invalid_request") }
            if (let Some(provider) <- transferReceiptProvider) {
                return transferReceiptPayload(provider.transferReceiptPage(fields[1], eventId), false)
            }
            return errorPayload("transfer_receipt_unavailable")
        }
        return errorPayload("invalid_request")
    }

    private func dispatchTransferReceiptChangesRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_PROGRESS")) { return errorPayload("unauthorized_action") }
        let fields = lines[2].split(" ")
        if (lines.size != 3 || fields.size != 4 || !isSafeIdentifier(fields[1])) {
            return errorPayload("invalid_request")
        }
        if (let Some(cursor) <- Int64.tryParse(fields[2])) {
            if (let Some(limit) <- Int64.tryParse(fields[3])) {
                if (cursor < 0 || limit < 1 || limit > 64) { return errorPayload("invalid_request") }
                if (let Some(provider) <- transferReceiptProvider) {
                    return transferReceiptPayload(provider.transferReceiptChangesPage(fields[1], cursor, limit), true)
                }
                return errorPayload("transfer_receipt_unavailable")
            }
        }
        return errorPayload("invalid_request")
    }

    private func transferReceiptPayload(page: CjguiSharedOperationTransferReceiptPage,
        changes: Bool): String {
        if (page.revision < 0 || page.retentionFloor < 0 || page.receipts.size > 64 ||
            (page.lookupState != "found" && page.lookupState != "expired" &&
             page.lookupState != "unknown" && page.lookupState != "changes")) {
            return errorPayload("invalid_transfer_receipt")
        }
        let kind = if (changes) { "TRANSFER_RECEIPT_CHANGES" } else { "TRANSFER_RECEIPT" }
        var payload = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND ${kind}\n" +
            "LOOKUP ${page.lookupState}\nREVISION ${page.revision}\n" +
            "RETENTION_FLOOR ${page.retentionFloor}\nRESYNC ${page.resyncRequired}\n" +
            "COUNT ${page.receipts.size}\n"
        for (receipt in page.receipts) {
            if (receipt.eventId == 0u64 || receipt.revision < 0 || receipt.semanticId.size > 256 ||
                receipt.sourceKind.size > 128 || receipt.reason.size > 128 ||
                receipt.contentDigest.size > 128 || !isSafeIdentifier(receipt.sessionIdentity)) {
                return errorPayload("invalid_transfer_receipt")
            }
            payload = "${payload}RECEIPT ${receipt.sessionIdentity} ${receipt.eventId} " +
                "${receipt.eventKind} ${receipt.nodeId} ${receipt.bindingEpoch} " +
                "${receipt.expectedOwnerVersion} ${receipt.ownerAttempted} " +
                "${receipt.ownerVersionBefore} ${receipt.ownerVersionAfter} " +
                "${receipt.acceptedSceneVersion} ${receipt.submittedFrameIndex} ${receipt.revision} " +
                "${encodeUtf8HexValue(receipt.semanticId)} ${encodeUtf8HexValue(receipt.sourceKind)} " +
                "${encodeUtf8HexValue(receipt.format)} ${encodeUtf8HexValue(receipt.contentDigest)} " +
                "${encodeUtf8HexValue(receipt.state)} ${encodeUtf8HexValue(receipt.reason)}\n"
        }
        payload = "${payload}END"
        return if (isBoundedPayload(payload)) { payload } else { errorPayload("response_too_large") }
    }

    private func dispatchTreeSelectionRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_TREE_SELECTION")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_TREE_SELECTION") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- treeSelectionProvider) {
            let payload = provider.selectionPayload()
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("selection_payload_too_large")
            }
            return generatedUiPayload("TREE_SELECTION", payload)
        }
        return errorPayload("tree_selection_unavailable")
    }

    private func dispatchTreeSelectionUpdate(lines: Array<String>): String {
        if (!authorization.permitsAction("UPDATE_TREE_SELECTION")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3) {
            return errorPayload("invalid_request")
        }
        let fields = lines[2].split(" ")
        if (fields.size != 4 || fields[0] != "UPDATE_TREE_SELECTION" || !isSafeInteger(fields[1]) ||
            !isSafeIdentifier(fields[2])) {
            return errorPayload("invalid_request")
        }
        let key = if (fields[3] == "-") { "" } else { fields[3] }
        // Stable selection keys may contain '-' (for example "record-12");
        // they are still bounded to the protocol-safe character set.
        if (key.size > 0 && !isSafeSelectionKey(key)) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- treeSelectionProvider) {
            let result = provider.applySelection(fields[2], key, parseInt64OrZero(fields[1]))
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND TREE_SELECTION_UPDATE\n" +
                "APPLIED ${result.applied}\nREASON ${if (result.reason.size > 0) { result.reason } else { "none" }}\n" +
                "SELECTION_VERSION ${result.selectionVersion}\nEND")) {
                return errorPayload("response_too_large")
            }
            if (result.applied) {
                synchronized(transportLock) {
                    windowRefreshRequested = true
                }
            }
            return body.toString()
        }
        return errorPayload("tree_selection_unavailable")
    }

    private func dispatchGeneratedUiCapabilities(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_GENERATED_UI_CAPABILITIES") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.capabilitiesPayload()
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            return generatedUiPayload("GENERATED_UI_CAPABILITIES", payload)
        }
        return errorPayload("generated_ui_unavailable")
    }

    private func dispatchGeneratedUiFields(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_GENERATED_UI_FIELDS") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.fieldsPayload()
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            return generatedUiPayload("GENERATED_UI_FIELDS", payload)
        }
        return errorPayload("generated_ui_unavailable")
    }

    /// Accepted generated instances, addressed by declared key. The provider
    /// supplies the `INSTANCE ...` lines; this handler adds the same version /
    /// candidate / scene context as the structure read, so a client can tell
    /// which generation the identities belong to.
    private func dispatchGeneratedUiInstances(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_GENERATED_UI_INSTANCES") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.acceptedInstancesPayload()
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND GENERATED_UI_INSTANCES\n" +
                "STRUCTURE_VERSION ${provider.acceptedStructureVersion()}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append("CANDIDATE_VERSION ${provider.candidateStructureVersion()}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append(
                "SCENE_STATE ${if (provider.sceneState().size > 0) { provider.sceneState() } else { "none" }}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append("INSTANCE_LENGTH ${payload.size}\n")) {
                return errorPayload("response_too_large")
            }
            // An empty projection is a legitimate answer (no window attached or
            // nothing accepted yet); it must not leave a blank line, which the
            // line protocol rejects.
            if (payload.size > 0) {
                if (!body.append(payload)) {
                    return errorPayload("response_too_large")
                }
                if (!body.append("\nEND")) {
                    return errorPayload("response_too_large")
                }
            } else {
                if (!body.append("END")) {
                    return errorPayload("response_too_large")
                }
            }
            return body.toString()
        }
        return errorPayload("generated_ui_unavailable")
    }

    /// Compact terminal read for ONE submission attempt. It answers with the
    /// attempt's own state only: a token outside the bounded table is reported
    /// as UNKNOWN, never as another attempt's rejection.
    private func dispatchGeneratedUiCandidate(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        let header = lines[2].split(" ")
        // COMMAND <token> [<instance> <bind_generation>]
        if (lines.size != 3 || (header.size != 2 && header.size != 4) ||
            header[0] != "GET_GENERATED_UI_CANDIDATE" || !isSafeInteger(header[1])) {
            return errorPayload("invalid_request")
        }
        if (header.size == 4) {
            // The caller names the endpoint instance its ticket belongs to. A
            // different instance is answered BEFORE the holder table is read, so
            // a restarted endpoint can never satisfy an old ticket with a
            // coincidentally equal token.
            if (header[2] != endpointInstanceValue || !isSafeInteger(header[3]) ||
                parseInt64OrZero(header[3]) != endpointGeneration) {
                return errorPayload("endpoint_replaced")
            }
        }
        if (let Some(provider) <- generatedUiProvider) {
            let token = parseInt64OrZero(header[1])
            let payload = provider.candidateTicketPayload(token)
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND GENERATED_UI_CANDIDATE\n" +
                "ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n")) {
                return errorPayload("response_too_large")
            }
            if (payload.size > 0) {
                if (!body.append(payload)) {
                    return errorPayload("response_too_large")
                }
            } else {
                // A provider without an attempt table cannot attribute the
                // token; say so instead of inventing a terminal state.
                if (!body.append("CANDIDATE_TOKEN ${token}\nTERMINAL_STATE UNKNOWN")) {
                    return errorPayload("response_too_large")
                }
            }
            if (!body.append("\nEND")) {
                return errorPayload("response_too_large")
            }
            return body.toString()
        }
        return errorPayload("generated_ui_unavailable")
    }

    /// ONE atomic snapshot from the provider, with the endpoint epoch attached
    /// so a reader can tell which endpoint the stream identity belongs to.
    private func dispatchGeneratedUiSnapshot(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_GENERATED_UI_SNAPSHOT") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.snapshotPayload()
            if (payload.size <= 0) {
                return errorPayload("generated_ui_unavailable")
            }
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            return generatedUiPayload("GENERATED_UI_SNAPSHOT",
                "ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n${payload}")
        }
        return errorPayload("generated_ui_unavailable")
    }

    /// Bounded change read. A provider without the observation seam is
    /// unavailable, not "no changes": those are different facts.
    private func dispatchGeneratedUiChanges(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        let header = lines[2].split(" ")
        // COMMAND <stream_epoch> <cursor>
        if (lines.size != 3 || header.size != 3 || header[0] != "GET_GENERATED_UI_CHANGES" ||
            !isSafeInteger(header[1]) || !isSafeInteger(header[2])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.changesPayload(parseInt64OrZero(header[1]),
                parseInt64OrZero(header[2]))
            if (payload.size <= 0) {
                return errorPayload("generated_ui_unavailable")
            }
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            return generatedUiPayload("GENERATED_UI_CHANGES",
                "ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n${payload}")
        }
        return errorPayload("generated_ui_unavailable")
    }

    /// ONE guarded snapshot section. The provider decides whether the cursor
    /// still matches; the transport only carries the answer.
    private func dispatchGeneratedUiSection(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        let header = lines[2].split(" ")
        // COMMAND <section> <expected_cursor>
        if (lines.size != 3 || header.size != 3 || header[0] != "GET_GENERATED_UI_SECTION" ||
            !isSafeInteger(header[2])) {
            return errorPayload("invalid_request")
        }
        let section = header[1]
        // STYLES is a section of its own: a client that observed a style
        // definition change re-reads the directory without pulling a tree.
        if (section != "FIELDS" && section != "STRUCTURE" && section != "INSTANCES" &&
            section != "STYLES" && section != "EFFECTS" && section != "PLATFORM") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.sectionPayload(section, parseInt64OrZero(header[2]))
            if (payload.size <= 0) {
                return errorPayload("generated_ui_unavailable")
            }
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            return generatedUiPayload("GENERATED_UI_SECTION",
                "ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n${payload}")
        }
        return errorPayload("generated_ui_unavailable")
    }

    private func dispatchGeneratedUiStructure(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_GENERATED_UI_STRUCTURE") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            let payload = provider.acceptedStructurePayload()
            if (payload.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND GENERATED_UI_STRUCTURE\n" +
                "STRUCTURE_VERSION ${provider.acceptedStructureVersion()}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append("CANDIDATE_VERSION ${provider.candidateStructureVersion()}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append(
                "SCENE_STATE ${if (provider.sceneState().size > 0) { provider.sceneState() } else { "none" }}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append("STRUCTURE_LENGTH ${payload.size}\n")) {
                return errorPayload("response_too_large")
            }
            if (!body.append(payload)) {
                return errorPayload("response_too_large")
            }
            if (!body.append("\nEND")) {
                return errorPayload("response_too_large")
            }
            return body.toString()
        }
        return errorPayload("generated_ui_unavailable")
    }

    private func dispatchGeneratedUiSubmit(lines: Array<String>): String {
        if (!authorization.permitsAction("SUBMIT_GENERATED_UI")) {
            return errorPayload("unauthorized_action")
        }
        let header = lines[2].split(" ")
        if (lines.size < 4 || header.size != 2 || header[0] != "SUBMIT_GENERATED_UI" ||
            !isSafeInteger(header[1])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- generatedUiProvider) {
            // Everything after the header line is the candidate payload.
            let builder = StringBuilder()
            var index: Int64 = 3
            while (index < lines.size) {
                if (index > 3) { builder.append("\n") }
                builder.append(lines[index])
                index += 1
            }
            let candidate = builder.toString()
            if (candidate.size <= 0 || candidate.size > CJGUI_SHARED_OPERATION_MAX_GENERATED_UI_BYTES) {
                return errorPayload("generated_ui_payload_too_large")
            }
            let result = provider.submitStructure(candidate, parseInt64OrZero(header[1]))
            if (result.accepted) {
                // An accepted structure is an external mutation of this
                // window's declarations: request the same bounded refresh the
                // business-action path uses.
                synchronized(transportLock) {
                    windowRefreshRequested = true
                }
            }
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND GENERATED_UI_SUBMIT\n" +
                "APPLIED ${result.accepted}\nREASON ${if (result.reason.size > 0) { result.reason } else { "none" }}\n" +
                "PATH ${if (result.path.size > 0) { result.path } else { "none" }}\n" +
                "VERSION_BEFORE ${result.versionBefore}\nVERSION_AFTER ${result.versionAfter}\n" +
                // Candidate receipt and scene acceptance are reported
                // separately: VERSION_AFTER stays the scene-accepted version,
                // so a client cannot read a received candidate as an accepted
                // interface.
                "CANDIDATE_ACCEPTED ${result.candidateAccepted}\n" +
                "SCENE_ACCEPTED ${result.sceneAccepted}\n" +
                "CANDIDATE_VERSION ${result.candidateVersion}\n" +
                // The attempt token and the endpoint it belongs to travel with
                // the reply: they are the caller's ONLY way to ask later what
                // happened to this exact submission.
                "ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n" +
                "CANDIDATE_TOKEN ${result.candidateToken}\n" +
                "RECEIPT ${if (result.receipt.size > 0) { result.receipt } else { "none" }}\nEND")) {
                return errorPayload("response_too_large")
            }
            return body.toString()
        }
        return errorPayload("generated_ui_unavailable")
    }

    private func generatedUiPayload(kind: String, payload: String): String {
        let body = CjguiSharedOperationBoundedTextBuilder()
        if (!body.append(
            "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND ${kind}\n" +
            "PAYLOAD_LENGTH ${payload.size}\n")) {
            return errorPayload("response_too_large")
        }
        if (!body.append(payload)) {
            return errorPayload("response_too_large")
        }
        if (!body.append("\nEND")) {
            return errorPayload("response_too_large")
        }
        return body.toString()
    }

    private func dispatchWindowProjectionTargetsRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_TARGETS")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_WINDOW_TARGETS") {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- windowProjectionTargetProvider) {
            let targets = provider.windowProjectionTargets()
            if (targets.size > CJGUI_SHARED_OPERATION_MAX_TARGETS) {
                return errorPayload("invalid_window_target")
            }
            let body = CjguiSharedOperationBoundedTextBuilder()
            if (!body.append(
                "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND WINDOW_TARGETS\nWINDOW_TARGETS ${targets.size}\n")) {
                return errorPayload("response_too_large")
            }
            let seen = ArrayList<String>()
            for (target in targets) {
                if (!isSafeIdentifier(target) || containsString(seen, target)) {
                    return errorPayload("invalid_window_target")
                }
                seen.add(target)
                if (!body.append("WINDOW_TARGET ${target}\n")) {
                    return errorPayload("response_too_large")
                }
            }
            if (!body.append("END")) {
                return errorPayload("response_too_large")
            }
            return body.toString()
        }
        return errorPayload("window_target_unavailable")
    }

    private func dispatchWindowProjectionContextRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_CONTEXT")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (lines.size != 3 || command.size != 2 || command[0] != "GET_WINDOW_CONTEXT" || !isSafeIdentifier(command[1])) {
            return errorPayload("invalid_request")
        }
        if (let Some(provider) <- windowProjectionTargetProvider) {
            if (let Some(projection) <- provider.windowProjectionForTarget(command[1])) {
                if (!projection.isActive) {
                    return errorPayload("unknown_window_target")
                }
                let body = snapshotBody(domain.contextSnapshot(), ArrayList<Int64>(), false, projection,
                    windowTarget: command[1])
                if (!body.isAvailable) {
                    return errorPayload(body.failureReason)
                }
                return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND SNAPSHOT\n${body.body}END"
            }
            return errorPayload("unknown_window_target")
        }
        return errorPayload("window_target_unavailable")
    }

    private func dispatchWindowInteractionRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_INTERACTION")) {
            return errorPayload("unauthorized_action")
        }
        if (lines.size != 3 || lines[2] != "GET_WINDOW_INTERACTION") {
            return errorPayload("invalid_request")
        }
        // Focus, selection and layer names are global window facts. A narrow
        // resource grant cannot prove that every current fact belongs to that
        // resource, so it emits no interaction projection at all.
        if (!authorization.allowsAllResources("GET_WINDOW_INTERACTION")) {
            return errorPayload("unauthorized_resource")
        }
        if (let Some(provider) <- windowProgressProvider) {
            return windowInteractionPayload(provider.windowProgress())
        }
        return errorPayload("window_interaction_unavailable")
    }

    private func dispatchWindowInteractionTargetRead(lines: Array<String>): String {
        if (!authorization.permitsAction("GET_WINDOW_INTERACTION")) {
            return errorPayload("unauthorized_action")
        }
        let command = lines[2].split(" ")
        if (lines.size != 3 || command.size != 2 || command[0] != "GET_WINDOW_INTERACTION" ||
            !isSafeIdentifier(command[1])) {
            return errorPayload("invalid_request")
        }
        // Focus, selection and layer names remain global window facts. Target
        // identity does not make a narrow domain resource grant sufficient.
        if (!authorization.allowsAllResources("GET_WINDOW_INTERACTION")) {
            return errorPayload("unauthorized_resource")
        }
        if (let Some(provider) <- windowProgressTargetProvider) {
            if (let Some(progress) <- provider.windowProgressForTarget(command[1])) {
                return windowInteractionPayload(progress, windowTarget: command[1])
            }
            return errorPayload("unknown_window_target")
        }
        return errorPayload("window_interaction_target_unavailable")
    }

    private func dispatchInvocation(lines: Array<String>): String {
        let command = lines[2].split(" ")
        if (command.size != 5 || command[0] != "INVOKE") {
            return errorPayload("invalid_request")
        }
        if (let Some(expectedVersion) <- Int64.tryParse(command[1])) {
            let actionName = command[2]
            if (!authorization.permitsAction(actionName)) {
                return errorPayload("unauthorized_action")
            }
            if (let Some(targetCount) <- Int64.tryParse(command[3])) {
                if (let Some(argumentCount) <- Int64.tryParse(command[4])) {
                    let descriptor = findAction(actionName)
                    if (let Some(action) <- descriptor) {
                        if (targetCount < action.minimumTargetCount || targetCount > action.maximumTargetCount ||
                            targetCount > CJGUI_SHARED_OPERATION_MAX_TARGETS || argumentCount < 0 || argumentCount > action
                            .parameters
                            .size || lines.size != 3 + targetCount + argumentCount) {
                            return errorPayload("invalid_parameters")
                        }
                        let targets = ArrayList<Int64>()
                        var index = 3
                        while (index < 3 + targetCount) {
                            let fields = lines[index].split(" ")
                            if (fields.size != 2 || fields[0] != "ID") {
                                return errorPayload("invalid_request")
                            }
                            if (let Some(resourceId) <- Int64.tryParse(fields[1])) {
                                if (!authorization.permitsResource(actionName, resourceId)) {
                                    return errorPayload("unauthorized_resource")
                                }
                                if (containsId(targets, resourceId)) {
                                    return errorPayload("invalid_parameters")
                                }
                                targets.add(resourceId)
                            } else {
                                return errorPayload("invalid_request")
                            }
                            index += 1
                        }
                        let arguments = ArrayList<CjguiSharedOperationActionArgument>()
                        while (index < lines.size) {
                            if (let Some(argument) <- parseArgument(lines[index])) {
                                if (containsArgument(arguments, argument.name)) {
                                    return errorPayload("invalid_parameters")
                                }
                                arguments.add(argument)
                            } else {
                                return errorPayload("invalid_parameters")
                            }
                            index += 1
                        }
                        if (!matchesDeclaredParameters(action, arguments)) {
                            return errorPayload("invalid_parameters")
                        }
                        let result = domain.executeFromExternal(
                            CjguiSharedOperationActionInvocation(actionName, expectedVersion, targets, arguments))
                        if (result.applied) {
                            synchronized(transportLock) {
                                windowRefreshRequested = true
                            }
                        }
                        return resultPayload(result)
                    }
                    return errorPayload("unauthorized_action")
                }
            }
        }
        return errorPayload("invalid_request")
    }

    private func snapshotPayload(targets: ArrayList<Int64>, hasExplicitTargets: Bool): String {
        let snapshot = if (hasExplicitTargets) {
            if (let Some(provider) <- targetedContextDomain) {
                if (let Some(targeted) <- provider.contextSnapshotForExternalTargets(targets)) {
                    targeted
                } else {
                    return errorPayload("unknown_resource")
                }
            } else {
                domain.contextSnapshot()
            }
        } else {
            domain.contextSnapshot()
        }
        if (hasExplicitTargets) {
            for (target in targets) {
                if (!snapshotContainsResource(snapshot, target)) {
                    return errorPayload("unknown_resource")
                }
            }
        }
        let projection = if (let Some(provider) <- windowProjectionProvider) {
            provider.windowProjection()
        } else {
            CjguiSharedOperationWindowProjection.inactive()
        }
        let body = snapshotBody(snapshot, targets, hasExplicitTargets, projection)
        if (!body.isAvailable) {
            return errorPayload(body.failureReason)
        }
        return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND SNAPSHOT\n${body.body}END"
    }

    private func windowProgressPayload(
        progress: CjguiSharedOperationWindowProgress,
        windowTarget!: String = ""
    ): String {
        if (windowTarget.size > 0 && !isSafeIdentifier(windowTarget)) {
            return errorPayload("invalid_window_target")
        }
        let targetLine = if (windowTarget.size > 0) {
            "WINDOW_TARGET ${windowTarget}\n"
        } else {
            ""
        }
        if (!progress.isActive) {
            return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND WINDOW_PROGRESS\n${targetLine}WINDOW_PROJECTION NONE\nEND"
        }
        if (progress.sceneVersion <= 0 || progress.nativeSubmissionVersion < -1 || progress.acceptedSceneVersion < 0 ||
            progress.submittedSceneVersion < -1 || progress.submittedFrameIndex < -1 ||
            progress.observedMetalCompletionFrameIndex < -1 || progress.observedMetalFailureFrameIndex < -1 ||
            progress.observedMetalGpuDurationMicros < -1 || progress.overlayDrawnSceneVersion < -1 ||
            (progress.geometry.state != "available" && progress.geometry.state != "unavailable") ||
            progress.geometry.pointUnit != "window_point" ||
            progress.geometry.currentWidthPoints < 0.0 || progress.geometry.currentHeightPoints < 0.0 ||
            (progress.geometry.state == "available" && progress.geometry.currentBackingScale <= 0.0) ||
            progress.geometry.currentDrawableWidthPixels < 0 ||
            progress.geometry.currentDrawableHeightPixels < 0 ||
            (progress.geometry.state == "available" && progress.geometry.currentRevision < 0) ||
            (progress.geometry.submittedState != "none" && progress.geometry.submittedState != "committed") ||
            (progress.geometry.submittedState == "committed" &&
                (progress.geometry.submittedBackingScale <= 0.0 ||
                 progress.geometry.submittedSceneVersion < 0 || progress.geometry.submittedFrameIndex < 0)) ||
            !isSafeIdentifier(progress.presentationState) || !isSafeIdentifier(progress.sessionIdentity) ||
            !isSafeWindowDiagnostic(progress.pendingRefreshReason) ||
            !isSafeWindowDiagnostic(progress.lastNativeFailure) ||
            progress.effectRequestedRadiusPoints < 0 || progress.effectRequestedRadiusPoints > 16 ||
            progress.effectSubmittedSceneVersion < -1 || progress.effectSubmittedFrameIndex < -1 ||
            progress.effectSubmittedRadiusPoints < 0 || progress.effectSubmittedRadiusPoints > 16 ||
            !isSafeIdentifier(progress.effectIdentity) || !isSafeIdentifier(progress.effectSubmittedMode) ||
            !isSafeIdentifier(progress.effectFallbackReason) || !isSafeIdentifier(progress.effectCompletion) ||
            !isSafeIdentifier(progress.windowBackgroundIdentity) ||
            !isSafeIdentifier(progress.windowBackgroundRequested) ||
            !isSafeIdentifier(progress.windowBackgroundBackend) ||
            !isSafeIdentifier(progress.windowBackgroundActual) ||
            !isSafeIdentifier(progress.windowBackgroundFallbackReason) ||
            progress.windowBackgroundAcceptedSceneVersion < -1 || progress.windowBackgroundFrameIndex < -1 ||
            progress.windowBackgroundRequestRevision < 0 || progress.windowBackgroundEnvironmentRevision < 0 ||
            progress.windowBackgroundObservationRevision < 0 ||
            !isSafeIdentifier(progress.windowBackgroundCompletion) ||
            progress.windowBackgroundVisualResult != "unobserved" ||
            (progress.workload.status != "disabled" && progress.workload.status != "enabled" &&
                progress.workload.status != "native_unavailable") ||
            (progress.workload.lastAttemptResult != "none" &&
                progress.workload.lastAttemptResult != "accepted" &&
                progress.workload.lastAttemptResult != "rejected") ||
            progress.workload.sceneVersion < -1 || progress.workload.nodeWrites < -1 ||
            progress.workload.nodeClones < -1 || progress.workload.nodeAllocations < -1 ||
            progress.workload.textLayoutPreparations < -1 || progress.workload.imageDecodeStarts < -1 ||
            progress.workload.reusableResourceBytes < -1 || progress.workload.lastAttemptNodeWrites < -1 ||
            progress.workload.lastAttemptNodeClones < -1 || progress.workload.lastAttemptNodeAllocations < -1 ||
            progress.workload.lastAttemptTextLayoutPreparations < -1 ||
            progress.workload.lastAttemptImageDecodeStarts < -1 ||
            (progress.windowBackgroundColorScheme != "light" &&
                progress.windowBackgroundColorScheme != "dark" &&
                progress.windowBackgroundColorScheme != "unavailable")) {
            return errorPayload("invalid_window_progress")
        }
        var payload = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND WINDOW_PROGRESS\n${targetLine}WINDOW_PROJECTION ACTIVE\nWINDOW_SCENE_VERSION ${progress.sceneVersion}\nWINDOW_NATIVE_SUBMISSION_VERSION ${progress.nativeSubmissionVersion}\nWINDOW_PRESENTATION_STATE ${progress.presentationState}\nWINDOW_SESSION ${progress.sessionIdentity}\nWINDOW_ACCEPTED_SCENE_VERSION ${progress.acceptedSceneVersion}\nWINDOW_SUBMITTED_SCENE_VERSION ${progress.submittedSceneVersion}\nWINDOW_SUBMITTED_FRAME_INDEX ${progress.submittedFrameIndex}\nWINDOW_METAL_COMPLETED_FRAME_INDEX ${progress.observedMetalCompletionFrameIndex}\nWINDOW_METAL_FAILED_FRAME_INDEX ${progress.observedMetalFailureFrameIndex}\nWINDOW_METAL_GPU_DURATION_MICROS ${progress.observedMetalGpuDurationMicros}\nWINDOW_OVERLAY_DRAWN_SCENE_VERSION ${progress.overlayDrawnSceneVersion}\nWINDOW_REFRESH_PENDING ${progress.pendingRefreshReason}\nWINDOW_LAST_NATIVE_FAILURE ${progress.lastNativeFailure}\n"
        payload = "${payload}${progress.geometryFactsPayload()}\n"
        payload = "${payload}${progress.workload.factsPayload()}\n"
        payload = "${payload}WINDOW_EFFECT_ID ${progress.effectIdentity}\n" +
            "WINDOW_EFFECT_REQUESTED_RADIUS_POINTS ${progress.effectRequestedRadiusPoints}\n" +
            "WINDOW_EFFECT_SUBMITTED_SCENE_VERSION ${progress.effectSubmittedSceneVersion}\n" +
            "WINDOW_EFFECT_SUBMITTED_FRAME_INDEX ${progress.effectSubmittedFrameIndex}\n" +
            "WINDOW_EFFECT_SUBMITTED_RADIUS_POINTS ${progress.effectSubmittedRadiusPoints}\n" +
            "WINDOW_EFFECT_SUBMITTED_MODE ${progress.effectSubmittedMode}\n" +
            "WINDOW_EFFECT_FALLBACK_REASON ${progress.effectFallbackReason}\n" +
            "WINDOW_EFFECT_COMPLETION ${progress.effectCompletion}\n" +
            "WINDOW_BACKGROUND_IDENTITY ${progress.windowBackgroundIdentity}\n" +
            "WINDOW_BACKGROUND_REQUESTED ${progress.windowBackgroundRequested}\n" +
            "WINDOW_BACKGROUND_BACKEND ${progress.windowBackgroundBackend}\n" +
            "WINDOW_BACKGROUND_ACTUAL ${progress.windowBackgroundActual}\n" +
            "WINDOW_BACKGROUND_FALLBACK_REASON ${progress.windowBackgroundFallbackReason}\n" +
            "WINDOW_BACKGROUND_ACCEPTED_SCENE_VERSION ${progress.windowBackgroundAcceptedSceneVersion}\n" +
            "WINDOW_BACKGROUND_FRAME_INDEX ${progress.windowBackgroundFrameIndex}\n" +
            "WINDOW_BACKGROUND_REQUEST_REVISION ${progress.windowBackgroundRequestRevision}\n" +
            "WINDOW_BACKGROUND_ENVIRONMENT_REVISION ${progress.windowBackgroundEnvironmentRevision}\n" +
            "WINDOW_BACKGROUND_OBSERVATION_REVISION ${progress.windowBackgroundObservationRevision}\n" +
            "WINDOW_BACKGROUND_COMPLETION ${progress.windowBackgroundCompletion}\n" +
            "WINDOW_BACKGROUND_REDUCE_TRANSPARENCY ${progress.windowBackgroundReduceTransparency}\n" +
            "WINDOW_BACKGROUND_ACTIVE ${progress.windowBackgroundActive}\n" +
            "WINDOW_BACKGROUND_VISUAL_RESULT ${progress.windowBackgroundVisualResult}\n" +
            "WINDOW_BACKGROUND_COLOR_SCHEME ${progress.windowBackgroundColorScheme}\nEND"
        if (!isBoundedPayload(payload)) {
            return errorPayload("response_too_large")
        }
        return payload
    }

    private func windowInteractionPayload(
        progress: CjguiSharedOperationWindowProgress,
        windowTarget!: String = ""
    ): String {
        if (windowTarget.size > 0 && !isSafeIdentifier(windowTarget)) {
            return errorPayload("invalid_window_target")
        }
        let targetLine = if (windowTarget.size > 0) {
            "WINDOW_TARGET ${windowTarget}\n"
        } else {
            ""
        }
        if (!progress.isActive) {
            return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND WINDOW_INTERACTION\n${targetLine}WINDOW_PROJECTION NONE\nEND"
        }
        if (!isSafeIdentifier(progress.sessionIdentity) || progress.interactionVersion < 0 ||
            !isSafeIdentifier(progress.focusedControlId) || !isSafeIdentifier(progress.activeLayerId) ||
            progress.selectionStart < 0 || progress.selectionEnd < progress.selectionStart) {
            return errorPayload("invalid_window_interaction")
        }
        // The focus fact must be one of the three published states, and any state
        // that cannot confirm a live identity must NOT carry a control id: the
        // payload would otherwise name a removed/rebound instance as focused.
        let focusStateKnown = progress.focusState == CJGUI_WINDOW_FOCUS_STATE_VALID ||
            progress.focusState == CJGUI_WINDOW_FOCUS_STATE_UNFOCUSED ||
            progress.focusState == CJGUI_WINDOW_FOCUS_STATE_UNKNOWN
        if (!focusStateKnown) {
            return errorPayload("invalid_window_interaction")
        }
        if (progress.focusState != CJGUI_WINDOW_FOCUS_STATE_VALID && progress.focusedControlId != "none") {
            return errorPayload("invalid_window_interaction")
        }
        var payload = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND WINDOW_INTERACTION\n${targetLine}WINDOW_PROJECTION ACTIVE\nWINDOW_SESSION ${progress.sessionIdentity}\nWINDOW_SCENE_VERSION ${progress.sceneVersion}\nWINDOW_INTERACTION_VERSION ${progress.interactionVersion}\nWINDOW_FOCUS_STATE ${progress.focusState}\nWINDOW_FOCUS ${progress.focusedControlId}\nWINDOW_ACTIVE_LAYER ${progress.activeLayerId}\nWINDOW_SOURCE window_interaction_projection\nWINDOW_KNOWN_SCOPE accepted_scene_identity\n"
        if (progress.hasTextSelection) {
            payload = "${payload}WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT\nWINDOW_SELECTION ${progress.focusedControlId} ${progress.selectionStart} ${progress.selectionEnd}\n"
        }
        for (fact in progress.viewportFacts) {
            // The window builds these from its own accepted viewport objects; the
            // transport only refuses control bytes and oversized lines, so an
            // external client never receives raw internal text.
            if (!isSafeViewportFact(fact)) {
                return errorPayload("invalid_window_interaction")
            }
            payload = "${payload}${fact}\n"
        }
        payload = "${payload}END"
        if (!isBoundedPayload(payload)) {
            return errorPayload("response_too_large")
        }
        return payload
    }

    /// A bounded printable viewport fact line produced by the window.
    private func isSafeViewportFact(fact: String): Bool {
        if (fact.size < 18 || fact.size > 220 || !fact.startsWith("WINDOW_VIEWPORT ")) {
            return false
        }
        for (ch in fact.toRuneArray()) {
            if (ch < r' ' || ch > r'~') {
                return false
            }
        }
        return true
    }

    private func resultPayload(result: CjguiSharedOperationActionResult): String {
        return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND RESULT\nAPPLIED ${result.applied}\nCONFLICT ${result.isVersionConflict}\nVERSION_BEFORE ${result.versionBefore}\nVERSION_AFTER ${result.versionAfter}\nREASON ${result.reason}\nEND"
    }

    private func rangeReadPayload(
        rangeRead: CjguiSharedOperationRangeRead,
        requestedResourceId: Int64,
        requestedStart: Int64,
        requestedEnd: Int64
    ): String {
        if (rangeRead.resourceId != requestedResourceId || rangeRead.version < 0 || rangeRead.start < 0 ||
            rangeRead.end < rangeRead.start || !isSafeIdentifier(rangeRead.reason)) {
            return errorPayload("invalid_range")
        }
        if (rangeRead.isAvailable) {
            if (rangeRead.isVersionConflict || rangeRead.start != requestedStart || rangeRead.end != requestedEnd ||
                rangeRead.content.size != requestedEnd - requestedStart || rangeRead.content.size >
                CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
                return errorPayload("invalid_range")
            }
        } else if (rangeRead.content.size != 0) {
            return errorPayload("invalid_range")
        }
        var payload = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND RANGE\nAVAILABLE ${rangeRead.isAvailable}\nCONFLICT ${rangeRead.isVersionConflict}\nRESOURCE ${rangeRead.resourceId}\nVERSION ${rangeRead.version}\nRANGE ${rangeRead.start} ${rangeRead.end}\nREASON ${rangeRead.reason}\n"
        if (rangeRead.isAvailable) {
            payload = "${payload}CONTENT_UTF8_HEX ${rangeRead.content.size} ${encodeUtf8HexValue(rangeRead.content)}\n"
        }
        payload = "${payload}END"
        if (!isBoundedPayload(payload)) {
            return errorPayload("response_too_large")
        }
        return payload
    }

    private func changesPayload(
        changes: CjguiSharedOperationChanges,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool
    ): String {
        if (changes.sinceVersion < 0 || changes.currentVersion < changes.sinceVersion ||
            !isSafeIdentifier(changes.streamIdentity)) {
            return errorPayload("invalid_changes")
        }
        let visible = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changes.entries) {
            if (entry.version <= changes.sinceVersion || entry.version > changes.currentVersion ||
                !isSafeIdentifier(entry.kind)) {
                return errorPayload("invalid_changes")
            }
            if (authorization.permitsResource("GET_CHANGES", entry.resourceId) && (!hasExplicitTargets || containsId(
                targets, entry.resourceId))) {
                visible.add(entry)
            }
        }
        var payload = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND CHANGES\nSTREAM_ID ${changes.streamIdentity}\nSINCE_VERSION ${changes.sinceVersion}\nCURRENT_VERSION ${changes.currentVersion}\nRESYNC_REQUIRED ${changes.requiresResync}\nCHANGES ${visible.size}\n"
        for (entry in visible) {
            payload = "${payload}CHANGE ${entry.version} ${entry.resourceId} ${entry.kind}\n"
        }
        payload = "${payload}END"
        if (!isBoundedPayload(payload)) {
            return errorPayload("response_too_large")
        }
        return payload
    }

    private func snapshotBody(
        snapshot: CjguiSharedOperationContextSnapshot,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool,
        windowProjection: CjguiSharedOperationWindowProjection,
        windowTarget!: String = ""
    ): CjguiSharedOperationSnapshotBody {
        if (!isSafeIdentifier(snapshot.resourceType) || (snapshot.streamIdentity.size > 0 &&
            !isSafeIdentifier(snapshot.streamIdentity)) || snapshot.contextName.size == 0 || snapshot.contextName.size >
            CJGUI_SHARED_OPERATION_MAX_STRING_BYTES || snapshot.ownerState.size >
            CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
            return CjguiSharedOperationSnapshotBody(false, "")
        }
        let actions = visibleActions()
        let body = CjguiSharedOperationBoundedTextBuilder()
        if (!body.append("VERSION ${snapshot.version}\n") ||
            !body.append(
            "RESOURCE_TYPE_UTF8_HEX ${snapshot.resourceType.size} ${encodeUtf8HexValue(snapshot.resourceType)}\n") ||
            !body.append(
            "CONTEXT_NAME_UTF8_HEX ${snapshot.contextName.size} ${encodeUtf8HexValue(snapshot.contextName)}\n") ||
            !body.append("ACTIONS ${actions.size}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        if (snapshot.streamIdentity.size > 0 && !body.append("STREAM_ID ${snapshot.streamIdentity}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        if (snapshot.ownerState.size > 0 && !body.append(
            "OWNER_STATE_UTF8_HEX ${snapshot.ownerState.size} ${encodeUtf8HexValue(snapshot.ownerState)}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        for (action in actions) {
            if (!body.append(actionMetadata(action))) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
        }
        if (authorization.callerId.size == 0 || authorization.callerId.size > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
            return CjguiSharedOperationSnapshotBody(false, "")
        }
        if (!body.append(
            "AUTH_CALLER_UTF8_HEX ${authorization.callerId.size} ${encodeUtf8HexValue(authorization.callerId)}\n") ||
            !body.append("AUTH_SCOPES ${actions.size}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        for (action in actions) {
            if (authorization.allowsAllResources(action.name)) {
                if (!body.append("AUTH_SCOPE ${action.name} ALL\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            } else {
                let allowed = authorization.allowedResourceIds(action.name)
                if (!body.append("AUTH_SCOPE ${action.name} IDS ${allowed.size}\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
                for (resourceId in allowed) {
                    if (!body.append("AUTH_SCOPE_RESOURCE_ID ${action.name} ${resourceId}\n")) {
                        return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                    }
                }
            }
        }

        let visibleResources = ArrayList<CjguiSharedOperationResource>()
        for (resource in snapshot.resources) {
            if (authorization.permitsResource("GET_CONTEXT", resource.id) && (!hasExplicitTargets || containsId(targets,
                resource.id))) {
                visibleResources.add(resource)
            }
        }
        if (!body.append("RESOURCES ${visibleResources.size}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        for (resource in visibleResources) {
            if (resource.name.size == 0 || resource.name.size > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
                return CjguiSharedOperationSnapshotBody(false, "")
            }
            if (!body.append(
                "RESOURCE ${resource.id} ${resource.name.size} ${encodeUtf8HexValue(resource.name)} ${resource.fields.size}\n")) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
            for (field in resource.fields) {
                if (!isSafeIdentifier(field.name)) {
                    return CjguiSharedOperationSnapshotBody(false, "")
                }
                if (field.value.valueType == "STRING") {
                    if (field.value.stringValue.size > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
                        return CjguiSharedOperationSnapshotBody(false, "")
                    }
                    if (!body.append(
                        "FIELD ${resource.id} ${field.name} STRING ${field.value.stringValue.size} ${encodeUtf8HexValue(field.value.stringValue)}\n")) {
                        return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                    }
                } else if (field.value.valueType == "INTEGER") {
                    if (!body.append("FIELD ${resource.id} ${field.name} INTEGER ${field.value.integerValue}\n")) {
                        return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                    }
                } else if (field.value.valueType == "BOOLEAN") {
                    let booleanValue = if (field.value.booleanValue) {
                        1
                    } else {
                        0
                    }
                    if (!body.append("FIELD ${resource.id} ${field.name} BOOLEAN ${booleanValue}\n")) {
                        return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                    }
                } else {
                    return CjguiSharedOperationSnapshotBody(false, "")
                }
            }
        }
        let visibleProjectionRelations = ArrayList<CjguiSharedOperationRelation>()
        let visibleProjectionNodes = ArrayList<CjguiSharedOperationWindowNode>()
        let visibleProjectionFieldValues = ArrayList<CjguiSharedOperationWindowFieldValue>()
        let visibleProjectionCollections = ArrayList<CjguiSharedOperationWindowCollection>()
        if (windowProjection.isActive) {
            for (node in windowProjection.nodes) {
                if (node.nodeId < 0 || !isSafeIdentifier(node.semanticId) || !isSafeIdentifier(node.nodeKind)) {
                    return CjguiSharedOperationSnapshotBody(false, "")
                }
                if (windowNodeIsVisible(node, targets, hasExplicitTargets)) {
                    visibleProjectionNodes.add(node)
                }
            }
            for (relation in windowProjection.relations) {
                if (!isSafeRelation(relation)) {
                    return CjguiSharedOperationSnapshotBody(false, "")
                }
                if (relationIsVisible(relation, targets, hasExplicitTargets)) {
                    visibleProjectionRelations.add(relation)
                }
            }
            for (fieldValue in windowProjection.fieldValues) {
                if (!isSafeWindowFieldValue(fieldValue)) {
                    return CjguiSharedOperationSnapshotBody(false, "")
                }
                if (windowFieldValueIsVisible(fieldValue, targets, hasExplicitTargets)) {
                    visibleProjectionFieldValues.add(fieldValue)
                }
            }
            // A logical list range may be described only to a caller already
            // authorized for the collection's full context. Target-filtered
            // reads retain their existing node-level filtering and do not use
            // count/range metadata to infer off-screen objects.
            if (!hasExplicitTargets && authorization.allowsAllResources("GET_CONTEXT")) {
                for (collection in windowProjection.collections) {
                    if (!isSafeIdentifier(collection.semanticId) || collection.totalCount < 0 ||
                        collection.materializedStart < 0 || collection.materializedEnd < collection.materializedStart ||
                        collection.materializedEnd > collection.totalCount || (collection.selectedKey.size > 0 &&
                        !isSafeIdentifier(collection.selectedKey)) || (collection.focusedKey.size > 0 &&
                        !isSafeIdentifier(collection.focusedKey))) {
                        return CjguiSharedOperationSnapshotBody(false, "")
                    }
                    visibleProjectionCollections.add(collection)
                }
            }
        }
        if (windowTarget.size > 0 && !isSafeIdentifier(windowTarget)) {
            return CjguiSharedOperationSnapshotBody(false, "")
        }
        if (windowTarget.size > 0 && !body.append("WINDOW_TARGET ${windowTarget}\n")) {
            return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
        }
        if (!windowProjection.isActive) {
            if (!body.append("WINDOW_PROJECTION NONE\n")) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
        } else {
            if (windowProjection.sceneVersion <= 0 || windowProjection.nativeSubmissionVersion < -1 ||
                windowProjection.acceptedSceneVersion < 0 || windowProjection.submittedSceneVersion < -1 ||
                windowProjection.submittedFrameIndex < -1 || windowProjection.observedMetalCompletionFrameIndex < -1 ||
                windowProjection.observedMetalFailureFrameIndex < -1 ||
                windowProjection.observedMetalGpuDurationMicros < -1 || windowProjection.overlayDrawnSceneVersion < -1 ||
                windowProjection.buildPassCount < 0 || windowProjection.layoutPassCount < 0 ||
                windowProjection.nativeSubmissionCount < 0 || windowProjection.lastBuildElapsedMs < -1 ||
                windowProjection.lastLayoutElapsedMs < -1 || windowProjection.lastNativeMeasurementElapsedMs < -1 ||
                windowProjection.lastNativeStageAndSubmitElapsedMs < -1 ||
                windowProjection.lastNativeMeasurementCallCount < 0 || windowProjection.layoutReuseHitCount < 0 ||
                windowProjection.layoutReuseMissCount < 0 || windowProjection.layoutReuseRevalidationNodeCount < 0 ||
                windowProjection.layoutReuseReplayedNodeCount < 0 || windowProjection.layoutReuseEntryCount < 0 ||
                !isSafeIdentifier(windowProjection.presentationState) ||
                !isSafeIdentifier(windowProjection.sessionIdentity) ||
                !isSafeWindowDiagnostic(windowProjection.pendingRefreshReason) ||
                !isSafeWindowDiagnostic(windowProjection.lastNativeFailure)) {
                return CjguiSharedOperationSnapshotBody(false, "")
            }
            if (!body.append("WINDOW_PROJECTION ACTIVE\n") ||
                !body.append("WINDOW_SCENE_VERSION ${windowProjection.sceneVersion}\n") ||
                !body.append("WINDOW_NATIVE_SUBMISSION_VERSION ${windowProjection.nativeSubmissionVersion}\n") ||
                !body.append("WINDOW_PRESENTATION_STATE ${windowProjection.presentationState}\n") ||
                !body.append("WINDOW_SESSION ${windowProjection.sessionIdentity}\n") ||
                !body.append("WINDOW_ACCEPTED_SCENE_VERSION ${windowProjection.acceptedSceneVersion}\n") ||
                !body.append("WINDOW_SUBMITTED_SCENE_VERSION ${windowProjection.submittedSceneVersion}\n") ||
                !body.append("WINDOW_SUBMITTED_FRAME_INDEX ${windowProjection.submittedFrameIndex}\n") ||
                !body.append(
                "WINDOW_METAL_COMPLETED_FRAME_INDEX ${windowProjection.observedMetalCompletionFrameIndex}\n") ||
                !body.append("WINDOW_METAL_FAILED_FRAME_INDEX ${windowProjection.observedMetalFailureFrameIndex}\n") ||
                !body.append("WINDOW_METAL_GPU_DURATION_MICROS ${windowProjection.observedMetalGpuDurationMicros}\n") ||
                !body.append("WINDOW_OVERLAY_DRAWN_SCENE_VERSION ${windowProjection.overlayDrawnSceneVersion}\n") ||
                !body.append("WINDOW_REFRESH_PENDING ${windowProjection.pendingRefreshReason}\n") ||
                !body.append("WINDOW_LAST_NATIVE_FAILURE ${windowProjection.lastNativeFailure}\n") ||
                !body.append(
                "WINDOW_WORK_COUNTS ${windowProjection.buildPassCount} ${windowProjection.layoutPassCount} ${windowProjection.nativeSubmissionCount}\n") ||
                !body.append(
                "WINDOW_WORK_TIMING_MS ${windowProjection.lastBuildElapsedMs} ${windowProjection.lastLayoutElapsedMs} ${windowProjection.lastNativeMeasurementElapsedMs} ${windowProjection.lastNativeStageAndSubmitElapsedMs}\n") ||
                !body.append("WINDOW_MEASUREMENT_CALL_COUNT ${windowProjection.lastNativeMeasurementCallCount}\n") ||
                !body.append(
                "WINDOW_LAYOUT_REUSE ${windowProjection.layoutReuseHitCount} ${windowProjection.layoutReuseMissCount} ${windowProjection.layoutReuseRevalidationNodeCount} ${windowProjection.layoutReuseReplayedNodeCount} ${windowProjection.layoutReuseEntryCount}\n")) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
            for (collection in visibleProjectionCollections) {
                if (!body.append(
                    "WINDOW_COLLECTION ${collection.semanticId} ${collection.totalCount} ${collection.materializedStart} ${collection.materializedEnd} ${if (collection.selectedKey.size > 0) { collection.selectedKey } else { "none" }} ${if (collection.focusedKey.size > 0) { collection.focusedKey } else { "none" }}\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            }
            for (node in visibleProjectionNodes) {
                if (!body.append("WINDOW_NODE ${node.semanticId} ${node.nodeId} ${node.nodeKind}\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            }
            for (fieldValue in visibleProjectionFieldValues) {
                if (!body.append(appendWindowFieldValue("", fieldValue))) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            }
            if (projectionFocusIsVisible(windowProjection, targets, hasExplicitTargets)) {
                if (!body.append("WINDOW_FOCUS control ${windowProjection.focusedControlId}\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            }
            if (windowProjection.hasTextSelection && projectionFocusIsVisible(windowProjection, targets,
                hasExplicitTargets)) {
                // Generic native-window selection is reported by AppKit in
                // UTF-16 code units. Document domains convert it at their
                // own UI boundary and expose their durable selection fields
                // separately in UTF-8 bytes.
                if (!body.append("WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT\n") ||
                    !body.append(
                    "WINDOW_SELECTION ${windowProjection.focusedControlId} ${windowProjection.selectionStart} ${windowProjection.selectionEnd}\n")) {
                    return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
                }
            }
        }
        for (relation in snapshot.relations) {
            if (!isSafeRelation(relation)) {
                return CjguiSharedOperationSnapshotBody(false, "")
            }
            if (!relationIsVisible(relation, targets, hasExplicitTargets)) {
                continue
            }
            if (!body.append(
                "RELATION ${relation.sourceKind} ${relation.sourceId} ${relation.relation} ${relation.targetKind} ${relation.targetId}\n")) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
        }
        for (relation in visibleProjectionRelations) {
            if (!body.append(
                "RELATION ${relation.sourceKind} ${relation.sourceId} ${relation.relation} ${relation.targetKind} ${relation.targetId}\n")) {
                return CjguiSharedOperationSnapshotBody(false, "", failureReason: "response_too_large")
            }
        }
        return CjguiSharedOperationSnapshotBody(true, body.toString())
    }

    private func isSafeRelation(relation: CjguiSharedOperationRelation): Bool {
        return isSafeIdentifier(relation.sourceKind) && isSafeIdentifier(relation.sourceId) && isSafeIdentifier(
            relation.relation) && isSafeIdentifier(relation.targetKind) && isSafeIdentifier(relation.targetId)
    }

    private func isSafeWindowFieldValue(fieldValue: CjguiSharedOperationWindowFieldValue): Bool {
        if (fieldValue.resourceId < 0 || !isSafeIdentifier(fieldValue.nodeSemanticId) ||
            !isSafeIdentifier(fieldValue.fieldId) || !isSafeIdentifier(fieldValue.displayValueRole) ||
            !isSafeIdentifier(fieldValue.valueSource)) {
            return false
        }
        if (fieldValue.value.valueType == "STRING") {
            return fieldValue.value.stringValue.size <= CJGUI_SHARED_OPERATION_MAX_STRING_BYTES
        }
        return fieldValue.value.valueType == "INTEGER" || fieldValue.value.valueType == "BOOLEAN"
    }

    private func appendWindowFieldValue(body: String, fieldValue: CjguiSharedOperationWindowFieldValue): String {
        let prefix = "${body}WINDOW_FIELD_VALUE ${fieldValue.nodeSemanticId} ${fieldValue.resourceId} ${fieldValue.fieldId} ${fieldValue.displayValueRole} ${fieldValue.valueSource}"
        if (fieldValue.value.valueType == "STRING") {
            return "${prefix} STRING ${fieldValue.value.stringValue.size} ${encodeUtf8HexValue(fieldValue.value.stringValue)}\n"
        }
        if (fieldValue.value.valueType == "INTEGER") {
            return "${prefix} INTEGER ${fieldValue.value.integerValue}\n"
        }
        let booleanValue = if (fieldValue.value.booleanValue) {
            1
        } else {
            0
        }
        return "${prefix} BOOLEAN ${booleanValue}\n"
    }

    private func projectionFocusIsVisible(
        windowProjection: CjguiSharedOperationWindowProjection,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool
    ): Bool {
        if (!isSafeIdentifier(windowProjection.focusedControlId) || windowProjection.selectionStart < 0 ||
            windowProjection.selectionEnd < windowProjection.selectionStart) {
            return false
        }
        for (relation in windowProjection.relations) {
            if (relationIsVisible(relation, targets, hasExplicitTargets) && (relation.sourceId == windowProjection
                .focusedControlId || relation.targetId == windowProjection.focusedControlId)) {
                return true
            }
        }
        return false
    }

    private func relationIsVisible(
        relation: CjguiSharedOperationRelation,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool
    ): Bool {
        for (resourceId in relation.resourceIds()) {
            if (!authorization.permitsResource("GET_CONTEXT", resourceId) || (hasExplicitTargets &&
                !containsId(targets, resourceId))) {
                return false
            }
        }
        return true
    }

    private func windowNodeIsVisible(
        node: CjguiSharedOperationWindowNode,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool
    ): Bool {
        for (resourceId in node.resourceIds()) {
            if (!authorization.permitsResource("GET_CONTEXT", resourceId) || (hasExplicitTargets &&
                !containsId(targets, resourceId))) {
                return false
            }
        }
        return true
    }

    private func windowFieldValueIsVisible(
        fieldValue: CjguiSharedOperationWindowFieldValue,
        targets: ArrayList<Int64>,
        hasExplicitTargets: Bool
    ): Bool {
        return authorization.permitsResource("GET_CONTEXT", fieldValue.resourceId) && (!hasExplicitTargets ||
            containsId(targets, fieldValue.resourceId))
    }

    private func visibleActions(): ArrayList<CjguiSharedOperationActionDescriptor> {
        let actions = ArrayList<CjguiSharedOperationActionDescriptor>()
        if (authorization.permitsAction("GET_CONTEXT")) {
            actions.add(
                CjguiSharedOperationActionDescriptor(
                    "GET_CONTEXT",
                    "读取当前上下文",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(),
                    0,
                    CJGUI_SHARED_OPERATION_MAX_TARGETS
                )
            )
        }
        if (authorization.permitsAction("GET_CHANGES")) {
            if (let Some(_) <- changeDomain) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_CHANGES",
                        "读取自版本后的变化",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        CJGUI_SHARED_OPERATION_MAX_TARGETS
                    )
                )
            }
        }
        if (authorization.permitsAction("GET_TREE_SELECTION")) {
            if (let Some(_) <- treeSelectionProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_TREE_SELECTION",
                        "读取树/集合选择快照",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
        }
        if (authorization.permitsAction("UPDATE_TREE_SELECTION")) {
            if (let Some(_) <- treeSelectionProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "UPDATE_TREE_SELECTION",
                        "更新树/集合选择",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        CJGUI_SHARED_OPERATION_MAX_TARGETS
                    )
                )
            }
        }
        if (authorization.permitsAction("GET_GENERATED_UI")) {
            if (let Some(_) <- generatedUiProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_GENERATED_UI",
                        "查询/读取运行时生成界面",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
        }
        if (authorization.permitsAction("SUBMIT_GENERATED_UI")) {
            if (let Some(_) <- generatedUiProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "SUBMIT_GENERATED_UI",
                        "提交运行时生成界面结构",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        CJGUI_SHARED_OPERATION_MAX_TARGETS
                    )
                )
            }
        }
        if (authorization.permitsAction("SNAPSHOT_ACQUIRE")) {
            if (let Some(_) <- snapshotProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "SNAPSHOT_ACQUIRE",
                        "取得固定快照租约",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(
                            [
                                CjguiSharedOperationParameterDescriptor("resourceId", "INTEGER", true),
                                CjguiSharedOperationParameterDescriptor("ttlMs", "INTEGER", false)
                            ]
                        ),
                        1,
                        1
                    )
                )
            }
        }
        if (authorization.permitsAction("SNAPSHOT_READ")) {
            if (let Some(_) <- snapshotProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "SNAPSHOT_READ",
                        "读取固定快照片段",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(
                            [
                                CjguiSharedOperationParameterDescriptor("start", "INTEGER", true),
                                CjguiSharedOperationParameterDescriptor("end", "INTEGER", true)
                            ]
                        ),
                        1,
                        1
                    )
                )
            }
        }
        if (authorization.permitsAction("SNAPSHOT_RELEASE")) {
            if (let Some(_) <- snapshotProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "SNAPSHOT_RELEASE",
                        "释放固定快照租约",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(
                            [
                                CjguiSharedOperationParameterDescriptor("token", "STRING", true)
                            ]
                        ),
                        1,
                        1
                    )
                )
            }
        }
        if (authorization.permitsAction("READ_RANGE")) {
            if (let Some(_) <- rangeReadDomain) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "READ_RANGE",
                        "读取文档片段",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(
                            [
                                CjguiSharedOperationParameterDescriptor("start", "INTEGER", true),
                                CjguiSharedOperationParameterDescriptor("end", "INTEGER", true),
                                CjguiSharedOperationParameterDescriptor("expectedVersion", "INTEGER", true)
                            ]
                        ),
                        1,
                        1
                    )
                )
            }
        }
        if (authorization.permitsAction("GET_WINDOW_PROGRESS")) {
            if (hasWindowProgressReadProvider()) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_WINDOW_PROGRESS",
                        "读取窄窗口进度",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
            if (let Some(_) <- transferReceiptProvider) {
                actions.add(CjguiSharedOperationActionDescriptor("GET_TRANSFER_RECEIPT",
                    "按窗口与事件身份读取图片接收回执",
                    ArrayList<CjguiSharedOperationParameterDescriptor>([
                        CjguiSharedOperationParameterDescriptor("sessionIdentity", "STRING", true),
                        CjguiSharedOperationParameterDescriptor("eventId", "INTEGER", true)
                    ]), 1, 1))
                actions.add(CjguiSharedOperationActionDescriptor("GET_TRANSFER_RECEIPT_CHANGES",
                    "有界增量读取图片接收回执",
                    ArrayList<CjguiSharedOperationParameterDescriptor>([
                        CjguiSharedOperationParameterDescriptor("sessionIdentity", "STRING", true),
                        CjguiSharedOperationParameterDescriptor("afterRevision", "INTEGER", true),
                        CjguiSharedOperationParameterDescriptor("maximum", "INTEGER", true)
                    ]), 1, 1))
            }
        }
        if (let Some(_) <- positionMotionProvider) {
            if (authorization.permitsAction("GET_NODE_TRANSLATION")) {
                actions.add(CjguiSharedOperationActionDescriptor("GET_NODE_TRANSLATION",
                    "读取已接受节点的平移目标与呈现值",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(), 0, 32))
            }
            if (authorization.permitsAction("SET_NODE_TRANSLATION")) {
                actions.add(CjguiSharedOperationActionDescriptor("SET_NODE_TRANSLATION",
                    "按接受身份设置节点平移目标",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1))
            }
            if (authorization.permitsAction("CLEAR_NODE_TRANSLATION")) {
                actions.add(CjguiSharedOperationActionDescriptor("CLEAR_NODE_TRANSLATION",
                    "按接受身份清除节点位置动效",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1))
            }
        }
        if (authorization.permitsAction("GET_WINDOW_TARGETS")) {
            if (let Some(_) <- windowProjectionTargetProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_WINDOW_TARGETS",
                        "列举已授权窗口目标",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
        }
        if (authorization.permitsAction("GET_WINDOW_CONTEXT")) {
            if (let Some(_) <- windowProjectionTargetProvider) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_WINDOW_CONTEXT",
                        "读取指定窗口上下文",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
        }
        if (authorization.permitsAction("GET_WINDOW_INTERACTION")) {
            if (hasWindowProgressReadProvider()) {
                actions.add(
                    CjguiSharedOperationActionDescriptor(
                        "GET_WINDOW_INTERACTION",
                        "读取已授权窗口交互",
                        ArrayList<CjguiSharedOperationParameterDescriptor>(),
                        0,
                        0
                    )
                )
            }
        }
        for (action in domain.actionDescriptors()) {
            if (authorization.permitsAction(action.name) && isSafeActionDescriptor(action)) {
                actions.add(action)
            }
        }
        return actions
    }

    private func hasWindowProgressReadProvider(): Bool {
        if (let Some(_) <- windowProgressProvider) {
            return true
        }
        if (let Some(_) <- windowProgressTargetProvider) {
            return true
        }
        return false
    }

    private func findAction(actionName: String): ?CjguiSharedOperationActionDescriptor {
        for (action in domain.actionDescriptors()) {
            if (action.name == actionName && authorization.permitsAction(actionName) && isSafeActionDescriptor(action)) {
                return Some(action)
            }
        }
        return None
    }

    private func actionMetadata(action: CjguiSharedOperationActionDescriptor): String {
        var metadata = "ACTION ${action.name} PARAMETERS ${action.parameters.size} TARGETS ${action.minimumTargetCount} ${action.maximumTargetCount}\n"
        metadata = "${metadata}ACTION_DISPLAY_NAME_UTF8_HEX ${action.name} ${action.displayName.size} ${encodeUtf8HexValue(action.displayName)}\n"
        for (parameter in action.parameters) {
            let required = if (parameter.isRequired) {
                "REQUIRED"
            } else {
                "OPTIONAL"
            }
            metadata = "${metadata}PARAMETER ${action.name} ${parameter.name} ${parameter.valueType} ${required}\n"
        }
        return metadata
    }

    private func descriptorPayload(): ?String {
        let actions = visibleActions()
        var descriptor = "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\n"
        descriptor = "${descriptor}SOCKET_PATH_UTF8_HEX ${socketPath.size} ${encodeUtf8HexValue(socketPath)}\n"
        let capability = authorization.capabilityForGrantedCaller()
        descriptor = "${descriptor}CAPABILITY_UTF8_HEX ${capability.size} ${encodeUtf8HexValue(capability)}\n"
        descriptor = "${descriptor}CALLER_UTF8_HEX ${authorization.callerId.size} ${encodeUtf8HexValue(authorization.callerId)}\n"
        descriptor = "${descriptor}ENDPOINT_EPOCH ${endpointGeneration}\nENDPOINT_INSTANCE ${endpointInstanceValue}\nENDPOINT_BIND_GENERATION ${endpointGeneration}\n"
        descriptor = "${descriptor}ACTIONS ${actions.size}\n"
        for (action in actions) {
            descriptor = "${descriptor}${actionMetadata(action)}"
            if (!isBoundedPayload(descriptor)) {
                return None
            }
        }
        descriptor = "${descriptor}SCOPES ${actions.size}\n"
        for (action in actions) {
            if (authorization.allowsAllResources(action.name)) {
                descriptor = "${descriptor}SCOPE ${action.name} ALL\n"
            } else {
                let allowed = authorization.allowedResourceIds(action.name)
                descriptor = "${descriptor}SCOPE ${action.name} IDS ${allowed.size}\n"
                for (resourceId in allowed) {
                    descriptor = "${descriptor}SCOPE_RESOURCE_ID ${action.name} ${resourceId}\n"
                }
            }
            if (!isBoundedPayload(descriptor)) {
                return None
            }
        }
        if (!isBoundedPayload("${descriptor}END\n")) {
            return None
        }
        return Some("${descriptor}END\n")
    }

    private func hasSafeAuthorization(): Bool {
        if (authorization.callerId.size == 0 || authorization.callerId.size > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES) {
            return false
        }
        let capability = authorization.capabilityForGrantedCaller()
        if (!isSafeCapability(capability)) {
            return false
        }
        let actions = visibleActions()
        if (actions.size == 0) {
            return false
        }
        for (scope in authorization.actionScopes()) {
            if (!isSafeIdentifier(scope.actionName)) {
                return false
            }
            if (scope.actionName != "GET_CONTEXT" && !containsAction(actions, scope.actionName)) {
                return false
            }
        }
        return true
    }

    private func isSafeActionDescriptor(action: CjguiSharedOperationActionDescriptor): Bool {
        if (!isSafeIdentifier(action.name) || action.displayName.size == 0 || action.displayName.size >
            CJGUI_SHARED_OPERATION_MAX_STRING_BYTES || action.minimumTargetCount < 0 || action.maximumTargetCount < action
            .minimumTargetCount || action.maximumTargetCount > CJGUI_SHARED_OPERATION_MAX_TARGETS ||
            action.parameters.size > 64) {
            return false
        }
        let names = ArrayList<String>()
        for (parameter in action.parameters) {
            if (!isSafeIdentifier(parameter.name) || !isSupportedValueType(parameter.valueType) || containsString(names,
                parameter.name)) {
                return false
            }
            names.add(parameter.name)
        }
        return true
    }

    private func matchesDeclaredParameters(
        action: CjguiSharedOperationActionDescriptor,
        arguments: ArrayList<CjguiSharedOperationActionArgument>
    ): Bool {
        for (argument in arguments) {
            var matches = false
            for (parameter in action.parameters) {
                if (parameter.name == argument.name && parameter.valueType == argument.value.valueType) {
                    matches = true
                }
            }
            if (!matches) {
                return false
            }
        }
        for (parameter in action.parameters) {
            let present = containsArgument(arguments, parameter.name)
            if (parameter.isRequired && !present) {
                return false
            }
        }
        return true
    }

    private func parseArgument(line: String): ?CjguiSharedOperationActionArgument {
        let fields = line.split(" ")
        if (fields.size < 4 || fields[0] != "ARG" || !isSafeIdentifier(fields[1])) {
            return None
        }
        if (fields[2] == "BOOLEAN" && fields.size == 4) {
            if (fields[3] == "1") {
                return Some(CjguiSharedOperationActionArgument(fields[1], CjguiSharedOperationValue.boolean(true)))
            }
            if (fields[3] == "0") {
                return Some(CjguiSharedOperationActionArgument(fields[1], CjguiSharedOperationValue.boolean(false)))
            }
            return None
        }
        if (fields[2] == "INTEGER" && fields.size == 4) {
            if (let Some(value) <- Int64.tryParse(fields[3])) {
                return Some(CjguiSharedOperationActionArgument(fields[1], CjguiSharedOperationValue.integer(value)))
            }
            return None
        }
        if (fields[2] == "STRING" && fields.size == 5) {
            if (let Some(byteCount) <- Int64.tryParse(fields[3])) {
                if (let Some(value) <- decodeUtf8Hex(fields[4], byteCount)) {
                    return Some(CjguiSharedOperationActionArgument(fields[1], CjguiSharedOperationValue.string(value)))
                }
            }
        }
        if (fields[2] == "TEXT_REPLACEMENTS" && fields.size == 5) {
            if (let Some(byteCount) <- Int64.tryParse(fields[3])) {
                if (let Some(value) <- decodeUtf8Hex(fields[4], byteCount)) {
                    return Some(
                        CjguiSharedOperationActionArgument(fields[1], CjguiSharedOperationValue.textReplacements(value)))
                }
            }
        }
        return None
    }

    private func snapshotContainsResource(snapshot: CjguiSharedOperationContextSnapshot, resourceId: Int64): Bool {
        for (resource in snapshot.resources) {
            if (resource.id == resourceId) {
                return true
            }
        }
        return false
    }

    private func isBoundedPayload(payload: String): Bool {
        return payload.size <= CJGUI_SHARED_OPERATION_MAX_FRAME_BYTES - 512
    }

    private func errorPayload(reason: String): String {
        return "PROTOCOL ${CJGUI_SHARED_OPERATION_PROTOCOL}\nKIND ERROR\nERROR ${reason}\nEND"
    }
}

private func encodeUtf8HexValue(value: String): String {
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let encoded = StringBuilder()
    for (byte in value) {
        let numeric = Int64(byte)
        encoded.append(digits[numeric / 16])
        encoded.append(digits[numeric % 16])
    }
    // Every line must retain its final field. `-` is the reserved explicit
    // representation of a zero-byte UTF-8 value; emitting an empty suffix
    // would be indistinguishable from a malformed protocol line.
    let result = encoded.toString()
    return if (result.size == 0) {
        "-"
    } else {
        result
    }
}

private func decodeUtf8Hex(encoded: String, byteCount: Int64): ?String {
    if (byteCount == 0 && encoded == "-") {
        return Some("")
    }
    if (byteCount < 0 || byteCount > CJGUI_SHARED_OPERATION_MAX_STRING_BYTES || encoded.size != byteCount * 2) {
        return None
    }
    let encodedBytes = encoded.toArray()
    let bytes = ArrayList<Byte>()
    var index = 0
    while (index < encodedBytes.size) {
        if (let Some(high) <- hexValue(encodedBytes[index])) {
            if (let Some(low) <- hexValue(encodedBytes[index + 1])) {
                bytes.add(UInt8(high * 16 + low))
            } else {
                return None
            }
        } else {
            return None
        }
        index += 2
    }
    try {
        return Some(String.fromUtf8(bytes.toArray()))
    } catch (_) {
        return None
    }
}

private func hexValue(value: Byte): ?Int64 {
    if (value >= b'0' && value <= b'9') {
        return Some(Int64(value) - Int64(b'0'))
    }
    if (value >= b'A' && value <= b'F') {
        return Some(Int64(value) - Int64(b'A') + 10)
    }
    if (value >= b'a' && value <= b'f') {
        return Some(Int64(value) - Int64(b'a') + 10)
    }
    return None
}

private func isSafeCapability(capability: String): Bool {
    if (capability.size == 0 || capability.size > 256 || !capability.isAscii()) {
        return false
    }
    for (byte in capability) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if (!isLetter && !isDigit && byte != b'-' && byte != b'_') {
            return false
        }
    }
    return true
}

private func isSafeSelectionKey(value: String): Bool {
    if (value.size == 0 || value.size > 64 || !value.isAscii()) {
        return false
    }
    var index = 0
    for (byte in value) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if ((!isLetter && byte != b'_') && index == 0) {
            return false
        }
        if (!isLetter && !isDigit && byte != b'_' && byte != b'-') {
            return false
        }
        index += 1
    }
    return true
}

private func isSafeInteger(value: String): Bool {
    if (value.size == 0 || value.size > 20 || !value.isAscii()) {
        return false
    }
    var index = 0
    for (byte in value) {
        if (index == 0 && byte == b'-') {
            index += 1
            continue
        }
        if (byte < b'0' || byte > b'9') {
            return false
        }
        index += 1
    }
    return true
}

private func parseInt64OrZero(value: String): Int64 {
    var result: Int64 = 0
    var negative = false
    var index = 0
    for (byte in value) {
        if (index == 0 && byte == b'-') {
            negative = true
            index += 1
            continue
        }
        result = result * 10 + Int64(byte - b'0')
        index += 1
    }
    return if (negative) { -result } else { result }
}

/// Opaque wire identities (endpoint instances, lease tokens, resource instance
/// ids) are only compared for equality and echoed back: the framing invariant
/// is "bounded ASCII with no whitespace or control bytes", nothing more.
/// Framework-generated endpoint instances are hex, so their first character
/// may be a digit -- isSafeIdentifier rejects those, and the endpoint then
/// refuses its own published identity as an invalid request.
private func isSafeOpaqueIdentity(value: String, maxLength: Int64): Bool {
    if (value.size == 0 || value.size > maxLength || !value.isAscii()) {
        return false
    }
    for (byte in value) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if (!isLetter && !isDigit && byte != b'_' && byte != b'-') {
            return false
        }
    }
    return true
}

private func sharedOperationPositionFinite(value: Float64): Bool {
    return value - value == 0.0
}

private func sharedOperationSafeOpaqueToken(value: String): Bool {
    if (value.size == 0 || value.size > 256 || !value.isAscii()) { return false }
    for (byte in value) {
        if (byte <= 32 || byte >= 127) { return false }
    }
    return true
}

private func sharedOperationSafeMotionReference(value: String): Bool {
    if (value.size == 0 || value.size > 64 || !value.isAscii()) { return false }
    for (byte in value) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if (!isLetter && !isDigit && byte != b'_' && byte != b'-' && byte != b'.') { return false }
    }
    return true
}

private func isSafeIdentifier(value: String): Bool {
    if (value.size == 0 || value.size > 64 || !value.isAscii()) {
        return false
    }
    var index = 0
    for (byte in value) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if ((!isLetter && byte != b'_') && index == 0) {
            return false
        }
        // Semantic ids come directly from composable component declarations.
        // Hyphens are token-safe and are already accepted for capabilities;
        // rejecting them here made a valid live window look like an oversized
        // response instead of publishing its projection.
        if (!isLetter && !isDigit && byte != b'_' && byte != b'-') {
            return false
        }
        index += 1
    }
    return true
}

/// Refresh diagnostics are read-only operational context, not caller supplied
/// protocol selectors. Scoped component failures include their public scope
/// and local key, so they need a larger bounded token than an action or
/// window-target identifier while retaining the same ASCII token grammar.
private func isSafeWindowDiagnostic(value: String): Bool {
    if (value.size == 0 || value.size > 384 || !value.isAscii()) {
        return false
    }
    for (byte in value) {
        let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let isDigit = byte >= b'0' && byte <= b'9'
        if (!isLetter && !isDigit && byte != b'_' && byte != b'-') {
            return false
        }
    }
    return true
}

private func isSupportedValueType(valueType: String): Bool {
    return valueType == "STRING" || valueType == "INTEGER" || valueType == "BOOLEAN" || valueType == "TEXT_REPLACEMENTS"
}

private func containsId(ids: ArrayList<Int64>, value: Int64): Bool {
    for (candidate in ids) {
        if (candidate == value) {
            return true
        }
    }
    return false
}

private func containsArgument(arguments: ArrayList<CjguiSharedOperationActionArgument>, name: String): Bool {
    for (argument in arguments) {
        if (argument.name == name) {
            return true
        }
    }
    return false
}

private func containsString(values: ArrayList<String>, value: String): Bool {
    for (candidate in values) {
        if (candidate == value) {
            return true
        }
    }
    return false
}

private func containsAction(actions: ArrayList<CjguiSharedOperationActionDescriptor>, actionName: String): Bool {
    for (action in actions) {
        if (action.name == actionName) {
            return true
        }
    }
    return false
}
