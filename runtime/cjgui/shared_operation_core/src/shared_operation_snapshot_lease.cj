package cjgui_shared_operation_core

import std.collection.*
import std.random.*
import std.sync.*
import std.time.*

/// Fixed-snapshot lease table (E1, Astra 2026-09-28).
///
/// The framework owns tokens, TTL, limits and accounting; the application
/// supplies an opaque handle per acquire and is never asked to copy content.
/// Every entry point here runs on the OWNER thread: the table is not thread
/// safe by itself and must not be touched by I/O workers.
///
/// State machine per record:
///   active -> released | expired | resource_closed | workspace_changed |
///             authorization_revoked | endpoint_changed | limit_exceeded
/// Once terminal, the lease never becomes readable again, and the first
/// terminal reason is kept for the whole diagnostic window.

/// One lease as the owner sees it. `handle == None` only after cleanup ran.
class CjguiSharedOperationSnapshotLeaseRecord {
    let token: String
    let endpointInstance: String
    let bindGeneration: Int64
    let grantId: String
    let authorizationEpoch: Int64
    let readScope: String
    let resourceId: Int64
    let resourceInstanceId: String
    let fixedVersion: Int64
    let fixedByteLength: Int64
    let acquireRequestId: String
    let acquireSignature: String
    let createdAt: MonoTime
    let expiresAt: MonoTime
    var cost: CjguiSharedOperationSnapshotRetentionCost
    var state: String = "active"
    var terminalReason: String = ""
    /// When the record first became terminal; drives the bounded diagnostic
    /// retention window after which maintenance may recycle its slot.
    var terminalAt: ?MonoTime = None
    var handle: ?CjguiSharedOperationSnapshotHandle
    var readsServed: Int64 = 0

    init(token: String, endpointInstance: String, bindGeneration: Int64, grantId: String,
        authorizationEpoch: Int64, readScope: String, resourceId: Int64,
        resourceInstanceId: String, fixedVersion: Int64, fixedByteLength: Int64,
        acquireRequestId: String, acquireSignature: String, createdAt: MonoTime,
        expiresAt: MonoTime, cost: CjguiSharedOperationSnapshotRetentionCost,
        handle: CjguiSharedOperationSnapshotHandle) {
        this.token = token
        this.endpointInstance = endpointInstance
        this.bindGeneration = bindGeneration
        this.grantId = grantId
        this.authorizationEpoch = authorizationEpoch
        this.readScope = readScope
        this.resourceId = resourceId
        this.resourceInstanceId = resourceInstanceId
        this.fixedVersion = fixedVersion
        this.fixedByteLength = fixedByteLength
        this.acquireRequestId = acquireRequestId
        this.acquireSignature = acquireSignature
        this.createdAt = createdAt
        this.expiresAt = expiresAt
        this.cost = cost
        this.handle = handle
    }

    func isActive(): Bool {
        return this.state == "active"
    }
}

/// Full lease description handed back to the client on acquire.
public class CjguiSharedOperationSnapshotLeaseDescription {
    public let token: String
    public let endpointInstance: String
    public let bindGeneration: Int64
    public let resourceId: Int64
    public let resourceInstanceId: String
    public let version: Int64
    public let byteLength: Int64
    public let grantedTtlMs: Int64
    public let remainingTtlMs: Int64
    public let maxReadBytes: Int64
    // What this lease RESERVED: the keep-alive bound the provider declared for the whole
    // holding period. Published so a client can see the reservation it is paying for instead
    // of trusting an unobservable number.
    public let reservedResidentBytes: Int64
    public let reservedBackingBytes: Int64

    public init(token: String, endpointInstance: String, bindGeneration: Int64, resourceId: Int64,
        resourceInstanceId: String, version: Int64, byteLength: Int64, grantedTtlMs: Int64,
        remainingTtlMs: Int64, maxReadBytes: Int64, reservedResidentBytes: Int64,
        reservedBackingBytes: Int64) {
        this.token = token
        this.endpointInstance = endpointInstance
        this.bindGeneration = bindGeneration
        this.resourceId = resourceId
        this.resourceInstanceId = resourceInstanceId
        this.version = version
        this.byteLength = byteLength
        this.grantedTtlMs = grantedTtlMs
        this.remainingTtlMs = remainingTtlMs
        this.maxReadBytes = maxReadBytes
        this.reservedResidentBytes = reservedResidentBytes
        this.reservedBackingBytes = reservedBackingBytes
    }
}

/// Acquire outcome for the transport: a description or a named refusal.
class CjguiSharedOperationSnapshotLeaseOutcome {
    let description: ?CjguiSharedOperationSnapshotLeaseDescription
    let refusal: String
    let isIdempotentReplay: Bool

    init(description: ?CjguiSharedOperationSnapshotLeaseDescription, refusal: String,
        isIdempotentReplay: Bool) {
        this.description = description
        this.refusal = refusal
        this.isIdempotentReplay = isIdempotentReplay
    }

    static func granted(description: CjguiSharedOperationSnapshotLeaseDescription,
        replay: Bool): CjguiSharedOperationSnapshotLeaseOutcome {
        return CjguiSharedOperationSnapshotLeaseOutcome(Some(description), "", replay)
    }

    static func refused(reason: String): CjguiSharedOperationSnapshotLeaseOutcome {
        return CjguiSharedOperationSnapshotLeaseOutcome(None, reason, false)
    }
}

/// Monotonic default clock. Tests install a controllable one instead.
class CjguiSharedOperationSnapshotSystemClock <: CjguiSharedOperationSnapshotClock {
    public func snapshotNow(): MonoTime {
        return MonoTime.now()
    }
}

/// The table itself. All methods run on the owner thread.
class CjguiSharedOperationSnapshotLeaseTable {
    private let limits: CjguiSharedOperationSnapshotLeaseLimits
    private let clock: CjguiSharedOperationSnapshotClock
    private let records: ArrayList<CjguiSharedOperationSnapshotLeaseRecord>
    private var nextSerial: Int64 = 0
    // Accounting that must survive the record's terminal state: a lease whose
    // reservation is still held (cleanup pending) must keep counting.
    private var cleanupPending: Int64 = 0

    init(limits: CjguiSharedOperationSnapshotLeaseLimits, clock: CjguiSharedOperationSnapshotClock) {
        this.limits = limits
        this.clock = clock
        this.records = ArrayList<CjguiSharedOperationSnapshotLeaseRecord>()
    }

    func systemClock(): CjguiSharedOperationSnapshotClock {
        return this.clock
    }

    func retainedRecordCount(): Int64 {
        return Int64(this.records.size)
    }

    func cleanupPendingCount(): Int64 {
        return this.cleanupPending
    }

    func activeCount(): Int64 {
        var active: Int64 = 0
        for (record in this.records) {
            if (record.isActive()) {
                active += 1
            }
        }
        return active
    }

    private func activeCountForGrant(grantId: String): Int64 {
        var active: Int64 = 0
        for (record in this.records) {
            if (record.isActive() && record.grantId == grantId) {
                active += 1
            }
        }
        return active
    }

    private func activeCountForResourceInstance(resourceId: Int64, instanceId: String): Int64 {
        var active: Int64 = 0
        for (record in this.records) {
            if (record.isActive() && record.resourceId == resourceId &&
                record.resourceInstanceId == instanceId) {
                active += 1
            }
        }
        return active
    }

    /// A reservation is held while the handle is held: an active lease AND a
    /// cleanup_pending one both still keep resources alive.
    private func reservedResidentBytes(): Int64 {
        var total: Int64 = 0
        for (record in this.records) {
            if (record.isActive() || record.state == "cleanup_pending") {
                total += record.cost.residentBytesUpperBound
            }
        }
        return total
    }

    private func reservedBackingBytes(): Int64 {
        var total: Int64 = 0
        for (record in this.records) {
            if (record.isActive() || record.state == "cleanup_pending") {
                total += record.cost.backingBytesUpperBound
            }
        }
        return total
    }

    private func reservedOpenResources(): Int64 {
        var total: Int64 = 0
        for (record in this.records) {
            if (record.isActive() || record.state == "cleanup_pending") {
                total += record.cost.openResourceCountUpperBound
            }
        }
        return total
    }

    private func findRecord(token: String): ?CjguiSharedOperationSnapshotLeaseRecord {
        for (record in this.records) {
            if (record.token == token) {
                return Some(record)
            }
        }
        return None
    }

    private func findByRequestId(requestId: String): ?CjguiSharedOperationSnapshotLeaseRecord {
        for (record in this.records) {
            if (record.acquireRequestId == requestId) {
                return Some(record)
            }
        }
        return None
    }

    private func newToken(endpointInstance: String, bindGeneration: Int64): String {
        this.nextSerial += 1
        let nonce = "${sharedOperationLeaseHex16(Random().nextUInt64())}${sharedOperationLeaseHex16(Random().nextUInt64())}"
        return "s1_${endpointInstance}_${bindGeneration}_${nonce}${this.nextSerial}"
    }

    /// Mark a record terminal and physically release its handle exactly once.
    /// Logical invalidation and physical cleanup are accounted separately: a
    /// release that throws leaves the record `cleanup_pending` (still holding
    /// its handle and reservation) and the owner retries it in maintenance.
    private func terminate(record: CjguiSharedOperationSnapshotLeaseRecord, reason: String): Unit {
        if (!record.isActive()) {
            return
        }
        record.terminalReason = reason
        record.terminalAt = Some(this.clock.snapshotNow())
        if (let Some(handle) <- record.handle) {
            try {
                handle.release()
                record.handle = None
                record.cost = CjguiSharedOperationSnapshotRetentionCost(0, 0, 0)
                record.state = reason
            } catch (e: Exception) {
                record.state = "cleanup_pending"
                this.cleanupPending += 1
            }
        } else {
            record.state = reason
        }
    }

    /// Deferred cleanups still holding a real handle. The owner's close path
    /// reads this to decide whether a bounded drain is needed; a non-zero
    /// value after that drain is a real, reported failure state.
    func deferredCleanupCount(): Int64 {
        return this.cleanupPending
    }

    /// One sweep over deferred cleanups only (no expiry, no trim): the owner's
    /// bounded exit path retries failed releases here. Returns the remaining
    /// pending count; 0 means every handle was physically returned.
    func retryDeferredCleanupOnce(): Int64 {
        this.retryPendingCleanup()
        return this.cleanupPending
    }

    /// Periodic maintenance: expire by the hard deadline and retry any deferred
    /// cleanup. Called from the owner's dispatch path so an idle endpoint still
    /// reclaims leases without any network traffic.
    func purgeExpired(): Int64 {
        let now = this.clock.snapshotNow()
        var expired: Int64 = 0
        for (record in this.records) {
            if (record.isActive() && now >= record.expiresAt) {
                this.terminate(record, "snapshot_expired")
                expired += 1
            }
        }
        this.retryPendingCleanup()
        this.trimRetainedRecords()
        return expired
    }

    private func retryPendingCleanup(): Unit {
        for (record in this.records) {
            if (record.state == "cleanup_pending") {
                if (let Some(handle) <- record.handle) {
                    try {
                        handle.release()
                        record.handle = None
                        record.cost = CjguiSharedOperationSnapshotRetentionCost(0, 0, 0)
                        record.state = record.terminalReason
                        if (this.cleanupPending > 0) {
                            this.cleanupPending -= 1
                        }
                    } catch (e: Exception) {
                        // Still pending: the next owner maintenance tries again.
                    }
                } else {
                    record.state = record.terminalReason
                    if (this.cleanupPending > 0) {
                        this.cleanupPending -= 1
                    }
                }
            }
        }
    }

    /// Keep the record table bounded while leaving capacity RECOVERABLE. A
    /// terminal record stays answerable until its ORIGINAL hard deadline plus
    /// a bounded diagnostic window (idempotent requestId replay, first
    /// terminal reason): an early release never shortens that promise, so the
    /// same requestId cannot acquire a fresh lease of the same version while
    /// the original grant could still have been alive. After the window,
    /// maintenance recycles the oldest such record so a table at its retained
    /// limit can accept again. Active and `cleanup_pending` records are never
    /// dropped -- the latter still hold a real handle and are retried instead.
    /// A dropped token answers `snapshot_unknown` from then on (never a new
    /// read).
    private func trimRetainedRecords(): Unit {
        let now = this.clock.snapshotNow()
        while (Int64(this.records.size) >= this.limits.maxRetainedRecords) {
            var index: Int64 = 0
            var dropAt: Int64 = -1
            while (index < Int64(this.records.size)) {
                let candidate = this.records[index]
                // A cleanup_pending record still holds its handle: it is never
                // dropped, it is retried.
                if (!candidate.isActive() && candidate.state != "cleanup_pending") {
                    var elapsed = false
                    if (let Some(terminalAt) <- candidate.terminalAt) {
                        // Retention anchor is the LATER of the grant's own hard
                        // deadline and the moment the record became terminal.
                        var anchor = terminalAt
                        if (candidate.expiresAt > anchor) {
                            anchor = candidate.expiresAt
                        }
                        elapsed = now >= anchor + Duration.millisecond *
                            this.limits.terminalRetentionMs
                    }
                    if (elapsed) {
                        dropAt = index
                        break
                    }
                }
                index += 1
            }
            if (dropAt < 0) {
                return
            }
            this.records.remove(at: dropAt)
        }
    }

    /// Acquire one fixed snapshot. `expectedVersion < 0` means ANY (the
    /// provider takes the current version at THIS owner execution point).
    func acquire(
        provider: CjguiSharedOperationSnapshotProvider,
        endpointInstance: String,
        bindGeneration: Int64,
        grantId: String,
        authorizationEpoch: Int64,
        readScope: String,
        requestId: String,
        resourceId: Int64,
        expectedInstanceId: String,
        expectedVersion: Int64,
        ttlMs: Int64
    ): CjguiSharedOperationSnapshotLeaseOutcome {
        let signature = "${endpointInstance}|${bindGeneration}|${resourceId}|${expectedInstanceId}|" +
            "${expectedVersion}|${ttlMs}"
        if (requestId != "") {
            if (let Some(existing) <- this.findByRequestId(requestId)) {
                if (existing.acquireSignature != signature) {
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_request_conflict")
                }
                // Idempotent replay: the SAME lease, its ORIGINAL deadline, never
                // a fresh version.
                if (!existing.isActive()) {
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused(existing.terminalReason)
                }
                let remaining = this.remainingMs(existing)
                if (remaining <= 0) {
                    this.terminate(existing, "snapshot_expired")
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_expired")
                }
                return CjguiSharedOperationSnapshotLeaseOutcome.granted(
                    this.describe(existing, remaining), true)
            }
        }
        this.purgeExpired()
        if (Int64(this.records.size) >= this.limits.maxRetainedRecords) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_limit_exceeded")
        }
        if (this.activeCountForGrant(grantId) >= this.limits.maxActiveLeasesPerGrant) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_limit_exceeded")
        }
        if (this.activeCount() >= this.limits.maxActiveLeasesPerEndpoint) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_limit_exceeded")
        }
        if (expectedInstanceId != "" &&
            this.activeCountForResourceInstance(resourceId, expectedInstanceId) >=
            this.limits.maxActiveLeasesPerResourceInstance) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_limit_exceeded")
        }
        var grantedTtl = ttlMs
        if (grantedTtl <= 0) {
            grantedTtl = this.limits.defaultTtlMs
        }
        if (grantedTtl > this.limits.maxTtlMs) {
            grantedTtl = this.limits.maxTtlMs
        }
        let budget = CjguiSharedOperationSnapshotRetentionBudget(
            this.limits.maxResidentBytes - this.reservedResidentBytes(),
            this.limits.maxBackingBytes - this.reservedBackingBytes(),
            this.limits.maxOpenResources - this.reservedOpenResources())
        if (budget.residentBytes <= 0 || budget.backingBytes <= 0 || budget.openResources <= 0) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_budget_exceeded")
        }
        // The liveness probe runs BEFORE the handle exists: a closed resource
        // must not be resurrected by an acquire.
        let state = provider.snapshotResourceState(resourceId)
        if (state.isKnown && !state.isOpen) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_resource_closed")
        }
        if (state.isKnown && expectedInstanceId != "" && state.instanceId != expectedInstanceId) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_instance_mismatch")
        }
        let result = provider.acquireSnapshotFromExternal(resourceId, expectedInstanceId,
            expectedVersion, budget)
        if (!result.isAcquired) {
            return CjguiSharedOperationSnapshotLeaseOutcome.refused(
                if (result.reason == "") { "snapshot_provider_error" } else { result.reason })
        }
        if (let Some(handle) <- result.handle) {
            let info = handle.snapshotInfo()
            if (let Some(cost) <- result.cost) {
                if (cost.residentBytesUpperBound > budget.residentBytes ||
                    cost.backingBytesUpperBound > budget.backingBytes ||
                    cost.openResourceCountUpperBound > budget.openResources) {
                    releaseSnapshotHandleQuietly(handle)
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_budget_exceeded")
                }
                if (info.resourceId != resourceId || info.byteLength < 0 || info.version < 0) {
                    releaseSnapshotHandleQuietly(handle)
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_provider_error")
                }
                if (expectedInstanceId != "" && info.resourceInstanceId != expectedInstanceId) {
                    releaseSnapshotHandleQuietly(handle)
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_instance_mismatch")
                }
                if (expectedVersion >= 0 && info.version != expectedVersion) {
                    releaseSnapshotHandleQuietly(handle)
                    return CjguiSharedOperationSnapshotLeaseOutcome.refused("version_conflict")
                }
                let now = this.clock.snapshotNow()
                let record = CjguiSharedOperationSnapshotLeaseRecord(
                    this.newToken(endpointInstance, bindGeneration), endpointInstance,
                    bindGeneration, grantId, authorizationEpoch, readScope, resourceId,
                    info.resourceInstanceId, info.version, info.byteLength, requestId,
                    signature, now, now + Duration.millisecond * grantedTtl, cost, handle)
                this.records.add(record)
                return CjguiSharedOperationSnapshotLeaseOutcome.granted(
                    this.describe(record, grantedTtl), false)
            }
            releaseSnapshotHandleQuietly(handle)
            return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_provider_error")
        }
        return CjguiSharedOperationSnapshotLeaseOutcome.refused("snapshot_provider_error")
    }

    private func remainingMs(record: CjguiSharedOperationSnapshotLeaseRecord): Int64 {
        let now = this.clock.snapshotNow()
        if (now >= record.expiresAt) {
            return 0
        }
        return (record.expiresAt - now).toMilliseconds()
    }

    private func describe(record: CjguiSharedOperationSnapshotLeaseRecord,
        remaining: Int64): CjguiSharedOperationSnapshotLeaseDescription {
        return CjguiSharedOperationSnapshotLeaseDescription(record.token, record.endpointInstance,
            record.bindGeneration, record.resourceId, record.resourceInstanceId, record.fixedVersion,
            record.fixedByteLength, (record.expiresAt - record.createdAt).toMilliseconds(),
            remaining, this.limits.maxReadBytes, record.cost.residentBytesUpperBound,
            record.cost.backingBytesUpperBound)
    }

    /// Read one bounded range of a lease. Every failure is named; success
    /// echoes the token identity, the frozen version and the exact bytes.
    func read(
        token: String,
        start: Int64,
        end: Int64,
        endpointInstance: String,
        bindGeneration: Int64,
        authorizationEpoch: Int64
    ): CjguiSharedOperationRangeRead {
        let record = match (this.findRecord(token)) {
            case Some(found) => found
            case None => return CjguiSharedOperationRangeRead(false, false, 0, 0, start, end, "",
                "snapshot_unknown")
        }
        if (!record.isActive()) {
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", record.terminalReason)
        }
        if (record.authorizationEpoch != authorizationEpoch) {
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", "authorization_revoked")
        }
        if (record.endpointInstance != endpointInstance || record.bindGeneration != bindGeneration) {
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", "snapshot_endpoint_changed")
        }
        if (this.clock.snapshotNow() >= record.expiresAt) {
            this.terminate(record, "snapshot_expired")
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", "snapshot_expired")
        }
        if (start < 0 || end < start || end > record.fixedByteLength) {
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", "invalid_range")
        }
        if (end - start > this.limits.maxReadBytes) {
            return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
                start, end, "", "invalid_range")
        }
        if (let Some(handle) <- record.handle) {
            let read = handle.readRange(start, end)
            if (!read.isAvailable) {
                return read
            }
            // The handle read the FROZEN version: the live document moving on
            // during this read is not a conflict, and a provider that returns a
            // different version or a short read is a provider error.
            if (read.version != record.fixedVersion || read.resourceId != record.resourceId ||
                Int64(read.content.toArray().size) != end - start) {
                this.terminate(record, "snapshot_provider_error")
                return CjguiSharedOperationRangeRead(false, false, record.resourceId,
                    record.fixedVersion, start, end, "", "snapshot_provider_error")
            }
            record.readsServed += 1
            return CjguiSharedOperationRangeRead(true, false, record.resourceId, record.fixedVersion,
                start, end, read.content, "available")
        }
        return CjguiSharedOperationRangeRead(false, false, record.resourceId, record.fixedVersion,
            start, end, "", "snapshot_unknown")
    }

    /// Explicit release wins over the TTL. Releasing a known terminal lease is
    /// an idempotent cleanup receipt that does NOT change its reason.
    func release(token: String, endpointInstance: String, bindGeneration: Int64,
        authorizationEpoch: Int64): String {
        let record = match (this.findRecord(token)) {
            case Some(found) => found
            case None => return "snapshot_unknown"
        }
        if (record.endpointInstance != endpointInstance || record.bindGeneration != bindGeneration) {
            return "snapshot_endpoint_changed"
        }
        if (!record.isActive()) {
            return record.terminalReason
        }
        if (record.authorizationEpoch != authorizationEpoch) {
            this.terminate(record, "authorization_revoked")
            return "authorization_revoked"
        }
        this.terminate(record, "snapshot_released")
        return "snapshot_released"
    }

    /// Provider-driven invalidation: every lease of one resource INSTANCE ends
    /// named. Leases of the same resource id bound to an older instance stay
    /// terminal for their own reason.
    func invalidateResource(resourceId: Int64, resourceInstanceId: String, reason: String): Int64 {
        var invalidated: Int64 = 0
        for (record in this.records) {
            if (record.isActive() && record.resourceId == resourceId &&
                (resourceInstanceId == "" || record.resourceInstanceId == resourceInstanceId)) {
                this.terminate(record, reason)
                invalidated += 1
            }
        }
        return invalidated
    }

    /// Batch invalidation: workspace lifecycle end, authorization revocation,
    /// endpoint replacement. An empty reason falls back to a safe identifier.
    func invalidateAll(reason: String): Int64 {
        let effective = if (isSafeLeaseReason(reason)) { reason } else { "snapshot_workspace_changed" }
        var invalidated: Int64 = 0
        for (record in this.records) {
            if (record.isActive()) {
                this.terminate(record, effective)
                invalidated += 1
            }
        }
        return invalidated
    }

    /// Invalidate every lease bound to an authorization epoch older than the
    /// current one (revocation), without touching leases of the new grant.
    func invalidateEpochsBefore(epoch: Int64, reason: String): Int64 {
        var invalidated: Int64 = 0
        for (record in this.records) {
            if (record.isActive() && record.authorizationEpoch < epoch) {
                this.terminate(record, reason)
                invalidated += 1
            }
        }
        return invalidated
    }
}

private func sharedOperationLeaseHex16(value: UInt64): String {
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

func isSafeLeaseReason(value: String): Bool {
    if (value.size == 0 || value.size > 64) {
        return false
    }
    let bytes = value.toArray()
    var index: Int64 = 0
    while (index < Int64(bytes.size)) {
        let b = bytes[index]
        let isDigit = b >= 48 && b <= 57
        let isLower = b >= 97 && b <= 122
        let isUpper = b >= 65 && b <= 90
        if (!(isDigit || isLower || isUpper || b == 95)) {
            return false
        }
        index += 1
    }
    return true
}

/// A handle rejected during acquire was never published: release it now, and
/// never let a provider failure turn into a second failure of the framework.
private func releaseSnapshotHandleQuietly(handle: CjguiSharedOperationSnapshotHandle): Unit {
    try {
        handle.release()
    } catch (e: Exception) {
        return
    }
}
