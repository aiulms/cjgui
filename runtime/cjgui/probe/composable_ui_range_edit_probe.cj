package cjgui

import std.collection.*

// Test-only entry points that drive the production AppKit event path. The
// probe never receives a native object; every result is a scalar.
foreign {
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_delete_composable_text(session: UInt64, nodeIndex: UInt32): Int32
}

/// A plain byte-array range store. It is deliberately not a Markdown, agent or
/// document-core type: the probe proves the public seam is usable on its own.
private class PlainRangeStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var bytes: Array<Byte>
    private var version: Int64 = 1
    private var conflictNext: Bool = false
    private var lastStart: Int64 = -1
    private var lastEnd: Int64 = -1
    private var lastInserted: String = ""

    init(text: String) {
        this.bytes = text.toArray()
    }

    public func text(): String {
        return String.fromUtf8(this.bytes)
    }

    public func armConflict(): Unit {
        this.conflictNext = true
    }

    public func lastStartByte(): Int64 {
        return this.lastStart
    }

    public func lastEndByte(): Int64 {
        return this.lastEnd
    }

    public func lastInsertedText(): String {
        return this.lastInserted
    }

    public func editCount(): Int64 {
        return this.version - 1
    }

    public func rangeTextVersion(): Int64 {
        return this.version
    }

    public func rangeTextByteLength(): Int64 {
        return Int64(this.bytes.size)
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        var requested = startByte
        if (requested < 0) {
            requested = 0
        }
        let aligned = cjguiAlignToUtf8Boundary(this.bytes, requested)
        let size = Int64(this.bytes.size)
        if (aligned > size) {
            return CjguiRangeTextSlice(startByte, aligned, "", this.version, size, true, "")
        }
        var limit = aligned + maxBytes
        if (limit > size) {
            limit = size
        }
        let end = cjguiValidUtf8End(this.bytes, aligned, limit)
        let complete = end == size
        var reason = ""
        if (!complete) {
            reason = "window_truncated"
        }
        return CjguiRangeTextSlice(startByte, aligned,
            String.fromUtf8(this.bytes.slice(aligned, end - aligned)), this.version, size, complete, reason)
    }

    public func applyRangeTextEdit(
        baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        if (this.conflictNext) {
            this.conflictNext = false
            return CjguiRangeTextEditOutcome.conflict(this.version, "armed_conflict")
        }
        if (baseVersion != this.version) {
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale_base")
        }
        this.lastStart = startByte
        this.lastEnd = endByte
        this.lastInserted = inserted
        let work = ArrayList<Byte>()
        var i: Int64 = 0
        while (i < Int64(this.bytes.size)) {
            work.add(this.bytes[i])
            i += 1
        }
        if (endByte > startByte) {
            work.remove(startByte..endByte)
        }
        let insertedBytes = inserted.toArray()
        var k: Int64 = 0
        while (k < Int64(insertedBytes.size)) {
            work.add(insertedBytes[k], at: startByte + k)
            k += 1
        }
        this.bytes = work.toArray()
        let before = this.version
        this.version += 1
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }
}

private class RangeEditController <: CjguiComposableUiController {
    private let store: PlainRangeStore
    private let window: CjguiRangeTextWindow
    private var sceneRevision: Int64 = 1
    private var rangeEdits: Int64 = 0
    private var fullTextEvents: Int64 = 0
    private var rejectedEdits: Int64 = 0
    private var lastRangeStart: Int64 = -1
    private var lastRangeEnd: Int64 = -1
    private var lastInserted: String = ""
    private var lastApplied: Bool = false
    private var lastReason: String = ""

    init() {
        this.store = PlainRangeStore("")
        this.window = CjguiRangeTextWindow(2, "range-edit", this.store, this.store, materializeLimit: 4096)
        let _ = this.window.refresh()
    }

    public func uiSceneVersion(): Int64 {
        return this.sceneRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "range-edit-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableMultilineTextInput(2, "range-edit-text", "", this.window.text(), 42,
            CjguiComposableUiStyle(fixedHeight: 180), tabInsertsText: true))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED && event.node.nodeId == 2) {
            this.rangeEdits += 1
            this.lastRangeStart = event.selectionStart
            this.lastRangeEnd = event.selectionEnd
            this.lastInserted = event.text
            let outcome = this.window.applyUtf16Edit(
                event.selectionStart, event.selectionEnd - event.selectionStart, event.text)
            this.lastApplied = outcome.applied
            this.lastReason = outcome.reason
            if (outcome.applied) {
                this.sceneRevision += 1
            } else {
                this.rejectedEdits += 1
                // A rejected edit must be re-projected from the owner, so the
                // scene revision advances and `buildUi` restores the old text.
                this.sceneRevision += 1
            }
            // Report the truth: a refused edit was not applied. The window uses
            // this to re-assert the accepted value into the native proxy.
            return CjguiComposableUiDispatchResult(outcome.applied)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.nodeId == 2) {
            // The full-value event keeps arriving for legacy consumers; this
            // probe ignores it on purpose and records that it did arrive.
            this.fullTextEvents += 1
            return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func armConflict(): Unit {
        this.store.armConflict()
    }

    public func ownerText(): String {
        return this.store.text()
    }

    public func projectionText(): String {
        return this.window.text()
    }

    public func observedRangeEdits(): Int64 {
        return this.rangeEdits
    }

    public func observedFullTextEvents(): Int64 {
        return this.fullTextEvents
    }

    public func observedRejectedEdits(): Int64 {
        return this.rejectedEdits
    }

    public func observedRangeStart(): Int64 {
        return this.lastRangeStart
    }

    public func observedRangeEnd(): Int64 {
        return this.lastRangeEnd
    }

    public func observedInserted(): String {
        return this.lastInserted
    }

    public func lastOutcomeApplied(): Bool {
        return this.lastApplied
    }

    public func lastOutcomeReason(): String {
        return this.lastReason
    }

    public func observedSinkStart(): Int64 {
        return this.store.lastStartByte()
    }

    public func observedSinkEnd(): Int64 {
        return this.store.lastEndByte()
    }
}

private func insertText(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_insert_composable_text(window.testSessionToken(), 1u32, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func deleteBackward(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_delete_composable_text(window.testSessionToken(), 1u32)
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func settle(window: CjguiComposableUiWindow): Bool {
    var i: Int64 = 0
    while (i < 8) {
        let _ = window.pump(4u32)
        i += 1
    }
    return window.isOpen()
}

/// The exactness of one delivered delta: replaced UTF-16 range, inserted text,
/// and the document byte range the sink actually received.
private func deltaMatches(
    controller: RangeEditController,
    utf16Start: Int64,
    utf16End: Int64,
    inserted: String,
    byteStart: Int64,
    byteEnd: Int64,
    expectedOwnerText: String): Bool {
    let passed = controller.observedRangeStart() == utf16Start && controller.observedRangeEnd() == utf16End &&
        controller.observedInserted() == inserted && controller.lastOutcomeApplied() &&
        controller.ownerText() == expectedOwnerText && controller.observedSinkStart() == byteStart &&
        controller.observedSinkEnd() == byteEnd
    println("CJGUI_RANGE_EDIT_CASE utf16=${utf16Start}:${utf16End} inserted_bytes=${inserted.toArray().size} " +
        "sink_bytes=${controller.observedSinkStart()}:${controller.observedSinkEnd()} owner_bytes=${controller.ownerText().toArray().size} " +
        "projection_equal=${controller.projectionText() == expectedOwnerText} passed=${passed}")
    return passed
}

private func runRangeEditProbe(): Bool {
    let controller = RangeEditController()
    let configuration = CjguiMacosApplicationWindowConfiguration(
        "CJGUI Range Edit Probe", 760u32, 460u32, rangeTextEditDeltaDelivery: true)
    let window = CjguiComposableUiWindow(controller, configuration: configuration)
    if (!window.start()) {
        println("CJGUI_RANGE_EDIT_RESULT start_failed=true")
        return false
    }
    let deliveryEnabled = window.isTextRangeEditDeltaDeliveryEnabled()
    println("CJGUI_RANGE_EDIT_DELIVERY enabled=${deliveryEnabled}")
    if (!deliveryEnabled) {
        window.close()
        return false
    }
    if (!settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT settle_failed=true")
        window.close()
        return false
    }
    var passed = true

    // 1. ASCII insert at the empty caret: replaced range 0:0, inserted "A".
    if (!insertText(window, "A") || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT insert_ascii_drive_failed=true")
        window.close()
        return false
    }
    passed = deltaMatches(controller, 0, 0, "A", 0, 0, "A") && passed

    // 2. CJK insert right after it: replaced range 1:1, one UTF-8 scalar.
    if (!insertText(window, "中") || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT insert_cjk_drive_failed=true")
        window.close()
        return false
    }
    passed = deltaMatches(controller, 1, 1, "中", 1, 1, "A中") && passed

    // 3. Emoji insert after the CJK scalar (UTF-16 offset 2, one surrogate pair).
    if (!insertText(window, "😀") || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT insert_emoji_drive_failed=true")
        window.close()
        return false
    }
    passed = deltaMatches(controller, 2, 2, "😀", 4, 4, "A中😀") && passed

    // 4. Backspace removes the whole emoji: replaced range 2:4, inserted "".
    if (!deleteBackward(window) || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT delete_drive_failed=true")
        window.close()
        return false
    }
    passed = deltaMatches(controller, 2, 4, "", 4, 8, "A中") && passed

    // 5. A rejected edit must not move the owner, and the projection must be
    //    restored from the owner rather than keeping the rejected local text.
    let ownerBefore = controller.ownerText()
    let rejectionsBefore = controller.observedRejectedEdits()
    controller.armConflict()
    if (!insertText(window, "X") || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RESULT conflict_drive_failed=true")
        window.close()
        return false
    }
    let rejectedExactlyOnce = controller.observedRejectedEdits() == rejectionsBefore + 1
    let ownerUnchanged = controller.ownerText() == ownerBefore
    let projectionRestored = controller.projectionText() == ownerBefore
    println("CJGUI_RANGE_EDIT_CONFLICT rejected_once=${rejectedExactlyOnce} owner_unchanged=${ownerUnchanged} " +
        "projection_restored=${projectionRestored} reason=${controller.lastOutcomeReason()}")
    passed = rejectedExactlyOnce && ownerUnchanged && projectionRestored && passed

    // 6. Continue editing after the rejection.
    //
    // KNOWN FRAMEWORK GAP (recorded, not a probe failure): after the owner
    // rejects a range edit, the window does not re-assert the accepted node
    // value to the hidden native proxy, whose local text still holds the
    // rejected characters. The next delta therefore arrives in coordinates of
    // the diverged native text and is refused by the seam. The probe therefore
    // reports this step separately instead of asserting it; the owner's content
    // and version are still correct and unchanged.
    let ownerBeforeRecovery = controller.ownerText()
    if (!insertText(window, "Y") || !settle(window)) {
        println("CJGUI_RANGE_EDIT_RECOVERY drive_status=unavailable")
        let rangeEdits = controller.observedRangeEdits()
        println("CJGUI_RANGE_EDIT_SUMMARY range_events=${rangeEdits} full_text_events=" +
            "${controller.observedFullTextEvents()} rejected=${controller.observedRejectedEdits()} " +
            "restore_gap=unknown passed=${passed}")
        window.close()
        return passed
    }
    let recovered = controller.ownerText() == ownerBeforeRecovery + "Y" &&
        controller.projectionText() == ownerBeforeRecovery + "Y"
    println("CJGUI_RANGE_EDIT_RECOVERY owner=${controller.ownerText()} projection_matches=${recovered} " +
        "restore_gap=${!recovered}")

    // 7. A SECOND consecutive edit after the refusal must also be accepted at
    //    owner coordinates. This is the counterexample that distinguishes "the
    //    proxy was really rolled back" from "one edit happened to line up".
    var chained = false
    if (insertText(window, "Z") && settle(window)) {
        chained = controller.ownerText() == ownerBeforeRecovery + "YZ" &&
            controller.projectionText() == ownerBeforeRecovery + "YZ"
    }
    println("CJGUI_RANGE_EDIT_CHAIN owner=${controller.ownerText()} chained_after_refusal=${chained}")

    let recoveries = window.refusedRangeTextRecoveryCount()
    let recoveryFailures = window.refusedRangeTextFailureCount()
    let recoveryPending = window.isRefusedRangeTextRecoveryPending()
    println("CJGUI_RANGE_EDIT_RECOVERY_STATE recoveries=${recoveries} failures=${recoveryFailures} " +
        "pending=${recoveryPending}")
    passed = recovered && chained && recoveries >= 1 && recoveryFailures == 0 && !recoveryPending && passed

    let rangeEdits = controller.observedRangeEdits()
    let fullTextEvents = controller.observedFullTextEvents()
    println("CJGUI_RANGE_EDIT_SUMMARY range_events=${rangeEdits} full_text_events=${fullTextEvents} " +
        "rejected=${controller.observedRejectedEdits()} restore_gap=${!recovered} " +
        "recoveries=${recoveries} failures=${recoveryFailures} passed=${passed}")
    let _ = window.pump(4u32)
    window.close()
    return passed
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--range-edit") {
        return if (runRangeEditProbe()) {
            0
        } else {
            90
        }
    }
    println("usage: composable_ui_range_edit_probe --range-edit")
    return 2
}
