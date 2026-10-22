package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

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
        // Quiet windows block up to 250ms; input, transport, image completion
        // and close still wake the same poll, and active animation/cursor work
        // is capped to 16ms by the shared owner allowance.
        if (let Some(connection) <- externalConnection) {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithExternal(composableWindow, connection,
                maximumIdleWaitMs: 250u32)
        } else {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(composableWindow,
                maximumIdleWaitMs: 250u32)
        }
        if (!composableWindow.isOpen()) { close(); return false }
        return true
    }

    /// A turn that never sleeps. A group owns the single shared idle wait so a
    /// quiet window cannot delay another window's X11 event behind its budget.
    func pumpOneTurnNoWait(): CjguiComposableUiWindowTurnResult {
        if (!started || closed || !composableWindow.isOpen()) {
            close()
            return CjguiComposableUiWindowTurnResult(0, 0u32, 0, CjguiComposableUiWindowPumpResult(false, false, 0, 0))
        }
        let result = if (let Some(connection) <- externalConnection) {
            CjguiComposableUiWindowTurnScheduler.pumpWithExternal(composableWindow, connection,
                maximumIdleWaitMs: 0u32)
        } else {
            CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(composableWindow, maximumIdleWaitMs: 0u32)
        }
        if (!composableWindow.isOpen()) { close() }
        return result
    }

    func hasActiveScheduling(): Bool {
        return composableWindow.hasActiveOwnerSchedulingRound()
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

/// One owner loop serving several Linux windows. Every host pumps without
/// sleeping, then the group blocks once on the shared owner revision/wake.
/// This keeps per-window input latency independent of how many quiet windows
/// exist, without raising the poll rate: the same X11 fd + self-pipe wait now
/// covers all registered windows in one poll.
@When[os == "Linux"]
public class CjguiLinuxApplicationHostGroup {
    private let hosts = ArrayList<CjguiLinuxApplicationHost>()

    public init() {}

    public func add(host: CjguiLinuxApplicationHost): Bool {
        for (existing in hosts) { if (refEq(existing, host)) { return false } }
        hosts.add(host)
        return true
    }

    public func remove(host: CjguiLinuxApplicationHost): Bool {
        for (index in 0..hosts.size) {
            if (refEq(hosts[index], host)) {
                let _ = hosts.remove(at: index)
                return true
            }
        }
        return false
    }

    public func count(): Int64 { return hosts.size }

    public func isOpen(): Bool {
        for (host in hosts) { if (host.isOpen()) { return true } }
        return false
    }

    /// Returns false once no window in the group is open. Closed hosts are
    /// dropped so a later reopen starts from a clean group.
    public func pumpOneTurn(maximumIdleWaitMs!: UInt32 = 250u32): Bool {
        var anyOpen = false
        var didWork = false
        var activeScheduling = false
        // A host's input turn can open another window and add it to this group.
        // Iterate a snapshot so that legitimate reentrant adds do not mutate the
        // collection being walked; the new host is pumped on the next turn and
        // suppresses this turn's idle wait.
        let snapshot = ArrayList<CjguiLinuxApplicationHost>(hosts)
        for (host in snapshot) {
            if (!host.isOpen()) { continue }
            anyOpen = true
            if (host.hasActiveScheduling()) { activeScheduling = true }
            let result = host.pumpOneTurnNoWait()
            if (result.externalActionCount > 0 || result.windowPumpResult.didApplyHumanAction) {
                didWork = true
            }
            if (host.hasActiveScheduling()) { activeScheduling = true }
        }
        if (hosts.size != snapshot.size) { didWork = true }
        if (!anyOpen && hosts.size == 0) { return false }
        if (!didWork && !activeScheduling) {
            // One wait for the whole group; native polls every registered
            // window's X11 fd and self-pipe in a single call.
            let revision = cjguiSchedulingWorkRevision()
            let _ = cjguiWaitIdleSchedulingWork(revision, cjguiIdleSchedulingDeadline(maximumIdleWaitMs))
        }
        var index: Int64 = 0
        while (index < hosts.size) {
            if (hosts[index].isOpen()) {
                index += 1
            } else {
                let _ = hosts.remove(at: index)
            }
        }
        return hosts.size > 0
    }

    public func closeAll(): Unit {
        for (host in hosts) { host.close() }
        hosts.clear()
    }
}

foreign {
    // Linux owner wake bridge: native self-pipe/X11 poll, no shared scheduler.
    @When[os == "Linux"]
    func cjgui_internal_renderer_owner_work_revision_linux(): UInt64
    @When[os == "Linux"]
    func cjgui_internal_renderer_owner_notify_work_linux(): Unit
    @When[os == "Linux"]
    func cjgui_internal_renderer_owner_wait_idle_work_linux(observedRevision: UInt64, absoluteDeadlineNs: UInt64,
        outIdleWaitNs: CPointer<UInt64>): Int32
    @When[os == "Linux"]
    func cjgui_internal_renderer_owner_wait_work_linux(observedRevision: UInt64, absoluteDeadlineNs: UInt64,
        outIdleWaitNs: CPointer<UInt64>): Int32
}
