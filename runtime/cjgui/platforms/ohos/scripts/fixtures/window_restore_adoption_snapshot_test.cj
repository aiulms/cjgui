package cjgui

import std.collection.*

/// H1-R.c 的生产窗口接缝反例。被测文本由
/// `scripts/test_window_restore_adoption_snapshot_cjpm.py` 从 H 快照逐字抽取注入；
/// 本文件只负责把身份/版本/落点摆成任务书里的静态交织形状，并逐位断言窗口账本。
private func harnessEvent(eventKind: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
    recordIndex!: UInt32 = 0u32, bindingEpoch!: UInt64 = 0u64): InternalRendererPumpResult {
    return InternalRendererPumpResult(eventKind, recordIndex, selectionStart, selectionEnd, 107u64, 6u64, 77,
        10u32, bindingEpoch, 6u64)
}

private func harnessSession(): CjguiTextSession {
    let session = CjguiTextSession()
    session.window.sourceVersion = 6
    session.contextEpoch = 1
    session.mirrorRevision = 2
    session.mirrorUtf16Length = 44
    return session
}

/// accepted 场景里只有正文节点 107（多行文本，resource 77，场景版本 6）。
/// `acceptScene` 走生产的 `publishAcceptedBindingEpochs`，因此绑定代次就是 6。
private func harnessWindow(session: CjguiTextSession): CjguiComposableUiWindow {
    let window = CjguiComposableUiWindow()
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    nodes.add(CjguiComposableUiLayoutNode(107, "pharos-editor-body", "pharos-editor-body", "", "", "", 77, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 1, value: "mirror"))
    window.acceptScene(6, nodes)
    window.ownedTextSession = Some(session)
    window.ownedTextSessionNodeId = 107
    window.ownedTextSessionResourceId = 77
    window.focusedNodeId = 107
    window.focusedResourceId = 77
    window.focusedNodeKind = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    window.interactionVersion = 3
    return window
}

private func resetHarnessGlobals(): Unit {
    harnessAnchorStatus = 0
    harnessAnchorSeq = 0
    harnessAnchorCalls = 0
    harnessTicketConsumeResult = true
    harnessTicketConsumeCalls = 0
    harnessRestoreIssueCalls = 0
}

/// round6-C：可控时钟下的等待窗判例共享摆位（正文 107 需恢复，issue 可脚本）。
private func anchorWaitFixture(issueStatus: Int32): (CjguiTextSession, CjguiComposableUiWindow) {
    resetHarnessGlobals()
    harnessRestoreIssueStatus = issueStatus
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    session.scriptedCanAnchor = false
    let window = harnessWindow(session)
    window.harnessClockAdvanceMs = 0
    return (session, window)
}

/// 恢复期里隐藏代理自己往前走的落点回声（实测 `ime select [19,19)…[24,24)`，
/// 越出 18 个 UTF-16 单元的 accepted 正文）：具名消费，绝不覆盖当前焦点/书签，
/// 也绝不交给消费者。这是 09-30 04:17 那次"8 次预算白烧、输入门再也打不开"的形状。
@Test
func ohosNamedStalePlatformSelectionKeepsFocusAndBookmark(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.mirrorUtf16Length = 18
    session.selectionNeedsNativeRestore = true
    session.scriptedCanAnchor = false
    let window = harnessWindow(session)
    window.focusedSelectionStart = 4
    window.focusedSelectionEnd = 9

    let pump = window.pumpSelectionEvent(harnessEvent(33u32, 19u32, 19u32))

    @Assert(window.staleOwnedSelectionEvents, 1)
    @Assert(window.humanSelectionAnchorsAdopted, 0)
    @Assert(harnessAnchorCalls, 0)
    // 焦点/选区/书签/交互版本原地不动：失败不覆盖当前焦点。
    @Assert(window.focusedSelectionStart, 4)
    @Assert(window.focusedSelectionEnd, 9)
    @Assert(window.interactionVersion, 3)
    @Assert(window.bookmarkRefreshes.size, 0)
    // 不是领域动作，也不落到 owner dispatcher。
    @Assert(window.controller.appliedKinds.size, 0)
    @Assert(pump.didApplyHumanAction, false)
    @Assert(window.closeCalls, 0)
    // 规范落点必须留在 accepted 正文里：拒绝恢复正是读这两个字段决定往哪装。
    @Assert(window.focusedSelectionEnd <= session.mirrorUtf16Length, true)
    @Assert(session.setSelection16Calls, 0)
    window.close()
}

/// 反向控制：镜像新鲜、没有待恢复位时，同一条 kind-33 事件仍然是人的导航，
/// 必须照常记账并交给消费者。三态守卫不得把正常选区一起吞掉。
@Test
func ohosAlignedPlatformSelectionStillRecordsFocus(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = false
    let window = harnessWindow(session)
    window.focusedSelectionStart = 4
    window.focusedSelectionEnd = 9

    let pump = window.pumpSelectionEvent(harnessEvent(33u32, 19u32, 21u32))

    @Assert(window.staleOwnedSelectionEvents, 0)
    @Assert(session.selStart16, 19)
    @Assert(session.selEnd16, 21)
    @Assert(window.focusedSelectionStart, 19)
    @Assert(window.focusedSelectionEnd, 21)
    @Assert(window.interactionVersion, 4)
    @Assert(window.bookmarkRefreshes.size, 1)
    @Assert(window.bookmarkRefreshes[0], 107)
    @Assert(window.controller.appliedKinds.size, 1)
    @Assert(window.controller.appliedKinds[0], 33)
    @Assert(window.controller.appliedSelections[0], 19)
    @Assert(window.controller.appliedSelections[1], 21)
    @Assert(pump.didApplyHumanAction, true)
    window.close()
}

/// H1-R.a 的人类锚在三态化之后仍然解锁：native 在人亲手落点冻结过锚、身份与值
/// 逐位相同 → 采纳并记账；身份相同但值不同的挂载回声取不走锚 → 仍按 stale 具名
/// 消费，不覆盖焦点。两条都在同一份生产决策文本上跑。
@Test
func ohosHumanAnchorSelectionStillUnlocksAfterReplace(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    session.scriptedCanAnchor = true
    let window = harnessWindow(session)
    window.focusedSelectionStart = 4
    window.focusedSelectionEnd = 9
    harnessAnchorStatus = 1
    harnessAnchorSeq = 7

    let pump = window.pumpSelectionEvent(harnessEvent(33u32, 24u32, 24u32))

    @Assert(harnessAnchorCalls, 1)
    @Assert(session.anchorAdoptCalls, 1)
    @Assert(window.humanSelectionAnchorsAdopted, 1)
    @Assert(window.staleOwnedSelectionEvents, 0)
    @Assert(session.selectionNeedsNativeRestore, false)
    @Assert(session.selStart16, 24)
    @Assert(window.focusedSelectionStart, 24)
    @Assert(window.focusedSelectionEnd, 24)
    @Assert(window.interactionVersion, 4)
    @Assert(window.controller.appliedKinds.size, 1)
    @Assert(pump.didApplyHumanAction, true)
    window.close()

    // 挂载/换焦回声：身份相同、值不同，native 不交锚（status=0）。
    resetHarnessGlobals()
    let echoSession = harnessSession()
    echoSession.selectionNeedsNativeRestore = true
    echoSession.scriptedCanAnchor = true
    let echoWindow = harnessWindow(echoSession)
    echoWindow.focusedSelectionStart = 4
    echoWindow.focusedSelectionEnd = 9
    harnessAnchorStatus = 0

    let echoPump = echoWindow.pumpSelectionEvent(harnessEvent(33u32, 44u32, 44u32))

    @Assert(harnessAnchorCalls, 1)
    @Assert(echoSession.anchorAdoptCalls, 0)
    @Assert(echoWindow.humanSelectionAnchorsAdopted, 0)
    @Assert(echoWindow.staleOwnedSelectionEvents, 1)
    @Assert(echoSession.selectionNeedsNativeRestore, true)
    @Assert(echoWindow.focusedSelectionStart, 4)
    @Assert(echoWindow.focusedSelectionEnd, 9)
    @Assert(echoWindow.interactionVersion, 3)
    @Assert(echoWindow.bookmarkRefreshes.size, 0)
    @Assert(echoWindow.controller.appliedKinds.size, 0)
    @Assert(echoPump.didApplyHumanAction, false)
    echoWindow.close()
}

/// H1-R.c 的静态交织：平台安装回执（v1）已进 FIFO，Agent 把 owner 推到 v2，窗口
/// 消费时预检通过、票据结清，随后会话按 owner 版本守卫拒绝采纳。这不是
/// WindowAdopted：不记成功、不回写焦点/书签、保留恢复意图、请求新投影有限重试。
@Test
func ohosRestoreReceiptRefusedByOwnerVersionIsNotWindowAdopted(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    // 第一次成功的 owner 边界提交之后，Agent 的换版落地（v6 → v7）。
    session.window.advanceAfterConfirmCalls = 1
    session.window.advanceToVersion = 7
    let window = harnessWindow(session)
    window.focusedSelectionStart = 44
    window.focusedSelectionEnd = 44
    window.armRestore(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 6, 6, Some(session), 9u64, 6u64, 6u64,
        4, 9)

    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, bindingEpoch: 9u64))

    @Assert(window.textSessionRestores, 0)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(window.lastNativeFailure, "restore_adoption_source_stale")
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(window.refreshRequests, 1)
    @Assert(harnessTicketConsumeCalls, 1)
    // 失败不覆盖当前焦点，也不把它当一次交互。
    @Assert(window.focusedSelectionStart, 44)
    @Assert(window.focusedSelectionEnd, 44)
    @Assert(window.interactionVersion, 3)
    @Assert(window.bookmarkRefreshes.size, 0)
    // 恢复意图保留：会话仍然锁着，等下一轮按 owner 现状重签发。
    @Assert(session.selectionNeedsNativeRestore, true)
    @Assert(session.lastReason, "selection_restore_version_stale")
    @Assert(session.setSelection16Calls, 0)
    @Assert(session.selStart16, 0)
    window.close()
}

/// 唯一成功终态：核验通过且会话真的采纳，才记一次成功、才回写焦点/书签；
/// 同一张票据的迟到回执不得二次完成。
@Test
func ohosRestoreReceiptAdoptedCountsSuccessOnce(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    let window = harnessWindow(session)
    window.focusedSelectionStart = 44
    window.focusedSelectionEnd = 44
    window.armRestore(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 6, 6, Some(session), 9u64, 6u64, 6u64,
        4, 9)

    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, bindingEpoch: 9u64))

    @Assert(window.textSessionRestores, 1)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.lastNativeFailure, "")
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(harnessTicketConsumeCalls, 1)
    @Assert(session.selectionNeedsNativeRestore, false)
    @Assert(session.selStart16, 4)
    @Assert(session.selEnd16, 9)
    @Assert(window.focusedSelectionStart, 4)
    @Assert(window.focusedSelectionEnd, 9)
    @Assert(window.interactionVersion, 4)
    @Assert(window.bookmarkRefreshes.size, 1)
    @Assert(window.bookmarkRefreshes[0], 107)

    // 迟到重放：pending 已清，同一身份也不得再记一次成功或再写一次焦点。
    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, bindingEpoch: 9u64))
    @Assert(window.textSessionRestores, 1)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.interactionVersion, 4)
    @Assert(window.bookmarkRefreshes.size, 1)
    @Assert(harnessTicketConsumeCalls, 1)
    window.close()
}

/// 终态回执（未安装/安装未确认）只按票据号清账：票据号不符时一个字都不动，
/// 符合时保留恢复意图、具名失败、请求新投影，且绝不消费票据、绝不记成功。
@Test
func ohosRestoreTerminalRequiresExactRequestIdentity(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    let window = harnessWindow(session)
    window.focusedSelectionStart = 44
    window.focusedSelectionEnd = 44
    window.armRestore(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 6, 6, Some(session), 9u64, 6u64, 6u64,
        4, 9)

    // 别的请求的终态（requestId=8）：不得命中本票据。
    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, recordIndex: 2u32, bindingEpoch: 8u64))
    @Assert(window.pendingPlatformRestore.isSome(), true)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.textSessionRestores, 0)
    @Assert(window.refreshRequests, 0)
    @Assert(window.lastNativeFailure, "")

    // 本请求的终态：清账 + 具名失败 + 请求新投影，不消费票据、不记成功、不动焦点。
    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, recordIndex: 2u32, bindingEpoch: 9u64))
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(window.lastNativeFailure, "owned_text_session_restore_failed")
    @Assert(window.textSessionRestores, 0)
    @Assert(window.refreshRequests, 1)
    @Assert(harnessTicketConsumeCalls, 0)
    @Assert(session.selectionNeedsNativeRestore, true)
    @Assert(window.focusedSelectionStart, 44)
    @Assert(window.focusedSelectionEnd, 44)
    @Assert(window.interactionVersion, 3)
    @Assert(window.bookmarkRefreshes.size, 0)

    // 终态之后迟到的"安装回执"：没有待办票据，不得把它当成功补记。
    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, bindingEpoch: 9u64))
    @Assert(window.textSessionRestores, 0)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(harnessTicketConsumeCalls, 0)
    @Assert(window.interactionVersion, 3)
    window.close()
}

/// 同值 owner 换版的生产 RED：kind51 因 selection_version_stale 被拒，
/// 随后的脏代理 kind33 报 4:4。即使镜像 fresh、未上校准锁，不能覆盖最后
/// accepted 的非空 0:26；恢复目标必须仍是 0:26。
@Test
func ohosRefusedDeltaSelectionEchoCannotCollapseAcceptedNonemptyRange(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = false
    session.scriptedCanAnchor = true
    let window = harnessWindow(session)
    window.refusedRangeTextPending = true
    window.refusedRangeTextNodeId = 107
    window.refusedRangeTextResourceId = 77
    window.refusedRangeTextNodeKind = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    window.focusedSelectionStart = 0
    window.focusedSelectionEnd = 26
    let result = window.pumpSelectionEvent(harnessEvent(33u32, 4u32, 4u32))
    @Assert(window.focusedSelectionStart, 0)
    @Assert(window.focusedSelectionEnd, 26)
    @Assert(session.setSelection16Calls, 0)
    @Assert(harnessAnchorCalls, 0)
    @Assert(window.staleOwnedSelectionEvents, 1)
    @Assert(window.controller.appliedKinds.size, 0)
    @Assert(result.didApplyHumanAction, false)
    window.close()
}

@Test
func ohosAnotherFieldRefusalDoesNotBlockOwnedSelection(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    window.refusedRangeTextPending = true
    window.refusedRangeTextNodeId = 108
    window.refusedRangeTextResourceId = 78
    window.refusedRangeTextNodeKind = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    let result = window.pumpSelectionEvent(harnessEvent(33u32, 4u32, 9u32))
    @Assert(window.focusedSelectionStart, 4)
    @Assert(window.focusedSelectionEnd, 9)
    @Assert(session.setSelection16Calls, 1)
    @Assert(result.didApplyHumanAction, true)
    window.close()
}

/// 安装失败之后 accepted 场景可不再变化：原身份仍须允许有界重签发。
/// 八次终态后停止；新 owner 版本才开启新一轮，不能靠无关重绘清预算。
@Test
func ohosOwnedRestoreRetriesSameSceneAndStopsAtEightTerminals(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    let window = harnessWindow(session)
    for (_ in 0..8) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
        let request = UInt64(harnessRestoreIssueCalls)
        @Assert(window.pendingPlatformRestore.isSome(), true)
        window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 0u32, 0u32,
            recordIndex: 2u32, bindingEpoch: request))
        @Assert(window.pendingPlatformRestore.isSome(), false)
    }
    @Assert(harnessRestoreIssueCalls, 8)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(harnessRestoreIssueCalls, 8)
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(session.selectionNeedsNativeRestore, true)
    @Assert(window.lastNativeFailure, "owned_selection_restore_budget_exhausted")
    // 相同预算耗尽终态只记一次。
    let failures = window.textSessionRestoreFailures
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.textSessionRestoreFailures, failures)
    session.window.sourceVersion = 7
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(harnessRestoreIssueCalls, 9)
    @Assert(window.pendingPlatformRestore.isSome(), true)
    window.close()
}

/// A→B→A 交接锚点（2026-10-03 GLM 裁决 D1）：release 必须把**已对齐当前 owner
/// 正文**的会话落点冻结进 `nodeSelectionMemory`，使重绑的 `carriedSelectionFor`
/// 交回人的中段锚（实测 [3,3]），而不是被装载回声写旧的文末值（实测 [63,63]）。
/// 焦点已移走（branch 1 不命中）时唯一来源就是这份冻结记录。
@Test
func ohosReleaseFreezesAlignedHandoffAnchor(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    // 会话持有人的中段锚 [3,3]，且已对齐当前 owner 正文。
    session.selStart16 = 3
    session.selEnd16 = 3
    session.selectionVersion = session.window.sourceVersion
    // 焦点在 B（已移走）：branch 1/3 都不命中，判据只看冻结记录。
    window.focusedNodeId = -1
    window.focusedResourceId = -1
    window.focusedNodeKind = -1
    // 记忆里是早先装载回声写下的文末值（本 trace 的 (63,63)）。
    window.nodeSelectionMemory[107] = (77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 63, 63)

    window.freezeHandoffAnchorFor(session)

    let carried = window.carriedSelectionFor(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    @Assert(carried.isSome(), true)
    let sel = carried.getOrThrow()
    @Assert(sel[0], 3)
    @Assert(sel[1], 3)
}

/// 反例（2026-10-03 round5-C GLM 裁定）：**首绑新节点**不得凭 FOCUS 缺省投影交回落点。
/// kind-31 FOCUS 事件结构性携带 (0,0)，窗口先 `rememberInteraction(node, 31, 0, 0)` 把
/// focusedSelection 写成 (0,0)，随后生成的 region 才 bind——第一分支必然读到该缺省值，
/// 而它滞后于人的真实点击（异步 caret-hit 测量恒晚于 bind）。实测生成编辑器：人锚 1:1
/// 被这张错票在 native 改写为 0:0，输入门卡死。首绑（无冻结记录、非同节点重绑）必须 None。
@Test
func ohosFirstBindNewNodeDoesNotCarryFocusDefault(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    // 生成新节点 802001 刚被 FOCUS 默认置 (0,0)：无会话、无冻结记录。
    window.ownedTextSession = None
    window.ownedTextSessionNodeId = -1
    window.ownedTextSessionResourceId = -1
    window.ownedTextSessionNodeKind = -1
    window.focusedNodeId = 802001
    window.focusedResourceId = 9801
    window.focusedNodeKind = CJGUI_COMPOSABLE_UI_TEXT_INPUT
    window.focusedSelectionStart = 0
    window.focusedSelectionEnd = 0
    let carried = window.carriedSelectionFor(802001, 9801, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(carried.isNone(), true)
}

/// 对照（资格门不得过宽）：bind 前会话**仍拥有该节点**（同节点重绑，region memo 变化）
/// 时，第一分支的即时落点仍须交回。
@Test
func ohosSameNodeRebindStillCarriesLiveSelection(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    window.focusedNodeId = 107
    window.focusedResourceId = 77
    window.focusedNodeKind = CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    window.focusedSelectionStart = 5
    window.focusedSelectionEnd = 5
    let carried = window.carriedSelectionFor(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    @Assert(carried.isSome(), true)
    @Assert(carried.getOrThrow()[0], 5)
    @Assert(carried.getOrThrow()[1], 5)
}

/// 对照：焦点已移走、且非同节点重绑，但存在冻结锚（`nodeSelectionMemory`）时仍可交回
/// （A→B→A 回访的唯一可靠来源）。
@Test
func ohosFrozenAnchorAloneStillCarries(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    window.ownedTextSessionNodeId = -1
    window.ownedTextSessionResourceId = -1
    window.ownedTextSessionNodeKind = -1
    window.focusedNodeId = -1
    window.focusedResourceId = -1
    window.focusedNodeKind = -1
    window.nodeSelectionMemory[107] = (77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 3, 3)
    let carried = window.carriedSelectionFor(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    @Assert(carried.isSome(), true)
    @Assert(carried.getOrThrow()[0], 3)
    @Assert(carried.getOrThrow()[1], 3)
}

/// 反例：未对齐当前正文（外部换版后 `selectionVersion` 落后）或仍在等待恢复回执的
/// 会话落点**不得**被冻结——保持旧条目，不清、不 clamp、不臆造。
@Test
func ohosReleaseSkipsUnalignedHandoffAnchor(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    let window = harnessWindow(session)
    session.selStart16 = 3
    session.selEnd16 = 3
    session.selectionVersion = session.window.sourceVersion - 1
    window.focusedNodeId = -1
    window.focusedResourceId = -1
    window.focusedNodeKind = -1
    window.nodeSelectionMemory[107] = (77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 63, 63)

    window.freezeHandoffAnchorFor(session)

    let carried = window.carriedSelectionFor(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    let sel = carried.getOrThrow()
    @Assert(sel[0], 63)
    @Assert(sel[1], 63)
}

// round5 后指导 C 的确定性反例：人锚确认延迟超过 8 个接受轮时，具名「等待人锚」既不
// 消耗失败重试预算也不逐帧重复签发；同一目标换成真平台失败仍按 8 次收束。
@Test
func ohosAnchorPendingWaitDoesNotBurnRestoreBudget(): Unit {
    // round6-C 改写：轮数不再过期等待——12（或任意多）个接受轮零时间内全部
    // 塌缩为一次签发；截止只由单调时间给出。
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    let window = harnessWindow(session)
    harnessRestoreIssueStatus = CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ANCHOR_PENDING
    for (_ in 0..12) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(harnessRestoreIssueCalls, 1)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(window.lastNativeFailure, "")
    @Assert(window.ownedAnchorWaiting, true)
    // 推进超过 2500ms：一次具名截止终态。
    window.harnessClockAdvanceMs = 2600
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    // round7-C：Expired 是终态 —— 同一目标后续换任何 issue 结果都**不再签发**，
    // 因此真平台失败也进不了 8 次预算（没有签发就没有失败可记）。
    let callsAtExpiry = harnessRestoreIssueCalls
    harnessRestoreIssueStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    for (_ in 0..40) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(harnessRestoreIssueCalls, callsAtExpiry)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    // 真平台失败仍由既有 8 次预算给出具名终态 —— 但必须先**显式建立新代**
    // （这里是新的选择意图），符合状态表「需要重试则显式建立新代」。
    session.selStart16 = 6
    session.selEnd16 = 6
    for (_ in 0..40) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
        if (window.lastNativeFailure == "owned_selection_restore_budget_exhausted") {
            break
        }
    }
    @Assert(window.lastNativeFailure, "owned_selection_restore_budget_exhausted")
    @Assert(window.ownedSelectionRestoreAttempts, 8)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(window.pendingPlatformRestore.isSome(), false)
    window.close()
}



// ---------------------------------------------------------------------------
// round6-C：等待人锚＝单调时间截止的待办（非失败）
// ---------------------------------------------------------------------------

@Test
func anchorPendingDoesNotBecomeFailureByPumpCount(): Unit {
    // 指导 0ms 反例：40 次零时间泵送全部 36，等待不得消耗失败预算/次数。
    let (_, window) = anchorWaitFixture(36)
    for (_ in 0..40) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.lastNativeFailure, "")
    @Assert(window.ownedAnchorWaiting, true)
    // 首个 pending 只签一次 native + 一次刷新；窗内后续泵送零新调用。
    @Assert(harnessRestoreIssueCalls, 1)
    @Assert(window.refreshRequests, 1)
    window.close()
}

@Test
func anchorWaitDeadlineExpiresOnceByNameAndKeepsBudgetSeparate(): Unit {
    // round7-C 修正：截止到期是**终态**。同一目标的后续普通 pump 直接返回——
    // 零新 native 调用、零 attempts、零失败计数，且不改写这次具名终态。
    // round6 的旧预期（「到期后 attempts=1、继续烧 8 次预算」）与原契约相反，
    // 指导的独立反例（calls_final=9 attempts=8 failures=1）已经把它钉成 RED。
    // 真平台失败（非 36）仍走既有 8 次预算，由 anchorTrueFailureStillUsesOriginalBudget
    // 独立证明——等待与失败两条账彻底分开。
    let (_, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaiting, true)
    @Assert(harnessRestoreIssueCalls, 1)
    window.harnessClockAdvanceMs = 2600   // 越过 2500ms 截止
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    @Assert(window.ownedAnchorWaiting, false)
    @Assert(window.ownedAnchorWaitExpired, true)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    // 终态之后：同一目标的普通 pump 全部直返，原数零增长。
    for (_ in 0..40) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(harnessRestoreIssueCalls, 1)          // 零新 native 请求
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0) // 不进 8 次平台失败预算
    @Assert(window.ownedAnchorWaiting, false)      // 不重开等待窗
    @Assert(window.ownedAnchorWaitExpired, true)  // 终态保留
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    window.close()
}

@Test
func anchorExpiredThenNewSelectionIntentOpensNewGeneration(): Unit {
    // round7-C 换代键含**选择意图的身份/修订**：到期后合法的**新落点意图**必须
    // 建立新代、重开等待窗——不能被 Expired 直返整个吞掉（那会把「烧预算」bug
    // 变成「静默丢弃恢复」bug）。同值重复 pump 则仍是同一代。
    let (session, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    window.harnessClockAdvanceMs = 2600
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaitExpired, true)
    let callsAtExpiry = harnessRestoreIssueCalls
    // 新意图：会话选区换到别的落点（人重新选了一段）。
    session.selStart16 = 4
    session.selEnd16 = 9
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaitExpired, false)   // 旧代撤销
    @Assert(window.ownedAnchorWaiting, true)       // 新代重开等待窗
    @Assert(harnessRestoreIssueCalls, callsAtExpiry + 1)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.refreshRequests, 2)              // 每一代各请求一次刷新
    // 同一新代内重复 pump 不再签发、也不再刷新。
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(harnessRestoreIssueCalls, callsAtExpiry + 1)
    @Assert(window.refreshRequests, 2)
    window.close()
}

@Test
func anchorExpiredThenSameIntentStaysExpired(): Unit {
    // 换代键的另一半：同值重复 pump **不**建立新代。防止「每个 pump 都自建新代」
    // 把 Expired 变成随手可清的暂态（那等于没有终态）。
    let (session, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    window.harnessClockAdvanceMs = 2600
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaitExpired, true)
    let callsAtExpiry = harnessRestoreIssueCalls
    for (_ in 0..10) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(harnessRestoreIssueCalls, callsAtExpiry)
    @Assert(window.ownedAnchorWaitExpired, true)
    @Assert(window.ownedAnchorWaiting, false)
    @Assert(window.textSessionRestoreFailures, 0)
    // 会话选区真的没动过（换代键的 sel 分量保持一致）。
    let sel = session.selection16()
    @Assert(sel[0], 0)
    @Assert(sel[1], 0)
    window.close()
}

@Test
func anchorExpiredThenExplicitRetryEdgeOpensNewGeneration(): Unit {
    // 显式重试：待恢复意图的 false→true **边沿**是唯一「值完全不变也能重开一代」
    // 的信号（`markNativeSelectionRestoreRequired` 与换绑交接都走它）。稳态真
    // （连续两次 true）不重开。
    let (session, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    window.harnessClockAdvanceMs = 2600
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaitExpired, true)
    let callsAtExpiry = harnessRestoreIssueCalls
    // 先确认（need→false，撤销终态），再显式重试（need→true 边沿）。
    session.selectionNeedsNativeRestore = false
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    session.selectionNeedsNativeRestore = true
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaiting, true)       // 新代等待窗
    @Assert(harnessRestoreIssueCalls, callsAtExpiry + 1)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    window.close()
}

@Test
func anchorConfirmationBeforeDeadlineCancelsWaitCleanly(): Unit {
    // 截止前确认（锚采纳清 need）＝确定终态：等待窗撤销、失败/次数账本复位、
    // 不再签票据（安装由 kind-33 锚采纳路径完成，恢复入口不重复签发）。
    let (session, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaiting, true)
    session.selectionNeedsNativeRestore = false   // 人锚确认
    harnessRestoreIssueStatus = 0                  // 后续 native 正常
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaiting, false)
    @Assert(window.ownedAnchorWaitExpired, false)
    @Assert(window.pendingPlatformRestore.isSome(), false)
    @Assert(harnessRestoreIssueCalls, 1)          // 确认后不再签发
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.lastNativeFailure, "")
    // 迟到的旧截止（时钟推进后）无任何副作用。
    window.harnessClockAdvanceMs = 9000
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.lastNativeFailure, "")
    window.close()
}

@Test
func anchorWaitNotResetByRepeatedPendingAndIgnoresPumpFrequency(): Unit {
    // 不同泵频率/重复 pending 不重置截止：第二次 pending 不再发刷新。
    let (_, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    window.harnessClockAdvanceMs = 900
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    window.harnessClockAdvanceMs = 1800
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.refreshRequests, 1)
    @Assert(harnessRestoreIssueCalls, 1)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.ownedAnchorWaiting, true)
    window.close()
}

@Test
func anchorIdentityChangeCancelsOldWaitAndLateDeadlineHasNoEffect(): Unit {
    // 换绑（会话上下文换代，身份三元之一）撤销旧等待窗：旧截止不终结新身份，
    // 新身份重新开窗、重新计数。
    let (session, window) = anchorWaitFixture(36)
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.ownedAnchorWaiting, true)
    session.contextEpoch += 1                    // 换绑：冻结身份换代
    window.harnessClockAdvanceMs = 3000          // 旧截止早已过
    window.restoreOwnedTextSelectionAfterAcceptedScene()
    @Assert(window.lastNativeFailure, "")        // 旧截止不终结新身份
    @Assert(window.ownedAnchorWaiting, true)     // 新身份重新开窗
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    window.close()
}

@Test
func anchorTrueFailureStillUsesOriginalBudget(): Unit {
    // 真失败（非 36）仍按 8 次预算：等待机制不给失败让路；终态在预算耗尽后的
    // 下一次进入给出（既有语义）。
    let (_, window) = anchorWaitFixture(99)
    for (_ in 0..7) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
    }
    @Assert(window.ownedSelectionRestoreAttempts, 7)
    @Assert(window.textSessionRestoreFailures, 0)
    for (_ in 0..4) {
        window.restoreOwnedTextSelectionAfterAcceptedScene()
        if (window.lastNativeFailure == "owned_selection_restore_budget_exhausted") {
            break
        }
    }
    @Assert(window.ownedSelectionRestoreAttempts, 8)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(window.lastNativeFailure, "owned_selection_restore_budget_exhausted")
    window.close()
}

// ---------------------------------------------------------------------------
// round8-C：终态归**当前恢复目标**，不归一次函数调用。下列用例全部走
// `reviewAcceptedRestoreAndFinish()`——恢复入口 + **生产收尾守卫**，不再只直接
// 调恢复方法（指导 round8 生产反例：只调入口的旧 24 例看不到收尾擦除路径）。
// ---------------------------------------------------------------------------

@Test
func expiredGoalRetainsNamedTerminalThroughAcceptedFinish(): Unit {
    // 指导 round8 反例的 GREEN：到期后**连续**的 accepted 收尾不得把原因清成 none。
    let (session, window) = anchorWaitFixture(36)
    window.reviewAcceptedRestoreAndFinish()
    window.harnessClockAdvanceMs = 2600
    window.reviewAcceptedRestoreAndFinish()
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    @Assert(window.ownedAnchorWaitExpired, true)
    let callsAtExpiry = harnessRestoreIssueCalls
    for (_ in 0..10) {
        window.reviewAcceptedRestoreAndFinish()
    }
    // 原数必须与指导反例的 RED 一致地「不增长」，且原因保留。
    @Assert(harnessRestoreIssueCalls, callsAtExpiry)
    @Assert(window.ownedSelectionRestoreAttempts, 0)
    @Assert(window.textSessionRestoreFailures, 0)
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    @Assert(session.needsNativeSelectionRestore(), true)   // 源锚保留
    @Assert(window.ownedAnchorWaitExpired, true)          // 终态保留
    window.close()
}

@Test
func newIntentAfterFinishClearsOldNamedTerminal(): Unit {
    // 换代必须撤销上一代的具名终态：新意图换了落点之后，收尾**可以**正常写 none。
    // 否则终态会变成永久粘住其他新错误的全局错误字符串（指导明确禁止）。
    let (session, window) = anchorWaitFixture(36)
    window.reviewAcceptedRestoreAndFinish()
    window.harnessClockAdvanceMs = 2600
    window.reviewAcceptedRestoreAndFinish()
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    session.selStart16 = 5
    session.selEnd16 = 5
    window.reviewAcceptedRestoreAndFinish()
    @Assert(window.ownedAnchorWaitExpired, false)        // 旧代已撤销
    @Assert(window.ownedAnchorWaiting, true)             // 新代重开等待窗
    @Assert(window.lastNativeFailure, "none")            // 收尾写回 none
    window.close()
}

@Test
func successfulAdoptionClearsNamedTerminal(): Unit {
    // 成功采纳是确定成功终态：采纳后收尾必须能写 none（否则成功后仍报过期原因）。
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = true
    session.scriptedCanAnchor = false
    let window = harnessWindow(session)
    harnessRestoreIssueStatus = 0
    window.armRestore(107, 77, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 6, 6, Some(session),
        9u64, 6u64, 6u64, 4, 9)
    window.onPlatformProxyRestoreReceipt(harnessEvent(55u32, 4u32, 9u32, bindingEpoch: 9u64))
    @Assert(window.textSessionRestores, 1)
    window.reviewAcceptedRestoreAndFinish()
    @Assert(window.lastNativeFailure, "none")
    window.close()
}

@Test
func trueFailureBudgetExhaustionSurvivesAcceptedFinish(): Unit {
    // 真失败（非 36）耗尽 8 次预算后，终态同样必须穿过收尾保留——真失败与等待
    // 到期是两条不同的具名终态，都归本恢复目标。
    let (_, window) = anchorWaitFixture(99)
    // 预算耗尽的具名终态在 attempts 达到 8 之后的**下一次**进入给出（既有语义）。
    for (_ in 0..9) {
        window.reviewAcceptedRestoreAndFinish()
    }
    @Assert(window.ownedSelectionRestoreAttempts, 8)
    @Assert(window.textSessionRestoreFailures, 1)
    @Assert(window.lastNativeFailure, "owned_selection_restore_budget_exhausted")
    for (_ in 0..5) {
        window.reviewAcceptedRestoreAndFinish()
    }
    @Assert(window.lastNativeFailure, "owned_selection_restore_budget_exhausted")
    @Assert(window.ownedSelectionRestoreAttempts, 8)
    @Assert(window.textSessionRestoreFailures, 1)
    window.close()
}

@Test
func lateOldConfirmationHasNoEffectOnExpiredGoal(): Unit {
    // 旧确认在到期之后到达：对同一目标零副作用（不重开发行、不改终态、不记成功）。
    let (session, window) = anchorWaitFixture(36)
    window.reviewAcceptedRestoreAndFinish()
    window.harnessClockAdvanceMs = 2600
    window.reviewAcceptedRestoreAndFinish()
    @Assert(window.lastNativeFailure, "owned_anchor_wait_deadline")
    let callsAtExpiry = harnessRestoreIssueCalls
    session.selectionNeedsNativeRestore = false
    window.reviewAcceptedRestoreAndFinish()
    session.selectionNeedsNativeRestore = true
    window.reviewAcceptedRestoreAndFinish()
    // 显式重试边沿合法建立新代，但这是一次**新**意图，不是旧确认。
    @Assert(window.ownedAnchorWaiting, true)
    @Assert(harnessRestoreIssueCalls, callsAtExpiry + 1)
    window.close()
}

// ---------------------------------------------------------------------------
// round9-A：采纳事实必须带**本事件自己的冻结来源**；拿不到就写 unverified，
// 绝不拿当前挂载反填。守护 `provenance-backfilled` 变异（去掉 provValid 判定）。
//
// 走 **kind-33 选择事件**路径（ADOPTED2 就在这条分支打印），不是 restore-receipt
// 路径——后者不打印采纳事实。
// ---------------------------------------------------------------------------

@Test
func adoptionFactCarriesFrozenSourceWhenAvailable(): Unit {
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = false
    let window = harnessWindow(session)
    window.focusedSelectionStart = 4
    window.focusedSelectionEnd = 9
    window.harnessProvenanceValid = true
    window.harnessProvenanceCtx = 42
    window.harnessProvenanceGen = 7u64
    let _ = window.pumpSelectionEvent(harnessEvent(33u32, 19u32, 21u32))
    @Assert(harnessLastWindowLog.contains("CJGUI_OWNED_SELECTION_ADOPTED2"), true)
    @Assert(harnessLastWindowLog.contains("source_ctx=42"), true)
    @Assert(harnessLastWindowLog.contains("source_gen=7"), true)
    @Assert(harnessLastWindowLog.contains("unverified"), false)
    window.close()
}

@Test
func adoptionFactIsUnverifiedWhenSourceUnavailable(): Unit {
    // 没有冻结来源（native 侧会话缺失/事件无来源身份）时必须具名 unverified。
    // 反填成「当前挂载」会让旧挂载的迟到采纳被读成新挂载的采纳——这正是 round8
    // 检查器只能「按到达时代号盖章」的原因。
    resetHarnessGlobals()
    let session = harnessSession()
    session.selectionNeedsNativeRestore = false
    let window = harnessWindow(session)
    window.focusedSelectionStart = 4
    window.focusedSelectionEnd = 9
    window.harnessProvenanceValid = false
    let _ = window.pumpSelectionEvent(harnessEvent(33u32, 19u32, 21u32))
    @Assert(harnessLastWindowLog.contains("CJGUI_OWNED_SELECTION_ADOPTED2"), true)
    @Assert(harnessLastWindowLog.contains("source_ctx=unverified"), true)
    @Assert(harnessLastWindowLog.contains("source_gen=unverified"), true)
    window.close()
}
