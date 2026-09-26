package cjgui_shared_operation_core

import std.collection.*
import std.time.*

/// Experimental public value carried by a resource field or action argument.
/// This stage intentionally supports only the concrete value kinds consumed by
/// the list and backup-rule examples. It is not a reflection or schema system.
public class CjguiSharedOperationValue {
    public let valueType: String
    public let stringValue: String
    public let integerValue: Int64
    public let booleanValue: Bool

    private init(valueType: String, stringValue: String, integerValue: Int64, booleanValue: Bool) {
        this.valueType = valueType
        this.stringValue = stringValue
        this.integerValue = integerValue
        this.booleanValue = booleanValue
    }

    public static func string(value: String): CjguiSharedOperationValue {
        return CjguiSharedOperationValue("STRING", value, 0, false)
    }

    public static func integer(value: Int64): CjguiSharedOperationValue {
        return CjguiSharedOperationValue("INTEGER", "", value, false)
    }

    public static func boolean(value: Bool): CjguiSharedOperationValue {
        return CjguiSharedOperationValue("BOOLEAN", "", 0, value)
    }

    /// Canonical single-line text form of this value. Every projection that has
    /// to publish a value as text (field readback, external queries, logs) uses
    /// this one definition instead of each consumer inventing its own encoding:
    /// STRING keeps its text, INTEGER its decimal form, BOOLEAN "true"/"false".
    /// Without it a boolean field published `stringValue` and an external reader
    /// saw an empty value even though the business value was set.
    public func displayText(): String {
        if (valueType == "BOOLEAN") {
            return if (booleanValue) {
                "true"
            } else {
                "false"
            }
        }
        if (valueType == "INTEGER") {
            return "${integerValue}"
        }
        return stringValue
    }

    /// A bounded, transport-decoded list of original-version text ranges.
    /// Only action parameters may use this type; resource projections remain
    /// the three ordinary scalar kinds above.
    public static func textReplacements(value: String): CjguiSharedOperationValue {
        return CjguiSharedOperationValue("TEXT_REPLACEMENTS", value, 0, false)
    }
}

/// Experimental immutable named field projected from application-owned truth.
public class CjguiSharedOperationField {
    public let name: String
    public let value: CjguiSharedOperationValue

    public init(name: String, value: CjguiSharedOperationValue) {
        this.name = name
        this.value = value
    }
}

/// Experimental immutable resource projection. The application owns field
/// truth and keeps resource IDs stable across human and external operations.
public class CjguiSharedOperationResource {
    public let id: Int64
    public let name: String
    public let fields: ArrayList<CjguiSharedOperationField>

    public init(id: Int64, name: String, fields: ArrayList<CjguiSharedOperationField>) {
        this.id = id
        this.name = name
        this.fields = ArrayList<CjguiSharedOperationField>(fields)
    }
}

/// Experimental read-only semantic edge from the consumer's actual component
/// binding. Identifiers are local names, not another writable object graph:
/// resource fields and actions remain owned by the application domain.
public class CjguiSharedOperationRelation {
    public let sourceKind: String
    public let sourceId: String
    public let relation: String
    public let targetKind: String
    public let targetId: String
    /// Resource identities whose visibility is required for this edge. Empty
    /// means the edge has no resource-specific disclosure requirement.
    private let relatedResourceIds: ArrayList<Int64>

    public init(
        sourceKind: String,
        sourceId: String,
        relation: String,
        targetKind: String,
        targetId: String,
        resourceIds!: ArrayList<Int64> = ArrayList<Int64>()
    ) {
        this.sourceKind = sourceKind; this.sourceId = sourceId; this.relation = relation
        this.targetKind = targetKind; this.targetId = targetId
        this.relatedResourceIds = uniqueResourceIds(resourceIds)
    }

    public func resourceIds(): ArrayList<Int64> {
        return ArrayList<Int64>(relatedResourceIds)
    }
}

/// One stable component identity from a live window snapshot. The node ID is
/// the native event target; the semantic ID names the corresponding context
/// relationship. Resource scopes are used for both authorization and targets.
public class CjguiSharedOperationWindowNode {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: String
    private let relatedResourceIds: ArrayList<Int64>

    public init(nodeId: Int64, semanticId: String, nodeKind: String, resourceIds: ArrayList<Int64>) {
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.nodeKind = nodeKind
        this.relatedResourceIds = uniqueResourceIds(resourceIds)
    }

    public func resourceIds(): ArrayList<Int64> {
        return ArrayList<Int64>(relatedResourceIds)
    }
}

/// Direct read-only declaration of a field value shown by a live component.
/// It deliberately carries resource, field, state role and value source as
/// individual fields so an external consumer never has to parse a composed
/// relation target such as `resource42_field_draft`. This is presentation
/// context only; application-owned resource fields remain the durable truth.
public class CjguiSharedOperationWindowFieldValue {
    public let nodeSemanticId: String
    public let resourceId: Int64
    public let fieldId: String
    public let displayValueRole: String
    public let valueSource: String
    public let value: CjguiSharedOperationValue

    public init(
        nodeSemanticId: String,
        resourceId: Int64,
        fieldId: String,
        displayValueRole: String,
        valueSource: String,
        value: CjguiSharedOperationValue
    ) {
        this.nodeSemanticId = nodeSemanticId; this.resourceId = resourceId; this.fieldId = fieldId
        this.displayValueRole = displayValueRole; this.valueSource = valueSource; this.value = value
    }
}

/// Optional read-only state supplied by a live window. It is deliberately
/// separate from application context truth: a headless domain never invents a
/// visible window, and the platform may honestly report presentation as
/// unavailable while it has accepted a scene submission.
public class CjguiSharedOperationWindowProjection {
    public let isActive: Bool
    public let sceneVersion: Int64
    public let nativeSubmissionVersion: Int64
    public let presentationState: String
    /// Opaque Cangjie-owned lifecycle label, never a renderer capability or
    /// native pointer. It distinguishes a closed/reopened window projection.
    public let sessionIdentity: String
    /// The last scene whose complete native staging was accepted. A scene can
    /// be accepted before the platform gives any human-visible presentation
    /// guarantee, which remains `presentationState = unavailable` on macOS.
    public let acceptedSceneVersion: Int64
    /// Scene and Metal frame identities describe different facts: the latter
    /// increments per native submission and is not a business/domain version.
    public let submittedSceneVersion: Int64
    public let submittedFrameIndex: Int64
    /// -1 means no asynchronous Metal completion has been observed; it must
    /// not be treated as a failed frame or a claim that a human saw pixels.
    public let observedMetalCompletionFrameIndex: Int64
    /// -1 means no submitted command buffer has reported a terminal failure.
    /// This is a native diagnostic, never a domain or presentation result.
    public let observedMetalFailureFrameIndex: Int64
    /// -1 means Metal did not provide usable start/end timestamps for the
    /// observed completion.  Non-negative values are microseconds only.
    public let observedMetalGpuDurationMicros: Int64
    /// Last scene version reached from the self-drawn AppKit overlay's actual
    /// drawRect. It is deliberately distinct from a Metal submission.
    public let overlayDrawnSceneVersion: Int64
    /// `none` or a safe, machine-readable reason. Reading it never causes a
    /// refresh attempt; callers may request an explicit retry through the
    /// window owner.
    public let pendingRefreshReason: String
    public let lastNativeFailure: String
    /// Work counters are session-local diagnostics, not durability evidence.
    public let buildPassCount: Int64
    public let layoutPassCount: Int64
    public let nativeSubmissionCount: Int64
    /// Per-most-recent projection diagnostics in monotonic milliseconds.
    /// They are neither domain truth nor a claim of human-visible latency.
    public let lastBuildElapsedMs: Int64
    public let lastLayoutElapsedMs: Int64
    public let lastNativeMeasurementElapsedMs: Int64
    public let lastNativeStageAndSubmitElapsedMs: Int64
    public let lastNativeMeasurementCallCount: Int64
    /// Derived layout-cache facts for the most recently accepted candidate.
    /// They describe Cangjie revalidation/replay work, never business state,
    /// native presentation, or physical pixel visibility.
    public let layoutReuseHitCount: Int64
    public let layoutReuseMissCount: Int64
    public let layoutReuseRevalidationNodeCount: Int64
    public let layoutReuseReplayedNodeCount: Int64
    public let layoutReuseEntryCount: Int64
    public let focusedControlId: String
    public let selectionStart: Int64
    public let selectionEnd: Int64
    /// Selection offsets only have a meaning for a focused text control.
    /// Other controls may receive focus but must not be serialized as though
    /// they held a text range left over from a previous input field.
    public let hasTextSelection: Bool
    /// Logical collection metadata is intentionally distinct from rendered
    /// nodes. It lets an authorized peer understand which small window range
    /// is materialized without pretending off-screen items are visible.
    public let collections: ArrayList<CjguiSharedOperationWindowCollection>
    public let relations: ArrayList<CjguiSharedOperationRelation>
    public let nodes: ArrayList<CjguiSharedOperationWindowNode>
    public let fieldValues: ArrayList<CjguiSharedOperationWindowFieldValue>

    public init(
        isActive: Bool,
        sceneVersion: Int64,
        nativeSubmissionVersion: Int64,
        presentationState: String,
        focusedControlId: String,
        selectionStart: Int64,
        selectionEnd: Int64,
        relations: ArrayList<CjguiSharedOperationRelation>,
        nodes!: ArrayList<CjguiSharedOperationWindowNode> = ArrayList<CjguiSharedOperationWindowNode>(),
        fieldValues!: ArrayList<CjguiSharedOperationWindowFieldValue> = ArrayList<CjguiSharedOperationWindowFieldValue>(),
        collections!: ArrayList<CjguiSharedOperationWindowCollection> = ArrayList<CjguiSharedOperationWindowCollection>(),
        hasTextSelection!: Bool = false,
        sessionIdentity!: String = "unavailable",
        acceptedSceneVersion!: Int64 = 0,
        submittedSceneVersion!: Int64 = -1,
        submittedFrameIndex!: Int64 = -1,
        observedMetalCompletionFrameIndex!: Int64 = -1,
        observedMetalFailureFrameIndex!: Int64 = -1,
        observedMetalGpuDurationMicros!: Int64 = -1,
        overlayDrawnSceneVersion!: Int64 = -1,
        pendingRefreshReason!: String = "none",
        lastNativeFailure!: String = "none",
        buildPassCount!: Int64 = 0,
        layoutPassCount!: Int64 = 0,
        nativeSubmissionCount!: Int64 = 0,
        lastBuildElapsedMs!: Int64 = 0,
        lastLayoutElapsedMs!: Int64 = 0,
        lastNativeMeasurementElapsedMs!: Int64 = 0,
        lastNativeStageAndSubmitElapsedMs!: Int64 = 0,
        lastNativeMeasurementCallCount!: Int64 = 0,
        layoutReuseHitCount!: Int64 = 0,
        layoutReuseMissCount!: Int64 = 0,
        layoutReuseRevalidationNodeCount!: Int64 = 0,
        layoutReuseReplayedNodeCount!: Int64 = 0,
        layoutReuseEntryCount!: Int64 = 0
    ) {
        this.isActive = isActive
        this.sceneVersion = sceneVersion
        this.nativeSubmissionVersion = nativeSubmissionVersion
        this.presentationState = presentationState
        this.sessionIdentity = sessionIdentity
        this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedSceneVersion = submittedSceneVersion
        this.submittedFrameIndex = submittedFrameIndex
        this.observedMetalCompletionFrameIndex = observedMetalCompletionFrameIndex
        this.observedMetalFailureFrameIndex = observedMetalFailureFrameIndex
        this.observedMetalGpuDurationMicros = observedMetalGpuDurationMicros
        this.overlayDrawnSceneVersion = overlayDrawnSceneVersion
        this.pendingRefreshReason = pendingRefreshReason
        this.lastNativeFailure = lastNativeFailure
        this.buildPassCount = buildPassCount
        this.layoutPassCount = layoutPassCount
        this.nativeSubmissionCount = nativeSubmissionCount
        this.lastBuildElapsedMs = lastBuildElapsedMs
        this.lastLayoutElapsedMs = lastLayoutElapsedMs
        this.lastNativeMeasurementElapsedMs = lastNativeMeasurementElapsedMs
        this.lastNativeStageAndSubmitElapsedMs = lastNativeStageAndSubmitElapsedMs
        this.lastNativeMeasurementCallCount = lastNativeMeasurementCallCount
        this.layoutReuseHitCount = layoutReuseHitCount
        this.layoutReuseMissCount = layoutReuseMissCount
        this.layoutReuseRevalidationNodeCount = layoutReuseRevalidationNodeCount
        this.layoutReuseReplayedNodeCount = layoutReuseReplayedNodeCount
        this.layoutReuseEntryCount = layoutReuseEntryCount
        this.focusedControlId = focusedControlId
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.hasTextSelection = hasTextSelection
        this.collections = ArrayList<CjguiSharedOperationWindowCollection>(collections)
        this.relations = ArrayList<CjguiSharedOperationRelation>(relations)
        this.nodes = ArrayList<CjguiSharedOperationWindowNode>(nodes)
        this.fieldValues = ArrayList<CjguiSharedOperationWindowFieldValue>(fieldValues)
    }

    public static func inactive(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            false,
            0,
            -1,
            "unavailable",
            "",
            0,
            0,
            ArrayList<CjguiSharedOperationRelation>()
        )
    }
}

/// Read-only metadata for one virtual collection in a live window projection.
/// Keys describe domain-owned logical items; only `[materializedStart,
/// materializedEnd)` is represented by `WINDOW_NODE` entries in this frame.
public class CjguiSharedOperationWindowCollection {
    public let semanticId: String
    public let totalCount: Int64
    public let materializedStart: Int64
    public let materializedEnd: Int64
    public let selectedKey: String
    public let focusedKey: String
    public init(semanticId: String, totalCount: Int64, materializedStart: Int64,
        materializedEnd: Int64, selectedKey: String, focusedKey: String) {
        this.semanticId = semanticId
        this.totalCount = if (totalCount > 0) { totalCount } else { 0 }
        this.materializedStart = if (materializedStart > 0) { materializedStart } else { 0 }
        this.materializedEnd = if (materializedEnd < this.materializedStart) { this.materializedStart }
            else if (materializedEnd > this.totalCount) { this.totalCount } else { materializedEnd }
        this.selectedKey = selectedKey; this.focusedKey = focusedKey
    }
}

/// Optional capability deliberately owned by a live UI consumer rather than a
/// business domain. The connection only reads it while serializing context.
public interface CjguiSharedOperationWindowProjectionProvider {
    func windowProjection(): CjguiSharedOperationWindowProjection
}

/// Optional read-only catalog for an application that owns more than one
/// live window. Targets are opaque, token-safe identities supplied by that
/// application; they neither name a domain resource nor grant a mutation.
/// Returning `None` is the precise closed/unknown-target result. A consumer
/// must not substitute another currently live window for that target.
public interface CjguiSharedOperationWindowProjectionTargetProvider {
    func windowProjectionTargets(): ArrayList<String>
    func windowProjectionForTarget(target: String): ?CjguiSharedOperationWindowProjection
}

/// Application-owned generated-UI structure provider. The payload encoding is
/// chosen by the application/framework pair; the connection bounds and
/// forwards it, and never interprets structure or business state itself.
/// Fields, drafts and actions stay with the application's own owner.
public interface CjguiSharedOperationGeneratedUiProvider {
    /// Typed capability description (components, properties, actions, fields
    /// and the size bounds) that an external client can query.
    func capabilitiesPayload(): String
    /// Live field projections (draft, applied value, validation, focus and
    /// selection) for the fields the application registered. The same shared
    /// field descriptor/projection feeds the handwritten form, the generated
    /// region and this external read.
    func fieldsPayload(): String
    /// The currently accepted structure, with its structure version.
    func acceptedStructurePayload(): String
    /// Version of the currently accepted structure (0 when none accepted yet).
    func acceptedStructureVersion(): Int64
    /// Validates and expands a candidate. The previous accepted structure and
    /// its interaction routing stay in place on any rejection.
    func submitStructure(candidatePayload: String, expectedVersion: Int64): CjguiSharedOperationGeneratedUiSubmit
    /// Version a received candidate would install once the scene accepts it
    /// (0 when no candidate is pending). An external reader can therefore see
    /// "candidate received" without mistaking it for "already displayed".
    func candidateStructureVersion(): Int64 {
        return 0
    }
    /// Scene state of the last candidate: "scene_accepted", "scene_pending",
    /// "scene_rejected:<reason>", or "" before any candidate.
    func sceneState(): String {
        return ""
    }
    /// Accepted generated instances an external caller can address by their
    /// DECLARED key, one `INSTANCE ...` line each (the client's
    /// `generated-instances` parser). It answers "which accepted component is
    /// this key, and where is it" without exposing a native handle. Default: no
    /// instances, so a provider without a window scene keeps working.
    func acceptedInstancesPayload(): String {
        return ""
    }
    /// Compact terminal read for ONE submission attempt, addressed by the token
    /// the submit reply reported. The default answers an empty payload, which
    /// the transport reports as an unknown ticket rather than as a state.
    func candidateTicketPayload(token: Int64): String {
        return ""
    }
    /// ONE atomic generated-UI snapshot: stream identity/cursor, the separated
    /// owner and scene facts, and the fields/structure/instances sampled in this
    /// same provider call. The default is empty (no observation seam), so a
    /// provider that has not opted in keeps working.
    func snapshotPayload(): String {
        return ""
    }
    /// Bounded change read at one (streamEpoch, cursor): categories only, no
    /// tree/fields/geometry. `RESYNC_REQUIRED` asks for a fresh snapshot when
    /// the increment cannot be proven continuous.
    func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        return ""
    }
    /// ONE section of the snapshot, read ONLY when the tracker still reports
    /// `expectedCursor`; otherwise it answers `SNAPSHOT_REVISION_CHANGED 1`
    /// with no section content, so a caller can never stitch an unguarded
    /// section response into an older snapshot. Default: no seam.
    func sectionPayload(section: String, expectedCursor: Int64): String {
        return ""
    }
}

/// Test-only observer for the exact moment a public request becomes READY for
/// the owner (it has entered the ready queue, before any owner code runs).
///
/// It carries no capability and adds no protocol surface: it exists so a bounded
/// latency probe can time the real ready-queue entry with the same monotonic
/// clock as the owner commit and the window submission, instead of inferring a
/// boundary from queue counters or from the client's own send time. The callback
/// runs on the transport worker thread and must only record bounded data.
public interface CjguiSharedOperationReadyRequestObserver {
    func readyRequestQueued(sequence: Int64, at: MonoTime): Unit
}

/// Selection provider for a tree/collection surface. The window's own
/// selection object stays the only owner; this interface exposes a snapshot
/// and routes external selection/expansion commands through the same handler
/// the human input path uses, verifying the selection version.
public interface CjguiSharedOperationTreeSelectionProvider {
    /// Keys, focus, anchor and selection/projection versions.
    func selectionPayload(): String
    /// Applies one selection/expansion command (replace, toggle, range,
    /// select-all, clear, expand, collapse) at an exact selection version.
    func applySelection(command: String, key: String,
                         expectedSelectionVersion: Int64): CjguiSharedOperationTreeSelectionResult
}

public class CjguiSharedOperationTreeSelectionResult {
    public let applied: Bool
    public let reason: String
    public let selectionVersion: Int64

    public init(applied: Bool, reason: String, selectionVersion: Int64) {
        this.applied = applied
        this.reason = reason
        this.selectionVersion = selectionVersion
    }
}

/// One structure-submission outcome. Candidate acceptance is reported
/// separately from business/scene effects.
public class CjguiSharedOperationGeneratedUiSubmit {
    public let accepted: Bool
    public let reason: String
    public let path: String
    public let versionBefore: Int64
    public let versionAfter: Int64
    /// True only when the candidate passed validation and was received. The
    /// scene may still be pending; `sceneAccepted` distinguishes the two.
    public let candidateAccepted: Bool
    /// True when the window had already accepted the scene that contains this
    /// structure. A freshly submitted candidate is normally still pending.
    public let sceneAccepted: Bool
    public let candidateVersion: Int64
    /// Token of THIS attempt, allocated by the structure holder before the
    /// candidate was decoded. A caller polls the token to learn what happened to
    /// its own submission; `candidateVersion` alone cannot distinguish two
    /// submitters that share a base version.
    public let candidateToken: Int64
    /// Receipt string that belongs to `candidateToken`.
    public let receipt: String

    public init(accepted: Bool, reason: String, path: String, versionBefore: Int64, versionAfter: Int64,
                sceneAccepted!: Bool = false, candidateVersion!: Int64 = 0,
                candidateToken!: Int64 = 0, receipt!: String = "") {
        this.accepted = accepted
        this.reason = reason
        this.path = path
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.candidateAccepted = accepted
        this.sceneAccepted = sceneAccepted
        this.candidateVersion = candidateVersion
        this.candidateToken = candidateToken
        this.receipt = receipt
    }
}

/// Narrow, read-only facts from a live window.  The progress endpoint exposes
/// only lifecycle/scene/frame facts; its separately authorized interaction
/// endpoint may expose focus, selection coordinates and the top active layer.
/// Neither endpoint carries a component tree, field values, resource IDs,
/// collection positions, or text content. Their identities remain independent
/// from domain-content versions.
/// Focus facts a window interaction projection may carry. `valid` means the
/// projection holds a LIVE accepted control identity; `unfocused` means the
/// window is active with nothing focused; `unknown` means a focus existed but its
/// accepted identity can no longer be confirmed, so NO stale control id may be
/// published with it.
public let CJGUI_WINDOW_FOCUS_STATE_VALID = "valid"
public let CJGUI_WINDOW_FOCUS_STATE_UNFOCUSED = "unfocused"
public let CJGUI_WINDOW_FOCUS_STATE_UNKNOWN = "unknown"

public class CjguiSharedOperationWindowProgress {
    public let isActive: Bool
    public let sceneVersion: Int64
    public let nativeSubmissionVersion: Int64
    public let presentationState: String
    public let sessionIdentity: String
    public let acceptedSceneVersion: Int64
    public let submittedSceneVersion: Int64
    public let submittedFrameIndex: Int64
    public let observedMetalCompletionFrameIndex: Int64
    public let observedMetalFailureFrameIndex: Int64
    public let observedMetalGpuDurationMicros: Int64
    public let overlayDrawnSceneVersion: Int64
    public let pendingRefreshReason: String
    public let lastNativeFailure: String
    public let interactionVersion: Int64
    public let focusedControlId: String
    public let hasTextSelection: Bool
    public let selectionStart: Int64
    public let selectionEnd: Int64
    public let activeLayerId: String
    /// Which kind of focus fact this projection carries. The window's processed
    /// interaction projection can SAY it has a live focus, say nothing is
    /// focused, or admit that the previously focused identity can no longer be
    /// confirmed (removed, rebound or replaced). Collapsing the last two into one
    /// value would let a caller read a dead control as "nothing focused" or read
    /// "nothing focused" as a stale instance. It is a projection of the accepted
    /// scene, NOT a claim about the platform's key window or first responder.
    public let focusState: String
    /// Bounded, printable viewport facts of the accepted scene (one short line
    /// per viewport-bound scroll area). They let an external client tell whether
    /// content exists, whether it is clipped, and which viewport owns it, without
    /// serializing the capability catalog again.
    public let viewportFacts: ArrayList<String>

    public init(
        isActive: Bool,
        sceneVersion: Int64,
        nativeSubmissionVersion: Int64,
        presentationState: String,
        sessionIdentity: String,
        acceptedSceneVersion: Int64,
        submittedSceneVersion: Int64,
        submittedFrameIndex: Int64,
        observedMetalCompletionFrameIndex: Int64,
        observedMetalFailureFrameIndex: Int64,
        observedMetalGpuDurationMicros: Int64,
        overlayDrawnSceneVersion: Int64,
        pendingRefreshReason: String,
        lastNativeFailure: String,
        interactionVersion: Int64,
        focusedControlId: String,
        hasTextSelection: Bool,
        selectionStart: Int64,
        selectionEnd: Int64,
        activeLayerId: String,
        focusState!: String = CJGUI_WINDOW_FOCUS_STATE_UNKNOWN,
        viewportFacts!: ArrayList<String> = ArrayList<String>()
    ) {
        this.isActive = isActive; this.sceneVersion = sceneVersion
        this.nativeSubmissionVersion = nativeSubmissionVersion; this.presentationState = presentationState
        this.sessionIdentity = sessionIdentity; this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedSceneVersion = submittedSceneVersion; this.submittedFrameIndex = submittedFrameIndex
        this.observedMetalCompletionFrameIndex = observedMetalCompletionFrameIndex
        this.observedMetalFailureFrameIndex = observedMetalFailureFrameIndex
        this.observedMetalGpuDurationMicros = observedMetalGpuDurationMicros
        this.overlayDrawnSceneVersion = overlayDrawnSceneVersion
        this.pendingRefreshReason = pendingRefreshReason; this.lastNativeFailure = lastNativeFailure
        this.interactionVersion = interactionVersion; this.focusedControlId = focusedControlId
        this.hasTextSelection = hasTextSelection; this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd; this.activeLayerId = activeLayerId
        this.focusState = focusState
        this.viewportFacts = ArrayList<String>(viewportFacts)
    }

    public static func inactive(): CjguiSharedOperationWindowProgress {
        return CjguiSharedOperationWindowProgress(false, 0, -1, "unavailable", "", 0, -1, -1, -1, -1, -1, -1, "none", "none", 0, "none", false, 0, 0, "none")
    }
}

/// Optional provider for the narrow progress endpoint.  A consumer must opt
/// in separately rather than paying to build a complete window projection.
public interface CjguiSharedOperationWindowProgressProvider {
    func windowProgress(): CjguiSharedOperationWindowProgress
}

/// Target-bound narrow facts for an application that owns several windows.
/// The caller must name an opaque target obtained from the matching
/// projection-target catalog. Returning `None` is the precise result for a
/// closed, stale, or foreign target; providers must never substitute a live
/// sibling's progress or interaction state.
public interface CjguiSharedOperationWindowProgressTargetProvider {
    func windowProgressForTarget(target: String): ?CjguiSharedOperationWindowProgress
}

/// Experimental read-only context projection for one application domain.
public class CjguiSharedOperationContextSnapshot {
    public let version: Int64
    /// Optional identity from the same owner read boundary as `version` and
    /// resources. Empty preserves compatibility with legacy snapshot owners;
    /// clients must then use full resyncs rather than incremental cursors.
    public let streamIdentity: String
    public let contextName: String
    public let resourceType: String
    public let resources: ArrayList<CjguiSharedOperationResource>
    public let relations: ArrayList<CjguiSharedOperationRelation>

    public init(
        version: Int64,
        contextName: String,
        resourceType: String,
        resources: ArrayList<CjguiSharedOperationResource>,
        relations!: ArrayList<CjguiSharedOperationRelation> = ArrayList<CjguiSharedOperationRelation>(),
        streamIdentity!: String = ""
    ) {
        this.version = version
        this.streamIdentity = streamIdentity
        this.contextName = contextName
        this.resourceType = resourceType
        this.resources = ArrayList<CjguiSharedOperationResource>(resources)
        this.relations = ArrayList<CjguiSharedOperationRelation>(relations)
    }
}

/// Experimental declared parameter shape used for discovery and transport
/// validation before application business code is called.
public class CjguiSharedOperationParameterDescriptor {
    public let name: String
    public let valueType: String
    public let isRequired: Bool

    public init(name: String, valueType: String, isRequired: Bool) {
        this.name = name
        this.valueType = valueType
        this.isRequired = isRequired
    }
}

/// Experimental declared business action. Target bounds are checked by the
/// shared transport; value ranges and business rules stay with the application.
public class CjguiSharedOperationActionDescriptor {
    public let name: String
    public let displayName: String
    public let parameters: ArrayList<CjguiSharedOperationParameterDescriptor>
    public let minimumTargetCount: Int64
    public let maximumTargetCount: Int64

    public init(
        name: String,
        displayName: String,
        parameters: ArrayList<CjguiSharedOperationParameterDescriptor>,
        minimumTargetCount: Int64,
        maximumTargetCount: Int64
    ) {
        this.name = name
        this.displayName = displayName
        this.parameters = ArrayList<CjguiSharedOperationParameterDescriptor>(parameters)
        this.minimumTargetCount = minimumTargetCount
        this.maximumTargetCount = maximumTargetCount
    }
}

/// Experimental one typed action argument after transport-level validation.
public class CjguiSharedOperationActionArgument {
    public let name: String
    public let value: CjguiSharedOperationValue

    public init(name: String, value: CjguiSharedOperationValue) {
        this.name = name
        this.value = value
    }
}

/// Experimental actual action request. `expectedVersion` is checked inside
/// the application's business lock for external calls; the human path carries
/// the same action shape but need not use a compare-and-swap version.
public class CjguiSharedOperationActionInvocation {
    public let actionName: String
    public let expectedVersion: Int64
    public let targetResourceIds: ArrayList<Int64>
    public let arguments: ArrayList<CjguiSharedOperationActionArgument>

    public init(
        actionName: String,
        expectedVersion: Int64,
        targetResourceIds: ArrayList<Int64>,
        arguments: ArrayList<CjguiSharedOperationActionArgument>
    ) {
        this.actionName = actionName
        this.expectedVersion = expectedVersion
        this.targetResourceIds = ArrayList<Int64>(targetResourceIds)
        this.arguments = ArrayList<CjguiSharedOperationActionArgument>(arguments)
    }
}

/// Experimental concrete business outcome. A rejected or stale call must not
/// claim success; applications report their version atomically with the result.
public class CjguiSharedOperationActionResult {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        reason: String
    ) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.reason = reason
    }
}

/// Application-owned truth and action boundary. The external connection never
/// implements a business action; it validates declared transport facts and
/// calls this interface. A trusted human entry calls `executeFromHuman`, while
/// socket calls can only reach `executeFromExternal`.
public interface CjguiSharedOperationDomain {
    func resourceType(): String
    func contextSnapshot(): CjguiSharedOperationContextSnapshot
    func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor>
    func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult
    func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult
}

/// Optional owner-side read path for an explicitly requested resource set.
/// It is deliberately unavailable for a whole-context read: callers retain
/// the compatible `contextSnapshot()` semantics unless they name every target
/// they need. Returning `None` means at least one target is unknown to the
/// owner; the transport must not reinterpret that as an empty snapshot.
public interface CjguiSharedOperationTargetedContextDomain {
    func contextSnapshotForExternalTargets(
        targets: ArrayList<Int64>
    ): ?CjguiSharedOperationContextSnapshot
}

/// Experimental bounded change entry derived from a domain's committed truth.
/// It identifies what may need rereading; it is not a second writable model.
public class CjguiSharedOperationChangeEntry {
    public let version: Int64
    public let resourceId: Int64
    public let kind: String
    public init(version: Int64, resourceId: Int64, kind: String) {
        this.version = version; this.resourceId = resourceId; this.kind = kind
    }
}

/// Experimental response for an incremental context read. `requiresResync`
/// is explicit when the bounded history cannot safely answer a cursor.
public class CjguiSharedOperationChanges {
    public let sinceVersion: Int64
    public let currentVersion: Int64
    /// Opaque domain/instance identity. A numeric version alone is not a
    /// cursor because a reopened document can legitimately restart at it.
    public let streamIdentity: String
    public let requiresResync: Bool
    public let entries: ArrayList<CjguiSharedOperationChangeEntry>
    public init(sinceVersion: Int64, currentVersion: Int64, streamIdentity: String, requiresResync: Bool, entries: ArrayList<CjguiSharedOperationChangeEntry>) {
        this.sinceVersion = sinceVersion; this.currentVersion = currentVersion
        this.streamIdentity = streamIdentity; this.requiresResync = requiresResync; this.entries = ArrayList<CjguiSharedOperationChangeEntry>(entries)
    }
}

/// Optional domain capability for bounded incremental reads. Connections only
/// expose it when the application explicitly supplies this capability.
public interface CjguiSharedOperationChangeDomain {
    func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>, expectedStreamIdentity: String): CjguiSharedOperationChanges
}

/// Experimental bounded text-range response. The body is returned only when
/// the application validates both the resource and the requested boundaries;
/// context discovery therefore never needs to disclose a full document.
public class CjguiSharedOperationRangeRead {
    public let isAvailable: Bool
    public let isVersionConflict: Bool
    public let resourceId: Int64
    public let version: Int64
    public let start: Int64
    public let end: Int64
    public let content: String
    public let reason: String

    public init(
        isAvailable: Bool,
        isVersionConflict: Bool,
        resourceId: Int64,
        version: Int64,
        start: Int64,
        end: Int64,
        content: String,
        reason: String
    ) {
        this.isAvailable = isAvailable
        this.isVersionConflict = isVersionConflict
        this.resourceId = resourceId
        this.version = version
        this.start = start
        this.end = end
        this.content = content
        this.reason = reason
    }
}

/// Optional application capability for reads of an explicitly authorized,
/// bounded document range. Range and version validation remain with document
/// truth; the transport only authenticates and bounds the wire request.
public interface CjguiSharedOperationRangeReadDomain {
    func readRangeFromExternal(
        resourceId: Int64,
        start: Int64,
        end: Int64,
        expectedVersion: Int64
    ): CjguiSharedOperationRangeRead
}

/// Experimental explicit authorization range for one operation over stable
/// resource IDs. `allowsAllResources` is suitable for a reader; a write is
/// normally limited to the resources the developer intentionally granted.
public class CjguiSharedOperationExternalActionScope {
    public let actionName: String
    public let allowsAllResources: Bool
    private let resourceIds: ArrayList<Int64>

    public init(actionName: String, resourceIds: ArrayList<Int64>, allowsAllResources: Bool) {
        this.actionName = actionName
        this.allowsAllResources = allowsAllResources
        this.resourceIds = uniqueResourceIds(resourceIds)
    }

    public func allowedResourceIds(): ArrayList<Int64> {
        return ArrayList<Int64>(resourceIds)
    }

    public func permitsResource(resourceId: Int64): Bool {
        return allowsAllResources || containsResourceId(resourceIds, resourceId)
    }
}

/// Experimental local capability grant. Applications create it through a
/// trusted ingress and hand its descriptor only to the already-authorized
/// caller; socket payloads cannot self-assert a human identity.
public class CjguiSharedOperationExternalAuthorization {
    public let callerId: String
    private let capabilityToken: String
    private let scopes: ArrayList<CjguiSharedOperationExternalActionScope>

    public init(
        callerId: String,
        capabilityToken: String,
        scopes: ArrayList<CjguiSharedOperationExternalActionScope>
    ) {
        this.callerId = callerId
        this.capabilityToken = capabilityToken
        this.scopes = ArrayList<CjguiSharedOperationExternalActionScope>(scopes)
    }

    public func actionScopes(): ArrayList<CjguiSharedOperationExternalActionScope> {
        return ArrayList<CjguiSharedOperationExternalActionScope>(scopes)
    }

    public func permitsAction(actionName: String): Bool {
        for (scope in scopes) {
            if (scope.actionName == actionName) {
                return true
            }
        }
        return false
    }

    public func permitsResource(actionName: String, resourceId: Int64): Bool {
        for (scope in scopes) {
            if (scope.actionName == actionName && scope.permitsResource(resourceId)) {
                return true
            }
        }
        return false
    }

    public func allowsAllResources(actionName: String): Bool {
        for (scope in scopes) {
            if (scope.actionName == actionName && scope.allowsAllResources) {
                return true
            }
        }
        return false
    }

    public func allowedResourceIds(actionName: String): ArrayList<Int64> {
        let allowed = ArrayList<Int64>()
        for (scope in scopes) {
            if (scope.actionName == actionName) {
                for (resourceId in scope.allowedResourceIds()) {
                    if (!containsResourceId(allowed, resourceId)) {
                        allowed.add(resourceId)
                    }
                }
            }
        }
        return allowed
    }

    public func matchesCapability(capability: String): Bool {
        return capability == capabilityToken
    }

    public func capabilityForGrantedCaller(): String {
        return capabilityToken
    }
}

/// Experimental discoverable local endpoint. Paths exist only after `start`;
/// the application-created descriptor remains the intended capability handoff.
public class CjguiSharedOperationConnectionInfo {
    public let protocol: String
    public let descriptorPath: String
    public let socketPath: String
    public let callerId: String
    public let capabilityToken: String
    public let actionScopes: ArrayList<CjguiSharedOperationExternalActionScope>
    public let actions: ArrayList<CjguiSharedOperationActionDescriptor>

    public init(
        protocol: String,
        descriptorPath: String,
        socketPath: String,
        callerId: String,
        capabilityToken: String,
        actionScopes: ArrayList<CjguiSharedOperationExternalActionScope>,
        actions: ArrayList<CjguiSharedOperationActionDescriptor>
    ) {
        this.protocol = protocol
        this.descriptorPath = descriptorPath
        this.socketPath = socketPath
        this.callerId = callerId
        this.capabilityToken = capabilityToken
        this.actionScopes = ArrayList<CjguiSharedOperationExternalActionScope>(actionScopes)
        this.actions = ArrayList<CjguiSharedOperationActionDescriptor>(actions)
    }
}

private func uniqueResourceIds(resourceIds: ArrayList<Int64>): ArrayList<Int64> {
    let unique = ArrayList<Int64>()
    for (resourceId in resourceIds) {
        if (!containsResourceId(unique, resourceId)) {
            unique.add(resourceId)
        }
    }
    return unique
}

private func containsResourceId(resourceIds: ArrayList<Int64>, resourceId: Int64): Bool {
    for (candidate in resourceIds) {
        if (candidate == resourceId) {
            return true
        }
    }
    return false
}
