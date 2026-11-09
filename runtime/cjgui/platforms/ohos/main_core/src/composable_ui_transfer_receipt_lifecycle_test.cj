package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class ReceiptLifecycleController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "receipt-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "receipt-target", "Target", "PRESS", 0,
            CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 32)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func transferReceiptSessionRestartKeepsIndependentEventOne(): Unit {
    let window = CjguiComposableUiWindow(ReceiptLifecycleController())
    @Assert(window.start(), true)
    let firstSession = window.windowProgress().sessionIdentity
    let node = CjguiComposableUiLayoutNode.missing()
    @Assert(window.beginTransferReceipt(firstSession, 1u64, 1u64, 49, node, 1u64,
        "local_file_url", 0, "reading"), "admitted")
    window.close()
    let first = window.transferReceipt(firstSession, 1u64)
    @Assert(first.state, "found")
    if (let Some(value) <- first.receipt) {
        @Assert(value.state, "cancelled")
        @Assert(value.reason, "window_closed")
    } else { @Assert(false, true) }
    @Assert(window.start(), true)
    let secondSession = window.windowProgress().sessionIdentity
    @Assert(secondSession != firstSession, true)
    @Assert(window.beginTransferReceipt(secondSession, 1u64, 1u64, 49, node, 1u64,
        "local_file_url", 0, "reading"), "admitted")
    @Assert(window.transferReceipt(firstSession, 1u64).state, "found")
    @Assert(window.transferReceipt(secondSession, 1u64).state, "found")
    window.close()
}

@Test
func transferReceiptPinsReadingAcrossLaterTerminalEviction(): Unit {
    let window = CjguiComposableUiWindow(ReceiptLifecycleController())
    @Assert(window.start(), true)
    let session = window.windowProgress().sessionIdentity
    let node = CjguiComposableUiLayoutNode.missing()
    @Assert(window.beginTransferReceipt(session, 1u64, 1u64, 49, node, 1u64,
        "local_file_url", 0, "reading"), "admitted")
    var eventId = 2u64
    while (eventId <= 66u64) {
        @Assert(window.beginTransferReceipt(session, eventId, eventId, 49, node, 1u64,
            "external_pasteboard", 0, "queued"), "admitted")
        window.settleTransferReceipt(session, eventId, "rejected", "png_invalid", "", None)
        eventId += 1u64
    }
    @Assert(window.transferReceipt(session, 1u64).state, "found")
    @Assert(window.transferReceipt(session, 2u64).state, "expired")
    @Assert(window.transferReceipt(session, 999u64).state, "unknown")
    @Assert(window.beginTransferReceipt(session, 3u64, 3u64, 49, node, 1u64,
        "local_file_url", 0, "queued"), "replayed")
    window.settleTransferReceipt(session, 1u64, "rejected", "file_changed_during_read", "", None)
    if (let Some(value) <- window.transferReceipt(session, 1u64).receipt) {
        @Assert(value.state, "rejected")
        @Assert(value.reason, "file_changed_during_read")
    } else { @Assert(false, true) }
    window.close()
}

@Test
func transferReceiptAllowsLateFirstDeliveryWithLowerEventId(): Unit {
    let window = CjguiComposableUiWindow(ReceiptLifecycleController())
    @Assert(window.start(), true)
    let session = window.windowProgress().sessionIdentity
    let node = CjguiComposableUiLayoutNode.missing()
    @Assert(window.beginTransferReceipt(session, 10u64, 1u64, 49, node, 1u64,
        "external_pasteboard", 0, "queued"), "admitted")
    // Native's fallback terminal queue may release event 2 after event 10;
    // first-dequeue ordinal 2 means it has never been handled before.
    @Assert(window.beginTransferReceipt(session, 2u64, 2u64, 49, node, 1u64,
        "local_file_url", 0, "queued"), "admitted")
    @Assert(window.transferReceipt(session, 2u64).state, "found")
    window.close()
}

@Test
func transferReceiptRefusesBeforeOwnerWhenActiveBudgetIsFull(): Unit {
    let window = CjguiComposableUiWindow(ReceiptLifecycleController())
    @Assert(window.start(), true)
    let session = window.windowProgress().sessionIdentity
    let node = CjguiComposableUiLayoutNode.missing()
    var eventId = 1u64
    while (eventId <= 63u64) {
        @Assert(window.beginTransferReceipt(session, eventId, eventId, 49, node, 1u64,
            "local_file_url", 0, "reading"), "admitted")
        eventId += 1u64
    }
    @Assert(window.beginTransferReceipt(session, 64u64, 64u64, 49, node, 1u64,
        "external_pasteboard", 0, "queued"), "capacity_rejected")
    if (let Some(value) <- window.transferReceipt(session, 64u64).receipt) {
        @Assert(value.state, "rejected")
        @Assert(value.reason, "receipt_capacity_exceeded")
        @Assert(value.ownerAttempted, false)
    } else { @Assert(false, true) }
    let revision = window.transferReceiptChanges(session, 0, 64).revision
    @Assert(window.beginTransferReceipt(session, 64u64, 64u64, 49, node, 1u64,
        "external_pasteboard", 0, "queued"), "existing")
    @Assert(window.transferReceiptChanges(session, 0, 64).revision, revision)
    window.settleTransferReceipt(session, 1u64, "rejected", "file_cancelled", "", None)
    @Assert(window.beginTransferReceipt(session, 65u64, 65u64, 49, node, 1u64,
        "external_pasteboard", 0, "queued"), "admitted")
    window.close()
}

@Test
func transferReceiptSupersededOwnerSettlesOnceAcrossLaterFrames(): Unit {
    let window = CjguiComposableUiWindow(ReceiptLifecycleController())
    @Assert(window.start(), true)
    let session = window.windowProgress().sessionIdentity
    var target = CjguiComposableUiLayoutNode.missing()
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "receipt-target") { target = node }
    }
    @Assert(target.semanticId, "receipt-target")
    @Assert(window.beginTransferReceipt(session, 1u64, 1u64, 49, target, 7u64,
        "local_file_url", 0, "queued"), "admitted")
    let accepted = CjguiSharedOperationTransferResult(true, false, 0, 1,
        "BINARY", "image/png", "applied")
    window.settleTransferReceipt(session, 1u64, "owner_accepted", "applied", "digest-v1", Some(accepted))
    let bindings = ArrayList<CjguiComposableUiDataTransferBinding>()
    bindings.add(CjguiComposableUiDataTransferBinding(
        CjguiComposableUiDataTransferDeclaration.target("receipt-target",
            CjguiSharedOperationTransferFormat.png()), target, "image/png", 7u64, 2))
    window.settleTransferSceneReceipts(bindings, 5, 9)
    let first = window.transferReceipt(session, 1u64)
    @Assert(first.state, "found")
    if (let Some(value) <- first.receipt) {
        @Assert(value.state, "owner_accepted")
        @Assert(value.reason, "superseded_before_scene")
        @Assert(value.ownerAttempted, true)
        @Assert(value.ownerVersionBefore, 0)
        @Assert(value.ownerVersionAfter, 1)
        @Assert(value.acceptedSceneVersion, -1)
        @Assert(value.submittedFrameIndex, -1)
    } else { @Assert(false, true) }
    let revision = if (let Some(value) <- first.receipt) { value.revision } else { -1 }
    window.settleTransferSceneReceipts(bindings, 6, 10)
    window.settleTransferSceneReceipts(bindings, 7, 11)
    let repeated = window.transferReceipt(session, 1u64)
    @Assert(if (let Some(value) <- repeated.receipt) { value.revision } else { -1 }, revision)
    window.close()
}
