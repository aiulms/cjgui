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
