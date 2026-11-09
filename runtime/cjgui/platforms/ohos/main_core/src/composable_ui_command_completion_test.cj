package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func ownerReceiptChoice(revision: Int64, version!: Int64 = 3, anchor!: Int64 = 8,
    focus!: Int64 = 8, document!: String = "receipt-document", epoch!: Int64 = 2): CjguiSourceSelectionSnapshot {
    return CjguiSourceSelectionSnapshot(version, revision, anchor, focus, documentId: document, sessionEpoch: epoch)
}
private func ownerReceiptFixture(): CjguiOwnerCommandReceipt {
    return CjguiOwnerCommandReceipt(9u64, InternalRendererInputProvenance(2u64, 3u64, 2u64, 34u32),
        ownerReceiptChoice(4, version: 2), ownerReceiptChoice(5), 7, 6u64, -1, -1, true, None)
}
@Test
func ownerReceiptSameCoordinatesNewChoiceCannotBorrowPrefix(): Unit {
    let receipt = ownerReceiptFixture()
    @Assert(receipt.isValid(), true)
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5), 7, 6u64), true)
    // Same bytes/version/coordinates, but this owner choice is a new action.
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(6), 7, 6u64), false)
    @Assert(receipt.convertsBusinessRevision(-1, -1, ownerReceiptChoice(6), 7, 6u64), false)
}
@Test
func ownerReceiptOriginalChoiceAndIndependentDomainsStaySeparate(): Unit {
    let receipt = ownerReceiptFixture()
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5), 7, 6u64), true)
    @Assert(receipt.isTailFor(4u64, ownerReceiptChoice(5), 7, 6u64), false)
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5, document: "another-owner"), 7, 6u64), false)
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5, epoch: 3), 7, 6u64), false)
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5), 8, 6u64), false)
    @Assert(receipt.isTailFor(3u64, ownerReceiptChoice(5), 7, 7u64), false)
}
