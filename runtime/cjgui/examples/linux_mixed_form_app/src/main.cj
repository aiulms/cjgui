/// Thin Linux mixed-form consumer: the handwritten section and the runtime
/// generated region share one notification-threshold owner, one field
/// declaration set and one action set. External clients use the public
/// generated-UI protocol; this application only wires the existing adapters.
package cjgui_linux_mixed_form_app

import cjgui.*
import cjgui_notification_threshold_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private let MIXED_TEXT_NODE: Int64 = 20
private let MIXED_ENABLED_NODE: Int64 = 21
private let MIXED_APPLY_NODE: Int64 = 22
private let MIXED_CLOSE_NODE: Int64 = 23
private let MIXED_CANCEL_NODE: Int64 = 24
private let MIXED_PALETTE_NODE: Int64 = 25
private let MIXED_GENERATED_HOST_NODE: Int64 = 30

private func mixedHex(text: String): String {
    return CjguiSharedOperationFrame.encodeUtf8Hex(text)
}

class MixedFormController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiContextMenuRequestHandler {
    private let domain: CjguiNotificationThresholdDomain
    public let form: CjguiGeneratedUiFormBinding
    private let generated: CjguiGeneratedUiWindowRegion
    private let commandScope = CjguiComposableUiIdentityScope("linux-mixed-commands")
    private let palette = CjguiCommandPalette("linux-mixed-palette")
    private let contextMenu = CjguiContextCommandMenu(
        CjguiComposableUiIdentityScope("linux-mixed-context"), "linux-mixed-context")
    private var localRevision: Int64 = 1
    private var status: String = "手写区域与运行时生成区域共用同一草稿；生成结构来自公共协议。"
    private var windowValue: ?CjguiComposableUiWindow = None
    private var contextTargetNodeId: Int64 = -1

    init(domain: CjguiNotificationThresholdDomain) {
        this.domain = domain
        this.form = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
        this.generated = CjguiGeneratedUiWindowRegion(form.capabilityCatalog(), form, "linux-mixed-generated")
    }

    public func bindWindow(window: CjguiComposableUiWindow): Unit {
        windowValue = Some(window)
        generated.attachWindow(window)
    }

    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion {
        return generated
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = commandPresentation().commands
        // The open palette publishes its own layer-scoped up/down/enter/escape
        // declarations. Native forwards the plain key; the common window still
        // resolves and executes it against the accepted footer controls.
        for (command in palette.commands()) {
            commands.add(command)
        }
        if (getVariable("CJGUI_MIXED_COMMAND_TRACE").isSome()) {
            for (command in commands) {
                let shortcut = if (command.hasShortcut()) { command.shortcut.encoded() } else { "" }
                println("CJGUI_MIXED_COMMAND id=${command.id} scope=${command.focusScopeId} " +
                    "shortcut=${shortcut} enabled=${command.isEnabled}")
            }
        }
        return commands
    }

    private func commandPresentation(): CjguiCommandPresentation {
        let canApply = form.actionAvailable("APPLY_DRAFT")
        let commands = ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("mixed-command-apply",
                CjguiComposableUiNodeReference.manual(MIXED_APPLY_NODE), "应用草稿",
                CjguiComposableUiShortcut("s"), "Actions", 0, canApply, false),
            CjguiComposableUiCommand("mixed-command-cancel",
                CjguiComposableUiNodeReference.manual(MIXED_CANCEL_NODE), "取消草稿",
                CjguiComposableUiShortcut("d"), "Actions", 1, true, false),
            CjguiComposableUiCommand("mixed-command-palette",
                CjguiComposableUiNodeReference.manual(MIXED_PALETTE_NODE), "命令面板",
                CjguiComposableUiShortcut("k"), "View", 0, true, false)
        ])
        let metadata = ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("mixed-command-apply", "APPLY_DRAFT",
                CjguiNotificationThresholdDomain.resourceId,
                detail: "把当前草稿应用为通知配置", disabledReason: "草稿存在字段错误或应用基线已变化"),
            CjguiCommandToolbarMetadata("mixed-command-cancel", "CANCEL_DRAFT",
                CjguiNotificationThresholdDomain.resourceId, detail: "丢弃草稿并恢复已应用配置"),
            CjguiCommandToolbarMetadata("mixed-command-palette", "PALETTE", -1,
                detail: "打开命令面板；也可按 ⌘K / Ctrl+K")
        ])
        return CjguiCommandPresentation(commands, metadata)
    }

    private func contextPresentation(targetNodeId: Int64): CjguiCommandPresentation {
        let canApply = form.actionAvailable("APPLY_DRAFT")
        let target = CjguiComposableUiNodeReference.manual(targetNodeId)
        let commands = ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("mixed-context-apply", target, "应用草稿", "", 0, canApply, false),
            CjguiComposableUiCommand("mixed-context-cancel", target, "取消草稿", "", 1, true, false)
        ])
        let metadata = ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("mixed-context-apply", "APPLY_DRAFT", 0,
                disabledReason: "草稿存在字段错误或应用基线已变化"),
            CjguiCommandToolbarMetadata("mixed-context-cancel", "CANCEL_DRAFT", 0)
        ])
        return CjguiCommandPresentation(commands, metadata)
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        let window = match (windowValue) {
            case Some(value) => value
            case None => return false
        }
        contextTargetNodeId = request.nodeId
        let opened = contextMenu.open(window, request, contextPresentation(request.nodeId),
            "linux-mixed", source: CjguiContextMenuCommandSource.RequestLocal,
            style: CjguiContextCommandMenuStyle.themed(CjguiComposableUiTheme.beaconDark()))
        status = if (opened) {
            "上下文命令来自与工具栏相同的草稿 owner"
        } else {
            "上下文菜单未打开：命令已禁用或目标已失效"
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
        match (windowValue) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    private func openCommandPalette() {
        let window = match (windowValue) {
            case Some(value) => value
            case None => return
        }
        let restore = window.focusedNodeReference() ?? CjguiComposableUiNodeReference.manual(MIXED_PALETTE_NODE)
        palette.open("命令", commandPresentation().placement(), restore, hint: "输入以筛选；Enter 执行，Esc 取消")
        status = "命令面板已打开；命令操作同一草稿 owner"
        localRevision += 1
        window.requestRefresh()
    }

    public func finishCommandPalette(window: CjguiComposableUiWindow): Unit {
        if (palette.isOpen()) {
            let before = palette.revision()
            palette.updateItems(commandPresentation().placement())
            if (palette.revision() != before) {
                window.requestRefresh()
            }
        }
        if (contextTargetNodeId >= 0) {
            let presentation = contextPresentation(contextTargetNodeId)
            let _ = contextMenu.reconcile(window, presentation.commands, presentation.metadata)
        }
        if (let Some(item) <- palette.takeConfirmed(window)) {
            if (!window.invokeCommand(item.commandId)) {
                status = "命令未执行：目标已失效或命令已禁用（${item.commandId}）"
                localRevision += 1
            }
            window.requestRefresh()
        }
        let failure = palette.takeConfirmationFailure()
        if (failure.size > 0) {
            status = "命令面板未执行：${failure}"
            localRevision += 1
            window.requestRefresh()
        }
    }

    public func uiSceneVersion(): Int64 {
        let draft = domain.draftSnapshot()
        let current = domain.notificationSnapshot()
        return localRevision + draft.draftVersion * 1000003 + current.version * 7919 + generated.revision() +
            palette.revision()
    }

    public func beginSceneRefresh(): Bool { return generated.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return generated.prepareSceneRefresh() }
    public func commitSceneRefresh(): Unit { generated.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { generated.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { generated.disposeSceneRefreshResources() }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let draft = domain.draftSnapshot()
        let current = domain.notificationSnapshot()
        let channelField = form.fieldSpec("deliveryChannel").getOrThrow()
        let enabledField = form.fieldSpec("isEnabled").getOrThrow()
        let draftChannel = draft.fieldForResourceId(channelField.resourceId).draftText
        let draftEnabled = draft.fieldForResourceId(enabledField.resourceId).draftText == "true"
        let inputStyle = CjguiComposableUiStyle(fixedHeight: 36, background: theme.input.background,
            border: theme.input.border, textColor: theme.input.textColor, pointerInteractive: true)
        let root = cjguiComposableVertical(1, "mixed-root",
            CjguiComposableUiStyle(padding: 18, gap: 10, background: theme.page.background))
        root.add(cjguiComposableText(2, "mixed-title", "Linux 手写 + 运行时生成表单",
            CjguiComposableUiStyle(fixedHeight: 34, fontSize: 24.0, fontWeight: 700, textColor: theme.heading.textColor)))
        root.add(cjguiComposableText(3, "mixed-subtitle",
            "上方为手写控件，下方生成区域由外部客户端按 catalog 提交；字段、按钮与草稿均属于同一 owner。",
            CjguiComposableUiStyle(fixedHeight: 24, fontSize: 13.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        root.add(cjguiComposableText(4, "mixed-handwritten-heading", "手写区域",
            CjguiComposableUiStyle(fixedHeight: 26, fontSize: 16.0, fontWeight: 600, textColor: theme.heading.textColor)))
        root.add(cjguiComposableTextInput(MIXED_TEXT_NODE, "mixed-channel", channelField.label,
            draftChannel, channelField.resourceId, inputStyle, fieldId: channelField.fieldId,
            operationActionName: channelField.writeActionName,
            operationResourceId: CjguiNotificationThresholdDomain.resourceId, displayValueRole: "draft",
            interactionStyle: theme.inputInteraction))
        root.add(cjguiComposableBooleanInput(MIXED_ENABLED_NODE, "mixed-enabled", enabledField.label,
            draftEnabled, enabledField.resourceId,
            CjguiComposableUiStyle(fixedHeight: 30, background: theme.input.background,
                border: theme.input.border, textColor: theme.input.textColor, pointerInteractive: true),
            fieldId: enabledField.fieldId, operationActionName: enabledField.writeActionName,
            operationResourceId: CjguiNotificationThresholdDomain.resourceId, displayValueRole: "draft"))
        let actions = cjguiComposableHorizontal(10, "mixed-handwritten-actions",
            CjguiComposableUiStyle(fixedHeight: 38, gap: 10))
        actions.add(cjguiComposableButton(MIXED_APPLY_NODE, "mixed-apply", "应用草稿", "APPLY_DRAFT",
            CjguiNotificationThresholdDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 112, fixedHeight: 34,
                background: theme.primaryAction.background, textColor: theme.primaryAction.textColor),
            enabled: form.actionAvailable("APPLY_DRAFT"), operationActionName: "APPLY_DRAFT",
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(MIXED_CANCEL_NODE, "mixed-cancel", "取消草稿", "CANCEL_DRAFT",
            CjguiNotificationThresholdDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 104, fixedHeight: 34, background: theme.card.background,
                border: theme.card.border, textColor: theme.body.textColor),
            interactionStyle: theme.cardInteraction))
        actions.add(cjguiComposableButton(MIXED_CLOSE_NODE, "mixed-close", "关闭", "CLOSE",
            CjguiNotificationThresholdDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 34, background: theme.card.background,
                border: theme.card.border, textColor: theme.body.textColor),
            interactionStyle: theme.cardInteraction))
        actions.add(cjguiComposableButton(MIXED_PALETTE_NODE, "mixed-palette", "命令…", "PALETTE", -1,
            CjguiComposableUiStyle(fixedWidth: 88, fixedHeight: 34, background: theme.card.background,
                border: theme.card.border, textColor: theme.body.textColor),
            interactionStyle: theme.cardInteraction))
        root.add(actions)
        root.add(cjguiComposableCommandToolbar(commandScope, "mixed-command-bar",
            commandPresentation().placement(), style: CjguiCommandToolbarStyle.themed(theme),
            searchLabel: "", searchActionName: "", searchResourceId: -1))
        root.add(cjguiComposableText(11, "mixed-generated-heading", "运行时生成区域",
            CjguiComposableUiStyle(fixedHeight: 26, fontSize: 16.0, fontWeight: 600, textColor: theme.heading.textColor)))
        let generatedHost = cjguiComposableVertical(MIXED_GENERATED_HOST_NODE, "mixed-generated-host",
            CjguiComposableUiStyle(growY: 1, padding: 12, gap: 8, cornerRadius: 10,
                background: theme.card.background, border: theme.card.border))
        generatedHost.add(generated.buildNode())
        root.add(generatedHost)
        root.add(cjguiComposableText(12, "mixed-status",
            "${status} · 草稿 v${draft.draftVersion} / 已应用 v${draft.baseAppliedConfigVersion} / 结构 v${generated.acceptedStructureVersion()}",
            CjguiComposableUiStyle(fixedHeight: 42, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 2, textOverflow: "ellipsis")))
        let host = cjguiComposableLayerHost(100, "mixed-layer-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(root)
        contextMenu.attachTo(host)
        return palette.attachTo(host, theme)
    }

    private func applyDraft(): Bool {
        let result = form.executeAction("APPLY_DRAFT", "mixed-handwritten-apply")
        status = if (result.applied) {
            "手写按钮已应用草稿 v${domain.draftSnapshot().baseAppliedConfigVersion}"
        } else {
            "应用被拒：${result.reason}"
        }
        localRevision += 1
        println("CJGUI_MIXED_APPLY applied=${result.applied} reason=${result.reason} " +
            "version=${domain.notificationSnapshot().version} status=${mixedHex(status)}")
        getStdOut().flush()
        return result.applied
    }

    private func cancelDraft(): Bool {
        let result = form.executeAction("CANCEL_DRAFT", "mixed-command-cancel")
        status = if (result.applied) {
            "命令已取消草稿，恢复到已应用 v${domain.draftSnapshot().baseAppliedConfigVersion}"
        } else {
            "取消失败：${result.reason}"
        }
        localRevision += 1
        println("CJGUI_MIXED_CANCEL applied=${result.applied} reason=${result.reason} " +
            "version=${domain.notificationSnapshot().version} status=${mixedHex(status)}")
        getStdOut().flush()
        return result.applied
    }

    private func commandActionName(commandId: String): String {
        return match (commandId) {
            case "mixed-command-apply" | "mixed-context-apply" => "APPLY_DRAFT"
            case "mixed-command-cancel" | "mixed-context-cancel" => "CANCEL_DRAFT"
            case "mixed-command-palette" => "PALETTE"
            case _ => ""
        }
    }

    private func performCommandAction(action: String): Bool {
        if (action == "APPLY_DRAFT") { return applyDraft() }
        if (action == "CANCEL_DRAFT") { return cancelDraft() }
        if (action == "PALETTE") {
            openCommandPalette()
            return true
        }
        return false
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (let Some(window) <- windowValue) {
            if (let Some(result) <- contextMenu.applyUiEvent(event, window)) {
                return result
            }
        }
        if (let Some(result) <- palette.applyUiEvent(event)) {
            return result
        }
        let generatedResult = generated.handleEvent(event)
        if (generatedResult.didApply) {
            return generatedResult
        }
        if (let Some(window) <- windowValue) {
            let formResult = form.handleFormEvent(event, window)
            if (formResult.didApply) {
                return formResult
            }
        }
        if (event.eventKind == 27) {
            let action = commandActionName(event.text)
            if (action.size > 0) {
                return CjguiComposableUiDispatchResult(performCommandAction(action))
            }
        }
        if (event.eventKind == 27) {
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                if (let Some(window) <- windowValue) {
                    let applied = window.invokeCommand(commandId)
                    if (!applied) {
                        status = "命令未执行：目标已失效或命令已禁用（${commandId}）"
                        localRevision += 1
                    }
                    return CjguiComposableUiDispatchResult(applied)
                }
                return CjguiComposableUiDispatchResult(false)
            }
        }
        if (event.eventKind == 27 && event.node.nodeId == MIXED_APPLY_NODE) {
            return CjguiComposableUiDispatchResult(applyDraft())
        }
        if (event.eventKind == 27 &&
            (event.node.actionName == "CANCEL_DRAFT" || event.node.nodeId == MIXED_CANCEL_NODE)) {
            return CjguiComposableUiDispatchResult(cancelDraft())
        }
        if (event.eventKind == 27 && event.node.actionName == "PALETTE") {
            openCommandPalette()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == MIXED_CLOSE_NODE) {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        status = "输入未应用：事件 ${eventKind} 的原控件已刷新或移除（节点 ${nodeId}）"
        localRevision += 1
        return CjguiComposableUiDispatchResult(false)
    }
}

private func mixedAuthorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "Linux 混合表单公开客户端",
        "linux-mixed-form-client-20261021",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
            CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
            CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true)
        ])
    )
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let domain = CjguiNotificationThresholdDomain()
    let controller = MixedFormController(domain)
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Linux 混合表单", 940u32, 760u32))
    let window = host.window()
    controller.bindWindow(window)
    let handwrittenSession = CjguiGeneratedFieldRangeSession(controller.form, "deliveryChannel")
    let _ = window.bindRangeTextSession(MIXED_TEXT_NODE, "mixed-channel", handwrittenSession,
        handwrittenSession, 9101, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    let connection = CjguiSharedOperationExternalConnection(domain, mixedAuthorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    let _ = window.requestInitialOwnedTextFocusRestore()
    println("CJGUI_MIXED_READY")
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_MIXED_DESCRIPTOR ${info.descriptorPath}")
        println("CJGUI_MIXED_PROTOCOL ${info.protocol}")
    } else {
        println("CJGUI_MIXED_DESCRIPTOR unavailable")
    }
    getStdOut().flush()
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        controller.finishCommandPalette(window)
    }
    let snapshot = domain.notificationSnapshot()
    let draft = domain.draftSnapshot()
    println("CJGUI_MIXED_CLOSED version=${snapshot.version} draft_version=${draft.draftVersion} " +
        "channel_hex=${mixedHex(snapshot.channel)} enabled=${snapshot.enabled} threshold=${snapshot.threshold}")
    getStdOut().flush()
    host.close()
    return 0
}
