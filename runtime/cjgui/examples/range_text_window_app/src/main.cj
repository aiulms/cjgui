/// Second consumer of the public range-text seam.
///
/// This application depends only on the exported `cjgui` package. It has no
/// Markdown, no agent protocol and no Pharos module: its whole truth is a
/// plain byte array that it exposes through `CjguiRangeTextSource` and writes
/// through `CjguiRangeTextEditSink`. It exists to prove the seam is usable by
/// an ordinary independent window application, not just by the editor.
package cjgui_range_text_window_app

import cjgui.*
import std.collection.*
import std.env.*

/// Plain byte-array truth. Reads are bounded; the sink is the only writer and
/// refuses a base version it no longer holds.
private class PlainRangeTextStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var bytes: Array<Byte>
    private var version: Int64 = 1
    private var appliedEdits: Int64 = 0
    private var rejectedEdits: Int64 = 0
    private var lastAppliedRange: String = "-"
    private var lastInsertedByteCount: Int64 = 0

    init(text: String) {
        this.bytes = text.toArray()
    }

    public func text(): String {
        return String.fromUtf8(this.bytes)
    }

    public func byteCount(): Int64 {
        return Int64(this.bytes.size)
    }

    public func rangeTextVersion(): Int64 {
        return this.version
    }

    public func appliedEditCount(): Int64 {
        return this.appliedEdits
    }

    public func rejectedEditCount(): Int64 {
        return this.rejectedEdits
    }

    public func lastAppliedRangeText(): String {
        return this.lastAppliedRange
    }

    public func lastInsertedBytes(): Int64 {
        return this.lastInsertedByteCount
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
        let reason = if (complete) { "" } else { "window_truncated" }
        return CjguiRangeTextSlice(startByte, aligned,
            String.fromUtf8(this.bytes.slice(aligned, end - aligned)), this.version, size, complete, reason)
    }

    public func applyRangeTextEdit(
        baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        if (baseVersion != this.version) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale_base")
        }
        if (startByte < 0 || endByte < startByte || endByte > Int64(this.bytes.size)) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "invalid_range")
        }
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
        this.appliedEdits += 1
        this.lastAppliedRange = "${startByte}:${endByte}"
        this.lastInsertedByteCount = Int64(insertedBytes.size)
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }
}

private class RangeTextWindowController <: CjguiComposableUiController {
    private let store: PlainRangeTextStore
    private let editorWindow: CjguiRangeTextWindow
    private var sceneRevision: Int64 = 1
    private var rangeEvents: Int64 = 0
    private var fullTextEvents: Int64 = 0
    private var lastDelta: String = "-"
    /// A raw-byte path stays available for an inline 64 KiB-bounded preview:
    /// the file bytes never become a second writable owner.
    private let capacityBytes: Int64

    init(initialText: String, capacityBytes!: Int64 = 65536) {
        this.store = PlainRangeTextStore(initialText)
        this.capacityBytes = capacityBytes
        this.editorWindow = CjguiRangeTextWindow(102, "range-text-editor", this.store, this.store,
            materializeLimit: capacityBytes)
        let _ = this.editorWindow.refresh()
    }

    public func uiSceneVersion(): Int64 {
        return this.sceneRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "range-text-root", CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(2, "range-text-heading", "Range text consumer (public seam only)",
            CjguiComposableUiStyle(fixedHeight: 24, fontSize: 16.0)))
        root.add(cjguiComposableText(3, "range-text-status", this.statusLine(),
            CjguiComposableUiStyle(fixedHeight: 20, fontSize: 11.0)))
        root.add(cjguiComposableMultilineTextInput(4, "range-text-body", "", this.editorWindow.text(), 102,
            CjguiComposableUiStyle(fixedHeight: 420), tabInsertsText: true))
        return root
    }

    private func statusLine(): String {
        var coverage = "complete"
        if (!this.editorWindow.isComplete()) {
            coverage = "partial(${this.editorWindow.unpreparedReason()})"
        }
        return "v${this.store.rangeTextVersion()} bytes=${this.store.byteCount()} " +
            "edits=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
            "window=${this.editorWindow.windowStartByte()}+${this.editorWindow.text().toArray().size} " +
            "coverage=${coverage} last=${this.store.lastAppliedRangeText()}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED && event.node.nodeId == 4) {
            this.rangeEvents += 1
            this.lastDelta = "${event.selectionStart}:${event.selectionEnd}"
            let outcome = this.editorWindow.applyUtf16Edit(
                event.selectionStart, event.selectionEnd - event.selectionStart, event.text)
            this.sceneRevision += 1
            getStdOut().writeln("RANGE_TEXT_EDIT delta_utf16=${this.lastDelta} inserted_bytes=${event.text.toArray().size} " +
                "applied=${outcome.applied} version=${this.editorWindow.contentVersion()} owner_bytes=${this.store.byteCount()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(outcome.applied)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.nodeId == 4) {
            // The full-value projection still arrives; this consumer is a range
            // consumer and deliberately ignores it, proving both can coexist.
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

    public func summary(): String {
        return "range_events=${this.rangeEvents} full_text_events=${this.fullTextEvents} " +
            "owner_bytes=${this.store.byteCount()} version=${this.store.rangeTextVersion()} " +
            "applied=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()}"
    }

    public func ownerText(): String {
        return this.store.text()
    }

    public func projectionText(): String {
        return this.editorWindow.text()
    }
}

private func defaultDocumentText(): String {
    return "# Pharos Mark range text consumer\n" +
        "这个窗口只用导出的 CJGUI 公共包：自己的 source/sink 覆盖一个普通字节数组。\n" +
        "中文、emoji 与 ASCII 混排：😀 世界 hello\n"
}

main(args: Array<String>): Int64 {
    let controller = RangeTextWindowController(defaultDocumentText())
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "CJGUI Range Text Consumer", 900u32, 620u32, rangeTextEditDeltaDelivery: true)
    )
    let started = host.start()
    let window = host.window()
    if (!started) {
        let progress = window.windowProgress()
        getStdOut().writeln("RANGE_TEXT_START_FAILED native_status=${window.nativeStatus()} " +
            "failure=${progress.lastNativeFailure} pending=${progress.pendingRefreshReason}")
        getStdOut().flush()
        host.close()
        CjguiMacosApplicationHost.stopApplicationLoop()
        return 1
    }
    getStdOut().writeln("RANGE_TEXT_READY delivery_enabled=${window.isTextRangeEditDeltaDeliveryEnabled()} " +
        "owner_bytes=${controller.ownerText().toArray().size}")
    getStdOut().flush()
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    getStdOut().writeln("RANGE_TEXT_SUMMARY ${controller.summary()}")
    getStdOut().flush()
    return 0
}
