package cjgui

import cjgui_shared_operation_core.*

/// Framework-owned Win32 application host. The renderer owns HWND creation,
/// message dispatch and D3D presentation; this class owns the existing CJGUI
/// window projection, shared-operation pump and orderly endpoint shutdown.
@When[os == "Windows"]
public class CjguiWindowsApplicationHost {
    private let composableWindow: CjguiComposableUiWindow
    private let configuration: CjguiMacosApplicationWindowConfiguration
    private var externalConnection: ?CjguiSharedOperationExternalConnection
    private var started: Bool = false
    private var closed: Bool = false

    public init(controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()) {
        this.configuration = configuration
        this.composableWindow = CjguiComposableUiWindow(controller, configuration: configuration)
        this.externalConnection = None
    }

    public func window(): CjguiComposableUiWindow {
        return composableWindow
    }

    public func attachExternalConnection(connection: CjguiSharedOperationExternalConnection): Bool {
        if (started || closed) { return false }
        if (let Some(_) <- externalConnection) { return false }
        externalConnection = Some(connection)
        return true
    }

    public func start(): Bool {
        if (closed || !configuration.isValid()) { close(); return false }
        if (started) { return true }
        var failed = false
        match (composableWindow.startWithOutcome()) {
            case StartFailed => failed = true
            case _ => failed = false
        }
        if (failed) { close(); return false }
        if (let Some(connection) <- externalConnection) {
            if (!connection.start()) { close(); return false }
        }
        started = true
        return true
    }

    /// A bounded CJGUI turn pumps external work and then lets the shared
    /// renderer consume Win32 messages through the session event queue.
    public func pumpOneTurn(): Bool {
        if (!started || closed || !composableWindow.isOpen()) { close(); return false }
        if (let Some(connection) <- externalConnection) {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithExternal(composableWindow, connection)
        } else {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(composableWindow)
        }
        if (!composableWindow.isOpen()) { close(); return false }
        return true
    }

    public func isOpen(): Bool {
        return started && !closed && composableWindow.isOpen()
    }

    public static func stopApplicationLoop(): Unit {
        internalRendererRequestApplicationStop()
    }

    public func close(): Unit {
        if (closed) { return }
        if (let Some(connection) <- externalConnection) { connection.close() }
        composableWindow.close()
        if (!composableWindow.isOpen()) { closed = true }
    }
}
