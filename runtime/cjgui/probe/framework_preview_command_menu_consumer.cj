package cjgui_ui_only_starter

import cjgui.*
import std.collection.*
import std.env.*

// This consumer is copied into an exported framework preview.  It deliberately
// uses only the public Cangjie surface: command ids stay in each controller,
// while the target is a scoped identity resolved against the accepted scene.
// The native menu projection never receives either owner name or callback.
private class PreviewCommandOwner <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let ownerName: String
    private let commandId: String
    private let shortcutKey: String
    private let resourceId: Int64
    private let identityScope: CjguiComposableUiIdentityScope
    private var count: Int64 = 0
    private var revision: Int64 = 1
    private var enabled: Bool = true

    init(ownerName: String, commandId: String, shortcutKey: String, resourceId: Int64) {
        this.ownerName = ownerName
        this.commandId = commandId
        this.shortcutKey = shortcutKey
        this.resourceId = resourceId
        this.identityScope = CjguiComposableUiIdentityScope("preview-${ownerName}")
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "preview-command-root-${ownerName}",
            CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(2, "preview-command-title-${ownerName}",
            "命令 owner：${ownerName}", CjguiComposableUiStyle(fixedHeight: 24)))
        // The platform menu command and this visible button resolve to this
        // one stable target and therefore enter the same controller action.
        root.add(CjguiComposableUiNode(-1, "preview-command-button-${ownerName}",
            CJGUI_COMPOSABLE_UI_BUTTON, "执行 ${ownerName}", "执行 ${ownerName}", "PUBLISH", -1,
            CjguiComposableUiStyle(fixedHeight: 32), enabled: enabled,
            identity: Some(identityScope.local("publish"))))
        // A field projection makes the accepted command result observable to
        // an external consumer without creating a second mutable state owner.
        root.add(cjguiComposableText(3, "preview-command-status-${ownerName}",
            "${ownerName} count=${count}", CjguiComposableUiStyle(fixedHeight: 24),
            resourceId: resourceId, fieldId: "invocations", displayValueRole: "applied",
            operationResourceId: resourceId))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "PUBLISH" && enabled) {
            count += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand(
                commandId,
                CjguiComposableUiNodeReference.scoped(identityScope, "publish"),
                "执行 ${ownerName}",
                CjguiComposableUiShortcut(shortcutKey),
                "Preview",
                0,
                enabled,
                count % 2 == 1
            )
        ])
    }

    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}

    public func disable(): Unit {
        enabled = false
        revision += 1
    }
}

private func readInvocationCount(window: CjguiComposableUiWindow, ownerName: String): String {
    let projection = window.windowProjection()
    for (field in projection.fieldValues) {
        if (field.nodeSemanticId == "preview-command-status-${ownerName}" && field.fieldId == "invocations") {
            return field.value.stringValue
        }
    }
    return "missing"
}

private func verifyCommandMenuConsumer(): Bool {
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let ownerA = PreviewCommandOwner("alpha", "preview.alpha.publish", "a", 101)
    let ownerB = PreviewCommandOwner("beta", "preview.beta.publish", "b", 102)
    let openedA = application.openWindow(ownerA,
        configuration: CjguiMacosApplicationWindowConfiguration("Preview 命令 Alpha", 420u32, 240u32))
    let openedB = application.openWindow(ownerB,
        configuration: CjguiMacosApplicationWindowConfiguration("Preview 命令 Beta", 420u32, 240u32))
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        return false
    }
    let identifierA = if (let Some(value) <- openedA.identifier) {
        value
    } else {
        application.close()
        return false
    }
    let identifierB = if (let Some(value) <- openedB.identifier) {
        value
    } else {
        application.close()
        return false
    }
    let windowA = if (let Some(value) <- application.window(identifierA)) {
        value
    } else {
        application.close()
        return false
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) {
        value
    } else {
        application.close()
        return false
    }
    let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
    let menuA = windowA.invokeCommand("preview.alpha.publish")
    let menuB = windowB.invokeCommand("preview.beta.publish")
    let alphaReadback = readInvocationCount(windowA, "alpha")
    let betaReadback = readInvocationCount(windowB, "beta")

    ownerA.disable()
    windowA.requestRefresh()
    let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
    let disabledRejected = !windowA.invokeCommand("preview.alpha.publish")
    let alphaAfterDisabled = readInvocationCount(windowA, "alpha")
    let passed = menuA && menuB && alphaReadback == "alpha count=1" && betaReadback == "beta count=1" &&
        disabledRejected && alphaAfterDisabled == alphaReadback
    getStdOut().writeln(
        "CJGUI_PREVIEW_COMMAND_MENU owners=2 menu_alpha=${menuA} menu_beta=${menuB} " +
        "alpha_readback=${alphaReadback} beta_readback=${betaReadback} disabled_rejected=${disabledRejected} " +
        "alpha_after_disabled=${alphaAfterDisabled} passed=${passed}")
    getStdOut().flush()
    application.close()
    return passed
}

main(args: Array<String>): Int64 {
    if (args.size != 1 || args[0] != "--verify-command-menu") { return 2 }
    return if (verifyCommandMenuConsumer()) { 0 } else { 1 }
}
