package cjgui

import std.collection.*

/// A real composable window whose command target is allocated from an existing
/// scoped component identity. Reordering only changes sibling order; it must
/// not make the declared command point at a former numeric node slot.
private class ScopedCommandController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let scope: CjguiComposableUiIdentityScope
    private var revision: Int64
    private var reversed: Bool
    private var appliedCount: Int64

    init() {
        this.scope = CjguiComposableUiIdentityScope("command-menu-binding")
        this.revision = 1
        this.reversed = false
        this.appliedCount = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "command-menu-binding-root", CjguiComposableUiStyle(padding: 12, gap: 6))
        let save = CjguiComposableUiNode(
            -1,
            "command-menu-binding-save",
            CJGUI_COMPOSABLE_UI_BUTTON,
            "Save",
            "Save",
            "SAVE",
            41,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
            identity: Some(scope.local("save"))
        )
        let note = cjguiComposableText(2, "command-menu-binding-note", "revision ${revision}",
            CjguiComposableUiStyle(fixedHeight: 20))
        if (reversed) {
            root.add(note)
            root.add(save)
        } else {
            root.add(save)
            root.add(note)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "command-menu-binding-save") {
            appliedCount += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
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
                "document.save",
                CjguiComposableUiNodeReference.scoped(scope, "save"),
                "Save",
                CjguiComposableUiShortcut("s"),
                "File",
                0,
                true,
                false
            )
        ])
    }

    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}

    public func reorder(): Unit {
        reversed = !reversed
        revision += 1
    }

    public func applications(): Int64 { return appliedCount }
}

main(args: Array<String>): Int64 {
    let controller = ScopedCommandController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return 10
    }
    if (!window.invokeCommand("document.save") || controller.applications() != 1) {
        window.close()
        return 11
    }
    controller.reorder()
    if (!window.refresh() || !window.invokeCommand("document.save") || controller.applications() != 2) {
        window.close()
        return 12
    }
    window.close()
    println("CJGUI_COMMAND_MENU_SCOPED_BINDING initial=true reordered=true applications=2")
    return 0
}
