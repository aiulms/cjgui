package adaptive_layout_public_consumer

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

class AdaptiveController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let domain: CjguiSharedOperationList
    let componentRegistry: CjguiComposableUiComponentRegistry
    var localRevision: Int64 = 1
    var usesCoralBeacon: Bool = false
    var showsSecondaryToggle: Bool = true
    var primaryToggleNodeId: Int64 = -1
    var secondaryToggleNodeId: Int64 = -1
    var primaryToggleScope: String = ""
    var secondaryToggleScope: String = ""

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.componentRegistry = CjguiComposableUiComponentRegistry()
    }

    public func buildUi(): CjguiComposableUiNode {
        let style = CjguiComposableUiStyle(
            minWidth: 280,
            idealWidth: 640,
            maxWidth: 920,
            minHeight: 160,
            idealHeight: 420,
            maxHeight: 720
        )
        let root = cjguiComposableVertical(1, "adaptive-root", style)
        let header = cjguiComposableHorizontal(2, "adaptive-header", style)
        header.add(
            cjguiComposableText(
                10,
                "adaptive-title",
                "Adaptive layout · 横纵组合 / 窄宽约束 / 动态领域状态",
                style,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        root.add(header)
        let status = cjguiComposableVertical(3, "adaptive-status-card", style)
        status.add(
            cjguiComposableText(
                11,
                "adaptive-domain-status",
                "领域状态 / shared operation version = ${domain.version()}",
                style,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        status.add(
            cjguiComposableText(
                12,
                "adaptive-long-label",
                "长标签：这是一个较长的中文标签，用于验证窄宽约束下的换行与裁剪行为",
                style,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        root.add(status)
        // Normal app bundles place declared rasters directly in
        // Contents/Resources; keep the scene path bundle-relative rather
        // than leaking the source-tree layout into the packaged executable.
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
        root.add(
            cjguiComposableImage(15, "adaptive-resource-beacon", beaconPath,
                CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
                imageResourceId: "adaptive-resource-beacon", imageResourceVersion: beaconVersion))
        let actions = cjguiComposableHorizontal(4, "adaptive-actions", style)
        actions.add(
            cjguiComposableButton(
                13,
                "adaptive-refresh",
                "刷新领域状态",
                "refresh-domain",
                0,
                style,
                enabled: true,
                operationActionName: "SET_MARKED",
                operationResourceId: 7101
            )
        )
        actions.add(
            cjguiComposableButton(
                14,
                "adaptive-close",
                "请求关闭",
                "request-close",
                0,
                style,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0
            )
        )
        actions.add(
            cjguiComposableButton(
                16,
                "adaptive-resource-toggle",
                "切换资源",
                "TOGGLE_RESOURCE",
                0,
                style,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0
            )
        )
        actions.add(
            cjguiComposableButton(
                17,
                "adaptive-component-toggle",
                "显示/隐藏第二个组件",
                "TOGGLE_COMPONENT",
                0,
                style,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0
            )
        )
        root.add(actions)
        // Repeated editor/action group: its local node IDs and scope derive
        // from stable business keys rather than a copied numeric range.
        primaryToggleNodeId = -1
        secondaryToggleNodeId = -1
        let primary = componentRegistry.use("adaptive-primary")
        if (primary.isLive()) {
            let group = cjguiComposableVertical(primary.nodeId("root"), primary.semanticId("root"),
                CjguiComposableUiStyle(padding: 6, gap: 3), inputScopeId: primary.focusScopeId())
            let toggle = cjguiComposableButton(primary.nodeId("toggle"), primary.semanticId("toggle"), "主组件切换资源",
                "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(fixedHeight: 28))
            group.add(toggle);
            root.add(group)
            primaryToggleNodeId = toggle.nodeId
            primaryToggleScope = primary.focusScopeId()
        }
        if (showsSecondaryToggle) {
            let secondary = componentRegistry.use("adaptive-secondary")
            if (secondary.isLive()) {
                let group = cjguiComposableVertical(secondary.nodeId("root"), secondary.semanticId("root"),
                    CjguiComposableUiStyle(padding: 6, gap: 3), inputScopeId: secondary.focusScopeId())
                let toggle = cjguiComposableButton(secondary.nodeId("toggle"), secondary.semanticId("toggle"),
                    "第二组件切换资源", "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(fixedHeight: 28))
                group.add(toggle);
                root.add(group)
                secondaryToggleNodeId = toggle.nodeId
                secondaryToggleScope = secondary.focusScopeId()
            }
        }
        return root
        /*
        let theme = CjguiComposableUiTheme.beaconDark()
        let root = CjguiComposableUiContainer("adaptive-root", theme)
        let header = cjguiComposableUiContainer("adaptive-header", theme)
        header.add(cjguiComposableText(
            "adaptive-title",
            "Adaptive layout",
            "横纵组合 / 窄宽约束 / 动态领域状态",
            theme
        ))
        root.add(header)

        let status = cjguiComposableUiContainer("adaptive-status-card", theme)
        status.add(cjguiComposableText(
            "adaptive-domain-status",
            "领域状态",
            "shared operation version = ${domain.version()}",
            theme
        ))
        status.add(cjguiComposableText(
            "adaptive-long-label",
            "长标签",
            "这是一个较长的中文标签，用于验证窄宽约束下的换行与裁剪行为",
            theme
        ))
        root.add(status)

        let actions = cjguiComposableUiContainer("adaptive-actions", theme)
        actions.add(cjguiComposableButton(
            "adaptive-refresh",
            "刷新领域状态",
            "refresh-domain",
            theme
        ))
        actions.add(cjguiComposableButton(
            "adaptive-close",
            "请求关闭",
            "request-close",
            theme
        ))
        root.add(actions)
        return root */
    }

    public func uiSceneVersion(): Int64 {
        return domain.version() + localRevision
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_RESOURCE") {
            usesCoralBeacon = !usesCoralBeacon
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_COMPONENT") {
            showsSecondaryToggle = !showsSecondaryToggle
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true, shouldClose: false)
    }

    public func rejectUiEvent(nodeId: Int64, eventKind: Int64): CjguiComposableUiDispatchResult {
        getStdErr().writeln("ADAPTIVE_UI_EVENT_REJECTED node=${nodeId} kind=${eventKind}")
        return CjguiComposableUiDispatchResult(false, shouldClose: false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func componentCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (primaryToggleNodeId >= 0) {
            commands.add(
                CjguiComposableUiCommand("adaptive.primary.toggle", primaryToggleNodeId, CjguiComposableUiShortcut("m"),
                    focusScopeId: primaryToggleScope))
        }
        if (secondaryToggleNodeId >= 0 && showsSecondaryToggle) {
            commands.add(
                CjguiComposableUiCommand("adaptive.secondary.toggle", secondaryToggleNodeId,
                    CjguiComposableUiShortcut("m"), focusScopeId: secondaryToggleScope))
        }
        return commands
    }
    public func beginSceneRefresh(): Bool {
        return componentRegistry.beginTransaction()
    }
    public func prepareSceneRefresh(): Bool {
        return componentRegistry.prepareTransaction()
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return componentCommands()
    }
    public func commitSceneRefresh(): Unit {
        componentRegistry.commitTransaction()
    }
    public func rollbackSceneRefresh(): Unit {
        componentRegistry.rollbackTransaction()
    }
}

main(): Int64 {
    let targetId: Int64 = 7101
    let domain = CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>([CjguiSharedOperationRecord(targetId, "窄宽布局动态项目", false)]))
    let authorization = CjguiSharedOperationExternalAuthorization(
        "adaptive-public-consumer",
        "demo-only-authorized-local-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([targetId]), false)
            ]
        )
    )
    let controller = AdaptiveController(domain)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "Adaptive Layout Public Consumer",
            640u32,
            420u32
        )
    )
    let window = host.window()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization, window)
    if (!connection.enableWindowProgressReads(window) || !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        getStdOut().writeln("ADAPTIVE_LAYOUT_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        getStdOut().flush()
    }
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    host.close()
    return 0
}
