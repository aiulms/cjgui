package cjgui

import std.collection.*

// 1b 正常窗口消费链探针:平台输入服务 → 窗口 FIFO → controller → CjguiTextSession →
// 有界镜像 → 唯一 owner Sink。驱动方式是框架自己的 test-only 平台钩子,走的是产品
// AppKit 路径(NSTextInputClient 代理 → shouldChange/enqueue → pump → applyUiEvent),
// 所以这里证明的是**真实队列**,不是会话单测里的同步 Fake owner。
//
// 层级声明:合成平台驱动 ≠ 人工物理输入,也 ≠ 真实系统 IME 组字;它证明的是队列、
// 身份与校准契约在正常窗口里成立。
foreign {
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_delete_composable_text(session: UInt64, nodeIndex: UInt32): Int32
    // 组字相位的真实平台驱动。参数与生产代理收到的 NSTextInputClient 参数一一对应:
    // marked 文本 + 相对 preedit 的内部选区 + 替换范围(-1 = NSNotFound)、unmarkText
    // (AppKit 定义为"接受预编辑")、取消形态(空 marked)、组合前的选区落点。
    func cjgui_internal_renderer_test_set_composable_marked_text_ex(
        session: UInt64, nodeIndex: UInt32, text: CString, innerStart: UInt32, innerEnd: UInt32,
        replacementStart: Int64, replacementLength: Int64
    ): Int32
    func cjgui_internal_renderer_test_unmark_composable_marked_text(session: UInt64): Int32
    func cjgui_internal_renderer_test_cancel_composable_marked_text(session: UInt64): Int32
    func cjgui_internal_renderer_test_commit_composable_marked_text(session: UInt64, text: CString): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
}

/// 独立纯文本 owner:普通字节数组 + 版本,读有界、写只经 Sink。
private class SessionPlainStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private var bytes: Array<Byte>
    private var version: Int64 = 1
    private var conflictNext: Bool = false
    var sinkCalls: Int64 = 0
    var ownerWrites: Int64 = 0
    var lastStart: Int64 = -1
    var lastEnd: Int64 = -1
    /// 到达 Sink 的每个**绝对文档字节**范围(按队列顺序)。窗口拥有会话后,消费方看不到
    /// 平台的 UTF-16 坐标,这条痕迹就是"两键一投、坐标逐键前进"的证据。
    var sinkTrace: String = ""

    init(text: String) {
        this.bytes = text.toArray()
    }

    public func text(): String {
        return String.fromUtf8(this.bytes)
    }

    public func armConflict(): Unit {
        this.conflictNext = true
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

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (fromVersion == this.rangeTextVersion() && startByte >= 0 &&
            endByte >= startByte && endByte <= this.rangeTextByteLength()) {
            return Some((fromVersion, startByte, endByte))
        }
        return None
    }

    public func rangeTextByteLength(): Int64 {
        return Int64(this.bytes.size)
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
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
        return CjguiRangeTextSlice(startByte, aligned,
            String.fromUtf8(this.bytes.slice(aligned, end - aligned)), this.version, size, end == size,
            if (end == size) { "" } else { "window_truncated" })
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        this.sinkCalls += 1
        this.sinkTrace += " ${startByte}:${endByte}"
        if (this.conflictNext) {
            this.conflictNext = false
            this.noteIntent(baseVersion, startByte, endByte, inserted, "armed_conflict")
            return CjguiRangeTextEditOutcome.conflict(this.version, "armed_conflict")
        }
        if (baseVersion != this.version) {
            this.noteIntent(baseVersion, startByte, endByte, inserted, "stale_base")
            return CjguiRangeTextEditOutcome.conflict(this.version, "stale_base")
        }
        // 从这里开始 owner 真的改正文:`ownerWrites` 只数正文写入,`sinkCalls` 数到达
        // Sink 的意图(含具名拒绝)。拒绝时两者必须分开,否则看不出锁是否挡住写入。
        this.ownerWrites += 1
        this.lastStart = startByte
        this.lastEnd = endByte
        let work = ArrayList<Byte>()
        work.add(all: this.bytes)
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
        this.noteIntent(baseVersion, startByte, endByte, inserted, "")
        return CjguiRangeTextEditOutcome.accepted(before, this.version)
    }

    /// owner 侧的唯一写入痕迹:每个到达 Sink 的意图一行,带绝对字节范围与判决。
    /// 会话内部的具名拒绝(校准锁、越界、组字占位)根本不到这里,所以这行只可能是
    /// "owner 接受"或"owner 冲突",两类事件的区分正靠它。
    private func noteIntent(baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String,
        refusal: String): Unit {
        println("CJGUI_SESSION_SINK bytes=${startByte}:${endByte} inserted_bytes=${inserted.toArray().size} " +
            "base_version=${baseVersion} owner_version=${this.version} call=${this.sinkCalls} " +
            "writes=${this.ownerWrites} refusal=${refusal}")
    }
}

private class TextSessionController <: CjguiComposableUiController {
    private let store: SessionPlainStore
    /// 1b:镜像与会话由**窗口**拥有。消费方只交出 owner 的读/写接缝,并保留只读查询
    /// 句柄;它既没有第二条正文写入路径,也不在 `buildUi` 里轮询恢复回执。
    private var host: Option<CjguiComposableUiWindow> = None
    private var session: Option<CjguiTextSession> = None
    private var lastPrintedTicket: Int64 = -2
    var fullValueEvents: Int64 = 0
    /// 窗口拥有会话后仍到达 owner 的范围意图数。必须恒为 0:非零即第二条写入路径复活。
    var leakedRangeEvents: Int64 = 0
    /// 最近一次整值(28)载荷 = native 代理当时的正文。用它区分"代理真的在上报的
    /// 偏移处插入了"和"偏移是旧投影的坐标"。
    var lastFullValue: String = ""
    var lastFullCaret: Int64 = -1

    init(initialText: String) {
        this.store = SessionPlainStore(initialText)
    }

    /// 由窗口建立并拥有会话;返回值只供消费方做只读查询(选区/组合/校准状态)。
    public func attach(window: CjguiComposableUiWindow): CjguiTextSession {
        this.host = Some(window)
        let bound = window.bindRangeTextSession(2, "text-session", this.store, this.store, 42,
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, materializeLimit: 4096)
        this.session = Some(bound)
        return bound
    }

    public func uiSceneVersion(): Int64 {
        // 会话写入不经 `applyUiEvent`,所以声明场景的版本必须跟着**正文**走:
        // owner 每接受一笔写入,消费方声明的场景就换代一次。
        return 1 + this.store.ownerWrites
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "text-session-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        // 正文节点的值 = 窗口拥有的会话镜像:投影与判决同源,native 代理不会再拿会话
        // 没见过的长度。恢复回执由窗口在回滚代理后自己交回会话,这里不轮询、不自签自认。
        let mirror = this.mirrorText()
        root.add(cjguiComposableMultilineTextInput(2, "text-session-body", "", mirror, 42,
            CjguiComposableUiStyle(fixedHeight: 180), tabInsertsText: true))
        this.reportWindowDecision(mirror)
        return root
    }

    /// 判决证据来自**窗口**(它拥有会话),按票据去重:同一笔判决不因多次投影重复打印。
    private func reportWindowDecision(mirror: String): Unit {
        let window = match (this.host) {
            case Some(host) => host
            case None => return
        }
        let decision = match (window.textSessionLastDecision()) {
            case Some(edit) => edit
            case None => return
        }
        if (decision.ticket == this.lastPrintedTicket) {
            return
        }
        this.lastPrintedTicket = decision.ticket
        println("CJGUI_SESSION_DECISION seq=${decision.seq} ticket=${decision.ticket} " +
            "accepted=${decision.accepted} reason=${decision.reason} epoch=${decision.contextEpoch} " +
            "mirror=${decision.mirrorRevision} version_after=${decision.versionAfter} " +
            "decisions=${window.textSessionRangeDecisionCount()} accepted_total=${window.textSessionAcceptedCount()} " +
            "refused_total=${window.textSessionRefusedCount()} restores=${window.textSessionRestoreCount()} " +
            "restore_failures=${window.textSessionRestoreFailureCount()} calibrating=${this.isCalibrating()} " +
            "mirror_bytes=${mirror.toArray().size} owner_bytes=${this.store.text().toArray().size}")
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED && event.node.nodeId == 2) {
            // 退役判据:窗口拥有会话后,该节点的范围意图由窗口路由给会话,不再到达 owner。
            // 到达即第二条写入路径复活(或路由失效),显式记账并失败,不静默判决。
            this.leakedRangeEvents += 1
            println("CJGUI_SESSION_LEAK utf16=${event.selectionStart}:${event.selectionEnd} " +
                "inserted_bytes=${event.text.toArray().size}")
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.nodeId == 2) {
            // 会话绑定的节点只接受范围意图;整值事件记录但不消费(退役判据:一意图一票据一判决)。
            this.fullValueEvents += 1
            this.lastFullValue = event.text
            this.lastFullCaret = event.selectionStart
            return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func armConflict(): Unit {
        this.store.armConflict()
    }

    public func ownerText(): String {
        return this.store.text()
    }

    public func mirrorText(): String {
        return match (this.host) {
            case Some(window) => window.textSessionMirrorText()
            case None => ""
        }
    }

    public func isCalibrating(): Bool {
        return match (this.session) {
            case Some(session) => session.awaitingCalibration()
            case None => false
        }
    }

    public func pendingCount(): Int64 {
        return match (this.session) {
            case Some(session) => session.pendingCount()
            case None => -1
        }
    }

    // ---- 判决证据一律取自窗口:它拥有会话,消费方不再自己数 ----

    public func rangeEvents(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionRangeDecisionCount()
            case None => -1
        }
    }

    public func acceptedEdits(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionAcceptedCount()
            case None => -1
        }
    }

    public func refusedEdits(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionRefusedCount()
            case None => -1
        }
    }

    public func restoredContexts(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionRestoreCount()
            case None => -1
        }
    }

    public func restoreFailures(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionRestoreFailureCount()
            case None => -1
        }
    }

    public func lastSeq(): Int64 {
        return match (this.session) {
            case Some(session) => session.currentEditSeq()
            case None => -1
        }
    }

    public func lastReason(): String {
        return match (this.session) {
            case Some(session) => session.lastRejectReason()
            case None => ""
        }
    }

    /// 判决快照里的具名原因。与会话的 `lastRejectReason()` 不同,它不会被随后成功的
    /// 恢复回执清空 —— 用例要断言的是"那一笔为什么被拒",不是"会话现在有没有原因"。
    public func lastDecisionReason(): String {
        let window = match (this.host) {
            case Some(host) => host
            case None => return ""
        }
        return match (window.textSessionLastDecision()) {
            case Some(decision) => decision.reason
            case None => ""
        }
    }

    public func lastDecisionTicket(): Int64 {
        let window = match (this.host) {
            case Some(host) => host
            case None => return -1
        }
        return match (window.textSessionLastDecision()) {
            case Some(decision) => decision.ticket
            case None => -1
        }
    }

    public func rangeTrace(): String {
        return this.store.sinkTrace
    }

    public func sinkCalls(): Int64 {
        return this.store.sinkCalls
    }

    public func ownerWrites(): Int64 {
        return this.store.ownerWrites
    }

    public func sinkStart(): Int64 {
        return this.store.lastStart
    }

    public func sinkEnd(): Int64 {
        return this.store.lastEnd
    }

    // ---- 组字状态一律取自窗口拥有的会话与窗口自己的判决计数 ----

    public func hasComposition(): Bool {
        return match (this.session) {
            case Some(session) => session.hasComposition()
            case None => false
        }
    }

    public func compositionText(): String {
        return match (this.session) {
            case Some(session) => session.compositionText()
            case None => ""
        }
    }

    public func markedRange(): (Int64, Int64) {
        return match (this.session) {
            case Some(session) => session.markedRange16()
            case None => (-1, 0)
        }
    }

    public func markedInner(): (Int64, Int64) {
        return match (this.session) {
            case Some(session) => session.markedInnerSelection16()
            case None => (0, 0)
        }
    }

    /// 组合基版本。冻结后必须跨重绘与后续 marked 更新保持不变:中途重取会让过时的
    /// 替换范围被标上新基版本。
    public func compositionBaseVersion(): Int64 {
        return match (this.session) {
            case Some(session) => session.compositionBaseVersionValue()
            case None => -1
        }
    }

    public func compositionDecisions(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionCompositionDecisionCount()
            case None => -1
        }
    }

    public func compositionRefusals(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionCompositionRefusalCount()
            case None => -1
        }
    }

    public func staleCompositionRefusals(): Int64 {
        return match (this.host) {
            case Some(window) => window.textSessionCompositionStaleRefusalCount()
            case None => -1
        }
    }

    public func lastCompositionReason(): String {
        return match (this.host) {
            case Some(window) => window.textSessionLastCompositionReason()
            case None => ""
        }
    }
}

private func insertText(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_insert_composable_text(window.testSessionToken(), 1u32, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func deleteBackward(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_delete_composable_text(window.testSessionToken(), 1u32)
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func selectRange(window: CjguiComposableUiWindow, start: UInt32, end: UInt32): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_set_composable_selection(
            window.testSessionToken(), 1u32, start, end
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func setMarkedEx(window: CjguiComposableUiWindow, text: String, innerStart: UInt32,
    innerEnd: UInt32, replacementStart: Int64, replacementLength: Int64): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_set_composable_marked_text_ex(window.testSessionToken(), 1u32,
                textResource.value, innerStart, innerEnd, replacementStart, replacementLength)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func commitMarked(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_commit_composable_marked_text(
                window.testSessionToken(), textResource.value
            )
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func unmarkMarked(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_unmark_composable_marked_text(window.testSessionToken())
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func cancelMarked(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_cancel_composable_marked_text(window.testSessionToken())
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func pumpOnce(window: CjguiComposableUiWindow): Unit {
    let _ = window.pump(4u32)
}

private func settle(window: CjguiComposableUiWindow): Bool {
    var i: Int64 = 0
    while (i < 8) {
        pumpOnce(window)
        i += 1
    }
    return window.isOpen()
}

private func report(name: String, ok: Bool, detail: String): Bool {
    println("CJGUI_SESSION_CASE ${name} passed=${ok} ${detail}")
    return ok
}

private func runSessionProbe(): Bool {
    let controller = TextSessionController("ab")
    let configuration = CjguiMacosApplicationWindowConfiguration(
        "CJGUI Text Session Probe", 760u32, 460u32, rangeTextEditDeltaDelivery: true)
    let window = CjguiComposableUiWindow(controller, configuration: configuration)
    // 1b:窗口建立并拥有会话与有界镜像;消费方只交出 owner 的读/写接缝。必须在 start
    // 之前绑定,首次投影发布的正文才是镜像而不是消费方自己的字符串。
    let session = controller.attach(window)
    if (!window.start()) {
        println("CJGUI_SESSION_RESULT start_failed=true")
        return false
    }
    if (session.boundNode() != 2 || !session.isBound() || window.textSessionMirrorText() != "ab") {
        println("CJGUI_SESSION_RESULT session_bind_failed=true node=${session.boundNode()} " +
            "bound=${session.isBound()} mirror=${window.textSessionMirrorText()}")
        window.close()
        return false
    }
    if (!window.isTextRangeEditDeltaDeliveryEnabled()) {
        println("CJGUI_SESSION_RESULT delta_delivery_off=true")
        window.close()
        return false
    }
    if (!settle(window)) {
        println("CJGUI_SESSION_RESULT settle_failed=true")
        window.close()
        return false
    }
    var passed = true

    // 1. 计划确定性反例:`ab` 在同一次 pump 之前连续输入 X、Y ⇒ 两笔事务、owner = abXY。
    //    两次驱动之间不 settle ⇒ 两条 51 都留在平台 FIFO 里,由同一轮队列消费。
    let sinkBefore = controller.sinkCalls()
    let d1 = insertText(window, "X")
    let d2 = insertText(window, "Y")
    let settled = settle(window)
    passed = report("two_edits_before_one_pump",
        d1 && d2 && settled && controller.acceptedEdits() == 2 && controller.rangeEvents() == 2 &&
            controller.ownerText() == "abXY" && controller.sinkCalls() == sinkBefore + 2 &&
            controller.lastSeq() == 2 && controller.pendingCount() == 0 &&
            controller.leakedRangeEvents == 0 &&
            // 坐标必须逐键前进:第二键落在第一键之后,而不是被折回旧投影长度。
            controller.rangeTrace() == " 2:2 3:3",
        "drives=${d1}/${d2} accepted=${controller.acceptedEdits()} range_events=${controller.rangeEvents()} " +
        "ranges=${controller.rangeTrace()} last_seq=${controller.lastSeq()} sink_calls=${controller.sinkCalls()} " +
        "owner=${controller.ownerText()} pending=${controller.pendingCount()} " +
        "leaked=${controller.leakedRangeEvents}") && passed

    // 2. 同一队列里的非 ASCII:中文与 emoji 必须按 UTF-16 范围映射到绝对字节再写。
    //    `abXY` = 4 字节,`中` 占 3 字节,😀 占 4 字节。
    let cjkSink = controller.sinkCalls()
    passed = report("cjk_and_emoji_through_real_queue",
        insertText(window, "中") && settle(window) && controller.ownerText() == "abXY中" &&
            controller.sinkStart() == 4 && controller.sinkEnd() == 4 &&
            insertText(window, "😀") && settle(window) && controller.ownerText() == "abXY中😀" &&
            controller.sinkStart() == 7 && controller.sinkEnd() == 7 &&
            controller.sinkCalls() == cjkSink + 2,
        "owner=${controller.ownerText()} sink=${controller.sinkStart()}:${controller.sinkEnd()} " +
        "sink_calls=${controller.sinkCalls()}") && passed

    // 3. 删除整个 emoji 字素簇:UTF-16 范围 5:7 ⇒ 文档字节 7:11。
    let delSink = controller.sinkCalls()
    passed = report("delete_removes_whole_emoji_cluster",
        deleteBackward(window) && settle(window) && controller.ownerText() == "abXY中" &&
            controller.sinkStart() == 7 && controller.sinkEnd() == 11 &&
            controller.sinkCalls() == delSink + 1,
        "owner=${controller.ownerText()} sink=${controller.sinkStart()}:${controller.sinkEnd()}") && passed

    // 4. owner 拒绝 ⇒ 会话持校准锁。锁必须挡住**同一轮里紧随其后**的意图:人在
    //    一次投影之前连打两键,Q 被 owner 拒掉后代理与 accepted 正文已经分叉,R 的
    //    坐标属于分叉后的代理,继续写就会把不该存在的字符钉进正文。
    let ownerBeforeRefusal = controller.ownerText()
    let writesBeforeRefusal = controller.ownerWrites()
    let seqBeforeRefusal = controller.lastSeq()
    let refusalsBeforeRefusal = controller.refusedEdits()
    controller.armConflict()
    let qDrive = insertText(window, "Q")
    let rDrive = insertText(window, "R")
    // 两笔意图一起进入队列:第一笔具名拒绝并上锁,第二笔在锁内被拒绝且不碰正文。
    let refusedDrive = qDrive && rDrive && settle(window)
    let blockedReason = controller.lastDecisionReason()
    let blockedTicket = controller.lastDecisionTicket()
    let blockedSeq = controller.lastSeq()
    let writesWhileLocked = controller.ownerWrites()
    passed = report("owner_refusal_locks_the_session",
        refusedDrive && ownerBeforeRefusal == "abXY中" && controller.ownerText() == ownerBeforeRefusal &&
            seqBeforeRefusal > 0 && blockedSeq == seqBeforeRefusal &&
            controller.refusedEdits() == refusalsBeforeRefusal + 2 && blockedReason == "recalibration_required" &&
            blockedTicket == -1 && writesWhileLocked == writesBeforeRefusal,
        "refused_drive=${refusedDrive} refused=${controller.refusedEdits()} reason=${blockedReason} " +
        "ticket=${blockedTicket} owner=${controller.ownerText()} owner_writes=${writesWhileLocked} " +
        "seq=${blockedSeq}") && passed

    // 5. 窗口回滚代理之后,由**窗口自己**把会话签发的恢复回执交回会话解锁;消费方一次
    //    也没有轮询过 `confirmProxyRestored`,锁内积压的意图也不会重放。
    let released = !controller.isCalibrating()
    let recovered = insertText(window, "S") && settle(window)
    passed = report("restore_receipt_reopens_input",
        released && recovered && controller.restoredContexts() >= 1 && controller.restoreFailures() == 0 &&
            window.refusedRangeTextRecoveryCount() >= 1 && window.refusedRangeTextFailureCount() == 0 &&
            controller.ownerText() == ownerBeforeRefusal + "S" &&
            controller.mirrorText() == controller.ownerText(),
        "released=${released} recovered=${recovered} restored=${controller.restoredContexts()} " +
        "restore_failures=${controller.restoreFailures()} owner=${controller.ownerText()} " +
        "mirror_equal=${controller.mirrorText() == controller.ownerText()} reason=${controller.lastReason()} " +
        "recovery_events=${window.refusedRangeTextRecoveryCount()} " +
        "recovery_failures=${window.refusedRangeTextFailureCount()}") && passed

    // 6. 退役判据(可执行):每次平台意图恰好一个票据一个判决;正文只由被接受的
    //    范围意图写入 —— 整值(28)事件确实到达过,但一次也没有成为第二次写入;
    //    范围意图一次也没有漏到 owner 的 `applyUiEvent`(第二条写入路径已退役)。
    let decisions = controller.acceptedEdits() + controller.refusedEdits()
    passed = report("single_write_path_per_intent",
        decisions == controller.rangeEvents() && controller.rangeEvents() > 0 &&
            controller.fullValueEvents >= controller.rangeEvents() &&
            controller.ownerWrites() == controller.acceptedEdits() &&
            controller.leakedRangeEvents == 0,
        "range_events=${controller.rangeEvents()} decisions=${decisions} accepted=${controller.acceptedEdits()} " +
        "refused=${controller.refusedEdits()} full_value_events=${controller.fullValueEvents} " +
        "owner_writes=${controller.ownerWrites()} leaked=${controller.leakedRangeEvents}") && passed

    // ---- kind 52 组字相位:平台 preedit 只在代理显示,正文只由被接受的相位写入 ----

    // 7. 组字开始:首次 setMarkedText 的替换范围为 NSNotFound ⇒ 解析为当前选区并被
    //    会话**冻结**;预编辑不进正文、不进撤销栈、镜像不动,窗口按相位判决。
    let composeSelect = selectRange(window, 6, 6)
    let compositionSinkBase = controller.sinkCalls()
    let compositionAcceptedBase = controller.acceptedEdits()
    // 正文写入的独立计量：组字相位不进范围意图的 accepted/refused 账，提交到底写没写
    // 由 owner 自己的写入痕迹证明，不被窗口计数口径变化影响。
    let compositionOwnerWritesBase = controller.ownerWrites()
    // 组字全程 owner 一次整值事件都不能收到:preedit 期间与终局 super 调用内的
    // 存储变化都必须被 native 侧抑制,否则会以第二条写入路径的形式到达 owner。
    let compositionFullValueBase = controller.fullValueEvents
    let updateFirst = setMarkedEx(window, "ni", 2, 2, -1, 0)
    let firstSettled = settle(window)
    let (firstMarkedStart, firstMarkedLength) = controller.markedRange()
    let (firstInnerAnchor, firstInnerFocus) = controller.markedInner()
    let frozenBaseVersion = controller.compositionBaseVersion()
    passed = report("composition_update_is_not_a_domain_write",
        composeSelect && updateFirst && firstSettled && controller.hasComposition() &&
            controller.compositionText() == "ni" &&
            firstMarkedStart == 6 && firstMarkedLength == 2 &&
            firstInnerAnchor == 2 && firstInnerFocus == 2 && frozenBaseVersion >= 1 &&
            controller.ownerText() == "abXY中S" && controller.mirrorText() == "abXY中S" &&
            controller.sinkCalls() == compositionSinkBase &&
            controller.acceptedEdits() == compositionAcceptedBase &&
            controller.compositionDecisions() == 1 && controller.compositionRefusals() == 0 &&
            controller.staleCompositionRefusals() == 0 &&
            controller.lastCompositionReason() == "accepted" && controller.pendingCount() == 0 &&
            controller.fullValueEvents == compositionFullValueBase &&
            controller.leakedRangeEvents == 0,
        "select=${composeSelect} update=${updateFirst} settled=${firstSettled} " +
        "composition=${controller.hasComposition()}/${controller.compositionText()} " +
        "marked=${firstMarkedStart}:${firstMarkedLength} inner=${firstInnerAnchor}:${firstInnerFocus} " +
        "base_version=${frozenBaseVersion} owner=${controller.ownerText()} " +
        "sink_calls=${controller.sinkCalls()} decisions=${controller.compositionDecisions()} " +
        "refusals=${controller.compositionRefusals()} reason=${controller.lastCompositionReason()} " +
        "writes=${controller.ownerWrites()} pending=${controller.pendingCount()}") && passed

    // 8. 重绘不清除 preedit,也不重取基版本:后续 marked 更新报的是**代理里当前的
    //    marked 范围**(起点与冻结起点一致、长度为旧 preedit 长度),会话只更新草稿
    //    与内部选区;冻结的替换范围到提交时仍然是开始的选区。
    let redraw = window.refresh()
    let redrawSettled = settle(window)
    let redrawKept = controller.hasComposition() && controller.compositionText() == "ni" &&
        controller.compositionBaseVersion() == frozenBaseVersion &&
        controller.compositionDecisions() == 1 && controller.ownerText() == "abXY中S"
    let updateSecond = setMarkedEx(window, "nih", 3, 3, -1, 0)
    let secondSettled = settle(window)
    let (secondMarkedStart, secondMarkedLength) = controller.markedRange()
    let (secondInnerAnchor, secondInnerFocus) = controller.markedInner()
    passed = report("redraw_keeps_frozen_composition_range",
        redraw && redrawSettled && redrawKept && updateSecond && secondSettled &&
            controller.hasComposition() && controller.compositionText() == "nih" &&
            secondMarkedStart == 6 && secondMarkedLength == 3 &&
            secondInnerAnchor == 3 && secondInnerFocus == 3 &&
            controller.compositionBaseVersion() == frozenBaseVersion &&
            controller.ownerText() == "abXY中S" && controller.sinkCalls() == compositionSinkBase &&
            controller.compositionDecisions() == 2 && controller.compositionRefusals() == 0 &&
            controller.lastCompositionReason() == "accepted" && controller.pendingCount() == 0,
        "redraw=${redraw}/${redrawSettled}/${redrawKept} update=${updateSecond} " +
        "settled=${secondSettled} composition=${controller.compositionText()} " +
        "marked=${secondMarkedStart}:${secondMarkedLength} inner=${secondInnerAnchor}:${secondInnerFocus} " +
        "base_version=${controller.compositionBaseVersion()} frozen=${frozenBaseVersion} " +
        "owner=${controller.ownerText()} decisions=${controller.compositionDecisions()} " +
        "reason=${controller.lastCompositionReason()}") && passed

    // 9. 提交走**冻结范围**而不是平台报的 marked 范围:平台报 6+3(代理里的 preedit
    //    落点),"abXY中S" 只有 6 个 UTF-16;若按平台坐标写就会替换掉 "S"。冻结的
    //    (6,0) 让 "nih" 落在文档字节 8:8 —— 一次事务,正文 abXY中Snih。
    let commitDrive = commitMarked(window, "nih")
    let commitSettled = settle(window)
    passed = report("commit_writes_frozen_range_once",
        commitDrive && commitSettled && !controller.hasComposition() &&
            controller.ownerText() == "abXY中Snih" && controller.mirrorText() == controller.ownerText() &&
            controller.sinkStart() == 8 && controller.sinkEnd() == 8 &&
            controller.sinkCalls() == compositionSinkBase + 1 &&
            controller.acceptedEdits() == compositionAcceptedBase &&
            controller.ownerWrites() == compositionOwnerWritesBase + 1 &&
            controller.compositionDecisions() == 3 && controller.compositionRefusals() == 0 &&
            controller.lastCompositionReason() == "accepted" && controller.pendingCount() == 0 &&
            controller.fullValueEvents == compositionFullValueBase &&
            controller.leakedRangeEvents == 0 && controller.fullValueEvents >= controller.rangeEvents(),
        "commit=${commitDrive} settled=${commitSettled} composition=${controller.hasComposition()} " +
        "owner=${controller.ownerText()} sink=${controller.sinkStart()}:${controller.sinkEnd()} " +
        "sink_calls=${controller.sinkCalls()} accepted=${controller.acceptedEdits()} " +
        "writes=${controller.ownerWrites()} " +
        "decisions=${controller.compositionDecisions()} reason=${controller.lastCompositionReason()}") && passed

    // 10. 取消形态(空 marked)是零事务:草稿丢弃,正文、撤销栈、Sink 全不动。
    let cancelStart = setMarkedEx(window, "hao", 3, 3, -1, 0) && settle(window)
    let cancelDrive = cancelMarked(window)
    let cancelSettled = settle(window)
    passed = report("cancel_composition_writes_nothing",
        cancelStart && cancelDrive && cancelSettled && !controller.hasComposition() &&
            controller.compositionText() == "" && !controller.isCalibrating() &&
            controller.ownerText() == "abXY中Snih" && controller.sinkCalls() == compositionSinkBase + 1 &&
            controller.acceptedEdits() == compositionAcceptedBase &&
            controller.ownerWrites() == compositionOwnerWritesBase + 1 &&
            controller.compositionDecisions() == 5 && controller.compositionRefusals() == 0 &&
            controller.lastCompositionReason() == "composition_cancel" &&
            controller.fullValueEvents == compositionFullValueBase &&
            controller.pendingCount() == 0 && controller.leakedRangeEvents == 0,
        "start=${cancelStart} cancel=${cancelDrive} settled=${cancelSettled} " +
        "composition=${controller.hasComposition()} calibrating=${controller.isCalibrating()} " +
        "owner=${controller.ownerText()} sink_calls=${controller.sinkCalls()} " +
        "decisions=${controller.compositionDecisions()} reason=${controller.lastCompositionReason()} " +
        "writes=${controller.ownerWrites()}") && passed

    // 11. unmarkText 是 AppKit 定义的"接受预编辑":一次提交把 preedit 落成正文,
    //     仍然按冻结范围写,且不产生取消 + 普通编辑的两笔事件。
    let unmarkStart = setMarkedEx(window, "ni", 2, 2, -1, 0) && settle(window)
    let unmarkDrive = unmarkMarked(window)
    let unmarkSettled = settle(window)
    passed = report("unmark_commits_preedit_once",
        unmarkStart && unmarkDrive && unmarkSettled && !controller.hasComposition() &&
            controller.ownerText() == "abXY中Snihni" && controller.mirrorText() == controller.ownerText() &&
            controller.sinkStart() == 11 && controller.sinkEnd() == 11 &&
            controller.sinkCalls() == compositionSinkBase + 2 &&
            controller.acceptedEdits() == compositionAcceptedBase &&
            controller.ownerWrites() == compositionOwnerWritesBase + 2 &&
            controller.compositionDecisions() == 7 && controller.compositionRefusals() == 0 &&
            controller.lastCompositionReason() == "accepted" && controller.pendingCount() == 0 &&
            controller.fullValueEvents == compositionFullValueBase &&
            controller.leakedRangeEvents == 0,
        "start=${unmarkStart} unmark=${unmarkDrive} settled=${unmarkSettled} " +
        "composition=${controller.hasComposition()} owner=${controller.ownerText()} " +
        "sink=${controller.sinkStart()}:${controller.sinkEnd()} sink_calls=${controller.sinkCalls()} " +
        "decisions=${controller.compositionDecisions()} reason=${controller.lastCompositionReason()} " +
        "writes=${controller.ownerWrites()}") && passed

    // 12. 平台报出一个属于**另一段**的显式替换范围(起点 ≠ 冻结起点):会话具名拒绝
    //     并持校准锁;窗口取消 native 组合、按有界回滚把代理恢复到 accepted 正文,
    //     再把会话签发的回执交回解锁。之后同一节点照常可写。
    let recoveriesBeforeForeign = window.refusedRangeTextRecoveryCount()
    let selectForForeign = selectRange(window, 11, 11) && settle(window)
    let foreignStart = setMarkedEx(window, "ni", 2, 2, -1, 0) && settle(window)
    let foreignDrive = setMarkedEx(window, "sh", 2, 2, 5, 2)
    let foreignSettled = settle(window)
    let foreignReason = controller.lastDecisionReason()
    passed = report("foreign_replacement_range_is_refused_and_recovered",
        selectForForeign && foreignStart && foreignDrive && foreignSettled &&
            foreignReason == "composition_range_changed" && controller.compositionRefusals() == 1 &&
            controller.staleCompositionRefusals() == 0 && !controller.hasComposition() &&
            !controller.isCalibrating() && controller.compositionDecisions() == 10 &&
            controller.ownerText() == "abXY中Snihni" &&
            controller.mirrorText() == controller.ownerText() &&
            controller.sinkCalls() == compositionSinkBase + 2 &&
            controller.acceptedEdits() == compositionAcceptedBase &&
            controller.ownerWrites() == compositionOwnerWritesBase + 2 &&
            window.refusedRangeTextRecoveryCount() == recoveriesBeforeForeign + 1 &&
            window.refusedRangeTextFailureCount() == 0 && controller.pendingCount() == 0 &&
            controller.leakedRangeEvents == 0,
        "select=${selectForForeign} start=${foreignStart} foreign=${foreignDrive} " +
        "settled=${foreignSettled} reason=${foreignReason} refusals=${controller.compositionRefusals()} " +
        "stale=${controller.staleCompositionRefusals()} composition=${controller.hasComposition()} " +
        "calibrating=${controller.isCalibrating()} decisions=${controller.compositionDecisions()} " +
        "owner=${controller.ownerText()} sink_calls=${controller.sinkCalls()} " +
        "writes=${controller.ownerWrites()} " +
        "recoveries=${window.refusedRangeTextRecoveryCount()} " +
        "recovery_failures=${window.refusedRangeTextFailureCount()} pending=${controller.pendingCount()}") && passed

    // 拒绝链的出口:解锁后同一节点照常接受普通输入(工具链没有被锁死在拒绝态)。
    let resumeSelect = selectRange(window, 11, 11)
    let resumeEdit = insertText(window, "!") && settle(window)
    passed = report("refused_composition_leaves_session_writable",
        resumeSelect && resumeEdit && controller.ownerText() == "abXY中Snihni!" &&
            controller.sinkStart() == 13 && controller.sinkEnd() == 13 &&
            controller.sinkCalls() == compositionSinkBase + 3 && !controller.isCalibrating() &&
            controller.ownerWrites() == compositionOwnerWritesBase + 3 &&
            controller.pendingCount() == 0,
        "select=${resumeSelect} edit=${resumeEdit} owner=${controller.ownerText()} " +
        "sink=${controller.sinkStart()}:${controller.sinkEnd()} " +
        "sink_calls=${controller.sinkCalls()} writes=${controller.ownerWrites()} " +
        "calibrating=${controller.isCalibrating()}") && passed

    // 13. 换绑代次:换绑前入队的组字相位属于旧会话,窗口必须按代次具名消费;新会话
    //     不继承旧草稿与旧坐标,也不允许旧 preedit 经普通路径落到新镜像上。
    let rebindSinkBase = controller.sinkCalls()
    let staleSelect = selectRange(window, 12, 12)
    let staleDrive = setMarkedEx(window, "late", 4, 4, -1, 0)
    let rebound = controller.attach(window)
    let rebindSettled = settle(window)
    let staleConsumed = controller.staleCompositionRefusals()
    passed = report("rebind_consumes_stale_composition",
        staleSelect && staleDrive && rebindSettled && !session.isBound() && rebound.isBound() &&
            rebound.boundNode() == 2 && !controller.hasComposition() &&
            controller.compositionDecisions() == 0 && controller.compositionRefusals() == 0 &&
            staleConsumed == 2 && controller.ownerText() == "abXY中Snihni!" &&
            controller.sinkCalls() == rebindSinkBase && controller.pendingCount() == 0 &&
            controller.leakedRangeEvents == 0,
        "select=${staleSelect} stale_drive=${staleDrive} settled=${rebindSettled} " +
        "old_bound=${session.isBound()} new_bound=${rebound.isBound()}/${rebound.boundNode()} " +
        "composition=${controller.hasComposition()} decisions=${controller.compositionDecisions()} " +
        "refusals=${controller.compositionRefusals()} stale=${staleConsumed} " +
        "owner=${controller.ownerText()} sink_calls=${controller.sinkCalls()} " +
        "pending=${controller.pendingCount()}") && passed

    // 换绑后的新会话必须完整可用:同样的组字 → 提交链在新代次上重新成立。
    let freshSelect = selectRange(window, 12, 12)
    let freshUpdate = setMarkedEx(window, "xin", 3, 3, -1, 0) && settle(window)
    let freshMarked = controller.hasComposition() && controller.compositionText() == "xin"
    let freshCommit = commitMarked(window, "xin") && settle(window)
    passed = report("rebound_session_composes_and_commits",
        freshSelect && freshUpdate && freshMarked && freshCommit &&
            controller.ownerText() == "abXY中Snihni!xin" &&
            controller.mirrorText() == controller.ownerText() &&
            controller.sinkStart() == 14 && controller.sinkEnd() == 14 &&
            controller.sinkCalls() == rebindSinkBase + 1 && !controller.hasComposition() &&
            controller.compositionDecisions() == 2 && controller.compositionRefusals() == 0 &&
            controller.staleCompositionRefusals() == 2 && controller.pendingCount() == 0 &&
            controller.leakedRangeEvents == 0,
        "select=${freshSelect} update=${freshUpdate} marked=${freshMarked} commit=${freshCommit} " +
        "owner=${controller.ownerText()} sink=${controller.sinkStart()}:${controller.sinkEnd()} " +
        "sink_calls=${controller.sinkCalls()} decisions=${controller.compositionDecisions()} " +
        "refusals=${controller.compositionRefusals()} stale=${controller.staleCompositionRefusals()}") && passed

    println("CJGUI_SESSION_SUMMARY range_events=${controller.rangeEvents()} " +
        "full_value_events=${controller.fullValueEvents} accepted=${controller.acceptedEdits()} " +
        "refused=${controller.refusedEdits()} restored=${controller.restoredContexts()} " +
        "restore_failures=${controller.restoreFailures()} leaked=${controller.leakedRangeEvents} " +
        "composition_decisions=${controller.compositionDecisions()} " +
        "composition_refusals=${controller.compositionRefusals()} " +
        "composition_stale=${controller.staleCompositionRefusals()} " +
        "sink_calls=${controller.sinkCalls()} owner=${controller.ownerText()} passed=${passed}")
    let _ = window.pump(4u32)
    window.close()
    // 14. 窗口销毁必须释放它拥有的会话:旧句柄立即失效,迟到的回执没有可写目标。
    passed = report("window_destroy_releases_session", !rebound.isBound(),
        "bound_after_close=${rebound.isBound()}") && passed
    return passed
}

main(args: Array<String>): Int64 {
    let passed = runSessionProbe()
    CjguiMacosApplicationHost.stopApplicationLoop()
    if (passed) {
        return 0
    }
    return 1
}
