// 1b(2026-09-27, Astra 方案 R): CjguiTextSession 契约反例。
//
// 覆盖计划要求的确定性链:pump 前连续两笔事务、显式范围替换两端点、首项拒绝后的
// 重新校准、换绑/旧代次回执照具名拒绝、`abc` 选 [0,2) 组字提交「你」→ `你c`、
// 取消零事务、owner 接受前不清草稿、Agent 改基版本后旧组合回调拒绝、有界上下文
// 不整篇读取。
//
// 层级声明:这里用同步 Fake owner,只证明**会话自身的转换/确认契约**。平台
// adapter/FIFO/pump/真实 IME 的链不在本文件的能力范围内,不能由这些用例宣称
// 正常窗口输入已经接通。
package cjgui

import std.collection.ArrayList

import std.unittest.*
import std.unittest.testmacro.*

// 独立纯文本消费者的最小 owner:字节存储 + 版本,经 Sink 提交同一写入路径。
// 同时记录读取工作量,用于证明会话只按有界窗口读取。
class FakeTextOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    var data: Array<Byte>
    var ver: Int64 = 1
    var rejectAll: Bool = false
    var lastRejectReason: String = ""
    var readCalls: Int64 = 0
    var maxReadBytes: Int64 = 0
    var writeCalls: Int64 = 0
    var reportIncompleteBoundedReads: Bool = false
    var maps: ArrayList<(Int64, Int64, Int64, Int64)> = ArrayList<(Int64, Int64, Int64, Int64)>()

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
        if (fromVersion < 1 || fromVersion > this.ver || startByte < 0 || endByte < startByte) {
            return None
        }
        var version = fromVersion
        var start = startByte
        var end = endByte
        for (map in this.maps) {
            if (map[0] < version) {
                continue
            }
            if (map[0] != version || (start > map[1] && start < map[2]) ||
                (end > map[1] && end < map[2])) {
                return None
            }
            if (start < end && map[1] < end && start < map[2]) {
                return None
            }
            let delta = map[3] - (map[2] - map[1])
            if (start > map[2] || (start == map[2] && map[1] == map[2]) ||
                (start == map[2] && map[1] != map[2])) {
                start += delta
            }
            if (end > map[2] || end == map[2]) {
                end += delta
            }
            version += 1
        }
        if (version != this.ver || end > this.data.size) {
            return None
        }
        return Some((version, start, end))
    }

    public func rangeTextByteLength(): Int64 {
        return this.data.size
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        this.readCalls += 1
        if (maxBytes > this.maxReadBytes) {
            this.maxReadBytes = maxBytes
        }
        let start = if (startByte < 0) { 0 } else { startByte }
        let cap = if (start > this.data.size) { 0 } else { this.data.size - start }
        let take = if (maxBytes < cap) { maxBytes } else { cap }
        let body = this.data.slice(start, take)
        let complete = !this.reportIncompleteBoundedReads || start + take >= this.data.size
        return CjguiRangeTextSlice(start, start,
            String.fromUtf8(body), this.ver, this.data.size, complete,
            if (complete) { "" } else { "window_truncated" })
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        this.writeCalls += 1
        if (this.rejectAll) {
            this.lastRejectReason = "forced_reject"
            return CjguiRangeTextEditOutcome(false, false, this.ver, this.ver, "forced_reject")
        }
        if (baseVersion != this.ver) {
            return CjguiRangeTextEditOutcome.conflict(this.ver, "version_conflict")
        }
        this.splice(startByte, endByte, inserted)
        return CjguiRangeTextEditOutcome.accepted(baseVersion, this.ver)
    }

    /// 不走 Sink 的 owner 侧写入:模拟 Agent/另一窗口在组合期间改动正文。
    public func externalWrite(startByte: Int64, endByte: Int64, inserted: String): Unit {
        this.splice(startByte, endByte, inserted)
    }

    /// owner 侧"写入后字节完全相同"(Agent 用同样内容替换、或格式重写)。文本没变**不等于**
    /// 镜像没变:范围的身份是 (锚点, 内容版本),所以重备必须报告身份变化。
    public func bumpVersionOnly(): Unit {
        this.maps.add((this.ver, 0, 0, 0))
        this.ver += 1
    }

    private func splice(startByte: Int64, endByte: Int64, inserted: String): Unit {
        this.maps.add((this.ver, startByte, endByte, Int64(inserted.toArray().size)))
        let head = this.data.slice(0, startByte)
        let tail = this.data.slice(endByte, this.data.size - endByte)
        let merged = ArrayList<Byte>()
        merged.add(all: head.toArray())
        merged.add(all: inserted.toArray())
        merged.add(all: tail.toArray())
        this.data = merged.toArray()
        this.ver += 1
    }

    public func text(): String {
        return String.fromUtf8(this.data)
    }
}

func makeSession(owner: FakeTextOwner, nodeId!: Int64 = 1001,
    materializeLimit!: Int64 = 65536): CjguiTextSession {
    let window = CjguiRangeTextWindow(nodeId, "plain-text", owner, owner,
        materializeLimit: materializeLimit)
    let session = CjguiTextSession(window)
    session.bind()
    return session
}

// 大正文夹具:只按单元复制,不依赖任何会话能力。
func repeatedText(unit: String, times: Int64): String {
    let src = unit.toArray()
    let bytes = ArrayList<Byte>()
    var i: Int64 = 0
    while (i < times) {
        var j: Int64 = 0
        while (j < src.size) {
            bytes.add(src[j])
            j += 1
        }
        i += 1
    }
    return String.fromUtf8(bytes.toArray())
}

@Test
func testContinuousInputBeforePumpYieldsTwoTransactions(): Unit {
    // 计划确定性反例:初始 ab,同一次 pump 前连续输入 X/Y ⇒ abXY、两笔事务。
    let owner = FakeTextOwner("ab")
    let session = makeSession(owner)
    let first = session.replaceRange16(2, 2, "X")
    @Assert(first.accepted)
    @Assert(first.seq, 1)
    let second = session.replaceRange16(3, 3, "Y")
    @Assert(second.accepted)
    @Assert(second.seq, 2)
    @Assert(owner.text(), "abXY")
    @Assert(owner.ver, 3)
    @Assert(owner.writeCalls, 2)
    // 两笔都还没有向平台结算:串行 pending 保留各自的前驱镜像修订,票据互不相同。
    @Assert(session.pendingCount(), 2)
    @Assert(session.oldestPendingTicket(), 1)
    @Assert(second.mirrorRevision > first.mirrorRevision)
    @Assert(second.ticket > first.ticket)
    @Assert(session.acknowledge(second.ticket, second.contextEpoch))
    @Assert(session.pendingCount(), 0)
}

@Test
func testExplicitRangeReplaceHonorsBothEndpoints(): Unit {
    // 显式范围替换必须执行两端点,不是 caret 处补插。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let edit = session.replaceRange16(0, 2, "XY")
    @Assert(edit.accepted)
    @Assert(owner.text(), "XYc")
    let (s, e) = session.selection16()
    @Assert(s, 2)
    @Assert(e, 2)
}

@Test
func testFirstRejectionForcesRecalibrationBeforeNextBodyWrite(): Unit {
    // 后续输入依赖前一输入镜像;第一项被拒后不得继续把旧坐标交给当前正文。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    owner.rejectAll = true
    session.setSelection16(1, 2)
    let rejected = session.replaceRange16(1, 2, "Z")
    @Assert(!rejected.accepted)
    @Assert(rejected.seq, 0)
    @Assert(session.lastRejectReason(), "forced_reject")
    let (beforeS, beforeE) = session.selection16()
    @Assert(beforeS, 1)
    @Assert(beforeE, 2)
    owner.rejectAll = false

    // 未结算该拒绝:镜像仍与 owner 分叉,继续写入被具名拒绝。
    let blind = session.replaceRange16(1, 2, "Z")
    @Assert(!blind.accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    @Assert(owner.writeCalls, 1)

    // 结算该回执 + 按 owner 现状重建镜像:这只恢复**会话侧**,校准锁仍在。
    @Assert(session.acknowledge(rejected.ticket, rejected.contextEpoch))
    @Assert(session.recalibrate())
    let stillLocked = session.replaceRange16(1, 2, "Z")
    @Assert(!stillLocked.accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    @Assert(owner.writeCalls, 1)
    // 旧世代的恢复回执解不开当前锁(native 恢复必须带它实际看到的身份)。
    @Assert(!session.confirmProxyRestored(rejected.contextEpoch, 999))
    @Assert(session.lastRejectReason(), "restore_receipt_mismatch")
    // 平台按新镜像重新投影并恢复代理后回执到位 ⇒ 同一编辑才允许落到正文。
    @Assert(session.awaitingCalibration())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.awaitingCalibration())
    let ok = session.replaceRange16(1, 2, "Z")
    @Assert(ok.accepted)
    @Assert(ok.seq, 1)
    @Assert(owner.text(), "aZc")
}

@Test
func testRebindAdvancesEpochAndStaleReceiptCalibratesNothing(): Unit {
    // 旧 context 的回执不得校准复用 nodeId 的新会话。
    let owner = FakeTextOwner("ab")
    let session = makeSession(owner, nodeId: 55)
    let oldEpoch = session.contextEpochValue()
    let edit = session.replaceRange16(2, 2, "X")
    @Assert(edit.accepted)

    // 换绑(同一绘制节点号被复用)开启新上下文。
    session.bind()
    @Assert(session.contextEpochValue() > oldEpoch)
    // 票据不随重绑归零:旧上下文迟到的回执既撞不上新票据,也过不了代次检查。
    @Assert(!session.acknowledge(edit.ticket, oldEpoch))
    @Assert(session.lastRejectReason(), "stale_context_receipt")
    // 被拒的旧回执没有清掉新会话的 pending 状态:新代次回执照常结算。
    let fresh = session.replaceRange16(2, 2, "Q")
    @Assert(fresh.accepted)
    @Assert(fresh.seq, 1)
    @Assert(fresh.ticket > edit.ticket)
    @Assert(session.acknowledge(fresh.ticket, fresh.contextEpoch))
    @Assert(session.pendingCount(), 0)
}

@Test
func testCompositionCommitReplacesTheOriginalRange(): Unit {
    // 计划确定性反例:abc 选 [0,2) 组字提交「你」⇒ 你c。终点不得塌回起点。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(began.accepted)
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "nihao")
    let (markStart, markLen) = session.markedRange16()
    @Assert(markStart, 0)
    @Assert(markLen, 5)
    // 组字更新不触碰 owner。
    @Assert(owner.text(), "abc")
    @Assert(owner.writeCalls, 0)

    let commit = session.commitComposition(finalText: "你")
    @Assert(commit.accepted)
    @Assert(commit.seq, 1)
    @Assert(owner.text(), "你c")
    @Assert(!session.hasComposition())
    // 「你」是 3 个 UTF-8 字节但只有 1 个 UTF-16 码元:折叠后的 caret 以平台单位表达。
    let (s, e) = session.selection16()
    @Assert(s, 1)
    @Assert(e, 1)
}

@Test
func testCompositionUpdatesKeepReplacementEndAcrossRedraws(): Unit {
    // 每次 setMarkedText 都重报同一替换范围;多次更新后提交仍替换整个原范围。
    let owner = FakeTextOwner("hello world")
    let session = makeSession(owner)
    session.setSelection16(6, 11)
    let _ = session.updateComposition("nihao", 6, 5, 6, 2, 2)
    let _ = session.updateComposition("nihao-更长的草稿", 6, 5, 6, 8, 8)
    let commit = session.commitComposition(finalText: "你好")
    @Assert(commit.accepted)
    @Assert(owner.text(), "hello 你好")
    // marked 内部选区按平台约定相对传入 preedit 原样回答。
    session.setSelection16(0, 0)
    let _ = session.updateComposition("x", 0, 0, 0, 1, 1)
    let (ia, ifc) = session.markedInnerSelection16()
    @Assert(ia, 1)
    @Assert(ifc, 1)
}

@Test
func testCompositionCancelProducesZeroTransactions(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    session.cancelComposition()
    @Assert(!session.hasComposition())
    @Assert(owner.text(), "abc")
    @Assert(owner.ver, 1)
    @Assert(session.currentEditSeq(), 0)
    @Assert(owner.writeCalls, 0)
    // 取消后正文可继续正常编辑:不残留组合守卫。
    let after = session.replaceRange16(0, 2, "Z")
    @Assert(after.accepted)
    @Assert(owner.text(), "Zc")
}

@Test
func testCompositionDraftSurvivesOwnerRejection(): Unit {
    // owner 接受后才清草稿:拒绝时用户看到的 preedit 不能被吞掉。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    owner.rejectAll = true
    let commit = session.commitComposition(finalText: "你")
    @Assert(!commit.accepted)
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "nihao")
    let (ms, ml) = session.markedRange16()
    @Assert(ms, 0)
    @Assert(ml, 5)
    @Assert(session.compositionBaseVersionValue(), 1)
    // 结算被拒的回执并要求重新校准,草稿仍可再次提交。
    @Assert(session.acknowledge(commit.ticket, commit.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.hasComposition())                     // 重建镜像不得吞掉用户已看到的 preedit
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    owner.rejectAll = false
    @Assert(session.commitComposition(finalText: "你").accepted)
    @Assert(owner.text(), "你c")
}

@Test
func testAgentWriteDuringCompositionIsNamedRejection(): Unit {
    // owner 登记保护前,至少基版本判别必须拒绝旧组合回调,而不是猜新坐标。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    owner.externalWrite(2, 3, "!")
    @Assert(owner.text(), "ab!")
    let commit = session.commitComposition(finalText: "你")
    @Assert(!commit.accepted)
    @Assert(session.lastRejectReason(), "composition_base_stale")
    @Assert(owner.text(), "ab!")
    @Assert(session.hasComposition())

    // owner 已推进 ⇒ **重发 marked 更新也不得重取基版本**:旧替换范围不能因为重新问了一次
    // owner 就被标成新基版本(Sol 复核前提二)。会话只能具名拒绝,由平台显式取消后重新组字。
    let redraw = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(!redraw.accepted)
    @Assert(session.lastRejectReason(), "composition_base_stale")
    @Assert(session.compositionBaseVersionValue(), 1)     // 基版本仍是组合开始时冻结的那个
    @Assert(owner.text(), "ab!")

    // 按新镜像重备 + 恢复回执到位,再**显式取消旧草稿**并重新组字,同一草稿才落到新正文。
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    session.cancelComposition()
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(session.compositionBaseVersionValue() > 1)
    @Assert(session.commitComposition(finalText: "你").accepted)
    @Assert(owner.text(), "你!")
}

@Test
func testInvalidateDropsStaleDraftAndReceipt(): Unit {
    // 换绑清理:旧草稿与旧代次回执照不能带进新上下文。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(session.hasComposition())
    let edit = session.replaceRange16(0, 1, "Q")
    @Assert(!edit.accepted)
    @Assert(session.lastRejectReason(), "composition_busy")
    let oldEpoch = session.contextEpochValue()
    session.invalidate()
    @Assert(!session.isBound())
    @Assert(!session.hasComposition())
    @Assert(session.compositionText(), "")
    @Assert(session.pendingCount(), 0)
    // 旧代次的回执:先被身份检查挡下,不校准任何当前状态。
    @Assert(!session.acknowledge(1, oldEpoch))
    @Assert(session.lastRejectReason(), "stale_context_receipt")
    // 新代次也没有可结算的票据 —— 清理是真的丢弃,不是留队在队列里。
    @Assert(!session.acknowledge(1, session.contextEpochValue()))
    @Assert(session.lastRejectReason(), "unknown_pending_ticket")
    // 失效会话上的后续编辑具名拒绝,不写正文。
    let late = session.replaceRange16(0, 1, "Q")
    @Assert(!late.accepted)
    @Assert(session.lastRejectReason(), "session_unbound")
    @Assert(owner.text(), "abc")
    @Assert(owner.writeCalls, 0)
    // 重新绑定开启新上下文,同一会话可继续编辑。
    session.bind()
    @Assert(session.isBound())
    let after = session.replaceRange16(0, 1, "Q")
    @Assert(after.accepted)
    @Assert(owner.text(), "Qbc")
}

@Test
func testBoundedContextNeverReadsWholeDocument(): Unit {
    // 原原型每次 readRangeText(0,total) 且超过 8MiB 直接拒绝;会话现在只在驻留的
    // 有界窗口上换算。窗口上限 16 字节,owner 有 4096 字节,读取请求必须始终 ≤16。
    let big = FakeTextOwner(repeatedText("a", 4096))
    let session = makeSession(big, materializeLimit: 16)
    @Assert(big.maxReadBytes <= 16)
    @Assert(session.contentVersion(), 1)
    let edit = session.replaceRange16(2, 2, "Z")
    @Assert(edit.accepted)
    @Assert(big.maxReadBytes <= 16)
    @Assert(big.data.size, 4097)

    // 越出已准备上下文是具名拒绝(缺页按准备契约处理),不是静默钳位。
    let outside = session.replaceRange16(4000, 4000, "Q")
    @Assert(!outside.accepted)
    @Assert(session.lastRejectReason(), CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW)
    @Assert(big.data.size, 4097)
    @Assert(big.writeCalls, 1)

    // 消费方显式把上下文移动到目标绝对位置后,同一编辑才落地。
    @Assert(session.revealByte(2000))
    let inside = session.replaceRange16(5, 5, "Q")
    @Assert(inside.accepted)
    @Assert(big.data.size, 4098)
    // 窗口锚点 = 2000 - 16/4 = 1996;镜像内 UTF-16 偏移 5 即文档字节 2001。
    @Assert(String.fromUtf8(big.data.slice(2001, 1)), "Q")
    @Assert(big.maxReadBytes <= 16)
    let (covStart, covEnd) = session.coverageBytes()
    @Assert(covStart, 1996)
    @Assert(covEnd, 2012)
}

@Test
func testMirrorSnapshotPublishesOneConsistentBoundedWindow(): Unit {
    let owner = FakeTextOwner("a中😀b")
    owner.reportIncompleteBoundedReads = true
    // The fake source returns exact byte slices, so choose a cap that ends on a
    // scalar boundary: "a中" is exactly four UTF-8 bytes.
    let session = makeSession(owner, materializeLimit: 4)
    let first = session.mirrorSnapshot()
    @Assert(first.contentVersion, 1)
    @Assert(first.sourceVersion, 1)
    @Assert(first.startByte, 0)
    @Assert(first.sourceByteLength, 9)
    @Assert(first.text, "a中")
    @Assert(!first.complete)
    @Assert(first.pendingReason, "window_truncated")

    // The same public snapshot advances its text, content version and total together.
    owner.externalWrite(0, 0, "中")
    @Assert(session.refreshMirror())
    let next = session.mirrorSnapshot()
    @Assert(next.contentVersion, 2)
    @Assert(next.sourceVersion, 2)
    @Assert(next.startByte, 0)
    @Assert(next.sourceByteLength, 12)
    @Assert(next.text, "中a")
    @Assert(!next.complete)
    @Assert(owner.maxReadBytes <= 4)
}

@Test
func testUtf16UnitsOnCjkTextAndBoundaryRefusal(): Unit {
    // UTF-16 单位:CJK 每字 1 单位;换算到 UTF-8 字节提交(每字 3 字节)。
    let owner = FakeTextOwner("选区")
    let session = makeSession(owner)
    let edit = session.replaceRange16(1, 2, "X")
    @Assert(edit.accepted)
    @Assert(owner.text(), "选X")

    // emoji 占 2 个 UTF-16 单位:落在代理对中间必须具名拒绝,不挪到其他有效位置。
    let emoji = FakeTextOwner("a😀b")
    let emojiSession = makeSession(emoji)
    let split = emojiSession.replaceRange16(2, 3, "Z")
    @Assert(!split.accepted)
    @Assert(emojiSession.lastRejectReason(), CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
    @Assert(emoji.text(), "a😀b")
    @Assert(emoji.writeCalls, 0)
    // 换算失败是提交前的拒绝:owner 未被触碰,代理与正文没有分叉,因此既不占票据
    // 也不要求重新校准(与 forced_reject 那类 owner 拒绝相对)。
    @Assert(split.ticket, -1)
    @Assert(emojiSession.pendingCount(), 0)
    let whole = emojiSession.replaceRange16(1, 3, "Z")
    @Assert(whole.accepted)
    @Assert(emoji.text(), "aZb")
    let (ws, we) = emojiSession.selection16()
    @Assert(ws, 2)
    @Assert(we, 2)
}

@Test
func testPureSelectionDoesNotAdvanceContent(): Unit {
    let owner = FakeTextOwner("hello")
    let session = makeSession(owner)
    session.setSelection16(2, 5)
    let (s, e) = session.selection16()
    @Assert(s, 2)
    @Assert(e, 5)
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
    @Assert(session.currentEditSeq(), 0)
    @Assert(session.pendingCount(), 0)
}

@Test
func testDirectReplaceDuringCompositionIsBusyRejected(): Unit {
    let owner = FakeTextOwner("选区")
    let session = makeSession(owner)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2)
    let busy = session.replaceRange16(0, 1, "Z")
    @Assert(!busy.accepted)
    @Assert(session.lastRejectReason(), "composition_busy")
    @Assert(session.hasComposition())
    @Assert(owner.writeCalls, 0)
}

@Test
func testExternalOwnerInsertionRebasesSourceCaretBeforeNativeReuse(): Unit {
    let owner = FakeTextOwner("# paXge\n\nabcdef\n")
    let session = makeSession(owner)
    session.setSelection16(5, 5)
    owner.externalWrite(0, 0, "<A>")
    @Assert(session.refreshMirror())
    let mapped = session.selection16()
    @Assert(mapped[0], 8)
    @Assert(mapped[1], 8)
    @Assert(session.needsNativeSelectionRestore())
    @Assert(session.confirmNativeSelectionRestored(2, 8, 8))
    @Assert(!session.needsNativeSelectionRestore())
    let edit = session.replaceRange16(8, 8, "Y")
    @Assert(edit.accepted)
    @Assert(owner.text(), "<A># paXYge\n\nabcdef\n")
}

@Test
func testPreparedSourceRangeWritesOnceFromFarBoundedPage(): Unit {
    let owner = FakeTextOwner("abcdefghijklmnop")
    let session = makeSession(owner, materializeLimit: 8)
    let prepared = session.prepareSourceRange(1, 10, 12)
    @Assert(prepared.isSome())
    @Assert(owner.maxReadBytes <= 8)
    let token = prepared.getOrThrow()
    @Assert(token.startByte, 10)
    @Assert(token.endByte, 12)
    let accepted = token.replace("XY")
    @Assert(accepted.accepted)
    @Assert(session.acknowledge(accepted.ticket, accepted.contextEpoch))
    @Assert(owner.text(), "abcdefghijXYmnop")
    @Assert(owner.writeCalls, 1)
    @Assert(!token.replace("Z").accepted)
    @Assert(owner.writeCalls, 1)
}

@Test
func testPreparedSourceRangeStaleAndUnchangedSourceProxyDoNotLock(): Unit {
    let owner = FakeTextOwner("abcdef")
    let session = makeSession(owner)
    let stale = session.prepareSourceRange(1, 2, 3).getOrThrow()
    owner.externalWrite(0, 0, "Q")
    let refused = stale.replace("X")
    @Assert(!refused.accepted)
    @Assert(refused.ticket, -1)
    @Assert(owner.writeCalls, 0)
    @Assert(!session.awaitingCalibration())

    let prepared = session.prepareSourceRange(2, 3, 4).getOrThrow()
    owner.rejectAll = true
    let sinkRefusal = prepared.replace("Y")
    @Assert(!sinkRefusal.accepted)
    @Assert(sinkRefusal.ticket >= 0)
    @Assert(session.acknowledge(sinkRefusal.ticket, sinkRefusal.contextEpoch))
    @Assert(!session.awaitingCalibration())
    owner.rejectAll = false
    let fresh = session.prepareSourceRange(2, 3, 4).getOrThrow().replace("Y")
    @Assert(fresh.accepted)
    @Assert(owner.text(), "QabYdef")
}

@Test
func testPreparedSourceRangeRefusesBudgetAndUtf8Split(): Unit {
    let owner = FakeTextOwner("a😀bcdefghijk")
    let session = makeSession(owner, materializeLimit: 8)
    @Assert(session.prepareSourceRange(1, 0, 9).isNone())
    @Assert(session.lastRejectReason(), CJGUI_RANGE_TEXT_REASON_BUDGET)
    @Assert(session.prepareSourceRange(1, 2, 3).isNone())
    @Assert(session.lastRejectReason(), CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
    @Assert(owner.writeCalls, 0)
}

@Test
func testIdenticalTextFromNewerOwnerVersionAdvancesMirrorRevision(): Unit {
    // Sol 复核前提三:窗口重备只按字符串比较报告变化,于是"同文不同版本"的镜像被当成没变,
    // 以旧镜像修订表达的范围看起来仍然合法。身份 = (文本, 锚点, 内容版本),任一变化即新镜像。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let revision0 = session.mirrorRevisionValue()
    owner.bumpVersionOnly()
    @Assert(owner.text() == "abc")                         // 字节完全相同
    @Assert(session.refreshMirror())                       // 仍必须报告镜像已变
    @Assert(session.mirrorRevisionValue() > revision0)
    @Assert(session.contentVersion() == owner.ver)
}

@Test
func testMirrorMoveDoesNotReleaseTheCalibrationLock(): Unit {
    // 校准锁要防的是"平台代理已落字、accepted 正文没变"的分叉。移动有界镜像只是让会话
    // 这一侧读到了新内容,native 代理并没有按新镜像重新绑定 ⇒ 不得顺手解锁。
    let owner = FakeTextOwner("abcdefghij")
    let session = makeSession(owner, materializeLimit: 4)
    owner.rejectAll = true
    let rejected = session.replaceRange16(1, 2, "Z")
    @Assert(!rejected.accepted)
    @Assert(session.acknowledge(rejected.ticket, rejected.contextEpoch))
    @Assert(session.awaitingCalibration())
    @Assert(session.revealByte(8))                         // 镜像确实移动了
    @Assert(session.awaitingCalibration())                 // 但锁仍然持有
    let blocked = session.replaceRange16(1, 2, "Z")
    @Assert(!blocked.accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    owner.rejectAll = false
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    // 镜像此刻覆盖文档字节 [7,10) = "hij":同一个 UTF-16 范围 (1,2) 经绝对锚点映射到字节 (8,9)。
    let (coverStart, coverEnd) = session.coverageBytes()
    @Assert(coverStart, 7)
    @Assert(coverEnd, 10)
    @Assert(session.replaceRange16(1, 2, "Z").accepted)
    @Assert(owner.text(), "abcdefghZj")
}

@Test
func testRestorationReceiptTakenBeforeMirrorAdvanceDoesNotUnlock(): Unit {
    // 平台恢复代理要跨回合:它取走回执后,owner 又写了正文(镜像换代)。此时交回的
    // 回执说明的是**上一代**镜像,解不开当前锁;必须重新校准、重新签发、重新恢复。
    // 消费方直接读当前 epoch/mirror 自签自认的话,这个形状会被静默放过。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    owner.rejectAll = true
    let rejected = session.replaceRange16(1, 2, "Z")
    @Assert(!rejected.accepted)
    @Assert(session.acknowledge(rejected.ticket, rejected.contextEpoch))
    @Assert(session.awaitingCalibration())
    // 上锁前没有回执可取:平台不能在还没分叉时就"确认恢复"。
    let (noLockEpoch, noLockMirror) = session.restorationReceipt()
    @Assert(noLockEpoch, -1)
    @Assert(noLockMirror, -1)
    @Assert(session.recalibrate())
    let (receiptEpoch, receiptMirror) = session.restorationReceipt()
    @Assert(receiptEpoch, session.contextEpochValue())
    @Assert(receiptMirror, session.mirrorRevisionValue())
    // 平台还没交回回执,Agent/另一窗口经 owner 改了正文 ⇒ 镜像换代。
    owner.externalWrite(3, 3, "!")
    @Assert(session.refreshMirror())
    @Assert(session.mirrorRevisionValue() > receiptMirror)
    @Assert(!session.confirmProxyRestored(receiptEpoch, receiptMirror))
    @Assert(session.lastRejectReason(), "restore_receipt_mismatch")
    @Assert(session.awaitingCalibration())
    let blocked = session.replaceRange16(1, 2, "Z")
    @Assert(!blocked.accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    @Assert(owner.text(), "abc!")
    // 按新镜像重新校准并重新签发后,同一恢复动作才允许解锁,输入落到 owner 现状上。
    owner.rejectAll = false
    @Assert(session.recalibrate())
    let (freshEpoch, freshMirror) = session.restorationReceipt()
    @Assert(freshMirror > receiptMirror)
    @Assert(session.confirmProxyRestored(freshEpoch, freshMirror))
    @Assert(!session.awaitingCalibration())
    @Assert(session.replaceRange16(1, 2, "Z").accepted)
    @Assert(owner.text(), "aZc!")
    // 解锁后不再有回执可取。
    let (doneEpoch, doneMirror) = session.restorationReceipt()
    @Assert(doneEpoch, -1)
    @Assert(doneMirror, -1)
}

@Test
func testRestorationReceiptRejectsOwnerWriteBeforeMirrorRefresh(): Unit {
    // An external writer can advance the owner while the native proxy is being
    // restored, before anyone calls refreshMirror. Epoch and mirror revision
    // still match the old receipt, but its source version no longer does.
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    owner.rejectAll = true
    let rejected = session.replaceRange16(1, 2, "Z")
    @Assert(!rejected.accepted)
    @Assert(session.acknowledge(rejected.ticket, rejected.contextEpoch))
    @Assert(session.recalibrate())
    let (receiptEpoch, receiptMirror) = session.restorationReceipt()
    owner.externalWrite(3, 3, "!")
    @Assert(!session.confirmProxyRestored(receiptEpoch, receiptMirror))
    @Assert(session.awaitingCalibration())
    @Assert(session.lastRejectReason(), "restore_source_stale")
    @Assert(!session.replaceRange16(1, 2, "Q").accepted)
    @Assert(owner.text(), "abc!")
}

@Test
func testStaleRejectionDoesNotBlockTheNextBoundedSubmit(): Unit {
    // 代理边界可能在投递前把范围裁到旧镜像长度。越出**当前**镜像的提交必须在取得 owner
    // 票据之前具名拒绝,否则一次陈旧拒绝会永久锁住有界窗口的后续输入。
    let owner = FakeTextOwner("abcdefghij")
    let session = makeSession(owner, materializeLimit: 4)
    let outside = session.replaceRange16(0, 10, "Z")
    @Assert(!outside.accepted)
    @Assert(session.lastRejectReason(), CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW)
    @Assert(!session.awaitingCalibration())
    @Assert(owner.writeCalls, 0)
    let inside = session.replaceRange16(1, 2, "Z")
    @Assert(inside.accepted)
    @Assert(owner.text(), "aZcdefghij")
}

@Test
func testCompositionFreezesFirstResolvedReplacementRange(): Unit {
    // 真实平台在后续 setMarkedText 里重报的是"当前 marked 范围"(起点与冻结起点一致)
    // 或 NS_NOT_FOUND。冻结起点之后,一个**不同起点**的范围表达的是另一个替换段,
    // 映射不到 owner 的原始文本上,只能具名拒绝。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    // 第一笔用 NS_NOT_FOUND:按当前选区解析并冻结 [0,2)。
    let began = session.updateComposition("ni", CjguiTextSession.NS_NOT_FOUND, 0, 0, 2, 2)
    @Assert(began.accepted)
    @Assert(session.markedRange16() == (0, 2))
    // 后续 setMarkedText 重报的替换范围是"当前 marked 范围"(起点同冻结起点,长度 = 旧
    // preedit 长度),新 preedit 更长也在 markedLength16 里:接受,冻结区间不变。
    let redraw = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(redraw.accepted)
    @Assert(session.markedRange16() == (0, 5))
    let again = session.updateComposition("nihao!", 0, 5, 0, 6, 6)
    @Assert(again.accepted)
    @Assert(session.commitComposition(finalText: "你").accepted)
    // 替换的是冻结的 [0,2);若误用最后一次更新自称的 [0,5),提交会越界或写错段。
    @Assert(owner.text(), "你c")
}

@Test
func testAcceptedInsertAtBoundedWindowEndRevealsNewCaretBeforeNextInput(): Unit {
    // At a full local window edge, the owner accepts Z just beyond the old
    // mirror. A second key in the same input sequence must use the NEW absolute
    // caret; clamping 17 back to old local offset 16 would produce YZ.
    let owner = FakeTextOwner("abcdefghijklmnopqrst")
    let session = makeSession(owner, materializeLimit: 16)
    let first = session.replaceRange16(16, 16, "Z")
    @Assert(first.accepted)
    let (caretStart, caretEnd) = session.selection16()
    @Assert(caretStart, caretEnd)
    let second = session.replaceRange16(caretStart, caretEnd, "Y")
    @Assert(second.accepted)
    @Assert(owner.text(), "abcdefghijklmnopZYqrst")
    @Assert(owner.writeCalls, 2)
}

@Test
func testCompositionRangeReanchorIsNamedRefusalWithLock(): Unit {
    let owner = FakeTextOwner("hello world")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2)
    // 组合中途显式改起点:另一个替换段,旧草稿无法重锚。
    let reanchor = session.updateComposition("ni", 6, 5, 6, 2, 2)
    @Assert(!reanchor.accepted)
    @Assert(session.lastRejectReason(), "composition_range_changed")
    @Assert(reanchor.ticket >= 0)                          // 一意图一票据,即使预检拒绝
    @Assert(session.awaitingCalibration())                 // 平台侧还挂着 preedit ⇒ 持锁
    @Assert(session.hasComposition())                      // 草稿保留,等待显式取消
    @Assert(owner.writeCalls, 0)
    // 恢复回执到位后同一动作可以解锁,并由平台显式取消后重新组字。
    @Assert(session.acknowledge(reanchor.ticket, reanchor.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.awaitingCalibration())
    session.cancelComposition()
    @Assert(!session.hasComposition())
    @Assert(session.updateComposition("ni", 6, 5, 6, 2, 2).accepted)
    @Assert(session.commitComposition(finalText: "你好").accepted)
    @Assert(owner.text(), "hello 你好")
}

@Test
func testCompositionFrozenRangeReportsExactOwnerBytesAcrossNonBmp(): Unit {
    let owner = FakeTextOwner("a😀b")
    let session = makeSession(owner)
    session.setSelection16(1, 3)
    @Assert(session.compositionFrozenRange().isNone())
    @Assert(session.updateComposition("ni", CjguiTextSession.NS_NOT_FOUND, 0, 1, 2, 2,
        compositionId: 7).accepted)
    if (let Some(span) <- session.compositionFrozenRange()) {
        @Assert(span[0], 7)
        @Assert(span[1], owner.rangeTextVersion())
        @Assert(span[2], 1)
        @Assert(span[3], 3)
        @Assert(span[4], 1)
        @Assert(span[5], 5)
    } else {
        @Assert(false)
    }
    @Assert(session.updateComposition("nihao", 1, 2, 1, 5, 5, compositionId: 7).accepted)
    if (let Some(span) <- session.compositionFrozenRange()) {
        @Assert(span[0], 7)
        @Assert(span[4], 1)
        @Assert(span[5], 5)
    } else {
        @Assert(false)
    }
    @Assert(session.commitComposition(finalText: "你", compositionId: 7).accepted)
    @Assert(session.compositionFrozenRange().isNone())
    @Assert(owner.text(), "a你b")
}

@Test
func testCompositionInnerRangeBeyondPreeditIsNamedRefusal(): Unit {
    // 内部选区相对**本次传入的 preedit**:越界说明平台报的锚点不对应这段文本,
    // 静默钳位会把用户光标搬到别处,因此具名拒绝并持锁(平台侧 preedit 已存在)。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let beyond = session.updateComposition("ni", 0, 2, 0, 3, 3)
    @Assert(!beyond.accepted)
    @Assert(session.lastRejectReason(), "composition_inner_range_invalid")
    @Assert(beyond.ticket >= 0)
    @Assert(session.awaitingCalibration())
    @Assert(!session.hasComposition())
    @Assert(owner.writeCalls, 0)
    @Assert(session.acknowledge(beyond.ticket, beyond.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    // 恢复后:锚点等于 preedit 长度(光标在末尾)是合法边界,被接受并原样回答。
    let began = session.updateComposition("ni", 0, 2, 0, 2, 1)
    @Assert(began.accepted)
    @Assert(session.markedInnerSelection16() == (2, 1))
    // 组合中途越界:拒绝且保留草稿,记录的内部选区不被改写。
    let midBeyond = session.updateComposition("nihao", 0, 2, 0, 6, 6)
    @Assert(!midBeyond.accepted)
    @Assert(session.lastRejectReason(), "composition_inner_range_invalid")
    @Assert(session.hasComposition())
    @Assert(session.markedInnerSelection16() == (2, 1))
}

@Test
func testCompositionExplicitEmptyCommitDeletesTheRange(): Unit {
    // 平台显式提交为空(insertText:@"")是合法终态:替换段被删除。它与"未提供最终
    // 文本"必须分开,后者提交的是当前草稿。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2)
    let empty = session.commitComposition(finalText: "")
    @Assert(empty.accepted)
    @Assert(owner.text(), "c")
    @Assert(!session.hasComposition())
    // 不带参数则提交草稿:同一路径的另一半行为。
    session.setSelection16(1, 1)
    let _ = session.updateComposition("ni", 1, 0, 1, 2, 2)
    @Assert(session.commitComposition().accepted)
    @Assert(owner.text(), "cni")
}

@Test
func testCompositionPrecheckRefusalCarriesIntentTicketAndLock(): Unit {
    // 提交意图即使没有活跃组合也要"一票据一判决":窗口按票据结算,并因为平台侧
    // 提交已经发生而持锁,而不是留下一笔无票判决。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    let orphan = session.commitComposition(compositionId: 4)
    @Assert(!orphan.accepted)
    @Assert(orphan.ticket >= 0)
    @Assert(session.lastRejectReason(), "composition_not_active")
    @Assert(session.awaitingCalibration())
    @Assert(session.acknowledge(orphan.ticket, orphan.contextEpoch))
    @Assert(session.pendingCount(), 0)
    @Assert(owner.writeCalls, 0)
    // 持锁期间普通输入具名拒绝;按恢复回执解锁后照常。
    @Assert(!session.replaceRange16(0, 1, "Z").accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(session.replaceRange16(0, 1, "Z").accepted)
    @Assert(owner.text(), "Zbc")
}

@Test
func testCompositionDuplicateTerminalIsNotANewIntent(): Unit {
    // 同一组合的终态可能经重入路径重复到达:它不是一笔新意图、不产生事务,
    // 也不能因为没有活跃组合就被当成异常而持锁。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2, compositionId: 7)
    let commit = session.commitComposition(finalText: "你", compositionId: 7)
    @Assert(commit.accepted)
    @Assert(owner.text(), "你c")
    let echo = session.commitComposition(finalText: "你", compositionId: 7)
    @Assert(!echo.accepted)
    @Assert(echo.ticket, -1)
    @Assert(session.lastRejectReason(), "composition_terminal_duplicate")
    @Assert(!session.awaitingCalibration())                // 没有新分叉,不持锁
    @Assert(owner.text(), "你c")
    @Assert(owner.writeCalls, 1)
    // 取消同一组合同样幂等:零事务、不持锁。
    session.cancelComposition(compositionId: 7)
    @Assert(session.lastRejectReason(), "composition_terminal_duplicate")
    @Assert(!session.awaitingCalibration())
    @Assert(owner.writeCalls, 1)
}

@Test
func testCompositionUnboundCommitIsCheckedBeforeCompositionState(): Unit {
    // 换绑/销毁后迟到的提交:身份属于已经消失的表面,拒绝原因必须是解绑本身,
    // 而不是"没有活跃组合";解绑会话不持锁(代次已推进,锁无意义)。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2)
    session.invalidate()
    let late = session.commitComposition(finalText: "你")
    @Assert(!late.accepted)
    @Assert(session.lastRejectReason(), "session_unbound")
    @Assert(late.ticket >= 0)
    @Assert(!session.awaitingCalibration())
    @Assert(owner.writeCalls, 0)
}

@Test
func testCompositionIdMismatchDuringActiveComposition(): Unit {
    // 两个组字不能共用一份草稿与冻结范围:活跃组合收到另一个身份的平台更新时具名拒绝。
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("ni", 0, 2, 0, 2, 2, compositionId: 11)
    let stranger = session.updateComposition("ni", 0, 2, 0, 2, 2, compositionId: 12)
    @Assert(!stranger.accepted)
    @Assert(session.lastRejectReason(), "composition_id_mismatch")
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "ni")
}

@Test
func testLateCancelCannotClearNewComposition(): Unit {
    let owner = FakeTextOwner("abc")
    let session = makeSession(owner)
    @Assert(session.updateComposition("old", 0, 0, 0, 3, 3, compositionId: 11).accepted)
    session.cancelComposition(compositionId: 11)
    @Assert(session.updateComposition("new", 0, 0, 0, 3, 3, compositionId: 12).accepted)
    let lateCommit = session.commitComposition(finalText: "旧", compositionId: 11)
    @Assert(!lateCommit.accepted)
    @Assert(lateCommit.ticket, -1)
    @Assert(owner.writeCalls, 0)
    session.cancelComposition(compositionId: 11)
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "new")
    @Assert(owner.writeCalls, 0)
    let committed = session.commitComposition(finalText: "新", compositionId: 12)
    @Assert(committed.accepted)
    @Assert(owner.text(), "新abc")
    @Assert(owner.writeCalls, 1)
}
