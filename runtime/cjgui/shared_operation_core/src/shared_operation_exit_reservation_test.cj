package cjgui_shared_operation_core

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*
import std.net.*
import std.sync.*
import std.time.*

@Test
func exitReservationRetainsClaimedLeaseAndRejectsOnlyDuringAttempt(): Unit {
    let state = CjguiSharedOperationIoState()
    let original = CjguiSharedOperationPendingClientRequest("original")
    let lease = state.tryQueueRequest(original).getOrThrow()
    @Assert(state.tryReserveExit(), false)
    @Assert(original.claimForOwner(), true)
    state.releaseReadyCharge(lease)
    // Ready accounting is zero but the original claimed request still owns
    // its reply. It cannot be hidden from the exit reservation.
    @Assert(state.tryReserveExit(), false)
    @Assert(original.complete("original-result"), true)
    state.finishPendingRequest(lease)
    @Assert(state.tryReserveExit(), true)
    let during = CjguiSharedOperationPendingClientRequest("during")
    @Assert(state.tryQueueRequest(during).isNone(), true)
    @Assert(during.exitReservationRejected, true)
    state.finishExitRejection(during)
    state.releaseExitReservation()
    let after = CjguiSharedOperationPendingClientRequest("after")
    @Assert(state.tryQueueRequest(after).isSome(), true)
    state.stop()
}

private class ExitReservationSocketDomain <: CjguiSharedOperationDomain {
    let entered = AtomicInt64(0)
    let release = AtomicInt64(0)
    let calls = AtomicInt64(0)
    public func resourceType(): String { return "exit_reservation_fixture" }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        if (calls.fetchAdd(1) == 0) {
            let _ = entered.fetchAdd(1)
            let deadline = MonoTime.now() + 3 * Duration.second
            while (release.load() == 0 && MonoTime.now() < deadline) {
                sleep(Duration.millisecond)
            }
        }
        return CjguiSharedOperationContextSnapshot(1, "exit reservation socket", resourceType(),
            ArrayList<CjguiSharedOperationResource>())
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

private func exitReservationSocketRequest(path: String): String {
    let payload = "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH exit-reservation-capability\nGET_CONTEXT 0"
    try (client = UnixSocket(path)) {
        client.connect()
        client.readTimeout = Some(Duration.second * 3)
        client.write(CjguiSharedOperationFrame.encode(payload))
        let decoder = CjguiSharedOperationFrameAccumulator()
        while (true) {
            let bytes = Array<Byte>(4096, repeat: 0)
            let count = client.read(bytes)
            if (count <= 0) { return "" }
            let frame = decoder.append(bytes, count)
            if (frame.isMalformed) { return "" }
            if (frame.isComplete) { return frame.payload }
        }
    } catch (_: Exception) { return "" }
    return ""
}

// A real private endpoint, original socket frames and the production owner
// claim/response path. This is controlled transport testing, not an App UI.
@When[os == "macOS"]
@Test
func exitReservationPreservesRealClaimAndRejectsCompleteSocketRequest(): Unit {
    let domain = ExitReservationSocketDomain()
    let authorization = CjguiSharedOperationExternalAuthorization("exit-reservation-client",
        "exit-reservation-capability", ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)]))
    let connection = CjguiSharedOperationExternalConnection(domain, authorization)
    @Assert(connection.start(), true)
    try {
        let path = connection.connectionInfo().getOrThrow().socketPath
        let first = spawn { => exitReservationSocketRequest(path) }
        let pump = spawn { =>
            let deadline = MonoTime.now() + 2 * Duration.second
            var dispatched = false
            while (!dispatched && MonoTime.now() < deadline) {
                dispatched = connection.pump(0u32)
                if (!dispatched) { sleep(Duration.millisecond) }
            }
            dispatched
        }
        let deadline = MonoTime.now() + 2 * Duration.second
        while (domain.entered.load() == 0 && MonoTime.now() < deadline) {
            sleep(Duration.millisecond)
        }
        let claimedReachedOwner = domain.entered.load() == 1
        let reservedWhileClaimed = connection.tryReserveApplicationExit()
        if (reservedWhileClaimed) { connection.releaseApplicationExitReservation() }
        let _ = domain.release.fetchAdd(1)
        let dispatched = pump.get()
        let firstResponse = first.get()
        @Assert(claimedReachedOwner, true)
        @Assert(reservedWhileClaimed, false)
        @Assert(dispatched, true)
        @Assert(firstResponse.contains("KIND SNAPSHOT"), true)

        let reserveDeadline = MonoTime.now() + 2 * Duration.second
        var reserved = false
        while (!reserved && MonoTime.now() < reserveDeadline) {
            reserved = connection.tryReserveApplicationExit()
            if (!reserved) { sleep(Duration.millisecond) }
        }
        @Assert(reserved, true)
        let during = spawn { => exitReservationSocketRequest(path) }
        let busyResponse = during.get()
        @Assert(busyResponse.contains("server_busy"), true)
        connection.releaseApplicationExitReservation()

        let after = spawn { => exitReservationSocketRequest(path) }
        let afterDeadline = MonoTime.now() + 2 * Duration.second
        var afterDispatched = false
        while (!afterDispatched && MonoTime.now() < afterDeadline) {
            afterDispatched = connection.pump(0u32)
            if (!afterDispatched) { sleep(Duration.millisecond) }
        }
        let afterResponse = after.get()
        @Assert(afterDispatched, true)
        @Assert(afterResponse.contains("KIND SNAPSHOT"), true)
    } finally {
        let _ = domain.release.fetchAdd(1)
        connection.releaseApplicationExitReservation()
        connection.close()
    }
}
