// One window-owned adapter between the shared generated structure holder and
// the ordinary scene/operation protocols. Applications provide only their
// catalog and live owner bindings; neither values nor business rules live here.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.sync.*
import std.time.*

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
}

/// A generated declaration belongs to exactly one window transaction. The
/// holder supplies candidate identity/rollback; this adapter publishes its
/// common protocol, observations and event route to any application domain.
public class CjguiGeneratedUiWindowRegion <: CjguiSharedOperationGeneratedUiProvider {
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let binding: CjguiGeneratedUiRegionBinding
    private let holder: CjguiGeneratedUiStructureHolder
    private let tracker: CjguiGeneratedUiObservationTracker
    private let lock: Mutex
    private var attachedWindow: ?CjguiComposableUiWindow
    private var revisionValue: Int64
    private var sceneTransactionActive: Bool
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

    public init(catalog: CjguiGeneratedUiCapabilityCatalog, binding: CjguiGeneratedUiRegionBinding,
                rootScopeName: String) {
        this.catalog = catalog
        this.binding = binding
        this.holder = CjguiGeneratedUiStructureHolder(catalog, rootScope: CjguiComposableUiIdentityScope(rootScopeName))
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

    public func acceptedNodeIdForKey(key: String): Int64 {
        return synchronized(lock) { holder.nodeIdForKey(key) }
    }

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) {
            if (sceneTransactionActive) { return false }
            closedSceneOutcome = ""
            sceneTransactionActive = true
            holder.beginStyleRefresh()
            if (!holder.beginCandidateRefresh()) {
                holder.rollbackCandidateRefresh()
                sceneTransactionActive = false
                revisionValue += 1
                return false
            }
            return true
        }
    }

    public func buildNode(): CjguiComposableUiNode {
        return synchronized(lock) {
            sceneBuilds += 1
            pendingOwnerStamp = binding.ownerRevision()
            match (attachedWindow) {
                case Some(window) => holder.sampleImageResourceStates(window)
                case None => ()
            }
            let started = MonoTime.now()
            let node = holder.buildRefreshNode(binding)
            buildNanoseconds += (MonoTime.now() - started).toNanoseconds()
            node
        }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) { holder.prepareCandidateRefresh() }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            sceneCommits += 1
            acceptedOwnerStamp = pendingOwnerStamp
            hasAcceptedOwnerStamp = true
            let hadCandidate = holder.hasPendingCandidate()
            let started = MonoTime.now()
            if (hadCandidate) {
                let _ = holder.commitCandidateRefresh()
                // Build sampled the previous accepted bindings. A prepared
                // image may already be ready when this candidate is accepted,
                // with no later completion epoch to refresh its public state.
                match (attachedWindow) {
                    case Some(window) => holder.sampleImageResourceStates(window)
                    case None => ()
                }
            } else {
                holder.commitStyleRefresh()
            }
            commitNanoseconds += (MonoTime.now() - started).toNanoseconds()
            sceneTransactionActive = false
            if (hadCandidate) { revisionValue += 1 }
        }
    }

    public func rollbackSceneRefresh(): Unit {
        synchronized(lock) {
            sceneRollbacks += 1
            let hadCandidate = holder.hasPendingCandidate()
            let started = MonoTime.now()
            if (hadCandidate) {
                holder.rollbackCandidateRefresh()
            } else {
                holder.rollbackStyleRefresh()
            }
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
            closedSceneOutcome = "scene_rejected:window_closed"
            sceneTransactionActive = false
            revisionValue += 1
        }
    }

    public func disposeSceneRefreshResources(): Unit {
        synchronized(lock) { holder.releaseAcceptedImageIdentities() }
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        synchronized(lock) {
            bindFieldRangeSessionIfFocused(event)
        }
        let intent = synchronized(lock) { holder.resolveIntent(event.node, event.eventKind, event.text) }
        if (intent.isFieldEdit()) {
            return binding.applyFieldIntent(intent)
        }
        if (intent.isAction()) {
            let outcome = binding.executeAction(intent.actionName, intent.nodeKey)
            return CjguiComposableUiDispatchResult(outcome.applied)
        }
        return CjguiComposableUiDispatchResult(false)
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
    private func bindFieldRangeSessionIfFocused(event: CjguiComposableUiEvent): Unit {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_FOCUS) {
            return
        }
        let node = event.node
        if (node.fieldId.size == 0) {
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} reason=no_field_id")
            return
        }
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return
        }
        if (catalog.fieldFor(node.fieldId).isNone()) {
            internalRendererWindowLog(
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
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "reason=binding_mismatch editor=${field.editorKind} writer=${field.writeActionName} " +
                "nodeWriter=${node.operationActionName} fieldRes=${field.resourceId} nodeRes=${node.resourceId} " +
                "ownerTarget=${node.operationResourceId}")
            return
        }
        if (!binding.rangeTextEditSupported(field.fieldId)) {
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "reason=provider_unsupported")
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
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "semantic=${node.semanticId} reason=stale_focus_not_accepted")
            return
        }
        if (window.ownedTextSessionBoundNodeId() == node.nodeId &&
            rangeSessionNodeId == node.nodeId && rangeSessionSemanticId == node.semanticId &&
            rangeSessionNodeKind == node.nodeKind && rangeSessionFieldId == field.fieldId &&
            rangeSessionWriterOperation == field.writeActionName &&
            rangeSessionFieldResource == field.resourceId &&
            rangeSessionOwnerTarget == node.operationResourceId) {
            return // 同一绑定的重复聚焦：不重建会话，组合态/选区保留
        }
        let session = CjguiGeneratedFieldRangeSession(binding, field.fieldId)
        let _ = window.bindRangeTextSession(node.nodeId, node.semanticId, session, session,
            field.resourceId, node.nodeKind)
        rangeSessionNodeId = node.nodeId
        rangeSessionSemanticId = node.semanticId
        rangeSessionNodeKind = node.nodeKind
        rangeSessionFieldId = field.fieldId
        rangeSessionWriterOperation = field.writeActionName
        rangeSessionFieldResource = field.resourceId
        rangeSessionOwnerTarget = node.operationResourceId
    }
    public func capabilitiesPayload(): String {
        return CjguiGeneratedUiEncoding.describe(catalog)
    }

    private func hexValue(value: String): String {
        return if (value.isEmpty()) { "-" } else { CjguiSharedOperationFrame.encodeUtf8Hex(value) }
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

    private func fieldsPayloadUnlocked(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): String {
        fieldsSerializations += 1
        let builder = StringBuilder()
        for (spec in catalog.fieldSpecs()) {
            let draft = if (spec.editorKind == "BOOLEAN") {
                CjguiSharedOperationValue.boolean(binding.draftBoolean(spec.fieldId) ?? false).displayText()
            } else {
                binding.draftText(spec.fieldId)
            }
            let applied = if (spec.editorKind == "BOOLEAN") {
                CjguiSharedOperationValue.boolean(binding.appliedBoolean(spec.fieldId) ?? false).displayText()
            } else {
                binding.appliedText(spec.fieldId)
            }
            let availability = binding.fieldAvailability(spec.fieldId)
            let available = if (!availability.known) { "unknown" } else if (availability.isAvailable) { "1" } else { "0" }
            let reason = if (availability.known && !availability.isAvailable) {
                hexValue(availability.reason)
            } else { "-" }
            builder.append("FIELD ${spec.fieldId} ${spec.resourceId} DRAFT_HEX ${hexValue(draft)} " +
                "APPLIED_HEX ${hexValue(applied)} ERROR none ${focusToken(spec.fieldId, instances)} " +
                "AVAILABLE ${available} REASON_HEX ${reason} TARGET ${availability.ownerResourceId} " +
                "STATE_VERSION ${availability.stateVersion} DRAFT_SOURCE ${binding.draftSource(spec.fieldId)} " +
                "VERSION ${binding.ownerRevision()}\n")
        }
        builder.append("END")
        return builder.toString()
    }

    public func fieldsPayload(): String {
        return synchronized(lock) { fieldsPayloadUnlocked(acceptedInstances()) }
    }

    private func structurePayloadUnlocked(): String {
        structureSerializations += 1
        return CjguiGeneratedUiEncoding.encode(holder.acceptedStructure(), holder.structureVersion())
    }

    public func acceptedStructurePayload(): String {
        return synchronized(lock) { structurePayloadUnlocked() }
    }

    public func acceptedStructureVersion(): Int64 {
        return synchronized(lock) { holder.structureVersion() }
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

    private func instancesPayloadUnlocked(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): String {
        instancesSerializations += 1
        return CjguiGeneratedUiEncoding.acceptedInstancesPayload(instances)
    }

    public func acceptedInstancesPayload(): String {
        return synchronized(lock) { instancesPayloadUnlocked(acceptedInstances()) }
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
                return CjguiSharedOperationGeneratedUiSubmit(false, "structure_version_conflict", "", current, current,
                    candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            candidateValidations += 1
            let validationStarted = MonoTime.now()
            let result = holder.submit(root, binding, attemptToken: token)
            validationNanoseconds += (MonoTime.now() - validationStarted).toNanoseconds()
            if (result.candidateAccepted) { revisionValue += 1 }
            CjguiSharedOperationGeneratedUiSubmit(result.candidateAccepted, result.reason, result.path,
                result.structureVersionBefore, result.structureVersionAfter,
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion,
                candidateToken: token, receipt: result.receipt)
        }
    }

    private func observationSource(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): CjguiGeneratedUiObservationSource {
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
        let ownerRevision = binding.ownerRevision()
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
            let source = observationSource(instances)
            let _ = tracker.observeSource(source)
            cjguiGeneratedUiSnapshotPayload(tracker, source, fieldsPayloadUnlocked(instances),
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
            let _ = tracker.observeSource(observationSource(instances))
            if (tracker.currentCursor() != expectedCursor) {
                return cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, "")
            }
            let payload = if (section == "FIELDS") {
                fieldsPayloadUnlocked(instances)
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
