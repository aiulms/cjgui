package cjgui_settings_form_window_app

import cjgui.*
import cjgui_settings_form_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private func settingsFeedbackPolicy(): CjguiFormFeedbackPolicy {
    return CjguiFormFeedbackPolicy(
        focusSemanticId: { fieldId => cjguiFormFieldSemanticId("settings-form", fieldId) })
}

private class CjguiSettingsFormController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiContextMenuRequestHandler {
    private let domain: CjguiSettingsFormDomain
    private let form: CjguiGeneratedUiFormBinding
    private let generated: CjguiGeneratedUiWindowRegion
    private let rootViewport: CjguiComposableUiScrollViewport
    private var localRevision: Int64
    private var status: String
    private var groupsReordered: Bool
    private var currentPlacement: CjguiComposableFormPlacement
    private let commandPalette: CjguiCommandPalette
    private var commandPlacement: CjguiCommandToolbarPlacement
    private let instanceAScope: CjguiComposableUiIdentityScope
    private let instanceBScope: CjguiComposableUiIdentityScope
    private var instanceAPlacement: CjguiCommandToolbarPlacement
    private var instanceBPlacement: CjguiCommandToolbarPlacement
    private let contextMenuA: CjguiContextCommandMenu
    private let contextMenuB: CjguiContextCommandMenu
    private var paletteOwner: String
    private var instancesSwapped: Bool
    private var scopedCommandMode: String
    private var latestFeedback: ?CjguiFormFeedbackProjection
    private var windowValue: ?CjguiComposableUiWindow
    private var staleSourceStep: Int64
    private var staleSourceRequestId: Int64
    private var staleSourceArmed: Bool
    private var staleSourceWasOpen: Bool
    private let narrowLayout: Bool
    private var themeName: String
    private var inspectorRequested: Bool

    init(domain: CjguiSettingsFormDomain) {
        this.domain = domain
        this.form = CjguiGeneratedUiFormBinding(domain, CjguiSettingsFormDomain.resourceId)
        this.generated = CjguiGeneratedUiWindowRegion(form.capabilityCatalog(), form, "settings-generated-form")
        this.rootViewport = CjguiComposableUiScrollViewport()
        this.localRevision = 1
        this.status = "手写分组与生成区域共用同一草稿；修改后显式应用。"
        this.groupsReordered = false
        this.currentPlacement = settingsPlacement(false)
        this.commandPalette = CjguiCommandPalette("settings-commands")
        this.commandPlacement = settingsCommandPlacement(true, false, settingsProxyChecked(domain.formSnapshot()))
        this.instanceAScope = CjguiComposableUiIdentityScope("settings-instance-a")
        this.instanceBScope = CjguiComposableUiIdentityScope("settings-instance-b")
        this.contextMenuA = CjguiContextCommandMenu(instanceAScope, "settings-context-menu-a")
        this.contextMenuB = CjguiContextCommandMenu(instanceBScope, "settings-context-menu-b")
        let snapshot = domain.formSnapshot()
        this.instanceAPlacement = settingsScopedPlacement(this.instanceAScope, "a", "代理 A", "TOGGLE_PROXY",
            settingsProxyChecked(snapshot), CjguiSettingsFormDomain.useProxyResourceId, "SEARCH_SCOPED_A")
        this.instanceBPlacement = settingsScopedPlacement(this.instanceBScope, "b", "通知 B", "TOGGLE_NOTIFY",
            settingsNotifyChecked(snapshot), CjguiSettingsFormDomain.notifyOnFailureResourceId, "SEARCH_SCOPED_B")
        this.paletteOwner = "main"
        this.instancesSwapped = false
        this.scopedCommandMode = match (getVariable("CJGUI_SETTINGS_SCOPED_MODE")) {
            case Some(value) => if (value.size > 0) { value } else { "all" }
            case None => "all"
        }
        this.latestFeedback = None
        this.windowValue = None
        this.staleSourceStep = 0
        this.staleSourceRequestId = -1
        this.staleSourceArmed = false
        this.staleSourceWasOpen = false
        this.narrowLayout = match (getVariable("CJGUI_SETTINGS_NARROW")) {
            case Some(value) => value == "1"
            case None => false
        }
        this.themeName = match (getVariable("CJGUI_SETTINGS_THEME")) {
            case Some(value) => if (value == "light") { "light" } else { "dark" }
            case None => "dark"
        }
        this.inspectorRequested = false
    }

    public func takeInspectorRequest(): Bool {
        let requested = inspectorRequested
        inspectorRequested = false
        return requested
    }

    private func commandTheme(): CjguiComposableUiTheme {
        return if (themeName == "light") {
            CjguiComposableUiTheme.paperLight()
        } else {
            CjguiComposableUiTheme.beaconDark()
        }
    }

    private func commandMenuStyle(): CjguiContextCommandMenuStyle {
        return if (narrowLayout) {
            CjguiContextCommandMenuStyle.themed(commandTheme(), width: 172, maxHeight: 132)
        } else {
            CjguiContextCommandMenuStyle.themed(commandTheme())
        }
    }

    public func bindWindow(window: CjguiComposableUiWindow): Unit {
        this.windowValue = Some(window)
        generated.attachWindow(window)
    }

    private func contextMenuTargetKey(window: CjguiComposableUiWindow,
        request: CjguiComposableUiContextMenuRequest): String {
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId != request.nodeId) { continue }
            if (node.resourceId != request.resourceId || node.nodeKind != request.nodeKind ||
                node.identityKey != request.identityKey || node.value != request.value) {
                return ""
            }
            if (node.semanticId == "settings-scope-a-control") { return "a" }
            if (node.semanticId == "settings-scope-b-control") { return "b" }
            return ""
        }
        return ""
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        let window = match (windowValue) {
            case Some(value) => value
            case None => return false
        }
        let key = contextMenuTargetKey(window, request)
        if (key.size == 0) {
            getStdOut().writeln(
                "SETTINGS_CONTEXT_MENU phase=refused request_id=${request.requestId} reason=not_a_scoped_control")
            getStdOut().flush()
            return false
        }
        let snapshot = domain.formSnapshot()
        let checked = if (key == "a") { settingsProxyChecked(snapshot) } else { settingsNotifyChecked(snapshot) }
        let enabled = !(key == "a" && scopedCommandMode == "disabled-a")
        // The menu consumes the same declaration holder shape as the toolbar and
        // palette; it does not own a second action table.
        let presentation = CjguiCommandPresentation(scopedMenuCommands(snapshot, key),
            scopedMenuMetadata(key), searchCommandId: "settings.instance-${key}.search")
        let menu = if (key == "a") { contextMenuA } else { contextMenuB }
        let opened = menu.open(window, request, presentation, "settings-scope-${key}",
            style: commandMenuStyle())
        if (!opened) {
            status = "右键菜单未打开：作用域 ${key} 的命令已移除或当前请求被窗口拒绝"
            localRevision += 1
            getStdOut().writeln(
                "SETTINGS_CONTEXT_MENU phase=refused request_id=${request.requestId} scope=${key} reason=no_declared_menu")
            getStdOut().flush()
            return false
        }
        status = "右键菜单已打开：作用域 ${key}；标题、勾选与禁用原因来自同一命令集"
        localRevision += 1
        getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=opened request_id=${request.requestId} " +
            "scope=${key} target=${request.nodeId}/${request.resourceId}/${request.nodeKind} " +
            "checked=${checked} enabled=${enabled} mode=${scopedCommandMode}")
        getStdOut().flush()
        return true
    }

    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        let endedA = contextMenuA.requestEnded(requestId)
        let endedB = contextMenuB.requestEnded(requestId)
        if (!endedA && !endedB) { return }
        status = "右键菜单已结束：${reason}"
        localRevision += 1
        getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=ended request_id=${requestId} reason=${reason}")
        getStdOut().flush()
        match (windowValue) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion {
        return generated
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        // One declaration list owns toolbar, palette and native shortcut
        // projection. The open panel contributes only its scoped navigation
        // commands; it never holds a second business-action definition.
        let snapshot = domain.formSnapshot()
        let commands = settingsCommands(snapshot.canApply, commandPalette.isOpen(),
            settingsProxyChecked(snapshot))
        for (command in scopedCommandsFor(snapshot)) {
            commands.add(command)
        }
        for (command in commandPalette.commands()) {
            commands.add(command)
        }
        return commands
    }

    private func scopedCommandsFor(snapshot: CjguiSharedFormSnapshot): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (scopedCommandMode == "empty") {
            return commands
        }
        if (scopedCommandMode != "removed-a") {
            let enabledA = scopedCommandMode != "disabled-a"
            let aCommands = if (scopedCommandMode == "leading-disabled-a") {
                settingsLeadingDisabledCommands(instanceAScope, settingsProxyChecked(snapshot))
            } else {
                settingsScopedCommands(instanceAScope, "a", "代理 A",
                    settingsProxyChecked(snapshot), enabled: enabledA)
            }
            for (command in aCommands) { commands.add(command) }
            // Reserved public prefix: the declaration still owns the target,
            // enabled state and chord; the window freezes the request itself.
            commands.add(CjguiComposableUiCommand(CJGUI_CONTEXT_MENU_OPEN_PREFIX + "settings.instance-a",
                CjguiComposableUiNodeReference.scoped(instanceAScope, "control"),
                "打开代理 A 命令菜单", CjguiComposableUiShortcut("m", usesShift: true),
                "", 0, enabledA, false))
        }
        for (command in settingsScopedCommands(instanceBScope, "b", "通知 B",
            settingsNotifyChecked(snapshot))) {
            commands.add(command)
        }
        return commands
    }

    // The open context menu re-projects this same source. A command removed or
    // disabled here must retire the menu instead of leaving an executable old row.
    private func scopedMenuCommands(snapshot: CjguiSharedFormSnapshot,
        key: String): ArrayList<CjguiComposableUiCommand> {
        if (scopedCommandMode == "empty" || (scopedCommandMode == "removed-a" && key == "a")) {
            return ArrayList<CjguiComposableUiCommand>()
        }
        let scope = if (key == "a") { instanceAScope } else { instanceBScope }
        let title = if (key == "a") { "代理 A" } else { "通知 B" }
        let checked = if (key == "a") { settingsProxyChecked(snapshot) } else { settingsNotifyChecked(snapshot) }
        if (key == "a" && scopedCommandMode == "leading-disabled-a") {
            return settingsLeadingDisabledCommands(scope, checked)
        }
        let enabled = !(key == "a" && scopedCommandMode == "disabled-a")
        return settingsScopedCommands(scope, key, title, checked, enabled: enabled)
    }

    private func scopedMenuMetadata(key: String): ArrayList<CjguiCommandToolbarMetadata> {
        if (scopedCommandMode == "empty" || (scopedCommandMode == "removed-a" && key == "a")) {
            return ArrayList<CjguiCommandToolbarMetadata>()
        }
        let actionName = if (key == "a") { "TOGGLE_PROXY" } else { "TOGGLE_NOTIFY" }
        let resourceId = if (key == "a") {
            CjguiSettingsFormDomain.useProxyResourceId
        } else {
            CjguiSettingsFormDomain.notifyOnFailureResourceId
        }
        let searchActionName = if (key == "a") { "SEARCH_SCOPED_A" } else { "SEARCH_SCOPED_B" }
        return settingsScopedMetadata(key, actionName, resourceId, searchActionName)
    }

    private func scopedPlacementFor(scope: CjguiComposableUiIdentityScope, key: String, title: String,
        actionName: String, checked: Bool, resourceId: Int64,
        searchActionName: String): CjguiCommandToolbarPlacement {
        if (scopedCommandMode == "empty" || (scopedCommandMode == "removed-a" && key == "a")) {
            // Re-project the current collection; the missing search declaration
            // removes the search button instead of leaving it default-enabled.
            return cjguiCommandToolbarPlacement(
                ArrayList<CjguiComposableUiCommand>(), ArrayList<CjguiCommandToolbarMetadata>(),
                searchCommandId: "settings.instance-${key}.search")
        }
        let enabled = !(scopedCommandMode == "disabled-a" && key == "a")
        return cjguiCommandToolbarPlacement(
            settingsScopedCommands(scope, key, title, checked, enabled: enabled),
            settingsScopedMetadata(key, actionName, resourceId, searchActionName),
            searchCommandId: "settings.instance-${key}.search")
    }

    public func uiSceneVersion(): Int64 {
        let draft = domain.formSnapshot()
        return localRevision + draft.draftVersion * 1000003 + draft.appliedConfigVersion * 7919 +
            commandPalette.revision() + generated.revision()
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

    private func scopedCommandInstance(scope: CjguiComposableUiIdentityScope, key: String,
        title: String, subject: String, actionName: String, checked: Bool, resourceId: Int64,
        placement: CjguiCommandToolbarPlacement, searchActionName: String): CjguiComposableUiNode {
        let card = cjguiComposableVertical(-1, "settings-scope-${key}",
            CjguiComposableUiStyle(padding: 8, gap: 5, growX: 1,
                background: CjguiComposableUiColor(0.11, 0.14, 0.2, 1.0),
                border: CjguiComposableUiColor(0.25, 0.32, 0.44, 1.0)),
            identity: Some(scope.local("card")))
        card.add(cjguiComposableText(-1, "settings-scope-${key}-title", "${title} · 作用域 ${key}",
            CjguiComposableUiStyle(fontSize: 12.5, fontWeight: 600, growX: 1,
                textColor: CjguiComposableUiColor(0.86, 0.91, 1.0, 1.0)),
            identity: Some(scope.local("title"))))
        let state = if (checked) {
            "开"
        } else {
            "关"
        }
        card.add(cjguiComposableButton(-1, "settings-scope-${key}-control", "${subject}：${state}",
            actionName, resourceId,
            CjguiComposableUiStyle(fixedHeight: 30, fontSize: 13.0,
                background: CjguiComposableUiColor(0.15, 0.19, 0.27, 1.0),
                border: CjguiComposableUiColor(0.32, 0.4, 0.55, 1.0),
                textColor: CjguiComposableUiColor(0.9, 0.94, 1.0, 1.0)),
            identity: Some(scope.local("control"))))
        card.add(cjguiComposableCommandToolbar(scope, "settings-scope-${key}-actions", placement,
            style: CjguiCommandToolbarStyle.themed(commandTheme(), rowHeight: 30),
            searchLabel: "搜索 ${key}", searchActionName: searchActionName,
            searchResourceId: resourceId))
        return card
    }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = domain.formSnapshot()
        let declarations = domain.formBinding()
        let feedback = CjguiFormFeedbackProjection(snapshot, declarations, CjguiSettingsFormDomain.resourceId,
            policy: settingsFeedbackPolicy(),
            readOnlyFields: ArrayList<String>(["workspaceId", "lastPublished"]))
        latestFeedback = Some(feedback)
        let placement = settingsPlacement(groupsReordered)
        currentPlacement = placement
        let proxyChecked = settingsProxyChecked(snapshot)
        let notifyChecked = settingsNotifyChecked(snapshot)
        commandPlacement = settingsCommandPlacement(feedback.canApply, commandPalette.isOpen(), proxyChecked)
        instanceAPlacement = scopedPlacementFor(instanceAScope, "a", "代理 A", "TOGGLE_PROXY",
            proxyChecked, CjguiSettingsFormDomain.useProxyResourceId, "SEARCH_SCOPED_A")
        instanceBPlacement = scopedPlacementFor(instanceBScope, "b", "通知 B", "TOGGLE_NOTIFY",
            notifyChecked, CjguiSettingsFormDomain.notifyOnFailureResourceId, "SEARCH_SCOPED_B")
        // The open palette reflects the same declaration list, but without the
        // panel's own focus gating: its rows must stay actionable while open.
        let panelPlacement = if (paletteOwner == "a") {
            instanceAPlacement
        } else if (paletteOwner == "b") {
            instanceBPlacement
        } else {
            settingsCommandPlacement(feedback.canApply, false, proxyChecked)
        }
        commandPalette.updateItems(panelPlacement)
        // The open context menus re-project the same accepted declaration
        // source on every build: label/checked/help move in place through the
        // presentation layer, while any executable-set change retires the
        // surface. Notifications downstream derive from the accepted change.
        if (let Some(window) <- windowValue) {
            if (contextMenuA.isOpen()) {
                let _ = contextMenuA.reconcile(window, scopedMenuCommands(snapshot, "a"),
                    scopedMenuMetadata("a"), searchCommandId: "settings.instance-a.search")
            }
            if (contextMenuB.isOpen()) {
                let _ = contextMenuB.reconcile(window, scopedMenuCommands(snapshot, "b"),
                    scopedMenuMetadata("b"), searchCommandId: "settings.instance-b.search")
            }
        }
        let content = cjguiComposableVertical(1, "settings-content",
            CjguiComposableUiStyle(padding: 18, gap: 12,
                background: CjguiComposableUiColor(0.075, 0.095, 0.14, 1.0)))
        let header = cjguiComposableVertical(2, "settings-header",
            CjguiComposableUiStyle(gap: 4, growX: 1))
        header.add(cjguiComposableText(3, "settings-title", "工作区设置",
            CjguiComposableUiStyle(fontSize: 24.0, fontWeight: 600, growX: 1,
                textColor: CjguiComposableUiColor(0.93, 0.96, 1.0, 1.0))))
        header.add(cjguiComposableText(4, "settings-subtitle",
            "分组、字段说明、必填提示与错误汇总来自同一份 owner 快照。窄窗口下字段与长说明自然换行。",
            CjguiComposableUiStyle(fontSize: 13.0, growX: 1,
                textColor: CjguiComposableUiColor(0.68, 0.76, 0.9, 1.0))))
        content.add(header)
        // Theme and Inspector are ordinary declarations: the toolbar materializes
        // their one control from the same placement the palette consumes, so the
        // consumer does not mount a second node with the same target id.
        content.add(cjguiComposableCommandToolbar(300, "settings-actions", commandPlacement,
            style: CjguiCommandToolbarStyle.themed(commandTheme(), rowHeight: 34),
            searchLabel: "搜索命令", searchActionName: "SEARCH_COMMANDS",
            searchResourceId: CjguiSettingsFormDomain.resourceId))
        let scopeCard = cjguiComposableVertical(600, "settings-scope-card",
            CjguiComposableUiStyle(padding: 10, gap: 6, growX: 1,
                background: CjguiComposableUiColor(0.095, 0.12, 0.175, 1.0),
                border: CjguiComposableUiColor(0.21, 0.28, 0.39, 1.0)))
        scopeCard.add(cjguiComposableText(601, "settings-scope-heading", "作用域命令 · 同一组件两次挂载",
            CjguiComposableUiStyle(fontSize: 13.0, fontWeight: 600, growX: 1,
                textColor: CjguiComposableUiColor(0.82, 0.88, 0.98, 1.0))))
        scopeCard.add(cjguiComposableText(602, "settings-scope-note",
            "每个实例只声明局部键；触发钮携带 commandId，经 window.invokeCommand 解析各自作用域的目标控件。命令集由外部控制增删，工具栏与面板复用同一投影。",
            CjguiComposableUiStyle(fontSize: 11.5, growX: 1,
                textColor: CjguiComposableUiColor(0.6, 0.68, 0.8, 1.0))))
        let scopeDynamic = cjguiComposableHorizontal(610, "settings-scope-dynamic",
            CjguiComposableUiStyle(gap: 6, growX: 1))
        let dynamicButtonStyle = CjguiComposableUiStyle(fixedHeight: 28, fontSize: 12.0,
            background: CjguiComposableUiColor(0.14, 0.18, 0.25, 1.0),
            border: CjguiComposableUiColor(0.3, 0.38, 0.5, 1.0),
            textColor: CjguiComposableUiColor(0.86, 0.9, 0.98, 1.0))
        scopeDynamic.add(cjguiComposableButton(611, "settings-swap-instances", "交换 A/B 位置",
            "SWAP_SCOPED_INSTANCES", 0, dynamicButtonStyle))
        let modeLabel = match (scopedCommandMode) {
            case "all" => "命令集：完整"
            case "disabled-a" => "命令集：禁用 A"
            case "removed-a" => "命令集：移除 A"
            case _ => "命令集：清空"
        }
        scopeDynamic.add(cjguiComposableButton(612, "settings-cycle-commands", modeLabel,
            "CYCLE_SCOPED_COMMANDS", 0, dynamicButtonStyle))
        scopeDynamic.add(cjguiComposableButton(613, "settings-invoke-a", "调用 A 命令",
            "INVOKE_SCOPED_A_COMMAND", 0, dynamicButtonStyle))
        scopeDynamic.add(cjguiComposableButton(614, "settings-open-a-panel", "打开 A 面板",
            "OPEN_SCOPED_A_PANEL", 0, dynamicButtonStyle))
        scopeCard.add(scopeDynamic)
        if (instancesSwapped) {
            scopeCard.add(scopedCommandInstance(instanceBScope, "b", "通知实例 B", "失败通知", "TOGGLE_NOTIFY",
                notifyChecked, CjguiSettingsFormDomain.notifyOnFailureResourceId, instanceBPlacement, "SEARCH_SCOPED_B"))
            scopeCard.add(scopedCommandInstance(instanceAScope, "a", "代理实例 A", "代理", "TOGGLE_PROXY",
                proxyChecked, CjguiSettingsFormDomain.useProxyResourceId, instanceAPlacement, "SEARCH_SCOPED_A"))
        } else {
            scopeCard.add(scopedCommandInstance(instanceAScope, "a", "代理实例 A", "代理", "TOGGLE_PROXY",
                proxyChecked, CjguiSettingsFormDomain.useProxyResourceId, instanceAPlacement, "SEARCH_SCOPED_A"))
            scopeCard.add(scopedCommandInstance(instanceBScope, "b", "通知实例 B", "失败通知", "TOGGLE_NOTIFY",
                notifyChecked, CjguiSettingsFormDomain.notifyOnFailureResourceId, instanceBPlacement, "SEARCH_SCOPED_B"))
        }
        content.add(scopeCard)
        let generatedCard = cjguiComposableVertical(400, "settings-generated-card",
            CjguiComposableUiStyle(padding: 10, gap: 6, growX: 1,
                background: CjguiComposableUiColor(0.095, 0.12, 0.175, 1.0),
                border: CjguiComposableUiColor(0.21, 0.28, 0.39, 1.0)))
        generatedCard.add(cjguiComposableText(401, "settings-generated-heading", "生成区域 · 共用同一 owner",
            CjguiComposableUiStyle(fontSize: 13.0, fontWeight: 600, growX: 1,
                textColor: CjguiComposableUiColor(0.82, 0.88, 0.98, 1.0))))
        generatedCard.add(cjguiComposableText(402, "settings-generated-note",
            "公开客户端可提交 catalog 结构；字段写入、反馈与焦点语义与上方一致。未连接客户端时此区域保持为空。",
            CjguiComposableUiStyle(fontSize: 11.5, growX: 1,
                textColor: CjguiComposableUiColor(0.6, 0.68, 0.8, 1.0))))
        generatedCard.add(generated.buildNode())
        content.add(generatedCard)
        let summaryCard = cjguiComposableVertical(100, "settings-summary-card",
            CjguiComposableUiStyle(padding: 10, gap: 4, growX: 1,
                background: CjguiComposableUiColor(0.105, 0.13, 0.19, 1.0),
                border: CjguiComposableUiColor(0.24, 0.31, 0.43, 1.0)))
        summaryCard.add(cjguiComposableText(101, "settings-summary-heading", "反馈汇总",
            CjguiComposableUiStyle(fontSize: 14.0, fontWeight: 600, growX: 1,
                textColor: CjguiComposableUiColor(0.9, 0.94, 1.0, 1.0))))
        summaryCard.add(cjguiComposableFormFeedbackSummary(102, "settings-feedback", feedback,
            "FOCUS_SETTINGS_FIELD",
            style: CjguiFormFeedbackSummaryStyle(
                container: CjguiComposableUiStyle(gap: 4, growX: 1),
                title: CjguiComposableUiStyle(fontSize: 13.0, growX: 1,
                    textColor: CjguiComposableUiColor(1.0, 0.78, 0.72, 1.0)),
                entry: CjguiComposableUiStyle(fontSize: 13.0, growX: 1, minHeight: 26, padding: 5,
                    background: CjguiComposableUiColor(0.16, 0.12, 0.14, 1.0),
                    border: CjguiComposableUiColor(0.42, 0.26, 0.27, 1.0),
                    textColor: CjguiComposableUiColor(1.0, 0.86, 0.82, 1.0)),
                note: CjguiComposableUiStyle(fontSize: 12.0, growX: 1,
                    textColor: CjguiComposableUiColor(0.68, 0.76, 0.88, 1.0)),
                rejection: CjguiComposableUiStyle(fontSize: 12.5, growX: 1,
                    textColor: CjguiComposableUiColor(0.95, 0.72, 0.65, 1.0)),
                ready: CjguiComposableUiStyle(fontSize: 12.5, growX: 1,
                    textColor: CjguiComposableUiColor(0.62, 0.85, 0.7, 1.0)))))
        content.add(summaryCard)
        let formCard = cjguiComposableVertical(200, "settings-form-card",
            CjguiComposableUiStyle(padding: 12, gap: 10, growX: 1,
                background: CjguiComposableUiColor(0.095, 0.12, 0.175, 1.0),
                border: CjguiComposableUiColor(0.21, 0.28, 0.39, 1.0)))
        formCard.add(cjguiComposableBoundFormGroups(201, "settings-form", placement, feedback,
            editorStyle: CjguiComposableUiStyle(fixedHeight: 32, fontSize: 15.0, growX: 1,
                background: CjguiComposableUiColor(0.13, 0.17, 0.24, 1.0),
                border: CjguiComposableUiColor(0.32, 0.4, 0.55, 1.0),
                textColor: CjguiComposableUiColor(0.93, 0.96, 1.0, 1.0)),
            validationStyle: CjguiComposableUiStyle(fontSize: 12.5, growX: 1,
                textColor: CjguiComposableUiColor(1.0, 0.55, 0.5, 1.0)),
            style: CjguiComposableFormGroupStyle(
                container: CjguiComposableUiStyle(gap: 16, growX: 1),
                group: CjguiComposableUiStyle(gap: 6, growX: 1),
                title: CjguiComposableUiStyle(fontSize: 16.0, fontWeight: 600, growX: 1,
                    textColor: CjguiComposableUiColor(0.9, 0.94, 1.0, 1.0)),
                description: CjguiComposableUiStyle(fontSize: 12.5, growX: 1,
                    textColor: CjguiComposableUiColor(0.64, 0.72, 0.86, 1.0)),
                help: CjguiComposableUiStyle(fontSize: 12.0, growX: 1,
                    textColor: CjguiComposableUiColor(0.62, 0.7, 0.82, 1.0)),
                note: CjguiComposableUiStyle(fontSize: 12.0, growX: 1,
                    textColor: CjguiComposableUiColor(0.75, 0.8, 0.9, 1.0))),
            textOperationActionName: "EDIT_DRAFT_TEXT",
            booleanOperationActionName: "EDIT_DRAFT_BOOLEAN",
            requiredMarker: " *", requiredHint: "必填"))
        content.add(formCard)
        content.add(cjguiComposableText(500, "settings-status",
            "${status} · 草稿 v${snapshot.draftVersion} / 已应用 v${snapshot.appliedConfigVersion}",
            CjguiComposableUiStyle(fontSize: 12.5, growX: 1,
                textColor: CjguiComposableUiColor(0.68, 0.76, 0.9, 1.0))))
        let scroll = cjguiComposableScrollArea(5, "settings-scroll", rootViewport,
            CjguiComposableUiStyle(growX: 1, growY: 1,
                background: CjguiComposableUiColor(0.075, 0.095, 0.14, 1.0)))
        scroll.add(content)
        let layerHost = cjguiComposableLayerHost(6, "settings-layer-host",
            CjguiComposableUiStyle(growX: 1, growY: 1))
        layerHost.add(scroll)
        contextMenuA.attachTo(layerHost)
        contextMenuB.attachTo(layerHost)
        return commandPalette.attachTo(layerHost, commandTheme())
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (let Some(window) <- windowValue) {
            if (let Some(result) <- contextMenuA.applyUiEvent(event, window)) {
                return result
            }
            if (let Some(result) <- contextMenuB.applyUiEvent(event, window)) {
                return result
            }
        }
        if (event.eventKind == 27 && event.node.actionName == "OPEN_INSPECTOR") {
            inspectorRequested = true
            status = "只读 Inspector 将在本帧后打开；它不执行命令，只读当前绑定"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_COMMAND_THEME") {
            themeName = if (themeName == "light") { "dark" } else { "light" }
            // Restyle only the paint of an already open menu; its request,
            // projection, initial focus and shared scroll viewport stay as-is.
            let _ = contextMenuA.restyle(commandMenuStyle())
            let _ = contextMenuB.restyle(commandMenuStyle())
            status = "命令主题：${if (themeName == "light") { "浅色" } else { "深色" }}；打开中的查询、导航与滚动位置保持不变"
            localRevision += 1
            getStdOut().writeln("SETTINGS_COMMAND_THEME mode=${themeName}")
            getStdOut().flush()
            if (let Some(window) <- windowValue) {
                window.requestRefresh()
            }
            return CjguiComposableUiDispatchResult(true)
        }
        // A context command re-enters here through invokeContextMenuCommand with
        // its stable id in the event text. Two commands may share one control
        // target, so the id selects the owner write before the target's own
        // action name is considered.
        if (event.eventKind == 27 && event.text.startsWith("settings.instance-")) {
            if (let Some(result) <- performScopedCommand(event.text)) {
                return result
            }
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
        if (let Some(result) <- commandPalette.applyUiEvent(event)) {
            return result
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        // A scoped command trigger carries only the command id. The common
        // window entry resolves the declaration's own scope/target and
        // re-enters this controller through the ordinary action event.
        if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
            if (let Some(window) <- windowValue) {
                let applied = window.invokeCommand(commandId)
                if (!applied) {
                    status = "命令未执行：目标已失效或命令已禁用"
                    localRevision += 1
                }
                return CjguiComposableUiDispatchResult(applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "SEARCH_COMMANDS") {
            if (let Some(window) <- windowValue) {
                let target = window.editingFocusReference() ?? window.focusedNodeReference() ??
                    CjguiComposableUiNodeReference.manual(305)
                paletteOwner = "main"
                commandPalette.open("命令", commandPlacement, target,
                    hint: "输入命令名或快捷键；回车执行，Esc 取消")
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "SEARCH_SCOPED_A" || event.node.actionName == "SEARCH_SCOPED_B") {
            let key = if (event.node.actionName == "SEARCH_SCOPED_A") {
                "a"
            } else {
                "b"
            }
            let scope = if (key == "a") {
                instanceAScope
            } else {
                instanceBScope
            }
            let placement = if (key == "a") {
                instanceAPlacement
            } else {
                instanceBPlacement
            }
            paletteOwner = key
            commandPalette.open("命令 ${key}", placement,
                CjguiComposableUiNodeReference.scoped(scope, "search"),
                hint: "只显示作用域 ${key} 的命令；回车执行，Esc 取消")
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "SWAP_SCOPED_INSTANCES") {
            instancesSwapped = !instancesSwapped
            status = if (instancesSwapped) {
                "已交换 A/B 组件位置；命令目标仍按各自作用域解析"
            } else {
                "已恢复 A/B 组件原顺序；命令目标仍按各自作用域解析"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CYCLE_SCOPED_COMMANDS") {
            let next = match (scopedCommandMode) {
                case "all" => "disabled-a"
                case "disabled-a" => "removed-a"
                case "removed-a" => "empty"
                case _ => "all"
            }
            scopedCommandMode = next
            // The same source feeds the open menu and the toolbar. Re-project
            // synchronously so an old row cannot stay actionable in this FIFO
            // turn; the window also revalidates the id at invocation.
            let snapshot = domain.formSnapshot()
            if (let Some(window) <- windowValue) {
                if (contextMenuA.isOpen()) {
                    let kept = contextMenuA.reconcile(window, scopedMenuCommands(snapshot, "a"),
                        scopedMenuMetadata("a"), searchCommandId: "settings.instance-a.search")
                    getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=${if (kept) { "reconciled" } else { "retired" }} " +
                        "request_id=${contextMenuA.currentRequestId()} scope=a mode=${scopedCommandMode}")
                    getStdOut().flush()
                }
                if (contextMenuB.isOpen()) {
                    let kept = contextMenuB.reconcile(window, scopedMenuCommands(snapshot, "b"),
                        scopedMenuMetadata("b"), searchCommandId: "settings.instance-b.search")
                    getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=${if (kept) { "reconciled" } else { "retired" }} " +
                        "request_id=${contextMenuB.currentRequestId()} scope=b mode=${scopedCommandMode}")
                    getStdOut().flush()
                }
            }
            status = "命令集已切换为 ${scopedCommandMode}；工具栏与打开的面板复用当前投影"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "INVOKE_SCOPED_A_COMMAND") {
            if (let Some(window) <- windowValue) {
                let applied = window.invokeCommand("settings.instance-a.toggle")
                status = if (applied) {
                    "A 命令已执行"
                } else {
                    "A 命令入口拒绝：已禁用或已移除，owner 未写入"
                }
                localRevision += 1
                return CjguiComposableUiDispatchResult(applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "OPEN_SCOPED_A_PANEL") {
            if (let Some(window) <- windowValue) {
                paletteOwner = "a"
                commandPalette.open("命令 a", instanceAPlacement,
                    CjguiComposableUiNodeReference.scoped(instanceAScope, "control"),
                    hint: "当前命令集：${scopedCommandMode}；Esc 取消")
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "FOCUS_SETTINGS_FIELD") {
            let feedback = match (latestFeedback) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let fieldId = feedback.fieldIdForResourceId(event.node.operationResourceId)
            if (fieldId.size == 0) {
                status = "无法定位：摘要项没有对应字段"
                localRevision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            let window = match (windowValue) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let outcome = cjguiFocusFormFeedback(window, feedback, fieldId,
                targetNodeId: currentPlacement.editorNodeId(fieldId))
            let label = match (feedback.descriptorFor(fieldId)) {
                case Some(value) => value.label
                case None => fieldId
            }
            status = if (outcome.focusRecorded) {
                "已请求定位「${label}」，窗口焦点记录已指向该字段"
            } else if (outcome.requestAccepted) {
                "已请求定位「${label}」，等待目标可见后记录焦点"
            } else {
                "无法定位「${label}」：${outcome.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(outcome.requestAccepted)
        }
        return performAction(event.node.actionName)
    }

    private func performScopedCommand(commandId: String): ?CjguiComposableUiDispatchResult {
        let isEnable = commandId.endsWith(".enable")
        let isDisable = commandId.endsWith(".disable")
        if (isEnable || isDisable) {
            let key = if (commandId.startsWith("settings.instance-a.")) { "a" } else { "b" }
            let resource = if (key == "a") {
                CjguiSettingsFormDomain.useProxyResourceId
            } else {
                CjguiSettingsFormDomain.notifyOnFailureResourceId
            }
            let targetValue = isEnable
            let result = domain.editBooleanFromHuman(resource, targetValue)
            let label = if (targetValue) { "设为开启" } else { "设为关闭" }
            status = if (result.applied) {
                "作用域 ${key} 的“${label}”已写入 owner"
            } else {
                "作用域 ${key} 的“${label}”未写入：${result.reason}"
            }
            localRevision += 1
            getStdOut().writeln("SETTINGS_SCOPED_COMMAND command_id=${commandId} " +
                "applied=${result.applied} reason=${if (result.applied) { "none" } else { result.reason }}")
            getStdOut().flush()
            return Some(CjguiComposableUiDispatchResult(result.applied))
        }
        if (commandId == "settings.instance-a.reset" || commandId == "settings.instance-b.reset") {
            status = "恢复默认命令已禁用；owner 未写入"
            localRevision += 1
            return Some(CjguiComposableUiDispatchResult(false))
        }
        return None
    }

    private func performAction(actionName: String): CjguiComposableUiDispatchResult {
        if (actionName == "APPLY") {
            let draft = domain.formSnapshot()
            let result = domain.applyDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "已应用设置 v${result.versionAfter}"
            } else {
                "未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (actionName == "RESET") {
            let draft = domain.formSnapshot()
            let result = domain.cancelDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion)
            status = if (result.applied) {
                "草稿已恢复为已应用值"
            } else {
                "未恢复：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (actionName == "REORDER_GROUPS") {
            groupsReordered = !groupsReordered
            status = "仅切换分组呈现顺序，草稿、已应用值和焦点身份未变"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (actionName == "TOGGLE_PROXY") {
            // The toolbar, palette and native menu all read this draft boolean
            // from the form owner; the command never keeps a second copy.
            let current = settingsProxyChecked(domain.formSnapshot())
            let result = domain.editBooleanFromHuman(CjguiSettingsFormDomain.useProxyResourceId, !current)
            let nextState = if (!current) {
                "开启"
            } else {
                "关闭"
            }
            status = if (result.applied) {
                "代理草稿已切换为${nextState}"
            } else {
                "未切换：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (actionName == "TOGGLE_NOTIFY") {
            let current = settingsNotifyChecked(domain.formSnapshot())
            let result = domain.editBooleanFromHuman(CjguiSettingsFormDomain.notifyOnFailureResourceId, !current)
            let nextState = if (!current) {
                "开启"
            } else {
                "关闭"
            }
            status = if (result.applied) {
                "失败通知草稿已切换为${nextState}"
            } else {
                "未切换：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    // Adversarial verification hook. It changes the command source without
    // re-projecting the open menu, then invokes through the old entry. The
    // framework must reject the stale command from its live command bindings.
    // Active only when the harness environment variable names the target mode.
    private func runStaleSourceHarness(window: CjguiComposableUiWindow): Unit {
        let mode = match (getVariable("CJGUI_CONTEXT_MENU_STALE_SOURCE")) {
            case Some(value) => value
            case None => return
        }
        if (mode.size == 0) { return }
        match (staleSourceStep) {
            case 0 =>
                let openNow = contextMenuA.isOpen()
                if (!openNow) {
                    if (staleSourceWasOpen) { staleSourceArmed = true }
                    staleSourceWasOpen = false
                    return
                }
                staleSourceWasOpen = true
                // The first menu of the run must fully close (normal execution)
                // before the next open becomes the adversarial stale-source case.
                if (!staleSourceArmed) {
                    return
                }
                staleSourceStep = 1
                staleSourceRequestId = contextMenuA.currentRequestId()
                scopedCommandMode = mode
                localRevision += 1
                window.requestRefresh()
                getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=source_changed " +
                    "request_id=${staleSourceRequestId} scope=a mode=${scopedCommandMode}")
                getStdOut().flush()
            case 1 =>
                staleSourceStep = 2
                let _ = window.refreshIfNeeded()
                let applied = window.invokeContextMenuCommand(staleSourceRequestId,
                    "settings.instance-a.toggle")
                localRevision += 1
                getStdOut().writeln("SETTINGS_CONTEXT_MENU phase=stale_invocation " +
                    "request_id=${staleSourceRequestId} scope=a command_id=settings.instance-a.toggle " +
                    "applied=${applied} mode=${scopedCommandMode}")
                getStdOut().flush()
            case _ => ()
        }
    }

    public func finishPanelAction(window: CjguiComposableUiWindow): Unit {
        runStaleSourceHarness(window)
        if (let Some(item) <- commandPalette.takeConfirmed(window)) {
            // Resolve the same declaration list the toolbar and native menu
            // use. A removed or now-disabled command is not executed from the
            // panel's older row snapshot.
            let snapshot = domain.formSnapshot()
            let commands = settingsCommands(snapshot.canApply, false, settingsProxyChecked(snapshot))
            for (command in scopedCommandsFor(snapshot)) {
                commands.add(command)
            }
            var declaration: ?CjguiComposableUiCommand = None
            for (command in commands) {
                if (command.id == item.commandId) {
                    declaration = Some(command)
                }
            }
            let current = match (declaration) {
                case Some(value) => value
                case None =>
                    status = "命令已移除，未执行：${item.label}"
                    localRevision += 1
                    window.requestRefresh()
                    return
            }
            if (!current.isEnabled) {
                status = "命令当前不可用，未执行：${item.label}"
                localRevision += 1
                window.requestRefresh()
                return
            }
            // The common window entry resolves the current target and scope,
            // then re-enters this controller through the normal event path.
            // The old panel placement never executes the business action.
            if (!window.invokeCommand(current.id)) {
                status = "命令未执行：${item.label}（目标已失效或不在当前范围）"
                localRevision += 1
                window.requestRefresh()
            }
        }
        let failure = commandPalette.takeConfirmationFailure()
        if (failure.size > 0) {
            status = "命令面板返回失败：${failure}"
            localRevision += 1
            window.requestRefresh()
        }
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        status = "输入未应用：事件 ${eventKind} 的目标已刷新或移除（节点 ${nodeId}）"
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }
}

private func settingsPlacement(reordered: Bool): CjguiComposableFormPlacement {
    let connection = CjguiComposableFormGroupPlacement("connection", "连接", 2100,
        ArrayList<CjguiComposableFormFieldPlacement>(
            [
                CjguiComposableFormFieldPlacement("endpoint", 2110,
                    helpText: "服务地址必须以 https:// 开头，且不能包含空格。此值在应用前只修改草稿，不会影响正在使用的已应用配置。"),
                CjguiComposableFormFieldPlacement("retryLimit", 2130, helpText: "失败后最多自动重试的次数，范围 1–10。"),
                CjguiComposableFormFieldPlacement("useProxy", 2150, helpText: "共享工作区请求经代理转发。"),
                CjguiComposableFormFieldPlacement("workspaceId", 2170, readOnly: true,
                    helpText: "工作区创建时分配，只读；编辑请求会由 owner 拒绝。")
            ]),
        description: "服务地址、重试策略和代理开关。分组与字段顺序只是呈现，字段身份始终是稳定 id。")
    let publishing = CjguiComposableFormGroupPlacement("publishing", "发布", 2200,
        ArrayList<CjguiComposableFormFieldPlacement>(
            [
                CjguiComposableFormFieldPlacement("displayName", 2210,
                    helpText: "显示在发布记录和失败通知中。留空会产生可复现的字段错误。"),
                CjguiComposableFormFieldPlacement("refreshSeconds", 2230,
                    helpText: "刷新间隔，范围 5–300 秒；超出范围时摘要与字段提示使用同一条 owner 反馈。"),
                CjguiComposableFormFieldPlacement("notifyOnFailure", 2250, helpText: "失败时通知工作区管理员。"),
                CjguiComposableFormFieldPlacement("lastPublished", 2270, readOnly: true,
                    helpText: "最近一次应用的时间标识，由 owner 在应用后写入。")
            ]),
        description: "发布名称、刷新节奏与失败通知。两个分组可以调换顺序，草稿不会因此应用或取消。")
    return if (reordered) {
        CjguiComposableFormPlacement(
            ArrayList<CjguiComposableFormGroupPlacement>([publishing, connection]))
    } else {
        CjguiComposableFormPlacement(
            ArrayList<CjguiComposableFormGroupPlacement>([connection, publishing]))
    }
}

// The single command declaration list. Labels, target nodes, enabled/checked
// state and shortcuts come from here; the toolbar and palette only project it.
private func settingsProxyChecked(snapshot: CjguiSharedFormSnapshot): Bool {
    return snapshot.fieldForResourceId(CjguiSettingsFormDomain.useProxyResourceId).draftText == "true"
}

private func settingsNotifyChecked(snapshot: CjguiSharedFormSnapshot): Bool {
    return snapshot.fieldForResourceId(CjguiSettingsFormDomain.notifyOnFailureResourceId).draftText == "true"
}

// The same reusable command component is mounted twice. Each mount owns one
// scope; the control, toolbar, search button and command targets below use
// only local keys, so the registry allocates independent node identities and
// a reorder cannot move a command to the sibling instance.
private func settingsScopedCommands(scope: CjguiComposableUiIdentityScope, key: String, title: String,
    checked: Bool, enabled!: Bool = true): ArrayList<CjguiComposableUiCommand> {
    let commands = ArrayList<CjguiComposableUiCommand>()
    commands.add(CjguiComposableUiCommand("settings.instance-${key}.toggle",
        CjguiComposableUiNodeReference.scoped(scope, "control"),
        "切换${title}并同步远程策略与本地缓存", "", 0, enabled, checked, isCheckable: true))
    // Two executable commands share the same control target; the middle one is
    // intentionally disabled so menu navigation must skip it.
    commands.add(CjguiComposableUiCommand("settings.instance-${key}.reset",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "恢复默认${title}", "", 1, false, false))
    commands.add(CjguiComposableUiCommand("settings.instance-${key}.disable",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "设为关闭${title}", "", 2, enabled, false))
    commands.add(CjguiComposableUiCommand("settings.instance-${key}.enable",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "设为开启${title}", "", 3, enabled, false))
    commands.add(CjguiComposableUiCommand("settings.instance-${key}.search",
        CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索${title}", "", 4, enabled, false))
    return commands
}

// The first enabled command is deliberately behind more disabled rows than a
// 132-high menu can show, so opening it exercises the initial-focus reveal.
private func settingsLeadingDisabledCommands(scope: CjguiComposableUiIdentityScope,
    checked: Bool): ArrayList<CjguiComposableUiCommand> {
    let commands = ArrayList<CjguiComposableUiCommand>()
    commands.add(CjguiComposableUiCommand("settings.instance-a.toggle",
        CjguiComposableUiNodeReference.scoped(scope, "control"),
        "切换代理 A 并同步远程策略与本地缓存", "", 0, false, checked, isCheckable: true))
    commands.add(CjguiComposableUiCommand("settings.instance-a.reset",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "恢复默认代理 A", "", 1, false, false))
    commands.add(CjguiComposableUiCommand("settings.instance-a.disable",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "设为关闭代理 A", "", 2, false, false))
    commands.add(CjguiComposableUiCommand("settings.instance-a.enable",
        CjguiComposableUiNodeReference.scoped(scope, "control"), "设为开启代理 A", "", 3, true, false))
    commands.add(CjguiComposableUiCommand("settings.instance-a.search",
        CjguiComposableUiNodeReference.scoped(scope, "search"), "搜索代理 A", "", 4, true, false))
    return commands
}

private func settingsScopedMetadata(key: String, actionName: String, resourceId: Int64,
    searchActionName: String): ArrayList<CjguiCommandToolbarMetadata> {
    return ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.instance-${key}.toggle", actionName, resourceId,
            detail: "作用域 ${key} 的命令；触发后经 window.invokeCommand 进入对应 owner 控件",
            disabledReason: "该作用域命令当前被外部命令集禁用"),
        CjguiCommandToolbarMetadata("settings.instance-${key}.reset", "RESET_SCOPED_${key}", resourceId,
            detail: "同一目标上的禁用命令；键盘导航必须跳过它",
            disabledReason: "当前草稿仍有未提交的字段修改，并且窄窗口下不允许恢复默认值"),
        CjguiCommandToolbarMetadata("settings.instance-${key}.disable", "DISABLE_SCOPED_${key}", resourceId,
            detail: "同一目标上的可执行命令，把布尔草稿设为关闭",
            disabledReason: "该作用域命令当前被外部命令集禁用"),
        CjguiCommandToolbarMetadata("settings.instance-${key}.enable", "ENABLE_SCOPED_${key}", resourceId,
            detail: "同一目标上的可执行命令，把布尔草稿设为开启",
            disabledReason: "该作用域命令当前被外部命令集禁用"),
        CjguiCommandToolbarMetadata("settings.instance-${key}.search", searchActionName, resourceId,
            detail: "打开只含作用域 ${key} 命令的面板",
            disabledReason: "该作用域命令当前被外部命令集禁用")
    ])
}

private func settingsScopedPresentation(scope: CjguiComposableUiIdentityScope, key: String, title: String,
    actionName: String, checked: Bool, resourceId: Int64,
    searchActionName: String): CjguiCommandPresentation {
    return CjguiCommandPresentation(
        settingsScopedCommands(scope, key, title, checked),
        settingsScopedMetadata(key, actionName, resourceId, searchActionName),
        searchCommandId: "settings.instance-${key}.search")
}

private func settingsScopedPlacement(scope: CjguiComposableUiIdentityScope, key: String, title: String,
    actionName: String, checked: Bool, resourceId: Int64,
    searchActionName: String): CjguiCommandToolbarPlacement {
    return settingsScopedPresentation(scope, key, title, actionName, checked, resourceId, searchActionName).placement()
}

private func settingsCommands(canApply: Bool, panelOpen: Bool,
    useProxyChecked: Bool): ArrayList<CjguiComposableUiCommand> {
    let commands = ArrayList<CjguiComposableUiCommand>()
    commands.add(CjguiComposableUiCommand("settings.apply",
        CjguiComposableUiNodeReference.manual(301), "应用设置", "Settings", 0,
        canApply && !panelOpen, false))
    commands.add(CjguiComposableUiCommand("settings.reset",
        CjguiComposableUiNodeReference.manual(302), "恢复已应用值", "Settings", 0, !panelOpen, false))
    commands.add(CjguiComposableUiCommand("settings.reorder-groups",
        CjguiComposableUiNodeReference.manual(303), "切换分组顺序", "View", 0, !panelOpen, false))
    // The draft proxy boolean is the only checked value. Toolbar, palette and
    // native menu all derive it from this one command declaration; the
    // checkable bit is declared, never guessed from a label glyph.
    commands.add(CjguiComposableUiCommand("settings.toggle-proxy",
        CjguiComposableUiNodeReference.manual(306), "使用代理", "Settings", 2, !panelOpen, useProxyChecked,
        isCheckable: true))
    commands.add(CjguiComposableUiCommand("settings.close",
        CjguiComposableUiNodeReference.manual(304), "关闭", "File", 1, !panelOpen, false))
    // The search button is a real button of this owner with the domain
    // resource, so its command identity can be staged by native. Cmd+K opens
    // the same panel the button opens; no synthetic resource is used.
    commands.add(CjguiComposableUiCommand("settings.search-commands",
        CjguiComposableUiNodeReference.manual(305), "搜索命令", CjguiComposableUiShortcut("k"), "View", 1, !panelOpen, false))
    // The theme switch stays enabled while the palette or a menu layer is open:
    // it is presentation-only and must remain reachable to exercise the
    // "theme change while open" contract.
    commands.add(CjguiComposableUiCommand("settings.toggle-command-theme",
        CjguiComposableUiNodeReference.manual(615), "切换命令主题",
        CjguiComposableUiShortcut("t", usesShift: true), "View", 2, true, false, presentationOnly: true))
    commands.add(CjguiComposableUiCommand("settings.open-inspector",
        CjguiComposableUiNodeReference.manual(617), "打开只读 Inspector",
        CjguiComposableUiShortcut("i", usesShift: true), "View", 3, true, false))
    return commands
}

private func settingsCommandMetadata(): ArrayList<CjguiCommandToolbarMetadata> {
    let resource = CjguiSettingsFormDomain.resourceId
    return ArrayList<CjguiCommandToolbarMetadata>(
        [
            CjguiCommandToolbarMetadata("settings.apply", "APPLY", resource,
                detail: "把当前草稿原子应用为已发布配置",
                disabledReason: "草稿仍有字段错误或应用基线已变化"),
            CjguiCommandToolbarMetadata("settings.reset", "RESET", resource,
                detail: "丢弃草稿并回到已应用配置"),
            CjguiCommandToolbarMetadata("settings.reorder-groups", "REORDER_GROUPS", resource,
                detail: "只改变分组呈现，不应用或取消草稿"),
            CjguiCommandToolbarMetadata("settings.toggle-proxy", "TOGGLE_PROXY", resource,
                detail: "切换草稿中的代理开关；勾选状态来自同一声明"),
            CjguiCommandToolbarMetadata("settings.close", "CLOSE", resource,
                detail: "正常关闭窗口"),
            CjguiCommandToolbarMetadata("settings.search-commands", "SEARCH_COMMANDS", resource,
                detail: "打开命令面板；也可按 ⌘K"),
            CjguiCommandToolbarMetadata("settings.toggle-command-theme", "TOGGLE_COMMAND_THEME", 0,
                detail: "切换工具栏、面板与上下文菜单的浅色／深色命令主题；打开期间保留查询、导航与滚动位置；也可按 ⌘⇧T"),
            CjguiCommandToolbarMetadata("settings.open-inspector", "OPEN_INSPECTOR", 0,
                detail: "打开既有只读 Inspector；按需读取命令声明与 accepted 目标，不执行命令；也可按 ⌘⇧I")
        ])
}

private func settingsCommandPresentation(canApply: Bool, panelOpen: Bool,
    useProxyChecked: Bool): CjguiCommandPresentation {
    return CjguiCommandPresentation(settingsCommands(canApply, panelOpen, useProxyChecked),
        settingsCommandMetadata(), searchCommandId: "settings.search-commands")
}

private func settingsCommandPlacement(canApply: Bool, panelOpen: Bool,
    useProxyChecked: Bool): CjguiCommandToolbarPlacement {
    return settingsCommandPresentation(canApply, panelOpen, useProxyChecked).placement()
}

private func settingsAuthorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "设置表单本地 Agent",
        "cjgui-settings-form-agent-20261020",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
                CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
                CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
                CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
                CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true)
            ]
        )
    )
}

private func runSettingsWindow(): Int32 {
    let domain = CjguiSettingsFormDomain()
    let controller = CjguiSettingsFormController(domain)
    let narrow = match (getVariable("CJGUI_SETTINGS_NARROW")) {
        case Some(value) => value == "1"
        case None => false
    }
    let width = if (narrow) { 460u32 } else { 980u32 }
    let height = if (narrow) { 760u32 } else { 900u32 }
    // The business window and the Inspector are two read-only consumers of the
    // same application lifecycle; the domain stays owned by this controller.
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("工作区设置 · 分组表单", width, height,
            rangeTextEditDeltaDelivery: true))
    if (!opened.didOpen) {
        application.close()
        return 1
    }
    let businessId = opened.identifier.getOrThrow()
    let window = application.window(businessId).getOrThrow()
    controller.bindWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, settingsAuthorization(), domain, window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !application.attachExternalConnection(connection)) {
        application.close()
        return 1
    }
    let inspector = CjguiMacosInspector(application, businessId)
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_SETTINGS_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_SETTINGS_READY PROTOCOL ${info.protocol}")
        output.writeln("CJGUI_SETTINGS_READY WINDOW ${width}x${height} narrow=${narrow}")
        output.flush()
    }
    while (application.isOpen()) {
        let _ = application.pumpOneTurn()
        if (controller.takeInspectorRequest()) {
            let result = inspector.open()
            getStdOut().writeln("SETTINGS_INSPECTOR phase=${if (result.didOpen) { "opened" } else { "refused" }} " +
                "reason=${result.reason}")
            getStdOut().flush()
        }
        inspector.synchronizeLifetime()
        controller.finishPanelAction(window)
    }
    inspector.close()
    application.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size != 0) {
        getStdErr().writeln("usage: CJGUISettingsForm")
        return 2
    }
    return Int64(runSettingsWindow())
}
