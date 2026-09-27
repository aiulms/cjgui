package cjgui

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

    public init(sceneIndex: Int64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        identityKey: String, identityAvailable: Bool, bounds: CjguiComposableUiRect,
        clipBounds: CjguiComposableUiRect, clipConstraints: ArrayList<CjguiComposableUiDiagnosticClip>,
        clipComplete: Bool, declaredEffectOutputBounds: CjguiComposableUiRect,
        nativeGeometryState: String, nativeGeometrySceneVersion: Int64,
        nativeGeometryFrameIndex: Int64, nativeOutputBounds: ?CjguiComposableUiDiagnosticFloatRect,
        nativeBackdropSampleBounds: ?CjguiComposableUiDiagnosticFloatRect,
        backdropCacheDisposition: String) {
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

    public init(status: String, sessionIdentity: String, acceptedSceneVersion: Int64,
        submittedSceneVersion: Int64, submittedFrameIndex: Int64, completedFrameIndex: Int64,
        failedFrameIndex: Int64, gpuDurationMicros: Int64, totalNodes: Int64, startIndex: Int64,
        nextIndex: Int64, truncated: Bool, nodes: ArrayList<CjguiComposableUiDiagnosticNode>,
        buildNanoseconds: Int64, layoutNanoseconds: Int64, nativeStageAndSubmitNanoseconds: Int64,
        buildPassCount: Int64, layoutPassCount: Int64, nativeSubmissionCount: Int64,
        effectLiveBytes: Int64, effectCachedBytes: Int64, effectInFlightBytes: Int64,
        rasterCount: Int64, uploadCount: Int64, effectPassCount: Int64, effectCacheHitCount: Int64,
        overlayEnabled: Bool, overlayStatus: String, overlayFlags: Int64, overlayDrawCount: Int64) {
        this.status = status; this.sessionIdentity = sessionIdentity
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
        this.buildPassCount = buildPassCount; this.layoutPassCount = layoutPassCount
        this.nativeSubmissionCount = nativeSubmissionCount
        this.effectLiveBytes = effectLiveBytes; this.effectCachedBytes = effectCachedBytes
        this.effectInFlightBytes = effectInFlightBytes
        this.rasterCount = rasterCount; this.uploadCount = uploadCount
        this.effectPassCount = effectPassCount; this.effectCacheHitCount = effectCacheHitCount
        this.overlayEnabled = overlayEnabled; this.overlayFlags = overlayFlags
        this.overlayStatus = overlayStatus
        this.overlayDrawCount = overlayDrawCount
    }
}

public class CjguiComposableUiDiagnosticOverlayOptions {
    public let enabled: Bool
    public let layout: Bool
    public let clip: Bool
    public let effectOutput: Bool
    public let backdropSample: Bool
    public let selectedIdentityKey: String
    public init(enabled: Bool, layout!: Bool = true, clip!: Bool = true,
        effectOutput!: Bool = true, backdropSample!: Bool = true, selectedIdentityKey!: String = "") {
        this.enabled = enabled; this.layout = layout; this.clip = clip
        this.effectOutput = effectOutput; this.backdropSample = backdropSample
        this.selectedIdentityKey = selectedIdentityKey
    }
}
