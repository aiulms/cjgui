package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_notification_threshold_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private class CjguiNotificationThresholdController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiContextMenuRequestHandler {
    private let domain: CjguiNotificationThresholdDomain
    private var localRevision: Int64
    private var status: String
    private var usesLightAppearance: Bool
    private var usesCoralBeacon: Bool
    private var usesMonospacedText: Bool
    private let channelPanel = CjguiSearchableSelectionPanel("notification-channel")
    private var panelWindow: ?CjguiComposableUiWindow = None
    private let form: CjguiGeneratedUiFormBinding
    private let generated: CjguiGeneratedUiWindowRegion
    private let commandScope = CjguiComposableUiIdentityScope("notification-commands")
    private let contextMenu = CjguiContextCommandMenu(
        CjguiComposableUiIdentityScope("notification-threshold-menu"), "notification-threshold-menu")
    private let formViewport = CjguiComposableUiScrollViewport()
    private var helpVisible = false
    private let helpReturn = CjguiComposableUiNodeReference.manual(43)
    // Linux dual-window seam: the preview session owns the second host and the
    // shared font registry; this window only forwards explicit user actions.
    private var previewActionHandler: Option<(String) -> (Bool, String)> = None

    public func bindPreviewActionHandler(handler: (String) -> (Bool, String)): Unit {
        previewActionHandler = Some(handler)
    }

    public func bindWindow(window: CjguiComposableUiWindow): Unit {
        panelWindow = Some(window)
        generated.attachWindow(window)
    }
    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion {
        return generated
    }

    init(domain: CjguiNotificationThresholdDomain) {
        this.domain = domain
        this.form = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
        this.generated = CjguiGeneratedUiWindowRegion(notificationGeneratedCatalog(domain, form), form,
            "notification-generated-form")
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
        return localRevision + draft.draftVersion * 1000003 + current.version * 7919 + channelPanel.revision() +
            generated.revision()
    }
    public func beginSceneRefresh(): Bool {
        return generated.beginSceneRefresh()
    }
    public func prepareSceneRefresh(): Bool {
        return generated.prepareSceneRefresh()
    }
    public func commitSceneRefresh(): Unit {
        generated.commitSceneRefresh()
    }
    public func rollbackSceneRefresh(): Unit {
        generated.rollbackSceneRefresh()
    }
    public func disposeSceneRefreshResources(): Unit {
        generated.disposeSceneRefreshResources()
    }
    private func currentTheme(): CjguiComposableUiTheme {
        return if (usesLightAppearance) {
            CjguiComposableUiTheme.paperLight()
        } else {
            CjguiComposableUiTheme.beaconDark()
        }
    }

    private func commandPresentation(): CjguiCommandPresentation {
        let canApply = form.actionAvailable("APPLY_DRAFT")
        let commands = ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("notification.command.apply",
                CjguiComposableUiNodeReference.manual(31), "应用通知配置", "Actions", 0, canApply, false),
            CjguiComposableUiCommand("notification.command.reset",
                CjguiComposableUiNodeReference.manual(32), "恢复已应用值", "Actions", 1, true, false),
            CjguiComposableUiCommand("notification.command.presentation",
                CjguiComposableUiNodeReference.manual(34), "切换外观与字体", "View", 0, true, usesLightAppearance,
                isCheckable: true),
            CjguiComposableUiCommand("notification.command.beacon",
                CjguiComposableUiNodeReference.manual(35), "切换图标资源", "View", 1, true, usesCoralBeacon,
                isCheckable: true),
            CjguiComposableUiCommand("notification.command.close",
                CjguiComposableUiNodeReference.manual(33), "关闭窗口", "File", 0, true, false),
            CjguiComposableUiCommand("notification-channel-picker",
                CjguiComposableUiNodeReference.manual(36), "选择投递通道",
                CjguiComposableUiShortcut("k"), "Settings", 0, true, false)
        ])
        let metadata = ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("notification.command.apply", "APPLY",
                CjguiNotificationThresholdDomain.resourceId,
                detail: "把当前草稿应用为通知配置", disabledReason: "草稿存在字段错误或应用基线已变化"),
            CjguiCommandToolbarMetadata("notification.command.reset", "RESET",
                CjguiNotificationThresholdDomain.resourceId, detail: "恢复到已应用的通知配置"),
            CjguiCommandToolbarMetadata("notification.command.presentation", "TOGGLE_PRESENTATION", -1,
                detail: "切换浅/深色与等宽字体；打开中的命令面板保留查询与导航"),
            CjguiCommandToolbarMetadata("notification.command.beacon", "TOGGLE_BEACON", -1,
                detail: "切换珊瑚/蓝色灯塔资源"),
            CjguiCommandToolbarMetadata("notification.command.close", "CLOSE",
                CjguiNotificationThresholdDomain.resourceId, detail: "正常关闭窗口"),
            CjguiCommandToolbarMetadata("notification-channel-picker", "CHOOSE_CHANNEL", 0,
                detail: "打开投递通道选择；也可按 ⌘K")
        ])
        return CjguiCommandPresentation(commands, metadata)
    }

    private func contextPresentation(): CjguiCommandPresentation {
        let canApply = form.actionAvailable("APPLY_DRAFT")
        // Every context command names the threshold input as its target; the
        // request itself still owns the accepted target and invocation path.
        let commands = ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("notification.context.apply",
                CjguiComposableUiNodeReference.manual(22), "应用通知配置", "", 0, canApply, false),
            CjguiComposableUiCommand("notification.context.reset",
                CjguiComposableUiNodeReference.manual(22), "恢复已应用值", "", 1, true, false),
            CjguiComposableUiCommand("notification.context.presentation",
                CjguiComposableUiNodeReference.manual(22), "切换外观与字体", "", 2, true, usesLightAppearance,
                isCheckable: true),
            CjguiComposableUiCommand("notification.context.beacon",
                CjguiComposableUiNodeReference.manual(22), "切换图标资源", "", 3, true, usesCoralBeacon,
                isCheckable: true)
        ])
        let metadata = ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("notification.context.apply", "APPLY", 0,
                disabledReason: "草稿存在字段错误或应用基线已变化"),
            CjguiCommandToolbarMetadata("notification.context.reset", "RESET", 0),
            CjguiCommandToolbarMetadata("notification.context.presentation", "TOGGLE_PRESENTATION", 0),
            CjguiCommandToolbarMetadata("notification.context.beacon", "TOGGLE_BEACON", 0)
        ])
        return CjguiCommandPresentation(commands, metadata)
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = commandPresentation().commands
        for (command in channelPanel.commands()) {
            commands.add(command)
        }
        return commands
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        if (request.nodeId != 22) {
            return false
        }
        let window = match (panelWindow) {
            case Some(value) => value
            case None => return false
        }
        // These rows target the threshold field itself and are not window-level
        // commands, so they declare RequestLocal. The window still checks the
        // frozen request target and dispatches through invokeContextMenuCommand
        // into the same business action as the toolbar.
        let opened = contextMenu.open(window, request, contextPresentation(), "notification-threshold",
            source: CjguiContextMenuCommandSource.RequestLocal,
            style: CjguiContextCommandMenuStyle.themed(currentTheme()))
        status = if (opened) {
            "阈值上下文菜单已打开；命令来自同一通知命令集"
        } else {
            "上下文菜单未打开：命令已移除或请求被拒绝"
        }
        localRevision += 1
        return opened
    }

    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        if (!contextMenu.requestEnded(requestId)) {
            return
        }
        status = "上下文菜单已结束：${reason}"
        localRevision += 1
        match (panelWindow) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    private func performNotificationAction(actionName: String): Bool {
        if (actionName == "TOGGLE_PRESENTATION") {
            usesLightAppearance = !usesLightAppearance
            usesMonospacedText = !usesMonospacedText
            let _ = contextMenu.restyle(CjguiContextCommandMenuStyle.themed(currentTheme()))
            status = if (usesLightAppearance) {
                "已切换到浅色与等宽文字"
            } else {
                "已切换到深色与系统文字"
            }
            localRevision += 1
            return true
        }
        if (actionName == "TOGGLE_BEACON") {
            usesCoralBeacon = !usesCoralBeacon
            status = if (usesCoralBeacon) {
                "已替换为珊瑚灯塔资源"
            } else {
                "已恢复蓝色灯塔资源"
            }
            localRevision += 1
            return true
        }
        if (actionName == "OPEN_PREVIEW" || actionName == "SWITCH_PREVIEW_FONT" ||
            actionName == "CLOSE_PREVIEW") {
            if (let Some(handler) <- previewActionHandler) {
                let (handled, message) = handler(actionName)
                status = message
                localRevision += 1
                return handled
            }
            status = "当前平台未启用双窗口预览"
            localRevision += 1
            return false
        }
        if (actionName == "RESET") {
            let draft = domain.draftSnapshot()
            let result = domain.cancelDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "草稿已恢复到已应用配置"
            } else {
                "未恢复：${result.reason}"
            }
            localRevision += 1
            return result.applied
        }
        if (actionName == "APPLY") {
            let draft = domain.draftSnapshot()
            let result = domain.applyDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "已应用通知配置 v${result.versionAfter}"
            } else {
                "未应用：${result.reason}"
            }
            localRevision += 1
            return result.applied
        }
        return false
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
        let theme = currentTheme()
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
        let declarations = domain.formBinding()
        let channelField = declarations.fieldAtControlIndex(0)
        let thresholdField = declarations.fieldAtControlIndex(1)
        let enabledField = declarations.fieldAtControlIndex(2)
        let draftChannel = draft.fieldForResourceId(channelField.resourceId).draftText
        let draftThreshold = draft.fieldForResourceId(thresholdField.resourceId).draftText
        let draftEnabled = draft.fieldForResourceId(enabledField.resourceId).draftText == "true"
        let root = cjguiComposableVertical(1, "notification-root",
            CjguiComposableUiStyle(padding: 16, gap: 10, background: theme.page.background))
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
        let cards = cjguiComposableHorizontal(10, "notification-cards", CjguiComposableUiStyle(fixedHeight: 180, gap: 16))
        let channelCard = cjguiComposableVertical(11, "channel-card",
            CjguiComposableUiStyle(growX: 1, padding: theme.card.padding, gap: theme.card.gap,
                background: theme.card.background, border: theme.card.border))
        channelCard.add(cjguiComposableText(12, "channel-heading", "投递通道", fixedTextStyle(headingStyle, 24)))
        channelCard.add(
            cjguiComposableTextInput(13, "delivery-channel", channelField.label, draftChannel, channelField.resourceId,
                inputStyle, fieldId: channelField.fieldId,
                operationActionName: form.fieldSpec(channelField.fieldId).getOrThrow().writeActionName,
                operationResourceId: CjguiNotificationThresholdDomain.resourceId, displayValueRole: "draft"))
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
        let thresholdSpec = form.fieldSpec(thresholdField.fieldId).getOrThrow()
        let thresholdBinding = CjguiNumericStepperBinding(2200, "trigger-threshold-group", 2201, 2202,
            22, "trigger-threshold", 2203, "trigger-threshold-down", 2204, "trigger-threshold-up",
            thresholdField.label, draftThreshold, thresholdSpec.minimum, thresholdSpec.maximum, 1,
            thresholdField.fieldId, thresholdSpec.writeActionName, thresholdField.resourceId,
            CjguiNotificationThresholdDomain.resourceId, "STEP_THRESHOLD_DOWN", "STEP_THRESHOLD_UP")
        thresholdFields.add(CjguiNumericStepper.build(thresholdBinding,
            style: CjguiNumericStepperStyle(input: inputStyle,
                button: CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 26))))
        thresholdFields.add(
            cjguiComposableBooleanInput(23, "notification-enabled", enabledField.label, draftEnabled,
                enabledField.resourceId, inputStyle, fieldId: enabledField.fieldId,
                operationActionName: form.fieldSpec(enabledField.fieldId).getOrThrow().writeActionName,
                operationResourceId: CjguiNotificationThresholdDomain.resourceId, displayValueRole: "draft"))
        thresholdCard.add(thresholdFields)
        thresholdCard.add(
            cjguiComposableText(24, "applied-summary",
                "当前已应用：${current.channel} / ${current.threshold} / ${if (current.enabled) { "已启用" } else { "已停用" }}",
                bodyStyle, resourceId: CjguiNotificationThresholdDomain.resourceId, fieldId: "notificationConfig",
                displayValueRole: "applied"))
        cards.add(thresholdCard);
        root.add(cards)
        // Toolbar and menu consume one declaration holder; both route through
        // the shared command entries rather than a second action table.
        root.add(cjguiComposableCommandToolbar(commandScope, "notification-command-bar",
            commandPresentation().placement(), style: CjguiCommandToolbarStyle.themed(theme),
            searchLabel: "", searchActionName: "", searchResourceId: -1))
        root.add(
            cjguiComposableText(41, "notification-generated-heading", "运行时区域 · 与上方共用同一草稿",
                CjguiComposableUiStyle(fixedHeight: 26, fontSize: bodyStyle.fontSize, textColor: bodyStyle.textColor,
                    textMaxLines: 1, textOverflow: "ellipsis")))
        let generatedHost = cjguiComposableVertical(42, "notification-generated-host",
            CjguiComposableUiStyle(fixedHeight: 250, padding: 12, gap: 8, background: theme.card.background,
                border: theme.card.border))
        generatedHost.add(generated.buildNode())
        root.add(generatedHost)
        root.add(
            cjguiComposableText(59, "notification-checklist-heading", "交付检查 · 手写说明与生成区域共用同一草稿",
                CjguiComposableUiStyle(fixedHeight: 28, fontSize: bodyStyle.fontSize, textColor: bodyStyle.textColor,
                    textMaxLines: 1, textOverflow: "ellipsis")))
        let checklist = cjguiComposableVertical(60, "notification-checklist",
            CjguiComposableUiStyle(gap: 6, padding: 10, background: theme.card.background,
                border: theme.card.border))
        let checklistRows = ArrayList<String>([
            "① 投递通道既是手写输入，也是生成区域的同一字段；两个入口读写同一个草稿。",
            "② 窗口缩窄后先滚动，再点击字段；Tab 与 Shift+Tab 会把下一字段带入视口。",
            "③ 中文组合提交前若 owner 被外部修改，提交会被拒绝并重锚，不会拼入旧预编辑。",
            "④ 运行时区域重排只改变结构，不另存业务状态；重排后续写仍落在同一 owner。",
            "⑤ 应用配置把草稿提升为已应用值；恢复已应用值取消尚未应用的草稿。",
            "⑥ 说明弹层由共同层管理焦点返回；Esc 与“返回编辑”走同一条关闭路径。"
        ])
        for (index in 0..checklistRows.size) {
            checklist.add(
                cjguiComposableText(61 + index, "notification-checklist-${index}", checklistRows[index],
                    CjguiComposableUiStyle(fixedHeight: 40, fontSize: bodyStyle.fontSize,
                        fontFamily: bodyStyle.fontFamily, textColor: bodyStyle.textColor, textMaxLines: 2,
                        textOverflow: "ellipsis")))
        }
        root.add(checklist)
        let helpRow = cjguiComposableHorizontal(67, "notification-help-row",
            CjguiComposableUiStyle(fixedHeight: 36, gap: 10))
        helpRow.add(
            cjguiComposableButton(43, "notification-open-help", "配置说明", "SHOW_NOTIFICATION_HELP", -1,
                CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        root.add(helpRow)
        let actions = cjguiComposableHorizontal(30, "notification-actions",
            CjguiComposableUiStyle(fixedHeight: 38, gap: 10))
        actions.add(
            cjguiComposableButton(31, "apply-notification", "应用配置", "APPLY",
                CjguiNotificationThresholdDomain.resourceId,
                CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: actionStyle.background,
                    textColor: actionStyle.textColor, fontFamily: actionStyle.fontFamily),
                enabled: form.actionAvailable("APPLY_DRAFT"), operationActionName: "APPLY_DRAFT"))
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
        presentationActions.add(
            cjguiComposableButton(38, "open-notification-preview", "打开预览窗", "OPEN_PREVIEW", -1,
                CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        presentationActions.add(
            cjguiComposableButton(39, "switch-preview-font", "切换字体版本", "SWITCH_PREVIEW_FONT", -1,
                CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        presentationActions.add(
            cjguiComposableButton(70, "close-notification-preview", "关闭预览窗", "CLOSE_PREVIEW", -1,
                CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: theme.card.background,
                    border: theme.card.border, textColor: bodyStyle.textColor, fontFamily: actionStyle.fontFamily)))
        root.add(presentationActions)
        root.add(
            cjguiComposableText(40, "notification-status",
                "${status} · 草稿 v${draft.draftVersion} / 基线已应用 v${draft.baseAppliedConfigVersion}",
                CjguiComposableUiStyle(fixedHeight: 42, fontSize: bodyStyle.fontSize, fontFamily: bodyStyle.fontFamily,
                    textColor: bodyStyle.textColor, textMaxLines: 2, textOverflow: "ellipsis")))
        let host = cjguiComposableLayerHost(100, "notification-layer-host",
            CjguiComposableUiStyle(growX: 1, growY: 1))
        // One shared viewport carries wheel navigation, accepted extents and
        // Tab focus reveal; the application does not compute scroll offsets.
        let scroll = cjguiComposableScrollArea(90, "notification-form-scroll", formViewport,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        scroll.add(root)
        host.add(scroll)
        contextMenu.attachTo(host)
        if (helpVisible) {
            let dialog = cjguiComposableDialogLayerWithReference(45, "notification-help-dialog", "notification-help",
                "notification-layer-host", helpReturn,
                CjguiComposableUiStyle(fixedWidth: 440, fixedHeight: 226, padding: 18, gap: 12,
                    background: theme.card.background, border: theme.card.border),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(46)))
            dialog.add(cjguiComposableText(47, "notification-help-title", "配置说明", headingStyle))
            dialog.add(
                cjguiComposableText(48, "notification-help-body",
                    "当前已应用：${current.channel} / ${current.threshold} / ${if (current.enabled) { "已启用" } else { "已停用" }}。\n窗口可滚动；Tab 会把目标字段带入视口。\n按 Esc 或“返回编辑”关闭本说明，焦点回到打开它的字段。",
                    CjguiComposableUiStyle(fontSize: bodyStyle.fontSize, fontFamily: bodyStyle.fontFamily,
                        textColor: bodyStyle.textColor, textMaxLines: 3, textOverflow: "ellipsis")))
            dialog.add(
                cjguiComposableButton(46, "notification-help-close", "返回编辑", "CLOSE_NOTIFICATION_HELP", -1,
                    CjguiComposableUiStyle(fixedWidth: 108, fixedHeight: 34, background: actionStyle.background,
                        textColor: actionStyle.textColor, fontFamily: actionStyle.fontFamily)))
            host.add(dialog)
        }
        return channelPanel.attachTo(host, theme)
    }

    private func commandActionName(commandId: String): String {
        let ids = ArrayList<String>([
            "notification.command.apply", "notification.command.reset",
            "notification.command.presentation", "notification.command.beacon", "notification.context.apply",
            "notification.context.reset", "notification.context.presentation", "notification.context.beacon"
        ])
        let actions = ArrayList<String>([
            "APPLY", "RESET", "TOGGLE_PRESENTATION", "TOGGLE_BEACON", "APPLY", "RESET",
            "TOGGLE_PRESENTATION", "TOGGLE_BEACON"
        ])
        for (index in 0..ids.size) {
            if (ids[index] == commandId) {
                return actions[index]
            }
        }
        return ""
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (let Some(window) <- panelWindow) {
            if (let Some(result) <- contextMenu.applyUiEvent(event, window)) {
                return result
            }
        }
        if (event.eventKind == 27 && event.node.nodeId == 43) {
            helpVisible = true
            status = "配置说明已打开；弹层由共同层管理焦点返回"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == 46) {
            helpVisible = false
            status = "配置说明已关闭；焦点返回打开它的按钮"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 36 && helpVisible) {
            helpVisible = false
            status = "配置说明已关闭：escape"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && (event.text.startsWith("notification.command.") ||
            event.text.startsWith("notification.context."))) {
            let action = commandActionName(event.text)
            if (action.size > 0) {
                return CjguiComposableUiDispatchResult(performNotificationAction(action))
            }
        }
        if (event.eventKind == 27) {
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                if (let Some(window) <- panelWindow) {
                    let applied = window.invokeCommand(commandId)
                    if (!applied) {
                        status = "命令未执行：目标已失效或命令已禁用"
                        localRevision += 1
                    }
                    return CjguiComposableUiDispatchResult(applied)
                }
                return CjguiComposableUiDispatchResult(false)
            }
        }
        let generatedResult = generated.handleEvent(event)
        if (generatedResult.didApply) {
            return generatedResult
        }
        if (let Some(window) <- panelWindow) {
            let formResult = form.handleFormEvent(event, window)
            if (formResult.didApply) {
                return formResult
            }
        }
        if (let Some(result) <- channelPanel.applyUiEvent(event)) {
            return result
        }
        if (event.eventKind == 27 && event.node.nodeId == 36) {
            let returnTarget = match (panelWindow) {
                case Some(window) => window.editingFocusReference() ?? window.focusedNodeReference() ??
                    CjguiComposableUiNodeReference.manual(36)
                case None => CjguiComposableUiNodeReference.manual(36)
            }
            channelPanel.open(
                "选择投递通道",
                ArrayList<CjguiSearchableSelectionItem>(
                    [
                        CjguiSearchableSelectionItem("邮件", "邮件", detail: "投递到通知邮箱", keywords: "email mail"),
                        CjguiSearchableSelectionItem("短信", "短信", detail: "投递到手机", keywords: "sms"),
                        CjguiSearchableSelectionItem("企业微信", "企业微信", detail: "投递到企业微信", keywords: "wecom")
                    ]
                ),
                returnTarget
            )
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 &&
            (event.node.actionName == "STEP_THRESHOLD_DOWN" || event.node.actionName == "STEP_THRESHOLD_UP")) {
            let field = form.fieldSpec("triggerThreshold").getOrThrow()
            let current = domain.formSnapshot().fieldForResourceId(field.resourceId).draftText
            let direction = if (event.node.actionName == "STEP_THRESHOLD_UP") {
                CJGUI_NUMERIC_STEP_UP
            } else {
                CJGUI_NUMERIC_STEP_DOWN
            }
            let stepped = CjguiNumericStepper.resolve(current, direction, field.minimum, field.maximum, 1)
            if (!stepped.canWrite()) {
                status = "阈值步进被拒：${stepped.issue}"
                localRevision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            let result = domain.editTextFromHuman(field.resourceId, stepped.text, 0, stepped.text.size)
            status = if (result.applied) {
                "阈值草稿已步进为 ${stepped.text}"
            } else {
                "阈值步进被拒：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        if (event.node.actionName == "TOGGLE_PRESENTATION" || event.node.actionName == "TOGGLE_BEACON" ||
            event.node.actionName == "RESET" || event.node.actionName == "APPLY" ||
            event.node.actionName == "OPEN_PREVIEW" || event.node.actionName == "SWITCH_PREVIEW_FONT" ||
            event.node.actionName == "CLOSE_PREVIEW") {
            return CjguiComposableUiDispatchResult(performNotificationAction(event.node.actionName))
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

    public func fieldResourceId(): Int64 {
        return this.resourceId
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
                CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
                CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
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
    let _ = window.bindRangeTextSession(13, "delivery-channel", bridge, bridge, bridge.fieldResourceId(),
        CJGUI_COMPOSABLE_UI_TEXT_INPUT)
}

@When[os != "Linux"]
private func notificationBindDraftTextSession(window: CjguiComposableUiWindow, bridge: CjguiNotificationDraftTextBridge): Unit {}

@When[os == "Linux"]
private func runNotificationWindow(): Int32 {
    let domain = CjguiNotificationThresholdDomain()
    let controller = CjguiNotificationThresholdController(domain)
    let group = CjguiLinuxApplicationHostGroup()
    let host = CjguiLinuxApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("通知配置 · 手写与生成", 1000u32, 860u32)
    )
    let window = host.window()
    controller.bindWindow(window)
    let draftBridge = CjguiNotificationDraftTextBridge(domain, 9101, "deliveryChannel")
    notificationBindDraftTextSession(window, draftBridge)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    let _ = group.add(host)
    let fonts = CjguiNotificationPreviewFonts()
    cjguiNotificationPreviewFontReport(fonts)
    let session = CjguiNotificationPreviewSession(group, fonts,
        createController: { => CjguiNotificationPreviewController(domain, fonts) })
    controller.bindPreviewActionHandler({action => session.perform(action)})
    let (previewOpened, previewMessage) = session.openPreviewNow()
    if (!previewOpened) {
        host.close()
        fonts.close()
        return 1
    }
    cjguiPreviewLog("CJGUI_PREVIEW_READY ${previewMessage} windows=${group.count()}")
    notificationInitialTextFocus(window)
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut();
        output.writeln("CJGUI_NOTIFICATION_READY DESCRIPTOR_PATH ${info.descriptorPath}");
        output.writeln("CJGUI_NOTIFICATION_READY PROTOCOL ${info.protocol}");
        output.flush()
    }
    while (group.pumpOneTurn()) {
        if (host.isOpen()) {
            controller.finishPanelAction(window)
        }
        session.finishTurn()
    }
    session.dispose()
    group.closeAll()
    fonts.close()
    let stats = cjguiFontResourceDiagnostics()
    cjguiPreviewLog("CJGUI_PREVIEW_FONT_EXIT active=${stats[0]} live=${stats[1]} bytes=${stats[2]} " +
        "snapshots=${stats[3]} registrations=${stats[4]}")
    return 0
}

@When[os != "Linux"]
private func runNotificationWindow(): Int32 {
    let domain = CjguiNotificationThresholdDomain()
    let controller = CjguiNotificationThresholdController(domain)
    let host = cjguiCreatePlatformApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("通知配置 · 手写与生成", 1000u32, 860u32)
    )
    let window = host.window()
    controller.bindWindow(window)
    // The draft channel field is the one editable text surface in this window.
    // Its public interaction declaration is an owned range session; the sink
    // writes the same domain field that the external operation channel exposes.
    let draftBridge = CjguiNotificationDraftTextBridge(domain, 9101, "deliveryChannel")
    notificationBindDraftTextSession(window, draftBridge)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
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
