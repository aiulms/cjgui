package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.random.*
import std.sync.*
import std.time.*

/// Public normalized pointer phases. Coordinates are logical layout points,
/// never native event objects. A controller receives them through its normal
/// `applyUiEvent` path and owns the resulting business/local state.
public let CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN: Int64 = 37
public let CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE: Int64 = 38
public let CJGUI_COMPOSABLE_UI_EVENT_POINTER_END: Int64 = 39
public let CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL: Int64 = 40

// This identifier is deliberately separate from the renderer's session token:
// clients may compare it in a window projection, but it grants no native
// operation.  The process nonce prevents a restarted/rebound endpoint from
// reusing a prior window name, while the locked counter makes concurrent
// windows and reopened instances distinct in one process.
private class CjguiComposableUiWindowSessionIdentityAllocator {
    private static let allocationLock = Mutex()
    private static let processNonce = Random().nextUInt64()
    private static var nextWindowGeneration: Int64 = 1

    public static func allocate(): String {
        return synchronized(CjguiComposableUiWindowSessionIdentityAllocator.allocationLock) {
            let generation = CjguiComposableUiWindowSessionIdentityAllocator.nextWindowGeneration
            CjguiComposableUiWindowSessionIdentityAllocator.nextWindowGeneration += 1
            return "cjgui_window_${CjguiComposableUiWindowSessionIdentityAllocator.processNonce}_${generation}"
        }
    }
}

/// Intent derived from one node in the most recently rendered scene. The
/// window refuses an event whose projection version or array target no longer
/// matches, so an external reorder/delete cannot retarget queued input.
public class CjguiComposableUiEvent {
    public let node: CjguiComposableUiLayoutNode
    public let eventKind: Int64
    public let text: String
    public let selectionStart: Int64
    public let selectionEnd: Int64
    public let projectionVersion: Int64
    public let pointerX: Int64
    public let pointerY: Int64
    public init(node: CjguiComposableUiLayoutNode, eventKind: Int64, text: String, selectionStart: Int64,
        selectionEnd: Int64, projectionVersion: Int64, pointerX!: Int64 = 0, pointerY!: Int64 = 0) {
        this.node = node
        this.eventKind = eventKind
        this.text = text
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.projectionVersion = projectionVersion
        this.pointerX = pointerX
        this.pointerY = pointerY
    }
}

public class CjguiComposableUiDispatchResult {
    public let didApply: Bool
    public let shouldClose: Bool
    public init(didApply: Bool, shouldClose!: Bool = false) {
        this.didApply = didApply
        this.shouldClose = shouldClose
    }
}

/// Experimental consumer boundary. Business state, field validation,
/// authorization and external operations remain with the application domain;
/// this controller only supplies a projection and routes a stable UI intent.
public interface CjguiComposableUiController {
    /// Monotonically advance for every renderer-visible declaration change:
    /// content, hierarchy, style, resource identity and local UI state. It is
    /// a cheap invalidation hint, not a business-content version. `refresh()`
    /// remains an explicit conservative rebuild for compatibility.
    func uiSceneVersion(): Int64
    func buildUi(): CjguiComposableUiNode
    func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult
    /// A queued intent no longer identifies a live rendered target. The
    /// consumer must surface this to the human rather than silently dropping
    /// keystrokes after an external delete/reorder.
    func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult
    func requestWindowClose(): CjguiComposableUiDispatchResult
}

/// Optional invalidation boundary for a captured continuous control. A
/// controller may expose an owner-scoped revision for one pointer target so
/// unrelated scene changes (for example a different document or status row)
/// do not revoke a live drag. The returned revision must advance whenever an
/// independently accepted write changes that target's owner truth. Controllers
/// that do not implement this interface retain the conservative whole-scene
/// invalidation policy.
public interface CjguiComposableUiPointerCaptureVersionProvider {
    func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64
}

/// Optional public transaction boundary for a controller that owns keyed
/// component identities and semantic command declarations. The window calls
/// it around one ordinary build/layout/native-present cycle. Implementers keep
/// domain state outside this API: it carries only candidate component identity
/// and command declarations, never native handles or application callbacks.
public interface CjguiComposableUiSceneRefreshParticipant {
    func beginSceneRefresh(): Bool
    func prepareSceneRefresh(): Bool
    func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand>
    func commitSceneRefresh(): Unit
    func rollbackSceneRefresh(): Unit
}

public class CjguiComposableUiWindowPumpResult {
    public let isOpen: Bool
    public let didApplyHumanAction: Bool
    public let nativeStatus: Int32
    public let displayedSceneVersion: Int64
    public init(isOpen: Bool, didApplyHumanAction: Bool, nativeStatus: Int32, displayedSceneVersion: Int64) {
        this.isOpen = isOpen
        this.didApplyHumanAction = didApplyHumanAction
        this.nativeStatus = nativeStatus
        this.displayedSceneVersion = displayedSceneVersion
    }
}

/// One ordinary application-loop turn. It records only scheduling facts for
/// the caller; all controller, native and domain state remains with its
/// established owner.
public class CjguiComposableUiWindowTurnResult {
    public let externalActionCount: Int64
    public let eventWaitBudgetMs: UInt32
    public let elapsedBeforeEventWaitMs: Int64
    public let windowPumpResult: CjguiComposableUiWindowPumpResult

    public init(
        externalActionCount: Int64,
        eventWaitBudgetMs: UInt32,
        elapsedBeforeEventWaitMs: Int64,
        windowPumpResult: CjguiComposableUiWindowPumpResult
    ) {
        this.externalActionCount = externalActionCount
        this.eventWaitBudgetMs = eventWaitBudgetMs
        this.elapsedBeforeEventWaitMs = elapsedBeforeEventWaitMs
        this.windowPumpResult = windowPumpResult
    }
}

/// Stateless owner-side pacing for normal composable windows. It performs no
/// background scheduling and never splits an already-started domain action:
/// the wall-clock budget is checked only between complete external actions,
/// then the remaining time belongs to AppKit's bounded native event wait.
public class CjguiComposableUiWindowTurnScheduler {
    public static func pumpWithoutExternal(
        window: CjguiComposableUiWindow,
        turnBudgetMs!: UInt32 = 16u32
    ): CjguiComposableUiWindowTurnResult {
        let started = MonoTime.now()
        let _ = window.refreshIfNeeded()
        return finishTurn(window, started, 0, turnBudgetMs)
    }

    public static func pumpWithExternal(
        window: CjguiComposableUiWindow,
        connection: CjguiSharedOperationExternalConnection,
        maximumExternalActions!: UInt32 = 16u32,
        turnBudgetMs!: UInt32 = 16u32
    ): CjguiComposableUiWindowTurnResult {
        let started = MonoTime.now()
        var externalActionCount: Int64 = 0
        while (externalActionCount < Int64(maximumExternalActions)) {
            // Do not start another action after the turn budget is consumed;
            // a claimed action remains whole and retains its normal owner.
            if (externalActionCount > 0 && elapsedMs(started) >= Int64(turnBudgetMs)) {
                break
            }
            if (!connection.pump(0u32)) {
                break
            }
            externalActionCount += 1
        }
        if (connection.consumeWindowRefreshRequest()) {
            window.requestRefresh()
        }
        let _ = window.refreshIfNeeded()
        return finishTurn(window, started, externalActionCount, turnBudgetMs)
    }

    private static func finishTurn(
        window: CjguiComposableUiWindow,
        started: MonoTime,
        externalActionCount: Int64,
        turnBudgetMs: UInt32
    ): CjguiComposableUiWindowTurnResult {
        let elapsed = elapsedMs(started)
        let waitBudget: UInt32 = if (elapsed >= Int64(turnBudgetMs)) {
            0u32
        } else {
            UInt32(Int64(turnBudgetMs) - elapsed)
        }
        let result = window.pump(waitBudget)
        return CjguiComposableUiWindowTurnResult(
            externalActionCount,
            waitBudget,
            elapsed,
            result
        )
    }

    private static func elapsedMs(started: MonoTime): Int64 {
        return (MonoTime.now() - started).toMilliseconds()
    }
}

/// Experimental normalized shortcut declaration. Only Command chords are
/// accepted in this first public slice: plain/control-only input remains with
/// the platform text service, while option/shift may refine a Command chord.
/// `encoded()` is an internal wire value, not a platform object or callback.
public class CjguiComposableUiShortcut {
    public let key: String
    public let usesCommand: Bool
    public let usesShift: Bool
    public let usesOption: Bool
    public let usesControl: Bool

    public init(key: String, usesCommand!: Bool = true, usesShift!: Bool = false, usesOption!: Bool = false,
        usesControl!: Bool = false) {
        this.key = key
        this.usesCommand = usesCommand
        this.usesShift = usesShift
        this.usesOption = usesOption
        this.usesControl = usesControl
    }

    public func isValid(): Bool {
        return usesCommand && key.size == 1
    }

    public func encoded(): String {
        var value = "shortcut:"
        if (usesControl) {
            value += "control+"
        }
        if (usesOption) {
            value += "option+"
        }
        if (usesShift) {
            value += "shift+"
        }
        if (usesCommand) {
            value += "command+"
        }
        return value + key
    }
}

/// Experimental semantic command bound by an application to one existing
/// interactive control. The command id is stable application vocabulary;
/// availability and optional scope are resolved against the accepted Cangjie
/// scene when the gesture arrives. The native side never receives a business
/// callback or action name.
public class CjguiComposableUiCommand {
    public let id: String
    public let targetNodeId: Int64
    public let shortcut: CjguiComposableUiShortcut
    /// Empty means global. A non-empty value must equal the currently focused
    /// Cangjie input scope, so a covered base command cannot bypass a layer.
    public let focusScopeId: String

    public init(id: String, targetNodeId: Int64, shortcut: CjguiComposableUiShortcut, focusScopeId!: String = "") {
        this.id = id
        this.targetNodeId = targetNodeId
        this.shortcut = shortcut
        this.focusScopeId = focusScopeId
    }

    public func isValid(): Bool {
        return id.size > 0 && targetNodeId >= 0 && shortcut.isValid()
    }
}

/// Scalar view of a renderer-owned image preparation. The Cangjie UI remains
/// the source of the requested path/id/version; this exposes only whether the
/// current session has an asynchronous resource ready, loading, busy, or failed.
public class CjguiComposableUiImageResourceStatus {
    public let state: String
    public let nativeStatus: Int32
    public init(state: String, nativeStatus: Int32) {
        this.state = state
        this.nativeStatus = nativeStatus
    }
}

/// Internal record retaining only a public declaration. It never owns an
/// application operation; resolution returns the current scene node so menu,
/// keyboard and accessibility still enter the controller through event 27.
private class CjguiComposableUiWindowCommandBinding {
    public let declaration: CjguiComposableUiCommand
    public init(declaration: CjguiComposableUiCommand) {
        this.declaration = declaration
    }
}

/// Normal macOS window consuming only Cangjie-computed generic scene nodes.
/// The native bridge sees neither consumer field names nor business command
/// branches; it receives copied geometry/style/semantics and returns a
/// bounded FIFO event with the rendered projection version.
public class CjguiComposableUiWindow <: CjguiSharedOperationWindowProjectionProvider & CjguiSharedOperationWindowProgressProvider {
    private let controller: CjguiComposableUiController
    private let configuration: CjguiMacosApplicationWindowConfiguration
    private var sessionToken: UInt64
    private var isWindowOpen: Bool
    private var lastNativeStatus: Int32
    private var renderedRoot: CjguiComposableUiNode
    private var renderedScene: CjguiComposableUiScene
    // External context can advance without a Metal submission when only
    // containment changes. Native FIFO intents must instead resolve against
    // the last scene that native actually displayed.
    private var nativeInputScene: CjguiComposableUiScene
    private var nextProjectionVersion: Int64
    // `refreshIfNeeded` consults this Cangjie-owned UI revision plus the
    // native resize revision before it asks the controller to build/layout.
    // It never substitutes a domain/content-only version for that contract.
    private var lastControllerSceneVersion: Int64
    private var lastViewportResizeVersion: UInt64
    private var lastResourceCompletionVersion: UInt64
    // Failed candidates must retain the last successful conditions above for
    // truth, while separately remembering the condition already attempted.
    // Otherwise the same v2/resize delta repeatedly looks new after failure.
    private var lastAttemptedControllerSceneVersion: Int64
    private var lastAttemptedViewportResizeVersion: UInt64
    private var lastAttemptedResourceCompletionVersion: UInt64
    private var refreshRequested: Bool
    private var pendingRefreshReason: String
    private var lastNativeFailure: String
    private var windowSessionIdentity: String
    private var acceptedSceneVersion: Int64
    private var submittedSceneVersion: Int64
    private var submittedFrameIndex: Int64
    private var observedMetalCompletionFrameIndex: Int64
    private var observedMetalFailureFrameIndex: Int64
    private var observedMetalGpuDurationMicros: Int64
    private var overlayDrawnSceneVersion: Int64
    private var buildPassCount: Int64
    private var layoutPassCount: Int64
    private var nativeSubmissionCount: Int64
    /// Most-recent projection timings are diagnostics of the real normal
    /// window path. They do not describe domain latency or pixel visibility.
    private var lastBuildElapsedMs: Int64
    private var lastLayoutElapsedMs: Int64
    private var lastNativeMeasurementElapsedMs: Int64
    private var lastNativeStageAndSubmitElapsedMs: Int64
    private var lastNativeMeasurementCallCount: Int64
    private var lastLayoutReuseHitCount: Int64
    private var lastLayoutReuseMissCount: Int64
    private var lastLayoutReuseRevalidationNodeCount: Int64
    private var lastLayoutReuseReplayedNodeCount: Int64
    private var lastLayoutReuseEntryCount: Int64
    private var focusedNodeId: Int64
    private var focusedResourceId: Int64
    private var focusedNodeKind: Int64
    private var focusedSelectionStart: Int64
    private var focusedSelectionEnd: Int64
    // A local edit that the domain owner accepted can retain the already-live
    // NSTextStorage for one projection. This hint is cleared only after that
    // projection commits, so an external replacement cannot be masked.
    private var pendingLocalTextNodeId: Int64
    private var pendingLocalTextResourceId: Int64
    private var pendingLocalTextNodeKind: Int64
    private var pendingLocalTextValue: String
    // One immediately preceding text generation can arrive while its
    // successor scene is being assembled.  Retain only the owner-accepted
    // value/identity needed to distinguish that local continuation from an
    // external replacement of the same field.
    private var localTextContinuationNodeId: Int64
    private var localTextContinuationResourceId: Int64
    private var localTextContinuationNodeKind: Int64
    private var localTextContinuationValue: String
    // The continuation is an owner-approved handoff, not merely a matching
    // native scene.  A separately arriving external write can preserve the
    // same node/value while advancing the controller's durable revision, so
    // retain that revision as part of the one-event capability.
    private var localTextContinuationOwnerVersion: Int64
    // Pointer capture is deliberately limited to one stable node identity in
    // this window session.  It carries no application value: the controller
    // remains the owner of pane size/slider value and decides each phase.
    private var pointerCaptureNode: CjguiComposableUiLayoutNode
    private var pointerCaptureOwnerVersion: Int64
    // A modal-layer transition changes the valid input scope even when the
    // captured control remains in the next projection.  Preserve the modal
    // identity from pointer-down so a newly opened/closed dialog cannot let
    // that old sequence continue through the underlying control.
    private var pointerCaptureModalLayerId: String
    private var pointerCaptureActive: Bool
    private var pointerCaptureX: Int64
    private var pointerCaptureY: Int64
    private var interactionVersion: Int64
    private var activeModalLayerId: String
    private var modalFocusRestoreNodeId: Int64
    // Layer focus restoration is semantic-tree state, not an AppKit menu
    // facility.  It covers a nested anchored menu disappearing while its
    // dialog remains, as well as the outer modal itself closing.
    private var activeLayerIds: ArrayList<String>
    private var activeLayerRestoreNodeIds: ArrayList<Int64>
    // The list is a replaceable declaration set, not an append-only native
    // registration. Native only ever sees normalized key input; Cangjie owns
    // target, focus policy and lifecycle.
    private var commandBindings: ArrayList<CjguiComposableUiWindowCommandBinding>
    // One renderer-bound measurer per open native session. Recreating this on
    // every refresh turns external read-only observation into repeated AppKit
    // shaping work and defeats the cache's safety bound.
    private var textMeasurer: CjguiInternalRendererTextMeasurer
    // Per-native-session, Cangjie-only derived layout cache. It retains no
    // controller/domain object and is recreated on a new session so stale
    // geometry, clip or input scopes cannot cross a generation boundary.
    private var layoutReuseCache: CjguiComposableUiLayoutReuseCache
    // Scoped component IDs belong to this window's candidate transaction.
    // They are neither application data nor native handles, and are cleared
    // whenever this window session ends.
    private let identityRegistry: CjguiComposableUiIdentityRegistry

    public init(
        controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()
    ) {
        this.controller = controller
        this.configuration = configuration
        this.sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        this.isWindowOpen = false
        this.lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        this.renderedRoot = cjguiComposableVertical(-1, "inactive-window", CjguiComposableUiStyle())
        this.renderedScene = CjguiComposableUiScene(0, CjguiComposableUiRect(0, 0, 0, 0),
            ArrayList<CjguiComposableUiLayoutNode>())
        this.nativeInputScene = CjguiComposableUiScene(0, CjguiComposableUiRect(0, 0, 0, 0),
            ArrayList<CjguiComposableUiLayoutNode>())
        this.nextProjectionVersion = 0
        this.lastControllerSceneVersion = -1
        this.lastViewportResizeVersion = 0u64
        this.lastResourceCompletionVersion = 0u64
        this.lastAttemptedControllerSceneVersion = -1
        this.lastAttemptedViewportResizeVersion = 0u64
        this.lastAttemptedResourceCompletionVersion = 0u64
        this.refreshRequested = false
        this.pendingRefreshReason = "none"
        this.lastNativeFailure = "none"
        this.windowSessionIdentity = ""
        this.acceptedSceneVersion = 0
        this.submittedSceneVersion = -1
        this.submittedFrameIndex = -1
        this.observedMetalCompletionFrameIndex = -1
        this.observedMetalFailureFrameIndex = -1
        this.observedMetalGpuDurationMicros = -1
        this.overlayDrawnSceneVersion = -1
        this.buildPassCount = 0
        this.layoutPassCount = 0
        this.nativeSubmissionCount = 0
        this.lastBuildElapsedMs = 0
        this.lastLayoutElapsedMs = 0
        this.lastNativeMeasurementElapsedMs = 0
        this.lastNativeStageAndSubmitElapsedMs = 0
        this.lastNativeMeasurementCallCount = 0
        this.lastLayoutReuseHitCount = 0
        this.lastLayoutReuseMissCount = 0
        this.lastLayoutReuseRevalidationNodeCount = 0
        this.lastLayoutReuseReplayedNodeCount = 0
        this.lastLayoutReuseEntryCount = 0
        this.focusedNodeId = -1
        this.focusedResourceId = -1
        this.focusedNodeKind = -1
        this.focusedSelectionStart = 0
        this.focusedSelectionEnd = 0
        this.pendingLocalTextNodeId = -1
        this.pendingLocalTextResourceId = -1
        this.pendingLocalTextNodeKind = -1
        this.pendingLocalTextValue = ""
        this.localTextContinuationNodeId = -1
        this.localTextContinuationResourceId = -1
        this.localTextContinuationNodeKind = -1
        this.localTextContinuationValue = ""
        this.localTextContinuationOwnerVersion = -1
        this.pointerCaptureNode = CjguiComposableUiLayoutNode.missing()
        this.pointerCaptureOwnerVersion = -1
        this.pointerCaptureModalLayerId = ""
        this.pointerCaptureActive = false
        this.pointerCaptureX = 0
        this.pointerCaptureY = 0
        this.interactionVersion = 0
        this.activeModalLayerId = ""
        this.modalFocusRestoreNodeId = -1
        this.activeLayerIds = ArrayList<String>()
        this.activeLayerRestoreNodeIds = ArrayList<Int64>()
        this.commandBindings = ArrayList<CjguiComposableUiWindowCommandBinding>()
        this.textMeasurer = CjguiInternalRendererTextMeasurer(CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN)
        this.layoutReuseCache = CjguiComposableUiLayoutReuseCache()
        this.identityRegistry = CjguiComposableUiIdentityRegistry()
    }

    public func start(): Bool {
        if (isWindowOpen) {
            return true
        }
        if (!configuration.isValid()) {
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
            return false
        }
        let created = internalRendererCreate(
            CjguiInternalRendererConfig(
                windowWidth: configuration.width,
                windowHeight: configuration.height,
                clearColorRed: 0.08,
                clearColorGreen: 0.16,
                clearColorBlue: 0.20,
                clearColorAlpha: 1.0
            )
        )
        if (created.status != CJGUI_INTERNAL_RENDERER_OK || created.token ==
            CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            lastNativeStatus = created.status
            return false
        }
        sessionToken = created.token
        isWindowOpen = true
        lastNativeStatus = internalRendererSetWindowTitle(sessionToken, configuration.title)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            discardSession()
            return false
        }
        windowSessionIdentity = CjguiComposableUiWindowSessionIdentityAllocator.allocate()
        // A reopened native session owns no prior scene snapshot. Retaining
        // the old Cangjie scene here could make `sameRenderedScene` suppress
        // the initial staging/submission into an empty new Metal view.
        renderedRoot = cjguiComposableVertical(-1, "inactive-window", CjguiComposableUiStyle())
        renderedScene = CjguiComposableUiScene(0, CjguiComposableUiRect(0, 0, 0, 0),
            ArrayList<CjguiComposableUiLayoutNode>())
        nativeInputScene = CjguiComposableUiScene(0, CjguiComposableUiRect(0, 0, 0, 0),
            ArrayList<CjguiComposableUiLayoutNode>())
        lastNativeFailure = "none"
        pendingRefreshReason = "none"
        acceptedSceneVersion = 0
        submittedSceneVersion = -1
        submittedFrameIndex = -1
        observedMetalCompletionFrameIndex = -1
        observedMetalFailureFrameIndex = -1
        observedMetalGpuDurationMicros = -1
        overlayDrawnSceneVersion = -1
        buildPassCount = 0
        layoutPassCount = 0
        nativeSubmissionCount = 0
        lastBuildElapsedMs = 0
        lastLayoutElapsedMs = 0
        lastNativeMeasurementElapsedMs = 0
        lastNativeStageAndSubmitElapsedMs = 0
        lastNativeMeasurementCallCount = 0
        lastLayoutReuseHitCount = 0
        lastLayoutReuseMissCount = 0
        lastLayoutReuseRevalidationNodeCount = 0
        lastLayoutReuseReplayedNodeCount = 0
        lastLayoutReuseEntryCount = 0
        lastControllerSceneVersion = -1
        lastViewportResizeVersion = 0u64
        lastResourceCompletionVersion = 0u64
        lastAttemptedControllerSceneVersion = -1
        lastAttemptedViewportResizeVersion = 0u64
        lastAttemptedResourceCompletionVersion = 0u64
        pointerCaptureNode = CjguiComposableUiLayoutNode.missing()
        pointerCaptureOwnerVersion = -1
        pointerCaptureModalLayerId = ""
        pointerCaptureActive = false
        pointerCaptureX = 0
        pointerCaptureY = 0
        textMeasurer = CjguiInternalRendererTextMeasurer(sessionToken)
        layoutReuseCache = CjguiComposableUiLayoutReuseCache()
        identityRegistry.clear()
        requestRefresh()
        if (!refreshIfNeeded()) {
            discardSession();
            return false
        }
        return true
    }

    /// Compatibility entry point: request one explicit conservative rebuild.
    /// A caller that merely observes state should instead use
    /// `refreshIfNeeded`, which performs no build/layout/native submission
    /// while the Cangjie UI revision and native viewport are unchanged.
    public func refresh(): Bool {
        requestRefresh()
        return refreshIfNeeded()
    }

    /// Mark a real external domain/style change for one coalesced refresh.
    /// Repeated marks before `refreshIfNeeded` intentionally stay one pass.
    public func requestRefresh() {
        if (isWindowOpen) {
            refreshRequested = true
        }
    }

    /// Bounded explicit recovery for a retained, temporarily unavailable
    /// renderer. It never loops or schedules background retries.
    public func retryPendingRefresh(): Bool {
        requestRefresh()
        return refreshIfNeeded()
    }

    private func imageResourceStatusFromNative(result: InternalRendererImageResourceResult): CjguiComposableUiImageResourceStatus {
        if (result.status != CJGUI_INTERNAL_RENDERER_OK) {
            return CjguiComposableUiImageResourceStatus("failed", result.status)
        }
        let state = if (result.stateCode == 2u32) {
            "ready"
        } else if (result.stateCode == 1u32) {
            "loading"
        } else if (result.stateCode == 3u32) {
            "failed"
        } else if (result.stateCode == 4u32) {
            "busy"
        } else {
            "unrequested"
        }
        return CjguiComposableUiImageResourceStatus(state, result.status)
    }

    /// Explicitly starts a bounded preparation before a component references
    /// it. This does not schedule a timer or create a second state machine;
    /// the next ordinary host turn notices a completed resource version.
    public func prepareImageResource(resourcePath: String, resourceId: String, resourceVersion: Int64): CjguiComposableUiImageResourceStatus {
        if (!isWindowOpen) {
            return CjguiComposableUiImageResourceStatus("failed", CJGUI_INTERNAL_RENDERER_INVALID_SESSION)
        }
        return imageResourceStatusFromNative(
            internalRendererPrepareComposableImageResource(sessionToken, resourcePath, resourceId, resourceVersion))
    }

    /// Reads existing preparation state only. It does not start I/O, redraw,
    /// or mutate Cangjie application state.
    public func imageResourceStatus(resourcePath: String, resourceId: String, resourceVersion: Int64): CjguiComposableUiImageResourceStatus {
        if (!isWindowOpen) {
            return CjguiComposableUiImageResourceStatus("failed", CJGUI_INTERNAL_RENDERER_INVALID_SESSION)
        }
        return imageResourceStatusFromNative(
            internalRendererComposableImageResourceState(sessionToken, resourcePath, resourceId, resourceVersion))
    }

    /// Cheap invalidation check used from ordinary application loops. It reads
    /// only the controller's declared UI revision and native viewport until a
    /// real change, resize, or explicit request requires one full projection.
    public func refreshIfNeeded(): Bool {
        if (!isWindowOpen) {
            return false
        }
        let viewport = internalRendererComposableViewport(sessionToken)
        if (viewport.status != CJGUI_INTERNAL_RENDERER_OK || viewport.width == 0u32 || viewport.height == 0u32) {
            return noteRefreshFailure(if (viewport.status == CJGUI_INTERNAL_RENDERER_OK) {
                CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
            } else {
                viewport.status
            })
        }
        let declaredVersion = controller.uiSceneVersion()
        if (!refreshRequested && pendingRefreshReason != "none" && declaredVersion == lastAttemptedControllerSceneVersion &&
            viewport.resizeVersion == lastAttemptedViewportResizeVersion && viewport.resourceCompletionVersion ==
            lastAttemptedResourceCompletionVersion) {
            return false
        }
        if (!refreshRequested && renderedScene.version > 0 && declaredVersion == lastControllerSceneVersion &&
            viewport.resizeVersion == lastViewportResizeVersion && viewport.resourceCompletionVersion ==
            lastResourceCompletionVersion) {
            return true
        }
        lastAttemptedControllerSceneVersion = declaredVersion
        lastAttemptedViewportResizeVersion = viewport.resizeVersion
        lastAttemptedResourceCompletionVersion = viewport.resourceCompletionVersion
        return syncProjection(viewport, declaredVersion)
    }

    public func pump(timeoutMs: UInt32): CjguiComposableUiWindowPumpResult {
        if (!isWindowOpen) {
            return result(false, false)
        }
        var didApply = false
        var requiresProjection = false
        var waitMs = timeoutMs
        let drainBudget = CjguiComposableUiEventDrainBudget()
        // Consume the complete FIFO against its original rendered snapshot,
        // then publish once. Rebuilding after each event used to invalidate
        // later accepted keystrokes from that same displayed scene.
        while (drainBudget.consumeOne()) {
            let nativeEvent = internalRendererPumpEvent(sessionToken, waitMs)
            waitMs = 0u32
            lastNativeStatus = nativeEvent.status
            if (nativeEvent.eventKind == 1u32) {
                discardSession();
                return result(false, didApply)
            }
            if (nativeEvent.status != CJGUI_INTERNAL_RENDERER_OK) {
                if (!isRecoverableNativeStatus(nativeEvent.status)) {
                    discardSession();
                    return result(false, didApply)
                }
                let _ = noteRefreshFailure(nativeEvent.status)
                return result(true, didApply)
            }
            if (nativeEvent.eventKind == 0u32) {
                break
            }
            if (nativeEvent.eventKind == 11u32) {
                // Native refused a new interaction only after preserving the
                // accepted FIFO.  It is never a successful edit; give the
                // consumer an explicit retry-visible outcome.
                let rejection = controller.rejectUiEvent(11, 0)
                didApply = didApply || rejection.didApply
                if (rejection.shouldClose) {
                    close();
                    return result(false, didApply)
                }
                requiresProjection = true
            } else if (nativeEvent.eventKind == 24u32) {
                let closeResult = controller.requestWindowClose()
                didApply = didApply || closeResult.didApply
                if (closeResult.shouldClose) {
                    close();
                    return result(false, didApply)
                }
                requiresProjection = true
            } else if (nativeEvent.eventKind >= 37u32 && nativeEvent.eventKind <= 40u32) {
                let dispatch = dispatchPointerEvent(nativeEvent)
                didApply = didApply || dispatch.didApply
                if (dispatch.shouldClose) {
                    close()
                    return result(false, didApply)
                }
                // A pointer phase may change only controller-local visual
                // state.  Keep the ordinary coalesced projection path rather
                // than pushing a native scene from inside the event loop.
                requiresProjection = true
            } else if (nativeEvent.eventKind == 33u32) {
                // Platform-owned selection is view state, not a domain
                // action. A document consumer may translate this UTF-16
                // range at its UI boundary, but it must not turn a caret
                // move into an external operation or force a scene rebuild.
                let nodeId = Int64(nativeEvent.nodeId)
                let resolved = if (nativeEvent.nodeId == 0u64) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    nativeInputScene.resolveSelection(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                        Int64(nativeEvent.projectionVersion))
                }
                if (resolved.nodeId == nodeId) {
                    rememberInteraction(resolved, 33, Int64(nativeEvent.selectionStart), Int64(nativeEvent.selectionEnd))
                    let selection = controller.applyUiEvent(
                        CjguiComposableUiEvent(
                            resolved,
                            33,
                            "",
                            Int64(nativeEvent.selectionStart),
                            Int64(nativeEvent.selectionEnd),
                            Int64(nativeEvent.projectionVersion)
                        )
                    )
                    didApply = didApply || selection.didApply
                    if (selection.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                }
            } else if (nativeEvent.eventKind == 34u32) {
                let target = boundCommandTarget(
                    internalRendererFormEventText(sessionToken),
                    false,
                    Int64(nativeEvent.projectionVersion)
                )
                if (target.nodeId >= 0) {
                    let dispatch = applyBoundCommand(target, Int64(nativeEvent.projectionVersion))
                    didApply = didApply || dispatch.didApply
                    if (dispatch.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    requiresProjection = true
                }
            } else if (nativeEvent.eventKind == 35u32) {
                // Native recognizes only a list-navigation gesture and its
                // scroll-container target. Cangjie resolves the current
                // stable-key range, so a recycled/off-screen row cannot be
                // mistaken for the prior materialized index.
                let nodeId = Int64(nativeEvent.nodeId)
                let resolved = if (nativeEvent.nodeId == 0u64) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    nativeInputScene.resolveInput(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                        Int64(nativeEvent.projectionVersion))
                }
                if (resolved.nodeId == nodeId && (resolved.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA || ((resolved
                    .nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE || resolved.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) &&
                    (internalRendererFormEventText(sessionToken) == "left" ||
                    internalRendererFormEventText(sessionToken) == "right" ||
                    internalRendererFormEventText(sessionToken) == "up" ||
                    internalRendererFormEventText(sessionToken) == "down")))) {
                    let dispatch = controller.applyUiEvent(
                        CjguiComposableUiEvent(
                            resolved,
                            35,
                            internalRendererFormEventText(sessionToken),
                            0,
                            0,
                            Int64(nativeEvent.projectionVersion)
                        )
                    )
                    didApply = didApply || dispatch.didApply
                    if (dispatch.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    requiresProjection = true
                } else {
                    let rejection = controller.rejectUiEvent(35, nodeId)
                    didApply = didApply || rejection.didApply
                    if (rejection.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    requiresProjection = true
                }
            } else if ((nativeEvent.eventKind >= 27u32 && nativeEvent.eventKind <= 31u32) || nativeEvent.eventKind ==
                36u32) {
                let nodeId = Int64(nativeEvent.nodeId)
                let eventText = internalRendererFormEventText(sessionToken)
                let resolved = if (nativeEvent.nodeId == 0u64) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    nativeInputScene.resolveInput(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                        Int64(nativeEvent.projectionVersion))
                }
                let continuation = if (resolved.nodeId == nodeId) {
                    resolved
                } else {
                    resolveLocalTextContinuation(
                        Int64(nativeEvent.eventKind),
                        nodeId,
                        nativeEvent.resourceId,
                        Int64(nativeEvent.nodeKind),
                        eventText,
                        Int64(nativeEvent.projectionVersion)
                    )
                }
                if (continuation.nodeId == nodeId) {
                    rememberInteraction(continuation, Int64(nativeEvent.eventKind), Int64(nativeEvent.selectionStart),
                        Int64(nativeEvent.selectionEnd))
                    let dispatch = controller.applyUiEvent(
                        CjguiComposableUiEvent(
                            continuation,
                            Int64(nativeEvent.eventKind),
                            eventText,
                            Int64(nativeEvent.selectionStart),
                            Int64(nativeEvent.selectionEnd),
                            Int64(nativeEvent.projectionVersion)
                        )
                    )
                    didApply = didApply || dispatch.didApply
                    if (dispatch.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    if (nativeEvent.eventKind == 28u32 && dispatch.didApply && isEditableTextNodeKind(
                        continuation.nodeKind)) {
                        pendingLocalTextNodeId = continuation.nodeId
                        pendingLocalTextResourceId = continuation.resourceId
                        pendingLocalTextNodeKind = continuation.nodeKind
                        pendingLocalTextValue = eventText
                        localTextContinuationNodeId = continuation.nodeId
                        localTextContinuationResourceId = continuation.resourceId
                        localTextContinuationNodeKind = continuation.nodeKind
                        localTextContinuationValue = eventText
                        localTextContinuationOwnerVersion = controller.uiSceneVersion()
                    } else if (nativeEvent.eventKind == 31u32) {
                        // A focus transfer ends the narrow adapter handoff.
                        // Returning to a field later is a new interaction,
                        // never authority for a stale callback captured
                        // before the blur/re-focus sequence.
                        clearLocalTextContinuation()
                    }
                    requiresProjection = true
                } else {
                    let rejection = controller.rejectUiEvent(Int64(nativeEvent.eventKind), nodeId)
                    didApply = didApply || rejection.didApply
                    if (rejection.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    requiresProjection = true
                }
            } else if (nativeEvent.eventKind == 32u32) {
                requiresProjection = true
            }
        }
        if (requiresProjection) {
            requestRefresh()
            if (!refreshIfNeeded() && !isWindowOpen) {
                return result(false, didApply)
            }
        }
        return result(true, didApply)
    }

    public func close() {
        if (isWindowOpen) {
            let _ = internalRendererRequestClose(sessionToken)
        }
        discardSession()
    }
    /// Ask the controller through the same close decision used by a native
    /// window-close event. A rejection leaves the Cangjie projection open;
    /// acceptance closes its session without exposing a platform object.
    public func requestCloseFromApplication(): Bool {
        if (!isWindowOpen) {
            return false
        }
        let closeResult = controller.requestWindowClose()
        if (closeResult.shouldClose) {
            close()
            return true
        }
        if (closeResult.didApply) {
            requestRefresh()
        }
        return false
    }
    public func isOpen(): Bool {
        return isWindowOpen
    }
    public func nativeStatus(): Int32 {
        return lastNativeStatus
    }
    public func displayedSceneVersion(): Int64 {
        return renderedScene.version
    }
    /// Incremental compatibility declaration. Duplicate IDs and a matching
    /// shortcut *in the same focus scope* fail closed; mutually exclusive
    /// scopes may deliberately reuse one chord.
    public func declareCommand(command: CjguiComposableUiCommand): Bool {
        if (!command.isValid()) {
            return false
        }
        for (binding in commandBindings) {
            if (binding.declaration.id == command.id || (binding.declaration.shortcut.encoded() ==
                command.shortcut.encoded() && binding.declaration.focusScopeId == command.focusScopeId)) {
                return false
            }
        }
        commandBindings.add(CjguiComposableUiWindowCommandBinding(command))
        return true
    }
    /// Atomically replace bindings after a component composition changed. A
    /// failed candidate leaves the last accepted set intact. Callers use the
    /// scene already accepted by `refresh`; this prevents a new declaration
    /// from targeting a node that native has not accepted.
    public func replaceCommands(commands: ArrayList<CjguiComposableUiCommand>): Bool {
        if (!isWindowOpen || !commandsValidForAcceptedScene(commands)) {
            return false
        }
        replaceCommandBindings(commands)
        return true
    }
    /// Removing a component's declaration is explicit and bounded; a later
    /// mount can use the same business vocabulary only by declaring again.
    public func revokeCommand(commandId: String): Bool {
        var index: Int64 = 0
        while (index < commandBindings.size) {
            if (commandBindings[index].declaration.id == commandId) {
                commandBindings.remove(at: index);
                return true
            }
            index += 1
        }
        return false
    }
    /// Legacy convenience for the original document commands. It remains a
    /// declaration layer, not a native save/undo/redo callback contract.
    public func bindCommand(command: String, nodeId: Int64): Bool {
        let shortcut = if (command == "save") {
            CjguiComposableUiShortcut("s")
        } else if (command == "undo") {
            CjguiComposableUiShortcut("z")
        } else if (command == "redo") {
            CjguiComposableUiShortcut("z", usesShift: true)
        } else {
            CjguiComposableUiShortcut("")
        }
        return declareCommand(CjguiComposableUiCommand(command, nodeId, shortcut))
    }
    /// A composable menu or another Cangjie-owned semantic surface may use
    /// the same command declaration. It has the exact same target, scope and
    /// controller event as a keyboard chord; it never calls an application
    /// operation directly.
    public func invokeCommand(commandId: String): Bool {
        if (!isWindowOpen) {
            return false
        }
        let target = boundCommandTarget(commandId, true, -1)
        if (target.nodeId < 0) {
            return false
        }
        let dispatch = applyBoundCommand(target, nativeInputScene.version)
        if (dispatch.shouldClose) {
            close();
            return dispatch.didApply
        }
        requestRefresh()
        let _ = refreshIfNeeded()
        return dispatch.didApply
    }
    // Probe-only package seam. It is intentionally not public: ordinary
    // consumers receive no native session handle, while the direct runtime
    // probe can enqueue the same native FIFO events that production input
    // consumes and verify controller routing end-to-end.
    func testSessionToken(): UInt64 {
        return sessionToken
    }
    public func windowProjection(): CjguiSharedOperationWindowProjection {
        if (!isWindowOpen || renderedScene.version <= 0) {
            return CjguiSharedOperationWindowProjection.inactive()
        }
        observeDisplayProgress()
        let focused = renderedScene.nodeForId(focusedNodeId)
        let hasLiveFocusedIdentity = focused.nodeId == focusedNodeId && focused.resourceId == focusedResourceId &&
            focused.nodeKind == focusedNodeKind
        return CjguiComposableUiWindowProjectionBuilder.fromScene(
            renderedRoot,
            renderedScene,
            focusedNodeId: if (hasLiveFocusedIdentity) {
                focusedNodeId
            } else {
                -1
            },
            selectionStart: if (hasLiveFocusedIdentity) {
                focusedSelectionStart
            } else {
                0
            },
            selectionEnd: if (hasLiveFocusedIdentity) {
                focusedSelectionEnd
            } else {
                0
            },
            nativeSubmissionVersion: submittedSceneVersion,
            sessionIdentity: windowSessionIdentity,
            acceptedSceneVersion: acceptedSceneVersion,
            submittedSceneVersion: submittedSceneVersion,
            submittedFrameIndex: submittedFrameIndex,
            observedMetalCompletionFrameIndex: observedMetalCompletionFrameIndex,
            observedMetalFailureFrameIndex: observedMetalFailureFrameIndex,
            observedMetalGpuDurationMicros: observedMetalGpuDurationMicros,
            overlayDrawnSceneVersion: overlayDrawnSceneVersion,
            pendingRefreshReason: pendingRefreshReason,
            lastNativeFailure: lastNativeFailure,
            buildPassCount: buildPassCount,
            layoutPassCount: layoutPassCount,
            nativeSubmissionCount: nativeSubmissionCount,
            lastBuildElapsedMs: lastBuildElapsedMs,
            lastLayoutElapsedMs: lastLayoutElapsedMs,
            lastNativeMeasurementElapsedMs: lastNativeMeasurementElapsedMs,
            lastNativeStageAndSubmitElapsedMs: lastNativeStageAndSubmitElapsedMs,
            lastNativeMeasurementCallCount: lastNativeMeasurementCallCount,
            layoutReuseHitCount: lastLayoutReuseHitCount,
            layoutReuseMissCount: lastLayoutReuseMissCount,
            layoutReuseRevalidationNodeCount: lastLayoutReuseRevalidationNodeCount,
            layoutReuseReplayedNodeCount: lastLayoutReuseReplayedNodeCount,
            layoutReuseEntryCount: lastLayoutReuseEntryCount
        )
    }

    /// Compact observation path: it observes only already-published native
    /// completion and interaction scalars and emits no scene tree, field
    /// values, resource IDs, collection metadata, or text. Reading it cannot
    /// request a refresh.
    public func windowProgress(): CjguiSharedOperationWindowProgress {
        if (!isWindowOpen || renderedScene.version <= 0) {
            return CjguiSharedOperationWindowProgress.inactive()
        }
        observeDisplayProgress()
        let focused = renderedScene.nodeForId(focusedNodeId)
        let hasLiveFocusedIdentity = focused.nodeId == focusedNodeId && focused.resourceId == focusedResourceId &&
            focused.nodeKind == focusedNodeKind
        let focusedControlId = if (hasLiveFocusedIdentity) {
            focused.semanticId
        } else {
            "none"
        }
        let hasTextSelection = hasLiveFocusedIdentity && (focused.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT ||
            focused.nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT || focused.nodeKind ==
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        let activeLayerId = if (activeLayerIds.size > 0) {
            activeLayerIds[activeLayerIds.size - 1]
        } else {
            "none"
        }
        return CjguiSharedOperationWindowProgress(
            true,
            renderedScene.version,
            submittedSceneVersion,
            "unavailable",
            windowSessionIdentity,
            acceptedSceneVersion,
            submittedSceneVersion,
            submittedFrameIndex,
            observedMetalCompletionFrameIndex,
            observedMetalFailureFrameIndex,
            observedMetalGpuDurationMicros,
            overlayDrawnSceneVersion,
            pendingRefreshReason,
            lastNativeFailure,
            interactionVersion,
            focusedControlId,
            hasTextSelection,
            if (hasTextSelection) {
                focusedSelectionStart
            } else {
                0
            },
            if (hasTextSelection) {
                focusedSelectionEnd
            } else {
                0
            },
            activeLayerId
        )
    }

    private func observeDisplayProgress() {
        let progress = internalRendererComposableDisplayProgress(sessionToken)
        if (progress.status != CJGUI_INTERNAL_RENDERER_OK) {
            return
        }
        if (progress.submittedFrameIndex > 0u64) {
            submittedFrameIndex = Int64(progress.submittedFrameIndex)
        }
        if (progress.observedMetalCompletionFrameIndex > 0u64) {
            observedMetalCompletionFrameIndex = Int64(progress.observedMetalCompletionFrameIndex)
        }
        if (progress.observedMetalFailureFrameIndex > 0u64) {
            observedMetalFailureFrameIndex = Int64(progress.observedMetalFailureFrameIndex)
        }
        if (progress.observedMetalGpuDurationMicros >= 0) {
            observedMetalGpuDurationMicros = progress.observedMetalGpuDurationMicros
        }
        if (progress.overlayDrawnProjectionVersion > 0u64) {
            overlayDrawnSceneVersion = Int64(progress.overlayDrawnProjectionVersion)
        }
    }

    private func syncProjection(viewport: InternalRendererViewportResult, declaredVersion: Int64): Bool {
        // A participant prepares only a Cangjie candidate. It is deliberately
        // opened before buildUi, then either promoted with the accepted native
        // scene or rolled back on every early return below.
        let participant = controller as CjguiComposableUiSceneRefreshParticipant
        // A resize generation also advances for a same-point backing-scale
        // transition. AppKit text metrics may legitimately differ while the
        // logical bounds remain equal, so no per-session entry crosses it.
        if (viewport.resizeVersion != lastViewportResizeVersion) {
            layoutReuseCache = CjguiComposableUiLayoutReuseCache()
        }
        // `Exception` is a recoverable language-level failure, distinct from
        // fatal runtime errors.  A controller can legitimately reject a
        // malformed candidate this way; it must not strand a registry
        // transaction merely because buildUi or a participant hook unwound.
        // We intentionally do not catch `Error`/fatal failures here.
        // This becomes true at the first irreversible accepted-state write.
        // Usually that is after native present and the Cangjie input snapshot;
        // a semantic-only refresh has no native present, but updating its
        // Cangjie containment/command projection is equally irreversible.
        // A later callback failure cannot truthfully be reported as a failed
        // candidate, because one of those accepted views is already live.
        var acceptedCandidate = false
        try {
            if (let Some(value) <- participant) {
                if (!value.beginSceneRefresh()) {
                    return noteRefreshFailure(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
                }
            }
            if (!identityRegistry.beginCandidate()) {
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(identityRegistry.lastIssue())
            }
            let buildStarted = MonoTime.now()
            let declaredRoot = controller.buildUi()
            lastBuildElapsedMs = (MonoTime.now() - buildStarted).toMilliseconds()
            buildPassCount += 1
            let identityIssue = identityRegistry.resolveCandidate(declaredRoot)
            if (identityIssue.size > 0) {
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(identityIssue)
            }
            // Scoped resolution intentionally writes numeric IDs so a
            // participant can derive its ordinary command bindings from the
            // declaration it supplied. The rendered candidate is then a deep
            // Cangjie snapshot: another window may reuse that declaration but
            // cannot mutate this window's accepted projection or virtual rows.
            let root = declaredRoot.cloneForWindowCandidate()
            let candidateRootIssue = identityRegistry.replaceCandidateRoot(root)
            if (candidateRootIssue.size > 0) {
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(candidateRootIssue)
            }
            if (let Some(value) <- participant) {
                if (!value.prepareSceneRefresh()) {
                    return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
                }
            }
            let candidateVersion = if (nextProjectionVersion <= 0) {
                1
            } else {
                nextProjectionVersion + 1
            }
            let layoutStarted = MonoTime.now()
            textMeasurer.beginMeasurementPass()
            let layoutResult = CjguiComposableUiLayoutEngine.layoutWithMetrics(
                root,
                CjguiComposableUiRect(0, 0, Int64(viewport.width), Int64(viewport.height)),
                candidateVersion,
                textMeasurer,
                reuseCache: layoutReuseCache,
                commitReusePass: false,
                identityRegistry: Some(identityRegistry)
            )
            let scene = layoutResult.scene
            lastLayoutElapsedMs = (MonoTime.now() - layoutStarted).toMilliseconds()
            lastNativeMeasurementElapsedMs = textMeasurer.measurementPassNativeElapsedMs()
            lastNativeMeasurementCallCount = textMeasurer.measurementPassNativeCallCount()
            lastLayoutReuseHitCount = layoutResult.metrics.subtreeReuseHitCount
            lastLayoutReuseMissCount = layoutResult.metrics.subtreeReuseMissCount
            lastLayoutReuseRevalidationNodeCount = layoutResult.metrics.subtreeReuseRevalidationNodeCount
            lastLayoutReuseReplayedNodeCount = layoutResult.metrics.subtreeReuseReplayedNodeCount
            lastLayoutReuseEntryCount = layoutResult.metrics.subtreeReuseEntryCount
            lastNativeStageAndSubmitElapsedMs = 0
            layoutPassCount += 1
            if (!scene.isValid()) {
                return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
            }
            // Do not let deterministic fallback geometry look like a successful
            // production AppKit projection. The previous committed scene remains
            // live because no native staging call has occurred yet.
            if (textMeasurer.measurementStatus() != CJGUI_INTERNAL_RENDERER_OK) {
                return rejectParticipantCandidate(participant, textMeasurer.measurementStatus())
            }
            let nodes = scene.nodes()
            if (nodes.size == 0 || nodes.size > 1024) {
                return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
            }
            // Virtual rows are built during the canonical layout pass, so
            // their scoped declarations join this candidate before, never
            // after, the one irreversible prepare/commit boundary.
            if (!identityRegistry.prepareCandidate()) {
                let dynamicIssue = identityRegistry.lastIssue()
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(dynamicIssue)
            }
            let candidateCommands = ArrayList<CjguiComposableUiCommand>()
            if (let Some(value) <- participant) {
                for (command in value.candidateSceneCommands()) {
                    candidateCommands.add(command)
                }
                if (!commandsValidForScene(candidateCommands, scene)) {
                    return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
                }
            }
            // `refresh()` is deliberately conservative for compatibility. Once a
            // real invalidation reaches this point, compare the resolved scene as
            // the correctness gate: a Cangjie UI revision may describe an
            // hierarchy-only change that does not require a native resubmission.
            // Equal output keeps the prior native input snapshot intact.
            // Image completion is invisible in the controller's structural scene:
            // the path/id/version are unchanged while native now owns a texture.
            // Treat that completion epoch as a real refresh invalidation so a
            // loading placeholder cannot remain permanently accepted.
            let resourceCompletionChanged = viewport.resourceCompletionVersion != lastResourceCompletionVersion
            // A same-point backing-scale transition leaves Cangjie's logical
            // scene equal but changes the native drawable and scale-keyed derived
            // text resources. It shares the resize revision with ordinary size
            // changes, so it must reach configure/present rather than publish a
            // semantic-only refresh with former-scale textures still accepted.
            let geometryChanged = viewport.resizeVersion != lastViewportResizeVersion
            if (!resourceCompletionChanged && !geometryChanged && sameRenderedScene(scene)) {
                // Transparent non-interactive grouping nodes can change only their
                // containment while leaving every rendered/hit-testable node
                // identical. Their native bounds are not pixels, but their tree
                // still is external context. Publish a new Cangjie projection
                // revision without a redundant Metal submission. Keep
                // nativeInputScene at the last native snapshot: native events
                // still carry that snapshot's version.
                // This branch has no native present, but from here it is about to
                // write accepted Cangjie state and promote the participant's
                // commands.  Mark that real acceptance boundary before either
                // write so an application callback cannot trigger a false
                // rollback of the already-published semantic candidate.
                acceptedCandidate = true
                identityRegistry.commitCandidate()
                if (!sameComponentTree(renderedRoot, root)) {
                    nextProjectionVersion = candidateVersion
                    renderedRoot = root
                    renderedScene = scene
                }
                if (let Some(value) <- participant) {
                    value.commitSceneRefresh()
                    replaceCommandBindings(candidateCommands)
                }
                acceptedSceneVersion = renderedScene.version
                lastControllerSceneVersion = declaredVersion
                lastViewportResizeVersion = viewport.resizeVersion
                lastResourceCompletionVersion = viewport.resourceCompletionVersion
                refreshRequested = false
                pendingRefreshReason = "none"
                // There is no native submission in this semantic-only branch,
                // but the Cangjie scene and commands are now accepted. Only this
                // boundary may promote derived layout candidates.
                layoutReuseCache.commitPass()
                reconcilePointerCaptureAfterProjection()
                return true
            }
            nextProjectionVersion = candidateVersion
            let stageAndSubmitStarted = MonoTime.now()
            lastNativeStatus = internalRendererConfigureComposableScene(sessionToken, UInt64(scene.version),
                UInt32(nodes.size))
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            // Configure creates an isolated native generation whose unchanged
            // immutable nodes are shared COW references to the previous accepted
            // scene. Send an FFI node only when its rendered/input state has
            // actually changed; native then clones only that staged index. This
            // keeps the live scene atomic while avoiding repeated allocation,
            // string conversion and image lookup for a local text/resource change.
            let previouslySubmittedScene = nativeInputScene
            let previousNativeNodes = previouslySubmittedScene.nodes()
            // Scope values are opaque within one submitted scene. Assign compact
            // per-scene IDs rather than hashing arbitrary layer names into a
            // checked UInt64 arithmetic expression (and risking overflow).
            let inputScopes = ArrayList<String>()
            // Fill the table before deciding which native nodes can be retained:
            // a changed node must receive the same compact scope code its
            // unchanged siblings already carry in the cloned generation.
            for (scopeNode in nodes) {
                let _ = inputScopeCode(scopeNode.inputScopeId, inputScopes)
            }
            // The native transaction starts from the previous generation. Its
            // compact scope IDs were assigned from that generation's traversal,
            // which can differ even when a retained node keeps the same symbolic
            // scope name (for example, when an earlier modal/layer scope is
            // removed). Rebuild that table as well so reuse never preserves a
            // stale native focus domain.
            let previousInputScopes = ArrayList<String>()
            for (scopeNode in previousNativeNodes) {
                let _ = inputScopeCode(scopeNode.inputScopeId, previousInputScopes)
            }
            var index: Int64 = 0
            while (index < nodes.size) {
                let node = nodes[index]
                let nativeInputScope = inputScopeCode(node.inputScopeId, inputScopes)
                let previousNativeInputScope = if (index < previousNativeNodes.size) {
                    inputScopeCode(previousNativeNodes[index].inputScopeId, previousInputScopes)
                } else {
                    0u64
                }
                let completionNeedsImageRestage = resourceCompletionChanged && node.nodeKind == CJGUI_COMPOSABLE_UI_IMAGE
                let canReuseStagedNativeNode = !completionNeedsImageRestage && index < previousNativeNodes.size &&
                    sameLayoutNode(previousNativeNodes[index], node) && previousNativeInputScope == nativeInputScope
                if (canReuseStagedNativeNode) {
                    index += 1
                    continue
                }
                let style = node.style
                // A transformed/normalized owner result is an external value
                // from the adapter's point of view. Only the exact event value
                // for this still-focused text identity may skip the full
                // Cangjie-to-NSString round trip.
                let preservesActiveLocalText = node.nodeId == pendingLocalTextNodeId && node.resourceId ==
                    pendingLocalTextResourceId && node.nodeKind == pendingLocalTextNodeKind && isEditableTextNodeKind(
                    node.nodeKind) && node.value == pendingLocalTextValue && focusedNodeId == node.nodeId &&
                    focusedResourceId == node.resourceId && focusedNodeKind == node.nodeKind
                let clipConstraints = node.clipConstraints()
                let clip0 = if (clipConstraints.size > 0) {
                    clipConstraints[0]
                } else {
                    CjguiComposableUiClipConstraint(node.clip)
                }
                let clip1 = if (clipConstraints.size > 1) {
                    clipConstraints[1]
                } else {
                    clip0
                }
                let clip2 = if (clipConstraints.size > 2) {
                    clipConstraints[2]
                } else {
                    clip1
                }
                let clip3 = if (clipConstraints.size > 3) {
                    clipConstraints[3]
                } else {
                    clip2
                }
                let nativeNode = CjguiInternalRendererComposableNode(
                    nodeId: UInt64(node.nodeId),
                    projectionVersion: UInt64(scene.version),
                    resourceId: node.resourceId,
                    x: node.bounds.x,
                    y: node.bounds.y,
                    width: node.bounds.width,
                    height: node.bounds.height,
                    clipX: node.clip.x,
                    clipY: node.clip.y,
                    clipWidth: node.clip.width,
                    clipHeight: node.clip.height,
                    nodeKind: UInt32(node.nodeKind),
                    isInteractive: if (node.canReceiveInput() || node.canReceiveFocus()) {
                        1u32
                    } else {
                        0u32
                    },
                    isReadOnly: if (node.isReadOnly) {
                        1u32
                    } else {
                        0u32
                    },
                    tabInsertsText: if (node.tabInsertsText) {
                        1u32
                    } else {
                        0u32
                    },
                    preservesActiveLocalText: if (preservesActiveLocalText) {
                        1u32
                    } else {
                        0u32
                    },
                    borderWidth: nonnegativeUInt32(style.borderWidth),
                    cornerRadius: Float64(style.cornerRadius),
                    clipCornerRadius: Float64(node.clipCornerRadius),
                    clipConstraintCount: UInt32(clipConstraints.size),
                    clip0X: clip0.rect.x,
                    clip0Y: clip0.rect.y,
                    clip0Width: clip0.rect.width,
                    clip0Height: clip0.rect.height,
                    clip0CornerRadius: Float64(clip0.cornerRadius),
                    clip1X: clip1.rect.x,
                    clip1Y: clip1.rect.y,
                    clip1Width: clip1.rect.width,
                    clip1Height: clip1.rect.height,
                    clip1CornerRadius: Float64(clip1.cornerRadius),
                    clip2X: clip2.rect.x,
                    clip2Y: clip2.rect.y,
                    clip2Width: clip2.rect.width,
                    clip2Height: clip2.rect.height,
                    clip2CornerRadius: Float64(clip2.cornerRadius),
                    clip3X: clip3.rect.x,
                    clip3Y: clip3.rect.y,
                    clip3Width: clip3.rect.width,
                    clip3Height: clip3.rect.height,
                    clip3CornerRadius: Float64(clip3.cornerRadius),
                    fontSize: style.fontSize,
                    fontWeight: if (style.fontWeight > 0) {
                        1u32
                    } else {
                        0u32
                    },
                    fontFamily: composableFontFamilyCode(style.fontFamily),
                    imageContentMode: if (node.imageContentMode == 2) {
                        2u32
                    } else {
                        1u32
                    },
                    fillRed: style.background.red,
                    fillGreen: style.background.green,
                    fillBlue: style.background.blue,
                    fillAlpha: style.background.alpha,
                    borderRed: style.border.red,
                    borderGreen: style.border.green,
                    borderBlue: style.border.blue,
                    borderAlpha: style.border.alpha,
                    textRed: style.textColor.red,
                    textGreen: style.textColor.green,
                    textBlue: style.textColor.blue,
                    textAlpha: style.textColor.alpha,
                    inputScope: nativeInputScope
                )
                let semanticLabel = if (node.label.size > 0) {
                    node.label
                } else {
                    node.semanticId
                }
                lastNativeStatus = internalRendererSetComposableSceneNode(
                    sessionToken,
                    UInt32(index),
                    nativeNode,
                    semanticLabel,
                    if (preservesActiveLocalText) {
                        ""
                    } else {
                        node.value
                    },
                    node.imageResourcePath,
                    node.imageResourceId,
                    node.imageResourceVersion
                )
                if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                    return rejectParticipantCandidate(participant, lastNativeStatus)
                }
                index += 1
            }
            let frame = internalRendererPresentComposableScene(sessionToken)
            lastNativeStageAndSubmitElapsedMs = (MonoTime.now() - stageAndSubmitStarted).toMilliseconds()
            lastNativeStatus = frame.status
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK && lastNativeStatus !=
                CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
                // The native side rolled its input/overlay snapshot back before
                // returning this presentation failure. Keep Cangjie's accepted
                // scene equally intact and wait for one explicit retry.
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            renderedRoot = root
            renderedScene = scene
            nativeInputScene = scene
            acceptedSceneVersion = scene.version
            submittedSceneVersion = scene.version
            submittedFrameIndex = Int64(frame.frameIndex)
            nativeSubmissionCount += 1
            if (frame.readbackCompleted != 0u8) {
                observedMetalCompletionFrameIndex = Int64(frame.frameIndex)
            }
            lastControllerSceneVersion = declaredVersion
            lastViewportResizeVersion = viewport.resizeVersion
            lastResourceCompletionVersion = viewport.resourceCompletionVersion
            refreshRequested = false
            pendingRefreshReason = "none"
            acceptedCandidate = true
            identityRegistry.commitCandidate()
            // A participant's commit is only the Cangjie-side candidate swap;
            // it runs after, never instead of, native acceptance. Implementors
            // must keep it total. If an application callback nevertheless throws
            // here (or during focus restoration), the window is terminally
            // closed below rather than falsely rolling the accepted scene back.
            if (let Some(value) <- participant) {
                value.commitSceneRefresh()
                replaceCommandBindings(candidateCommands)
            }
            // Native staging/present accepted this exact scene. Failed native
            // candidates return through `rejectParticipantCandidate`, which
            // discards the pending derived entries instead of caching failure.
            layoutReuseCache.commitPass()
            updateModalFocus(root)
            restoreFocusAfterProjectionChange(previouslySubmittedScene)
            reconcilePointerCaptureAfterProjection()
            if (lastNativeStatus == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
                lastNativeFailure = nativeStatusReason(lastNativeStatus)
                return true
            }
            lastNativeFailure = "none"
            pendingLocalTextNodeId = -1
            pendingLocalTextResourceId = -1
            pendingLocalTextNodeKind = -1
            pendingLocalTextValue = ""
            return true
        } catch (_: Exception) {
            if (acceptedCandidate) {
                // Do not invoke participant rollback after native present or
                // a semantic-only Cangjie acceptance. The only honest
                // recovery boundary is a terminal close; reopening starts a
                // new transaction from durable application state.
                lastNativeFailure = "accepted_post_commit_exception"
                close()
                return false
            }
            // The participant API is Cangjie-only bookkeeping. Its rollback
            // implementation is required to be total/idempotent so an
            // ordinary controller exception can return to the accepted scene
            // and one later explicit retry may begin a fresh candidate.
            if (let Some(value) <- participant) {
                value.rollbackSceneRefresh()
            }
            identityRegistry.rollbackCandidate()
            return noteRefreshFailure(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        }
    }

    private func nonnegativeUInt32(value: Int64): UInt32 {
        if (value <= 0) {
            return 0u32
        }
        if (value > 4294967295) {
            return 4294967295u32
        }
        return UInt32(value)
    }
    private func inputScopeCode(value: String, scopes: ArrayList<String>): UInt64 {
        if (value.size == 0) {
            return 0u64
        }
        var index: Int64 = 0
        while (index < scopes.size) {
            if (scopes[index] == value) {
                return UInt64(index + 1)
            }
            index += 1
        }
        scopes.add(value)
        return UInt64(scopes.size)
    }
    private func updateModalFocus(root: CjguiComposableUiNode): Unit {
        let visibleLayers = ArrayList<CjguiComposableUiNode>()
        collectLayers(root, visibleLayers)
        var layersChanged = visibleLayers.size != activeLayerIds.size
        if (!layersChanged) {
            var layerIndex: Int64 = 0
            while (layerIndex < visibleLayers.size) {
                if (visibleLayers[layerIndex].layerId() != activeLayerIds[layerIndex]) {
                    layersChanged = true
                    break
                }
                layerIndex += 1
            }
        }
        var didSetFocus = false
        if (let Some(layer) <- topModalLayer(root)) {
            if (layer.layerId() != activeModalLayerId) {
                activeModalLayerId = layer.layerId()
                modalFocusRestoreNodeId = layer.layerAnchorNodeId()
                if (layer.layerInitialFocusNodeId() >= 0) {
                    didSetFocus = focusProjectedNode(layer.layerInitialFocusNodeId())
                }
            }
        } else if (activeModalLayerId.size > 0) {
            let restoreNodeId = modalFocusRestoreNodeId
            activeModalLayerId = ""
            modalFocusRestoreNodeId = -1
            if (restoreNodeId >= 0) {
                didSetFocus = focusProjectedNode(restoreNodeId)
            }
        }
        // If a popup/submenu vanished but an enclosing dialog is still live,
        // restore its declared anchor rather than leaving AppKit focused on a
        // stale projection identity.  Select the first still-live owner so
        // closing a dialog plus every child returns to the base trigger.
        if (!didSetFocus) {
            var previousIndex: Int64 = 0
            while (previousIndex < activeLayerIds.size) {
                if (!hasLayerId(visibleLayers, activeLayerIds[previousIndex])) {
                    let restoreNodeId = activeLayerRestoreNodeIds[previousIndex]
                    if (restoreNodeId >= 0 && containsNodeId(root, restoreNodeId)) {
                        didSetFocus = focusProjectedNode(restoreNodeId)
                        break
                    }
                }
                previousIndex += 1
            }
        }
        // Menus and popups are non-modal, but they still establish a real
        // input scope in the submitted Cangjie scene.  When a newly declared
        // layer becomes visible, move focus into its explicit initial target
        // or first live focusable descendant.  Otherwise Tab/Escape remain on
        // the base control that opened the layer, so the layer cannot receive
        // its normal keyboard dismissal event.
        if (!didSetFocus) {
            var newLayerFocusNodeId: Int64 = -1
            for (layer in visibleLayers) {
                if (!wasLayerPreviouslyVisible(layer.layerId())) {
                    newLayerFocusNodeId = if (layer.layerInitialFocusNodeId() >= 0) {
                        layer.layerInitialFocusNodeId()
                    } else {
                        firstFocusableNodeIdInLayer(layer.layerId())
                    }
                }
            }
            if (newLayerFocusNodeId >= 0) {
                didSetFocus = focusProjectedNode(newLayerFocusNodeId)
            }
        }
        activeLayerIds.clear();
        activeLayerRestoreNodeIds.clear()
        for (layer in visibleLayers) {
            activeLayerIds.add(layer.layerId())
            activeLayerRestoreNodeIds.add(layer.layerAnchorNodeId())
        }
        if (layersChanged) {
            interactionVersion += 1
        }
    }
    /// Keep the framework's focus projection in step with a focus move that
    /// it requested while committing a new scene.  Native objects stay
    /// private; Cangjie records only the same stable layout identity used for
    /// every FIFO event.
    private func focusProjectedNode(nodeId: Int64): Bool {
        let node = nativeInputScene.nodeForId(nodeId)
        if (node.nodeId != nodeId || !node.canReceiveFocus()) {
            return false
        }
        let status = internalRendererFocusComposableNode(sessionToken, nodeId)
        lastNativeStatus = status
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return false
        }
        recordProjectedFocus(node)
        return true
    }
    private func recordProjectedFocus(node: CjguiComposableUiLayoutNode): Unit {
        let changed = focusedNodeId != node.nodeId || focusedResourceId != node.resourceId || focusedNodeKind != node
            .nodeKind
        focusedNodeId = node.nodeId
        focusedResourceId = node.resourceId
        focusedNodeKind = node.nodeKind
        if (changed) {
            focusedSelectionStart = 0
            focusedSelectionEnd = 0
            interactionVersion += 1
        }
    }
    private func clearProjectedFocus(): Unit {
        if (focusedNodeId >= 0 || focusedResourceId >= 0 || focusedNodeKind >= 0) {
            interactionVersion += 1
        }
        focusedNodeId = -1
        focusedResourceId = -1
        focusedNodeKind = -1
        focusedSelectionStart = 0
        focusedSelectionEnd = 0
    }
    /// A disabled or removed focus target is never allowed to survive as a
    /// Cangjie identity.  Prefer the next focusable node in its prior scope,
    /// wrapping once, so an unrelated newly visible layer cannot receive an
    /// edit merely because an earlier sibling disappeared.
    private func restoreFocusAfterProjectionChange(previousScene: CjguiComposableUiScene): Unit {
        if (focusedNodeId < 0) {
            return
        }
        let current = nativeInputScene.nodeForId(focusedNodeId)
        if (current.nodeId == focusedNodeId && current.resourceId == focusedResourceId && current.nodeKind ==
            focusedNodeKind && current.canReceiveFocus()) {
            return
        }
        // Reusing a raw node id for a different resource/kind is an identity
        // rebind, not a disabled/deleted continuation. Do not carry focus,
        // selection or a pending platform text target into that new object.
        if (current.nodeId == focusedNodeId && (current.resourceId != focusedResourceId || current.nodeKind !=
            focusedNodeKind)) {
            clearProjectedFocus()
            return
        }
        let previous = previousScene.nodeForId(focusedNodeId)
        if (previous.nodeId != focusedNodeId || previous.resourceId != focusedResourceId || previous.nodeKind !=
            focusedNodeKind) {
            clearProjectedFocus()
            return
        }
        let previousNodes = previousScene.nodes()
        var previousIndex: Int64 = 0
        while (previousIndex < previousNodes.size && previousNodes[previousIndex].nodeId != focusedNodeId) {
            previousIndex += 1
        }
        let nextNodes = nativeInputScene.nodes()
        if (nextNodes.size == 0) {
            clearProjectedFocus();
            return
        }
        var candidateIndex = if (previousIndex < nextNodes.size) {
            previousIndex
        } else {
            0
        }
        var checked: Int64 = 0
        while (checked < nextNodes.size) {
            let candidate = nextNodes[candidateIndex]
            if (candidate.inputScopeId == previous.inputScopeId && candidate.canReceiveFocus()) {
                if (focusProjectedNode(candidate.nodeId)) {
                    return
                }
                break
            }
            candidateIndex += 1
            if (candidateIndex >= nextNodes.size) {
                candidateIndex = 0
            }
            checked += 1
        }
        clearProjectedFocus()
    }
    private func collectLayers(node: CjguiComposableUiNode, output: ArrayList<CjguiComposableUiNode>): Unit {
        if (node.layerId().size > 0 && node.layerKind().size > 0) {
            output.add(node)
        }
        for (child in node.children()) {
            collectLayers(child, output)
        }
    }
    private func hasLayerId(layers: ArrayList<CjguiComposableUiNode>, layerId: String): Bool {
        for (layer in layers) {
            if (layer.layerId() == layerId) {
                return true
            }
        }
        return false
    }
    private func wasLayerPreviouslyVisible(layerId: String): Bool {
        for (activeLayerId in activeLayerIds) {
            if (activeLayerId == layerId) {
                return true
            }
        }
        return false
    }
    private func firstFocusableNodeIdInLayer(layerId: String): Int64 {
        for (node in renderedScene.nodes()) {
            if (node.inputScopeId == layerId && node.canReceiveFocus()) {
                return node.nodeId
            }
        }
        return -1
    }
    private func containsNodeId(node: CjguiComposableUiNode, nodeId: Int64): Bool {
        if (node.nodeId == nodeId) {
            return true
        }
        for (child in node.children()) {
            if (containsNodeId(child, nodeId)) {
                return true
            }
        }
        return false
    }
    private func topModalLayer(node: CjguiComposableUiNode): ?CjguiComposableUiNode {
        var latest: ?CjguiComposableUiNode = if (node.layerIsModal()) {
            Some(node)
        } else {
            None
        }
        for (child in node.children()) {
            if (let Some(candidate) <- topModalLayer(child)) {
                latest = Some(candidate)
            }
        }
        return latest
    }
    private func sameRenderedScene(candidate: CjguiComposableUiScene): Bool {
        if (renderedScene.version <= 0) {
            return false
        }
        if (!sameRect(renderedScene.viewport, candidate.viewport)) {
            return false
        }
        let before = renderedScene.nodes()
        let after = candidate.nodes()
        if (before.size != after.size) {
            return false
        }
        var index: Int64 = 0
        while (index < before.size) {
            if (!sameLayoutNode(before[index], after[index])) {
                return false
            }
            index += 1
        }
        return true
    }
    private func sameLayoutNode(left: CjguiComposableUiLayoutNode, right: CjguiComposableUiLayoutNode): Bool {
        let sameIdentity = left.nodeId == right.nodeId && left.semanticId == right.semanticId && left.nodeKind == right
            .nodeKind && left.label == right.label && left.value == right.value && left.actionName == right.actionName &&
            left.resourceId == right.resourceId && left.fieldId == right.fieldId && left.operationActionName == right
            .operationActionName && left.operationResourceId == right.operationResourceId && left.displayValueRole == right
            .displayValueRole && left.imageResourcePath == right.imageResourcePath && left.imageResourceId == right
            .imageResourceId && left.imageResourceVersion == right.imageResourceVersion && left.imageContentMode == right
            .imageContentMode && left.isEnabled == right.isEnabled && left.isReadOnly == right.isReadOnly &&
            left.tabInsertsText == right.tabInsertsText && left.inputScopeId == right.inputScopeId && left.layerId == right
            .layerId && left.layerKind == right.layerKind
        if (!sameIdentity) {
            return false
        }
        // Layout groups with neither fill nor visible border have no native
        // draw or input behavior. Their bounds may differ solely because a
        // child was reparented; evaluate that relationship below, not as a
        // fake visual scene change.
        if (isVisuallyNeutralGroup(left) && isVisuallyNeutralGroup(right)) {
            return true
        }
        return sameRect(left.bounds, right.bounds) && sameRect(left.clip, right.clip) && sameStyle(left.style,
            right.style)
    }
    private func isVisuallyNeutralGroup(node: CjguiComposableUiLayoutNode): Bool {
        let isGroup = node.nodeKind == CJGUI_COMPOSABLE_UI_VERTICAL || node.nodeKind == CJGUI_COMPOSABLE_UI_HORIZONTAL
        return isGroup && node.style.background.alpha <= 0.0 && (node.style.borderWidth <= 0 ||
            node.style.border.alpha <= 0.0)
    }
    private func sameComponentTree(left: CjguiComposableUiNode, right: CjguiComposableUiNode): Bool {
        if (left.nodeId != right.nodeId || left.semanticId != right.semanticId || left.nodeKind != right.nodeKind ||
            left.label != right.label || left.value != right.value || left.actionName != right.actionName ||
            left.resourceId != right.resourceId || left.fieldId != right.fieldId || left.operationActionName != right
            .operationActionName || left.operationResourceId != right.operationResourceId || left.displayValueRole != right
            .displayValueRole || left.imageResourcePath != right.imageResourcePath || left.imageResourceId != right
            .imageResourceId || left.imageResourceVersion != right.imageResourceVersion || left.imageContentMode != right
            .imageContentMode || left.isEnabled != right.isEnabled || left.isReadOnly != right.isReadOnly ||
            left.tabInsertsText != right.tabInsertsText || left.scrollOffset != right.scrollOffset || left.layerId() !=
            right.layerId() || left.layerKind() != right.layerKind() || left.layerOwnerSemanticId() !=
            right.layerOwnerSemanticId() || left.layerAnchorNodeId() != right.layerAnchorNodeId() ||
            left.layerIsModal() != right.layerIsModal() || left.layerInitialFocusNodeId() !=
            right.layerInitialFocusNodeId() || !sameStyle(left.style, right.style)) {
            return false
        }
        let leftChildren = left.children();
        let rightChildren = right.children()
        if (leftChildren.size != rightChildren.size) {
            return false
        }
        var index: Int64 = 0
        while (index < leftChildren.size) {
            if (!sameComponentTree(leftChildren[index], rightChildren[index])) {
                return false
            }
            index += 1
        }
        return true
    }
    private func sameStyle(left: CjguiComposableUiStyle, right: CjguiComposableUiStyle): Bool {
        return sameColor(left.background, right.background) && sameColor(left.border, right.border) && sameColor(
            left.textColor, right.textColor) && left.padding == right.padding && left.gap == right.gap &&
            left.fixedWidth == right.fixedWidth && left.fixedHeight == right.fixedHeight && left.growX == right.growX &&
            left.growY == right.growY && left.borderWidth == right.borderWidth && left.cornerRadius == right
            .cornerRadius && left.clipsContent == right.clipsContent && left.fontSize == right.fontSize &&
            left.fontWeight == right.fontWeight && left.fontFamily == right.fontFamily && left.minWidth == right
            .minWidth && left.maxWidth == right.maxWidth && left.idealWidth == right.idealWidth && left.minHeight == right
            .minHeight && left.maxHeight == right.maxHeight && left.idealHeight == right.idealHeight && left.alignX == right
            .alignX && left.alignY == right.alignY
    }
    private func sameColor(left: CjguiComposableUiColor, right: CjguiComposableUiColor): Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right
            .alpha
    }
    private func sameRect(left: CjguiComposableUiRect, right: CjguiComposableUiRect): Bool {
        return left.x == right.x && left.y == right.y && left.width == right.width && left.height == right.height
    }
    private func result(open: Bool, didApply: Bool): CjguiComposableUiWindowPumpResult {
        return CjguiComposableUiWindowPumpResult(open, didApply, lastNativeStatus, renderedScene.version)
    }
    /// `matchesId` distinguishes a Cangjie menu invocation from a normalized
    /// native shortcut. Both paths still resolve current availability and
    /// scope against `nativeInputScene` before they can produce event 27.
    private func boundCommandTarget(
        command: String,
        matchesId: Bool,
        nativeProjectionVersion: Int64
    ): CjguiComposableUiLayoutNode {
        // A native key intent belongs to its captured scene. A visual refresh
        // may retain a similarly named declaration, but it must not turn that
        // old input into a command on an external Cangjie update. Direct menu
        // invocation (`matchesId`) has no native scene to validate.
        if (!matchesId && Int64(nativeInputScene.version) != nativeProjectionVersion) {
            return CjguiComposableUiLayoutNode.missing()
        }
        let focused = nativeInputScene.nodeForId(focusedNodeId)
        let focusedScope = if (focused.nodeId == focusedNodeId && focused.resourceId == focusedResourceId &&
            focused.nodeKind == focusedNodeKind) {
            focused.inputScopeId
        } else {
            ""
        }
        // Exact focused-scope declaration wins. This keeps a top layer or a
        // repeated editor from accidentally invoking a sibling's command.
        for (binding in commandBindings) {
            let declaration = binding.declaration
            if (((matchesId && declaration.id == command) || (!matchesId && declaration.shortcut.encoded() == command)) &&
                declaration.focusScopeId.size > 0 && declaration.focusScopeId == focusedScope) {
                let node = nativeInputScene.nodeForId(declaration.targetNodeId)
                if (commandTargetIsLive(node, declaration, focusedScope)) {
                    return node
                }
            }
        }
        // A global declaration is a fallback only for base focus. It cannot
        // punch through an active component/layer focus scope.
        if (focusedScope.size > 0) {
            return CjguiComposableUiLayoutNode.missing()
        }
        for (binding in commandBindings) {
            let declaration = binding.declaration
            if (((matchesId && declaration.id == command) || (!matchesId && declaration.shortcut.encoded() == command)) &&
                declaration.focusScopeId.size == 0) {
                let node = nativeInputScene.nodeForId(declaration.targetNodeId)
                if (commandTargetIsLive(node, declaration, focusedScope)) {
                    return node
                }
            }
        }
        return CjguiComposableUiLayoutNode.missing()
    }
    private func commandTargetIsLive(node: CjguiComposableUiLayoutNode, declaration: CjguiComposableUiCommand,
        focusedScope: String): Bool {
        return node.nodeId == declaration.targetNodeId && node.canReceiveInput() && node.actionName.size > 0 &&
            node.inputScopeId == declaration.focusScopeId && (declaration.focusScopeId.size == 0 ||
            declaration.focusScopeId == focusedScope)
    }
    private func commandsValidForAcceptedScene(commands: ArrayList<CjguiComposableUiCommand>): Bool {
        return commandsValidForScene(commands, nativeInputScene)
    }
    private func commandsValidForScene(commands: ArrayList<CjguiComposableUiCommand>, scene: CjguiComposableUiScene): Bool {
        var index: Int64 = 0
        while (index < commands.size) {
            let command = commands[index]
            if (!command.isValid()) {
                return false
            }
            let target = scene.nodeForId(command.targetNodeId)
            if (!commandTargetIsLive(target, command, command.focusScopeId)) {
                return false
            }
            var prior: Int64 = 0
            while (prior < index) {
                if (commands[prior].id == command.id || (commands[prior].shortcut.encoded() == command
                    .shortcut
                    .encoded() && commands[prior].focusScopeId == command.focusScopeId)) {
                    return false
                }
                prior += 1
            }
            index += 1
        }
        return true
    }
    private func replaceCommandBindings(commands: ArrayList<CjguiComposableUiCommand>) {
        commandBindings.clear()
        for (command in commands) {
            commandBindings.add(CjguiComposableUiWindowCommandBinding(command))
        }
    }
    private func applyBoundCommand(target: CjguiComposableUiLayoutNode, projectionVersion: Int64): CjguiComposableUiDispatchResult {
        rememberInteraction(target, 27, 0, 0)
        return controller.applyUiEvent(CjguiComposableUiEvent(target, 27, "", 0, 0, projectionVersion))
    }
    private func isPointerCapturable(node: CjguiComposableUiLayoutNode): Bool {
        return (node.nodeKind == 13 || node.nodeKind == 14) && node.canReceiveInput()
    }
    private func pointerCaptureVersionFor(node: CjguiComposableUiLayoutNode): Int64 {
        let provider = controller as CjguiComposableUiPointerCaptureVersionProvider
        if (let Some(value) <- provider) {
            return value.pointerCaptureVersion(node)
        }
        return controller.uiSceneVersion()
    }
    private func clearPointerCapture(): Unit {
        pointerCaptureNode = CjguiComposableUiLayoutNode.missing()
        pointerCaptureOwnerVersion = -1
        pointerCaptureModalLayerId = ""
        pointerCaptureActive = false
        pointerCaptureX = 0
        pointerCaptureY = 0
    }
    private func cancelPointerCapture(): CjguiComposableUiDispatchResult {
        if (!pointerCaptureActive || pointerCaptureNode.nodeId < 0) {
            clearPointerCapture()
            return CjguiComposableUiDispatchResult(false)
        }
        let target = pointerCaptureNode
        let x = pointerCaptureX
        let y = pointerCaptureY
        // Clear first: a controller callback may request a refresh, close the
        // window, or reject the phase. None of those paths may leave the old
        // target able to receive a later move/up.
        let _ = internalRendererCancelComposablePointerCapture(sessionToken)
        clearPointerCapture()
        return controller.applyUiEvent(
            CjguiComposableUiEvent(
                target,
                CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL,
                "",
                0,
                0,
                nativeInputScene.version,
                pointerX: x,
                pointerY: y
            )
        )
    }
    private func dispatchPointerEvent(nativeEvent: InternalRendererPumpResult): CjguiComposableUiDispatchResult {
        let eventKind = Int64(nativeEvent.eventKind)
        let nodeId = Int64(nativeEvent.nodeId)
        let x = nativeEvent.pointerX
        let y = nativeEvent.pointerY
        if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN) {
            if (pointerCaptureActive) {
                let _ = cancelPointerCapture()
            }
            let resolved = if (nativeEvent.nodeId == 0u64) {
                CjguiComposableUiLayoutNode.missing()
            } else {
                nativeInputScene.resolveInput(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                    Int64(nativeEvent.projectionVersion))
            }
            if (!isPointerCapturable(resolved)) {
                return controller.rejectUiEvent(eventKind, nodeId)
            }
            let dispatch = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    resolved,
                    eventKind,
                    "",
                    0,
                    0,
                    Int64(nativeEvent.projectionVersion),
                    pointerX: x,
                    pointerY: y
                )
            )
            if (dispatch.didApply) {
                pointerCaptureNode = resolved
                pointerCaptureOwnerVersion = pointerCaptureVersionFor(resolved)
                pointerCaptureModalLayerId = activeModalLayerId
                pointerCaptureActive = true
                pointerCaptureX = x
                pointerCaptureY = y
                rememberInteraction(resolved, eventKind, 0, 0)
            }
            return dispatch
        }
        if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            return cancelPointerCapture()
        }
        if (!pointerCaptureActive || pointerCaptureNode.nodeId != nodeId || pointerCaptureNode.resourceId != nativeEvent
            .resourceId || pointerCaptureNode.nodeKind != Int64(nativeEvent.nodeKind)) {
            return controller.rejectUiEvent(eventKind, nodeId)
        }
        // A Cangjie callback records the target owner revision it just
        // accepted. Any independently accepted write that changes this
        // target cancels rather than letting stale capture overwrite it;
        // controllers without a target-scoped provider remain conservative.
        if (pointerCaptureVersionFor(pointerCaptureNode) != pointerCaptureOwnerVersion || activeModalLayerId !=
            pointerCaptureModalLayerId) {
            return cancelPointerCapture()
        }
        let current = nativeInputScene.nodeForId(pointerCaptureNode.nodeId)
        if (!isPointerCapturable(current) || current.resourceId != pointerCaptureNode.resourceId || current.nodeKind != pointerCaptureNode
            .nodeKind) {
            return cancelPointerCapture()
        }
        let dispatch = controller.applyUiEvent(
            CjguiComposableUiEvent(
                current,
                eventKind,
                "",
                0,
                0,
                Int64(nativeEvent.projectionVersion),
                pointerX: x,
                pointerY: y
            )
        )
        pointerCaptureX = x
        pointerCaptureY = y
        if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) {
            clearPointerCapture()
        } else if (dispatch.didApply) {
            pointerCaptureOwnerVersion = pointerCaptureVersionFor(current)
            rememberInteraction(current, eventKind, 0, 0)
        }
        return dispatch
    }
    private func reconcilePointerCaptureAfterProjection(): Unit {
        if (!pointerCaptureActive) {
            return
        }
        let current = nativeInputScene.nodeForId(pointerCaptureNode.nodeId)
        if (pointerCaptureVersionFor(pointerCaptureNode) != pointerCaptureOwnerVersion || activeModalLayerId !=
            pointerCaptureModalLayerId || !isPointerCapturable(current) || current.resourceId != pointerCaptureNode
            .resourceId || current.nodeKind != pointerCaptureNode.nodeKind) {
            let cancellation = cancelPointerCapture()
            if (cancellation.didApply && isWindowOpen) {
                requestRefresh()
            }
        }
    }
    private func isEditableTextNodeKind(nodeKind: Int64): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT ||
            nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    }
    /// Admit only the single-generation continuation that was produced by
    /// the live focused text adapter while its accepted successor scene was
    /// being assembled.  The current owner value must still be exactly the
    /// preceding local value; an external write, disable, delete or resource
    /// replacement fails one of these checks and remains rejectable.
    private func resolveLocalTextContinuation(eventKind: Int64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        eventText: String, projectionVersion: Int64): CjguiComposableUiLayoutNode {
        if (eventKind != 28 || !isEditableTextNodeKind(nodeKind) || projectionVersion + 1 != nativeInputScene.version ||
            nodeId != localTextContinuationNodeId || resourceId != localTextContinuationResourceId || nodeKind !=
            localTextContinuationNodeKind || nodeId != focusedNodeId || resourceId != focusedResourceId || nodeKind !=
            focusedNodeKind || eventText == localTextContinuationValue) {
            return CjguiComposableUiLayoutNode.missing()
        }
        // `nativeInputScene` is a rendered input snapshot, not the real-time
        // domain owner.  In particular, an external same-object replacement
        // can leave its value unchanged while advancing the controller's
        // declared revision.  Admit this one callback only while the durable
        // owner still reports exactly the revision that accepted its first
        // local character.
        if (controller.uiSceneVersion() != localTextContinuationOwnerVersion) {
            return CjguiComposableUiLayoutNode.missing()
        }
        let current = nativeInputScene.nodeForId(nodeId)
        if (!current.canReceiveInput() || current.resourceId != resourceId || current.nodeKind != nodeKind ||
            current.value != localTextContinuationValue) {
            return CjguiComposableUiLayoutNode.missing()
        }
        return current
    }
    private func clearLocalTextContinuation(): Unit {
        localTextContinuationNodeId = -1
        localTextContinuationResourceId = -1
        localTextContinuationNodeKind = -1
        localTextContinuationValue = ""
        localTextContinuationOwnerVersion = -1
    }
    private func rememberInteraction(node: CjguiComposableUiLayoutNode, eventKind: Int64, selectionStart: Int64,
        selectionEnd: Int64) {
        if (eventKind == 27 || eventKind == 28 || eventKind == 29 || eventKind == 31 || eventKind == 33) {
            focusedNodeId = node.nodeId
            focusedResourceId = node.resourceId
            focusedNodeKind = node.nodeKind
        }
        if (eventKind == 28 || eventKind == 31 || eventKind == 33) {
            focusedSelectionStart = if (selectionStart < 0) {
                0
            } else {
                selectionStart
            }
            focusedSelectionEnd = if (selectionEnd < focusedSelectionStart) {
                focusedSelectionStart
            } else {
                selectionEnd
            }
        }
        interactionVersion += 1
    }
    private func rejectParticipantCandidate(participant: ?CjguiComposableUiSceneRefreshParticipant, status: Int32): Bool {
        layoutReuseCache.discardPass()
        if (let Some(value) <- participant) {
            value.rollbackSceneRefresh()
        }
        identityRegistry.rollbackCandidate()
        return noteRefreshFailure(status)
    }
    private func noteIdentityRefreshFailure(issue: String): Bool {
        layoutReuseCache.discardPass()
        lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        let resolvedIssue = if (issue.size > 0) {
            issue
        } else {
            "identity_candidate_invalid"
        }
        lastNativeFailure = resolvedIssue
        pendingRefreshReason = "refresh_${resolvedIssue}"
        refreshRequested = false
        return false
    }
    private func noteRefreshFailure(status: Int32): Bool {
        layoutReuseCache.discardPass()
        lastNativeStatus = status
        let reason = nativeStatusReason(status)
        lastNativeFailure = reason
        pendingRefreshReason = "refresh_${reason}"
        // Do not turn a temporarily unavailable drawable into a 60 Hz retry
        // loop. The retained scene stays live until an explicit retry, a new
        // external mutation, resize, or human event marks refresh again.
        refreshRequested = false
        return false
    }
    private func isRecoverableNativeStatus(status: Int32): Bool {
        return status == CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE || status ==
            CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE || status ==
            CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE || status == CJGUI_INTERNAL_RENDERER_READBACK_FAILED ||
            status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    private func nativeStatusReason(status: Int32): String {
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            return "none"
        }
        if (status == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD) {
            return "not_main_thread"
        }
        if (status == CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED) {
            return "app_init_failed"
        }
        if (status == CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED) {
            return "window_create_failed"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE) {
            return "metal_device_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_COMMAND_QUEUE_UNAVAILABLE) {
            return "metal_command_queue_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE) {
            return "metal_layer_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE) {
            return "metal_drawable_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE) {
            return "metal_command_buffer_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE) {
            return "metal_encoder_unavailable"
        }
        if (status == CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED) {
            return "view_invalidated"
        }
        if (status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            return "invalid_session"
        }
        if (status == CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL) {
            return "session_table_full"
        }
        if (status == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
            return "readback_failed"
        }
        return "internal_error"
    }
    private func discardSession() {
        if (sessionToken != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            let status = internalRendererDestroy(sessionToken)
            if (status != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = status
            }
        }
        sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        isWindowOpen = false
        windowSessionIdentity = ""
        nativeInputScene = CjguiComposableUiScene(0, CjguiComposableUiRect(0, 0, 0, 0),
            ArrayList<CjguiComposableUiLayoutNode>())
        focusedNodeId = -1
        focusedResourceId = -1
        focusedNodeKind = -1
        focusedSelectionStart = 0
        focusedSelectionEnd = 0
        pendingLocalTextNodeId = -1
        pendingLocalTextResourceId = -1
        pendingLocalTextNodeKind = -1
        pendingLocalTextValue = ""
        localTextContinuationNodeId = -1
        localTextContinuationResourceId = -1
        localTextContinuationNodeKind = -1
        localTextContinuationValue = ""
        localTextContinuationOwnerVersion = -1
        clearPointerCapture()
        interactionVersion = 0
        activeModalLayerId = ""
        modalFocusRestoreNodeId = -1
        activeLayerIds.clear();
        activeLayerRestoreNodeIds.clear()
        refreshRequested = false
        pendingRefreshReason = "none"
        acceptedSceneVersion = 0
        submittedSceneVersion = -1
        submittedFrameIndex = -1
        observedMetalCompletionFrameIndex = -1
        observedMetalFailureFrameIndex = -1
        observedMetalGpuDurationMicros = -1
        overlayDrawnSceneVersion = -1
        textMeasurer = CjguiInternalRendererTextMeasurer(CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN)
        layoutReuseCache = CjguiComposableUiLayoutReuseCache()
        identityRegistry.clear()
    }
}
