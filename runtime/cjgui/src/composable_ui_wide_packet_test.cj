package cjgui

import std.collection.*
import std.sync.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

// A test-only native trace for the real kind-9 preparation admission/service
// calls. Each row contains nine Int64 fields in this order:
// preparation id, nonce, count, event kind, native status, accepted prefix,
// original owner-turn deadline, preparation generation, and actual successful
// owned reservation byte count (zero for a refusal without a reservation).
foreign func cjgui_internal_renderer_test_mixed_packet_records(session: UInt64, outRows: CPointer<Int64>,
    capacityRows: UInt32, outCount: CPointer<UInt32>): Int32

private let WIDE_PACKET_NODE_COUNT: Int64 = 16
private let WIDE_PACKET_SLOT_BYTES: Int64 = 4 * 1024 * 1024
private let WIDE_PACKET_RECORD_FIELDS: Int64 = 9
private let WIDE_PACKET_RECORD_CAPACITY: Int64 = 64

private func widePacketText(byteCount: Int64): String {
    // Keep both paragraphs inside the production 131072-byte paragraph cap,
    // including at the per-value 262144-byte boundary.
    if (byteCount <= 1 || byteCount > 262144) {
        throw Exception("wide_packet_text_out_of_production_bounds:${byteCount}")
    }
    let bodyBytes = byteCount - 1
    let firstBytes = bodyBytes / 2
    let secondBytes = bodyBytes - firstBytes
    if (firstBytes > 131072 || secondBytes > 131072) {
        throw Exception("wide_packet_paragraph_out_of_production_bounds:${byteCount}")
    }
    return String.fromUtf8(Array<UInt8>(firstBytes, repeat: 0x61u8)) + "\n" + String.fromUtf8(
        Array<UInt8>(secondBytes, repeat: 0x62u8))
}

private class WidePacketController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var nodeValues: Array<String> = Array<String>(16, repeat: "")
    var firstLabelExpanded: Bool = false
    let fillerStyle = CjguiComposableUiStyle(fixedHeight: 32)
    let nodeStyle = CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 18, fontSize: 10.0, textMaxLines: 1,
        textOverflow: "ellipsis")

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(17100, "wide-packet-root", CjguiComposableUiStyle())
        // Keep all large values below the 420-point viewport. Their transport
        // is under test here; making them visible would enter the separate
        // 32768-UTF16 cold text layout limit. Fifteen 32-point fillers occupy
        // 480 points before the value nodes begin.
        for (index in 0..15) {
            root.add(cjguiComposableText(17101 + index, "wide-packet-filler-${index}", "filler ${index}", fillerStyle))
        }
        for (index in 0..WIDE_PACKET_NODE_COUNT) {
            let semanticId = "wide-packet-value-${index}"
            let label = if (index == 0) {
                if (firstLabelExpanded) {
                    "captionXX"
                } else {
                    "caption"
                }
            } else {
                "caption-${index}"
            }
            root.add(
                CjguiComposableUiNode(17200 + index, semanticId, CJGUI_COMPOSABLE_UI_TEXT, label, nodeValues[index], "",
                    17200 + index, nodeStyle, semanticLabel: semanticId))
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func runWidePacketOwnerTurn(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget): Bool {
    if (!budget.begin()) {
        return false
    }
    let _ = window.refreshIfNeeded()
    let _ = window.pump(0u32)
    let _ = budget.finishScheduling()
    budget.end()
    return true
}

private func settleWidePacketCandidate(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget, priorScene: Int64): Unit {
    let deadline = MonoTime.now() + 5 * Duration.second
    var turns: Int64 = 0
    while ((window.displayedSceneVersion() <= priorScene || window.hasDeferredEventWork()) && MonoTime.now() < deadline &&
            turns < 96) {
        @Assert(runWidePacketOwnerTurn(window, budget), true)
        turns += 1
    }
    @Assert(window.displayedSceneVersion() > priorScene, true)
    @Assert(window.hasDeferredEventWork(), false)
    @Assert(window.settlementFault(), "")
    @Assert(turns <= 96, true)
}

private func widePacketRefresh(window: CjguiComposableUiWindow, controller: WidePacketController,
    budget: CjguiOwnerTurnBudget): Unit {
    let priorScene = window.displayedSceneVersion()
    controller.revision += 1
    window.requestRefresh()
    settleWidePacketCandidate(window, budget, priorScene)
}

private func assertWidePacketAccepted(window: CjguiComposableUiWindow, controller: WidePacketController): Unit {
    let nodes = window.acceptedSceneNodes()
    @Assert(nodes.size, 32)
    var index: Int64 = 0
    while (index < WIDE_PACKET_NODE_COUNT) {
        let semanticId = "wide-packet-value-${index}"
        var foundNode = false
        for (node in nodes) {
            if (node.semanticId == semanticId) {
                foundNode = true
                let visible = node.bounds.intersect(node.clip)
                @Assert(visible.width <= 0 || visible.height <= 0, true)
                @Assert(node.bounds.y >= node.clip.y + node.clip.height, true)
            }
        }
        @Assert(foundNode, true)
        let actual = match (window.acceptedNodeValue(semanticId)) {
            case Some(value) => value
            case None => throw Exception("wide_packet_accepted_value_missing:${semanticId}")
        }
        @Assert(actual.size, controller.nodeValues[index].size)
        @Assert(actual == controller.nodeValues[index], true)
        index += 1
    }
}

private func readWidePacketRecords(window: CjguiComposableUiWindow): Array<Int64> {
    var rows = Array<Int64>(WIDE_PACKET_RECORD_CAPACITY * WIDE_PACKET_RECORD_FIELDS, repeat: 0)
    var count: UInt32 = 0u32
    let status = unsafe {
        let handle = acquireArrayRawData(rows)
        try {
            cjgui_internal_renderer_test_mixed_packet_records(window.testSessionToken(), handle.pointer,
                UInt32(WIDE_PACKET_RECORD_CAPACITY), inout count)
        } finally {
            releaseArrayRawData(handle)
        }
    }
    @Assert(status, CJGUI_INTERNAL_RENDERER_OK)
    @Assert(count <= UInt32(WIDE_PACKET_RECORD_CAPACITY), true)
    let used = Array<Int64>(Int64(count) * WIDE_PACKET_RECORD_FIELDS, repeat: 0)
    var index: Int64 = 0
    while (index < Int64(used.size)) {
        used[index] = rows[index]
        index += 1
    }
    return used
}

private func widePacketRecordField(rows: Array<Int64>, row: Int64, field: Int64): Int64 {
    return rows[row * WIDE_PACKET_RECORD_FIELDS + field]
}

private func latestWidePacketReservationBytes(window: CjguiComposableUiWindow): Int64 {
    let rows = readWidePacketRecords(window)
    @Assert(rows.size >= WIDE_PACKET_RECORD_FIELDS, true)
    let lastRow = rows.size / WIDE_PACKET_RECORD_FIELDS - 1
    let preparationId = widePacketRecordField(rows, lastRow, 0)
    var maxFullPacketBytes: Int64 = 0
    var sawFullPacket = false
    var row: Int64 = 0
    while (row <= lastRow) {
        if (widePacketRecordField(rows, row, 0) == preparationId && widePacketRecordField(rows, row, 3) == 2) {
            let count = widePacketRecordField(rows, row, 2)
            let prefix = widePacketRecordField(rows, row, 5)
            @Assert(widePacketRecordField(rows, row, 4), Int64(CJGUI_INTERNAL_RENDERER_OK))
            @Assert(count > 0 && count <= 16, true)
            @Assert(prefix >= 0 && prefix <= count, true)
            @Assert(widePacketRecordField(rows, row, 6) > 0, true)
            if (count == 16) {
                sawFullPacket = true
                let reserved = widePacketRecordField(rows, row, 8)
                if (reserved > maxFullPacketBytes) {
                    maxFullPacketBytes = reserved
                }
            }
        }
        row += 1
    }
    @Assert(sawFullPacket, true)
    @Assert(maxFullPacketBytes > 0 && maxFullPacketBytes < WIDE_PACKET_SLOT_BYTES, true)
    return maxFullPacketBytes
}

private func assertWidePacketFullValueReads(window: CjguiComposableUiWindow, controller: WidePacketController): Unit {
    var index: Int64 = 0
    while (index < WIDE_PACKET_NODE_COUNT) {
        @Assert(controller.nodeValues[index].size > 0, true)
        @Assert(controller.nodeValues[index].size <= 262144, true)
        let actual = match (window.acceptedNodeValue("wide-packet-value-${index}")) {
            case Some(value) => value
            case None => throw Exception("wide_packet_value_not_accepted:${index}")
        }
        @Assert(actual.size, controller.nodeValues[index].size)
        // Equality checks the entire UTF-8 payload without printing large text
        // into a failing test log.
        @Assert(actual == controller.nodeValues[index], true)
        index += 1
    }
}

@When[os == "macOS"]
@Test
func mixedKind9WidePacketRetriesSameCandidateWithinEightNodePackets(): Unit {
    cjguiMacosOwnerTest({=> mixedKind9WidePacketBody()})
}

private func mixedKind9WidePacketBody(): Unit {
    let controller = WidePacketController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI legal wide mixed packet boundary", 520u32, 420u32))
    let budget = CjguiOwnerTurnBudget()
    window.useOwnerTurnBudget(budget)
    try {
        @Assert(window.start(), true)
        settleWidePacketCandidate(window, budget, 0)
        @Assert(window.acceptedSceneNodes().size, 32)
        assertWidePacketAccepted(window, controller)

        // Three accepted owner candidates introduce legal, non-empty values
        // in 7/7/2 groups. Unchanged rows reuse their accepted values, so each
        // candidate adds under the 2 MiB declaration budget while each kind-9
        // packet still owns all sixteen row strings. Values are offscreen and
        // are not evidence that a 200 KiB visible text node can be laid out.
        let initialLength: Int64 = 200000
        var index: Int64 = 0
        while (index < 7) {
            controller.nodeValues[index] = widePacketText(initialLength)
            index += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketAccepted(window, controller)
        let _ = latestWidePacketReservationBytes(window)

        while (index < 14) {
            controller.nodeValues[index] = widePacketText(initialLength)
            index += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketAccepted(window, controller)
        let _ = latestWidePacketReservationBytes(window)

        while (index < WIDE_PACKET_NODE_COUNT) {
            controller.nodeValues[index] = widePacketText(initialLength)
            index += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketFullValueReads(window, controller)
        let baselineBytes = latestWidePacketReservationBytes(window)

        // Measure the actual native byte total (including native object/POD,
        // pointer and small-string costs), then approach the slot boundary in
        // another accepted 7/7/2 series. The exact pre-trigger packet is one
        // byte below 4 MiB; no guessed ABI sizes enter this test.
        @Assert(baselineBytes > 0, true)
        @Assert(baselineBytes < WIDE_PACKET_SLOT_BYTES, true)
        let targetIncrease = WIDE_PACKET_SLOT_BYTES - 1 - baselineBytes
        @Assert(targetIncrease > 0, true)
        let increasePerNode = targetIncrease / WIDE_PACKET_NODE_COUNT
        let extraBytes = targetIncrease % WIDE_PACKET_NODE_COUNT
        var tuneIndex: Int64 = 0
        while (tuneIndex < 7) {
            let increment = increasePerNode + (if (tuneIndex < extraBytes) {
                1
            } else {
                0
            })
            controller.nodeValues[tuneIndex] = widePacketText(initialLength + increment)
            tuneIndex += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketAccepted(window, controller)
        let _ = latestWidePacketReservationBytes(window)

        while (tuneIndex < 14) {
            let increment = increasePerNode + (if (tuneIndex < extraBytes) {
                1
            } else {
                0
            })
            controller.nodeValues[tuneIndex] = widePacketText(initialLength + increment)
            tuneIndex += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketAccepted(window, controller)
        let _ = latestWidePacketReservationBytes(window)

        while (tuneIndex < WIDE_PACKET_NODE_COUNT) {
            let increment = increasePerNode + (if (tuneIndex < extraBytes) {
                1
            } else {
                0
            })
            controller.nodeValues[tuneIndex] = widePacketText(initialLength + increment)
            tuneIndex += 1
        }
        widePacketRefresh(window, controller, budget)
        assertWidePacketFullValueReads(window, controller)
        let boundaryBytes = latestWidePacketReservationBytes(window)

        @Assert(boundaryBytes, WIDE_PACKET_SLOT_BYTES - 1)

        // Keep all stable identities and values. Only one short label grows by
        // two bytes, moving the same complete 16-node packet from cap-1 to
        // cap+1 and forcing a genuine native zero-prefix budget refusal.
        controller.firstLabelExpanded = true
        let beforeLabel = window.displayedSceneVersion()
        controller.revision += 1
        window.requestRefresh()
        settleWidePacketCandidate(window, budget, beforeLabel)
        assertWidePacketFullValueReads(window, controller)
        let finalNodes = window.acceptedSceneNodes()
        var foundFirst = false
        for (node in finalNodes) {
            if (node.semanticId == "wide-packet-value-0") {
                foundFirst = true
                @Assert(node.label, "captionXX")
            }
        }
        @Assert(foundFirst, true)

        let rows = readWidePacketRecords(window)
        @Assert(rows.size >= 3 * WIDE_PACKET_RECORD_FIELDS, true)
        let totalRows = rows.size / WIDE_PACKET_RECORD_FIELDS
        var rejectedRow: Int64 = -1
        var rejectionCount: Int64 = 0
        var row: Int64 = 0
        while (row < totalRows) {
            if (widePacketRecordField(rows, row, 3) == 1 && widePacketRecordField(rows, row, 2) == 16) {
                rejectedRow = row
                rejectionCount += 1
            }
            row += 1
        }
        @Assert(rejectionCount, 1)
        @Assert(widePacketRecordField(rows, rejectedRow, 4),
            Int64(CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED))
        @Assert(widePacketRecordField(rows, rejectedRow, 5), 0)
        @Assert(widePacketRecordField(rows, rejectedRow, 1), 0)
        @Assert(widePacketRecordField(rows, rejectedRow, 8), 0)
        let preparationId = widePacketRecordField(rows, rejectedRow, 0)
        let generation = widePacketRecordField(rows, rejectedRow, 7)
        @Assert(preparationId > 0, true)
        @Assert(generation > 0, true)
        @Assert(widePacketRecordField(rows, rejectedRow, 6) > 0, true)

        var resumedPrefix: Int64 = 0
        var resumedEvents: Int64 = 0
        var previousDeadline: Int64 = widePacketRecordField(rows, rejectedRow, 6)
        row = rejectedRow + 1
        while (row < totalRows) {
            if (widePacketRecordField(rows, row, 0) == preparationId) {
                @Assert(widePacketRecordField(rows, row, 3), 2)
                @Assert(widePacketRecordField(rows, row, 4), Int64(CJGUI_INTERNAL_RENDERER_OK))
                let count = widePacketRecordField(rows, row, 2)
                let prefix = widePacketRecordField(rows, row, 5)
                if (resumedEvents == 0) {
                    @Assert(count, 8)
                }
                @Assert(count > 0 && count <= 8, true)
                @Assert(prefix >= 0 && prefix <= count, true)
                @Assert(widePacketRecordField(rows, row, 1) > 0, true)
                let reservedBytes = widePacketRecordField(rows, row, 8)
                @Assert(reservedBytes > 0 && reservedBytes <= WIDE_PACKET_SLOT_BYTES, true)
                @Assert(widePacketRecordField(rows, row, 6) >= previousDeadline, true)
                @Assert(widePacketRecordField(rows, row, 7), generation)
                resumedPrefix += prefix
                resumedEvents += 1
                previousDeadline = widePacketRecordField(rows, row, 6)
            }
            row += 1
        }
        @Assert(resumedEvents > 0, true)
        @Assert(resumedPrefix, 16)
    } finally {
        budget.end()
        window.close()
    }
}
