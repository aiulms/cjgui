// B4/1b(2026-09-27, Astra 方案 R): 框架内部文本会话。
//
// 在既有 CjguiRangeTextSource/CjguiRangeTextEditSink/CjguiRangeTextWindow 接缝之上,
// 为"呈现 TEXT 节点 + 可编辑语义"提供一条唯一的平台输入写入路径:会话身份与上下文
// 代次、有界驻留镜像、明确的 UTF-16 范围单位、编辑序号与串行 ACK/拒绝校准、组合
// (marked)状态。
//
// 契约边界(架构 §6.2):会话不认识产品私有类型;owner 写入只经 Sink;拒绝回执按
// 会话上下文归还,不校准别的会话;纯选区变化不推进内容版本;范围换算只发生在已准备
// 的有界镜像上,不整篇读取。
package cjgui

import std.collection.ArrayList

/// 一次会话编辑的判决结果。`contextEpoch` + `ticket` 一起构成回执身份:代次不同的
/// 回执不得校准任何当前状态(重绑后 nodeId 可能被复用,身份由代次区分)。
public class CjguiTextSessionEdit {
    /// 已接受事务的序号;被拒的提交不推进它。
    public let seq: Int64
    /// 本次提交在串行队列上的票据号:每笔提交(含被拒的)都有唯一票据,回执据此
    /// 指认被结算的是哪一笔。-1 表示该判决没有提交正文。
    public let ticket: Int64
    public let accepted: Bool
    public let versionAfter: Int64
    /// 本次判决完成后的镜像修订:接受会重读镜像所以推进,拒绝不动。
    public let mirrorRevision: Int64
    public let contextEpoch: Int64
    public let reason: String

    init(seq: Int64, ticket: Int64, accepted: Bool, versionAfter: Int64, mirrorRevision: Int64,
        contextEpoch: Int64, reason: String) {
        this.seq = seq
        this.ticket = ticket
        this.accepted = accepted
        this.versionAfter = versionAfter
        this.mirrorRevision = mirrorRevision
        this.contextEpoch = contextEpoch
        this.reason = reason
    }
}

/// A single-use source-byte intent prepared against one bounded session mirror.
/// The submission closure is owned by the issuing session, so a consumer cannot
/// pass this credential to a different window or invent a second Sink.
public class CjguiPreparedSourceRange {
    public let contentVersion: Int64
    public let startByte: Int64
    public let endByte: Int64
    public let contextEpoch: Int64
    public let mirrorRevision: Int64
    private let submitter: (String, Bool) -> CjguiTextSessionEdit
    private var consumed: Bool = false

    init(contentVersion: Int64, startByte: Int64, endByte: Int64, contextEpoch: Int64,
        mirrorRevision: Int64, submitter: (String, Bool) -> CjguiTextSessionEdit) {
        this.contentVersion = contentVersion
        this.startByte = startByte
        this.endByte = endByte
        this.contextEpoch = contextEpoch
        this.mirrorRevision = mirrorRevision
        this.submitter = submitter
    }

    /// `sourceProxyChanged` describes this session's SOURCE native proxy. A
    /// visual fragment is a separate native target recovered by the window;
    /// its edit does not mutate the source proxy before the Sink responds.
    public func replace(text: String, sourceProxyChanged!: Bool = false): CjguiTextSessionEdit {
        if (this.consumed) {
            return CjguiTextSessionEdit(-1, -1, false, this.contentVersion,
                this.mirrorRevision, this.contextEpoch, "prepared_range_consumed")
        }
        this.consumed = true
        return this.submitter(text, sourceProxyChanged)
    }
}

/// 已提交、尚未结算的编辑。串行 pending:后一笔的范围建立在前一笔的镜像之上,
/// 因此需要记录它依据的镜像修订,拒绝时才能判定从哪一处起需要重新校准。
class CjguiTextSessionPending {
    let ticket: Int64
    let baseMirrorRevision: Int64
    let edit: CjguiTextSessionEdit
    let sourceProxyChanged: Bool

    init(ticket: Int64, baseMirrorRevision: Int64, edit: CjguiTextSessionEdit,
        sourceProxyChanged!: Bool = true) {
        this.ticket = ticket
        this.baseMirrorRevision = baseMirrorRevision
        this.edit = edit
        this.sourceProxyChanged = sourceProxyChanged
    }
}

/// A single-read view of the text session's bounded mirror and its owner metadata.
/// Consumers should use this instead of keeping a second range-window projection
/// whose text and version could be observed at different times.
public class CjguiTextSessionMirrorSnapshot {
    public let contextEpoch: Int64
    public let mirrorRevision: Int64
    public let contentVersion: Int64
    public let sourceVersion: Int64
    public let startByte: Int64
    public let sourceByteLength: Int64
    public let text: String
    public let prepared: Bool
    public let complete: Bool
    public let pendingReason: String

    init(contextEpoch: Int64, mirrorRevision: Int64, contentVersion: Int64, sourceVersion: Int64,
        startByte: Int64, sourceByteLength: Int64,
        text: String, prepared: Bool, complete: Bool, pendingReason: String) {
        this.contextEpoch = contextEpoch
        this.mirrorRevision = mirrorRevision
        this.contentVersion = contentVersion
        this.sourceVersion = sourceVersion
        this.startByte = startByte
        this.sourceByteLength = sourceByteLength
        this.text = text
        this.prepared = prepared
        this.complete = complete
        this.pendingReason = pendingReason
    }
}

/// 单个逻辑编辑表面的输入会话。同一正文的多个 fragment 共用一个会话;
/// 换绑(文档切换/节点销毁)即失效,旧绑定上的后续编辑与旧回执都具名拒绝。
public class CjguiTextSession {
    private let window: CjguiRangeTextWindow

    private var contextEpoch: Int64 = 0
    private var editSeq: Int64 = 0
    /// 提交票据:与会话对象的生存期一样单调,不随重绑归零,旧回执不可能撞号。
    private var ticketSeq: Int64 = 0
    /// 镜像修订:每次重新准备有界上下文都推进,编辑范围据此判定是否仍然适用。
    private var mirrorRevision: Int64 = 0
    private var mirrorUtf16Length: Int64 = 0

    private var selStart16: Int64 = 0
    private var selEnd16: Int64 = 0
    /// Absolute source-byte selection is the durable view anchor. UTF-16
    /// coordinates above are only its projection into the current mirror.
    private var selectionVersion: Int64 = -1
    private var selectionStartByte: Int64 = -1
    private var selectionEndByte: Int64 = -1
    private var selectionNeedsNativeRestore: Bool = false

    // ---- 组合(IME marked)状态 ----
    // 草稿只存会话,不写持久正文:每次组字更新写正文会污染撤销与协同状态(§6.2 契约 5)。
    private var compositionActive: Bool = false
    private var compositionDraft: String = ""
    /// 组合开始时的 owner 版本与镜像修订:期间 Agent/另一窗口改过正文即为基版本失效。
    private var compositionBaseVersion: Int64 = -1
    private var compositionBaseMirror: Int64 = -1
    /// 平台给出的原替换范围(setMarkedText 的 replacementRange);终点必须保留到提交,
    /// 不能塌回起点。markedText 在镜像中的位置与之分离记录。
    private var replacementStart16: Int64 = 0
    private var replacementLength16: Int64 = 0
    /// marked 文本在镜像中的范围,以及平台报告的、相对于传入 preedit 的内部选区。
    private var markedStart16: Int64 = 0
    private var markedLength16: Int64 = 0
    private var markedInnerAnchor16: Int64 = 0
    private var markedInnerFocus16: Int64 = 0
    /// 本次组合的平台身份(native 会话内单调)。终态用它去重:同一组合的重复提交
    /// 不是一笔新意图,也不能因为"没有活跃组合"就被当成异常而持锁。
    private var activeCompositionId: Int64 = -1
    /// 最近一次真正结束的组合身份(提交接受或取消)。仅用于终态去重。
    private var lastTerminalCompositionId: Int64 = -1

    private var pending: ArrayList<CjguiTextSessionPending> = ArrayList<CjguiTextSessionPending>()
    /// 会话是否绑定着一个可编辑表面。`invalidate` 之后窗口归消费方所有,旧回调
    /// 只能被具名拒绝,不能继续写正文。
    private var bound: Bool = false
    /// 有一笔编辑被 owner 拒绝(无论已结算还是仍在队列中)。平台代理已经落字,而
    /// accepted 正文没有:重新按 owner 现状准备镜像之前,不得继续把旧坐标交给正文。
    private var needsCalibration: Bool = false
    /// 本次上锁后是否已按 owner 现状重建过镜像。只有重建过,`restorationReceipt()` 才签发
    /// 身份;否则平台拿到的镜像修订描述的还是拒绝发生前的状态。
    private var calibrationRecalibrated: Bool = false

    /// 最近一次拒绝的具名原因(消费方读取用于 UI/日志;不阻塞后续编辑)。
    private var lastReason: String = ""

    /// 会话只拥有一个已准备的有界投影窗口;窗口是唯一的 owner 写入通道。
    public init(window: CjguiRangeTextWindow) {
        this.window = window
        this.mirrorUtf16Length = cjguiUtf16Length(window.text())
    }

    // ---- 会话身份与换绑 ----

    public func boundNode(): Int64 {
        return this.window.nodeId()
    }

    /// 当前上下文代次。重绑/解绑都推进。
    public func contextEpochValue(): Int64 {
        return this.contextEpoch
    }

    /// 会话是否仍绑定着一个可编辑表面。
    public func isBound(): Bool {
        return this.bound
    }

    public func currentEditSeq(): Int64 {
        return this.editSeq
    }

    public func mirrorRevisionValue(): Int64 {
        return this.mirrorRevision
    }

    public func lastRejectReason(): String {
        return this.lastReason
    }

    /// 绑定到一个已准备的窗口。`bind` 总是开启新的上下文代次:绘制节点号可以被
    /// 复用,旧上下文里的回执与组合回调不能跨代次校准新会话。绑定即准备自己的
    /// 有界上下文(不是整篇读取),之后镜像常驻。
    public func bind(): Unit {
        this.bound = true
        this.contextEpoch += 1
        this.editSeq = 0
        this.mirrorRevision += 1
        this.selStart16 = 0
        this.selEnd16 = 0
        this.lastReason = ""
        this.pending.clear()
        this.needsCalibration = false
        this.calibrationRecalibrated = false
        // 组合身份随上下文重建:新代次里的第一个同号组合不得被旧终态去重掉。
        this.lastTerminalCompositionId = -1
        this.clearComposition()
        this.window.refresh()
        this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
        this.selectionVersion = this.window.contentVersion()
        this.selectionStartByte = this.window.windowStartByte()
        this.selectionEndByte = this.selectionStartByte
        this.selectionNeedsNativeRestore = false
    }

    /// 解绑语义由 `bind` 推进代次 + 窗口归属变化实现:旧 nodeId 上的后续编辑与
    /// 旧回执都因代次不符而具名拒绝,组合草稿随上下文一起丢弃。
    public func invalidate(): Unit {
        this.bound = false
        this.contextEpoch += 1
        this.selStart16 = 0
        this.selEnd16 = 0
        this.selectionVersion = -1
        this.selectionStartByte = -1
        this.selectionEndByte = -1
        this.selectionNeedsNativeRestore = false
        this.lastReason = ""
        this.pending.clear()
        this.needsCalibration = false
        this.calibrationRecalibrated = false
        this.clearComposition()
    }

    // ---- 有界镜像 ----

    /// 已准备的有界镜像正文。消费方(或拥有会话的窗口)在声明场景时原样发布它,
    /// 投影与判决才同源:平台代理不会再拿到会话没见过的长度。
    public func mirrorText(): String {
        return this.window.text()
    }

    /// Atomically capture the session-owned bounded mirror and the metadata used
    /// to interpret its text. This is a projection snapshot, not document truth.
    public func mirrorSnapshot(): CjguiTextSessionMirrorSnapshot {
        return CjguiTextSessionMirrorSnapshot(
            this.contextEpoch,
            this.mirrorRevision,
            this.window.contentVersion(),
            this.window.sourceVersion(),
            this.window.windowStartByte(),
            this.window.sourceByteLength(),
            this.window.text(),
            this.window.isPrepared(),
            this.window.isComplete(),
            this.window.unpreparedReason())
    }

    /// 镜像覆盖的绝对文档字节范围;平台需要判断请求是否越出已准备上下文。
    public func coverageBytes(): (Int64, Int64) {
        let start = this.window.windowStartByte()
        return (start, start + Int64(this.window.text().toArray().size))
    }

    public func contentVersion(): Int64 {
        return this.window.contentVersion()
    }

    /// 重新准备有界上下文。返回镜像身份是否变化;变化即推进镜像修订,
    /// 使所有以旧修订表达的范围不再适用。
    /// 注意:本方法**不解除校准锁**。owner 报"已准备完整"只说明会话这一侧可读,
    /// 而锁要防的是平台代理与 accepted 正文分叉 —— 那只会在 native 按新镜像重新
    /// 绑定/投影之后消失。解除必须走 `confirmProxyRestored`。
    public func refreshMirror(): Bool {
        let wasVersion = this.window.contentVersion()
        var rebased: ?(Int64, Int64, Int64) = None
        let externalChange = this.window.sourceVersion() != wasVersion
        if (externalChange && this.selectionVersion == wasVersion &&
            this.selectionStartByte >= 0 && !this.compositionActive) {
            rebased = this.window.rebaseSelection(wasVersion, this.selectionStartByte,
                this.selectionEndByte)
        }
        let changed = this.window.refresh()
        if (changed) {
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
        }
        if (externalChange) {
            if (let Some(mapped) <- rebased) {
                if (mapped[0] == this.window.contentVersion() &&
                    this.projectSourceSelection(mapped[1], mapped[2])) {
                    this.selectionVersion = mapped[0]
                    this.selectionStartByte = mapped[1]
                    this.selectionEndByte = mapped[2]
                    this.selectionNeedsNativeRestore = true
                } else {
                    this.invalidateSourceSelection("selection_projection_unavailable")
                }
            } else {
                this.invalidateSourceSelection("selection_rebase_unavailable")
            }
        }
        return changed
    }

    private func invalidateSourceSelection(reason: String): Unit {
        this.selectionVersion = -1
        this.selectionStartByte = -1
        this.selectionEndByte = -1
        this.selectionNeedsNativeRestore = false
        this.lastReason = reason
    }

    private func projectSourceSelection(startByte: Int64, endByte: Int64): Bool {
        var start = this.window.windowStartByte()
        var coverEnd = start + cjguiUtf8Length(this.window.text())
        if (startByte < start || endByte > coverEnd) {
            let moved = this.window.revealByte(startByte)
            if (moved) {
                this.mirrorRevision += 1
                this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            }
            start = this.window.windowStartByte()
            coverEnd = start + cjguiUtf8Length(this.window.text())
        }
        if (!this.window.isPrepared() || startByte < start || endByte > coverEnd) {
            return false
        }
        let localStart = cjguiUtf8OffsetToUtf16(this.window.text(), startByte - start)
        let localEnd = cjguiUtf8OffsetToUtf16(this.window.text(), endByte - start)
        if (let Some(a) <- localStart) {
            if (let Some(b) <- localEnd) {
                this.selStart16 = a
                this.selEnd16 = b
                return true
            }
        }
        return false
    }

    public func needsNativeSelectionRestore(): Bool {
        return this.selectionNeedsNativeRestore
    }

    public func confirmNativeSelectionRestored(version: Int64, start16: Int64, end16: Int64): Bool {
        if (!this.selectionNeedsNativeRestore || version != this.selectionVersion ||
            version != this.window.contentVersion() || start16 != this.selStart16 ||
            end16 != this.selEnd16) {
            return false
        }
        if (!this.window.confirmContentVersion({ =>
            this.selectionNeedsNativeRestore = false
            this.lastReason = ""
            return true
        })) {
            this.lastReason = "selection_restore_source_stale"
            return false
        }
        return true
    }

    /// 是否仍在等待一次带完整身份的 native 恢复回执。为 true 时任何正文写入都被具名拒绝。
    public func awaitingCalibration(): Bool {
        return this.needsCalibration
    }

    /// 平台侧开始恢复输入代理时取走的**回执身份**,恢复完成后必须原样交回
    /// `confirmProxyRestored`。未上锁、或上锁后还没 `recalibrate()` 时返回 (-1, -1)。
    ///
    /// 与"消费方读当前 epoch/mirror 再自己确认"的差别在于时间:这张回执要跨越平台
    /// 实际做恢复的那些回合。期间 owner 又写了正文(镜像换代)或会话换绑(代次推进),
    /// 旧回执就解不开新锁 —— 那正是"代理已落字、accepted 正文没变"的分叉形状。
    ///
    /// 校准前不签发:此刻镜像描述的还是拒绝发生时的旧状态,平台照着它"确认恢复"
    /// 等于自签自认,锁会在没人核对 owner 现状的情况下被解开。
    public func restorationReceipt(): (Int64, Int64) {
        if (!this.needsCalibration || !this.calibrationRecalibrated) {
            return (-1, -1)
        }
        return (this.contextEpoch, this.mirrorRevision)
    }

    /// 解除校准锁的**唯一**入口:平台在取到新镜像、重新投影并恢复输入代理(含选区)之后,
    /// 带它实际恢复到的上下文代次与镜像修订回来。身份不符即维持锁并具名报告 ——
    /// 用旧世代的恢复回执解开新世代的锁,正是原来"落字但正文没变"的那个形状。
    public func confirmProxyRestored(contextEpoch: Int64, mirrorRevision: Int64,
        selectionStart16!: Int64 = -1, selectionEnd16!: Int64 = -1): Bool {
        if (!this.needsCalibration) {
            return true
        }
        if (contextEpoch != this.contextEpoch || mirrorRevision != this.mirrorRevision) {
            this.lastReason = "restore_receipt_mismatch"
            return false
        }
        if (!this.window.isPrepared()) {
            this.lastReason = this.window.unpreparedReason()
            return false
        }
        if (!this.window.confirmContentVersion({ =>
            // Source runs this tiny state change in the same boundary as its
            // owner-version check. Native work and mirror reads are outside it.
            this.needsCalibration = false
            this.calibrationRecalibrated = false
            // The platform has installed this exact mirror and its actual
            // selection. The native result, when available, is authoritative;
            // direct pure-session consumers keep their explicit local range.
            if (selectionStart16 >= 0 && selectionEnd16 >= selectionStart16) {
                this.setSelection16(selectionStart16, selectionEnd16)
            } else {
                this.setSelection16(this.selStart16, this.selEnd16)
            }
            this.selectionNeedsNativeRestore = false
            this.lastReason = ""
            return true
        })) {
            this.lastReason = "restore_source_stale"
            return false
        }
        return true
    }

    /// owner 尚未准备好的范围不得当作空文本编辑。
    public func mirrorIsReady(): Bool {
        return this.window.isPrepared()
    }

    /// 把有界上下文移动到覆盖某个绝对文档字节位置。缺页由消费方(平台 adapter)按
    /// 准备契约显式发起,会话不在编辑路径里偷偷整篇读取。
    public func revealByte(anchorByte: Int64): Bool {
        let moved = this.window.revealByte(anchorByte)
        if (moved) {
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
        }
        return moved
    }

    public func unpreparedReason(): String {
        return this.window.unpreparedReason()
    }

    // ---- 选区 ----

    /// 纯选区变化(平台选区导航/鼠标):只推进视图状态,不产生事务、不推进内容版本。
    public func setSelection16(start16: Int64, end16: Int64): Unit {
        let lo = if (start16 <= end16) { start16 } else { end16 }
        let hi = if (start16 <= end16) { end16 } else { start16 }
        this.selStart16 = this.clamp16(lo)
        this.selEnd16 = if (hi < 0) { 0 } else { if (hi > this.mirrorUtf16Length) { this.mirrorUtf16Length } else { hi } }
        let sourceRange = this.window.documentRangeForUtf16(this.selStart16,
            this.selEnd16 - this.selStart16)
        if (let Some(bytes) <- sourceRange) {
            this.selectionVersion = this.window.contentVersion()
            this.selectionStartByte = bytes[0]
            this.selectionEndByte = bytes[1]
        } else {
            this.invalidateSourceSelection("selection_not_utf8_boundary")
        }
    }

    private func clamp16(value: Int64): Int64 {
        var out = value
        if (out < 0) {
            out = 0
        }
        if (out > this.mirrorUtf16Length) {
            out = this.mirrorUtf16Length
        }
        return out
    }

    public func selection16(): (Int64, Int64) {
        return (this.selStart16, this.selEnd16)
    }

    // ---- 组合(IME marked) ----

    public func hasComposition(): Bool {
        return this.compositionActive
    }

    public func compositionText(): String {
        return this.compositionDraft
    }

    /// 组合基版本(开始组字时的 owner 内容版本);无组合时为 -1。
    public func compositionBaseVersionValue(): Int64 {
        return if (this.compositionActive) { this.compositionBaseVersion } else { -1 }
    }

    public func markedRange16(): (Int64, Int64) {
        return if (this.compositionActive) {
            (this.markedStart16, this.markedLength16)
        } else {
            (-1, 0)
        }
    }

    /// The original replacement span frozen when marked input began. The byte endpoints
    /// use the same prepared mirror conversion as submitRange16, including its absolute
    /// window start. They are observation only; a consumer must still submit through
    /// the session so version, context and owner acceptance are checked.
    public func compositionFrozenRange(): ?(Int64, Int64, Int64, Int64, Int64, Int64) {
        if (!this.compositionActive || !this.window.isPrepared()) {
            return None
        }
        if (let Some(bytes) <- this.window.documentRangeForUtf16(
            this.replacementStart16, this.replacementLength16)) {
            return Some((this.activeCompositionId, this.compositionBaseVersion,
                this.replacementStart16, this.replacementStart16 + this.replacementLength16,
                bytes[0], bytes[1]))
        }
        return None
    }

    /// 平台 marked 范围查询协议里的"无效范围"哨兵。
    public static let NS_NOT_FOUND: Int64 = -1

    /// 开始/更新组字。`replacementStart16`/`replacementLength16` 是平台显式给出的
    /// 替换范围(`CjguiTextSession.NS_NOT_FOUND` 表示协议定义的默认语义:替换当前
    /// 选区);`markedStart16` 是 preedit 在镜像中的落点;`innerAnchor16`/`innerFocus16`
    /// 相对传入的 preedit;`compositionId` 是平台为本次组字分配的编号(缺省 -1 表示
    /// 平台未提供,不做身份校验)。
    ///
    /// **首次**解析出的 owner 替换范围在组合开始时冻结,后续 marked 更新只更新
    /// preedit 与内部选区:真实平台的后续更新可能报"当前 marked 范围"(其起点与冻结
    /// 起点一致)或 NS_NOT_FOUND,但显式给出**不同起点**的范围表达的是另一个替换段,
    /// 映射不到 owner 的原始文本上,只能具名拒绝并由平台按新镜像重建组合。
    public func updateComposition(text: String, replacementStart16: Int64, replacementLength16: Int64,
        markedStart16: Int64, innerAnchor16: Int64, innerFocus16: Int64,
        compositionId!: Int64 = -1): CjguiTextSessionEdit {
        if (!this.bound) {
            this.lastReason = "session_unbound"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (replacementLength16 < 0 || markedStart16 < 0 || markedStart16 > this.mirrorUtf16Length) {
            return this.refuseCompositionIntent(CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW, true)
        }
        let startingComposition = !this.compositionActive
        let resolvedStart = if (replacementStart16 == CjguiTextSession.NS_NOT_FOUND) {
            this.selStart16
        } else {
            replacementStart16
        }
        let resolvedLength = if (replacementStart16 == CjguiTextSession.NS_NOT_FOUND) {
            this.selEnd16 - this.selStart16
        } else {
            replacementLength16
        }
        // 后续更新(重绘/候选变化)**不得重取基版本**:否则 Agent 在两次 marked 更新之间
        // 写入正文时,旧替换范围会被重新标成新基版本,提交时看似合法而它表达的是过时正文。
        // 基版本只在组合开始时冻结一次;期间 owner 推进就是具名拒绝,由平台重新组字。
        if (this.compositionActive && (this.window.sourceVersion() != this.compositionBaseVersion ||
                this.mirrorRevision != this.compositionBaseMirror)) {
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        if (this.compositionActive && compositionId >= 0 && compositionId != this.activeCompositionId) {
            // 更新自称属于另一个组合:两个组字不能共用一份草稿与冻结范围。
            return this.refuseCompositionIntent("composition_id_mismatch", true)
        }
        if (startingComposition) {
            if (resolvedStart < 0 || resolvedLength < 0 ||
                resolvedStart + resolvedLength > this.mirrorUtf16Length) {
                return this.refuseCompositionIntent(CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW, true)
            }
        } else if (resolvedStart != this.replacementStart16) {
            // 后续更新报告的是平台代理里的当前 marked 范围:起点与冻结起点一致(实测
            // shouldChangeText 报 0+2、0+3),长度是**旧 preedit 长度**,其终点可以超过
            // 镜像长度 —— preedit 只存在于代理显示,不在镜像里,因此不按镜像校验它。
            // 起点改变才表达另一个替换段,映射不到 owner 原始文本,只能具名拒绝。
            return this.refuseCompositionIntent("composition_range_changed", true)
        }
        let textLen16 = cjguiUtf16Length(text)
        if (innerAnchor16 < 0 || innerFocus16 < 0 || innerAnchor16 > textLen16 || innerFocus16 > textLen16) {
            // 内部选区相对**本次传入的 preedit**:越界说明平台报的锚点不对应这段
            // 文本,静默钳位会把用户光标搬到别处,因此具名拒绝并由平台重建组合。
            return this.refuseCompositionIntent("composition_inner_range_invalid", true)
        }
        this.compositionActive = true
        this.compositionDraft = text
        if (startingComposition) {
            // 基版本取 owner 的当前真值版本,不是镜像缓存版本:组合期间 Agent/另一窗口
            // 通过 Sink 写过正文,镜像版本号不变但 owner 已推进,只比镜像就漏判。
            this.compositionBaseVersion = this.window.sourceVersion()
            this.compositionBaseMirror = this.mirrorRevision
            this.replacementStart16 = resolvedStart
            this.replacementLength16 = resolvedLength
            this.activeCompositionId = compositionId
        }
        this.markedStart16 = markedStart16
        this.markedLength16 = cjguiUtf16Length(text)
        this.markedInnerAnchor16 = innerAnchor16
        this.markedInnerFocus16 = innerFocus16
        this.lastReason = ""
        return this.edit(this.editSeq, true, -1, "")
    }

    /// 提交组字:草稿一次性经唯一写入路径落为**单个**事务,替换的是组合开始时冻结的
    /// 原范围而非起点补插。只有 owner 接受后才清草稿 —— 拒绝时用户看到的 preedit
    /// 不能被吞掉。
    /// 不带参数是"未提供最终文本,提交当前草稿";`commitComposition(finalText: "")`
    /// 是"平台显式提交为空"(真实平台在提交路径上删除整段替换文本的合法终态)。
    /// 每个提交意图一票据一判决:预检拒绝(未绑定/无活跃组合/基版本失效)也从意图票据
    /// 序列取号并进入 pending,窗口按同一 `acknowledge` 结算;这些拒绝意味着平台代理
    /// 可能已落字而 owner 没有,因此除解绑外一律持校准锁,等待既有恢复回执。
    public func commitComposition(compositionId!: Int64 = -1): CjguiTextSessionEdit {
        return this.commitCompositionText(None, compositionId)
    }

    public func commitComposition(finalText!: String, compositionId!: Int64 = -1): CjguiTextSessionEdit {
        return this.commitCompositionText(Some(finalText), compositionId)
    }

    private func commitCompositionText(finalText: ?String, compositionId: Int64): CjguiTextSessionEdit {
        if (!this.bound) {
            // 会话已解绑:旧平台回调不写正文,也不持锁(代次已推进,锁本身无意义)。
            return this.refuseCompositionIntent("session_unbound", false)
        }
        if (!this.compositionActive) {
            if (compositionId >= 0 && compositionId == this.lastTerminalCompositionId) {
                // 同一组合的重复终态:代理与 owner 没有新分叉,不持锁、不记账。
                this.lastReason = "composition_terminal_duplicate"
                return this.edit(this.editSeq, false, -1, this.lastReason)
            }
            return this.refuseCompositionIntent("composition_not_active", true)
        }
        if (compositionId >= 0 && this.activeCompositionId >= 0 &&
            compositionId != this.activeCompositionId) {
            // A delayed terminal from A must never consume B's frozen range.
            // It cannot describe B's proxy state, so leave B and its ticket
            // untouched for its own terminal phase.
            this.lastReason = if (compositionId == this.lastTerminalCompositionId) {
                "composition_terminal_duplicate"
            } else {
                "composition_id_mismatch"
            }
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (this.window.sourceVersion() != this.compositionBaseVersion ||
            this.mirrorRevision != this.compositionBaseMirror) {
            // Agent/另一窗口在组合期间改过基版本:旧回调不猜新坐标,具名拒绝并要
            // 求平台按新镜像重新组字。草稿保留,由用户决定重打还是放弃。
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        let committed = match (finalText) {
            case Some(value) => value
            case None => this.compositionDraft
        }
        let result = this.submitRange16(this.replacementStart16,
            this.replacementStart16 + this.replacementLength16, committed)
        if (result.accepted) {
            this.lastTerminalCompositionId = compositionId
            this.clearComposition()
            return result
        }
        if (result.ticket < 0) {
            // 提交前的具名拒绝(镜像未准备/越界/换算失败):owner 完全没被触碰,
            // 而平台侧提交已经发生,同样持锁等待恢复;原因沿用 submitRange16 写下的那个。
            return this.refuseCompositionIntent(result.reason, true)
        }
        return result
    }

    /// 取消组字:丢弃草稿,不产生任何事务(撤销 ≠ 取消;正文零变化)。
    /// `compositionId` 命中最近一次真正结束的组合时按重复终态处理(幂等)。
    public func cancelComposition(compositionId!: Int64 = -1): Unit {
        if (this.compositionActive) {
            if (compositionId >= 0 && this.activeCompositionId >= 0 &&
                compositionId != this.activeCompositionId) {
                this.lastReason = if (compositionId == this.lastTerminalCompositionId) {
                    "composition_terminal_duplicate"
                } else {
                    "composition_id_mismatch"
                }
                return
            }
            this.lastTerminalCompositionId = compositionId
            this.clearComposition()
            return
        }
        if (compositionId >= 0 && compositionId == this.lastTerminalCompositionId) {
            this.lastReason = "composition_terminal_duplicate"
        }
    }

    /// 组字路径上的具名拒绝:分配**意图票据**(与已提交事务同一序列,不从别处借号)、
    /// 进入 pending 等待 `acknowledge` 结算,并(除解绑外)持有校准锁 —— 平台代理
    /// 已落字而 owner 没有,继续按旧坐标写入就是静默改写。
    private func refuseCompositionIntent(reason: String, holdCalibration: Bool): CjguiTextSessionEdit {
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        this.lastReason = reason
        let refusal = this.edit(this.editSeq, false, -1, reason, ticket)
        this.pending.add(CjguiTextSessionPending(ticket, this.mirrorRevision, refusal))
        if (holdCalibration) {
            this.needsCalibration = true
            this.calibrationRecalibrated = false
        }
        return refusal
    }

    private func clearComposition(): Unit {
        this.compositionActive = false
        this.compositionDraft = ""
        this.compositionBaseVersion = -1
        this.compositionBaseMirror = -1
        this.replacementStart16 = 0
        this.replacementLength16 = 0
        this.markedStart16 = 0
        this.markedLength16 = 0
        this.markedInnerAnchor16 = 0
        this.markedInnerFocus16 = 0
        this.activeCompositionId = -1
    }

    /// 组字期间平台报告的 marked 内部选区(相对传入 preedit),供选区查询原样回答。
    public func markedInnerSelection16(): (Int64, Int64) {
        return if (this.compositionActive) {
            (this.markedInnerAnchor16, this.markedInnerFocus16)
        } else {
            (0, 0)
        }
    }

    // ---- 唯一的范围替换路径 ----

    /// 显式范围替换(镜像内 UTF-16 单位)。平台直接输入走这里,因此组字期间必须
    /// 让位给 marked 提交路径,不能同时存在第二个正文写入者。
    public func replaceRange16(start16: Int64, end16: Int64, text: String): CjguiTextSessionEdit {
        if (this.compositionActive) {
            this.lastReason = "composition_busy"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        return this.submitRange16(start16, end16, text)
    }

    /// Prepare an already-mapped absolute source span. Mapping display syntax
    /// remains with the application; the session proves one bounded mirror
    /// covers both UTF-8 endpoints at the requested owner version.
    public func prepareSourceRange(expectedVersion: Int64, startByte: Int64,
        endByte: Int64): ?CjguiPreparedSourceRange {
        if (!this.bound) {
            this.lastReason = "session_unbound"
            return None
        }
        if (this.needsCalibration || this.compositionActive) {
            this.lastReason = if (this.needsCalibration) { "recalibration_required" } else { "composition_busy" }
            return None
        }
        if (this.window.sourceVersion() != expectedVersion) {
            this.lastReason = CJGUI_RANGE_TEXT_REASON_VERSION
            return None
        }
        if (this.window.contentVersion() != expectedVersion) {
            let _ = this.refreshMirror()
        }
        if (this.window.contentVersion() != expectedVersion) {
            this.lastReason = CJGUI_RANGE_TEXT_REASON_VERSION
            return None
        }
        let priorStart = this.window.windowStartByte()
        let priorText = this.window.text()
        let reason = this.window.prepareByteRange(startByte, endByte)
        if (priorStart != this.window.windowStartByte() || priorText != this.window.text()) {
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
        }
        if (reason != "") {
            this.lastReason = reason
            return None
        }
        if (this.window.contentVersion() != expectedVersion ||
            this.window.sourceVersion() != expectedVersion) {
            this.lastReason = CJGUI_RANGE_TEXT_REASON_VERSION
            return None
        }
        let epoch = this.contextEpoch
        let mirror = this.mirrorRevision
        this.lastReason = ""
        return Some(CjguiPreparedSourceRange(expectedVersion, startByte, endByte, epoch, mirror,
            { text, sourceProxyChanged =>
                return this.submitPreparedSourceRange(epoch, mirror, expectedVersion,
                    startByte, endByte, text, sourceProxyChanged)
            }))
    }

    private func submitPreparedSourceRange(epoch: Int64, mirror: Int64, expectedVersion: Int64,
        startByte: Int64, endByte: Int64, text: String,
        sourceProxyChanged: Bool): CjguiTextSessionEdit {
        if (!this.bound || epoch != this.contextEpoch || mirror != this.mirrorRevision ||
            this.needsCalibration || this.compositionActive || !this.window.isPrepared()) {
            this.lastReason = "prepared_range_stale"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (this.window.contentVersion() != expectedVersion ||
            this.window.sourceVersion() != expectedVersion) {
            this.lastReason = CJGUI_RANGE_TEXT_REASON_VERSION
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        let outcome = this.window.applyByteEdit(startByte, endByte, text)
        if (outcome.applied) {
            this.editSeq += 1
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            if (this.selectionVersion >= 0 && this.selectionStartByte >= 0) {
                if (let Some(mapped) <- this.window.rebaseSelection(this.selectionVersion,
                    this.selectionStartByte, this.selectionEndByte)) {
                    if (mapped[0] == outcome.versionAfter &&
                        this.projectSourceSelection(mapped[1], mapped[2])) {
                        this.selectionVersion = mapped[0]
                        this.selectionStartByte = mapped[1]
                        this.selectionEndByte = mapped[2]
                        this.selectionNeedsNativeRestore = true
                    } else {
                        this.invalidateSourceSelection("selection_projection_unavailable")
                    }
                } else {
                    this.invalidateSourceSelection("selection_rebase_unavailable")
                }
            }
            this.lastReason = ""
            let accepted = this.edit(this.editSeq, true, outcome.versionAfter, "", ticket)
            this.pending.add(CjguiTextSessionPending(ticket, mirror, accepted,
                sourceProxyChanged: sourceProxyChanged))
            return accepted
        }
        this.lastReason = outcome.reason
        let rejected = this.edit(this.editSeq, false, outcome.versionAfter, outcome.reason, ticket)
        this.pending.add(CjguiTextSessionPending(ticket, mirror, rejected,
            sourceProxyChanged: sourceProxyChanged))
        if (sourceProxyChanged) {
            this.needsCalibration = true
            this.calibrationRecalibrated = false
        }
        return rejected
    }

    /// 会话内部的唯一写入路径:换算只发生在已准备的有界镜像上,得到绝对文档字节
    /// 范围后经窗口提交,owner 版本不符即冲突拒绝。
    /// 接受 ⇒ edit 序号推进、选区折叠到插入末尾;拒绝 ⇒ 序号/选区不动、具名原因,
    /// 并且要求先按 owner 现状重新校准才能继续输入。
    private func submitRange16(start16: Int64, end16: Int64, text: String): CjguiTextSessionEdit {
        if (!this.bound) {
            // 换绑/销毁后迟到的平台回调:坐标属于已经消失的表面,具名拒绝。
            this.lastReason = "session_unbound"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (this.needsCalibration) {
            // 上一笔被拒而镜像仍停在旧坐标:继续提交会把编辑写进一个已经不存在的位置。
            this.lastReason = "recalibration_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (this.selectionVersion != this.window.contentVersion() ||
            this.selectionStartByte < 0 || this.selectionNeedsNativeRestore) {
            // Native may still hold coordinates from the previous accepted
            // scene. Do not reinterpret those numbers against the new mirror.
            this.lastReason = "selection_native_alignment_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (!this.window.isPrepared()) {
            this.lastReason = this.window.unpreparedReason()
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        let lo = if (start16 <= end16) { start16 } else { end16 }
        let hi = if (start16 <= end16) { end16 } else { start16 }
        if (lo < 0) {
            this.lastReason = "negative_range"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (hi > this.mirrorUtf16Length) {
            // 超出已准备上下文:具名拒绝并请求按新镜像重新准备,不钳成其他有效位置。
            this.lastReason = CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        let baseMirror = this.mirrorRevision
        // 先在镜像里换算:换算失败是**提交前**的具名拒绝(owner 完全没被触碰),与
        // "owner 收到但拒绝"是两类事件 —— 只有后者让平台代理与 accepted 正文分叉。
        let (startByte, endByte) = match (this.window.documentRangeForUtf16(lo, hi - lo)) {
            case Some(r) => r
            case None => (-1, -1)
        }
        if (startByte < 0) {
            this.lastReason = CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        let outcome = this.window.applyByteEdit(startByte, endByte, text)
        if (outcome.applied) {
            this.editSeq += 1
            // Accepted text may extend beyond the old bounded slice. Resolve the
            // new caret in owner byte coordinates, then project it through the
            // newly materialised slice before exposing another input range.
            let caretByte = startByte + Int64(text.toArray().size)
            this.window.revealByte(caretByte)
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            let localCaretByte = caretByte - this.window.windowStartByte()
            let mappedCaret: ?Int64 = if (this.window.isPrepared() &&
                this.window.contentVersion() == outcome.versionAfter) {
                cjguiUtf8OffsetToUtf16(this.window.text(), localCaretByte)
            } else { None }
            if (let Some(caret16) <- mappedCaret) {
                this.setSelection16(caret16, caret16)
                this.lastReason = ""
            } else {
                // The owner transaction is already accepted. Keep its receipt,
                // but stop further input until the native proxy is recalibrated.
                this.needsCalibration = true
                this.calibrationRecalibrated = false
                this.lastReason = "accepted_caret_unprepared"
            }
            let result = this.edit(this.editSeq, true, outcome.versionAfter, this.lastReason, ticket)
            this.pending.add(CjguiTextSessionPending(ticket, baseMirror, result))
            return result
        }
        this.lastReason = outcome.reason
        let rejected = this.edit(this.editSeq, false, outcome.versionAfter, outcome.reason, ticket)
        this.pending.add(CjguiTextSessionPending(ticket, baseMirror, rejected))
        // 平台代理已经落了字,owner 没有:两侧从这一刻起分叉。
        this.needsCalibration = true
        this.calibrationRecalibrated = false
        return rejected
    }

    private func edit(seq: Int64, accepted: Bool, versionAfter: Int64, reason: String): CjguiTextSessionEdit {
        return this.edit(seq, accepted, versionAfter, reason, -1)
    }

    private func edit(seq: Int64, accepted: Bool, versionAfter: Int64, reason: String,
        ticket: Int64): CjguiTextSessionEdit {
        return CjguiTextSessionEdit(seq, ticket, accepted, versionAfter, this.mirrorRevision,
            this.contextEpoch, reason)
    }

    // ---- 串行 pending / ACK / 拒绝校准 ----

    public func pendingCount(): Int64 {
        return this.pending.size
    }

    public func oldestPendingTicket(): Int64 {
        return if (this.pending.size > 0) { this.pending[0].ticket } else { -1 }
    }

    /// 按位置结算:参数依次为 `ticket`(结算到该票据为止,含)与 `contextEpoch`。
    /// 回执身份必须匹配当前上下文代次,否则这次 ACK 说明
    /// 不了当前镜像的任何事 —— 例如 nodeId 被复用后旧上下文迟到的回执。
    /// 结算批次里只要有一笔被 owner 拒绝,平台代理与 accepted 正文就已经分叉:置
    /// 校准位,阻止后续输入继续以旧坐标写入当前正文。
    /// 返回 true 表示这次结算被采纳。
    public func acknowledge(ticket: Int64, contextEpoch: Int64): Bool {
        if (contextEpoch != this.contextEpoch) {
            this.lastReason = "stale_context_receipt"
            return false
        }
        var settled: Int64 = 0
        var i: Int64 = 0
        while (i < this.pending.size) {
            let item = this.pending[i]
            if (item.ticket > ticket) {
                break
            }
            if (!item.edit.accepted && item.sourceProxyChanged) {
                this.needsCalibration = true
                this.calibrationRecalibrated = false
            }
            settled += 1
            i += 1
        }
        if (settled == 0) {
            this.lastReason = "unknown_pending_ticket"
            return false
        }
        var k: Int64 = 0
        while (k < settled) {
            this.pending.remove(at: 0)
            k += 1
        }
        return true
    }

    /// 拒绝后的**第一步**:按 owner 现状重建镜像并推进镜像修订,返回镜像此刻是否可用于
    /// 重新表达范围。此刻校准锁**仍然持有** —— 锁的解除属于平台侧事件(代理已按新镜像
    /// 重新绑定/投影),必须由 `confirmProxyRestored` 带完整身份回执完成:平台在这一步
    /// 之后取 `restorationReceipt()`,恢复完成再交回。
    public func recalibrate(): Bool {
        this.refreshMirror()
        this.calibrationRecalibrated = this.window.isPrepared()
        return this.calibrationRecalibrated
    }
}
