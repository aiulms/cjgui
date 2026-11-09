package cjgui_shared_operation_core

import std.collection.*
import std.sync.*

private const CJGUI_TEXT_DOCUMENT_MAXIMUM_UTF8_BYTES: Int64 = 512 * 1024
private const CJGUI_TEXT_DOCUMENT_DEFAULT_HISTORY_LIMIT: Int64 = 64
private const CJGUI_TEXT_DOCUMENT_MAXIMUM_REPLACEMENTS: Int64 = 64

/// Experimental immutable UTF-8 byte range. Offsets are rejected inside UTF-8
/// scalars and the current conservative UAX #29-informed profile: CRLF,
/// common combining marks/variation selectors/skin tones, ZWJ adjacency and
/// regional-indicator pairs. This is deliberately not a claim of complete
/// extended-grapheme segmentation for every Unicode script/property.
public class CjguiTextDocumentRange {
    public let start: Int64
    public let end: Int64

    public init(start: Int64, end: Int64) {
        this.start = start
        this.end = end
    }
}

/// Experimental point-in-time document truth. `content` is returned only to
/// direct in-process consumers; socket range reads remain separately bounded.
public class CjguiTextDocumentSnapshot {
    public let documentId: Int64
    public let title: String
    public let content: String
    public let version: Int64
    public let positionUnit: String

    public init(documentId: Int64, title: String, content: String, version: Int64) {
        this.documentId = documentId
        this.title = title
        this.content = content
        this.version = version
        this.positionUnit = "UTF8_BYTE"
    }
}

/// Experimental result of one document operation. The affected range refers
/// to the resulting document for a successful mutation; rejected calls leave
/// both truth and history unchanged.
public class CjguiTextDocumentEditResult {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let range: CjguiTextDocumentRange
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        range: CjguiTextDocumentRange,
        reason: String
    ) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.range = range
        this.reason = reason
    }
}

/// One replacement expressed in the byte coordinates of one original
/// document version. A batch is ordered and non-overlapping; it is never
/// interpreted as a sequence of shifting edits.
public class CjguiTextDocumentReplacement {
    public let range: CjguiTextDocumentRange
    public let text: String

    public init(range: CjguiTextDocumentRange, text: String) {
        this.range = range
        this.text = text
    }
}

/// Result of an atomic multi-range text mutation. Each returned range is in
/// the resulting document; one successful batch advances the version once.
public class CjguiTextDocumentBatchEditResult {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let ranges: ArrayList<CjguiTextDocumentRange>
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        ranges: ArrayList<CjguiTextDocumentRange>,
        reason: String
    ) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.ranges = ranges
        this.reason = reason
    }
}

/// Experimental result of a bounded in-memory range read. This is distinct
/// from the socket response so a workspace can preserve the document lock and
/// decide authorization before adapting it to an external protocol.
public class CjguiTextDocumentReadResult {
    public let isAvailable: Bool
    public let isVersionConflict: Bool
    public let version: Int64
    public let range: CjguiTextDocumentRange
    public let content: String
    public let reason: String

    public init(
        isAvailable: Bool,
        isVersionConflict: Bool,
        version: Int64,
        range: CjguiTextDocumentRange,
        content: String,
        reason: String
    ) {
        this.isAvailable = isAvailable
        this.isVersionConflict = isVersionConflict
        this.version = version
        this.range = range
        this.content = content
        this.reason = reason
    }
}

private class CjguiTextDocumentHistoryFragment {
    let originalRange: CjguiTextDocumentRange
    let resultingRange: CjguiTextDocumentRange
    let removedText: String
    let insertedText: String

    init(
        originalRange: CjguiTextDocumentRange,
        resultingRange: CjguiTextDocumentRange,
        removedText: String,
        insertedText: String
    ) {
        this.originalRange = originalRange
        this.resultingRange = resultingRange
        this.removedText = removedText
        this.insertedText = insertedText
    }
}

private class CjguiTextDocumentHistoryEntry {
    let fragments: ArrayList<CjguiTextDocumentHistoryFragment>

    init(fragments: ArrayList<CjguiTextDocumentHistoryFragment>) {
        this.fragments = fragments
    }
}

/// Pure-Cangjie editable text truth shared by window and headless consumers.
/// It uses UTF-8 byte offsets at its public boundary because transport payload
/// sizes are byte based, but rejects positions that would split common joined
/// Unicode sequences. The one mutable body is never delegated to a platform
/// text control; undo/redo retain only changed fragments and are bounded.
public class CjguiTextDocument {
    private let documentIdValue: Int64
    private let titleValue: String
    private let lock: Mutex
    private let historyLimit: Int64
    private var contentValue: String
    private var currentVersion: Int64
    private let undoHistory: ArrayList<CjguiTextDocumentHistoryEntry>
    private let redoHistory: ArrayList<CjguiTextDocumentHistoryEntry>

    public init(documentId: Int64, title: String, content: String, historyLimit!: Int64 = CJGUI_TEXT_DOCUMENT_DEFAULT_HISTORY_LIMIT) {
        if (documentId < 0 || title.size == 0 || content.size > CJGUI_TEXT_DOCUMENT_MAXIMUM_UTF8_BYTES || historyLimit <= 0) {
            throw IllegalArgumentException("invalid_text_document")
        }
        this.documentIdValue = documentId
        this.titleValue = title
        this.lock = Mutex()
        this.historyLimit = historyLimit
        this.contentValue = content
        this.currentVersion = 0
        this.undoHistory = ArrayList<CjguiTextDocumentHistoryEntry>()
        this.redoHistory = ArrayList<CjguiTextDocumentHistoryEntry>()
    }

    public func documentId(): Int64 { return documentIdValue }

    public func version(): Int64 { return synchronized(lock) { currentVersion } }

    public func snapshot(): CjguiTextDocumentSnapshot {
        return synchronized(lock) { CjguiTextDocumentSnapshot(documentIdValue, titleValue, contentValue, currentVersion) }
    }

    public func undoDepth(): Int64 { return synchronized(lock) { undoHistory.size } }

    public func redoDepth(): Int64 { return synchronized(lock) { redoHistory.size } }

    public func insertFromHuman(offset: Int64, text: String): CjguiTextDocumentEditResult {
        return synchronized(lock) { replaceUnlocked(CjguiTextDocumentRange(offset, offset), text, true) }
    }

    public func deleteRangeFromHuman(range: CjguiTextDocumentRange): CjguiTextDocumentEditResult {
        return synchronized(lock) { replaceUnlocked(range, "", true) }
    }

    public func replaceRangeFromHuman(range: CjguiTextDocumentRange, text: String): CjguiTextDocumentEditResult {
        return synchronized(lock) { replaceUnlocked(range, text, true) }
    }

    /// Applies one committed native plain-text projection without treating
    /// its complete adapter string as one complete document replacement. The
    /// native bridge owns UTF-16/marked-text mechanics; this owner converts
    /// the committed before/after projection into one conservative UTF-8
    /// boundary-safe range, so a composition commit remains one human undo
    /// entry and its unchanged prefix/suffix are never re-encoded as business
    /// content. It does not certify full UAX #29 segmentation.
    public func replaceProjectionTextFromHuman(text: String): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            let source = contentValue.toArray()
            let replacement = text.toArray()
            if (source == replacement) {
                return CjguiTextDocumentEditResult(false, false, currentVersion, currentVersion,
                    CjguiTextDocumentRange(0, 0), "unchanged")
            }
            var prefix: Int64 = 0
            while (prefix < source.size && prefix < replacement.size && source[prefix] == replacement[prefix]) {
                prefix += 1
            }
            // A raw UTF-8 prefix may stop inside an accented cluster or a
            // joined emoji. Back up until both old and replacement strings
            // accept the same public byte boundary.
            while (prefix > 0 && (!isTextClusterBoundary(source, prefix) || !isTextClusterBoundary(replacement, prefix))) {
                prefix -= 1
            }
            var sourceEnd = source.size
            var replacementEnd = replacement.size
            while (sourceEnd > prefix && replacementEnd > prefix &&
                source[sourceEnd - 1] == replacement[replacementEnd - 1]) {
                sourceEnd -= 1; replacementEnd -= 1
            }
            // If a common raw suffix starts inside either cluster, retaining
            // it would split that cluster between old and new values. The
            // conservative whole-tail replacement is still one domain edit.
            if (!isTextClusterBoundary(source, sourceEnd) || !isTextClusterBoundary(replacement, replacementEnd)) {
                sourceEnd = source.size; replacementEnd = replacement.size
            }
            let range = CjguiTextDocumentRange(prefix, sourceEnd)
            if (!isTextRangeBoundary(source, range)) {
                return CjguiTextDocumentEditResult(false, false, currentVersion, currentVersion,
                    CjguiTextDocumentRange(0, 0), "invalid_text_boundary")
            }
            return replaceUnlocked(range, String.fromUtf8(replacement.slice(prefix, replacementEnd - prefix)), true)
        }
    }

    public func insertFromExternal(offset: Int64, text: String, expectedVersion: Int64): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            if (expectedVersion != currentVersion) { return versionConflictUnlocked() }
            replaceUnlocked(CjguiTextDocumentRange(offset, offset), text, true)
        }
    }

    public func deleteRangeFromExternal(range: CjguiTextDocumentRange, expectedVersion: Int64): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            if (expectedVersion != currentVersion) { return versionConflictUnlocked() }
            replaceUnlocked(range, "", true)
        }
    }

    public func replaceRangeFromExternal(
        range: CjguiTextDocumentRange,
        text: String,
        expectedVersion: Int64
    ): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            if (expectedVersion != currentVersion) { return versionConflictUnlocked() }
            replaceUnlocked(range, text, true)
        }
    }

    /// Applies replacements expressed against exactly `expectedVersion`. All
    /// ranges are validated before the in-memory truth, version, or history
    /// changes. A caller must re-read after a version conflict.
    public func replaceRangesFromExternal(
        replacements: ArrayList<CjguiTextDocumentReplacement>,
        expectedVersion: Int64
    ): CjguiTextDocumentBatchEditResult {
        return synchronized(lock) {
            if (expectedVersion != currentVersion) { return batchVersionConflictUnlocked() }
            replaceRangesUnlocked(replacements, true)
        }
    }

    public func readRangeFromExternal(
        range: CjguiTextDocumentRange,
        expectedVersion: Int64
    ): CjguiTextDocumentReadResult {
        return synchronized(lock) {
            if (expectedVersion != currentVersion) {
                return CjguiTextDocumentReadResult(false, true, currentVersion,
                    CjguiTextDocumentRange(0, 0), "", "version_conflict")
            }
            let source = contentValue.toArray()
            if (!isTextRangeBoundary(source, range)) {
                return CjguiTextDocumentReadResult(false, false, currentVersion,
                    CjguiTextDocumentRange(0, 0), "", "invalid_text_boundary")
            }
            return CjguiTextDocumentReadResult(true, false, currentVersion,
                CjguiTextDocumentRange(range.start, range.end),
                String.fromUtf8(source.slice(range.start, range.end - range.start)), "available")
        }
    }

    public func acceptsRange(range: CjguiTextDocumentRange): Bool {
        return synchronized(lock) { isTextRangeBoundary(contentValue.toArray(), range) }
    }

    /// Converts the platform text-service unit (UTF-16 code units) to this
    /// module's UTF-8-byte position unit. A half-surrogate, combining-mark or
    /// joined-emoji boundary is rejected instead of silently drifting a
    /// selection into a different document range.
    public func rangeFromUtf16(start: Int64, end: Int64): ?CjguiTextDocumentRange {
        return synchronized(lock) {
            let source = contentValue.toArray()
            if (let Some(startByte) <- utf8OffsetForUtf16(source, start)) {
                if (let Some(endByte) <- utf8OffsetForUtf16(source, end)) {
                    let range = CjguiTextDocumentRange(startByte, endByte)
                    if (isTextRangeBoundary(source, range)) { return Some(range) }
                }
            }
            return None
        }
    }

    public func undoFromHuman(): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            let versionBefore = currentVersion
            if (undoHistory.size > 0) {
                let entry = undoHistory.remove(at: undoHistory.size - 1)
                let inverse = ArrayList<CjguiTextDocumentReplacement>()
                for (fragment in entry.fragments) {
                    inverse.add(CjguiTextDocumentReplacement(fragment.resultingRange, fragment.removedText))
                }
                let result = editResultFromBatch(replaceRangesUnlocked(inverse, false))
                if (result.applied) {
                    retainHistory(redoHistory, entry)
                    return result
                }
                undoHistory.add(entry)
                return result
            }
            CjguiTextDocumentEditResult(false, false, versionBefore, versionBefore,
                CjguiTextDocumentRange(0, 0), "nothing_to_undo")
        }
    }

    public func redoFromHuman(): CjguiTextDocumentEditResult {
        return synchronized(lock) {
            let versionBefore = currentVersion
            if (redoHistory.size > 0) {
                let entry = redoHistory.remove(at: redoHistory.size - 1)
                let forward = ArrayList<CjguiTextDocumentReplacement>()
                for (fragment in entry.fragments) {
                    forward.add(CjguiTextDocumentReplacement(fragment.originalRange, fragment.insertedText))
                }
                let result = editResultFromBatch(replaceRangesUnlocked(forward, false))
                if (result.applied) {
                    retainHistory(undoHistory, entry)
                    return result
                }
                redoHistory.add(entry)
                return result
            }
            CjguiTextDocumentEditResult(false, false, versionBefore, versionBefore,
                CjguiTextDocumentRange(0, 0), "nothing_to_redo")
        }
    }

    private func replaceUnlocked(
        range: CjguiTextDocumentRange,
        replacement: String,
        recordsHistory: Bool
    ): CjguiTextDocumentEditResult {
        return editResultFromBatch(replaceRangesUnlocked(
            ArrayList<CjguiTextDocumentReplacement>([CjguiTextDocumentReplacement(range, replacement)]),
            recordsHistory
        ))
    }

    private func replaceRangesUnlocked(
        replacements: ArrayList<CjguiTextDocumentReplacement>,
        recordsHistory: Bool
    ): CjguiTextDocumentBatchEditResult {
        let versionBefore = currentVersion
        if (replacements.size == 0 || replacements.size > CJGUI_TEXT_DOCUMENT_MAXIMUM_REPLACEMENTS) {
            return rejectedBatchUnlocked("invalid_text_replacement_count")
        }
        let source = contentValue.toArray()
        var priorStart: Int64 = -1
        var priorEnd: Int64 = -1
        var resultingSize = source.size
        for (replacement in replacements) {
            let range = replacement.range
            if (replacement.text.size > CJGUI_TEXT_DOCUMENT_MAXIMUM_UTF8_BYTES ||
                !isTextRangeBoundary(source, range)) {
                return rejectedBatchUnlocked(if (replacement.text.size > CJGUI_TEXT_DOCUMENT_MAXIMUM_UTF8_BYTES) {
                    "document_too_large"
                } else {
                    "invalid_text_boundary"
                })
            }
            if (priorStart >= 0 && (range.start < priorEnd ||
                (range.start == priorStart && range.end == priorEnd))) {
                return rejectedBatchUnlocked("overlapping_text_ranges")
            }
            priorStart = range.start
            priorEnd = range.end
            resultingSize = resultingSize - (range.end - range.start) + replacement.text.size
            if (resultingSize > CJGUI_TEXT_DOCUMENT_MAXIMUM_UTF8_BYTES) {
                return rejectedBatchUnlocked("document_too_large")
            }
        }

        let fragments = ArrayList<CjguiTextDocumentHistoryFragment>()
        let resultingRanges = ArrayList<CjguiTextDocumentRange>()
        let next = ArrayList<Byte>()
        var sourceCursor: Int64 = 0
        var resultingCursor: Int64 = 0
        var isChanged = false
        for (replacement in replacements) {
            let range = replacement.range
            let prefixSize = range.start - sourceCursor
            if (prefixSize > 0) { next.add(all: source.slice(sourceCursor, prefixSize)) }
            resultingCursor += prefixSize
            let removed = String.fromUtf8(source.slice(range.start, range.end - range.start))
            let resultingRange = CjguiTextDocumentRange(resultingCursor, resultingCursor + replacement.text.size)
            fragments.add(CjguiTextDocumentHistoryFragment(range, resultingRange, removed, replacement.text))
            resultingRanges.add(resultingRange)
            next.add(all: replacement.text.toArray())
            resultingCursor += replacement.text.size
            sourceCursor = range.end
            if (removed != replacement.text) { isChanged = true }
        }
        if (sourceCursor < source.size) { next.add(all: source.slice(sourceCursor, source.size - sourceCursor)) }
        if (!isChanged) {
            return CjguiTextDocumentBatchEditResult(true, false, versionBefore, versionBefore,
                resultingRanges, "already_at_target")
        }
        contentValue = String.fromUtf8(next.toArray())
        currentVersion += 1
        if (recordsHistory) {
            retainHistory(undoHistory, CjguiTextDocumentHistoryEntry(fragments))
            while (redoHistory.size > 0) { let _ = redoHistory.remove(at: redoHistory.size - 1) }
        }
        return CjguiTextDocumentBatchEditResult(true, false, versionBefore, currentVersion,
            resultingRanges, "applied")
    }

    private func editResultFromBatch(result: CjguiTextDocumentBatchEditResult): CjguiTextDocumentEditResult {
        let range = if (result.ranges.size > 0) { result.ranges[0] } else { CjguiTextDocumentRange(0, 0) }
        return CjguiTextDocumentEditResult(result.applied, result.isVersionConflict,
            result.versionBefore, result.versionAfter, range, result.reason)
    }

    private func retainHistory(
        history: ArrayList<CjguiTextDocumentHistoryEntry>,
        entry: CjguiTextDocumentHistoryEntry
    ) {
        history.add(entry)
        while (history.size > historyLimit) { let _ = history.remove(at: 0) }
    }

    private func rejectedBatchUnlocked(reason: String): CjguiTextDocumentBatchEditResult {
        return CjguiTextDocumentBatchEditResult(false, false, currentVersion, currentVersion,
            ArrayList<CjguiTextDocumentRange>(), reason)
    }

    private func versionConflictUnlocked(): CjguiTextDocumentEditResult {
        return CjguiTextDocumentEditResult(false, true, currentVersion, currentVersion,
            CjguiTextDocumentRange(0, 0), "version_conflict")
    }

    private func batchVersionConflictUnlocked(): CjguiTextDocumentBatchEditResult {
        return CjguiTextDocumentBatchEditResult(false, true, currentVersion, currentVersion,
            ArrayList<CjguiTextDocumentRange>(), "version_conflict")
    }
}

// Package-visible: the fixed-snapshot handle enforces the SAME UTF-8 cluster
// boundary rule on frozen bytes, so a range the live document accepts is not
// rejected by its own snapshot (and vice versa).
func isTextRangeBoundary(bytes: Array<Byte>, range: CjguiTextDocumentRange): Bool {
    return range.start >= 0 && range.end >= range.start && range.end <= bytes.size &&
        isTextClusterBoundary(bytes, range.start) && isTextClusterBoundary(bytes, range.end)
}

private func utf8OffsetForUtf16(bytes: Array<Byte>, utf16Offset: Int64): ?Int64 {
    if (utf16Offset < 0) { return None }
    var byteOffset: Int64 = 0
    var utf16Count: Int64 = 0
    while (byteOffset < bytes.size) {
        if (utf16Count == utf16Offset) { return Some(byteOffset) }
        let codePoint = codePointAt(bytes, byteOffset)
        let codeUnits: Int64 = if (codePoint > 0xffff) { 2 } else { 1 }
        if (utf16Offset > utf16Count && utf16Offset < utf16Count + codeUnits) { return None }
        utf16Count += codeUnits
        byteOffset += utf8CodePointLength(bytes[byteOffset])
    }
    if (utf16Count == utf16Offset) { return Some(byteOffset) }
    return None
}

private func utf8CodePointLength(firstByte: Byte): Int64 {
    let first = Int64(firstByte)
    if (first < 128) { return 1 }
    if (first < 224) { return 2 }
    if (first < 240) { return 3 }
    return 4
}

private func isTextClusterBoundary(bytes: Array<Byte>, offset: Int64): Bool {
    if (offset == 0 || offset == bytes.size) { return true }
    if (offset < 0 || offset > bytes.size || isUtf8Continuation(bytes[offset])) { return false }
    let current = codePointAt(bytes, offset)
    let previousStart = previousCodePointStart(bytes, offset)
    let previous = codePointAt(bytes, previousStart)
    // Keep CRLF as one hard line-break cluster. A caller that supplied the
    // intermediate UTF-16 position must retry with either side of the pair;
    // translating it to a byte boundary would otherwise split a platform
    // newline into an unintended document edit.
    if (previous == 0x000d && current == 0x000a) { return false }
    if (isCombiningMark(current) || isVariationSelector(current) || isEmojiSkinTone(current) || current == 0x200d) {
        return false
    }
    if (previous == 0x200d) { return false }
    // UAX #29 pairs regional indicators from the start of their consecutive
    // run: RI RI | RI RI. The previous implementation rejected every RI/RI
    // boundary, which made the boundary between a complete flag and the next
    // unpaired indicator impossible to select.
    if (isRegionalIndicator(previous) && isRegionalIndicator(current)) {
        return regionalIndicatorCountBefore(bytes, offset) % 2 == 0
    }
    return true
}

private func regionalIndicatorCountBefore(bytes: Array<Byte>, offset: Int64): Int64 {
    var count: Int64 = 0
    var cursor = offset
    while (cursor > 0) {
        let start = previousCodePointStart(bytes, cursor)
        if (!isRegionalIndicator(codePointAt(bytes, start))) { return count }
        count += 1
        cursor = start
    }
    return count
}

private func previousCodePointStart(bytes: Array<Byte>, offset: Int64): Int64 {
    var index = offset - 1
    while (index > 0 && isUtf8Continuation(bytes[index])) { index -= 1 }
    return index
}

private func isUtf8Continuation(value: Byte): Bool {
    let numeric = Int64(value)
    return numeric >= 128 && numeric <= 191
}

private func codePointAt(bytes: Array<Byte>, offset: Int64): Int64 {
    let first = Int64(bytes[offset])
    if (first < 128) { return first }
    if (first < 224) {
        return (first - 192) * 64 + (Int64(bytes[offset + 1]) - 128)
    }
    if (first < 240) {
        return (first - 224) * 4096 + (Int64(bytes[offset + 1]) - 128) * 64 + (Int64(bytes[offset + 2]) - 128)
    }
    return (first - 240) * 262144 + (Int64(bytes[offset + 1]) - 128) * 4096 +
        (Int64(bytes[offset + 2]) - 128) * 64 + (Int64(bytes[offset + 3]) - 128)
}

private func isCombiningMark(codePoint: Int64): Bool {
    return (codePoint >= 0x0300 && codePoint <= 0x036f) ||
        (codePoint >= 0x1ab0 && codePoint <= 0x1aff) ||
        (codePoint >= 0x1dc0 && codePoint <= 0x1dff) ||
        (codePoint >= 0x20d0 && codePoint <= 0x20ff) ||
        (codePoint >= 0xfe20 && codePoint <= 0xfe2f)
}

private func isVariationSelector(codePoint: Int64): Bool {
    return (codePoint >= 0xfe00 && codePoint <= 0xfe0f) || (codePoint >= 0xe0100 && codePoint <= 0xe01ef)
}

private func isEmojiSkinTone(codePoint: Int64): Bool {
    return codePoint >= 0x1f3fb && codePoint <= 0x1f3ff
}

private func isRegionalIndicator(codePoint: Int64): Bool {
    return codePoint >= 0x1f1e6 && codePoint <= 0x1f1ff
}
