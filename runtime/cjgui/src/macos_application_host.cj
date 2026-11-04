package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.overflow.*
import std.random.*
import std.sync.*
import std.time.*
import std.env.*
import std.io.*

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

/// Experimental macOS system-window facts, copied from the actual native lifecycle.
public class CjguiMacosApplicationWindowState {
    public let isFullScreen: Bool
    public let isEnteringFullScreen: Bool
    public let isExitingFullScreen: Bool
    public let stateRevision: UInt64
    public let isMinimized: Bool
    public let isVisible: Bool
    public let contentWidth: Int64
    public let contentHeight: Int64
    public let drawableWidth: UInt64
    public let drawableHeight: UInt64
    public let fullScreenFailure: String
    // Experimental macOS observation. Only native lifecycle facts produce
    // this snapshot; no native object or session generation is public.
    init(words: Array<UInt64>) {
        isFullScreen = words[0] != 0u64
        isEnteringFullScreen = words[1] == 1u64; isExitingFullScreen = words[1] == 2u64
        stateRevision = words[2]; isMinimized = words[3] != 0u64; isVisible = words[4] != 0u64
        contentWidth = Int64(words[5]); contentHeight = Int64(words[6])
        fullScreenFailure = if (words[7] == 1u64) { "enter_failed" }
            else if (words[7] == 2u64) { "exit_failed" } else { "none" }
        drawableWidth = words[9]; drawableHeight = words[10]
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

    public static func isEmpty(): Bool {
        return synchronized(CjguiMacosApplicationLoopReferenceRegistry.referenceLock) {
            CjguiMacosApplicationLoopReferenceRegistry.activeApplicationIdentifiers.size == 0
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

// Reuse the renderer's generation-checked lifecycle snapshot. Ordinary owner
// turns must not rediscover NSWindow or read AppKit objects through the legacy
// window-number bridge. A temporarily unavailable snapshot retains the last
// accepted visibility policy, with the existing conservative startup defaults.
private func cjguiMacosPublishedVisibility(window: CjguiComposableUiWindow,
    previous: ?CjguiComposableUiPlatformStateSnapshot): (Bool, Bool) {
    if (let Some(state) <- window.macosSystemWindowState()) {
        return (state.isVisible, state.isMinimized)
    }
    if (let Some(state) <- previous) { return (state.windowVisible, state.windowMinimized) }
    return (true, false)
}

private class CjguiMacosApplicationWindowEntry {
    let identifier: CjguiMacosApplicationWindowIdentifier
    let composableWindow: CjguiComposableUiWindow
    /// C：每个窗口自己的平台状态追踪器，仅在系统/窗口事实变化时推一次动效策略；
    /// 同一事实重复出现不重发。
    let platformStateTracker: CjguiComposableUiPlatformStateTracker

    init(identifier: CjguiMacosApplicationWindowIdentifier, composableWindow: CjguiComposableUiWindow) {
        this.identifier = identifier
        this.composableWindow = composableWindow
        this.platformStateTracker = CjguiComposableUiPlatformStateTracker()
    }
}

private class CjguiMacosApplicationExitBasis {
    let identifier: CjguiMacosApplicationWindowIdentifier
    let scene: Int64
    let owner: Int64
    init(identifier: CjguiMacosApplicationWindowIdentifier, scene: Int64, owner: Int64) {
        this.identifier = identifier; this.scene = scene; this.owner = owner
    }
}

/// The application owns final process exit, while its consumer owns the
/// business decision to allow it. A `false` result must leave every live
/// window and the shared endpoint usable.
public interface CjguiMacosApplicationExitDecisionProvider {
    func requestApplicationExit(): Bool
}

/// Optional lifecycle for a decision that retains per-window permissions
/// until the application has actually committed the exit. After native commit
/// all participating windows are logically closed and the application rejects
/// new work before invoking `applicationExitDidCommit`. Callback exceptions
/// are reported by name and cannot stop post-commit resource retirement.
public interface CjguiMacosApplicationExitDecisionLifecycle {
    func applicationExitDidCommit(): Unit
    func applicationExitDidCancel(): Unit
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
    // Additional already-started endpoints owned by an opt-in single Host.
    private let hostExitConnections = ArrayList<CjguiSharedOperationExternalConnection>()
    private var hostExitManaged = false
    private var hostExitNativeCommitted = false
    private let exitDecisionProvider: ?CjguiMacosApplicationExitDecisionProvider
    private var closed: Bool
    private var nextGeneration: Int64
    private var nextWaitIndex: Int64
    private var nextPreparationIndex: Int64
    private var ordinaryDeferredRounds: Int64
    private var sharedOwnerTurnBudget = CjguiOwnerTurnBudget()
    private let traceScheduling = getVariable("CJGUI_HOST_SCHEDULING_TRACE") == Some("1")
    private var schedulingWaitBudget: UInt32 = 0u32
    private var schedulingRepeats: Int64 = 0
    private var schedulingTraceLines: Int64 = 0

    // Test-only: the FIRST window retirement and the application close reason, so
    // a bounded probe can name the actual first state change instead of only
    // printing that everything is closed at the end.
    private var testRetirementTraceValue: String
    private var testCloseTraceValue: String
    private var testExitIntentTraceValue: String
    private var isPumpingTurn: Bool
    private var deferredCloseIdentifiers: ArrayList<CjguiMacosApplicationWindowIdentifier>
    private var deferredAuthorizedClose: Bool
    private var deferredApplicationExit: Bool
    // Set only after native atomic commit. Public reentry cannot add work to
    // the participant set whose native sessions have already been destroyed.
    private var applicationExitCommitInProgress = false
    private var applicationExitDecisionInProgress = false
    private let closeLifecycleTraceEnabled = getVariable("CJGUI_CLOSE_LIFECYCLE_TRACE") == Some("1")
    private var closeLifecycleTraceLast = ""
    private var closeLifecycleTraceRows: Int64 = 0
    private var applicationExitApproved: Bool
    private var applicationExitLifecycleFinalized: Bool
    private let applicationExitBasis: ArrayList<CjguiMacosApplicationExitBasis>
    private var ownsProcessLoopReference: Bool
    private var ownsApplicationExitLifecycleReference: Bool
    private var testPostRefreshObserver: ?CjguiMacosApplicationPostRefreshObserver
    /// C：应用级主题策略。固定值优先于系统跟随；默认跟随系统。
    private var selectedThemePreference: CjguiComposableUiThemePreference
    private var selectedAccentPreferenceToken: String = "system"

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
        this.deferredApplicationExit = false
        this.applicationExitApproved = false
        this.applicationExitLifecycleFinalized = false
        this.applicationExitBasis = ArrayList<CjguiMacosApplicationExitBasis>()
        this.ownsProcessLoopReference = false
        this.ownsApplicationExitLifecycleReference = false
        this.testPostRefreshObserver = None
        this.selectedThemePreference = CjguiComposableUiThemePreference.SystemFollow
    }

    /// Test-only: registers the post-refresh/pre-pump observer (see
    /// CjguiMacosApplicationPostRefreshObserver). Passing None removes it.
    public func setTestPostRefreshObserver(observer: ?CjguiMacosApplicationPostRefreshObserver): Unit {
        testPostRefreshObserver = observer
    }

    /// C：应用选择的主题策略（token 形式）。固定浅色/深色优先于系统跟随；
    /// 未知 token 被拒并保持当前选择，不做静默归一化。
    public func setThemePreference(token: String): Bool {
        if (closed || applicationExitCommitInProgress) { return false }
        if (let Some(preference) <- CjguiComposableUiPlatformStateCodec.themePreferenceFromToken(token)) {
            selectedThemePreference = preference
            return true
        }
        return false
    }

    /// C：当前应用级主题策略。
    public func themePreference(): CjguiComposableUiThemePreference {
        return selectedThemePreference
    }

    public func setAccentPreference(token: String): Bool {
        if (closed || applicationExitCommitInProgress) { return false }
        if (CjguiComposableUiAccentPreference.fromToken(token).isNone()) { return false }
        selectedAccentPreferenceToken = token
        for (entry in windows) { let _ = entry.composableWindow.selectAccentPreference(token) }
        return true
    }

    /// Opens one independent projection/session. The controller and its
    /// domain remain caller-owned; this method never duplicates the domain.
    public func openWindow(
        controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()
    ): CjguiMacosApplicationWindowOpenResult {
        if (closed || applicationExitCommitInProgress) {
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
        window.installDefaultOwnerTurnBudget(sharedOwnerTurnBudget)
        let _ = window.selectAccentPreference(selectedAccentPreferenceToken)
        let _ = window.offerPlatformColorScheme(CjguiComposableUiPlatformStateResolution.resolveColorScheme(
            selectedThemePreference, CjguiComposableUiPlatformFacts.systemColorScheme()))
        let _ = window.observeSystemAccent()
        // A1：受理（首帧 PENDING）不是失败——窗口已打开且留在泵送集合里，
        // 由后续 turn 的前置结算门推进到 Ready/失败。只有 StartFailed 才拒绝。
        var windowStartFailed = false
        match (window.startForApplicationWindow(liveWindowCount() > 0)) {
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
        nextGeneration = if (following <= generation) {
            0
        } else {
            following
        }
        let identifier = CjguiMacosApplicationWindowIdentifier(
            applicationIdentity,
            "${applicationIdentity}_window_${generation}",
            generation
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

    // A Host-owned engine must never report application-exit commit for a
    // failed startup or an ordinary local close.
    func configureForHostExit(): Unit { hostExitManaged = true }

    // A single-window Host already exposed this same window for controller and
    // connection binding before start. Adopt it into the existing application
    // exit engine without constructing a second window or changing its budget.
    func adoptStartedHostWindow(window: CjguiComposableUiWindow): Bool {
        if (closed || windows.size != 0 || !window.isOpen() || applicationIdentity.size == 0) { return false }
        let identifier = CjguiMacosApplicationWindowIdentifier(applicationIdentity,
            "${applicationIdentity}_window_1", 1)
        if (!CjguiMacosApplicationLoopReferenceRegistry.retain(applicationIdentity)) { return false }
        ownsProcessLoopReference = true
        internalRendererRetainApplicationExitLifecycleOwner()
        ownsApplicationExitLifecycleReference = true
        hostExitManaged = true
        windows.add(CjguiMacosApplicationWindowEntry(identifier, window))
        nextGeneration = 2
        return true
    }

    // The Host owns startup/pumping, while this engine owns these endpoints'
    // application-exit reservations and terminal cleanup. They are never
    // started or pumped a second time here.
    func adoptHostExitConnection(connection: CjguiSharedOperationExternalConnection): Bool {
        if (closed || applicationExitCommitInProgress) { return false }
        if (let Some(primary) <- externalConnection) { if (refEq(primary, connection)) { return false } }
        for (existing in hostExitConnections) { if (refEq(existing, connection)) { return false } }
        hostExitConnections.add(connection)
        // An added endpoint changes the set whose outstanding requests must be
        // settled; a prior approval cannot authorize the changed basis.
        applicationExitApproved = false
        return true
    }

    // Host turns use the same reentry guard as Application turns. In
    // particular, a provider cannot recursively commit while its first
    // decision callback is still on the stack.
    func beginHostExitTurn(): Bool {
        if (closed || isPumpingTurn || applicationExitCommitInProgress) { return false }
        isPumpingTurn = true
        return true
    }

    func endHostExitTurn(): Unit { isPumpingTurn = false }

    // Called after the Host has drained its actual scheduler turn. The normal
    // application exit machinery remains the sole owner of the decision.
    func serviceHostExitAfterTurn(handledInput: Bool, externalActions: Int64): Unit {
        if (applicationExitApproved && (handledInput || externalActions > 0)) { applicationExitApproved = false }
        consumeNativeApplicationExitIntent()
        applyDeferredMutations()
    }

    /// Public owner identity used only to bind scalar window identifiers. It
    /// is not a native session token and has no authority on its own.
    public func applicationIdentifier(): String {
        return applicationIdentity
    }

    /// Attach at most one process-level connection. Its owner/authorization is
    /// supplied by the application; closing a single window never closes it.
    public func attachExternalConnection(connection: CjguiSharedOperationExternalConnection): Bool {
        if (closed || applicationExitCommitInProgress) {
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

    /// Experimental/macOS. A live identity is checked on every request.
    /// true means the system request was admitted; observe windowState for
    /// the actual enter/exit result. Repeated identical requests are idempotent.
    public func requestFullScreen(identifier: CjguiMacosApplicationWindowIdentifier, enabled: Bool): Bool {
        return match (window(identifier)) {
            case Some(value) => value.requestMacosFullScreen(enabled)
            case None => false
        }
    }

    public func windowState(identifier: CjguiMacosApplicationWindowIdentifier): ?CjguiMacosApplicationWindowState {
        return match (window(identifier)) {
            case Some(value) => value.macosSystemWindowState()
            case None => None
        }
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
    public func testRetirementTrace(): String {
        return testRetirementTraceValue
    }
    public func testApplicationCloseTrace(): String {
        return testCloseTraceValue
    }
    public func testExitIntentTrace(): String {
        return testExitIntentTraceValue
    }

    /// Ask the target controller's established close decision. A rejection is
    /// local to that window and leaves all siblings, the connection and the
    /// application loop alive.
    public func requestClose(identifier: CjguiMacosApplicationWindowIdentifier): Bool {
        if (closed || applicationExitCommitInProgress || !identifier.isValid()) {
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
        if (closed || applicationExitCommitInProgress || exitDecisionProvider.isNone()) { return false }
        if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=request_exit pumping=${isPumpingTurn}") }
        deferredApplicationExit = true
        cjguiNotifySchedulingWork()
        if (isPumpingTurn || applicationExitDecisionInProgress) { return true }
        return processApplicationExit()
    }

    private func traceCloseLifecycle(state: String): Unit {
        if (!closeLifecycleTraceEnabled || closeLifecycleTraceRows >= 64 || state == closeLifecycleTraceLast) { return }
        closeLifecycleTraceLast = state; closeLifecycleTraceRows += 1
        println("CJGUI_CLOSE_LIFECYCLE scope=host ${state}")
        getStdOut().flush()
    }

    /// Cancel a queued ordinary application-exit request. Forceful `close()`
    /// is a separate operation and is not revoked by this method.
    public func cancelPendingApplicationExit(notifyProvider!: Bool = true): Unit {
        if (applicationExitCommitInProgress && notifyProvider) { return }
        deferredApplicationExit = false
        applicationExitApproved = false
        applicationExitBasis.clear()
        if (notifyProvider) {
            if (let Some(provider) <- exitDecisionProvider) {
                if (let Some(lifecycle) <- (provider as CjguiMacosApplicationExitDecisionLifecycle)) {
                    lifecycle.applicationExitDidCancel()
                }
            }
        }
    }

    /// One shared turn: external work is admitted once, all live windows get
    /// a non-blocking refresh/event drain, and a rotating live window receives
    /// the only bounded AppKit wait. A pending connection refresh is consumed
    /// once here, but it never forces every window to rebuild: each live
    /// projection's declared scene version decides whether that domain change
    /// actually concerns it. This keeps a shared document's sibling views in
    /// sync while leaving unrelated owners idle.
    public func pumpOneTurn(turnBudgetMs!: UInt32 = 16u32): CjguiMacosApplicationTurnResult {
        return pumpTurn(turnBudgetMs, turnBudgetMs)
    }

    /// Normal event-driven loop. Work retains the original turn allowance;
    /// timeoutMs bounds this whole call, or Max waits for a real wake/deadline.
    public func pumpUntilWork(turnBudgetMs!: UInt32 = 16u32,
        timeoutMs!: UInt32 = UInt32.Max): CjguiMacosApplicationTurnResult {
        return pumpTurn(turnBudgetMs, timeoutMs)
    }

    private func ownerBudgetForTurn(): CjguiOwnerTurnBudget {
        var declared: ?CjguiOwnerTurnBudget = None
        for (entry in windows) {
            if (entry.composableWindow.hasExplicitOwnerTurnBudget()) {
                if (let Some(value) <- entry.composableWindow.attachedOwnerTurnBudget()) {
                    if (let Some(previous) <- declared) {
                        if (!refEq(previous,value)) { throw Exception("application_owner_budget_conflict") }
                    } else { declared = Some(value) }
                }
            }
        }
        if (let Some(value) <- declared) { sharedOwnerTurnBudget = value }
        for (entry in windows) { entry.composableWindow.installDefaultOwnerTurnBudget(sharedOwnerTurnBudget) }
        return sharedOwnerTurnBudget
    }

    private func pumpTurn(turnBudgetMs: UInt32, maximumIdleWaitMs: UInt32): CjguiMacosApplicationTurnResult {
        if (applicationExitCommitInProgress) {
            return CjguiMacosApplicationTurnResult(false, 0, 0, 0u32, 0, None)
        }
        // A controller may synchronously re-enter the application while an
        // event is being delivered. It gets no second event drain or wait;
        // structural close requests are queued and applied by the outer turn.
        if (isPumpingTurn) {
            return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), 0, 0u32, 0, None)
        }
        if (!isOpen()) {
            reapClosedEntries()
            closeIfEmpty()
            return CjguiMacosApplicationTurnResult(false, 0, 0, 0u32, 0, None)
        }
        let budget = ownerBudgetForTurn()
        let ownsTurn = !budget.isActive()
        if (ownsTurn && !budget.begin(budgetMicroseconds: max(1, Int64(turnBudgetMs) * 1000))) {
            throw Exception("owner_turn_unavailable")
        }
        isPumpingTurn = true
        schedulingWaitBudget = 0u32
        if (ownsTurn) { cjguiOwnerTraceBoundary(0u64,UInt64(budget.turnIdentity()),144u32,0u32,0u32,0u64,UInt64.Max) }
        try {
            let result = pumpOneTurnWhileGuarded(turnBudgetMs, maximumIdleWaitMs, ownsTurn)
            isPumpingTurn = false
            return result
        } catch (error: Exception) {
            // Callback failures retain their original failure semantics, but
            // cannot leave every later call looking like a nested turn.
            // Deferred lifecycle work is deliberately not applied here: the
            // caller observed a failed turn and may decide recovery itself.
            isPumpingTurn = false
            throw error
        } finally {
            if (ownsTurn) {
                observeSchedulingDecision(schedulingWaitBudget, budget.observedIdleNanoseconds() / 1000)
                budget.end()
                cjguiOwnerTraceBoundary(0u64,UInt64(budget.turnIdentity()),145u32,0u32,0u32,0u64,UInt64.Max)
            }
        }
    }

    /// All normal exits flow through `pumpOneTurn` so the reentry guard is
    /// released both after a result and after a propagated callback failure.
    private func pumpOneTurnWhileGuarded(turnBudgetMs: UInt32,
        maximumIdleWaitMs: UInt32, frameworkOwnsTurn: Bool): CjguiMacosApplicationTurnResult {
        let started = MonoTime.now()
        if (let Some(connection) <- externalConnection) {
            connection.ensureOwnerWorkNotifier(cjguiNotifySchedulingWork)
        }
        let observedWork = cjguiSchedulingWorkRevision()
        var externalActionCount: Int64 = 0
        var handledInput = false
        if (let Some(connection) <- externalConnection) {
            while (externalActionCount < 16) {
                if (externalActionCount > 0 && (elapsedMs(started) >= Int64(turnBudgetMs) || !sharedOwnerTurnBudget.admitsAnotherExternalAction())) {
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
                if (closed) {
                    break
                }
                if (let Some(composableWindow) <- window(identifier)) {
                    let _ = composableWindow.refreshIfNeeded()
                    if (composableWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                        return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                            0u32, elapsedMs(started), None)
                    }
                    if (let Some(liveWindow) <- window(identifier)) {
                        observer.postRefreshBeforePump(liveWindow)
                        let result = liveWindow.pump(0u32)
                        handledInput = handledInput || result.didApplyHumanAction
                        if (liveWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                            return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                                0u32, elapsedMs(started), None)
                        }
                        if (!result.isOpen) {
                            retire(identifier)
                        }
                    }
                }
            }
        } else {
            // Event ownership is cheap relative to a long TextKit/layout
            // preparation. Drain each accepted FIFO before any window starts
            // such work, then publish event-bearing windows first.
            let eventWindows = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            let continuationWindows = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            let otherWindows = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            for (identifier in nonBlockingIdentifiers) {
                if (closed) {
                    break
                }
                if (let Some(composableWindow) <- window(identifier)) {
                    let result = composableWindow.pumpEventsWithoutRefresh(0u32)
                    if (composableWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                        return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                            0u32, elapsedMs(started), None)
                    }
                    if (!result.isOpen) {
                        retire(identifier)
                    } else if (result.didApplyHumanAction) {
                        handledInput = true
                        eventWindows.add(identifier)
                    } else if (composableWindow.hasRetainedSceneContinuation()) {
                        continuationWindows.add(identifier)
                    } else {
                        otherWindows.add(identifier)
                    }
                }
            }
            for (identifier in eventWindows) {
                if (closed) {
                    break
                }
                if (let Some(composableWindow) <- window(identifier)) {
                    let _ = composableWindow.refreshAfterDeferredPump()
                    if (composableWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                        return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                            0u32, elapsedMs(started), None)
                    }
                }
            }
            // All accepted FIFOs were drained above. Continue existing work
            // before building a fresh sibling scene; each window retains its
            // own budget, source, FIFO and publish checks. A resource that is
            // still waiting yields through that existing path, without polling
            // or a second event drain. Each window is serviced once per turn.
            for (identifier in continuationWindows) {
                if (closed) { break }
                if (let Some(composableWindow) <- window(identifier)) {
                    let _ = composableWindow.refreshAfterDeferredPump()
                    if (composableWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                        return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                            0u32, elapsedMs(started), None)
                    }
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
                        if (closed) {
                            break
                        }
                        if (let Some(composableWindow) <- window(identifier)) {
                            let _ = composableWindow.refreshAfterDeferredPump()
                            if (composableWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                                return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                                    0u32, elapsedMs(started), None)
                            }
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
        if (applicationExitApproved && (handledInput || externalActionCount > 0)) {
            applicationExitApproved = false
        }
        applyDeferredMutations()
        reapClosedEntries()
        if (!isOpen()) {
            return CjguiMacosApplicationTurnResult(false, 0, externalActionCount, 0u32, elapsedMs(started), None)
        }
        // P2：在任何 AppKit 长等待之前推进所有窗口的动效，并把系统“减少动态
        // 效果”偏好推给每个窗口。只有仍有活动动效时才收缩等待预算——静止后
        // 帧请求自然收敛，另一窗的输入不受影响。
        let anyActiveAnimation = serviceWindowAnimations()

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
        var waitBudget: UInt32 = if (handledInput || externalActionCount > 0 || elapsed >= Int64(turnBudgetMs) ||
            (maximumIdleWaitMs != UInt32.Max && elapsed >= Int64(maximumIdleWaitMs))) {
            0u32
        } else {
            if (maximumIdleWaitMs == UInt32.Max) { UInt32.Max } else {
                maximumIdleWaitMs - UInt32(elapsed)
            }
        }
        for (identifier in waitIdentifiers) {
            if (let Some(liveWindow) <- window(identifier)) {
                waitBudget = min(waitBudget, liveWindow.ownerIdleWaitAllowance(waitBudget, frameworkOwnsTurn: frameworkOwnsTurn))
            }
        }
        // P2：有活动动效时申请下一帧而不是长睡。无活动动效时保留原休眠预算，
        // 因此静止窗口不会持续唤醒，帧请求与提交收敛。
        if (anyActiveAnimation && waitBudget > CJGUI_COMPOSABLE_UI_ANIMATION_FRAME_WAIT_MS) {
            waitBudget = CJGUI_COMPOSABLE_UI_ANIMATION_FRAME_WAIT_MS
        }
        // Every live window has already serviced ready FIFO work above. Wait
        // once for any host or worker, using the original outer wall deadline;
        // a sibling becoming ready cannot be stranded behind the chosen host.
        if (cjguiCommonSchedulingEnabled() && waitBudget > 0u32) {
            if (frameworkOwnsTurn) { let _ = sharedOwnerTurnBudget.finishFrameworkScheduling(waitBudget) }
            else { let _ = cjguiWaitIdleSchedulingWork(observedWork, cjguiIdleSchedulingDeadline(waitBudget)) }
        }
        schedulingWaitBudget = waitBudget
        let pumpWait = if (cjguiCommonSchedulingEnabled()) { 0u32 } else { min(waitBudget, 16u32) }
        var tailHandledInput = false
        if (!hasPostRefreshObserver && waitBudget > 0u32) {
            // A shared resource wake belongs to any live window. Drain all
            // accepted FIFOs first; then consume those windows' retained visual
            // work before returning to an unrelated caller/peer preparation.
            // This is the existing single wait tail, never another wait/turn.
            let tailWork = ArrayList<CjguiMacosApplicationWindowIdentifier>()
            for (identifier in windowIdentifiers()) {
                if (closed) { break }
                if (let Some(liveWindow) <- window(identifier)) {
                    let drained = liveWindow.pumpEventsWithoutRefresh(
                        if (identifier.value == waitedIdentifier.value) { pumpWait } else { 0u32 })
                    handledInput = handledInput || drained.didApplyHumanAction
                    tailHandledInput = tailHandledInput || drained.didApplyHumanAction
                    if (liveWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                        return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                            0u32, elapsedMs(started), None)
                    }
                    if (!drained.isOpen) { retire(identifier) }
                    else if (drained.didApplyHumanAction || liveWindow.hasDeferredEventWork()) { tailWork.add(identifier) }
                }
            }
            for (identifier in tailWork) {
                if (closed) { break }
                if (let Some(liveWindow) <- window(identifier)) {
                    let _ = liveWindow.refreshAfterDeferredPump(afterSharedWait: true)
                }
            }
        } else if (let Some(waitedWindow) <- window(waitedIdentifier)) {
            let waited = if (hasPostRefreshObserver) { waitedWindow.pump(pumpWait) }
                else { waitedWindow.pumpEventsWithoutRefresh(pumpWait) }
            handledInput = handledInput || waited.didApplyHumanAction
            tailHandledInput = tailHandledInput || waited.didApplyHumanAction
            if (waitedWindow.nativeStatus() == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
                return CjguiMacosApplicationTurnResult(isOpen(), liveWindowCount(), externalActionCount,
                    0u32, elapsedMs(started), None)
            }
            if (!waited.isOpen) { retire(waitedIdentifier) }
            else if (waited.didApplyHumanAction || waitedWindow.hasDeferredEventWork()) {
                let _ = waitedWindow.refreshAfterDeferredPump()
            }
        }
        consumeNativeApplicationExitIntent()
        if (applicationExitApproved && tailHandledInput) {
            applicationExitApproved = false
        }
        applyDeferredMutations()
        reapClosedEntries()
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

    private func observeSchedulingDecision(waitMs: UInt32, idleUs: Int64): Unit {
        if (!traceScheduling || schedulingTraceLines >= 128) { return }
        if (idleUs > 0) { schedulingRepeats = 0; return }
        schedulingRepeats += 1
        if (schedulingRepeats >= 64 && (schedulingRepeats & (schedulingRepeats - 1)) == 0) {
            var signature = "wait_ms=${waitMs} idle_us=${idleUs} " + sharedOwnerTurnBudget.schedulingObservation()
            for (entry in windows) {
                signature += " [${entry.composableWindow.schedulingObservation()}]"
            }
            getStdErr().writeln("CJGUI_HOST_NO_IDLE turn=${sharedOwnerTurnBudget.turnIdentity()} " +
                "repeats=${schedulingRepeats} ${signature}")
            getStdErr().flush()
            schedulingTraceLines += 1
        }
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
        if (ownsApplicationExitLifecycleReference && CjguiMacosApplicationLoopReferenceRegistry.isExclusiveOwner(
            applicationIdentity) && internalRendererHasUnkeyedApplicationExitRequest()) {
            if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=consume_unkeyed") }
            internalRendererCompleteApplicationExitRequest()
            testExitIntentTraceValue = "unkeyed_exit_intent_consumed"
            let _ = requestApplicationExit()
            return
        }
        for (identifier in windowIdentifiers()) {
            if (let Some(composableWindow) <- window(identifier)) {
                if (composableWindow.consumeApplicationExitRequest()) {
                    if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=consume_42 window=${identifier.value}") }
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
    public func close(): Unit {
        if (closed || applicationExitCommitInProgress) {
            return
        }
        if (isPumpingTurn) {
            deferredAuthorizedClose = true
            return
        }
        closeImmediately()
    }

    private func closeImmediately(): Unit {
        if (closed) {
            return
        }
        deferredAuthorizedClose = true
        for (entry in windows) {
            entry.composableWindow.close()
        }
        reapClosedEntries()
        if (windows.size > 0) {
            // An unacknowledged present or rejected owner-thread destroy leaves
            // live sessions here. Keep the transport and process-loop owner
            // until a later legal turn completes the same shutdown request.
            deferredAuthorizedClose = true
            return
        }
        deferredAuthorizedClose = false
        closed = true
        if (!hostExitManaged || hostExitNativeCommitted) { finalizeApplicationExitLifecycle() }
        var hostIndex = hostExitConnections.size - 1
        while (hostIndex >= 0) { hostExitConnections[hostIndex].close(); hostIndex -= 1 }
        hostExitConnections.clear()
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
            } else {
                // An unkeyed Quit may now have exactly one owner.
                cjguiNotifySchedulingWork()
            }
        }
    }

    private func entryFor(identifier: CjguiMacosApplicationWindowIdentifier): ?CjguiMacosApplicationWindowEntry {
        if (!identifier.belongsTo(applicationIdentity)) {
            return None
        }
        for (entry in windows) {
            if (entry.identifier.applicationIdentifier == identifier.applicationIdentifier && entry.identifier.value == identifier
                .value && entry.identifier.generation == identifier.generation) {
                return Some(entry)
            }
        }
        return None
    }

    private func retire(identifier: CjguiMacosApplicationWindowIdentifier): Unit {
        let remaining = ArrayList<CjguiMacosApplicationWindowEntry>()
        var retired = false
        for (entry in windows) {
            if (entry.identifier.applicationIdentifier == identifier.applicationIdentifier && entry.identifier.value == identifier
                .value && entry.identifier.generation == identifier.generation && !entry.composableWindow.isOpen()) {
                if (testRetirementTraceValue.size == 0) {
                    testRetirementTraceValue = "window=${identifier.value} gen=${identifier.generation} " +
                        "${entry.composableWindow.testCloseTrace()} live_windows_before=${liveWindowCount()}"
                }
                retired = true
            } else {
                remaining.add(entry)
            }
        }
        if (!retired) { return }
        windows = remaining
        if (nextWaitIndex >= windows.size) {
            nextWaitIndex = 0
        }
        if (!deferredAuthorizedClose) {
            closeIfEmpty()
        }
    }

    private func reapClosedEntries(): Unit {
        let identifiers = ArrayList<CjguiMacosApplicationWindowIdentifier>()
        for (entry in windows) {
            if (!entry.composableWindow.isOpen()) {
                identifiers.add(entry.identifier)
            }
        }
        for (identifier in identifiers) {
            retire(identifier)
        }
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

    private func applicationExitBasisMatches(): Bool {
        if (!applicationExitApproved || applicationExitBasis.size != windows.size) { return false }
        for (index in 0..windows.size) {
            let entry = windows[index]
            let basis = applicationExitBasis[index]
            let (scene, owner) = entry.composableWindow.applicationExitDecisionVersion()
            if (entry.identifier.value != basis.identifier.value ||
                entry.identifier.generation != basis.identifier.generation ||
                scene != basis.scene || owner != basis.owner) { return false }
        }
        return true
    }

    private func finalizeApplicationExitLifecycle(): Unit {
        if (applicationExitLifecycleFinalized) { return }
        applicationExitLifecycleFinalized = true
        if (let Some(provider) <- exitDecisionProvider) {
            if (let Some(lifecycle) <- (provider as CjguiMacosApplicationExitDecisionLifecycle)) {
                try {
                    lifecycle.applicationExitDidCommit()
                } catch (error: Exception) {
                    testCloseTraceValue = "application_exit_lifecycle_exception"
                    getStdOut().writeln("CJGUI_APPLICATION_EXIT_LIFECYCLE_ERROR reason=application_exit_lifecycle_exception")
                    getStdOut().flush()
                }
            }
        }
    }

    // The consumer's Bool decision is made at most once per unchanged owner
    // basis. A native busy result keeps the intention and the bound decision;
    // ordinary work can continue and invalidates it before another attempt.
    private func processApplicationExit(): Bool {
        if (!deferredApplicationExit || closed) { return false }
        let sessions = ArrayList<UInt64>()
        let generations = ArrayList<UInt64>()
        let participants = ArrayList<CjguiMacosApplicationWindowEntry>()
        for (entry in windows) {
            let (token, generation) = match (entry.composableWindow.applicationExitPreflight()) {
                case Some(value) => value
                case None =>
                    if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=preflight_blocked window=${entry.identifier.value}") }
                    return true
            }
            sessions.add(token); generations.add(generation); participants.add(entry)
        }
        if (sessions.size == 0) { deferredApplicationExit = false; return false }
        if (!applicationExitBasisMatches()) {
            applicationExitApproved = false
            applicationExitBasis.clear()
            // Capture the actual participant/owner basis before consulting
            // the consumer. A callback that changes it cannot authorize a
            // different set or newer owner state.
            for (entry in windows) {
                let (scene, owner) = entry.composableWindow.applicationExitDecisionVersion()
                applicationExitBasis.add(CjguiMacosApplicationExitBasis(entry.identifier, scene, owner))
            }
            applicationExitApproved = true
            let provider = match (exitDecisionProvider) {
                case Some(value) => value
                case None =>
                    deferredApplicationExit = false
                    return false
            }
            if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=provider_enter windows=${windows.size}") }
            applicationExitDecisionInProgress = true
            var allowed = false
            try {
                allowed = provider.requestApplicationExit()
            } catch (error: Exception) {
                applicationExitApproved = false
                applicationExitBasis.clear()
                deferredApplicationExit = false
                throw error
            } finally {
                applicationExitDecisionInProgress = false
            }
            if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=provider_return allowed=${allowed}") }
            if (!allowed) {
                deferredApplicationExit = false
                applicationExitApproved = false
                applicationExitBasis.clear()
                return false
            }
            if (!deferredApplicationExit || closed) { return false }
            if (!applicationExitBasisMatches()) {
                applicationExitApproved = false
                applicationExitBasis.clear()
                return true
            }
        }
        if (!applicationExitBasisMatches() || sessions.size != windows.size) { return true }
        for (index in 0..windows.size) {
            let (token, generation) = match (windows[index].composableWindow.applicationExitPreflight()) {
                case Some(value) => value
                case None => return true
            }
            if (token != sessions[index] || generation != generations[index]) { return true }
        }
        let reservedConnections = ArrayList<CjguiSharedOperationExternalConnection>()
        if (let Some(connection) <- externalConnection) {
            if (!connection.tryReserveApplicationExit()) {
                if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=external_reservation_blocked") }
                return true
            }
            reservedConnections.add(connection)
        }
        for (connection in hostExitConnections) {
            if (!connection.tryReserveApplicationExit()) {
                var index = reservedConnections.size - 1
                while (index >= 0) { reservedConnections[index].releaseApplicationExitReservation(); index -= 1 }
                if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=external_reservation_blocked") }
                return true
            }
            reservedConnections.add(connection)
        }
        let status = internalRendererExitCommit(sessions.toArray(), generations.toArray())
        if (closeLifecycleTraceEnabled) { traceCloseLifecycle("stage=batch_commit status=${status}") }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            var index = reservedConnections.size - 1
            while (index >= 0) { reservedConnections[index].releaseApplicationExitReservation(); index -= 1 }
            return true
        }
        deferredApplicationExit = false
        applicationExitCommitInProgress = true
        if (hostExitManaged) { hostExitNativeCommitted = true }
        // Close admission and mark every exact committed participant before
        // any public lifecycle callback can re-enter this application.
        deferredAuthorizedClose = true
        var retirementFailed = false
        for (index in 0..participants.size) {
            if (!participants[index].composableWindow.markCommittedApplicationExit(sessions[index])) {
                retirementFailed = true
                testCloseTraceValue = "application_exit_committed_retirement_identity_mismatch token=${sessions[index]}"
            }
        }
        finalizeApplicationExitLifecycle()
        for (index in 0..participants.size) {
            if (!participants[index].composableWindow.finishCommittedApplicationExit(sessions[index])) {
                retirementFailed = true
                testCloseTraceValue = "application_exit_committed_retirement_identity_mismatch token=${sessions[index]}"
            }
        }
        reapClosedEntries()
        for (connection in reservedConnections) { connection.finishCommittedApplicationExitReservation() }
        if (retirementFailed) {
            deferredAuthorizedClose = false
            applicationExitCommitInProgress = false
            return false
        }
        closeImmediately()
        applicationExitCommitInProgress = false
        return true
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
        } else if (deferredApplicationExit) {
            let _ = processApplicationExit()
        }
    }

    private func closeIfEmpty(): Unit {
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

    /// P2/C：推进本应用所有窗口的动效。每个窗口先采集一次最小平台状态，只有
    /// 系统“减少动态效果”、系统外观、窗口可见/最小化或应用主题策略真正变化时
    /// 才把动效策略推给该窗口；同值重复出现不重发，也不重建主题。返回是否有
    /// 任一窗口仍有活动动效。
    private func serviceWindowAnimations(): Bool {
        let now = MonoTime.now()
        var anyActive = false
        for (entry in windows) {
            if (closed) {
                break
            }
            if (!entry.composableWindow.isOpen()) {
                continue
            }
            servicePlatformStateFor(entry)
            if (entry.composableWindow.advanceAnimations(atTime: now)) {
                anyActive = true
            }
        }
        return anyActive
    }

    /// C：采集一个窗口的最小平台状态，仅在事实变化时把动效策略推给该窗口。
    /// 系统减少动效、窗口隐藏或最小化都会让该窗口确定收敛；恢复可见后回到系统
    /// 策略。同值重复采样不重发动效策略，避免每帧重建。
    private func servicePlatformStateFor(entry: CjguiMacosApplicationWindowEntry): Bool {
        let platformSpan = entry.composableWindow.beginOwnerTracePhase(65u32)
        try {
        let accentSpan = entry.composableWindow.beginOwnerTracePhase(74u32)
        let accentChanged = entry.composableWindow.observeSystemAccent()
        entry.composableWindow.endOwnerTracePhase(74u32, accentSpan)
        let motionSpan = entry.composableWindow.beginOwnerTracePhase(71u32)
        let reduceMotion = CjguiComposableUiPlatformFacts.reduceMotionEnabled()
        entry.composableWindow.endOwnerTracePhase(71u32, motionSpan)
        let appearanceSpan = entry.composableWindow.beginOwnerTracePhase(72u32)
        let colorScheme = CjguiComposableUiPlatformFacts.systemColorScheme()
        entry.composableWindow.endOwnerTracePhase(72u32, appearanceSpan)
        let visibilitySpan = entry.composableWindow.beginOwnerTracePhase(73u32)
        let visibility = cjguiMacosPublishedVisibility(entry.composableWindow, entry.platformStateTracker.accepted())
        let visible = visibility[0]
        let minimized = visibility[1]
        entry.composableWindow.endOwnerTracePhase(73u32, visibilitySpan)
        let changed = entry.platformStateTracker.observe(
            reduceMotion: reduceMotion,
            systemColorScheme: colorScheme,
            themePreference: selectedThemePreference,
            windowVisible: visible,
            windowMinimized: minimized
        )
        if (changed) {
            if (let Some(snapshot) <- entry.platformStateTracker.accepted()) {
                let _ = entry.composableWindow.setReduceMotionEnabled(snapshot.motionConverges())
                let _ = entry.composableWindow.offerPlatformColorScheme(snapshot.effectiveColorScheme())
            }
        }
        return changed || accentChanged
        } finally {
            entry.composableWindow.endOwnerTracePhase(65u32, platformSpan)
        }
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
    private let defaultOwnerTurnBudget = CjguiOwnerTurnBudget()
    private let legacyLoopIdentity: String
    private var ownsLegacyLoopReference = false
    private let exitApplication: ?CjguiMacosApplication
    private var exitWindowAdopted = false
    private var hostPumpingTurn = false
    private var externalConnection: ?CjguiSharedOperationExternalConnection
    // Additional endpoints keep their own pump and authorization. The Host
    // owns their final close before the AppKit loop is stopped.
    private let adoptedExternalConnections: ArrayList<CjguiSharedOperationExternalConnection>
    private var started: Bool
    private var closed: Bool
    /// C：本窗最小平台状态追踪器与主题策略。只有事实变化时才重发动效策略。
    private var platformStateTracker: CjguiComposableUiPlatformStateTracker
    private var selectedThemePreference: CjguiComposableUiThemePreference
    private var selectedAccentPreferenceToken: String = "system"

    public init(controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard(),
        exitDecisionProvider!: ?CjguiMacosApplicationExitDecisionProvider = None) {
        this.configuration = configuration
        this.composableWindow = CjguiComposableUiWindow(controller, configuration: configuration)
        this.legacyLoopIdentity = CjguiMacosApplicationIdentityAllocator.allocate()
        this.exitApplication = match (exitDecisionProvider) {
            case Some(provider) => Some(CjguiMacosApplication(maximumWindowCount: 1, exitDecisionProvider: Some(provider)))
            case None => None
        }
        if (exitDecisionProvider.isSome()) { this.composableWindow.enableDeferredHostCloseDecision() }
        this.composableWindow.installDefaultOwnerTurnBudget(defaultOwnerTurnBudget)
        this.externalConnection = None
        this.adoptedExternalConnections = ArrayList<CjguiSharedOperationExternalConnection>()
        this.started = false
        this.closed = false
        this.platformStateTracker = CjguiComposableUiPlatformStateTracker()
        this.selectedThemePreference = CjguiComposableUiThemePreference.SystemFollow
        if (let Some(application) <- this.exitApplication) { application.configureForHostExit() }
    }

    /// The framework window remains a Cangjie projection surface. Returning it
    /// permits an application to bind semantic commands or compose its optional
    /// external connection without exposing a native session token.
    public func window(): CjguiComposableUiWindow {
        return composableWindow
    }

    /// Experimental/macOS, same native lifecycle as Application and green button.
    public func requestFullScreen(enabled: Bool): Bool {
        return started && !closed && composableWindow.requestMacosFullScreen(enabled)
    }

    public func windowState(): ?CjguiMacosApplicationWindowState {
        return if (started && !closed) { composableWindow.macosSystemWindowState() } else { None }
    }

    /// C：应用选择的主题策略（token 形式）。固定浅色/深色优先于系统跟随；
    /// 未知 token 被拒并保持当前选择。
    public func setThemePreference(token: String): Bool {
        if (let Some(preference) <- CjguiComposableUiPlatformStateCodec.themePreferenceFromToken(token)) {
            selectedThemePreference = preference
            return true
        }
        return false
    }

    /// C：当前应用级主题策略。
    public func themePreference(): CjguiComposableUiThemePreference {
        return selectedThemePreference
    }

    public func setAccentPreference(token: String): Bool {
        if (CjguiComposableUiAccentPreference.fromToken(token).isNone()) { return false }
        selectedAccentPreferenceToken = token
        let _ = composableWindow.selectAccentPreference(token)
        return true
    }

    /// C：最近一次采集到的平台状态快照（未采集时为 None）。
    public func platformState(): ?CjguiComposableUiPlatformStateSnapshot {
        return platformStateTracker.accepted()
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
        for (adopted in adoptedExternalConnections) {
            if (refEq(adopted, connection)) { return false }
        }
        externalConnection = Some(connection)
        return true
    }

    /// Adopt shutdown ownership for an independently pumped external endpoint.
    /// The caller still owns its authorization, start and request pump. Up to
    /// four may be adopted before or after Host.start; rejection leaves the
    /// connection untouched and caller-owned.
    public func adoptExternalConnectionForClose(connection: CjguiSharedOperationExternalConnection): Bool {
        if (closed || adoptedExternalConnections.size >= 4 ||
            (started && !composableWindow.isOpen())) { return false }
        if (let Some(primary) <- externalConnection) {
            if (refEq(primary, connection)) { return false }
        }
        for (adopted in adoptedExternalConnections) {
            if (refEq(adopted, connection)) { return false }
        }
        if (let Some(application) <- exitApplication) {
            if (started && !application.adoptHostExitConnection(connection)) { return false }
        }
        adoptedExternalConnections.add(connection)
        return true
    }

    public func start(): Bool {
        if (closed) {
            return false
        }
        if (!configuration.isValid()) {
            close()
            return false
        }
        if (started) {
            return true
        }
        // The first frame consumes the current platform theme through the same
        // controller projection used by later host turns.
        let _ = servicePlatformState()
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
        if (let Some(application) <- exitApplication) {
            if (!application.adoptStartedHostWindow(composableWindow)) { close(); return false }
            exitWindowAdopted = true
        } else {
            if (!CjguiMacosApplicationLoopReferenceRegistry.retain(legacyLoopIdentity)) { close(); return false }
            ownsLegacyLoopReference = true
        }
        if (let Some(connection) <- externalConnection) {
            if (!connection.start()) { close(); return false }
            if (let Some(application) <- exitApplication) {
                if (!application.adoptHostExitConnection(connection)) { close(); return false }
            }
        }
        if (let Some(application) <- exitApplication) {
            for (connection in adoptedExternalConnections) {
                if (!application.adoptHostExitConnection(connection)) { close(); return false }
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

    /// C：采集本窗最小平台状态并在事实变化时把动效策略推给本窗。系统减少动效、
    /// 窗口隐藏或最小化都会让本窗确定收敛；恢复可见后回到系统策略。同值重复
    /// 采样不重发、不重建主题。返回是否发生变化。
    private func servicePlatformState(): Bool {
        let platformSpan = composableWindow.beginOwnerTracePhase(65u32)
        try {
        let accentSpan = composableWindow.beginOwnerTracePhase(74u32)
        let accentChanged = composableWindow.observeSystemAccent()
        composableWindow.endOwnerTracePhase(74u32, accentSpan)
        let motionSpan = composableWindow.beginOwnerTracePhase(71u32)
        let reduceMotion = CjguiComposableUiPlatformFacts.reduceMotionEnabled()
        composableWindow.endOwnerTracePhase(71u32, motionSpan)
        let appearanceSpan = composableWindow.beginOwnerTracePhase(72u32)
        let colorScheme = CjguiComposableUiPlatformFacts.systemColorScheme()
        composableWindow.endOwnerTracePhase(72u32, appearanceSpan)
        let visibilitySpan = composableWindow.beginOwnerTracePhase(73u32)
        let visibility = cjguiMacosPublishedVisibility(composableWindow, platformStateTracker.accepted())
        let visible = visibility[0]
        let minimized = visibility[1]
        composableWindow.endOwnerTracePhase(73u32, visibilitySpan)
        let changed = platformStateTracker.observe(
            reduceMotion: reduceMotion,
            systemColorScheme: colorScheme,
            themePreference: selectedThemePreference,
            windowVisible: visible,
            windowMinimized: minimized
        )
        if (changed) {
            if (let Some(snapshot) <- platformStateTracker.accepted()) {
                let _ = composableWindow.setReduceMotionEnabled(snapshot.motionConverges())
                let _ = composableWindow.offerPlatformColorScheme(snapshot.effectiveColorScheme())
            }
        }
        return changed || accentChanged
        } finally {
            composableWindow.endOwnerTracePhase(65u32, platformSpan)
        }
    }

    /// One bounded normal turn. The existing scheduler remains the only
    /// source of AppKit event waiting and optional external action pacing.
    public func pumpOneTurn(): Bool { return pumpTurn(16u32) }

    /// Event-driven counterpart of the compatibility bounded turn. A finite
    /// timeout remains an actual caller deadline, including measurement loops.
    public func pumpUntilWork(timeoutMs!: UInt32 = UInt32.Max): Bool { return pumpTurn(timeoutMs) }

    private func pumpTurn(maximumIdleWaitMs: UInt32): Bool {
        if (!started || closed || !composableWindow.isOpen()) {
            close()
            return false
        }
        if (exitApplication.isSome() && hostPumpingTurn) { return isOpen() }
        let budget = composableWindow.attachedOwnerTurnBudget().getOrThrow()
        let ownsTurn = !budget.isActive()
        if (ownsTurn && !budget.begin()) { throw Exception("owner_turn_unavailable") }
        if (let Some(application) <- exitApplication) {
            if (!application.beginHostExitTurn()) {
                if (ownsTurn) { budget.end() }
                return isOpen()
            }
            hostPumpingTurn = true
        }
        if (ownsTurn) { cjguiOwnerTraceBoundary(0u64,UInt64(budget.turnIdentity()),144u32,0u32,0u32,0u64,UInt64.Max) }
        try {
        // C：先采集本窗最小平台状态，只有事实变化时才重发动效策略；随后推进
        // 本窗动效。无活动动画时保持原有休眠。
        cjguiOwnerTraceBoundary(0u64, 0u64, 311u32, 0u32, 0u32, 0u64, UInt64.Max)
        let _ = servicePlatformState()
        cjguiOwnerTraceBoundary(0u64, 0u64, 312u32, 0u32, 0u32, 0u64, UInt64.Max)
        let _ = composableWindow.advanceAnimations(atTime: MonoTime.now())
        cjguiOwnerTraceBoundary(0u64, 0u64, 313u32, 0u32, 0u32, 0u64, UInt64.Max)
        let turn = if (let Some(connection) <- externalConnection) {
            CjguiComposableUiWindowTurnScheduler.pumpWithExternalInRound(composableWindow, connection,
                16u32, 16u32, maximumIdleWaitMs, ownsTurn)
        } else {
            CjguiComposableUiWindowTurnScheduler.pumpWithoutExternalInRound(composableWindow,
                16u32, maximumIdleWaitMs, ownsTurn)
        }
        if (let Some(application) <- exitApplication) {
            application.serviceHostExitAfterTurn(turn.windowPumpResult.didApplyHumanAction, turn.externalActionCount)
            let _ = composableWindow.serviceDeferredHostCloseDecision()
        }
        cjguiOwnerTraceBoundary(0u64, 0u64, 314u32, 0u32, 0u32, 0u64, UInt64.Max)
        cjguiOwnerTraceBoundary(0u64, 0u64, 315u32, 0u32, 0u32, 0u64, UInt64.Max)
        if (!composableWindow.isOpen()) {
            // An opt-in engine is still inside its guarded turn; its final
            // Host cleanup runs after that guard is released in finally.
            if (exitApplication.isNone()) { close() }
            return false
        }
        cjguiOwnerTraceBoundary(0u64, 0u64, 316u32, 0u32, 0u32, 0u64, UInt64.Max)
        return true
        } finally {
            if (let Some(application) <- exitApplication) {
                application.endHostExitTurn()
                hostPumpingTurn = false
                if (!composableWindow.isOpen() && !closed) { close() }
            }
            if (ownsTurn) {
                budget.end()
                cjguiOwnerTraceBoundary(0u64,UInt64(budget.turnIdentity()),145u32,0u32,0u32,0u64,UInt64.Max)
            }
        }
    }

    public func isOpen(): Bool {
        return started && !closed && composableWindow.isOpen()
    }

    /// Request the application-owned local close decision without reaching
    /// into AppKit. With an exit provider, true means admitted for processing
    /// after the original input settles, not that the window has closed.
    /// Without a provider the legacy synchronous result is unchanged.
    public func requestClose(): Bool {
        if (!isOpen()) {
            return false
        }
        if (!composableWindow.requestCloseFromApplication()) {
            return false
        }
        // Opt-in local close is settled by the original Host pump before its
        // controller policy; legacy hosts keep the synchronous contract.
        if (exitApplication.isSome()) { return true }
        close()
        return true
    }

    /// Request an application-level exit through the explicitly supplied
    /// provider. A true result means accepted for processing, not committed.
    public func requestApplicationExit(): Bool {
        if (!isOpen()) { return false }
        return match (exitApplication) {
            case Some(application) => application.requestApplicationExit()
            case None => false
        }
    }

    /// Revoke a pending application-level request; local window-close requests
    /// remain independent. A consumer may suppress its own cancellation hook
    /// when it has already cleared the corresponding business approval.
    public func cancelPendingApplicationExit(notifyProvider!: Bool = true): Unit {
        if (let Some(application) <- exitApplication) {
            application.cancelPendingApplicationExit(notifyProvider: notifyProvider)
        }
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
        if (let Some(application) <- exitApplication) {
            application.close()
            if (!exitWindowAdopted) { composableWindow.close() }
        } else { composableWindow.close() }
        if (composableWindow.isOpen()) {
            // The native session still owns its scene and may be waiting for
            // an original present ticket or a legal owner thread. Keep both
            // external endpoints and the loop reference until closure commits.
            return
        }
        closed = true
        // A native close can stop NSApplication.run as soon as the window is
        // retired. Close independently pumped endpoints first, while their
        // transport owner and the process loop are still live.
        var index = adoptedExternalConnections.size - 1
        while (index >= 0) {
            adoptedExternalConnections[index].close()
            index -= 1
        }
        adoptedExternalConnections.clear()
        if (let Some(connection) <- externalConnection) {
            connection.close()
        }
        externalConnection = None
        let partialStart = !started
        started = false
        if (ownsLegacyLoopReference) {
            ownsLegacyLoopReference = false
            if (CjguiMacosApplicationLoopReferenceRegistry.release(legacyLoopIdentity)) {
                CjguiMacosApplicationHost.stopApplicationLoop()
            } else {
                cjguiNotifySchedulingWork()
            }
        } else if (partialStart && CjguiMacosApplicationLoopReferenceRegistry.isEmpty()) {
            CjguiMacosApplicationHost.stopApplicationLoop()
        }
    }
}
