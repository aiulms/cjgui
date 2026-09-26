package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
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

/// A human text edit delivered as an edit delta instead of the whole value.
/// `selectionStart`/`selectionEnd` are the replaced UTF-16 range in the value
/// the event was projected from, and `text` is the inserted replacement
/// string. `CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED` (28) keeps its existing
/// "here is the resulting value" meaning, so current consumers are unaffected.
public let CJGUI_COMPOSABLE_UI_EVENT_TEXT_RANGE_CHANGED: Int64 = 51

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

/// Allocates the per-PROCESS identity of one window INSTANCE. Shared mutable view
/// state (scroll viewport, split size, active tab page) belongs to exactly one
/// window, so the framework needs a cheap way to name that window without
/// building a second global registry.
private class CjguiComposableUiWindowInstanceAllocator {
    private static let allocationLock = Mutex()
    private static var nextInstanceToken: Int64 = 1

    public static func allocate(): Int64 {
        return synchronized(CjguiComposableUiWindowInstanceAllocator.allocationLock) {
            let token = CjguiComposableUiWindowInstanceAllocator.nextInstanceToken
            CjguiComposableUiWindowInstanceAllocator.nextInstanceToken += 1
            return token
        }
    }
}

/// B2: the bounded per-page focus/selection bookmark. It records WHERE a person
/// was (an accepted identity, its resource/kind, and a selection position), never
/// a business value: a value the owner changed while the page was hidden is read
/// from the owner on the next accepted scene, and a stale position is bounded or
/// dropped instead of replayed.
private class CjguiComposableUiPageFocusBookmark {
    let groupIdentity: Int64
    let pageKey: String
    let nodeId: Int64
    let resourceId: Int64
    let nodeKind: Int64
    let selectionStart: Int64
    let selectionEnd: Int64
    /// UTF-16 code units, matching AppKit's NSRange selection positions.
    let valueLength: Int64

    init(groupIdentity: Int64, pageKey: String, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        selectionStart: Int64, selectionEnd: Int64, valueLength: Int64) {
        this.groupIdentity = groupIdentity
        this.pageKey = pageKey
        this.nodeId = nodeId
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.valueLength = valueLength
    }
}

private func cjguiSelectionUtf16Length(value: String): Int64 {
    var length: Int64 = 0
    for (rune in value.runes()) {
        length += if (rune.toString().size == 4) { 2 } else { 1 }
    }
    return length
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
    /// Releases view-owned resources when the window is disposed (a normal close
    /// or a startup/native failure). The default does nothing, so existing
    /// participants keep working; a participant that holds references into a
    /// SHARED catalog releases exactly its own holds here, and the release must
    /// be idempotent because dispose can run more than once for one window.
    func disposeSceneRefreshResources(): Unit {
    }
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

/// Test-only snapshot of one successful native scene submission.
///
/// It exists so a bounded latency probe can attribute the exact submission that
/// carried a value to the host's monotonic clock, using the SAME window state the
/// window really committed. It exposes no native handle and is not a business
/// result; a normal consumer never needs it.
public class CjguiComposableUiNativeSubmissionSnapshot {
    public let time: MonoTime
    public let acceptedSceneVersion: Int64
    public let submittedSceneVersion: Int64
    public let submissionCount: Int64

    public init(time: MonoTime, acceptedSceneVersion: Int64, submittedSceneVersion: Int64,
                submissionCount: Int64) {
        this.time = time
        this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedSceneVersion = submittedSceneVersion
        this.submissionCount = submissionCount
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

/// A1：一次 PENDING 提交的原事务。native 拥有提交任务、原生资源与提交结果；
/// 核心记录「结算这一次提交」所需的全部原事实，使“提交新候选”与“查询原提交”
/// 拆成两个入口之后，收尾仍然只用原事实完成，不去读最新 owner。
///
/// 保存的可变对象引用都是**本次候选自己的快照**（`cloneForWindowCandidate()` /
/// `sceneWithResolvedInteractionPaint()` 的产物），不会被后续候选就地改写，因此
/// “保存引用”在这里等价于保存原事实。viewport 的 staged 数据属于窗口对象，仍在
/// 原处保留，直到本次结算把它提升或丢弃。
// A1 注入开关（默认恒 false，休眠）：仅由测试变体的验证接缝置位；普通产物
// 没有任何写入路径（verify 文件不编入）。置位后，生产结算路径的接受/回滚
// 回调以显式异常失败——异常结果仍由生产 settle 逻辑裁决（终止收敛），
// 闸门本身只注入失败，不产生任何“成功”。
public var CJGUI_WINDOW_GATE_ACCEPTANCE_THROW = false
public var CJGUI_WINDOW_GATE_ROLLBACK_THROW = false

private class CjguiComposableUiPendingPresentTransaction {
    /// 提交类型：0 = 完整刷新投影；1 = 交互投影。
    /// 交互投影没有 participant/identity/layout 候选，因此不得调用完整刷新的
    /// 回滚链，也只做自己的收尾（Astra：交互投影走自己的收尾）。
    let kind: Int64
    /// 本地单调递增的提交尝试编号（每窗口唯一在途事务的护栏）。
    let attemptId: Int64
    /// native 侧票据编号；0 表示 native 声称 PENDING 却没给票据（协议缺口）。
    let ticketId: UInt64
    /// 发起本次提交时的刷新请求代际。结算只消费它，不消费更新值。
    let consumedRequestEpoch: Int64
    /// 本次提交要晋升的场景（两类提交都有）。
    let paintScene: CjguiComposableUiScene
    // ---- kind = 0（完整刷新）专用 ----
    let root: ?CjguiComposableUiNode
    let previouslySubmittedScene: ?CjguiComposableUiScene
    let participant: ?CjguiComposableUiSceneRefreshParticipant
    let candidateCommands: ?ArrayList<CjguiComposableUiCommand>
    let candidateDataTransferBindings: ?ArrayList<CjguiComposableUiDataTransferBinding>
    let declaredVersion: Int64
    let viewportResizeVersion: UInt64
    let viewportResourceCompletionVersion: UInt64
    // ---- kind = 1（交互投影）专用 ----
    let interactionDataTransferBindings: ?ArrayList<CjguiComposableUiDataTransferBinding>
    /// 是否已结算。结算只发生一次；重复查询不得再次 commit/rollback。
    var settled: Bool = false
    // ---- A1：native 终态、核心收尾、ACK 完成三者分开 ----
    // settled 只表示 native 终态已观察（Accepted/Rejected），不再改判；
    // acceptanceStarted 表示核心收尾已进入过一次——一旦为真绝不再进入同一
    // 回调（防止重复 participant/focus 调用）；
    // coreSettled 表示核心收尾完整成功；ackCompleted 只表示原票 ACK 完成
    // （协议层了结），不得当成核心收尾成功；settlementFault 是核心未完整
    // 收尾时的命名原因（进入不可回滚的终止收敛路径）。
    var acceptanceStarted: Bool = false
    var coreSettled: Bool = false
    var ackCompleted: Bool = false
    var settlementFault: String = ""

    init(kind: Int64, attemptId: Int64, ticketId: UInt64, consumedRequestEpoch: Int64,
        paintScene: CjguiComposableUiScene, root!: ?CjguiComposableUiNode = None,
        previouslySubmittedScene!: ?CjguiComposableUiScene = None,
        participant!: ?CjguiComposableUiSceneRefreshParticipant = None,
        candidateCommands!: ?ArrayList<CjguiComposableUiCommand> = None,
        candidateDataTransferBindings!: ?ArrayList<CjguiComposableUiDataTransferBinding> = None,
        declaredVersion!: Int64 = 0, viewportResizeVersion!: UInt64 = 0u64,
        viewportResourceCompletionVersion!: UInt64 = 0u64,
        interactionDataTransferBindings!: ?ArrayList<CjguiComposableUiDataTransferBinding> = None) {
        this.kind = kind
        this.attemptId = attemptId
        this.ticketId = ticketId
        this.consumedRequestEpoch = consumedRequestEpoch
        this.paintScene = paintScene
        this.root = root
        this.previouslySubmittedScene = previouslySubmittedScene
        this.participant = participant
        this.candidateCommands = candidateCommands
        this.candidateDataTransferBindings = candidateDataTransferBindings
        this.declaredVersion = declaredVersion
        this.viewportResizeVersion = viewportResizeVersion
        this.viewportResourceCompletionVersion = viewportResourceCompletionVersion
        this.interactionDataTransferBindings = interactionDataTransferBindings
    }
}

/// A1：启动结果三分。Ready = 首帧已确认；AcceptedPending = native 已受理
/// 首帧票据（终态未定），宿主必须继续泵送至收敛；Failed = 真实失败，
/// 会话已按 start 的责任清理。
public enum CjguiComposableUiWindowStartOutcome {
    | StartReady
    | StartAcceptedPending
    | StartFailed
}

/// Normal macOS window consuming only Cangjie-computed generic scene nodes.
/// The native bridge sees neither consumer field names nor business command
/// branches; it receives copied geometry/style/semantics and returns a
/// bounded FIFO event with the rendered projection version.
public class CjguiComposableUiWindow <: CjguiSharedOperationWindowProjectionProvider & CjguiSharedOperationWindowProgressProvider {
    private let controller: CjguiComposableUiController
    /// The per-process identity of THIS window instance, used to detect a
    /// declaration that tries to share one mutable view object between windows.
    private let instanceToken: Int64 = CjguiComposableUiWindowInstanceAllocator.allocate()
    private let configuration: CjguiMacosApplicationWindowConfiguration
    private var sessionToken: UInt64
    private var isWindowOpen: Bool
    /// True when this window asked the native renderer to deliver explicit
    /// edit deltas for text nodes (see `rangeTextEditDeltaDeliveryEnabled`).
    private var textRangeEditDeltaDeliveryEnabled: Bool
    /// A range edit the application refused. The hidden proxy still holds the
    /// refused local text, so the next drain must roll it back to the value the
    /// owner actually accepted before any further delta is judged.
    private var refusedRangeTextPending: Bool
    private var refusedRangeTextNodeId: Int64
    private var refusedRangeTextResourceId: Int64
    private var refusedRangeTextNodeKind: Int64
    private var refusedRangeTextAttempts: Int64
    private var refusedRangeTextRecoveries: Int64
    private var refusedRangeTextFailures: Int64
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
    private var deferredInteractionPaint: Bool
    // A1 票据事务（Astra pending-transaction/answer.md 第 1/2 点）。native 拥有
    // 提交任务与原生资源；这里保存“结算这一次提交”所需的原事实快照，使
    // “提交新候选”和“查询原提交”拆开之后仍能只用原事实完成收尾，不读最新 owner。
    // 每窗口最多一个在途事务；attemptId 是它的护栏。
    private var pendingTransaction: ?CjguiComposableUiPendingPresentTransaction
    // A1：close 在票据未决时的持久意图；结算完成后由刷新门自动完成关闭。
    private var closeIntentPending: Bool
    // A1：首帧以 PENDING 受理后的启动状态。native 已收下首帧票据（终态未定），
    // 会话与原事务保留，宿主继续泵送至 Ready/失败；真实 Ready 时清零。
    private var startingPending: Bool
    // A1：最近一次核心收尾未完整的命名原因（终止收敛路径的可观察出口）。
    private var lastSettlementFault: String
    // A1：destroy 被拒绝（未确认票据在结算槽）时保留会话，待结算后重试 discard。
    private var discardRetryReason: String
    private var presentAttemptCounter: Int64
    // A1：刷新请求代际。等待期间新的 requestRefresh() 推进它；结算后只消费原事务
    // 记录的那个 epoch，更新的 epoch 必须触发下一轮刷新。这样「不可沿用原成功段
    // 无条件清 refreshRequested」不会把等待期间的新修改吞掉。
    private var refreshRequestEpoch: Int64
    private var deferredEventWork: Bool
    private var pendingRefreshReason: String
    private var lastNativeFailure: String
    // The initial scene may fail before a progress snapshot exists. Keep the
    // first rejecting stage through teardown; a later destroy status must not
    // replace the cause that made start() return false.
    private var startupPhase: String
    private var firstStartupFailure: String
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
    // Test-only: the FIRST reason this window stopped being open, so a bounded
    // scheduler probe can report why an instance retired instead of only that it
    // did. It records no business state and changes no close path.
    private var testCloseReason: String
    private var testCloseEventKind: Int64
    private var testCloseNativeStatus: Int32
    /// The most recent successful native submission, on the monotonic clock.
    private var lastNativeSubmissionSnapshotValue: ?CjguiComposableUiNativeSubmissionSnapshot
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

    /// The accepted rect of a scene node as (x, y, width, height).
    public func nodeRect(nodeId: Int64): ?(Int64, Int64, Int64, Int64) {
        var x: Int64 = 0
        var y: Int64 = 0
        var w: Int64 = 0
        var h: Int64 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_node_rect(this.sessionToken, UInt64(nodeId),
                inout x, inout y, inout w, inout h)
        }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return None
        }
        return (x, y, w, h)
    }

    /// (isKey, isMain, isAppActive) for this window.
    public func windowActivationState(): ?(Bool, Bool, Bool) {
        var key: Int32 = 0
        var mainWindow: Int32 = 0
        var active: Int32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_window_activation_state(this.sessionToken,
                inout key, inout mainWindow, inout active)
        }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return None
        }
        return (key != 0, mainWindow != 0, active != 0)
    }

    /// Bring this window to the front and make it key.
    public func activateWindow(): Bool {
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_activate_window(this.sessionToken)
        }
        return status == CJGUI_INTERNAL_RENDERER_OK
    }

    /// The window's on-screen frame as (x, y, width, height) with a top-left
    /// origin, so a caller can place a synthetic pointer at a scene point.
    public func windowScreenFrame(): ?(Int64, Int64, Int64, Int64) {
        var x: Int64 = 0
        var y: Int64 = 0
        var w: Int64 = 0
        var h: Int64 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_window_frame(this.sessionToken, inout x, inout y, inout w, inout h)
        }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return None
        }
        return (x, y, w, h)
    }

    /// Read-only hit test: a scene point becomes a UTF-8 display byte offset plus
    /// a caret affinity. Geometry comes from the same attributed text the raster
    /// path draws, so a hit and a painted glyph cannot disagree.
    /// The raw status of a hit-test attempt, so a caller can distinguish "the
    /// node is not in the accepted scene yet" from a programming error.
    public func hitTestComposableTextStatus(nodeId: Int64, x: Float64, y: Float64): Int64 {
        var offset: UInt32 = 0
        var affinity: UInt32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_hit_test_composable_text(this.sessionToken,
                UInt64(nodeId), x, y, inout offset, inout affinity)
        }
        return Int64(status)
    }

    public func hitTestComposableText(nodeId: Int64, x: Float64, y: Float64): ?(Int64, Int64) {
        var offset: UInt32 = 0
        var affinity: UInt32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_hit_test_composable_text(this.sessionToken,
                UInt64(nodeId), x, y, inout offset, inout affinity)
        }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return None
        }
        return (Int64(offset), Int64(affinity))
    }

    /// Scalar text measurement from the SAME session-backed measurer the layout
    /// uses. A presentation baseline needs the production metrics; the public
    /// fallback measurer is a non-AppKit estimate and must not stand in for it.
    public func measureComposableText(value: String, style: CjguiComposableUiStyle,
        maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        return this.textMeasurer.measure(value, style, maximumWidth)
    }

    /// The font-environment key behind the numbers above, so a caller can bind a
    /// cached measurement set to the environment that produced it.
    public func textMeasurementEnvironmentKey(): String {
        return this.textMeasurer.layoutMeasurementEnvironmentKey()
    }
    // Per-native-session, Cangjie-only derived layout cache. It retains no
    // controller/domain object and is recreated on a new session so stale
    // geometry, clip or input scopes cannot cross a generation boundary.
    private var layoutReuseCache: CjguiComposableUiLayoutReuseCache
    // Public scroll viewports the layout staged candidate facts for. The window
    // is the ONE place that promotes them with the accepted scene or discards
    // them on every rejection, so an application never writes its own rollback.
    private var stagedSceneViewports: ArrayList<CjguiComposableUiScrollViewport> =
        ArrayList<CjguiComposableUiScrollViewport>()
    // Candidate split track facts the layout staged for the SAME attempt. They
    // are promoted with the accepted scene and discarded with a rejected one, so
    // a trial layout never widens the bounds a real divider drag is clamped to.
    private var stagedSceneSplitTracks: ArrayList<CjguiComposableUiSplitTrackFact> =
        ArrayList<CjguiComposableUiSplitTrackFact>()
    // Shared MUTABLE view objects (scroll viewport, split size, active tab page)
    // this window newly bound in the candidate currently in flight. Ownership is
    // validated for the WHOLE candidate and only PUBLISHED when the scene that
    // contains it is accepted, so a candidate that fails after binding one object
    // cannot leave that object claimed by a window whose scene never used it.
    private var stagedViewStateViewports: ArrayList<CjguiComposableUiScrollViewport> =
        ArrayList<CjguiComposableUiScrollViewport>()
    private var stagedViewStateSplits: ArrayList<CjguiComposableUiSplitState> =
        ArrayList<CjguiComposableUiSplitState>()
    private var stagedViewStateTabs: ArrayList<CjguiComposableUiTabsState> =
        ArrayList<CjguiComposableUiTabsState>()
    // The view objects the ACCEPTED structure currently binds for this window.
    // The window is their ONE release point: dropping the last reference (a
    // removed element), a startup failure and a normal close all give the objects
    // back so another window may legally take them over.
    private var ownedViewStateViewports: ArrayList<CjguiComposableUiScrollViewport> =
        ArrayList<CjguiComposableUiScrollViewport>()
    private var ownedViewStateSplits: ArrayList<CjguiComposableUiSplitState> =
        ArrayList<CjguiComposableUiSplitState>()
    private var ownedViewStateTabs: ArrayList<CjguiComposableUiTabsState> =
        ArrayList<CjguiComposableUiTabsState>()
    // Monotonic stamp of the last accepted-structure walk; see
    // CjguiComposableUiSplitState.markLive.
    private var viewStateLiveStamp: Int64 = 0
    // B2: the last VALID focus/selection of a page, per (tab container instance,
    // page key). Hiding a page keeps its identity, so switching away and back must
    // present the person's own place again instead of an empty editor. The record
    // is a bounded VIEW bookmark: it stores no business value, and it is applied
    // only by an explicit tab switch, never by a background write.
    private var pageFocusBookmarks: ArrayList<CjguiComposableUiPageFocusBookmark> =
        ArrayList<CjguiComposableUiPageFocusBookmark>()
    // The ACTIVE page of each accepted tab container, keyed by the container's
    // view-state identity. A commit that changes one of these is a page SWITCH,
    // and only such a switch may move focus back into a page.
    private var acceptedActivePageKeys: HashMap<Int64, String> = HashMap<Int64, String>()
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
        this.textRangeEditDeltaDeliveryEnabled = false
        this.refusedRangeTextPending = false
        this.refusedRangeTextNodeId = -1
        this.refusedRangeTextResourceId = -1
        this.refusedRangeTextNodeKind = -1
        this.refusedRangeTextAttempts = 0
        this.refusedRangeTextRecoveries = 0
        this.refusedRangeTextFailures = 0
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
        this.deferredInteractionPaint = false
        this.pendingTransaction = None
        this.closeIntentPending = false
        this.startingPending = false
        this.lastSettlementFault = ""
        this.discardRetryReason = ""
        this.presentAttemptCounter = 0
        this.refreshRequestEpoch = 0
        this.deferredEventWork = false
        this.pendingRefreshReason = "none"
        this.lastNativeFailure = "none"
        this.startupPhase = "none"
        this.firstStartupFailure = "none"
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
        testCloseReason = ""
        testCloseEventKind = -1
        testCloseNativeStatus = 0
        lastNativeSubmissionSnapshotValue = None
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

    /// A1：启动受理与 Ready 结果分别可观察。首帧 PENDING 不是失败：
    /// native 已受理票据、会话与候选持有保留，宿主把窗口留在泵送集合里，
    /// 由后续 turn 的前置结算门推进到 Ready/失败；失败/单次 close/Starting
    /// 时 stop 都留在同一实例状态机内直到真实收敛。
    public func startWithOutcome(): CjguiComposableUiWindowStartOutcome {
        if (isWindowOpen) {
            return StartReady
        }
        if (!configuration.isValid()) {
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
            firstStartupFailure = "invalid_configuration"
            return StartFailed
        }
        startupPhase = "renderer_create"
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
            firstStartupFailure = if (created.status == CJGUI_INTERNAL_RENDERER_OK) {
                "renderer_create_invalid_token"
            } else {
                "renderer_create_${nativeStatusReason(created.status)}"
            }
            return StartFailed
        }
        sessionToken = created.token
        isWindowOpen = true
        textRangeEditDeltaDeliveryEnabled = false
        if (configuration.rangeTextEditDeltaDelivery) {
            let deltaStatus = internalRendererSetComposableRangeEditDelta(sessionToken, true)
            if (deltaStatus == CJGUI_INTERNAL_RENDERER_OK) {
                textRangeEditDeltaDeliveryEnabled = true
            } else {
                lastNativeStatus = deltaStatus
                firstStartupFailure = "renderer_range_edit_${nativeStatusReason(deltaStatus)}"
                discardSession("start_range_edit_failed")
                return StartFailed
            }
        }
        lastNativeStatus = internalRendererSetWindowTitle(sessionToken, configuration.title)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            firstStartupFailure = "renderer_title_${nativeStatusReason(lastNativeStatus)}"
            discardSession("start_title_failed")
            return StartFailed
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
        deferredInteractionPaint = false
        deferredEventWork = false
        firstStartupFailure = "none"
        startupPhase = "viewport"
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
        testCloseReason = ""
        testCloseEventKind = -1
        testCloseNativeStatus = 0
        lastNativeSubmissionSnapshotValue = None
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
        let refreshedAtStart = refreshIfNeeded()
        if (!refreshedAtStart) {
            // A1：首帧 PENDING 不是启动失败。native 已受理首帧票据（终态未定），
            // 会话与原事务保留，宿主继续泵送至 Ready/失败；不得 discard——
            // 那会让 native 票据变成不可寻址的孤儿。
            var pendingNow = false
            match (pendingTransaction) {
                case Some(_) => pendingNow = true
                case None => pendingNow = false
            }
            if (isWindowOpen && pendingNow) {
                startingPending = true
                startupPhase = "starting_pending"
                firstStartupFailure = "none"
                return StartAcceptedPending
            }
            if (firstStartupFailure == "none") {
                firstStartupFailure = "refresh_unknown_failure"
            }
            discardSession("start_refresh_failed")
            return StartFailed
        }
        return StartReady
    }

    /// 兼容入口：受理（首帧未定）与 Ready 都算窗口已打开，只有真实失败返回假。
    /// 需要区分受理/Ready 的宿主改用 startWithOutcome 与 isStartingPending。
    public func start(): Bool {
        let outcome = startWithOutcome()
        match (outcome) {
            case StartFailed => return false
            case _ => return true
        }
    }

    /// A1：首帧受理状态。native 已收下首帧票据但终态未定；真实 Ready 清零。
    public func isStartingPending(): Bool {
        return isWindowOpen && startingPending
    }

    /// A1：最近一次「核心收尾未完整」的命名原因（终止收敛可观察出口）；
    /// 空串 = 无未收敛故障。
    public func settlementFault(): String {
        return lastSettlementFault
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
            // A1：推进刷新请求代际。等待中的原事务只消费它自己记录的 epoch，
            // 因此等待期间产生的任何新修改都会在结算后再走一轮，不会被吞掉。
            refreshRequestEpoch += 1
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
        // A1 前置结算门：必须先结算原票据，再决定本轮是否提交新候选。它早于
        // viewport 失败判断，因此 PENDING 期间的 viewport 波动不会被误当成新失败。
        if (settlePendingPresent()) {
            return false
        }
        // A1：close 意图消费点。事务已完全结算（含 ACK）后，一次 close 请求
        // 在此自动收敛；不再恢复焦点或挂代理。
        if (closeIntentPending) {
            closeIntentPending = false
            if (isWindowOpen) {
                let _ = internalRendererRequestClose(sessionToken)
            }
            discardSession("close_after_settlement")
            return false
        }
        startupPhase = "viewport"
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
        startupPhase = "scene_sync"
        let synced = syncProjection(viewport, declaredVersion)
        return synced
    }

    public func pump(timeoutMs: UInt32): CjguiComposableUiWindowPumpResult {
        return pumpWithRefreshPolicy(timeoutMs, true)
    }

    // Application turns drain every window's accepted FIFO before beginning
    // any potentially expensive scene preparation. Public pump keeps its
    // synchronous refresh semantics for direct callers.
    func pumpEventsWithoutRefresh(timeoutMs: UInt32): CjguiComposableUiWindowPumpResult {
        return pumpWithRefreshPolicy(timeoutMs, false)
    }

    func hasDeferredEventWork(): Bool {
        return deferredEventWork
    }

    func refreshAfterDeferredPump(): Bool {
        let refreshed = refreshIfNeeded()
        if (deferredInteractionPaint && isWindowOpen) {
            let _ = refreshInteractionPaintIfNeeded()
        }
        deferredInteractionPaint = false
        deferredEventWork = false
        return refreshed
    }

    private func pumpWithRefreshPolicy(timeoutMs: UInt32, refreshNow: Bool): CjguiComposableUiWindowPumpResult {
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
                testCloseEventKind = Int64(nativeEvent.eventKind)
                testCloseNativeStatus = nativeEvent.status
                discardSession("pump_session_closed")
                return result(false, didApply)
            }
            if (nativeEvent.status != CJGUI_INTERNAL_RENDERER_OK) {
                if (!isRecoverableNativeStatus(nativeEvent.status)) {
                    testCloseEventKind = Int64(nativeEvent.eventKind)
                    testCloseNativeStatus = nativeEvent.status
                    discardSession("pump_native_status")
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
                // A tab TITLE owns Left/Right inside its OWN accepted group: the
                // focus moves to the next ENABLED title and nothing else moves.
                // Selecting a page is the ordinary ACTIVATE interaction, so the
                // arrow rule can never switch a page by itself.
                var resolvedNavigate = resolved
                if (resolvedNavigate.nodeId != nodeId && nativeEvent.nodeId != 0u64) {
                    // A pointer-reporting, non-input presentation node resolves
                    // through the pointer-target path: it owns caret intents but
                    // is deliberately not an editable input.
                    resolvedNavigate = nativeInputScene.resolvePointerTarget(nodeId, nativeEvent.resourceId,
                        Int64(nativeEvent.nodeKind), Int64(nativeEvent.projectionVersion))
                }
                let titleKeyboardText = internalRendererFormEventText(sessionToken)
                let titleOwnsKeyboard = resolved.nodeId == nodeId && resolved.isTabTitle() && resolved.isEnabled &&
                    (titleKeyboardText == "left" || titleKeyboardText == "right" ||
                    titleKeyboardText == "pageUp" || titleKeyboardText == "pageDown" ||
                    titleKeyboardText == "up" || titleKeyboardText == "down")
                let titleStepApplied = titleOwnsKeyboard &&
                    applyTabsTitleNavigation(resolved, titleKeyboardText)
                // A divider whose author bound shared split view state is owned by
                // the framework: the keyboard nudge is applied against the ACCEPTED
                // track and the event never reaches an application split owner.
                let splitKeyboardText = internalRendererFormEventText(sessionToken)
                let splitOwnsKeyboard = resolved.nodeId == nodeId && isSplitSizeNavigation(splitKeyboardText) &&
                    splitStateForDivider(resolved).isSome()
                let splitStepApplied = splitOwnsKeyboard &&
                    applySplitStateKeyboardStep(resolved, splitKeyboardText)
                let caretIntentOwned = resolvedNavigate.nodeId == nodeId &&
                    resolvedNavigate.nodeKind == CJGUI_COMPOSABLE_UI_TEXT &&
                    resolvedNavigate.style.pointerInteractive &&
                    (titleKeyboardText == "deleteBackward" || titleKeyboardText == "deleteForward" ||
                    titleKeyboardText == "left" || titleKeyboardText == "right" ||
                    // Tab in a presentation text node is the product's own intent
                    // (e.g. table cell navigation), not a key the framework owns.
                    titleKeyboardText == "nextCell")
                if (caretIntentOwned) {
                    // The product resolves this intent against its own SourceMap;
                    // the framework only reports which key was pressed.
                    let caretDispatch = controller.applyUiEvent(CjguiComposableUiEvent(
                        resolvedNavigate,
                        35,
                        titleKeyboardText,
                        0,
                        0,
                        Int64(nativeEvent.projectionVersion)))
                    didApply = didApply || caretDispatch.didApply
                    if (caretDispatch.shouldClose) {
                        close()
                        return result(false, didApply)
                    }
                    requiresProjection = true
                } else if (titleOwnsKeyboard) {
                    didApply = didApply || titleStepApplied
                    requiresProjection = true
                } else if (splitOwnsKeyboard) {
                    didApply = didApply || splitStepApplied
                    requiresProjection = true
                } else if (resolved.nodeId == nodeId && (resolved.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA || ((resolved
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
                36u32 || nativeEvent.eventKind == 51u32) {
                let nodeId = Int64(nativeEvent.nodeId)
                let eventText = internalRendererFormEventText(sessionToken)
                var resolved = if (nativeEvent.nodeId == 0u64) {
                    CjguiComposableUiLayoutNode.missing()
                } else {
                    nativeInputScene.resolveInput(nodeId, nativeEvent.resourceId, Int64(nativeEvent.nodeKind),
                        Int64(nativeEvent.projectionVersion))
                }
                if (resolved.nodeId != nodeId && nativeEvent.nodeId != 0u64) {
                    // A pointer-reporting, non-input node (a read-only
                    // presentation fragment) resolves through the pointer-target
                    // path with the same identity checks.
                    resolved = nativeInputScene.resolvePointerTarget(nodeId, nativeEvent.resourceId,
                        Int64(nativeEvent.nodeKind), Int64(nativeEvent.projectionVersion))
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
                // A viewport-bound scroll area is owned by the framework: the
                // real wheel gesture changes the shared viewport request and the
                // next commit presents the new offset. The business version,
                // drafts and selection are untouched, and no field write is
                // invented to drive the viewport.
                let viewportScrollApplied = nativeEvent.eventKind == 30u32 && continuation.nodeId == nodeId &&
                    applyViewportScrollStep(continuation, eventText)
                // Tab can land on a legal control that is currently clipped out of
                // its viewport. Reveal it and let this commit present the new
                // offset: the focused identity does not change, so the keyboard
                // reaches an editor below the fold without a coordinate guess.
                let viewportFocusRevealed = nativeEvent.eventKind == 31u32 && continuation.nodeId == nodeId &&
                    revealAcceptedNodeIfNeeded(continuation.nodeId)
                // A tab TITLE is a framework-owned view intent: pointer activation
                // and the keyboard both switch the shared tab state, so a page
                // switch is presented by the next commit without a business write.
                let tabsIntentConsumed = nativeEvent.eventKind == 27u32 && continuation.nodeId == nodeId &&
                    continuation.isTabTitle() && continuation.isEnabled &&
                    applyTabsActivationStep(continuation)
                if (tabsIntentConsumed) {
                    didApply = true
                    requiresProjection = true
                }
                let rejectsReboundPressActivation = nativeEvent.eventKind == 27u32 &&
                    consumeSuppressedPressActivation(continuation)
                if (continuation.nodeId == nodeId && !rejectsReboundPressActivation && !tabsIntentConsumed) {
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
                            // A pointer activation must carry WHERE it happened:
                            // a pointer-reporting, non-input node resolves the
                            // clicked display offset from this point through the
                            // framework hit test. Keyboard/AX activations keep
                            // zero here and are unaffected.
                            pointerX: Int64(nativeEvent.pointerX),
                            pointerY: Int64(nativeEvent.pointerY),
                            // A queued pointer activation keeps the modifier
                            // state observed when that pointer event happened;
                            // keyboard/AX activations are enqueued with zero
                            // in the native bridge and therefore never inherit
                            // a previous mouse gesture's Command/Shift.
                            modifierFlags: Int64(nativeEvent.modifierFlags)
                        )
                    )
                    didApply = didApply || dispatch.didApply || viewportScrollApplied
                    if (viewportScrollApplied || viewportFocusRevealed) {
                        requiresProjection = true
                    }
                    if (dispatch.shouldClose) {
                        close();
                        return result(false, didApply)
                    }
                    if ((nativeEvent.eventKind == 28u32 || nativeEvent.eventKind == 51u32) && !dispatch.didApply &&
                        isEditableTextNodeKind(continuation.nodeKind)) {
                        // The owner refused this edit. Native already applied it
                        // locally, so the accepted value must be written back on
                        // the next projection instead of being skipped as "same".
                        clearPendingLocalTextValue()
                    }
                    if (nativeEvent.eventKind == 51u32 && textRangeEditDeltaDeliveryEnabled && !dispatch.didApply &&
                        isEditableTextNodeKind(continuation.nodeKind)) {
                        // A refused RANGE edit leaves a proxy that the ordinary
                        // projection path cannot repair: the Cangjie scene is
                        // unchanged, so staging would skip the node, and native
                        // reads "candidate == previous value" as a local edit to
                        // preserve. Record an explicit rollback intent instead.
                        refusedRangeTextPending = true
                        refusedRangeTextNodeId = continuation.nodeId
                        refusedRangeTextResourceId = continuation.resourceId
                        refusedRangeTextNodeKind = continuation.nodeKind
                        refusedRangeTextAttempts = 0
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
            if (!refreshNow) { deferredEventWork = true }
            if (refreshNow && !refreshIfNeeded() && !isWindowOpen) {
                return result(false, didApply)
            }
        } else if (requiresInteractionPaint) {
            if (refreshNow) {
                let _ = refreshInteractionPaintIfNeeded()
            } else {
                deferredInteractionPaint = true
                deferredEventWork = true
            }
        }
        // The FIFO is drained for this turn. Only now is it safe to roll a
        // refused range edit's proxy back: every queued delta has been judged
        // against the accepted value, and no later event is pending.
        recoverRefusedRangeTextProxy()
        return result(true, didApply)
    }

    public func close() {
        // A1：关闭前先尝试结算原票据。仍未定时不得谎称已关闭——native 会拒绝
        // 销毁未结算的会话，核心同样把窗口留在“关闭未完成”，等 owner 继续结算。
        if (settlePendingPresent()) {
            match (pendingTransaction) {
                case Some(tx) =>
                    if (tx.ackCompleted && !tx.coreSettled) {
                        // A1：终止收敛持有（native 已确认、协议已 ACK、核心收尾
                        // 未完整）的唯一出路就是关闭——直接 discard。ACK 已完成，
                        // native destroy 不会因未结算被拒；原票与故障已留痕。
                        discardSession("close_after_settlement_incomplete")
                        return
                    }
                    // A1：持久记录关闭意图。票据结算（Accepted 按事实收尾 /
                    // Rejected 回滚）完成后由刷新门自动完成本次 close；
                    // 关闭态不再恢复焦点/挂代理。
                    closeIntentPending = true
                    pendingRefreshReason = "close_pending_settlement"
                    lastNativeFailure = "close_pending_settlement"
                    startupPhase = "close_pending_settlement"
                    return
                case None => ()
            }
        }
        if (isWindowOpen) {
            let _ = internalRendererRequestClose(sessionToken)
        }
        discardSession("close")
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
    public func cancelComposition(): String {
        var hadMarked: Int32 = 0
        var returned: Int32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_cancel_composition(this.sessionToken, inout hadMarked,
                inout returned)
        }
        return "status=${status} had_marked=${hadMarked} returned=${returned}"
    }

    /// The native window number of this window, so a capture can name the window it wants.
    /// Relying on "the frontmost window" silently produced all-black screenshots.
    public func windowNumber(): Int64 {
        var number: Int64 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_window_number(this.sessionToken, inout number)
        }
        return if (status == CJGUI_INTERNAL_RENDERER_OK) { number } else { 0 }
    }

    public func probeImageTexture(nodeId: Int64): String {
        var found: Int32 = 0
        var hasTexture: Int32 = 0
        var keyLength: Int32 = 0
        var failed: Int32 = 0
        var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        unsafe {
            status = cjgui_internal_renderer_probe_image_texture(this.sessionToken, UInt64(nodeId),
                inout found, inout hasTexture, inout keyLength, inout failed)
        }
        return "status=${status} found=${found} texture=${hasTexture} key_len=${keyLength} failed=${failed}"
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
    /// True when this window opted in to explicit text edit deltas and the
    /// native renderer accepted the request. Readiness only; it says nothing
    /// about whether any edit has happened yet.
    public func isTextRangeEditDeltaDeliveryEnabled(): Bool {
        return textRangeEditDeltaDeliveryEnabled
    }

    public func nativeStatus(): Int32 {
        return lastNativeStatus
    }
    public func displayedSceneVersion(): Int64 {
        return renderedScene.version
    }

    /// Read-only view of the window's OWN accepted scene: the displayed text of
    /// the accepted node carrying this semantic id, or None when the accepted
    /// scene has no such node.
    ///
    /// It reports what the window actually committed, not the controller's
    /// latest build output, so a caller can verify that a content change really
    /// reached the accepted projection in the same step instead of inferring it
    /// from controller state or from a later full rebuild. A text node carries
    /// its string in `value` and a button in `label`, so the displayed text is
    /// whichever the node kind really uses.
    public func acceptedNodeText(semanticId: String): ?String {
        if (!isWindowOpen) {
            return None
        }
        for (node in renderedScene.nodes()) {
            if (node.semanticId == semanticId) {
                if (!node.label.isEmpty()) {
                    return Some(node.label)
                }
                return Some(node.value)
            }
        }
        return None
    }

    /// Read-only dump of the window's accepted scene, one line per node:
    /// node_id|kind|semantic_id|label|value|field_id|action|operation|
    /// operation_target|resource|role|gap|padding|x,y,w,h.
    ///
    /// A generation node's semantic id is its declared structural key, so a caller
    /// can address the node the window really accepted (content, binding, layout
    /// and style) instead of guessing a registry allocation. It reports the
    /// committed scene, never the controller's latest build.
    public func acceptedSceneDump(): String {
        if (!isWindowOpen) {
            return ""
        }
        let builder = StringBuilder()
        for (node in renderedScene.nodes()) {
            builder.append("${node.nodeId}|${node.nodeKind}|${node.semanticId}|${node.label}|${node.value}|" +
                "${node.fieldId}|${node.actionName}|${node.operationActionName}|" +
                "${node.operationResourceId}|${node.resourceId}|${node.displayValueRole}|" +
                "${node.style.gap}|${node.style.padding}|" +
                "${node.bounds.x},${node.bounds.y},${node.bounds.width},${node.bounds.height}\n")
        }
        return builder.toString()
    }

    /// Accepted VALUE of the node carrying this semantic id, or None when the
    /// accepted scene has no such node. `acceptedNodeText` reports the accessible
    /// caption (a button's label, a text node's value); an editable control's
    /// displayed content is its value, and this is the precise probe for it.
    public func acceptedNodeValue(semanticId: String): ?String {
        if (!isWindowOpen) {
            return None
        }
        for (node in renderedScene.nodes()) {
            if (node.semanticId == semanticId) {
                return Some(node.value)
            }
        }
        return None
    }

    /// Accepted geometry of the node carrying this semantic id, or None when the
    /// accepted scene has no such node. Companion to `acceptedNodeText`: it lets a
    /// caller verify that a layout change really reached the accepted scene
    /// instead of inferring it from a controller counter.
    public func acceptedNodeBounds(semanticId: String): ?CjguiComposableUiRect {
        if (!isWindowOpen) {
            return None
        }
        for (node in renderedScene.nodes()) {
            if (node.semanticId == semanticId) {
                return Some(node.bounds)
            }
        }
        return None
    }

    /// Number of nodes in the window's accepted scene (0 when nothing is
    /// accepted). Read-only: it reports what the window committed, so a caller
    /// can record the real expansion size of the scene it timed.
    public func acceptedNodeCount(): Int64 {
        if (!isWindowOpen) {
            return 0
        }
        return renderedScene.nodes().size
    }

    /// Test-only: why this window first stopped being open ("" while it is open),
    /// with the native event kind/status that triggered it when there was one.
    public func testCloseTrace(): String {
        if (testCloseReason.size == 0) {
            return "open"
        }
        return "reason=${testCloseReason} event_kind=${testCloseEventKind} native_status=${testCloseNativeStatus}"
    }

    /// Test-only: the most recent successful native submission (monotonic time,
    /// accepted/submitted scene version and submission count). A bounded latency
    /// probe uses it to attribute the submission that carried a value; it is not
    /// a presentation claim and changes no normal path.
    public func testLastNativeSubmissionSnapshot(): ?CjguiComposableUiNativeSubmissionSnapshot {
        return lastNativeSubmissionSnapshotValue
    }

    /// The window's accepted scene nodes, so a caller can read the REAL accepted
    /// geometry/identity of each node instead of parsing the debug text dump.
    /// Read-only snapshot: it reports what the window committed, never a pending
    /// candidate, and exposes no native handle.
    public func acceptedSceneNodes(): ArrayList<CjguiComposableUiLayoutNode> {
        if (!isWindowOpen) {
            return ArrayList<CjguiComposableUiLayoutNode>()
        }
        let snapshot = ArrayList<CjguiComposableUiLayoutNode>()
        for (node in renderedScene.nodes()) {
            snapshot.add(node)
        }
        return snapshot
    }

    /// Incremental compatibility declaration. Duplicate IDs and a matching
    /// shortcut *in the same focus scope* fail closed; mutually exclusive
    /// scopes may deliberately reuse one chord.
    // --- B2 text geometry seam (identity + named failures) -------------------------------------
    //
    // Astra's ruling for B2: build an accepted-layout geometry snapshot that carries IDENTITY and
    // VERSIONS, and refuse by NAME when it cannot answer. This first step deliberately answers
    // `pending`: the identity and the refusal vocabulary are established before any geometry is
    // computed, so consumers cannot silently invent a caret rect. Query contract (to be honoured when
    // the geometry lands): read only already-accepted/prepared layout and transform indices -- no
    // disk, no parsing, no shaping, no whole-document layout; coordinates in window content points.
    /// B2 geometry versions. Content/layout/transform are owned separately (Astra): a stale value must
    /// be REFUSABLE, so each gets its own counter instead of one "scene version" used as a hint.
    public var geometryContentVersion: Int64 = 1
    public var geometryLayoutVersion: Int64 = 1
    public var geometryTransformVersion: Int64 = 1

    public func textGeometryPendingReason(): String {
        return "pending"
    }

    public func textGeometryIdentity(nodeId: Int64): CjguiComposableTextGeometryIdentity {
        return CjguiComposableTextGeometryIdentity(nodeId, this.contentVersionForGeometry(),
            this.layoutVersionForGeometry(), this.transformVersionForGeometry())
    }

    public func contentVersionForGeometry(): Int64 {
        return this.geometryContentVersion
    }

    public func layoutVersionForGeometry(): Int64 {
        return this.geometryLayoutVersion
    }

    public func transformVersionForGeometry(): Int64 {
        return this.geometryTransformVersion
    }

    /// Atomic interaction declaration: one call binds the selection overlay, the caret and the IME
    /// insertion point to the SAME identity, which is what the ruling requires (the old
    /// pixel-carrying `declareInputCaret` could not do that).
    public func declareTextInteraction(nodeId: Int64, anchorDisplayByte: Int64, focusDisplayByte: Int64,
        contentVersion: Int64, layoutVersion: Int64, caretWidthPt: Float64): CjguiComposableTextGeometry {
        let identity = CjguiComposableTextGeometryIdentity(nodeId, contentVersion, layoutVersion,
            this.geometryTransformVersion)
        if (contentVersion != this.geometryContentVersion) {
            return CjguiComposableTextGeometry.pending(identity, "stale_layout")
        }
        if (layoutVersion != this.geometryLayoutVersion) {
            return CjguiComposableTextGeometry.pending(identity, "stale_layout")
        }
        if (nodeId <= 0 || anchorDisplayByte < 0 || focusDisplayByte < 0) {
            return CjguiComposableTextGeometry.pending(identity, "out_of_coverage")
        }
        // B2(2026-09-26):读**已接受场景中已持留**的排版几何(只读、不重排);
        // 拿不到 ⇒ 按状态码给**具名**原因,绝不静默零矩形。
        if (let Some(rect) <- cjguiTextGeometryCaretRect(this.sessionToken, nodeId,
                anchorDisplayByte, caretWidthPt)) {
            return CjguiComposableTextGeometry(true, false, "", identity,
                rect[0], rect[1], rect[2], rect[3])
        }
        let reason = cjguiTextGeometryReasonForStatus(
            cjguiTextGeometryCaretStatus(this.sessionToken, nodeId, anchorDisplayByte, caretWidthPt))
        return CjguiComposableTextGeometry.pending(identity, reason)
    }

    public func textCaretRect(nodeId: Int64, displayByteOffset: Int64, contentVersion: Int64,
        layoutVersion: Int64): CjguiComposableTextGeometry {
        return this.declareTextInteraction(nodeId, displayByteOffset, displayByteOffset, contentVersion,
            layoutVersion, 1.0)
    }


    /// B2:同一 session 下的状态查询(供 rangeRects 映射具名原因)。
    private func cjguiTextGeometryCaretStatus(nodeId: Int64, displayByte: Int64): Int32 {
        return cjguiTextGeometryCaretStatus(this.sessionToken, nodeId, displayByte, 1.0)
    }

    public func textRangeRects(nodeId: Int64, startDisplayByte: Int64, endDisplayByte: Int64,
        maxRects: Int64): Array<CjguiComposableTextGeometry> {
        let out = ArrayList<CjguiComposableTextGeometry>()
        if (maxRects <= 0 || endDisplayByte < startDisplayByte) {
            // 无效范围 / 无容量:具名失败(绝不静默零矩形)。
            let guardIdentity = this.textGeometryIdentity(nodeId)
            out.add(CjguiComposableTextGeometry.pending(guardIdentity, "out_of_coverage"))
            return out.toArray()
        }
        let identity = this.textGeometryIdentity(nodeId)
        // 2026-09-26(B2/B3):逐行选择框(正常流程)—— 只读行矩形查询构造选择覆盖层几何;不重排。
        let (lineStatus, lineFlat, linePartial) = cjguiTextLineRects(
            this.sessionToken, nodeId, startDisplayByte, endDisplayByte, Int32(maxRects))
        if (lineStatus == 0 && Int64(lineFlat.size) >= 4) {
            var row = Int64(0)
            let total = Int64(lineFlat.size) / 4
            while (row < total) {
                out.add(CjguiComposableTextGeometry(true, linePartial,
                    if (linePartial) { "partial" } else { "" }, identity,
                    lineFlat[row * 4], lineFlat[row * 4 + 1],
                    lineFlat[row * 4 + 2], lineFlat[row * 4 + 3]))
                row += 1
            }
            return out.toArray()
        }
        let reason = cjguiTextGeometryReasonForStatus(lineStatus)
        out.add(CjguiComposableTextGeometry.pending(identity, reason))
        return out.toArray()
    }

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
    /// Package-only trace of the bounded per-page focus bookmarks. It exposes
    /// view positions (identity + selection) only, never a business value, and no
    /// native handle or controller object reaches a probe.
    func testPageFocusBookmarkTrace(): String {
        var text = "focused=${focusedNodeId} sel=${focusedSelectionStart}-${focusedSelectionEnd}"
        for (bookmark in pageFocusBookmarks) {
            text += "|group=${bookmark.groupIdentity} page=${bookmark.pageKey} node=${bookmark.nodeId} kind=${bookmark.nodeKind} sel=${bookmark.selectionStart}-${bookmark.selectionEnd}"
        }
        return text
    }
    /// Package-only probe for the SELECTION half of the page bookmark. It runs the
    /// SAME bookkeeping the production SELECTION_CHANGED event (kind 33) takes, so a
    /// test can pin "a person's place in a page survives being hidden" without a
    /// native event. It is not a second input route and does not write the accepted
    /// scene; it reports whether a focused node existed to receive the position.
    func testRememberFocusedSelection(start: Int64, end: Int64): Bool {
        let node = nativeInputScene.nodeForId(focusedNodeId)
        if (node.nodeId != focusedNodeId) {
            return false
        }
        rememberInteraction(node, 33, start, end)
        return true
    }
    /// Package-only probe for the tab TITLE keyboard rule: it runs the SAME
    /// decision the native NAVIGATE branch takes (event 35 + left/right on a tab
    /// title), so the rule can be pinned without a native event. It is not a
    /// second input route: the production path is unchanged.
    func testNavigateTabTitle(nodeId: Int64, direction: String): Bool {
        let node = nativeInputScene.nodeForId(nodeId)
        if (node.nodeId != nodeId || !node.isTabTitle() || !node.isEnabled) {
            return false
        }
        return applyTabsTitleNavigation(node, direction)
    }
    /// Package-only probe for the tab TITLE activation rule: the same decision the
    /// native ACTIVATE branch (Enter/Space, AXPress, pointer) takes for a title.
    func testActivateTabTitle(nodeId: Int64): Bool {
        let node = nativeInputScene.nodeForId(nodeId)
        if (node.nodeId != nodeId) {
            return false
        }
        return applyTabsActivationStep(node)
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
            let failure = if (firstStartupFailure != "none") { firstStartupFailure } else { lastNativeFailure }
            let pending = if (firstStartupFailure != "none") {
                "start_${firstStartupFailure}"
            } else {
                pendingRefreshReason
            }
            return CjguiSharedOperationWindowProgress(false, 0, -1, "unavailable", "", 0, -1,
                -1, -1, -1, -1, -1, pending, failure, interactionVersion, "none", false, 0, 0, "none")
        }
        observeDisplayProgress()
        let focused = renderedScene.nodeForId(focusedNodeId)
        let hasLiveFocusedIdentity = focused.nodeId == focusedNodeId && focused.resourceId == focusedResourceId &&
            focused.nodeKind == focusedNodeKind
        // Three DIFFERENT facts, never collapsed: nothing focused, a live focus,
        // and a focus whose accepted identity can no longer be confirmed. The last
        // one must not publish the stale control id, and must not pretend the
        // window is simply unfocused.
        let focusState = if (focusedNodeId <= 0) {
            CJGUI_WINDOW_FOCUS_STATE_UNFOCUSED
        } else if (hasLiveFocusedIdentity) {
            CJGUI_WINDOW_FOCUS_STATE_VALID
        } else {
            CJGUI_WINDOW_FOCUS_STATE_UNKNOWN
        }
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
        var viewportFacts = ArrayList<String>()
        for (node in renderedScene.nodes()) {
            if (node.nodeKind != CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
                continue
            }
            if (viewportFacts.size >= 4) {
                break
            }
            if (let Some(viewport) <- node.scrollViewport) {
                let pending = if (viewport.hasPendingRequest()) {
                    1
                } else {
                    0
                }
                viewportFacts.add(
                    "WINDOW_VIEWPORT ${node.semanticId} offset=${viewport.offset()} " +
                    "accepted=${viewport.acceptedOffset()} content=${viewport.contentExtent()} " +
                    "viewport=${viewport.viewportExtent()} pending=${pending} solves=${viewport.acceptedSolveCount()}"
                )
            }
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
            activeLayerId,
            focusState: focusState,
            viewportFacts: viewportFacts
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
                startupPhase = "participant_begin"
                let began = value.beginSceneRefresh()
                if (!began) {
                    return noteRefreshFailure(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
                }
            }
            startupPhase = "identity_begin"
            let identityBegan = identityRegistry.beginCandidate()
            if (!identityBegan) {
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(identityRegistry.lastIssue())
            }
            let buildStarted = MonoTime.now()
            startupPhase = "controller_build"
            let declaredRoot = controller.buildUi()
            let buildElapsed = MonoTime.now() - buildStarted
            lastBuildElapsedMs = buildElapsed.toMilliseconds()
            lastRefreshTiming.buildNanoseconds = buildElapsed.toNanoseconds()
            buildPassCount += 1
            let identityResolutionStarted = MonoTime.now()
            startupPhase = "identity_resolve"
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
            startupPhase = "candidate_clone"
            let root = declaredRoot.cloneForWindowCandidate()
            // Shared MUTABLE view objects (scroll viewport, split size, active tab
            // page) belong to ONE window. A declaration that hands the same object
            // to a second window is refused deterministically HERE, instead of
            // letting either window move the other's accepted geometry. Ownership
            // is only VALIDATED here and published with the accepted scene, so a
            // candidate that fails later leaves nothing claimed.
            startupPhase = "view_state_ownership"
            let ownershipIssue = validateCandidateViewStateOwnership(root)
            if (ownershipIssue.size > 0) {
                discardStagedViewStateOwnership()
                if (let Some(value) <- participant) {
                    value.rollbackSceneRefresh()
                }
                identityRegistry.rollbackCandidate()
                return noteIdentityRefreshFailure(ownershipIssue)
            }
            startupPhase = "identity_replace_root"
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
                startupPhase = "participant_prepare"
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
            startupPhase = "layout"
            textMeasurer.beginMeasurementPass()
            // Runs must be installed before the scene is rasterized; installing
            // them from the controller's tree avoids depending on every layout
            // clone carrying the field.
            let runInstallStatus = internalRendererInstallComposableTextRuns(sessionToken, root)
            if (runInstallStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = runInstallStatus
            }
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
            // Candidate viewport facts belong to THIS attempt until the scene is
            // accepted (or rejected) below.
            stagedSceneViewports = layoutResult.viewports
            stagedSceneSplitTracks = layoutResult.splitTracks
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
            startupPhase = "text_measurement"
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
            startupPhase = "identity_prepare"
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
            startupPhase = "command_bindings"
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
            startupPhase = "data_transfer_bindings"
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
                startupPhase = "semantic_menu"
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
                commitStagedSceneViewports()
                commitStagedSceneSplitTracks()
                // Ownership of the shared view objects is published with the same
                // accepted scene, and the objects this accepted structure no
                // longer references are given back.
                commitCandidateViewStateOwnership()
                reconcileOwnedViewStateAfterAcceptance(root)
                acceptedSceneVersion = renderedScene.version
                // 2026-09-26(B2):随 accept 一起发布三个几何版本 —— 此前三者恒为 1,
                // 使 declareTextInteraction 的 stale_layout 守卫永不触发;写入后守卫才真正生效
                // (契约 implementation order 3:版本/覆盖不匹配时保留既有具名 pending)。
                geometryContentVersion = declaredVersion
                geometryLayoutVersion = candidateVersion
                geometryTransformVersion = geometryTransformVersion + 1
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
            startupPhase = "native_menu"
            lastNativeStatus = stageNativeCommandMenu(candidateCommands, UInt64(paintScene.version), inputScopes)
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            startupPhase = "native_prepare"
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
                let (tabGroupId, tabSelected) = nativeTabStopMetadata(node)
                // Presentation runs belong to the node. Send them to the session
                // (one encoded string per node) instead of widening the marshalled
                // node struct; a node with no runs keeps today's single style.
                if (node.textStyleRuns.size > 0) {
                    var encoded = ""
                    var runIndex: Int64 = 0
                    while (runIndex < node.textStyleRuns.size) {
                        if (runIndex > 0) {
                            encoded += ";"
                        }
                        encoded += node.textStyleRuns[runIndex].encoded()
                        runIndex += 1
                    }
                    let runStatus = internalRendererSetComposableTextRuns(this.sessionToken, UInt64(node.nodeId), encoded)
                    if (runStatus != CJGUI_INTERNAL_RENDERER_OK) {
                        lastNativeStatus = runStatus
                    }
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
                    isInteractive: if (node.canReceiveInput() || node.canReceiveFocus() || node.style.pointerInteractive) {
                        1u32
                    } else {
                        0u32
                    },
                    // A node that opts into pointer delivery must not take the
                    // read-only early return in the native mouse-down path, and
                    // it is deliberately NOT an input: TEXT nodes are neither
                    // pressable nor text inputs, so it only reaches the pointer
                    // reporting branch.
                    isReadOnly: if (node.isReadOnly && !node.style.pointerInteractive) {
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
                    fontWeight: composableNativeFontWeight(style.fontWeight),
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
                    inputScope: nativeInputScope,
                    tabGroupId: tabGroupId,
                    tabSelected: tabSelected
                )
                let semanticLabel = if (node.label.size > 0) {
                    node.label
                } else {
                    node.semanticId
                }
                startupPhase = "native_node_${index}"
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
                    node.semanticId,
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
            startupPhase = "native_data_transfer"
            lastNativeStatus = stageNativeDataTransfer(candidateDataTransferBindings, paintScene.version)
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastRefreshTiming.nativeStageAndSubmitNanoseconds = elapsedNanoseconds(stageAndSubmitStarted)
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            startupPhase = "native_present"
            let frame = internalRendererPresentComposableScene(sessionToken)
            let nativeStageAndSubmitElapsed = MonoTime.now() - stageAndSubmitStarted
            lastNativeStageAndSubmitElapsedMs = nativeStageAndSubmitElapsed.toMilliseconds()
            lastRefreshTiming.nativeStageAndSubmitNanoseconds = nativeStageAndSubmitElapsed.toNanoseconds()
            lastNativeStatus = frame.status
            if (lastNativeStatus == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) {
                // 提交未定：不得回滚候选，也不得声称拒绝。把本次提交的原事实
                // 收进事务，等 native 票据的终态由前置结算门一次性接受或回滚。
                // 不再由下一次 present“顺便结算”。
                return beginPendingTransaction(participant: participant, root: root, paintScene: paintScene,
                    previouslySubmittedScene: previouslySubmittedScene, declaredVersion: declaredVersion,
                    viewport: viewport, candidateCommands: candidateCommands,
                    candidateDataTransferBindings: candidateDataTransferBindings, ticketId: frame.ticketId,
                    consumedRequestEpoch: refreshRequestEpoch)
            }
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK && lastNativeStatus !=
                CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
                // The native side rolled its input/overlay snapshot back before
                // returning this presentation failure. Keep Cangjie's accepted
                // scene equally intact and wait for one explicit retry.
                return rejectParticipantCandidate(participant, lastNativeStatus)
            }
            // 同步成功：native 已当场接受。先标记不可回滚（收到 Accepted 后必须
            // 在任何焦点恢复或 participant 调用之前设置），再执行共用的收尾链。
            acceptedCandidate = true
            return finishAcceptedScene(root: root, paintScene: paintScene,
                previouslySubmittedScene: previouslySubmittedScene, participant: participant,
                candidateCommands: candidateCommands,
                candidateDataTransferBindings: candidateDataTransferBindings, declaredVersion: declaredVersion,
                viewportResizeVersion: viewport.resizeVersion,
                viewportResourceCompletionVersion: viewport.resourceCompletionVersion,
                frameIndex: Int64(frame.frameIndex), readbackCompleted: frame.readbackCompleted,
                consumedRequestEpoch: refreshRequestEpoch)
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
            startupPhase = "candidate_exception_after_${startupPhase}"
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
        if (nodeId >= 0 && revealAcceptedNodeIfNeeded(nodeId)) {
            // The target exists but is outside the visible part of its scroll
            // viewport. Reveal it, remember the SAME request, and let the commit
            // that makes it visible satisfy the focus: keyboard navigation must
            // reach an editor below the fold instead of silently doing nothing.
            pendingScopedFocusScope = Some(scope)
            pendingScopedFocusKey = localKey
            requestRefresh()
            return false
        }
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

    /// One real wheel step against a scroll area that shares a public viewport.
    /// Returns true when the request moved, so the caller schedules a projection.
    /// The shared split view state of a state-bound divider, or None when this
    /// node is not a generated split handle. The framework only claims a divider
    /// whose author bound shared view state; a handwritten split keeps its own
    /// application owner.
    private func splitStateForDivider(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSplitState {
        if (node.nodeKind != CJGUI_COMPOSABLE_UI_SPLIT_HANDLE) {
            return None
        }
        return node.splitState
    }

    private func isSplitSizeNavigation(text: String): Bool {
        return text == "left" || text == "right" || text == "up" || text == "down"
    }

    /// The keyboard size rule for a state-bound divider: the same ±8 nudge the
    /// handwritten split uses, bounded by the framework's ONE rule against the
    /// track the ACCEPTED scene really solved. Returns true when the size moved.
    private func applySplitStateKeyboardStep(node: CjguiComposableUiLayoutNode, text: String): Bool {
        if (let Some(state) <- splitStateForDivider(node)) {
            let direction = if (text == "left" || text == "up") {
                -1
            } else if (text == "right" || text == "down") {
                1
            } else {
                0
            }
            if (direction == 0) {
                return false
            }
            // The nudge starts from the size the ACCEPTED scene really shows when
            // one exists, so a not-yet-solved request cannot compound.
            let before = if (state.acceptedTrack() > 0) {
                state.acceptedFirstSize()
            } else {
                state.firstSize()
            }
            // A bounded ±8 nudge: the ONE rule below still clamps it to the
            // accepted track and to both declared minimums.
            let requested = if (direction < 0) {
                if (before < 8) {
                    0
                } else {
                    before - 8
                }
            } else if (before > Int64.Max - 8) {
                Int64.Max
            } else {
                before + 8
            }
            let _ = state.applyAcceptedFirstSize(requested)
            return state.firstSize() != before
        }
        return false
    }

    /// The pointer rule for a state-bound divider: the REAL pointer position is
    /// mapped through the framework's ONE size rule onto the accepted track, so
    /// no sample width and no application split owner is involved. Returns true
    /// when the size moved.
    private func applySplitStatePointerDrag(node: CjguiComposableUiLayoutNode, pointerX: Int64): Bool {
        if (let Some(state) <- splitStateForDivider(node)) {
            let track = state.acceptedTrack()
            if (track <= 0) {
                return false
            }
            let handleSize = if (state.acceptedHandleSize() > 0) {
                state.acceptedHandleSize()
            } else {
                node.pointerControlHandleThickness
            }
            // The origin comes from the ACCEPTED geometry: the divider's own
            // accepted x minus the width the accepted scene really allocated.
            // Deriving it from a possibly-unsolved request shifted the whole
            // mapping after the first oversized drag.
            let acceptedFirst = if (state.acceptedTrack() > 0) {
                state.acceptedFirstSize()
            } else {
                state.firstSize()
            }
            let trackOrigin = node.bounds.x - acceptedFirst
            let requested = CjguiComposableUiSplitGeometry.firstSizeForPointer(pointerX, trackOrigin, track,
                handleSize, state.firstMinimum(), state.secondMinimum())
            let before = state.firstSize()
            let _ = state.applyFirstSize(requested, track, handleSize)
            return state.firstSize() != before
        }
        return false
    }

    /// ONE tab view intent, shared by pointer activation and the keyboard: a
    /// title whose container bound shared tab view state is owned by the
    /// framework, so switching a page never invents a business write and never
    /// depends on which author built the container. Returns true when the active
    /// page moved and the caller must present a new projection.
    private func applyTabsActivationStep(node: CjguiComposableUiLayoutNode): Bool {
        if (!node.isTabTitle() || !node.isEnabled) {
            return false
        }
        if (let Some(state) <- node.tabsState) {
            // The page being LEFT keeps the person's place: the accepted scene is
            // still presenting it, so this is the moment the bookmark is exact.
            if (focusedNodeId >= 0) {
                let focused = nativeInputScene.nodeForId(focusedNodeId)
                if (focused.nodeId == focusedNodeId) {
                    refreshPageFocusBookmark(focused)
                }
            }
            if (state.select(node.tabsPageKey)) {
                // The focus/selection restore is driven by the commit that really
                // presents the new page (see restorePageFocusAfterAcceptedScene).
                return true
            }
            // The page is already active: the intent is consumed (the title is
            // framework-owned) even though nothing has to be re-presented.
            return true
        }
        return false
    }

    // Internal native focus metadata is a projection of the same tabs state
    // that owns page selection. The native side chooses one Tab stop per group
    // and falls back to its first enabled title if the selected key vanished.
    private func nativeTabStopMetadata(node: CjguiComposableUiLayoutNode): (UInt64, UInt32) {
        if (!node.isTabTitle()) {
            return (0u64, 0u32)
        }
        let state = match (node.tabsState) {
            case Some(value) => value
            case None => return (0u64, 0u32)
        }
        let selected = node.isEnabled && state.activeKey() == node.tabsPageKey
        return (UInt64(state.viewStateIdentity()), if (selected) { 1u32 } else { 0u32 })
    }

    /// Moves the TITLE focus inside ONE accepted tab group. Left/Right only move
    /// the title focus; selecting a page stays the ordinary ACTIVATE interaction,
    /// so an arrow can never switch a page by itself. Disabled titles are skipped
    /// and both ends clamp, which keeps the rule deterministic for a person and
    /// for a program (a press at the end is simply consumed).
    private func applyTabsTitleNavigation(node: CjguiComposableUiLayoutNode, direction: String): Bool {
        let state = match (node.tabsState) {
            case Some(value) => value
            case None => return false
        }
        // The GROUP is the accepted tab container instance, identified by the
        // shared view-state object itself rather than by title text or a
        // controller-owned state machine.
        let groupIdentity = state.viewStateIdentity()
        let titles = ArrayList<CjguiComposableUiLayoutNode>()
        for (candidate in nativeInputScene.nodes()) {
            if (!candidate.isTabTitle()) {
                continue
            }
            if (let Some(candidateState) <- candidate.tabsState) {
                if (candidateState.viewStateIdentity() == groupIdentity) {
                    titles.add(candidate)
                }
            }
        }
        var current = -1
        var index = 0
        while (index < titles.size) {
            if (titles[index].nodeId == node.nodeId) {
                current = index
            }
            index += 1
        }
        if (current < 0) {
            return false
        }
        let step = if (direction == "left") {
            -1
        } else {
            1
        }
        var next = current + step
        while (next >= 0 && next < titles.size && !titles[next].isEnabled) {
            next += step
        }
        if (next < 0 || next >= titles.size) {
            return false
        }
        return focusProjectedNode(titles[next].nodeId)
    }

    private func applyViewportScrollStep(node: CjguiComposableUiLayoutNode, direction: String): Bool {
        if (let Some(viewport) <- node.scrollViewport) {
            let half = viewport.viewportExtent() / 2
            let step = if (half > 24) {
                half
            } else {
                24
            }
            return viewport.step(direction, step)
        }
        return false
    }

    /// Reveals an accepted node that is outside the visible part of its scroll
    /// viewport. Returns true when a new offset was requested; the caller then
    /// re-focuses after the commit instead of focusing an unreachable node.
    private func revealAcceptedNodeIfNeeded(nodeId: Int64): Bool {
        let target = nativeInputScene.nodeForId(nodeId)
        if (target.nodeId != nodeId || target.bounds.height <= 0) {
            return false
        }
        // The target must become visible through its WHOLE clip chain, not only
        // through the innermost viewport: a field at the bottom of an inner scroll
        // can still sit outside the outer scroll's visible band. Ancestors are
        // handled innermost first, and each step is skipped when the target is
        // already fully inside that viewport after the previous steps.
        let ancestors = viewportAncestorsForNode(target)
        var revealed = false
        var top = target.bounds.y
        let height = target.bounds.height
        for (container in ancestors) {
            if (let Some(viewport) <- container.scrollViewport) {
                let padding = container.style.padding
                let innerTop = container.bounds.y + padding
                let innerHeight = container.bounds.height - padding * 2
                if (innerHeight <= 0) {
                    continue
                }
                let acceptedOffset = viewport.acceptedOffset()
                if (!(top >= innerTop && top + height <= innerTop + innerHeight)) {
                    // The node's bounds are already offset by the accepted scroll,
                    // so the content-relative top puts it back into content
                    // coordinates.
                    let contentTop = top - innerTop + acceptedOffset
                    let contentBottom = contentTop + height
                    let _ = viewport.reveal(contentTop, contentBottom)
                }
                // Layout applies `contentY - offset`. The next (outer)
                // viewport therefore sees the accepted target moved by the
                // whole accepted-to-pending delta, including a request that
                // was already pending before this reveal call. Do not mix the
                // previous requested coordinate with the accepted scene.
                let pendingDelta = viewport.offset() - acceptedOffset
                if (pendingDelta != 0) {
                    revealed = true
                    top -= pendingDelta
                }
            }
        }
        return revealed
    }

    /// Every viewport-bound scroll area whose clip chain contains the target,
    /// INNERMOST FIRST, resolved by the ACCEPTED ancestor IDENTITY the layout
    /// recorded for each clip constraint.
    ///
    /// Geometry is not evidence of containment: two sibling scroll areas can
    /// overlap exactly, so matching a viewport by an equal inner rectangle used to
    /// let an unrelated neighbour receive a reveal. The clip chain of the target is
    /// already ordered innermost-last, so walking it backwards yields the real
    /// ancestor ORDER as well as the real ancestors.
    private func viewportAncestorsForNode(target: CjguiComposableUiLayoutNode):
        ArrayList<CjguiComposableUiLayoutNode> {
        let matches = ArrayList<CjguiComposableUiLayoutNode>()
        let constraints = target.clipConstraints()
        var index = constraints.size - 1
        while (index >= 0) {
            let owner = constraints[index].ownerIdentity
            if (owner.size > 0) {
                if (let Some(container) <- viewportNodeForIdentity(owner)) {
                    matches.add(container)
                }
            }
            index -= 1
        }
        return matches
    }

    /// The accepted scroll area whose stable identity is `identity`, when it binds
    /// a public viewport. Identity is unique inside one accepted scene, so two
    /// exactly overlapping siblings can never be confused.
    private func viewportNodeForIdentity(identity: String): ?CjguiComposableUiLayoutNode {
        for (candidate in nativeInputScene.nodes()) {
            if (candidate.nodeKind != CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
                continue
            }
            if (candidate.scrollViewport.isNone()) {
                continue
            }
            if (candidate.identityKey == identity) {
                return Some(candidate)
            }
        }
        return None
    }

    private func focusProjectedNode(nodeId: Int64, rememberBookmark!: Bool = true): Bool {
        let node = nativeInputScene.nodeForId(nodeId)
        if (node.nodeId != nodeId || !node.canReceiveFocus()) {
            return false
        }
        let status = internalRendererFocusComposableNode(sessionToken, nodeId)
        lastNativeStatus = status
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            return false
        }
        recordProjectedFocus(node, rememberBookmark: rememberBookmark)
        return true
    }
    private func recordProjectedFocus(node: CjguiComposableUiLayoutNode, rememberBookmark!: Bool = true): Unit {
        let changed = focusedNodeId != node.nodeId || focusedResourceId != node.resourceId || focusedNodeKind != node
            .nodeKind
        focusedNodeId = node.nodeId
        focusedResourceId = node.resourceId
        focusedNodeKind = node.nodeKind
        if (changed) {
            // Native focus starts a newly focused editor at the end of its
            // current UTF-16 value. Keep the projection in the same unit.
            let caret = if (node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || node.nodeKind ==
                CJGUI_COMPOSABLE_UI_INTEGER_INPUT || node.nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
                cjguiSelectionUtf16Length(node.value)
            } else {
                0
            }
            focusedSelectionStart = caret
            focusedSelectionEnd = caret
            interactionVersion += 1
        }
        if (rememberBookmark) {
            refreshPageFocusBookmark(node)
        }
    }

    /// Resolve the innermost active page in the accepted component ancestry.
    /// Flat paint order and coincident bounds cannot establish ownership.
    private func pageContextForNode(node: CjguiComposableUiLayoutNode): ?(Int64, String) {
        if (nativeInputScene.nodeForId(node.nodeId).nodeId != node.nodeId) {
            return None
        }
        return pageContextInAcceptedTree(renderedRoot, node.nodeId, None)
    }

    private func pageContextInAcceptedTree(root: CjguiComposableUiNode, nodeId: Int64,
        parentContext: ?(Int64, String)): ?(Int64, String) {
        var context = parentContext
        if (root.isTabPage() && root.tabsPageActive) {
            if (let Some(state) <- root.tabsState) {
                context = Some((state.viewStateIdentity(), root.tabsPageKey))
            }
        }
        if (root.nodeId == nodeId) {
            return context
        }
        for (child in root.children()) {
            let found = pageContextInAcceptedTree(child, nodeId, context)
            if (found.isSome()) {
                return found
            }
        }
        return None
    }

    /// Records where the person is INSIDE the page they are on. Only a valid,
    /// focused, page-owned identity is recorded, so a title or a foreign node can
    /// never seed a page bookmark.
    private func refreshPageFocusBookmark(node: CjguiComposableUiLayoutNode): Unit {
        if (focusedNodeId != node.nodeId || !node.canReceiveFocus()) {
            return
        }
        let context = pageContextForNode(node)
        if (context.isNone()) {
            return
        }
        let resolved = context.getOrThrow()
        let groupIdentity = resolved[0]
        let pageKey = resolved[1]
        let bookmark = CjguiComposableUiPageFocusBookmark(groupIdentity, pageKey, node.nodeId, node.resourceId,
            node.nodeKind, focusedSelectionStart, focusedSelectionEnd, cjguiSelectionUtf16Length(node.value))
        var index = 0
        while (index < pageFocusBookmarks.size) {
            let existing = pageFocusBookmarks[index]
            if (existing.groupIdentity == groupIdentity && existing.pageKey == pageKey) {
                pageFocusBookmarks[index] = bookmark
                return
            }
            index += 1
        }
        // Bounded: the oldest bookmark is dropped, so a long-lived window with
        // many tab containers keeps a fixed amount of view state.
        while (pageFocusBookmarks.size >= 8) {
            pageFocusBookmarks.remove(at: 0)
        }
        pageFocusBookmarks.add(bookmark)
    }

    /// Runs on every accepted scene. A tab container whose ACTIVE page changed in
    /// THIS scene is a real page switch (pointer, keyboard, AX or a public
    /// `select`), and only then does that page restore its bookmark. A background
    /// business write cannot change the active page, so it can never steal focus.
    private func restorePageFocusAfterAcceptedScene(): Unit {
        let nextActive = HashMap<Int64, String>()
        let switched = ArrayList<(Int64, String)>()
        for (node in nativeInputScene.nodes()) {
            if (!node.isTabPage() || !node.tabsPageActive) {
                continue
            }
            let state = match (node.tabsState) {
                case Some(value) => value
                case None => continue
            }
            let group = state.viewStateIdentity()
            nextActive.add(group, node.tabsPageKey)
            let previous = acceptedActivePageKeys.get(group)
            let changed = match (previous) {
                case Some(value) => value != node.tabsPageKey
                case None => false
            }
            if (changed) {
                switched.add((group, node.tabsPageKey))
            }
        }
        acceptedActivePageKeys = nextActive
        for (entry in switched) {
            restorePageFocusFor(entry[0], entry[1])
        }
    }

    /// Applies the bookmark of the page a person just switched TO. It validates the
    /// recorded identity against the ACCEPTED scene and bounds the stale selection
    /// against the value the OWNER has now. An identity that was rebound, disabled
    /// or removed keeps the title focus instead, which is the legal fallback.
    private func restorePageFocusFor(groupIdentity: Int64, pageKey: String): Unit {
        var record: ?CjguiComposableUiPageFocusBookmark = None
        for (candidate in pageFocusBookmarks) {
            if (candidate.groupIdentity == groupIdentity && candidate.pageKey == pageKey) {
                record = Some(candidate)
            }
        }
        if (record.isNone()) {
            return
        }
        let bookmark = record.getOrThrow()
        let current = nativeInputScene.nodeForId(bookmark.nodeId)
        if (current.nodeId != bookmark.nodeId || current.resourceId != bookmark.resourceId ||
            current.nodeKind != bookmark.nodeKind || !current.canReceiveFocus()) {
            return
        }
        let context = pageContextForNode(current)
        if (context.isNone()) {
            return
        }
        let resolved = context.getOrThrow()
        if (resolved[0] != groupIdentity || resolved[1] != pageKey) {
            return
        }
        if (!focusProjectedNode(current.nodeId, rememberBookmark: false)) {
            return
        }
        // The position is bounded by the value the owner has NOW; the value itself
        // is never replayed from the bookmark.
        let currentLength = cjguiSelectionUtf16Length(current.value)
        let bound = if (currentLength < bookmark.valueLength) {
            currentLength
        } else {
            bookmark.valueLength
        }
        var start = if (bookmark.selectionStart > bound) {
            bound
        } else {
            bookmark.selectionStart
        }
        var end = if (bookmark.selectionEnd > bound) {
            bound
        } else {
            bookmark.selectionEnd
        }
        if (end < start) {
            end = start
        }
        let nativeSelection = internalRendererRestoreComposableSelection(sessionToken, current.nodeId,
            current.resourceId, current.nodeKind, nativeInputScene.version, current.value, start, end)
        lastNativeStatus = nativeSelection[0]
        if (nativeSelection[0] != CJGUI_INTERNAL_RENDERER_OK) {
            return
        }
        focusedSelectionStart = nativeSelection[1]
        focusedSelectionEnd = nativeSelection[2]
        // Publish only the selection actually accepted by the native input proxy.
        refreshPageFocusBookmark(current)
        interactionVersion += 1
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
        let (tabGroupId, tabSelected) = nativeTabStopMetadata(node)
        if (node.textStyleRuns.size > 0) {
            var encoded = ""
            var runIndex: Int64 = 0
            while (runIndex < node.textStyleRuns.size) {
                if (runIndex > 0) {
                    encoded += ";"
                }
                encoded += node.textStyleRuns[runIndex].encoded()
                runIndex += 1
            }
            let runStatus = internalRendererSetComposableTextRuns(this.sessionToken, UInt64(node.nodeId), encoded)
            if (runStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = runStatus
            }
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
            isInteractive: if (node.canReceiveInput() || node.canReceiveFocus() || node.style.pointerInteractive) {
                1u32
            } else {
                0u32
            },
            isReadOnly: if (node.isReadOnly && !node.style.pointerInteractive) {
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
            inputScope: nativeInputScope,
            tabGroupId: tabGroupId,
            tabSelected: tabSelected
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
            node.semanticId,
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
        // A1 前置结算门：有未决票据时不提交交互投影，否则会与在途候选争用
        // native 的唯一未确认槽，让原候选被裁决两次。
        if (settlePendingPresent()) {
            return false
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
        if (lastNativeStatus == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) {
            // A1：交互投影同样会产生票据，必须建立自己的事务（它没有 participant /
            // identity / layout 候选，收尾不走完整刷新链，也不调用完整回滚链）。
            return beginPendingInteractionTransaction(paintScene: paintScene,
                dataTransferBindings: interactionDataTransferBindings, ticketId: frame.ticketId,
                consumedRequestEpoch: refreshRequestEpoch)
        }
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

    /// Runs are part of the rendered scene. A run-only change (a caret mark, an inline
    /// tint, a new bold span) must count as a SCENE CHANGE: otherwise the refresh takes
    /// the "same scene, nothing to submit" branch, the native side never commits, and the
    /// change is never rasterized -- which is exactly why the caret was never painted
    /// (root cause confirmed against the commit numbers). Comparing the SAME encoding the
    /// renderer consumes keeps this comparison and the native texture key in step.
    private func sameTextStyleRuns(left: Array<CjguiComposableUiTextStyleRun>,
        right: Array<CjguiComposableUiTextStyleRun>): Bool {
        if (left.size != right.size) {
            return false
        }
        var index: Int64 = 0
        while (index < left.size) {
            if (left[index].encoded() != right[index].encoded()) {
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
            right.style) && this.sameTextStyleRuns(left.textStyleRuns, right.textStyleRuns)
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
            right.layerInitialFocusNodeId() || !sameStyle(left.style, right.style) ||
            !this.sameTextStyleRuns(left.textStyleRuns, right.textStyleRuns)) {
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
        if ((node.nodeKind == 13 || node.nodeKind == 14) && node.canReceiveInput()) {
            return true
        }
        // A read-only presentation surface that opted into pointer delivery also
        // gets the begin/update/end phases. Without this the pointer never
        // reaches the controller for a TEXT node, so a click could not be
        // resolved to a display position even though the hit test is ready.
        return node.style.pointerInteractive
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
            // A state-bound divider is framework-owned: the drag is applied to the
            // shared split view state and the ordinary capture path keeps the
            // update/end phases flowing without an application split owner.
            if (splitStateForDivider(resolved).isSome()) {
                let _ = applySplitStatePointerDrag(resolved, x)
                pointerCaptureNode = resolved
                pointerCaptureOwnerVersion = pointerCaptureVersionFor(resolved)
                pointerCaptureModalLayerId = activeModalLayerId
                pointerCaptureActive = true
                pointerCaptureX = x
                pointerCaptureY = y
                return CjguiComposableUiDispatchResult(true)
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
        if (!pointerCaptureActive) {
            return controller.rejectUiEvent(eventKind, nodeId)
        }
        // The framework owns a state-bound divider for the WHOLE drag: the pointer
        // legitimately leaves the thin divider while the panes resize, and a
        // framework-only size change must not cancel the gesture the way a stale
        // business write does. No phase is handed to an application split owner.
        if (splitStateForDivider(pointerCaptureNode).isSome() && (eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE || eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            let splitDragChanged = applySplitStatePointerDrag(pointerCaptureNode, x)
            pointerCaptureX = x
            pointerCaptureY = y
            if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) {
                clearPointerCapture()
            }
            return CjguiComposableUiDispatchResult(splitDragChanged)
        }
        if (pointerCaptureNode.nodeId != nodeId || pointerCaptureNode.resourceId != nativeEvent.resourceId ||
            pointerCaptureNode.nodeKind != Int64(nativeEvent.nodeKind)) {
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
    /// Roll a hidden text proxy back to the value the owner actually accepted
    /// after a refused range edit. It never invents content: it restores the
    /// committed node value under projection suppression and adopts the
    /// grapheme-safe caret native reports. The intent is dropped as soon as the
    /// target is no longer the active node, because the ordinary projection path
    /// then owns the value again.
    private func recoverRefusedRangeTextProxy(): Unit {
        if (!refusedRangeTextPending || !isWindowOpen) {
            return
        }
        if (refusedRangeTextAttempts >= 3) {
            // Bounded retries: report the failure instead of looping forever.
            refusedRangeTextPending = false
            refusedRangeTextFailures += 1
            return
        }
        refusedRangeTextAttempts += 1
        let target = nativeInputScene.resolveInput(refusedRangeTextNodeId, refusedRangeTextResourceId,
            refusedRangeTextNodeKind, nativeInputScene.version)
        if (target.nodeId != refusedRangeTextNodeId || target.resourceId != refusedRangeTextResourceId ||
            target.nodeKind != refusedRangeTextNodeKind) {
            refusedRangeTextPending = false
            return
        }
        let outcome = internalRendererRecoverActiveTextProxy(sessionToken, refusedRangeTextNodeId,
            refusedRangeTextResourceId, refusedRangeTextNodeKind, target.value)
        if (outcome[0] == CJGUI_INTERNAL_RENDERER_OK) {
            refusedRangeTextPending = false
            refusedRangeTextRecoveries += 1
            focusedSelectionStart = outcome[1]
            focusedSelectionEnd = outcome[2]
            interactionVersion += 1
            return
        }
        // Still focused on the same identity: keep the intent for the next
        // bounded attempt. Otherwise the dirty proxy no longer belongs to this
        // target and the normal staging path is authoritative.
        if (focusedNodeId != refusedRangeTextNodeId || focusedResourceId != refusedRangeTextResourceId ||
            focusedNodeKind != refusedRangeTextNodeKind) {
            refusedRangeTextPending = false
        }
    }

    /// Number of successful proxy rollbacks after refused range edits.
    public func refusedRangeTextRecoveryCount(): Int64 {
        return refusedRangeTextRecoveries
    }

    /// Number of refused range edits whose bounded rollback retries were spent
    /// without restoring the proxy. A non-zero value means the platform adapter
    /// stayed dirty, which must be reported rather than called recovered.
    public func refusedRangeTextFailureCount(): Int64 {
        return refusedRangeTextFailures
    }

    /// True while a refused range edit still needs its proxy rolled back.
    public func isRefusedRangeTextRecoveryPending(): Bool {
        return refusedRangeTextPending
    }

    /// Forget the "the hidden proxy already holds this value" handoff. It must
    /// be dropped whenever the owner refuses a text edit: the proxy still holds
    /// the refused local text, so the next projection has to re-assert the
    /// accepted value (and caret) through a real Cangjie-to-NSString round trip.
    private func clearPendingLocalTextValue(): Unit {
        pendingLocalTextNodeId = -1
        pendingLocalTextResourceId = -1
        pendingLocalTextNodeKind = -1
        pendingLocalTextValue = ""
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
        // A selection the person moved inside a page updates that page's bookmark,
        // so switching away and back presents the place they last had.
        refreshPageFocusBookmark(node)
        interactionVersion += 1
    }
    /// Rejects the candidate and keeps the accepted scene live. A concrete
    /// rejection reason (for example `duplicate_node_id` from an invalid
    /// candidate scene) is published through window progress instead of
    /// collapsing into the generic renderer status text: an external operator
    /// driving this window must be able to tell *why* the visible scene did not
    /// follow its change, without a diagnostic build.
    /// A1：完整刷新的接受链收尾。同步成功与「票据结算为 Accepted」共用同一段
    /// 代码，避免两条路径分叉。所有事实来自本次提交的原事务，不读最新 owner。
    ///
    /// Astra：收到 native Accepted 后，必须在任何焦点恢复或 participant 调用
    /// 之前进入不可回滚状态——因此调用方负责在进入本函数前设置 acceptedCandidate。
    private func finishAcceptedScene(root!: CjguiComposableUiNode, paintScene!: CjguiComposableUiScene,
        previouslySubmittedScene!: CjguiComposableUiScene,
        participant!: ?CjguiComposableUiSceneRefreshParticipant,
        candidateCommands!: ArrayList<CjguiComposableUiCommand>,
        candidateDataTransferBindings!: ArrayList<CjguiComposableUiDataTransferBinding>,
        declaredVersion!: Int64, viewportResizeVersion!: UInt64, viewportResourceCompletionVersion!: UInt64,
        frameIndex!: Int64, readbackCompleted!: UInt8, consumedRequestEpoch!: Int64): Bool {
        renderedRoot = root
        renderedScene = paintScene
        nativeInputScene = paintScene
        commitStagedSceneViewports()
        commitStagedSceneSplitTracks()
        // Ownership of the shared view objects is published with the same
        // accepted scene, and the objects this accepted structure no longer
        // references are given back.
        commitCandidateViewStateOwnership()
        reconcileOwnedViewStateAfterAcceptance(root)
        // B2: a tab switch is presented by THIS scene, so the page the person
        // switched to restores its own valid focus/selection now. It runs only
        // here, where `nativeInputScene` is the scene just accepted.
        restorePageFocusAfterAcceptedScene()
        acceptedSceneVersion = paintScene.version
        submittedSceneVersion = paintScene.version
        submittedFrameIndex = frameIndex
        nativeSubmissionCount += 1
        lastNativeSubmissionSnapshotValue = Some(CjguiComposableUiNativeSubmissionSnapshot(MonoTime.now(),
            acceptedSceneVersion, submittedSceneVersion, nativeSubmissionCount))
        if (readbackCompleted != 0u8) {
            observedMetalCompletionFrameIndex = frameIndex
        }
        lastControllerSceneVersion = declaredVersion
        lastViewportResizeVersion = viewportResizeVersion
        lastResourceCompletionVersion = viewportResourceCompletionVersion
        // A1：只消费原事务记录的那个 epoch。等待期间若有更新的刷新请求，必须
        // 保留 refreshRequested，让下一轮重新提交，而不是静默吞掉那些修改。
        if (refreshRequestEpoch > consumedRequestEpoch) {
            pendingRefreshReason = "refresh_after_pending_settlement"
        } else {
            refreshRequested = false
            pendingRefreshReason = "none"
        }
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
        // A1：关闭意图挂起时不再恢复焦点（关闭态不得绑定交互状态）。
        if (!closeIntentPending) {
            restoreFocusAfterProjectionChange(previouslySubmittedScene)
        }
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
    }

    /// A1：交互投影的接受收尾。交互投影没有 participant/identity/layout 候选，
    /// 因此不得调用完整刷新的回滚链，只晋升自己的场景与绑定（Astra 第 1 点）。
    private func finishAcceptedInteractionPaint(paintScene!: CjguiComposableUiScene,
        dataTransferBindings!: ArrayList<CjguiComposableUiDataTransferBinding>, frameIndex!: Int64,
        readbackCompleted!: UInt8, consumedRequestEpoch!: Int64): Bool {
        nextProjectionVersion = paintScene.version
        renderedScene = paintScene
        nativeInputScene = paintScene
        replaceDataTransferBindings(dataTransferBindings)
        acceptedSceneVersion = paintScene.version
        submittedSceneVersion = paintScene.version
        submittedFrameIndex = frameIndex
        nativeSubmissionCount += 1
        if (readbackCompleted != 0u8) {
            observedMetalCompletionFrameIndex = frameIndex
        }
        lastNativeFailure = if (lastNativeStatus == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
            nativeStatusReason(lastNativeStatus)
        } else {
            "none"
        }
        if (refreshRequestEpoch > consumedRequestEpoch) {
            pendingRefreshReason = "refresh_after_pending_settlement"
        } else {
            refreshRequested = false
            pendingRefreshReason = "none"
        }
        return true
    }

    /// A1：把一次 PENDING 的完整刷新收进事务，并请求下一轮结算。候选与 staged
    /// 事实全部保留（不回滚、不丢弃视口/所有权）；native 的一次性 commit/rollback
    /// 仍是唯一的 accepted 裁决点。
    private func beginPendingTransaction(participant!: ?CjguiComposableUiSceneRefreshParticipant,
        root!: CjguiComposableUiNode, paintScene!: CjguiComposableUiScene,
        previouslySubmittedScene!: CjguiComposableUiScene, declaredVersion!: Int64,
        viewport!: InternalRendererViewportResult,
        candidateCommands!: ArrayList<CjguiComposableUiCommand>,
        candidateDataTransferBindings!: ArrayList<CjguiComposableUiDataTransferBinding>,
        ticketId!: UInt64, consumedRequestEpoch!: Int64): Bool {
        return recordPendingTransaction(0, ticketId, consumedRequestEpoch, paintScene, root: root,
            previouslySubmittedScene: previouslySubmittedScene, participant: participant,
            candidateCommands: candidateCommands, candidateDataTransferBindings: candidateDataTransferBindings,
            declaredVersion: declaredVersion, viewportResizeVersion: viewport.resizeVersion,
            viewportResourceCompletionVersion: viewport.resourceCompletionVersion)
    }

    /// A1：把一次 PENDING 的交互投影收进事务。
    private func beginPendingInteractionTransaction(paintScene!: CjguiComposableUiScene,
        dataTransferBindings!: ArrayList<CjguiComposableUiDataTransferBinding>, ticketId!: UInt64,
        consumedRequestEpoch!: Int64): Bool {
        return recordPendingTransaction(1, ticketId, consumedRequestEpoch, paintScene,
            interactionDataTransferBindings: dataTransferBindings)
    }

    /// A1：事务登记的唯一实现点。ticketId == 0 说明 native 声称“未定”却没有给出
    /// 票据编号——核心无从查询，这是协议缺口，不得伪造成事务无限重试。
    private func recordPendingTransaction(kind: Int64, ticketId: UInt64, consumedRequestEpoch: Int64,
        paintScene: CjguiComposableUiScene, root!: ?CjguiComposableUiNode = None,
        previouslySubmittedScene!: ?CjguiComposableUiScene = None,
        participant!: ?CjguiComposableUiSceneRefreshParticipant = None,
        candidateCommands!: ?ArrayList<CjguiComposableUiCommand> = None,
        candidateDataTransferBindings!: ?ArrayList<CjguiComposableUiDataTransferBinding> = None,
        declaredVersion!: Int64 = 0, viewportResizeVersion!: UInt64 = 0u64,
        viewportResourceCompletionVersion!: UInt64 = 0u64,
        interactionDataTransferBindings!: ?ArrayList<CjguiComposableUiDataTransferBinding> = None): Bool {
        lastNativeStatus = CJGUI_INTERNAL_RENDERER_PRESENT_PENDING
        pendingRefreshReason = "refresh_present_pending"
        refreshRequested = true
        presentAttemptCounter += 1
        if (ticketId == 0) {
            lastNativeFailure = "present_pending_without_ticket"
            startupPhase = "pending_without_ticket"
            recordStartupFailure("present_pending_without_ticket")
            refreshRequested = false
            pendingRefreshReason = "refresh_present_pending_without_ticket"
            return false
        }
        lastNativeFailure = "present_pending"
        pendingTransaction = Some(CjguiComposableUiPendingPresentTransaction(kind, presentAttemptCounter,
            ticketId, consumedRequestEpoch, paintScene, root: root,
            previouslySubmittedScene: previouslySubmittedScene, participant: participant,
            candidateCommands: candidateCommands, candidateDataTransferBindings: candidateDataTransferBindings,
            declaredVersion: declaredVersion, viewportResizeVersion: viewportResizeVersion,
            viewportResourceCompletionVersion: viewportResourceCompletionVersion,
            interactionDataTransferBindings: interactionDataTransferBindings))
        return false
    }

    /// A1：前置结算门。所有可能刷新或分发交互的入口都必须先经过它。
    ///
    /// 返回 true 表示本轮**不得**提交新候选：仍有未决票据，或刚完成一次结算而需要
    /// 重新评估刷新条件。返回 false 表示没有未决票据，可以正常继续。
    func settlePendingPresent(): Bool {
        let tx = match (pendingTransaction) {
            case Some(value) => value
            case None => return false
        }
        if (tx.settled) {
            // A1：native 终态已观察。ACK 只重试原票；ACK 成功不等于核心收尾
            // 成功，清票必须以 coreSettled 为准。
            if (!tx.ackCompleted) {
                let ackRetry = internalRendererAcknowledgePresent(sessionToken, tx.ticketId)
                if (ackRetry == CJGUI_INTERNAL_RENDERER_OK) {
                    tx.ackCompleted = true
                } else {
                    lastNativeStatus = ackRetry
                    lastNativeFailure = "present_ack_retry"
                    pendingRefreshReason = "present_ack_retry"
                    return true
                }
            }
            if (!tx.coreSettled) {
                // A1：不可回滚的终止收敛路径。native 终态已确认、协议已 ACK，
                // 但核心收尾未完整（回调异常或返回假）。候选持有保留（阻止
                // 新候选），不重跑 acceptance/rollback（避免重复 participant/
                // focus 回调）；每轮命名报告故障。唯一出路是显式 close/discard。
                lastNativeStatus = CJGUI_INTERNAL_RENDERER_OK
                lastNativeFailure = tx.settlementFault
                lastSettlementFault = tx.settlementFault
                pendingRefreshReason = "refresh_settlement_incomplete"
                return true
            }
            pendingTransaction = None
            if (discardRetryReason != "") {
                let reason = discardRetryReason
                discardRetryReason = ""
                discardSession(reason)
            }
            return false
        }
        let receipt = internalRendererQueryPresent(sessionToken, tx.ticketId)
        if (receipt.status != CJGUI_INTERNAL_RENDERER_OK) {
            // 查询本身失败：既不把它当成拒绝，也不建第二个事务。
            lastNativeStatus = receipt.status
            lastNativeFailure = "present_query_${nativeStatusReason(receipt.status)}"
            pendingRefreshReason = "refresh_present_query_failed"
            return true
        }
        if (receipt.decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING) {
            // 仍未定：保留全部候选与 accepted，不 begin/build/present/回滚。
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_PRESENT_PENDING
            lastNativeFailure = "present_pending"
            return true
        }
        if (receipt.decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) {
            tx.settled = true
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_OK
            // A1：接受必须使用事务里保存的版本、绑定与 scene，不能临时读最新
            // owner 来完成旧候选；即使 owner 已从 V1 改成 V2，也先接受 V1。
            // 收尾回调可能抛异常：acceptanceStarted 先落账，异常不再重跑同一
            // 回调（防重复 participant/focus），转入不可回滚的终止收敛。
            if (!tx.acceptanceStarted) {
                tx.acceptanceStarted = true
                try {
                    tx.coreSettled = applyPendingAcceptance(tx, receipt.frameIndex)
                    if (!tx.coreSettled) {
                        tx.settlementFault = "present_acceptance_incomplete"
                    }
                } catch (e: Exception) {
                    tx.coreSettled = false
                    tx.settlementFault = "present_acceptance_exception"
                }
            }
            if (!tx.coreSettled) {
                // 核心收尾未完整：本轮不 ACK、不清票，由 settled 分支做终止收敛。
                lastNativeFailure = tx.settlementFault
                pendingRefreshReason = "refresh_settlement_incomplete"
                return true
            }
            // A1：ACK 结果必须检查；失败保留事务（settled），下一结算轮重试
            // 原 ACK，期间不得开放新候选。
            let ackStatus = internalRendererAcknowledgePresent(sessionToken, tx.ticketId)
            if (ackStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = ackStatus
                lastNativeFailure = "present_ack_failed"
                pendingRefreshReason = "present_ack_retry"
                return true
            }
            tx.ackCompleted = true
            if (startingPending) {
                // A1：首帧以 PENDING 受理后在此真正 Ready。
                startingPending = false
            }
            pendingTransaction = None
            if (discardRetryReason != "") {
                let reason = discardRetryReason
                discardRetryReason = ""
                discardSession(reason)
                return true
            }
            return true
        }
        if (receipt.decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED) {
            tx.settled = true
            // A1：回滚异常同样按原票收尾——不重跑回滚（防重复回调），转入
            // 终止收敛；rollback 成功才允许 ACK/清票/再投影。
            if (!tx.acceptanceStarted) {
                tx.acceptanceStarted = true
                try {
                    let _ = rollbackPendingTransaction(tx, receipt)
                    tx.coreSettled = true
                } catch (e: Exception) {
                    tx.coreSettled = false
                    tx.settlementFault = "present_rollback_exception"
                }
            }
            if (!tx.coreSettled) {
                lastNativeFailure = tx.settlementFault
                pendingRefreshReason = "refresh_settlement_incomplete"
                return true
            }
            let ackStatus = internalRendererAcknowledgePresent(sessionToken, tx.ticketId)
            if (ackStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = ackStatus
                lastNativeFailure = "present_ack_failed"
                pendingRefreshReason = "present_ack_retry"
                return true
            }
            tx.ackCompleted = true
            pendingTransaction = None
            // 画面可能与刚提交的候选分离：安排一次重新同步（下一轮刷新）。
            refreshRequested = true
            pendingRefreshReason = "refresh_after_present_rejected"
            if (discardRetryReason != "") {
                let reason = discardRetryReason
                discardRetryReason = ""
                discardSession(reason)
            }
            return true
        }
        // DECISION_NONE：核心本地仍持有该 ticket 却查不到 —— 协议缺口。
        // 不得把它当成拒绝，也不得当成重新开始的许可。
        lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        lastNativeFailure = "present_ticket_lost"
        pendingRefreshReason = "refresh_present_ticket_lost"
        return true
    }

    /// A1：按原提交类型执行原接受链一次。
    private func applyPendingAcceptance(tx: CjguiComposableUiPendingPresentTransaction,
        settledFrameIndex: UInt64): Bool {
        if (CJGUI_WINDOW_GATE_ACCEPTANCE_THROW) {
            CJGUI_WINDOW_GATE_ACCEPTANCE_THROW = false
            throw Exception("gate_injected_acceptance_exception")
        }
        if (tx.kind == 1) {
            match (tx.interactionDataTransferBindings) {
                case Some(bindings) => return finishAcceptedInteractionPaint(paintScene: tx.paintScene,
                    dataTransferBindings: bindings, frameIndex: Int64(settledFrameIndex), readbackCompleted: 0u8,
                    consumedRequestEpoch: tx.consumedRequestEpoch)
                case None => return false
            }
        }
        let rootValue = match (tx.root) {
            case Some(value) => value
            case None => return false
        }
        let commands = match (tx.candidateCommands) {
            case Some(value) => value
            case None => return false
        }
        let bindings = match (tx.candidateDataTransferBindings) {
            case Some(value) => value
            case None => return false
        }
        let previous = match (tx.previouslySubmittedScene) {
            case Some(value) => value
            case None => tx.paintScene
        }
        return finishAcceptedScene(root: rootValue, paintScene: tx.paintScene,
            previouslySubmittedScene: previous, participant: tx.participant, candidateCommands: commands,
            candidateDataTransferBindings: bindings, declaredVersion: tx.declaredVersion,
            viewportResizeVersion: tx.viewportResizeVersion,
            viewportResourceCompletionVersion: tx.viewportResourceCompletionVersion,
            frameIndex: Int64(settledFrameIndex), readbackCompleted: 0u8,
            consumedRequestEpoch: tx.consumedRequestEpoch)
    }

    /// A1：按原提交类型回滚原候选一次。完整刷新走 participant/registry 回滚链；
    /// 交互投影只丢弃自己的 staged 事实。
    private func rollbackPendingTransaction(tx: CjguiComposableUiPendingPresentTransaction,
        receipt: InternalRendererPresentReceipt): Bool {
        if (CJGUI_WINDOW_GATE_ROLLBACK_THROW) {
            CJGUI_WINDOW_GATE_ROLLBACK_THROW = false
            throw Exception("gate_injected_rollback_exception")
        }
        if (tx.kind == 1) {
            return noteInteractionPaintFailure(receipt.terminalStatus)
        }
        return rejectParticipantCandidate(tx.participant, receipt.terminalStatus,
            reason: "present_settlement_rejected")
    }

    private func rejectParticipantCandidate(participant: ?CjguiComposableUiSceneRefreshParticipant, status: Int32,
        reason!: String = ""): Bool {
        layoutReuseCache.discardPass()
        // Every early return and rejection path drops the candidate viewport
        // facts; the previous accepted scene keeps publishing its own.
        discardStagedSceneViewports()
        discardStagedSceneSplitTracks()
        // Ownership this candidate only VALIDATED is dropped too: a rejected
        // attempt must not leave a shared view object claimed by a window whose
        // accepted scene never contained it.
        discardStagedViewStateOwnership()
        if (let Some(value) <- participant) {
            value.rollbackSceneRefresh()
        }
        identityRegistry.rollbackCandidate()
        if (reason.size > 0) {
            lastNativeStatus = status
            lastNativeFailure = reason
            pendingRefreshReason = "refresh_${reason}"
            recordStartupFailure(reason)
            refreshRequested = false
            return false
        }
        return noteRefreshFailure(status)
    }
    /// Promotes the candidate viewport facts of the scene the window just
    /// accepted. The offset becomes accepted only now.
    private func commitStagedSceneViewports(): Unit {
        for (viewport in stagedSceneViewports) {
            viewport.commitStagedExtents()
        }
        stagedSceneViewports = ArrayList<CjguiComposableUiScrollViewport>()
    }

    /// Promotes the candidate split track facts of the same accepted scene, so a
    /// divider drag is clamped by the track that is really on screen.
    private func commitStagedSceneSplitTracks(): Unit {
        for (fact in stagedSceneSplitTracks) {
            fact.state.acceptSplitTrack(fact.track, fact.handleSize, fact.firstSize)
        }
        stagedSceneSplitTracks = ArrayList<CjguiComposableUiSplitTrackFact>()
    }

    /// Drops the candidate viewport facts of a rejected/abandoned attempt.
    private func discardStagedSceneViewports(): Unit {
        for (viewport in stagedSceneViewports) {
            viewport.discardStagedExtents()
        }
        stagedSceneViewports = ArrayList<CjguiComposableUiScrollViewport>()
    }

    /// Drops the candidate split track facts of a rejected/abandoned attempt, so
    /// a trial layout never becomes the bounds a real drag is measured against.
    private func discardStagedSceneSplitTracks(): Unit {
        stagedSceneSplitTracks = ArrayList<CjguiComposableUiSplitTrackFact>()
    }

    /// Validates every MUTABLE view object bound by this candidate for THIS
    /// window, without publishing anything. Returns a non-empty issue when a
    /// different window already accepted a scene containing one of them: sharing
    /// a single mutable viewport/split/tab state across windows is not supported,
    /// so the candidate is refused rather than silently coupling the two windows'
    /// geometry.
    ///
    /// The objects this candidate would NEWLY claim are staged, not claimed: a
    /// later failure in the same candidate (or a rejected scene) therefore leaves
    /// no ownership behind at all, which is what lets a third window use an object
    /// that a failed candidate merely mentioned.
    private func validateCandidateViewStateOwnership(node: CjguiComposableUiNode): String {
        if (let Some(viewport) <- node.scrollViewport) {
            let owner = viewport.ownerWindowToken()
            if (owner != 0 && owner != instanceToken) {
                return "cross_window_view_state_shared:scroll"
            }
            if (owner == 0) {
                stagedViewStateViewports.add(viewport)
            }
        }
        if (let Some(state) <- node.splitState) {
            let owner = state.ownerWindowToken()
            if (owner != 0 && owner != instanceToken) {
                return "cross_window_view_state_shared:split"
            }
            if (owner == 0) {
                stagedViewStateSplits.add(state)
            }
        }
        if (let Some(state) <- node.tabsState) {
            let owner = state.ownerWindowToken()
            if (owner != 0 && owner != instanceToken) {
                return "cross_window_view_state_shared:tabs"
            }
            if (owner == 0) {
                stagedViewStateTabs.add(state)
            }
        }
        for (child in node.children()) {
            let issue = validateCandidateViewStateOwnership(child)
            if (issue.size > 0) {
                return issue
            }
        }
        return ""
    }

    /// Publishes the ownership this candidate staged, in the same transaction that
    /// accepts the scene containing those objects. `claimOwner` is idempotent, so
    /// the same object reached twice by the walk is harmless.
    private func commitCandidateViewStateOwnership(): Unit {
        for (viewport in stagedViewStateViewports) {
            let _ = viewport.claimOwner(instanceToken)
        }
        for (state in stagedViewStateSplits) {
            let _ = state.claimOwner(instanceToken)
        }
        for (state in stagedViewStateTabs) {
            let _ = state.claimOwner(instanceToken)
        }
        discardStagedViewStateOwnership()
    }

    /// Drops the ownership this candidate staged. Nothing was published, so no
    /// accepted object and no other window's right is touched.
    private func discardStagedViewStateOwnership(): Unit {
        stagedViewStateViewports = ArrayList<CjguiComposableUiScrollViewport>()
        stagedViewStateSplits = ArrayList<CjguiComposableUiSplitState>()
        stagedViewStateTabs = ArrayList<CjguiComposableUiTabsState>()
    }

    /// Recomputes which view objects this window still references from the
    /// ACCEPTED scene, and gives back the ones it no longer references (a removed
    /// or re-identified element). The object list is rebuilt from the walk, so
    /// repeated refreshes cannot accumulate stale ownership.
    private func reconcileOwnedViewStateAfterAcceptance(root: CjguiComposableUiNode): Unit {
        viewStateLiveStamp += 1
        let stamp = viewStateLiveStamp
        let previousViewports = ownedViewStateViewports
        let previousSplits = ownedViewStateSplits
        let previousTabs = ownedViewStateTabs
        ownedViewStateViewports = ArrayList<CjguiComposableUiScrollViewport>()
        ownedViewStateSplits = ArrayList<CjguiComposableUiSplitState>()
        ownedViewStateTabs = ArrayList<CjguiComposableUiTabsState>()
        collectOwnedViewStateObjects(root, stamp)
        for (viewport in previousViewports) {
            if (viewport.liveStamp() != stamp) {
                let _ = viewport.releaseOwner(instanceToken)
            }
        }
        for (state in previousSplits) {
            if (state.liveStamp() != stamp) {
                let _ = state.releaseOwner(instanceToken)
            }
        }
        for (state in previousTabs) {
            if (state.liveStamp() != stamp) {
                let _ = state.releaseOwner(instanceToken)
            }
        }
    }

    private func collectOwnedViewStateObjects(node: CjguiComposableUiNode, stamp: Int64): Unit {
        if (let Some(viewport) <- node.scrollViewport) {
            if (viewport.ownerWindowToken() == instanceToken) {
                viewport.markLive(stamp)
                ownedViewStateViewports.add(viewport)
            }
        }
        if (let Some(state) <- node.splitState) {
            if (state.ownerWindowToken() == instanceToken) {
                state.markLive(stamp)
                ownedViewStateSplits.add(state)
            }
        }
        if (let Some(state) <- node.tabsState) {
            if (state.ownerWindowToken() == instanceToken) {
                state.markLive(stamp)
                ownedViewStateTabs.add(state)
            }
        }
        for (child in node.children()) {
            collectOwnedViewStateObjects(child, stamp)
        }
    }

    /// Gives every view object this window owns back (startup failure, normal
    /// close, session discard). Releasing twice is a no-op, so a repeated call is
    /// safe.
    private func releaseOwnedViewStateOwnership(): Unit {
        discardStagedViewStateOwnership()
        for (viewport in ownedViewStateViewports) {
            let _ = viewport.releaseOwner(instanceToken)
        }
        for (state in ownedViewStateSplits) {
            let _ = state.releaseOwner(instanceToken)
        }
        for (state in ownedViewStateTabs) {
            let _ = state.releaseOwner(instanceToken)
        }
        ownedViewStateViewports = ArrayList<CjguiComposableUiScrollViewport>()
        ownedViewStateSplits = ArrayList<CjguiComposableUiSplitState>()
        ownedViewStateTabs = ArrayList<CjguiComposableUiTabsState>()
    }

    private func recordStartupFailure(reason: String): Unit {
        if (acceptedSceneVersion <= 0 && firstStartupFailure == "none") {
            firstStartupFailure = "${startupPhase}_${reason}"
        }
    }
    private func noteIdentityRefreshFailure(issue: String): Bool {
        layoutReuseCache.discardPass()
        discardStagedSceneViewports()
        discardStagedSceneSplitTracks()
        discardStagedViewStateOwnership()
        lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        let resolvedIssue = if (issue.size > 0) {
            issue
        } else {
            "identity_candidate_invalid"
        }
        lastNativeFailure = resolvedIssue
        pendingRefreshReason = "refresh_${resolvedIssue}"
        recordStartupFailure(resolvedIssue)
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
        recordStartupFailure(reason)
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
            status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR || status ==
            CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED
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
        if (status == CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED) {
            return "text_resource_budget_exceeded"
        }
        return "internal_error"
    }
    private func discardSession(reason: String) {
        // The window's ONE dispose boundary. It runs for a normal close AND for a
        // startup/native failure, so a participant's shared-catalog holds are
        // released by the real lifecycle instead of by a caller remembering to
        // call the release method.
        discardStagedSceneViewports()
        discardStagedSceneSplitTracks()
        // The window's accepted structure ends here, so every shared view object
        // it owned is given back: a later window may legally take the same
        // declaration over instead of inheriting a dead window's claim.
        releaseOwnedViewStateOwnership()
        let disposeParticipant = controller as CjguiComposableUiSceneRefreshParticipant
        if (let Some(value) <- disposeParticipant) {
            value.disposeSceneRefreshResources()
        }
        if (sessionToken != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            let status = internalRendererDestroy(sessionToken)
            if (status != CJGUI_INTERNAL_RENDERER_OK) {
                // A1：destroy 被拒绝（结算槽有未确认票据）。保留 session token
                // 与窗口状态，记录重试原因；结算 + ACK 完成后重试本 discard。
                // 不能无视拒绝清 token——那会让 native 会话变成不可寻址的孤儿。
                lastNativeStatus = status
                discardRetryReason = reason
                return
            }
        }
        discardRetryReason = ""
        closeIntentPending = false
        if (testCloseReason.size == 0) {
            testCloseReason = reason
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
        // The window's accepted pages end here, so their focus/selection bookmarks
        // are released with the rest of its per-session view state.
        pageFocusBookmarks = ArrayList<CjguiComposableUiPageFocusBookmark>()
        acceptedActivePageKeys = HashMap<Int64, String>()
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

/// Install style runs for every node in a composable tree. The controller's tree
/// is the authoritative carrier of presentation runs; walking it here means the
/// runs do not have to survive every layout/clone path inside the engine.
func internalRendererInstallComposableTextRuns(session: UInt64, node: CjguiComposableUiNode): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_OK
    // Always publish this node's runs, INCLUDING the empty case: a node that had a caret
    // run and no longer does must clear the session entry, otherwise the stale mark stays
    // in the accepted picture (the run table is the renderer's source of truth).
    var encoded = ""
    var runIndex: Int64 = 0
    while (runIndex < node.textStyleRuns.size) {
        if (runIndex > 0) {
            encoded += ";"
        }
        encoded += node.textStyleRuns[runIndex].encoded()
        runIndex += 1
    }
    status = internalRendererSetComposableTextRuns(session, UInt64(node.nodeId), encoded)
    let children = node.children()
    var index: Int64 = 0
    while (index < children.size) {
        let childStatus = internalRendererInstallComposableTextRuns(session, children[index])
        if (childStatus != CJGUI_INTERNAL_RENDERER_OK && status == CJGUI_INTERNAL_RENDERER_OK) {
            status = childStatus
        }
        index += 1
    }
    return status
}

/// Install one node's encoded presentation runs into the renderer session.
func internalRendererSetComposableTextRuns(session: UInt64, nodeId: UInt64, encoded: String): Int32 {
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let cEncoded = unsafe { LibC.mallocCString(encoded) }
    try (resource = cEncoded.asResource()) {
        unsafe {
            status = cjgui_internal_renderer_set_composable_text_runs(session, nodeId, resource.value)
        }
    }
    return status
}

/// Map a style weight onto the value the native renderer expects. The native
/// side accepts the legacy boolean (0/1) and the numeric scale, so the value is
/// passed through unchanged except for clamping.
func composableNativeFontWeight(fontWeight: Int64): UInt32 {
    if (fontWeight <= 0) {
        return 0
    }
    if (fontWeight > 1000) {
        return 1000
    }
    return UInt32(fontWeight)
}


/// Identity of a text-geometry answer: which fragment, and under which versions. Astra: geometry that
/// cannot name its identity must not be used to place a caret or a selection overlay.
public class CjguiComposableTextGeometryIdentity {
    public let fragmentNodeId: Int64
    public let contentVersion: Int64
    public let layoutVersion: Int64
    public let transformVersion: Int64

    public init(fragmentNodeId: Int64, contentVersion: Int64, layoutVersion: Int64,
        transformVersion: Int64) {
        this.fragmentNodeId = fragmentNodeId
        this.contentVersion = contentVersion
        this.layoutVersion = layoutVersion
        this.transformVersion = transformVersion
    }
}

/// One geometry answer. `reason` is a NAMED refusal (never a silent zero rect):
/// `pending`, `stale_layout`, `out_of_coverage`, `invalid_utf8_boundary`, `grapheme_boundary`,
/// `unavailable`. Coordinates, when available, are window content logical points.
public class CjguiComposableTextGeometry {
    public let available: Bool
    public let isPartial: Bool
    public let reason: String
    public let identity: CjguiComposableTextGeometryIdentity
    public let xPt: Float64
    public let yPt: Float64
    public let widthPt: Float64
    public let heightPt: Float64

    public init(available: Bool, isPartial: Bool, reason: String,
        identity: CjguiComposableTextGeometryIdentity, xPt: Float64, yPt: Float64, widthPt: Float64,
        heightPt: Float64) {
        this.available = available
        this.isPartial = isPartial
        this.reason = reason
        this.identity = identity
        this.xPt = xPt
        this.yPt = yPt
        this.widthPt = widthPt
        this.heightPt = heightPt
    }

    public static func pending(identity: CjguiComposableTextGeometryIdentity, reason: String): CjguiComposableTextGeometry {
        return CjguiComposableTextGeometry(false, false, reason, identity, 0.0, 0.0, 0.0, 0.0)
    }
}
