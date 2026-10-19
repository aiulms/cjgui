package cjgui

import cjgui_shared_operation_core.*

/// 框架自有的 Linux 应用宿主。渲染器（X11 + Vulkan）拥有窗口创建、事件泵与帧提交；
/// 这个类只拥有已有的 CJGUI 窗口投影、共同操作泵和有序退出。它照 Windows 宿主写，
/// 不新增平台状态机：消费者看到的仍是 `CjguiApplicationHost` 那五个方法。
///
/// 与 macOS/Windows 相同的两点契约：
///  - `start()` 走 `composableWindow.startWithOutcome()`，首帧 PENDING 不是失败；
///  - `close()` 只调用共同层的 close，不在这里抢资源释放顺序。
@When[os == "Linux"]
public class CjguiLinuxApplicationHost {
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

    /// 一轮有界 CJGUI turn：先泵外部工作，再让共享渲染器经会话事件队列消费 X11 事件。
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
