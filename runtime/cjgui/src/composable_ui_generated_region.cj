// One window-owned adapter between the shared generated structure holder and
// the ordinary scene/operation protocols. Applications provide only their
// catalog and live owner bindings; neither values nor business rules live here.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.sync.*
import std.time.*
import std.env.*

/// Owner-specific operations needed by a generated region. Draft and applied
/// values are read from the application, never stored in the description.
public interface CjguiGeneratedUiRegionBinding <: CjguiGeneratedUiBindingProvider {
    func ownerRevision(): Int64
    func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult
    func appliedBoolean(fieldId: String): ?Bool {
        return draftBoolean(fieldId)
    }
    /// Describes the source of DRAFT_HEX. It never implies that an uncommitted
    /// platform text-proxy buffer was read from the business owner.
    func draftSource(fieldId: String): String {
        let _ = fieldId
        return "owner_projection"
    }
    /// Select fields declared once by this binding. Handwritten controls use
    /// the same controller object, so owner writes and availability stay shared.
    func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return ArrayList<CjguiSelectFieldBinding>()
    }
}

/// A generated declaration belongs to exactly one window transaction. The
/// holder supplies candidate identity/rollback; this adapter publishes its
/// common protocol, observations and event route to any application domain.
public class CjguiGeneratedUiAcceptedDocument {
    public let text: String
    public let version: Int64
    public let digest: String

    public init(text: String, version: Int64, digest: String) {
        this.text = text
        this.version = version
        this.digest = digest
    }
}

public class CjguiGeneratedUiWindowRegion <: CjguiSharedOperationGeneratedUiProvider {
    private let documentSurfaceIdentityValue: Int64 = cjguiNextUiDocumentSurfaceIdentity()
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let binding: CjguiGeneratedUiRegionBinding
    private let rootScopeValue: CjguiComposableUiIdentityScope
    private let holder: CjguiGeneratedUiStructureHolder
    private let fieldSliders: CjguiFieldSliderAdapter
    private let compositionSelects: CjguiCompositionSelectHost
    private let tracker: CjguiGeneratedUiObservationTracker
    private let lock: Mutex
    private var attachedWindow: ?CjguiComposableUiWindow
    private var revisionValue: Int64
    private var sceneTransactionActive: Bool
    // DS51 §12 C2: the candidate token THIS scene was built against (0 when it
    // renders the accepted structure). A candidate admitted later belongs to a
    // later scene; settling it here would publish or roll back definitions the
    // accepted scene never carried.
    private var sceneCandidateToken: Int64 = 0
    private var closedSceneOutcome: String
    private var acceptedOwnerStamp: Int64
    private var hasAcceptedOwnerStamp: Bool
    private var pendingOwnerStamp: Int64
    private var fieldsSerializations: Int64
    private var structureSerializations: Int64
    private var instancesSerializations: Int64
    private var acceptedInstanceSamples: Int64
    private var candidateDecodes: Int64
    private var candidateValidations: Int64
    private var sceneBuilds: Int64
    private var sceneCommits: Int64
    private var sceneRollbacks: Int64
    private var decodeNanoseconds: Int64
    private var validationNanoseconds: Int64
    private var buildNanoseconds: Int64
    private var commitNanoseconds: Int64
    private var rollbackNanoseconds: Int64
    // R3补轮（2026-10-02）：字段编辑聚焦时绑定的通用范围会话的**完整绑定身份**
    // memo。它只描述"我们上次绑定的身份"，幂等跳过还必须同时满足窗口的**当前
    // 活动会话**就是这一节点（ownedTextSessionBoundNodeId）——其他消费方/区域
    // 的 bind 会释放本会话，关闭/重开会清空，region 记忆单独存在不代表绑定
    // 仍然活着。任一身份维度变化（node/semantic/kind/field/writer/resource/
    // ownerTarget）都视为真正换绑，重新 bindRangeTextSession（窗口自动释放旧
    // 会话并推进声明代次）。
    private var rangeSessionNodeId: Int64 = -1
    private var rangeSessionSemanticId: String = ""
    private var rangeSessionNodeKind: Int64 = -1
    private var rangeSessionFieldId: String = ""
    private var rangeSessionWriterOperation: String = ""
    private var rangeSessionFieldResource: Int64 = -1
    private var rangeSessionOwnerTarget: Int64 = -1
    private var rangeSessionInstanceKey: String = ""
    private var rangeSessionInstanceIncarnation: Int64 = 0
    private var rangeSessionOwned: ?CjguiTextSession = None
    private var rangeSessionBridge: ?CjguiGeneratedFieldRangeSession = None
    private var documentHistoryAccessValue: ?CjguiUiDocumentHistoryAccess = None

    public init(catalog: CjguiGeneratedUiCapabilityCatalog, binding: CjguiGeneratedUiRegionBinding,
                rootScopeName: String) {
        this.catalog = catalog
        this.binding = binding
        this.rootScopeValue = CjguiComposableUiIdentityScope(rootScopeName)
        this.holder = CjguiGeneratedUiStructureHolder(catalog, rootScope: this.rootScopeValue)
        this.fieldSliders = CjguiFieldSliderAdapter(binding, {id => catalog.fieldFor(id)})
        this.compositionSelects = CjguiCompositionSelectHost(this.holder)
        this.tracker = CjguiGeneratedUiObservationTracker()
        this.lock = Mutex()
        this.attachedWindow = None
        this.revisionValue = 1
        this.sceneTransactionActive = false
        this.closedSceneOutcome = ""
        this.acceptedOwnerStamp = 0
        this.hasAcceptedOwnerStamp = false
        this.pendingOwnerStamp = 0
        this.fieldsSerializations = 0
        this.structureSerializations = 0
        this.instancesSerializations = 0
        this.acceptedInstanceSamples = 0
        this.candidateDecodes = 0
        this.candidateValidations = 0
        this.sceneBuilds = 0
        this.sceneCommits = 0
        this.sceneRollbacks = 0
        this.decodeNanoseconds = 0
        this.validationNanoseconds = 0
        this.buildNanoseconds = 0
        this.commitNanoseconds = 0
        this.rollbackNanoseconds = 0
    }

    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        synchronized(lock) { attachedWindow = Some(window) }
    }

    public func revision(): Int64 {
        return synchronized(lock) { revisionValue }
    }

    public func uiDocumentSurfaceIdentity(): Int64 {
        return documentSurfaceIdentityValue
    }

    public func acceptedNodeIdForKey(key: String): Int64 {
        return synchronized(lock) { holder.nodeIdForKey(key) }
    }

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) {
            if (sceneTransactionActive) { return false }
            closedSceneOutcome = ""
            sceneTransactionActive = true
            sceneCandidateToken = holder.pendingCandidateToken()
            holder.beginStyleRefresh()
            if (!holder.beginCandidateRefresh()) {
                holder.rollbackCandidateRefresh()
                sceneTransactionActive = false
                revisionValue += 1
                return false
            }
            holder.beginHandwrittenInstanceAliasRefresh()
            return true
        }
    }

    public func buildNode(feedback!: ?CjguiGeneratedUiFormFeedback = None): CjguiComposableUiNode {
        return synchronized(lock) {
            sceneBuilds += 1
            let frozenFeedback = if (feedback.isSome()) { feedback } else { binding.formFeedback() }
            pendingOwnerStamp = feedbackRevision(frozenFeedback)
            match (attachedWindow) {
                case Some(window) => holder.sampleImageResourceStates(window)
                case None => ()
            }
            let started = MonoTime.now()
            let node = holder.buildRefreshNode(binding, feedback: frozenFeedback)
            buildNanoseconds += (MonoTime.now() - started).toNanoseconds()
            node
        }
    }

    /// Wrap the generated root with any open Select popup AFTER the rest of the
    /// scene exists. The popup is a layer host, never a clipped form child.
    public func attachTransientLayers(root: CjguiComposableUiNode): CjguiComposableUiNode {
        var scene = root
        for (declaredSelect in binding.generatedSelectBindings()) {
            if (declaredSelect.select.isOpen() && declaredSelect.select.presentedIn(root)) {
                scene = declaredSelect.select.attachTo(scene)
            }
        }
        return compositionSelects.attach(scene)
    }

    /// Commands of every OPEN Select this region owns. Handwritten declared
    /// selects and runtime-composition instance popups publish through the
    /// same candidate-scene command list, so arrows/Enter/Esc reach the
    /// component that owns the popup and confirm through its owner writer.
    public func generatedSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return synchronized(lock) {
            let result = ArrayList<CjguiComposableUiCommand>()
            for (declaredSelect in binding.generatedSelectBindings()) {
                if (!declaredSelect.select.isOpen()) { continue }
                for (command in declaredSelect.select.commands()) { result.add(command) }
            }
            for (command in compositionSelects.commands()) { result.add(command) }
            result
        }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) {
            if (!holder.prepareCandidateRefresh()) { return false }
            if (let Some(window) <- attachedWindow) {
                if (ownsCurrentRangeSession(window) && preparedRangeBindingChanged()) {
                    // Freeze/retain unfinished input under the OLD accepted
                    // owner. This does not release the session or publish any
                    // alias, and a refusal rejects the original scene.
                    return window.prepareTextSessionUnbind()
                }
            }
            return true
        }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            // Only the currently open scene owns a terminal hook. A late
            // duplicate must not settle a subsequently admitted declaration.
            if (!sceneTransactionActive) { return }
            sceneCommits += 1
            acceptedOwnerStamp = pendingOwnerStamp
            hasAcceptedOwnerStamp = true
            let sceneToken = sceneCandidateToken
            sceneCandidateToken = 0
            let superseded = sceneToken > 0 && holder.pendingCandidateToken() != sceneToken
            let hadCandidate = sceneToken > 0 && !superseded
            let started = MonoTime.now()
            // The native scene is accepted now. Only a session this region
            // actually installed may be retired; another region may own the
            // same numeric node. Old input is settled before alias publication.
            let rebindAcceptedFocus = retireRangeSessionForAcceptedScene()
            if (hadCandidate) {
                let committed = holder.commitCandidateRefresh()
                if (committed) {
                    // Definitions and instances became visible in the SAME
                    // accepted scene; only now may the catalog change.
                    catalog.commitStagedComposites()
                } else {
                    // The candidate this scene carried could not be published:
                    // settle it as rejected so it cannot poison a later build
                    // with a definition floor this commit just dropped.
                    holder.rollbackCandidateRefresh(holder.lastSceneOutcome())
                    catalog.rollbackStagedComposites()
                }
                // Build sampled the previous accepted bindings. A prepared
                // image may already be ready when this candidate is accepted,
                // with no later completion epoch to refresh its public state.
                match (attachedWindow) {
                    case Some(window) => holder.sampleImageResourceStates(window)
                    case None => ()
                }
            } else {
                // An ordinary scene (or one superseded before it built) must
                // NOT touch the definition overlay: it may belong to a candidate
                // admitted after this scene began.
                holder.commitStyleRefresh()
            }
            // A style-only refresh builds the ACCEPTED structure as its scene:
            // the mounts that render prepared become accepted only now. With a
            // candidate, the candidate commit already published its own mounts
            // and any accepted-render staging is superseded.
            if (hadCandidate) {
                holder.discardSceneViewState()
            } else {
                holder.settleAcceptedRenderViewState()
            }
            let acceptedNodes: ?ArrayList<CjguiComposableUiLayoutNode> = match (attachedWindow) {
                case Some(window) => Some(window.acceptedSceneNodes())
                case None => None
            }
            holder.commitHandwrittenInstanceAliasRefresh(acceptedNodes: acceptedNodes)
            // Only now is the accepted element table the new authority. A
            // popup whose instance was removed/rebound/disabled is closed here,
            // before another event can reach its stale rows.
            compositionSelects.reconcile()
            if (rebindAcceptedFocus) { bindAcceptedFocusedRangeSession() }
            commitNanoseconds += (MonoTime.now() - started).toNanoseconds()
            sceneTransactionActive = false
            if (hadCandidate) { revisionValue += 1 }
        }
    }

    public func rollbackSceneRefresh(): Unit {
        rollbackSceneRefresh("")
    }

    public func rollbackSceneRefresh(reason: String): Unit {
        synchronized(lock) {
            // Only the currently open scene owns a terminal hook. A late
            // duplicate must not settle a subsequently admitted declaration.
            if (!sceneTransactionActive) { return }
            sceneRollbacks += 1
            let sceneToken = sceneCandidateToken
            sceneCandidateToken = 0
            let superseded = sceneToken > 0 && holder.pendingCandidateToken() != sceneToken
            let hadCandidate = sceneToken > 0 && !superseded
            let started = MonoTime.now()
            if (hadCandidate) {
                holder.rollbackCandidateRefresh(reason)
                // A rejected candidate never leaves ITS definitions installed.
                // A transport supersession keeps the candidate pending: the
                // staged overlay belongs to the still-pending candidate and
                // must survive for the re-carrying scene transaction.
                if (!(holder.hasPendingCandidate() && holder.pendingCandidateToken() == sceneToken)) {
                    catalog.rollbackStagedComposites()
                }
            } else {
                holder.rollbackStyleRefresh()
            }
            // No transaction this scene opened may survive the rejection: the
            // candidate's and the accepted fallback render's staged mounts are
            // dropped with it, so the accepted interface keeps its own facts.
            holder.discardSceneViewState()
            holder.rollbackHandwrittenInstanceAliasRefresh()
            rollbackNanoseconds += (MonoTime.now() - started).toNanoseconds()
            sceneTransactionActive = false
            if (hadCandidate) { revisionValue += 1 }
        }
    }

    /// The pre-Surface owner may stop before a scene transaction ever starts.
    /// It must settle that exact ticket while the endpoint still exists.
    public func rejectPendingOnClose(): Unit {
        synchronized(lock) {
            if (!holder.hasPendingCandidate()) { return }
            holder.rejectCandidateAttempt(holder.pendingCandidateToken(), "window_closed", "")
            holder.rollbackCandidateRefresh()
            holder.discardSceneViewState()
            catalog.rollbackStagedComposites()
            closedSceneOutcome = "scene_rejected:window_closed"
            sceneTransactionActive = false
            revisionValue += 1
        }
    }

    public func disposeSceneRefreshResources(): Unit {
        synchronized(lock) {
            compositionSelects.closeAll()
            catalog.rollbackStagedComposites()
            holder.discardSceneViewState()
            holder.rollbackHandwrittenInstanceAliasRefresh()
            holder.disposeViewState()
            holder.releaseAcceptedImageIdentities()
        }
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return handleEventIfClaimed(event).getOrDefault({ => CjguiComposableUiDispatchResult(false) })
    }

    /// None means this region does not own the event. Some(false) preserves an
    /// owned observation, no change or refusal; a caller must not retry it via
    /// another writer. The legacy handleEvent keeps its didApply contract.
    public func handleEventIfClaimed(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        // An open instance popup owns its trigger/query/rows/outside guard. Its
        // action family is instance-qualified, so a sibling card's popup can
        // never claim these events.
        if (let Some(result) <- compositionSelects.handleEvent(event, binding)) {
            revisionValue += 1
            return Some(result)
        }
        for (declaredSelect in binding.generatedSelectBindings()) {
            if (let Some(result) <- declaredSelect.select.applyUiEvent(event)) {
                var didApply = result.didApply
                if (let Some(option) <- declaredSelect.takeConfirmed()) {
                    didApply = declaredSelect.commit(option)
                    if (!didApply) {
                        getStdOut().writeln("CJGUI_GENERATED_SELECT phase=refused field=${declaredSelect.fieldId} reason=${declaredSelect.lastFailure()}")
                    }
                    revisionValue += 1
                }
                return Some(CjguiComposableUiDispatchResult(didApply))
            }
        }
        if (event.node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) {
            let current = synchronized(lock) { holder.matchesFieldSlider(event.node) }
            return if (current) { Some(fieldSliders.handle(event)) } else { None }
        }
        synchronized(lock) {
            bindFieldRangeSessionIfFocused(event)
        }
        let intent = synchronized(lock) { holder.resolveIntent(event.node, event.eventKind, event.text) }
        if (intent.isFieldEdit()) {
            let observation = synchronized(lock) { wholeTextIsOwnedObservation(event, intent) }
            if (observation) {
                if (getVariable("CJGUI_RANGE_ROUTE_TRACE").isSome()) {
                    println("CJGUI_GEN_RANGE_OBSERVE event=28 node=${event.node.nodeId} field=${intent.fieldId} owner_version=${binding.ownerRevision()}")
                }
                return Some(CjguiComposableUiDispatchResult(false))
            }
            return Some(binding.applyFieldIntent(intent))
        }
        if (intent.isAction()) {
            // Resolution and execution are separate steps: the owner mapping
            // can change in between. The holder's shared dispatch route
            // re-checks the SAME accepted element and hands the ORIGINAL
            // target and generation to the owner transaction; it never
            // re-resolves the key here. Execution stays outside this region's
            // lock, exactly as before: the provider takes its own owner locks.
            return Some(holder.dispatchActionIntent(intent, binding))
        }
        // Even a metadata mismatch or unsupported event on an accepted target
        // belongs to this route. Lookup uses accepted tables, never staging or
        // an application's current selection.
        let claimed = synchronized(lock) {
            holder.keyForNodeId(event.node.nodeId).size > 0 ||
                holder.compositeInstanceKeyForNodeId(event.node.nodeId).size > 0
        }
        return if (claimed) { Some(CjguiComposableUiDispatchResult(false)) } else { None }
    }

    /// Manual and generated INTEGER sliders use this same field writer.
    public func handleFieldSliderEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return fieldSliders.handle(event)
    }
    public func sliderCaptureVersion(): Int64 { return fieldSliders.version() }
    public func sliderCaptureMapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping {
        return fieldSliders.mapping(node)
    }

    // Native can report a whole-value projection beside the original range
    // delta. Only the current, fully matching owned TEXT binding observes it;
    // the range channel remains the one owner submission/receipt source.
    private func wholeTextIsOwnedObservation(event: CjguiComposableUiEvent,
        intent: CjguiGeneratedUiIntent): Bool {
        let node = event.node
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED ||
            node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT_INPUT || node.fieldId != intent.fieldId ||
            node.resourceId != binding.fieldResourceId(intent.fieldId) ||
            node.operationResourceId != binding.fieldOperationResourceId(intent.fieldId, intent.instanceKey) ||
            node.operationResourceId != intent.ownerTargetResourceId ||
            node.operationActionName != intent.writerOperation ||
            !binding.rangeTextEditSupported(intent.fieldId, intent.instanceKey)) {
            return false
        }
        let window = match (attachedWindow) { case Some(value) => value; case None => return false }
        if (!window.isTextRangeEditDeltaDeliveryEnabled() || window.ownedTextSessionBoundNodeId() != node.nodeId ||
            rangeSessionNodeId != node.nodeId || rangeSessionSemanticId != node.semanticId ||
            rangeSessionNodeKind != node.nodeKind || rangeSessionFieldId != intent.fieldId ||
            rangeSessionWriterOperation != intent.writerOperation || rangeSessionFieldResource != node.resourceId ||
            rangeSessionOwnerTarget != node.operationResourceId ||
            rangeSessionInstanceKey != intent.instanceKey) { return false }
        for (accepted in window.acceptedSceneNodes()) {
            if (accepted.nodeId == node.nodeId) {
                return accepted.semanticId == node.semanticId && accepted.semanticIncarnation == node.semanticIncarnation &&
                    accepted.nodeKind == node.nodeKind && accepted.resourceId == node.resourceId &&
                    accepted.fieldId == node.fieldId && accepted.operationResourceId == node.operationResourceId &&
                    accepted.operationActionName == node.operationActionName
            }
        }
        return false
    }

    /// R3/R3补轮：生成 TEXT 字段在**编辑聚焦**（kind 31 FOCUS）时绑定通用范围
    /// 会话（CjguiGeneratedFieldRangeSession）。绑定后该节点的系统输入以精确
    /// 范围增量（kind 51）经会话镜像到达 provider 的 owner 事务文本写。程序化
    /// 聚焦（窗口 recordProjectedFocus 合成通知）与平台 FOCUS 事件共用本入口。
    /// 判定顺序（R3补轮反例驱动）：
    ///   1. 字段声明与事件节点的绑定事实一致（同 resolveIntent ordinary 校验）；
    ///   2. **先验证当前 accepted 目标**：accepted 场景里该 nodeId 的完整身份
    ///      （semantic/kind/resource/field/writer/ownerTarget）必须与事件节点
    ///      一致——迟到旧 FOCUS（节点已换绑/移除/换语义）在此具名拒绝，不得
    ///      夺回新 owner；
    ///   3. 幂等 = 窗口**当前活动会话**绑定本节点 **且** region memo 的完整
    ///      绑定身份逐一相等。只满足后者不跳过：其他消费方 bind/关闭重开已把
    ///      会话换走（A→B→A 反例）；只满足前者不跳过：同 node 换 semantic/
    ///      换绑是真正新绑定（semantic_rebind 反例）。真重复聚焦不重建会话，
    ///      组合态与选区保留。
    private func ownsCurrentRangeSession(window: CjguiComposableUiWindow): Bool {
        let expected = match (rangeSessionOwned) { case Some(value) => value; case None => return false }
        let current = match (window.textSession()) { case Some(value) => value; case None => return false }
        return refEq(expected, current)
    }

    private func preparedRangeBindingChanged(): Bool {
        let key = holder.compositeInstanceKeyForPreparedNodeId(rangeSessionNodeId)
        return key != rangeSessionInstanceKey ||
            holder.compositeInstanceIncarnationForPreparedNodeId(rangeSessionNodeId) !=
                rangeSessionInstanceIncarnation ||
            binding.fieldOperationResourceId(rangeSessionFieldId, key) != rangeSessionOwnerTarget
    }

    private func rangeSessionMatchesNode(node: CjguiComposableUiLayoutNode): Bool {
        return node.nodeId == rangeSessionNodeId && node.semanticId == rangeSessionSemanticId &&
            node.nodeKind == rangeSessionNodeKind && node.fieldId == rangeSessionFieldId &&
            node.operationActionName == rangeSessionWriterOperation &&
            node.resourceId == rangeSessionFieldResource && node.operationResourceId == rangeSessionOwnerTarget
    }

    private func retireRangeSessionForAcceptedScene(): Bool {
        let window = match (attachedWindow) { case Some(value) => value; case None => return false }
        if (!ownsCurrentRangeSession(window)) { return false }
        var unchanged = false
        if (!preparedRangeBindingChanged()) {
            for (node in window.acceptedSceneNodes()) {
                if (rangeSessionMatchesNode(node)) { unchanged = true; break }
            }
        }
        if (unchanged) { return false }
        window.releaseTextSession()
        // Release can retain its original carrier when an input/recovery
        // receipt is unfinished. Retire the adapter in either case: keeping
        // that carrier cannot write through a newly accepted owner binding.
        if (let Some(bridge) <- rangeSessionBridge) { bridge.retireAcceptedBinding() }
        if (ownsCurrentRangeSession(window)) {
            generatedRegionDiagLog("GEN_RANGE_RETIRE_PENDING node=${rangeSessionNodeId} reason=input_unsettled")
            return false
        }
        rangeSessionOwned = None
        rangeSessionBridge = None
        return true
    }

    private func bindAcceptedFocusedRangeSession(): Unit {
        let window = match (attachedWindow) { case Some(value) => value; case None => return }
        let focus = window.windowProgress()
        if (focus.focusState != CJGUI_WINDOW_FOCUS_STATE_VALID) { return }
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == focus.focusedControlId) {
                bindAcceptedFieldRangeSession(node)
                return
            }
        }
    }

    private func bindFieldRangeSessionIfFocused(event: CjguiComposableUiEvent): Unit {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_FOCUS) {
            return
        }
        bindAcceptedFieldRangeSession(event.node)
    }

    private func bindAcceptedFieldRangeSession(node: CjguiComposableUiLayoutNode): Unit {
        if (node.fieldId.size == 0) {
            generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} reason=no_field_id")
            return
        }
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return
        }
        // Whole-value windows keep their original form writer. Declaring an
        // owned range session here would make that writer suppress the only
        // text event even though this window cannot deliver range deltas.
        if (!window.isTextRangeEditDeltaDeliveryEnabled()) { return }
        if (catalog.fieldFor(node.fieldId).isNone()) {
            generatedRegionDiagLog(
                "GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} reason=unknown_field")
            return
        }
        let field = match (catalog.fieldFor(node.fieldId)) {
            case Some(value) => value
            case None => return
        }
        if (field.editorKind != "TEXT" || field.writeActionName.size == 0 ||
            node.operationActionName != field.writeActionName ||
            node.resourceId != field.resourceId || node.operationResourceId < 0) {
            generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "reason=binding_mismatch editor=${field.editorKind} writer=${field.writeActionName} " +
                "nodeWriter=${node.operationActionName} fieldRes=${field.resourceId} nodeRes=${node.resourceId} " +
                "ownerTarget=${node.operationResourceId}")
            return
        }
        let instanceKey = holder.compositeInstanceKeyForNodeId(node.nodeId)
        if (!binding.rangeTextEditSupported(field.fieldId, instanceKey)) {
            generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${field.fieldId} " +
                "instance=${instanceKey} reason=provider_unsupported")
            return
        }
        // The provider that WILL own the session must be the owner the accepted
        // node froze: a handwritten node outside the generated holder resolves
        // to the DEFAULT instance, whose provider may serve a different owner
        // (mixed: root 6200 fallback vs the selected card's 6301 on the same
        // fieldId). Binding anyway installs a session whose every delta is then
        // rejected as owner_target_retired AND suppresses the node's ordinary
        // whole-value writer, so a legal editor goes dead. Mismatch never
        // builds an owned session here; the node keeps its declared writer and
        // the correct provider is wired by the consumer's own alias (see the
        // selected-card detail in the mixed consumer). A legal EMPTY instance
        // key still binds exactly as before when the owners agree.
        let providerOwner = binding.fieldOperationResourceId(field.fieldId, instanceKey)
        if (providerOwner != node.operationResourceId) {
            generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${field.fieldId} " +
                "instance=${instanceKey} reason=provider_owner_mismatch " +
                "providerOwner=${providerOwner} nodeOwner=${node.operationResourceId}")
            return
        }
        var acceptedMatched = false
        for (accepted in window.acceptedSceneNodes()) {
            if (accepted.nodeId != node.nodeId) {
                continue
            }
            acceptedMatched = accepted.semanticId == node.semanticId &&
                accepted.nodeKind == node.nodeKind && accepted.resourceId == node.resourceId &&
                accepted.fieldId == node.fieldId &&
                accepted.operationActionName == node.operationActionName &&
                accepted.operationResourceId == node.operationResourceId
            break
        }
        if (!acceptedMatched) {
            generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "semantic=${node.semanticId} reason=stale_focus_not_accepted")
            return
        }
        if (ownsCurrentRangeSession(window) && window.ownedTextSessionBoundNodeId() == node.nodeId &&
            rangeSessionNodeId == node.nodeId && rangeSessionSemanticId == node.semanticId &&
            rangeSessionNodeKind == node.nodeKind && rangeSessionFieldId == field.fieldId &&
            rangeSessionWriterOperation == field.writeActionName &&
            rangeSessionFieldResource == field.resourceId &&
            rangeSessionOwnerTarget == node.operationResourceId &&
            rangeSessionInstanceKey == instanceKey &&
            rangeSessionInstanceIncarnation == holder.compositeInstanceIncarnationForNodeId(node.nodeId)) {
            return // 同一绑定的重复聚焦：不重建会话，组合态/选区保留
        }
        let acceptedIncarnation = holder.compositeInstanceIncarnationForNodeId(node.nodeId)
        let bindingCurrent = { =>
            holder.compositeInstanceIncarnationForNodeId(node.nodeId) == acceptedIncarnation &&
                holder.compositeInstanceKeyForNodeId(node.nodeId) == instanceKey
        }
        let session = CjguiGeneratedFieldRangeSession(binding, field.fieldId, instanceKey: instanceKey,
            ownerTarget: node.operationResourceId, bindingCurrent: bindingCurrent)
        let previous = window.textSession()
        let installed = window.bindRangeTextSession(node.nodeId, node.semanticId, session, session,
            field.resourceId, node.nodeKind)
        if (let Some(old) <- previous) {
            if (refEq(old, installed)) {
                generatedRegionDiagLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} reason=previous_input_unsettled")
                return
            }
        }
        rangeSessionOwned = Some(installed)
        rangeSessionBridge = Some(session)
        rangeSessionNodeId = node.nodeId
        rangeSessionSemanticId = node.semanticId
        rangeSessionNodeKind = node.nodeKind
        rangeSessionFieldId = field.fieldId
        rangeSessionWriterOperation = field.writeActionName
        rangeSessionFieldResource = field.resourceId
        rangeSessionOwnerTarget = node.operationResourceId
        rangeSessionInstanceKey = instanceKey
        rangeSessionInstanceIncarnation = acceptedIncarnation
    }
    private func documentHistoryAccess(): CjguiUiDocumentHistoryAccess {
        return synchronized(lock) {
            if (let Some(value) <- documentHistoryAccessValue) { return value }
            let value = CjguiUiDocumentHistoryAccess(this)
            documentHistoryAccessValue = Some(value)
            value
        }
    }
    public func capabilitiesPayload(): String {
        return CjguiUiDocumentHistoryAccess.capabilitiesPayload(CjguiGeneratedUiEncoding.describe(catalog))
    }
    public func attachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): String {
        return documentHistoryAccess().attach(workspace)
    }
    public func detachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): Unit {
        let access = synchronized(lock) { documentHistoryAccessValue }
        if (let Some(value) <- access) { value.detach(workspace) }
    }
    public func uiDocumentHistoryPayload(): String { return documentHistoryAccess().payload() }
    public func submitUiDocumentHistory(action: String, expectedVersion: Int64, expectedDigest: String,
        surfaceIdentity: Int64, historyEpoch: Int64): CjguiSharedOperationGeneratedUiSubmit {
        return documentHistoryAccess().submit(action, expectedVersion, expectedDigest, surfaceIdentity, historyEpoch)
    }

    private func hexValue(value: String): String {
        return if (value.isEmpty()) { "-" } else { CjguiSharedOperationFrame.encodeUtf8Hex(value) }
    }

    /// Declares the DECLARED instance key one of the consumer's HANDWRITTEN
    /// field editors belongs to (outside any accepted composite). The consumer
    /// refreshes this mapping with its own selection. During a scene build it
    /// changes staging only; acceptance/rollback settle it with that scene.
    /// The range-session entry
    /// still verifies the resolved provider's actual owner against the node's
    /// frozen operationResourceId before building an owned session.
    public func declareHandwrittenInstanceAlias(nodeId: Int64, instanceKey: String): Unit {
        synchronized(lock) { holder.declareHandwrittenInstanceAlias(nodeId, instanceKey) }
    }

    /// Drops every handwritten alias in one call (selection change).
    public func clearHandwrittenInstanceAliases(): Unit {
        synchronized(lock) { holder.clearHandwrittenInstanceAliases() }
    }

    private func acceptedInstances(): ArrayList<CjguiGeneratedUiAcceptedInstance> {
        return match (attachedWindow) {
            case Some(window) =>
                acceptedInstanceSamples += 1
                cjguiGeneratedUiAcceptedInstances(window, holder)
            case None => ArrayList<CjguiGeneratedUiAcceptedInstance>()
        }
    }

    private func focusToken(fieldId: String, instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): String {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return "FOCUS unknown"
        }
        let progress = window.windowProgress()
        if (progress.focusState == CJGUI_WINDOW_FOCUS_STATE_UNKNOWN) { return "FOCUS unknown" }
        if (progress.focusState == CJGUI_WINDOW_FOCUS_STATE_VALID) {
            for (instance in instances) {
                if (instance.semanticId == progress.focusedControlId && instance.fieldId == fieldId) {
                    if (progress.hasTextSelection) {
                        return "FOCUS 1 SELECTION ${progress.selectionStart} ${progress.selectionEnd}"
                    }
                    return "FOCUS 1 SELECTION 0 0"
                }
            }
        }
        return "FOCUS 0 SELECTION 0 0"
    }

    private func feedbackRevision(feedback: ?CjguiGeneratedUiFormFeedback): Int64 {
        return match (feedback) {
            case Some(value) => value.snapshot.contextVersion
            case None => binding.ownerRevision()
        }
    }
    private func availabilityPayload(value: CjguiSharedAvailability): String {
        let available = if (!value.known) { "unknown" } else if (value.isAvailable) { "1" } else { "0" }
        let reason = if (value.known && !value.isAvailable) { hexValue(value.reason) } else { "-" }
        return "AVAILABLE ${available} REASON_HEX ${reason} TARGET ${value.ownerResourceId} STATE_VERSION ${value.stateVersion}"
    }
    private func fieldsPayloadUnlocked(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>,
        feedback: ?CjguiGeneratedUiFormFeedback, version: Int64): String {
        fieldsSerializations += 1
        let builder = StringBuilder()
        let header = match (feedback) {
            case Some(value) =>
                let snapshot = value.snapshot
                "FORM_STATE KNOWN 1 CONSISTENT 1 VERSION ${version} DRAFT_VERSION ${snapshot.draftVersion} " +
                    "APPLIED_VERSION ${snapshot.appliedConfigVersion} CAN_APPLY ${if (snapshot.canApply) { "1" } else { "0" }} " +
                    "MESSAGE_HEX ${hexValue(snapshot.statusMessage)} TARGET ${value.ownerResourceId}"
            case None => "FORM_STATE KNOWN 0 CONSISTENT 1 VERSION ${version} DRAFT_VERSION -1 APPLIED_VERSION -1 CAN_APPLY unknown MESSAGE_HEX - TARGET -1"
        }
        builder.append(header + "\n")
        for (spec in catalog.fieldSpecs()) {
            var draft = ""
            var applied = ""
            var validation = "unknown"
            var message = ""
            var validationVersion: Int64 = -1
            var fieldVersion: Int64 = -1
            var draftVersion = version
            var availability = CjguiSharedAvailability.unknown()
            if (let Some(value) <- feedback) {
                if (let Some(field) <- value.fieldFor(spec.fieldId)) {
                    if (field.resourceId == spec.resourceId) {
                        draft = field.draftText
                        applied = field.appliedValue.displayText()
                        validation = if (field.validationError.isEmpty()) { "valid" } else { "invalid" }
                        message = field.validationError
                        validationVersion = value.snapshot.contextVersion
                        fieldVersion = field.draftFieldVersion
                        draftVersion = value.snapshot.draftVersion
                        availability = value.fieldAvailability(spec.fieldId)
                    }
                }
            } else {
                draft = if (spec.editorKind == "BOOLEAN") {
                    CjguiSharedOperationValue.boolean(binding.draftBoolean(spec.fieldId) ?? false).displayText()
                } else { binding.draftText(spec.fieldId) }
                applied = if (spec.editorKind == "BOOLEAN") {
                    CjguiSharedOperationValue.boolean(binding.appliedBoolean(spec.fieldId) ?? false).displayText()
                } else { binding.appliedText(spec.fieldId) }
                availability = binding.fieldAvailability(spec.fieldId)
            }
            let legacyError = if (validation == "valid") { "none" } else { validation }
            let source = if (feedback.isSome()) { "owner_projection" } else { binding.draftSource(spec.fieldId) }
            builder.append("FIELD ${spec.fieldId} ${spec.resourceId} DRAFT_HEX ${hexValue(draft)} " +
                "APPLIED_HEX ${hexValue(applied)} ERROR ${legacyError} ${focusToken(spec.fieldId, instances)} " +
                availabilityPayload(availability) + " DRAFT_SOURCE ${source} VERSION ${draftVersion} " +
                "VALIDATION_STATE ${validation} VALIDATION_MESSAGE_HEX ${hexValue(message)} " +
                "VALIDATION_VERSION ${validationVersion} FIELD_VERSION ${fieldVersion}\n")
        }
        for (name in catalog.actionNames()) {
            let state = match (feedback) {
                case Some(value) => value.actionAvailability(name)
                case None => binding.actionAvailability(name)
            }
            builder.append("ACTION_STATE ${name} " + availabilityPayload(state) + "\n")
        }
        // Legacy providers retain their read path, but a moving owner cannot
        // publish a mixture as one state. No retries, guessed values or ticket.
        if (feedback.isNone() && binding.ownerRevision() != version) {
            return "FORM_STATE KNOWN 0 CONSISTENT 0 VERSION ${version} DRAFT_VERSION -1 APPLIED_VERSION -1 CAN_APPLY unknown MESSAGE_HEX - TARGET -1\nEND"
        }
        builder.append("END")
        return builder.toString()
    }

    public func fieldsPayload(): String {
        return synchronized(lock) {
            let feedback = binding.formFeedback()
            fieldsPayloadUnlocked(acceptedInstances(), feedback, feedbackRevision(feedback))
        }
    }

    /// ONE instance's complete owner projection (draft/applied, validation,
    /// dirty/canApply and action conditions) sampled from its own snapshot.
    /// Empty means the provider does not publish per-instance feedback; the
    /// transport turns that into a named refusal instead of a guessed state.
    public func fieldsPayload(instanceKey: String): String {
        return synchronized(lock) {
            if (!holder.isAcceptedCompositeInstanceKey(instanceKey)) {
                return ""
            }
            let feedback = match (binding.formFeedback(instanceKey)) {
                case Some(value) => value
                case None => return ""
            }
            // The accepted owner target and the returned projection must name
            // the SAME object; a provider that drifted is unknown, not a
            // projection silently attributed to another owner.
            let acceptedOwner = holder.compositeOwnerTargetForInstance(instanceKey)
            if (acceptedOwner >= 0 && feedback.ownerResourceId != acceptedOwner) {
                return ""
            }
            fieldsPayloadUnlocked(acceptedInstances(), feedback, feedbackRevision(feedback))
        }
    }

    /// The same projection addressed by business owner id. The accepted
    /// composite binding table is the only authority; an owner no accepted
    /// instance binds is unknown, never redirected to a live sibling. An owner
    /// bound by more than one instance is ambiguous and also stays unknown.
    public func fieldsPayloadForOwner(ownerResourceId: Int64): String {
        return synchronized(lock) {
            let instances = acceptedInstances()
            let key = holder.compositeInstanceKeyForOwnerTarget(ownerResourceId)
            if (!key.isEmpty()) {
                if (let Some(feedback) <- binding.formFeedback(key)) {
                    if (feedback.ownerResourceId == ownerResourceId) {
                        return fieldsPayloadUnlocked(instances, feedback, feedbackRevision(feedback))
                    }
                }
            }
            if (let Some(feedback) <- binding.formFeedback()) {
                if (feedback.ownerResourceId == ownerResourceId && !holder.hasAcceptedCompositeBindings()) {
                    return fieldsPayloadUnlocked(instances, feedback, feedbackRevision(feedback))
                }
            }
            return ""
        }
    }

    public func instanceOwnerResourceId(instanceKey: String): Int64 {
        return synchronized(lock) { holder.compositeOwnerTargetForInstance(instanceKey) }
    }

    private func structurePayloadUnlocked(): String {
        structureSerializations += 1
        // Definitions and nodes are read under the SAME lock and the SAME
        // structure version: a reader can prove what the accepted instances
        // were expanded from instead of trusting a local submission copy.
        return CjguiGeneratedUiEncoding.encode(holder.acceptedStructure(), holder.structureVersion(),
            definitions: catalog.acceptedCompositionPayload())
    }

    /// The accepted collection mount of THIS region/holder for one declared
    /// instance key. The scope-only collection query refuses ambiguity across
    /// holders; the region always answers for its own holder.
    public func acceptedCollectionView(collection: CjguiGeneratedUiCollection,
        instanceKey: String): ?CjguiGeneratedCollectionView {
        return synchronized(lock) {
            collection.acceptedView(rootScopeValue, instanceKey, holder.holderIdentity())
        }
    }

    /// Resolve the accepted collection mount a key/focus event belongs to from
    /// the EXACT viewport object the event carries. A stale generation or a
    /// foreign viewport resolves to None; the caller then leaves the event
    /// unhandled instead of moving some other mount.
    public func acceptedCollectionViewForEvent(collection: CjguiGeneratedUiCollection,
        event: CjguiComposableUiEvent): ?CjguiGeneratedCollectionView {
        return synchronized(lock) {
            let viewport = match (event.node.scrollViewport) {
                case Some(value) => value
                case None => return None
            }
            for (instance in acceptedInstances()) {
                if (instance.kindToken != collection.kind) { continue }
                if (let Some(view) <- collection.acceptedView(rootScopeValue,
                    instance.key, holder.holderIdentity())) {
                    if (!view.isRetired() && refEq(view.viewport, viewport)) {
                        return Some(view)
                    }
                }
            }
            return None
        }
    }

    public func acceptedStructurePayload(): String {
        return synchronized(lock) { structurePayloadUnlocked() }
    }

    private func acceptedUiDocumentUnlocked(): CjguiGeneratedUiAcceptedDocument {
        let definitions = catalog.acceptedCompositionPayload()
        let formatVersion = if (definitions.size > 0) { 2 } else { 1 }
        let text = CjguiGeneratedUiEncoding.encodeCandidate(holder.acceptedStructure(),
            formatVersion, definitions: definitions)
        return CjguiGeneratedUiAcceptedDocument(text, holder.structureVersion(),
            cjguiUiDocumentDigest(text))
    }

    /// ONE consistent accepted document fact: the portable structure text (the
    /// exact bytes a `cjgui.ui-document` embeds), its accepted version and its
    /// structure digest, all read under the same lock.
    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        return synchronized(lock) { acceptedUiDocumentUnlocked() }
    }

    /// One document ticket AND the accepted document it was compared against,
    /// read under the region's one lock. The session never turns a digest match
    /// into an acceptance claim: only the holder's terminal record settles it.
    public func uiDocumentTicketSnapshot(token: Int64): CjguiUiDocumentTicket {
        return synchronized(lock) {
            let accepted = acceptedUiDocumentUnlocked()
            let record = match (holder.candidateRecord(token)) {
                case Some(value) => value
                case None => return CjguiUiDocumentTicket(token, false, "UNKNOWN",
                    "none", "", 0, accepted.version, accepted.digest)
            }
            return CjguiUiDocumentTicket(token, true, record.terminalState(),
                if (record.sceneState().size > 0) { record.sceneState() } else { "none" },
                record.reason(), record.acceptedVersion(), accepted.version, accepted.digest)
        }
    }

    public func acceptedStructureVersion(): Int64 {
        return synchronized(lock) { holder.structureVersion() }
    }

    /// True when no scene transaction spans the current turn. A startup
    /// document is submitted only at such an idle boundary; submitting inside
    /// an in-flight transaction is refused as busy rather than queued.
    public func sceneTransactionIdle(): Bool {
        return synchronized(lock) { !sceneTransactionActive }
    }

    public func candidateStructureVersion(): Int64 {
        return synchronized(lock) { holder.candidateStructureVersion() }
    }

    public func sceneState(): String {
        return synchronized(lock) { sceneOutcomeUnlocked() }
    }

    private func sceneOutcomeUnlocked(): String {
        return if (closedSceneOutcome.isEmpty()) { holder.lastSceneOutcome() } else { closedSceneOutcome }
    }

    public func candidateTicketPayload(token: Int64): String {
        return synchronized(lock) { holder.candidateTicketPayload(token) }
    }

    /// Bounded diagnostic for the DS seam: the ticket of the pending candidate,
    /// or of the most recent attempt when none is pending. It names the REAL
    /// rejection reason/path instead of the window's generic internal_error, and
    /// never publishes or mutates candidate state.
    public func candidateTicketForDiagnosis(): String {
        return synchronized(lock) {
            let token = if (holder.pendingCandidateToken() > 0) {
                holder.pendingCandidateToken()
            } else {
                holder.latestCandidateToken()
            }
            holder.candidateTicketPayload(token)
        }
    }

    private func instancesPayloadUnlocked(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): String {
        instancesSerializations += 1
        return CjguiGeneratedUiEncoding.acceptedInstancesPayload(instances)
    }

    public func acceptedInstancesPayload(): String {
        return synchronized(lock) { instancesPayloadUnlocked(acceptedInstances()) }
    }

    private func rejectedSubmit(token: Int64, current: Int64,
        reason: String): CjguiSharedOperationGeneratedUiSubmit {
        return CjguiSharedOperationGeneratedUiSubmit(false, reason, "", current, current,
            candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
    }

    public func submitStructure(candidatePayload: String, expectedVersion: Int64): CjguiSharedOperationGeneratedUiSubmit {
        // Allocate before every possible failure so a rejected call also has
        // its own endpoint-scoped ticket and cannot be confused with another.
        let token = synchronized(lock) {
            closedSceneOutcome = ""
            holder.allocateCandidateAttempt()
        }
        let decodeStarted = MonoTime.now()
        let decoded = CjguiGeneratedUiEncoding.decode(candidatePayload)
        let decodedNanoseconds = (MonoTime.now() - decodeStarted).toNanoseconds()
        synchronized(lock) {
            candidateDecodes += 1
            decodeNanoseconds += decodedNanoseconds
        }
        if (!decoded.ok) {
            return synchronized(lock) {
                holder.rejectCandidateAttempt(token, decoded.reason, "")
                let current = holder.structureVersion()
                CjguiSharedOperationGeneratedUiSubmit(false, decoded.reason, "", current, current,
                    candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
        }
        let root = match (decoded.root) {
            case Some(value) => value
            case None =>
                return synchronized(lock) {
                    holder.rejectCandidateAttempt(token, "empty_structure", "")
                    let current = holder.structureVersion()
                    CjguiSharedOperationGeneratedUiSubmit(false, "empty_structure", "", current, current,
                        candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
                }
        }
        return synchronized(lock) {
            let current = holder.structureVersion()
            if (sceneTransactionActive) {
                holder.rejectCandidateAttempt(token, "scene_transaction_busy", "")
                return CjguiSharedOperationGeneratedUiSubmit(false, "scene_transaction_busy", "", current, current,
                    candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            if (expectedVersion != current) {
                holder.rejectCandidateAttempt(token, "structure_version_conflict", "")
                return rejectedSubmit(token, current, "structure_version_conflict")
            }
            // The definition, its deletions and its instances travel in ONE
            // candidate ticket. Start this attempt from an EMPTY overlay: a
            // legal replacement retires the previous pending definition, while
            // an invalid B restores the snapshot below and keeps A pending.
            let previousOverlay = catalog.snapshotStagedComposites()
            catalog.rollbackStagedComposites()
            // Every definition of the ticket is staged before any removal or
            // instance validation. A failure at any position restores the
            // overlay the previous candidate owned, so a partly staged batch is
            // never observable.
            let definitionIssue = cjguiStageRuntimeCompositions(catalog, decoded.definitions)
            if (definitionIssue.size > 0) {
                catalog.restoreStagedComposites(previousOverlay)
                holder.rejectCandidateAttempt(token, definitionIssue, "")
                return rejectedSubmit(token, current, definitionIssue)
            }
            for (removed in decoded.removals) {
                let removalIssue = catalog.stageCompositionRemoval(removed)
                if (removalIssue.size > 0) {
                    catalog.restoreStagedComposites(previousOverlay)
                    holder.rejectCandidateAttempt(token, removalIssue, "")
                    return rejectedSubmit(token, current, removalIssue)
                }
                if (cjguiCompositionReferences(root, removed)) {
                    catalog.restoreStagedComposites(previousOverlay)
                    let issue = "composition_remove_still_referenced:${removed}"
                    holder.rejectCandidateAttempt(token, issue, "")
                    return rejectedSubmit(token, current, issue)
                }
                // §16: a definition REMAINING in the effective set may compose
                // the removed name; removing it would strand the reference.
                // The effective set = the staged batch + accepted minus every
                // name this candidate removes or replaces.
                if (cjguiCompositionReferencedByDefinitions(catalog,
                    decoded.definitions, removed)) {
                    catalog.restoreStagedComposites(previousOverlay)
                    let issue = "composition_remove_still_referenced:${removed}"
                    holder.rejectCandidateAttempt(token, issue, "")
                    return rejectedSubmit(token, current, issue)
                }
            }
            candidateValidations += 1
            let validationStarted = MonoTime.now()
            let result = holder.submit(root, binding, attemptToken: token)
            validationNanoseconds += (MonoTime.now() - validationStarted).toNanoseconds()
            if (!result.candidateAccepted) {
                // An invalid reference/budget/binding keeps the previous
                // candidate's definition, every accepted instance and data.
                catalog.restoreStagedComposites(previousOverlay)
            }
            if (result.candidateAccepted) { revisionValue += 1 }
            CjguiSharedOperationGeneratedUiSubmit(result.candidateAccepted, result.reason, result.path,
                result.structureVersionBefore, result.structureVersionAfter,
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion,
                candidateToken: token, receipt: result.receipt)
        }
    }

    private func observationSource(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>, ownerVersion!: Int64 = -1): CjguiGeneratedUiObservationSource {
        var identity = ""
        var sceneVersion: Int64 = 0
        var interactionRevision: Int64 = 0
        match (attachedWindow) {
            case Some(window) =>
                let progress = window.windowProgress()
                identity = progress.sessionIdentity
                sceneVersion = progress.acceptedSceneVersion
                interactionRevision = progress.interactionVersion
            case None => ()
        }
        let ownerRevision = if (ownerVersion >= 0) { ownerVersion } else { binding.ownerRevision() }
        return CjguiGeneratedUiObservationSource(identity, ownerRevision, ownerRevision,
            cjguiGeneratedUiBindingRevision(instances), holder.structureVersion(),
            holder.latestCandidateToken(), sceneOutcomeUnlocked(), sceneVersion,
            cjguiGeneratedUiGeometryRevision(instances), interactionRevision,
            cjguiGeneratedUiInstanceRevision(instances),
            !hasAcceptedOwnerStamp || ownerRevision != acceptedOwnerStamp,
            resourceRevision: catalog.imageResourceRevision(),
            imageStateRevision: holder.imageResourceStateRevision(),
            styleRevision: catalog.namedStyles().revision(),
            structureCandidatePending: holder.hasPendingCandidate())
    }

    public func snapshotPayload(): String {
        return synchronized(lock) {
            let instances = acceptedInstances()
            let feedback = binding.formFeedback()
            let version = feedbackRevision(feedback)
            let source = observationSource(instances, ownerVersion: version)
            let _ = tracker.observeSource(source)
            cjguiGeneratedUiSnapshotPayload(tracker, source, fieldsPayloadUnlocked(instances, feedback, version),
                structurePayloadUnlocked(), instancesPayloadUnlocked(instances),
                stylesPayload: CjguiGeneratedUiEncoding.stylesPayload(catalog))
        }
    }

    public func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        return synchronized(lock) {
            let _ = tracker.observeSource(observationSource(acceptedInstances()))
            tracker.changesPayload(streamEpoch, cursor)
        }
    }

    public func sectionPayload(section: String, expectedCursor: Int64): String {
        return synchronized(lock) {
            let instances = acceptedInstances()
            let feedback = binding.formFeedback()
            let version = feedbackRevision(feedback)
            let _ = tracker.observeSource(observationSource(instances, ownerVersion: version))
            if (tracker.currentCursor() != expectedCursor) {
                return cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, "")
            }
            let payload = if (section == "FIELDS") {
                fieldsPayloadUnlocked(instances, feedback, version)
            } else if (section == "STRUCTURE") {
                structurePayloadUnlocked()
            } else if (section == "INSTANCES") {
                instancesPayloadUnlocked(instances)
            } else if (section == "STYLES") {
                CjguiGeneratedUiEncoding.stylesPayload(catalog)
            } else { "" }
            cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, payload)
        }
    }

    /// Bounded work counters for normal consumers' idle-versus-submit cost
    /// evidence. A read of these counters performs no serialization itself.
    public func testWorkCounts(): String {
        return synchronized(lock) {
            "fields=${fieldsSerializations} structure=${structureSerializations} " +
                "instances=${instancesSerializations} samples=${acceptedInstanceSamples} " +
                "decodes=${candidateDecodes} validations=${candidateValidations} " +
                "builds=${sceneBuilds} commits=${sceneCommits} rollbacks=${sceneRollbacks} " +
                "decode_ns=${decodeNanoseconds} validation_ns=${validationNanoseconds} " +
                "build_ns=${buildNanoseconds} commit_ns=${commitNanoseconds} rollback_ns=${rollbackNanoseconds}"
        }
    }
}
