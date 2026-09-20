package cjgui_application_command_menu_native_app

import cjgui.*
import std.collection.*
import std.fs.*

// This seam only reads the normal AppKit projection counter. The command
// declaration and its target stay unchanged while the scene version advances
// because an unrelated label changes.
foreign {
    func cjgui_internal_renderer_test_observe_composable_command_menu_projection(
        outRebuildCount: CPointer<UInt64>, outStandardMenuFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_prepare_composable_command_menu_window(
        title: CString, outReadinessFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_observe_current_composable_command_menu(
        outReadinessFlags: CPointer<UInt32>
    ): Int32
}

private class StableCommandProjectionController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let scope: CjguiComposableUiIdentityScope
    private var revision: Int64

    init() {
        this.scope = CjguiComposableUiIdentityScope("effective-command-menu")
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "effective-command-menu-root",
            CjguiComposableUiStyle(padding: 12, gap: 6))
        root.add(CjguiComposableUiNode(
            -1,
            "effective-command-menu-save",
            CJGUI_COMPOSABLE_UI_BUTTON,
            "Save",
            "Save",
            "SAVE",
            41,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
            identity: Some(scope.local("save"))
        ))
        // This changes across the refresh but is not consumed by the command
        // menu projection. It makes the scene-version delta explicit instead
        // of relying on a duplicate command declaration.
        root.add(cjguiComposableText(2, "effective-command-menu-revision",
            "revision=${revision}", CjguiComposableUiStyle(fixedHeight: 20)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
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

    public func advanceUnrelatedSceneState(): Unit {
        revision += 1
    }
}

private func resultPath(args: Array<String>): String {
    var index: Int64 = 0
    while (index + 1 < args.size) {
        if (args[index] == "--result-path") {
            return args[index + 1]
        }
        index += 1
    }
    return ""
}

private func writeResult(path: String, content: String): Unit {
    if (path.size > 0) {
        File.writeTo(Path(path), content.toArray())
    }
}

main(args: Array<String>): Int64 {
    let result = resultPath(args)
    let controller = StableCommandProjectionController()
    let application = CjguiMacosApplication(maximumWindowCount: 1)
    let opened = application.openWindow(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "CJGUI Effective Command Menu Probe", 640u32, 360u32)
    )
    if (!opened.didOpen) {
        application.close()
        writeResult(result, "verdict=failed\nreason=open_window\n")
        return 10
    }

    let nativeTitle = unsafe { LibC.mallocCString("CJGUI Effective Command Menu Probe") }
    var readiness: UInt32 = 0u32
    var prepareStatus: Int32 = -1
    try (titleResource = nativeTitle.asResource()) {
        prepareStatus = unsafe {
            cjgui_internal_renderer_test_prepare_composable_command_menu_window(titleResource.value, inout readiness)
        }
    }
    var initialTurn = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
    var keyObservation = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
    var keyWaitTurns: Int64 = 0
    while (initialTurn && (keyObservation != 0 || readiness != 255u32) && keyWaitTurns < 8) {
        initialTurn = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
        keyObservation = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
        keyWaitTurns += 1
    }
    var rebuildBefore: UInt64 = 0u64
    var standardBefore: UInt32 = 0u32
    let observeBefore = unsafe {
        cjgui_internal_renderer_test_observe_composable_command_menu_projection(
            inout rebuildBefore, inout standardBefore)
    }

    controller.advanceUnrelatedSceneState()
    let refreshTurn = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
    var rebuildAfter: UInt64 = 0u64
    var standardAfter: UInt32 = 0u32
    let observeAfter = unsafe {
        cjgui_internal_renderer_test_observe_composable_command_menu_projection(
            inout rebuildAfter, inout standardAfter)
    }

    // RED against the current implementation: the accepted command list,
    // effective scope and key identity are unchanged, but a scene-only
    // version advance still rebuilds NSApp.mainMenu.
    let passed = prepareStatus == 0 && initialTurn && keyObservation == 0 && readiness == 255u32 && refreshTurn &&
        observeBefore == 0 && observeAfter == 0 &&
        standardBefore == 3u32 && standardAfter == 3u32 && rebuildAfter == rebuildBefore
    let verdict = if (passed) { "passed" } else { "failed" }
    let receipt = "verdict=${verdict}\n" +
        "prepare_status=${prepareStatus}\nreadiness=${readiness}\nkey_wait_turns=${keyWaitTurns}\n" +
        "initial_turn=${initialTurn}\nrefresh_turn=${refreshTurn}\n" +
        "observe_before=${observeBefore}\nobserve_after=${observeAfter}\n" +
        "rebuild_before=${rebuildBefore}\nrebuild_after=${rebuildAfter}\n" +
        "standard_before=${standardBefore}\nstandard_after=${standardAfter}\n"
    println("CJGUI_COMMAND_MENU_EFFECTIVE_PROJECTION verdict=${verdict} rebuild_before=${rebuildBefore} rebuild_after=${rebuildAfter} scene_only=true")
    application.close()
    writeResult(result, receipt)
    return if (passed) { 0 } else { 11 }
}
