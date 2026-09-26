/// Tests for the public range-text seam: coordinate mapping, bounded
/// materialisation, precise range forwarding and rejection behaviour.
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

/// A plain byte-array consumer: no Markdown, no agent protocol, no platform
/// object. It is both the reader and the single writer of its own truth.
class MemoryRangeStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    var bytes: Array<Byte>
    var version: Int64 = 1
    var recordedEdits: ArrayList<String> = ArrayList<String>()
    var lastRangeStart: Int64 = -1
    var lastRangeEnd: Int64 = -1
    var lastInserted: String = ""
    var readCallCount: Int64 = 0
    var conflictNext: Bool = false

    init(text: String) {
        this.bytes = text.toArray()
    }

    public func text(): String {
        return String.fromUtf8(this.bytes)
    }

    public func rangeTextVersion(): Int64 {
        return this.version
    }

    public func rangeTextByteLength(): Int64 {
        return Int64(this.bytes.size)
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        this.readCallCount += 1
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
        let content = String.fromUtf8(this.bytes.slice(aligned, end - aligned))
        let complete = end == size
        var reason = ""
        if (!complete) {
            reason = "window_truncated"
        }
        return CjguiRangeTextSlice(startByte, aligned, content, this.version, size, complete, reason)
    }

    public func applyRangeTextEdit(
        baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        if (this.conflictNext) {
            this.conflictNext = false
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale base")
        }
        if (baseVersion != this.version) {
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale base")
        }
        this.lastRangeStart = startByte
        this.lastRangeEnd = endByte
        this.lastInserted = inserted
        this.recordedEdits.add("${startByte}:${endByte}:${inserted}")
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

@Test
func testUtf16AndUtf8OffsetsAgree(): Unit {
    let ascii = "abc"
    @Assert(cjguiUtf8Length(ascii), 3)
    @Assert(cjguiUtf16Length(ascii), 3)
    @Assert(cjguiUtf16OffsetToUtf8(ascii, 2).getOrThrow(), 2)
    @Assert(cjguiUtf8OffsetToUtf16(ascii, 2).getOrThrow(), 2)

    let mixed = "a中😀b"
    // a=1 byte/1 unit, 中=3 bytes/1 unit, 😀=4 bytes/2 units, b=1 byte/1 unit
    @Assert(cjguiUtf8Length(mixed), 9)
    @Assert(cjguiUtf16Length(mixed), 5)
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 0).getOrThrow(), 0)
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 1).getOrThrow(), 1)
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 2).getOrThrow(), 4)
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 4).getOrThrow(), 8)
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 5).getOrThrow(), 9)
    @Assert(cjguiUtf8OffsetToUtf16(mixed, 4).getOrThrow(), 2)
    @Assert(cjguiUtf8OffsetToUtf16(mixed, 8).getOrThrow(), 4)
    // An offset inside the surrogate pair / inside a multi-byte scalar has no
    // exact image and must be refused rather than rounded.
    @Assert(cjguiUtf16OffsetToUtf8(mixed, 3).isNone())
    @Assert(cjguiUtf8OffsetToUtf16(mixed, 2).isNone())
    @Assert(cjguiUtf8OffsetToUtf16(mixed, 10).isNone())
}

@Test
func testBoundaryAlignmentAndValidEnd(): Unit {
    let text = "a中😀b"
    let bytes = text.toArray()
    @Assert(cjguiIsUtf8Boundary(bytes, 0))
    // Index 1 starts the three-byte scalar 中; index 2 is its continuation byte.
    @Assert(cjguiIsUtf8Boundary(bytes, 1))
    @Assert(!cjguiIsUtf8Boundary(bytes, 2))
    @Assert(cjguiIsUtf8Boundary(bytes, 4))
    @Assert(cjguiAlignToUtf8Boundary(bytes, 2), 4)
    @Assert(cjguiAlignToUtf8Boundary(bytes, 5), 8)
    // A limit in the middle of a scalar backs off to the last complete scalar.
    @Assert(cjguiValidUtf8End(bytes, 0, 3), 1)
    @Assert(cjguiValidUtf8End(bytes, 0, 7), 4)
    @Assert(cjguiValidUtf8End(bytes, 0, 8), 8)
    @Assert(cjguiValidUtf8End(bytes, 0, 9), 9)
}

@Test
func testWindowMaterialisesBoundedSliceOfLargeText(): Unit {
    let paragraph = "段落：Pharos Mark 的分块正文。\n"
    let store = MemoryRangeStore(paragraph)
    let window = CjguiRangeTextWindow(11, "doc", store, store, materializeLimit: 8)
    @Assert(window.refresh())
    // The materialised projection is bounded, never the whole text.
    @Assert(cjguiUtf8Length(window.text()) <= 8)
    @Assert(!window.isComplete())
    @Assert(window.unpreparedReason(), "window_truncated")
    @Assert(window.windowStartByte(), 0)
    @Assert(window.contentVersion(), 1)
    @Assert(window.sourceByteLength(), Int64(store.bytes.size))
    // A slice is aligned, so re-reading the same slice is stable.
    let text = window.text()
    @Assert(!window.refresh())
    @Assert(window.text(), text)
}

@Test
func testWindowForwardsOnePreciseRangeEdit(): Unit {
    let store = MemoryRangeStore("hello 世界 😀 end")
    let window = CjguiRangeTextWindow(3, "editor", store, store, materializeLimit: 4096)
    @Assert(window.refresh())
    @Assert(window.text(), "hello 世界 😀 end")
    // UTF-16 offsets: "hello " = 6, "世界" = units 6..8.
    let outcome = window.applyUtf16Edit(6, 2, "地球")
    @Assert(outcome.applied)
    @Assert(outcome.versionBefore, 1)
    @Assert(outcome.versionAfter, 2)
    // The sink received the exact document byte range, not a full-text diff.
    @Assert(store.lastRangeStart, 6)
    @Assert(store.lastRangeEnd, 12)
    @Assert(store.lastInserted, "地球")
    @Assert(store.text(), "hello 地球 😀 end")
    @Assert(window.text(), "hello 地球 😀 end")
    @Assert(window.contentVersion(), 2)
    @Assert(window.forwardedEditCountValue(), 1)
    @Assert(window.rejectedEditCountValue(), 0)
}

@Test
func testWindowForwardsEmojiEditBySurrogatePair(): Unit {
    let store = MemoryRangeStore("a😀b")
    let window = CjguiRangeTextWindow(4, "editor", store, store, materializeLimit: 64)
    @Assert(window.refresh())
    // 😀 occupies UTF-16 units 1..3.
    let outcome = window.applyUtf16Edit(1, 2, "😀😀")
    @Assert(outcome.applied)
    @Assert(store.lastRangeStart, 1)
    @Assert(store.lastRangeEnd, 5)
    @Assert(store.lastInserted, "😀😀")
    @Assert(store.text(), "a😀😀b")
    @Assert(window.text(), "a😀😀b")
}

@Test
func testSplitSurrogateIsRejectedWithoutTouchingTheOwner(): Unit {
    let store = MemoryRangeStore("a😀b")
    let window = CjguiRangeTextWindow(4, "editor", store, store, materializeLimit: 64)
    @Assert(window.refresh())
    // Unit 2 is inside the surrogate pair: there is no document range.
    let outcome = window.applyUtf16Edit(2, 1, "x")
    @Assert(!outcome.applied)
    @Assert(outcome.reason, CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
    @Assert(store.recordedEdits.size, 0)
    @Assert(store.text(), "a😀b")
    @Assert(window.text(), "a😀b")
    @Assert(window.contentVersion(), 1)
    @Assert(window.rejectedEditCountValue(), 1)
}

@Test
func testRejectedEditKeepsProjectionAndVersion(): Unit {
    let store = MemoryRangeStore("abcdef")
    let window = CjguiRangeTextWindow(5, "editor", store, store, materializeLimit: 64)
    @Assert(window.refresh())
    store.conflictNext = true
    let outcome = window.applyByteEdit(0, 1, "Z")
    @Assert(!outcome.applied)
    @Assert(outcome.isVersionConflict)
    @Assert(window.text(), "abcdef")
    @Assert(window.contentVersion(), 1)
    @Assert(window.forwardedEditCountValue(), 0)
    @Assert(window.rejectedEditCountValue(), 1)
    // The owner still accepts the next edit at the same base version.
    let retry = window.applyByteEdit(0, 1, "Z")
    @Assert(retry.applied)
    @Assert(store.text(), "Zbcdef")
    @Assert(window.text(), "Zbcdef")
}

@Test
func testWindowRevealMovesTheBoundedSlice(): Unit {
    let filler = "0123456789abcdefghijklmnopqrstuvwxyz\n"
    let store = MemoryRangeStore(filler)
    let window = CjguiRangeTextWindow(6, "editor", store, store, materializeLimit: 16)
    @Assert(window.refresh())
    @Assert(window.windowStartByte(), 0)
    let moved = window.revealByte(200)
    @Assert(moved)
    @Assert(window.windowStartByte() > 0)
    @Assert(cjguiUtf8Length(window.text()) <= 16)
}

@Test
func testSourceReadsAreBoundedAndCounted(): Unit {
    let paragraph = "句式：中英混排 with ASCII and 😀 emoji。\n"
    var text = ""
    var i: Int64 = 0
    while (i < 200) {
        text += paragraph
        i += 1
    }
    let store = MemoryRangeStore(text)
    let window = CjguiRangeTextWindow(7, "editor", store, store, materializeLimit: 256)
    @Assert(window.refresh())
    @Assert(cjguiUtf8Length(window.text()) <= 256)
    @Assert(store.readCallCount, 1)
    @Assert(window.isComplete() == (Int64(text.toArray().size) <= 256))
    // A tail edit inside the window still reaches the owner with document
    // coordinates that include the window start.
    let outcome = window.applyByteEdit(window.windowStartByte(), window.windowStartByte(), "X")
    @Assert(outcome.applied)
    @Assert(store.lastRangeStart, 0)
    @Assert(store.lastRangeEnd, 0)
    @Assert(store.text().startsWith("X"))
}
