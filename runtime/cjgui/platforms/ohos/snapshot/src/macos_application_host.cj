package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.overflow.*
import std.random.*
import std.sync.*
import std.time.*

/// Experimental macOS window declaration owned by the framework. It contains
/// copied scalar values only; no AppKit object or native handle crosses this
/// public boundary.
public class CjguiMacosApplicationWindowConfiguration {
    public let title: String
    public let width: UInt32
    public let height: UInt32
    /// Opt in to explicit edit deltas for composable text nodes. When true each
    /// human edit is also delivered as
    /// `CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED` (replaced UTF-16 range +
    /// inserted string), so a range-text consumer never diffs the whole value.
    /// Both events are delivered; `CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED` keeps
    /// its existing meaning and traffic for every other consumer.
    public let rangeTextEditDeltaDelivery: Bool

    public init(title: String, width: UInt32, height: UInt32, rangeTextEditDeltaDelivery!: Bool = false) {
        this.title = title
        this.width = width
        this.height = height
        this.rangeTextEditDeltaDelivery = rangeTextEditDeltaDelivery
    }

    public static func standard(): CjguiMacosApplicationWindowConfiguration {
        return CjguiMacosApplicationWindowConfiguration("CJGUI", 980u32, 620u32)
    }

    /// Bounds prevent an accidental public configuration from reaching the
    /// native renderer with a zero or implausibly large drawable request.
    public func isValid(): Bool {
        return title.size > 0 && width > 0u32 && height > 0u32 && width <= 8192u32 && height <= 8192u32
    }
}

/// A public application-scoped identity. It carries the application owner and
/// a monotonically assigned generation, never a renderer session token or an
/// AppKit object. Closing and reopening a logical view therefore cannot let a
/// stale caller address a later native session or a window in another app.
public class CjguiMacosApplicationWindowIdentifier {
    public let applicationIdentifier: String
    public let value: String
    public let generation: Int64

    public init(applicationIdentifier: String, value: String, generation: Int64) {
        this.applicationIdentifier = applicationIdentifier
        this.value = value
        this.generation = generation
    }

    public func isValid(): Bool {
        return applicationIdentifier.size > 0 && value.size > 0 && generation > 0
    }

    public func belongsTo(applicationIdentifier: String): Bool {
        return isValid() && this.applicationIdentifier == applicationIdentifier
    }
}

/// A process-local allocator provides a distinct owner for every application
/// instance. The nonce prevents process reuse after restart; the locked
/// generation prevents same-process collisions. Exhaustion fails closed
/// rather than restarting any identity sequence.
private class CjguiMacosApplicationIdentityAllocator {
    private static let allocationLock = Mutex()
    private static let processNonce = Random().nextUInt64()
    private static var nextApplicationGeneration: Int64 = 1

    public static func allocate(): String {
        return synchronized(CjguiMacosApplicationIdentityAllocator.allocationLock) {
            let generation = CjguiMacosApplicationIdentityAllocator.nextApplicationGeneration
            if (generation <= 0) {
                return ""
            }
            let following = generation.saturatingAdd(1)
            CjguiMacosApplicationIdentityAllocator.nextApplicationGeneration = if (following <= generation) {
                0
            } else {
                following
            }
            return "cjgui_application_${CjguiMacosApplicationIdentityAllocator.processNonce}_${generation}"
        }
    }
}

/// AppKit owns one process-global event loop even when this framework exposes
/// several independent `CjguiMacosApplication` owners. A closing owner must
/// therefore release its reference, not stop the shared loop while a sibling
/// application still has a native projection. The registry contains scalar
/// application identities only; it never stores a renderer session or an
/// AppKit object.
private class CjguiMacosApplicationLoopReferenceRegistry {
    private static let referenceLock = Mutex()
    private static var activeApplicationIdentifiers = ArrayList<String>()

    public static func retain(applicationIdentifier: String): Bool {
        if (applicationIdentifier.size == 0) {
            return false
        }
        return synchronized(CjguiMacosApplicationLoopReferenceRegistry.referenceLock) {
            for (activeIdentifier in CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers) {
                if (activeIdentifier == applicationIdentifier) {
                    return true
                }
            }
            CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers.add(applicationIdentifier)
            return true
        }
    }

    /// Returns true only for the owner that released the final framework
    /// application reference and may therefore request `NSApp stop`.
    public static func release(applicationIdentifier: String): Bool {
        return synchronized(CjguiMacosApplicationLoopReferenceRegistry.referenceLock) {
            let remaining = ArrayList<String>()
            for (activeIdentifier in CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers) {
                if (activeIdentifier != applicationIdentifier) {
                    remaining.add(activeIdentifier)
                }
            }
            CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers = remaining
            return remaining.size == 0
        }
    }

    /// A process-level standard Quit without a key window has no focus
    /// routing information. Only the sole live application lifecycle owner
    /// may consume that intent; more than one owner deliberately remains
    /// fail-closed rather than borrowing a sibling window.
    public static func isExclusiveOwner(applicationIdentifier: String): Bool {
        if (applicationIdentifier.size == 0) {
            return false
        }
        return synchronized(CjguiMacosApplicationLoopReferenceRegistry.referenceLock) {
            return CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers.size == 1 &&
                CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers[0] == applicationIdentifier
        }
    }
}

/// Value-only result for a requested window creation. A failed creation never
/// returns a native handle and leaves existing application windows unchanged.
public class CjguiMacosApplicationWindowOpenResult {
    public let didOpen: Bool
    public let identifier: ?CjguiMacosApplicationWindowIdentifier
    public let reason: String

    public init(didOpen: Bool, identifier: ?CjguiMacosApplicationWindowIdentifier, reason: String) {
        this.didOpen = didOpen
        this.identifier = identifier
        this.reason = reason
    }
}

/// Per-turn facts for an application-owned scheduler. One turn has at most
/// one non-zero AppKit event wait regardless of the number of live windows.
public class CjguiMacosApplicationTurnResult {
    public let isOpen: Bool
    public let windowCount: Int64
    public let externalActionCount: Int64
    public let eventWaitBudgetMs: UInt32
    public let elapsedBeforeEventWaitMs: Int64
    public let waitedWindow: ?CjguiMacosApplicationWindowIdentifier

    public init(
        isOpen: Bool,
        windowCount: Int64,
        externalActionCount: Int64,
        eventWaitBudgetMs: UInt32,
        elapsedBeforeEventWaitMs: Int64,
        waitedWindow: ?CjguiMacosApplicationWindowIdentifier
    ) {
        this.isOpen = isOpen
        this.windowCount = windowCount
        this.externalActionCount = externalActionCount
        this.eventWaitBudgetMs = eventWaitBudgetMs
        this.elapsedBeforeEventWaitMs = elapsedBeforeEventWaitMs
        this.waitedWindow = waitedWindow
    }
}

private class CjguiMacosApplicationWindowEntry {
    let identifier: CjguiMacosApplicationWindowIdentifier
    let composableWindow: CjguiComposableUiWindow

    init(identifier: CjguiMacosApplicationWindowIdentifier, composableWindow: CjguiComposableUiWindow) {
        this.identifier = identifier
        this.composableWindow = composableWindow
    }
}

/// The application owns final process exit, while its consumer owns the
/// business decision to allow it. A `false` result must leave every live
/// window and the shared endpoint usable.
public interface CjguiMacosApplicationExitDecisionProvider {
    func requestApplicationExit(): Bool
}

/// Application-owned same-process multi-window lifecycle. It is deliberately
/// separate from the legacy one-window Host: the application owns its single
/// external connection and one bounded wait, while the process-global AppKit
/// loop stops only after its final live application reference releases; each
/// entry owns only its projection/session and close decision.
/// Test-only seam at the EXACT boundary a same-turn acceptance is about: after
/// a window's external-driven refresh has been applied and before the same turn
/// pumps that window. A probe registers this observer to inject its ordinary
/// input at that point, so "my input and the external change advanced in the same
/// turn" can be measured without guessing an injection delay. It adds no
/// production behavior and is never invoked unless a test registers it.
public interface CjguiMacosApplicationPostRefreshObserver {
    func postRefreshBeforePump(window: CjguiComposableUiWindow): Unit
}

public class CjguiMacosApplication <: CjguiSharedOperationWindowProjectionTargetProvider & CjguiSharedOperationWindowProgressTargetProvider {
    private let maximumWindowCount: Int64
    private let applicationIdentity: String
    private var windows: ArrayList<CjguiMacosApplicationWindowEntry>
    private var externalConnection: ?CjguiSharedOperationExternalConnection
    private let exitDecisionProvider: ?CjguiMacosApplicationExitDecisionProvider
    private var closed: Bool
    private var nextGeneration: Int64
    private var nextWaitIndex: Int64
    private var nextPreparationIndex: Int64
    private var ordinaryDeferredRounds: Int64
    // Test-only: the FIRST window retirement and the application close reason, so
    // a bounded probe can name the actual first state change instead of only
    // printing that everything is closed at the end.
    private var testRetirementTraceValue: String
    private var testCloseTraceValue: String
    private var testExitIntentTraceValue: String
    private var isPumpingTurn: Bool
    private var deferredCloseIdentifiers: ArrayList<CjguiMacosApplicationWindowIdentifier>
    private var deferredAuthorizedClose: Bool
    private var ownsProcessLoopReference: Bool
    private var ownsApplicationExitLifecycleReference: Bool
    private var testPostRefreshObserver: ?CjguiMacosApplicationPostRefreshObserver

    public init(
        maximumWindowCount!: Int64 = 4,
        exitDecisionProvider!: ?CjguiMacosApplicationExitDecisionProvider = None
    ) {
        this.maximumWindowCount = if (maximumWindowCount > 0 && maximumWindowCount <= 4) {
            maximumWindowCount
        } else {
            4
        }
        this.applicationIdentity = CjguiMacosApplicationIdentityAllocator.allocate()
        this.windows = ArrayList<CjguiMacosApplicationWindowEntry>()
        this.externalConnection = None
        this.exitDecisionProvider = exitDecisionProvider
        this.closed = false
        this.nextGeneration = 1
        this.nextWaitIndex = 0
        this.nextPreparationIndex = 0
        this.ordinaryDeferredRounds = 0
        this.testRetirementTraceValue = ""
        this.testCloseTraceValue = ""
        this.testExitIntentTraceValue = ""
        this.isPumpingTurn = false
        this.deferredCloseIdentifiers = ArrayList<CjguiMacosApplicationWindowIdentifier>()
        this.deferredAuthorizedClose = false
        this.ownsProcessLoopReference = false
        this.ownsApplicationExitLifecycleReference = false
        this.testPostRefreshObserver = None
    }

    /// Test-only: registers the post-refresh/pre-pump observer (see
    /// CjguiMacosApplicationPostRefreshObserver). Passing None removes it.
    public func setTestPostRefreshObserver(observer: ?CjguiMacosApplicationPostRefreshObserver): Unit {
        testPostRefreshObserver = observer
    }

    /// Opens one independent projection/session. The controller and its
    /// domain remain caller-owned; this method never duplicates the domain.
    public func openWindow(
        controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()
    ): CjguiMacosApplicationWindowOpenResult {
        if (closed) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "application_closed")
        }
        // Starting an AppKit session from a controller callback would mutate
        // the collection currently being scheduled. The request is rejected
        // explicitly; callers may retry on the next turn after observing the
        // stable application state.
        if (isPumpingTurn) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "application_turn_active")
        }
        if (applicationIdentity.size == 0) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "application_identity_exhausted")
        }
        if (!configuration.isValid()) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "invalid_configuration")
        }
        if (windows.size >= maximumWindowCount) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "window_limit")
        }
        // Do not create a native session that cannot receive a permanent
        // public identity. Exhaustion fails before touching AppKit, rather
        // than briefly opening and retiring an unaddressable window.
        if (nextGeneration <= 0) {
            return CjguiMacosApplicationWindowOpenResult(false, None, "window_generation_exhausted")
        }
        let window = CjguiComposableUiWindow(controller, configuration: configuration)
        // A1：受理（首帧 PENDING）不是失败——窗口已打开且留在泵送集合里，
        // 由后续 turn 的前置结算门推进到 Ready/失败。只有 StartFailed 才拒绝。
        var windowStartFailed = false
        match (window.startWithOutcome()) {
            case StartFailed => windowStartFailed = true
            case _ => windowStartFailed = false
        }
        if (windowStartFailed) {
            // `start` owns its own partial-session cleanup. Nothing has been
            // inserted into the application collection yet, so live windows
            // and any application connection remain untouched.
            return CjguiMacosApplicationWindowOpenResult(false, None, "native_start_failed")
        }
        let generation = nextGeneration
        let following = generation.saturatingAdd(1)
        nextGeneration = if (following <= generation) { 0 } else { following }
        let identifier = CjguiMacosApplicationWindowIdentifier(
            applicationIdentity, "${applicationIdentity}_window_${generation}", generation
        )
        if (!ownsProcessLoopReference) {
            if (!CjguiMacosApplicationLoopReferenceRegistry.retain(applicationIdentity)) {
                window.close()
                return CjguiMacosApplicationWindowOpenResult(false, None, "application_loop_reference_failed")
            }
            ownsProcessLoopReference = true
            internalRendererRetainApplicationExitLifecycleOwner()
            ownsApplicationExitLifecycleReference = true
        }
        windows.add(CjguiMacosApplicationWindowEntry(identifier, window))
        return CjguiMacosApplicationWindowOpenResult(true, Some(identifier), "opened")
    }

    /// Public owner identity used only to bind scalar window identifiers. It
    /// is not a native session token and has no authority on its own.
    public func applicationIdentifier(): String {
        return applicationIdentity
    }

    /// Attach at most one process-level connection. Its owner/authorization is
    /// supplied by the application; closing a single window never closes it.
    public func attachExternalConnection(connection: CjguiSharedOperationExternalConnection): Bool {
        if (closed) {
            return false
        }
        if (let Some(_) <- externalConnection) {
            return false
        }
        if (!connection.start()) {
            return false
        }
        externalConnection = Some(connection)
        return true
    }

    public func windowIdentifiers(): ArrayList<CjguiMacosApplicationWindowIdentifier> {
        let identifiers = ArrayList<CjguiMacosApplicationWindowIdentifier>()
        for (entry in windows) {
            if (entry.composableWindow.isOpen()) {
                identifiers.add(entry.identifier)
            }
        }
        return identifiers
    }

    /// Returns a projection surface only for a live generation. The returned
    /// Cangjie object exposes no native session token; application bookkeeping
    /// still retires it if it closes through its ordinary controller path.
    public func window(identifier: CjguiMacosApplicationWindowIdentifier): ?CjguiComposableUiWindow {
        if (!identifier.isValid()) {
            return None
        }
        if (let Some(entry) <- entryFor(identifier)) {
            if (entry.composableWindow.isOpen()) {
                return Some(entry.composableWindow)
            }
        }
        return None
    }

    /// Enumerate only currently live opaque target identities. A caller must
    /// later ask for one exact target; this method never selects a sibling.
    public func windowProjectionTargets(): ArrayList<String> {
        let targets = ArrayList<String>()
        for (entry in windows) {
            if (entry.composableWindow.isOpen()) {
                targets.add(entry.identifier.value)
            }
        }
        return targets
    }

    /// Returns the named live projection or `None` for a closed, stale, or
    /// foreign target. In particular it never falls back to the first live
    /// window after the requested one closes.
    public func windowProjectionForTarget(target: String): ?CjguiSharedOperationWindowProjection {
        for (entry in windows) {
            if (entry.identifier.value == target && entry.identifier.belongsTo(applicationIdentity) &&
                entry.composableWindow.isOpen()) {
                return Some(entry.composableWindow.windowProjection())
            }
        }
        return None
    }

    /// Returns narrow progress and interaction scalars for exactly one live
    /// application-owned target. The value is never borrowed from a sibling
    /// if the requested generation has closed or belongs to another app.
    public func windowProgressForTarget(target: String): ?CjguiSharedOperationWindowProgress {
        for (entry in windows) {
            if (entry.identifier.value == target && entry.identifier.belongsTo(applicationIdentity) &&
                entry.composableWindow.isOpen()) {
                return Some(entry.composableWindow.windowProgress())
            }
        }
        return None
    }

    public func isOpen(): Bool {
        return !closed && liveWindowCount() > 0
    }

    /// Test-only: the first window retirement reason, the application close reason
    /// and whether an application-exit intent was consumed. They add no business
    /// semantics and only exist so a bounded scheduler probe can localize the first
    /// state change.
    public func testRetirementTrace(): String { return testRetirementTraceValue }
    public func testApplicationCloseTrace(): String { return testCloseTraceValue }
    public func testExitIntentTrace(): String { return testExitIntentTraceValue }

    /// Ask the target controller's established close decision. A rejection is
    /// local to that window and leaves all siblings, the connection and the
    /// application loop alive.
    public func requestClose(identifier: CjguiMacosApplicationWindowIdentifier): Bool {
        if (closed || !identifier.isValid()) {
            return false
        }
        if (let None <- entryFor(identifier)) {
            return false
        }
        if (isPumpingTurn) {
            if (!containsIdentifier(deferredCloseIdentifiers, identifier)) {
                deferredCloseIdentifiers.add(identifier)
            }
            return true
        }
        return requestCloseImmediately(identifier)
    }

    /// Requests normal process exit through the consumer's actual business
    /// decision. A rejected decision leaves the application untouched. The
    /// forceful `close()` remains for an already-authorized shutdown such as
    /// startup rollback or a caller that has separately completed this step.
    public func requestApplicationExit(): Bool {
        if (closed) {
            return false
        }
        if (let Some(provider) <- exitDecisionProvider) {
            if (!provider.requestApplicationExit()) {
                return false
            }
            if (isPumpingTurn) {
                deferredAuthorizedClose = true
            } else {
                closeImmediately()
            }
            return true
        }
        return false
    }

    /// One shared turn: external work is admitted once, all live windows get
    /// a non-blocking refresh/event drain, and a rotating live window receives
    /// the only bounded AppKit wait. A pending connection refresh is consumed
    /// once here, but it never forces every window to rebuild: each live
    /// projection's declared scene version decides whether that domain change
    /// actually concerns it. This keeps a shared document's sibling views in
    /// sync while leaving unrelated owners idle.
    public func pumpOneTurn(turnBudgetMs!: UInt32 = 16u32): CjguiMacosApplicationTurnResult {
        // A controller may synchronously re-enter the application while an
        // event is being delivered. It gets no second event drain or wait;
        // structural close requests are queued and applied by the outer turn.
        if (isPumpingTurn) {
            return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), 0, 0u32, 0, None)
        }
        if (!isOpen()) {
            closeIfEmpty()
            return CjguiMacosApplicationTurnResult(false, 0, 0, 0u32, 0, None)
        }
        isPumpingTurn = true
        try {
            let result = pumpOneTurnWhileGuarded(turnBudgetMs)
            isPumpingTurn = false
            return result
        } catch (error: Exception) {
            // Callback failures retain their original failure semantics, but
            // cannot leave every later call looking like a nested turn.
            // Deferred lifecycle work is deliberately not applied here: the
            // caller observed a failed turn and may decide recovery itself.
            isPumpingTurn = false
            throw error
        }
    }

    /// All normal exits flow through `pumpOneTurn` so the reentry guard is
    /// released both after a result and after a propagated callback failure.
    private func pumpOneTurnWhileGuarded(turnBudgetMs: UInt32): CjguiMacosApplicationTurnResult {
        let started = MonoTime.now()
        var externalActionCount: Int64 = 0
        if (let Some(connection) <- externalConnection) {
            while (externalActionCount < 16) {
                if (externalActionCount > 0 && elapsedMs(started) >= Int64(turnBudgetMs)) {
                    break
                }
                if (!connection.pump(0u32)) {
                    break
                }
                externalActionCount += 1
            }
            let _ = connection.consumeWindowRefreshRequest()
        }

        // Snapshot scalar identifiers, then reacquire each live entry after a
        // controller callback. A callback can request sibling close or final
        // exit without invalidating this iteration or operating a stale one.
        let nonBlockingIdentifiers = windowIdentifiers()
        var hasPostRefreshObserver = false
        if (let Some(observer) <- testPostRefreshObserver) {
            hasPostRefreshObserver = true
            // The explicitly installed testing seam observes the historical
            // refreshed-scene boundary before injecting a native event.
            for (identifier in nonBlockingIdentifiers) {
                if (closed) { break }
                if (let Some(composableWindow) <- window(identifier)) {
                    let _ = composableWindow.refreshIfNeeded()
                    if (let Some(liveWindow) <- window(identifier)) {
                        observer.postRefreshBeforePump(liveWindow)
                        let result = liveWindow.pump(0u32)
                        if (!result.isOpen) { retire(identifier) }
                    }
                }
            }
        } else {
            // Event ownership is cheap relative to a long TextKit/layout
            // preparation. Drain each accepted FIFO before any window starts
            // such work, then publish event-bearing windows first.
            let eventWindows = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            let otherWindows = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            for (identifier in nonBlockingIdentifiers) {
                if (closed) { break }
                if (let Some(composableWindow) <- window(identifier)) {
                    let result = composableWindow.pumpEventsWithoutRefresh(0u32)
                    if (!result.isOpen) {
                        retire(identifier)
                    } else if (result.didApplyHumanAction) {
                        eventWindows.add(identifier)
                    } else {
                        otherWindows.add(identifier)
                    }
                }
            }
            for (identifier in eventWindows) {
                if (closed) { break }
                if (let Some(composableWindow) <- window(identifier)) {
                    let _ = composableWindow.refreshAfterDeferredPump()
                }
            }
            // A turn with newly handled input returns before starting an
            // unrelated costly refresh, so the caller can observe the input
            // without waiting for that work. A second consecutive event turn
            // must service ordinary invalidations to prevent starvation.
            let serviceOrdinary = eventWindows.size == 0 || ordinaryDeferredRounds > 0
            if (serviceOrdinary) {
                ordinaryDeferredRounds = 0
                if (otherWindows.size > 0) {
                    if (nextPreparationIndex < 0 || nextPreparationIndex >= otherWindows.size) {
                        nextPreparationIndex = 0
                    }
                    var offset: Int64 = 0
                    while (offset < otherWindows.size) {
                        let index = (nextPreparationIndex + offset) % otherWindows.size
                        let identifier = otherWindows[index]
                        if (closed) { break }
                        if (let Some(composableWindow) <- window(identifier)) {
                            let _ = composableWindow.refreshAfterDeferredPump()
                        }
                        offset += 1
                    }
                    nextPreparationIndex = (nextPreparationIndex + 1) % otherWindows.size
                }
            } else {
                ordinaryDeferredRounds += 1
            }
        }
        consumeNativeApplicationExitIntent()
        applyDeferredMutations()
        if (!isOpen()) {
            return CjguiMacosApplicationTurnResult(false, 0, externalActionCount, 0u32, elapsedMs(started), None)
        }

        let waitIdentifiers = windowIdentifiers()
        if (nextWaitIndex < 0 || nextWaitIndex >= waitIdentifiers.size) {
            nextWaitIndex = 0
        }
        let waitedIdentifier = waitIdentifiers[nextWaitIndex]
        nextWaitIndex = nextWaitIndex.saturatingAdd(1)
        if (nextWaitIndex >= waitIdentifiers.size) {
            nextWaitIndex = 0
        }
        let elapsed = elapsedMs(started)
        let waitBudget: UInt32 = if (elapsed >= Int64(turnBudgetMs)) {
            0u32
        } else {
            UInt32(Int64(turnBudgetMs) - elapsed)
        }
        if (let Some(waitedWindow) <- window(waitedIdentifier)) {
            let waited = if (hasPostRefreshObserver) {
                waitedWindow.pump(waitBudget)
            } else {
                waitedWindow.pumpEventsWithoutRefresh(waitBudget)
            }
            if (!waited.isOpen) {
                retire(waitedIdentifier)
            } else if (waited.didApplyHumanAction) {
                let _ = waitedWindow.refreshAfterDeferredPump()
            }
        }
        consumeNativeApplicationExitIntent()
        applyDeferredMutations()
        let result = CjguiMacosApplicationTurnResult(
            isOpen(),
            liveWindowCount(),
            externalActionCount,
            waitBudget,
            elapsed,
            Some(waitedIdentifier)
        )
        return result
    }

    /// AppKit's delegate only queues a coalesced, process-level Quit intent
    /// and returns immediately. The current normal application turn is the
    /// sole place that consumes it, so the already-public exit decision
    /// provider decides rejection/cleanup without a main-thread wait on
    /// Cangjie. One native intent is enough even when the user repeats Quit
    /// before this turn reaches its key window.
    private func consumeNativeApplicationExitIntent(): Unit {
        // No key window means keyboard focus cannot identify a session, but
        // it does not erase this application's lifecycle owner. Consume only
        // when the reference registry proves that this is the one live
        // application owner; otherwise leave the native intent pending and
        // fail closed instead of selecting an arbitrary sibling window.
        if (ownsApplicationExitLifecycleReference &&
            CjguiMacosApplicationLoopReferenceRegistry.isExclusiveOwner(applicationIdentity) &&
            internalRendererHasUnkeyedApplicationExitRequest()) {
            internalRendererCompleteApplicationExitRequest()
            testExitIntentTraceValue = "unkeyed_exit_intent_consumed"
            let _ = requestApplicationExit()
            return
        }
        for (identifier in windowIdentifiers()) {
            if (let Some(composableWindow) <- window(identifier)) {
                if (composableWindow.consumeApplicationExitRequest()) {
                    testExitIntentTraceValue = "window_exit_intent_consumed window=${identifier.value}"
                    let _ = requestApplicationExit()
                    return
                }
            }
        }
    }

    /// Final application shutdown intentionally bypasses per-window business
    /// close prompts: it is used only after an explicit application-level
    /// decision or a startup failure. It is idempotent and owns connection
    /// cleanup plus the single AppKit stop.
    public func close() {
        if (closed) {
            return
        }
        if (isPumpingTurn) {
            deferredAuthorizedClose = true
            return
        }
        closeImmediately()
    }

    private func closeImmediately() {
        if (closed) {
            return
        }
        closed = true
        for (entry in windows) {
            entry.composableWindow.close()
        }
        windows = ArrayList<CjguiMacosApplicationWindowEntry>()
        if (let Some(connection) <- externalConnection) {
            connection.close()
        }
        externalConnection = None
        if (ownsApplicationExitLifecycleReference) {
            ownsApplicationExitLifecycleReference = false
            internalRendererReleaseApplicationExitLifecycleOwner()
        }
        if (ownsProcessLoopReference) {
            ownsProcessLoopReference = false
            if (CjguiMacosApplicationLoopReferenceRegistry.release(applicationIdentity)) {
                CjguiMacosApplicationHost.stopApplicationLoop()
            }
        }
    }

    private func entryFor(identifier: CjguiMacosApplicationWindowIdentifier): ?CjguiMacosApplicationWindowEntry {
        if (!identifier.belongsTo(applicationIdentity)) {
            return None
        }
        for (entry in windows) {
            if (entry.identifier.applicationIdentifier == identifier.applicationIdentifier &&
                entry.identifier.value == identifier.value && entry.identifier.generation == identifier.generation) {
                return Some(entry)
            }
        }
        return None
    }

    private func retire(identifier: CjguiMacosApplicationWindowIdentifier) {
        if (testRetirementTraceValue.size == 0) {
            let trace = if (let Some(retiring) <- window(identifier)) { retiring.testCloseTrace() } else { "missing" }
            testRetirementTraceValue = "window=${identifier.value} gen=${identifier.generation} ${trace} live_windows_before=${liveWindowCount()}"
        }
        let remaining = ArrayList<CjguiMacosApplicationWindowEntry>()
        for (entry in windows) {
            if (entry.identifier.applicationIdentifier == identifier.applicationIdentifier &&
                entry.identifier.value == identifier.value && entry.identifier.generation == identifier.generation) {
                entry.composableWindow.close()
            } else {
                remaining.add(entry)
            }
        }
        windows = remaining
        if (nextWaitIndex >= windows.size) {
            nextWaitIndex = 0
        }
        closeIfEmpty()
    }

    private func requestCloseImmediately(identifier: CjguiMacosApplicationWindowIdentifier): Bool {
        if (let Some(entry) <- entryFor(identifier)) {
            if (!entry.composableWindow.requestCloseFromApplication()) {
                return false
            }
            retire(identifier)
            return true
        }
        return false
    }

    private func applyDeferredMutations() {
        let requestedCloses = deferredCloseIdentifiers
        deferredCloseIdentifiers = ArrayList<CjguiMacosApplicationWindowIdentifier>()
        for (identifier in requestedCloses) {
            if (!closed) {
                let _ = requestCloseImmediately(identifier)
            }
        }
        if (deferredAuthorizedClose) {
            deferredAuthorizedClose = false
            closeImmediately()
        }
    }

    private func closeIfEmpty() {
        if (!closed && windows.size == 0) {
            close()
        }
    }

    private func liveWindowCount(): Int64 {
        var count: Int64 = 0
        for (entry in windows) {
            if (entry.composableWindow.isOpen()) {
                count += 1
            }
        }
        return count
    }

    private func elapsedMs(started: MonoTime): Int64 {
        return (MonoTime.now() - started).toMilliseconds()
    }

    private func containsIdentifier(
        identifiers: ArrayList<CjguiMacosApplicationWindowIdentifier>,
        target: CjguiMacosApplicationWindowIdentifier
    ): Bool {
        for (identifier in identifiers) {
            if (identifier.applicationIdentifier == target.applicationIdentifier && identifier.value == target.value &&
                identifier.generation == target.generation) {
                return true
            }
        }
        return false
    }
}

/// Framework-owned normal macOS host for one composable window. Applications
/// retain their controller and optional shared-operation owner; this host owns
/// native start, the one turn scheduler, partial-start cleanup and close.
public class CjguiMacosApplicationHost {
    private let configuration: CjguiMacosApplicationWindowConfiguration
    private let composableWindow: CjguiComposableUiWindow
    private var externalConnection: ?CjguiSharedOperationExternalConnection
    private var started: Bool
    private var closed: Bool

    public init(controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()) {
        this.configuration = configuration
        this.composableWindow = CjguiComposableUiWindow(controller, configuration: configuration)
        this.externalConnection = None
        this.started = false
        this.closed = false
    }

    /// The framework window remains a Cangjie projection surface. Returning it
    /// permits an application to bind semantic commands or compose its optional
    /// external connection without exposing a native session token.
    public func window(): CjguiComposableUiWindow {
        return composableWindow
    }

    /// Attach at most one optional external connection before startup. Its
    /// authorization and domain remain application-owned.
    public func attachExternalConnection(connection: CjguiSharedOperationExternalConnection): Bool {
        if (started || closed) {
            return false
        }
        if (let Some(_) <- externalConnection) {
            return false
        }
        externalConnection = Some(connection)
        return true
    }

    public func start(): Bool {
        if (closed || !configuration.isValid()) {
            return false
        }
        if (started) {
            return true
        }
        // A1：受理（首帧 PENDING）也继续：宿主泵送经前置结算门推进到 Ready。
        var hostStartFailed = false
        match (composableWindow.startWithOutcome()) {
            case StartFailed => hostStartFailed = true
            case _ => hostStartFailed = false
        }
        if (hostStartFailed) {
            close()
            return false
        }
        if (let Some(connection) <- externalConnection) {
            if (!connection.start()) {
                close()
                return false
            }
        }
        started = true
        return true
    }

    /// A1：启动受理状态透出。true = 首帧已受理但终态未定（宿主泵送中）；
    /// false 且已启动 = 首帧 Ready。真实失败经 start 返回假。
    public func isWindowStartingPending(): Bool {
        return composableWindow.isStartingPending()
    }

    /// A1：终止收敛命名故障透出（空串 = 无未收敛故障）。
    public func windowSettlementFault(): String {
        return composableWindow.settlementFault()
    }

    /// One bounded normal turn. The existing scheduler remains the only
    /// source of AppKit event waiting and optional external action pacing.
    public func pumpOneTurn(): Bool {
        if (!started || closed || !composableWindow.isOpen()) {
            close()
            return false
        }
        // H2（astra 共同宿主推进）：滚动活动由共同宿主在每个回合推进一次——
        // `changed` 请求本回合刷新（末帧交付），`active` 经调度器把等待预算
        // 缩到 0 形成有界唤醒；样例不再各自 step（labs 已退役本地推进）。
        let activity = composableWindow.stepWindowActivities(MonoTime.now())
        if (activity.changed) {
            composableWindow.requestRefresh()
        }
        if (let Some(connection) <- externalConnection) {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithExternal(composableWindow, connection)
        } else {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(composableWindow)
        }
        if (!composableWindow.isOpen()) {
            close()
            return false
        }
        return true
    }

    public func isOpen(): Bool {
        return started && !closed && composableWindow.isOpen()
    }

    /// Request the application-owned close decision without reaching into
    /// AppKit. Rejection leaves this Host usable; acceptance uses normal,
    /// idempotent Host cleanup.
    public func requestClose(): Bool {
        if (!isOpen()) {
            return false
        }
        if (!composableWindow.requestCloseFromApplication()) {
            return false
        }
        close()
        return true
    }

    /// Use for an argument/configuration failure before a host instance can
    /// start. The native request is lifecycle-only and never publishes an
    /// AppKit handle to the application.
    public static func stopApplicationLoop() {
        internalRendererRequestApplicationStop()
    }

    public func close() {
        if (closed) {
            return
        }
        closed = true
        composableWindow.close()
        if (let Some(connection) <- externalConnection) {
            connection.close()
        }
        started = false
        CjguiMacosApplicationHost.stopApplicationLoop()
    }
}
