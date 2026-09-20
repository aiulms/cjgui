package cjgui

import std.collection.*

/// This seam is compiled only by the native test runner.  Its implementation
/// must locate the real NSMenuItem created from the accepted Cangjie command
/// declaration and invoke that item's AppKit action; it must not inject a
/// synthetic FIFO record directly.
foreign {
    func cjgui_internal_renderer_test_invoke_composable_menu_item(
        session: UInt64, commandId: CString
    ): Int32
}

private class NativeMenuCommandController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let scope: CjguiComposableUiIdentityScope
    private var revision: Int64
    private var saveCount: Int64

    init() {
        this.scope = CjguiComposableUiIdentityScope("native-menu-command")
        this.revision = 1
        this.saveCount = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "native-menu-command-root", CjguiComposableUiStyle(padding: 12))
        root.add(CjguiComposableUiNode(
            -1,
            "native-menu-command-save",
            CJGUI_COMPOSABLE_UI_BUTTON,
            "Save",
            "Save",
            "SAVE_DOCUMENT",
            51,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
            identity: Some(scope.local("save"))
        ))
        root.add(cjguiComposableText(2, "native-menu-command-count", "saves=${saveCount}",
            CjguiComposableUiStyle(fixedHeight: 20)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "native-menu-command-save") {
            saveCount += 1
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

    public func saves(): Int64 { return saveCount }
}

private func invokeNativeMenu(session: UInt64, commandId: String): Int32 {
    let nativeCommandId = unsafe { LibC.mallocCString(commandId) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (commandIdResource = nativeCommandId.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_invoke_composable_menu_item(session, commandIdResource.value)
        }
    }
    return status
}

main(args: Array<String>): Int64 {
    let controller = NativeMenuCommandController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        return 10
    }
    let menuStatus = invokeNativeMenu(window.testSessionToken(), "document.save")
    let turn = window.pump(0u32)
    let passed = menuStatus == CJGUI_INTERNAL_RENDERER_OK && turn.didApplyHumanAction && controller.saves() == 1
    window.close()
    if (!passed) {
        println("CJGUI_COMMAND_MENU_NATIVE_DIAGNOSTIC status=${menuStatus} did_apply=${turn.didApplyHumanAction} saves=${controller.saves()}")
        return 11
    }
    println("CJGUI_COMMAND_MENU_NATIVE selection=true owner_dispatches=1")
    return 0
}
