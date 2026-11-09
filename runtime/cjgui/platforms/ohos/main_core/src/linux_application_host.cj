package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.time.*

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
    private var closeRequestedValue: Bool = false
    // Test-only lifecycle seam: a real native close can be retained by an
    // unsettled ticket/ACK. This models exactly that state without a native
    // session so the group's retention/release contract is testable.
    private var inertForTest: Bool = false
    private var inertOpenForTest: Bool = false
    private var inertHoldCloseForTest: Bool = false
    private var inertStartFailsForTest: Bool = false
    // Observation-only wrapper for CJGUI_OWNER_TURN_COST. It carries the same
    // outer turn identity on Linux as macOS so the existing CJGUI_REFRESH_COST
    // rows have a turn to attribute; it attaches no budget and changes no wait.
    private var observingOrdinaryCost: Bool = false

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
        if (inertForTest) {
            if (inertStartFailsForTest) { close(); return false }
            started = true
            return true
        }
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
        beginOrdinaryCostObservation()
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
        finishOrdinaryCostObservation()
        if (!composableWindow.isOpen()) { close(); return false }
        return true
    }

    /// A turn that never sleeps. A group owns the single shared idle wait so a
    /// quiet window cannot delay another window's X11 event behind its budget.
    func pumpOneTurnNoWait(): CjguiComposableUiWindowTurnResult {
        if (inertForTest) {
            if (!inertOpenForTest) { closed = true }
            return CjguiComposableUiWindowTurnResult(0, 0u32, 0, CjguiComposableUiWindowPumpResult(false, false, 0, 0))
        }
        if (!started || closed || !composableWindow.isOpen()) {
            close()
            return CjguiComposableUiWindowTurnResult(0, 0u32, 0, CjguiComposableUiWindowPumpResult(false, false, 0, 0))
        }
        beginOrdinaryCostObservation()
        let result = if (let Some(connection) <- externalConnection) {
            CjguiComposableUiWindowTurnScheduler.pumpWithExternal(composableWindow, connection,
                maximumIdleWaitMs: 0u32)
        } else {
            CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(composableWindow, maximumIdleWaitMs: 0u32)
        }
        finishOrdinaryCostObservation()
        if (!composableWindow.isOpen()) { close() }
        return result
    }

    // The observation carries the existing outer turn identity; it never
    // admits work or alters a wait. A previous turn interrupted by a propagated
    // callback failure is closed before a new identity is taken.
    private func beginOrdinaryCostObservation(): Unit {
        if (observingOrdinaryCost) {
            cjguiOrdinaryOwnerCostObservation.finish()
            observingOrdinaryCost = false
        }
        if (!cjguiOrdinaryOwnerCostObservation.enabled) { return }
        if (composableWindow.hasActiveOwnerSchedulingRound()) { return }
        observingOrdinaryCost = cjguiOrdinaryOwnerCostObservation.begin()
    }

    private func finishOrdinaryCostObservation(): Unit {
        if (!observingOrdinaryCost) { return }
        cjguiOrdinaryOwnerCostObservation.finish()
        observingOrdinaryCost = false
    }

    func hasActiveScheduling(): Bool {
        return composableWindow.hasActiveOwnerSchedulingRound()
    }

    func hasStarted(): Bool {
        return started
    }

    /// 真实窗口是否仍然存在。`isOpen()` 还要求 start 成功，因此启动失败的
    /// 窗口不能用它判断保留责任——共同关闭待结算时窗口仍可能存活。
    func windowIsOpen(): Bool {
        if (inertForTest) { return inertOpenForTest }
        return composableWindow.isOpen()
    }

    func startInertForTest(): Unit {
        inertForTest = true
        inertOpenForTest = true
        started = true
    }

    /// Models a start failure whose common close is retained (the native window
    /// still exists until its settlement completes). The group must keep the
    /// controller/slot and pump until the window really goes away.
    func startInertFailureForTest(): Unit {
        inertForTest = true
        inertOpenForTest = true
        inertHoldCloseForTest = true
        inertStartFailsForTest = true
        started = false
    }

    func holdInertCloseForTest(): Unit {
        inertHoldCloseForTest = true
    }

    func releaseInertCloseForTest(): Unit {
        inertHoldCloseForTest = false
        inertOpenForTest = false
    }

    func isInertForTest(): Bool {
        return inertForTest
    }

    func closeRequested(): Bool {
        return closeRequestedValue
    }

    public func isOpen(): Bool {
        return started && !closed && composableWindow.isOpen()
    }

    public static func stopApplicationLoop(): Unit {
        internalRendererRequestApplicationStop()
    }

    public func close(): Unit {
        if (closed) { return }
        closeRequestedValue = true
        if (inertForTest) {
            if (!inertHoldCloseForTest) {
                inertOpenForTest = false
                closed = true
            }
            return
        }
        if (let Some(connection) <- externalConnection) { connection.close() }
        composableWindow.close()
        if (!composableWindow.isOpen()) { closed = true }
    }
}

/// 生命周期请求的公开结果。请求只在所属 Linux 宿主的回合边界执行：
/// 派发期返回 Pending，边界后成功/失败才落定；调用方可按同一个对象观察。
@When[os == "Linux"]
public enum CjguiLinuxWindowRequestStatus {
    | Pending
    | Applied
    | Failed
    | Superseded
}

@When[os == "Linux"]
private func cjguiLinuxWindowRequestStatusName(status: CjguiLinuxWindowRequestStatus): String {
    return match (status) {
        case CjguiLinuxWindowRequestStatus.Pending => "pending"
        case CjguiLinuxWindowRequestStatus.Applied => "applied"
        case CjguiLinuxWindowRequestStatus.Failed => "failed"
        case CjguiLinuxWindowRequestStatus.Superseded => "superseded"
    }
}

@When[os == "Linux"]
public class CjguiLinuxWindowRequest {
    public let kind: String
    public let key: String
    public let windowId: Int64
    private var statusValue: CjguiLinuxWindowRequestStatus
    private var messageValue: String

    init(kind: String, key: String, windowId: Int64,
        status: CjguiLinuxWindowRequestStatus, message: String) {
        this.kind = kind
        this.key = key
        this.windowId = windowId
        this.statusValue = status
        this.messageValue = message
    }

    public func status(): CjguiLinuxWindowRequestStatus {
        return statusValue
    }

    public func message(): String {
        return messageValue
    }

    public func isPending(): Bool {
        return match (statusValue) {
            case CjguiLinuxWindowRequestStatus.Pending => true
            case _ => false
        }
    }

    public func isSettled(): Bool {
        return !isPending()
    }

    /// Every request settles once at the owner boundary. The trace is the
    /// once-only receipt callers and tests can reconcile against.
    func settle(status: CjguiLinuxWindowRequestStatus, message: String): Unit {
        let pending = match (statusValue) {
            case CjguiLinuxWindowRequestStatus.Pending => true
            case _ => false
        }
        if (!pending) { return }
        statusValue = status
        messageValue = message
        getStdOut().writeln("CJGUI_LINUX_WINDOW_REQUEST kind=${kind} key=${key} window=${windowId} " +
            "status=${cjguiLinuxWindowRequestStatusName(status)} message=${message}")
        getStdOut().flush()
    }
}

@When[os == "Linux"]
class CjguiLinuxWindowSlot {
    let id: Int64
    let key: String
    let host: CjguiLinuxApplicationHost

    init(id: Int64, key: String, host: CjguiLinuxApplicationHost) {
        this.id = id
        this.key = key
        this.host = host
    }
}

@When[os == "Linux"]
class CjguiLinuxPendingOpen {
    let request: CjguiLinuxWindowRequest
    let factory: (Int64) -> CjguiLinuxApplicationHost
    // True only while this boundary is running the factory/start. A same-key
    // request issued from inside that factory is a new request that must be
    // judged at the next boundary, not deduplicated onto the in-flight one.
    var executing: Bool = false

    init(request: CjguiLinuxWindowRequest, factory: (Int64) -> CjguiLinuxApplicationHost) {
        this.request = request
        this.factory = factory
    }
}

@When[os == "Linux"]
class CjguiLinuxClosingTicket {
    let request: CjguiLinuxWindowRequest

    init(request: CjguiLinuxWindowRequest) {
        this.request = request
    }
}

/// One owner loop serving several Linux windows. Every host pumps without
/// sleeping, then the group blocks once on the shared owner revision/wake.
/// This keeps per-window input latency independent of how many quiet windows
/// exist, without raising the poll rate: the same X11 fd + self-pipe wait now
/// covers all registered windows in one poll.
///
/// 生命周期（打开/关闭/重开/整体退出）也归这里：窗口派发期间只登记请求，
/// 由本宿主在同一回合的边界执行。这样应用不再复制 openPending/closePending/
/// finishTurn；创建或销毁另一个 native 会话不会发生在某个窗口的派发栈内。
@When[os == "Linux"]
public class CjguiLinuxApplicationHostGroup {
    private let slots = ArrayList<CjguiLinuxWindowSlot>()
    private let pendingOpens = ArrayList<CjguiLinuxPendingOpen>()
    private let closingTickets = ArrayList<CjguiLinuxClosingTicket>()
    private var nextWindowId: Int64 = 1
    private var pumping: Bool = false
    // A direct request (startup or a factory) applies at once; requests issued
    // while that apply is running belong to the next boundary, not a nested
    // one. Native creation/teardown must never run inside another apply.
    private var applyingLifecycle: Bool = false
    private var exitRequest: ?CjguiLinuxWindowRequest = None

    public init() {}

    // Legacy single-window registration. Named/reopenable windows use
    // requestOpen, which assigns an identity and can report duplicate/stale
    // requests instead of silently acting on whatever host is at the front.
    public func add(host: CjguiLinuxApplicationHost): Bool {
        if (exitRequested()) { return false }
        for (slot in slots) { if (refEq(slot.host, host)) { return false } }
        let windowId = nextWindowId
        nextWindowId += 1
        slots.add(CjguiLinuxWindowSlot(windowId, "", host))
        return true
    }

    public func remove(host: CjguiLinuxApplicationHost): Bool {
        var index: Int64 = 0
        while (index < slots.size) {
            if (refEq(slots[index].host, host)) {
                let removed = slots[index]
                // Removing an open or still-settling window would drop the last
                // owner before native discard. Refuse instead of faking close.
                if (removed.host.windowIsOpen() || hasPendingClose(removed.id)) { return false }
                let _ = slots.remove(at: index)
                settleTicketForRemoved(removed.id)
                return true
            }
            index += 1
        }
        return false
    }

    private func settleTicketForRemoved(windowId: Int64): Unit {
        var index: Int64 = 0
        while (index < closingTickets.size) {
            if (closingTickets[index].request.windowId == windowId) {
                closingTickets[index].request.settle(CjguiLinuxWindowRequestStatus.Applied, "removed_after_close")
                let _ = closingTickets.remove(at: index)
            } else {
                index += 1
            }
        }
    }

    private func slotForId(windowId: Int64): ?CjguiLinuxWindowSlot {
        if (windowId <= 0) { return None }
        for (slot in slots) { if (slot.id == windowId) { return slot } }
        return None
    }

    private func slotForKey(key: String): ?CjguiLinuxWindowSlot {
        if (key.size == 0) { return None }
        for (slot in slots) { if (slot.key == key) { return slot } }
        return None
    }

    /// A close has been requested but the host's common close has not run yet.
    /// An open for the same key must queue behind it, not report the old
    /// generation as still occupying the key.
    private func hasPendingClose(windowId: Int64): Bool {
        for (ticket in closingTickets) {
            if (ticket.request.windowId == windowId && ticket.request.isPending()) { return true }
        }
        return false
    }

    private func removeSlotById(windowId: Int64): Bool {
        var index: Int64 = 0
        while (index < slots.size) {
            if (slots[index].id == windowId) {
                let _ = slots.remove(at: index)
                return true
            }
            index += 1
        }
        return false
    }

    private func exitRequested(): Bool {
        return exitRequest.isSome()
    }

    private func hasPendingLifecycleWork(): Bool {
        return pendingOpens.size > 0 || closingTickets.size > 0 || exitRequested()
    }

    /// 派发期登记打开；不在派发时立即在边界执行。工厂只负责构造并返回
    /// 尚未 start 的 host；本方法负责 start、登记和失败保留。
    public func requestOpen(key: String,
        factory: (Int64) -> CjguiLinuxApplicationHost): CjguiLinuxWindowRequest {
        if (exitRequested()) {
            return CjguiLinuxWindowRequest("open", key, 0,
                CjguiLinuxWindowRequestStatus.Failed, "exit_requested")
        }
        if (key.size > 0) {
            if (let Some(slot) <- slotForKey(key)) {
                if (slot.host.windowIsOpen()) {
                    if (!slot.host.closeRequested() && !hasPendingClose(slot.id)) {
                        return CjguiLinuxWindowRequest("open", key, slot.id,
                            CjguiLinuxWindowRequestStatus.Failed, "window_already_open")
                    }
                    // Previous generation is closing (close already ran, or a
                    // close ticket is queued for this boundary). Queue the
                    // reopen; its new identity is created only after the slot
                    // retires.
                } else {
                    let _ = removeSlotById(slot.id)
                }
            }
            for (pending in pendingOpens) {
                if (pending.request.key == key && pending.request.isPending() && !pending.executing) {
                    return pending.request
                }
            }
        }
        let windowId = nextWindowId
        nextWindowId += 1
        let request = CjguiLinuxWindowRequest("open", key, windowId,
            CjguiLinuxWindowRequestStatus.Pending, "queued")
        pendingOpens.add(CjguiLinuxPendingOpen(request, factory))
        if (!pumping && !applyingLifecycle) { applyLifecycleRequests() }
        return request
    }

    /// 按当前 key 关闭。打开请求仍在队列时，关闭取消该请求而不是先创建再销毁；
    /// 已存在窗口则用它的稳定 id 关闭。
    public func requestCloseKey(key: String): CjguiLinuxWindowRequest {
        var index: Int64 = 0
        while (index < pendingOpens.size) {
            if (pendingOpens[index].request.key == key && pendingOpens[index].request.isPending()) {
                let request = pendingOpens[index].request
                let _ = pendingOpens.remove(at: index)
                request.settle(CjguiLinuxWindowRequestStatus.Superseded, "cancelled_by_close")
                return CjguiLinuxWindowRequest("close", key, request.windowId,
                    CjguiLinuxWindowRequestStatus.Applied, "cancelled_pending_open")
            }
            index += 1
        }
        if (let Some(slot) <- slotForKey(key)) {
            return requestClose(slot.id)
        }
        return CjguiLinuxWindowRequest("close", key, 0,
            CjguiLinuxWindowRequestStatus.Failed, "window_not_open")
    }

    /// 按身份关闭；旧窗口请求不会作用到后来重开的新身份。
    public func requestClose(windowId: Int64): CjguiLinuxWindowRequest {
        match (slotForId(windowId)) {
            case None =>
                return CjguiLinuxWindowRequest("close", "", windowId,
                    CjguiLinuxWindowRequestStatus.Failed, "stale_window")
            case Some(slot) =>
                for (ticket in closingTickets) {
                    if (ticket.request.windowId == windowId && ticket.request.isPending()) {
                        return ticket.request
                    }
                }
                if (!slot.host.windowIsOpen()) {
                    let _ = removeSlotById(windowId)
                    return CjguiLinuxWindowRequest("close", slot.key, windowId,
                        CjguiLinuxWindowRequestStatus.Applied, "already_closed")
                }
                let request = CjguiLinuxWindowRequest("close", slot.key, windowId,
                    CjguiLinuxWindowRequestStatus.Pending, "close_queued")
                closingTickets.add(CjguiLinuxClosingTicket(request))
                if (!pumping && !applyingLifecycle) { applyLifecycleRequests() }
                return request
        }
    }

    /// 业务退出决定。已有窗口在后续边界关闭并泵到真实结算；返回值在
    /// 所有窗口都退出后才是 Applied。已请求过则返回同一个对象。
    public func requestExit(): CjguiLinuxWindowRequest {
        match (exitRequest) {
            case Some(existing) => return existing
            case None => ()
        }
        let request = CjguiLinuxWindowRequest("exit", "", 0,
            CjguiLinuxWindowRequestStatus.Pending, "exit_queued")
        exitRequest = Some(request)
        if (!pumping && !applyingLifecycle) { applyLifecycleRequests() }
        return request
    }

    public func window(key: String): ?CjguiLinuxApplicationHost {
        match (slotForKey(key)) {
            case Some(slot) => return Some(slot.host)
            case None => return None
        }
    }

    public func windowById(windowId: Int64): ?CjguiLinuxApplicationHost {
        match (slotForId(windowId)) {
            case Some(slot) => return Some(slot.host)
            case None => return None
        }
    }

    public func windowId(key: String): Int64 {
        match (slotForKey(key)) {
            case Some(slot) => return slot.id
            case None => return 0
        }
    }

    public func isWindowOpen(key: String): Bool {
        match (slotForKey(key)) {
            case Some(slot) => return slot.host.windowIsOpen()
            case None => return false
        }
    }

    public func isWindowOpen(windowId: Int64): Bool {
        match (slotForId(windowId)) {
            case Some(slot) => return slot.host.windowIsOpen()
            case None => return false
        }
    }

    public func count(): Int64 { return slots.size }

    public func liveCount(): Int64 {
        var count: Int64 = 0
        for (slot in slots) { if (slot.host.isOpen()) { count += 1 } }
        return count
    }

    public func isOpen(): Bool {
        for (slot in slots) { if (slot.host.isOpen()) { return true } }
        for (pending in pendingOpens) { if (pending.request.isPending()) { return true } }
        return false
    }

    private func applyLifecycleRequests(): Unit {
        if (applyingLifecycle) { return }
        applyingLifecycle = true
        // Requests stay in the live queue until they settle. Nothing is moved
        // into a local copy, so a throw cannot strand unprocessed requests, and
        // terminal requests are never re-executed.
        // 1) Exit supersedes queued opens and requests close on every live
        //    generation. Existing close tickets continue below.
        match (exitRequest) {
            case Some(request) =>
                if (request.isPending()) {
                    var pendingIndex: Int64 = 0
                    while (pendingIndex < pendingOpens.size) {
                        let pending = pendingOpens[pendingIndex]
                        pending.request.settle(CjguiLinuxWindowRequestStatus.Superseded, "exit_requested")
                        let _ = pendingOpens.remove(at: pendingIndex)
                    }
                    let snapshot = ArrayList<CjguiLinuxWindowSlot>(slots)
                    for (slot in snapshot) {
                        if (slot.host.windowIsOpen()) {
                            var tracked = false
                            for (ticket in closingTickets) {
                                if (ticket.request.windowId == slot.id) { tracked = true }
                            }
                            if (!tracked) {
                                closingTickets.add(CjguiLinuxClosingTicket(
                                    CjguiLinuxWindowRequest("close", slot.key, slot.id,
                                        CjguiLinuxWindowRequestStatus.Pending, "exit_close_queued")))
                            }
                        }
                    }
                }
            case None => ()
        }

        // 2) Close requests execute only here, never inside another window's
        //    dispatch. A retained common close stays tracked until isOpen is
        //    false; the host identity and controller are kept meanwhile.
        var closeIndex: Int64 = 0
        while (closeIndex < closingTickets.size) {
            let ticket = closingTickets[closeIndex]
            let windowId = ticket.request.windowId
            match (slotForId(windowId)) {
                case None =>
                    ticket.request.settle(CjguiLinuxWindowRequestStatus.Applied, "closed")
                    let _ = closingTickets.remove(at: closeIndex)
                case Some(slot) =>
                    if (!slot.host.windowIsOpen()) {
                        let _ = removeSlotById(windowId)
                        ticket.request.settle(CjguiLinuxWindowRequestStatus.Applied, "closed")
                        let _ = closingTickets.remove(at: closeIndex)
                    } else {
                        slot.host.close()
                        if (!slot.host.windowIsOpen()) {
                            let _ = removeSlotById(windowId)
                            ticket.request.settle(CjguiLinuxWindowRequestStatus.Applied, "closed")
                            let _ = closingTickets.remove(at: closeIndex)
                        } else {
                            closeIndex += 1
                        }
                    }
            }
        }

        // 3) Opens run after closes, and a key whose previous generation is
        //    still settling remains queued for a later boundary. This loop is
        //    deliberately outside any exception region: host.start() presents
        //    through the native renderer, and a Cangjie try block spanning that
        //    call crashes deterministically in this environment (r24/r27).
        //    Only the factory call itself is guarded (openNow); a request whose
        //    factory throws settles Failed without losing its siblings.
        let opens = ArrayList<CjguiLinuxPendingOpen>(pendingOpens)
        for (pending in opens) {
            if (!pendingQueueContains(pending)) { continue }
            if (!pending.request.isPending()) {
                removePendingOpen(pending)
                continue
            }
            if (exitRequested()) {
                pending.request.settle(CjguiLinuxWindowRequestStatus.Superseded, "exit_requested")
                removePendingOpen(pending)
                continue
            }
            var blocked = false
            if (pending.request.key.size > 0) {
                if (let Some(slot) <- slotForKey(pending.request.key)) {
                    if (slot.host.windowIsOpen()) {
                        if (slot.host.closeRequested() || hasPendingClose(slot.id)) {
                            blocked = true
                        } else {
                            // A terminal request must never reach the factory.
                            pending.request.settle(CjguiLinuxWindowRequestStatus.Failed, "window_already_open")
                            removePendingOpen(pending)
                            continue
                        }
                    } else {
                        let _ = removeSlotById(slot.id)
                    }
                }
            }
            if (blocked) { continue }
            pending.executing = true
            openNow(pending)
            pending.executing = false
            if (!pending.request.isPending()) { removePendingOpen(pending) }
        }
        settleExitIfDone()
        applyingLifecycle = false
    }

    private func pendingQueueContains(pending: CjguiLinuxPendingOpen): Bool {
        for (queued in pendingOpens) { if (refEq(queued, pending)) { return true } }
        return false
    }

    private func removePendingOpen(pending: CjguiLinuxPendingOpen): Unit {
        var index: Int64 = 0
        while (index < pendingOpens.size) {
            if (refEq(pendingOpens[index], pending)) {
                let _ = pendingOpens.remove(at: index)
                return
            }
            index += 1
        }
    }

    private func openNow(pending: CjguiLinuxPendingOpen): Unit {
        if (!pending.request.isPending()) { return }
        var created: ?CjguiLinuxApplicationHost = None
        try {
            created = Some(pending.factory(pending.request.windowId))
        } catch (error: Exception) {
            pending.request.settle(CjguiLinuxWindowRequestStatus.Failed, "factory_exception")
            return
        }
        match (created) {
            case None => pending.request.settle(CjguiLinuxWindowRequestStatus.Failed, "factory_returned_none")
            case Some(host) =>
                // The factory may have closed this key while it was running; a
                // terminal request must not start a window.
                if (!pending.request.isPending()) { return }
                // Register before start so a failed/retained close still has a
                // real owner and cannot lose its controller or font lease.
                slots.add(CjguiLinuxWindowSlot(pending.request.windowId, pending.request.key, host))
                // start() reports failure through its Bool; it must not throw.
                // Deliberately unguarded: see the loop comment above.
                if (!host.start()) {
                    host.close()
                    if (!host.windowIsOpen()) {
                        let _ = removeSlotById(pending.request.windowId)
                    }
                    pending.request.settle(CjguiLinuxWindowRequestStatus.Failed, "start_failed")
                    return
                }
                pending.request.settle(CjguiLinuxWindowRequestStatus.Applied, "window_open")
        }
    }

    private func settleExitIfDone(): Unit {
        match (exitRequest) {
            case Some(request) =>
                if (request.isPending() && slots.size == 0 && pendingOpens.size == 0 &&
                    closingTickets.size == 0) {
                    request.settle(CjguiLinuxWindowRequestStatus.Applied, "application_closed")
                }
            case None => ()
        }
    }

    private func reapClosedSlots(): Unit {
        var index: Int64 = 0
        while (index < slots.size) {
            if (!slots[index].host.windowIsOpen()) {
                let _ = slots.remove(at: index)
            } else {
                index += 1
            }
        }
    }

    /// Returns false once no window in the group is open. Closed hosts are
    /// dropped so a later reopen starts from a clean group.
    public func pumpOneTurn(maximumIdleWaitMs!: UInt32 = 250u32): Bool {
        if (pumping || applyingLifecycle) {
            // A request issued from a dispatch or a factory is already queued;
            // the active boundary will apply it. Never clear the active guard.
            return slots.size > 0 || pendingOpens.size > 0 || closingTickets.size > 0
        }
        pumping = true
        try {
            var anyOpen = false
            var didWork = false
            var activeScheduling = false
            // A host's input turn can request another window. Iterate a
            // snapshot so lifecycle changes do not mutate the collection
            // being walked; requests are applied after every host has pumped.
            let snapshot = ArrayList<CjguiLinuxWindowSlot>(slots)
            for (slot in snapshot) {
                let host = slot.host
                if (!host.windowIsOpen()) { continue }
                anyOpen = true
                if (!host.hasStarted()) {
                    // Start failed before the window settled its close; no
                    // normal pump is allowed, but its native session still
                    // needs a turn to finish the retained close.
                    host.close()
                    didWork = true
                    continue
                }
                if (!host.isInertForTest() && host.hasActiveScheduling()) { activeScheduling = true }
                let result = host.pumpOneTurnNoWait()
                if (result.externalActionCount > 0 || result.windowPumpResult.didApplyHumanAction) {
                    didWork = true
                }
                if (!host.isInertForTest() && host.hasActiveScheduling()) { activeScheduling = true }
            }
            let slotsBeforeLifecycle = slots.size
            applyLifecycleRequests()
            if (slots.size != slotsBeforeLifecycle) { didWork = true }
            if (!didWork && !activeScheduling && !hasPendingLifecycleWork()) {
                // One wait for the whole group; native polls every registered
                // window's X11 fd and self-pipe in a single call.
                let revision = cjguiSchedulingWorkRevision()
                let _ = cjguiWaitIdleSchedulingWork(revision, cjguiIdleSchedulingDeadline(maximumIdleWaitMs))
            } else if (hasPendingLifecycleWork() && !didWork && !activeScheduling) {
                // Settlement/ACK work needs a retried boundary, not a long
                // sleep; this is active close work, not an idle spin.
                let wait = if (maximumIdleWaitMs > 16u32) { 16u32 } else { maximumIdleWaitMs }
                if (wait > 0u32) {
                    let revision = cjguiSchedulingWorkRevision()
                    let _ = cjguiWaitIdleSchedulingWork(revision, cjguiIdleSchedulingDeadline(wait))
                }
            }
            reapClosedSlots()
            settleExitIfDone()
            return slots.size > 0 || pendingOpens.size > 0 || closingTickets.size > 0
        } finally {
            pumping = false
            // Same-boundary cleanup only. A nested pump invoked from a factory
            // never reaches here (it returns at the guard above), so this can
            // not clear a guard that is still active. If the boundary itself
            // unwound, the next boundary starts clean; requests that were not
            // settled remain in pendingOpens.
            applyingLifecycle = false
        }
    }

    /// Normal shutdown: request exit first, then keep the single owner loop
    /// pumping until every retained close really settles. Returns false if the
    /// bound expires or the caller invoked it from inside a dispatch; callers
    /// must not clear controllers/regions or release fonts on false.
    public func closeAll(maximumWaitMs!: Int64 = 5000): Bool {
        let request = requestExit()
        if (pumping || applyingLifecycle) { return false }
        let started = MonoTime.now()
        while (slots.size > 0 || pendingOpens.size > 0 || closingTickets.size > 0) {
            if ((MonoTime.now() - started).toMilliseconds() >= maximumWaitMs) {
                return false
            }
            let _ = pumpOneTurn(maximumIdleWaitMs: 50u32)
            if (request.isSettled() && slots.size == 0) { break }
        }
        return request.isSettled() && slots.size == 0 && pendingOpens.size == 0 &&
            closingTickets.size == 0
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
