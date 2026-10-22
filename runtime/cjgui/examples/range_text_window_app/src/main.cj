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
    let count = if (Int64(bytes.size) < maximumBytes) {
        Int64(bytes.size)
    } else {
        maximumBytes
    }
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

let RANGE_TEXT_WRITER_SETTLED: Int64 = 1
let RANGE_TEXT_WRITER_RETAINED: Int64 = 2
let RANGE_TEXT_WRITER_NOT_ADMITTED: Int64 = 3
let RANGE_TEXT_WRITER_FAILED: Int64 = 4
let RANGE_TEXT_WRITER_MAX_ITEMS: Int64 = 64
let RANGE_TEXT_WRITER_MAX_BYTES: Int64 = 1048576

/// Caller-owned full intent. Capacity refusal returns this exact value so the
/// producer can retry without reconstructing bytes, callbacks or request ids.
public class PlainRangeTextWriterIntent<T> {
    public let operationId: String
    public let payloadIdentity: String
    public let retainedBytes: Int64
    let run: () -> T

    public init(operationId: String, payloadIdentity: String, retainedBytes: Int64, run: () -> T) {
        this.operationId = operationId
        this.payloadIdentity = payloadIdentity
        this.retainedBytes = retainedBytes
        this.run = run
    }
}

public class PlainRangeTextWriterTicket<T> {
    public let operationId: String
    private var kind: Int64 = 0
    private var completedValue: Option<T> = None
    private var failureText: String = ""
    init(operationId: String) {
        this.operationId = operationId
    }
    public func status(): Int64 {
        return this.kind
    }
    public func result(): Option<T> {
        return this.completedValue
    }
    public func failure(): String {
        return this.failureText
    }
    func complete(value: T): Unit {
        this.completedValue = Some(value)
        this.kind = RANGE_TEXT_WRITER_SETTLED
    }
    func fail(reason: String): Unit {
        this.failureText = reason
        this.kind = RANGE_TEXT_WRITER_FAILED
    }
}

private abstract class PlainRangeTextQueuedWriter {
    public let operationId: String
    public let payloadIdentity: String
    public let retainedBytes: Int64
    init(operationId: String, payloadIdentity: String, retainedBytes: Int64) {
        this.operationId = operationId
        this.payloadIdentity = payloadIdentity
        this.retainedBytes = retainedBytes
    }
    public func execute(): Unit
}

private class PlainRangeTextTypedQueuedWriter<T> <: PlainRangeTextQueuedWriter {
    private let intent: PlainRangeTextWriterIntent<T>
    public let ticket: PlainRangeTextWriterTicket<T>
    init(intent: PlainRangeTextWriterIntent<T>, ticket: PlainRangeTextWriterTicket<T>) {
        super(intent.operationId, intent.payloadIdentity, intent.retainedBytes)
        this.intent = intent
        this.ticket = ticket
    }
    public override func execute(): Unit {
        try {
            this.ticket.complete(this.intent.run())
        } catch (error: Exception) {
            this.ticket.fail(error.toString())
        }
    }
}

public class PlainRangeTextWriterAdmission<T> {
    public let kind: Int64
    public let value: Option<T>
    public let ticket: Option<PlainRangeTextWriterTicket<T>>
    public let notAdmittedIntent: Option<PlainRangeTextWriterIntent<T>>
    public let reason: String
    init(kind: Int64, value: Option<T>, ticket: Option<PlainRangeTextWriterTicket<T>>,
        notAdmittedIntent: Option<PlainRangeTextWriterIntent<T>>, reason: String) {
        this.kind = kind
        this.value = value
        this.ticket = ticket
        this.notAdmittedIntent = notAdmittedIntent
        this.reason = reason
    }
}

public class PlainRangeTextWriterRetainedException<T> <: Exception {
    public let admission: PlainRangeTextWriterAdmission<T>
    public init(admission: PlainRangeTextWriterAdmission<T>) {
        super("plain range text writer deferred; caller must retain or retry the typed admission")
        this.admission = admission
    }
}

private class PlainRangeTextSelectionTransfer {
    let version: Int64
    let revisionA: Int64
    let anchorA: Int64
    let focusA: Int64
    let revisionB: Int64
    let anchorB: Int64
    let focusB: Int64
    let decision: CjguiSelectionDecision
    init(version: Int64, revisionA: Int64, anchorA: Int64, focusA: Int64, revisionB: Int64, anchorB: Int64,
        focusB: Int64, decision: CjguiSelectionDecision) {
        this.version = version
        this.revisionA = revisionA
        this.anchorA = anchorA
        this.focusA = focusA
        this.revisionB = revisionB
        this.anchorB = anchorB
        this.focusB = focusB
        this.decision = decision
    }
}

private class PlainRangeTextUndoEntry {
    let bytes: Array<Byte>
    let anchorByte: Int64
    let focusByte: Int64
    init(bytes: Array<Byte>, anchorByte: Int64, focusByte: Int64) {
        this.bytes = bytes
        this.anchorByte = anchorByte
        this.focusByte = focusByte
    }
}

/// Plain byte-array or file-span truth. Reads are bounded; the sink is the only
/// writer and refuses a base version it no longer holds.
/// 选择写作的可选接缝（CjguiRangeTextSelectionEditSink）只在声明该接口的平台上
/// 由下面的扩展 conform；选择能力本身（owner/source snapshot）不在这里丢失。
class PlainRangeTextStore <: CjguiRangeTextSource & CjguiRangeTextEditSink & CjguiRangeTextSelectionOwner {
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
    /// This store is consumed on the application's single owner executor. The native decision port
    /// is atomic/scalar-only; queued closures run only after a terminal is folded by that executor.
    private var selectionAnchorByte: Int64 = 0
    private var selectionFocusByte: Int64 = 0
    private var selectionRevision: Int64 = 0
    /// Stable logical identity for this owner lifetime. File-backed instances use
    /// their configured source path; the in-memory example has one named source.
    private let selectionDocumentId: String
    private let selectionSessionEpoch: Int64 = 1
    private let selectionViewGeneration: Int64 = 1
    private var selectionTransfer: Option<PlainRangeTextSelectionTransfer> = None
    private let retainedWriters: ArrayList<PlainRangeTextQueuedWriter> = ArrayList<PlainRangeTextQueuedWriter>()
    private var retainedWriterBytes: Int64 = 0
    private let undoHistory: ArrayList<PlainRangeTextUndoEntry> = ArrayList<PlainRangeTextUndoEntry>()
    private let redoHistory: ArrayList<PlainRangeTextUndoEntry> = ArrayList<PlainRangeTextUndoEntry>()
    private let enableUndoHistory: Bool
    private var nextWriterId: Int64 = 1

    init(text: String, refuseFirstEdit!: Bool = false, filePath!: String = "", maxFileReadBytes!: Int64 = 65536,
        timingDiagnostics!: Bool = false, enableUndoHistory!: Bool = false) {
        this.filePath = filePath
        this.selectionDocumentId = if (filePath == "") {
            "cjgui-range-text-window-app:memory"
        } else {
            "cjgui-range-text-window-app:file:${filePath}"
        }
        this.maxFileReadBytes = if (maxFileReadBytes < 4) {
            4
        } else {
            maxFileReadBytes
        }
        this.timingDiagnostics = timingDiagnostics
        this.enableUndoHistory = enableUndoHistory
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
        let intent = PlainRangeTextWriterIntent<Unit>(this.nextWriterOperationId("close"), "close", 32, {
            => if (let Some(handle) <- this.file) {
                handle.close()
                this.file = None
            }
        })
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind != RANGE_TEXT_WRITER_SETTLED) {
            throw PlainRangeTextWriterRetainedException(admission)
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
        if (ownerEnd > this.logicalBytes) {
            ownerEnd = this.logicalBytes
        }
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
                "owner_hex=${ownerHex} owner_hex_omitted=0")
        getStdOut().flush()
    }

    public func byteCount(): Int64 {
        return this.logicalBytes
    }

    public func rangeTextVersion(): Int64 {
        return this.version
    }

    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot {
        var anchor = this.selectionAnchorByte
        var focus = this.selectionFocusByte
        var revision = this.selectionRevision
        if (let Some(transfer) <- this.selectionTransfer) {
            let state = transfer.decision.state()
            if (state == 3) {
                anchor = transfer.anchorB
                focus = transfer.focusB
                revision = transfer.revisionB
            } else {
                anchor = transfer.anchorA
                focus = transfer.focusA
                revision = transfer.revisionA
            }
            return CjguiSourceSelectionSnapshot(transfer.version, revision, anchor, focus,
                documentId: this.selectionDocumentId, sessionEpoch: this.selectionSessionEpoch,
                viewGeneration: this.selectionViewGeneration)
        }
        return CjguiSourceSelectionSnapshot(this.version, revision, anchor, focus, documentId: this.selectionDocumentId,
            sessionEpoch: this.selectionSessionEpoch, viewGeneration: this.selectionViewGeneration)
    }

    public func setSourceSelection(version: Int64, anchorByte: Int64, focusByte: Int64): Bool {
        let operationId = this.nextWriterOperationId("selection")
        let identity = "${version}:${anchorByte}:${focusByte}"
        let intent = PlainRangeTextWriterIntent<Bool>(
            operationId,
            identity,
            64,
            {
                =>
                    if (this.version != version || !this.validSelectionBytes(anchorByte, focusByte)) {
                        return false
                    }
                    this.installSelection(anchorByte, focusByte)
                    return true
            }
        )
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind == RANGE_TEXT_WRITER_SETTLED) {
            return admission.value.getOrThrow()
        }
        throw PlainRangeTextWriterRetainedException(admission)
    }

    public func reserveSourceSelection(version: Int64, revision: Int64, anchorByte: Int64, focusByte: Int64,
        decision: CjguiSelectionDecision): Int64 {
        if (this.selectionTransfer.isSome() || version != this.version || revision != this.selectionRevision ||
            decision.state() != 1 || !this.validSelectionBytes(anchorByte, focusByte)) {
            return -1
        }
        let reservedRevision = this.selectionRevision + 1
        this.selectionTransfer = Some(
            PlainRangeTextSelectionTransfer(version, this.selectionRevision, this.selectionAnchorByte,
                this.selectionFocusByte, reservedRevision, anchorByte, focusByte, decision))
        return reservedRevision
    }

    public func settleSourceSelection(revision: Int64): Unit {
        if (let Some(transfer) <- this.selectionTransfer) {
            if (transfer.revisionB != revision) {
                return
            }
            let state = transfer.decision.state()
            if (state == 3 || state == 4 || state == 6 || state == 0) {
                if (state == 3) {
                    this.selectionAnchorByte = transfer.anchorB
                    this.selectionFocusByte = transfer.focusB
                    this.selectionRevision = transfer.revisionB
                } else {
                    this.selectionAnchorByte = transfer.anchorA
                    this.selectionFocusByte = transfer.focusA
                    this.selectionRevision = transfer.revisionA
                }
                this.selectionTransfer = None
                let _ = this.drainRetainedWriters()
            }
        }
    }

    public func submitOwnerWriter<T>(intent: PlainRangeTextWriterIntent<T>): PlainRangeTextWriterAdmission<T> {
        if (this.retainedWriters.size > 0 || !this.admitOrFoldSelectionForWriter()) {
            return this.retainOwnerWriter(intent)
        }
        return PlainRangeTextWriterAdmission(RANGE_TEXT_WRITER_SETTLED, Some(intent.run()), None, None, "")
    }

    private func nextWriterOperationId(prefix: String): String {
        let value = this.nextWriterId
        this.nextWriterId += 1
        return "${prefix}-${value}"
    }

    private func validSelectionBytes(anchor: Int64, focus: Int64): Bool {
        return anchor >= 0 && focus >= 0 && anchor <= this.logicalBytes && focus <= this.logicalBytes &&
            this.isUtf8Boundary(anchor) && this.isUtf8Boundary(focus)
    }

    private func installSelection(anchor: Int64, focus: Int64): Unit {
        this.selectionAnchorByte = anchor
        this.selectionFocusByte = focus
        this.selectionRevision += 1
    }

    private func captureUndoEntry(): PlainRangeTextUndoEntry {
        return PlainRangeTextUndoEntry(this.bytes.slice(0, Int64(this.bytes.size)), this.selectionAnchorByte,
            this.selectionFocusByte)
    }

    private func pushUndoEntry(stack: ArrayList<PlainRangeTextUndoEntry>, entry: PlainRangeTextUndoEntry): Unit {
        stack.add(entry)
        while (stack.size > 32) {
            stack.remove(at: 0)
        }
    }

    public func undoOwnerEdit(): Bool {
        let intent = PlainRangeTextWriterIntent<Bool>(
            this.nextWriterOperationId("undo"),
            "undo",
            64,
            {
                =>
                    if (this.isFileBacked() || this.undoHistory.size == 0) {
                        return false
                    }
                    this.pushUndoEntry(this.redoHistory, this.captureUndoEntry())
                    let entry = this.undoHistory.remove(at: this.undoHistory.size - 1)
                    this.bytes = entry.bytes.slice(0, Int64(entry.bytes.size))
                    this.logicalBytes = Int64(this.bytes.size)
                    this.version += 1
                    this.appliedEdits += 1
                    this.lastAppliedRange = "undo"
                    this.lastInsertedByteCount = this.logicalBytes
                    this.installSelection(entry.anchorByte, entry.focusByte)
                    return true
            }
        )
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind == RANGE_TEXT_WRITER_SETTLED) {
            return admission.value.getOrThrow()
        }
        throw PlainRangeTextWriterRetainedException(admission)
    }

    public func redoOwnerEdit(): Bool {
        let intent = PlainRangeTextWriterIntent<Bool>(
            this.nextWriterOperationId("redo"),
            "redo",
            64,
            {
                =>
                    if (this.isFileBacked() || this.redoHistory.size == 0) {
                        return false
                    }
                    this.pushUndoEntry(this.undoHistory, this.captureUndoEntry())
                    let entry = this.redoHistory.remove(at: this.redoHistory.size - 1)
                    this.bytes = entry.bytes.slice(0, Int64(entry.bytes.size))
                    this.logicalBytes = Int64(this.bytes.size)
                    this.version += 1
                    this.appliedEdits += 1
                    this.lastAppliedRange = "redo"
                    this.lastInsertedByteCount = this.logicalBytes
                    this.installSelection(entry.anchorByte, entry.focusByte)
                    return true
            }
        )
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind == RANGE_TEXT_WRITER_SETTLED) {
            return admission.value.getOrThrow()
        }
        throw PlainRangeTextWriterRetainedException(admission)
    }

    private func admitOrFoldSelectionForWriter(): Bool {
        if (let Some(transfer) <- this.selectionTransfer) {
            var state = transfer.decision.state()
            if (state == 1) {
                if (!transfer.decision.admitWriter()) {
                    state = transfer.decision.state()
                } else {
                    state = transfer.decision.state()
                }
            }
            if (state == 2 || state == 5 || state == 1) {
                return false
            }
            if (state == 3) {
                this.selectionAnchorByte = transfer.anchorB
                this.selectionFocusByte = transfer.focusB
                this.selectionRevision = transfer.revisionB
            } else if (state == 4 || state == 6 || state == 0) {
                this.selectionAnchorByte = transfer.anchorA
                this.selectionFocusByte = transfer.focusA
                this.selectionRevision = transfer.revisionA
            } else {
                return false
            }
            this.selectionTransfer = None
        }
        return true
    }

    private func retainOwnerWriter<T>(intent: PlainRangeTextWriterIntent<T>): PlainRangeTextWriterAdmission<T> {
        if (intent.retainedBytes < 0 || intent.retainedBytes > RANGE_TEXT_WRITER_MAX_BYTES ||
            this.retainedWriters.size >= RANGE_TEXT_WRITER_MAX_ITEMS || intent.retainedBytes >
            RANGE_TEXT_WRITER_MAX_BYTES - this.retainedWriterBytes) {
            return PlainRangeTextWriterAdmission(RANGE_TEXT_WRITER_NOT_ADMITTED, None, None, Some(intent),
                "selection_finalization_retention_capacity")
        }
        var index: Int64 = 0
        while (index < this.retainedWriters.size) {
            let existing = this.retainedWriters[index]
            if (existing.operationId == intent.operationId && existing.payloadIdentity == intent.payloadIdentity) {
                if (let Some(typed) <- (existing as PlainRangeTextTypedQueuedWriter<T>)) {
                    return PlainRangeTextWriterAdmission(RANGE_TEXT_WRITER_RETAINED, None, Some(typed.ticket), None, "")
                }
                return PlainRangeTextWriterAdmission(RANGE_TEXT_WRITER_NOT_ADMITTED, None, None, Some(intent),
                    "selection_finalization_operation_type_conflict")
            }
            index += 1
        }
        let ticket = PlainRangeTextWriterTicket<T>(intent.operationId)
        this.retainedWriters.add(PlainRangeTextTypedQueuedWriter<T>(intent, ticket))
        this.retainedWriterBytes += intent.retainedBytes
        return PlainRangeTextWriterAdmission(RANGE_TEXT_WRITER_RETAINED, None, Some(ticket), None, "")
    }

    private func drainRetainedWriters(): Int64 {
        var drained: Int64 = 0
        while (this.retainedWriters.size > 0 && this.admitOrFoldSelectionForWriter()) {
            let task = this.retainedWriters.remove(at: 0)
            this.retainedWriterBytes -= task.retainedBytes
            task.execute()
            drained += 1
        }
        return drained
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

    public func retainedWriterCount(): Int64 {
        return this.retainedWriters.size
    }
    public func retainedWriterByteCount(): Int64 {
        return this.retainedWriterBytes
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

    public func applySourceSelectionEdit(choice: CjguiSourceSelectionSnapshot,
        inserted: String): CjguiRangeTextEditOutcome {
        let insertedBytes = inserted.toArray()
        // The identity includes every frozen owner/source-selection coordinate and the full
        // replacement. A retained intent can therefore never be mistaken for a different write.
        let payloadIdentity = "selection-edit|${choice.documentId.toArray().size}:${choice.documentId}|" +
            "${choice.sessionEpoch}|${choice.viewGeneration}|${choice.version}|${choice.revision}|" +
            "${choice.anchorByte}|${choice.focusByte}|${insertedBytes.size}:${inserted}"
        let operationId = this.nextWriterOperationId("selection-edit")
        let intent = PlainRangeTextWriterIntent<CjguiRangeTextEditOutcome>(operationId,
            payloadIdentity, 128 + Int64(insertedBytes.size), {
                =>
                    let current = this.sourceSelectionSnapshot()
                    if (current.documentId != choice.documentId || current.sessionEpoch != choice.sessionEpoch ||
                        current.viewGeneration != choice.viewGeneration || current.version != choice.version ||
                        current.revision != choice.revision || current.anchorByte != choice.anchorByte ||
                        current.focusByte != choice.focusByte) {
                        this.rejectedEdits += 1
                        return CjguiRangeTextEditOutcome.conflict(this.version, "source_selection_stale")
                    }
                    let startByte = if (choice.anchorByte < choice.focusByte) { choice.anchorByte } else {
                        choice.focusByte
                    }
                    let endByte = if (choice.anchorByte > choice.focusByte) { choice.anchorByte } else {
                        choice.focusByte
                    }
                    return this.applyRangeTextEditNow(choice.version, startByte, endByte, inserted)
            })
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind == RANGE_TEXT_WRITER_SETTLED) {
            return admission.value.getOrThrow()
        }
        // Preserve the same typed retention contract as ordinary range edits. The captured choice
        // is checked only when its real FIFO writer closure executes, after selection finalization.
        throw PlainRangeTextWriterRetainedException(admission)
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        let operationId = this.nextWriterOperationId("body")
        let intent = PlainRangeTextWriterIntent<CjguiRangeTextEditOutcome>(operationId,
            "${baseVersion}:${startByte}:${endByte}:${inserted}", 128 + Int64(inserted.toArray().size), {
                => return this.applyRangeTextEditNow(baseVersion, startByte, endByte, inserted)
            })
        let admission = this.submitOwnerWriter(intent)
        if (admission.kind == RANGE_TEXT_WRITER_SETTLED) {
            return admission.value.getOrThrow()
        }
        // The Sink has no deferred result variant. Propagate a typed ticket/intent instead of
        // returning a rejection that the framework could ACK before this closure later writes.
        throw PlainRangeTextWriterRetainedException(admission)
    }

    private func applyRangeTextEditNow(baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
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
        // A whole-owner replacement drops file spans by reference. It neither
        // reads the removed body nor changes the backing file; only the small
        // inserted String is materialized. Other file edits keep the original
        // bounded span admission, including a large local-window selection.
        let wholeOwnerRange = startByte == 0 && endByte == this.logicalBytes
        if (this.isFileBacked() && endByte - startByte > 128 && !wholeOwnerRange) {
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
        if (this.enableUndoHistory) {
            this.pushUndoEntry(this.undoHistory, this.captureUndoEntry())
            this.redoHistory.clear()
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
        this.installSelection(startByte + Int64(insertedBytes.size), startByte + Int64(insertedBytes.size))
        this.logAcceptedOwnerEdit(before, startByte, endByte, insertedBytes)
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }
}

/// A plain source slice, not a second owner. Its endpoints are absolute UTF-8
/// bytes; only the accepted immutable binding is used by pointer/input events.
class RangeTextPreviewBinding {
    let contextEpoch: Int64
    let ownerVersion: Int64
    let sourceStart: Int64
    let text: String

    init(contextEpoch: Int64, ownerVersion: Int64, sourceStart: Int64, mirrorText: String, maxBytes!: Int64 = 24) {
        this.contextEpoch = contextEpoch
        this.ownerVersion = ownerVersion
        this.sourceStart = sourceStart
        let prefix = ArrayList<UInt8>()
        for (rune in mirrorText.runes()) {
            let encoded = rune.toString().toArray()
            if (prefix.size + encoded.size > maxBytes) {
                break
            }
            for (byte in encoded) {
                prefix.add(byte)
            }
        }
        this.text = String.fromUtf8(prefix.toArray())
    }

    func sourceEnd(): Int64 {
        return this.sourceStart + Int64(this.text.toArray().size)
    }

    /// Validate this accepted preview as an exact byte slice of the current
    /// bounded mirror. A fragment may begin inside the mirror; matching the
    /// entire mirror string would incorrectly reject every nonzero pane.
    func matchesMirror(epoch: Int64, ownerVersion: Int64, mirrorStart: Int64, mirrorText: String): Bool {
        if (this.contextEpoch != epoch || this.ownerVersion != ownerVersion || this.sourceStart < 0 || mirrorStart < 0 ||
            this.sourceStart < mirrorStart) {
            return false
        }
        let localStart = this.sourceStart - mirrorStart
        let expected = this.text.toArray()
        let mirror = mirrorText.toArray()
        let localLength = Int64(expected.size)
        let mirrorLength = Int64(mirror.size)
        if (this.sourceStart > Int64.Max - localLength || mirrorStart > Int64.Max - mirrorLength) {
            return false
        }
        if (localStart > mirrorLength || localLength > mirrorLength - localStart) {
            return false
        }
        let actual = mirror.slice(localStart, localLength)
        if (actual.size != expected.size) {
            return false
        }
        var index: Int64 = 0
        while (index < localLength) {
            if (actual[index] != expected[index]) {
                return false
            }
            index += 1
        }
        return true
    }

    func sameSource(other: RangeTextPreviewBinding): Bool {
        return this.contextEpoch == other.contextEpoch && this.ownerVersion == other.ownerVersion && this.sourceStart == other
            .sourceStart && this.text == other.text
    }

    func sourceRangeUtf16(start16: Int64, end16: Int64): ?(Int64, Int64) {
        if (start16 < 0 || end16 < start16) {
            return None
        }
        let start = match (cjguiUtf16OffsetToUtf8(this.text, start16)) {
            case Some(v) => v;
            case None => return None
        }
        let end = match (cjguiUtf16OffsetToUtf8(this.text, end16)) {
            case Some(v) => v;
            case None => return None
        }
        return Some((this.sourceStart + start, this.sourceStart + end))
    }
}

func rangeTextTwoPaneBindings(contextEpoch: Int64, ownerVersion: Int64, sourceStart: Int64, text: String): Option<(RangeTextPreviewBinding, 
    RangeTextPreviewBinding)> {
    let bytes = text.toArray()
    var split: Int64 = -1
    var i: Int64 = 0
    while (i < Int64(bytes.size)) {
        if (bytes[i] == 10u8) {
            split = i
            break
        }
        i += 1
    }
    if (split < 0) {
        return None
    }
    let first = String.fromUtf8(bytes.slice(0, split))
    let second = String.fromUtf8(bytes.slice(split + 1, Int64(bytes.size) - split - 1))
    return Some(
        (RangeTextPreviewBinding(contextEpoch, ownerVersion, sourceStart, first), RangeTextPreviewBinding(contextEpoch,
                ownerVersion, sourceStart + split + 1, second)))
}

func rangeTextPaneSelection(binding: RangeTextPreviewBinding, anchor: Int64, focus: Int64): (Int64, Int64) {
    let low = if (anchor < focus) {
        anchor
    } else {
        focus
    }
    let high = if (anchor > focus) {
        anchor
    } else {
        focus
    }
    // The owner range is global. The native proxy receives its local
    // intersection, including the exact insertion point for a collapsed range.
    let start = if (low < binding.sourceStart) {
        binding.sourceStart
    } else if (low > binding.sourceEnd()) {
        binding.sourceEnd()
    } else {
        low
    }
    let end = if (high < binding.sourceStart) {
        binding.sourceStart
    } else if (high > binding.sourceEnd()) {
        binding.sourceEnd()
    } else {
        high
    }
    return (start - binding.sourceStart, end - binding.sourceStart)
}

class RangeTextPreviewCaptureRevision {
    private var revision: Int64 = 0
    private var previous: ?RangeTextPreviewBinding = None
    private var liveEpoch: Int64 = -1
    private var liveVersion: Int64 = -1
    private var liveStart: Int64 = -1

    func observe(binding: ?RangeTextPreviewBinding, epoch: Int64, version: Int64, start: Int64): Int64 {
        var sameBinding = binding.isNone() && this.previous.isNone()
        if (let Some(current) <- binding) {
            if (let Some(prior) <- this.previous) {
                sameBinding = prior.sameSource(current)
            }
        }
        if (!sameBinding || epoch != this.liveEpoch || version != this.liveVersion || start != this.liveStart) {
            if (this.revision == Int64.Max) {
                throw Exception("range_preview_capture_revision_exhausted")
            }
            this.revision += 1
            this.previous = binding
            this.liveEpoch = epoch
            this.liveVersion = version
            this.liveStart = start
        }
        return this.revision
    }
}

// 预览选区样式是跨平台的语义投影（同一份 range 用同一份背景色），所以 macOS、
// Windows 与 Linux 共用真实实现；没有该投影能力的平台才返回空，而不是让消费者
// 自己分叉。Linux 的落点依赖框架的选区背景能力版本为 1（显式选区色）：
// runtime_renderer_session.cj 的 internalRendererSelectionBackgroundVersion()，
// 版本不受支持时 composable_ui_window.cj 会具名拒绝整个候选场景。
@When[os == "macOS" || os == "Windows" || os == "Linux"]
func rangeTextPreviewSelectionRuns(start: Int64, end: Int64): Array<CjguiComposableUiTextStyleRun> {
    if (end <= start) {
        return Array<CjguiComposableUiTextStyleRun>()
    }
    return [CjguiComposableUiTextStyleRun.selectionBackground(start, end, CjguiComposableUiColor(0.25, 0.50, 0.85, 0.42))]
}

// 其余（当前主树不产出的）平台：没有选区背景投影，显式返回空数组。
// 这条不再是 Linux 的落点。
@When[os != "macOS" && os != "Windows" && os != "Linux"]
func rangeTextPreviewSelectionRuns(start: Int64, end: Int64): Array<CjguiComposableUiTextStyleRun> {
    return Array<CjguiComposableUiTextStyleRun>()
}

func rangeTextPreviewNode(binding: ?RangeTextPreviewBinding, ink: CjguiComposableUiColor, selectionStart!: Int64 = 0,
    selectionEnd!: Int64 = 0, nodeId!: Int64 = 9, semanticId!: String = "range-text-preview",
    fieldId!: String = "plain-text-preview", resourceId!: Int64 = 102): CjguiComposableUiNode {
    let text = match (binding) {
        case Some(value) => value.text;
        case None => ""
    }
    return cjguiComposableText(nodeId, semanticId, text,
        CjguiComposableUiStyle(fixedHeight: if (text.size > 24) {
            0
        } else {
            34
        }, fontSize: 16.0, textColor: ink, pointerInteractive: true), resourceId: resourceId, fieldId: fieldId,
        displayValueRole: "source-preview", textStyleRuns: rangeTextPreviewSelectionRuns(selectionStart, selectionEnd))
}

/// Resolve a drag point against the two currently accepted preview fragments.
/// The native pointer capture keeps BEGIN's node as `event.node`, so UPDATE and
/// END must use the accepted scene geometry to select the pane under the point.
func rangeTextPreviewTargetNodeAtPoint(firstRect: ?(Int64, Int64, Int64, Int64),
    secondRect: ?(Int64, Int64, Int64, Int64), x: Int64, y: Int64): Int64 {
    if (let Some((left, top, width, height)) <- secondRect) {
        if (x >= left && x <= left + width && y >= top && y <= top + height) {
            return 11
        }
    }
    if (let Some((left, top, width, height)) <- firstRect) {
        if (x >= left && x <= left + width && y >= top && y <= top + height) {
            return 9
        }
    }
    return -1
}

func rangeTextPreviewSourceByteAtHit(preview: RangeTextPreviewBinding, localHit: Int64): ?Int64 {
    if (localHit < 0 || localHit > Int64(preview.text.toArray().size)) {
        return None
    }
    return Some(preview.sourceStart + localHit)
}

class RangeTextWindowController <: CjguiComposableUiController & CjguiComposableUiContextMenuRequestHandler & CjguiComposableUiPlatformThemeConsumer & CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiBusinessOwnerRevisionProvider & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiCompositionRangeProvider & CjguiComposableUiWindowBackgroundProvider & CjguiComposableUiSelectionCompletionProvider {
    private let store: PlainRangeTextStore
    /// 1b:镜像与会话由**窗口**拥有。消费方只交出 owner 的读/写接缝,并保留只读查询
    /// 句柄;它既没有第二条正文写入路径,也不在 `buildUi` 里轮询恢复回执。
    private var hostWindow: Option<CjguiComposableUiWindow> = None
    private var session: Option<CjguiTextSession> = None
    private var fullTextEvents: Int64 = 0
    /// 窗口拥有会话后仍到达 owner 的范围意图数。必须恒为 0:非零即第二条写入路径复活。
    private var leakedRangeEvents: Int64 = 0
    private var recoveryRevision: Int64 = 0
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
    private var previewDecorationRevision: Int64 = 0
    private var candidatePreview: ?RangeTextPreviewBinding = None
    private var acceptedPreview: ?RangeTextPreviewBinding = None
    private var candidateSecondPreview: ?RangeTextPreviewBinding = None
    private var acceptedSecondPreview: ?RangeTextPreviewBinding = None
    private let twoPaneFixture: Bool
    private let previewByteLimit: Int64
    private let previewCaptureRevision = RangeTextPreviewCaptureRevision()
    private var previewDragActive: Bool = false
    private var previewDragRevision: Int64 = -1
    private var previewDragAnchorByte: Int64 = 0
    private var installedPreviewNode: Int64 = -1
    private var candidateSourceCompletion: ?CjguiInstalledSelectionCompletion = None
    private var candidateSourceSelection: ?CjguiComposableUiCandidateSelectionProjection = None
    private var previewPaneOrderReversed: Bool = false
    private var previewSourceShifted: Bool = false
    // Optional ordinary public-API consumer of coordinate-origin handoff.
    // It changes only the local layout prefix; the source/body stay authoritative.
    private let originDemo: Bool = getVariable("RANGE_TEXT_ORIGIN_DEMO") == Some("1")
    private let originViewport = CjguiComposableUiScrollViewport()
    private var originExpanded: Bool = false
    private var originAnchor: ?CjguiComposableUiScrollOriginAnchor = None
    // Durable ordinary visual scene: translate, zIndex hit order, effect groups
    // and paint-only tint/scale/rotate toggles. State is plain app state; the
    // framework owns geometry, painting and hit routing.
    private var visualLabRevision: Int64 = 0
    private var visualLabShifted: Bool = false
    private var visualLabTinted: Bool = false
    private var visualLabScaled: Bool = false
    private var visualLabRotated: Bool = false
    private var visualLabTopClicks: Int64 = 0
    private var visualLabEqualClicks: Int64 = 0
    private var visualLabLastHit: String = "-"

    private func originBinding(): CjguiComposableUiScrollOriginBinding {
        let choice = this.store.sourceSelectionSnapshot()
        return CjguiComposableUiScrollOriginBinding(choice.documentId, choice.version,
            "plain-preview", if (this.originExpanded) { "prefix70" } else { "prefix50" })
    }


    init(initialText: String, capacityBytes!: Int64 = 65536, refuseFirstEdit!: Bool = false, filePath!: String = "",
        timingDiagnostics!: Bool = false, twoPaneFixture!: Bool = false, previewByteLimit!: Int64 = 24) {
        this.store = PlainRangeTextStore(initialText, refuseFirstEdit: refuseFirstEdit, filePath: filePath,
            maxFileReadBytes: capacityBytes, timingDiagnostics: timingDiagnostics,
            enableUndoHistory: twoPaneFixture && filePath == "")
        this.capacityBytes = capacityBytes
        this.fileBacked = filePath != ""
        this.twoPaneFixture = twoPaneFixture && filePath == ""
        this.previewByteLimit = previewByteLimit
        if (this.originDemo) { this.originViewport.requestInitialOffset(40) }
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
        // Public selection, Undo and native input all project the same owner
        // choice. A selection-only change must also refresh the declaration.
        return 1 + this.recoveryRevision + this.store.appliedEditCount() + this.store.sourceSelectionSnapshot().revision + this.themeRevision + this
            .previewDecorationRevision + this.visualLabRevision
    }

    public func uiBusinessOwnerRevision(): Int64 {
        return this.store.rangeTextVersion()
    }

    public func beginSceneRefresh(): Bool {
        this.candidatePreview = None; this.candidateSecondPreview = None
        this.candidateSourceSelection = None
        this.candidateSourceCompletion = match (this.hostWindow) {
            case Some(window) => window.installedSelectionCompletion(); case None => None
        }
        return true
    }
    public func candidateSelectionProjection(): ?CjguiComposableUiCandidateSelectionProjection {
        return this.candidateSourceSelection
    }
    private func freezeCandidatePreviewSelection(): Unit {
        this.candidateSourceSelection = None
        // Literal source input owns the complete bounded mirror. Navigation
        // seals its true source choice before this candidate is constructed;
        // the common handoff supplies actual A, never an expired receipt.
        if (this.installedPreviewNode < 0) {
            let bound = match (this.session) { case Some(value) => value; case None => return }
            let mirror = bound.mirrorSnapshot()
            let selected = this.store.sourceSelectionSnapshot()
            if (!mirror.prepared || mirror.contentVersion != selected.version ||
                mirror.contextEpoch != bound.contextEpochValue()) { return }
            let anchor = selected.anchorByte - mirror.startByte
            let focus = selected.focusByte - mirror.startByte
            let a16 = match (cjguiUtf8OffsetToUtf16(mirror.text, anchor)) { case Some(value) => value; case None => return }
            let f16 = match (cjguiUtf8OffsetToUtf16(mirror.text, focus)) { case Some(value) => value; case None => return }
            this.candidateSourceSelection = Some(CjguiComposableUiCandidateSelectionProjection(
                None, selected, bound.freezeSelectionTicket(),
                "source:${mirror.contextEpoch}:${mirror.contentVersion}:${mirror.startByte}:${mirror.text.size}",
                4, 102, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, mirror.text, a16, f16, focus))
            return
        }
        if (let Some(source) <- this.candidateSourceCompletion) {
            if (source.targetNodeKind != CJGUI_COMPOSABLE_UI_TEXT ||
                (source.targetNodeId != 9 && source.targetNodeId != 11)) { return }
        } else if (this.installedPreviewNode < 0) { return }
        let bound = match (this.session) { case Some(value) => value; case None => return }
        let selected = this.store.sourceSelectionSnapshot()
        for (nodeId in [9, 11]) {
            let preview = match (if (nodeId == 9) { this.candidatePreview } else { this.candidateSecondPreview }) {
                case Some(value) => value; case None => continue
            }
            if (preview.ownerVersion != selected.version || selected.focusByte < preview.sourceStart ||
                selected.focusByte > preview.sourceEnd()) { continue }
            let local = rangeTextPaneSelection(preview, selected.anchorByte, selected.focusByte)
            let a = if (selected.anchorByte <= selected.focusByte) { local[0] } else { local[1] }
            let f = selected.focusByte - preview.sourceStart
            let a16 = match (cjguiUtf8OffsetToUtf16(preview.text, a)) { case Some(value) => value; case None => return }
            let f16 = match (cjguiUtf8OffsetToUtf16(preview.text, f)) { case Some(value) => value; case None => return }
            this.candidateSourceSelection = Some(CjguiComposableUiCandidateSelectionProjection(
                this.candidateSourceCompletion, selected, bound.freezeSelectionTicket(),
                "${preview.contextEpoch}:${preview.ownerVersion}:${preview.sourceStart}:${preview.sourceEnd()}:${nodeId}",
                nodeId, if (nodeId == 11) { 103 } else { 102 }, CJGUI_COMPOSABLE_UI_TEXT, preview.text,
                a16, f16, f))
            return
        }
    }
    private func shiftPreviewSource(preview: RangeTextPreviewBinding): RangeTextPreviewBinding {
        if (!this.previewSourceShifted) { return preview }
        var firstBytes: Int64 = 0
        for (rune in preview.text.runes()) { firstBytes = Int64(rune.toString().size); break }
        let bytes = preview.text.toArray()
        return RangeTextPreviewBinding(preview.contextEpoch, preview.ownerVersion, preview.sourceStart + firstBytes,
            String.fromUtf8(bytes.slice(firstBytes, Int64(bytes.size) - firstBytes)))
    }
    public func prepareSceneRefresh(): Bool {
        if (!this.originDemo) { return true }
        let staged = this.originViewport.stageCoordinateOrigin(this.originBinding(),
            anchor: this.originAnchor, targetNodeId: 9, targetLocalByte: 4)
        getStdOut().writeln("RANGE_TEXT_ORIGIN_STAGE result=${staged} expanded=${this.originExpanded}")
        getStdOut().flush()
        return staged != "scroll_origin_handoff_required" && staged != "scroll_origin_anchor_stale" &&
            staged != "scroll_origin_binding_invalid"
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (this.fileBacked) {
            commands.add(CjguiComposableUiCommand("range-text-tail-selection", 4, CjguiComposableUiShortcut("l", usesShift: true)))
            for ((nodeId, commandId, label) in [(5, "range-text-first", "首"),
                (6, "range-text-middle", "中"), (7, "range-text-last", "尾")]) {
                commands.add(CjguiComposableUiCommand(commandId,
                    CjguiComposableUiNodeReference.manual(nodeId), label, "", 0, true, false))
            }
        }
        if (this.twoPaneFixture) {
            commands.add(CjguiComposableUiCommand("range-text-undo", 14, CjguiComposableUiShortcut("z")))
            commands.add(CjguiComposableUiCommand("range-text-redo", 15,
                CjguiComposableUiShortcut("z", usesShift: true)))
        }
        if (this.twoPaneFixture) {
            commands.add(CjguiComposableUiCommand("range-text-swap-panes", 16,
                CjguiComposableUiShortcut("m", usesShift: true)))
            commands.add(CjguiComposableUiCommand("range-text-shift-source", 17,
                CjguiComposableUiShortcut("n", usesShift: true)))
        }
        if (this.originDemo) {
            commands.add(CjguiComposableUiCommand("range-text-origin-move", 904,
                CjguiComposableUiShortcut("p", usesShift: true)))
        }
        return commands
    }
    public func commitSceneRefresh(): Unit {
        var same = false
        if (let Some(candidate) <- this.candidatePreview) {
            if (let Some(accepted) <- this.acceptedPreview) {
                // A mapping move preserves the source anchor; owner/context
                // replacement retires it. Native certifies the actual handoff.
                same = if ((this as CjguiComposableUiCandidateSelectionProvider).isSome()) {
                    accepted.contextEpoch == candidate.contextEpoch && accepted.ownerVersion == candidate.ownerVersion
                } else { accepted.sameSource(candidate) }
            }
        }
        if (!same) {
            this.previewDragActive = false
            this.previewDragRevision = -1
        }
        if (this.originDemo) {
            getStdOut().writeln("RANGE_TEXT_ORIGIN_COMMIT origin=${this.originBinding().layoutOrigin} " +
                "owner=${this.store.rangeTextVersion()} accepted_offset=${this.originViewport.acceptedOffset()}")
            getStdOut().flush()
            this.originAnchor = None
        }
        this.acceptedPreview = this.candidatePreview
        this.acceptedSecondPreview = this.candidateSecondPreview
        this.candidatePreview = None
        this.candidateSecondPreview = None
        if (this.previewDragActive) {
            if (let Some(bound) <- this.session) {
                this.previewDragRevision = this
                    .previewCaptureRevision
                    .observe(this.acceptedPreview, bound.contextEpochValue(), this.store.rangeTextVersion(),
                        bound.mirrorSnapshot().startByte)
            }
        }
        // The common candidate can install an owner after-image while its
        // source completion is already expired. Consume that actual current
        // receipt instead of starting a second restore from the old source
        // query; a second installation would replace the FIFO predecessor.
        var candidateInstalled = false
        if (let Some(projected) <- this.candidateSourceSelection) {
            if (let Some(window) <- this.hostWindow) {
                if (let Some(completed) <- window.installedSelectionCompletion()) {
                    candidateInstalled = completed.targetNodeId == projected.targetNodeId &&
                        completed.targetResourceId == projected.targetResourceId && completed.targetNodeKind == projected
                        .targetNodeKind && completed.targetBody == projected.targetBody
                }
            }
        }
        if (!candidateInstalled && ((this as CjguiComposableUiCandidateSelectionProvider).isNone() ||
            this.candidateSourceCompletion.isNone())) {
            this.restoreAcceptedPreviewChoice()
        }
        this.candidateSourceSelection = None
    }

    public func selectionInstallationCompleted(completion: CjguiInstalledSelectionCompletion): Unit {
        let selected = this.store.sourceSelectionSnapshot()
        if (completion.sourceSelection.version != selected.version ||
            completion.sourceSelection.revision != selected.revision) { return }
        this.installedPreviewNode = if (completion.targetNodeKind == CJGUI_COMPOSABLE_UI_TEXT &&
            (completion.targetNodeId == 9 || completion.targetNodeId == 11)) {
            completion.targetNodeId
        } else { -1 }
        if (this.twoPaneFixture) {
            getStdOut().writeln("RANGE_TEXT_PREVIEW_COMPLETED transfer=${completion.transferId} " +
                "node=${completion.targetNodeId} resource=${completion.targetResourceId} scene=${completion.targetSceneVersion} " +
                "owner_version=${selected.version} owner_revision=${selected.revision} " +
                "source_anchor=${selected.anchorByte} source_focus=${selected.focusByte} " +
                "proxy_generation=${completion.targetProxyGeneration} proxy_start16=${completion.targetSelectionStart16} " +
                "proxy_end16=${completion.targetSelectionEnd16}")
            getStdOut().flush()
        }
    }

    private var observedCaretTransfer: UInt64 = 0u64
    public func observeAcceptedPreviewCaret(window: CjguiComposableUiWindow): Unit {
        if (!twoPaneFixture) { return }
        let completion = match (candidateSourceCompletion) { case Some(v) => v; case None => return }
        if (completion.transferId == observedCaretTransfer || installedPreviewNode < 0) { return }
        let preview = match (previewForNode(installedPreviewNode)) { case Some(v) => v; case None => return }
        let selected = store.sourceSelectionSnapshot()
        let local = selected.focusByte - preview.sourceStart
        if (local < 0 || local > preview.text.toArray().size) { return }
        let geometry = window.acceptedInputCaret(installedPreviewNode, local,
            window.contentVersionForGeometry(), window.layoutVersionForGeometry())
        if (!geometry.available) { return }
        observedCaretTransfer = completion.transferId
        getStdOut().writeln("RANGE_TEXT_PREVIEW_CARET_VALUE transfer=${completion.transferId} " +
            "node=${installedPreviewNode} available=${geometry.available} x=${geometry.xPt} " +
            "y=${geometry.yPt} h=${geometry.heightPt} scene=${window.inputSceneVersion()}")
        getStdOut().flush()
    }

    // This consumer owns its two plain byte-span maps. After native accepts
    // their new owner version, map the existing choice into that exact pane
    // and submit through the common immutable installation/receipt lifecycle.
    private func restoreAcceptedPreviewChoice(): Unit {
        if (this.installedPreviewNode < 0) { return }
        let bound = match (this.session) { case Some(value) => value; case None => return }
        let window = match (this.hostWindow) { case Some(value) => value; case None => return }
        if (!window.isOpen() || !bound.needsNativeSelectionRestore()) { return }
        let selected = this.store.sourceSelectionSnapshot()
        for (nodeId in [this.installedPreviewNode, if (this.installedPreviewNode == 9) { 11 } else { 9 }]) {
            let preview = match (this.previewForNode(nodeId)) { case Some(value) => value; case None => continue }
            if (preview.ownerVersion != selected.version || selected.focusByte < preview.sourceStart ||
                selected.focusByte > preview.sourceStart + Int64(preview.text.size)) { continue }
            var acceptedMatches = false
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == nodeId && node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT &&
                    node.resourceId == (if (nodeId == 11) { 103 } else { 102 }) &&
                    node.value == preview.text) { acceptedMatches = true }
            }
            if (!acceptedMatches) { continue }
            let ticket = match (window.freezeAcceptedSelection(nodeId)) { case Some(value) => value; case None => continue }
            let local = rangeTextPaneSelection(preview, selected.anchorByte, selected.focusByte)
            let start = match (cjguiUtf8OffsetToUtf16(preview.text, local[0])) { case Some(value) => value; case None => return }
            let end = match (cjguiUtf8OffsetToUtf16(preview.text, local[1])) { case Some(value) => value; case None => return }
            let id = window.requestAcceptedSelectionRestore(ticket, selected.anchorByte, selected.focusByte,
                start, end, { => }, sourceCoordinatesAreBytes: true)
            getStdOut().writeln("RANGE_TEXT_PREVIEW_OWNER_RESTORE id=${id} owner_version=${selected.version} node=${nodeId}")
            getStdOut().flush()
            return
        }
        let _ = window.requestOwnedSelectionRestore()
    }
    public func rollbackSceneRefresh(): Unit {
        this.originAnchor = None
        this.candidatePreview = None; this.candidateSecondPreview = None
        this.candidateSourceSelection = None; this.candidateSourceCompletion = None
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if ((node.nodeId != 9 && node.nodeId != 11) || node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT) {
            return this.uiSceneVersion()
        }
        let bound = match (this.session) {
            case Some(value) => value;
            case None => return this.uiSceneVersion()
        }
        return this
            .previewCaptureRevision
            .observe(this.acceptedPreview, bound.contextEpochValue(), this.store.rangeTextVersion(),
                bound.mirrorSnapshot().startByte)
    }

    private func currentPreview(): ?RangeTextPreviewBinding {
        let preview = match (this.acceptedPreview) {
            case Some(value) => value;
            case None => return None
        }
        let bound = match (this.session) {
            case Some(value) => value;
            case None => return None
        }
        let mirror = bound.mirrorSnapshot()
        if (!mirror.prepared || preview.contextEpoch != bound.contextEpochValue() || preview.ownerVersion !=
            this.store.rangeTextVersion() || mirror.contentVersion != preview.ownerVersion || mirror.contextEpoch != preview
            .contextEpoch ||
            !preview.matchesMirror(mirror.contextEpoch, mirror.contentVersion, mirror.startByte, mirror.text)) {
            return None
        }
        return Some(preview)
    }

    private func previewForNode(nodeId: Int64): ?RangeTextPreviewBinding {
        if (nodeId == 11) {
            let preview = match (this.acceptedSecondPreview) {
                case Some(value) => value;
                case None => return None
            }
            let bound = match (this.session) {
                case Some(value) => value;
                case None => return None
            }
            let mirror = bound.mirrorSnapshot()
            if (!mirror.prepared || preview.contextEpoch != bound.contextEpochValue() || preview.ownerVersion !=
                this.store.rangeTextVersion() || mirror.contentVersion != preview.ownerVersion || mirror.contextEpoch != preview
                .contextEpoch ||
                !preview.matchesMirror(mirror.contextEpoch, mirror.contentVersion, mirror.startByte, mirror.text)) {
                return None
            }
            return Some(preview)
        }
        return this.currentPreview()
    }

    private func windowUtf16ForSourceByte(sourceByte: Int64): Option<Int64> {
        let bound = match (this.session) {
            case Some(value) => value;
            case None => return None
        }
        let mirror = bound.mirrorSnapshot()
        let local = sourceByte - mirror.startByte
        if (local < 0 || local > Int64(mirror.text.toArray().size)) {
            return None
        }
        return cjguiUtf8OffsetToUtf16(mirror.text, local)
    }

    public func prepareCompositionSourceRange(node: CjguiComposableUiLayoutNode, start16: Int64, end16: Int64,
        sceneVersion: Int64): CjguiMappedCompositionRange {
        let window = match (this.hostWindow) {
            case Some(value) => value;
            case None => return CjguiMappedCompositionRange(None, reason: "preview_window_missing")
        }
        let preview = match (this.previewForNode(node.nodeId)) {
            case Some(value) => value;
            case None => return CjguiMappedCompositionRange(None, reason: "preview_source_stale")
        }
        let expectedResource = if (node.nodeId == 11) {
            103
        } else {
            102
        }
        if ((node.nodeId != 9 && node.nodeId != 11) || node.resourceId != expectedResource || node.nodeKind !=
            CJGUI_COMPOSABLE_UI_TEXT || node.value != preview.text || sceneVersion != window
            .windowProjection()
            .acceptedSceneVersion) {
            return CjguiMappedCompositionRange(None, reason: "preview_target_or_scene_stale")
        }
        let range = match (preview.sourceRangeUtf16(start16, end16)) {
            case Some(value) => value;
            case None => return CjguiMappedCompositionRange(None, reason: "preview_utf16_range_invalid")
        }
        let prepared = this.session.getOrThrow().prepareSourceRange(preview.ownerVersion, range[0], range[1])
        getStdOut().writeln(
            "RANGE_TEXT_PREVIEW_RANGE node=${node.nodeId} scene=${sceneVersion} " +
                "source=${range[0]}:${range[1]} version=${preview.ownerVersion} prepared=${prepared.isSome()}")
        getStdOut().flush()
        return CjguiMappedCompositionRange(prepared, reason: if (prepared.isSome()) {
            ""
        } else {
            "preview_prepare_refused"
        })
    }

    private func applyPreviewPointer(event: CjguiComposableUiEvent): Bool {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            this.previewDragActive = false
            this.previewDragRevision = -1
            getStdOut().writeln(
                "RANGE_TEXT_PREVIEW_POINTER phase=cancel owner_version=${this.store.rangeTextVersion()}")
            getStdOut().flush()
            return true
        }
        let begin = event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN
        let end = event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END
        let window = match (this.hostWindow) {
            case Some(value) => value;
            case None => return false
        }
        let revision = this.pointerCaptureVersion(event.node)
        if (!begin && (!this.previewDragActive || revision != this.previewDragRevision)) {
            return false
        }
        let acceptedNodes = window.acceptedSceneNodes()
        var firstAccepted = false
        var secondAccepted = false
        for (node in acceptedNodes) {
            if (node.nodeId == 9 && node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT && node.resourceId == 102 &&
                this.previewForNode(9).isSome() && node.value == this.previewForNode(9).getOrThrow().text) {
                firstAccepted = true
            }
            if (node.nodeId == 11 && node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT && node.resourceId == 103 &&
                this.previewForNode(11).isSome() && node.value == this.previewForNode(11).getOrThrow().text) {
                secondAccepted = true
            }
        }
        if (begin && !firstAccepted && !secondAccepted) {
            return false
        }
        let targetNodeId = if (begin) {
            event.node.nodeId
        } else {
            rangeTextPreviewTargetNodeAtPoint(if (firstAccepted) {
                window.nodeRect(9)
            } else {
                None
            }, if (secondAccepted) {
                window.nodeRect(11)
            } else {
                None
            }, event.pointerX, event.pointerY)
        }
        if (targetNodeId != 9 && targetNodeId != 11) {
            return false
        }
        var targetNode: ?CjguiComposableUiLayoutNode = None
        for (node in acceptedNodes) {
            if (node.nodeId == targetNodeId) {
                targetNode = Some(node)
                break
            }
        }
        let acceptedTarget = match (targetNode) {
            case Some(value) => value;
            case None => return false
        }
        let preview = match (this.previewForNode(targetNodeId)) {
            case Some(value) => value;
            case None => return false
        }
        let expectedResource = if (targetNodeId == 11) {
            103
        } else {
            102
        }
        if (acceptedTarget.nodeKind != CJGUI_COMPOSABLE_UI_TEXT || acceptedTarget.resourceId != expectedResource ||
            acceptedTarget.value != preview.text) {
            return false
        }
        if (begin) {
            window.invalidatePlainPositionBranch()
        }
        let (status, hit, affinity) = window.hitTestComposableTextDetailed(targetNodeId, Float64(event.pointerX),
            Float64(event.pointerY))
        if (status != 0 || hit < 0 || hit > Int64(preview.text.toArray().size)) {
            return false
        }
        let focusByte = match (rangeTextPreviewSourceByteAtHit(preview, hit)) {
            case Some(value) => value;
            case None => return false
        }
        let anchorByte = if (begin) {
            focusByte
        } else {
            this.previewDragAnchorByte
        }
        let anchor16 = match (this.windowUtf16ForSourceByte(anchorByte)) {
            case Some(value) => value;
            case None => return false
        }
        let focus16 = match (this.windowUtf16ForSourceByte(focusByte)) {
            case Some(value) => value;
            case None => return false
        }
        let proxySelectionBytes = rangeTextPaneSelection(preview, anchorByte, focusByte)
        let proxyStart16 = match (cjguiUtf8OffsetToUtf16(preview.text, proxySelectionBytes[0])) {
            case Some(value) => value;
            case None => return false
        }
        let proxyEnd16 = match (cjguiUtf8OffsetToUtf16(preview.text, proxySelectionBytes[1])) {
            case Some(value) => value;
            case None => return false
        }
        let ticket = match (window.freezeAcceptedSelection(targetNodeId)) {
            case Some(value) => value;
            case None => return false
        }
        let submission = window.submitAcceptedSelection(ticket, anchor16, focus16, proxyStart16, proxyEnd16, {
            => this.previewDecorationRevision += 1
        })
        let applied = match (submission) {
            case CjguiSelectionSubmission.Committed => true
            case CjguiSelectionSubmission.Retained(id) =>
                getStdOut().writeln(
                    "RANGE_TEXT_PREVIEW_RETAINED id=${id} source_anchor=${anchorByte} source_focus=${focusByte} owner_written=false")
                true
            case CjguiSelectionSubmission.NotAdmitted(reason) =>
                getStdOut().writeln("RANGE_TEXT_PREVIEW_NOT_ADMITTED reason=${reason}")
                false
        }
        if (begin) {
            // Never replace the BEGIN-era owner certificate with a post-callback value.
            this.previewDragActive = applied && this.pointerCaptureVersion(event.node) == revision
            this.previewDragRevision = if (this.previewDragActive) {
                revision
            } else {
                -1
            }
            if (this.previewDragActive) {
                this.previewDragAnchorByte = anchorByte
            }
        }
        if (end) {
            this.previewDragActive = false
            this.previewDragRevision = -1
        }
        let (ownerSelectionStart16, ownerSelectionEnd16) = this.session.getOrThrow().selection16()
        getStdOut().writeln(
            "RANGE_TEXT_PREVIEW_POINTER phase=${if (begin) { "begin" } else if (end) { "end" } else { "update" }} " +
                "node=${event.node.nodeId} target_node=${targetNodeId} event_scene=${event.projectionVersion} accepted_scene=${window.windowProjection().acceptedSceneVersion} " +
                "source_anchor=${anchorByte} source_focus=${focusByte} " +
                "owner_version=${this.store.rangeTextVersion()} owner_selection_utf16=${ownerSelectionStart16}:${ownerSelectionEnd16} " +
                "affinity=${affinity} applied=${applied}")
        getStdOut().flush()
        return applied
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

    public func candidateWindowBackground(): String {
        return CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
    }

    /// Durable ordinary visual scene. It uses only public style declarations:
    /// translate/zIndex are layout-owned sibling effects, effect groups are
    /// isolated composites, and tint/scale/rotate are paint-only declarations.
    private func visualLabScene(): CjguiComposableUiNode {
        let dark = this.usesDarkAppearance
        let surface = if (dark) { CjguiComposableUiColor(0.15, 0.16, 0.18, 1.0) } else { CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0) }
        let surface2 = if (dark) { CjguiComposableUiColor(0.11, 0.12, 0.14, 1.0) } else { CjguiComposableUiColor(0.98, 0.98, 0.984, 1.0) }
        let ink = if (dark) { CjguiComposableUiColor(0.94, 0.95, 0.96, 1.0) } else { CjguiComposableUiColor(0.09, 0.098, 0.122, 1.0) }
        let secondary = if (dark) { CjguiComposableUiColor(0.68, 0.70, 0.74, 1.0) } else { CjguiComposableUiColor(0.373, 0.396, 0.447, 1.0) }
        let tertiary = if (dark) { CjguiComposableUiColor(0.48, 0.50, 0.55, 1.0) } else { CjguiComposableUiColor(0.545, 0.569, 0.616, 1.0) }
        let line = if (dark) { CjguiComposableUiColor(0.23, 0.24, 0.26, 1.0) } else { CjguiComposableUiColor(0.89, 0.894, 0.914, 1.0) }
        let lineStrong = if (dark) { CjguiComposableUiColor(0.30, 0.31, 0.34, 1.0) } else { CjguiComposableUiColor(0.827, 0.835, 0.863, 1.0) }
        let accent = if (dark) { CjguiComposableUiColor(0.43, 0.58, 1.0, 1.0) } else { CjguiComposableUiColor(0.169, 0.349, 0.847, 1.0) }
        let accentSoft = if (dark) { CjguiComposableUiColor(0.16, 0.20, 0.32, 1.0) } else { CjguiComposableUiColor(0.914, 0.933, 0.988, 1.0) }
        let stage = if (dark) { CjguiComposableUiColor(0.07, 0.075, 0.09, 1.0) } else { CjguiComposableUiColor(0.137, 0.149, 0.18, 1.0) }
        let mutedButton = if (dark) { CjguiComposableUiColor(0.18, 0.19, 0.22, 1.0) } else { CjguiComposableUiColor(0.933, 0.941, 0.957, 1.0) }
        let softGreen = if (dark) { CjguiComposableUiColor(0.16, 0.26, 0.21, 1.0) } else { CjguiComposableUiColor(0.918, 0.945, 0.925, 1.0) }
        let greenInk = if (dark) { CjguiComposableUiColor(0.56, 0.82, 0.67, 1.0) } else { CjguiComposableUiColor(0.212, 0.376, 0.29, 1.0) }
        let onStage = CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
        let onAccent = CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
        let red = CjguiComposableUiColor(0.847, 0.345, 0.247, 1.0)
        let orange = CjguiComposableUiColor(1.0, 0.549, 0.149, 1.0)

        let lab = cjguiComposableVertical(950, "visual-lab",
            CjguiComposableUiStyle(gap: 0, fixedHeight: 317, clipsContent: true))
        let header = cjguiComposableHorizontal(980, "visual-lab-header",
            CjguiComposableUiStyle(fixedHeight: 22, gap: 8))
        header.add(cjguiComposableText(981, "visual-lab-header-title", "视觉语义",
            CjguiComposableUiStyle(fixedHeight: 18, fontSize: 11.0, fontWeight: 600, textColor: secondary)))
        header.add(cjguiComposableVertical(982, "visual-lab-header-spacer",
            CjguiComposableUiStyle(growX: 1, fixedHeight: 1)))
        header.add(cjguiComposableText(983, "visual-lab-header-note", "仅绘制 · 命中随可见位置",
            CjguiComposableUiStyle(fixedHeight: 18, fontSize: 9.5, textColor: tertiary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        lab.add(header)
        lab.add(cjguiComposableVertical(984, "visual-lab-divider-984",
            CjguiComposableUiStyle(fixedHeight: 1, background: lineStrong)))

        let translateRow = cjguiComposableHorizontal(971, "visual-lab-translate-row",
            CjguiComposableUiStyle(fixedHeight: 66, gap: 18))
        let translateCopy = cjguiComposableVertical(9711, "visual-lab-translate-copy",
            CjguiComposableUiStyle(fixedWidth: 242, gap: 3))
        translateCopy.add(cjguiComposableText(9712, "visual-lab-translate-title", "Translate",
            CjguiComposableUiStyle(fixedHeight: 17, fontSize: 13.0, fontWeight: 600, textColor: ink)))
        translateCopy.add(cjguiComposableText(9713, "visual-lab-translate-detail", "绘制右移 24 pt，命中随可见位置。",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, textColor: secondary)))
        translateCopy.add(cjguiComposableText(9714, "visual-lab-translate-boundary", "原位置不再响应",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary)))
        translateRow.add(translateCopy)
        let translateStage = cjguiComposableHorizontal(9715, "visual-lab-translate-stage",
            CjguiComposableUiStyle(fixedHeight: 48, growX: 1, padding: 9, gap: 0, background: surface2,
                border: line, borderWidth: 1, cornerRadius: 8, clipsContent: true,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        translateStage.add(cjguiComposableVertical(9716, "visual-lab-origin-line",
            CjguiComposableUiStyle(fixedWidth: 1, fixedHeight: 28, background: lineStrong)))
        translateStage.add(cjguiComposableVertical(9717, "visual-lab-origin-gap",
            CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 1)))
        translateStage.add(cjguiComposableButton(953, "visual-lab-translate", "点击 · 24 pt", "VISUAL_LAB_TRANSLATE", 0,
            CjguiComposableUiStyle(fixedWidth: 108, fixedHeight: 28, background: accent, textColor: onAccent,
                cornerRadius: 6, fontSize: 10.5,
                translateX: if (this.visualLabShifted) { 24.0 } else { 0.0 })))
        translateRow.add(translateStage)
        let translateRead = cjguiComposableVertical(9718, "visual-lab-translate-read",
            CjguiComposableUiStyle(fixedWidth: 142, gap: 2, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END))
        translateRead.add(cjguiComposableText(9719, "visual-lab-translate-dx",
            "dx ${if (this.visualLabShifted) { 24 } else { 0 }}",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: secondary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        translateRead.add(cjguiComposableText(9720, "visual-lab-translate-hit", "last hit ${this.visualLabLastHit}",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        translateRow.add(translateRead)
        lab.add(translateRow)
        lab.add(cjguiComposableVertical(985, "visual-lab-divider-985",
            CjguiComposableUiStyle(fixedHeight: 1, background: line)))

        let zRow = cjguiComposableHorizontal(957, "visual-lab-zindex-row",
            CjguiComposableUiStyle(fixedHeight: 66, gap: 18))
        let zCopy = cjguiComposableVertical(9571, "visual-lab-zindex-copy",
            CjguiComposableUiStyle(fixedWidth: 242, gap: 3))
        zCopy.add(cjguiComposableText(9572, "visual-lab-zindex-title", "zIndex",
            CjguiComposableUiStyle(fixedHeight: 17, fontSize: 13.0, fontWeight: 600, textColor: ink)))
        zCopy.add(cjguiComposableText(9573, "visual-lab-zindex-detail", "上层接收点击，同值保持书写顺序。",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, textColor: secondary)))
        zCopy.add(cjguiComposableText(9574, "visual-lab-zindex-boundary", "先写的在下，后写的在上",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary)))
        zRow.add(zCopy)
        let zStage = cjguiComposableHorizontal(9575, "visual-lab-zindex-stage",
            CjguiComposableUiStyle(fixedHeight: 48, growX: 1, padding: 9, gap: 0, background: surface2,
                border: line, borderWidth: 1, cornerRadius: 8, clipsContent: true,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        let zChips = cjguiComposableHorizontal(9576, "visual-lab-zindex-chips",
            CjguiComposableUiStyle(fixedHeight: 30, gap: 0, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        zChips.add(cjguiComposableButton(958, "visual-lab-under", "底", "VISUAL_LAB_UNDER", 0,
            CjguiComposableUiStyle(fixedWidth: 46, fixedHeight: 28, background: mutedButton, textColor: secondary,
                border: lineStrong, borderWidth: 1, cornerRadius: 6, fontSize: 10.0)))
        zChips.add(cjguiComposableButton(959, "visual-lab-top", "顶", "VISUAL_LAB_TOP", 0,
            CjguiComposableUiStyle(fixedWidth: 66, fixedHeight: 28, translateX: -18.0, zIndex: 1,
                background: surface, textColor: ink, border: accent, borderWidth: 1,
                cornerRadius: 6, fontSize: 10.0)))
        zChips.add(cjguiComposableVertical(9577, "visual-lab-zindex-gap-left",
            CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 1)))
        zChips.add(cjguiComposableVertical(9578, "visual-lab-zindex-divider",
            CjguiComposableUiStyle(fixedWidth: 1, fixedHeight: 24, background: lineStrong)))
        zChips.add(cjguiComposableVertical(9579, "visual-lab-zindex-gap-right",
            CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 1)))
        zChips.add(cjguiComposableButton(961, "visual-lab-equal-first", "先", "VISUAL_LAB_EQUAL_FIRST", 0,
            CjguiComposableUiStyle(fixedWidth: 42, fixedHeight: 28, zIndex: 1, background: softGreen,
                textColor: greenInk, border: lineStrong, borderWidth: 1, cornerRadius: 6, fontSize: 10.0)))
        zChips.add(cjguiComposableButton(962, "visual-lab-equal-second", "后", "VISUAL_LAB_EQUAL_SECOND", 0,
            CjguiComposableUiStyle(fixedWidth: 42, fixedHeight: 28, translateX: -34.0, zIndex: 1,
                background: surface, textColor: ink, border: lineStrong, borderWidth: 1,
                cornerRadius: 6, fontSize: 10.0)))
        zStage.add(zChips)
        zRow.add(zStage)
        let zRead = cjguiComposableVertical(9570, "visual-lab-zindex-read",
            CjguiComposableUiStyle(fixedWidth: 142, gap: 2, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END))
        zRead.add(cjguiComposableText(9569, "visual-lab-zindex-counts",
            "top ${this.visualLabTopClicks} · equal ${this.visualLabEqualClicks}",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: secondary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        zRead.add(cjguiComposableText(9568, "visual-lab-zindex-hit", "last hit ${this.visualLabLastHit}",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        zRow.add(zRead)
        lab.add(zRow)
        lab.add(cjguiComposableVertical(986, "visual-lab-divider-986",
            CjguiComposableUiStyle(fixedHeight: 1, background: line)))

        let groupRow = cjguiComposableHorizontal(963, "visual-lab-groups-row",
            CjguiComposableUiStyle(fixedHeight: 66, gap: 18))
        let groupCopy = cjguiComposableVertical(9631, "visual-lab-groups-copy",
            CjguiComposableUiStyle(fixedWidth: 242, gap: 3))
        groupCopy.add(cjguiComposableText(9632, "visual-lab-groups-title", "EffectGroup",
            CjguiComposableUiStyle(fixedHeight: 17, fontSize: 13.0, fontWeight: 600, textColor: ink)))
        groupCopy.add(cjguiComposableText(9633, "visual-lab-groups-detail", "透明度作用于整组，不逐节点叠加。",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, textColor: secondary)))
        groupCopy.add(cjguiComposableText(9634, "visual-lab-groups-boundary", "单节点组与裁剪组",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary)))
        groupRow.add(groupCopy)
        let groupStage = cjguiComposableHorizontal(9635, "visual-lab-groups-stage",
            CjguiComposableUiStyle(fixedHeight: 48, growX: 1, padding: 7, gap: 9, background: surface2,
                border: line, borderWidth: 1, cornerRadius: 8, clipsContent: true,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        let singleGroup = cjguiComposableVertical(964, "visual-lab-single-group",
            CjguiComposableUiStyle(fixedWidth: 196, fixedHeight: 34, growX: 1, padding: 9,
                background: if (dark) { CjguiComposableUiColor(0.12, 0.14, 0.18, 1.0) } else { CjguiComposableUiColor(0.933, 0.945, 0.969, 1.0) },
                border: line, borderWidth: 1, cornerRadius: 6,
                effectGroup: CjguiComposableUiEffectGroup(opacity: 0.45)))
        singleGroup.add(cjguiComposableText(965, "visual-lab-single-label", "单节点组",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, fontWeight: 600,
                textColor: if (dark) { CjguiComposableUiColor(0.72, 0.78, 0.88, 1.0) } else { CjguiComposableUiColor(0.243, 0.278, 0.341, 1.0) })))
        groupStage.add(singleGroup)
        let multiGroup = cjguiComposableVertical(966, "visual-lab-multi-group",
            CjguiComposableUiStyle(fixedWidth: 196, fixedHeight: 34, growX: 1, padding: 6,
                background: stage, cornerRadius: 6, clipsContent: true,
                effectGroup: CjguiComposableUiEffectGroup(opacity: 0.65)))
        let artRow = cjguiComposableHorizontal(967, "visual-lab-art-row",
            CjguiComposableUiStyle(fixedHeight: 22, gap: 6, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        artRow.add(cjguiComposableImage(968, "visual-lab-glyph", "assets/tint_glyph_white.png",
            CjguiComposableUiStyle(fixedWidth: 22, fixedHeight: 22,
                scaleX: if (this.visualLabScaled) { 1.5 } else { 1.0 },
                scaleY: if (this.visualLabScaled) { 1.5 } else { 1.0 },
                rotateDegrees: if (this.visualLabRotated) { 20.0 } else { 0.0 },
                iconTint: if (this.visualLabTinted) { Some(orange) } else { None }),
            imageResourceId: "visual-lab-glyph-white", imageResourceVersion: 1))
        artRow.add(cjguiComposableText(970, "visual-lab-multi-label", "重叠子内容",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, fontWeight: 600, textColor: onStage)))
        artRow.add(cjguiComposableText(969, "visual-lab-overlay", "z1",
            CjguiComposableUiStyle(fixedWidth: 22, fixedHeight: 14, translateX: -8.0, zIndex: 1,
                background: red, textColor: onStage, fontSize: 8.0, cornerRadius: 3,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)))
        multiGroup.add(artRow)
        groupStage.add(multiGroup)
        groupRow.add(groupStage)
        let groupRead = cjguiComposableVertical(9636, "visual-lab-groups-read",
            CjguiComposableUiStyle(fixedWidth: 142, gap: 2, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END))
        groupRead.add(cjguiComposableText(9637, "visual-lab-groups-isolated", "isolated 2",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: secondary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        groupRead.add(cjguiComposableText(9638, "visual-lab-groups-opacity", "0.45 / 0.65",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        groupRow.add(groupRead)
        lab.add(groupRow)
        lab.add(cjguiComposableVertical(987, "visual-lab-divider-987",
            CjguiComposableUiStyle(fixedHeight: 1, background: line)))

        let tintRow = cjguiComposableHorizontal(952, "visual-lab-tint-row",
            CjguiComposableUiStyle(fixedHeight: 66, gap: 18))
        let tintCopy = cjguiComposableVertical(9521, "visual-lab-tint-copy",
            CjguiComposableUiStyle(fixedWidth: 242, gap: 3))
        tintCopy.add(cjguiComposableText(9522, "visual-lab-tint-title", "Tint & transform",
            CjguiComposableUiStyle(fixedHeight: 17, fontSize: 13.0, fontWeight: 600, textColor: ink)))
        tintCopy.add(cjguiComposableText(9523, "visual-lab-tint-detail", "RGB 与 alpha 相乘，缩放后旋转。",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 10.5, textColor: secondary)))
        tintCopy.add(cjguiComposableText(9524, "visual-lab-tint-boundary", "绕节点中心，不改命中矩形",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: tertiary)))
        tintRow.add(tintCopy)
        let tintStage = cjguiComposableHorizontal(9525, "visual-lab-tint-stage",
            CjguiComposableUiStyle(fixedHeight: 48, growX: 1, padding: 7, gap: 12, background: surface2,
                border: line, borderWidth: 1, cornerRadius: 8, clipsContent: true,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        let tintTile = cjguiComposableHorizontal(9526, "visual-lab-tint-tile",
            CjguiComposableUiStyle(fixedWidth: 36, fixedHeight: 36, background: stage, cornerRadius: 6,
                clipsContent: true, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        tintTile.add(cjguiComposableImage(9527, "visual-lab-tint-glyph", "assets/tint_glyph_red.png",
            CjguiComposableUiStyle(fixedWidth: 28, fixedHeight: 28,
                scaleX: if (this.visualLabScaled) { 1.5 } else { 1.0 },
                scaleY: if (this.visualLabScaled) { 1.5 } else { 1.0 },
                rotateDegrees: if (this.visualLabRotated) { 20.0 } else { 0.0 },
                iconTint: if (this.visualLabTinted) { Some(orange) } else { None }),
            imageResourceId: "visual-lab-glyph-red", imageResourceVersion: 1))
        tintStage.add(tintTile)
        let tintRead = cjguiComposableVertical(9528, "visual-lab-tint-read",
            CjguiComposableUiStyle(growX: 1, gap: 2))
        tintRead.add(cjguiComposableText(9529, "visual-lab-tint-rgb",
            "tint ${if (this.visualLabTinted) { "#ff8c26" } else { "source" }} · " +
                "scale ${if (this.visualLabScaled) { "1.50" } else { "1.00" }} · " +
                "rotate ${if (this.visualLabRotated) { "20°" } else { "0°" }}",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5, textColor: secondary)))
        tintRead.add(cjguiComposableText(9530, "visual-lab-tint-note", "source alpha 0.50 · multiplied, not replaced",
            CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.0, textColor: tertiary)))
        tintStage.add(tintRead)
        tintRow.add(tintStage)
        let tintControls = cjguiComposableHorizontal(9531, "visual-lab-tint-controls",
            CjguiComposableUiStyle(fixedWidth: 142, fixedHeight: 30, gap: 4))
        tintControls.add(cjguiComposableButton(954, "visual-lab-tint", "着色", "VISUAL_LAB_TINT", 0,
            CjguiComposableUiStyle(fixedWidth: 44, fixedHeight: 28,
                background: if (this.visualLabTinted) { accentSoft } else { surface },
                textColor: if (this.visualLabTinted) { accent } else { ink },
                border: if (this.visualLabTinted) { accentSoft } else { lineStrong }, borderWidth: 1,
                cornerRadius: 6, fontSize: 10.0)))
        tintControls.add(cjguiComposableButton(955, "visual-lab-scale", "缩放", "VISUAL_LAB_SCALE", 0,
            CjguiComposableUiStyle(fixedWidth: 44, fixedHeight: 28,
                background: if (this.visualLabScaled) { accentSoft } else { surface },
                textColor: if (this.visualLabScaled) { accent } else { ink },
                border: if (this.visualLabScaled) { accentSoft } else { lineStrong }, borderWidth: 1,
                cornerRadius: 6, fontSize: 10.0)))
        tintControls.add(cjguiComposableButton(956, "visual-lab-rotate", "旋转", "VISUAL_LAB_ROTATE", 0,
            CjguiComposableUiStyle(fixedWidth: 44, fixedHeight: 28,
                background: if (this.visualLabRotated) { accentSoft } else { surface },
                textColor: if (this.visualLabRotated) { accent } else { ink },
                border: if (this.visualLabRotated) { accentSoft } else { lineStrong }, borderWidth: 1,
                cornerRadius: 6, fontSize: 10.0)))
        tintRow.add(tintControls)
        lab.add(tintRow)
        lab.add(cjguiComposableVertical(988, "visual-lab-divider-988",
            CjguiComposableUiStyle(fixedHeight: 1, background: lineStrong)))

        let strip = cjguiComposableHorizontal(951, "visual-lab-status",
            CjguiComposableUiStyle(fixedHeight: 26, gap: 8, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        strip.add(cjguiComposableText(9511, "visual-lab-status-text",
            "last hit ${this.visualLabLastHit} · top ${this.visualLabTopClicks} · equal ${this.visualLabEqualClicks} · " +
                "dx ${if (this.visualLabShifted) { 24 } else { 0 }} · " +
                "tint ${if (this.visualLabTinted) { 1 } else { 0 }} · " +
                "scale ${if (this.visualLabScaled) { 1 } else { 0 }} · " +
                "rotate ${if (this.visualLabRotated) { 1 } else { 0 }}",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 9.5, textColor: tertiary)))
        strip.add(cjguiComposableVertical(9512, "visual-lab-status-spacer",
            CjguiComposableUiStyle(growX: 1, fixedHeight: 1)))
        strip.add(cjguiComposableText(9513, "visual-lab-status-note", "点击控件验证命中与重绘",
            CjguiComposableUiStyle(fixedHeight: 16, fontSize: 9.5, textColor: tertiary,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_END)))
        lab.add(strip)
        return lab
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
        let root = cjguiComposableVertical(1, "range-text-root", CjguiComposableUiStyle(padding: 16, gap: 7))
        let originContent = cjguiComposableVertical(902, "range-text-origin-content", CjguiComposableUiStyle())
        if (this.originDemo) {
            originContent.add(cjguiComposableVertical(903, "range-text-origin-prefix",
                CjguiComposableUiStyle(fixedHeight: if (this.originExpanded) { 70 } else { 50 })))
            root.add(cjguiComposableButton(904, "range-text-origin-move", "移动阅读原点 ⇧⌘P",
                "RANGE_TEXT_ORIGIN_MOVE", 0, CjguiComposableUiStyle(fixedHeight: 30,
                    background: buttonBackground, textColor: ink)))
        }
        root.add(
            cjguiComposableText(2, "range-text-heading", "Range text consumer",
                CjguiComposableUiStyle(fixedHeight: 26, fontSize: 21.0, fontWeight: 600, textColor: ink)))
        root.add(
            cjguiComposableText(301, "range-text-subtitle", "公开 API 消费者，内存持有字节区间",
                CjguiComposableUiStyle(fixedHeight: 15, fontSize: 11.5,
                    textColor: if (this.usesDarkAppearance) {
                        CjguiComposableUiColor(0.68, 0.70, 0.74, 1.0)
                    } else {
                        CjguiComposableUiColor(0.373, 0.396, 0.447, 1.0)
                    })))
        root.add(
            cjguiComposableText(3, "range-text-status", this.statusLine(),
                CjguiComposableUiStyle(fixedHeight: 15, fontSize: 9.5,
                    textColor: if (this.usesDarkAppearance) {
                        CjguiComposableUiColor(0.48, 0.50, 0.55, 1.0)
                    } else {
                        CjguiComposableUiColor(0.545, 0.569, 0.616, 1.0)
                    })))
        root.add(this.visualLabScene())
        if (let Some(window) <- this.hostWindow) {
            let drafts = window.textSessionRecoveryDrafts()
            if (drafts.size > 0) {
                let actions = cjguiComposableHorizontal(20, "range-text-recovery-actions",
                    CjguiComposableUiStyle(gap: 8, fixedHeight: 30))
                actions.add(cjguiComposableButton(21, "range-text-recovery-retrieve", "取回未提交输入",
                    "RANGE_RECOVERY_RETRIEVE", 102, CjguiComposableUiStyle(fixedWidth: 148, fixedHeight: 30,
                    background: buttonBackground, textColor: ink)))
                actions.add(cjguiComposableButton(22, "range-text-recovery-discard", "放弃草稿",
                    "RANGE_RECOVERY_DISCARD", 102, CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 30,
                    background: buttonBackground, textColor: ink)))
                root.add(actions)
            }
        }
        if (let Some(bound) <- this.session) {
            let mirror = bound.mirrorSnapshot()
            if (mirror.prepared && mirror.contentVersion == this.store.rangeTextVersion() && mirror.contextEpoch ==
                bound.contextEpochValue()) {
                this.candidatePreview = Some(
                    RangeTextPreviewBinding(mirror.contextEpoch, mirror.contentVersion, mirror.startByte, mirror.text,
                        maxBytes: this.previewByteLimit))
                if (this.twoPaneFixture) {
                    if (let Some(panes) <- rangeTextTwoPaneBindings(mirror.contextEpoch, mirror.contentVersion,
                        mirror.startByte, mirror.text)) {
                        this.candidatePreview = Some(this.shiftPreviewSource(if (this.previewPaneOrderReversed) { panes[1] } else { panes[0] }))
                        this.candidateSecondPreview = Some(this.shiftPreviewSource(if (this.previewPaneOrderReversed) { panes[0] } else { panes[1] }))
                    }
                }
            }
        }
        this.freezeCandidatePreviewSelection()
        var displayedAnchor: Int64 = 0
        var displayedFocus: Int64 = 0
        let sourceChoice = this.store.sourceSelectionSnapshot()
        if (let Some(candidate) <- this.candidatePreview) {
            if (sourceChoice.version == candidate.ownerVersion) {
                displayedAnchor = sourceChoice.anchorByte
                displayedFocus = sourceChoice.focusByte
            }
        }
        let selectedBytes = if (displayedFocus >= displayedAnchor) {
            displayedFocus - displayedAnchor
        } else {
            displayedAnchor - displayedFocus
        }
        if (this.twoPaneFixture && this.candidatePreview.isSome() && this.candidateSecondPreview.isSome()) {
            let first = this.candidatePreview.getOrThrow()
            let second = this.candidateSecondPreview.getOrThrow()
            let firstSelection = rangeTextPaneSelection(first, displayedAnchor, displayedFocus)
            let secondSelection = rangeTextPaneSelection(second, displayedAnchor, displayedFocus)
            let panes = cjguiComposableHorizontal(12, "range-text-two-pane",
                CjguiComposableUiStyle(gap: 10, fixedHeight: 92, growX: 1))
            panes.add(
                rangeTextPreviewNode(Some(first), ink, selectionStart: firstSelection[0],
                    selectionEnd: firstSelection[1]))
            let secondNode = rangeTextPreviewNode(Some(second), ink, selectionStart: secondSelection[0],
                selectionEnd: secondSelection[1], nodeId: 11, semanticId: "range-text-preview-second",
                fieldId: "plain-text-preview-second", resourceId: 103)
            panes.add(secondNode)
            root.add(panes)
            let controls = cjguiComposableHorizontal(13, "range-text-undo-controls",
                CjguiComposableUiStyle(gap: 8, fixedHeight: 34))
            controls.add(
                cjguiComposableButton(14, "range-text-undo", "撤销并恢复选区", "RANGE_TEXT_UNDO", 0,
                    CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 30, background: buttonBackground,
                        textColor: ink)))
            controls.add(
                cjguiComposableButton(15, "range-text-redo", "重做", "RANGE_TEXT_REDO", 0,
                    CjguiComposableUiStyle(fixedWidth: 70, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            controls.add(cjguiComposableButton(16, "range-text-swap-panes", "交换片段 ⇧⌘M", "RANGE_TEXT_SWAP_PANES", 0,
                CjguiComposableUiStyle(fixedWidth: 135, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            controls.add(cjguiComposableButton(17, "range-text-shift-source", "移动源范围 ⇧⌘N", "RANGE_TEXT_SHIFT_SOURCE", 0,
                CjguiComposableUiStyle(fixedWidth: 145, fixedHeight: 30, background: buttonBackground, textColor: ink)))
            root.add(controls)
        } else {
            let local = if (let Some(binding) <- this.candidatePreview) {
                rangeTextPaneSelection(binding, displayedAnchor, displayedFocus)
            } else {
                (0, 0)
            }
            let previewNode = rangeTextPreviewNode(this.candidatePreview, ink, selectionStart: local[0], selectionEnd: local[1])
            if (this.originDemo) { originContent.add(previewNode) } else { root.add(previewNode) }
        }
        root.add(
            cjguiComposableText(10, "range-text-preview-selection",
                "Plain owner choice ${sourceChoice.anchorByte}:${sourceChoice.focusByte} " +
                    "rev=${sourceChoice.revision} (${selectedBytes} bytes)",
                CjguiComposableUiStyle(fixedHeight: 20, fontSize: 12.0, textColor: ink)))
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
        let displayedBody = this.mirrorText()
        if (displayedBody.size <= 32 && getVariable("CJGUI_WINDOWS_TRACE_TIMING") == Some("1")) {
            if (let Some(bound) <- this.session) {
                getStdOut().writeln("CJGUI_WINDOWS_DISPLAY_CONTROLLER scene=${this.uiSceneVersion()} owner=${this.store.rangeTextVersion()} context=${bound.contextEpochValue()} mirror=${bound.mirrorRevisionValue()} node=4 resource=102 bytes=${displayedBody.size} value_hex=${rangeTextHexPrefix(displayedBody.toArray(), 32)}")
                getStdOut().flush()
            }
        }
        let bodyNode = cjguiComposableMultilineTextInput(4, "range-text-body", "", displayedBody, 102,
            rangeTextBodyStyle(ink), tabInsertsText: true)
        if (this.originDemo) {
            originContent.add(bodyNode)
            let scroll = cjguiComposableScrollArea(901, "range-text-origin-scroll", this.originViewport,
                CjguiComposableUiStyle(fixedHeight: 240, growX: 1))
            scroll.add(originContent); root.add(scroll)
        } else { root.add(bodyNode) }
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
        let selection = this.store.sourceSelectionSnapshot()
        return "v${this.store.rangeTextVersion()} bytes=${this.store.byteCount()} source=${if (this.fileBacked) { "file" } else { "memory" }} " +
            "edits=${this.store.appliedEditCount()} rejected=${this.store.rejectedEditCount()} " +
            "window=${coverageStart}..${coverageEnd} coverage=${coverage} " +
            "seq=${session.currentEditSeq()} mirror=${session.mirrorRevisionValue()} " +
            "epoch=${session.contextEpochValue()} calibrating=${session.awaitingCalibration()} " +
            "decisions=${window.textSessionRangeDecisionCount()} restored=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} " +
            "selection=${selection.anchorByte}:${selection.focusByte} selection_revision=${selection.revision} " +
            "retained_writers=${this.store.retainedWriterCount()} recovery_drafts=${window.textSessionRecoveryDrafts().size} " +
            "last=${this.store.lastAppliedRangeText()} ${this.store.timingSummary()}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName.startsWith("VISUAL_LAB_")) {
            let action = event.node.actionName
            if (action == "VISUAL_LAB_TRANSLATE") {
                this.visualLabShifted = !this.visualLabShifted
                this.visualLabLastHit = "translate"
            }
            if (action == "VISUAL_LAB_TINT") {
                this.visualLabTinted = !this.visualLabTinted
                this.visualLabLastHit = "tint"
            }
            if (action == "VISUAL_LAB_SCALE") {
                this.visualLabScaled = !this.visualLabScaled
                this.visualLabLastHit = "scale"
            }
            if (action == "VISUAL_LAB_ROTATE") {
                this.visualLabRotated = !this.visualLabRotated
                this.visualLabLastHit = "rotate"
            }
            if (action == "VISUAL_LAB_UNDER") { this.visualLabLastHit = "under" }
            if (action == "VISUAL_LAB_TOP") {
                this.visualLabTopClicks += 1
                this.visualLabLastHit = "top"
            }
            if (action == "VISUAL_LAB_EQUAL_FIRST") { this.visualLabLastHit = "equal-first" }
            if (action == "VISUAL_LAB_EQUAL_SECOND") {
                this.visualLabEqualClicks += 1
                this.visualLabLastHit = "equal-second"
            }
            this.visualLabRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && this.originDemo && event.node.actionName == "RANGE_TEXT_ORIGIN_MOVE") {
            let window = match (this.hostWindow) { case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false) }
            let preview = match (this.acceptedPreview) { case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false) }
            this.originAnchor = window.freezeScrollOriginAnchor(this.originViewport, 9, 4,
                "${preview.sourceStart + 4}", this.originBinding())
            if (this.originAnchor.isNone()) { return CjguiComposableUiDispatchResult(false) }
            this.originExpanded = !this.originExpanded
            this.previewDecorationRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && (event.node.actionName == "RANGE_RECOVERY_RETRIEVE" ||
            event.node.actionName == "RANGE_RECOVERY_DISCARD")) {
            let window = match (this.hostWindow) { case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false) }
            let bound = match (this.session) { case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false) }
            let drafts = window.textSessionRecoveryDrafts()
            if (drafts.isEmpty()) { return CjguiComposableUiDispatchResult(false) }
            let draft = drafts[0]
            if (event.node.actionName == "RANGE_RECOVERY_DISCARD") {
                let discarded = bound.discardRecoveryDraft(draft.draftId)
                if (discarded) { this.recoveryRevision += 1; window.requestRefresh() }
                return CjguiComposableUiDispatchResult(discarded)
            }
            if (!bound.canConsumeRecoveryDraft(draft.draftId)) { return CjguiComposableUiDispatchResult(false) }
            let current = this.store.sourceSelectionSnapshot()
            let start = if (current.anchorByte < current.focusByte) { current.anchorByte } else { current.focusByte }
            let end = if (current.anchorByte > current.focusByte) { current.anchorByte } else { current.focusByte }
            let prepared = match (bound.prepareSourceRange(current.version, start, end)) {
                case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
            }
            // Explicit user retrieval is one new owner edit at the current
            // selection. Frozen recovery coordinates remain evidence only.
            let decision = prepared.replace(draft.content)
            if (decision.ticket >= 0) { let _ = bound.acknowledge(decision.ticket, decision.contextEpoch) }
            if (decision.accepted) {
                let consumed = bound.consumeRecoveryDraft(draft.draftId).isSome()
                let _ = window.requestOwnedSelectionRestore()
                this.recoveryRevision += 1; window.requestRefresh()
                getStdOut().writeln("RANGE_TEXT_RECOVERY draft=${draft.draftId} owner_version=${this.store.rangeTextVersion()} consumed=${consumed}")
                getStdOut().flush()
            }
            return CjguiComposableUiDispatchResult(decision.accepted)
        }
        if ((event.node.nodeId == 9 || event.node.nodeId == 11) && event.node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT && (event
            .eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN || event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE || event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL)) {
            return CjguiComposableUiDispatchResult(this.applyPreviewPointer(event))
        }
        if (event.eventKind == 27 && this.twoPaneFixture &&
            (event.node.actionName == "RANGE_TEXT_SWAP_PANES" || event.node.actionName == "RANGE_TEXT_SHIFT_SOURCE")) {
            if (event.node.actionName == "RANGE_TEXT_SWAP_PANES") { this.previewPaneOrderReversed = !this.previewPaneOrderReversed }
            else { this.previewSourceShifted = !this.previewSourceShifted }
            this.previewDecorationRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && (event.node.actionName == "RANGE_TEXT_UNDO" || event.node.actionName ==
            "RANGE_TEXT_REDO")) {
            let bound = match (this.session) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let window = match (this.hostWindow) {
                case Some(value) => value;
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let change = { =>
                let before = this.store.rangeTextVersion()
                let applied = if (event.node.actionName == "RANGE_TEXT_UNDO") {
                    this.store.undoOwnerEdit()
                } else {
                    this.store.redoOwnerEdit()
                }
                (applied, before, this.store.rangeTextVersion())
            }
            // Declaration/owner consumers may use this controller before its
            // native window is started. Live windows use the common handoff;
            // an unstarted declaration has no installed input to transfer.
            let changed = if (window.isOpen()) {
                rangeTextOwnerSelectionTransaction(window, change)
            } else { change()[0] }
            if (changed) {
                let source = this.store.sourceSelectionSnapshot()
                // Undo has already committed to the owner. Refresh its body
                // before mapping that same-version choice into the proxy;
                // revealByte alone does not reload an in-window old mirror.
                let _ = bound.refreshMirror()
                let _ = bound.revealByte(source.anchorByte)
                let _ = bound.selection16()
                let queued = if (window.pendingSelectionRestoreId() >= 0) {
                    true
                } else if (this.installedPreviewNode < 0) {
                    window.requestOwnedSelectionRestore()
                } else {
                    // The preview owns this choice. Its exact new byte-span
                    // map is published by commitSceneRefresh before requesting
                    // the one common restore; a source request here would be
                    // superseded and abort the admitted history input prefix.
                    false
                }
                getStdOut().writeln(
                    "RANGE_TEXT_HISTORY_RESTORE owner_version=${source.version} " +
                        "mirror_version=${bound.mirrorSnapshot().contentVersion} queued=${queued} " +
                        "mapped_after_accept=${this.installedPreviewNode >= 0}")
                getStdOut().flush()
                window.requestRefresh()
            }
            return CjguiComposableUiDispatchResult(changed)
        }
        // Request-local context commands target the body node; handle them
        // before the generic node-4 navigation branch below.
        if (event.eventKind == 27 && event.text == "select_all") {
            let request = match (contextMenuRequest) {
                case Some(value) => value;
                case None =>
                    getStdOut().writeln("RANGE_CONTEXT_SELECT_ALL_REFUSED reason=no_request")
                    getStdOut().flush()
                    return CjguiComposableUiDispatchResult(false)
            }
            let targetMatches = event.node.nodeId == request.nodeId && event.node.resourceId == request.resourceId &&
                event.node.nodeKind == request.nodeKind && event.node.value == request.value
            let window = match (hostWindow) {
                case Some(value) => value;
                case None =>
                    getStdOut().writeln("RANGE_CONTEXT_SELECT_ALL_REFUSED reason=window_missing request=${request.requestId}")
                    getStdOut().flush()
                    return CjguiComposableUiDispatchResult(false)
            }
            getStdOut().writeln("RANGE_CONTEXT_SELECT_ALL request=${request.requestId} target_match=${targetMatches} " +
                "event=${event.node.nodeId}/${event.node.resourceId}/${event.node.nodeKind} " +
                "request_target=${request.nodeId}/${request.resourceId}/${request.nodeKind} " +
                "value_bytes=${event.node.value.toArray().size}/${request.value.toArray().size}")
            getStdOut().flush()
            if (!targetMatches) {
                return CjguiComposableUiDispatchResult(false)
            }
            let frozen = window.freezeAcceptedSelection(request.nodeId)
            getStdOut().writeln("RANGE_CONTEXT_SELECT_ALL_FREEZE request=${request.requestId} frozen=${frozen.isSome()}")
            getStdOut().flush()
            let ticket = match (frozen) {
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
            getStdOut().writeln("RANGE_CONTEXT_SELECT_ALL_RESTORE request=${request.requestId} restore=${restore}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(restore >= 0)
        }
        if (event.eventKind == 27 && (event.node.actionName == "RANGE_TEXT_FIRST" || event.node.actionName ==
            "RANGE_TEXT_MIDDLE" || event.node.actionName == "RANGE_TEXT_LAST" || event.node.nodeId == 4)) {
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
            if (event.node.actionName == "RANGE_TEXT_LAST" || event.node.nodeId == 4) {
                target = length - this.capacityBytes / 2
                if (target < 0) {
                    target = 0
                }
            }
            let window = match (this.hostWindow) { case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false) }
            let requestedTarget = target
            let change = { =>
                let _ = bound.revealByte(requestedTarget)
                let mirror = bound.mirrorSnapshot()
                let bytes = mirror.text.toArray()
                var local = requestedTarget - mirror.startByte
                // The owner may only choose an exact scalar boundary.
                while (local >= 0 && local < Int64(bytes.size) && bytes[local] >= 0x80 && bytes[local] <= 0xBF) { local += 1 }
                if (!mirror.prepared || local < 0 || local > Int64(bytes.size)) { return false }
                let caret = match (cjguiUtf8OffsetToUtf16(mirror.text, local)) { case Some(value) => value; case None => return false }
                bound.setSelection16(caret, caret)
                let choice = this.store.sourceSelectionSnapshot()
                return choice.version == mirror.contentVersion && choice.anchorByte == mirror.startByte + local &&
                    choice.focusByte == choice.anchorByte
            }
            let restoreRequested = rangeTextOwnerSelectionMove(window, change)
            getStdOut().writeln(
                "RANGE_TEXT_PREPARE action=${event.node.actionName} target=${target} " +
                    "window_start=${bound.mirrorSnapshot().startByte} window_bytes=${bound.mirrorSnapshot().text.toArray().size} admitted=${restoreRequested} " +
                    "restore_requested=${restoreRequested} " + this.store.timingSummary())
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(restoreRequested)
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
        if (eventKind == 11) { this.recoveryRevision += 1; return CjguiComposableUiDispatchResult(true) }
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

    // A small file consumer can expose its exact owner at normal shutdown.
    // The same bounded source read is used; a large owner remains metadata-only.
    public func boundedOwnerHex(): String {
        let version = this.store.rangeTextVersion()
        let size = this.store.rangeTextByteLength()
        if (size > 65536) {
            return "available=false reason=owner_exceeds_64KiB version=${version} total=${size}"
        }
        let bytes = ArrayList<Byte>()
        var cursor: Int64 = 0
        while (cursor < size) {
            let slice = this.store.readRangeText(cursor, size - cursor)
            let page = slice.content.toArray()
            let count = Int64(page.size)
            if (!slice.complete || slice.actualStart != cursor || slice.contentVersion != version ||
                this.store.rangeTextVersion() != version || slice.byteLength != size || count <= 0 || count > size -
                cursor) {
                return "available=false reason=owner_snapshot_incomplete version=${version} total=${size}"
            }
            for (byte in page) {
                bytes.add(byte)
            }
            cursor += count
        }
        if (this.store.rangeTextVersion() != version || this.store.rangeTextByteLength() != size) {
            return "available=false reason=owner_snapshot_incomplete version=${version} total=${size}"
        }
        return "available=true version=${version} start=0 bytes=${size} hex=${rangeTextHexPrefix(bytes.toArray(), 65536)}"
    }

    public func storeTimingSummary(): String {
        return this.store.timingSummary()
    }

    public func close(): Unit {
        this.store.close()
    }
}

// 选择型 owner 事务的平台接缝。支持 owner handoff 的平台走共同正典；不支持的平台
// 走正典在同样条件下本来就走的那一步（直接执行事务），不是消费者自己另造的行为。
@When[os == "macOS"]
func rangeTextOwnerSelectionTransaction(window: CjguiComposableUiWindow,
    change: () -> (Bool, Int64, Int64)): Bool {
    return window.performTextOwnerSelectionChange(change)
}

// Linux 显式并入 Windows 支：两者都没有 owner handoff 原生能力，
// 走正典在同样条件下本来就走的那一步（直接执行事务）。见审计文档 §4.2。
@When[os == "Windows" || os == "Linux"]
func rangeTextOwnerSelectionTransaction(window: CjguiComposableUiWindow,
    change: () -> (Bool, Int64, Int64)): Bool {
    return change()[0]
}

@When[os != "macOS" && os != "Windows" && os != "Linux"]
func rangeTextOwnerSelectionTransaction(window: CjguiComposableUiWindow,
    change: () -> (Bool, Int64, Int64)): Bool {
    return change()[0]
}

// Reuse the framework's retained normal-opening intent before any scene.
// 正文样式接缝。Linux 上必须声明指针交付：框架的 isPointerCapturable 对 TEXT 系节点
// 只看 style.pointerInteractive，缺了它点击会被共同层以 "pointer_interactive=false"
// 拒掉，正文永远拿不到 POINTER_BEGIN，也就没有插入点、选择和替换。macOS/Windows
// 保持原样式不动（两条线正在跑各自的验收，不在这里顺手改它们的行为）。
@When[os == "Linux"]
func rangeTextBodyStyle(ink: CjguiComposableUiColor): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(fixedHeight: 360, textColor: ink, pointerInteractive: true)
}

@When[os != "Linux"]
func rangeTextBodyStyle(ink: CjguiComposableUiColor): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(fixedHeight: 360, textColor: ink)
}

// The common pump waits for a visible active window and returns a true A.
@When[os == "macOS"]
func rangeTextInitialFocus(window: CjguiComposableUiWindow): Unit {
    let _ = window.requestInitialOwnedTextFocusRestore()
}
// Linux 与 macOS 同样使用框架的保留式初始焦点意图：Linux 的渲染器同样拥有
// 窗口级文本会话（set_composable_owned_text_session 已声明 node 4），保留意图
// 让共同层在首个已接受场景就绪后把焦点与选区推到原生代理，键盘输入才有去处。
// Windows 保持空实现（该线现状不动）。
@When[os == "Linux"]
func rangeTextInitialFocus(window: CjguiComposableUiWindow): Unit {
    let _ = window.requestInitialOwnedTextFocusRestore()
}

@When[os == "Windows"]
func rangeTextInitialFocus(window: CjguiComposableUiWindow): Unit { }

@When[os != "macOS" && os != "Windows" && os != "Linux"]
func rangeTextInitialFocus(window: CjguiComposableUiWindow): Unit { }

// Selection-only navigation uses the same public common root as Pharos.
@When[os == "macOS"]
func rangeTextOwnerSelectionMove(window: CjguiComposableUiWindow, change: () -> Bool): Bool {
    return window.performTextOwnerSelectionMove(change)
}
@When[os == "Windows" || os == "Linux"]
func rangeTextOwnerSelectionMove(window: CjguiComposableUiWindow, change: () -> Bool): Bool {
    let moved = change()
    if (moved) { let _ = window.requestOwnedSelectionRestore(); window.requestRefresh() }
    return moved
}

@When[os != "macOS" && os != "Windows" && os != "Linux"]
func rangeTextOwnerSelectionMove(window: CjguiComposableUiWindow, change: () -> Bool): Bool {
    let moved = change()
    if (moved) { let _ = window.requestOwnedSelectionRestore(); window.requestRefresh() }
    return moved
}

// owner 回合预算的调度收尾计量只在实现该计量的平台上存在；其余平台不伪造空步骤，
// 预算责任仍由既有的 begin→pumpOneTurn→end 承担。
@When[os == "macOS"]
func finishRangeTextOwnerScheduling(budget: CjguiOwnerTurnBudget): Unit {
    let _ = budget.finishScheduling()
}

// Linux 显式并入 Windows 支：框架侧没有该调度的计量通道（owner_turn_budget.cj
// 的 cjguiSchedulingWorkRevision/cjguiWaitSchedulingWork 在 Linux 是显式 0），
// 消费者不伪造空步骤。
@When[os == "Windows" || os == "Linux"]
func finishRangeTextOwnerScheduling(budget: CjguiOwnerTurnBudget): Unit {
    return
}

@When[os != "macOS" && os != "Windows" && os != "Linux"]
func finishRangeTextOwnerScheduling(budget: CjguiOwnerTurnBudget): Unit {
    return
}

// 可选的选择写作接缝只在声明该接口的框架版本上 conform；实现本身始终在类体内，
// 因此选择能力不因平台而丢失。
@When[os == "macOS"]
extend PlainRangeTextStore <: CjguiRangeTextSelectionEditSink {}

@When[os == "macOS"]
extend RangeTextWindowController <: CjguiComposableUiCandidateSelectionProvider {}

private func defaultDocumentText(): String {
    return "# Pharos Mark range text consumer\n" +
        "这个窗口只用导出的 CJGUI 公共包：自己的 source/sink 覆盖一个普通字节数组。\n" +
        "中文、emoji 与 ASCII 混排：😀 世界 hello\n"
}

private func defaultTwoPaneFixtureText(): String {
    return "first pane: A😀B\nsecond pane: C中文D\n"
}


// An opt-in ordinary consumer of the experimental shared read-only seam. The
// original request is retained through pending; it never supplies input authority.
private class RangeTextSelectionGeometryObserver {
    private var expected: ?CjguiSelectionGeometryRequest = None
    private var completed = ""
    private var lastReason = ""
    private var lastOwnerChoice = ""
    private let observationInstance = match (getVariable("RANGE_TEXT_SELECTION_OBSERVATION_INSTANCE")) {
        case Some(value) => value; case None => "unscoped"
    }
    private func fields(r: CjguiSelectionGeometryRequest): String {
        return "instance=${observationInstance} window=${r.window} binding=${r.binding} " +
            "node=${r.nodeId} version=${r.semantic.contentVersion} revision=${r.semantic.selectionRevision} " +
            "context=${r.semantic.contextEpoch} mirror=${r.semantic.mirrorRevision} sourceVersion=${r.semantic.sourceVersion} " +
            "sourceStart=${r.mirror.startByte} sourceBytes=${r.mirror.text.size} " +
            "anchor16=${r.anchor16} focus16=${r.focus16} anchorByte=${r.anchorByte} focusByte=${r.focusByte}"
    }
    private func stamp(r: CjguiSelectionGeometryRequest): String {
        return "${r.nodeId}:${r.binding}:${r.semantic.contextEpoch}:${r.semantic.mirrorRevision}:" +
            "${r.semantic.sourceVersion}:${r.semantic.contentVersion}:${r.semantic.selectionRevision}:" +
            "${r.mirror.startByte}:${r.mirror.text.size}:${r.anchorByte}:${r.focusByte}"
    }
    public func observe(window: CjguiComposableUiWindow): Unit {
        // Read-only owner-choice evidence is independent of an older pending
        // geometry request. It does not refresh, scroll, install or edit.
        if (let Some(current) <- window.freezeSelectionGeometryRequest()) {
            if (stamp(current) != lastOwnerChoice) {
                getStdOut().writeln("RANGE_TEXT_SELECTION_GEOMETRY reason=choice ${fields(current)}")
                getStdOut().flush(); lastOwnerChoice = stamp(current)
            }
        }
        if (expected.isNone()) {
            let current = match (window.freezeSelectionGeometryRequest()) {
                case Some(value) => value; case None => return
            }
            if (stamp(current) == completed) { return }
            expected = Some(current); lastReason = ""
        }
        let original = expected.getOrThrow()
        let result = window.readAcceptedSelectionGeometry(original, original.focusByte - original.mirror.startByte)
        if (result.reason == "pending_selection_publication") {
            if (lastReason != result.reason) {
                getStdOut().writeln("RANGE_TEXT_SELECTION_GEOMETRY reason=pending_selection_publication ${fields(original)}")
                getStdOut().flush(); lastReason = result.reason
            }
            return
        }
        if (result.reason == "ready") {
            let p = result.position.getOrThrow()
            getStdOut().writeln("RANGE_TEXT_SELECTION_GEOMETRY reason=ready ${fields(original)} " +
                "scene=${p.sceneVersion} lease=${p.layoutLease} displayByte=${p.displayByte} " +
                "screenX=${result.screenX} screenY=${result.screenY} dpi=${result.dpi} bodyHash=${result.bodyHash} " +
                "x=${p.x} y=${p.y} height=${p.height} clipX=${result.visibleBounds[0]} clipY=${result.visibleBounds[1]} " +
                "clipWidth=${result.visibleBounds[2]} clipHeight=${result.visibleBounds[3]}")
            completed = stamp(original)
        } else {
            getStdOut().writeln("RANGE_TEXT_SELECTION_GEOMETRY reason=${result.reason} ${fields(original)}")
        }
        getStdOut().flush(); expected = None
    }
}

main(args: Array<String>): Int64 {
    return cjguiRunMacosApplication({=> runRangeTextApplication(args)})
}

/// 平台应用宿主工厂。普通消费者只依赖框架的最小公共面（CjguiApplicationHost）：
/// 启动、跑一轮、是否还开着、关闭与取窗口都是同一行代码，消费者不复制平台主流程，
/// 也不自带平台分支的启动/关闭逻辑。
@When[os == "macOS"]
private func rangeTextCreateHost(controller: CjguiComposableUiController, title: String): CjguiApplicationHost {
    return CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(title, 900u32, 620u32,
            rangeTextEditDeltaDelivery: true))
}

@When[os == "Windows"]
private func rangeTextCreateHost(controller: CjguiComposableUiController, title: String): CjguiApplicationHost {
    return CjguiWindowsApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(title, 900u32, 620u32,
            rangeTextEditDeltaDelivery: true))
}

// Linux 与 Windows 同参数：窗口/事件泵/帧提交由渲染器（X11 + Vulkan）拥有，
// 这个宿主只拥有已有的 CJGUI 窗口投影、共同操作泵与有序退出。
@When[os == "Linux"]
private func rangeTextCreateHost(controller: CjguiComposableUiController, title: String): CjguiApplicationHost {
    return CjguiLinuxApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(title, 900u32, 620u32,
            rangeTextEditDeltaDelivery: true))
}

private func runRangeTextApplication(args: Array<String>): Int64 {
    let twoPaneFixture = match (getVariable("RANGE_TEXT_TWO_PANE")) {
        case Some(flag) => flag == "1"
        case None => false
    }
    // 测试种子入口：字素语料可由环境注入（普通消费者消费同一公共能力的验收
    // 用）；不设置时保持默认文档。
    let initialText = match (getVariable("RANGE_TEXT_INITIAL")) {
        case Some(seed) => seed
        case None =>
            if (twoPaneFixture) {
                defaultTwoPaneFixtureText()
            } else {
                defaultDocumentText()
            }
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
    var previewByteLimit: Int64 = 24
    if (let Some(limitText) <- getVariable("RANGE_TEXT_PREVIEW_BYTES")) {
        try {
            let limit = Int64.parse(limitText)
            if (limit >= 1 && limit <= capacityBytes) {
                previewByteLimit = limit
            }
        } catch (_) {}
    }
    let controller = RangeTextWindowController(initialText, capacityBytes: capacityBytes, refuseFirstEdit: refuseFirst,
        filePath: filePath, timingDiagnostics: timingDiagnostics, twoPaneFixture: twoPaneFixture,
        previewByteLimit: previewByteLimit)
    let windowTitle = match (getVariable("RANGE_TEXT_WINDOW_TITLE")) {
        case Some(title) => title
        case None => "CJGUI Range Text Consumer"
    }
    let host: CjguiApplicationHost = rangeTextCreateHost(controller, windowTitle)
    // 窗口拥有会话:必须在 start 之前绑定,首次投影发布的正文才是镜像。
    let session = controller.attach(host.window())
    rangeTextInitialFocus(host.window())
    let window = host.window()
    let ownerTurnBudget = CjguiOwnerTurnBudget()
    window.useOwnerTurnBudget(ownerTurnBudget)
    // Startup uses the same retained preparation path as later owner turns.
    let started = host.start()
    if (!started) {
        let progress = window.windowProgress()
        getStdOut().writeln(
            "RANGE_TEXT_START_FAILED native_status=${window.nativeStatus()} " +
                "failure=${progress.lastNativeFailure} pending=${progress.pendingRefreshReason}")
        getStdOut().flush()
        host.close()
        controller.close()
        cjguiStopApplicationLoop()
        return 1
    }
    // 同一运行内的正文 raster/upload 计数（成本核对）：启用窗口的负载诊断并在
    // READY/SUMMARY 各记录一次，会话身份一致才可比。
    let workloadEnabled = window.setWorkloadDiagnostics(true)
    let workloadBase = window.diagnosticScalarSnapshot()
    getStdOut().writeln(
        "RANGE_TEXT_READY delivery_enabled=${window.isTextRangeEditDeltaDeliveryEnabled()} " +
            "starting_preparing=${window.isStartingPreparing()} " +
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
    let selectionGeometryObserver = RangeTextSelectionGeometryObserver()
    let observeSelectionGeometry = getVariable("RANGE_TEXT_SELECTION_GEOMETRY") == Some("1")
    while (host.isOpen()) {
        let _ = ownerTurnBudget.begin()
        let traceTurn = ownerTurnBudget.turnIdentity()
        let traceSpan = window.beginOwnerTraceTurn(traceTurn)
        try {
            let _ = host.pumpOneTurn()
            controller.observeAcceptedPreviewCaret(window)
            if (observeSelectionGeometry) { selectionGeometryObserver.observe(window) }
            turn += 1
            if (turn % 5 == 0) {
                let live = window.diagnosticScalarSnapshot()
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
                if (timingDiagnostics) {
                    // Read the owner after every accepted writer, including Undo
                    // and Redo, through the existing version-checked bounded reader.
                    // This diagnostic work remains inside the complete owner turn.
                    getStdOut().writeln("RANGE_TEXT_OWNER_AFTER_WRITE ${controller.boundedOwnerHex()}")
                }
                getStdOut().flush()
                lastSnapshotEdits = appliedNow
            }
        } finally {
            finishRangeTextOwnerScheduling(ownerTurnBudget)
            window.recordOwnerTraceBoundary(traceTurn, 143u32)
            window.endOwnerTraceTurn(traceTurn, traceSpan)
            ownerTurnBudget.end()
            window.recordOwnerTraceBoundary(traceTurn, 145u32)
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
        let snapshotStarted = MonoTime.now()
        getStdOut().writeln("RANGE_TEXT_OWNER_BOUNDED ${controller.boundedOwnerHex()}")
        getStdOut().flush()
        getStdOut().writeln(
            "RANGE_TEXT_OWNER_BOUNDED_COST wall_us=${(MonoTime.now() - snapshotStarted).toMicroseconds()} " +
                "scope=normal_shutdown_read_format_write_flush")
    }
    getStdOut().writeln(
        "RANGE_TEXT_WORKLOAD phase=final state=${workloadFinal.status} " + "session=${workloadFinal.sessionIdentity} " +
            "raster=${workloadFinal.textRasterCount}/${workloadFinal.textRasterBytes}/${workloadFinal.textRasterMicros} " +
            "upload=${workloadFinal.textUploadCount}/${workloadFinal.textUploadBytes}/${workloadFinal.textUploadMicros}")
    getStdOut().writeln("RANGE_TEXT_SUMMARY ${controller.summary()}")
    getStdOut().flush()
    controller.close()
    // The enclosing macOS entry scope exports after this real cleanup tail.
    return 0
}
