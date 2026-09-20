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
public let CJGUI_COMPOSABLE_UI_EVENT_HOVER_ENTER: Int64 = 43
public let CJGUI_COMPOSABLE_UI_EVENT_HOVER_LEAVE: Int64 = 44
public let CJGUI_COMPOSABLE_UI_EVENT_PRESS_BEGIN: Int64 = 45
public let CJGUI_COMPOSABLE_UI_EVENT_PRESS_END: Int64 = 46
public let CJGUI_COMPOSABLE_UI_EVENT_PRESS_CANCEL: Int64 = 47

/// The human-input kinds a self-drawn control reports, published so a
/// controller never has to hardcode them. They match the native bridge's
/// normalized event kinds: a press activation, an edited text projection, a
/// toggled boolean projection (whose `text` is the projected next value), a
/// scroll intent and a focus change. A generated editor kind maps to exactly
/// one of these through `CjguiGeneratedUiFieldSpec.changeEventKind()`.
public let CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE: Int64 = 27
public let CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED: Int64 = 28
public let CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED: Int64 = 29
public let CJGUI_COMPOSABLE_UI_EVENT_SCROLL: Int64 = 30
public let CJGUI_COMPOSABLE_UI_EVENT_FOCUS: Int64 = 31

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
/// AppKit keyboard modifier bits as delivered on pointer events. They are
/// public so controllers can implement ordinary Command/Shift click semantics
/// without a second input mechanism.
public let CJGUI_UI_MODIFIER_SHIFT: Int64 = 1 << 17
public let CJGUI_UI_MODIFIER_CONTROL: Int64 = 1 << 18
public let CJGUI_UI_MODIFIER_OPTION: Int64 = 1 << 19
public let CJGUI_UI_MODIFIER_COMMAND: Int64 = 1 << 20

public class CjguiComposableUiEvent {
    public let node: CjguiComposableUiLayoutNode
    public let eventKind: Int64
    public let text: String
    public let selectionStart: Int64
    public let selectionEnd: Int64
    public let projectionVersion: Int64
    public let pointerX: Int64
    public let pointerY: Int64
    /// Keyboard modifier flags of the pointer event (AppKit
    /// NSEventModifierFlag* bits): command = 1 << 20, shift = 1 << 17,
    /// option = 1 << 19, control = 1 << 18. Non-pointer intents carry 0.
    public let modifierFlags: Int64
    public init(node: CjguiComposableUiLayoutNode, eventKind: Int64, text: String, selectionStart: Int64,
        selectionEnd: Int64, projectionVersion: Int64, pointerX!: Int64 = 0, pointerY!: Int64 = 0,
        modifierFlags!: Int64 = 0) {
        this.node = node
        this.eventKind = eventKind
        this.text = text
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.projectionVersion = projectionVersion
        this.pointerX = pointerX
        this.pointerY = pointerY
        this.modifierFlags = modifierFlags
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

public let CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY: Int64 = 48
public let CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_PASTE: Int64 = 49
public let CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP: Int64 = 50

/// Experimental transfer declaration for one semantic composable node. The
/// node remains a normal control; the declaration merely lets the host copy a
/// bounded UTF-8 offer on an explicit shortcut or drag gesture. Native owns
/// no application handler, owner reference or durable transfer history.
public class CjguiComposableUiDataTransferDeclaration {
    public let semanticId: String
    public let role: String
    public let format: CjguiSharedOperationTransferFormat
    public let offer: ?CjguiSharedOperationTransferOffer

    private init(
        semanticId: String,
        role: String,
        format: CjguiSharedOperationTransferFormat,
        offer: ?CjguiSharedOperationTransferOffer
    ) {
        this.semanticId = semanticId
        this.role = role
        this.format = format
        this.offer = offer
    }

    public static func source(
        semanticId: String,
        offer: CjguiSharedOperationTransferOffer
    ): CjguiComposableUiDataTransferDeclaration {
        return CjguiComposableUiDataTransferDeclaration(semanticId, "SOURCE", offer.format, Some(offer))
    }

    public static func target(
        semanticId: String,
        format: CjguiSharedOperationTransferFormat
    ): CjguiComposableUiDataTransferDeclaration {
        return CjguiComposableUiDataTransferDeclaration(semanticId, "TARGET", format, None)
    }

    public func isValid(): Bool {
        if (semanticId.size == 0 || !format.isValid()) { return false }
        if (role == "SOURCE") {
            if (let Some(value) <- offer) {
                return value.operation == "COPY" && value.format.kind == format.kind &&
                    value.format.identifier == format.identifier && value.format.version == format.version &&
                    format.acceptsPayload(value.payload)
            }
            return false
        }
        return role == "TARGET" && offer.isNone()
    }
}

/// Copied platform intent delivered only after the window has re-resolved the
/// native event against an accepted semantic node. A target event's offer is
/// an immutable external-pasteboard value; the application decides whether it
/// reaches an existing human owner operation.
public class CjguiComposableUiDataTransferEvent {
    public let node: CjguiComposableUiLayoutNode
    public let eventKind: Int64
    public let offer: CjguiSharedOperationTransferOffer
    public let format: CjguiSharedOperationTransferFormat
    public let projectionVersion: Int64

    public init(
        node: CjguiComposableUiLayoutNode,
        eventKind: Int64,
        offer: CjguiSharedOperationTransferOffer,
        format: CjguiSharedOperationTransferFormat,
        projectionVersion: Int64
    ) {
        this.node = node
        this.eventKind = eventKind
        this.offer = offer
        this.format = format
        this.projectionVersion = projectionVersion
    }
}

/// Optional public value boundary for a controller with normal transfer
/// consumers. An application keeps offer construction, validation and all
/// domain mutation behind this interface; the composable host only stages the
/// resulting bounded values and returns copied native intents.
public interface CjguiComposableUiDataTransferProvider {
    func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration>
    func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult
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

private class CjguiComposableUiDataTransferBinding {
    let declaration: CjguiComposableUiDataTransferDeclaration
    let node: CjguiComposableUiLayoutNode
    let nativeFormat: String

    init(declaration: CjguiComposableUiDataTransferDeclaration,
        node: CjguiComposableUiLayoutNode, nativeFormat: String) {
        this.declaration = declaration
        this.node = node
        this.nativeFormat = nativeFormat
    }
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
    /// Kept for source compatibility. New dynamic components should use
    /// `targetReference`, which resolves after component identity allocation.
    public let targetNodeId: Int64
    public let targetReference: CjguiComposableUiNodeReference
    public let displayName: String
    public let shortcut: CjguiComposableUiShortcut
    private let shortcutDeclared: Bool
    /// Empty means no platform-menu entry; a Cangjie-owned contextual surface
    /// can still invoke the stable command id through `invokeCommand`.
    public let menuGroup: String
    /// A changed non-negative section inserts a separator within one group.
    public let menuSection: Int64
    /// These values describe the current accepted Cangjie declaration. Native
    /// menu validation is a projection and re-enters this command dispatch.
    public let isEnabled: Bool
    public let isChecked: Bool
    /// Empty means global. A non-empty value must equal the currently focused
    /// Cangjie input scope, so a covered base command cannot bypass a layer.
    public let focusScopeId: String

    public init(id: String, targetNodeId: Int64, shortcut: CjguiComposableUiShortcut, focusScopeId!: String = "") {
        this.id = id
        this.targetNodeId = targetNodeId
        this.targetReference = CjguiComposableUiNodeReference.manual(targetNodeId)
        this.displayName = id
        this.shortcut = shortcut
        this.shortcutDeclared = true
        this.menuGroup = ""
        this.menuSection = 0
        this.isEnabled = true
        this.isChecked = false
        this.focusScopeId = focusScopeId
    }

    /// Dynamic-component declaration. The semantic reference is resolved only
    /// in the accepted scene, so a rejected candidate cannot leave a menu or
    /// shortcut pointing at a provisional renderer node.
    public init(
        id: String,
        targetReference: CjguiComposableUiNodeReference,
        displayName: String,
        shortcut: CjguiComposableUiShortcut,
        menuGroup: String,
        menuSection: Int64,
        isEnabled: Bool,
        isChecked: Bool,
        focusScopeId!: String = ""
    ) {
        this.id = id
        this.targetNodeId = -1
        this.targetReference = targetReference
        this.displayName = displayName
        this.shortcut = shortcut
        this.shortcutDeclared = true
        this.menuGroup = menuGroup
        this.menuSection = menuSection
        this.isEnabled = isEnabled
        this.isChecked = isChecked
        this.focusScopeId = focusScopeId
    }

    /// A command may deliberately appear in a menu without claiming a
    /// keyboard chord. This avoids teaching applications to reserve a dummy
    /// shortcut merely to express menu state.
    public init(
        id: String,
        targetReference: CjguiComposableUiNodeReference,
        displayName: String,
        menuGroup: String,
        menuSection: Int64,
        isEnabled: Bool,
        isChecked: Bool,
        focusScopeId!: String = ""
    ) {
        this.id = id
        this.targetNodeId = -1
        this.targetReference = targetReference
        this.displayName = displayName
        this.shortcut = CjguiComposableUiShortcut("")
        this.shortcutDeclared = false
        this.menuGroup = menuGroup
        this.menuSection = menuSection
        this.isEnabled = isEnabled
        this.isChecked = isChecked
        this.focusScopeId = focusScopeId
    }

    public func hasShortcut(): Bool {
        return shortcutDeclared
    }

    public func isValid(): Bool {
        return id.size > 0 && displayName.size > 0 && menuSection >= 0 && targetReference.isValid() &&
            (!shortcutDeclared || shortcut.isValid())
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

// Package-only diagnostic for the real refresh transaction. It exists so
// probes can separate work that has already happened; ordinary consumers keep
// using the stable projection/context APIs and never receive these counters.
class CjguiComposableUiRefreshTiming {
    var buildNanoseconds: Int64
    var identityResolutionNanoseconds: Int64
    var candidateCloneNanoseconds: Int64
    var participantPreparationNanoseconds: Int64
    var layoutNanoseconds: Int64
    var identityCandidatePrepareNanoseconds: Int64
    var commandBindingNanoseconds: Int64
    var sameSceneComparisonNanoseconds: Int64
    var interactionPaintResolutionNanoseconds: Int64
    var interactionPaintComparisonNanoseconds: Int64
    var nativeStageAndSubmitNanoseconds: Int64
    var candidateNodeCount: Int64

    init() {
        this.buildNanoseconds = -1
        this.identityResolutionNanoseconds = -1
        this.candidateCloneNanoseconds = -1
        this.participantPreparationNanoseconds = -1
        this.layoutNanoseconds = -1
        this.identityCandidatePrepareNanoseconds = -1
        this.commandBindingNanoseconds = -1
        this.sameSceneComparisonNanoseconds = -1
        this.interactionPaintResolutionNanoseconds = -1
        this.interactionPaintComparisonNanoseconds = -1
        this.nativeStageAndSubmitNanoseconds = -1
        this.candidateNodeCount = -1
    }
}

// Compact native focus-scope IDs are assigned by Cangjie for a single staged
// scene.  Keep the prior first-seen order, but use a key table so a complex
// tree with many independent layers does not repeatedly linearly scan every
// scope seen before it.  The table is temporary transaction metadata: it
// contains no controller/domain object and is discarded after each refresh.
class CjguiComposableUiNativeInputScopeTable {
    private let codes: HashMap<String, UInt64>
    private var nextCode: UInt64

    init() {
        this.codes = HashMap<String, UInt64>()
        this.nextCode = 1u64
    }

    func codeFor(value: String): UInt64 {
        if (value.size == 0) {
            return 0u64
        }
        if (let Some(existing) <- codes.get(value)) {
            return existing
        }
        let assigned = nextCode
        let _ = codes.add(value, assigned)
        nextCode += 1u64
        return assigned
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
    // Standard AppKit Quit is admitted as one process-level native intent.
    // It never becomes a controller action: the enclosing
    // `CjguiMacosApplication` consumes it and asks its established exit
    // decision provider during the ordinary application turn.
    private var applicationExitRequested: Bool
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
    private var lastRefreshTiming: CjguiComposableUiRefreshTiming
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
    // The framework owns these ephemeral visual identities. They are always
    // checked against the accepted native input scene before use; an owner
    // never writes hover/pressed/focus directly.
    private var hoveredInteractionNode: CjguiComposableUiLayoutNode
    private var pressedInteractionNode: CjguiComposableUiLayoutNode
    // A physical press may outlive a replacement projection.  Keep only the
    // terminal routing slot that must reject the paired activation when the
    // current action/scope is no longer the declaration seen at press-down.
    // This is framework-local input provenance, never an owner write or a
    // native business callback.
    private var suppressedPressActivationNode: CjguiComposableUiLayoutNode
    // Package-only trace values for the physical press terminal boundary.
    // They let probes prove whether a rebind was compared and its paired
    // activation consumed without exposing native routing to consumers.
    private var lastTerminalPressIdentityChanged: Bool
    private var lastPressActivationSuppressed: Bool
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
    // Accepted transfer declarations follow the same scene lifecycle as
    // input/command bindings. They are replaceable values, never an owner
    // cache or a retained native pasteboard/drag object.
    private var dataTransferBindings: ArrayList<CjguiComposableUiDataTransferBinding>
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
    // A focus request whose target row only appears in the next accepted scene
    // (an off-screen tree row that was just revealed). It is retried once right
    // after that commit instead of being silently dropped.
    private var pendingScopedFocusScope: ?CjguiComposableUiIdentityScope = None
    private var pendingScopedFocusKey: String = ""

    public init(
        controller: CjguiComposableUiController,
        configuration!: CjguiMacosApplicationWindowConfiguration = CjguiMacosApplicationWindowConfiguration.standard()
    ) {
        this.controller = controller
        this.configuration = configuration
        this.sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        this.isWindowOpen = false
        this.lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        this.applicationExitRequested = false
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
        this.lastRefreshTiming = CjguiComposableUiRefreshTiming()
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
        this.hoveredInteractionNode = CjguiComposableUiLayoutNode.missing()
        this.pressedInteractionNode = CjguiComposableUiLayoutNode.missing()
        this.suppressedPressActivationNode = CjguiComposableUiLayoutNode.missing()
        this.lastTerminalPressIdentityChanged = false
        this.lastPressActivationSuppressed = false
        this.interactionVersion = 0
        this.activeModalLayerId = ""
        this.modalFocusRestoreNodeId = -1
        this.activeLayerIds = ArrayList<String>()
        this.activeLayerRestoreNodeIds = ArrayList<Int64>()
        this.commandBindings = ArrayList<CjguiComposableUiWindowCommandBinding>()
        this.dataTransferBindings = ArrayList<CjguiComposableUiDataTransferBinding>()
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
        lastRefreshTiming = CjguiComposableUiRefreshTiming()
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
        hoveredInteractionNode = CjguiComposableUiLayoutNode.missing()
        pressedInteractionNode = CjguiComposableUiLayoutNode.missing()
        suppressedPressActivationNode = CjguiComposableUiLayoutNode.missing()
        lastTerminalPressIdentityChanged = false
        lastPressActivationSuppressed = false
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
        var requiresInteractionPaint = false
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
            if (nativeEvent.eventKind == 42u32) {
                // The native AppKit delegate already returned immediately
                // with NSTerminateCancel.  Keep this request outside the
                // controller's event vocabulary so a document cannot turn a
                // process-close decision into an ordinary content action.
                applicationExitRequested = true
            } else if (nativeEvent.eventKind == 11u32) {
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
            } else if (nativeEvent.eventKind >= 43u32 && nativeEvent.eventKind <= 47u32) {
                // Interaction-only intents are resolved against the exact
                // native input snapshot that produced them. They never enter
                // the controller/business event path; the framework owns
                // hover, press and focus projection locally.
                let nodeId = Int64(nativeEvent.nodeId)
                let resolved = if (nativeEvent.nodeId == 0u64 || Int64(nativeEvent.projectionVersion) !=
                    nativeInputScene.version) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    let candidate = nativeInputScene.nodeForId(nodeId)
                    if (candidate.nodeId == nodeId && candidate.resourceId == nativeEvent.resourceId &&
                        candidate.nodeKind == Int64(nativeEvent.nodeKind) && candidate.isEnabled &&
                        (candidate.canReceiveInput() || candidate.canReceiveFocus())) {
                        candidate
                    } else {
                        CjguiComposableUiLayoutNode.missing()
                    }
                }
                if (resolved.nodeId == nodeId) {
                    if (nativeEvent.eventKind == 43u32) {
                        hoveredInteractionNode = resolved
                    } else if (nativeEvent.eventKind == 44u32) {
                        if (sameInteractionSlot(hoveredInteractionNode, resolved)) {
                            hoveredInteractionNode = CjguiComposableUiLayoutNode.missing()
                        }
                    } else if (nativeEvent.eventKind == 45u32) {
                        pressedInteractionNode = resolved
                        suppressedPressActivationNode = CjguiComposableUiLayoutNode.missing()
                        lastTerminalPressIdentityChanged = false
                        lastPressActivationSuppressed = false
                        recordProjectedFocus(resolved)
                    } else if (nativeEvent.eventKind == 46u32) {
                        if (sameInteractionSlot(pressedInteractionNode, resolved)) {
                            let identityChanged = !samePressActivationIdentity(pressedInteractionNode, resolved)
                            lastTerminalPressIdentityChanged = identityChanged
                            if (identityChanged) {
                                suppressedPressActivationNode = resolved
                            }
                            pressedInteractionNode = CjguiComposableUiLayoutNode.missing()
                        }
                    } else if (nativeEvent.eventKind == 47u32) {
                        if (sameInteractionSlot(pressedInteractionNode, resolved)) {
                            pressedInteractionNode = CjguiComposableUiLayoutNode.missing()
                        }
                    }
                    requiresInteractionPaint = true
                }
            } else if (nativeEvent.eventKind >= 48u32 && nativeEvent.eventKind <= 50u32) {
                // Clipboard and drag/drop deliver only one copied, bounded
                // value. Re-resolve against the accepted native input scene
                // before the optional consumer maps that value to its existing
                // human owner operation; the platform bridge owns neither
                // business state nor an application callback.
                let nodeId = Int64(nativeEvent.nodeId)
                let resolved = if (nativeEvent.nodeId == 0u64) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    nativeInputScene.resolveInput(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                        Int64(nativeEvent.projectionVersion))
                }
                if (resolved.nodeId == nodeId) {
                    let eventKind = Int64(nativeEvent.eventKind)
                    let dispatch = applyDataTransfer(resolved, eventKind, internalRendererFormEventText(sessionToken),
                        internalRendererDataTransferEventFormat(sessionToken),
                        internalRendererDataTransferEventSourceKind(sessionToken),
                        internalRendererDataTransferEventSourceIdentity(sessionToken),
                        internalRendererDataTransferEventSourceId(sessionToken), Int64(nativeEvent.projectionVersion))
                    didApply = didApply || dispatch.didApply
                    if (dispatch.shouldClose) {
                        close()
                        return result(false, didApply)
                    }
                    // Copy acknowledgement and rejected paste/drop are visible
                    // consumer-local state.  A successful target consumes the
                    // owner mutation through the same coalesced projection
                    // path as every normal human action.
                    requiresProjection = true
                } else {
                    let rejection = controller.rejectUiEvent(Int64(nativeEvent.eventKind), nodeId)
                    didApply = didApply || rejection.didApply
                    if (rejection.shouldClose) {
                        close()
                        return result(false, didApply)
                    }
                    requiresProjection = true
                }
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
            } else if (nativeEvent.eventKind == 41u32) {
                let target = boundCommandTarget(
                    internalRendererFormEventText(sessionToken),
                    true,
                    Int64(nativeEvent.projectionVersion)
                )
                if (target.nodeId >= 0) {
                    let dispatch = applyBoundCommand(target, Int64(nativeEvent.projectionVersion))
                    didApply = didApply || dispatch.didApply
                    if (dispatch.shouldClose) {
                        close()
                        return result(false, didApply)
                    }
                    requiresProjection = true
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
                            Int64(nativeEvent.projectionVersion),
                            // The keyDown that produced this navigation carries
                            // its own modifiers (Shift extends a range, Command
                            // marks select-all); a programmatic/AX navigation is
                            // enqueued with zero and never inherits a mouse
                            // gesture's state.
                            modifierFlags: Int64(nativeEvent.modifierFlags)
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
                let rejectsReboundPressActivation = nativeEvent.eventKind == 27u32 &&
                    consumeSuppressedPressActivation(continuation)
                if (continuation.nodeId == nodeId && !rejectsReboundPressActivation) {
                    let controllerVersionBefore = controller.uiSceneVersion()
                    rememberInteraction(continuation, Int64(nativeEvent.eventKind), Int64(nativeEvent.selectionStart),
                        Int64(nativeEvent.selectionEnd))
                    let dispatch = controller.applyUiEvent(
                        CjguiComposableUiEvent(
                            continuation,
                            Int64(nativeEvent.eventKind),
                            eventText,
                            Int64(nativeEvent.selectionStart),
                            Int64(nativeEvent.selectionEnd),
                            Int64(nativeEvent.projectionVersion),
                            // A queued pointer activation keeps the modifier
                            // state observed when that pointer event happened;
                            // keyboard/AX activations are enqueued with zero
                            // in the native bridge and therefore never inherit
                            // a previous mouse gesture's Command/Shift.
                            modifierFlags: Int64(nativeEvent.modifierFlags)
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
                    if (nativeEvent.eventKind == 31u32 && controller.uiSceneVersion() == controllerVersionBefore) {
                        // Focus paint is framework-local when the owner did
                        // not change its declared scene. Preserve the system
                        // text proxy and reuse the accepted geometry.
                        requiresInteractionPaint = true
                    } else {
                        requiresProjection = true
                    }
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
        } else if (requiresInteractionPaint) {
            let _ = refreshInteractionPaintIfNeeded()
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

    /// Returns exactly one pending standard-Quit intent for this window.
    /// Acknowledgement clears native coalescing before the application asks
    /// its decision provider, so a rejected request leaves a later human Quit
    /// available while repeated clicks before that turn remain idempotent.
    public func consumeApplicationExitRequest(): Bool {
        if (!applicationExitRequested) {
            return false
        }
        applicationExitRequested = false
        internalRendererCompleteApplicationExitRequest()
        return true
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
            if (binding.declaration.id == command.id || (binding.declaration.hasShortcut() && command.hasShortcut() &&
                binding.declaration.shortcut.encoded() == command.shortcut.encoded() &&
                binding.declaration.focusScopeId == command.focusScopeId)) {
                return false
            }
        }
        if (isWindowOpen) {
            let replacement = ArrayList<CjguiComposableUiCommand>()
            for (binding in commandBindings) {
                replacement.add(binding.declaration)
            }
            replacement.add(command)
            if (!commandsValidForAcceptedScene(replacement) || !replaceNativeCommandMenu(replacement,
                UInt64(nativeInputScene.version), nativeInputScopesFor(nativeInputScene))) {
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
        if (!replaceNativeCommandMenu(commands, UInt64(nativeInputScene.version), nativeInputScopesFor(nativeInputScene))) {
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
                if (isWindowOpen) {
                    let replacement = ArrayList<CjguiComposableUiCommand>()
                    var replacementIndex: Int64 = 0
                    while (replacementIndex < commandBindings.size) {
                        if (replacementIndex != index) {
                            replacement.add(commandBindings[replacementIndex].declaration)
                        }
                        replacementIndex += 1
                    }
                    if (!replaceNativeCommandMenu(replacement, UInt64(nativeInputScene.version),
                        nativeInputScopesFor(nativeInputScene))) {
                        return false
                    }
                }
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
    // Probe-only snapshot of timings captured inside one actual
    // `syncProjection` execution. It cannot trigger a refresh or expose a
    // native handle, and it intentionally stays outside the public consumer
    // projection contract.
    func testRefreshTiming(): CjguiComposableUiRefreshTiming {
        return lastRefreshTiming
    }
    /// Package-only input provenance trace. It exposes copied action text and
    /// booleans only; no native handle or controller object reaches probes.
    func testPressedInteractionActionName(): String {
        return pressedInteractionNode.actionName
    }
    func testLastTerminalPressIdentityChanged(): Bool {
        return lastTerminalPressIdentityChanged
    }
    func testLastPressActivationSuppressed(): Bool {
        return lastPressActivationSuppressed
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
        // Reset at the exact real-refresh boundary. Unreached phases retain
        // -1 on a rejection rather than borrowing a prior successful pass.
        lastRefreshTiming = CjguiComposableUiRefreshTiming()
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
            let buildElapsed = MonoTime.now() - buildStarted
            lastBuildElapsedMs = buildElapsed.toMilliseconds()
            lastRefreshTiming.buildNanoseconds = buildElapsed.toNanoseconds()
            buildPassCount += 1
            let identityResolutionStarted = MonoTime.now()
            let identityIssue = identityRegistry.resolveCandidate(declaredRoot)
            lastRefreshTiming.identityResolutionNanoseconds = elapsedNanoseconds(identityResolutionStarted)
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
            let candidateCloneStarted = MonoTime.now()
            let root = declaredRoot.cloneForWindowCandidate()
            let candidateRootIssue = identityRegistry.replaceCandidateRoot(root)
            lastRefreshTiming.candidateCloneNanoseconds = elapsedNanoseconds(candidateCloneStarted)
            if (candidateRootIssue.size > 0) {
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(candidateRootIssue)
            }
            if (let Some(value) <- participant) {
                let participantPreparationStarted = MonoTime.now()
                let prepared = value.prepareSceneRefresh()
                lastRefreshTiming.participantPreparationNanoseconds = elapsedNanoseconds(participantPreparationStarted)
                if (!prepared) {
                    return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
                }
            } else {
                lastRefreshTiming.participantPreparationNanoseconds = 0
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
            let layoutElapsed = MonoTime.now() - layoutStarted
            lastLayoutElapsedMs = layoutElapsed.toMilliseconds()
            lastRefreshTiming.layoutNanoseconds = layoutElapsed.toNanoseconds()
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
                return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                    reason: if (scene.layoutError().size > 0) {
                        scene.layoutError()
                    } else {
                        "invalid_scene"
                    })
            }
            let paintScene = sceneWithResolvedInteractionPaint(scene)
            // Do not let deterministic fallback geometry look like a successful
            // production AppKit projection. The previous committed scene remains
            // live because no native staging call has occurred yet.
            if (textMeasurer.measurementStatus() != CJGUI_INTERNAL_RENDERER_OK) {
                return rejectParticipantCandidate(participant, textMeasurer.measurementStatus())
            }
            let nodes = paintScene.nodes()
            lastRefreshTiming.candidateNodeCount = nodes.size
            if (nodes.size == 0 || nodes.size > 1024) {
                return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                    reason: "scene_node_count_invalid")
            }
            // The command menu and native scene must use one compact mapping:
            // AppKit can gate equal shortcuts by the same focus domain which
            // the Cangjie input route revalidates after FIFO delivery.
            let inputScopes = nativeInputScopesFor(paintScene)
            // Virtual rows are built during the canonical layout pass, so
            // their scoped declarations join this candidate before, never
            // after, the one irreversible prepare/commit boundary.
            let identityCandidatePrepareStarted = MonoTime.now()
            let identityCandidatePrepared = identityRegistry.prepareCandidate()
            lastRefreshTiming.identityCandidatePrepareNanoseconds = elapsedNanoseconds(identityCandidatePrepareStarted)
            if (!identityCandidatePrepared) {
                let dynamicIssue = identityRegistry.lastIssue()
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(dynamicIssue)
            }
            let commandBindingStarted = MonoTime.now()
            let candidateCommands = ArrayList<CjguiComposableUiCommand>()
            if (let Some(value) <- participant) {
                for (command in value.candidateSceneCommands()) {
                    candidateCommands.add(command)
                }
                if (!commandsValidForCandidateScene(candidateCommands, scene)) {
                    lastRefreshTiming.commandBindingNanoseconds = elapsedNanoseconds(commandBindingStarted)
                    return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                        reason: "candidate_commands_invalid")
                }
            } else {
                for (binding in commandBindings) {
                    candidateCommands.add(binding.declaration)
                }
            }
            lastRefreshTiming.commandBindingNanoseconds = elapsedNanoseconds(commandBindingStarted)
            let candidateDataTransferBindings = if (let Some(bindings) <- dataTransferBindingsFor(paintScene)) {
                bindings
            } else {
                return rejectParticipantCandidate(participant, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                    reason: "data_transfer_bindings_invalid")
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
            let sameSceneComparisonStarted = MonoTime.now()
            let matchesRenderedScene = sameRenderedScene(paintScene)
            lastRefreshTiming.sameSceneComparisonNanoseconds = elapsedNanoseconds(sameSceneComparisonStarted)
            if (!resourceCompletionChanged && !geometryChanged && matchesRenderedScene &&
                sameDataTransferBindings(candidateDataTransferBindings, dataTransferBindings)) {
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
                if (!replaceNativeCommandMenu(candidateCommands, UInt64(nativeInputScene.version), inputScopes)) {
                    return rejectParticipantCandidate(participant, lastNativeStatus)
                }
                acceptedCandidate = true
                identityRegistry.commitCandidate()
                flushPendingScopedFocus()
                if (!sameComponentTree(renderedRoot, root)) {
                    nextProjectionVersion = candidateVersion
                    renderedRoot = root
                    renderedScene = paintScene
                }
                if (let Some(value) <- participant) {
                    value.commitSceneRefresh()
                    replaceCommandBindings(candidateCommands)
                }
                replaceDataTransferBindings(candidateDataTransferBindings)
                acceptedSceneVersion = renderedScene.version
                lastControllerSceneVersion = declaredVersion
                lastViewportResizeVersion = viewport.resizeVersion
                lastResourceCompletionVersion = viewport.resourceCompletionVersion
                refreshRequested = false
                pendingRefreshReason = "none"
                // A semantic-only acceptance still clears a failure recorded by
                // an earlier rejected candidate: leaving it set would tell an
                // external operator that the window is still broken after it
                // recovered.
                lastNativeFailure = "none"
                // There is no native submission in this semantic-only branch,
                // but the Cangjie scene and commands are now accepted. Only this
                // boundary may promote derived layout candidates.
                layoutReuseCache.commitPass()
                reconcilePointerCaptureAfterProjection()
                return true
            }
            nextProjectionVersion = candidateVersion
            let stageAndSubmitStarted = MonoTime.now()
            lastNativeStatus = stageNativeCommandMenu(candidateCommands, UInt64(paintScene.version), inputScopes)
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            lastNativeStatus = internalRendererConfigureComposableScene(sessionToken, UInt64(paintScene.version),
                UInt32(nodes.size))
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
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
            // The native transaction starts from the previous generation. Its
            // compact scope IDs were assigned from that generation's traversal,
            // which can differ even when a retained node keeps the same symbolic
            // scope name (for example, when an earlier modal/layer scope is
            // removed). Rebuild that table as well so reuse never preserves a
            // stale native focus domain.
            let previousInputScopes = CjguiComposableUiNativeInputScopeTable()
            for (scopeNode in previousNativeNodes) {
                let _ = previousInputScopes.codeFor(scopeNode.inputScopeId)
            }
            var index: Int64 = 0
            while (index < nodes.size) {
                let node = nodes[index]
                let nativeInputScope = inputScopes.codeFor(node.inputScopeId)
                let previousNativeInputScope = if (index < previousNativeNodes.size) {
                    previousInputScopes.codeFor(previousNativeNodes[index].inputScopeId)
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
                    projectionVersion: UInt64(paintScene.version),
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
                    lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
                    return rejectParticipantCandidate(participant, lastNativeStatus)
                }
                index += 1
            }
            lastNativeStatus = stageNativeDataTransfer(candidateDataTransferBindings, paintScene.version)
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            let frame = internalRendererPresentComposableScene(sessionToken)
            let nativeStageAndSubmitElapsed = MonoTime.now() - stageAndSubmitStarted
            lastNativeStageAndSubmitElapsedMs = nativeStageAndSubmitElapsed.toMilliseconds()
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = nativeStageAndSubmitElapsed.toNanoseconds()
            lastNativeStatus = frame.status
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK && lastNativeStatus !=
                CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
                // The native side rolled its input/overlay snapshot back before
                // returning this presentation failure. Keep Cangjie's accepted
                // scene equally intact and wait for one explicit retry.
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            renderedRoot = root
            renderedScene = paintScene
            nativeInputScene = paintScene
            acceptedSceneVersion = paintScene.version
            submittedSceneVersion = paintScene.version
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
            flushPendingScopedFocus()
            // A participant's commit is only the Cangjie-side candidate swap;
            // it runs after, never instead of, native acceptance. Implementors
            // must keep it total. If an application callback nevertheless throws
            // here (or during focus restoration), the window is terminally
            // closed below rather than falsely rolling the accepted scene back.
            if (let Some(value) <- participant) {
                value.commitSceneRefresh()
                replaceCommandBindings(candidateCommands)
            }
            replaceDataTransferBindings(candidateDataTransferBindings)
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
    private func elapsedNanoseconds(started: MonoTime): Int64 {
        let elapsed = (MonoTime.now() - started).toNanoseconds()
        return if (elapsed >= 0) {
            elapsed
        } else {
            0
        }
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
    /// Focus the layout node declared with this scoped identity, when the
    /// accepted scene still contains it. A controller whose own model moved its
    /// focus (for example tree keyboard navigation) calls this so the native
    /// focus, the component's logical focus and the materialized row stay one
    /// thing: a later key event is routed by the native focus, and a row removed
    /// in between would otherwise leave the keyboard with no target.
    ///
    /// Experimental: the identity vocabulary is the same one the component
    /// declaration uses; nothing native crosses this boundary.
    public func focusScopedNode(scope: CjguiComposableUiIdentityScope, localKey: String): Bool {
        let reference = CjguiComposableUiNodeReference.scoped(scope, localKey)
        let nodeId = identityRegistry.acceptedNodeIdForReference(reference)
        if (nodeId < 0) {
            // The row may only exist once the scene that materializes it has
            // been accepted (an off-screen tree target that was just revealed).
            // Remember the request and retry right after the next commit
            // instead of dropping it and leaving the keyboard without a target.
            pendingScopedFocusScope = Some(scope)
            pendingScopedFocusKey = localKey
            return false
        }
        pendingScopedFocusScope = None
        pendingScopedFocusKey = ""
        return focusProjectedNode(nodeId)
    }

    /// Satisfies a focus request whose row was not in the accepted scene yet.
    private func flushPendingScopedFocus(): Unit {
        if (let Some(scope) <- pendingScopedFocusScope) {
            let key = pendingScopedFocusKey
            pendingScopedFocusScope = None
            pendingScopedFocusKey = ""
            let _ = focusScopedNode(scope, key)
        }
    }

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
    private func sameInteractionSlot(left: CjguiComposableUiLayoutNode,
        right: CjguiComposableUiLayoutNode): Bool {
        return left.nodeId >= 0 && left.nodeId == right.nodeId && left.resourceId == right.resourceId &&
            left.nodeKind == right.nodeKind
    }
    /// A press is bound to the declarative action and focus context seen at
    /// press-down, not merely to a recyclable renderer slot. Hover may retain
    /// its visual slot across a caption/action refresh, but a later release
    /// must never turn an old press into the replacement action.
    private func samePressActivationIdentity(left: CjguiComposableUiLayoutNode,
        right: CjguiComposableUiLayoutNode): Bool {
        return sameInteractionSlot(left, right) && left.semanticId == right.semanticId && left.actionName == right.actionName &&
            left.fieldId == right.fieldId && left.operationActionName == right.operationActionName &&
            left.operationResourceId == right.operationResourceId && left.inputScopeId == right.inputScopeId
    }
    private func consumeSuppressedPressActivation(target: CjguiComposableUiLayoutNode): Bool {
        if (!sameInteractionSlot(suppressedPressActivationNode, target)) {
            return false
        }
        suppressedPressActivationNode = CjguiComposableUiLayoutNode.missing()
        lastPressActivationSuppressed = true
        return true
    }
    private func interactionStateFor(node: CjguiComposableUiLayoutNode): Int64 {
        var state = node.ownerInteractionState
        if (!node.isEnabled) {
            state = state | CjguiComposableUiInteractionState.DISABLED
        } else {
            if (sameInteractionSlot(node, hoveredInteractionNode)) {
                state = state | CjguiComposableUiInteractionState.HOVER
            }
            if (samePressActivationIdentity(node, pressedInteractionNode)) {
                state = state | CjguiComposableUiInteractionState.PRESSED
            }
            if (node.nodeId == focusedNodeId && node.resourceId == focusedResourceId && node.nodeKind == focusedNodeKind) {
                state = state | CjguiComposableUiInteractionState.FOCUSED
            }
        }
        return state
    }
    /// Resolve one accepted layout snapshot into paint output without calling
    /// a controller, text measurer or layout engine. The returned nodes keep
    /// their declared style and every geometry/input identity intact.
    private func sceneWithResolvedInteractionPaint(source: CjguiComposableUiScene,
        version!: Int64 = -1): CjguiComposableUiScene {
        let resolved = ArrayList<CjguiComposableUiLayoutNode>()
        for (node in source.nodes()) {
            let style = node.interactionStyle.resolve(node.declaredStyle, interactionStateFor(node))
            if (sameStyle(node.style, style)) {
                resolved.add(node)
            } else {
                resolved.add(node.withResolvedPaintStyle(style))
            }
        }
        return CjguiComposableUiScene(if (version > 0) { version } else { source.version }, source.viewport, resolved,
            valid: source.isValid(), layoutError: source.layoutError())
    }
    private func reconcileInteractionProjection(): Bool {
        let currentHover = nativeInputScene.nodeForId(hoveredInteractionNode.nodeId)
        if (!sameInteractionSlot(currentHover, hoveredInteractionNode) || !currentHover.isEnabled) {
            hoveredInteractionNode = CjguiComposableUiLayoutNode.missing()
        }
        // A repaint may run between a domain replacement and the paired
        // terminal interaction event.  Keep the press-down snapshot until
        // that release/cancel is drained: event 46 compares it with the
        // current native target and records the one-shot activation
        // suppression when their semantic identity changed.  Clearing it
        // here would make a later generic activation indistinguishable from
        // a new action on the replacement node.  Rendering remains safe:
        // `interactionStateFor` applies PRESSED only when the current node
        // still has that same activation identity, and a later press simply
        // replaces this bounded snapshot.
        return true
    }

    /// Stage one already-resolved node into the native transaction. This is
    /// shared by the normal scene path and the interaction-only paint path;
    /// callers decide whether an unchanged node can be reused before entering
    /// here. No layout, measurement, or controller callback happens here.
    private func stageComposableSceneNode(node: CjguiComposableUiLayoutNode, projectionVersion: Int64,
        index: Int64, nativeInputScope: UInt64): Int32 {
        let style = node.style
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
            projectionVersion: UInt64(projectionVersion),
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
        return internalRendererSetComposableSceneNode(
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
    }

    /// Repaint interaction state from the accepted layout snapshot. This is
    /// intentionally independent of `refreshIfNeeded`: a hover/press/focus
    /// change cannot call buildUi, layout or text measurement and does not
    /// advance the controller's UI revision.
    private func refreshInteractionPaintIfNeeded(): Bool {
        if (!isWindowOpen || nativeInputScene.version <= 0) {
            return true
        }
        // Keep this package-only timing snapshot at the same boundary as the
        // ordinary refresh transaction.  A probe can then distinguish style
        // resolution, comparison and native stage/present without exposing
        // diagnostics to public consumers.
        lastRefreshTiming = CjguiComposableUiRefreshTiming()
        let _ = reconcileInteractionProjection()
        let candidateVersion = if (nextProjectionVersion <= 0) {
            1
        } else {
            nextProjectionVersion + 1
        }
        let resolutionStarted = MonoTime.now()
        let paintScene = sceneWithResolvedInteractionPaint(nativeInputScene, version: candidateVersion)
        lastRefreshTiming.interactionPaintResolutionNanoseconds = elapsedNanoseconds(resolutionStarted)
        let previousNodes = nativeInputScene.nodes()
        let nextNodes = paintScene.nodes()
        lastRefreshTiming.candidateNodeCount = nextNodes.size
        if (previousNodes.size != nextNodes.size) {
            return noteInteractionPaintFailure(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        }
        var samePaint = true
        let comparisonStarted = MonoTime.now()
        var compareIndex: Int64 = 0
        while (compareIndex < nextNodes.size) {
            if (!sameLayoutNode(previousNodes[compareIndex], nextNodes[compareIndex])) {
                samePaint = false
                break
            }
            compareIndex += 1
        }
        lastRefreshTiming.interactionPaintComparisonNanoseconds = elapsedNanoseconds(comparisonStarted)
        if (samePaint) {
            return true
        }
        let stageStarted = MonoTime.now()
        lastNativeStatus = internalRendererConfigureComposableScene(sessionToken, UInt64(candidateVersion),
            UInt32(nextNodes.size))
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageStarted)
            return noteInteractionPaintFailure(lastNativeStatus)
        }
        let previousInputScopes = CjguiComposableUiNativeInputScopeTable()
        let nextInputScopes = CjguiComposableUiNativeInputScopeTable()
        for (node in previousNodes) {
            let _ = previousInputScopes.codeFor(node.inputScopeId)
        }
        for (node in nextNodes) {
            let _ = nextInputScopes.codeFor(node.inputScopeId)
        }
        // Native commits a scene and its command-menu generation atomically.
        // Interaction paint does not change command declarations, but it still
        // advances the accepted scene version; restage the existing Cangjie
        // declarations under that version without entering the controller.
        let interactionCommands = ArrayList<CjguiComposableUiCommand>()
        for (binding in commandBindings) {
            interactionCommands.add(binding.declaration)
        }
        lastNativeStatus = stageNativeCommandMenu(interactionCommands, UInt64(candidateVersion), nextInputScopes)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageStarted)
            return noteInteractionPaintFailure(lastNativeStatus)
        }
        let interactionDataTransferBindings = if (let Some(bindings) <- dataTransferBindingsForAcceptedScene(paintScene)) {
            bindings
        } else {
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageStarted)
            return noteInteractionPaintFailure(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        }
        var index: Int64 = 0
        while (index < nextNodes.size) {
            let node = nextNodes[index]
            let nativeInputScope = nextInputScopes.codeFor(node.inputScopeId)
            let previousNativeInputScope = previousInputScopes.codeFor(previousNodes[index].inputScopeId)
            if (!sameLayoutNode(previousNodes[index], node) || previousNativeInputScope != nativeInputScope) {
                lastNativeStatus = stageComposableSceneNode(node, candidateVersion, index, nativeInputScope)
                if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                    lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageStarted)
                    return noteInteractionPaintFailure(lastNativeStatus)
                }
            }
            index += 1
        }
        lastNativeStatus = stageNativeDataTransfer(interactionDataTransferBindings, candidateVersion)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageStarted)
            return noteInteractionPaintFailure(lastNativeStatus)
        }
        let frame = internalRendererPresentComposableScene(sessionToken)
        let elapsed = MonoTime.now() - stageStarted
        lastNativeStageAndSubmitElapsedMs = elapsed.toMilliseconds()
        lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsed.toNanoseconds()
        lastNativeStatus = frame.status
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK && lastNativeStatus !=
            CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
            return noteInteractionPaintFailure(lastNativeStatus)
        }
        nextProjectionVersion = candidateVersion
        renderedScene = paintScene
        nativeInputScene = paintScene
        replaceDataTransferBindings(interactionDataTransferBindings)
        acceptedSceneVersion = paintScene.version
        submittedSceneVersion = paintScene.version
        submittedFrameIndex = Int64(frame.frameIndex)
        nativeSubmissionCount += 1
        if (frame.readbackCompleted != 0u8) {
            observedMetalCompletionFrameIndex = Int64(frame.frameIndex)
        }
        lastNativeFailure = if (lastNativeStatus == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
            nativeStatusReason(lastNativeStatus)
        } else {
            "none"
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
        if (nativeProjectionVersion >= 0 && Int64(nativeInputScene.version) != nativeProjectionVersion) {
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
            if (commandMatches(declaration, command, matchesId) &&
                declaration.focusScopeId.size > 0 && declaration.focusScopeId == focusedScope) {
                let node = commandTargetForAcceptedScene(nativeInputScene, declaration)
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
            if (commandMatches(declaration, command, matchesId) &&
                declaration.focusScopeId.size == 0) {
                let node = commandTargetForAcceptedScene(nativeInputScene, declaration)
                if (commandTargetIsLive(node, declaration, focusedScope)) {
                    return node
                }
            }
        }
        return CjguiComposableUiLayoutNode.missing()
    }
    private func commandTargetIsLive(node: CjguiComposableUiLayoutNode, declaration: CjguiComposableUiCommand,
        focusedScope: String): Bool {
        return commandTargetIsDeclared(node, declaration) && declaration.isEnabled && node.canReceiveInput() &&
            (declaration.focusScopeId.size == 0 || declaration.focusScopeId == focusedScope)
    }
    private func commandsValidForAcceptedScene(commands: ArrayList<CjguiComposableUiCommand>): Bool {
        return commandsValidForResolvedScene(commands, nativeInputScene, false)
    }
    private func commandsValidForCandidateScene(commands: ArrayList<CjguiComposableUiCommand>, scene: CjguiComposableUiScene): Bool {
        return commandsValidForResolvedScene(commands, scene, true)
    }
    private func commandsValidForResolvedScene(commands: ArrayList<CjguiComposableUiCommand>, scene: CjguiComposableUiScene,
        candidateReferences: Bool): Bool {
        var index: Int64 = 0
        while (index < commands.size) {
            let command = commands[index]
            if (!command.isValid()) {
                return false
            }
            let target = if (candidateReferences) {
                commandTargetForCandidateScene(scene, command)
            } else {
                commandTargetForAcceptedScene(scene, command)
            }
            // A disabled command remains a valid declaration so a menu can
            // project its disabled state.  Invocation still checks current
            // availability in `commandTargetIsLive`.
            if (!commandTargetIsDeclared(target, command)) {
                return false
            }
            var prior: Int64 = 0
            while (prior < index) {
                if (commands[prior].id == command.id || (commands[prior].hasShortcut() && command.hasShortcut() &&
                    commands[prior].shortcut.encoded() == command.shortcut.encoded() &&
                    commands[prior].focusScopeId == command.focusScopeId)) {
                    return false
                }
                prior += 1
            }
            index += 1
        }
        return true
    }
    private func commandMatches(declaration: CjguiComposableUiCommand, command: String, matchesId: Bool): Bool {
        if (matchesId) {
            return declaration.id == command
        }
        return declaration.hasShortcut() && declaration.shortcut.encoded() == command
    }
    private func commandTargetForCandidateScene(scene: CjguiComposableUiScene,
        declaration: CjguiComposableUiCommand): CjguiComposableUiLayoutNode {
        return scene.nodeForId(identityRegistry.candidateNodeIdForReference(declaration.targetReference))
    }
    private func commandTargetForAcceptedScene(scene: CjguiComposableUiScene,
        declaration: CjguiComposableUiCommand): CjguiComposableUiLayoutNode {
        return scene.nodeForId(identityRegistry.acceptedNodeIdForReference(declaration.targetReference))
    }
    private func commandTargetIsDeclared(node: CjguiComposableUiLayoutNode,
        declaration: CjguiComposableUiCommand): Bool {
        return node.nodeId >= 0 && node.actionName.size > 0 && node.inputScopeId == declaration.focusScopeId
    }
    /// Stage only scalar menu projection data. Native copies every string,
    /// owns no action callback, and promotes the staged values with the scene
    /// transaction (or by this explicit state-only commit).
    private func nativeInputScopesFor(scene: CjguiComposableUiScene): CjguiComposableUiNativeInputScopeTable {
        // Scope values are opaque within a scene. Assign compact IDs rather
        // than hashing arbitrary layer names into checked UInt64 arithmetic.
        let scopes = CjguiComposableUiNativeInputScopeTable()
        for (node in scene.nodes()) {
            let _ = scopes.codeFor(node.inputScopeId)
        }
        return scopes
    }
    private func dataTransferProvider(): ?CjguiComposableUiDataTransferProvider {
        return controller as CjguiComposableUiDataTransferProvider
    }
    private func nativeDataTransferFormat(format: CjguiSharedOperationTransferFormat): String {
        return if (format.kind == "UTF8_TEXT") { "text/plain" } else { format.identifier }
    }
    private func dataTransferBindingsFor(scene: CjguiComposableUiScene): ?ArrayList<CjguiComposableUiDataTransferBinding> {
        if (let Some(provider) <- dataTransferProvider()) {
            let declarations = provider.dataTransferDeclarations()
            if (declarations.size > 128) { return None }
            let bindings = ArrayList<CjguiComposableUiDataTransferBinding>()
            var declarationIndex: Int64 = 0
            while (declarationIndex < declarations.size) {
                let declaration = declarations[declarationIndex]
                if (!declaration.isValid() || declaration.format.maximumBytes > 512 * 1024) {
                    return None
                }
                let nativeFormat = nativeDataTransferFormat(declaration.format)
                if (nativeFormat != "text/plain" && !nativeFormat.startsWith("application/") &&
                    !nativeFormat.startsWith("cjgui.")) {
                    return None
                }
                var matching = CjguiComposableUiLayoutNode.missing()
                var nodeIndex: Int64 = 0
                while (nodeIndex < scene.nodes().size) {
                    let candidate = scene.nodes()[nodeIndex]
                    if (candidate.semanticId == declaration.semanticId) {
                        if (matching.nodeId >= 0) { return None }
                        matching = candidate
                    }
                    nodeIndex += 1
                }
                // A declaration stays part of its controller's stable offer
                // even while a control is disabled. That is an ordinary
                // unavailable endpoint, not a malformed candidate scene:
                // omit it from this native generation so neither paste nor
                // drop can reach its owner, while unrelated controls keep
                // their accepted projection.
                if (matching.nodeId < 0) {
                    return None
                }
                if (!matching.isEnabled) {
                    declarationIndex += 1
                    continue
                }
                if (!matching.canReceiveInput() || matching.isReadOnly) {
                    return None
                }
                var prior: Int64 = 0
                while (prior < bindings.size) {
                    let existing = bindings[prior]
                    if (existing.node.nodeId == matching.nodeId && existing.node.resourceId == matching.resourceId &&
                        existing.declaration.role == declaration.role && existing.nativeFormat == nativeFormat) {
                        return None
                    }
                    prior += 1
                }
                bindings.add(CjguiComposableUiDataTransferBinding(declaration, matching, nativeFormat))
                declarationIndex += 1
            }
            return Some(bindings)
        }
        return Some(ArrayList<CjguiComposableUiDataTransferBinding>())
    }
    /// Interaction-only presentation changes may advance the native scene
    /// version without asking the application to build a new offer. Rebind the
    /// last accepted declarations to their new layout nodes so native never
    /// retains a pre-paint node identity or payload by accident.
    private func dataTransferBindingsForAcceptedScene(
        scene: CjguiComposableUiScene
    ): ?ArrayList<CjguiComposableUiDataTransferBinding> {
        let bindings = ArrayList<CjguiComposableUiDataTransferBinding>()
        let nodes = scene.nodes()
        for (accepted in dataTransferBindings) {
            var matching = CjguiComposableUiLayoutNode.missing()
            for (candidate in nodes) {
                if (candidate.semanticId == accepted.declaration.semanticId) {
                    if (matching.nodeId >= 0) { return None }
                    matching = candidate
                }
            }
            // Interaction-only repaint may disable a previously staged
            // endpoint. Rebind the surviving declarations only; keeping the
            // old native item would turn a disabled target into a stale
            // receiver, while rejecting the entire repaint would make normal
            // availability state a window failure.
            if (matching.nodeId < 0) {
                return None
            }
            if (!matching.isEnabled) {
                continue
            }
            if (!matching.canReceiveInput() || matching.isReadOnly) {
                return None
            }
            bindings.add(CjguiComposableUiDataTransferBinding(accepted.declaration, matching, accepted.nativeFormat))
        }
        return Some(bindings)
    }
    private func sameDataTransferBindings(
        left: ArrayList<CjguiComposableUiDataTransferBinding>, right: ArrayList<CjguiComposableUiDataTransferBinding>
    ): Bool {
        if (left.size != right.size) { return false }
        var index: Int64 = 0
        while (index < left.size) {
            let lhs = left[index]
            let rhs = right[index]
            if (lhs.node.nodeId != rhs.node.nodeId || lhs.node.resourceId != rhs.node.resourceId ||
                lhs.node.nodeKind != rhs.node.nodeKind || lhs.declaration.semanticId != rhs.declaration.semanticId ||
                lhs.declaration.role != rhs.declaration.role || lhs.nativeFormat != rhs.nativeFormat ||
                lhs.declaration.format.kind != rhs.declaration.format.kind ||
                lhs.declaration.format.identifier != rhs.declaration.format.identifier ||
                lhs.declaration.format.version != rhs.declaration.format.version ||
                lhs.declaration.format.maximumBytes != rhs.declaration.format.maximumBytes) {
                return false
            }
            let leftPayload = if (let Some(offer) <- lhs.declaration.offer) { offer.payload } else { "" }
            let rightPayload = if (let Some(offer) <- rhs.declaration.offer) { offer.payload } else { "" }
            if (leftPayload != rightPayload) { return false }
            index += 1
        }
        return true
    }
    private func replaceDataTransferBindings(bindings: ArrayList<CjguiComposableUiDataTransferBinding>): Unit {
        dataTransferBindings.clear()
        for (binding in bindings) {
            dataTransferBindings.add(binding)
        }
    }
    private func stageNativeDataTransfer(
        bindings: ArrayList<CjguiComposableUiDataTransferBinding>, projectionVersion: Int64
    ): Int32 {
        var status = internalRendererConfigureComposableDataTransfer(sessionToken, UInt64(projectionVersion),
            UInt32(bindings.size))
        if (status != CJGUI_INTERNAL_RENDERER_OK) { return status }
        var index: Int64 = 0
        while (index < bindings.size) {
            let binding = bindings[index]
            let declaration = binding.declaration
            let node = binding.node
            let role: UInt32 = if (declaration.role == "SOURCE") { 1u32 } else { 2u32 }
            let payload = if (let Some(offer) <- declaration.offer) { offer.payload } else { "" }
            let sourceKind = if (let Some(offer) <- declaration.offer) { offer.sourceKind } else { "" }
            let sourceIdentity = if (let Some(offer) <- declaration.offer) { offer.sourceIdentity } else { "" }
            let sourceId = if (let Some(offer) <- declaration.offer) { offer.sourceId } else { -1 }
            status = internalRendererSetComposableDataTransferItem(
                sessionToken,
                UInt32(index),
                CjguiInternalRendererComposableDataTransferItem(
                    nodeId: UInt64(node.nodeId), projectionVersion: UInt64(projectionVersion),
                    resourceId: node.resourceId, nodeKind: UInt32(node.nodeKind), role: role,
                    maximumPayloadBytes: UInt32(declaration.format.maximumBytes), sourceId: sourceId
                ),
                binding.nativeFormat,
                payload,
                sourceKind,
                sourceIdentity
            )
            if (status != CJGUI_INTERNAL_RENDERER_OK) { return status }
            index += 1
        }
        return CJGUI_INTERNAL_RENDERER_OK
    }
    private func dataTransferBindingFor(
        node: CjguiComposableUiLayoutNode, eventKind: Int64, nativeFormat: String
    ): ?CjguiComposableUiDataTransferBinding {
        let role = if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) { "SOURCE" } else { "TARGET" }
        for (binding in dataTransferBindings) {
            if (binding.declaration.role == role && binding.nativeFormat == nativeFormat &&
                binding.node.nodeId == node.nodeId && binding.node.resourceId == node.resourceId &&
                binding.node.nodeKind == node.nodeKind) {
                return Some(binding)
            }
        }
        return None
    }
    private func applyDataTransfer(
        node: CjguiComposableUiLayoutNode, eventKind: Int64, payload: String,
        nativeFormat: String, sourceKind: String, sourceIdentity: String, sourceId: Int64, projectionVersion: Int64
    ): CjguiComposableUiDispatchResult {
        if (let Some(provider) <- dataTransferProvider()) {
            if (let Some(binding) <- dataTransferBindingFor(node, eventKind, nativeFormat)) {
                if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
                    if (let Some(value) <- binding.declaration.offer) {
                        return provider.applyDataTransfer(CjguiComposableUiDataTransferEvent(
                            node, eventKind, value, binding.declaration.format, projectionVersion))
                    }
                } else if (let Some(value) <- CjguiSharedOperationTransferOffer.create(
                    "COPY", if (sourceKind.size > 0) { sourceKind } else { "external_pasteboard" },
                    if (sourceIdentity.size > 0) { sourceIdentity } else { "macos" },
                    if (sourceId >= 0) { sourceId } else { 0 }, binding.declaration.format, payload)) {
                    return provider.applyDataTransfer(CjguiComposableUiDataTransferEvent(
                        node, eventKind, value, binding.declaration.format, projectionVersion))
                }
            }
        }
        return controller.rejectUiEvent(eventKind, node.nodeId)
    }
    private func stageNativeCommandMenu(commands: ArrayList<CjguiComposableUiCommand>,
        projectionVersion: UInt64, inputScopes: CjguiComposableUiNativeInputScopeTable): Int32 {
        if (commands.size > 128) {
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        }
        var status = internalRendererConfigureComposableCommandMenu(sessionToken, projectionVersion,
            UInt32(commands.size))
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return status
        }
        var index: Int64 = 0
        while (index < commands.size) {
            let command = commands[index]
            status = internalRendererSetComposableCommandMenuItem(
                sessionToken,
                UInt32(index),
                command.id,
                command.displayName,
                command.menuGroup,
                if (command.hasShortcut()) {
                    command.shortcut.encoded()
                } else {
                    ""
                },
                nonnegativeUInt32(command.menuSection),
                inputScopes.codeFor(command.focusScopeId),
                command.isEnabled,
                command.isChecked
            )
            if (status != CJGUI_INTERNAL_RENDERER_OK) {
                return status
            }
            index += 1
        }
        return CJGUI_INTERNAL_RENDERER_OK
    }
    private func replaceNativeCommandMenu(commands: ArrayList<CjguiComposableUiCommand>,
        projectionVersion: UInt64, inputScopes: CjguiComposableUiNativeInputScopeTable): Bool {
        lastNativeStatus = stageNativeCommandMenu(commands, projectionVersion, inputScopes)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            return false
        }
        lastNativeStatus = internalRendererCommitComposableCommandMenu(sessionToken)
        return lastNativeStatus == CJGUI_INTERNAL_RENDERER_OK
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
                    pointerY: y,
                    modifierFlags: Int64(nativeEvent.modifierFlags)
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
    /// Rejects the candidate and keeps the accepted scene live. A concrete
    /// rejection reason (for example `duplicate_node_id` from an invalid
    /// candidate scene) is published through window progress instead of
    /// collapsing into the generic renderer status text: an external operator
    /// driving this window must be able to tell *why* the visible scene did not
    /// follow its change, without a diagnostic build.
    private func rejectParticipantCandidate(participant: ?CjguiComposableUiSceneRefreshParticipant, status: Int32,
        reason!: String = ""): Bool {
        layoutReuseCache.discardPass()
        if (let Some(value) <- participant) {
            value.rollbackSceneRefresh()
        }
        identityRegistry.rollbackCandidate()
        if (reason.size > 0) {
            lastNativeStatus = status
            lastNativeFailure = reason
            pendingRefreshReason = "refresh_${reason}"
            refreshRequested = false
            return false
        }
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
    /// Interaction paint stages against an already accepted Cangjie scene, so
    /// a native rejection must retain that scene and wait for a caller's
    /// explicit retry. Unlike a full projection candidate, it owns no pending
    /// layout-cache pass to discard.
    private func noteInteractionPaintFailure(status: Int32): Bool {
        lastNativeStatus = status
        let reason = nativeStatusReason(status)
        lastNativeFailure = reason
        pendingRefreshReason = "interaction_paint_${reason}"
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
        hoveredInteractionNode = CjguiComposableUiLayoutNode.missing()
        pressedInteractionNode = CjguiComposableUiLayoutNode.missing()
        suppressedPressActivationNode = CjguiComposableUiLayoutNode.missing()
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
