package cjgui_command_surface_starter

import cjgui.*
import std.collection.*
import std.env.*

/// Optional command-surface starter. One declaration list feeds the toolbar,
/// the context menu, shortcut chords and the native menu projection. The
/// controller owns the counter; focus, layers and command revalidation stay in
/// the framework.
class CommandSurfaceController <: CjguiComposableUiController & CjguiComposableUiContextMenuRequestHandler &
    CjguiComposableUiSceneRefreshParticipant {
    private let commandScope = CjguiComposableUiIdentityScope("starter-commands")
    private let menu = CjguiContextCommandMenu(CjguiComposableUiIdentityScope("starter-menu"),
        "starter-command-menu")
    private var count: Int64 = 0
    private var pinned: Bool = false
    private var usesLight: Bool = false
    private var status: String = "工具栏、右键菜单与快捷键消费同一组命令声明"
    private var revision: Int64 = 1
    private var windowValue: ?CjguiComposableUiWindow = None
    private var inspectorRequested: Bool = false

    public func attach(window: CjguiComposableUiWindow): Unit {
        windowValue = Some(window)
    }

    /// The application drains this after a pump turn; opening a second window
    /// is application wiring, not a framework command side effect.
    public func takeInspectorRequest(): Bool {
        let requested = inspectorRequested
        inspectorRequested = false
        return requested
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func beginSceneRefresh(): Bool {
        return true
    }

    public func prepareSceneRefresh(): Bool {
        return true
    }

    /// The window binds these declarations only after the target resolves in
    /// the accepted scene, so menus and shortcuts never point at a provisional
    /// renderer node.
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return commands()
    }

    public func commitSceneRefresh(): Unit {
    }

    public func rollbackSceneRefresh(): Unit {
    }

    public func disposeSceneRefreshResources(): Unit {
    }

    private func currentTheme(): CjguiComposableUiTheme {
        return if (usesLight) {
            CjguiComposableUiTheme.paperLight()
        } else {
            CjguiComposableUiTheme.beaconDark()
        }
    }

    // Each command names its own owner control. Toolbar and native/shortcut
    // dispatch execute the target's declared action, so two commands cannot
    // share one generic target and still stay distinguishable. Disabled and
    // checked state are part of the declaration, not of each surface.
    private func commands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        commands.add(CjguiComposableUiCommand("starter.add", CjguiComposableUiNodeReference.manual(22),
            "计数 +1", CjguiComposableUiShortcut("n"), "Edit", 0, true, false))
        commands.add(CjguiComposableUiCommand("starter.pin", CjguiComposableUiNodeReference.manual(23),
            "固定读数", CjguiComposableUiShortcut("p"), "View", 0, true, pinned, isCheckable: true))
        commands.add(CjguiComposableUiCommand("starter.reset", CjguiComposableUiNodeReference.manual(24),
            "清零", CjguiComposableUiShortcut("r"), "Edit", 1, count != 0, false))
        commands.add(CjguiComposableUiCommand("starter.theme", CjguiComposableUiNodeReference.manual(25),
            "浅色外观", CjguiComposableUiShortcut("t"), "View", 1, true, usesLight, isCheckable: true))
        commands.add(CjguiComposableUiCommand("starter.inspector", CjguiComposableUiNodeReference.manual(26),
            "只读命令诊断", CjguiComposableUiShortcut("i", usesShift: true), "View", 2, true, false))
        commands.add(CjguiComposableUiCommand("starter.close", CjguiComposableUiNodeReference.manual(27),
            "关闭", CjguiComposableUiShortcut("w"), "File", 0, true, false))
        return commands
    }

    // The right-clicked owner is the request target. These rows exist only for
    // the frozen request, so they declare RequestLocal and the window still
    // re-checks the accepted target at invocation. Each id selects the same
    // owner action as its window command.
    private func contextCommands(): ArrayList<CjguiComposableUiCommand> {
        let target = CjguiComposableUiNodeReference.manual(22)
        let commands = ArrayList<CjguiComposableUiCommand>()
        commands.add(CjguiComposableUiCommand("starter.context.add", target, "计数 +1", "", 0, true, false))
        commands.add(CjguiComposableUiCommand("starter.context.pin", target, "固定读数", "", 1, true, pinned,
            isCheckable: true))
        commands.add(CjguiComposableUiCommand("starter.context.reset", target, "清零", "", 2,
            count != 0, false))
        commands.add(CjguiComposableUiCommand("starter.context.inspector", target, "只读命令诊断", "", 3,
            true, false))
        return commands
    }

    private func metadata(): ArrayList<CjguiCommandToolbarMetadata> {
        return ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("starter.add", "STARTER_ADD", 0,
                detail: "增加本地计数；⌘N 与两个入口执行同一命令"),
            CjguiCommandToolbarMetadata("starter.pin", "STARTER_PIN", 0,
                detail: "勾选状态来自同一声明"),
            CjguiCommandToolbarMetadata("starter.reset", "STARTER_RESET", 0,
                detail: "把计数归零", disabledReason: "计数已经为 0"),
            CjguiCommandToolbarMetadata("starter.theme", "STARTER_THEME", 0,
                detail: "切换浅色／深色；打开中的菜单只换漆并保留导航"),
            CjguiCommandToolbarMetadata("starter.inspector", "STARTER_INSPECTOR", 0,
                detail: "打开只读 Inspector 的命令视图"),
            CjguiCommandToolbarMetadata("starter.close", "STARTER_CLOSE", 0,
                detail: "正常关闭窗口")
        ])
    }

    private func contextMetadata(): ArrayList<CjguiCommandToolbarMetadata> {
        return ArrayList<CjguiCommandToolbarMetadata>([
            CjguiCommandToolbarMetadata("starter.context.add", "STARTER_ADD", 0,
                detail: "与工具栏、快捷键落到同一个 STARTER_ADD 动作"),
            CjguiCommandToolbarMetadata("starter.context.pin", "STARTER_PIN", 0,
                detail: "勾选来自请求时的命令声明"),
            CjguiCommandToolbarMetadata("starter.context.reset", "STARTER_RESET", 0,
                detail: "把计数归零", disabledReason: "计数已经为 0"),
            CjguiCommandToolbarMetadata("starter.context.inspector", "STARTER_INSPECTOR", 0,
                detail: "只读命令诊断；不执行命令")
        ])
    }

    private func presentation(): CjguiCommandPresentation {
        return CjguiCommandPresentation(commands(), metadata())
    }

    private func contextPresentation(): CjguiCommandPresentation {
        return CjguiCommandPresentation(contextCommands(), contextMetadata())
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = currentTheme()
        let action = CjguiComposableUiNamedStyle("starter-action", theme.primaryAction,
            interaction: theme.primaryActionInteraction, purpose: "主操作")
        let targetStyle = CjguiComposableUiStyle(fixedHeight: 32, background: theme.card.background,
            border: theme.card.border, textColor: theme.body.textColor, fontFamily: theme.body.fontFamily)
        let host = cjguiComposableLayerHost(1, "command-surface-root", theme.page)
        let content = cjguiComposableVertical(2, "command-surface-content",
            CjguiComposableUiStyle(padding: 16, gap: 10, growY: 1, background: theme.card.background,
                border: theme.card.border, cornerRadius: 12, clipsContent: true))
        content.add(cjguiComposableText(3, "command-surface-title", "命令组件入门", theme.heading))
        content.add(cjguiComposableText(4, "command-surface-help",
            "下面是真正的 owner 控件；工具栏、快捷键与右键菜单只投影同一组声明，激活后仍回到这些控件声明的动作。",
            CjguiComposableUiStyle(fontSize: theme.body.fontSize, textColor: theme.body.textColor,
                textMaxLines: 2, textOverflow: "ellipsis")))
        content.add(cjguiComposableCommandToolbar(commandScope, "command-surface-toolbar",
            presentation().placement(), style: CjguiCommandToolbarStyle.themed(theme)))
        let pinSuffix = if (pinned) { " · 已固定" } else { "" }
        let reading = if (count == 0) {
            "当前读数：0${pinSuffix} · 计数为 0 时“清零”在工具栏与菜单中同为禁用"
        } else {
            "当前读数：${count}${pinSuffix}"
        }
        content.add(cjguiComposableText(5, "command-surface-reading", reading,
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 20.0, fontWeight: 1,
                textColor: theme.heading.textColor)))
        let owners = cjguiComposableWrap(20, "command-surface-owners",
            CjguiComposableUiStyle(gap: 8, growX: 1), rowGap: 8)
        owners.add(cjguiComposableButton(22, "command-surface-target",
            "计数 +1", "STARTER_ADD", 0, targetStyle, interactionStyle: theme.cardInteraction))
        owners.add(cjguiComposableButton(23, "command-surface-owner-pin",
            "固定读数", "STARTER_PIN", 0, targetStyle, interactionStyle: theme.cardInteraction))
        owners.add(cjguiComposableButton(24, "command-surface-owner-reset",
            "清零", "STARTER_RESET", 0, targetStyle, enabled: count != 0,
            interactionStyle: theme.cardInteraction))
        owners.add(cjguiComposableButton(25, "command-surface-owner-theme",
            "浅色外观", "STARTER_THEME", 0, targetStyle, interactionStyle: theme.cardInteraction))
        owners.add(cjguiComposableButton(26, "command-surface-owner-inspector",
            "只读命令诊断", "STARTER_INSPECTOR", 0, targetStyle,
            interactionStyle: theme.cardInteraction))
        owners.add(cjguiComposableButton(27, "command-surface-owner-close",
            "关闭", "STARTER_CLOSE", 0, targetStyle, interactionStyle: theme.cardInteraction))
        content.add(owners)
        content.add(cjguiComposableText(6, "command-surface-status", status,
            CjguiComposableUiStyle(fixedHeight: 40, fontSize: theme.body.fontSize,
                textColor: theme.body.textColor, textMaxLines: 2, textOverflow: "ellipsis")))
        host.add(content)
        host.add(cjguiComposableText(7, "command-surface-foot",
            "⌘N / ⌘P / ⌘R / ⌘T / ⌘⇧I / ⌘W 由同一组声明提供；原生菜单只做投影。",
            CjguiComposableUiStyle(fixedHeight: 22, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        menu.attachTo(host)
        return host
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        if (request.nodeId != 22) {
            status = "只有命令目标声明了上下文命令；其他控件不伪造右键请求"
            revision += 1
            return false
        }
        let window = match (windowValue) {
            case Some(value) => value
            case None => return false
        }
        let opened = menu.open(window, request, contextPresentation(), "command-surface",
            source: CjguiContextMenuCommandSource.RequestLocal,
            style: CjguiContextCommandMenuStyle.themed(currentTheme()))
        status = if (opened) {
            "上下文菜单已打开；行来自请求本地的命令，执行仍回到对应 owner 动作"
        } else {
            "上下文菜单未打开：命令集为空或请求已被窗口拒绝"
        }
        revision += 1
        return opened
    }

    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        if (!menu.requestEnded(requestId)) {
            return
        }
        status = "上下文菜单已结束：${reason}"
        revision += 1
        match (windowValue) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    private func applyAction(action: String): CjguiComposableUiDispatchResult {
        if (action == "STARTER_ADD") {
            count += 1
            status = "计数已增加；工具栏、快捷键与上下文菜单走同一个 owner 动作"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (action == "STARTER_PIN") {
            pinned = !pinned
            status = if (pinned) {
                "读数已固定；勾选标记来自声明本身"
            } else {
                "读数已取消固定"
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (action == "STARTER_RESET") {
            count = 0
            status = "计数已清零；清零命令现在本身不可用"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (action == "STARTER_THEME") {
            usesLight = !usesLight
            let _ = menu.restyle(CjguiContextCommandMenuStyle.themed(currentTheme()))
            status = "命令外观已切换；打开中的菜单保留查询、导航与滚动位置"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (action == "STARTER_INSPECTOR") {
            inspectorRequested = true
            status = "只读 Inspector 将在本帧后打开；它不执行命令，只读当前绑定"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (action == "STARTER_CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    // A request-local row is selected by its id, not by the target's default
    // action, because every row names the same right-clicked owner.
    private func contextActionName(commandId: String): String {
        if (commandId == "starter.context.add") { return "STARTER_ADD" }
        if (commandId == "starter.context.pin") { return "STARTER_PIN" }
        if (commandId == "starter.context.reset") { return "STARTER_RESET" }
        if (commandId == "starter.context.inspector") { return "STARTER_INSPECTOR" }
        return ""
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (let Some(window) <- windowValue) {
            if (let Some(result) <- menu.applyUiEvent(event, window)) {
                return result
            }
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        // A context row re-enters with its request-local id in `event.text`.
        // Window commands dispatch to their owner target with empty text, so
        // the target's own action below is the single execution definition.
        if (event.text.startsWith("starter.context.")) {
            return applyAction(contextActionName(event.text))
        }
        if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
            if (let Some(window) <- windowValue) {
                let applied = window.invokeCommand(commandId)
                if (!applied) {
                    status = "命令未执行：目标已失效或命令已禁用"
                    revision += 1
                }
                return CjguiComposableUiDispatchResult(applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        return applyAction(event.node.actionName)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = CommandSurfaceController()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("命令组件入门", 760u32, 460u32))
    if (!opened.didOpen) {
        getStdOut().writeln("CJGUI_COMMAND_SURFACE_OPEN_FAILED reason=${opened.reason}")
        getStdOut().flush()
        application.close()
        return 1
    }
    let businessId = opened.identifier.getOrThrow()
    let business = application.window(businessId).getOrThrow()
    controller.attach(business)
    // The inspector is a second read-only consumer on the same application and
    // window lifecycle. Closing it restores the existing collection settings.
    let inspector = CjguiMacosInspector(application, businessId)
    getStdOut().writeln("CJGUI_COMMAND_SURFACE_READY")
    getStdOut().flush()
    while (application.isOpen()) {
        let _ = application.pumpOneTurn()
        if (controller.takeInspectorRequest()) {
            let _ = inspector.open()
        }
        inspector.synchronizeLifetime()
    }
    inspector.close()
    application.close()
    getStdOut().writeln("CJGUI_COMMAND_SURFACE_CLOSED")
    getStdOut().flush()
    return 0
}
