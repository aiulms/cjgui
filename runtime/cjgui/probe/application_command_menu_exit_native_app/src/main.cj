package cjgui_application_command_menu_exit_native_app

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.fs.*

// The normal bundle invokes AppKit's actual standard Quit responder. The only
// native seams hide/observe the process application and invoke that responder;
// no seam calls the Cangjie exit decision or selects a renderer session.
foreign {
    func cjgui_internal_renderer_test_observe_current_composable_command_menu(
        outReadinessFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_invoke_standard_quit_menu_item(): Int32

    func cjgui_internal_renderer_test_set_application_hidden(
        hidden: UInt8, outNoKeyWindow: CPointer<UInt32>
    ): Int32
}

private class ExitNativeCommandController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let scope: CjguiComposableUiIdentityScope
    private var revision: Int64
    private var content: String
    private var contentVersion: Int64

    init(scopeName: String) {
        this.scope = CjguiComposableUiIdentityScope(scopeName)
        this.revision = 1
        this.content = "unchanged"
        this.contentVersion = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "exit-native-root", CjguiComposableUiStyle(padding: 12, gap: 6))
        root.add(CjguiComposableUiNode(
            -1, "exit-native-save", CJGUI_COMPOSABLE_UI_BUTTON, "Persist", "Persist", "PERSIST", 61,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1), identity: Some(scope.local("persist"))
        ))
        root.add(cjguiComposableText(2, "exit-native-content", "${content} @${contentVersion}",
            CjguiComposableUiStyle(fixedHeight: 20)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.semanticId == "exit-native-save") {
            content = "persisted"
            contentVersion += 1
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
                "exit-probe.persist", CjguiComposableUiNodeReference.scoped(scope, "persist"), "Persist",
                CjguiComposableUiShortcut("s"), "File", 0, true, false
            )
        ])
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}

    public func snapshot(): String { return "${content}@${contentVersion}" }
}

private class ExitDecision <: CjguiMacosApplicationExitDecisionProvider {
    private var allowsExit: Bool
    private var requests: Int64

    init() {
        this.allowsExit = false
        this.requests = 0
    }

    public func requestApplicationExit(): Bool {
        requests += 1
        return allowsExit
    }

    public func requestCount(): Int64 { return requests }
    public func allow(): Unit { allowsExit = true }
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "application-exit-native-probe",
        "cjgui-application-exit-native-probe-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
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
    let decision = ExitDecision()
    let controllerA = ExitNativeCommandController("exit-native-a")
    let controllerB = ExitNativeCommandController("exit-native-b")
    let application = CjguiMacosApplication(maximumWindowCount: 2, exitDecisionProvider: Some(decision))
    let openedA = application.openWindow(controllerA,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Exit Native Probe A", 520u32, 240u32))
    let openedB = application.openWindow(controllerB,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Exit Native Probe B", 520u32, 240u32))
    let connectionDomain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(1, "exit connection", false)
    ]))
    let connection = CjguiSharedOperationExternalConnection(connectionDomain, authorization())
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        writeResult(result, "verdict=failed\nreason=startup\n")
        return 10
    }

    let connectionStarted = application.attachExternalConnection(connection)
    let connectionLive = if (let Some(_) <- connection.connectionInfo()) { true } else { false }

    // An application can remain fully live while every normal window is
    // hidden and therefore no CJGUI window is key. Standard Quit must still
    // reach the application-owned decision provider; it must not select one
    // of these windows or let AppKit terminate the process immediately.
    var noKeyWindow: UInt32 = 0u32
    let hideStatus = unsafe { cjgui_internal_renderer_test_set_application_hidden(1u8, inout noKeyWindow) }
    var hiddenReadiness: UInt32 = 0u32
    var hiddenObserveStatus: Int32 = 0i32
    // A hide can resign the AppKit key window after the first scheduler turn.
    // Let the existing bounded application scheduler settle that transition;
    // do not spin a native loop or choose a window as lifecycle owner.
    var hideTurn = true
    var hideTurns: Int64 = 0
    while (hideTurns < 8 && application.isOpen() && noKeyWindow == 0u32) {
        hideTurn = hideTurn && application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
        hiddenReadiness = 0u32
        hiddenObserveStatus = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout hiddenReadiness) }
        noKeyWindow = if (hiddenObserveStatus != 0 && (hiddenReadiness & 128u32) == 0u32) { 1u32 } else { 0u32 }
        hideTurns += 1
    }
    let rejectQuitA = if (hideStatus == 0 && hideTurn && noKeyWindow == 1u32 && connectionStarted && connectionLive) {
        unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }
    } else { -1i32 }
    let rejectQuitB = if (rejectQuitA == 0) {
        unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }
    } else { -1i32 }
    let rejectionTurn = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen
    let saveAfterReject = if (rejectionTurn && decision.requestCount() == 1 && application.windowIdentifiers().size == 2 &&
        (let Some(_) <- connection.connectionInfo())) {
        if (let Some(identifier) <- openedB.identifier) {
            if (let Some(window) <- application.window(identifier)) {
                if (window.invokeCommand("exit-probe.persist")) { 0i32 } else { 99i32 }
            } else { 99i32 }
        } else { 99i32 }
    } else { -1i32 }
    let saveTurn = application.pumpOneTurn(turnBudgetMs: 16u32).isOpen

    decision.allow()
    let allowQuit = if (saveAfterReject == 0 && saveTurn && controllerB.snapshot() == "persisted@2" &&
        decision.requestCount() == 1) {
        unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }
    } else { -1i32 }
    let allowTurn = application.pumpOneTurn(turnBudgetMs: 16u32)

    let passed = hideStatus == 0 && hideTurn && hiddenObserveStatus != 0 && noKeyWindow == 1u32 &&
        rejectQuitA == 0 && rejectQuitB == 0 && rejectionTurn && decision.requestCount() == 2 &&
        saveAfterReject == 0 && saveTurn && controllerB.snapshot() == "persisted@2" &&
        allowQuit == 0 && !allowTurn.isOpen && !application.isOpen() && application.windowIdentifiers().size == 0
    let verdict = if (passed) { "passed" } else { "failed" }
    let receipt = "verdict=${verdict}\n" +
        "reject_quit_a=${rejectQuitA}\nreject_quit_b=${rejectQuitB}\n" +
        "hide_status=${hideStatus}\nhide_turn=${hideTurn}\nhidden_observe_status=${hiddenObserveStatus}\n" +
        "hidden_readiness=${hiddenReadiness}\nhide_turns=${hideTurns}\nno_key_window=${noKeyWindow}\n" +
        "connection_started=${connectionStarted}\nconnection_live=${connectionLive}\n" +
        "rejection_turn=${rejectionTurn}\nsave_after_reject=${saveAfterReject}\nsave_turn=${saveTurn}\n" +
        "allow_quit=${allowQuit}\n" +
        "exit_requests=${decision.requestCount()}\napplication_open=${application.isOpen()}\n" +
        "windows_after_allow=${application.windowIdentifiers().size}\ncontent_b=${controllerB.snapshot()}\n"
    println("CJGUI_APPLICATION_EXIT_NATIVE verdict=${verdict} duplicate_coalesced=${decision.requestCount() == 2} content_b=${controllerB.snapshot()} closed=${!application.isOpen()}")
    if (application.isOpen()) {
        application.close()
    }
    writeResult(result, receipt)
    return if (passed) { 0 } else { 11 }
}
