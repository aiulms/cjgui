package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

/// 可视编辑 A1（2026-10-05 Astra 裁决）：本地延续准入的**冻结版本**与
/// **窗口起点**语义。这些负控驱动真实 `CjguiTextSession` / `CjguiRangeTextWindow`
/// 与真实 sink，不是 oracle 的复制品。
///
/// owner 按公共契约实现：每笔接受写入都推进版本，**同字节写入也推进**
/// （对应 thermostat `SET_NOTE` 无条件 `versionValue += 1`）。
private class ContinuationOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var data: Array<Byte>
    private var ver: Int64 = 1
    var writeCalls: Int64 = 0
    var lastBaseVersion: Int64 = -1
    var lastStartByte: Int64 = -1

    init(text: String) {
        this.data = text.toArray()
    }

    public func rangeTextVersion(): Int64 {
        return this.ver
    }

    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (this.ver != expectedVersion) {
            return false
        }
        return action()
    }

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (fromVersion != this.ver) {
            return None
        }
        return Some((startByte, endByte, this.ver))
    }

    public func rangeTextByteLength(): Int64 {
        return this.data.size
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let start = if (startByte < 0) { 0 } else { startByte }
        let cap = if (start > this.data.size) { 0 } else { this.data.size - start }
        let take = if (maxBytes < cap) { maxBytes } else { cap }
        let body = this.data.slice(start, take)
        return CjguiRangeTextSlice(start, start, String.fromUtf8(body), this.ver,
            this.data.size, true, "")
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        this.writeCalls += 1
        this.lastBaseVersion = baseVersion
        this.lastStartByte = startByte
        if (baseVersion != this.ver) {
            return CjguiRangeTextEditOutcome.conflict(this.ver, "version_conflict")
        }
        let head = this.data.slice(0, startByte)
        let tail = this.data.slice(endByte, this.data.size - endByte)
        let merged = ArrayList<Byte>()
        merged.add(all: head.toArray())
        merged.add(all: inserted.toArray())
        merged.add(all: tail.toArray())
        this.data = merged.toArray()
        this.ver += 1
        return CjguiRangeTextEditOutcome.accepted(baseVersion, this.ver)
    }

    /// owner 侧写入（不经 Sink）：模拟 Agent/另一窗口改动正文。
    public func externalWrite(startByte: Int64, endByte: Int64, inserted: String): Unit {
        let head = this.data.slice(0, startByte)
        let tail = this.data.slice(endByte, this.data.size - endByte)
        let merged = ArrayList<Byte>()
        merged.add(all: head.toArray())
        merged.add(all: inserted.toArray())
        merged.add(all: tail.toArray())
        this.data = merged.toArray()
        this.ver += 1
    }

    /// 合规 owner 的**同字节**外部写：内容不变，版本照旧推进。
    public func bumpVersionOnly(): Unit {
        this.ver += 1
    }

    public func text(): String {
        return String.fromUtf8(this.data)
    }
}

private func makeContinuationSession(owner: ContinuationOwner,
    materializeLimit!: Int64 = 65536): CjguiTextSession {
    let window = CjguiRangeTextWindow(313, "note", owner, owner,
        materializeLimit: materializeLimit)
    let session = CjguiTextSession(window)
    session.bind()
    return session
}

/// 正常 Q1→Q2 的**正向**对照：无外部写时，延续记录冻结的版本就是当前版本，
/// 因此按冻结版本 prepare 仍必须成立（证明修正不是靠过度拒绝换来的）。
@Test
func qqFrozenVersionStillAdmitsUndisturbedContinuation(): Unit {
    let owner = ContinuationOwner("abc")
    let session = makeContinuationSession(owner)

    // Q1：正常接受。
    let q1 = session.prepareSourceRange(1, 1, 1).getOrThrow().replace("Q")
    @Assert(q1.accepted, true)
    @Assert(owner.text(), "aQbc")
    // 延续记录冻结的后像（等价于窗口在 Q1 接受后写入的 mirror 快照）。
    let frozen = session.mirrorSnapshot()

    // Q2：期间无任何外部写 ⇒ 冻结版本 == 当前 sourceVersion。
    @Assert(frozen.contentVersion, owner.rangeTextVersion())
    let q2 = session.prepareSourceRange(frozen.contentVersion, 2, 2).getOrThrow().replace("Q")
    @Assert(q2.accepted, true)
    @Assert(owner.text(), "aQQbc")
}

/// Q1 后 owner **同字节换版**：冻结版本必须被拒；用当前版本 prepare 会成功——
/// 这正是被移除的旁路（"改用当前 ownerVersion 再提交"）造成的越权写入。
@Test
func qqFrozenVersionRejectsSameBytesExternalRevision(): Unit {
    let owner = ContinuationOwner("abc")
    let session = makeContinuationSession(owner)
    @Assert(session.prepareSourceRange(1, 1, 1).getOrThrow().replace("Q").accepted, true)
    let frozen = session.mirrorSnapshot()

    // 外部同字节写：字节不变，版本推进（合规 owner）。
    owner.bumpVersionOnly()
    @Assert(owner.text(), "aQbc")
    @Assert(session.refreshMirror(), true)

    // 判别力：当前版本确实可提交——旧旁路就是靠这个把迟到 Q2 写进去的。
    let writesBefore = owner.writeCalls
    @Assert(session.prepareSourceRange(session.contentVersion(), 2, 2).isSome(), true)

    // 冻结版本必须拒绝，即使字节完全相同。
    @Assert(session.prepareSourceRange(frozen.contentVersion, 2, 2).isNone(), true)
    @Assert(owner.writeCalls, writesBefore)
    @Assert(owner.text(), "aQbc")
}

/// ABA：owner 写走再写回原文，字节回到 Q1 后像，版本已推进两次。
@Test
func qqFrozenVersionRejectsAbaBackToOriginalBytes(): Unit {
    let owner = ContinuationOwner("abc")
    let session = makeContinuationSession(owner)
    @Assert(session.prepareSourceRange(1, 1, 1).getOrThrow().replace("Q").accepted, true)
    let frozen = session.mirrorSnapshot()

    owner.externalWrite(0, 1, "Z")   // aQbc → ZQbc
    @Assert(owner.text(), "ZQbc")
    owner.externalWrite(0, 1, "a")   // ZQbc → aQbc（回到原字节，ABA）
    @Assert(owner.text(), "aQbc")
    @Assert(session.refreshMirror(), true)

    @Assert(owner.rangeTextVersion() > frozen.contentVersion, true)
    @Assert(session.prepareSourceRange(frozen.contentVersion, 2, 2).isNone(), true)
    @Assert(owner.text(), "aQbc")
}

/// 窗口起点非零时，`prepareSourceRange` 收**绝对文档字节**：省略
/// `mirror.startByte` 会落到窗口起点之前，事后无法撤销。
@Test
func qqPrepareSourceRangeNeedsAbsoluteDocumentBytes(): Unit {
    let owner = ContinuationOwner("0123456789abcdefghij")
    let session = makeContinuationSession(owner, materializeLimit: 8)

    // 起始窗口覆盖 [0,8)；锚点必须落在窗口**之外**才会真正移动
    // （revealByte 对窗口内锚点按设计返回 false）。
    @Assert(session.revealByte(12), true)
    let mirror = session.mirrorSnapshot()
    @Assert(mirror.startByte, 10)
    @Assert(mirror.text, "abcdefgh")

    // 窗口内 UTF-16 偏移 1 ⇒ 局部字节 1。
    let localByte = cjguiUtf16OffsetToUtf8(mirror.text, 1).getOrThrow()
    @Assert(localByte, 1)

    // **反例本体**：把局部偏移当绝对字节提交**不会被拒绝**——prepareByteRange
    // 对窗口外范围是重新 reveal（range_text.cj:621-624），不是具名拒绝。于是写入
    // 静默落到文档字节 1（窗口起点之前），正文被改错；后像检查在写入之后，
    // 无法撤销。这正是必须补 mirror.startByte 的原因。
    let wrong = session.prepareSourceRange(mirror.contentVersion, localByte, localByte)
        .getOrThrow().replace("Q")
    @Assert(wrong.accepted, true)
    @Assert(owner.lastStartByte, 1)
    @Assert(owner.text(), "0Q123456789abcdefghij")

    // 正确映射：局部 1 + 窗口起点 10 ⇒ 绝对 11。上一笔已经过会话提交，
    // 窗口已是最新（refreshMirror 此时返回 false 是正确的），只需把窗口挪回。
    @Assert(session.revealByte(12), true)
    let back = session.mirrorSnapshot()
    @Assert(back.startByte, 10)
    @Assert(back.text, "9abcdefg")
    let absByte = back.startByte + cjguiUtf16OffsetToUtf8(back.text, 1).getOrThrow()
    @Assert(absByte, 11)
    let edit = session.prepareSourceRange(back.contentVersion, absByte, absByte)
        .getOrThrow().replace("Q")
    @Assert(edit.accepted, true)
    @Assert(owner.lastStartByte, absByte)
    @Assert(owner.text(), "0Q123456789Qabcdefghij")
}