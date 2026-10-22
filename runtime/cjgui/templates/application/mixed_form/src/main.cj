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
private let MIXED_GENERATED_HOST_NODE: Int64 = 30

private func mixedHex(text: String): String {
    return CjguiSharedOperationFrame.encodeUtf8Hex(text)
}

class MixedFormController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let domain: CjguiNotificationThresholdDomain
    public let form: CjguiGeneratedUiFormBinding
    private let generated: CjguiGeneratedUiWindowRegion
    private var localRevision: Int64 = 1
    private var status: String = "手写区域与运行时生成区域共用同一草稿；生成结构来自公共协议。"
    private var windowValue: ?CjguiComposableUiWindow = None

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
        return ArrayList<CjguiComposableUiCommand>()
    }

    public func uiSceneVersion(): Int64 {
        let draft = domain.draftSnapshot()
        let current = domain.notificationSnapshot()
        return localRevision + draft.draftVersion * 1000003 + current.version * 7919 + generated.revision()
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
        actions.add(cjguiComposableButton(MIXED_CLOSE_NODE, "mixed-close", "关闭", "CLOSE",
            CjguiNotificationThresholdDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 34, background: theme.card.background,
                border: theme.card.border, textColor: theme.body.textColor),
            interactionStyle: theme.cardInteraction))
        root.add(actions)
        root.add(cjguiComposableText(11, "mixed-generated-heading", "运行时生成区域",
            CjguiComposableUiStyle(fixedHeight: 26, fontSize: 16.0, fontWeight: 600, textColor: theme.heading.textColor)))
        let generatedHost = cjguiComposableVertical(MIXED_GENERATED_HOST_NODE, "mixed-generated-host",
            CjguiComposableUiStyle(growY: 1, padding: 12, gap: 8, cornerRadius: 10,
                background: theme.card.background, border: theme.card.border))
        generatedHost.add(generated.buildNode())
        root.add(generatedHost)
        root.add(cjguiComposableText(12, "mixed-status",
            "${status} · 草稿 v${draft.draftVersion} / 已应用 v${current.version} / 结构 v${generated.acceptedStructureVersion()}",
            CjguiComposableUiStyle(fixedHeight: 42, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 2, textOverflow: "ellipsis")))
        let host = cjguiComposableLayerHost(100, "mixed-layer-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(root)
        return host
    }

    private func applyDraft(): Bool {
        let result = form.executeAction("APPLY_DRAFT", "mixed-handwritten-apply")
        status = if (result.applied) {
            "手写按钮已应用草稿 v${domain.notificationSnapshot().version}"
        } else {
            "应用被拒：${result.reason}"
        }
        localRevision += 1
        println("CJGUI_MIXED_APPLY applied=${result.applied} reason=${result.reason} " +
            "version=${domain.notificationSnapshot().version} status=${mixedHex(status)}")
        getStdOut().flush()
        return result.applied
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
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
        if (event.eventKind == 27 && event.node.nodeId == MIXED_APPLY_NODE) {
            return CjguiComposableUiDispatchResult(applyDraft())
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
    }
    let snapshot = domain.notificationSnapshot()
    let draft = domain.draftSnapshot()
    println("CJGUI_MIXED_CLOSED version=${snapshot.version} draft_version=${draft.draftVersion} " +
        "channel_hex=${mixedHex(snapshot.channel)} enabled=${snapshot.enabled} threshold=${snapshot.threshold}")
    getStdOut().flush()
    host.close()
    return 0
}
