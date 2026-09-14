package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_notification_threshold_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private class CjguiNotificationThresholdController <: CjguiComposableUiController {
    private let domain: CjguiNotificationThresholdDomain
    private var localRevision: Int64
    private var status: String
    private var usesLightAppearance: Bool
    private var usesCoralBeacon: Bool
    private var usesMonospacedText: Bool

    init(domain: CjguiNotificationThresholdDomain) {
        this.domain = domain; this.localRevision = 1; this.status = "编辑后应用通知阈值配置"
        this.usesLightAppearance = false; this.usesCoralBeacon = false; this.usesMonospacedText = false
    }
    public func uiSceneVersion(): Int64 { return localRevision }
    public func buildUi(): CjguiComposableUiNode {
        let current = domain.notificationSnapshot()
        let draft = domain.draftSnapshot()
        let theme = if (usesLightAppearance) { CjguiComposableUiTheme.paperLight() } else { CjguiComposableUiTheme.beaconDark() }
        let headingStyle = presentationTextStyle(theme.heading)
        let bodyStyle = presentationTextStyle(theme.body)
        let inputStyle = presentationTextStyle(theme.input)
        let actionStyle = presentationTextStyle(theme.primaryAction)
        let beaconPath = if (usesCoralBeacon) { "composable-beacon-coral.png" } else { "composable-beacon.png" }
        let beaconVersion = if (usesCoralBeacon) { 2 } else { 1 }
        let draftChannel = draft.fieldForResourceId(9101).draftText
        let draftThreshold = draft.fieldForResourceId(9102).draftText
        let draftEnabled = draft.fieldForResourceId(9103).draftText == "true"
        let root = cjguiComposableVertical(1, "notification-root", theme.page)
        let hero = cjguiComposableHorizontal(4, "notification-hero", CjguiComposableUiStyle(fixedHeight: 84, gap: 12))
        let heroCopy = cjguiComposableVertical(5, "notification-hero-copy", CjguiComposableUiStyle(growX: 1, gap: 4))
        heroCopy.add(cjguiComposableText(2, "notification-title", "异常提醒阈值", headingStyle))
        heroCopy.add(cjguiComposableText(3, "notification-subtitle", "通知通道、触发阈值与开关是独立通知领域的实际配置。", bodyStyle))
        hero.add(heroCopy)
        hero.add(cjguiComposableImage(6, "notification-beacon", beaconPath, CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 76), imageResourceId: "notification-beacon", imageResourceVersion: beaconVersion))
        root.add(hero)
        let cards = cjguiComposableHorizontal(10, "notification-cards", CjguiComposableUiStyle(growY: 1, gap: 16))
        let channelCard = cjguiComposableVertical(11, "channel-card", CjguiComposableUiStyle(fixedWidth: 360, padding: theme.card.padding, gap: theme.card.gap, background: theme.card.background, border: theme.card.border))
        channelCard.add(cjguiComposableText(12, "channel-heading", "投递通道", fixedTextStyle(headingStyle, 24)))
        channelCard.add(cjguiComposableTextInput(13, "delivery-channel", "通道", draftChannel,
            CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "deliveryChannel", operationActionName: "EDIT_DRAFT_TEXT", displayValueRole: "draft"))
        channelCard.add(cjguiComposableText(14, "channel-help", "例如：邮件、短信、企业微信", fixedTextStyle(bodyStyle, 22)))
        cards.add(channelCard)
        let thresholdCard = cjguiComposableVertical(20, "threshold-card", CjguiComposableUiStyle(growX: 1, padding: theme.card.padding, gap: theme.card.gap, background: theme.card.background, border: theme.card.border))
        thresholdCard.add(cjguiComposableText(21, "threshold-heading", "触发条件", fixedTextStyle(headingStyle, 24)))
        // This grouping is declared only by the consumer. The external window
        // context is derived from this tree, so no domain relation table needs
        // a matching update when the arrangement changes.
        let thresholdFields = cjguiComposableVertical(25, "threshold-fields", CjguiComposableUiStyle(gap: 8))
        thresholdFields.add(cjguiComposableIntegerInput(22, "trigger-threshold", "阈值（1–100）", draftThreshold,
            CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "triggerThreshold", operationActionName: "EDIT_DRAFT_TEXT", displayValueRole: "draft"))
        thresholdFields.add(cjguiComposableBooleanInput(23, "notification-enabled", "启用异常提醒", draftEnabled,
            CjguiNotificationThresholdDomain.resourceId, inputStyle, fieldId: "isEnabled", operationActionName: "EDIT_DRAFT_BOOLEAN", displayValueRole: "draft"))
        thresholdCard.add(thresholdFields)
        thresholdCard.add(cjguiComposableText(24, "applied-summary", "当前已应用：${current.channel} / ${current.threshold} / ${if (current.enabled) { "已启用" } else { "已停用" }}", bodyStyle,
            resourceId: CjguiNotificationThresholdDomain.resourceId, fieldId: "notificationConfig", displayValueRole: "applied"))
        cards.add(thresholdCard); root.add(cards)
        let actions = cjguiComposableHorizontal(30, "notification-actions", CjguiComposableUiStyle(fixedHeight: 38, gap: 10))
        actions.add(cjguiComposableButton(31, "apply-notification", "应用配置", "APPLY", CjguiNotificationThresholdDomain.resourceId,
            actionStyle, operationActionName: "APPLY_DRAFT"))
        actions.add(cjguiComposableButton(32, "reset-notification", "恢复已应用值", "RESET", CjguiNotificationThresholdDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 34, background: theme.card.background, border: theme.card.border, fontFamily: actionStyle.fontFamily), operationActionName: "CANCEL_DRAFT"))
        actions.add(cjguiComposableButton(33, "close-notification", "关闭", "CLOSE", CjguiNotificationThresholdDomain.resourceId, CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 34, background: CjguiComposableUiColor(0.20, 0.26, 0.38, 1.0), border: CjguiComposableUiColor(0.36, 0.45, 0.62, 1.0))))
        actions.add(cjguiComposableButton(34, "toggle-notification-presentation", "切换外观/字体", "TOGGLE_PRESENTATION", -1,
            CjguiComposableUiStyle(fixedWidth: 132, fixedHeight: 34, background: theme.card.background, border: theme.card.border, fontFamily: actionStyle.fontFamily)))
        actions.add(cjguiComposableButton(35, "toggle-notification-beacon", "切换图标", "TOGGLE_BEACON", -1,
            CjguiComposableUiStyle(fixedWidth: 88, fixedHeight: 34, background: theme.card.background, border: theme.card.border, fontFamily: actionStyle.fontFamily)))
        root.add(actions)
        root.add(cjguiComposableText(40, "notification-status", "${status} · 草稿 v${draft.draftVersion} / 基线已应用 v${draft.baseAppliedConfigVersion}", fixedTextStyle(bodyStyle, 26)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28) {
            let draft = domain.draftSnapshot()
            if (event.node.nodeId == 13) {
                let result = domain.editDraftTextFromHuman("deliveryChannel", event.text, draft.draftVersion)
                status = if (result.applied) { "草稿已更新" } else { "未更新：${result.reason}" }; localRevision += 1; return CjguiComposableUiDispatchResult(result.applied)
            }
            if (event.node.nodeId == 22) {
                let result = domain.editDraftTextFromHuman("triggerThreshold", event.text, draft.draftVersion)
                status = if (result.applied) { "草稿已更新" } else { "未更新：${result.reason}" }; localRevision += 1; return CjguiComposableUiDispatchResult(result.applied)
            }
        }
        if (event.eventKind == 29 && event.node.nodeId == 23) {
            let draft = domain.draftSnapshot(); let result = domain.editDraftBooleanFromHuman("isEnabled", event.text == "true", draft.draftVersion)
            status = if (result.applied) { "草稿已更新" } else { "未更新：${result.reason}" }; localRevision += 1; return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) { return CjguiComposableUiDispatchResult(false) }
        if (event.node.actionName == "TOGGLE_PRESENTATION") {
            usesLightAppearance = !usesLightAppearance; usesMonospacedText = !usesMonospacedText
            status = if (usesLightAppearance) { "已切换到浅色与等宽文字" } else { "已切换到深色与系统文字" }
            localRevision += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "TOGGLE_BEACON") {
            usesCoralBeacon = !usesCoralBeacon
            status = if (usesCoralBeacon) { "已替换为珊瑚灯塔资源" } else { "已恢复蓝色灯塔资源" }
            localRevision += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "RESET") {
            let draft = domain.draftSnapshot(); let result = domain.cancelDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) { "草稿已恢复到已应用配置" } else { "未恢复：${result.reason}" }; localRevision += 1; return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.actionName == "CLOSE") { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
        if (event.node.actionName == "APPLY") {
            let draft = domain.draftSnapshot(); let result = domain.applyDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) { "已应用通知配置 v${result.versionAfter}" } else { "未应用：${result.reason}" }
            localRevision += 1; return CjguiComposableUiDispatchResult(result.applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        status = if (eventKind == 11) { "输入队列已满：本次输入未应用，请重试" }
            else { "输入未应用：事件 ${eventKind} 的原控件已刷新或移除（节点 ${nodeId}）" }
        localRevision += 1; return CjguiComposableUiDispatchResult(true)
    }

    private func presentationTextStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
            padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
            growX: base.growX, growY: base.growY, borderWidth: base.borderWidth, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: if (usesMonospacedText) { "monospaced" } else { "system" },
            minWidth: base.minWidth, maxWidth: base.maxWidth, idealWidth: base.idealWidth,
            minHeight: base.minHeight, maxHeight: base.maxHeight, idealHeight: base.idealHeight,
            alignX: base.alignX, alignY: base.alignY)
    }

    private func fixedTextStyle(base: CjguiComposableUiStyle, height: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: height, textColor: base.textColor, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: base.fontFamily)
    }
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization("通知阈值本地 Agent", "cjgui-notification-window-agent-20260912", ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
        CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
        CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
        CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true),
        CjguiSharedOperationExternalActionScope("CONFIGURE_NOTIFICATION_THRESHOLD", all, true)
    ]))
}

private func runNotificationWindow(): Int32 {
    let domain = CjguiNotificationThresholdDomain()
    let host = CjguiMacosApplicationHost(
        CjguiNotificationThresholdController(domain),
        configuration: CjguiMacosApplicationWindowConfiguration("通知阈值", 840u32, 520u32)
    )
    let window = host.window()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) || !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut(); output.writeln("CJGUI_NOTIFICATION_READY DESCRIPTOR_PATH ${info.descriptorPath}"); output.writeln("CJGUI_NOTIFICATION_READY PROTOCOL ${info.protocol}"); output.flush()
    }
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    host.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { getStdErr().writeln("usage: CJGUINotificationThreshold"); return 2 }
    return Int64(runNotificationWindow())
}
