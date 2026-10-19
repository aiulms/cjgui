package cjgui

import std.collection.*

// Actual result of the ordinary Windows restore command. Constructed only by
// the transport after that command succeeds; never an input transfer receipt.
class CjguiSelectionPaintNativeRestore {
    let requestId: Int64
    let commandId: UInt64
    let rendererGeneration: UInt64
    let bindingEpoch: UInt64
    let sceneVersion: Int64
    let nodeId: Int64
    let resourceId: Int64
    let nodeKind: Int64
    let start16: Int64
    let end16: Int64
    init(facts: Array<UInt64>) {
        requestId = Int64(facts[0]); commandId = facts[1]
        rendererGeneration = facts[2]; bindingEpoch = facts[3]
        sceneVersion = Int64(facts[4]); nodeId = Int64(facts[5])
        // Resource IDs are signed Int64, including the ordinary unassigned -1.
        // The numeric wire preserves its 64 bits; checked numeric conversion
        // would throw for every negative resource instead of preserving it.
        resourceId = if (facts[6] <= UInt64(Int64.Max)) { Int64(facts[6]) }
            else { -1 - Int64(UInt64.Max - facts[6]) }
        nodeKind = Int64(facts[7])
        start16 = Int64(facts[8]); end16 = Int64(facts[9])
    }
}

class CjguiSelectionPaintNativeRestoreBox {
    var value: ?CjguiSelectionPaintNativeRestore = None
}

/// Experimental, read-only paint observation. The framework freezes this only
/// after the actual ordinary restore, owner adoption and final binding publish.
/// It grants no input authority and contains no transfer/proxy/install nonce.
public class CjguiAcceptedSelectionPaintBasis {
    public let publicationId: UInt64
    public let windowSession: UInt64
    public let windowInstanceToken: UInt64
    public let requestId: Int64
    public let nativeCommandId: UInt64
    public let rendererSessionGeneration: UInt64
    public let nativeBindingEpoch: UInt64
    public let bindingEpoch: UInt64
    public let targetSceneVersion: Int64
    public let targetNodeId: Int64
    public let targetResourceId: Int64
    public let targetNodeKind: Int64
    public let targetBody: String
    public let targetStart16: Int64
    public let targetEnd16: Int64
    public let sourceSelection: CjguiSourceSelectionSnapshot

    init(publicationId: UInt64, window: UInt64, instance: UInt64,
        native: CjguiSelectionPaintNativeRestore, binding: UInt64, body: String,
        selected: CjguiSourceSelectionSnapshot) {
        this.publicationId = publicationId; windowSession = window; windowInstanceToken = instance
        requestId = native.requestId; nativeCommandId = native.commandId
        rendererSessionGeneration = native.rendererGeneration; nativeBindingEpoch = native.bindingEpoch
        bindingEpoch = binding; targetSceneVersion = native.sceneVersion
        targetNodeId = native.nodeId; targetResourceId = native.resourceId; targetNodeKind = native.nodeKind
        targetBody = body; targetStart16 = native.start16; targetEnd16 = native.end16
        sourceSelection = selected
    }

    func matches(selected: CjguiSourceSelectionSnapshot, window: UInt64, binding: UInt64): Bool {
        let original = sourceSelection
        return publicationId != 0u64 && nativeCommandId != 0u64 && requestId > 0 &&
            rendererSessionGeneration != 0u64 && windowSession == window && bindingEpoch == binding &&
            targetNodeKind == CJGUI_COMPOSABLE_UI_TEXT && targetSceneVersion > 0 &&
            targetStart16 >= 0 && targetEnd16 >= targetStart16 && original.documentId.size > 0 &&
            original.sessionEpoch > 0 && original.documentId == selected.documentId &&
            original.sessionEpoch == selected.sessionEpoch && original.viewGeneration == selected.viewGeneration &&
            original.version == selected.version && original.revision == selected.revision &&
            original.anchorByte == selected.anchorByte && original.focusByte == selected.focusByte
    }
}

/// Optional incremental provider for ordinary restore paint. None means the
/// accepted mapping is not ready; the framework retains one bounded obligation.
/// Implementations read accepted state only and must not submit another choice.
public interface CjguiComposableUiSelectionPaintProvider {
    func acceptedSelectionPaint(basis: CjguiAcceptedSelectionPaintBasis):
        ?CjguiComposableUiSelectionDecoration
}

// Exactly one logical pending publication per window, independent of native
// batch retirement. Existing transfer consumers keep their original API.
enum CjguiPreviewSelectionPaintPublication {
    Transfer(CjguiInstalledSelectionCompletion) | Restore(CjguiAcceptedSelectionPaintBasis, Bool) | Clear
}

func cjguiPreviewPaintTransfer(value: ?CjguiInstalledSelectionCompletion): ?CjguiPreviewSelectionPaintPublication {
    return match (value) { case Some(v) => Some(CjguiPreviewSelectionPaintPublication.Transfer(v)); case None => None }
}

func cjguiPreviewPaintCompletion(value: ?CjguiPreviewSelectionPaintPublication): ?CjguiInstalledSelectionCompletion {
    return match (value) {
        case Some(CjguiPreviewSelectionPaintPublication.Transfer(v)) => Some(v)
        case _ => None
    }
}

// Package-private Darwin bridge. Public completion remains platform-neutral;
// paint publication neither creates a receipt nor grants input authority.
@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_publish_installed_selection_owner(session: UInt64,
        generation: UInt64, window: UInt64, context: UInt64,
        receipt: CPointer<CjguiInternalSelectionTransferReceipt>, version: Int64, revision: Int64): Int32
    func cjgui_internal_renderer_finish_selection_paint_publication(session: UInt64,
        transfer: UInt64, generation: UInt64, binding: UInt64, proxy: UInt64,
        nativeRevision: UInt64, ownerVersion: Int64, ownerRevision: Int64,
        proxyOnly: UInt8, needsProjection: CPointer<UInt8>): Int32
    func cjgui_internal_renderer_stage_selection_paint_publication(session: UInt64,
        transfer: UInt64, generation: UInt64, binding: UInt64, ownerVersion: Int64,
        ownerRevision: Int64, scene: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererActualSelectionReceipt(v: CjguiInstalledSelectionCompletion): CjguiInternalSelectionTransferReceipt {
    var r = CjguiInternalSelectionTransferReceipt()
    r.transferId = v.transferId; r.sceneVersion = UInt64(v.targetSceneVersion)
    r.bindingEpoch = v.targetBindingEpoch; r.nodeId = UInt64(v.targetNodeId)
    r.projectionVersion = UInt64(v.targetProjectionVersion); r.resourceId = v.targetResourceId
    r.nodeKind = UInt32(v.targetNodeKind); r.selectionStart16 = UInt32(v.targetSelectionStart16)
    r.selectionEnd16 = UInt32(v.targetSelectionEnd16); r.selectionRevision = v.targetSelectionRevision
    r.proxyGeneration = v.targetProxyGeneration; r.firstResponder = 1u8
    return r
}

@When[os == "macOS"]
func internalRendererPublishInstalledSelectionOwner(v: CjguiInstalledSelectionCompletion): Int32 {
    var r = internalRendererActualSelectionReceipt(v)
    return unsafe { cjgui_internal_renderer_publish_installed_selection_owner(v.windowSession,
        v.rendererSessionGeneration, v.windowInstanceToken, UInt64(v.sourceContextEpoch),
        inout r, v.sourceSelection.version, v.sourceSelection.revision) }
}

@When[os != "macOS"]
func internalRendererPublishInstalledSelectionOwner(v: CjguiInstalledSelectionCompletion): Int32 {
    return CJGUI_INTERNAL_RENDERER_OK
}

@When[os == "macOS"]
func internalRendererFinishSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    proxyOnly: Bool): (Int32, Bool) {
    var needs: UInt8 = 0
    let status = unsafe { cjgui_internal_renderer_finish_selection_paint_publication(
        completion.windowSession, completion.transferId, completion.rendererSessionGeneration,
        completion.targetBindingEpoch, completion.targetProxyGeneration,
        completion.targetSelectionRevision, completion.sourceOwnerVersion,
        completion.sourceSelection.revision, if (proxyOnly) { 1u8 } else { 0u8 }, inout needs) }
    return (status, needs == 1u8)
}

@When[os != "macOS"]
func internalRendererFinishSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    proxyOnly: Bool): (Int32, Bool) { return (CJGUI_INTERNAL_RENDERER_OK, false) }

@When[os == "macOS"]
func internalRendererStageSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    scene: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_stage_selection_paint_publication(
        completion.windowSession, completion.transferId, completion.rendererSessionGeneration,
        completion.targetBindingEpoch, completion.sourceOwnerVersion,
        completion.sourceSelection.revision, scene) }
}

@When[os != "macOS"]
func internalRendererStageSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    scene: UInt64): Int32 { return CJGUI_INTERNAL_RENDERER_OK }

@When[os == "Windows"]
foreign func cjgui_internal_renderer_stage_preview_selection_decoration(session: UInt64,
    publication: UInt64, rendererGeneration: UInt64, bindingEpoch: UInt64,
    ownerVersion: Int64, ownerRevision: Int64, projectionId: Int64, sceneVersion: UInt64,
    red: Float64, green: Float64, blue: Float64, alpha: Float64, rows: CString): Int32

@When[os == "Windows"]
foreign func cjgui_internal_renderer_clear_preview_selection_decoration(session: UInt64): Int32

@When[os == "Windows"]
func internalRendererClearPreviewSelectionDecoration(session: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_clear_preview_selection_decoration(session) }
}

@When[os != "Windows"]
func internalRendererClearPreviewSelectionDecoration(session: UInt64): Int32 { return CJGUI_INTERNAL_RENDERER_OK }

@When[os == "Windows"]
func internalRendererStagePreviewSelectionPaint(session: UInt64, basis: CjguiAcceptedSelectionPaintBasis,
    decoration: CjguiComposableUiSelectionDecoration, scene: Int64,
    nodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 {
    if (decoration.paintPublicationId != basis.publicationId || decoration.transferId != 0u64 ||
        decoration.ownerVersion != basis.sourceSelection.version ||
        decoration.ownerRevision != basis.sourceSelection.revision || decoration.projectionId <= 0 ||
        decoration.acceptedSceneVersion != scene || scene <= 0 ||
        decoration.color.rejectionReason().isSome()) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    let rows = match (decoration.encodedNodeRanges()) {
        case Some(value) => value; case None => return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID
    }
    for (fragment in decoration.fragments) {
        var found = false
        for (node in nodes) {
            if (node.nodeId == fragment.nodeId) {
                if (node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT || node.value != fragment.body) {
                    return CJGUI_INTERNAL_RENDERER_SCENE_STALE
                }
                found = true; break
            }
        }
        if (!found) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    }
    let wire = unsafe { LibC.mallocCString(rows) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (resource = wire.asResource()) {
        status = unsafe { cjgui_internal_renderer_stage_preview_selection_decoration(session,
            basis.publicationId, basis.rendererSessionGeneration, basis.bindingEpoch,
            decoration.ownerVersion, decoration.ownerRevision, decoration.projectionId, UInt64(scene),
            decoration.color.red, decoration.color.green, decoration.color.blue, decoration.color.alpha, resource.value) }
    }
    return status
}

@When[os != "Windows"]
func internalRendererStagePreviewSelectionPaint(session: UInt64, basis: CjguiAcceptedSelectionPaintBasis,
    decoration: CjguiComposableUiSelectionDecoration, scene: Int64,
    nodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 { return -1 }

@When[os == "Windows"]
func internalRendererStagePreviewSelectionDecoration(session: UInt64,
    completion: CjguiInstalledSelectionCompletion,
    decoration: CjguiComposableUiSelectionDecoration,
    acceptedSceneVersion: Int64,
    sceneNodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 {
    return internalRendererStagePreviewSelectionDecorationForCurrentOwner(session, completion,
        completion.sourceSelection, decoration, acceptedSceneVersion, sceneNodes)
}

@When[os == "Windows"]
func internalRendererStagePreviewSelectionDecorationForCurrentOwner(session: UInt64,
    completion: CjguiInstalledSelectionCompletion,
    selected: CjguiSourceSelectionSnapshot,
    decoration: CjguiComposableUiSelectionDecoration,
    acceptedSceneVersion: Int64,
    sceneNodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 {
    if (!decoration.matchesCurrentOwner(completion, selected, acceptedSceneVersion) ||
        decoration.color.rejectionReason().isSome() || decoration.color.red < 0.0 ||
        decoration.color.red > 1.0 || decoration.color.green < 0.0 ||
        decoration.color.green > 1.0 || decoration.color.blue < 0.0 ||
        decoration.color.blue > 1.0 || decoration.color.alpha < 0.0 ||
        decoration.color.alpha > 1.0) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    let rows = match (decoration.encodedNodeRanges()) {
        case Some(value) => value
        case None => return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID
    }
    for (fragment in decoration.fragments) {
        var found = false
        for (node in sceneNodes) {
            if (node.nodeId == fragment.nodeId) {
                if (node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT || node.value != fragment.body) {
                    return CJGUI_INTERNAL_RENDERER_SCENE_STALE
                }
                found = true
                break
            }
        }
        if (!found) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    }
    let wire = unsafe { LibC.mallocCString(rows) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (resource = wire.asResource()) {
        status = unsafe { cjgui_internal_renderer_stage_preview_selection_decoration(session,
            completion.transferId, completion.rendererSessionGeneration,
            completion.targetBindingEpoch, selected.version,
            selected.revision, decoration.projectionId,
            UInt64(acceptedSceneVersion), decoration.color.red, decoration.color.green,
            decoration.color.blue, decoration.color.alpha, resource.value) }
    }
    return status
}

@When[os != "Windows"]
func internalRendererStagePreviewSelectionDecoration(session: UInt64,
    completion: CjguiInstalledSelectionCompletion,
    decoration: CjguiComposableUiSelectionDecoration,
    acceptedSceneVersion: Int64,
    sceneNodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 { return -1 }

@When[os != "Windows"]
func internalRendererStagePreviewSelectionDecorationForCurrentOwner(session: UInt64,
    completion: CjguiInstalledSelectionCompletion,
    selected: CjguiSourceSelectionSnapshot,
    decoration: CjguiComposableUiSelectionDecoration,
    acceptedSceneVersion: Int64,
    sceneNodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 { return -1 }

// Only Darwin paints an accepted selection on the native text proxy. A caller
// that skips its own decoration publication must be told when the platform will
// not paint it, or the selection silently never reaches the screen.
@When[os == "macOS"]
func internalRendererSupportsProxySelectionPaint(): Bool { return true }

@When[os != "macOS"]
func internalRendererSupportsProxySelectionPaint(): Bool { return false }

// Windows has no native proxy selection paint, but its renderer can stage the
// accepted range against the accepted layout and repaint only the decoration.
// That is what makes the proxy-only consumer shortcut safe there: the framework,
// not the consumer, carries the draw. Deliberately separate from the
// native-proxy predicate above, which decides whether the framework has to
// compensate at all; conflating them would either skip the compensation on
// Windows or force a needless refresh on Darwin.
@When[os == "Windows"]
func internalRendererSupportsStagedPreviewSelectionPaint(): Bool { return true }

@When[os != "Windows"]
func internalRendererSupportsStagedPreviewSelectionPaint(): Bool { return false }

// The first accepted decoration is also the source lineage for later accepted
// scenes. A Windows display-fragment batch is tied to one scene version, so a
// subsequent legal owner edit must be able to reproject and stage it again.
// Native proxy painters have already consumed the accepted decoration and do
// not need this retained preview obligation.
func selectionPaintPublicationForAcceptedPreview(
    completion: CjguiInstalledSelectionCompletion,
    supportsStagedPreviewPaint: Bool): ?CjguiInstalledSelectionCompletion {
    if (supportsStagedPreviewPaint && completion.targetNodeKind == CJGUI_COMPOSABLE_UI_TEXT) {
        return Some(completion)
    }
    return None
}

/// A display fragment in an accepted-source selection decoration. `body` is
/// retained only at the Cangjie validation boundary so the window can require
/// an exact match with the accepted scene before sending numeric ranges to the
/// platform renderer.
public class CjguiComposableUiSelectionDecorationFragment {
    public let nodeId: Int64
    public let body: String
    public let start16: Int64
    public let end16: Int64

    public init(nodeId: Int64, body: String, start16: Int64, end16: Int64) {
        this.nodeId = nodeId
        this.body = body
        this.start16 = start16
        this.end16 = end16
    }
}

/// One bounded paint projection of an already accepted owner selection.
/// Ranges may be empty to explicitly clear a fragment from the previous paint.
public class CjguiComposableUiSelectionDecoration {
    public let transferId: UInt64
    public let paintPublicationId: UInt64
    public let ownerVersion: Int64
    public let ownerRevision: Int64
    public let projectionId: Int64
    public let acceptedSceneVersion: Int64
    public let color: CjguiComposableUiColor
    public let fragments: ArrayList<CjguiComposableUiSelectionDecorationFragment>
    // Optional for existing consumers. Direct accepted-layout paint requires
    // the same opaque mapping identity frozen in the accepted caret proposal.
    public let mappingIdentity: String

    public init(transferId: UInt64, ownerVersion: Int64, ownerRevision: Int64,
        projectionId: Int64, acceptedSceneVersion: Int64,
        color: CjguiComposableUiColor,
        fragments: ArrayList<CjguiComposableUiSelectionDecorationFragment>,
        mappingIdentity!: String = "") {
        this.mappingIdentity = mappingIdentity
        this.transferId = transferId
        this.paintPublicationId = 0u64
        this.ownerVersion = ownerVersion
        this.ownerRevision = ownerRevision
        this.projectionId = projectionId
        this.acceptedSceneVersion = acceptedSceneVersion
        this.color = color
        this.fragments = fragments
    }

    private init(publicationId: UInt64, ownerVersion: Int64, ownerRevision: Int64,
        projectionId: Int64, scene: Int64, color: CjguiComposableUiColor,
        fragments: ArrayList<CjguiComposableUiSelectionDecorationFragment>, paint: Bool) {
        transferId = 0u64; paintPublicationId = publicationId
        this.ownerVersion = ownerVersion; this.ownerRevision = ownerRevision
        this.projectionId = projectionId; acceptedSceneVersion = scene
        this.color = color; this.fragments = fragments; mappingIdentity = ""
    }

    public static func forPaint(publicationId: UInt64, ownerVersion: Int64, ownerRevision: Int64,
        projectionId: Int64, scene: Int64, color: CjguiComposableUiColor,
        fragments: ArrayList<CjguiComposableUiSelectionDecorationFragment>): CjguiComposableUiSelectionDecoration {
        return CjguiComposableUiSelectionDecoration(publicationId, ownerVersion, ownerRevision,
            projectionId, scene, color, fragments, true)
    }

    func matches(completion: CjguiInstalledSelectionCompletion,
        acceptedSceneVersion: Int64): Bool {
        return transferId != 0u64 && transferId == completion.transferId &&
            ownerVersion == completion.sourceOwnerVersion &&
            ownerRevision == completion.sourceSelection.revision && ownerRevision > 0 &&
            projectionId > 0 && this.acceptedSceneVersion == acceptedSceneVersion &&
            acceptedSceneVersion > 0 && completion.targetSceneVersion > 0 &&
            completion.targetNodeKind == CJGUI_COMPOSABLE_UI_TEXT
    }

    /// Retained paint may follow a newer accepted owner selection while the
    /// original installation receipt remains immutable. Keep the transfer and
    /// owner-session identity, but bind the ranges to the current source version,
    /// selection revision, and accepted scene.
    func matchesCurrentOwner(completion: CjguiInstalledSelectionCompletion,
        selected: CjguiSourceSelectionSnapshot, acceptedSceneVersion: Int64): Bool {
        let original = completion.sourceSelection
        return transferId != 0u64 && transferId == completion.transferId &&
            completion.targetNodeKind == CJGUI_COMPOSABLE_UI_TEXT &&
            completion.targetSceneVersion > 0 && completion.targetBindingEpoch != 0u64 &&
            original.version == completion.sourceOwnerVersion &&
            original.revision == completion.semantic.selectionRevision &&
            selected.documentId == original.documentId && selected.documentId.size > 0 &&
            selected.sessionEpoch == original.sessionEpoch && selected.sessionEpoch > 0 &&
            selected.viewGeneration == original.viewGeneration &&
            selected.version >= completion.sourceOwnerVersion && selected.version > 0 &&
            selected.revision > 0 && ownerVersion == selected.version &&
            ownerRevision == selected.revision && projectionId > 0 &&
            this.acceptedSceneVersion == acceptedSceneVersion && acceptedSceneVersion > 0
    }

    func matchesMapping(completion: CjguiInstalledSelectionCompletion,
        scene: Int64, acceptedMapping: String): Bool {
        return acceptedMapping.size > 0 && mappingIdentity == acceptedMapping && matches(completion, scene)
    }

    /// Private numeric wire for the native stage call. The caller verifies
    /// every body and node kind against the accepted scene before using it.
    func encodedNodeRanges(): ?String {
        if (fragments.size == 0 || fragments.size > 64) { return None }
        var seen = ArrayList<Int64>()
        var encoded = ""
        for (fragment in fragments) {
            if (fragment.nodeId <= 0 || fragment.start16 < 0 ||
                fragment.end16 < fragment.start16 || seen.contains(fragment.nodeId)) {
                return None
            }
            seen.add(fragment.nodeId)
            if (encoded.size > 0) { encoded += ";" }
            encoded += "${fragment.nodeId}:${fragment.start16}:${fragment.end16}"
        }
        if (encoded.size > 8192) { return None }
        return Some(encoded)
    }
}

/// The application maps owner coordinates through its accepted SourceMap and
/// returns bounded display fragments. The window performs a second check
/// against its accepted scene before staging paint; this provider grants no
/// input, edit, focus, or selection authority.
public interface CjguiComposableUiSelectionDecorationProvider {
    func acceptedSelectionDecoration(completion: CjguiInstalledSelectionCompletion):
        ?CjguiComposableUiSelectionDecoration
}

@When[os == "macOS"]
foreign func cjgui_internal_renderer_stage_accepted_selection_decoration(session: UInt64,
    transfer: UInt64, generation: UInt64, binding: UInt64, ownerVersion: Int64,
    ownerRevision: Int64, projection: Int64, scene: UInt64,
    red: Float64, green: Float64, blue: Float64, alpha: Float64,
    rows: CString, semantic: CPointer<UInt64>): Int32

@When[os == "macOS"]
func internalRendererStageAcceptedSelectionDecoration(session: UInt64,
    completion: CjguiInstalledSelectionCompletion, decoration: CjguiComposableUiSelectionDecoration,
    scene: Int64, mapping: String, nodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 {
    if (!decoration.matchesMapping(completion, scene, mapping) ||
        decoration.color.rejectionReason().isSome()) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    let rows = match (decoration.encodedNodeRanges()) { case Some(value) => value; case None => return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID }
    for (fragment in decoration.fragments) {
        var found = false
        for (node in nodes) {
            if (node.nodeId == fragment.nodeId) {
                if (node.nodeKind != CJGUI_COMPOSABLE_UI_TEXT || node.value != fragment.body) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
                found = true
                break
            }
        }
        if (!found) { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }
    }
    let t = completion.semantic; let selected = completion.sourceSelection
    let key = [completion.windowInstanceToken, completion.targetBindingEpoch,
        UInt64(t.contextEpoch), UInt64(t.mirrorRevision), UInt64(t.contentVersion), UInt64(t.sourceVersion),
        UInt64(t.selectionRevision), UInt64(selected.sessionEpoch), UInt64(selected.version),
        UInt64(selected.revision), UInt64(selected.anchorByte), UInt64(selected.focusByte)]
    let wire = unsafe { LibC.mallocCString(rows) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (resource = wire.asResource()) {
        status = unsafe {
            let data = acquireArrayRawData(key)
            try {
                cjgui_internal_renderer_stage_accepted_selection_decoration(session, completion.transferId,
                    completion.rendererSessionGeneration, completion.targetBindingEpoch,
                    completion.sourceOwnerVersion, selected.revision, decoration.projectionId, UInt64(scene),
                    decoration.color.red, decoration.color.green, decoration.color.blue, decoration.color.alpha,
                    resource.value, data.pointer)
            } finally { releaseArrayRawData(data) }
        }
    }
    return status
}

@When[os != "macOS"]
func internalRendererStageAcceptedSelectionDecoration(session: UInt64,
    completion: CjguiInstalledSelectionCompletion, decoration: CjguiComposableUiSelectionDecoration,
    scene: Int64, mapping: String, nodes: ArrayList<CjguiComposableUiLayoutNode>): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
