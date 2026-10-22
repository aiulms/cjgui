package cjgui_shared_operation_core

import std.sync.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

// A claimed owner request has no polling deadline. The existing queue must
// deliver its original completion, even when the owner takes more than 8ms.
@Test
func claimedReplyWaitsForOriginalCompletion(): Unit {
    let request = CjguiSharedOperationPendingClientRequest("original-request")
    @Assert(request.claimForOwner(), true)
    let entered = Barrier(2)
    let worker = spawn { => entered.wait(); request.waitForResponse() }
    entered.wait()
    sleep(Duration.millisecond * 40)
    @Assert(request.complete("original-response"), true)
    @Assert(worker.get().getOrThrow(), "original-response")
}

@Test
func ownerNotificationCoalescesAndRunsOutsideQueueLock(): Unit {
    let state = CjguiSharedOperationIoState()
    let calls = AtomicInt64(0)
    state.setOwnerWorkNotifier(Some({ =>
        let _ = state.diagnostics()
        let _ = calls.fetchAdd(1)
    }))
    let _ = state.tryQueueRequest(CjguiSharedOperationPendingClientRequest("one"))
    let _ = state.tryQueueRequest(CjguiSharedOperationPendingClientRequest("two"))
    @Assert(calls.load(), 1)
    let _ = state.readyBatch(0u32)
    let _ = state.tryQueueRequest(CjguiSharedOperationPendingClientRequest("three"))
    @Assert(calls.load(), 2)
    state.setOwnerWorkNotifier(None)
    state.stop()
    @Assert(state.tryQueueRequest(CjguiSharedOperationPendingClientRequest("late")).isNone(), true)
    @Assert(calls.load(), 2)
}

@Test
func stopWakesIdleIoAndClaimedResponseWaiters(): Unit {
    let state = CjguiSharedOperationIoState()
    let entered = Barrier(2)
    let worker = spawn { => entered.wait(); state.takeAcceptedClient() }
    entered.wait()
    state.stop()
    @Assert(worker.get().isNone(), true)
    let request = CjguiSharedOperationPendingClientRequest("cancel-original")
    @Assert(request.claimForOwner(), true)
    let responseWorker = spawn { => request.waitForResponse() }
    request.cancel()
    @Assert(responseWorker.get().isNone(), true)
}

@Test
func notifierInstalledAfterArrivalObservesPendingWork(): Unit {
    let state = CjguiSharedOperationIoState()
    let _ = state.tryQueueRequest(CjguiSharedOperationPendingClientRequest("before-install"))
    let calls = AtomicInt64(0)
    state.setOwnerWorkNotifier(Some({ => let _ = calls.fetchAdd(1) }))
    @Assert(calls.load(), 1)
    state.stop()
    @Assert(calls.load(), 2)
}
