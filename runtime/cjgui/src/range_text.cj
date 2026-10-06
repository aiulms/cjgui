/// Public range-text seam.
///
/// Purpose
/// -------
/// A composable text surface must not require the application to hand the
/// framework one full `String` of the whole document. This seam lets an
/// application expose a *bounded range reader* and a *single range writer*,
/// while the framework materialises only a bounded projection window for
/// layout, hit testing and native text services.
///
/// Division of ownership
/// ---------------------
/// - `CjguiRangeTextSource` is implemented by the application. The framework
///   only ever reads. Reads are bounded and must not scan the whole text.
/// - `CjguiRangeTextEditSink` is implemented by the application and remains the
///   only writer of the document truth. A stale base version is rejected, never
///   merged.
/// - `CjguiRangeTextWindow` is framework-side: it materialises a bounded slice,
///   maps UTF-16 input coordinates (which is what AppKit speaks) into document
///   byte coordinates, and forwards one precise range replacement per edit.
///
/// This file deliberately contains no Markdown, no agent protocol and no
/// platform object. A plain-text consumer can use it with a byte array.
package cjgui

/// Result of one bounded range read, in UTF-8 byte coordinates.
public class CjguiRangeTextSlice {
    /// The offset the caller asked for.
    public let requestedStart: Int64
    /// The offset the content actually starts at. It equals `requestedStart`
    /// when the request was already on a UTF-8 scalar boundary.
    public let actualStart: Int64
    /// The bytes that were available, decoded as UTF-8 and starting/ending on a
    /// scalar boundary.
    public let content: String
    /// Monotonic version of the content these bytes came from.
    public let contentVersion: Int64
    /// Total byte length of the source, or -1 when the source cannot state it
    /// yet (a large file still being snapshotted).
    public let byteLength: Int64
    /// False when fewer bytes than requested were available because the source
    /// is not fully prepared. The caller must show partial state, not zero.
    public let complete: Bool
    /// Machine-readable explanation when `complete` is false.
    public let pendingReason: String

    public init(
        requestedStart: Int64,
        actualStart: Int64,
        content: String,
        contentVersion: Int64,
        byteLength: Int64,
        complete: Bool,
        pendingReason: String) {
        this.requestedStart = requestedStart
        this.actualStart = actualStart
        this.content = content
        this.contentVersion = contentVersion
        this.byteLength = byteLength
        this.complete = complete
        this.pendingReason = pendingReason
    }

    public func byteCount(): Int64 {
        return Int64(this.content.toArray().size)
    }
}

/// Application-provided bounded reader over a document truth.
public interface CjguiRangeTextSource {
    /// Monotonic content version. It advances once per accepted edit.
    func rangeTextVersion(): Int64

    /// Run a short restoration confirmation only while this same source still
    /// publishes `expectedVersion`. The owner must serialize this callback with
    /// every content write; it must not read text, call native, or re-enter Sink.
    func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool

    /// Map a view's absolute source-byte selection from one owner version to
    /// the current one. Return None if the map chain has a gap or either
    /// endpoint was replaced ambiguously. The owner must do this atomically
    /// with its version and change-map history reads.
    func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64)

    /// Total byte length, or -1 when not yet known.
    func rangeTextByteLength(): Int64

    /// Read up to `maxBytes` bytes from `startByte`.
    ///
    /// The implementation must return whole UTF-8 scalars: it may move the
    /// start forward to the next scalar boundary and truncate the tail. It must
    /// return a bounded amount of work even for a huge document.
    func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice
}

/// Result of one attempted range replacement.
public class CjguiRangeTextEditOutcome {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        reason: String) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.reason = reason
    }

    public static func accepted(before: Int64, after: Int64): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome(true, false, before, after, "")
    }

    public static func rejected(version: Int64, reason: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome(false, false, version, version, reason)
    }

    public static func conflict(version: Int64, reason: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome(false, true, version, version, reason)
    }
}

/// Application-provided single writer. `startByte`/`endByte` are UTF-8 byte
/// offsets in the version named by `baseVersion`.
public interface CjguiRangeTextEditSink {
    func applyRangeTextEdit(
        baseVersion: Int64,
        startByte: Int64,
        endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome
}

/// Result of a composition `begin`. `accepted=false` names the reason and no claim is live; on
/// success `token` is the credential every later phase of THIS composition must present, and the
/// echoed range is in the version the caller computed it in.
public class CjguiRangeTextCompositionClaim {
    public let accepted: Bool
    public let reason: String
    public let token: Int64
    public let startByte: Int64
    public let endByte: Int64
    public let baseVersion: Int64

    public init(accepted: Bool, reason: String, token: Int64, startByte: Int64, endByte: Int64,
        baseVersion: Int64) {
        this.accepted = accepted
        this.reason = reason
        this.token = token
        this.startByte = startByte
        this.endByte = endByte
        this.baseVersion = baseVersion
    }

    public static func refused(reason: String, version: Int64): CjguiRangeTextCompositionClaim {
        return CjguiRangeTextCompositionClaim(false, reason, -1, -1, -1, version)
    }
}

/// In-lock inspection of one live claim by its credential. The range is the claim's CURRENT
/// coordinates and `contentVersion` is the owner version they belong to: every accepted
/// transaction migrates the claim, so a range can never be read without that version.
public class CjguiRangeTextCompositionInspection {
    public let ok: Bool
    public let reason: String
    public let startByte: Int64
    public let endByte: Int64
    public let contentVersion: Int64

    public init(ok: Bool, reason: String, startByte: Int64, endByte: Int64, contentVersion: Int64) {
        this.ok = ok
        this.reason = reason
        this.startByte = startByte
        this.endByte = endByte
        this.contentVersion = contentVersion
    }

    public static func refused(reason: String,
        version: Int64): CjguiRangeTextCompositionInspection {
        return CjguiRangeTextCompositionInspection(false, reason, -1, -1, version)
    }
}

/// The answer to one composition terminal.
///
/// `consumed` is the credential fact: true means the presented token is terminated, whatever
/// happened next. `published` is the body fact: true means THIS call advanced the owner version by
/// exactly one transaction. `accepted` is true for a published commit and for the NO-CHANGE
/// terminal (a zero-width claim committed with empty text: zero version, zero history); a no-change
/// terminal must never be reported as an accepted composition WRITE, so a consumer that records
/// writes reads `published`.
public class CjguiRangeTextCompositionOutcome {
    public let accepted: Bool
    public let published: Bool
    public let consumed: Bool
    public let reason: String
    public let startByte: Int64
    public let endByte: Int64
    public let versionBefore: Int64
    public let versionAfter: Int64

    public init(accepted: Bool, published: Bool, consumed: Bool, reason: String, startByte: Int64,
        endByte: Int64, versionBefore: Int64, versionAfter: Int64) {
        this.accepted = accepted
        this.published = published
        this.consumed = consumed
        this.reason = reason
        this.startByte = startByte
        this.endByte = endByte
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
    }

    public static func refused(reason: String, consumed: Bool,
        version: Int64): CjguiRangeTextCompositionOutcome {
        return CjguiRangeTextCompositionOutcome(false, false, consumed, reason, -1, -1, version,
            version)
    }
}

/// The answer to a composition cancel. `released=false` means the presented token was not the live
/// claim (already consumed, or never issued): the owner's legal claim, if any, was left alone.
public class CjguiRangeTextCompositionRelease {
    public let released: Bool
    public let reason: String

    public init(released: Bool, reason: String) {
        this.released = released
        this.reason = reason
    }

    public static func refused(reason: String): CjguiRangeTextCompositionRelease {
        return CjguiRangeTextCompositionRelease(false, reason)
    }
}

/// OPTIONAL composition-write capability, implemented by the same application object as
/// `CjguiRangeTextEditSink` when the document owner can hold a live claim on a composing range.
///
/// When a window binding declares composition arbitration, the session registers the owner's claim
/// at composition start and every terminal presents the returned credential -- the ordinary
/// `applyRangeTextEdit` is never used for a composition. A binding that declares arbitration but
/// does not implement this interface is refused by name (`composition_arbitration_unavailable`)
/// instead of silently falling back to the ordinary writer.
///
/// `bindingIdentity` binds the credential to one window binding; the implementation must refuse a
/// credential presented from a different binding. `expectedVersion` is the owner version the range
/// coordinates were translated in: a stale frame must be refused by name, never re-interpreted.
public interface CjguiRangeTextCompositionSink {
    /// Register the owner's live claim on `[startByte, endByte)` of `expectedVersion`.
    func beginRangeTextComposition(bindingIdentity: String, expectedVersion: Int64, startByte: Int64,
        endByte: Int64): CjguiRangeTextCompositionClaim

    /// Read the claim's current range and the version it belongs to, in one owner critical point.
    func inspectRangeTextComposition(token: Int64): CjguiRangeTextCompositionInspection

    /// Replace the claim's current range with `text` as exactly one transaction. `requestId` is the
    /// terminal's fixed identity: a repeated delivery of the same terminal must not write twice.
    func commitRangeTextComposition(token: Int64, expectedVersion: Int64, text: String,
        requestId: String): CjguiRangeTextCompositionOutcome

    /// Drop the claim without touching content (cancel / unbind / focus loss).
    func cancelRangeTextComposition(token: Int64): CjguiRangeTextCompositionRelease
}

public let CJGUI_RANGE_TEXT_REASON_UNPREPARED: String = "source_unprepared"
public let CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY: String = "not_utf8_boundary"
public let CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW: String = "outside_materialized_window"
public let CJGUI_RANGE_TEXT_REASON_VERSION: String = "version_conflict"
public let CJGUI_RANGE_TEXT_REASON_BUDGET: String = "range_exceeds_materialize_budget"
/// The binding declared composition arbitration but its sink implements no composition capability.
/// The composition is refused by this name; it must never silently fall back to the ordinary sink.
public let CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE: String = "composition_arbitration_unavailable"
/// A composition terminal that settled with zero body change (zero-width claim, empty final text):
/// no version, no history. Named so it is not counted as an accepted composition write.
public let CJGUI_RANGE_TEXT_REASON_COMPOSITION_NO_CHANGE: String = "composition_no_change"

/// UTF-8 byte length of a string.
public func cjguiUtf8Length(value: String): Int64 {
    return Int64(value.toArray().size)
}

/// UTF-16 code-unit length, which is the unit AppKit reports.
public func cjguiUtf16Length(value: String): Int64 {
    var units: Int64 = 0
    for (rune in value.runes()) {
        if (rune.toString().toArray().size == 4) {
            units += 2
        } else {
            units += 1
        }
    }
    return units
}

/// True when `index` sits on a UTF-8 scalar boundary (or at the end).
public func cjguiIsUtf8Boundary(bytes: Array<Byte>, index: Int64): Bool {
    if (index < 0 || index > bytes.size) {
        return false
    }
    if (index == bytes.size) {
        return true
    }
    // Continuation bytes are 0b10xxxxxx.
    return (bytes[index] & 0xC0) != 0x80
}

/// Move `index` forward to the next UTF-8 scalar boundary.
public func cjguiAlignToUtf8Boundary(bytes: Array<Byte>, index: Int64): Int64 {
    var cursor = index
    if (cursor < 0) {
        cursor = 0
    }
    if (cursor > bytes.size) {
        return bytes.size
    }
    while (cursor < bytes.size && (bytes[cursor] & 0xC0) == 0x80) {
        cursor += 1
    }
    return cursor
}

/// Largest `end <= limit` such that `bytes[start, end)` holds only complete
/// UTF-8 scalars. `start` must already be on a scalar boundary. A malformed
/// lead byte is treated as a one-byte scalar so a damaged tail can never make
/// the caller drop the whole read.
public func cjguiValidUtf8End(bytes: Array<Byte>, start: Int64, limit: Int64): Int64 {
    var cursor = start
    while (cursor < limit) {
        let lead = bytes[cursor]
        var width = 1
        if ((lead & 0x80) == 0) {
            width = 1
        } else if ((lead & 0xE0) == 0xC0) {
            width = 2
        } else if ((lead & 0xF0) == 0xE0) {
            width = 3
        } else if ((lead & 0xF8) == 0xF0) {
            width = 4
        }
        if (cursor + width > limit) {
            break
        }
        var k: Int64 = 1
        var valid = true
        while (k < width) {
            if ((bytes[cursor + k] & 0xC0) != 0x80) {
                valid = false
                break
            }
            k += 1
        }
        if (!valid) {
            break
        }
        cursor += width
    }
    return cursor
}

/// Convert a UTF-16 code-unit offset inside `value` into a UTF-8 byte offset.
/// Returns `None` when the offset would split a surrogate pair.
public func cjguiUtf16OffsetToUtf8(value: String, utf16Offset: Int64): ?Int64 {
    if (utf16Offset < 0) {
        return None
    }
    var units: Int64 = 0
    var bytes: Int64 = 0
    if (utf16Offset == 0) {
        return Some(0)
    }
    for (rune in value.runes()) {
        let encoded = rune.toString()
        let byteLength = Int64(encoded.toArray().size)
        let unitLength = if (byteLength == 4) { 2 } else { 1 }
        if (units + unitLength == utf16Offset) {
            return Some(bytes + byteLength)
        }
        if (units + unitLength > utf16Offset) {
            // The offset lands inside this scalar (a split surrogate pair).
            return None
        }
        units += unitLength
        bytes += byteLength
    }
    if (units == utf16Offset) {
        return Some(bytes)
    }
    return None
}

/// Convert a UTF-8 byte offset inside `value` into a UTF-16 code-unit offset.
/// Returns `None` when the offset splits a UTF-8 scalar.
public func cjguiUtf8OffsetToUtf16(value: String, byteOffset: Int64): ?Int64 {
    if (byteOffset < 0) {
        return None
    }
    var units: Int64 = 0
    var bytes: Int64 = 0
    if (byteOffset == 0) {
        return Some(0)
    }
    for (rune in value.runes()) {
        let encoded = rune.toString()
        let byteLength = Int64(encoded.toArray().size)
        let unitLength = if (byteLength == 4) { 2 } else { 1 }
        if (bytes + byteLength == byteOffset) {
            return Some(units + unitLength)
        }
        if (bytes + byteLength > byteOffset) {
            return None
        }
        bytes += byteLength
        units += unitLength
    }
    if (bytes == byteOffset) {
        return Some(units)
    }
    return None
}

/// A bounded, materialised projection of a range text source.
///
/// It is a *projection*, never the truth: the application sink remains the only
/// writer. Every human edit is forwarded as one precise byte range replacement
/// in the version the window was materialised from.
public class CjguiRangeTextWindow {
    private let nodeIdValue: Int64
    private let semanticIdValue: String
    private let source: CjguiRangeTextSource
    private let sink: CjguiRangeTextEditSink
    private let materializeLimit: Int64
    private var startByte: Int64 = 0
    private var value: String = ""
    private var version: Int64 = 0
    private var totalBytes: Int64 = -1
    private var prepared: Bool = false
    private var complete: Bool = false
    private var pendingReason: String = CJGUI_RANGE_TEXT_REASON_UNPREPARED
    private var refreshCount: Int64 = 0
    private var forwardedEditCount: Int64 = 0
    private var rejectedEditCount: Int64 = 0

    public init(
        nodeId: Int64,
        semanticId: String,
        source: CjguiRangeTextSource,
        sink: CjguiRangeTextEditSink,
        materializeLimit!: Int64 = 65536) {
        this.nodeIdValue = nodeId
        this.semanticIdValue = semanticId
        this.source = source
        this.sink = sink
        // A UTF-8 scalar may occupy four bytes; smaller windows cannot hold one.
        this.materializeLimit = if (materializeLimit < 4) { 4 } else { materializeLimit }
    }

    public func nodeId(): Int64 {
        return this.nodeIdValue
    }

    public func semanticId(): String {
        return this.semanticIdValue
    }

    /// The materialised projection text handed to layout and native text
    /// services. It is at most `materializeLimit` bytes.
    public func text(): String {
        return this.value
    }

    /// Document byte offset of the first materialised byte.
    public func windowStartByte(): Int64 {
        return this.startByte
    }

    public func contentVersion(): Int64 {
        return this.version
    }

    /// The version the owner reports RIGHT NOW, which can be ahead of the
    /// materialised projection: an agent or another window may have written
    /// through the sink since the last `refresh`. A caller that must detect a
    /// stale mirror (an input session holding a composition, for instance) has
    /// to compare against this, not against `contentVersion()`.
    public func sourceVersion(): Int64 {
        return this.source.rangeTextVersion()
    }

    func selectionOwner(): ?CjguiRangeTextSelectionOwner {
        return this.source as CjguiRangeTextSelectionOwner
    }

    /// The callback is the final session-only state transition. Source/owner
    /// protects the version comparison and that transition in one write boundary.
    public func confirmContentVersion(action: () -> Bool): Bool {
        return this.source.confirmRangeTextVersion(this.version, action)
    }

    public func rebaseSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        return this.source.rebaseRangeTextSelection(fromVersion, startByte, endByte)
    }

    /// Total document byte length, or -1 when the source does not know it yet.
    public func sourceByteLength(): Int64 {
        return this.totalBytes
    }

    /// Whether the local slice is fully prepared for range conversion/editing.
    /// A healthy bounded page is prepared even when more document bytes exist.
    public func isPrepared(): Bool {
        return this.prepared
    }

    /// Whether this prepared slice covers the whole document.
    public func isComplete(): Bool {
        return this.complete
    }

    public func coversWholeDocument(): Bool {
        return this.complete
    }

    public func unpreparedReason(): String {
        return this.pendingReason
    }

    public func materializeLimitBytes(): Int64 {
        return this.materializeLimit
    }

    public func refreshCountValue(): Int64 {
        return this.refreshCount
    }

    public func forwardedEditCountValue(): Int64 {
        return this.forwardedEditCount
    }

    public func rejectedEditCountValue(): Int64 {
        return this.rejectedEditCount
    }

    /// Load (or reload) the projection at the current window start.
    /// Returns true when the mirror's IDENTITY changed -- text, document anchor or
    /// content version. A same-text reload at a different anchor, or an owner write that
    /// happens to produce the same visible bytes, is still a new mirror: callers advance
    /// the mirror revision from this return value, so reporting only "the string differs"
    /// would leave ranges expressed against the previous mirror looking still valid.
    public func refresh(): Bool {
        // The window keeps its document anchor across edits: the caret stays
        // where the user put it and only the text in view changes.
        let slice = this.source.readRangeText(this.startByte, this.materializeLimit)
        let previous = this.value
        let previousStart = this.startByte
        let previousVersion = this.version
        let previousTotal = this.totalBytes
        let previousPrepared = this.prepared
        let previousComplete = this.complete
        let previousReason = this.pendingReason
        // Validate the source candidate before publishing any of its text.
        // A buggy range source can return more than requested; marking the
        // mirror unprepared while retaining that oversized value would still
        // hand it to layout and native text services on the next frame.
        let contentBytes = Int64(slice.content.toArray().size)
        let withinBudget = contentBytes <= this.materializeLimit
        let endByte = if (withinBudget && slice.actualStart >= 0 &&
            slice.actualStart <= 9223372036854775807 - contentBytes) {
            slice.actualStart + contentBytes
        } else {
            -1
        }
        let validSpan = slice.actualStart >= 0 && slice.actualStart >= slice.requestedStart &&
            withinBudget && endByte >= slice.actualStart &&
            (slice.byteLength < 0 || endByte <= slice.byteLength)
        this.startByte = slice.actualStart
        this.value = if (validSpan) { slice.content } else { "" }
        this.version = slice.contentVersion
        this.totalBytes = slice.byteLength
        this.prepared = slice.complete && validSpan &&
            (slice.byteLength < 0 || slice.actualStart == slice.byteLength ||
                contentBytes > 0)
        this.complete = this.prepared && slice.byteLength >= 0 &&
            slice.actualStart == 0 && endByte == slice.byteLength
        this.pendingReason = if (!withinBudget) {
            CJGUI_RANGE_TEXT_REASON_BUDGET
        } else if (!validSpan) {
            "invalid_local_slice"
        } else if (this.prepared) { "" } else if (slice.pendingReason != "") {
            slice.pendingReason
        } else { "invalid_local_slice" }
        this.refreshCount += 1
        return previous != this.value || previousStart != this.startByte ||
            previousVersion != this.version || previousTotal != this.totalBytes ||
            previousPrepared != this.prepared || previousComplete != this.complete ||
            previousReason != this.pendingReason
    }

    /// Recentre the projection so `anchorByte` is visible. Returns true when
    /// the window moved (the caller must then reload layout).
    public func revealByte(anchorByte: Int64): Bool {
        if (this.prepared && anchorByte >= this.startByte &&
            anchorByte <= this.startByte + Int64(this.value.toArray().size)) {
            return false
        }
        var target = anchorByte - this.materializeLimit / 4
        if (target < 0) {
            target = 0
        }
        // The anchor moved even when the re-read text happens to be identical (a
        // filler document, an unchanged window of repeats): callers key their
        // remap/relayout on this return value, so it must report the move.
        let moved = target != this.startByte
        this.startByte = target
        let changed = this.refresh()
        return moved || changed
    }

    /// Prepare one exact absolute source span, never a guessed pair of
    /// separately revealed endpoints. The read remains within this window's
    /// fixed budget and does not call Sink.
    public func prepareByteRange(startByte: Int64, endByte: Int64): String {
        if (startByte < 0 || endByte < startByte ||
            (this.totalBytes >= 0 && endByte > this.totalBytes)) {
            return "invalid_range"
        }
        if (endByte - startByte > this.materializeLimit) {
            return CJGUI_RANGE_TEXT_REASON_BUDGET
        }
        let coverEnd = this.startByte + cjguiUtf8Length(this.value)
        if (!this.prepared || startByte < this.startByte || endByte > coverEnd) {
            this.startByte = startByte
            let _ = this.refresh()
        }
        if (!this.prepared) {
            return this.pendingReason
        }
        if (startByte < this.startByte || endByte > this.startByte + cjguiUtf8Length(this.value)) {
            return CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW
        }
        let bytes = this.value.toArray()
        if (!cjguiIsUtf8Boundary(bytes, startByte - this.startByte) ||
            !cjguiIsUtf8Boundary(bytes, endByte - this.startByte)) {
            return CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY
        }
        return ""
    }

    // Only document endpoints are proved without materializing their interior.
    // The source's pure version guard binds its exact length to that version.
    func confirmedWholeSourceLength(expectedVersion: Int64): ?Int64 {
        let total = Array<Int64>(1, repeat: -1)
        let confirmed = this.source.confirmRangeTextVersion(expectedVersion, { =>
            total[0] = this.source.rangeTextByteLength()
            return total[0] >= 0
        })
        return if (confirmed) { Some(total[0]) } else { None }
    }

    // Package-only, called with the session's explicit whole-choice proof.
    // Arbitrary out-of-window spans still use prepareByteRange/applyByteEdit.
    func applyWholeSourceEdit(expectedVersion: Int64, total: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        let current = this.confirmedWholeSourceLength(expectedVersion)
        if (total < 0 || current.isNone() || current.getOrThrow() != total) {
            this.rejectedEditCount += 1
            return CjguiRangeTextEditOutcome.conflict(this.source.rangeTextVersion(),
                CJGUI_RANGE_TEXT_REASON_VERSION)
        }
        let outcome = this.sink.applyRangeTextEdit(expectedVersion, 0, total, inserted)
        if (!outcome.applied) {
            this.rejectedEditCount += 1
            return outcome
        }
        this.forwardedEditCount += 1
        // The old remote viewport has no coordinates in the replacement body.
        // Reset only after the real Sink accepted; failure retains the old view.
        this.startByte = 0
        let _ = this.refresh()
        return outcome
    }

    /// Map a UTF-16 range inside the materialised text into document byte
    /// coordinates. Returns None when the range splits a scalar.
    public func documentRangeForUtf16(location: Int64, length: Int64): ?(Int64, Int64) {
        if (!this.prepared || length < 0) {
            return None
        }
        let localStart = cjguiUtf16OffsetToUtf8(this.value, location)
        if (let Some(s) <- localStart) {
            let localEnd = cjguiUtf16OffsetToUtf8(this.value, location + length)
            if (let Some(e) <- localEnd) {
                return Some((this.startByte + s, this.startByte + e))
            }
        }
        return None
    }

    /// Forward one human edit expressed in UTF-16 coordinates of the current
    /// projection. The sink receives the exact document byte range.
    public func applyUtf16Edit(
        locationUtf16: Int64,
        lengthUtf16: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        let mapped = this.documentRangeForUtf16(locationUtf16, lengthUtf16)
        if (let Some(range) <- mapped) {
            return this.applyByteEdit(range[0], range[1], inserted)
        }
        this.rejectedEditCount += 1
        return CjguiRangeTextEditOutcome.rejected(this.version, CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
    }

    /// Forward one edit already expressed in document byte coordinates.
    public func applyByteEdit(
        startByte: Int64,
        endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        if (!this.prepared) {
            this.rejectedEditCount += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, this.pendingReason)
        }
        if (startByte < 0 || endByte < startByte) {
            this.rejectedEditCount += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, "invalid_range")
        }
        let coverEnd = this.startByte + Int64(this.value.toArray().size)
        if (startByte < this.startByte || endByte > coverEnd) {
            this.rejectedEditCount += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW)
        }
        let currentBytes = this.value.toArray()
        if (!cjguiIsUtf8Boundary(currentBytes, startByte - this.startByte) ||
            !cjguiIsUtf8Boundary(currentBytes, endByte - this.startByte)) {
            this.rejectedEditCount += 1
            return CjguiRangeTextEditOutcome.rejected(this.version, CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
        }
        let outcome = this.sink.applyRangeTextEdit(this.version, startByte, endByte, inserted)
        if (!outcome.applied) {
            this.rejectedEditCount += 1
            // A rejected edit must not move the projection: the old text and the
            // old version both stay, so the next input is judged against them.
            return outcome
        }
        this.forwardedEditCount += 1
        // The window anchor does not move with the edit; only the text in view
        // changes. If the document shrank past the anchor, `refresh` re-reads
        // from the clamped position the source reports.
        if (!this.refresh()) {
            // The edit was accepted but the window text is unchanged (for
            // example a same-length replacement produced the same bytes); the
            // version must still follow the owner.
            this.version = outcome.versionAfter
        }
        return outcome
    }
}
