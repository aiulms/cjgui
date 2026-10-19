package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_notification_threshold_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private class CjguiNotificationThresholdController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let domain: CjguiNotificationThresholdDomain
    private var localRevision: Int64
    private var status: String
    private var usesLightAppearance: Bool
    private var usesCoralBeacon: Bool
    private var usesMonospacedText: Bool
    private let channelPanel = CjguiSearchableSelectionPanel("notification-channel")

    init(domain: CjguiNotificationThresholdDomain) {
        this.domain = domain
        this.localRevision = 1
        this.status = "编辑后应用通知阈值配置"
        this.usesLightAppearance = false
        this.usesCoralBeacon = false
        this.usesMonospacedText = false
    }
    public func uiSceneVersion(): Int64 {
        // The draft text is also written by the shared-operation sink and by
        // external clients; the projection must follow that truth, not only
        // local button/status changes.
        let draft = domain.draftSnapshot()
        let current = domain.notificationSnapshot()
        return localRevision + draft.draftVersion * 1000003 + current.version * 7919 + channelPanel.revision()
    }
    public func beginSceneRefresh(): Bool {
        return true
    }
    public func prepareSceneRefresh(): Bool {
        return true
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = channelPanel.commands()
        commands.add(CjguiComposableUiCommand("notification-channel-picker", 36, CjguiComposableUiShortcut("k")))
        return commands
    }
    public func finishPanelAction(window: CjguiComposableUiWindow): Unit {
        if (let Some(item) <- channelPanel.takeConfirmed(window)) {
            let draft = domain.draftSnapshot()
            let result = domain.editDraftTextFromHuman("deliveryChannel", item.key, draft.draftVersion)
            status = if (result.applied) {
                "投递通道已选择：${item.title}"
            } else {
                "未更新：${result.reason}"
            }
            localRevision += 1
            window.requestRefresh()
        }
        let failure = channelPanel.takeConfirmationFailure()
        if (failure.size > 0) {
            status = "选区恢复失败，未执行面板操作：${failure}"
            localRevision += 1
            window.requestRefresh()
        }
    }
    public func buildUi(): CjguiComposableUiNode {
        let current = domain.notificationSnapshot()
        let draft = domain.draftSnapshot()
        let theme = if (usesLightAppearance) {
            CjguiComposableUiTheme.paperLight()
        } else {
            CjguiComposableUiTheme.beaconDark()
        }
        let headingStyle = presentationTextStyle(theme.heading)
        let bodyStyle = presentationTextStyle(theme.body)
        let inputStyle = interactiveInputStyle(theme.input)
        let actionStyle = presentationTextStyle(theme.primaryAction)
        let beaconPath = if (usesCoralBeacon) {
            "composable-beacon-coral.png"
        } else {
            "composable-beacon.png"
        }
        let beaconVersion = if (usesCoralBeacon) {
            2
        } else {
            1
        }
        let draftChannel = draft.fieldForResourceId(9101).draftText
        let draftThreshold = draft.fieldForResourceId(9102).draftText
        let draftEnabled = draft.fieldForResourceId(9103).draftText == "true"
        let root = cjguiComposableVertical(1, "notification-root", theme.page)
        let hero = cjguiComposableHorizontal(4, "notification-hero", CjguiComposableUiStyle(fixedHeight: 84, gap: 12))
        let heroCopy = cjguiComposableVertical(5, "notification-hero-copy", CjguiComposableUiStyle(growX: 1, gap: 4))
        heroCopy.add(cjguiComposableText(2, "notification-title", "异常提醒阈值", headingStyle))
        heroCopy.add(
            cjguiComposableText(3, "notification-subtitle",
                "通知通道、触发阈值与开关是独立通知领域的实际配置。\n支持中文说明与 emoji 👩🏽‍💻；应用后更新规则。\n完整配置与说明始终保留，可从领域状态和辅助功能读取。",
                CjguiComposableUiStyle(fontSize: bodyStyle.fontSize, fontFamily: bodyStyle.fontFamily,
                    textColor: bodyStyle.textColor, textMaxLines: 2, textOverflow: "ellipsis")))
        hero.add(heroCopy)
        hero.add(
            cjguiComposableImage(6, "notification-beacon", beaconPath,
                CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 76), imageResourceId: "notification-beacon",
                imageResourceVersion: beaconVersion))
        root.add(hero)
        let cards = cjguiComposableHorizontal(10, "notification-cards", CjguiComposableUiStyle(growY: 1, gap: 16))
        let channelCard = cjguiComposableVertical(11, "channel-card",
            CjguiComposableUiStyle(growX: 1, padding: theme.card.padding, gap: theme.card.gap,
                background: theme.card.background, border: theme.card.border))
        channelCard.add(cjguiComposableText(12, "channel-heading", "投递通道", fixedTextStyle(headingStyle, 24)))
        channelCard.add(
            cjguiComposableTextInput(13, "delivery-channel", "通道", draftChannel,
                CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "deliveryChannel",
                operationActionName: "EDIT_DRAFT_TEXT", displayValueRole: "draft"))
        channelCard.add(
            cjguiComposableText(14, "channel-help", "例如：邮件、短信、企业微信\n按 ⌘K 打开通道选择",
                CjguiComposableUiStyle(fixedHeight: 22, fontSize: bodyStyle.fontSize, fontFamily: bodyStyle.fontFamily,
                    textColor: bodyStyle.textColor, textMaxLines: 1, textOverflow: "ellipsis")))
        channelCard.add(
            cjguiComposableButton(36, "choose-delivery-channel", "选择通道… ⌘K", "CHOOSE_CHANNEL", 0,
                CjguiComposableUiStyle(fixedHeight: 32, textColor: theme.body.textColor,
                    background: theme.input.background)))
        cards.add(channelCard)
        let thresholdCard = cjguiComposableVertical(20, "threshold-card",
            CjguiComposableUiStyle(growX: 1, padding: theme.card.padding, gap: theme.card.gap,
                background: theme.card.background, border: theme.card.border))
        thresholdCard.add(cjguiComposableText(21, "threshold-heading", "触发条件", fixedTextStyle(headingStyle, 24)))
        // This grouping is declared only by the consumer. The external window
        // context is derived from this tree, so no domain relation table needs
        // a matching update when the arrangement changes.
        let thresholdFields = cjguiComposableVertical(25, "threshold-fields", CjguiComposableUiStyle(gap: 8))
        thresholdFields.add(
            cjguiComposableIntegerInput(22, "trigger-threshold", "阈值（1–100）", draftThreshold,
                CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "triggerThreshold",
                operationActionName: "EDIT_DRAFT_TEXT", displayValueRole: "draft"))
        thresholdFields.add(
            cjguiComposableBooleanInput(23, "notification-enabled", "启用异常提醒", draftEnabled,
                CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "isEnabled",
                operationActionName: "EDIT_DRAFT_BOOLEAN", displayValueRole: "draft"))
        thresholdCard.add(thresholdFields)
        thresholdCard.add(
            cjguiComposableText(24, "applied-summary",
                "当前已应用：${current.channel} / ${current.threshold} / ${if (current.enabled) { "已启用" } else { "已停用" }}",
                bodyStyle, resourceId: CjguiNotificationThresholdDomain.resourceId, fieldId: "notificationConfig",
                displayValueRole: "applied"))
        cards.add(thresholdCard);
        root.add(cards)
        let actions = cjguiComposableHorizontal(30, "notification-actions",
            CjguiComposableUiStyle(fixedHeight: 38, gap: 10))
        actions.add(
            cjguiComposableButton(31, "apply-notification", "应用配置", "APPLY",
                CjguiNotificationThresholdDomain.resourceId,
                CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: actionStyle.background,
                    textColor: actionStyle.textColor, fontFamily: actionStyle.fontFamily),
                operationActionName: "APPLY_DRAFT"))
        actions.add(
            cjguiComposableButton(32, "reset-notification", "恢复已应用值", "RESET",
                CjguiNotificationThresholdDomain.resourceId,
                CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily),
                operationActionName: "CANCEL_DRAFT"))
        actions.add(
            cjguiComposableButton(33, "close-notification", "关闭", "CLOSE", CjguiNotificationThresholdDomain.resourceId,
                CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 34, textColor: headingStyle.textColor,
                    background: CjguiComposableUiColor(0.20, 0.26, 0.38, 1.0),
                    border: CjguiComposableUiColor(0.36, 0.45, 0.62, 1.0))))
        root.add(actions)
        let presentationActions = cjguiComposableHorizontal(37, "notification-presentation-actions",
            CjguiComposableUiStyle(fixedHeight: 38, gap: 10))
        presentationActions.add(
            cjguiComposableButton(34, "toggle-notification-presentation", "切换外观/字体", "TOGGLE_PRESENTATION", -1,
                CjguiComposableUiStyle(fixedWidth: 132, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        presentationActions.add(
            cjguiComposableButton(35, "toggle-notification-beacon", "切换图标", "TOGGLE_BEACON", -1,
                CjguiComposableUiStyle(fixedWidth: 88, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        root.add(presentationActions)
        root.add(
            cjguiComposableText(40, "notification-status",
                "${status} · 草稿 v${draft.draftVersion} / 基线已应用 v${draft.baseAppliedConfigVersion}",
                CjguiComposableUiStyle(fixedHeight: 42, fontSize: bodyStyle.fontSize, fontFamily: bodyStyle.fontFamily,
                    textColor: bodyStyle.textColor, textMaxLines: 2, textOverflow: "ellipsis")))
        return channelPanel.attachTo(root, theme)
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (let Some(result) <- channelPanel.applyUiEvent(event)) {
            return result
        }
        if (event.eventKind == 27 && event.node.nodeId == 36) {
            channelPanel.open(
                "选择投递通道",
                ArrayList<CjguiSearchableSelectionItem>(
                    [
                        CjguiSearchableSelectionItem("邮件", "邮件", detail: "投递到通知邮箱", keywords: "email mail"),
                        CjguiSearchableSelectionItem("短信", "短信", detail: "投递到手机", keywords: "sms"),
                        CjguiSearchableSelectionItem("企业微信", "企业微信", detail: "投递到企业微信", keywords: "wecom")
                    ]
                ),
                CjguiComposableUiNodeReference.manual(13)
            )
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28) {
            let draft = domain.draftSnapshot()
            if (event.node.nodeId == 13) {
                // On Linux the draft field is an owned text surface: its range
                // intent is settled through the bound session sink, so the
                // whole-value event that accompanies it is already applied.
                if (notificationOwnsDraftText()) {
                    return CjguiComposableUiDispatchResult(true)
                }
                let result = domain.editDraftTextFromHuman("deliveryChannel", event.text, draft.draftVersion)
                status = if (result.applied) {
                    "草稿已更新"
                } else {
                    "未更新：${result.reason}"
                };
                localRevision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
            if (event.node.nodeId == 22) {
                let result = domain.editDraftTextFromHuman("triggerThreshold", event.text, draft.draftVersion)
                status = if (result.applied) {
                    "草稿已更新"
                } else {
                    "未更新：${result.reason}"
                };
                localRevision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
        }
        if (event.eventKind == 29 && event.node.nodeId == 23) {
            let draft = domain.draftSnapshot();
            let result = domain.editDraftBooleanFromHuman("isEnabled", event.text == "true", draft.draftVersion)
            status = if (result.applied) {
                "草稿已更新"
            } else {
                "未更新：${result.reason}"
            };
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "TOGGLE_PRESENTATION") {
            usesLightAppearance = !usesLightAppearance
            usesMonospacedText = !usesMonospacedText
            status = if (usesLightAppearance) {
                "已切换到浅色与等宽文字"
            } else {
                "已切换到深色与系统文字"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "TOGGLE_BEACON") {
            usesCoralBeacon = !usesCoralBeacon
            status = if (usesCoralBeacon) {
                "已替换为珊瑚灯塔资源"
            } else {
                "已恢复蓝色灯塔资源"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "RESET") {
            let draft = domain.draftSnapshot();
            let result = domain.cancelDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "草稿已恢复到已应用配置"
            } else {
                "未恢复：${result.reason}"
            };
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        if (event.node.actionName == "APPLY") {
            let draft = domain.draftSnapshot();
            let result = domain.applyDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "已应用通知配置 v${result.versionAfter}"
            } else {
                "未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        status = if (eventKind == 11) {
            "输入队列已满：本次输入未应用，请重试"
        } else {
            "输入未应用：事件 ${eventKind} 的原控件已刷新或移除（节点 ${nodeId}）"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }

    private func presentationTextStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
            padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
            growX: base.growX, growY: base.growY, borderWidth: base.borderWidth, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            }, minWidth: base.minWidth, maxWidth: base.maxWidth, idealWidth: base.idealWidth, minHeight: base.minHeight,
            maxHeight: base.maxHeight, idealHeight: base.idealHeight, alignX: base.alignX, alignY: base.alignY)
    }

    private func interactiveInputStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
        return notificationInteractiveStyle(presentationTextStyle(base))
    }

    private func fixedTextStyle(base: CjguiComposableUiStyle, height: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: height, textColor: base.textColor, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: base.fontFamily)
    }
}

// The draft text field is an owned text surface: the window routes native
// pointer/range input through this source+sink pair, and the same domain write
// is what the external client reads. No second document truth lives here.
private class CjguiNotificationDraftTextBridge <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private let domain: CjguiNotificationThresholdDomain
    private let resourceId: Int64
    private let fieldId: String

    init(domain: CjguiNotificationThresholdDomain, resourceId: Int64, fieldId: String) {
        this.domain = domain
        this.resourceId = resourceId
        this.fieldId = fieldId
    }

    private func currentText(): String {
        return this.domain.draftSnapshot().fieldForResourceId(this.resourceId).draftText
    }

    private func currentVersion(): Int64 {
        return this.domain.draftSnapshot().draftVersion
    }

    public func rangeTextVersion(): Int64 {
        return currentVersion()
    }

    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (currentVersion() != expectedVersion) {
            return false
        }
        return action()
    }

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) {
        let version = currentVersion()
        let size = rangeTextByteLength()
        if (fromVersion == version && startByte >= 0 && endByte >= startByte && endByte <= size) {
            return Some((version, startByte, endByte))
        }
        if (fromVersion < version) {
            // This field is a whole-value draft: an external write replaces the
            // entire value, so the old byte coordinates have no continuation.
            // Its explicit policy is to relocate the caret to the end of the
            // NEW value and report that new version -- never to claim the old
            // coordinates were mapped onto it.
            return Some((version, size, size))
        }
        return None
    }

    public func rangeTextByteLength(): Int64 {
        return Int64(currentText().toArray().size)
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let bytes = currentText().toArray()
        let size = Int64(bytes.size)
        var start = if (startByte < 0) {
            0
        } else if (startByte > size) {
            size
        } else {
            startByte
        }
        while (start < size && (bytes[start] & 0xC0u8) == 0x80u8) {
            start += 1
        }
        var limit = start + (if (maxBytes < 0) {
            0
        } else {
            maxBytes
        })
        if (limit > size) {
            limit = size
        }
        var end = limit
        while (end > start && end < size && (bytes[end] & 0xC0u8) == 0x80u8) {
            end -= 1
        }
        return CjguiRangeTextSlice(startByte, start, String.fromUtf8(bytes.slice(start, end - start)), currentVersion(),
            size, true, "")
    }

    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64, inserted: String): CjguiRangeTextEditOutcome {
        let version = currentVersion()
        if (baseVersion != version) {
            return CjguiRangeTextEditOutcome.conflict(version, "stale_base")
        }
        let bytes = currentText().toArray()
        let size = Int64(bytes.size)
        if (startByte < 0 || endByte < startByte || endByte > size) {
            return CjguiRangeTextEditOutcome.rejected(version, "invalid_range")
        }
        let updated = ArrayList<UInt8>()
        for (byte in bytes.slice(0, startByte)) {
            updated.add(byte)
        }
        for (byte in inserted.toArray()) {
            updated.add(byte)
        }
        for (byte in bytes.slice(endByte, size - endByte)) {
            updated.add(byte)
        }
        let result = this.domain.editDraftTextFromHuman(this.fieldId, String.fromUtf8(updated.toArray()), version)
        if (result.applied) {
            return CjguiRangeTextEditOutcome.accepted(version, this.currentVersion())
        }
        if (result.isVersionConflict) {
            return CjguiRangeTextEditOutcome.conflict(this.currentVersion(), result.reason)
        }
        return CjguiRangeTextEditOutcome.rejected(this.currentVersion(), result.reason)
    }
}

@When[os == "Linux"]
private func notificationInteractiveStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
        padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
        growX: base.growX, growY: base.growY, borderWidth: base.borderWidth, fontSize: base.fontSize,
        fontWeight: base.fontWeight, fontFamily: base.fontFamily, minWidth: base.minWidth, maxWidth: base.maxWidth,
        idealWidth: base.idealWidth, minHeight: base.minHeight, maxHeight: base.maxHeight, idealHeight: base.idealHeight,
        alignX: base.alignX, alignY: base.alignY, pointerInteractive: true)
}

@When[os != "Linux"]
private func notificationInteractiveStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
    return base
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "通知阈值本地 Agent",
        "cjgui-notification-window-agent-20260912",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
                CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
                CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("CONFIGURE_NOTIFICATION_THRESHOLD", all, true)
            ]
        )
    )
}

@When[os == "macOS" || os == "Linux"]
private func notificationInitialTextFocus(window: CjguiComposableUiWindow): Unit {
    let _ = window.requestInitialOwnedTextFocusRestore()
}

@When[os != "macOS" && os != "Linux"]
private func notificationInitialTextFocus(window: CjguiComposableUiWindow): Unit {}

@When[os == "Linux"]
private func notificationOwnsDraftText(): Bool {
    return true
}

@When[os != "Linux"]
private func notificationOwnsDraftText(): Bool {
    return false
}

@When[os == "Linux"]
private func notificationBindDraftTextSession(window: CjguiComposableUiWindow, bridge: CjguiNotificationDraftTextBridge): Unit {
    let _ = window.bindRangeTextSession(13, "delivery-channel", bridge, bridge,
        CjguiNotificationThresholdDomain.resourceId, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
}

@When[os != "Linux"]
private func notificationBindDraftTextSession(window: CjguiComposableUiWindow, bridge: CjguiNotificationDraftTextBridge): Unit {}

private func runNotificationWindow(): Int32 {
    let domain = CjguiNotificationThresholdDomain()
    let controller = CjguiNotificationThresholdController(domain)
    let host = cjguiCreatePlatformApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("通知阈值", 840u32, 520u32)
    )
    let window = host.window()
    // The draft channel field is the one editable text surface in this window.
    // Its public interaction declaration is an owned range session; the sink
    // writes the same domain field that the external operation channel exposes.
    let draftBridge = CjguiNotificationDraftTextBridge(domain, 9101, "deliveryChannel")
    notificationBindDraftTextSession(window, draftBridge)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) || !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    notificationInitialTextFocus(window)
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut();
        output.writeln("CJGUI_NOTIFICATION_READY DESCRIPTOR_PATH ${info.descriptorPath}");
        output.writeln("CJGUI_NOTIFICATION_READY PROTOCOL ${info.protocol}");
        output.flush()
    }
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        controller.finishPanelAction(window)
    }
    host.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size != 0) {
        getStdErr().writeln("usage: CJGUINotificationThreshold");
        return 2
    }
    return Int64(runNotificationWindow())
}
