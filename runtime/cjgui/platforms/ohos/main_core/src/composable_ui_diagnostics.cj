package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

/// Experimental, bounded, read-only developer view of one accepted scene.
/// These values contain no controller, text value, texture or native handle.
public class CjguiComposableUiDiagnosticClip {
    public let bounds: CjguiComposableUiRect
    public let cornerRadius: Int64
    public let ownerIdentity: String
    public let ownerIdentityAvailable: Bool

    public init(bounds: CjguiComposableUiRect, cornerRadius: Int64, ownerIdentity: String,
        ownerIdentityAvailable: Bool) {
        this.bounds = bounds
        this.cornerRadius = cornerRadius
        this.ownerIdentity = ownerIdentity
        this.ownerIdentityAvailable = ownerIdentityAvailable
    }
}

public class CjguiComposableUiDiagnosticNode {
    public let sceneIndex: Int64
    public let nodeId: Int64
    public let resourceId: Int64
    public let nodeKind: Int64
    public let identityKey: String
    public let identityAvailable: Bool
    public let bounds: CjguiComposableUiRect
    public let clipBounds: CjguiComposableUiRect
    public let clipConstraints: ArrayList<CjguiComposableUiDiagnosticClip>
    public let clipComplete: Bool
    /// Conservative Cangjie shadow extent for this node, not the final group
    /// target. Exact native effect output is separate and version tagged.
    public let declaredEffectOutputBounds: CjguiComposableUiRect
    public let nativeGeometryState: String
    public let nativeGeometrySceneVersion: Int64
    public let nativeGeometryFrameIndex: Int64
    public let nativeOutputBounds: ?CjguiComposableUiDiagnosticFloatRect
    public let nativeBackdropSampleBounds: ?CjguiComposableUiDiagnosticFloatRect
    public let backdropCacheDisposition: String
    /// Read-only metadata from this accepted layout. No label/value/body text.
    public let semanticId: String
    public let parentSceneIndex: Int64
    public let parentIdentityKey: String
    public let depth: Int64
    public let styleSummary: String
    public let fieldId: String
    public let actionName: String
    public let ownerTargetResourceId: Int64
    public let semanticIncarnation: Int64

    public init(sceneIndex: Int64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        identityKey: String, identityAvailable: Bool, bounds: CjguiComposableUiRect,
        clipBounds: CjguiComposableUiRect, clipConstraints: ArrayList<CjguiComposableUiDiagnosticClip>,
        clipComplete: Bool, declaredEffectOutputBounds: CjguiComposableUiRect,
        nativeGeometryState: String, nativeGeometrySceneVersion: Int64,
        nativeGeometryFrameIndex: Int64, nativeOutputBounds: ?CjguiComposableUiDiagnosticFloatRect,
        nativeBackdropSampleBounds: ?CjguiComposableUiDiagnosticFloatRect,
        backdropCacheDisposition: String, semanticId!: String = "", parentSceneIndex!: Int64 = -1,
        parentIdentityKey!: String = "", depth!: Int64 = -1, styleSummary!: String = "",
        fieldId!: String = "", actionName!: String = "", ownerTargetResourceId!: Int64 = -1,
        semanticIncarnation!: Int64 = -1) {
        this.sceneIndex = sceneIndex
        this.nodeId = nodeId
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.identityKey = identityKey
        this.identityAvailable = identityAvailable
        this.bounds = bounds
        this.clipBounds = clipBounds
        this.clipConstraints = ArrayList<CjguiComposableUiDiagnosticClip>(clipConstraints)
        this.clipComplete = clipComplete
        this.declaredEffectOutputBounds = declaredEffectOutputBounds
        this.nativeGeometryState = nativeGeometryState
        this.nativeGeometrySceneVersion = nativeGeometrySceneVersion
        this.nativeGeometryFrameIndex = nativeGeometryFrameIndex
        this.nativeOutputBounds = nativeOutputBounds
        this.nativeBackdropSampleBounds = nativeBackdropSampleBounds
        this.backdropCacheDisposition = backdropCacheDisposition
        this.semanticId = semanticId
        this.parentSceneIndex = parentSceneIndex
        this.parentIdentityKey = parentIdentityKey
        this.depth = depth
        this.styleSummary = styleSummary
        this.fieldId = fieldId
        this.actionName = actionName
        this.ownerTargetResourceId = ownerTargetResourceId
        this.semanticIncarnation = semanticIncarnation
    }
}

/// Native geometry uses point coordinates, including exact subpoint ROI edges.
public class CjguiComposableUiDiagnosticFloatRect {
    public let x: Float64
    public let y: Float64
    public let width: Float64
    public let height: Float64
    public init(x: Float64, y: Float64, width: Float64, height: Float64) {
        this.x = x; this.y = y; this.width = width; this.height = height
    }
}

public class CjguiComposableUiDiagnosticSnapshot {
    public let status: String
    public let geometry: CjguiSharedOperationWindowGeometry
    public let sessionIdentity: String
    public let acceptedSceneVersion: Int64
    public let submittedSceneVersion: Int64
    public let submittedFrameIndex: Int64
    public let completedFrameIndex: Int64
    public let failedFrameIndex: Int64
    public let gpuDurationMicros: Int64
    public let totalNodes: Int64
    public let startIndex: Int64
    public let nextIndex: Int64
    public let truncated: Bool
    public let nodes: ArrayList<CjguiComposableUiDiagnosticNode>
    /// Last refresh ATTEMPT timings; a rejected candidate can be the source.
    /// Negative values mean the interval was not measured.
    public let buildNanoseconds: Int64
    public let layoutNanoseconds: Int64
    public let nativeStageAndSubmitNanoseconds: Int64
    /// Cumulative completed refresh attempts, for whole-operation deltas.
    public let totalBuildNanoseconds: Int64
    public let totalLayoutNanoseconds: Int64
    public let totalNativeStageAndSubmitNanoseconds: Int64
    public let buildPassCount: Int64
    public let layoutPassCount: Int64
    public let nativeSubmissionCount: Int64
    /// Native budget accounting includes in-flight generations. A negative
    /// value means this backend has not published that metric.
    public let effectLiveBytes: Int64
    public let effectCachedBytes: Int64
    public let effectInFlightBytes: Int64
    public let rasterCount: Int64
    public let uploadCount: Int64
    public let effectPassCount: Int64
    public let effectCacheHitCount: Int64
    public let overlayEnabled: Bool
    public let overlayStatus: String
    public let overlayFlags: Int64
    public let overlayDrawCount: Int64
    /// Explicitly enabled bounded workload observation. Counting is a scalar
    /// increment at real work points and stays on in normal builds; this switch
    /// only decides whether the snapshot publishes the values, so a disabled
    /// read costs nothing and no read ever triggers a refresh, a clone or a
    /// submission. Negative values mean "not published"; `workloadStatus`
    /// carries "disabled", "enabled" or "native_unavailable".
    public let workloadEnabled: Bool
    public let workloadStatus: String
    /// Accepted-scene identity of the native read that produced the cumulative
    /// totals below; -1 when the values were not published.
    public let workloadSceneVersion: Int64
    public let nodeWriteCount: Int64
    public let nodeCloneCount: Int64
    public let nodeAllocationCount: Int64
    public let textLayoutPreparationCount: Int64
    public let imageDecodeStartCount: Int64
    /// Current (not cumulative) reusable bytes: this session's accepted text
    /// textures and resident vector buffers plus the shared image texture
    /// cache. A rejected candidate keeps the accepted scene's values.
    public let reusableResourceBytes: Int64
    /// Cumulative normal-build text work; the resource values are current
    /// accepted bytes and the accepted-plus-candidate high water respectively.
    public let textRasterCount: Int64
    public let textRasterBytes: Int64
    public let textRasterMicros: Int64
    public let textUploadCount: Int64
    public let textUploadBytes: Int64
    public let textUploadMicros: Int64
    public let textTextureLiveBytes: Int64
    public let textCandidatePeakBytes: Int64
    /// The last completed refresh attempt's workload deltas, measured from the
    /// attempt start to its accept or reject terminal. "none" until one
    /// completed attempt has been observed with observation enabled.
    public let lastAttemptWorkloadResult: String
    public let lastAttemptNodeWrites: Int64
    public let lastAttemptNodeClones: Int64
    public let lastAttemptNodeAllocations: Int64
    public let lastAttemptTextLayoutPreparations: Int64
    public let lastAttemptImageDecodeStarts: Int64
    /// Opt-in, session-scoped timing. All duration fields use nanoseconds;
    /// -1 means disabled or unavailable, while zero is a measured zero.
    public let timingEnabled: Bool
    public let timingStatus: String
    public let timingClockSource: String
    public let timingSessionIdentity: String
    public let timingAcceptedSceneVersion: Int64
    public let positionPrepareCount: Int64
    public let positionQueryCount: Int64
    public let positionLineBuildCount: Int64
    public let positionCacheHitCount: Int64
    public let positionPrepareNanoseconds: Int64
    public let positionQueryNanoseconds: Int64
    public let positionLineBuildNanoseconds: Int64
    public let encodeNanoseconds: Int64
    public let submitNanoseconds: Int64
    public let textRasterNanoseconds: Int64
    public let textUploadNanoseconds: Int64
    public let timingReadCount: Int64
    public let timingReadNanoseconds: Int64

    public init(status: String, sessionIdentity: String, acceptedSceneVersion: Int64,
        submittedSceneVersion: Int64, submittedFrameIndex: Int64, completedFrameIndex: Int64,
        failedFrameIndex: Int64, gpuDurationMicros: Int64, totalNodes: Int64, startIndex: Int64,
        nextIndex: Int64, truncated: Bool, nodes: ArrayList<CjguiComposableUiDiagnosticNode>,
        buildNanoseconds: Int64, layoutNanoseconds: Int64, nativeStageAndSubmitNanoseconds: Int64,
        buildPassCount: Int64, layoutPassCount: Int64, nativeSubmissionCount: Int64,
        effectLiveBytes: Int64, effectCachedBytes: Int64, effectInFlightBytes: Int64,
        rasterCount: Int64, uploadCount: Int64, effectPassCount: Int64, effectCacheHitCount: Int64,
        overlayEnabled: Bool, overlayStatus: String, overlayFlags: Int64, overlayDrawCount: Int64,
        workloadEnabled!: Bool = false, workloadStatus!: String = "disabled",
        workloadSceneVersion!: Int64 = -1, nodeWriteCount!: Int64 = -1, nodeCloneCount!: Int64 = -1,
        nodeAllocationCount!: Int64 = -1, textLayoutPreparationCount!: Int64 = -1,
        imageDecodeStartCount!: Int64 = -1, reusableResourceBytes!: Int64 = -1,
        lastAttemptWorkloadResult!: String = "none", lastAttemptNodeWrites!: Int64 = -1,
        lastAttemptNodeClones!: Int64 = -1, lastAttemptNodeAllocations!: Int64 = -1,
        lastAttemptTextLayoutPreparations!: Int64 = -1, lastAttemptImageDecodeStarts!: Int64 = -1,
        geometry!: CjguiSharedOperationWindowGeometry = CjguiSharedOperationWindowGeometry.unavailable(),
        totalBuildNanoseconds!: Int64 = -1, totalLayoutNanoseconds!: Int64 = -1,
        totalNativeStageAndSubmitNanoseconds!: Int64 = -1,
        textRasterCount!: Int64 = -1, textRasterBytes!: Int64 = -1,
        textRasterMicros!: Int64 = -1, textUploadCount!: Int64 = -1,
        textUploadBytes!: Int64 = -1, textUploadMicros!: Int64 = -1,
        textTextureLiveBytes!: Int64 = -1, textCandidatePeakBytes!: Int64 = -1,
        timingEnabled!: Bool = false, timingStatus!: String = "disabled",
        timingClockSource!: String = "unavailable", timingSessionIdentity!: String = "unavailable",
        timingAcceptedSceneVersion!: Int64 = -1, positionPrepareCount!: Int64 = -1,
        positionQueryCount!: Int64 = -1, positionLineBuildCount!: Int64 = -1,
        positionCacheHitCount!: Int64 = -1, positionPrepareNanoseconds!: Int64 = -1,
        positionQueryNanoseconds!: Int64 = -1, positionLineBuildNanoseconds!: Int64 = -1,
        encodeNanoseconds!: Int64 = -1, submitNanoseconds!: Int64 = -1,
        textRasterNanoseconds!: Int64 = -1, textUploadNanoseconds!: Int64 = -1,
        timingReadCount!: Int64 = -1, timingReadNanoseconds!: Int64 = -1) {
        this.status = status; this.sessionIdentity = sessionIdentity
        this.geometry = geometry
        this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedSceneVersion = submittedSceneVersion
        this.submittedFrameIndex = submittedFrameIndex
        this.completedFrameIndex = completedFrameIndex
        this.failedFrameIndex = failedFrameIndex
        this.gpuDurationMicros = gpuDurationMicros
        this.totalNodes = totalNodes; this.startIndex = startIndex
        this.nextIndex = nextIndex; this.truncated = truncated
        this.nodes = ArrayList<CjguiComposableUiDiagnosticNode>(nodes)
        this.buildNanoseconds = buildNanoseconds
        this.layoutNanoseconds = layoutNanoseconds
        this.nativeStageAndSubmitNanoseconds = nativeStageAndSubmitNanoseconds
        this.totalBuildNanoseconds = totalBuildNanoseconds
        this.totalLayoutNanoseconds = totalLayoutNanoseconds
        this.totalNativeStageAndSubmitNanoseconds = totalNativeStageAndSubmitNanoseconds
        this.buildPassCount = buildPassCount; this.layoutPassCount = layoutPassCount
        this.nativeSubmissionCount = nativeSubmissionCount
        this.effectLiveBytes = effectLiveBytes; this.effectCachedBytes = effectCachedBytes
        this.effectInFlightBytes = effectInFlightBytes
        this.rasterCount = rasterCount; this.uploadCount = uploadCount
        this.effectPassCount = effectPassCount; this.effectCacheHitCount = effectCacheHitCount
        this.overlayEnabled = overlayEnabled; this.overlayFlags = overlayFlags
        this.overlayStatus = overlayStatus
        this.overlayDrawCount = overlayDrawCount
        this.workloadEnabled = workloadEnabled; this.workloadStatus = workloadStatus
        this.workloadSceneVersion = workloadSceneVersion
        this.nodeWriteCount = nodeWriteCount; this.nodeCloneCount = nodeCloneCount
        this.nodeAllocationCount = nodeAllocationCount
        this.textLayoutPreparationCount = textLayoutPreparationCount
        this.imageDecodeStartCount = imageDecodeStartCount
        this.reusableResourceBytes = reusableResourceBytes
        this.textRasterCount = textRasterCount
        this.textRasterBytes = textRasterBytes
        this.textRasterMicros = textRasterMicros
        this.textUploadCount = textUploadCount
        this.textUploadBytes = textUploadBytes
        this.textUploadMicros = textUploadMicros
        this.textTextureLiveBytes = textTextureLiveBytes
        this.textCandidatePeakBytes = textCandidatePeakBytes
        this.lastAttemptWorkloadResult = lastAttemptWorkloadResult
        this.lastAttemptNodeWrites = lastAttemptNodeWrites
        this.lastAttemptNodeClones = lastAttemptNodeClones
        this.lastAttemptNodeAllocations = lastAttemptNodeAllocations
        this.lastAttemptTextLayoutPreparations = lastAttemptTextLayoutPreparations
        this.lastAttemptImageDecodeStarts = lastAttemptImageDecodeStarts
        this.timingEnabled = timingEnabled
        this.timingStatus = timingStatus
        this.timingClockSource = timingClockSource
        this.timingSessionIdentity = timingSessionIdentity
        this.timingAcceptedSceneVersion = timingAcceptedSceneVersion
        this.positionPrepareCount = positionPrepareCount
        this.positionQueryCount = positionQueryCount
        this.positionLineBuildCount = positionLineBuildCount
        this.positionCacheHitCount = positionCacheHitCount
        this.positionPrepareNanoseconds = positionPrepareNanoseconds
        this.positionQueryNanoseconds = positionQueryNanoseconds
        this.positionLineBuildNanoseconds = positionLineBuildNanoseconds
        this.encodeNanoseconds = encodeNanoseconds
        this.submitNanoseconds = submitNanoseconds
        this.textRasterNanoseconds = textRasterNanoseconds
        this.textUploadNanoseconds = textUploadNanoseconds
        this.timingReadCount = timingReadCount
        this.timingReadNanoseconds = timingReadNanoseconds
    }
}

public class CjguiComposableUiDiagnosticOverlayOptions {
    public let enabled: Bool
    public let layout: Bool
    public let clip: Bool
    public let effectOutput: Bool
    public let backdropSample: Bool
    public let selectedIdentityKey: String
    /// Optional pinned accepted snapshot. Legacy overlays remain unpinned.
    public let expectedSessionIdentity: String
    public let expectedAcceptedSceneVersion: Int64
    /// Caller-owned tag; conditional clear cannot erase another tool's layer.
    public let ownerKey: String
    public init(enabled: Bool, layout!: Bool = true, clip!: Bool = true,
        effectOutput!: Bool = true, backdropSample!: Bool = true, selectedIdentityKey!: String = "",
        expectedSessionIdentity!: String = "", expectedAcceptedSceneVersion!: Int64 = -1,
        ownerKey!: String = "") {
        this.enabled = enabled; this.layout = layout; this.clip = clip
        this.effectOutput = effectOutput; this.backdropSample = backdropSample
        this.selectedIdentityKey = selectedIdentityKey
        this.expectedSessionIdentity = expectedSessionIdentity
        this.expectedAcceptedSceneVersion = expectedAcceptedSceneVersion
        this.ownerKey = ownerKey
    }

    public func matchesAccepted(sessionIdentity: String, acceptedSceneVersion: Int64): Bool {
        return (expectedSessionIdentity.isEmpty() || expectedSessionIdentity == sessionIdentity) &&
            (expectedAcceptedSceneVersion < 0 || expectedAcceptedSceneVersion == acceptedSceneVersion)
    }
}

/// One accepted command declaration plus its resolution against the accepted
/// scene. This is a read-only projection: building it never invokes a command,
/// resolves a candidate scene, or copies business text. `resolution` is one of
/// "resolved", "unresolved" or "rejected"; `unavailableReason` is empty only
/// when the target resolves and the declaration is enabled.
public class CjguiComposableUiDiagnosticCommand {
    public let id: String
    public let displayName: String
    public let scopeId: String
    public let targetReference: String
    public let resolvedNodeId: Int64
    public let resolvedNodeKind: Int64
    public let resolution: String
    public let enabled: Bool
    public let checked: Bool
    /// The declaration's own checkable bit. An unchecked checkable command
    /// (`checked=false, checkable=true`) and a plain action
    /// (`checked=false, checkable=false`) are different facts.
    public let checkable: Bool
    public let shortcut: String
    public let menuGroup: String
    public let menuSection: Int64
    public let acceptedSceneVersion: Int64
    public let publicationRevision: Int64
    public let unavailableReason: String

    public init(id: String, displayName: String, scopeId: String, targetReference: String,
        resolvedNodeId: Int64, resolvedNodeKind: Int64, resolution: String, enabled: Bool, checked: Bool,
        checkable: Bool, shortcut: String, menuGroup: String, menuSection: Int64, acceptedSceneVersion: Int64,
        publicationRevision: Int64, unavailableReason: String) {
        this.id = id
        this.displayName = displayName
        this.scopeId = scopeId
        this.targetReference = targetReference
        this.resolvedNodeId = resolvedNodeId
        this.resolvedNodeKind = resolvedNodeKind
        this.resolution = resolution
        this.enabled = enabled
        this.checked = checked
        this.checkable = checkable
        this.shortcut = shortcut
        this.menuGroup = menuGroup
        this.menuSection = menuSection
        this.acceptedSceneVersion = acceptedSceneVersion
        this.publicationRevision = publicationRevision
        this.unavailableReason = unavailableReason
    }

    public func searchText(): String {
        return "${id} ${displayName} ${scopeId} ${targetReference} ${resolution} ${shortcut}"
    }
}

/// Bounded command view for the existing inspector. `totalCommands` is the
/// number of accepted bindings at read time; `commands` covers
/// `[startIndex, nextIndex)` of that order and `truncated` says more pages
/// exist. `publicationRevision` is the accepted command publication the page
/// was read against; window identity and scene version alone cannot see a
/// same-scene replace/revoke. No snapshot retains the window or the controller.
public class CjguiComposableUiCommandDiagnosticSnapshot {
    public let status: String
    public let sessionIdentity: String
    public let acceptedSceneVersion: Int64
    public let publicationRevision: Int64
    public let totalCommands: Int64
    public let truncated: Bool
    public let startIndex: Int64
    public let nextIndex: Int64
    public let commands: ArrayList<CjguiComposableUiDiagnosticCommand>

    public init(status: String, sessionIdentity: String, acceptedSceneVersion: Int64,
        publicationRevision: Int64, totalCommands: Int64, truncated: Bool, startIndex: Int64,
        nextIndex: Int64, commands: ArrayList<CjguiComposableUiDiagnosticCommand>) {
        this.status = status
        this.sessionIdentity = sessionIdentity
        this.acceptedSceneVersion = acceptedSceneVersion
        this.publicationRevision = publicationRevision
        this.totalCommands = totalCommands
        this.truncated = truncated
        this.startIndex = startIndex
        this.nextIndex = nextIndex
        this.commands = ArrayList<CjguiComposableUiDiagnosticCommand>(commands)
    }
}

/// Walk the accepted layout's actual preorder spans, never rectangle enclosure.
/// Output paging can omit ancestors; their absolute scene indices remain facts.
class CjguiDiagnosticHierarchyCursor {
    private let nodes: ArrayList<CjguiComposableUiLayoutNode>
    private let stack = ArrayList<Int64>()
    private var cursor: Int64 = 0
    var parentIndex: Int64 = -1
    var depth: Int64 = 0
    init(nodes: ArrayList<CjguiComposableUiLayoutNode>) { this.nodes = nodes }
    func advanceTo(index: Int64): Unit {
        while (cursor <= index && cursor < nodes.size) {
            while (!stack.isEmpty()) {
                let parent = stack[stack.size - 1]
                if (parent + nodes[parent].subtreeNodeCount > cursor) { break }
                let _ = stack.remove(at: stack.size - 1)
            }
            parentIndex = if (stack.isEmpty()) { -1 } else { stack[stack.size - 1] }
            depth = stack.size
            stack.add(cursor)
            cursor += 1
        }
    }
}
