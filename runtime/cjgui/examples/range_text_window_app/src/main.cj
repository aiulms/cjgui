/// Second consumer of the public range-text seam.
///
/// This application depends only on the exported `cjgui` package. It has no
/// Markdown, no agent protocol and no Pharos module: by default its truth is a
/// plain byte array; the optional file mode exposes read-only file spans plus
/// small copy-on-write inserts through the same source/sink seam.
package cjgui_range_text_window_app

import cjgui.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*
import std.io.*
import std.time.*

/// One immutable file span or a small inserted span in the optional file owner.
/// The list is copied around edits; the original large file remains untouched.
private class RangeTextPiece {
    public let fileBacked: Bool
    public let fileOffset: Int64
    public let bytes: Array<Byte>
    public let length: Int64

    init(fileOffset: Int64, length: Int64) {
        this.fileBacked = true
        this.fileOffset = fileOffset
        this.bytes = Array<Byte>()
        this.length = length
    }

    init(bytes: Array<Byte>) {
        this.fileBacked = false
        this.fileOffset = 0
        this.bytes = bytes
        this.length = Int64(bytes.size)
    }

    public func subpiece(offset: Int64, count: Int64): RangeTextPiece {
        if (this.fileBacked) {
            return RangeTextPiece(this.fileOffset + offset, count)
        }
        return RangeTextPiece(this.bytes.slice(offset, count))
    }
}

/// Hex output is intentionally capped so a legal 1 MiB insert cannot turn a
/// single ordinary owner receipt into a multi-megabyte log line.
private let RANGE_TEXT_OWNER_RECEIPT_INSERT_HEX_BYTES: Int64 = 128
private let RANGE_TEXT_OWNER_RECEIPT_CONTEXT_BYTES: Int64 = 32

private func rangeTextHexPrefix(bytes: Array<Byte>, maximumBytes: Int64): String {
    let count = if (Int64(bytes.size) < maximumBytes) { Int64(bytes.size) } else { maximumBytes }
    let digits = "0123456789abcdef".toArray()
    let output = ArrayList<UInt8>()
    var index: Int64 = 0
    while (index < count) {
        let value = UInt64(bytes[index])
        output.add(digits[Int64(value / 16u64)])
        output.add(digits[Int64(value % 16u64)])
        index += 1
    }
    return String.fromUtf8(output.toArray())
}

/// Plain byte-array or file-span truth. Reads are bounded; the sink is the only
/// writer and refuses a base version it no longer holds.
private class PlainRangeTextStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var bytes: Array<Byte>
    private var filePath: String = ""
    private var file: Option<File> = None
    private var pieces: ArrayList<RangeTextPiece> = ArrayList<RangeTextPiece>()
    private var logicalBytes: Int64 = 0
    private let maxFileReadBytes: Int64
    private var version: Int64 = 1
    private var appliedEdits: Int64 = 0
    private var rejectedEdits: Int64 = 0
    private var lastAppliedRange: String = "-"
    private var lastInsertedByteCount: Int64 = 0
    /// M3 拒绝恢复探针：首次 applyEdit 强制一次具名冲突（stale_base 之外的独立
    /// 标记），随后照常接受——用于验证会话拒绝恢复恰好一笔、不双执行。
    private var forceFirstRefusal: Bool = false
    private let timingDiagnostics: Bool
    private var rangeReadCount: Int64 = 0
    private var rangeReadBytes: Int64 = 0
    private var backingReadCount: Int64 = 0
    private var backingReadBytes: Int64 = 0
    private var rangeReadMicros: Int64 = 0
    private var rangeReadMaxMicros: Int64 = 0
    private var lastReadStart: Int64 = -1
    private var lastReadActualStart: Int64 = -1
    private var lastReadLimit: Int64 = 0
    private var lastReadBytes: Int64 = 0
    private var lastReadMicros: Int64 = 0
    private var lastPrepareDescription: String = "none"

    init(text: String, refuseFirstEdit!: Bool = false, filePath!: String = "", maxFileReadBytes!: Int64 = 65536,
        timingDiagnostics!: Bool = false) {
        this.filePath = filePath
        this.maxFileReadBytes = if (maxFileReadBytes < 4) {
            4
        } else {
            maxFileReadBytes
        }
        this.timingDiagnostics = timingDiagnostics
        this.forceFirstRefusal = refuseFirstEdit
        if (filePath == "") {
            this.bytes = text.toArray()
            this.logicalBytes = Int64(this.bytes.size)
        } else {
            this.bytes = Array<Byte>()
            let info = FileInfo(filePath)
            this.logicalBytes = info.size
            this.file = Some(File(filePath, OpenMode.Read))
            if (this.logicalBytes > 0) {
                this.pieces.add(RangeTextPiece(0, this.logicalBytes))
            }
        }
    }

    public func text(): String {
        if (this.filePath != "") {
            return this.ownerSnapshot()
        }
        return String.fromUtf8(this.bytes)
    }

    public func isFileBacked(): Bool {
        return this.filePath != ""
    }

    public func ownerSnapshot(): String {
        if (this.filePath != "") {
            return "file_backed=true bytes=${this.logicalBytes} version=${this.version} pieces=${this.pieces.size}"
        }
        return String.fromUtf8(this.bytes)
    }

    public func timingSummary(): String {
        if (!this.timingDiagnostics) {
            return "timing=off"
        }
        return "range_reads=${this.rangeReadCount} returned_bytes=${this.rangeReadBytes} " +
            "backing_reads=${this.backingReadCount} backing_bytes=${this.backingReadBytes} " +
            "read_total_us=${this.rangeReadMicros} read_max_us=${this.rangeReadMaxMicros} " +
            "last_prepare=${this.lastPrepareDescription} last_read_us=${this.lastReadMicros}"
    }

    public func close(): Unit {
        if (let Some(handle) <- this.file) {
            handle.close()
            this.file = None
        }
    }

    private func splitPieceList(source: ArrayList<RangeTextPiece>, position: Int64): (ArrayList<RangeTextPiece>,
        ArrayList<RangeTextPiece>) {
        let left = ArrayList<RangeTextPiece>()
        let right = ArrayList<RangeTextPiece>()
        var cursor: Int64 = 0
        for (piece in source) {
            let next = cursor + piece.length
            if (next <= position) {
                left.add(piece)
            } else if (cursor >= position) {
                right.add(piece)
            } else {
                let leftCount = position - cursor
                let rightCount = next - position
                if (leftCount > 0) {
                    left.add(piece.subpiece(0, leftCount))
                }
                if (rightCount > 0) {
                    right.add(piece.subpiece(leftCount, rightCount))
                }
            }
            cursor = next
        }
        return (left, right)
    }

    private func splitPieces(position: Int64): (ArrayList<RangeTextPiece>, ArrayList<RangeTextPiece>) {
        return this.splitPieceList(this.pieces, position)
    }

    private func appendLogicalRange(out: ArrayList<Byte>, startByte: Int64, count: Int64): Unit {
        if (count <= 0) {
            return
        }
        if (!this.isFileBacked()) {
            var i = startByte
            let end = startByte + count
            while (i < end) {
                out.add(this.bytes[i])
                i += 1
            }
            return
        }
        var cursor: Int64 = 0
        let endByte = startByte + count
        for (piece in this.pieces) {
            let pieceEnd = cursor + piece.length
            if (pieceEnd > startByte && cursor < endByte) {
                let withinStart = if (startByte > cursor) {
                    startByte - cursor
                } else {
                    0
                }
                let withinEnd = if (endByte < pieceEnd) {
                    endByte - cursor
                } else {
                    piece.length
                }
                let withinCount = withinEnd - withinStart
                if (piece.fileBacked) {
                    var fileOffset = piece.fileOffset + withinStart
                    var remaining = withinCount
                    while (remaining > 0) {
                        let chunkSize = if (remaining > 65536) {
                            65536
                        } else {
                            remaining
                        }
                        let handle = match (this.file) {
                            case Some(value) => value
                            case None => throw Exception("range source file is closed")
                        }
                        let _ = handle.seek(SeekPosition.Begin(fileOffset))
                        var readThisChunk: Int64 = 0
                        while (readThisChunk < chunkSize) {
                            let buffer = Array<Byte>(chunkSize - readThisChunk, repeat: 0u8)
                            let read = handle.read(buffer)
                            if (read <= 0) {
                                throw Exception("unexpected end of range source file")
                            }
                            if (this.timingDiagnostics) {
                                this.backingReadCount += 1
                                this.backingReadBytes += read
                            }
                            var t: Int64 = 0
                            while (t < read) {
                                out.add(buffer[t])
                                t += 1
                            }
                            readThisChunk += read
                            fileOffset += read
                            remaining -= read
                        }
                    }
                } else {
                    var i = withinStart
                    while (i < withinEnd) {
                        out.add(piece.bytes[i])
                        i += 1
                    }
                }
            }
            cursor = pieceEnd
            if (cursor >= endByte) {
                break
            }
        }
    }

    private func logicalBytesAt(startByte: Int64, count: Int64): Array<Byte> {
        let out = ArrayList<Byte>()
        this.appendLogicalRange(out, startByte, count)
        return out.toArray()
    }

    private func byteAt(offset: Int64): Byte {
        return this.logicalBytesAt(offset, 1)[0]
    }

    private func isUtf8Boundary(offset: Int64): Bool {
        if (offset <= 0 || offset >= this.logicalBytes) {
            return true
        }
        return (this.byteAt(offset) & 0xC0) != 0x80
    }

    /// Print one accepted owner transition and an exact, bounded raw-byte
    /// window around its start. UTF-8 boundary adjustment only shrinks the
    /// requested context, so each side stays within the named 32-byte bound.
    private func logAcceptedOwnerEdit(beforeVersion: Int64, sourceStart: Int64, sourceEnd: Int64,
        insertedBytes: Array<Byte>): Unit {
        let insertedHexCount = if (Int64(insertedBytes.size) < RANGE_TEXT_OWNER_RECEIPT_INSERT_HEX_BYTES) {
            Int64(insertedBytes.size)
        } else {
            RANGE_TEXT_OWNER_RECEIPT_INSERT_HEX_BYTES
        }
        var sampleEnd = sourceStart + insertedHexCount
        var endAdjustments: Int64 = 0
        while (sampleEnd > sourceStart && endAdjustments < 3 && !this.isUtf8Boundary(sampleEnd)) {
            sampleEnd -= 1
            endAdjustments += 1
        }

        var ownerStart = if (sourceStart > RANGE_TEXT_OWNER_RECEIPT_CONTEXT_BYTES) {
            sourceStart - RANGE_TEXT_OWNER_RECEIPT_CONTEXT_BYTES
        } else {
            0
        }
        var startAdjustments: Int64 = 0
        while (ownerStart < sourceStart && startAdjustments < 3 && !this.isUtf8Boundary(ownerStart)) {
            ownerStart += 1
            startAdjustments += 1
        }
        var ownerEnd = sampleEnd + RANGE_TEXT_OWNER_RECEIPT_CONTEXT_BYTES
        if (ownerEnd > this.logicalBytes) { ownerEnd = this.logicalBytes }
        endAdjustments = 0
        while (ownerEnd > sampleEnd && endAdjustments < 3 && !this.isUtf8Boundary(ownerEnd)) {
            ownerEnd -= 1
            endAdjustments += 1
        }

        let ownerBytes = this.logicalBytesAt(ownerStart, ownerEnd - ownerStart)
        let insertedHex = rangeTextHexPrefix(insertedBytes, RANGE_TEXT_OWNER_RECEIPT_INSERT_HEX_BYTES)
        let ownerHex = rangeTextHexPrefix(ownerBytes, Int64(ownerBytes.size))
        getStdOut().writeln(
            "RANGE_TEXT_OWNER_EDIT_RECEIPT before_version=${beforeVersion} after_version=${this.version} " +
                "source_start=${sourceStart} source_end=${sourceEnd} inserted_bytes=${Int64(insertedBytes.size)} " +
                "inserted_hex=${insertedHex} inserted_hex_omitted=${Int64(insertedBytes.size) - insertedHexCount} " +
                "owner_start=${ownerStart} owner_end=${ownerEnd} owner_bytes=${Int64(ownerBytes.size)} " +
                "owner_hex=${ownerHex} owner_hex_omitted=0"
        )
        getStdOut().flush()
    }

    public func byteCount(): Int64 {
        return this.logicalBytes
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

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) {
        if (fromVersion == this.rangeTextVersion() && startByte >= 0 && endByte >= startByte && endByte <=
            this.rangeTextByteLength()) {
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
        return this.logicalBytes
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        var begin: Option<MonoTime> = None
        if (this.timingDiagnostics) {
            begin = Some(MonoTime.now())
        }
        var requested = startByte
        if (requested < 0) {
            requested = 0
        }
        let size = this.logicalBytes
        if (requested > size) {
            requested = size
        }
        var aligned = requested
        if (!this.isFileBacked()) {
            aligned = cjguiAlignToUtf8Boundary(this.bytes, requested)
        } else if (aligned < size && (this.byteAt(aligned) & 0xC0) == 0x80) {
            var scanned: Int64 = 0
            while (aligned < size && scanned < 3 && (this.byteAt(aligned) & 0xC0) == 0x80) {
                aligned += 1
                scanned += 1
            }
        }
        if (aligned > size) {
            aligned = size
        }
        var requestedCount = maxBytes
        if (requestedCount < 0) {
            requestedCount = 0
        }
        if (this.isFileBacked() && requestedCount > this.maxFileReadBytes) {
            requestedCount = this.maxFileReadBytes
        }
        var limit = aligned + requestedCount
        if (limit > size) {
            limit = size
        }
        let raw = this.logicalBytesAt(aligned, limit - aligned)
        let rawSize = Int64(raw.size)
        let end = cjguiValidUtf8End(raw, 0, rawSize)
        let contentBytes = raw.slice(0, end)
        let content = String.fromUtf8(contentBytes)
        var elapsed: Int64 = 0
        if (this.timingDiagnostics) {
            if (let Some(started) <- begin) {
                elapsed = (MonoTime.now() - started).toMicroseconds()
            }
            this.rangeReadCount += 1
            this.rangeReadBytes += end
            this.rangeReadMicros += elapsed
            if (elapsed > this.rangeReadMaxMicros) {
                this.rangeReadMaxMicros = elapsed
            }
            this.lastReadStart = startByte
            this.lastReadActualStart = aligned
            this.lastReadLimit = requestedCount
            this.lastReadBytes = end
            this.lastReadMicros = elapsed
            this.lastPrepareDescription = "start=${startByte} actual=${aligned} limit=${requestedCount} bytes=${end}"
        }
        // complete means this bounded request was fulfilled; it does not mean
        // the whole document was read. The window tracks whole-document coverage.
        return CjguiRangeTextSlice(startByte, aligned, content, this.version, size, true, "")
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        if (this.forceFirstRefusal) {
            // 一次性探针拒绝：不写 owner、不推进版本；记一次拒绝供计数守恒。
            this.forceFirstRefusal = false
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.conflict(this.version, "forced_probe_refusal")
        }
        if (baseVersion != this.version) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale_base")
        }
        if (startByte < 0 || endByte < startByte || endByte > this.logicalBytes) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "invalid_range")
        }
        if (this.isFileBacked() && endByte - startByte > 128) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "file_edit_span_limit_128")
        }
        if (this.isFileBacked() && inserted.size > 1048576) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "file_insert_limit_1048576")
        }
        let insertedBytes = inserted.toArray()
        if (this.isFileBacked() && (!this.isUtf8Boundary(startByte) || !this.isUtf8Boundary(endByte))) {
            this.rejectedEdits += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "not_utf8_boundary")
        }
        if (this.isFileBacked()) {
            let (left, _) = this.splitPieces(startByte)
            // Keep the right side after the removed source span; retain the
            // original file bytes and add only this small inserted buffer.
            let (_, tail) = this.splitPieces(endByte)
            let joined = ArrayList<RangeTextPiece>()
            joined.add(all: left)
            if (insertedBytes.size > 0) {
                joined.add(RangeTextPiece(insertedBytes))
            }
            joined.add(all: tail)
            this.pieces = joined
            this.logicalBytes = this.logicalBytes - (endByte - startByte) + Int64(insertedBytes.size)
        } else {
            let work = ArrayList<Byte>()
            var i: Int64 = 0
            while (i < Int64(this.bytes.size)) {
                work.add(this.bytes[i])
                i += 1
            }
            if (endByte > startByte) {
                work.remove(startByte..endByte)
            }
            var k: Int64 = 0
            while (k < Int64(insertedBytes.size)) {
                work.add(insertedBytes[k], at: startByte + k)
                k += 1
            }
            this.bytes = work.toArray()
            this.logicalBytes = Int64(this.bytes.size)
        }
        let before = this.version
        this.version += 1
        this.appliedEdits += 1
        this.lastAppliedRange = "${startByte}:${endByte}"
        this.lastInsertedByteCount = Int64(insertedBytes.size)
        this.logAcceptedOwnerEdit(before, startByte, endByte, insertedBytes)
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }
}

private class RangeTextWindowController <: CjguiComposableUiController & CjguiComposableUiContextMenuRequestHandler & CjguiComposableUiPlatformThemeConsumer {
    private let store: PlainRangeTextStore
    /// 1b:镜像与会话由**窗口**拥有。消费方只交出 owner 的读/写接缝,并保留只读查询
    /// 句柄;它既没有第二条正文写入路径,也不在 `buildUi` 里轮询恢复回执。
    private var hostWindow: Option<CjguiComposableUiWindow> = None
    private var session: Option<CjguiTextSession> = None
    private var fullTextEvents: Int64 = 0
    /// 窗口拥有会话后仍到达 owner 的范围意图数。必须恒为 0:非零即第二条写入路径复活。
    private var leakedRangeEvents: Int64 = 0
    /// Context-menu state is declarative app state; framework retains and
    /// validates the accepted target/selection ticket behind this request.
    private var contextMenuRequest: Option<CjguiComposableUiContextMenuRequest> = None
    private var contextMenuVisible: Bool = false
    /// A raw-byte path stays available for an inline 64 KiB-bounded preview:
    /// the file bytes never become a second writable owner.
    private let capacityBytes: Int64
    private let fileBacked: Bool
    private var usesDarkAppearance: Bool = true
    private var themeRevision: Int64 = 0

    init(initialText: String, capacityBytes!: Int64 = 65536, refuseFirstEdit!: Bool = false, filePath!: String = "",
        timingDiagnostics!: Bool = false) {
        this.store = PlainRangeTextStore(initialText, refuseFirstEdit: refuseFirstEdit, filePath: filePath,
            maxFileReadBytes: capacityBytes, timingDiagnostics: timingDiagnostics)
        this.capacityBytes = capacityBytes
        this.fileBacked = filePath != ""
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
        return 1 + this.store.appliedEditCount() + this.themeRevision
    }

    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        let dark = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme) ==
            CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        if (dark == this.usesDarkAppearance) {
            return false
        }
        this.usesDarkAppearance = dark
        this.themeRevision += 1
        return true
    }

    public func buildUi(): CjguiComposableUiNode {
        let ink = if (this.usesDarkAppearance) {
            CjguiComposableUiColor(0.92, 0.95, 0.97, 1.0)
        } else {
            CjguiComposableUiColor(0.12, 0.13, 0.16, 1.0)
        }
        let buttonBackground = if (this.usesDarkAppearance) {
            CjguiComposableUiColor(0.16, 0.27, 0.32, 1.0)
        } else {
            CjguiComposableUiColor(0.88, 0.91, 0.94, 1.0)
        }
        let root = cjguiComposableVertical(1, "range-text-root", CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(
            cjguiComposableText(2, "range-text-heading", "Range text consumer (public seam only)",
                CjguiComposableUiStyle(fixedHeight: 24, fontSize: 16.0, textColor: ink)))
        root.add(
            cjguiComposableText(3, "range-text-status", this.statusLine(),
                CjguiComposableUiStyle(fixedHeight: 20, fontSize: 11.0, textColor: ink)))
        if (this.fileBacked) {
            let navigation = cjguiComposableHorizontal(8, "range-text-navigation",
                CjguiComposableUiStyle(gap: 8, fixedHeight: 32))
            navigation.add(
                cjguiComposableButton(5, "range-text-first", "首段", "RANGE_TEXT_FIRST", 102,
                    CjguiComposableUiStyle(fixedWidth: 70, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            navigation.add(
                cjguiComposableButton(6, "range-text-middle", "中段", "RANGE_TEXT_MIDDLE", 102,
                    CjguiComposableUiStyle(fixedWidth: 70, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            navigation.add(
                cjguiComposableButton(7, "range-text-last", "尾段", "RANGE_TEXT_LAST", 102,
                    CjguiComposableUiStyle(fixedWidth: 70, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            root.add(navigation)
        }
        // 正文节点的值 = 窗口拥有的会话镜像。投影与镜像同源 ⇒ 平台代理不会再拿着一份
        // 会话没见过的旧值去表达范围(那正是 native 按旧长度 clamp 的根源)。恢复回执由
        // 窗口在回滚代理之后自己交回会话,消费方不轮询、不自签自认。
        root.add(
            cjguiComposableMultilineTextInput(4, "range-text-body", "", this.mirrorText(), 102,
                CjguiComposableUiStyle(fixedHeight: 420, textColor: ink), tabInsertsText: true))
        let host = cjguiComposableLayerHost(900, "range-text-layer-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(root)
        if (contextMenuVisible) {
            if (let Some(request) <- contextMenuRequest) {
                let menu = cjguiComposableContextMenuLayer(500, "range-text-context-menu", request.layerId,
                    "range-text-body", request.nodeId, request.hostLocalX, request.hostLocalY,
                    CjguiComposableUiStyle(fixedWidth: 184, fixedHeight: 48, background: buttonBackground,
                        border: CjguiComposableUiColor(0.55, 0.55, 0.55, 1.0), textColor: ink, borderWidth: 1,
                        padding: 6, gap: 2))
                menu.add(
                    cjguiComposableButton(501, "range-text-context-select-all", "全选", "RANGE_CONTEXT_SELECT_ALL", 102,
                        CjguiComposableUiStyle(fixedHeight: 34, growX: 1, textColor: ink)))
                host.add(menu)
            }
        }
        return host
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
        return "v${this.store.rangeTextVersion()} bytes=${this.store.byteCount()} source=${if (this.fileBacked) { "file" } else { "memory" }} " +
            "edits=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
            "window=${coverageStart}..${coverageEnd} coverage=${coverage} " +
            "seq=${session.currentEditSeq()} mirror=${session.mirrorRevisionValue()} " +
            "epoch=${session.contextEpochValue()} calibrating=${session.awaitingCalibration()} " +
            "decisions=${window.textSessionRangeDecisionCount()} restored=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} " +
            "last=${this.store.lastAppliedRangeText()} ${this.store.timingSummary()}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && (event.node.actionName == "RANGE_TEXT_FIRST" || event.node.actionName ==
            "RANGE_TEXT_MIDDLE" || event.node.actionName == "RANGE_TEXT_LAST")) {
            if (!this.fileBacked) {
                return CjguiComposableUiDispatchResult(false)
            }
            let bound = match (this.session) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let length = this.store.rangeTextByteLength()
            var target: Int64 = 0
            if (event.node.actionName == "RANGE_TEXT_MIDDLE") {
                target = length / 2
            }
            if (event.node.actionName == "RANGE_TEXT_LAST") {
                target = length - this.capacityBytes / 2
                if (target < 0) {
                    target = 0
                }
            }
            let moved = bound.revealByte(target)
            match (this.hostWindow) {
                case Some(window) => window.requestRefresh()
                case None => ()
            }
            getStdOut().writeln(
                "RANGE_TEXT_PREPARE action=${event.node.actionName} target=${target} " +
                    "window_start=${bound.mirrorSnapshot().startByte} window_bytes=${bound.mirrorSnapshot().text.toArray().size} moved=${moved} " +
                    this.store.timingSummary())
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "RANGE_CONTEXT_SELECT_ALL") {
            let request = match (contextMenuRequest) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let window = match (hostWindow) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let applied = window.invokeContextMenuCommand(request.requestId, "select_all")
            if (applied) {
                getStdOut().writeln("RANGE_CONTEXT_MENU command=select_all request=${request.requestId}")
                getStdOut().flush()
            }
            return CjguiComposableUiDispatchResult(applied)
        }
        if (event.eventKind == 27 && event.text == "select_all") {
            let request = match (contextMenuRequest) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            if (event.node.nodeId != request.nodeId || event.node.resourceId != request.resourceId ||
                event.node.nodeKind != request.nodeKind || event.node.value != request.value) {
                return CjguiComposableUiDispatchResult(false)
            }
            let window = match (hostWindow) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let ticket = match (window.freezeAcceptedSelection(request.nodeId)) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let length = cjguiUtf16Length(request.value)
            let restore = window.requestAcceptedSelectionRestore(ticket, 0, length, 0, length, {
                => if (let Some(current) <- contextMenuRequest) {
                    if (current.requestId == request.requestId) {
                        contextMenuVisible = false
                        window.requestRefresh()
                    }
                }
            })
            return CjguiComposableUiDispatchResult(restore >= 0)
        }
        if (event.eventKind == 36) {
            if (let Some(request) <- contextMenuRequest) {
                if (event.text == "outside:${request.requestId}" || event.text == "escape:${request.requestId}") {
                    contextMenuVisible = false
                    return CjguiComposableUiDispatchResult(true)
                }
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED && event.node.nodeId == 4) {
            // 退役判据:窗口拥有会话后,该节点的范围意图由窗口路由给会话,不再到达 owner。
            // 到达即第二条写入路径复活(或路由失效),显式记账,不静默判决。
            this.leakedRangeEvents += 1
            getStdOut().writeln(
                "RANGE_TEXT_LEAK delta_utf16=${event.selectionStart}:${event.selectionEnd} " +
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

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        if (request.resourceId != 102) {
            return false
        }
        let window = match (hostWindow) {
            case Some(value) => value;
            case None => return false
        }
        let declaration = CjguiComposableUiCommand("select_all", CjguiComposableUiNodeReference.manual(request.nodeId),
            "全选", "", 0, true, false)
        if (!window.declareContextMenuCommand(request.requestId, declaration)) {
            return false
        }
        contextMenuRequest = Some(request)
        contextMenuVisible = true
        getStdOut().writeln(
            "RANGE_CONTEXT_MENU_REQUEST id=${request.requestId} target=${request.nodeId}/${request.resourceId}/${request.nodeKind} projection=${request.projectionVersion} selection=${request.selectionAnchor16}:${request.selectionFocus16}")
        getStdOut().flush()
        return true
    }

    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        if (let Some(request) <- contextMenuRequest) {
            if (request.requestId != requestId) {
                return
            }
        } else {
            return
        }
        contextMenuVisible = false
        contextMenuRequest = None
        getStdOut().writeln("RANGE_CONTEXT_MENU_END request=${requestId} reason=${reason}")
        getStdOut().flush()
        match (hostWindow) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    /// M4 逐笔成本采样用：owner 已接受写入数。
    public func ownerAppliedEditCount(): Int64 {
        return this.store.appliedEditCount()
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
        // 关闭后活计数按释放语义清零；汇总读释放前的终局快照（带绑定身份），
        // 三类守恒：decisions == accepted + refused + zero_write_selections。
        match (window.textSessionTerminalCounters()) {
            case Some(terminal) => return "range_decisions=${terminal.rangeDecisions} " +
                "full_text_events=${this.fullTextEvents} leaked_range_events=${this.leakedRangeEvents} " +
                "session_accepted=${terminal.acceptedEdits} " + "session_refused=${terminal.refusedEdits} " +
                "zero_write_selections=${terminal.zeroWriteSelections} " +
                "binding=${terminal.bindingNodeId}/${terminal.bindingResourceId}/${terminal.bindingNodeKind} " +
                "restored=${terminal.restores} " + "restore_failures=${terminal.restoreFailures} pending=${pending} " +
                "owner_bytes=${this.store.byteCount()} version=${this.store.rangeTextVersion()} " +
                "applied=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
                "${this.store.timingSummary()}"
            case None => ()
        }
        return "range_decisions=${window.textSessionRangeDecisionCount()} " +
            "full_text_events=${this.fullTextEvents} leaked_range_events=${this.leakedRangeEvents} " +
            "session_accepted=${window.textSessionAcceptedCount()} " +
            "session_refused=${window.textSessionRefusedCount()} " + "restored=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} pending=${pending} " +
            "owner_bytes=${this.store.byteCount()} version=${this.store.rangeTextVersion()} " +
            "applied=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
            "${this.store.timingSummary()}"
    }

    public func ownerText(): String {
        return this.store.text()
    }

    public func ownerSnapshot(): String {
        return this.store.ownerSnapshot()
    }

    public func storeTimingSummary(): String {
        return this.store.timingSummary()
    }

    public func close(): Unit {
        this.store.close()
    }
}

private func defaultDocumentText(): String {
    return "# Pharos Mark range text consumer\n" +
        "这个窗口只用导出的 CJGUI 公共包：自己的 source/sink 覆盖一个普通字节数组。\n" +
        "中文、emoji 与 ASCII 混排：😀 世界 hello\n"
}

main(args: Array<String>): Int64 {
    // 测试种子入口：字素语料可由环境注入（普通消费者消费同一公共能力的验收
    // 用）；不设置时保持默认文档。
    let initialText = match (getVariable("RANGE_TEXT_INITIAL")) {
        case Some(seed) => seed
        case None => defaultDocumentText()
    }
    // M3 拒绝恢复探针开关：RANGE_TEXT_REFUSE_FIRST=1 ⇒ store 首笔编辑强制拒绝。
    let refuseFirst = match (getVariable("RANGE_TEXT_REFUSE_FIRST")) {
        case Some(flag) => flag == "1"
        case None => false
    }
    let filePath = match (getVariable("RANGE_TEXT_FILE")) {
        case Some(path) => path
        case None => ""
    }
    var capacityBytes: Int64 = 65536
    if (let Some(capacityText) <- getVariable("RANGE_TEXT_CAPACITY_BYTES")) {
        try {
            let parsed = Int64.parse(capacityText)
            if (parsed >= 4 && parsed <= 1048576) {
                capacityBytes = parsed
            }
        } catch (_) {}
    }
    let timingDiagnostics = match (getVariable("RANGE_TEXT_TIMING")) {
        case Some(flag) => flag == "1"
        case None => false
    }
    let controller = RangeTextWindowController(initialText, capacityBytes: capacityBytes, refuseFirstEdit: refuseFirst,
        filePath: filePath, timingDiagnostics: timingDiagnostics)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Range Text Consumer", 900u32, 620u32,
            rangeTextEditDeltaDelivery: true)
    )
    // 窗口拥有会话:必须在 start 之前绑定,首次投影发布的正文才是镜像。
    let session = controller.attach(host.window())
    let started = host.start()
    let window = host.window()
    if (!started) {
        let progress = window.windowProgress()
        getStdOut().writeln(
            "RANGE_TEXT_START_FAILED native_status=${window.nativeStatus()} " +
                "failure=${progress.lastNativeFailure} pending=${progress.pendingRefreshReason}")
        getStdOut().flush()
        host.close()
        controller.close()
        CjguiMacosApplicationHost.stopApplicationLoop()
        return 1
    }
    // 同一运行内的正文 raster/upload 计数（成本核对）：启用窗口的负载诊断并在
    // READY/SUMMARY 各记录一次，会话身份一致才可比。
    let workloadEnabled = window.setWorkloadDiagnostics(true)
    let workloadBase = window.diagnosticSnapshot(maximumNodes: 1)
    getStdOut().writeln(
        "RANGE_TEXT_READY delivery_enabled=${window.isTextRangeEditDeltaDeliveryEnabled()} " +
            "session_node=${session.boundNode()} session_bound=${session.isBound()} " +
            "mirror_bytes=${window.textSessionMirrorText().toArray().size} " + "owner=${controller.ownerSnapshot()} " +
            "capacity_bytes=${capacityBytes} " + "workload_enabled=${workloadEnabled} " + controller
            .storeTimingSummary())
    getStdOut().writeln(
        "RANGE_TEXT_WORKLOAD phase=baseline state=${workloadBase.status} " + "session=${workloadBase.sessionIdentity} " +
            "raster=${workloadBase.textRasterCount}/${workloadBase.textRasterBytes}/${workloadBase.textRasterMicros} " +
            "upload=${workloadBase.textUploadCount}/${workloadBase.textUploadBytes}/${workloadBase.textUploadMicros}")
    getStdOut().flush()
    var turn: Int64 = 0
    var lastWorkload = workloadBase
    // M4 逐类别成本采样：owner 已接受写入数每次前进时落一行 workload 快照
    // （raster/upload 计数/字节）——写入类别与纯选区/导航（edits 不变）可区分。
    var lastSnapshotEdits: Int64 = controller.ownerAppliedEditCount()
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        turn += 1
        if (turn % 5 == 0) {
            let live = window.diagnosticSnapshot(maximumNodes: 1)
            if (live.status == "ok") {
                lastWorkload = live
            }
        }
        let appliedNow = controller.ownerAppliedEditCount()
        if (appliedNow != lastSnapshotEdits) {
            getStdOut().writeln(
                "RANGE_TEXT_WORKLOAD_STEP edits=${appliedNow} " +
                    "raster=${lastWorkload.textRasterCount}/${lastWorkload.textRasterBytes}/${lastWorkload.textRasterMicros} " +
                    "upload=${lastWorkload.textUploadCount}/${lastWorkload.textUploadBytes}/${lastWorkload.textUploadMicros}")
            getStdOut().flush()
            lastSnapshotEdits = appliedNow
        }
    }
    let workloadFinal = lastWorkload
    if (filePath == "") {
        // Default byte-array mode retains its old full owner-byte snapshot.
        var ownerHex = ""
        let ownerBytes = controller.ownerText().toArray()
        let digits = "0123456789abcdef".toArray()
        var oi: Int64 = 0
        while (oi < Int64(ownerBytes.size)) {
            let v = UInt64(ownerBytes[oi])
            ownerHex += String.fromUtf8(ArrayList<UInt8>([digits[Int64(v / 16u64)], digits[Int64(v % 16u64)]]).toArray())
            oi += 1
        }
        getStdOut().writeln("RANGE_TEXT_OWNER_HEX bytes=${Int64(ownerBytes.size)} hex=${ownerHex}")
    } else {
        // File mode never asks the owner to materialise a whole-document String.
        getStdOut().writeln("RANGE_TEXT_OWNER_SNAPSHOT ${controller.ownerSnapshot()}")
    }
    getStdOut().writeln(
        "RANGE_TEXT_WORKLOAD phase=final state=${workloadFinal.status} " + "session=${workloadFinal.sessionIdentity} " +
            "raster=${workloadFinal.textRasterCount}/${workloadFinal.textRasterBytes}/${workloadFinal.textRasterMicros} " +
            "upload=${workloadFinal.textUploadCount}/${workloadFinal.textUploadBytes}/${workloadFinal.textUploadMicros}")
    getStdOut().writeln("RANGE_TEXT_SUMMARY ${controller.summary()}")
    getStdOut().flush()
    controller.close()
    return 0
}
