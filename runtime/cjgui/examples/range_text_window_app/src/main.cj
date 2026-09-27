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

    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (this.version != expectedVersion) {
            return false
        }
        return action()
    }

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (fromVersion == this.rangeTextVersion() && startByte >= 0 &&
            endByte >= startByte && endByte <= this.rangeTextByteLength()) {
            return Some((fromVersion, startByte, endByte))
        }
        return None
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
    /// 1b:镜像与会话由**窗口**拥有。消费方只交出 owner 的读/写接缝,并保留只读查询
    /// 句柄;它既没有第二条正文写入路径,也不在 `buildUi` 里轮询恢复回执。
    private var hostWindow: Option<CjguiComposableUiWindow> = None
    private var session: Option<CjguiTextSession> = None
    private var fullTextEvents: Int64 = 0
    /// 窗口拥有会话后仍到达 owner 的范围意图数。必须恒为 0:非零即第二条写入路径复活。
    private var leakedRangeEvents: Int64 = 0
    /// A raw-byte path stays available for an inline 64 KiB-bounded preview:
    /// the file bytes never become a second writable owner.
    private let capacityBytes: Int64

    init(initialText: String, capacityBytes!: Int64 = 65536) {
        this.store = PlainRangeTextStore(initialText)
        this.capacityBytes = capacityBytes
    }

    /// 由窗口建立并拥有会话;返回值只供消费方做只读查询(选区/组合/校准状态)。
    /// 必须在 `start()` 之前调用,首次投影发布的正文才是镜像而不是消费方自己的字符串。
    /// 绑定身份必须与正文节点的 (nodeId, resourceId) 完全一致,窗口才把该节点的范围
    /// 意图路由给会话;错一个字段就会退回 owner 路径(leaked_range_events 非零)。
    public func attach(window: CjguiComposableUiWindow): CjguiTextSession {
        this.hostWindow = Some(window)
        let bound = window.bindRangeTextSession(4, "range-text-body", this.store, this.store, 102,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: this.capacityBytes)
        this.session = Some(bound)
        return bound
    }

    public func uiSceneVersion(): Int64 {
        // 会话写入不经 `applyUiEvent`,所以声明场景的版本必须跟着**正文**走:
        // owner 每接受一笔写入,消费方声明的场景就换代一次。
        return 1 + this.store.appliedEditCount()
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "range-text-root", CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(2, "range-text-heading", "Range text consumer (public seam only)",
            CjguiComposableUiStyle(fixedHeight: 24, fontSize: 16.0)))
        root.add(cjguiComposableText(3, "range-text-status", this.statusLine(),
            CjguiComposableUiStyle(fixedHeight: 20, fontSize: 11.0)))
        // 正文节点的值 = 窗口拥有的会话镜像。投影与镜像同源 ⇒ 平台代理不会再拿着一份
        // 会话没见过的旧值去表达范围(那正是 native 按旧长度 clamp 的根源)。恢复回执由
        // 窗口在回滚代理之后自己交回会话,消费方不轮询、不自签自认。
        root.add(cjguiComposableMultilineTextInput(4, "range-text-body", "", this.mirrorText(), 102,
            CjguiComposableUiStyle(fixedHeight: 420), tabInsertsText: true))
        return root
    }

    public func mirrorText(): String {
        return match (this.hostWindow) {
            case Some(window) => window.textSessionMirrorText()
            case None => ""
        }
    }

    private func statusLine(): String {
        let window = match (this.hostWindow) {
            case Some(host) => host
            case None => return "session=unbound"
        }
        let session = match (this.session) {
            case Some(bound) => bound
            case None => return "session=unbound"
        }
        var coverage = "complete"
        if (!session.mirrorIsReady()) {
            coverage = "partial(${session.unpreparedReason()})"
        }
        let (coverageStart, coverageEnd) = session.coverageBytes()
        return "v${this.store.rangeTextVersion()} bytes=${this.store.byteCount()} " +
            "edits=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
            "window=${coverageStart}..${coverageEnd} coverage=${coverage} " +
            "seq=${session.currentEditSeq()} mirror=${session.mirrorRevisionValue()} " +
            "epoch=${session.contextEpochValue()} calibrating=${session.awaitingCalibration()} " +
            "decisions=${window.textSessionRangeDecisionCount()} restored=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} " +
            "last=${this.store.lastAppliedRangeText()}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED && event.node.nodeId == 4) {
            // 退役判据:窗口拥有会话后,该节点的范围意图由窗口路由给会话,不再到达 owner。
            // 到达即第二条写入路径复活(或路由失效),显式记账,不静默判决。
            this.leakedRangeEvents += 1
            getStdOut().writeln("RANGE_TEXT_LEAK delta_utf16=${event.selectionStart}:${event.selectionEnd} " +
                "inserted_bytes=${event.text.toArray().size}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.nodeId == 4) {
            // 会话绑定的节点只接受范围意图:同笔整值事件一律不消费,不做第二次 UTF-16 换算,
            // 也不退回整值 diff(退役判据:一个 native 意图 → 一个会话票据 → 一个 owner 判决)。
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
        let window = match (this.hostWindow) {
            case Some(host) => host
            case None => return "session=unbound"
        }
        let pending = match (this.session) {
            case Some(bound) => bound.pendingCount()
            case None => -1
        }
        return "range_decisions=${window.textSessionRangeDecisionCount()} " +
            "full_text_events=${this.fullTextEvents} leaked_range_events=${this.leakedRangeEvents} " +
            "session_accepted=${window.textSessionAcceptedCount()} " +
            "session_refused=${window.textSessionRefusedCount()} " +
            "restored=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} pending=${pending} " +
            "owner_bytes=${this.store.byteCount()} version=${this.store.rangeTextVersion()} " +
            "applied=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()}"
    }

    public func ownerText(): String {
        return this.store.text()
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
    // 窗口拥有会话:必须在 start 之前绑定,首次投影发布的正文才是镜像。
    let session = controller.attach(host.window())
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
        "session_node=${session.boundNode()} session_bound=${session.isBound()} " +
        "mirror_bytes=${window.textSessionMirrorText().toArray().size} " +
        "owner_bytes=${controller.ownerText().toArray().size}")
    getStdOut().flush()
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    getStdOut().writeln("RANGE_TEXT_SUMMARY ${controller.summary()}")
    getStdOut().flush()
    return 0
}
