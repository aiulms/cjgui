package cjgui_application_command_menu_native_app

import cjgui.*
import std.collection.*
import std.fs.*

/// These two symbols exist only in the test-native archive selected by the
/// runner. The probe itself uses the normal Cangjie host, command declaration,
/// FIFO pump and controller action path.
foreign {
    func cjgui_internal_renderer_test_observe_current_composable_command_menu(
        outReadinessFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_prepare_composable_command_menu_window(
        title: CString, outReadinessFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_invoke_current_composable_menu_item(
        commandId: CString
    ): Int32

    func cjgui_internal_renderer_test_dispatch_current_composable_command_shortcut(
        keyCode: UInt16, modifiers: UInt64, characters: CString
    ): Int32

    func cjgui_internal_renderer_test_capture_current_composable_menu_item(commandId: CString): Int32

    func cjgui_internal_renderer_test_invoke_captured_composable_menu_item(): Int32

    func cjgui_internal_renderer_test_observe_composable_command_menu_projection(
        outRebuildCount: CPointer<UInt64>, outStandardMenuFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_observe_current_composable_menu_item(
        commandId: CString, outStateFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_observe_standard_edit_shortcuts(
        outShortcutFlags: CPointer<UInt32>
    ): Int32
}

private class NativeMenuCommandController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let scope: CjguiComposableUiIdentityScope
    private var revision: Int64
    private var saveCount: Int64
    private var layerSaveCount: Int64
    private var saveEnabled: Bool
    private var externalMenuState: Bool
    private var layerOpen: Bool
    private var documentContent: String
    private var documentVersion: Int64
    private var undoCount: Int64
    private var redoCount: Int64
    private var canUndo: Bool
    private var canRedo: Bool
    private var layerUndoCount: Int64
    private var layerUndoEnabled: Bool

    init() {
        this.scope = CjguiComposableUiIdentityScope("normal-native-menu-command")
        this.revision = 1
        this.saveCount = 0
        this.layerSaveCount = 0
        this.saveEnabled = true
        this.externalMenuState = false
        this.layerOpen = false
        this.documentContent = "current"
        this.documentVersion = 2
        this.undoCount = 0
        this.redoCount = 0
        this.canUndo = true
        this.canRedo = false
        this.layerUndoCount = 0
        this.layerUndoEnabled = true
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "normal-native-menu-root", CjguiComposableUiStyle(padding: 12))
        root.add(CjguiComposableUiNode(
            -1,
            "normal-native-menu-save",
            CJGUI_COMPOSABLE_UI_BUTTON,
            "Save",
            "Save",
            "SAVE_DOCUMENT",
            51,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
            identity: Some(scope.local("save"))
        ))
        root.add(cjguiComposableText(2, "normal-native-menu-count", "saves=${saveCount}",
            CjguiComposableUiStyle(fixedHeight: 20)))
        root.add(cjguiComposableText(4, "normal-native-menu-document", "${documentContent}@${documentVersion}",
            CjguiComposableUiStyle(fixedHeight: 20)))
        root.add(CjguiComposableUiNode(
            -1, "normal-native-menu-undo", CJGUI_COMPOSABLE_UI_BUTTON, "Undo", "Undo", "UNDO_DOCUMENT", 53,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1), identity: Some(scope.local("undo"))
        ))
        root.add(CjguiComposableUiNode(
            -1, "normal-native-menu-redo", CJGUI_COMPOSABLE_UI_BUTTON, "Redo", "Redo", "REDO_DOCUMENT", 54,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1), identity: Some(scope.local("redo"))
        ))
        if (layerOpen) {
            let layer = cjguiComposableAnchoredLayer(3, "normal-native-menu-layer", "normal-native-menu-layer", "menu",
                "normal-native-menu-save", 1, CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 60, padding: 6))
            layer.add(CjguiComposableUiNode(
                -1,
                "normal-native-menu-layer-save",
                CJGUI_COMPOSABLE_UI_BUTTON,
                "Save in layer",
                "Save in layer",
                "SAVE_LAYER_DOCUMENT",
                52,
                CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
                identity: Some(scope.local("layer-save"))
            ))
            layer.add(CjguiComposableUiNode(
                -1,
                "normal-native-menu-layer-undo",
                CJGUI_COMPOSABLE_UI_BUTTON,
                "Undo in layer",
                "Undo in layer",
                "UNDO_LAYER_DOCUMENT",
                55,
                CjguiComposableUiStyle(fixedHeight: 28, growX: 1),
                identity: Some(scope.local("layer-undo"))
            ))
            root.add(layer)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "normal-native-menu-save") {
            saveCount += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.semanticId == "normal-native-menu-layer-save") {
            layerSaveCount += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.semanticId == "normal-native-menu-undo" && canUndo) {
            documentContent = "prior"
            documentVersion += 1
            undoCount += 1
            canUndo = false
            canRedo = true
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.semanticId == "normal-native-menu-redo" && canRedo) {
            documentContent = "current"
            documentVersion += 1
            redoCount += 1
            canUndo = true
            canRedo = false
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.semanticId == "normal-native-menu-layer-undo" && layerUndoEnabled) {
            layerUndoCount += 1
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
        let commands = ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand(
                "document.save",
                CjguiComposableUiNodeReference.scoped(scope, "save"),
                "Save",
                CjguiComposableUiShortcut("s"),
                "File",
                0,
                saveEnabled,
                externalMenuState
            ),
            CjguiComposableUiCommand(
                "document.undo",
                CjguiComposableUiNodeReference.scoped(scope, "undo"),
                "Undo",
                CjguiComposableUiShortcut("z"),
                "Edit",
                0,
                canUndo,
                false
            ),
            CjguiComposableUiCommand(
                "document.redo",
                CjguiComposableUiNodeReference.scoped(scope, "redo"),
                "Redo",
                CjguiComposableUiShortcut("z", usesShift: true),
                "Edit",
                0,
                canRedo,
                false
            )
        ])
        if (layerOpen) {
            commands.add(CjguiComposableUiCommand(
                "document.save-layer",
                CjguiComposableUiNodeReference.scoped(scope, "layer-save"),
                "Save in layer",
                CjguiComposableUiShortcut("s"),
                "File",
                0,
                true,
                false,
                focusScopeId: "normal-native-menu-layer"
            ))
            commands.add(CjguiComposableUiCommand(
                "document.undo-layer",
                CjguiComposableUiNodeReference.scoped(scope, "layer-undo"),
                "Undo in layer",
                CjguiComposableUiShortcut("z"),
                "Edit",
                0,
                layerUndoEnabled,
                false,
                focusScopeId: "normal-native-menu-layer"
            ))
        }
        return commands
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}

    public func saves(): Int64 { return saveCount }

    public func setSaveEnabled(value: Bool): Unit {
        if (saveEnabled != value) {
            saveEnabled = value
            revision += 1
        }
    }

    public func applyExternalMenuState(): Unit {
        externalMenuState = !externalMenuState
        revision += 1
    }

    public func openLayer(): Unit {
        if (!layerOpen) {
            layerOpen = true
            revision += 1
        }
    }

    public func layerSaves(): Int64 { return layerSaveCount }

    public func documentSnapshot(): String { return "${documentContent}@${documentVersion}" }
    public func ownerUndoCount(): Int64 { return undoCount }
    public func ownerRedoCount(): Int64 { return redoCount }
    public func layerUndos(): Int64 { return layerUndoCount }

    public func setLayerUndoEnabled(value: Bool): Unit {
        if (layerUndoEnabled != value) {
            layerUndoEnabled = value
            revision += 1
        }
    }
}

private func invokeNativeMenu(commandId: String): Int32 {
    let nativeCommandId = unsafe { LibC.mallocCString(commandId) }
    var status: Int32 = -1
    try (commandIdResource = nativeCommandId.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_invoke_current_composable_menu_item(commandIdResource.value)
        }
    }
    return status
}

private class NativeMenuObservation {
    public let status: Int32
    public let stateFlags: UInt32

    public init(status: Int32, stateFlags: UInt32) {
        this.status = status
        this.stateFlags = stateFlags
    }
}

private func observeNativeMenu(commandId: String): NativeMenuObservation {
    let nativeCommandId = unsafe { LibC.mallocCString(commandId) }
    var status: Int32 = -1
    var stateFlags: UInt32 = 0u32
    try (commandIdResource = nativeCommandId.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_observe_current_composable_menu_item(
                commandIdResource.value, inout stateFlags)
        }
    }
    return NativeMenuObservation(status, stateFlags)
}

private func dispatchNativeShortcut(keyCode: UInt16, modifiers: UInt64, characters: String): Int32 {
    let nativeCharacters = unsafe { LibC.mallocCString(characters) }
    var status: Int32 = -1
    try (charactersResource = nativeCharacters.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_dispatch_current_composable_command_shortcut(
                keyCode, modifiers, charactersResource.value)
        }
    }
    return status
}

private func captureNativeMenu(commandId: String): Int32 {
    let nativeCommandId = unsafe { LibC.mallocCString(commandId) }
    var status: Int32 = -1
    try (commandIdResource = nativeCommandId.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_capture_current_composable_menu_item(commandIdResource.value) }
    }
    return status
}

private func invokeCapturedNativeMenu(): Int32 {
    return unsafe { cjgui_internal_renderer_test_invoke_captured_composable_menu_item() }
}

// LaunchServices does not inherit an invoking shell's stdout. This test-only
// receipt is therefore a one-line result in a runner-owned temporary path;
// it carries no production state and lets the shell distinguish a completed
// normal bundle test from a merely successful `open -W` invocation.
private func nativeProbeResultPath(args: Array<String>): String {
    var index: Int64 = 0
    while (index + 1 < args.size) {
        if (args[index] == "--result-path") {
            return args[index + 1]
        }
        index += 1
    }
    return ""
}

private func writeNativeProbeResult(path: String, content: String): Unit {
    if (path.size > 0) {
        File.writeTo(Path(path), content.toArray())
    }
}

main(args: Array<String>): Int64 {
    let resultPath = nativeProbeResultPath(args)
    let controllerA = NativeMenuCommandController()
    let controllerB = NativeMenuCommandController()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let openedA = application.openWindow(
        controllerA,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Command Menu Probe A", 640u32, 360u32)
    )
    let openedB = application.openWindow(
        controllerB,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Command Menu Probe B", 640u32, 360u32)
    )
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        writeNativeProbeResult(resultPath, "verdict=failed\nreason=open_windows\n")
        return 10
    }
    var readinessA: UInt32 = 0u32
    let nativeTitleA = unsafe { LibC.mallocCString("CJGUI Command Menu Probe A") }
    var preparationA: Int32 = -1
    try (titleResourceA = nativeTitleA.asResource()) {
        preparationA = unsafe {
            cjgui_internal_renderer_test_prepare_composable_command_menu_window(titleResourceA.value, inout readinessA)
        }
    }
    // The focus request above merely asks AppKit to front the named normal
    // window. Let the ordinary application scheduler process its bounded
    // turn, then prove the process-global key window without passing a
    // session token to the menu selector.
    let readinessTurnA = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
    let observedA = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readinessA) }
    // Capture A's real NSMenuItem while A is key. The later invocation occurs
    // only after B becomes key, so its dispatcher must not retain A's owner.
    let captureA = if (preparationA == 0 && readinessTurnA && observedA == 0 && readinessA == 255u32) {
        captureNativeMenu("document.save")
    } else {
        -1i32
    }
    let menuStatusA = if (captureA == 0) {
        invokeNativeMenu("document.save")
    } else {
        captureA
    }
    let menuTurnA = application.pumpOneTurn().isOpen
    var rebuildCountBeforeBackgroundUpdate: UInt64 = 0u64
    var standardMenuFlagsBeforeBackgroundUpdate: UInt32 = 0u32
    let projectionBeforeBackgroundUpdate = unsafe {
        cjgui_internal_renderer_test_observe_composable_command_menu_projection(inout rebuildCountBeforeBackgroundUpdate,
            inout standardMenuFlagsBeforeBackgroundUpdate)
    }
    // This mutation belongs to B's owner while A remains the actual key
    // window. It must update B's next accepted menu state without replacing
    // the process-global menu object which still projects A.
    controllerB.applyExternalMenuState()
    let backgroundProjectionTurn = application.pumpOneTurn().isOpen
    var rebuildCountAfterBackgroundUpdate: UInt64 = 0u64
    var standardMenuFlagsAfterBackgroundUpdate: UInt32 = 0u32
    let projectionAfterBackgroundUpdate = unsafe {
        cjgui_internal_renderer_test_observe_composable_command_menu_projection(inout rebuildCountAfterBackgroundUpdate,
            inout standardMenuFlagsAfterBackgroundUpdate)
    }
    var readinessB: UInt32 = 0u32
    let nativeTitleB = unsafe { LibC.mallocCString("CJGUI Command Menu Probe B") }
    var preparationB: Int32 = -1
    try (titleResourceB = nativeTitleB.asResource()) {
        preparationB = unsafe {
            cjgui_internal_renderer_test_prepare_composable_command_menu_window(titleResourceB.value, inout readinessB)
        }
    }
    let readinessTurnB = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
    let observedB = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readinessB) }
    var externalStateFlagsB: UInt32 = 0u32
    let externalStateStatusB = if (preparationB == 0 && readinessTurnB && observedB == 0 && readinessB == 255u32) {
        let nativeCommandId = unsafe { LibC.mallocCString("document.save") }
        var status: Int32 = -1
        try (commandIdResource = nativeCommandId.asResource()) {
            status = unsafe {
                cjgui_internal_renderer_test_observe_current_composable_menu_item(commandIdResource.value,
                    inout externalStateFlagsB)
            }
        }
        status
    } else {
        -1i32
    }
    let shortcutStatusB = if (menuStatusA == 0 && menuTurnA && controllerA.saves() == 1 &&
        projectionBeforeBackgroundUpdate == 0 && standardMenuFlagsBeforeBackgroundUpdate == 3u32 &&
        backgroundProjectionTurn && projectionAfterBackgroundUpdate == 0 &&
        rebuildCountAfterBackgroundUpdate == rebuildCountBeforeBackgroundUpdate &&
        standardMenuFlagsAfterBackgroundUpdate == 3u32 && externalStateStatusB == 0 && externalStateFlagsB == 7u32) {
        // macOS virtual-keycode 1 is S; the command modifier is the actual
        // AppKit menu key equivalent registered by the accepted declaration.
        dispatchNativeShortcut(1u16, 1048576u64, "s")
    } else {
        -1i32
    }
    let shortcutTurnB = application.pumpOneTurn().isOpen
    let staleMenuStatusB = if (shortcutStatusB == 0 && shortcutTurnB && controllerB.saves() == 1) {
        invokeCapturedNativeMenu()
    } else {
        -1i32
    }
    let staleMenuTurnB = application.pumpOneTurn().isOpen
    let closedA = if (let Some(identifierA) <- openedA.identifier) {
        application.requestClose(identifierA)
    } else {
        false
    }
    let afterCloseMenuStatusB = if (closedA && staleMenuStatusB == 0 && staleMenuTurnB && controllerB.saves() == 2) {
        invokeNativeMenu("document.save")
    } else {
        -1i32
    }
    let afterCloseTurnB = application.pumpOneTurn().isOpen
    // A declared document owner must take Cmd-Z/Cmd-Shift-Z before the
    // standard responder chain.  The test reads the resulting document state
    // and owner version rather than treating a native event receipt as proof.
    var standardEditFlagsDocument: UInt32 = 0u32
    let standardEditStatusDocument = if (closedA && afterCloseMenuStatusB == 0 && afterCloseTurnB &&
        controllerB.saves() == 3) {
        unsafe { cjgui_internal_renderer_test_observe_standard_edit_shortcuts(inout standardEditFlagsDocument) }
    } else {
        -1i32
    }
    let undoShortcutStatusB = if (standardEditStatusDocument == 0) {
        dispatchNativeShortcut(6u16, 1048576u64, "z")
    } else {
        -1i32
    }
    let undoShortcutTurnB = application.pumpOneTurn().isOpen
    // The first turn drains the owner command; the next one publishes that
    // owner's changed availability before AppKit chooses Cmd-Shift-Z. Without
    // this normal scheduler boundary, a disabled stale Redo item could leave
    // the preceding Undo key equivalent installed.
    let undoRefreshTurnB = application.pumpOneTurn().isOpen
    let redoShortcutStatusB = if (undoShortcutStatusB == 0 && undoShortcutTurnB && undoRefreshTurnB &&
        controllerB.documentSnapshot() == "prior@3" && controllerB.ownerUndoCount() == 1) {
        dispatchNativeShortcut(6u16, 1179648u64, "Z")
    } else {
        -1i32
    }
    let redoShortcutTurnB = application.pumpOneTurn().isOpen
    let redoRefreshTurnB = application.pumpOneTurn().isOpen
    controllerB.openLayer()
    let layerProjectionTurnB = application.pumpOneTurn().isOpen
    let layerSaveObservationB = if (layerProjectionTurnB) {
        observeNativeMenu("document.save-layer")
    } else {
        NativeMenuObservation(-1i32, 0u32)
    }
    let layerSaveStateStatusB = layerSaveObservationB.status
    let layerSaveStateFlagsB = layerSaveObservationB.stateFlags
    // Both accepted declarations use Cmd-S. When the layer owns focus,
    // AppKit must expose only its item as the key equivalent; the base item
    // cannot intercept the native menu traversal before Cangjie validates it.
    let layerShortcutStatusB = if (closedA && afterCloseMenuStatusB == 0 && afterCloseTurnB &&
        controllerB.saves() == 3 && layerProjectionTurnB && layerSaveStateStatusB == 0 && layerSaveStateFlagsB == 5u32) {
        dispatchNativeShortcut(1u16, 1048576u64, "s")
    } else {
        -1i32
    }
    let layerShortcutTurnB = application.pumpOneTurn().isOpen
    var standardEditFlagsLayer: UInt32 = 0u32
    let standardEditStatusLayer = if (layerShortcutStatusB == 0 && layerShortcutTurnB &&
        controllerB.layerSaves() == 1 && controllerB.documentSnapshot() == "current@4" && redoRefreshTurnB &&
        controllerB.ownerRedoCount() == 1) {
        unsafe { cjgui_internal_renderer_test_observe_standard_edit_shortcuts(inout standardEditFlagsLayer) }
    } else {
        -1i32
    }
    let layerUndoShortcutStatusB = if (standardEditStatusLayer == 0) {
        dispatchNativeShortcut(6u16, 1048576u64, "z")
    } else {
        -1i32
    }
    let layerUndoShortcutTurnB = application.pumpOneTurn().isOpen
    controllerB.setLayerUndoEnabled(false)
    let disabledLayerProjectionTurnB = application.pumpOneTurn().isOpen
    var standardEditFlagsDisabledLayer: UInt32 = 0u32
    let standardEditStatusDisabledLayer = if (disabledLayerProjectionTurnB) {
        unsafe { cjgui_internal_renderer_test_observe_standard_edit_shortcuts(inout standardEditFlagsDisabledLayer) }
    } else {
        -1i32
    }
    let disabledLayerShortcutStatusB = if (standardEditStatusDisabledLayer == 0) {
        dispatchNativeShortcut(6u16, 1048576u64, "z")
    } else {
        -1i32
    }
    let disabledLayerShortcutTurnB = application.pumpOneTurn().isOpen
    controllerB.setSaveEnabled(false)
    let disabledProjectionTurnB = application.pumpOneTurn().isOpen
    let disabledMenuStatusB = invokeNativeMenu("document.save")
    let disabledMenuTurnB = application.pumpOneTurn().isOpen
    let passed = preparationA == 0 && readinessTurnA && observedA == 0 && readinessA == 255u32 && captureA == 0 &&
        menuStatusA == 0 && menuTurnA && preparationB == 0 && readinessTurnB && observedB == 0 &&
        readinessB == 255u32 && shortcutStatusB == 0 && shortcutTurnB &&
        staleMenuStatusB == 0 && staleMenuTurnB && closedA && afterCloseMenuStatusB == 0 && afterCloseTurnB &&
        standardEditStatusDocument == 0 && standardEditFlagsDocument == 0u32 && undoShortcutStatusB == 0 &&
        undoShortcutTurnB && undoRefreshTurnB && redoShortcutStatusB != -1 && redoShortcutTurnB && redoRefreshTurnB &&
        controllerB.documentSnapshot() == "current@4" &&
        controllerB.ownerUndoCount() == 1 && controllerB.ownerRedoCount() == 1 &&
        layerSaveStateStatusB == 0 && layerSaveStateFlagsB == 5u32 && layerShortcutStatusB == 0 && layerShortcutTurnB &&
        controllerB.layerSaves() == 1 &&
        standardEditStatusLayer == 0 && standardEditFlagsLayer == 0u32 && layerUndoShortcutStatusB == 0 &&
        layerUndoShortcutTurnB && controllerB.layerUndos() == 1 && disabledLayerProjectionTurnB &&
        standardEditStatusDisabledLayer == 0 && standardEditFlagsDisabledLayer == 0u32 &&
        // A disabled declared command may enter the ordinary bounded input
        // path, but it must not fall through to the standard responder or
        // produce a second owner mutation.
        disabledLayerShortcutStatusB == 0 && disabledLayerShortcutTurnB && controllerB.layerUndos() == 1 &&
        disabledProjectionTurnB && disabledMenuStatusB != 0 && disabledMenuTurnB &&
        controllerA.saves() == 1 && controllerB.saves() == 3
    if (passed) {
        println("CJGUI_COMMAND_MENU_NATIVE readiness_a=${readinessA} readiness_b=${readinessB} menu_a=true external_checked_b=true shortcut_b=true background_commit_rebuilds=0 standard_menus=app,text owner_undo_redo=true standard_edit_fallback_suppressed=true scope_shortcut_routes_layer=true stale_callback_routes_b=true close_a_preserves_b=true disabled_rejected=true owner_dispatches=1,3 layer_dispatches=1")
    } else {
        println("CJGUI_COMMAND_MENU_NATIVE_DIAGNOSTIC prepare_a=${preparationA} readiness_turn_a=${readinessTurnA} observed_a=${observedA} readiness_a=${readinessA} capture_a=${captureA} menu_a=${menuStatusA} menu_turn_a=${menuTurnA} projection_before=${projectionBeforeBackgroundUpdate} rebuild_before=${rebuildCountBeforeBackgroundUpdate} standard_before=${standardMenuFlagsBeforeBackgroundUpdate} background_turn=${backgroundProjectionTurn} projection_after=${projectionAfterBackgroundUpdate} rebuild_after=${rebuildCountAfterBackgroundUpdate} standard_after=${standardMenuFlagsAfterBackgroundUpdate} prepare_b=${preparationB} readiness_turn_b=${readinessTurnB} observed_b=${observedB} readiness_b=${readinessB} external_state_b=${externalStateStatusB},${externalStateFlagsB} shortcut_b=${shortcutStatusB} shortcut_turn_b=${shortcutTurnB} stale_b=${staleMenuStatusB} stale_turn_b=${staleMenuTurnB} close_a=${closedA} after_close_b=${afterCloseMenuStatusB} after_close_turn_b=${afterCloseTurnB} edit_document=${standardEditStatusDocument},${standardEditFlagsDocument} undo=${undoShortcutStatusB},${undoShortcutTurnB},${controllerB.documentSnapshot()} redo=${redoShortcutStatusB},${redoShortcutTurnB},${controllerB.documentSnapshot()} layer_projection_b=${layerProjectionTurnB} layer_save_state=${layerSaveStateStatusB},${layerSaveStateFlagsB} layer_shortcut_b=${layerShortcutStatusB} layer_shortcut_turn_b=${layerShortcutTurnB} edit_layer=${standardEditStatusLayer},${standardEditFlagsLayer} layer_undo=${layerUndoShortcutStatusB},${layerUndoShortcutTurnB},${controllerB.layerUndos()} edit_disabled_layer=${standardEditStatusDisabledLayer},${standardEditFlagsDisabledLayer} disabled_layer_shortcut=${disabledLayerShortcutStatusB},${disabledLayerShortcutTurnB} disabled_projection_b=${disabledProjectionTurnB} disabled_menu_b=${disabledMenuStatusB} disabled_turn_b=${disabledMenuTurnB} saves=${controllerA.saves()},${controllerB.saves()} layer_saves=${controllerB.layerSaves()}")
    }
    let verdict = if (passed) { "passed" } else { "failed" }
    let receipt = "verdict=${verdict}\n" +
        "readiness_a=${readinessA}\nreadiness_b=${readinessB}\n" +
        "menu_status_a=${menuStatusA}\nshortcut_status_b=${shortcutStatusB}\n" +
        "background_rebuild_before=${rebuildCountBeforeBackgroundUpdate}\n" +
        "background_rebuild_after=${rebuildCountAfterBackgroundUpdate}\n" +
        "standard_menu_flags_before=${standardMenuFlagsBeforeBackgroundUpdate}\n" +
        "standard_menu_flags_after=${standardMenuFlagsAfterBackgroundUpdate}\n" +
        "external_state_status_b=${externalStateStatusB}\nexternal_state_flags_b=${externalStateFlagsB}\n" +
        "standard_edit_document_status=${standardEditStatusDocument}\nstandard_edit_document_flags=${standardEditFlagsDocument}\n" +
        "undo_shortcut_status_b=${undoShortcutStatusB}\nundo_refresh_turn_b=${undoRefreshTurnB}\n" +
        "redo_shortcut_status_b=${redoShortcutStatusB}\nredo_refresh_turn_b=${redoRefreshTurnB}\n" +
        "document_b=${controllerB.documentSnapshot()}\nundo_count_b=${controllerB.ownerUndoCount()}\nredo_count_b=${controllerB.ownerRedoCount()}\n" +
        "layer_shortcut_status_b=${layerShortcutStatusB}\n" +
        "layer_save_state_status_b=${layerSaveStateStatusB}\nlayer_save_state_flags_b=${layerSaveStateFlagsB}\n" +
        "standard_edit_layer_status=${standardEditStatusLayer}\nstandard_edit_layer_flags=${standardEditFlagsLayer}\n" +
        "layer_undo_shortcut_status_b=${layerUndoShortcutStatusB}\nlayer_undo_count_b=${controllerB.layerUndos()}\n" +
        "standard_edit_disabled_layer_status=${standardEditStatusDisabledLayer}\nstandard_edit_disabled_layer_flags=${standardEditFlagsDisabledLayer}\n" +
        "disabled_layer_shortcut_status_b=${disabledLayerShortcutStatusB}\n" +
        "saves_a=${controllerA.saves()}\nsaves_b=${controllerB.saves()}\nlayer_saves_b=${controllerB.layerSaves()}\n"
    application.close()
    writeNativeProbeResult(resultPath, receipt)
    return if (passed) { 0 } else { 11 }
}
