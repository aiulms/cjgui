package cjgui_shared_operation_core

import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

// Fixed-snapshot lease contract counterexamples (E1, Astra 2026-09-28 order:
// counterexamples first). Every test drives the real dispatch path of a
// connection; the provider is a counting immutable-version stub and the clock
// is controllable, so expiry needs no sleeping.

private class SnapshotProbeCounters {
    var released: Int64 = 0
    var acquires: Int64 = 0
    /// E1: inject N failing `release()` calls (each throws), so the
    /// deferred-cleanup path (`cleanup_pending` → owner retry on a LATER beat)
    /// is observable even though one maintenance pass retries immediately.
    var failReleaseAttempts: Int64 = 0
}

private class SnapshotProbeHandle <: CjguiSharedOperationSnapshotHandle {
    private let resourceId: Int64
    private let instanceValue: String
    private let versionValue: Int64
    private let content: Array<UInt8>
    private let counters: SnapshotProbeCounters
    private let corruptMode: Int64

    init(resourceId: Int64, instanceValue: String, versionValue: Int64, content: Array<UInt8>,
        counters: SnapshotProbeCounters, corruptMode: Int64) {
        this.resourceId = resourceId
        this.instanceValue = instanceValue
        this.versionValue = versionValue
        this.content = content
        this.counters = counters
        this.corruptMode = corruptMode
    }

    public func snapshotInfo(): CjguiSharedOperationSnapshotInfo {
        return CjguiSharedOperationSnapshotInfo(this.resourceId, this.instanceValue,
            this.versionValue, Int64(this.content.size))
    }

    public func readRange(start: Int64, end: Int64): CjguiSharedOperationRangeRead {
        if (start < 0 || end < start || end > Int64(this.content.size)) {
            return CjguiSharedOperationRangeRead(false, false, this.resourceId, this.versionValue,
                start, end, "", "invalid_range")
        }
        var version = this.versionValue
        var sliceEnd = end
        if (this.corruptMode == 1) {
            // Short read: fewer bytes than the request span.
            sliceEnd = start
        }
        if (this.corruptMode == 2) {
            // Wrong version echo.
            version = this.versionValue + 1
        }
        let slice = this.content[start..sliceEnd]
        return CjguiSharedOperationRangeRead(true, false, this.resourceId, version, start, end,
            String.fromUtf8(slice), "available")
    }

    public func release(): Unit {
        if (this.counters.failReleaseAttempts > 0) {
            this.counters.failReleaseAttempts -= 1
            throw Exception("probe_release_failed_injected")
        }
        this.counters.released += 1
    }
}

private class SnapshotProbeProvider <: CjguiSharedOperationSnapshotProvider {
    let counters: SnapshotProbeCounters
    var version: Int64 = 1
    var text: String = "abcdefgh"
    var instanceValue: String = "doc7_ep1"
    var isOpen: Bool = true
    var overBudget: Bool = false
    var corruptMode: Int64 = 0

    init(counters: SnapshotProbeCounters) {
        this.counters = counters
    }

    public func acquireSnapshotFromExternal(resourceId: Int64, expectedInstanceId: String,
        expectedVersion: Int64, retentionBudget: CjguiSharedOperationSnapshotRetentionBudget
    ): CjguiSharedOperationSnapshotAcquireResult {
        this.counters.acquires += 1
        if (!this.isOpen) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_resource_closed")
        }
        if (expectedInstanceId != "" && expectedInstanceId != this.instanceValue) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("snapshot_instance_mismatch")
        }
        if (expectedVersion >= 0 && expectedVersion != this.version) {
            return CjguiSharedOperationSnapshotAcquireResult.refused("version_conflict")
        }
        let frozen = if (expectedVersion >= 0) { expectedVersion } else { this.version }
        let bytes = this.text.toArray()
        let cost = if (this.overBudget) {
            // A provider that cannot state a bound inside the reservation must
            // not be accepted: the framework checks the declared cost.
            CjguiSharedOperationSnapshotRetentionCost(retentionBudget.residentBytes + 1, 0, 0)
        } else {
            CjguiSharedOperationSnapshotRetentionCost(Int64(bytes.size), Int64(bytes.size), 1)
        }
        return CjguiSharedOperationSnapshotAcquireResult.acquired(
            SnapshotProbeHandle(resourceId, this.instanceValue, frozen, bytes, this.counters,
                this.corruptMode), cost)
    }

    public func snapshotResourceState(resourceId: Int64): CjguiSharedOperationSnapshotResourceState {
        if (!this.isOpen) {
            return CjguiSharedOperationSnapshotResourceState.closed(this.instanceValue)
        }
        return CjguiSharedOperationSnapshotResourceState.open(this.instanceValue)
    }
}

private class SnapshotProbeDomain <: CjguiSharedOperationDomain {
    public func resourceType(): String { return "snapshot_probe" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(1, "快照探针", resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(7101, "说明", ArrayList<CjguiSharedOperationField>())
            ]))
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 1, 1, "not_supported")
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 1, 1, "not_supported")
    }
}

private class SnapshotProbeClock <: CjguiSharedOperationSnapshotClock {
    private var current: MonoTime = MonoTime.now()

    func advance(milliseconds: Int64): Unit {
        this.current = this.current + Duration.millisecond * milliseconds
    }

    public func snapshotNow(): MonoTime {
        return this.current
    }
}

private let SNAPSHOT_PROBE_CAPABILITY = "snapshot-probe-capability"
private let SNAPSHOT_PROBE_RESOURCE: Int64 = 7101

private func snapshotProbeAuthorization(capability!: String = SNAPSHOT_PROBE_CAPABILITY,
    caller!: String = "快照读取者"): CjguiSharedOperationExternalAuthorization {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([SNAPSHOT_PROBE_RESOURCE]), false),
        CjguiSharedOperationExternalActionScope("SNAPSHOT_ACQUIRE", ArrayList<Int64>([SNAPSHOT_PROBE_RESOURCE]), false),
        CjguiSharedOperationExternalActionScope("SNAPSHOT_READ", ArrayList<Int64>([SNAPSHOT_PROBE_RESOURCE]), false),
        CjguiSharedOperationExternalActionScope("SNAPSHOT_RELEASE", ArrayList<Int64>([SNAPSHOT_PROBE_RESOURCE]), false)
    ])
    return CjguiSharedOperationExternalAuthorization(caller, capability, scopes)
}

/// E1(2026-09-28 复核):同 capability 重授必须具名拒绝——把被杀死的凭证原样装回
/// 等于复活被撤权的调用方。
private let SNAPSHOT_PROBE_CAPABILITY_B = "snapshot-probe-capability-b"

private func snapshotProbeRequest(command: String): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH ${SNAPSHOT_PROBE_CAPABILITY}\n${command}"
}

private func snapshotProbeRequestB(command: String): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH ${SNAPSHOT_PROBE_CAPABILITY_B}\n${command}"
}

private func snapshotProbeField(payload: String, name: String): String {
    for (line in payload.split("\n")) {
        if (line.startsWith(name + " ")) {
            return line[name.size + 1..line.size]
        }
    }
    return ""
}

private func snapshotProbeAcquire(connection: CjguiSharedOperationExternalConnection,
    endpoint: String, bind: Int64, requestId: String, instanceId: String, expectedVersion: String,
    ttlMs: Int64): String {
    return connection.dispatchPayload(snapshotProbeRequest(
        "SNAPSHOT_ACQUIRE ${endpoint} ${bind} ${requestId} ${SNAPSHOT_PROBE_RESOURCE} ${instanceId} " +
        "${expectedVersion} ${ttlMs}"))
}

/// Native transports dispatch the public payload without a Unix descriptor. A client must
/// discover the SAME endpoint nonce before acquiring a fixed version; restarting with resource
/// id 7101 is not permission to reuse the old nonce.
@Test
func snapshotLeaseContextPublishesCurrentEndpointIdentity(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider), true)
    let context = connection.dispatchPayload(snapshotProbeRequest("GET_CONTEXT 1\nID ${SNAPSHOT_PROBE_RESOURCE}"))
    @Assert(snapshotProbeField(context, "ENDPOINT_INSTANCE"), connection.endpointInstance())
    @Assert(snapshotProbeField(context, "ENDPOINT_BIND_GENERATION"), "${connection.endpointEpoch()}")
    let reopened = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(), snapshotProbeAuthorization())
    @Assert(reopened.enableSnapshotReads(provider), true)
    @Assert(reopened.endpointInstance() != connection.endpointInstance(), true)
    let refused = snapshotProbeAcquire(reopened, connection.endpointInstance(), connection.endpointEpoch(),
        "old-context", provider.instanceValue, "ANY", 60000)
    @Assert(refused.contains("snapshot_endpoint_changed"), true)
}

/// A lease holds ONE version: the same token keeps returning the frozen bytes
/// after the live document moves on, and a NEW acquire is what observes v2.
@Test
func snapshotLeaseKeepsItsFixedVersionWhileLiveContentMoves(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()

    let acquired = snapshotProbeAcquire(connection, endpoint, bind, "req-1", provider.instanceValue, "ANY", 60000)
    @Assert(acquired.contains("KIND SNAPSHOT_LEASE"), true)
    let token = snapshotProbeField(acquired, "TOKEN")
    @Assert(token.startsWith("s1_"), true)
    @Assert(snapshotProbeField(acquired, "VERSION"), "1")
    @Assert(snapshotProbeField(acquired, "BYTE_LENGTH"), "8")
    // The reservation is part of the receipt, not an unobservable provider detail. The probe
    // declares the frozen text's size as both resident and backing.
    @Assert(snapshotProbeField(acquired, "RESERVED_RESIDENT_BYTES"), "8")
    @Assert(snapshotProbeField(acquired, "RESERVED_BACKING_BYTES"), "8")

    // The live document advances; the lease must not follow it.
    provider.version = 2
    provider.text = "VERSION-TWO!"

    let frozen = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 8"))
    @Assert(frozen.contains("KIND RANGE"), true)
    @Assert(frozen.contains("AVAILABLE true"), true)
    @Assert(snapshotProbeField(frozen, "VERSION"), "1")
    @Assert(snapshotProbeField(frozen, "RESOURCE_INSTANCE") == "", true)
    @Assert(frozen.contains("CONTENT_UTF8_HEX 8 6162636465666768"), true)

    let fresh = snapshotProbeAcquire(connection, endpoint, bind, "req-2", provider.instanceValue, "ANY", 60000)
    @Assert(snapshotProbeField(fresh, "VERSION"), "2")
    let freshToken = snapshotProbeField(fresh, "TOKEN")
    let live = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${freshToken} 0 12"))
    @Assert(live.contains("CONTENT_UTF8_HEX 12 56455253494F4E2D54574F21"), true)
}

/// Releasing is idempotent, keeps the FIRST terminal reason, and the released
/// token never becomes readable again.
@Test
func snapshotReleaseIsIdempotentAndKeepsItsFirstReason(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-rel", provider.instanceValue, "ANY", 60000), "TOKEN")

    let released = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_RELEASE ${token}"))
    @Assert(released.contains("KIND SNAPSHOT_RELEASE"), true)
    @Assert(released.contains("REASON snapshot_released"), true)
    @Assert(counters.released, 1)

    let again = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_RELEASE ${token}"))
    @Assert(again.contains("REASON snapshot_released"), true)
    @Assert(counters.released, 1)

    // A terminated lease reads as the SAME range envelope with a named
    // reason, so one client parser covers both live and dead leases.
    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("KIND RANGE"), true)
    @Assert(read.contains("AVAILABLE false"), true)
    @Assert(read.contains("REASON snapshot_released"), true)
}

/// A lease that is never touched still expires on the owner clock, and the
/// handle is released at expiry without any client traffic.
@Test
func snapshotLeaseExpiresOnTheOwnerClockWithoutTraffic(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-ttl", provider.instanceValue, "ANY", 5000), "TOKEN")
    @Assert(counters.released, 0)

    clock.advance(6000)
    // The next dispatch (any request at all) runs owner maintenance first.
    let maintenance = snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-after", provider.instanceValue, "ANY", 5000)
    @Assert(maintenance.contains("KIND SNAPSHOT_LEASE"), true)
    @Assert(counters.released, 1)

    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("AVAILABLE false"), true)
    @Assert(read.contains("REASON snapshot_expired"), true)
}

/// Acquire retries: the same requestId returns the SAME lease and deadline;
/// different arguments under the same requestId are a named conflict.
@Test
func snapshotAcquireIsIdempotentPerRequestId(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()

    let first = snapshotProbeAcquire(connection, endpoint, bind, "req-same", provider.instanceValue, "ANY", 60000)
    let token = snapshotProbeField(first, "TOKEN")
    // The live document moves between the attempt and its retry.
    provider.version = 2
    provider.text = "second version"
    clock.advance(1000)
    let retry = snapshotProbeAcquire(connection, endpoint, bind, "req-same", provider.instanceValue, "ANY", 60000)
    @Assert(snapshotProbeField(retry, "TOKEN"), token)
    @Assert(snapshotProbeField(retry, "VERSION"), "1")
    @Assert(counters.acquires, 1)

    let conflict = snapshotProbeAcquire(connection, endpoint, bind, "req-same", provider.instanceValue, "2", 60000)
    @Assert(conflict.contains("ERROR snapshot_request_conflict"), true)
}

/// The per-resource-instance limit refuses the extra acquire and leaves every
/// existing lease readable.
@Test
func snapshotLeaseLimitsRefuseNewAcquiresWithoutDisturbingExistingLeases(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    let limits = CjguiSharedOperationSnapshotLeaseLimits(
        maxActiveLeasesPerGrant: 8,
        maxActiveLeasesPerResourceInstance: 2,
        maxActiveLeasesPerEndpoint: 8
    )
    @Assert(connection.enableSnapshotReads(provider, limits: limits, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()

    let first = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-a",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    let second = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-b",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    let refused = snapshotProbeAcquire(connection, endpoint, bind, "req-c", provider.instanceValue, "ANY", 60000)
    @Assert(refused.contains("ERROR snapshot_limit_exceeded"), true)

    let firstRead = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${first} 0 3"))
    @Assert(firstRead.contains("CONTENT_UTF8_HEX 3 616263"), true)
    let secondRead = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${second} 0 3"))
    @Assert(secondRead.contains("AVAILABLE true"), true)
}

/// Two leases of the SAME version are independent: releasing one leaves the
/// other readable, and the second lease's release is accounted separately.
@Test
func snapshotLeasesOfTheSameVersionReleaseIndependently(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()
    let first = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-x",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    let second = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-y",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    @Assert(first != second, true)

    let _ = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_RELEASE ${first}"))
    @Assert(counters.released, 1)
    let survivor = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${second} 0 4"))
    @Assert(survivor.contains("CONTENT_UTF8_HEX 4 61626364"), true)
    let _ = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_RELEASE ${second}"))
    @Assert(counters.released, 2)
}

/// A handle whose declared retention exceeds the reservation is refused and
/// released immediately: the budget is a reservation, not a promise.
@Test
func snapshotAcquireRefusesAHandleOverItsReservationBudget(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    provider.overBudget = true
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)

    let refused = snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-budget", provider.instanceValue, "ANY", 60000)
    @Assert(refused.contains("ERROR snapshot_budget_exceeded"), true)
    @Assert(counters.released, 1)
}

/// Resource invalidation ends every matching lease by name; a lease of another
/// resource instance is untouched.
@Test
func snapshotResourceInvalidationEndsMatchingLeasesByName(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()
    let token = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-close",
        provider.instanceValue, "ANY", 60000), "TOKEN")

    @Assert(connection.invalidateSnapshotResource(SNAPSHOT_PROBE_RESOURCE, provider.instanceValue,
        "snapshot_resource_closed"), 1)
    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("AVAILABLE false"), true)
    @Assert(read.contains("REASON snapshot_resource_closed"), true)
    @Assert(counters.released, 1)

    // A lease of a DIFFERENT instance of the same resource is not matched.
    provider.version = 3
    let other = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "req-other",
        "", "ANY", 60000), "TOKEN")
    @Assert(connection.invalidateSnapshotResource(SNAPSHOT_PROBE_RESOURCE, "doc7_ep2",
        "snapshot_resource_closed"), 0)
    let alive = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${other} 0 4"))
    @Assert(alive.contains("AVAILABLE true"), true)
}

/// A provider that echoes a wrong version or returns a short read terminates
/// its own lease with a named error; no partial content is ever returned.
@Test
func snapshotProviderShortReadBecomesANamedProviderError(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    provider.corruptMode = 1
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-short", provider.instanceValue, "ANY", 60000), "TOKEN")

    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("AVAILABLE false"), true)
    @Assert(read.contains("REASON snapshot_provider_error"), true)
    @Assert(counters.released, 1)
    let after = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(after.contains("REASON snapshot_provider_error"), true)
}

/// `-` means "no request id", not "a request id that happens to be a dash":
/// two otherwise identical acquires without one must take TWO snapshots.
@Test
func snapshotAcquireWithoutARequestIdTakesANewSnapshot(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()

    let first = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "-",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    let second = snapshotProbeField(snapshotProbeAcquire(connection, endpoint, bind, "-",
        provider.instanceValue, "ANY", 60000), "TOKEN")
    @Assert(first != second, true)
    @Assert(counters.acquires, 2)
    @Assert(connection.snapshotLeaseDiagnostics().contains("active=2"), true)
}

/// Closing the endpoint converges every lease: the framework owns the tokens,
/// so it must not leave an application handle alive after the socket is gone.
@Test
func snapshotEndpointCloseReleasesEveryHandle(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let _ = snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-close", provider.instanceValue, "ANY", 60000)
    @Assert(counters.released, 0)

    connection.close()
    @Assert(counters.released, 1)
    @Assert(connection.snapshotLeaseDiagnostics().contains("active=0"), true)
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=0"), true)
}

/// Identity binding: a request addressed to another endpoint instance is
/// refused before the provider is consulted.
@Test
func snapshotAcquireRefusesAForeignEndpointInstance(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)

    let foreignEndpoint = snapshotProbeAcquire(connection, "00000000000000000000000000000000", 1,
        "req-foreign", provider.instanceValue, "ANY", 60000)
    @Assert(foreignEndpoint.contains("ERROR snapshot_endpoint_changed"), true)
    @Assert(counters.acquires, 0)
}

/// Authorization lifecycle: revoking the grant (a new epoch) terminates every
/// lease of the old epoch, and a scope without a provider cannot start at all.
@Test
func snapshotCapabilityRequiresProviderAndAuthorizationEpoch(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()

    // Scope declared, provider absent: the endpoint must not even start.
    let bare = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(bare.start(), false)
    @Assert(bare.dispatchPayload(snapshotProbeRequest("GET_CONTEXT 1\nID 7101"))
        .contains("ERROR unauthorized_caller"), true)

    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-revoke", provider.instanceValue, "ANY", 60000), "TOKEN")
    @Assert(connection.revokeAuthorization(), 1)
    // E1 rework: a revoked authorization is DEAD at the dispatch gate -- the old
    // AUTH gets a named refusal for EVERY verb (it could otherwise acquire a
    // fresh lease under the new epoch, the hole this closes). The revoked lease
    // itself was still released and the table records zero active leases.
    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("ERROR authorization_revoked"), true)
    @Assert(counters.released, 1)
    @Assert(counters.acquires, 1)                    // no provider call on its behalf
    @Assert(connection.snapshotLeaseDiagnostics().contains("active=0"), true)
    @Assert(connection.snapshotLeaseDiagnostics().contains("authorization_revoked=true"), true)
}

/// The lease read is the SAME bounded range payload as READ_RANGE: the client
/// can use one parser, and a range outside the frozen length is refused.
@Test
func snapshotReadRefusesRangesOutsideTheFrozenLength(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-range", provider.instanceValue, "ANY", 60000), "TOKEN")

    let beyond = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 9"))
    @Assert(beyond.contains("AVAILABLE false"), true)
    @Assert(beyond.contains("REASON invalid_range"), true)
    let unknown = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ s1_nope 0 1"))
    @Assert(unknown.contains("AVAILABLE false"), true)
    @Assert(unknown.contains("REASON snapshot_unknown"), true)
    // The lease survives a refused range: it is still usable.
    let ok = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 1 3"))
    @Assert(ok.contains("CONTENT_UTF8_HEX 2 6263"), true)
}

// ---- E1 复核第 2 项（2026-09-28）：撤权生效 / 无流量回收 / 终态容量恢复 ----

/// 撤权是**真撤权**：同一 AUTH 在 revoke 之后 read/acquire/release/context 全部
/// 具名拒绝且 provider 零调用；显式重新授权后才有新 grant，旧 token 永不复活。
@Test
func revokedAuthorizationIsDeadUntilExplicitRegrant(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()
    let acquired = snapshotProbeAcquire(connection, endpoint, bind, "req-pre-revoke",
        provider.instanceValue, "ANY", 60000)
    let token = snapshotProbeField(acquired, "TOKEN")
    @Assert(token.startsWith("s1_"), true)
    let acquiresBefore = counters.acquires

    let revoked = connection.revokeAuthorization()
    @Assert(revoked, 1)                                // 那一笔租约按旧代次终结
    // 旧 AUTH 的每一类请求都被具名拒绝,provider 不再被调用。
    let read = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(read.contains("ERROR authorization_revoked"), true)
    let acquire = snapshotProbeAcquire(connection, endpoint, bind, "req-post-revoke",
        provider.instanceValue, "ANY", 60000)
    @Assert(acquire.contains("ERROR authorization_revoked"), true)
    let release = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_RELEASE ${token}"))
    @Assert(release.contains("ERROR authorization_revoked"), true)
    let context = connection.dispatchPayload(snapshotProbeRequest("GET_CONTEXT"))
    @Assert(context.contains("ERROR authorization_revoked"), true)
    @Assert(counters.acquires, acquiresBefore)         // 零 provider 调用
    @Assert(connection.snapshotLeaseDiagnostics().contains("authorization_revoked=true"), true)

    // 同一 capability 重授:具名拒绝,撤权状态保持。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization()), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    @Assert(connection.snapshotLeaseDiagnostics().contains("authorization_revoked=true"), true)
    let stillDead = snapshotProbeAcquire(connection, endpoint, bind, "req-post-recycle",
        provider.instanceValue, "ANY", 60000)
    @Assert(stillDead.contains("ERROR authorization_revoked"), true)

    // 显式重新授权(不同凭证):新能力 + 新代次,acquire 恢复;旧 token 仍按旧终态回答。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: SNAPSHOT_PROBE_CAPABILITY_B, caller: "快照读取者B")), true)
    @Assert(connection.lastGrantRefusalReason(), "")
    @Assert(connection.snapshotLeaseDiagnostics().contains("authorization_revoked=false"), true)
    // 旧 A 凭证不再匹配任何入口。
    let oldAuth = connection.dispatchPayload(snapshotProbeRequest("GET_CONTEXT"))
    @Assert(oldAuth.contains("ERROR unauthorized_caller"), true)
    let fresh = connection.dispatchPayload(snapshotProbeRequestB(
        "SNAPSHOT_ACQUIRE ${endpoint} ${bind} req-post-grant ${SNAPSHOT_PROBE_RESOURCE} " +
        "${provider.instanceValue} ANY 60000"))
    @Assert(fresh.contains("KIND SNAPSHOT_LEASE"), true)
    @Assert(counters.acquires, acquiresBefore + 1)
    // 旧 token 的终态应答要由**新凭证**读:它按撤销终态回答,永不复活。
    let oldRead = connection.dispatchPayload(
        snapshotProbeRequestB("SNAPSHOT_READ ${token} 0 4"))
    @Assert(oldRead.contains("AVAILABLE false"), true)
    @Assert(oldRead.contains("REASON authorization_revoked"), true)
}

/// E1 复核第 3 项：**同 connection 多轮授权**下,被撤权的凭证永远不能再装回。
/// 只记"最近一次被撤的 capability"时,A→revoke→close→grantB→revokeB→close→grantA
/// 会把 A 重新放行(B 的撤销覆盖了 A 的记录);旧凭证隔离按连接生命周期成立,
/// 不随中间插入的其他授权失效。
@Test
func revokedCredentialsStayDeadAcrossGrantRounds(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)

    // 第 1 轮:A 被撤权后关闭端点。
    let _ = connection.revokeAuthorization()
    connection.close()
    // 第 2 轮:合法的不同凭证 B 装上、被撤权、再关闭。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: SNAPSHOT_PROBE_CAPABILITY_B, caller: "快照读取者B")), true)
    let _ = connection.revokeAuthorization()
    connection.close()
    // A 已经是"被撤权的旧凭证",装回必须具名拒绝。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization()), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    // 拒绝后端点不得半授权:A 的请求仍然被拒,provider 零调用。
    let acquiresBefore = counters.acquires
    let denied = connection.dispatchPayload(snapshotProbeRequest("GET_CONTEXT"))
    @Assert(denied.contains("ERROR "), true)
    @Assert(counters.acquires, acquiresBefore)
    // 全新凭证 C 可正常授予;装上 C 之后 A 依旧被拒绝——拒绝不是"只在最新一轮有效"。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: "snapshot-probe-capability-c", caller: "快照读取者C")), true)
    @Assert(connection.lastGrantRefusalReason(), "")
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization()), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    @Assert(connection.snapshotLeaseDiagnostics().contains("revoked_credential_retained=2"), true)
    // 再走一轮(B 也是被撤权的旧凭证)后,A 仍拒绝。
    let _ = connection.revokeAuthorization()
    connection.close()
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: SNAPSHOT_PROBE_CAPABILITY_B, caller: "快照读取者B")), false)
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization()), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    @Assert(connection.snapshotLeaseDiagnostics().contains("revoked_credential_retained=3"), true)
    @Assert(connection.snapshotLeaseDiagnostics().contains("revoked_credential_evictions=0"), true)
}

/// 撤权历史是**有界**的:容量内逐条具名拒绝,超出容量时如实计数被挤出的记录,
/// 不把"忘掉了"说成永久隔离。这里用容量+2 次不同凭证的撤销,断言两条被挤出、
/// 容量内最新的那些仍然拒绝。
@Test
func revokedCredentialHistoryIsBoundedAndHonestlyCounted(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    // SNAPSHOT_* 作用域只有在 provider 装上后才可见,否则授权本身被判 invalid。
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let cap = connection.revokedCredentialRetentionCapacity()
    @Assert(cap > 0, true)
    var index: Int64 = 0
    var olderEvictedCredentials = ArrayList<String>()
    // 每一轮的授予都必须成功(否则判定点记下第一个失败轮次,便于定位)。
    var firstRefusedRound: Int64 = -1
    var firstRefusedReason = ""
    while (index < cap + 2) {
        let capability = "snapshot-probe-capability-${index}"
        if (connection.grantAuthorization(snapshotProbeAuthorization(
            capability: capability, caller: "快照读取者${index}"))) {
            let _ = connection.revokeAuthorization()
            connection.close()
        } else if (firstRefusedRound < 0) {
            firstRefusedRound = index
            firstRefusedReason = connection.lastGrantRefusalReason()
        }
        if (index < 2) {
            olderEvictedCredentials.add(capability)
        }
        index += 1
    }
    @Assert(firstRefusedRound, -1)
    @Assert(firstRefusedReason, "")
    @Assert(connection.revokedCredentialEvictionCount(), 2)
    // 容量内(最近 cap 条)仍然拒绝;被挤出的两条按记账不再声称隔离。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: "snapshot-probe-capability-${cap + 1}", caller: "快照读取者")), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: olderEvictedCredentials[0], caller: "快照读取者")), true)
    @Assert(connection.snapshotLeaseDiagnostics().contains("revoked_credential_evictions=2"), true)
}

/// E1 复核第 2 项：**重装 provider 不得丢掉旧清理责任**。持续失败的 release 让旧
/// table 仍真实持有句柄（`cleanup_pending=1`）时,`enableSnapshotReads` 必须具名
/// 拒绝而非覆盖旧 table；清理在后续节拍成功后,重装才被接受,新表可以正常服务。
@Test
func reinstallRefusesWhileTheOldTableStillHoldsCleanup(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-reinstall", provider.instanceValue, "ANY", 5000), "TOKEN")
    clock.advance(6000)
    // 持续失败:close 的有界追加清扫也没能拿回句柄。
    counters.failReleaseAttempts = 64
    connection.close()
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=1"), true)

    let replacementCounters = SnapshotProbeCounters()
    let replacement = SnapshotProbeProvider(replacementCounters)
    @Assert(connection.enableSnapshotReads(replacement, clock: clock), false)
    @Assert(connection.lastSnapshotEnableRefusalReason(), "snapshot_reinstall_pending_cleanup")
    // 旧持有仍在框架账上,没有被新表 diagnostics=0 掩盖。
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=1"), true)
    @Assert(counters.released, 0)
    // 旧 token 也不会因为"重装"变成新表里的未知:旧 table 仍在,它照旧按自己
    // 的终态回答(若是被覆盖,新表只会答 snapshot_unknown)。
    let afterRefusal = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(afterRefusal.contains("AVAILABLE false"), true)
    @Assert(afterRefusal.contains("REASON snapshot_unknown"), false)
    @Assert(afterRefusal.contains("REASON snapshot_endpoint_closed"), true)

    // 停止失败注入,后续维护节拍把旧句柄真正释放;此后重装被接受。
    counters.failReleaseAttempts = 0
    let _ = connection.pump(0u32)
    @Assert(counters.released, 1)
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=0"), true)
    @Assert(connection.enableSnapshotReads(replacement, clock: clock), true)
    @Assert(connection.lastSnapshotEnableRefusalReason(), "")
    let fresh = snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
        "req-reinstalled", replacement.instanceValue, "ANY", 60000)
    @Assert(fresh.contains("KIND SNAPSHOT_LEASE"), true)
    @Assert(replacementCounters.acquires, 1)
}

/// 无流量也回收：硬期限到达由 owner 维护节拍（pump,无任何客户端流量）终结并释放
/// handle；注入一次 release 失败落入 `cleanup_pending`（资源仍计数,不谎报清零），
/// 下一个节拍重试成功后归零收敛。
@Test
func idleEndpointReclaimsLeasesOnTheOwnerBeat(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-idle", provider.instanceValue, "ANY", 5000), "TOKEN")
    @Assert(counters.released, 0)

    clock.advance(6000)
    // 首个节拍:到期终结;注入的 release 失败(含同拍的立即重试)⇒ cleanup_pending,
    // 仍持有资源。两次失败让"同拍重试"与"下拍重试"两条路径都可判别。
    counters.failReleaseAttempts = 2
    let beatOne = connection.pump(0u32)
    @Assert(beatOne, false)                            // 没有客户端被服务,纯维护
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=1"), true)
    @Assert(counters.released, 0)                      // 未释放时不得报告清零
    let dead = connection.dispatchPayload(snapshotProbeRequest("SNAPSHOT_READ ${token} 0 4"))
    @Assert(dead.contains("REASON snapshot_expired"), true)

    // 第二个节拍:延迟清理重试成功,计数收敛为 0。
    let beatTwo = connection.pump(0u32)
    @Assert(beatTwo, false)
    @Assert(counters.released, 1)
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=0"), true)
}

/// 终态容量可恢复：表满时已终结记录在自己的有界诊断窗口内保持幂等应答并占用容量；
/// 窗口过后维护回收槽位,acquire 再次成功,存活租约不受损。
@Test
func terminalRecordsRecycleCapacityAfterTheirBoundedWindow(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    let limits = CjguiSharedOperationSnapshotLeaseLimits(maxRetainedRecords: 2,
        terminalRetentionMs: 1000)
    @Assert(connection.enableSnapshotReads(provider, limits: limits, clock: clock), true)
    let endpoint = connection.endpointInstance()
    let bind = connection.endpointEpoch()

    let first = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-1",
        provider.instanceValue, "ANY", 2000)
    @Assert(first.contains("KIND SNAPSHOT_LEASE"), true)
    // 第二笔用长 TTL:它是"存活租约不受损"的证人,不能跟着到期。
    let second = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-2",
        provider.instanceValue, "ANY", 600000)
    @Assert(second.contains("KIND SNAPSHOT_LEASE"), true)
    let liveToken = snapshotProbeField(second, "TOKEN")

    // 释放第一笔:表满(2/2)。硬期限(创建+2000ms)+诊断窗口之前,记录必须保留:
    // 同 requestId 幂等应答原终态,新 acquire 被诚实的容量拒绝——不能把幂等承诺
    // 缩短成"提前释放即可重取"。
    let released = connection.dispatchPayload(
        snapshotProbeRequest("SNAPSHOT_RELEASE ${snapshotProbeField(first, "TOKEN")}"))
    @Assert(released.contains("REASON snapshot_released"), true)
    clock.advance(1500)                                        // 未到硬期限(2000ms)
    let beforeDeadline = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-3",
        provider.instanceValue, "ANY", 60000)
    @Assert(beforeDeadline.contains("ERROR snapshot_limit_exceeded"), true)
    let replayEarly = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-1",
        provider.instanceValue, "ANY", 2000)
    @Assert(replayEarly.contains("ERROR snapshot_released"), true)   // 幂等:原终态应答

    // 硬期限(2000ms)已过、诊断窗口(1000ms)未满:承诺仍在,容量未回收。
    clock.advance(1000)                                        // 累计 2500ms
    let stillHeld = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-4",
        provider.instanceValue, "ANY", 60000)
    @Assert(stillHeld.contains("ERROR snapshot_limit_exceeded"), true)
    let replayAtDeadline = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-1",
        provider.instanceValue, "ANY", 2000)
    @Assert(replayAtDeadline.contains("ERROR snapshot_released"), true)

    // 硬期限+诊断窗口(3000ms)之后:维护回收容量,新 acquire 成功;存活租约精确读回。
    clock.advance(1000)                                        // 累计 3500ms
    let recovered = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-5",
        provider.instanceValue, "ANY", 60000)
    @Assert(recovered.contains("KIND SNAPSHOT_LEASE"), true)
    let stillLive = connection.dispatchPayload(
        snapshotProbeRequest("SNAPSHOT_READ ${liveToken} 0 8"))
    @Assert(stillLive.contains("AVAILABLE true"), true)
    @Assert(stillLive.contains("CONTENT_UTF8_HEX 8 6162636465666768"), true)
    // 窗口外的旧 requestId 不再走幂等应答:记录已被回收,此刻表满,它得到的是
    // 当前的容量拒绝(而非旧的 snapshot_released 应答)—— 两条路径可判别。
    let afterWindow = snapshotProbeAcquire(connection, endpoint, bind, "req-cap-1",
        provider.instanceValue, "ANY", 60000)
    @Assert(!afterWindow.contains("snapshot_released"), true)
    @Assert(afterWindow.contains("ERROR snapshot_limit_exceeded"), true)
}

/// 正常退出的清理执行者:主循环结束后没有 owner pump,close() 自己是最后一个
/// owner 安全点。注入两次释放失败,第三次(关闭路径的有界清扫)成功——资源真实归还;
/// 持续失败时保留真实计账,不丢引用、不谎报清零。
@Test
func closeDrainsDeferredReleasesAtTheLastOwnerSafePoint(): Unit {
    // 场景一:失败两次,第三次成功。
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    @Assert(connection.start(), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-close-drain", provider.instanceValue, "ANY", 60000), "TOKEN")
    clock.advance(61000)                               // 硬期限到点
    counters.failReleaseAttempts = 2                   // 到期释放失败 + 维护重试失败
    connection.pump(0u32)
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=1"), true)
    @Assert(counters.released, 0)
    // 正常关闭:close 内的有界清扫第三次尝试成功,退出前资源归还、计账归零。
    connection.close()
    @Assert(counters.released, 1)
    @Assert(connection.snapshotLeaseDiagnostics().contains("cleanup_pending=0"), true)

    // 场景二:持续失败——有界退出后保留真实失败状态,可读、不零报。
    let counters2 = SnapshotProbeCounters()
    let provider2 = SnapshotProbeProvider(counters2)
    let clock2 = SnapshotProbeClock()
    let failing = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(failing.enableSnapshotReads(provider2, clock: clock2), true)
    @Assert(failing.start(), true)
    let token2 = snapshotProbeField(
        snapshotProbeAcquire(failing, failing.endpointInstance(), failing.endpointEpoch(),
            "req-close-stuck", provider2.instanceValue, "ANY", 60000), "TOKEN")
    clock2.advance(61000)
    counters2.failReleaseAttempts = 99                 // 关闭清扫也无法成功
    failing.close()
    @Assert(counters2.released, 0)
    let diag = failing.snapshotLeaseDiagnostics()
    @Assert(diag.contains("cleanup_pending=1"), true)  // 真实计账保留,不谎报清零
}

/// 第二消费者生命周期:A 凭证→revoke→close→grant B→重新发布——旧 A 全面拒绝且
/// provider 不被调用,新 B 可用,旧 token 终态不复活。
@Test
func secondConsumerLifecycleIsolatesCredentialsAcrossRegrant(): Unit {
    let counters = SnapshotProbeCounters()
    let provider = SnapshotProbeProvider(counters)
    let clock = SnapshotProbeClock()
    let connection = CjguiSharedOperationExternalConnection(SnapshotProbeDomain(),
        snapshotProbeAuthorization())
    @Assert(connection.enableSnapshotReads(provider, clock: clock), true)
    @Assert(connection.start(), true)
    let token = snapshotProbeField(
        snapshotProbeAcquire(connection, connection.endpointInstance(), connection.endpointEpoch(),
            "req-lifecycle-a", provider.instanceValue, "ANY", 60000), "TOKEN")
    @Assert(token.startsWith("s1_"), true)
    let acquiresA = counters.acquires

    @Assert(connection.revokeAuthorization(), 1)
    connection.close()
    // 同 A 凭证重授被具名拒绝;B 凭证成功并重新发布。
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization()), false)
    @Assert(connection.lastGrantRefusalReason(), "authorization_credential_recycled")
    @Assert(connection.grantAuthorization(snapshotProbeAuthorization(
        capability: SNAPSHOT_PROBE_CAPABILITY_B, caller: "快照读取者B")), true)
    @Assert(connection.start(), true)

    // 旧 A:每一动词拒绝(能力不匹配),provider 不被调用。
    let aContext = connection.dispatchPayload(snapshotProbeRequest("GET_CONTEXT"))
    @Assert(aContext.contains("ERROR unauthorized_caller"), true)
    let aAcquire = snapshotProbeAcquire(connection, connection.endpointInstance(),
        connection.endpointEpoch(), "req-lifecycle-a2", provider.instanceValue, "ANY", 60000)
    @Assert(aAcquire.contains("ERROR unauthorized_caller"), true)
    @Assert(counters.acquires, acquiresA)
    // 旧 token:由 B 读到撤销终态,永不复活。
    let oldToken = connection.dispatchPayload(
        snapshotProbeRequestB("SNAPSHOT_READ ${token} 0 4"))
    @Assert(oldToken.contains("AVAILABLE false"), true)
    @Assert(oldToken.contains("REASON authorization_revoked"), true)
    // 新 B:acquire 真实可用。
    let bAcquire = connection.dispatchPayload(snapshotProbeRequestB(
        "SNAPSHOT_ACQUIRE ${connection.endpointInstance()} ${connection.endpointEpoch()} " +
        "req-lifecycle-b ${SNAPSHOT_PROBE_RESOURCE} ${provider.instanceValue} ANY 60000"))
    @Assert(bAcquire.contains("KIND SNAPSHOT_LEASE"), true)
    @Assert(counters.acquires, acquiresA + 1)
    connection.close()
}
