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
import std.env.*

/// Semantic ticket: selection has its own revision even when bytes and content
/// version stay equal. A click A -> B -> A still retires a pending candidate.
public struct CjguiTextSelectionTicket {
    public let contextEpoch: Int64
    public let mirrorRevision: Int64
    public let contentVersion: Int64
    public let sourceVersion: Int64
    public let selectionRevision: Int64
    init(context: Int64, mirror: Int64, content: Int64, source: Int64, selection: Int64) {
        contextEpoch = context
        mirrorRevision = mirror
        contentVersion = content
        sourceVersion = source
        selectionRevision = selection
    }
}



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
    /// False only for a stale composition identity whose native event cannot
    /// describe the current proxy. The window must leave that proxy untouched.
    public let proxyRecoveryRequired: Bool

    init(seq: Int64, ticket: Int64, accepted: Bool, versionAfter: Int64, mirrorRevision: Int64,
        contextEpoch: Int64, reason: String, proxyRecoveryRequired!: Bool = true) {
        this.seq = seq
        this.ticket = ticket
        this.accepted = accepted
        this.versionAfter = versionAfter
        this.mirrorRevision = mirrorRevision
        this.contextEpoch = contextEpoch
        this.reason = reason
        this.proxyRecoveryRequired = proxyRecoveryRequired
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
    private let submitter: (String, Bool, () -> Bool) -> CjguiTextSessionEdit
    private var consumed: Bool = false

    init(contentVersion: Int64, startByte: Int64, endByte: Int64, contextEpoch: Int64,
        mirrorRevision: Int64, submitter: (String, Bool, () -> Bool) -> CjguiTextSessionEdit) {
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
        return this.submitter(text, sourceProxyChanged, { => true })
    }
    public func replaceAuthorized(text: String, choiceIsCurrent: () -> Bool,
        sourceProxyChanged!: Bool = false): CjguiTextSessionEdit {
        if (this.consumed) {
            return CjguiTextSessionEdit(-1, -1, false, this.contentVersion,
                this.mirrorRevision, this.contextEpoch, "prepared_range_consumed")
        }
        this.consumed = true
        return this.submitter(text, sourceProxyChanged, choiceIsCurrent)
    }
}

/// Experimental explicit whole-document choice. Its endpoints are versioned
/// source metadata, independent of the bounded native mirror. The constructor
/// is package-only; a local UTF-16 range cannot acquire this authority.
public class CjguiWholeDocumentSelection {
    public let contentVersion: Int64
    public let byteLength: Int64
    public let contextEpoch: Int64
    public let selectionRevision: Int64
    let choiceId: Int64
    private let current: () -> Bool
    private let submitter: (String, Bool) -> CjguiTextSessionEdit
    private var consumed: Bool = false
    init(version: Int64, total: Int64, context: Int64, revision: Int64, choice: Int64,
        current: () -> Bool, submitter: (String, Bool) -> CjguiTextSessionEdit) {
        contentVersion = version; byteLength = total; contextEpoch = context
        selectionRevision = revision; choiceId = choice
        this.current = current; this.submitter = submitter
    }
    public func isCurrent(): Bool { return current() }
    public func replace(text: String, sourceProxyChanged!: Bool = false): CjguiTextSessionEdit {
        if (consumed) {
            return CjguiTextSessionEdit(-1, -1, false, contentVersion, -1,
                contextEpoch, "whole_choice_consumed")
        }
        consumed = true
        return submitter(text, sourceProxyChanged)
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

// Once-only ledger for captured TextKit input. The range is owner-global and
// directed by the product descriptor; the native local range never appears in
// this record. Entries remain until the matching managed ACK retires the FIFO
// head, so a duplicate pump cannot submit a second owner write.
class CjguiSelectionInputMemo {
    let transferId: UInt64
    let inputId: UInt64
    let sequence: UInt64
    let previousSequence: UInt64
    let expectedVersion: Int64
    let choiceRevision: Int64
    let anchorByte: Int64
    let focusByte: Int64
    let replacement: String
    let edit: CjguiTextSessionEdit
    init(transferId: UInt64, inputId: UInt64, sequence: UInt64, previousSequence: UInt64,
        expectedVersion: Int64, choiceRevision: Int64, anchorByte: Int64, focusByte: Int64,
        replacement: String, edit: CjguiTextSessionEdit) {
        this.transferId = transferId; this.inputId = inputId; this.sequence = sequence
        this.previousSequence = previousSequence; this.expectedVersion = expectedVersion
        this.choiceRevision = choiceRevision; this.anchorByte = anchorByte; this.focusByte = focusByte
        this.replacement = replacement; this.edit = edit
    }
    func matches(transferId: UInt64, inputId: UInt64, sequence: UInt64, previousSequence: UInt64,
        expectedVersion: Int64, choiceRevision: Int64, anchorByte: Int64, focusByte: Int64,
        replacement: String): Bool {
        return this.transferId == transferId && this.inputId == inputId && this.sequence == sequence &&
            this.previousSequence == previousSequence && this.expectedVersion == expectedVersion &&
            this.choiceRevision == choiceRevision && this.anchorByte == anchorByte &&
            this.focusByte == focusByte && this.replacement == replacement
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

/// 一份**独立于活动组合**的恢复草稿(Astra 重锚裁决 Q4:先保存草稿、再取消)。
/// 外部正文在 owner claim 之上推进而平台无法保留输入源自身的转换会话时,组字被
/// 迫结束;用户已输入的 preedit 不能随之蒸发。草稿是纯证据+可取回内容:取回(作为
/// 一笔显式的新编辑落回正文)或放弃由**消费方的明确用户动作**决定,会话绝不静默
/// 自动提交它。迟到 cancel、重复终态与后续新组合都不能删掉这份草稿。
public class CjguiTextSessionRecoveryDraft {
    /// 会话内单调的草稿身份。通知、取回与放弃都绑定它:多份未处理草稿并存时,
    /// 界面显示的那一份就是取回动作消费的那一份。
    public let draftId: Int64
    /// 被中断的 preedit 文本(用户看到并可取回的内容)。
    public let content: String
    /// 组合开始时冻结的 owner 字节范围(旧版本坐标,仅作证据;取回时不得直接套用)。
    public let sourceStartByte: Int64
    public let sourceEndByte: Int64
    /// 草稿所属的 owner 内容版本。
    public let sourceVersion: Int64
    /// 草稿产生时的会话上下文代次与平台组合编号。
    public let contextEpoch: Int64
    public let compositionId: Int64
    /// 被中断组合的 owner claim 凭据(该 claim 已终结;此值只标识来源,不可再消费)。
    public let token: Int64
    /// 产生草稿的绑定身份:换绑后取回必须按名字拒绝,禁止恢复到新目标。
    public let bindingIdentity: String
    /// 0 = 正文(mirror)表面,1 = 呈现(presentation TEXT)表面。
    public let surface: Int64
    public let reason: String
    public let cause: String

    init(draftId: Int64, content: String, sourceStartByte: Int64, sourceEndByte: Int64,
        sourceVersion: Int64, contextEpoch: Int64, compositionId: Int64, token: Int64,
        bindingIdentity: String, surface: Int64, reason: String, cause: String) {
        this.draftId = draftId
        this.content = content
        this.sourceStartByte = sourceStartByte
        this.sourceEndByte = sourceEndByte
        this.sourceVersion = sourceVersion
        this.contextEpoch = contextEpoch
        this.compositionId = compositionId
        this.token = token
        this.bindingIdentity = bindingIdentity
        this.surface = surface
        this.reason = reason
        this.cause = cause
    }
}

/// 恢复草稿队列容量:未处理草稿并存的上界。容量在组合 begin 处生效——
/// 已满时新的组字被具名拒绝(`recovery_draft_capacity`),中断后绝不静默覆盖。
public let CJGUI_TEXT_SESSION_MAX_RECOVERY_DRAFTS: Int64 = 2

/// 普通文字意图（Astra Q5 共同处理器词汇）：一次按键表达的**用户级**动作。
/// 单位是用户感知字素（平台 oracle），不是 UTF-8/UTF-16 标量。
public enum CjguiTextPlainIntent {
    | DeleteBackward
    | DeleteForward
    | MoveLeft
    | MoveRight
    | ExtendLeft
    | ExtendRight
}

/// 一次普通文字意图的判决结果。`handled=false` 是具名拒绝（零写入、零选区
/// 变化），调用方不得再让平台默认行为执行一遍；`wroteOwner=true` 表示恰好一
/// 笔 owner 事务（移动/扩选恒为 false）。
public class CjguiPlainIntentOutcome {
    public let handled: Bool
    public let reason: String
    public let wroteOwner: Bool
    public let selectionStart16: Int64
    public let selectionEnd16: Int64

    init(handled!: Bool, reason!: String, wroteOwner!: Bool, start16!: Int64, end16!: Int64) {
        this.handled = handled
        this.reason = reason
        this.wroteOwner = wroteOwner
        this.selectionStart16 = start16
        this.selectionEnd16 = end16
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
    /// 普通意图的方向事实：Shift 只移动 focus，anchor 保持（Astra 位置契约）。
    /// 平台代理只接收 min/max 投影，方向是会话内部状态；-1 = 未定（折叠/未知）。
    private var selectionAnchor16: Int64 = -1
    private var selectionFocus16: Int64 = -1
    private var selEnd16: Int64 = 0
    /// Absolute source-byte selection is the durable view anchor. UTF-16
    /// coordinates above are only its projection into the current mirror.
    private var selectionVersion: Int64 = -1
    private var selectionRevision: Int64 = 0
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
    /// 活动组合所属表面:0 = 正文(mirror,坐标为镜像 UTF-16),1 = 呈现 TEXT(坐标由
    /// 消费方映射器解析为 owner 源字节)。两种表面共用同一 owner claim 生命周期。
    private var compositionSurface: Int64 = 0
    /// 呈现面组合冻结的 owner 源字节范围(正文表面的对应物是 replacementStart16/…)。
    private var compositionSourceStartByte: Int64 = -1
    private var compositionSourceEndByte: Int64 = -1
    /// 独立恢复草稿(见 `CjguiTextSessionRecoveryDraft`);生命周期与活动组合解耦。
    /// 有界队列:每份草稿有稳定身份,A 未处理时 B 的中断**追加**而不是覆盖;
    /// 容量在**接纳下一组合之前**检查(begin 具名拒绝),中断发生后绝不静默丢弃。
    private var recoveryDrafts: ArrayList<CjguiTextSessionRecoveryDraft> =
        ArrayList<CjguiTextSessionRecoveryDraft>()
    private var recoveryDraftSeq: Int64 = 0
    // Separately admitted native caret-prefix inputs. Their UTF-8 bytes and
    // slots stay charged until explicit discard/consume/ownership handoff.
    private var caretRecoveryDrafts: ArrayList<(CjguiTextSessionRecoveryDraft,
        InternalRendererCaretRecovery)> = ArrayList<(CjguiTextSessionRecoveryDraft,
        InternalRendererCaretRecovery)>()
    private var caretRecoveryBytes: Int64 = 0
    /// 防御性计账:begin 闸门使溢出不可达;若仍发生,最旧草稿被挤出的次数在此
    /// 如实计数(公开可读),绝不静默。
    private var recoveryDraftsDisplaced: Int64 = 0
    /// 本次**活动组合**是否已经保留过打断草稿。同一次中断可能先命中 stale 拒绝
    /// (提交/更新)再由平台的取消相位到达;没有这个标志时同一份 preedit 会被保留两遍
    /// (真实反例:commit→stale 保留 + 随后 redraw→stale 再保留 ⇒ drafts=2,容量闸门
    /// 反而把下一次合法组字拒成 `recovery_draft_capacity`)。按 id 判重不行——平台可以
    /// 不提供 compositionId(-1)。标志随 `clearComposition()` 归零,即"下一次组合"重新计。
    private var compositionDraftRetained: Bool = false

    /// 可选的 owner 组合接线(见 `CjguiRangeTextCompositionSink`)与绑定声明。声明仲裁但没有
    /// 该能力时,组合在 begin 就具名拒绝,绝不静默退回普通 sink。
    private let compositionSink: ?CjguiRangeTextCompositionSink
    private let compositionArbitration: Bool
    /// 活动 owner claim 的凭据;-1 表示没有登记(未声明仲裁、尚未 begin,或凭据已被消费终结)。
    private var compositionToken: Int64 = -1
    /// 该组合已无法继续对抗它的 owner claim(基版本/范围变化,本会话尚不能重锚):claim 已释放、
    /// 草稿保留,后续相位一律按此名字拒绝,直到平台取消并重新组字。
    private var compositionInvalidReason: String = ""
    /// 已被消费但未写成正文的终态草稿:只作恢复证据保留,本会话绝不重投。
    private var terminalCompositionDraft: String = ""
    /// owner 版本在组合期间前进后,同一 claim 上成功续接基点的次数(重锚证据)。
    private var compositionReanchors: Int64 = 0

    private var pending: ArrayList<CjguiTextSessionPending> = ArrayList<CjguiTextSessionPending>()
    private var selectionInputMemos: ArrayList<CjguiSelectionInputMemo> =
        ArrayList<CjguiSelectionInputMemo>()
    private var selectionInputLastTransferId: UInt64 = 0u64
    private var selectionInputLastSequence: UInt64 = 0u64
    private var selectionInputRetiredId: UInt64 = 0u64
    private var installedRangeChain: ?CjguiInstalledRangeChain = None
    private var wholeDocumentChoice: ?CjguiWholeDocumentSelection = None
    private var wholeDocumentChoiceSequence: Int64 = 0
    // A native source-surface handoff stages a new installed basis without
    // replacing the currently accepted chain. The native proxy remains
    // input-blocked until the owner commit and native declaration both pass.
    private var stagedInstalledRangeBasis: ?(CjguiInstalledRangeBasis, UInt64) = None
    private var frozenInstalledRangeHandoff: ?(CjguiInstalledRangeBasis, CjguiTextSelectionTicket) = None
    private var previousInstalledRangeChainForHandoff: ?CjguiInstalledRangeChain = None
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
    /// `compositionSink`/`compositionArbitration` 是可选组合仲裁接线:只有声明仲裁的绑定才会在
    /// 组合开始时登记 owner claim;普通消费者的行为完全不变。
    public init(window: CjguiRangeTextWindow, compositionSink!: ?CjguiRangeTextCompositionSink = None,
        compositionArbitration!: Bool = false) {
        this.window = window
        this.compositionSink = compositionSink
        this.compositionArbitration = compositionArbitration
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
        this.wholeDocumentChoice = None
        this.installedRangeChain = None
        this.selectionInputMemos.clear()
        this.selectionInputLastTransferId = 0u64
        this.selectionInputLastSequence = 0u64
        this.selectionInputRetiredId = 0u64
        this.stagedInstalledRangeBasis = None
        this.frozenInstalledRangeHandoff = None
        this.previousInstalledRangeChainForHandoff = None
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
        // 生命周期解绑先按精确 token 结束 owner claim,不能让保护跨绑定存活。
        this.endOwnerClaim()
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
        this.installedRangeChain = None
        this.selectionInputMemos.clear()
        this.selectionInputLastTransferId = 0u64
        this.selectionInputLastSequence = 0u64
        this.selectionInputRetiredId = 0u64
        this.stagedInstalledRangeBasis = None
        this.frozenInstalledRangeHandoff = None
        this.previousInstalledRangeChainForHandoff = None
        this.selectionRevision += 1
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
        // 解绑/销毁是框架生命周期发起的精确取消:旧 claim 随旧代次一起结束。
        this.endOwnerClaim()
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
        if (externalChange && this.selectionVersion >= 0 &&
            this.selectionStartByte >= 0 && !this.compositionActive) {
            rebased = this.window.rebaseSelection(this.selectionVersion, this.selectionStartByte,
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
                    // The owner proved these byte endpoints even when a page is
                    // unavailable. Keep their version so a later read, including
                    // another owner rebase, can project this same choice.
                    this.retainUnprojectedSourceSelection(mapped[0], mapped[1], mapped[2],
                        "selection_projection_unavailable")
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

    private func retainUnprojectedSourceSelection(version: Int64, startByte: Int64,
        endByte: Int64, reason: String): Unit {
        this.selectionRevision += 1
        this.selectionVersion = version
        this.selectionStartByte = startByte
        this.selectionEndByte = endByte
        this.selectionNeedsNativeRestore = true
        this.needsCalibration = true
        this.calibrationRecalibrated = false
        this.lastReason = reason
    }

    private func projectSourceSelection(startByte: Int64, endByte: Int64): Bool {
        this.selectionRevision += 1
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
                let reverse = this.selectionFocus16 < this.selectionAnchor16
                this.selStart16 = a
                this.selEnd16 = b
                this.selectionAnchor16 = if (reverse) { b } else { a }
                this.selectionFocus16 = if (reverse) { a } else { b }
                return true
            }
        }
        return false
    }

    public func needsNativeSelectionRestore(): Bool {
        this.refreshOwnerSelectionProjection()
        return this.selectionNeedsNativeRestore
    }

    // A bounded mirror can move without accepting a new semantic choice. The
    // retained absolute selection must still name these local UTF-16 positions
    // before they can authorize input or be signed into a native restoration.
    // Installation provenance has its own frozen basis and does not use this
    // current-mirror proof to reinterpret an older installed range.
    func selectionCoordinatesMatchMirror(): Bool {
        if (!this.bound || !this.window.isPrepared() ||
            this.selectionVersion != this.window.contentVersion() ||
            this.selectionStartByte < 0 || this.selectionEndByte < this.selectionStartByte) { return false }
        return match (this.window.documentRangeForUtf16(this.selStart16, this.selEnd16 - this.selStart16)) {
            case Some(range) => range[0] == this.selectionStartByte && range[1] == this.selectionEndByte
            case None => false
        }
    }

    public func confirmNativeSelectionRestored(version: Int64, start16: Int64, end16: Int64): Bool {
        if (!this.selectionNeedsNativeRestore || this.needsCalibration || !this.window.isPrepared() ||
            !this.selectionCoordinatesMatchMirror() ||
            version != this.selectionVersion ||
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
        if (this.selectionNeedsNativeRestore) {
            let start16 = if (selectionStart16 >= 0) { selectionStart16 } else { this.selStart16 }
            let end16 = if (selectionEnd16 >= 0) { selectionEnd16 } else { this.selEnd16 }
            let installedSource = this.window.documentRangeForUtf16(start16, end16 - start16)
            let matches = match (installedSource) {
                case Some(range) => this.selectionVersion == this.window.contentVersion() &&
                    range[0] == this.selectionStartByte && range[1] == this.selectionEndByte
                case None => false
            }
            if (!this.calibrationRecalibrated || !matches) {
                this.lastReason = "restore_selection_mismatch"
                return false
            }
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
                // 方向端点（anchor/focus）是会话侧状态：原生回执只确认范围。
                // 若回执范围与当前选择一致，保留既有方向，避免 Shift 扩选在
                // 代理往返后被折叠（anchor/focus 被 lo/hi 顺序覆盖）。
                let priorAnchor = this.selectionAnchor16
                let priorFocus = this.selectionFocus16
                this.setSelection16(selectionStart16, selectionEnd16)
                let confirmedLo = if (selectionStart16 <= selectionEnd16) { selectionStart16 } else { selectionEnd16 }
                let confirmedHi = if (selectionStart16 <= selectionEnd16) { selectionEnd16 } else { selectionStart16 }
                if (priorAnchor >= confirmedLo && priorAnchor <= confirmedHi &&
                    priorFocus >= confirmedLo && priorFocus <= confirmedHi &&
                    priorAnchor != priorFocus) {
                    this.selectionAnchor16 = priorAnchor
                    this.selectionFocus16 = priorFocus
                }
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

    /// The owner keeps the only directed source choice. These fields are a
    /// bounded UTF-16 projection and may be unavailable outside this mirror.
    private func refreshOwnerSelectionProjection(): Unit {
        let owner = match (this.window.selectionOwner()) { case Some(value) => value; case None => return }
        let value = owner.sourceSelectionSnapshot()
        let changed = value.revision != this.selectionRevision || value.version != this.selectionVersion
        this.selectionRevision = value.revision
        this.selectionVersion = value.version
        if (value.anchorByte < 0 || value.focusByte < 0) {
            this.selectionStartByte = -1; this.selectionEndByte = -1
            this.selectionAnchor16 = 0; this.selectionFocus16 = 0
            this.selStart16 = 0; this.selEnd16 = 0
            this.selectionNeedsNativeRestore = false
            return
        }
        this.selectionStartByte = if (value.anchorByte < value.focusByte) { value.anchorByte } else { value.focusByte }
        this.selectionEndByte = if (value.anchorByte > value.focusByte) { value.anchorByte } else { value.focusByte }
        if (value.version == this.window.contentVersion()) {
            let a = cjguiUtf8OffsetToUtf16(this.window.text(), value.anchorByte - this.window.windowStartByte())
            let b = cjguiUtf8OffsetToUtf16(this.window.text(), value.focusByte - this.window.windowStartByte())
            if (a.isSome() && b.isSome()) {
                this.selectionAnchor16 = a.getOrThrow(); this.selectionFocus16 = b.getOrThrow()
                this.selStart16 = if (this.selectionAnchor16 < this.selectionFocus16) { this.selectionAnchor16 } else { this.selectionFocus16 }
                this.selEnd16 = if (this.selectionAnchor16 > this.selectionFocus16) { this.selectionAnchor16 } else { this.selectionFocus16 }
            }
        }
        if (changed) { this.selectionNeedsNativeRestore = true }
    }

    public func sourceSelectionSnapshot(): ?CjguiSourceSelectionSnapshot {
        if (let Some(owner) <- this.window.selectionOwner()) { return Some(owner.sourceSelectionSnapshot()) }
        return None
    }

    /// Pure selection changes have zero body transactions. Same-valued choices
    /// still consume a new owner revision. Only accepted owner bytes are projected.
    public func setSelection16(start16: Int64, end16: Int64): Unit {
        let a = this.clamp16(start16)
        let b = this.clamp16(end16)
        let lo = if (a < b) { a } else { b }
        let hi = if (a > b) { a } else { b }
        let source = this.window.documentRangeForUtf16(lo, hi - lo)
        if (let Some(owner) <- this.window.selectionOwner()) {
            let bytes = match (source) { case Some(value) => value; case None => return }
            if (!owner.setSourceSelection(this.window.contentVersion(),
                if (a <= b) { bytes[0] } else { bytes[1] },
                if (a <= b) { bytes[1] } else { bytes[0] })) { return }
            this.refreshOwnerSelectionProjection()
        } else {
            this.selectionRevision += 1
            if (let Some(bytes) <- source) {
                this.selectionVersion = this.window.contentVersion()
                this.selectionStartByte = bytes[0]; this.selectionEndByte = bytes[1]
            } else { this.invalidateSourceSelection("selection_not_utf8_boundary") }
        }
        this.wholeDocumentChoice = None
        this.selectionAnchor16 = a; this.selectionFocus16 = b
        this.selStart16 = lo; this.selEnd16 = hi
    }

    /// The accepted source span represented by the current UTF-16 selection.
    /// It is read-only evidence for a caller about to use `replaceRange16`;
    /// the replacement still performs its own same-version owner arbitration.
    public func selectedSourceRange(): ?(Int64, Int64, Int64) {
        this.refreshOwnerSelectionProjection()
        if (!this.bound || this.selectionVersion < 0 ||
            this.selectionStartByte < 0 || this.selectionEndByte < this.selectionStartByte ||
            this.selectionNeedsNativeRestore || !this.selectionCoordinatesMatchMirror()) {
            return None
        }
        return Some((this.selectionVersion, this.selectionStartByte, this.selectionEndByte))
    }

    /// Semantic source coordinates for SourceMap preparation, including while
    /// the native proxy still needs installation. This does not acknowledge that
    /// installation or authorize input; the eventual commit must validate the
    /// same complete ticket again.
    public func sourceRangeForSelectionTicket(ticket: CjguiTextSelectionTicket): ?(Int64, Int64, Int64) {
        if (!this.selectionTicketMatches(ticket) || this.needsCalibration || this.selectionVersion < 0 ||
            this.selectionStartByte < 0 || this.selectionEndByte < this.selectionStartByte ||
            this.selectionVersion != this.window.contentVersion() ||
            this.window.sourceVersion() != this.window.contentVersion()) {
            return None
        }
        return Some((this.selectionVersion, this.selectionStartByte, this.selectionEndByte))
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
        this.refreshOwnerSelectionProjection()
        return (this.selStart16, this.selEnd16)
    }

    public func selectionRevisionValue(): Int64 { this.refreshOwnerSelectionProjection(); return this.selectionRevision }

    public func freezeSelectionTicket(): CjguiTextSelectionTicket {
        this.refreshOwnerSelectionProjection()
        return CjguiTextSelectionTicket(this.contextEpoch, this.mirrorRevision,
            this.window.contentVersion(), this.window.sourceVersion(), this.selectionRevision)
    }

    public func selectionTicketMatches(ticket: CjguiTextSelectionTicket): Bool {
        this.refreshOwnerSelectionProjection()
        return this.bound && !this.compositionActive &&
            ticket.contextEpoch == this.contextEpoch && ticket.mirrorRevision == this.mirrorRevision &&
            ticket.contentVersion == this.window.contentVersion() &&
            ticket.sourceVersion == this.window.sourceVersion() &&
            ticket.selectionRevision == this.selectionRevision
    }

    func settleReservedSelectionRevision(revision: Int64): Unit {
        if (revision < 0) { return }
        if (let Some(owner) <- this.window.selectionOwner()) { owner.settleSourceSelection(revision) }
        this.refreshOwnerSelectionProjection()
    }

    /// Reserve immutable A/B under the owner lock. The native installer owns the
    /// only terminal decision, and runs outside that lock. Once committed, later
    /// writes or projection failure cannot turn this accepted choice into refusal.
    func commitReservedSelectionTicket(ticket: CjguiTextSelectionTicket, anchor16: Int64,
        focus16: Int64, decision: CjguiSelectionDecision, installAndSettle: (Int64) -> Unit): Bool {
        let bytes = match (this.sourceBytesForSelection16(anchor16, focus16)) {
            case Some(value) => value; case None => return false
        }
        return this.commitReservedSourceSelectionTicket(ticket, bytes[0], bytes[1], decision, installAndSettle)
    }

    func sourceBytesForSelection16(anchor16: Int64, focus16: Int64): ?(Int64, Int64) {
        let lo = if (anchor16 < focus16) { anchor16 } else { focus16 }
        let hi = if (anchor16 > focus16) { anchor16 } else { focus16 }
        let bytes = match (this.window.documentRangeForUtf16(lo, hi - lo)) {
            case Some(value) => value; case None => return None
        }
        return Some(if (anchor16 <= focus16) { bytes } else { (bytes[1], bytes[0]) })
    }

    // Global source endpoints do not require materializing the interior. The
    // owner validates both byte boundaries and the frozen version/revision;
    // the same native decision still commits the bounded input surface.
    func commitReservedSourceSelectionTicket(ticket: CjguiTextSelectionTicket, anchorByte: Int64,
        focusByte: Int64, decision: CjguiSelectionDecision, installAndSettle: (Int64) -> Unit): Bool {
        let owner = match (this.window.selectionOwner()) { case Some(value) => value; case None => return false }
        if (anchorByte < 0 || focusByte < 0 || !this.selectionTicketMatches(ticket)) { return false }
        let reservedRevision = owner.reserveSourceSelection(ticket.contentVersion, ticket.selectionRevision,
            anchorByte, focusByte, decision)
        if (reservedRevision < 0) { return false }
        installAndSettle(reservedRevision)
        let committed = decision.state() == 3
        owner.settleSourceSelection(reservedRevision)
        this.refreshOwnerSelectionProjection()
        if (committed && this.selectionRevision == reservedRevision &&
            this.selectionVersion == ticket.contentVersion) {
            this.selectionNeedsNativeRestore = false
        }
        return committed
    }

    /// Owner guards contain only pure session work. Native installation may
    /// synchronously enter AppKit, so it must run outside the owner's lock.
    /// Revalidate the original ticket and owner version after installation.
    func commitSelectionTicket(ticket: CjguiTextSelectionTicket, anchor16: Int64,
        focus16: Int64, install: () -> Bool): Bool {
        if (!this.selectionTicketMatches(ticket)) { return false }
        let lo = if (anchor16 < focus16) { anchor16 } else { focus16 }
        let hi = if (anchor16 < focus16) { focus16 } else { anchor16 }
        if (lo < 0 || hi > this.mirrorUtf16Length ||
            this.window.documentRangeForUtf16(lo, hi - lo).isNone()) { return false }
        if (!this.window.confirmContentVersion({ => this.selectionTicketMatches(ticket) })) { return false }
        if (!install()) { return false }
        return this.window.confirmContentVersion({ =>
            if (!this.selectionTicketMatches(ticket)) { return false }
            this.setSelection16(anchor16, focus16)
            this.selectionAnchor16 = anchor16
            this.selectionFocus16 = focus16
            this.selectionNeedsNativeRestore = false
            return true
        })
    }

    // ---- 普通文字意图共同处理器（Astra Q5；E/macOS B 切片） ----

    /// 判决一次普通文字意图。删除=用户感知字素整簇（内部 caret 零写入、缺簇
    /// 具名拒绝，不退回标量）；移动/扩选只改选区（零正文事务），选区改动标记
    /// 原生恢复，由窗口推回代理。组字期间一律具名拒绝——组合会话拥有选区与
    /// 终态；非空选区的删除只提交一笔精确事务。
    public func handlePlainIntent(intent: CjguiTextPlainIntent): CjguiPlainIntentOutcome {
        let (failA, failB) = this.selection16()
        if (!this.bound) {
            return CjguiPlainIntentOutcome(handled: false, reason: "session_unbound",
                wroteOwner: false, start16: failA, end16: failB)
        }
        if (this.compositionActive) {
            return CjguiPlainIntentOutcome(handled: false, reason: "composition_busy",
                wroteOwner: false, start16: failA, end16: failB)
        }
        if (this.needsCalibration) {
            return CjguiPlainIntentOutcome(handled: false, reason: "recalibration_required",
                wroteOwner: false, start16: failA, end16: failB)
        }
        if (!this.window.isPrepared()) {
            return CjguiPlainIntentOutcome(handled: false, reason: this.window.unpreparedReason(),
                wroteOwner: false, start16: failA, end16: failB)
        }
        // 写入路径保留完整对齐门（版本+边界+代理恢复未决）；纯选区意图对选区
        // 自身是权威的，只要求版本与字节边界已对齐——上一次移动的代理推送尚未
        // 结算不应阻断下一次移动（窗口按序推送并确认）。
        if (!this.selectionCoordinatesMatchMirror()) {
            return CjguiPlainIntentOutcome(handled: false, reason: "selection_native_alignment_required",
                wroteOwner: false, start16: failA, end16: failB)
        }
        let text = this.window.text()
        let total16 = this.mirrorUtf16Length
        let (lo, hi) = this.selection16()
        let bytes = text.toArray()
        if (match (intent) { case DeleteBackward | DeleteForward => true case _ => false }) {
            if (this.selectionNeedsNativeRestore) {
                return CjguiPlainIntentOutcome(handled: false, reason: "selection_native_alignment_required",
                    wroteOwner: false, start16: failA, end16: failB)
            }
            if (hi > lo) {
                // 非空选区删除：两端必须都是字素边界（指导反例 1：Ae\u{0301}B 的
                // [2,3) 只删重音）。内部端点具名拒绝并保持原文**与原选区**。
                if (!this.clusterBoundary16(text, bytes, lo) || !this.clusterBoundary16(text, bytes, hi)) {
                    return CjguiPlainIntentOutcome(handled: false, reason: "selection_endpoint_inside_grapheme",
                        wroteOwner: false, start16: lo, end16: hi)
                }
                return this.submitPlainDelete(lo, hi)
            }
            let caretByte = match (cjguiUtf16OffsetToUtf8(text, lo)) {
                case Some(byte) => byte
                case None =>
                    return CjguiPlainIntentOutcome(handled: false, reason: "selection_not_utf8_boundary",
                        wroteOwner: false, start16: lo, end16: hi)
            }
            if (match (intent) { case DeleteBackward => true case _ => false }) {
                if (lo == 0 || caretByte == 0) {
                    return CjguiPlainIntentOutcome(handled: false, reason: "at_document_start",
                        wroteOwner: false, start16: lo, end16: hi)
                }
                match (cjguiGraphemeClusterRangeUtf8(text, caretByte - 1)) {
                    case Some((clusterStart, clusterEnd)) =>
                        let clusterStart16 = cjguiUtf16Length(String.fromUtf8(bytes[0..clusterStart]))
                        let clusterEnd16 = cjguiUtf16Length(String.fromUtf8(bytes[0..clusterEnd]))
                        if (clusterEnd16 != lo) {
                            // caret 落在簇内部：删除半个用户字符没有合法名字，保持原文。
                            return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_interior",
                                wroteOwner: false, start16: lo, end16: hi)
                        }
                        return this.submitPlainDelete(clusterStart16, clusterEnd16)
                    case None =>
                        return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                            wroteOwner: false, start16: lo, end16: hi)
                }
            }
            if (lo >= total16 || caretByte >= Int64(bytes.size)) {
                return CjguiPlainIntentOutcome(handled: false, reason: "at_document_end",
                    wroteOwner: false, start16: lo, end16: hi)
            }
            match (cjguiGraphemeClusterRangeUtf8(text, caretByte)) {
                case Some((clusterStart, clusterEnd)) =>
                    if (clusterStart != caretByte) {
                        return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_interior",
                            wroteOwner: false, start16: lo, end16: hi)
                    }
                    let clusterEnd16 = cjguiUtf16Length(String.fromUtf8(bytes[0..clusterEnd]))
                    return this.submitPlainDelete(lo, clusterEnd16)
                case None =>
                    return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                        wroteOwner: false, start16: lo, end16: hi)
            }
        }
        if (match (intent) { case MoveLeft | MoveRight => true case _ => false }) {
            // 普通移动：非空选区先**折叠**到目标端（指导反例 3：[0,2) 在文首按
            // Left、[1,4) 在文尾按 Right 都必须折叠成功，不因端点贴边被拒），
            // 折叠是零事务且不做边界判断；已折叠才判移动边界。
            if (hi > lo) {
                let target = if (match (intent) { case MoveLeft => true case _ => false }) { lo } else { hi }
                return this.applyPlainSelection(target, target)
            }
            if (match (intent) { case MoveLeft => true case _ => false }) {
                if (lo == 0) {
                    return CjguiPlainIntentOutcome(handled: false,
                        reason: this.mirrorEdgeRefusalReason(atStart: true),
                        wroteOwner: false, start16: lo, end16: hi)
                }
                let clusterStart16 = match (this.clusterStartLeftOf16(text, bytes, lo)) {
                    case Some(start) => start
                    case None =>
                        return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                            wroteOwner: false, start16: lo, end16: hi)
                }
                return this.applyPlainSelection(clusterStart16, clusterStart16)
            }
            if (hi >= total16) {
                return CjguiPlainIntentOutcome(handled: false,
                    reason: this.mirrorEdgeRefusalReason(atStart: false),
                    wroteOwner: false, start16: lo, end16: hi)
            }
            let clusterEnd16 = match (this.clusterEndRightOf16(text, bytes, hi)) {
                case Some(end) => end
                case None =>
                    return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                        wroteOwner: false, start16: lo, end16: hi)
            }
            return this.applyPlainSelection(clusterEnd16, clusterEnd16)
        }
        if (match (intent) { case ExtendLeft | ExtendRight => true case _ => false }) {
            // 扩选（指导反例 2）：Shift 只移动 **focus**，anchor 不动；越过 anchor
            // 后选区收缩/翻转连续正确（abcd caret2 → Shift+Left [1,2) anchor=2 →
            // Shift+Right 应回 [2,2)，不是 [1,3)）。focus 缺省取选区活动端/折叠点。
            let anchor = if (this.selectionAnchor16 >= 0) { this.selectionAnchor16 } else { hi }
            let focus = if (this.selectionFocus16 >= 0 &&
                this.selectionFocus16 >= lo && this.selectionFocus16 <= hi) {
                this.selectionFocus16
            } else {
                hi
            }
            if (match (intent) { case ExtendLeft => true case _ => false }) {
                if (focus == 0) {
                    return CjguiPlainIntentOutcome(handled: false,
                        reason: this.mirrorEdgeRefusalReason(atStart: true),
                        wroteOwner: false, start16: lo, end16: hi)
                }
                let newFocus = match (this.clusterStartLeftOf16(text, bytes, focus)) {
                    case Some(start) => start
                    case None =>
                        return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                            wroteOwner: false, start16: lo, end16: hi)
                }
                return this.applyDirectedSelection(anchor, newFocus)
            }
            if (focus >= total16) {
                return CjguiPlainIntentOutcome(handled: false,
                    reason: this.mirrorEdgeRefusalReason(atStart: false),
                    wroteOwner: false, start16: lo, end16: hi)
            }
            let newFocus = match (this.clusterEndRightOf16(text, bytes, focus)) {
                case Some(end) => end
                case None =>
                    return CjguiPlainIntentOutcome(handled: false, reason: "grapheme_boundary_unavailable",
                        wroteOwner: false, start16: lo, end16: hi)
            }
            return this.applyDirectedSelection(anchor, newFocus)
        }
        return CjguiPlainIntentOutcome(handled: false, reason: "intent_unknown",
            wroteOwner: false, start16: lo, end16: hi)
    }

    /// x16 是否为字素边界（0/镜像末端天然合法；否则含该偏移字节的簇必须恰从 x16 起）。
    private func clusterBoundary16(text: String, bytes: Array<Byte>, x16: Int64): Bool {
        if (x16 == 0 || x16 >= this.mirrorUtf16Length) {
            return true
        }
        let byte = match (cjguiUtf16OffsetToUtf8(text, x16)) {
            case Some(at) => at
            case None => return false
        }
        match (cjguiGraphemeClusterRangeUtf8(text, byte)) {
            case Some((clusterStart, _)) =>
                let clusterStart16 = cjguiUtf16Length(String.fromUtf8(bytes[0..clusterStart]))
                return clusterStart16 == x16
            case None => return false
        }
    }

    /// x16 左侧最近字素边界的 UTF-16 坐标（用于 Move/Extend 向左停靠）。
    private func clusterStartLeftOf16(text: String, bytes: Array<Byte>, x16: Int64): ?Int64 {
        let byte = match (cjguiUtf16OffsetToUtf8(text, x16)) {
            case Some(at) => at
            case None => return None
        }
        if (byte <= 0) {
            return None
        }
        match (cjguiGraphemeClusterRangeUtf8(text, byte - 1)) {
            case Some((clusterStart, _)) =>
                return Some(cjguiUtf16Length(String.fromUtf8(bytes[0..clusterStart])))
            case None => return None
        }
    }

    /// x16 右侧最近字素边界（簇终点）的 UTF-16 坐标（用于 Move/Extend 向右停靠）。
    private func clusterEndRightOf16(text: String, bytes: Array<Byte>, x16: Int64): ?Int64 {
        let byte = match (cjguiUtf16OffsetToUtf8(text, x16)) {
            case Some(at) => at
            case None => return None
        }
        if (byte >= Int64(bytes.size)) {
            return None
        }
        match (cjguiGraphemeClusterRangeUtf8(text, byte)) {
            case Some((_, clusterEnd)) =>
                return Some(cjguiUtf16Length(String.fromUtf8(bytes[0..clusterEnd])))
            case None => return None
        }
    }

    /// 镜像边界 vs 文档边界：窗口未覆盖全文时，贴边拒绝是**窗口**边缘而非文档
    /// 首尾，具名区分，不以窗口边缘冒充文档首尾。
    /// 镜像边缘 ≠ 文档边缘：有界镜像的窗口边缘与 owner 文档首尾分别具名，
    /// 供窗口级视觉导航（M2 水平/垂直）与逻辑意图共用同一拒绝词表。
    public func mirrorEdgeRefusalReason(atStart!: Bool): String {
        let atDocumentEdge = if (atStart) {
            this.window.windowStartByte() <= 0
        } else {
            this.window.windowStartByte() + Int64(this.window.text().toArray().size) >=
                this.window.sourceByteLength()
        }
        return if (atDocumentEdge) {
            if (atStart) { "at_document_start" } else { "at_document_end" }
        } else {
            if (atStart) { "at_window_start" } else { "at_window_end" }
        }
    }

    private func applyPlainSelection(start16: Int64, end16: Int64): CjguiPlainIntentOutcome {
        this.setSelection16(start16, end16)
        this.selectionNeedsNativeRestore = true
        let (a, b) = this.selection16()
        return CjguiPlainIntentOutcome(handled: true, reason: "", wroteOwner: false,
            start16: a, end16: b)
    }

    /// 普通意图的方向事实只读入口（窗口垂直导航等需要移动 focus）。
    public func plainSelectionAnchorValue(): Int64 {
        this.refreshOwnerSelectionProjection()
        return this.selectionAnchor16
    }

    public func plainSelectionFocusValue(): Int64 {
        this.refreshOwnerSelectionProjection()
        return this.selectionFocus16
    }

    /// 窗口级普通意图（垂直导航）的方向选区应用：与水平意图同一投影与恢复标记。
    public func applyDirectedPlainSelection(anchor16: Int64, focus16: Int64): Bool {
        if (!this.bound || this.compositionActive) {
            return false
        }
        let lo = if (anchor16 <= focus16) { anchor16 } else { focus16 }
        let hi = if (anchor16 <= focus16) { focus16 } else { anchor16 }
        if (lo < 0 || hi > this.mirrorUtf16Length) {
            return false
        }
        this.applyDirectedSelection(anchor16, focus16)
        return true
    }

    /// 方向保留的选区应用：anchor/focus 原样记录，投影 min/max 给平台与镜像。
    private func applyDirectedSelection(anchor16: Int64, focus16: Int64): CjguiPlainIntentOutcome {
        this.selectionAnchor16 = anchor16
        this.selectionFocus16 = focus16
        let lo = if (anchor16 <= focus16) { anchor16 } else { focus16 }
        let hi = if (anchor16 <= focus16) { focus16 } else { anchor16 }
        this.setSelection16(anchor16, focus16)
        // The owner received the directed endpoints; this is only its projection.
        this.selectionAnchor16 = anchor16
        this.selectionFocus16 = focus16
        this.selectionNeedsNativeRestore = true
        let (a, b) = this.selection16()
        return CjguiPlainIntentOutcome(handled: true, reason: "", wroteOwner: false,
            start16: a, end16: b)
    }

    private func submitPlainDelete(start16: Int64, end16: Int64): CjguiPlainIntentOutcome {
        let decision = this.replaceRange16(start16, end16, "")
        let (a, b) = this.selection16()
        if (decision.accepted) {
            // 会话驱动的写入：会话算出的 caret 是权威。标记原生恢复，让场景刷新
            // 时代理旧选区的钳制事件（kind 33）被拒，窗口在 accepted 边界把会话
            // caret 推回代理后才放行。
            this.selectionNeedsNativeRestore = true
            return CjguiPlainIntentOutcome(handled: true, reason: "", wroteOwner: true,
                start16: a, end16: b)
        }
        return CjguiPlainIntentOutcome(handled: false, reason: decision.reason, wroteOwner: false,
            start16: a, end16: b)
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
        if (!this.compositionActive) {
            return None
        }
        if (this.compositionSurface == 1) {
            // 呈现面:冻结范围本就是 owner 源字节,无镜像换算;UTF-16 端点不适用(-1)。
            return Some((this.activeCompositionId, this.compositionBaseVersion, -1, -1,
                this.compositionSourceStartByte, this.compositionSourceEndByte))
        }
        if (!this.window.isPrepared()) {
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
        if (this.compositionActive && this.compositionInvalidReason != "") {
            // claim 已经没了:后续相位不得再把这份草稿解释到它上面。
            return this.refuseCompositionIntent(this.compositionInvalidReason, true)
        }
        if (this.compositionActive && this.compositionSurface == 1) {
            // 呈现面组合持有唯一的组合槽位:正文表面的相位不得解释它的草稿与范围。
            return this.refuseCompositionIntent("composition_busy", true)
        }
        // 后续更新(重绘/候选变化)**不得重取基版本**:否则 Agent 在两次 marked 更新之间
        // 写入正文时,旧替换范围会被重新标成新基版本,提交时看似合法而它表达的是过时正文。
        // 基版本只在组合开始时冻结一次;期间 owner 推进就是具名拒绝,由平台重新组字。
        if (this.compositionActive && (this.window.sourceVersion() != this.compositionBaseVersion ||
                this.mirrorRevision != this.compositionBaseMirror)) {
            // 同一 Q4 恢复契约:被外部写打断的组合要保留可取回的 preedit,否则用户
            // 刚打出的字随组合一起消失(各表面四个 stale 分支共用同一份保留实现)。
            // 先保留(它按精确 token 结束 claim 并把 token 记进草稿),再按名字锁死
            // 这次组合——顺序反过来草稿只能记下 -1,丢失 claim 身份。
            this.retainInterruptedCompositionDraft(this.compositionSurface,
                "composition_base_stale", "owner_version_advanced", this.activeCompositionId,
                clear: false)
            this.invalidateCompositionClaim("composition_base_stale")
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        if (this.compositionActive && compositionId >= 0 && compositionId != this.activeCompositionId) {
            // 更新自称属于另一个组合:两个组字不能共用一份草稿与冻结范围。
            return this.refuseCompositionIntent("composition_id_mismatch", true)
        }
        // 统一恢复确认门(E2 复核第 1 项,在既有具名判定之后):恢复未完整确认
        // (镜像/代理仍停在扰乱前坐标)期间,新旧组字一律具名拒绝;旧相位只按
        // 身份终结,不开新组合。
        if (this.needsCalibration) {
            this.lastReason = "recalibration_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        // 恢复草稿容量闸门:未处理草稿占满时,先让用户取回/放弃再组新字——
        // 中断发生后绝不静默丢草稿,所以准入放在组合开始之前。
        if (startingComposition &&
            Int64(this.recoveryDrafts.size) >= CJGUI_TEXT_SESSION_MAX_RECOVERY_DRAFTS) {
            return this.refuseCompositionIntent("recovery_draft_capacity", false)
        }
        if (startingComposition) {
            if (resolvedStart < 0 || resolvedLength < 0 ||
                resolvedStart + resolvedLength > this.mirrorUtf16Length) {
                return this.refuseCompositionIntent(CJGUI_RANGE_TEXT_REASON_OUTSIDE_WINDOW, true)
            }
            if (this.compositionArbitration) {
                // 声明仲裁 ⇒ 组合必须有 owner claim 才允许开始;owner 的版本守卫拒绝即
                // `version_conflict`,这里不猜新坐标、也不登记。
                let claim = this.beginOwnerClaim(resolvedStart, resolvedLength)
                if (!claim.accepted) {
                    return this.refuseCompositionIntent(claim.reason, true)
                }
                this.compositionToken = claim.token
            }
        } else if (resolvedStart != this.replacementStart16) {
            // 后续更新报告的是平台代理里的当前 marked 范围:起点与冻结起点一致(实测
            // shouldChangeText 报 0+2、0+3),长度是**旧 preedit 长度**,其终点可以超过
            // 镜像长度 —— preedit 只存在于代理显示,不在镜像里,因此不按镜像校验它。
            // 起点改变才表达另一个替换段,映射不到 owner 原始文本,只能具名拒绝。
            this.invalidateCompositionClaim("composition_range_changed")
            return this.refuseCompositionIntent("composition_range_changed", true)
        }
        let textLen16 = cjguiUtf16Length(text)
        if (innerAnchor16 < 0 || innerFocus16 < 0 || innerAnchor16 > textLen16 || innerFocus16 > textLen16) {
            // 内部选区相对**本次传入的 preedit**:越界说明平台报的锚点不对应这段
            // 文本,静默钳位会把用户光标搬到别处,因此具名拒绝并由平台重建组合。
            this.invalidateCompositionClaim("composition_inner_range_invalid")
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
                return this.ignoredCompositionEvent(this.lastReason)
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
            return this.ignoredCompositionEvent(this.lastReason)
        }
        if (this.compositionActive && this.compositionSurface == 1) {
            // 呈现面组合的终态只经 `commitPresentationComposition`:正文提交入口
            // 不能把呈现面冻结的源字节范围解释成镜像 UTF-16 坐标。
            return this.refuseCompositionIntent("composition_busy", true)
        }
        if (this.compositionInvalidReason != "") {
            // 该组合的 claim 已经结束:终态不得再落到任何写入路径。
            let reason = this.compositionInvalidReason
            this.retainInterruptedCompositionDraft(this.compositionSurface, reason,
                "terminal_after_invalid_update", this.activeCompositionId)
            return this.refuseCompositionIntent(reason, true)
        }
        if (this.window.sourceVersion() != this.compositionBaseVersion ||
            this.mirrorRevision != this.compositionBaseMirror) {
            // Agent/另一窗口在组合期间改过基版本:旧回调不猜新坐标,具名拒绝并要
            // 求平台按新镜像重新组字。草稿保留,由用户决定重打还是放弃。
            this.retainInterruptedCompositionDraft(this.compositionSurface,
                "composition_base_stale", "owner_version_advanced", this.activeCompositionId)
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        // 统一恢复确认门(在既有具名判定之后):恢复未确认期间,任何仍活动的组合
        // 终态不得落写入路径——镜像/代理还停在分叉前的旧坐标。
        if (this.needsCalibration) {
            this.lastReason = "recalibration_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        let committed = match (finalText) {
            case Some(value) => value
            case None => this.compositionDraft
        }
        if (this.compositionToken >= 0) {
            // 声明仲裁的组合只走 owner 凭据终态:普通 sink 路径会被 owner 的保护拒绝
            // (自锁),也绕开"恰好一次"的 token 记账。
            return this.commitOwnerClaim(committed, compositionId)
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
            this.endOwnerClaim()
            this.lastTerminalCompositionId = compositionId
            this.clearComposition()
            return
        }
        if (compositionId >= 0 && compositionId == this.lastTerminalCompositionId) {
            this.lastReason = "composition_terminal_duplicate"
        }
    }

    /// 外部扰乱导致组合被迫结束(Astra 重锚裁决 Q4 安全恢复分支,由窗口在取消相位调用):
    /// 保存**独立**恢复草稿 → 按精确 token 结束 owner claim → 结束组合状态 →
    /// 持校准锁关闭输入门(正文表面),等待消费方按 owner 现状重建投影、native 代理
    /// 恢复并带完整回执 `confirmProxyRestored` 之后才放行新输入。
    /// 已接受的 Agent 事务原样保留;本路径自身零正文写入、零新撤销记录,也不会把
    /// 草稿静默提交 —— 取回/放弃由消费方的明确用户动作决定(`consumeRecoveryDraft`)。
    /// 返回值是本次扰乱判决(意图票据),供窗口按同一 acknowledge 结算留痕。
    public func disruptComposition(compositionId: Int64, reason: String,
        cause: String): CjguiTextSessionEdit {
        let surface = this.compositionSurface
        if (!this.compositionActive) {
            // 没有活动组合:重复/迟到的扰乱取消按重复终态处理,不产生新草稿。
            return this.refuseCompositionIntent("composition_terminal_duplicate", false)
        }
        if (compositionId >= 0 && this.activeCompositionId >= 0 &&
            compositionId != this.activeCompositionId) {
            return this.refuseCompositionIntent("composition_id_mismatch", false)
        }
        this.retainInterruptedCompositionDraft(surface, reason, cause, compositionId)
        // 两种表面共用同一恢复确认门(needsCalibration):镜像/投影仍停在扰乱前的
        // 旧坐标,完整恢复回执确认之前放行任何新输入就是把旧坐标写进新正文。
        // visual 表面的解锁由可视代理恢复链(recalibrate→恢复→confirmProxyRestored)
        // 完成,与正文表面同一入口。
        return this.refuseCompositionIntent(reason, true)
    }

    /// Q4 的“保存独立恢复草稿”步骤,单独成函数:凡是**活动组合被外部写打断**的
    /// 具名拒绝都必须走它,否则用户的 preedit 会随组合一起消失。首个真实输入反例是
    /// visual 表面的 base-stale 分支——外部写之后到达的 marked 更新此前只拒绝、零草稿,
    /// 产品因此既无通知也无「取回草稿」可点(α visual 链停在 PENDING 之前)。
    /// 本函数自身零正文写入、零新撤销记录;草稿按精确 token 结束 claim 后进入队列,
    /// 取回/放弃仍由消费方的明确用户动作决定。
    /// `clear` 区分两种调用者:`disruptComposition` 是终局(组合就此结束),
    /// 各 stale 拒绝分支只是把这次组合判成**不可继续**(组合保留、`compositionInvalidReason`
    /// 锁住后续同名字拒绝,等平台自己的取消相位收尾),因此不能替它清组合状态。
    /// `compositionId` 同时充当"这次组合已保留过"的判据:同一次中断的迟到相位
    /// (先 stale 拒绝、后取消相位)不得产生第二份草稿。空 preedit(用户尚未输入
    /// 任何内容)不产生草稿,只有 claim 收尾与恢复门关闭。
    private func retainInterruptedCompositionDraft(surface: Int64, reason: String,
        cause: String, compositionId: Int64, clear!: Bool = true): Unit {
        if (this.compositionDraftRetained) {
            // 这次组合的 preedit 已经保留过:迟到相位只收尾,不产生第二份。
            if (clear) {
                this.clearComposition()
            }
            return
        }
        if (this.compositionDraft == "") {
            // 没有任何已接受的 preedit 就没有可恢复内容:不生成空草稿(否则产品会
            // 为一个空串弹「取回草稿」),但 claim 仍按精确 token 结束、组合按调用者
            // 语义收尾,恢复确认门照常关闭。
            this.compositionDraftRetained = true
            this.endOwnerClaim()
            this.lastTerminalCompositionId = compositionId
            if (clear) {
                this.clearComposition()
            }
            return
        }
        var startByte: Int64 = -1
        var endByte: Int64 = -1
        if (surface == 1) {
            startByte = this.compositionSourceStartByte
            endByte = this.compositionSourceEndByte
        } else if (let Some(bytes) <- this.window.documentRangeForUtf16(
            this.replacementStart16, this.replacementLength16)) {
            startByte = bytes[0]
            endByte = bytes[1]
        }
        this.recoveryDraftSeq += 1
        let draft = CjguiTextSessionRecoveryDraft(
            this.recoveryDraftSeq, this.compositionDraft, startByte, endByte,
            this.compositionBaseVersion, this.contextEpoch, this.activeCompositionId,
            this.compositionToken, this.compositionBindingIdentity(), surface, reason, cause)
        // 追加而非覆盖;容量闸门在组合 begin 处,这里防御性地保界并如实计数。
        if (Int64(this.recoveryDrafts.size) >= CJGUI_TEXT_SESSION_MAX_RECOVERY_DRAFTS) {
            this.recoveryDrafts.remove(at: 0)
            this.recoveryDraftsDisplaced += 1
        }
        this.recoveryDrafts.add(draft)
        this.compositionDraftRetained = true
        this.endOwnerClaim()
        this.lastTerminalCompositionId = compositionId
        if (clear) {
            this.clearComposition()
        }
    }

    func retainCaretRecovery(recovery: InternalRendererCaretRecovery): Bool {
        let m = recovery.metadata
        let id = Int64(281474976710656u64 + m[0])
        for ((draft, previous) in this.caretRecoveryDrafts) {
            if (draft.draftId == id && previous.metadata[1] == m[1]) {
                return draft.content == recovery.content && internalRendererFinishCaretRecovery(recovery, 1u32) ==
                    CJGUI_INTERNAL_RENDERER_OK
            }
        }
        let bytes = recovery.content.toArray().size
        if (this.caretRecoveryDrafts.size >= 64 || bytes > 262144 - this.caretRecoveryBytes) {
            this.lastReason = "input_recovery_capacity"
            return false
        }
        let identity = "cjgui-input:${m[1]}:window:${m[2]}:binding:${m[3]}:context:${m[4]}:node:${m[13]}"
        let cause = "${recovery.reason};proxy=${m[8]};selection=${m[9]};after=${m[10]};nonce=${m[15]};ack=${m[19]}"
        let draft = CjguiTextSessionRecoveryDraft(id, recovery.content, Int64(m[6]), Int64(m[7]), Int64(m[5]),
            Int64(m[4]), -1, Int64(m[0]), identity, if (m[20] == UInt64(CJGUI_COMPOSABLE_UI_TEXT)) {
                1
            } else {
                0
            }, "caret_input_interrupted", cause)
        // Own the complete copy before confirming that native may release it.
        this.caretRecoveryDrafts.add((draft, recovery))
        if (internalRendererFinishCaretRecovery(recovery, 1u32) != CJGUI_INTERNAL_RENDERER_OK) {
            this.caretRecoveryDrafts.remove(at: this.caretRecoveryDrafts.size - 1)
            this.lastReason = "input_recovery_handoff_unconfirmed"
            return false
        }
        this.caretRecoveryBytes += bytes
        return true
    }

    func hasCaretRecovery(): Bool {
        !this.caretRecoveryDrafts.isEmpty()
    }

    // Consumer has retained the complete draft under the original document
    // identity. This releases the quota, and never writes owner content.
    func handoffCaretRecovery(draftId: Int64): Bool {
        var index: Int64 = 0
        while (index < this.caretRecoveryDrafts.size) {
            let (draft, recovery) = this.caretRecoveryDrafts[index]
            if (draft.draftId == draftId) {
                if (internalRendererFinishCaretRecovery(recovery, 2u32) != CJGUI_INTERNAL_RENDERER_OK) {
                    this.lastReason = "input_recovery_release_unconfirmed"
                    return false
                }
                this.caretRecoveryBytes -= draft.content.toArray().size
                this.caretRecoveryDrafts.remove(at: index)
                return true
            }
            index += 1
        }
        return false
    }

    /// 未处理恢复草稿(新→旧);有界,每份带稳定身份。
    public func recoveryDraftsValue(): Array<CjguiTextSessionRecoveryDraft> {
        let out = ArrayList<CjguiTextSessionRecoveryDraft>()
        var caretIndex = this.caretRecoveryDrafts.size - 1
        while (caretIndex >= 0) {
            out.add(this.caretRecoveryDrafts[caretIndex][0]);
            caretIndex -= 1
        }
        var index = Int64(this.recoveryDrafts.size) - 1
        while (index >= 0) {
            out.add(this.recoveryDrafts[index])
            index -= 1
        }
        return out.toArray()
    }

    /// 最新恢复草稿(只读观察;消费方据此在反馈区告知并保留可取回内容)。
    public func recoveryDraftValue(): ?CjguiTextSessionRecoveryDraft {
        if (!this.caretRecoveryDrafts.isEmpty()) {
            return Some(this.caretRecoveryDrafts[this.caretRecoveryDrafts.size - 1][0])
        }
        if (Int64(this.recoveryDrafts.size) == 0) {
            return None
        }
        return Some(this.recoveryDrafts[this.recoveryDrafts.size - 1])
    }

    /// 防御性挤出的草稿数(begin 闸门使其正常为 0);公开可读的诚实计账。
    public func recoveryDraftsDisplacedCount(): Int64 {
        return this.recoveryDraftsDisplaced
    }

    /// **写前校验**:某份草稿此刻能否被取回(身份匹配、绑定未换、恢复门未锁)。
    /// 消费方在提交任何正文之前调用;失败具名,草稿原样保留。
    public func canConsumeRecoveryDraft(draftId: Int64): Bool {
        for ((draft, recovery) in this.caretRecoveryDrafts) {
            if (draft.draftId == draftId) {
                if (!this.bound || this.needsCalibration || draft.contextEpoch != this.contextEpoch) {
                    this.lastReason = "recovery_draft_binding_lost"
                    return false
                }
                if (internalRendererFinishCaretRecovery(recovery, 0u32) != CJGUI_INTERNAL_RENDERER_OK) {
                    this.lastReason = "input_recovery_origin_lost"
                    return false
                }
                return true
            }
        }
        for (draft in this.recoveryDrafts) {
            if (draft.draftId == draftId) {
                if (this.needsCalibration) {
                    this.lastReason = "recalibration_required"
                    return false
                }
                if (draft.contextEpoch != this.contextEpoch || draft.bindingIdentity != this
                    .compositionBindingIdentity()) {
                    this.lastReason = "recovery_draft_binding_lost"
                    return false
                }
                return true
            }
        }
        this.lastReason = "recovery_draft_absent"
        return false
    }

    /// **显式取回**:一次性交出指定身份的草稿并移出队列。取回后的落字是消费方
    /// 自己的一笔显式新编辑,不经旧 claim、不自动提交;身份/绑定/恢复门不符按名字
    /// 拒绝,草稿保留。消费方必须先以 `canConsumeRecoveryDraft` 做写前校验——本
    /// 方法自身也再核一次,但它不应是唯一的保护点。
    public func consumeRecoveryDraft(draftId: Int64): ?CjguiTextSessionRecoveryDraft {
        for ((draft, _) in this.caretRecoveryDrafts) {
            if (draft.draftId == draftId) {
                if (!this.canConsumeRecoveryDraft(draftId) || !this.handoffCaretRecovery(draftId)) {
                    return None
                }
                this.lastReason = ""
                return Some(draft)
            }
        }
        var index: Int64 = 0
        while (index < Int64(this.recoveryDrafts.size)) {
            let draft = this.recoveryDrafts[index]
            if (draft.draftId == draftId) {
                if (!this.canConsumeRecoveryDraft(draftId)) {
                    return None
                }
                this.recoveryDrafts.remove(at: index)
                this.lastReason = ""
                return Some(draft)
            }
            index += 1
        }
        this.lastReason = "recovery_draft_absent"
        return None
    }

    /// **显式放弃**指定身份的草稿(用户决定不要这份 preedit)。身份不符返回 false。
    public func discardRecoveryDraft(draftId: Int64): Bool {
        if (this.handoffCaretRecovery(draftId)) {
            return true
        }
        var index: Int64 = 0
        while (index < Int64(this.recoveryDrafts.size)) {
            if (this.recoveryDrafts[index].draftId == draftId) {
                this.recoveryDrafts.remove(at: index)
                return true
            }
            index += 1
        }
        return false
    }

    // ---- 呈现(presentation TEXT)组合:同一 owner claim 的第二表面 ----

    /// 呈现面组合开始:消费方映射器已把首个替换范围解析为同版本 owner 源字节跨度
    /// (`CjguiPreparedSourceRange` 的身份字段)。仲裁绑定的组合在这里登记 owner
    /// claim;未声明仲裁的绑定不得使用本入口(继续走既有普通替换路径)。
    /// 冻结范围是**源字节**:呈现坐标属于消费方投影,不经镜像换算。
    public func beginPresentationComposition(contentVersion: Int64, startByte: Int64,
        endByte: Int64, contextEpoch: Int64, mirrorRevision: Int64, compositionId: Int64,
        firstPreedit!: String = "", firstInnerAnchor16!: Int64 = 0,
        firstInnerFocus16!: Int64 = 0): CjguiTextSessionEdit {
        if (!this.bound) {
            return this.refuseCompositionIntent("session_unbound", false)
        }
        if (this.needsCalibration) {
            return this.refuseCompositionIntent("recalibration_required", false)
        }
        if (this.compositionActive) {
            return this.refuseCompositionIntent("composition_busy", false)
        }
        // 恢复草稿容量闸门:与正文表面同一策略,组合开始之前检查。
        if (Int64(this.recoveryDrafts.size) >= CJGUI_TEXT_SESSION_MAX_RECOVERY_DRAFTS) {
            return this.refuseCompositionIntent("recovery_draft_capacity", false)
        }
        // 首个相位本身也是数据(E2 复核第 1 项):begin 与合法 preedit 更新在同一
        // 相位完成。外部扰乱恰在唯一一次 marked update 之后到来时,保存的草稿必须
        // 与刚显示的文字一致——begin 后草稿为空的旧形状做不到这一点。
        let preeditUnits = cjguiUtf16Length(firstPreedit)
        if (firstInnerAnchor16 < 0 || firstInnerFocus16 < 0 ||
            firstInnerAnchor16 > preeditUnits || firstInnerFocus16 > preeditUnits) {
            return this.refuseCompositionIntent("composition_inner_range_invalid", false)
        }
        if (contextEpoch != this.contextEpoch || mirrorRevision != this.mirrorRevision) {
            return this.refuseCompositionIntent("prepared_range_stale", false)
        }
        if (this.window.sourceVersion() != contentVersion) {
            return this.refuseCompositionIntent(CJGUI_RANGE_TEXT_REASON_VERSION, false)
        }
        if (this.compositionArbitration) {
            let sink = match (this.compositionSink) {
                case Some(wired) => wired
                case None => return this.refuseCompositionIntent(
                    CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE, false)
            }
            let claim = sink.beginRangeTextComposition(this.compositionBindingIdentity(),
                contentVersion, startByte, endByte)
            if (!claim.accepted) {
                return this.refuseCompositionIntent(claim.reason, false)
            }
            this.compositionToken = claim.token
        } else {
            return this.refuseCompositionIntent(
                CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE, false)
        }
        this.compositionActive = true
        this.compositionSurface = 1
        this.compositionDraft = firstPreedit
        this.compositionBaseVersion = contentVersion
        this.compositionBaseMirror = this.mirrorRevision
        this.compositionSourceStartByte = startByte
        this.compositionSourceEndByte = endByte
        this.activeCompositionId = compositionId
        this.markedStart16 = 0
        this.markedLength16 = preeditUnits
        this.markedInnerAnchor16 = firstInnerAnchor16
        this.markedInnerFocus16 = firstInnerFocus16
        this.lastReason = ""
        return this.edit(this.editSeq, true, -1, "")
    }

    /// 呈现面组合更新:只更新 preedit 与内部选区(相对传入 preedit)。期间 owner 版本
    /// 前进 ⇒ claim 具名失效并保留草稿,由平台按新投影重建组合;不再有镜像坐标判定。
    public func updatePresentationComposition(text: String, innerAnchor16: Int64,
        innerFocus16: Int64, compositionId: Int64): CjguiTextSessionEdit {
        if (!this.bound) {
            return this.refuseCompositionIntent("session_unbound", false)
        }
        if (!this.compositionActive || this.compositionSurface != 1) {
            return this.refuseCompositionIntent("composition_not_active", false)
        }
        if (this.compositionInvalidReason != "") {
            return this.refuseCompositionIntent(this.compositionInvalidReason, false)
        }
        if (compositionId >= 0 && this.activeCompositionId >= 0 &&
            compositionId != this.activeCompositionId) {
            return this.refuseCompositionIntent("composition_id_mismatch", false)
        }
        if (this.window.sourceVersion() != this.compositionBaseVersion) {
            // Q4 同一恢复契约:外部写让镜像/投影停在旧坐标时,已接受的 preedit 必须
            // 保留可取回。此前这条分支只拒绝(真实输入反例:α visual 链在 base-stale
            // 之后没有任何恢复草稿,产品无通知、无「取回草稿」)。草稿保留后组合仍由
            // 平台自己的取消相位收尾,迟到的相位不会产生第二份。
            this.retainInterruptedCompositionDraft(this.compositionSurface,
                "composition_base_stale", "owner_version_advanced", this.activeCompositionId,
                clear: false)
            this.invalidateCompositionClaim("composition_base_stale")
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        // 统一恢复确认门(在既有具名判定之后),与正文表面同一把锁。
        if (this.needsCalibration) {
            this.lastReason = "recalibration_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        let textLen16 = cjguiUtf16Length(text)
        if (innerAnchor16 < 0 || innerFocus16 < 0 || innerAnchor16 > textLen16 ||
            innerFocus16 > textLen16) {
            this.invalidateCompositionClaim("composition_inner_range_invalid")
            return this.refuseCompositionIntent("composition_inner_range_invalid", true)
        }
        this.compositionDraft = text
        this.markedLength16 = textLen16
        this.markedInnerAnchor16 = innerAnchor16
        this.markedInnerFocus16 = innerFocus16
        this.lastReason = ""
        return this.edit(this.editSeq, true, -1, "")
    }

    /// 呈现面组合终态:与正文表面共用 `commitOwnerClaim` —— 一笔 Human 事务、凭据
    /// 恰好消费一次、提交后镜像按 owner 实际消费范围刷新。
    public func commitPresentationComposition(finalText: String,
        compositionId: Int64): CjguiTextSessionEdit {
        if (!this.bound) {
            return this.refuseCompositionIntent("session_unbound", false)
        }
        if (!this.compositionActive || this.compositionSurface != 1) {
            if (compositionId >= 0 && compositionId == this.lastTerminalCompositionId) {
                this.lastReason = "composition_terminal_duplicate"
                return this.ignoredCompositionEvent(this.lastReason)
            }
            return this.refuseCompositionIntent("composition_not_active", false)
        }
        if (compositionId >= 0 && this.activeCompositionId >= 0 &&
            compositionId != this.activeCompositionId) {
            this.lastReason = if (compositionId == this.lastTerminalCompositionId) {
                "composition_terminal_duplicate"
            } else {
                "composition_id_mismatch"
            }
            return this.ignoredCompositionEvent(this.lastReason)
        }
        if (this.compositionInvalidReason != "") {
            let reason = this.compositionInvalidReason
            this.retainInterruptedCompositionDraft(this.compositionSurface, reason,
                "terminal_after_invalid_update", this.activeCompositionId)
            return this.refuseCompositionIntent(reason, true)
        }
        if (this.window.sourceVersion() != this.compositionBaseVersion) {
            // 真实输入反例(α visual 链):这条分支就是终局——native 在外部写之后
            // 到达的是一次**提交**(phase 2),此前只拒绝 ⇒ 用户刚提交的首候选直接
            // 消失,产品既无通知也无「取回草稿」。按同一 Q4 契约保留草稿。
            this.retainInterruptedCompositionDraft(this.compositionSurface,
                "composition_base_stale", "owner_version_advanced", this.activeCompositionId)
            return this.refuseCompositionIntent("composition_base_stale", true)
        }
        // 统一恢复确认门(在既有具名判定之后),与正文表面同一把锁。
        if (this.needsCalibration) {
            this.lastReason = "recalibration_required"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        if (this.compositionToken >= 0) {
            return this.commitOwnerClaim(finalText, compositionId)
        }
        return this.refuseCompositionIntent(
            CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE, true)
    }

    /// 呈现面组合取消:零事务,按精确 token 结束 claim(含重复终态幂等)。
    public func cancelPresentationComposition(compositionId!: Int64 = -1): Unit {
        if (this.compositionActive && this.compositionSurface == 1) {
            if (compositionId >= 0 && this.activeCompositionId >= 0 &&
                compositionId != this.activeCompositionId) {
                this.lastReason = if (compositionId == this.lastTerminalCompositionId) {
                    "composition_terminal_duplicate"
                } else {
                    "composition_id_mismatch"
                }
                return
            }
            this.endOwnerClaim()
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
        this.compositionDraftRetained = false
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
        this.compositionSurface = 0
        this.compositionSourceStartByte = -1
        this.compositionSourceEndByte = -1
        // 凭据与失效原因随组合一起清:释放动作由结束路径(endOwnerClaim/cancel)负责,
        // 这里只把状态归零,绝不在清除时偷偷调用 owner。
        this.compositionToken = -1
        this.compositionInvalidReason = ""
    }

    /// 镜像坐标下的当前选区(UTF-16;折叠时两端相等)。只读观测:消费探针据此
    /// 核对 source 表面的停靠/删除落点,不参与任何判决。
    public func selectionUtf16Value(): (Int64, Int64) {
        return (this.selStart16, this.selEnd16)
    }

    /// 组字期间平台报告的 marked 内部选区(相对传入 preedit),供选区查询原答。
    public func markedInnerSelection16(): (Int64, Int64) {
        return if (this.compositionActive) {
            (this.markedInnerAnchor16, this.markedInnerFocus16)
        } else {
            (0, 0)
        }
    }

    // ---- owner 组合凭据(可选仲裁) ----

    /// 凭据绑定的窗口身份:上下文代次 + 节点号,不是可复用的窗口名。重绑推进代次,
    /// 旧凭据永远指认不了新绑定。
    private func compositionBindingIdentity(): String {
        return "cjgui-session:${this.contextEpoch}:node:${this.window.nodeId()}"
    }

    /// 活动 claim 凭据;-1 表示没有登记。消费方/证据读取用。
    public func compositionClaimTokenValue(): Int64 {
        return this.compositionToken
    }

    /// 活动组合的平台编号；无活动组合或平台未提供时为 -1。窗口据此在副作用之前
    /// 判决迟到终态的身份，与 visual 表面的 `presentationCompositionId` 同契约。
    public func compositionIdValue(): Int64 {
        return if (this.compositionActive) { this.activeCompositionId } else { -1 }
    }

    /// 最近一次真正结束(提交/取消/扰乱/保留草稿)的组合编号；-1 表示尚无终态。
    /// 迟到的重复终态据此按 `composition_terminal_duplicate` 幂等拒绝。
    public func lastTerminalCompositionIdValue(): Int64 {
        return this.lastTerminalCompositionId
    }

    /// 本绑定是否声明了组合仲裁。声明而没有能力时,组合在 begin 即具名拒绝。
    public func compositionArbitrationDeclared(): Bool {
        return this.compositionArbitration
    }

    /// 非终态组合已无法到达 owner claim 的具名原因;健康(或未声明仲裁)时为空。
    public func compositionInvalidationReason(): String {
        return this.compositionInvalidReason
    }

    /// 活动组合的基点是否已被 owner 版本推进越过:与各 stale 拒绝分支**同一判据**
    /// (`window.sourceVersion() != compositionBaseVersion`),供窗口在 native 结束组合
    /// (取消相位)时判定"这次结束是外部写打断"。
    ///
    /// 为什么不能只看被组字片段自己的渲染值变化:呈现面的组合可能落在标题片段上,而
    /// 外部写落在正文片段——片段值不变,旧的表面变化判据漏判,取消相位就落成普通
    /// cancel,用户的 preedit 零草稿丢失(visual α 链 2026-09-29 实测)。owner 版本
    /// 越过组合基点时,旧冻结坐标一律不可再落字,这条判据与 stale 分支同源。
    public func compositionBaseStale(): Bool {
        return this.compositionActive && this.window.sourceVersion() != this.compositionBaseVersion
    }

    /// 组合期间 owner 版本前进后的**续接结算**:在同一 owner 临界点确认活动 claim 仍是
    /// 本会话那个 token(身份、活动性、owner 实例都在 `inspect` 里核对),并采用它当前
    /// 所属的版本作为新的组合基点——镜像随之按 owner 刷新,镜像修订推进,使以旧修订
    /// 表达的冻结坐标不再被当成当前。
    ///
    /// 它只改会话的基点状态,绝不代写正文、绝不新建 claim;claim 已失效时具名拒绝并
    /// 保留草稿。调用方必须已在 native 侧装好同一基文的代理(重锚读回成功),否则
    /// 平台 preedit 与这份新基点不描述同一段正文。
    public func rebaseCompositionBaseFromClaim(): Bool {
        if (!this.compositionActive || this.compositionToken < 0) {
            return false
        }
        if (this.mirrorRevision == this.compositionBaseMirror &&
            this.window.sourceVersion() == this.compositionBaseVersion) {
            return true
        }
        let sink = match (this.compositionSink) {
            case Some(wired) => wired
            case None =>
                this.lastReason = CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE
                return false
        }
        let live = sink.inspectRangeTextComposition(this.compositionToken)
        if (!live.ok) {
            this.lastReason = if (live.reason == "") { "composition_stale" } else { live.reason }
            return false
        }
        let _ = this.refreshMirror()
        this.compositionBaseVersion = live.contentVersion
        this.compositionBaseMirror = this.mirrorRevision
        this.compositionReanchors += 1
        this.lastReason = ""
        return true
    }

    /// 组合基点被 owner 推进后成功续接的次数(重锚证据)。
    public func compositionReanchorCount(): Int64 {
        return this.compositionReanchors
    }

    /// 已被消费但未写成正文的终态草稿(只作恢复证据,不会重投)。
    public func lastTerminalCompositionDraft(): String {
        return this.terminalCompositionDraft
    }

    /// 为组合开始登记 owner 的活动 claim,范围 `[resolvedStart16, +resolvedLength16)`。范围经
    /// **同一个**有界镜像换算,并由 owner 判定换算版本:陈旧镜像必然得到 `version_conflict`,
    /// 零 claim、零正文变化,而不是把旧坐标登记到新文本上。
    private func beginOwnerClaim(resolvedStart16: Int64,
        resolvedLength16: Int64): CjguiRangeTextCompositionClaim {
        let sink = match (this.compositionSink) {
            case Some(wired) => wired
            case None => return CjguiRangeTextCompositionClaim.refused(
                CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE, this.window.contentVersion())
        }
        let mapped = match (this.window.documentRangeForUtf16(resolvedStart16, resolvedLength16)) {
            case Some(range) => range
            case None => return CjguiRangeTextCompositionClaim.refused(
                CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY, this.window.contentVersion())
        }
        return sink.beginRangeTextComposition(this.compositionBindingIdentity(),
            this.window.contentVersion(), mapped[0], mapped[1])
    }

    /// 用精确 token 释放活动 claim(绝不用按名字的通配释放)。best effort:owner 可能已经
    /// 消费或释放过它。
    private func endOwnerClaim(): Unit {
        if (this.compositionToken < 0) {
            return
        }
        let token = this.compositionToken
        this.compositionToken = -1
        if (let Some(sink) <- this.compositionSink) {
            let _ = sink.cancelRangeTextComposition(token)
        }
    }

    /// 该组合不能再对抗它的 claim:按名字释放保护、保留草稿。被拒绝的组合不得留下永久
    /// 活动的保护。
    private func invalidateCompositionClaim(reason: String): Unit {
        if (!this.compositionArbitration) {
            return
        }
        this.endOwnerClaim()
        this.compositionInvalidReason = reason
    }

    /// owner 凭据的终态路径。最终文本只经组合 Sink 与活动 token 落成**一笔** Human 事务,
    /// 绝不走普通范围替换;凭据只被一个终态消费:消费后但未写成正文的终态不在此重试
    /// (仅保留终态草稿作恢复证据),而没到达 owner 的拒绝会具名结束 claim,不让保护
    /// 挂在已死的组合后面。
    private func commitOwnerClaim(committed: String, compositionId: Int64): CjguiTextSessionEdit {
        let sink = match (this.compositionSink) {
            case Some(wired) => wired
            case None => return this.refuseCompositionIntent(
                CJGUI_RANGE_TEXT_REASON_ARBITRATION_UNAVAILABLE, true)
        }
        let token = this.compositionToken
        let expectedVersion = this.compositionBaseVersion
        let baseMirror = this.mirrorRevision
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        let outcome = sink.commitRangeTextComposition(token, expectedVersion, committed,
            "composition-terminal:${this.contextEpoch}:${token}")
        if (outcome.consumed) {
            this.compositionToken = -1
        }
        if (outcome.accepted) {
            this.lastTerminalCompositionId = compositionId
            if (!outcome.published) {
                // 零宽 claim + 空终态:owner 结算了"无变更终态"(零版本、零历史)。没有正文
                // 需要刷新,也不持校准锁;具名报告,不冒充一次已接受的组合写入。
                this.clearComposition()
                this.lastReason = CJGUI_RANGE_TEXT_REASON_COMPOSITION_NO_CHANGE
                let settled = this.edit(this.editSeq, true, outcome.versionAfter,
                    CJGUI_RANGE_TEXT_REASON_COMPOSITION_NO_CHANGE, ticket)
                this.pending.add(CjguiTextSessionPending(ticket, baseMirror, settled))
                return settled
            }
            // 一笔事务已落:caret 由 owner 回执的实际消费范围投影(消费起点 + 插入字节),
            // 不跨过"刚被自己替换"的范围去猜。
            let caretByte = outcome.startByte + cjguiUtf8Length(committed)
            let _ = this.window.revealByte(caretByte)
            let changed = this.window.refresh()
            if (changed) {
                this.mirrorRevision += 1
                this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            }
            this.editSeq += 1
            let localCaret = caretByte - this.window.windowStartByte()
            let caret: ?Int64 = if (this.window.isPrepared() &&
                this.window.contentVersion() == outcome.versionAfter) {
                cjguiUtf8OffsetToUtf16(this.window.text(), localCaret)
            } else {
                None
            }
            this.clearComposition()
            if (let Some(caret16) <- caret) {
                this.setSelection16(caret16, caret16)
                this.lastReason = ""
            } else {
                this.needsCalibration = true
                this.calibrationRecalibrated = false
                this.lastReason = "accepted_caret_unprepared"
            }
            let result = this.edit(this.editSeq, true, outcome.versionAfter, this.lastReason, ticket)
            this.pending.add(CjguiTextSessionPending(ticket, baseMirror, result))
            return result
        }
        // 凭据已被消费但正文未写,或 owner 在消费前拒绝:两种情况本会话都不再重试这笔终态。
        // 具名结束 claim、保留草稿(消费态另存终态草稿)、持校准锁等平台取消/重建组合。
        this.endOwnerClaim()
        if (outcome.consumed) {
            this.terminalCompositionDraft = committed
        }
        this.compositionInvalidReason = if (outcome.reason == "") {
            "composition_not_written"
        } else {
            outcome.reason
        }
        this.needsCalibration = true
        this.calibrationRecalibrated = false
        this.lastReason = this.compositionInvalidReason
        this.retainInterruptedCompositionDraft(this.compositionSurface, this.lastReason,
            "owner_terminal_refused", this.activeCompositionId)
        let refused = this.edit(this.editSeq, false, outcome.versionAfter, this.lastReason, ticket)
        this.pending.add(CjguiTextSessionPending(ticket, baseMirror, refused))
        return refused
    }

    // ---- 唯一的范围替换路径 ----

    // Freeze a bounded owner source before the native candidate is armed. The
    // caller activates it only after the exact native installation receipt.
    func freezeInstalledRangeBasis(nonce: UInt64, document: UInt64,
        binding: UInt64): ?CjguiInstalledRangeBasis {
        if (!this.bound || nonce == 0 || document == 0 || binding == 0 ||
            this.compositionActive || !this.window.isPrepared() ||
            cjguiUtf8Length(this.window.text()) > 65536) { return None }
        let ticket = this.freezeSelectionTicket()
        let start = this.window.windowStartByte()
        let body = this.window.text()
        let basis = CjguiInstalledRangeBasis(nonce, document, binding, this.contextEpoch,
            this.mirrorRevision, this.window.contentVersion(), start, start + cjguiUtf8Length(body), body)
        let valid = this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(ticket) && this.window.windowStartByte() == basis.sourceStart &&
                this.window.text() == basis.text
        })
        return if (valid) { Some(basis) } else { None }
    }

    // Handoff candidates retain the exact semantic selection ticket that was
    // current when the future binding was armed. A same-value new selection
    // therefore invalidates this candidate instead of being silently carried.
    func freezeInstalledRangeHandoffBasis(nonce: UInt64, document: UInt64,
        binding: UInt64): ?CjguiInstalledRangeBasis {
        if (!this.bound || nonce == 0 || document == 0 || binding == 0 ||
            this.compositionActive || this.needsCalibration || !this.window.isPrepared() ||
            !this.selectionCoordinatesMatchMirror() ||
            cjguiUtf8Length(this.window.text()) > 65536) { return None }
        let ticket = this.freezeSelectionTicket()
        let start = this.window.windowStartByte()
        let body = this.window.text()
        let basis = CjguiInstalledRangeBasis(nonce, document, binding, this.contextEpoch,
            this.mirrorRevision, this.window.contentVersion(), start, start + cjguiUtf8Length(body), body)
        let valid = this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(ticket) && this.window.windowStartByte() == basis.sourceStart &&
                this.window.text() == basis.text
        })
        if (!valid) { return None }
        frozenInstalledRangeHandoff = Some((basis, ticket))
        return Some(basis)
    }

    // Pure owner/session confirmation, performed before the native receipt is
    // made input-ready. It never calls native or clears the public restore gate.
    func activateInstalledRangeBasis(basis: CjguiInstalledRangeBasis,
        proxyGeneration: UInt64): Bool {
        if (!this.bound || proxyGeneration == 0 || basis.context != this.contextEpoch ||
            basis.mirror != this.mirrorRevision || basis.sourceStart != this.window.windowStartByte() ||
            basis.text != this.window.text() || basis.ownerVersion != this.window.contentVersion()) { return false }
        return this.window.confirmContentVersion({ =>
            if (basis.context != this.contextEpoch || basis.ownerVersion != this.window.contentVersion()) { return false }
            this.installedRangeChain = Some(CjguiInstalledRangeChain(basis, proxyGeneration))
            return true
        })
    }

    // Pure owner-side precheck for a native source handoff. It records no new
    // active basis and leaves the old chain available if native receipt/commit
    // subsequently fails.
    func stageInstalledRangeBasis(basis: CjguiInstalledRangeBasis,
        proxyGeneration: UInt64): Bool {
        if (!this.bound || this.needsCalibration || proxyGeneration == 0 || basis.context != this.contextEpoch ||
            basis.mirror != this.mirrorRevision || basis.sourceStart != this.window.windowStartByte() ||
            basis.text != this.window.text() || basis.ownerVersion != this.window.contentVersion()) { return false }
        let frozen = match (frozenInstalledRangeHandoff) { case Some(value) => value; case None => return false }
        let ticket = frozen[1]
        if (frozen[0].nonce != basis.nonce || frozen[0].document != basis.document ||
            frozen[0].binding != basis.binding || frozen[0].context != basis.context ||
            frozen[0].mirror != basis.mirror || frozen[0].ownerVersion != basis.ownerVersion ||
            frozen[0].sourceStart != basis.sourceStart || frozen[0].sourceEnd != basis.sourceEnd ||
            frozen[0].text != basis.text) { return false }
        let valid = this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(ticket) && basis.context == this.contextEpoch &&
                basis.mirror == this.mirrorRevision && basis.ownerVersion == this.window.contentVersion() &&
                basis.sourceStart == this.window.windowStartByte() && basis.text == this.window.text()
        })
        if (!valid) { return false }
        stagedInstalledRangeBasis = Some((basis, proxyGeneration))
        return true
    }

    // Revalidate and publish only after native has atomically switched its
    // declaration under the still-closed input gate. The prior chain remains
    // available for exact rollback until native finishes the handoff.
    func commitStagedInstalledRangeBasis(nonce: UInt64): Bool {
        let staged = match (stagedInstalledRangeBasis) { case Some(value) => value; case None => return false }
        let basis = staged[0]
        if (basis.nonce != nonce || !this.bound || this.needsCalibration || basis.context != this.contextEpoch ||
            basis.mirror != this.mirrorRevision || basis.sourceStart != this.window.windowStartByte() ||
            basis.text != this.window.text() || basis.ownerVersion != this.window.contentVersion()) { return false }
        let frozen = match (frozenInstalledRangeHandoff) { case Some(value) => value; case None => return false }
        let ticket = frozen[1]
        let valid = this.window.confirmContentVersion({ =>
            if (!this.selectionTicketMatches(ticket) || basis.context != this.contextEpoch ||
                basis.mirror != this.mirrorRevision || basis.sourceStart != this.window.windowStartByte() ||
                basis.text != this.window.text() || basis.ownerVersion != this.window.contentVersion()) { return false }
            previousInstalledRangeChainForHandoff = installedRangeChain
            installedRangeChain = Some(CjguiInstalledRangeChain(basis, staged[1]))
            stagedInstalledRangeBasis = None
            return true
        })
        return valid
    }

    func installedRangeHandoffBasisCurrent(basis: CjguiInstalledRangeBasis): Bool {
        if (this.needsCalibration) { return false }
        let frozen = match (frozenInstalledRangeHandoff) { case Some(value) => value; case None => return false }
        if (frozen[0].nonce != basis.nonce || frozen[0].document != basis.document ||
            frozen[0].binding != basis.binding || frozen[0].context != basis.context ||
            frozen[0].mirror != basis.mirror || frozen[0].ownerVersion != basis.ownerVersion ||
            frozen[0].sourceStart != basis.sourceStart || frozen[0].sourceEnd != basis.sourceEnd ||
            frozen[0].text != basis.text) { return false }
        return this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(frozen[1]) && basis.context == this.contextEpoch &&
                basis.mirror == this.mirrorRevision && basis.ownerVersion == this.window.contentVersion() &&
                basis.sourceStart == this.window.windowStartByte() && basis.text == this.window.text()
        })
    }

    // Called only after the real native source-selection event has passed the
    // ordinary owner selection commit. It captures that new accepted ticket;
    // unrelated or same-value later selection changes cannot use this path.
    func refreshInstalledRangeHandoffSelectionTicket(basis: CjguiInstalledRangeBasis): Bool {
        if (this.needsCalibration) { return false }
        let frozen = match (frozenInstalledRangeHandoff) { case Some(value) => value; case None => return false }
        if (frozen[0].nonce != basis.nonce || frozen[0].document != basis.document ||
            frozen[0].binding != basis.binding || frozen[0].context != basis.context ||
            frozen[0].mirror != basis.mirror || frozen[0].ownerVersion != basis.ownerVersion ||
            frozen[0].sourceStart != basis.sourceStart || frozen[0].sourceEnd != basis.sourceEnd ||
            frozen[0].text != basis.text) { return false }
        let ticket = this.freezeSelectionTicket()
        let valid = this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(ticket) && basis.context == this.contextEpoch &&
                basis.mirror == this.mirrorRevision && basis.ownerVersion == this.window.contentVersion() &&
                basis.sourceStart == this.window.windowStartByte() && basis.text == this.window.text()
        })
        if (!valid) { return false }
        frozenInstalledRangeHandoff = Some((basis, ticket))
        return true
    }

    func rollbackStagedInstalledRangeBasis(nonce: UInt64): Unit {
        if (let Some(staged) <- stagedInstalledRangeBasis) {
            if (staged[0].nonce == nonce) { stagedInstalledRangeBasis = None }
        }
        if (let Some(frozen) <- frozenInstalledRangeHandoff) {
            if (frozen[0].nonce == nonce) { frozenInstalledRangeHandoff = None }
        }
        if (let Some(chain) <- installedRangeChain) {
            if (chain.basis.nonce == nonce) {
                installedRangeChain = previousInstalledRangeChainForHandoff
                previousInstalledRangeChainForHandoff = None
            }
        }
    }

    func finishStagedInstalledRangeBasis(nonce: UInt64): Bool {
        if (let Some(chain) <- installedRangeChain) {
            if (chain.basis.nonce == nonce) {
                previousInstalledRangeChainForHandoff = None
                stagedInstalledRangeBasis = None
                frozenInstalledRangeHandoff = None
                return true
            }
        }
        return false
    }

    private func refuseInstalledRange(reason: String): CjguiTextSessionEdit {
        if (let Some(chain) <- this.installedRangeChain) { chain.closed = true }
        this.needsCalibration = true
        this.calibrationRecalibrated = false
        this.lastReason = reason
        this.ticketSeq += 1
        let rejected = this.edit(this.editSeq, false, this.window.sourceVersion(), reason, this.ticketSeq)
        this.pending.add(CjguiTextSessionPending(this.ticketSeq, this.mirrorRevision, rejected,
            sourceProxyChanged: true))
        return rejected
    }

    func abandonInstalledRangeBasis(nonce: UInt64): Unit {
        if (let Some(chain) <- this.installedRangeChain) {
            if (chain.basis.nonce == nonce) { this.installedRangeChain = None }
        }
    }

    func installedRangeExpectedVersion(): Int64 {
        return match (this.installedRangeChain) {
            case Some(chain) => chain.acceptedVersion
            case None => -1
        }
    }

    /// Freeze the current owner-ACKed installed source for a cross-fragment
    /// transfer. This does not infer provenance from the mirror: the caller
    /// must separately obtain and match the native active receipt for nonce.
    func freezeInstalledSelectionSource(document: UInt64, binding: UInt64):
        ?CjguiInstalledSelectionSourceSnapshot {
        if (!this.bound || this.compositionActive || this.needsCalibration ||
            document == 0u64 || binding == 0u64 || !this.window.isPrepared()) {
            getStdOut().writeln("CJGUI_INSTALLED_SELECTION_SOURCE_REFUSED stage=session " +
                "bound=${this.bound} composition=${this.compositionActive} calibration=${this.needsCalibration} " +
                "document=${document} binding=${binding} prepared=${this.window.isPrepared()}")
            return None
        }
        let chain = match (this.installedRangeChain) {
            case Some(value) => value
            case None =>
                getStdOut().writeln("CJGUI_INSTALLED_SELECTION_SOURCE_REFUSED stage=no_chain")
                return None
        }
        if (chain.closed || chain.basis.document != document || chain.basis.binding != binding ||
            chain.proxyGeneration == 0u64 || chain.acceptedVersion < chain.basis.ownerVersion ||
                (chain.acceptedSequence > 0u64 && chain.acceptedVersion <= chain.basis.ownerVersion)) {
            getStdOut().writeln("CJGUI_INSTALLED_SELECTION_SOURCE_REFUSED stage=chain_identity " +
                "closed=${chain.closed} proxy=${chain.proxyGeneration} accepted=${chain.acceptedVersion} " +
                "base=${chain.basis.ownerVersion} sequence=${chain.acceptedSequence}")
            return None
        }
        let ticket = this.freezeSelectionTicket()
        let body = chain.postBody
        let sourceStart = chain.acceptedSourceStart
        let sourceEnd = sourceStart + cjguiUtf8Length(body)
        if (body.size > 65536 || sourceStart < 0 || sourceEnd < sourceStart ||
            this.window.sourceVersion() != chain.acceptedVersion) {
            getStdOut().writeln("CJGUI_INSTALLED_SELECTION_SOURCE_REFUSED stage=body_or_version " +
                "bytes=${body.size} start=${sourceStart} end=${sourceEnd} " +
                "source_version=${this.window.sourceVersion()} accepted=${chain.acceptedVersion}")
            return None
        }
        let snapshot = CjguiInstalledSelectionSourceSnapshot(chain.basis, chain.acceptedSequence,
            chain.acceptedVersion, sourceStart, sourceEnd, chain.proxyGeneration, body)
        let valid = this.window.confirmContentVersion({ =>
            return this.selectionTicketMatches(ticket) &&
                this.installedRangeChain.isSome() &&
                this.installedRangeChain.getOrThrow().basis.nonce == snapshot.basis.nonce &&
                this.installedRangeChain.getOrThrow().proxyGeneration == snapshot.proxyGeneration &&
                !chain.closed && chain.postBody == snapshot.body &&
                chain.acceptedSequence == snapshot.acceptedSequence &&
                chain.acceptedVersion == snapshot.acceptedVersion &&
                chain.acceptedSourceStart == snapshot.sourceStart &&
                chain.proxyGeneration == snapshot.proxyGeneration &&
                this.window.sourceVersion() == snapshot.acceptedVersion
        })
        if (!valid) { getStdOut().writeln("CJGUI_INSTALLED_SELECTION_SOURCE_REFUSED stage=final_ticket") }
        return if (valid) { Some(snapshot) } else { None }
    }

    // The only old-proxy coordinate entry: prove the installed root and its
    // accepted FIFO prefix, then prepare the absolute span and use the same Sink.
    // Public replaceRange16 retains its complete current-mirror alignment gate.
    func submitInstalledRange16(input: CjguiInstalledRangeInput, text: String,
        actualPostBody!: ?String = None): CjguiTextSessionEdit {
        if (!this.bound || input.basis.context != this.contextEpoch) {
            return this.edit(this.editSeq, false, -1, "installed_range_stale_binding")
        }
        let chain = match (this.installedRangeChain) {
            case Some(active) => active
            case None => return this.refuseInstalledRange("installed_range_unregistered")
        }
        if (!chain.matches(input) || chain.closed || input.sequence == 0 ||
            input.previousSequence != chain.acceptedSequence || input.sequence <= input.previousSequence ||
            input.preBody != chain.postBody || !chain.observedAckMatches(input)) {
            return this.refuseInstalledRange("installed_range_prefix_mismatch")
        }
        if (this.needsCalibration || this.compositionActive) {
            return this.refuseInstalledRange(if (this.compositionActive) { "composition_busy" } else { "recalibration_required" })
        }
        let expected = chain.acceptedVersion
        if (this.window.sourceVersion() != expected) { return this.refuseInstalledRange(CJGUI_RANGE_TEXT_REASON_VERSION) }
        let preBytes = cjguiUtf8Length(input.preBody)
        let insertedBytes = cjguiUtf8Length(text)
        let payloadLimit = CJGUI_INSTALLED_RANGE_PAYLOAD_BUDGET / CJGUI_INSTALLED_RANGE_PAYLOAD_COPIES
        if (preBytes > payloadLimit || insertedBytes > payloadLimit) {
            return this.refuseInstalledRange(CJGUI_RANGE_TEXT_REASON_BUDGET)
        }
        let lo = input.start16
        let hi = input.end16
        let startLocal = cjguiUtf16OffsetToUtf8(input.preBody, lo)
        let endLocal = cjguiUtf16OffsetToUtf8(input.preBody, hi)
        if (lo < 0 || hi < lo || startLocal.isNone() || endLocal.isNone()) {
            return this.refuseInstalledRange(CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
        }
        let start = chain.acceptedSourceStart + startLocal.getOrThrow()
        let end = chain.acceptedSourceStart + endLocal.getOrThrow()
        let postBytes = preBytes - (end - start) + insertedBytes
        if (preBytes + insertedBytes + postBytes > payloadLimit) {
            return this.refuseInstalledRange(CJGUI_RANGE_TEXT_REASON_BUDGET)
        }
        let bytes = input.preBody.toArray()
        let post = String.fromUtf8(bytes.slice(0, startLocal.getOrThrow())) + text +
            String.fromUtf8(bytes.slice(endLocal.getOrThrow(), bytes.size - endLocal.getOrThrow()))
        if (let Some(actual) <- actualPostBody) {
            if (actual != post) { return this.refuseInstalledRange("installed_range_post_body_mismatch") }
        }
        let whole = input.wholeChoiceNonce != 0
        let accepted = if (whole) {
            // The private native receipt names the real Cmd+A that preceded
            // this exact mutation. A full local range alone grants no authority.
            if (input.wholeChoiceNonce <= chain.lastWholeChoiceNonce ||
                input.wholeChoicePrevious != input.previousSequence ||
                lo != 0 || hi != cjguiUtf16Length(input.preBody)) {
                return this.refuseInstalledRange("installed_whole_choice_mismatch")
            }
            let choice = this.selectWholeDocument(expected)
            if (choice.isNone()) { return this.refuseInstalledRange(this.lastReason) }
            choice.getOrThrow().replace(text, sourceProxyChanged: false)
        } else {
            let prepared = this.prepareSourceRange(expected, start, end)
            if (prepared.isNone()) { return this.refuseInstalledRange(this.lastReason) }
            // The public alignment/restore gate is never cleared for old input.
            prepared.getOrThrow().replace(text, sourceProxyChanged: false)
        }
        if (accepted.accepted) {
            if (whole) {
                chain.acceptedSourceStart = 0
                chain.lastWholeChoiceNonce = input.wholeChoiceNonce
            }
            chain.accept(input, accepted.versionAfter, post)
            return accepted
        }
        chain.closed = true
        this.needsCalibration = true
        this.calibrationRecalibrated = false
        return accepted
    }

    func refuseCapturedInstalledRange(): CjguiTextSessionEdit {
        return this.refuseInstalledRange("installed_range_sideband_invalid")
    }

    /// 显式范围替换(镜像内 UTF-16 单位)。平台直接输入走这里,因此组字期间必须
    /// 让位给 marked 提交路径,不能同时存在第二个正文写入者。
    public func replaceRange16(start16: Int64, end16: Int64, text: String): CjguiTextSessionEdit {
        if (this.compositionActive) {
            this.lastReason = "composition_busy"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        return this.submitRange16(start16, end16, text)
    }

    /// Submit one ordinary TextKit edit against a product-authorized owner
    /// choice. The directed owner-global source endpoints come from the
    /// descriptor callback; B's local UTF-16 range is deliberately absent.
    /// A duplicate inputId reuses the same result until its FIFO ACK.
    public func submitAuthorizedSelectionRange(transferId: UInt64, inputId: UInt64,
        sequence: UInt64, previousSequence: UInt64, expectedVersion: Int64,
        choiceRevision: Int64, anchorByte: Int64, focusByte: Int64, replacement: String,
        choiceIsCurrent: () -> Bool): CjguiTextSessionEdit {
        for (memo in selectionInputMemos) {
            if (memo.inputId == inputId) {
                if (memo.matches(transferId, inputId, sequence, previousSequence, expectedVersion,
                    choiceRevision, anchorByte, focusByte, replacement)) { return memo.edit }
                return this.edit(this.editSeq, false, this.window.sourceVersion(), "selection_input_id_conflict")
            }
        }
        if (!this.bound || transferId == 0u64 || inputId == 0u64 || sequence == 0u64 ||
            previousSequence == UInt64.Max || previousSequence + 1u64 != sequence ||
            expectedVersion < 0 || choiceRevision < 0 || anchorByte < 0 || focusByte < 0 ||
            inputId <= selectionInputRetiredId ||
            (selectionInputLastTransferId != 0u64 && transferId < selectionInputLastTransferId)) {
            return this.edit(this.editSeq, false, this.window.sourceVersion(), "selection_input_stale")
        }
        var expectedPrevious = selectionInputLastSequence
        var sameTransfer = selectionInputLastTransferId == transferId
        if (!selectionInputMemos.isEmpty()) {
            let tail = selectionInputMemos[selectionInputMemos.size - 1]
            if (inputId <= tail.inputId || tail.transferId != transferId) {
                return this.edit(this.editSeq, false, this.window.sourceVersion(),
                    "selection_input_prefix_mismatch")
            }
            if (tail.transferId == transferId) {
                expectedPrevious = tail.sequence
                sameTransfer = true
            }
        }
        if ((sameTransfer && (previousSequence != expectedPrevious || sequence <= expectedPrevious)) ||
            selectionInputMemos.size >= 64) {
            return this.edit(this.editSeq, false, this.window.sourceVersion(),
                if (selectionInputMemos.size >= 64) { "selection_input_capacity" } else {
                    "selection_input_prefix_mismatch"
                })
        }
        if (!choiceIsCurrent()) {
            let stale = this.edit(this.editSeq, false, this.window.sourceVersion(), "selection_input_choice_stale")
            this.rememberSelectionInput(transferId, inputId, sequence, previousSequence, expectedVersion,
                choiceRevision, anchorByte, focusByte, replacement, stale)
            return stale
        }
        let lo = if (anchorByte < focusByte) { anchorByte } else { focusByte }
        let hi = if (anchorByte < focusByte) { focusByte } else { anchorByte }
        // A proven global selection can exceed the native mirror. Reuse the
        // whole-source owner operation without reading the selected interior.
        // This capability comes from the current owner choice, never from a
        // local proxy merely reporting that all of its own text is selected.
        if (lo == 0) {
            let whole = this.wholeDocumentChoiceForCurrentSelection(expectedVersion)
            if (let Some(value) <- whole) {
                if (value.byteLength == hi && value.selectionRevision == choiceRevision && choiceIsCurrent()) {
                    let decision = value.replace(replacement, sourceProxyChanged: false)
                    this.rememberSelectionInput(transferId, inputId, sequence, previousSequence, expectedVersion,
                        choiceRevision, anchorByte, focusByte, replacement, decision)
                    return decision
                }
            }
        }
        let prepared = match (this.prepareSourceRange(expectedVersion, lo, hi)) {
            case Some(value) => value
            case None =>
                let rejected = this.edit(this.editSeq, false, this.window.sourceVersion(), this.lastReason)
                this.rememberSelectionInput(transferId, inputId, sequence, previousSequence,
                    expectedVersion, choiceRevision, anchorByte, focusByte, replacement, rejected)
                return rejected
        }
        let decision = prepared.replaceAuthorized(replacement, choiceIsCurrent,
            sourceProxyChanged: false)
        this.rememberSelectionInput(transferId, inputId, sequence, previousSequence, expectedVersion,
            choiceRevision, anchorByte, focusByte, replacement, decision)
        return decision
    }

    /// Retire only the matching ledger head after its external owner ACK.
    public func acknowledgeAuthorizedSelectionInput(transferId: UInt64, inputId: UInt64): Bool {
        // Native ACK retry may repeat the exact confirmation after the FIFO
        // head was already retired. Preserve idempotence for that full ledger
        // identity without accepting an older or merely same-numbered input.
        if (inputId != 0u64 && transferId != 0u64 &&
            inputId == selectionInputRetiredId && transferId == selectionInputLastTransferId) {
            return true
        }
        if (selectionInputMemos.isEmpty()) { return false }
        let head = selectionInputMemos[0]
        if (head.transferId != transferId || head.inputId != inputId) { return false }
        selectionInputMemos.remove(at: 0)
        if (inputId > selectionInputRetiredId) { selectionInputRetiredId = inputId }
        selectionInputLastTransferId = transferId
        selectionInputLastSequence = head.sequence
        return true
    }

    /// The window's held native ACK records whether a memo must be retired
    /// after native confirms the exact captured claim. This is intentionally
    /// read-only: retry never resubmits the owner edit.
    func hasAuthorizedSelectionInputMemo(transferId: UInt64, inputId: UInt64): Bool {
        for (memo in selectionInputMemos) {
            if (memo.transferId == transferId && memo.inputId == inputId) { return true }
        }
        return false
    }

    private func rememberSelectionInput(transferId: UInt64, inputId: UInt64,
        sequence: UInt64, previousSequence: UInt64, expectedVersion: Int64,
        choiceRevision: Int64, anchorByte: Int64, focusByte: Int64, replacement: String,
        edit: CjguiTextSessionEdit): Unit {
        if (selectionInputMemos.size < 64) {
            selectionInputMemos.add(CjguiSelectionInputMemo(transferId, inputId, sequence,
                previousSequence, expectedVersion, choiceRevision, anchorByte, focusByte,
                replacement, edit))
        }
    }

    /// Experimental: issue a source-wide choice without reading its interior.
    /// Consumers must bind native events to this exact choice before using it;
    /// consulting the current choice from an old local input is never valid.
    public func selectWholeDocument(expectedVersion: Int64): ?CjguiWholeDocumentSelection {
        if (!this.bound || this.needsCalibration || this.compositionActive) {
            this.lastReason = if (!this.bound) { "session_unbound" } else {
                if (this.compositionActive) { "composition_busy" } else { "recalibration_required" }
            }
            return None
        }
        let total = this.window.confirmedWholeSourceLength(expectedVersion)
        if (total.isNone()) { this.lastReason = CJGUI_RANGE_TEXT_REASON_VERSION; return None }
        if (let Some(owner) <- this.window.selectionOwner()) {
            if (!owner.setSourceSelection(expectedVersion, 0, total.getOrThrow())) {
                this.lastReason = "source_selection_not_admitted"
                return None
            }
            this.refreshOwnerSelectionProjection()
        } else { this.selectionRevision += 1 }
        let issued = this.issueWholeDocumentChoice(expectedVersion, total.getOrThrow())
        this.selectionVersion = expectedVersion
        this.selectionStartByte = 0
        this.selectionEndByte = total.getOrThrow()
        // UTF-16 values below are a bounded feedback projection only.
        this.selStart16 = 0
        this.selEnd16 = this.mirrorUtf16Length
        this.selectionAnchor16 = 0
        this.selectionFocus16 = this.mirrorUtf16Length
        this.selectionNeedsNativeRestore = false
        this.lastReason = ""
        return Some(issued)
    }

    /// Read-only capability for a whole-document choice already committed by
    /// the owner/native selection decision. Does not make another selection.
    public func wholeDocumentChoiceForCurrentSelection(expectedVersion: Int64): ?CjguiWholeDocumentSelection {
        if (!this.bound || this.needsCalibration || this.compositionActive) { return None }
        this.refreshOwnerSelectionProjection()
        let owner = match (this.window.selectionOwner()) { case Some(value) => value; case None => return None }
        let selected = owner.sourceSelectionSnapshot()
        let total = this.window.confirmedWholeSourceLength(expectedVersion)
        if (total.isNone() || selected.version != expectedVersion || selected.revision != this.selectionRevision ||
            !((selected.anchorByte == 0 && selected.focusByte == total.getOrThrow()) ||
              (selected.focusByte == 0 && selected.anchorByte == total.getOrThrow()))) { return None }
        if (let Some(current) <- this.wholeDocumentChoice) {
            if (current.contentVersion == expectedVersion && current.byteLength == total.getOrThrow() &&
                current.contextEpoch == this.contextEpoch && current.selectionRevision == selected.revision) {
                return Some(current)
            }
        }
        return Some(this.issueWholeDocumentChoice(expectedVersion, total.getOrThrow()))
    }

    private func issueWholeDocumentChoice(expectedVersion: Int64, length: Int64): CjguiWholeDocumentSelection {
        this.wholeDocumentChoiceSequence += 1
        let context = this.contextEpoch
        let choice = this.wholeDocumentChoiceSequence
        let revision = this.selectionRevision
        let issued = CjguiWholeDocumentSelection(expectedVersion, length, context, revision, choice,
            { => this.wholeDocumentChoiceMatches(context, revision, choice, expectedVersion) },
            { text, nativeChanged =>
                this.submitWholeDocumentChoice(context, revision, choice, expectedVersion, length,
                    text, nativeChanged)
            })
        this.wholeDocumentChoice = Some(issued)
        return issued
    }

    private func wholeDocumentChoiceMatches(context: Int64, revision: Int64,
        choice: Int64, version: Int64): Bool {
        this.refreshOwnerSelectionProjection()
        let active = match (this.wholeDocumentChoice) { case Some(value) => value; case None => return false }
        return this.bound && context == this.contextEpoch && revision == this.selectionRevision &&
            active.choiceId == choice && !this.needsCalibration && !this.compositionActive &&
            this.window.sourceVersion() == version
    }

    private func submitWholeDocumentChoice(context: Int64, revision: Int64, choice: Int64,
        version: Int64, total: Int64, text: String, sourceProxyChanged: Bool): CjguiTextSessionEdit {
        if (!this.wholeDocumentChoiceMatches(context, revision, choice, version)) {
            this.lastReason = "whole_choice_stale"
            return this.edit(this.editSeq, false, -1, this.lastReason)
        }
        let priorMirror = this.mirrorRevision
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        let outcome = this.window.applyWholeSourceEdit(version, total, text)
        if (outcome.applied) {
            this.wholeDocumentChoice = None
            this.editSeq += 1
            let caretByte = cjguiUtf8Length(text)
            let _ = this.window.revealByte(caretByte)
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            let caret: ?Int64 = if (this.window.isPrepared() && this.window.contentVersion() == outcome.versionAfter) {
                cjguiUtf8OffsetToUtf16(this.window.text(), caretByte - this.window.windowStartByte())
            } else { None }
            if (let Some(caret16) <- caret) {
                this.setSelection16(caret16, caret16)
                this.selectionNeedsNativeRestore = !sourceProxyChanged
                this.lastReason = ""
            } else {
                this.retainUnprojectedSourceSelection(outcome.versionAfter, caretByte, caretByte,
                    "accepted_caret_unprepared")
            }
        } else {
            this.lastReason = outcome.reason
            if (sourceProxyChanged) {
                this.needsCalibration = true
                this.calibrationRecalibrated = false
            }
        }
        let decision = this.edit(this.editSeq, outcome.applied, outcome.versionAfter, this.lastReason, ticket)
        this.pending.add(CjguiTextSessionPending(ticket, priorMirror, decision,
            sourceProxyChanged: sourceProxyChanged))
        return decision
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
            { text, sourceProxyChanged, choiceIsCurrent =>
                return this.submitPreparedSourceRange(epoch, mirror, expectedVersion,
                    startByte, endByte, text, sourceProxyChanged, choiceIsCurrent)
            }))
    }

    private func submitPreparedSourceRange(epoch: Int64, mirror: Int64, expectedVersion: Int64,
        startByte: Int64, endByte: Int64, text: String,
        sourceProxyChanged: Bool, choiceIsCurrent: () -> Bool): CjguiTextSessionEdit {
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
        if (!choiceIsCurrent()) {
            this.lastReason = "selection_input_choice_stale"
            return this.edit(this.editSeq, false, this.window.sourceVersion(), this.lastReason)
        }
        this.ticketSeq += 1
        let ticket = this.ticketSeq
        let outcome = this.window.applyByteEdit(startByte, endByte, text)
        if (outcome.applied) {
            this.editSeq += 1
            // This is an accepted human range edit, so its new caret is the
            // consumed start plus inserted bytes. Rebasing the prior selection
            // is reserved for independent owner changes in refreshMirror.
            let caretByte = startByte + cjguiUtf8Length(text)
            let _ = this.window.revealByte(caretByte)
            this.mirrorRevision += 1
            this.mirrorUtf16Length = cjguiUtf16Length(this.window.text())
            let caret: ?Int64 = if (this.window.isPrepared() &&
                this.window.contentVersion() == outcome.versionAfter) {
                cjguiUtf8OffsetToUtf16(this.window.text(), caretByte - this.window.windowStartByte())
            } else { None }
            if (let Some(caret16) <- caret) {
                this.setSelection16(caret16, caret16)
                this.selectionNeedsNativeRestore = !sourceProxyChanged
                this.lastReason = ""
            } else {
                this.retainUnprojectedSourceSelection(outcome.versionAfter, caretByte, caretByte,
                    "accepted_caret_unprepared")
            }
            let accepted = this.edit(this.editSeq, true, outcome.versionAfter, this.lastReason, ticket)
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
        if (!this.selectionCoordinatesMatchMirror() || this.selectionNeedsNativeRestore) {
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
                this.retainUnprojectedSourceSelection(outcome.versionAfter, caretByte, caretByte,
                    "accepted_caret_unprepared")
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

    private func ignoredCompositionEvent(reason: String): CjguiTextSessionEdit {
        return CjguiTextSessionEdit(this.editSeq, -1, false, -1, this.mirrorRevision,
            this.contextEpoch, reason, proxyRecoveryRequired: false)
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
        if (this.calibrationRecalibrated && this.needsCalibration && this.selectionNeedsNativeRestore) {
            this.calibrationRecalibrated = this.selectionVersion == this.window.contentVersion() &&
                this.projectSourceSelection(this.selectionStartByte, this.selectionEndByte)
        }
        return this.calibrationRecalibrated
    }
}
