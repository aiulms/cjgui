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
    /// Test-only failures around the accepted-edit readback boundary. The default
    /// leaves all existing session tests on the normal owner path.
    var readsUnavailable: Bool = false
    var refuseReadsAfterNextAccept: Bool = false
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
        if (this.readsUnavailable) {
            return CjguiRangeTextSlice(startByte, startByte, "", this.ver,
                this.data.size, false, "test_read_unavailable")
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
        if (this.refuseReadsAfterNextAccept) {
            this.refuseReadsAfterNextAccept = false
            this.readsUnavailable = true
        }
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

@Test
func wholeChoiceUsesExactOwnerEndpointsAndBoundedReads(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghijklmnopqrstuvwxyz🙂")
    let session = makeSession(owner, materializeLimit: 8)
    let _ = session.revealByte(24)
    let choice = session.selectWholeDocument(1).getOrThrow()
    @Assert(choice.byteLength, Int64(owner.data.size))
    @Assert(choice.isCurrent(), true)
    let unaligned = session.replaceRange16(0, cjguiUtf16Length(session.mirrorSnapshot().text), "partial")
    @Assert(unaligned.accepted, false)
    @Assert(owner.writeCalls, 0)
    let edited = choice.replace("x")
    @Assert(edited.accepted, true)
    @Assert(owner.text(), "x")
    @Assert(owner.ver, 2)
    @Assert(owner.writeCalls, 1)
    @Assert(owner.maxReadBytes <= 8, true)
    @Assert(choice.isCurrent(), false)
    @Assert(session.acknowledge(edited.ticket, edited.contextEpoch), true)
    @Assert(choice.replace("replay").accepted, false)
    @Assert(owner.writeCalls, 1)
}

@Test
func wholeChoiceSameValueNewChoiceAndOwnerWriteRevokeAuthority(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghijklmnopqrstuvwxyz")
    let session = makeSession(owner, materializeLimit: 8)
    let old = session.selectWholeDocument(1).getOrThrow()
    let newer = session.selectWholeDocument(1).getOrThrow()
    @Assert(old.isCurrent(), false)
    @Assert(old.replace("").accepted, false)
    @Assert(owner.writeCalls, 0)
    session.setSelection16(0, 0)
    @Assert(newer.isCurrent(), false)
    @Assert(newer.replace("").accepted, false)
    @Assert(owner.writeCalls, 0)
    let beforeOwner = session.selectWholeDocument(1).getOrThrow()
    owner.bumpVersionOnly()
    @Assert(beforeOwner.isCurrent(), false)
    @Assert(beforeOwner.replace("").accepted, false)
    @Assert(owner.writeCalls, 0)
    @Assert(owner.text(), "0123456789abcdefghijklmnopqrstuvwxyz")
}

@Test
func wholeChoiceFailureKeepsOwnerAndRemoteWindow(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghijklmnopqrstuvwxyz")
    let session = makeSession(owner, materializeLimit: 8)
    let _ = session.revealByte(24)
    let prior = session.mirrorSnapshot()
    let choice = session.selectWholeDocument(1).getOrThrow()
    owner.rejectAll = true
    let refused = choice.replace("")
    @Assert(refused.accepted, false)
    @Assert(owner.text(), "0123456789abcdefghijklmnopqrstuvwxyz")
    @Assert(owner.ver, 1)
    @Assert(session.mirrorSnapshot().startByte, prior.startByte)
    @Assert(session.mirrorSnapshot().text, prior.text)
    @Assert(choice.isCurrent(), true)
    @Assert(session.acknowledge(refused.ticket, refused.contextEpoch), true)
}

@Test
func wholeChoiceAcceptedReadFailureNeverResubmits(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghijklmnopqrstuvwxyz")
    let session = makeSession(owner, materializeLimit: 8)
    let choice = session.selectWholeDocument(1).getOrThrow()
    owner.refuseReadsAfterNextAccept = true
    let edited = choice.replace("x")
    @Assert(edited.accepted, true)
    @Assert(owner.text(), "x")
    @Assert(owner.writeCalls, 1)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(choice.replace("replay").accepted, false)
    @Assert(owner.writeCalls, 1)
}

// Cross-fragment owner-range contract. B's actual local TextKit selection is
// [0,2), while the owner choice is [3,7) across A/B. Only the product
// descriptor's directed global endpoints are submitted to the source session.
@Test
func crossFragmentOrdinaryInputReplacesAuthorizedOwnerChoiceExactlyOnce(): Unit {
    let owner = FakeTextOwner("abcdeFGHIJ")
    let session = makeSession(owner, materializeLimit: 10)
    let choiceCurrent = true
    let first = session.submitAuthorizedSelectionRange(77u64, 1u64, 1u64, 0u64,
        1, 11, 3, 7, "X", { => choiceCurrent })
    @Assert(first.accepted, true)
    @Assert(owner.text(), "abcXHIJ")
    @Assert(owner.writeCalls, 1)
    let duplicate = session.submitAuthorizedSelectionRange(77u64, 1u64, 1u64, 0u64,
        1, 11, 3, 7, "X", { => choiceCurrent })
    @Assert(duplicate.ticket, first.ticket)
    @Assert(owner.writeCalls, 1)
    let conflict = session.submitAuthorizedSelectionRange(77u64, 1u64, 1u64, 0u64,
        1, 11, 3, 7, "Y", { => choiceCurrent })
    @Assert(conflict.accepted, false)
    @Assert(conflict.reason, "selection_input_id_conflict")
    @Assert(owner.text(), "abcXHIJ")
    @Assert(session.hasAuthorizedSelectionInputMemo(77u64, 1u64), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(77u64, 1u64), true)
    @Assert(session.hasAuthorizedSelectionInputMemo(77u64, 1u64), false)
    @Assert(session.acknowledgeAuthorizedSelectionInput(77u64, 1u64), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(78u64, 1u64), false)
    @Assert(session.acknowledge(first.ticket, first.contextEpoch), true)
    let replay = session.submitAuthorizedSelectionRange(77u64, 1u64, 1u64, 0u64,
        1, 11, 3, 7, "X", { => false })
    @Assert(replay.accepted, false)
    @Assert(owner.writeCalls, 1)
}

@Test
func crossFragmentInputUsesAfterReceiptAndRejectsLateSameValueChoice(): Unit {
    let owner = FakeTextOwner("abcdeFGHIJ")
    let session = makeSession(owner, materializeLimit: 10)
    let currentChoice = true
    let first = session.submitAuthorizedSelectionRange(78u64, 1u64, 1u64, 0u64,
        1, 20, 3, 7, "X", { => currentChoice })
    @Assert(first.accepted, true)
    @Assert(session.acknowledge(first.ticket, first.contextEpoch), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(78u64, 1u64), true)
    // The owner publishes the first accepted edit and a new collapsed choice
    // at byte 4. The next native input names its actual predecessor.
    let second = session.submitAuthorizedSelectionRange(78u64, 2u64, 2u64, 1u64,
        2, 21, 4, 4, "Y", { => currentChoice })
    @Assert(second.accepted, true)
    @Assert(owner.text(), "abcXYHIJ")
    @Assert(owner.writeCalls, 2)
    @Assert(session.acknowledge(second.ticket, second.contextEpoch), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(78u64, 2u64), true)

    // A same-value selection still has a new revision. A delayed callback for
    // that old revision is rejected even though bytes and endpoints match.
    let stale = session.submitAuthorizedSelectionRange(78u64, 3u64, 3u64, 2u64,
        2, 21, 4, 4, "Z", { => false })
    @Assert(stale.accepted, false)
    @Assert(stale.reason, "selection_input_choice_stale")
    @Assert(owner.text(), "abcXYHIJ")
    @Assert(owner.writeCalls, 2)
}

@Test
func crossFragmentInputRechecksChoiceAfterSourcePreparation(): Unit {
    let owner = FakeTextOwner("abcdeFGHIJ")
    let session = makeSession(owner, materializeLimit: 4)
    let checks = ArrayList<Int64>()
    let staleAtSubmit = session.submitAuthorizedSelectionRange(79u64, 1u64, 1u64, 0u64,
        1, 30, 3, 7, "X", { =>
            checks.add(1)
            return checks.size == 1
        })
    @Assert(staleAtSubmit.accepted, false)
    @Assert(staleAtSubmit.reason, "selection_input_choice_stale")
    @Assert(owner.text(), "abcdeFGHIJ")
    @Assert(owner.writeCalls, 0)
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
    @Assert(!session.hasComposition())
    @Assert(session.recoveryDraftsValue().size, 1)

    // 终态已自行结束组合；恢复回执前新 marked 更新不能另开组合。
    let redraw = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(!redraw.accepted)
    @Assert(session.lastRejectReason(), "recalibration_required")
    @Assert(owner.text(), "ab!")

    // 按新镜像重备 + 恢复回执到位即可重新组字，无额外 cancel。
    @Assert(session.acknowledge(commit.ticket, commit.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 9)
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
    // Moving storage is not accepting a new selection. Old proxy coordinates
    // cannot authorize input at the same local number in a different mirror.
    @Assert(session.replaceRange16(5, 5, "Q").accepted, false)
    @Assert(big.writeCalls, 1)
    session.setSelection16(5, 5)
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
func testPreparedSelectionMirrorMoveCannotReinterpretOldPublicRange(): Unit {
    let owner = FakeTextOwner("abcdefghABCDEFGHijklmnopIJKLMNOP")
    let session = makeSession(owner, materializeLimit: 8)
    session.setSelection16(2, 2)
    let original = session.freezeSelectionTicket()
    let prepared = session.prepareSourceRange(1, 24, 24)
    @Assert(prepared.isSome(), true)
    @Assert(session.mirrorSnapshot().startByte, 24)
    @Assert(session.selectionTicketMatches(original), false)
    let failedInstall = session.commitSelectionTicket(session.freezeSelectionTicket(), 1, 1, { => false })
    @Assert(failedInstall, false)
    let kept = session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()
    @Assert(kept[1], 2)
    @Assert(kept[2], 2)
    @Assert(session.selectedSourceRange().isNone(), true)
    @Assert(session.freezeInstalledRangeHandoffBasis(91, 41, 3).isNone(), true)
    @Assert(session.replaceRange16(2, 2, "WRONG").accepted, false)
    @Assert(owner.writeCalls, 0)
    @Assert(owner.text(), "abcdefghABCDEFGHijklmnopIJKLMNOP")
}

@Test
func testPreparedSelectionMirrorMoveCannotConfirmAliasedNativeSelection(): Unit {
    let owner = FakeTextOwner("abcdefghABCDEFGHijklmnopIJKLMNOP")
    let session = makeSession(owner, materializeLimit: 8)
    session.setSelection16(2, 2)
    @Assert(session.applyDirectedPlainSelection(2, 2), true)
    @Assert(session.prepareSourceRange(1, 24, 24).isSome(), true)
    @Assert(session.confirmNativeSelectionRestored(1, 2, 2), false)
    @Assert(session.handlePlainIntent(MoveRight).handled, false)
    @Assert(owner.writeCalls, 0)
    let kept = session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()
    @Assert(kept[1], 2)
}

@Test
func testPreparedSelectionMirrorMoveCommitsNewChoiceOnlyAfterInstall(): Unit {
    let owner = FakeTextOwner("abcdefghABCDEFGHijklmnopIJKLMNOP")
    let session = makeSession(owner, materializeLimit: 8)
    session.setSelection16(2, 2)
    @Assert(session.prepareSourceRange(1, 24, 24).isSome(), true)
    @Assert(session.commitSelectionTicket(session.freezeSelectionTicket(), 1, 1, { => true }), true)
    let selected = session.selectedSourceRange().getOrThrow()
    @Assert(selected[1], 25)
    @Assert(session.replaceRange16(1, 1, "X").accepted, true)
    @Assert(owner.writeCalls, 1)
    @Assert(owner.text(), "abcdefghABCDEFGHijklmnopIXJKLMNOP")
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
    @Assert(!lateCommit.proxyRecoveryRequired)
    @Assert(owner.writeCalls, 0)
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "new")
    session.cancelComposition(compositionId: 11)
    @Assert(session.hasComposition())
    @Assert(session.compositionText(), "new")
    @Assert(owner.writeCalls, 0)
    let committed = session.commitComposition(finalText: "新", compositionId: 12)
    @Assert(committed.accepted)
    @Assert(owner.text(), "新abc")
    @Assert(owner.writeCalls, 1)
}

// ---- E2(2026-09-28): owner 组合仲裁的可选能力反例 ----
//
// 桩 owner 在最小字节/版本语义上增加"每文档一个活动 claim + 凭据终态"的 owner 行为。它只
// 证明**会话如何调度组合凭据**(begin/提交前守卫/消费分类/精确取消),不替代真实 owner 的
// 判决,也不等于真实 IME 链。
class FakeClaimOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink & CjguiRangeTextCompositionSink {
    var data: Array<Byte>
    var ver: Int64 = 1
    var writeCalls: Int64 = 0
    var beginCalls: Int64 = 0
    var commitCalls: Int64 = 0
    var cancelCalls: Int64 = 0
    var lastBeginIdentity: String = ""
    var lastBeginVersion: Int64 = -1
    var lastBeginStart: Int64 = -1
    var lastBeginEnd: Int64 = -1
    var committedToken: Int64 = -1
    var committedText: String = ""
    var committedRequestId: String = ""
    var committedStart: Int64 = -1
    var committedEnd: Int64 = -1
    var claimToken: Int64 = -1
    var claimStart: Int64 = -1
    var claimEnd: Int64 = -1
    var claimBaseVersion: Int64 = -1
    var tokenSeq: Int64 = 0
    /// 非空 ⇒ 提交在**消费前**被拒绝(claim 保持活动)。
    var refuseCommitWithoutConsuming: String = ""
    /// 非空 ⇒ 提交消费凭据后拒绝(正文未写)。
    var refuseCommitAfterConsuming: String = ""

    init(text: String) {
        this.data = text.toArray()
    }

    // ---- Source ----
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
        if (fromVersion < 1 || fromVersion > this.ver || startByte < 0 || endByte < startByte ||
            fromVersion != this.ver) {
            return None
        }
        return Some((this.ver, startByte, endByte))
    }

    public func rangeTextByteLength(): Int64 {
        return this.data.size
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let start = if (startByte < 0) { 0 } else { startByte }
        let cap = if (start > this.data.size) { 0 } else { this.data.size - start }
        let take = if (maxBytes < cap) { maxBytes } else { cap }
        let body = this.data.slice(start, take)
        return CjguiRangeTextSlice(start, start, String.fromUtf8(body), this.ver, this.data.size,
            true, "")
    }

    // ---- 普通 Sink ----
    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        this.writeCalls += 1
        if (baseVersion != this.ver) {
            return CjguiRangeTextEditOutcome.conflict(this.ver, "version_conflict")
        }
        this.splice(startByte, endByte, inserted)
        return CjguiRangeTextEditOutcome.accepted(baseVersion, this.ver)
    }

    // ---- 组合 Sink ----
    public func beginRangeTextComposition(bindingIdentity: String, expectedVersion: Int64,
        startByte: Int64, endByte: Int64): CjguiRangeTextCompositionClaim {
        this.beginCalls += 1
        this.lastBeginIdentity = bindingIdentity
        this.lastBeginVersion = expectedVersion
        this.lastBeginStart = startByte
        this.lastBeginEnd = endByte
        if (expectedVersion != this.ver) {
            return CjguiRangeTextCompositionClaim.refused("version_conflict", this.ver)
        }
        if (this.claimToken >= 0) {
            return CjguiRangeTextCompositionClaim.refused("composition_busy", this.ver)
        }
        if (startByte < 0 || endByte < startByte || endByte > this.data.size) {
            return CjguiRangeTextCompositionClaim.refused("invalid_range", this.ver)
        }
        this.tokenSeq += 1
        this.claimToken = this.tokenSeq
        this.claimStart = startByte
        this.claimEnd = endByte
        this.claimBaseVersion = expectedVersion
        return CjguiRangeTextCompositionClaim(true, "", this.claimToken, startByte, endByte,
            expectedVersion)
    }

    public func inspectRangeTextComposition(token: Int64): CjguiRangeTextCompositionInspection {
        if (this.claimToken < 0 || token != this.claimToken) {
            return CjguiRangeTextCompositionInspection.refused("composition_stale", this.ver)
        }
        return CjguiRangeTextCompositionInspection(true, "", this.claimStart, this.claimEnd, this.ver)
    }

    public func commitRangeTextComposition(token: Int64, expectedVersion: Int64, text: String,
        requestId: String): CjguiRangeTextCompositionOutcome {
        this.commitCalls += 1
        this.committedToken = token
        this.committedText = text
        this.committedRequestId = requestId
        if (this.refuseCommitWithoutConsuming != "") {
            return CjguiRangeTextCompositionOutcome.refused(this.refuseCommitWithoutConsuming, false,
                this.ver)
        }
        if (this.claimToken < 0 || token != this.claimToken) {
            return CjguiRangeTextCompositionOutcome.refused("composition_stale", false, this.ver)
        }
        if (expectedVersion >= 0 && expectedVersion != this.ver) {
            return CjguiRangeTextCompositionOutcome.refused("version_conflict", false, this.ver)
        }
        let start = this.claimStart
        let end = this.claimEnd
        this.claimToken = -1
        this.committedStart = start
        this.committedEnd = end
        if (this.refuseCommitAfterConsuming != "") {
            return CjguiRangeTextCompositionOutcome(false, false, true, this.refuseCommitAfterConsuming,
                start, end, this.ver, this.ver)
        }
        if (start == end && text.size == 0) {
            return CjguiRangeTextCompositionOutcome(true, false, true, "", start, end, this.ver,
                this.ver)
        }
        let before = this.ver
        this.splice(start, end, text)
        return CjguiRangeTextCompositionOutcome(true, true, true, "", start, end, before, this.ver)
    }

    public func cancelRangeTextComposition(token: Int64): CjguiRangeTextCompositionRelease {
        this.cancelCalls += 1
        if (this.claimToken < 0 || token != this.claimToken) {
            return CjguiRangeTextCompositionRelease.refused("composition_stale")
        }
        this.claimToken = -1
        return CjguiRangeTextCompositionRelease(true, "")
    }

    public func text(): String {
        return String.fromUtf8(this.data)
    }

    /// 不经 Sink 的 owner 侧写入:模拟 Agent/另一窗口在组合期间推进版本。
    public func externalWrite(startByte: Int64, endByte: Int64, inserted: String): Unit {
        this.splice(startByte, endByte, inserted)
    }

    private func splice(startByte: Int64, endByte: Int64, inserted: String): Unit {
        let head = this.data.slice(0, startByte)
        let tail = this.data.slice(endByte, this.data.size - endByte)
        let merged = ArrayList<Byte>()
        merged.add(all: head.toArray())
        merged.add(all: inserted.toArray())
        merged.add(all: tail.toArray())
        this.data = merged.toArray()
        this.ver += 1
    }
}

func makeClaimSession(owner: FakeClaimOwner, nodeId!: Int64 = 1001): CjguiTextSession {
    let window = CjguiRangeTextWindow(nodeId, "plain-text", owner, owner)
    let sink: ?CjguiRangeTextCompositionSink = match (owner as CjguiRangeTextCompositionSink) {
        case Some(wired) => Some(wired)
        case None => None
    }
    let session = CjguiTextSession(window, compositionSink: sink, compositionArbitration: true)
    session.bind()
    return session
}

@Test
func testArbitratedCompositionRegistersTheClaimAndCommitsThroughTheCredential(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    @Assert(session.compositionArbitrationDeclared())
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(began.accepted)
    // owner 侧真的登记了 claim:换算后的绝对源范围与镜像版本一起交给它。
    @Assert(owner.beginCalls, 1)
    @Assert(owner.claimToken, 1)
    @Assert(owner.claimStart, 0)
    @Assert(owner.claimEnd, 2)
    @Assert(owner.claimBaseVersion, 1)
    @Assert(session.compositionClaimTokenValue(), 1)
    @Assert(owner.text(), "abc")                    // 预编辑零正文写入
    @Assert(owner.writeCalls, 0)
    let commit = session.commitComposition(finalText: "你", compositionId: 9)
    @Assert(commit.accepted)
    // 终态只经组合凭据:普通 sink 一次都没被调用,owner 消费了 token 1。
    @Assert(owner.commitCalls, 1)
    @Assert(owner.committedToken, 1)
    @Assert(owner.committedText, "你")
    @Assert(owner.writeCalls, 0)
    @Assert(owner.committedStart, 0)
    @Assert(owner.committedEnd, 2)
    @Assert(owner.committedRequestId, "composition-terminal:1:1")
    @Assert(owner.text(), "你c")
    @Assert(!session.hasComposition())
    @Assert(session.compositionClaimTokenValue(), -1)
    let (s, e) = session.selection16()
    @Assert(s, 1)
    @Assert(e, 1)
    @Assert(session.acknowledge(commit.ticket, commit.contextEpoch))
}

@Test
func testDeclaredArbitrationWithoutCapabilityIsRefusedByName(): Unit {
    let owner = FakeTextOwner("abc")
    let window = CjguiRangeTextWindow(1001, "plain-text", owner, owner)
    // 声明仲裁,sink 却没有组合能力:组合必须具名拒绝,不能静默退回普通写入。
    let session = CjguiTextSession(window, compositionArbitration: true)
    session.bind()
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(!began.accepted)
    @Assert(began.reason, CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE)
    @Assert(!session.hasComposition())
    @Assert(owner.writeCalls, 0)
}

@Test
func testOwnedClaimBeginRefusesAStaleMirrorVersion(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    // owner 在组合开始前已推进(镜像仍是 v1):登记必须失败 version_conflict、零 claim。
    owner.externalWrite(2, 3, "!")
    @Assert(owner.text(), "ab!")
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(!began.accepted)
    @Assert(began.reason, "version_conflict")
    @Assert(owner.beginCalls, 1)
    @Assert(owner.claimToken, -1)
    @Assert(!session.hasComposition())
    @Assert(owner.text(), "ab!")
}

@Test
func testArbitratedCommitRefusalEndsTheClaimByName(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 9)
    // owner 在消费前拒绝(例如它自己的版本守卫):会话具名结束 claim、保留草稿,不再重试。
    owner.refuseCommitWithoutConsuming = "stale_handle"
    let commit = session.commitComposition(finalText: "你", compositionId: 9)
    @Assert(!commit.accepted)
    @Assert(commit.reason, "stale_handle")
    @Assert(!session.hasComposition())
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.compositionClaimTokenValue(), -1)
    @Assert(session.lastRejectReason(), "stale_handle")
    @Assert(owner.claimToken, -1)                   // 绑定身份发起的精确取消
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.text(), "abc")
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
    // 后续终态不会再次触达 owner:失效原因先行拒绝。
    let again = session.commitComposition(finalText: "你", compositionId: 9)
    @Assert(!again.accepted)
    @Assert(again.reason, "composition_terminal_duplicate")
    @Assert(owner.commitCalls, 1)
}

@Test
func testConsumedTerminalWithoutWriteKeepsDraftAndHoldsCalibration(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    owner.refuseCommitAfterConsuming = "apply_rejected"
    let commit = session.commitComposition(finalText: "你")
    @Assert(!commit.accepted)
    @Assert(commit.reason, "apply_rejected")
    // 凭据已消费且正文未写:组合不能再当活动组合重试,终态草稿只作恢复证据。
    @Assert(session.compositionClaimTokenValue(), -1)
    @Assert(!session.hasComposition())
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.lastRejectReason(), "apply_rejected")
    @Assert(session.lastTerminalCompositionDraft(), "你")
    @Assert(session.awaitingCalibration())
    @Assert(owner.text(), "abc")
    @Assert(owner.ver, 1)
    // 走既有恢复回执解锁；终态已经自行结束活动槽。
    @Assert(session.acknowledge(commit.ticket, commit.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.hasComposition())
    owner.refuseCommitAfterConsuming = ""
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(session.compositionClaimTokenValue(), 2)
    let settled = session.commitComposition(finalText: "你")
    @Assert(settled.accepted)
    @Assert(owner.text(), "你c")
}

@Test
func testArbitratedCancelAndInvalidateUseTheExactToken(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(owner.claimToken, 1)
    session.cancelComposition()
    @Assert(!session.hasComposition())
    @Assert(session.compositionClaimTokenValue(), -1)
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.claimToken, -1)                   // 精确 token 取消,不是通配
    @Assert(owner.text(), "abc")
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
    // 换绑/销毁同样由生命周期发起精确取消,不让保护跨绑定存活。
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(owner.claimToken, 2)
    session.invalidate()
    @Assert(owner.cancelCalls, 2)
    @Assert(owner.claimToken, -1)
    @Assert(session.compositionClaimTokenValue(), -1)
}

@Test
func testNoChangeTerminalSettlesWithoutVersionOrHistory(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(1, 1)
    let began = session.updateComposition("", 1, 0, 1, 0, 0)
    @Assert(began.accepted)
    @Assert(owner.claimStart, 1)
    @Assert(owner.claimEnd, 1)
    let commit = session.commitComposition(finalText: "")
    // 零宽 claim + 空终态:已结算但零版本、零历史,不算一次已接受的组合写入。
    @Assert(commit.accepted)
    @Assert(commit.reason, CJGUI_RANGE_TEXT_REASON_COMPOSITION_NO_CHANGE)
    @Assert(commit.versionAfter, 1)
    @Assert(!session.hasComposition())
    @Assert(session.compositionClaimTokenValue(), -1)
    @Assert(!session.awaitingCalibration())
    @Assert(owner.text(), "abc")
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
}

@Test
func testNonArbitratedBindingKeepsTheOrdinaryCompositionPath(): Unit {
    let owner = FakeClaimOwner("abc")
    let window = CjguiRangeTextWindow(1001, "plain-text", owner, owner)
    let session = CjguiTextSession(window)
    session.bind()
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5)
    @Assert(began.accepted)
    // 未声明仲裁:会话一个 claim 都不登记,提交仍走普通 sink(旧路径完全不变)。
    @Assert(owner.beginCalls, 0)
    @Assert(session.compositionClaimTokenValue(), -1)
    let commit = session.commitComposition(finalText: "你")
    @Assert(commit.accepted)
    @Assert(owner.writeCalls, 1)
    @Assert(owner.commitCalls, 0)
    @Assert(owner.text(), "你c")
}

// ---- E2 复核第 1 项（2026-09-28,Astra 重锚裁决 Q4 安全恢复分支） ----

/// α 终局:外部正文在 claim 之上推进 → 扰乱取消保存独立恢复草稿 → 输入门关闭 →
/// 恢复确认放行 → 新组合恰好一次提交;已接受 Agent 事务保留、失败恢复零正文写入。
@Test
func testDisruptedCompositionSavesRecoveryDraftAndRecoversInput(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 1)
    @Assert(owner.claimToken, 1)
    // Agent 末尾追加:owner 版本前进,外部事务已被接受并保留。
    owner.externalWrite(3, 3, "X")
    @Assert(owner.text(), "abcX")
    @Assert(owner.ver, 2)
    let disrupted = session.disruptComposition(1, "composition_reanchor_unavailable",
        "native_context_lost")
    @Assert(!disrupted.accepted)
    @Assert(disrupted.reason, "composition_reanchor_unavailable")
    // claim 已按精确 token 结束;失败恢复自身零正文写入、零新撤销记录。
    @Assert(owner.claimToken, -1)
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.ver, 2)
    @Assert(owner.writeCalls, 0)
    @Assert(owner.commitCalls, 0)
    // 独立恢复草稿:内容、冻结范围(旧版本坐标)、来源版本与组合身份俱全。
    let draft = session.recoveryDraftValue()
    @Assert(draft.isSome())
    if (let Some(value) <- draft) {
        @Assert(value.content, "nihao")
        @Assert(value.sourceStartByte, 0)
        @Assert(value.sourceEndByte, 2)
        @Assert(value.sourceVersion, 1)
        @Assert(value.compositionId, 1)
        @Assert(value.token, 1)
        @Assert(value.reason, "composition_reanchor_unavailable")
        @Assert(value.cause, "native_context_lost")
    }
    // 组合状态已结束;迟到/重复取消不得删掉恢复草稿。
    @Assert(!session.hasComposition())
    session.cancelComposition(compositionId: 1)
    @Assert(session.recoveryDraftValue().isSome())
    // 输入门关闭:旧坐标的普通输入在恢复确认前被具名拒绝。
    @Assert(session.awaitingCalibration())
    let refused = session.replaceRange16(3, 3, "z")
    @Assert(!refused.accepted)
    @Assert(refused.reason, "recalibration_required")
    @Assert(owner.ver, 2)
    // 恢复链:结算扰乱票据 → 按 owner 现状重建镜像 → 完整回执确认 → 放行。
    @Assert(session.acknowledge(disrupted.ticket, disrupted.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.awaitingCalibration())
    // 重组字恰好一次:新 claim 新 token,一笔事务落盘。
    let _ = session.updateComposition("hao", 1, 1, 1, 3, 3, compositionId: 2)
    @Assert(owner.claimToken, 2)
    let settled = session.commitComposition(finalText: "好", compositionId: 2)
    @Assert(settled.accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "a好cX")
    @Assert(owner.ver, 3)
    // 草稿仍在:新组合的成功不吞掉它;按身份显式取回一次性交出。
    let draftId = match (session.recoveryDraftValue()) {
        case Some(value) => value.draftId
        case None => -1
    }
    @Assert(draftId > 0)
    @Assert(session.canConsumeRecoveryDraft(draftId))
    let retrieved = session.consumeRecoveryDraft(draftId)
    @Assert(retrieved.isSome())
    @Assert(session.recoveryDraftValue().isNone())
    let again = session.consumeRecoveryDraft(draftId)
    @Assert(again.isNone())
    @Assert(session.lastRejectReason(), "recovery_draft_absent")
}

/// 草稿绑定身份:换绑(新文档/新绑定)后取回被具名拒绝,禁止恢复到新目标。
@Test
func testRecoveryDraftCannotBeConsumedAfterRebind(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 1)
    owner.externalWrite(3, 3, "X")
    let disrupted = session.disruptComposition(1, "composition_reanchor_unavailable",
        "native_context_lost")
    let _ = session.acknowledge(disrupted.ticket, disrupted.contextEpoch)
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    // 换绑推进代次:旧草稿不能再取回到新绑定上,但保留为可辨认证据。
    session.bind()
    @Assert(session.recoveryDraftsValue().size, 1)
    let staleId = session.recoveryDraftsValue()[0].draftId
    @Assert(!session.canConsumeRecoveryDraft(staleId))
    @Assert(session.lastRejectReason(), "recovery_draft_binding_lost")
    @Assert(session.consumeRecoveryDraft(staleId).isNone())
    @Assert(session.recoveryDraftsValue().size, 1)
    // 显式放弃(按身份)后队列清空。
    @Assert(session.discardRecoveryDraft(staleId))
    @Assert(session.recoveryDraftValue().isNone())
    @Assert(!session.discardRecoveryDraft(staleId))
}

/// 呈现面组合(E2 复核:presentation TEXT 接同一 owner claim)。映射器给出的源字节
/// 跨度在 begin 登记;update 零写入;commit 只经凭据落一笔事务。
@Test
func testPresentationCompositionRegistersClaimAndCommitsThroughCredential(): Unit {
    let owner = FakeClaimOwner("# 标题\n\n正文。\n")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    // 映射器解析出的同版本源跨度:替换「正文。」
    let began = session.beginPresentationComposition(mirror.sourceVersion, 10, 16,
        mirror.contextEpoch, mirror.mirrorRevision, 7)
    @Assert(began.accepted)
    @Assert(owner.beginCalls, 1)
    @Assert(owner.claimStart, 10)
    @Assert(owner.claimEnd, 16)
    @Assert(session.compositionClaimTokenValue(), 1)
    // 冻结范围以源字节报告(UTF-16 端点不适用)。
    if (let Some(frozen) <- session.compositionFrozenRange()) {
        @Assert(frozen[0], 7)
        @Assert(frozen[4], 10)
        @Assert(frozen[5], 16)
    } else {
        @Assert(false)
    }
    let updated = session.updatePresentationComposition("nihao", 5, 5, 7)
    @Assert(updated.accepted)
    @Assert(session.compositionText(), "nihao")
    @Assert(owner.writeCalls, 0)
    @Assert(owner.ver, 1)
    let settled = session.commitPresentationComposition("你好", 7)
    @Assert(settled.accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.committedToken, 1)
    @Assert(owner.committedText, "你好")
    @Assert(owner.committedStart, 10)
    @Assert(owner.committedEnd, 16)
    @Assert(owner.writeCalls, 0)                     // 终态绝不经普通 sink
    @Assert(owner.text(), "# 标题\n\n你好。\n")
    @Assert(!session.hasComposition())
    @Assert(session.acknowledge(settled.ticket, settled.contextEpoch))
}

/// 呈现面组合期间 owner 版本前进:update 具名拒绝 base_stale、claim 精确结束、
/// 草稿保留给平台取消;随后的取消清理状态,零事务。
@Test
func testPresentationCompositionBaseStaleEndsClaimByName(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 4)
    owner.externalWrite(3, 3, "!")
    let updated = session.updatePresentationComposition("x", 1, 1, 4)
    @Assert(!updated.accepted)
    @Assert(updated.reason, "composition_base_stale")
    @Assert(owner.claimToken, -1)
    @Assert(owner.cancelCalls, 1)
    // begin 之后没有已接受的 preedit:无可恢复内容,不产生空草稿(恢复门仍关闭)。
    @Assert(session.compositionText(), "")
    @Assert(session.recoveryDraftsValue().size, 0)
    @Assert(session.awaitingCalibration())
    // 平台随后的取消相位清理组合状态;正文零变化。
    session.cancelPresentationComposition(compositionId: 4)
    @Assert(!session.hasComposition())
    @Assert(owner.ver, 2)
    @Assert(owner.writeCalls, 0)
    // 恢复确认后输入门放行。
    @Assert(session.acknowledge(updated.ticket, updated.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.awaitingCalibration())
}

/// α visual 真实反例的框架侧固化:呈现面的终局相位(phase 2 提交)遇到 owner 版本
/// 前进时,已接受的 preedit 必须落成恢复草稿(旧坐标只作证据),不得静默丢弃;
/// 完整恢复确认后可重新组字并提交,草稿仍按身份一次性取回。
@Test
func testPresentationCommitOnStaleBaseRetainsPreeditDraft(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 5)
    let updated = session.updatePresentationComposition("nihao", 3, 3, 5)
    @Assert(updated.accepted)
    @Assert(session.compositionText(), "nihao")
    owner.externalWrite(3, 3, "!")
    let settled = session.commitPresentationComposition("你", 5)
    @Assert(!settled.accepted)
    @Assert(settled.reason, "composition_base_stale")
    @Assert(owner.claimToken, -1)
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.writeCalls, 0)
    @Assert(owner.commitCalls, 0)
    // 草稿 = 最后被接受的 preedit,带呈现面身份(1)与旧版本冻结坐标。
    let draft = session.recoveryDraftValue()
    @Assert(draft.isSome())
    if (let Some(value) <- draft) {
        @Assert(value.content, "nihao")
        @Assert(value.surface, 1)
        @Assert(value.sourceStartByte, 0)
        @Assert(value.sourceEndByte, 2)
        @Assert(value.sourceVersion, 1)
        @Assert(value.token, 1)
        @Assert(value.reason, "composition_base_stale")
        @Assert(value.cause, "owner_version_advanced")
    }
    // 平台迟到的取消相位收尾同一次组合:不产生第二份草稿。
    session.cancelPresentationComposition(compositionId: 5)
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(!session.hasComposition())
    @Assert(session.awaitingCalibration())
    // 恢复链:结算 → 重建投影 → 完整回执确认,之后同一会话重新组字并落一笔事务。
    @Assert(session.acknowledge(settled.ticket, settled.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(!session.awaitingCalibration())
    let mirror2 = session.mirrorSnapshot()
    let began = session.beginPresentationComposition(mirror2.sourceVersion, 0, 2,
        mirror2.contextEpoch, mirror2.mirrorRevision, 6)
    @Assert(began.accepted)
    let _ = session.updatePresentationComposition("hao", 3, 3, 6)
    let final = session.commitPresentationComposition("好", 6)
    @Assert(final.accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "好c!")
    // 被中断的 preedit 仍可按身份取回一次(与新组合的成功提交互不吞噬)。
    let draftId = match (session.recoveryDraftValue()) {
        case Some(value) => value.draftId
        case None => -1
    }
    @Assert(draftId > 0)
    @Assert(session.consumeRecoveryDraft(draftId).isSome())
}

/// A terminal refusal must release the active slot itself. There is no promise that
/// AppKit sends a second cancel after the rejected commit.
@Test
func testSourceStaleTerminalRecoversWithoutSyntheticCancel(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let began = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 71)
    @Assert(began.accepted)
    owner.externalWrite(3, 3, "!")
    let refused = session.commitComposition(finalText: "你好", compositionId: 71)
    @Assert(!refused.accepted)
    @Assert(refused.reason, "composition_base_stale")
    @Assert(!session.hasComposition())
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.commitCalls, 0)
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.awaitingCalibration())
    @Assert(session.acknowledge(refused.ticket, refused.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let next = session.updateComposition("hao", 0, 2, 0, 3, 3, compositionId: 72)
    @Assert(next.accepted)
    let committed = session.commitComposition(finalText: "好", compositionId: 72)
    @Assert(committed.accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "好c!")
    @Assert(session.recoveryDraftsValue().size, 1)
}

@Test
func testSourceUpdateStaleThenTerminalRecoversWithoutSyntheticCancel(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    @Assert(session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 73).accepted)
    owner.externalWrite(3, 3, "!")
    let stale = session.updateComposition("niha", 0, 2, 0, 4, 4, compositionId: 73)
    @Assert(!stale.accepted)
    @Assert(stale.reason, "composition_base_stale")
    let terminal = session.commitComposition(finalText: "你好", compositionId: 73)
    @Assert(!terminal.accepted)
    @Assert(terminal.reason, "composition_base_stale")
    @Assert(!session.hasComposition())
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.commitCalls, 0)
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.acknowledge(stale.ticket, stale.contextEpoch))
    @Assert(session.acknowledge(terminal.ticket, terminal.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    @Assert(session.updateComposition("hao", 0, 2, 0, 3, 3, compositionId: 74).accepted)
    @Assert(session.commitComposition(finalText: "好", compositionId: 74).accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "好c!")
}

@Test
func testVisualDirectStaleTerminalRecoversWithoutSyntheticCancel(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    @Assert(session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 83, firstPreedit: "nihao").accepted)
    owner.externalWrite(3, 3, "!")
    let refused = session.commitPresentationComposition("你好", 83)
    @Assert(!refused.accepted)
    @Assert(refused.reason, "composition_base_stale")
    @Assert(!session.hasComposition())
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.commitCalls, 0)
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.acknowledge(refused.ticket, refused.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let nextMirror = session.mirrorSnapshot()
    @Assert(session.beginPresentationComposition(nextMirror.sourceVersion, 0, 2,
        nextMirror.contextEpoch, nextMirror.mirrorRevision, 84).accepted)
    @Assert(session.commitPresentationComposition("好", 84).accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "好c!")
}

@Test
func testVisualUpdateStaleThenTerminalRecoversWithoutSyntheticCancel(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    let began = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 81)
    @Assert(began.accepted)
    let preedit = session.updatePresentationComposition("nihao", 5, 5, 81)
    @Assert(preedit.accepted)
    owner.externalWrite(3, 3, "!")
    let stale = session.updatePresentationComposition("niha", 4, 4, 81)
    @Assert(!stale.accepted)
    @Assert(stale.reason, "composition_base_stale")
    let terminal = session.commitPresentationComposition("你好", 81)
    @Assert(!terminal.accepted)
    @Assert(terminal.reason, "composition_base_stale")
    @Assert(!session.hasComposition())
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.commitCalls, 0)
    @Assert(session.recoveryDraftsValue().size, 1)
    @Assert(session.acknowledge(stale.ticket, stale.contextEpoch))
    @Assert(session.acknowledge(terminal.ticket, terminal.contextEpoch))
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let nextMirror = session.mirrorSnapshot()
    let next = session.beginPresentationComposition(nextMirror.sourceVersion, 0, 2,
        nextMirror.contextEpoch, nextMirror.mirrorRevision, 82)
    @Assert(next.accepted)
    let committed = session.commitPresentationComposition("好", 82)
    @Assert(committed.accepted)
    @Assert(owner.commitCalls, 1)
    @Assert(owner.text(), "好c!")
    @Assert(session.recoveryDraftsValue().size, 1)
}

/// 呈现面组合取消:零事务、按精确 token 结束、重复终态幂等。
@Test
func testPresentationCompositionCancelUsesExactToken(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 9)
    @Assert(owner.claimToken, 1)
    session.cancelPresentationComposition(compositionId: 9)
    @Assert(owner.cancelCalls, 1)
    @Assert(owner.claimToken, -1)
    @Assert(!session.hasComposition())
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
    // 正文表面入口不能解释呈现面组合的任何相位。
    let mirror2 = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror2.sourceVersion, 0, 2,
        mirror2.contextEpoch, mirror2.mirrorRevision, 10)
    let sourcePhase = session.updateComposition("ab", 0, 0, 0, 2, 2, compositionId: 10)
    @Assert(!sourcePhase.accepted)
    @Assert(sourcePhase.reason, "composition_busy")
    session.cancelPresentationComposition(compositionId: 10)
    @Assert(owner.claimToken, -1)
}

/// 取消相位的打断判据:owner 版本越过组合基点就是中断,即使被组字片段自己的渲染值
/// 没变(外部写落在别的片段)——只按表面值变化判会漏判成普通 cancel,preedit 丢失。
@Test
func testCompositionBaseStaleIsTheOwnerVersionPredicate(): Unit {
    let owner = FakeClaimOwner("# 标题\n\n正文。\n")
    let session = makeClaimSession(owner)
    // 没有活动组合:判据为假(cancel 相位不得凭空造中断)。
    @Assert(!session.compositionBaseStale())
    let mirror = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror.sourceVersion, 10, 16,
        mirror.contextEpoch, mirror.mirrorRevision, 7)
    @Assert(!session.compositionBaseStale())
    // 外部写落在**别的片段**(组合范围之外,组合自己的源跨度仍逐字未变)。
    owner.externalWrite(0, 0, "X")
    @Assert(session.compositionBaseStale())
    // 结束这次组合后判据随组合消失:普通 cancel 不继承上一次的 stale。
    session.cancelPresentationComposition(compositionId: 7)
    @Assert(!session.compositionBaseStale())
    // 新组合以新版本为基点,再次为假。
    let mirror2 = session.mirrorSnapshot()
    let _ = session.beginPresentationComposition(mirror2.sourceVersion, 11, 17,
        mirror2.contextEpoch, mirror2.mirrorRevision, 8)
    @Assert(!session.compositionBaseStale())
    session.cancelPresentationComposition(compositionId: 8)
}

/// 未声明仲裁的绑定不得使用呈现面 claim 入口(具名拒绝,不静默退回普通写入)。
@Test
func testPresentationCompositionRequiresArbitrationDeclaration(): Unit {
    let owner = FakeClaimOwner("abc")
    let window = CjguiRangeTextWindow(1001, "plain-text", owner, owner)
    let session = CjguiTextSession(window)
    session.bind()
    let mirror = session.mirrorSnapshot()
    let began = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 3)
    @Assert(!began.accepted)
    @Assert(began.reason, CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE)
    @Assert(owner.beginCalls, 0)
    @Assert(owner.writeCalls, 0)
}

// ---- E2 复核第 1 项（2026-09-28 第二轮）：统一恢复确认门 + 有身份恢复草稿 ----

/// 交错 1：首个相位本身也是数据。begin 与 preedit 在同一相位入账后立即扰乱——
/// 保存的草稿就是刚显示的文字（唯一一次 marked update 之后的真实形状）。
@Test
func testFirstPresentationPhaseIsItselfTheDraft(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    let mirror = session.mirrorSnapshot()
    let began = session.beginPresentationComposition(mirror.sourceVersion, 0, 2,
        mirror.contextEpoch, mirror.mirrorRevision, 21, firstPreedit: "ni",
        firstInnerAnchor16: 2, firstInnerFocus16: 2)
    @Assert(began.accepted)
    @Assert(session.compositionText(), "ni")
    @Assert(owner.text(), "abc")
    // 唯一一次 marked update 之后外部扰乱:草稿内容与显示一致。
    owner.externalWrite(3, 3, "!")
    let disrupted = session.disruptComposition(21, "composition_reanchor_unavailable",
        "native_context_lost")
    @Assert(!disrupted.accepted)
    let draft = match (session.recoveryDraftValue()) {
        case Some(value) => value
        case None => @Assert(session.recoveryDraftValue().isSome()); return
    }
    @Assert(draft.content, "ni")
    @Assert(draft.compositionId, 21)
    @Assert(draft.draftId > 0)
}

/// 交错 2：恢复确认未完成（ACK 延迟/失败）期间,新组字、普通编辑、prepared 写入
/// 全部具名拒绝;零新增 claim/事务/历史,确认后才放行。
@Test
func testRecoveryGateBlocksAllInputsUntilFullConfirmation(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 2)
    let _ = session.updateComposition("nihao", 0, 2, 0, 5, 5, compositionId: 1)
    owner.externalWrite(3, 3, "!")
    let disrupted = session.disruptComposition(1, "composition_reanchor_unavailable",
        "native_context_lost")
    @Assert(session.awaitingCalibration())
    let versionAfterDisrupt = owner.ver
    // 新组字(两表面)、普通编辑、prepared 写入都关在门外。
    let newMarked = session.updateComposition("x", 0, 0, 0, 1, 1, compositionId: 2)
    @Assert(!newMarked.accepted)
    @Assert(newMarked.reason, "recalibration_required")
    let mirror2 = session.mirrorSnapshot()
    let presentationBegin = session.beginPresentationComposition(mirror2.sourceVersion,
        0, 0, mirror2.contextEpoch, mirror2.mirrorRevision, 3)
    @Assert(!presentationBegin.accepted)
    @Assert(presentationBegin.reason, "recalibration_required")
    let plainEdit = session.replaceRange16(0, 0, "z")
    @Assert(!plainEdit.accepted)
    @Assert(plainEdit.reason, "recalibration_required")
    let prepared = session.prepareSourceRange(owner.ver, 0, 0)
    @Assert(prepared.isNone())
    @Assert(session.lastRejectReason(), "recalibration_required")
    // 零新增 claim/事务/历史。
    @Assert(owner.beginCalls, 1)
    @Assert(owner.writeCalls, 0)
    @Assert(owner.commitCalls, 0)
    @Assert(owner.ver, versionAfterDisrupt)
    // recalibrate 之后、完整回执确认之前,门仍然关着。
    @Assert(session.acknowledge(disrupted.ticket, disrupted.contextEpoch))
    @Assert(session.recalibrate())
    let stillGated = session.replaceRange16(0, 0, "z")
    @Assert(!stillGated.accepted)
    @Assert(stillGated.reason, "recalibration_required")
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let released = session.replaceRange16(0, 0, "z")
    @Assert(released.accepted)
    @Assert(owner.text(), "zabc!")
}

/// 交错 3：A 草稿未处理时 B 再中断——追加而非覆盖,两份身份可辨;容量占满后
/// 新组字在 begin 处具名拒绝,放弃 A 后才放行。
@Test
func testRecoveryDraftsAppendWithIdentityUntilCapacity(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    // A:第一段组合被扰乱。
    session.setSelection16(0, 0)
    let _ = session.updateComposition("A-preedit", 0, 0, 0, 9, 9, compositionId: 1)
    owner.externalWrite(3, 3, "!")
    let disruptedA = session.disruptComposition(1, "composition_reanchor_unavailable",
        "native_context_lost")
    let _ = session.acknowledge(disruptedA.ticket, disruptedA.contextEpoch)
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let draftsA = session.recoveryDraftsValue()
    @Assert(draftsA.size, 1)
    @Assert(draftsA[0].content, "A-preedit")
    let idA = draftsA[0].draftId
    // B:恢复确认后的第二段组合再被扰乱——追加,不覆盖 A。
    session.setSelection16(0, 0)
    let _ = session.updateComposition("B-preedit", 0, 0, 0, 9, 9, compositionId: 2)
    owner.externalWrite(4, 4, "?")
    let disruptedB = session.disruptComposition(2, "composition_reanchor_unavailable",
        "native_context_lost")
    let _ = session.acknowledge(disruptedB.ticket, disruptedB.contextEpoch)
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let draftsB = session.recoveryDraftsValue()
    @Assert(draftsB.size, 2)
    @Assert(draftsB[0].content, "B-preedit")         // 新→旧
    @Assert(draftsB[1].content, "A-preedit")
    let idB = draftsB[0].draftId
    @Assert(idB != idA)
    @Assert(session.recoveryDraftsDisplacedCount(), 0)
    // 容量占满:新组字在 begin 处具名拒绝(A/B 都未被处理)。
    session.setSelection16(0, 0)
    let refused = session.updateComposition("C", 0, 0, 0, 1, 1, compositionId: 3)
    @Assert(!refused.accepted)
    @Assert(refused.reason, "recovery_draft_capacity")
    @Assert(owner.beginCalls, 2)
    // 按身份放弃 A 后,容量恢复,新组字可登记。
    @Assert(session.discardRecoveryDraft(idA))
    @Assert(session.recoveryDraftsValue().size, 1)
    session.setSelection16(0, 0)
    let beganC = session.updateComposition("C", 0, 0, 0, 1, 1, compositionId: 3)
    @Assert(beganC.accepted)
    @Assert(owner.beginCalls, 3)
    session.cancelComposition(compositionId: 3)
    // 按身份取回 B;错身份/已消费身份都具名拒绝。
    @Assert(session.canConsumeRecoveryDraft(idB))
    let retrieved = session.consumeRecoveryDraft(idB)
    @Assert(retrieved.isSome())
    @Assert(session.consumeRecoveryDraft(idB).isNone())
    @Assert(session.lastRejectReason(), "recovery_draft_absent")
    @Assert(session.recoveryDraftValue().isNone())
}

/// 交错 4：旧草稿取回的身份校验在**写前**发生——身份不符零正文写入,草稿可辨认。
@Test
func testRecoveryDraftIdentityCheckedBeforeAnyWrite(): Unit {
    let owner = FakeClaimOwner("abc")
    let session = makeClaimSession(owner)
    session.setSelection16(0, 0)
    let _ = session.updateComposition("旧词", 0, 0, 0, 2, 2, compositionId: 1)
    owner.externalWrite(3, 3, "!")
    let disrupted = session.disruptComposition(1, "composition_reanchor_unavailable",
        "native_context_lost")
    let _ = session.acknowledge(disrupted.ticket, disrupted.contextEpoch)
    @Assert(session.recalibrate())
    @Assert(session.confirmProxyRestored(session.contextEpochValue(), session.mirrorRevisionValue()))
    let draftId = session.recoveryDraftsValue()[0].draftId
    // 不存在的身份:写前校验失败,零正文变化,草稿保留。
    @Assert(!session.canConsumeRecoveryDraft(draftId + 100))
    @Assert(session.lastRejectReason(), "recovery_draft_absent")
    @Assert(session.consumeRecoveryDraft(draftId + 100).isNone())
    @Assert(owner.writeCalls, 0)
    @Assert(owner.ver, 2)
    @Assert(session.recoveryDraftsValue().size, 1)
}


/// 模拟生产窗口在纯选区意图后的"推送+确认"链（restore 标记清除）。
private func confirmPlainSelectionPush(session: CjguiTextSession): Unit {
    let (a, b) = session.selection16()
    let version = session.mirrorSnapshot().contentVersion
    let _ = session.confirmNativeSelectionRestored(version, a, b)
}

// ---- 普通文字意图共同处理器（Astra Q5；E/macOS B 切片） ----

@Test
func testPlainIntentMovesByWholeGraphemeCluster(): Unit {
    // "a👨‍👩‍👧b"：a[0,1) 家庭[1,19) b[19,20)；UTF-16 a=0, 家庭=[1,9), b=9, 末=10。
    let owner = FakeTextOwner("a👨‍👩‍👧b")
    let session = makeSession(owner)
    session.setSelection16(10, 10)
    let left = session.handlePlainIntent(CjguiTextPlainIntent.MoveLeft)
    @Assert(left.handled, true)
    @Assert(left.wroteOwner, false)
    @Assert(left.selectionStart16, 9)
    @Assert(left.selectionEnd16, 9)
    let left2 = session.handlePlainIntent(CjguiTextPlainIntent.MoveLeft)
    @Assert(left2.selectionStart16, 1)   // 一次跨过整个家庭（8 个 UTF-16 单位）
    confirmPlainSelectionPush(session)
    let right = session.handlePlainIntent(CjguiTextPlainIntent.MoveRight)
    @Assert(right.selectionStart16, 9)   // 回程同样整簇
    @Assert(right.wroteOwner, false)
    @Assert(owner.writeCalls, 0)          // 纯移动零正文事务
}

@Test
func testPlainIntentExtendCoversWholeCluster(): Unit {
    let owner = FakeTextOwner("AéB")
    let session = makeSession(owner)
    session.setSelection16(1, 1)
    let extendSel = session.handlePlainIntent(CjguiTextPlainIntent.ExtendRight)
    @Assert(extendSel.handled, true)
    @Assert(extendSel.wroteOwner, false)
    @Assert(extendSel.selectionStart16, 1)
    @Assert(extendSel.selectionEnd16, 2)     // é（预组合）整簇一次覆盖
    // 扩选后的删除=一笔精确事务（生产中窗口先推送确认选区）。
    confirmPlainSelectionPush(session)
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(del.handled, true)
    @Assert(del.wroteOwner, true)
    @Assert(owner.text(), "AB")
    @Assert(owner.writeCalls, 1)          // 恰好一笔
}

@Test
func testPlainIntentDeleteBackwardWholeCluster(): Unit {
    // 分解式 e+U+0301：一次 Backspace 删整簇 3B（不是只删组合符）。
    let owner = FakeTextOwner("Ae\u{0301}B")
    let session = makeSession(owner)
    session.setSelection16(3, 3)          // UTF-16: A=0, e=1, U+0301=2, B=3
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(del.handled, true)
    @Assert(del.wroteOwner, true)
    @Assert(owner.text(), "AB")
    @Assert(owner.writeCalls, 1)
}

@Test
func testPlainIntentInteriorCaretRefusesWithZeroWrite(): Unit {
    let owner = FakeTextOwner("Ae\u{0301}B")
    let session = makeSession(owner)
    session.setSelection16(2, 2)          // caret 落在 e 与组合符之间（簇内部）
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(del.handled, false)
    @Assert(del.reason, "grapheme_interior")
    @Assert(owner.writeCalls, 0)
    @Assert(owner.text(), "Ae\u{0301}B")
}

@Test
func testPlainIntentBoundaryRefusals(): Unit {
    let owner = FakeTextOwner("ab")
    let session = makeSession(owner)
    session.setSelection16(0, 0)
    let back = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(back.handled, false)
    @Assert(back.reason, "at_document_start")
    let left = session.handlePlainIntent(CjguiTextPlainIntent.MoveLeft)
    @Assert(left.reason, "at_document_start")
    session.setSelection16(2, 2)
    let fwd = session.handlePlainIntent(CjguiTextPlainIntent.DeleteForward)
    @Assert(fwd.reason, "at_document_end")
    let right = session.handlePlainIntent(CjguiTextPlainIntent.MoveRight)
    @Assert(right.reason, "at_document_end")
    @Assert(owner.writeCalls, 0)
}

@Test
func testPlainIntentSelectionCollapseBeforeMove(): Unit {
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    session.setSelection16(1, 3)
    let left = session.handlePlainIntent(CjguiTextPlainIntent.MoveLeft)
    @Assert(left.handled, true)
    @Assert(left.wroteOwner, false)
    @Assert(left.selectionStart16, 1)     // 非空选区先折叠到左端
    confirmPlainSelectionPush(session)
    let selBack = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(selBack.handled, true)
    @Assert(selBack.wroteOwner, true)
    @Assert(owner.text(), "bcd")   // 折叠到左端后 Backspace 删 caret 前的 'a'
}

// ---- 指导复核反例（editor-macos-position-session-next 2026-09-29 深夜复审） ----

@Test
func testPlainIntentSelectionDeleteRejectsInteriorEndpoint(): Unit {
    // 反例 1：Ae\u{0301}B 的 UTF-16 选区 [2,3)（重音符半簇）——此前 hi>lo 直接
    // 提交会只删组合符。共同处理器必须先证明两端边界，内部端点具名零写入并
    // 保持原选区。
    let owner = FakeTextOwner("Ae\u{0301}B")
    let session = makeSession(owner)
    session.setSelection16(2, 3)
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(del.handled, false)
    @Assert(del.reason, "selection_endpoint_inside_grapheme")
    @Assert(owner.writeCalls, 0)
    @Assert(owner.text(), "Ae\u{0301}B")
    let (a, b) = session.selection16()
    @Assert(a, 2)
    @Assert(b, 3)
}

@Test
func testPlainIntentSelectionDeleteWholeClusterOnce(): Unit {
    // 正控：合法整簇选区 [1,3)（完整 e+重音簇）一笔精确删除。
    let owner = FakeTextOwner("Ae\u{0301}B")
    let session = makeSession(owner)
    session.setSelection16(1, 3)
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    @Assert(del.handled, true)
    @Assert(del.wroteOwner, true)
    @Assert(owner.text(), "AB")
    @Assert(owner.writeCalls, 1)
}

@Test
func testPlainIntentReverseShiftCollapsesNotExpands(): Unit {
    // 反例 2：abcd caret 2 → Shift+Left [1,2)（anchor=2 focus=1）→ Shift+Right
    // 应回 [2,2)（收缩），不是 [1,3)（扩张）。
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    session.setSelection16(2, 2)
    let extendLeft = session.handlePlainIntent(CjguiTextPlainIntent.ExtendLeft)
    @Assert(extendLeft.handled, true)
    @Assert(extendLeft.selectionStart16, 1)
    @Assert(extendLeft.selectionEnd16, 2)
    confirmPlainSelectionPush(session)
    let extendRight = session.handlePlainIntent(CjguiTextPlainIntent.ExtendRight)
    @Assert(extendRight.handled, true)
    @Assert(extendRight.selectionStart16, 2)
    @Assert(extendRight.selectionEnd16, 2)
    // 连续反向再扩张仍然正确：anchor=2 保持，focus 回到 3 → [2,3)。
    confirmPlainSelectionPush(session)
    let again = session.handlePlainIntent(CjguiTextPlainIntent.ExtendRight)
    @Assert(again.selectionStart16, 2)
    @Assert(again.selectionEnd16, 3)
    @Assert(owner.writeCalls, 0)
}

@Test
func testPlainIntentDocumentBoundaryKeepsDirectedAnchorAndZeroOwnerWrites(): Unit {
    let owner = FakeTextOwner("A中😀B")
    let session = makeSession(owner)
    session.setSelection16(2, 2)
    let start = session.handlePlainIntent(CjguiTextPlainIntent.MoveDocumentStart)
    @Assert(start.handled, true)
    @Assert(start.selectionStart16, 0)
    @Assert(start.selectionEnd16, 0)
    confirmPlainSelectionPush(session)
    session.setSelection16(2, 2)
    let extendedSelection = session.handlePlainIntent(CjguiTextPlainIntent.ExtendDocumentEnd)
    @Assert(extendedSelection.handled, true)
    @Assert(extendedSelection.selectionStart16, 2)
    @Assert(extendedSelection.selectionEnd16, 5)
    confirmPlainSelectionPush(session)
    let reverse = session.handlePlainIntent(CjguiTextPlainIntent.ExtendDocumentStart)
    @Assert(reverse.selectionStart16, 0)
    @Assert(reverse.selectionEnd16, 2)
    confirmPlainSelectionPush(session)
    let end = session.handlePlainIntent(CjguiTextPlainIntent.MoveDocumentEnd)
    @Assert(end.selectionStart16, 5)
    @Assert(end.selectionEnd16, 5)
    @Assert(owner.text(), "A中😀B")
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
}


@Test
func testPlainIntentDocumentBoundaryRejectsPartialMirror(): Unit {
    let owner = FakeTextOwner("0123456789abcdefghijklmnopqrstuv")
    let session = makeSession(owner, materializeLimit: 8)
    let _ = session.revealByte(12)
    let mirror = session.mirrorSnapshot()
    @Assert(mirror.startByte > 0, true)
    @Assert(mirror.startByte + Int64(mirror.text.toArray().size) < owner.data.size, true)
    session.setSelection16(1, 1)
    let start = session.handlePlainIntent(CjguiTextPlainIntent.MoveDocumentStart)
    @Assert(start.handled, false)
    @Assert(start.reason, "at_window_start")
    let end = session.handlePlainIntent(CjguiTextPlainIntent.ExtendDocumentEnd)
    @Assert(end.handled, false)
    @Assert(end.reason, "at_window_end")
    let (a, b) = session.selection16()
    @Assert(a, 1)
    @Assert(b, 1)
    @Assert(owner.text(), "0123456789abcdefghijklmnopqrstuv")
    @Assert(owner.ver, 1)
    @Assert(owner.writeCalls, 0)
}

@Test
func testPlainIntentSelectionCollapseAtDocumentEdges(): Unit {
    // 反例 3：abcd 选 [0,2) 在文首按 Left、选 [1,4) 在文尾按 Right——都必须先
    // 折叠成功（零事务），不因贴边被拒。
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    session.setSelection16(0, 2)
    let left = session.handlePlainIntent(CjguiTextPlainIntent.MoveLeft)
    @Assert(left.handled, true)
    @Assert(left.selectionStart16, 0)
    @Assert(left.selectionEnd16, 0)
    confirmPlainSelectionPush(session)
    session.setSelection16(1, 4)
    let right = session.handlePlainIntent(CjguiTextPlainIntent.MoveRight)
    @Assert(right.handled, true)
    @Assert(right.selectionStart16, 4)
    @Assert(right.selectionEnd16, 4)
    @Assert(owner.writeCalls, 0)
}

@Test
func testPlainIntentCounterClassificationConservation(): Unit {
    // 三类守恒（指导复核反例 4）：每个普通意图恰归一类——正文接受/零写入选区/
    // 具名拒绝。此处在会话层校验行为分类，窗口层守恒由真实消费脚本核对。
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    var accepted: Int64 = 0
    var zeroWrite: Int64 = 0
    var refused: Int64 = 0
    session.setSelection16(1, 1)
    var i: Int64 = 0
    while (i < 3) {
        let move = session.handlePlainIntent(CjguiTextPlainIntent.MoveRight)
        if (move.handled && !move.wroteOwner) { zeroWrite += 1 } else if (move.wroteOwner) { accepted += 1 } else { refused += 1 }
        confirmPlainSelectionPush(session)
        i += 1
    }
    let edge = session.handlePlainIntent(CjguiTextPlainIntent.MoveRight)
    if (edge.handled && !edge.wroteOwner) { zeroWrite += 1 } else if (edge.wroteOwner) { accepted += 1 } else { refused += 1 }
    confirmPlainSelectionPush(session)
    let del = session.handlePlainIntent(CjguiTextPlainIntent.DeleteBackward)
    if (del.wroteOwner) { accepted += 1 } else if (del.handled) { zeroWrite += 1 } else { refused += 1 }
    @Assert(accepted, 1)     // 一次删除恰好一笔正文事务
    @Assert(zeroWrite, 3)    // 三次移动
    @Assert(refused, 1)      // 文尾拒绝一次
    @Assert(owner.writeCalls, 1)
}


// Semantic selection tickets are independent of text versions and values.
@Test
func testSelectionRebasePublishesCollapsedDirectedEndpoints(): Unit {
    let owner = FakeTextOwner("Uabcd")
    let session = makeSession(owner)
    session.setSelection16(3, 3)
    let ticket = session.freezeSelectionTicket()
    owner.externalWrite(0, 1, "")
    @Assert(session.refreshMirror(), true)
    @Assert(session.selectionTicketMatches(ticket), false)
    @Assert(session.selection16()[0], 2)
    @Assert(session.selection16()[1], 2)
    @Assert(session.plainSelectionAnchorValue(), 2)
    @Assert(session.plainSelectionFocusValue(), 2)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.confirmNativeSelectionRestored(2, 2, 2), true)
    @Assert(owner.writeCalls, 0)
}

@Test
func testPreparedHumanReplacementAndInsertionPublishNewCaret(): Unit {
    let owner = FakeTextOwner("A中B文C")
    let session = makeSession(owner)
    session.setSelection16(1, 2)
    let old = session.freezeSelectionTicket()
    let replacement = session.prepareSourceRange(1, 1, 4).getOrThrow().replace("换")
    @Assert(replacement.accepted, true)
    @Assert(owner.text(), "A换B文C")
    @Assert(session.selectionTicketMatches(old), false)
    @Assert(session.selection16()[0], 2)
    @Assert(session.selection16()[1], 2)
    @Assert(session.plainSelectionAnchorValue(), 2)
    @Assert(session.plainSelectionFocusValue(), 2)
    @Assert(session.selectedSourceRange().isNone(), true)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()[1], 4)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.confirmNativeSelectionRestored(2, 2, 2), true)
    let insertion = session.prepareSourceRange(2, 4, 4).getOrThrow().replace("视")
    @Assert(insertion.accepted, true)
    @Assert(owner.text(), "A换视B文C")
    @Assert(session.selection16()[0], 3)
    @Assert(session.selection16()[1], 3)
    @Assert(session.plainSelectionAnchorValue(), 3)
    @Assert(session.plainSelectionFocusValue(), 3)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()[1], 7)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()[2], 7)
    @Assert(session.confirmNativeSelectionRestored(3, 3, 3), true)
    @Assert(owner.writeCalls, 2)
}

@Test
func testPreparedHumanReplacementCollapsesReverseSourceSelection(): Unit {
    let owner = FakeTextOwner("A中B文C")
    let session = makeSession(owner)
    let old = session.freezeSelectionTicket()
    @Assert(session.commitSelectionTicket(old, 4, 1, { => true }), true)
    let reverse = session.freezeSelectionTicket()
    let replacement = session.prepareSourceRange(1, 1, 8).getOrThrow().replace("中文")
    @Assert(replacement.accepted, true)
    @Assert(owner.text(), "A中文C")
    @Assert(session.selectionTicketMatches(reverse), false)
    @Assert(session.selection16()[0], 3)
    @Assert(session.selection16()[1], 3)
    @Assert(session.plainSelectionAnchorValue(), 3)
    @Assert(session.plainSelectionFocusValue(), 3)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()[1], 7)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).getOrThrow()[2], 7)
    @Assert(session.confirmNativeSelectionRestored(2, 3, 3), true)
    @Assert(owner.writeCalls, 1)
}

@Test
func testSelectionRebasePreservesReverseDirection(): Unit {
    let owner = FakeTextOwner("Uabcd")
    let session = makeSession(owner)
    let ticket = session.freezeSelectionTicket()
    @Assert(session.commitSelectionTicket(ticket, 4, 2, { => true }), true)
    owner.externalWrite(0, 1, "")
    @Assert(session.refreshMirror(), true)
    @Assert(session.selection16()[0], 1)
    @Assert(session.selection16()[1], 3)
    @Assert(session.plainSelectionAnchorValue(), 3)
    @Assert(session.plainSelectionFocusValue(), 1)
    @Assert(session.confirmNativeSelectionRestored(2, 1, 3), true)
    @Assert(owner.writeCalls, 0)
}

@Test
func testSelectionTicketSameValueABARejectsOldChoice(): Unit {
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    session.setSelection16(2, 2)
    let old = session.freezeSelectionTicket()
    session.setSelection16(1, 1)
    session.setSelection16(2, 2)
    @Assert(session.selectionTicketMatches(old), false)
    @Assert(session.commitSelectionTicket(old, 3, 3, { => true }), false)
    @Assert(session.selection16()[0], 2)
    @Assert(session.selection16()[1], 2)
    @Assert(owner.writeCalls, 0)
}

@Test
func testSelectionTicketFailedInstallPublishesNothingAndRemainsUsable(): Unit {
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    session.setSelection16(2, 2)
    let ticket = session.freezeSelectionTicket()
    @Assert(session.commitSelectionTicket(ticket, 2, 1, { => false }), false)
    @Assert(session.selection16()[0], 2)
    @Assert(session.selection16()[1], 2)
    @Assert(session.plainSelectionAnchorValue(), 2)
    @Assert(session.plainSelectionFocusValue(), 2)
    @Assert(session.selectionTicketMatches(ticket), true)
    @Assert(session.commitSelectionTicket(ticket, 2, 1, { => true }), true)
    @Assert(session.selection16()[0], 1)
    @Assert(session.selection16()[1], 2)
    @Assert(session.plainSelectionAnchorValue(), 2)
    @Assert(session.plainSelectionFocusValue(), 1)
    @Assert(session.selectionTicketMatches(ticket), false)
    @Assert(owner.writeCalls, 0)
}

@Test
func testSelectionTicketInvalidSourceMappingRejectsBeforeInstall(): Unit {
    let owner = FakeTextOwner("中🙂x")
    let session = makeSession(owner)
    session.setSelection16(0, 0)
    let ticket = session.freezeSelectionTicket()
    @Assert(session.commitSelectionTicket(ticket, 2, 2, { =>
        owner.bumpVersionOnly()
        return true
    }), false)
    @Assert(owner.ver, 1) // invalid surrogate mapping never invokes install
    @Assert(session.selection16()[0], 0)
    @Assert(session.selection16()[1], 0)
}

@Test
func testSelectionTicketOwnerVersionChangeRejectsBeforeInstall(): Unit {
    let owner = FakeTextOwner("abcd")
    let session = makeSession(owner)
    let ticket = session.freezeSelectionTicket()
    owner.bumpVersionOnly()
    @Assert(session.commitSelectionTicket(ticket, 1, 1, { =>
        owner.bumpVersionOnly()
        return true
    }), false)
    @Assert(owner.ver, 2)
    @Assert(owner.writeCalls, 0)
}

@Test
func testAcceptedCaretSurvivesUnavailableReadUntilRestoreConfirmation(): Unit {
    let owner = FakeTextOwner("A中B文C")
    let session = makeSession(owner)
    session.setSelection16(1, 2)
    let oldTicket = session.freezeSelectionTicket()
    owner.refuseReadsAfterNextAccept = true
    let edit = session.prepareSourceRange(1, 1, 4).getOrThrow().replace("视续")

    @Assert(edit.accepted, true)
    @Assert(owner.text(), "A视续B文C")
    @Assert(session.selectionTicketMatches(oldTicket), false)
    @Assert(session.selectedSourceRange().isNone(), true)
    @Assert(session.awaitingCalibration(), true)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).isNone(), true)
    @Assert(session.acknowledge(edit.ticket, session.contextEpochValue()), true)
    @Assert(session.pendingCount(), 0)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).isNone(), true)

    @Assert(session.recalibrate(), false)
    owner.readsUnavailable = false
    @Assert(session.recalibrate(), true)
    @Assert(session.selection16()[0], 3)
    @Assert(session.selection16()[1], 3)
    @Assert(session.needsNativeSelectionRestore(), true)
    let (receiptEpoch, receiptMirror) = session.restorationReceipt()
    @Assert(session.confirmProxyRestored(receiptEpoch, receiptMirror,
        selectionStart16: 1, selectionEnd16: 1), false)
    @Assert(session.awaitingCalibration(), true)
    @Assert(session.confirmProxyRestored(receiptEpoch, receiptMirror,
        selectionStart16: 3, selectionEnd16: 3), true)
    @Assert(session.awaitingCalibration(), false)
    let restored = session.selectedSourceRange().getOrThrow()
    @Assert(restored[0], 2)
    @Assert(restored[1], 7)
    @Assert(restored[2], 7)
    @Assert(owner.writeCalls, 1)
}

@Test
func testAcceptedCaretRebasesAcrossExternalWriteWhileReadsUnavailable(): Unit {
    let owner = FakeTextOwner("A中B文C")
    let session = makeSession(owner)
    session.setSelection16(1, 2)
    owner.refuseReadsAfterNextAccept = true
    let edit = session.prepareSourceRange(1, 1, 4).getOrThrow().replace("视续")

    @Assert(edit.accepted, true)
    @Assert(session.acknowledge(edit.ticket, session.contextEpochValue()), true)
    @Assert(session.pendingCount(), 0)
    @Assert(session.awaitingCalibration(), true)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).isNone(), true)

    owner.externalWrite(0, 0, "【A】")
    @Assert(owner.text(), "【A】A视续B文C")
    @Assert(session.recalibrate(), false)
    @Assert(owner.text(), "【A】A视续B文C")
    @Assert(session.awaitingCalibration(), true)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.sourceRangeForSelectionTicket(session.freezeSelectionTicket()).isNone(), true)

    owner.readsUnavailable = false
    @Assert(session.recalibrate(), true)
    @Assert(session.selection16()[0], 6)
    @Assert(session.selection16()[1], 6)
    @Assert(session.needsNativeSelectionRestore(), true)
    let (receiptEpoch, receiptMirror) = session.restorationReceipt()
    @Assert(session.confirmProxyRestored(receiptEpoch, receiptMirror,
        selectionStart16: 6, selectionEnd16: 6), true)
    @Assert(session.awaitingCalibration(), false)
    let restored = session.selectedSourceRange().getOrThrow()
    @Assert(restored[0], 3)
    @Assert(restored[1], 14)
    @Assert(restored[2], 14)
    @Assert(owner.writeCalls, 1)
}

@Test
func installedSelectionSourceSnapshotRequiresCurrentOwnerAckedChain(): Unit {
    let owner = FakeTextOwner("ABCDE")
    let session = makeSession(owner)
    let basis = session.freezeInstalledRangeBasis(91u64, 7u64, 3u64).getOrThrow()
    @Assert(session.activateInstalledRangeBasis(basis, 5u64), true)
    let frozen = session.freezeInstalledSelectionSource(7u64, 3u64).getOrThrow()
    @Assert(frozen.basis.nonce, 91u64)
    @Assert(frozen.acceptedSequence, 0u64)
    @Assert(frozen.acceptedVersion, basis.ownerVersion)
    @Assert(frozen.sourceStart, basis.sourceStart)
    @Assert(frozen.sourceEnd, basis.sourceEnd)
    @Assert(frozen.proxyGeneration, 5u64)
    @Assert(frozen.body, "ABCDE")

    owner.bumpVersionOnly()
    @Assert(session.freezeInstalledSelectionSource(7u64, 3u64).isNone(), true)
    @Assert(session.freezeInstalledSelectionSource(8u64, 3u64).isNone(), true)
}

// Native ACK settlement can be retried after the owner has accepted. The
// duplicate confirmation names the same complete FIFO identity and must stay
// successful without submitting the owner edit a second time.
@Test
func crossFragmentAcceptedInputConfirmationIsIdempotentForSameIdentity(): Unit {
    let owner = FakeTextOwner("abcdeFGHIJ")
    let session = makeSession(owner, materializeLimit: 10)
    let choiceCurrent = true
    let first = session.submitAuthorizedSelectionRange(88u64, 4u64, 1u64, 0u64,
        1, 31, 3, 7, "X", { => choiceCurrent })
    @Assert(first.accepted, true)
    @Assert(owner.text(), "abcXHIJ")
    @Assert(owner.writeCalls, 1)
    @Assert(session.acknowledge(first.ticket, first.contextEpoch), true)

    @Assert(session.hasAuthorizedSelectionInputMemo(88u64, 4u64), true)
    @Assert(session.acknowledgeAuthorizedSelectionInput(88u64, 4u64), true)
    @Assert(session.hasAuthorizedSelectionInputMemo(88u64, 4u64), false)
    @Assert(session.acknowledgeAuthorizedSelectionInput(88u64, 4u64), true)
    @Assert(owner.text(), "abcXHIJ")
    @Assert(owner.writeCalls, 1)
}
