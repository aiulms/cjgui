package cjgui

// Internal copied ABI. No native object or borrowed pointer escapes a call.
@C
struct CjguiInternalPointerCaptureContinuationOffer {
    var gestureEpoch: UInt64 = 0
    var sessionGeneration: UInt64 = 0
    var windowInstanceToken: UInt64 = 0
    var coordinateGeneration: UInt64 = 0
    var originNodeId: UInt64 = 0
    var originResourceId: Int64 = -1
    var originNodeKind: UInt32 = 0
    var originProjectionVersion: UInt64 = 0
    var candidateSceneVersion: UInt64 = 0
    var viewportNodeId: UInt64 = 0
    var viewportResourceId: Int64 = -1
    var viewportNodeKind: UInt32 = 0
    var viewportBindingEpoch: UInt64 = 0
    var viewportIdentity: UInt64 = 0
    var requestGeneration: Int64 = 0
    var requestedOffset: Int64 = 0
    var acceptedOffset: Int64 = 0
    var selectionTransferId: UInt64 = 0
    var selectionReceiptSceneVersion: UInt64 = 0
    var selectionBindingEpoch: UInt64 = 0
    var proxyGeneration: UInt64 = 0
    var nativeSelectionRevision: UInt64 = 0
    var ownerVersion: Int64 = -1
    var ownerRevision: Int64 = -1
    var focusNodeId: UInt64 = 0
    var focusResourceId: Int64 = -1
    var focusNodeKind: UInt32 = 0
    var focusSemanticIncarnation: Int64 = 0
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_offer_pointer_capture_continuation(session: UInt64,
        offer: CPointer<CjguiInternalPointerCaptureContinuationOffer>): Int32
    func cjgui_internal_renderer_complete_pointer_capture_continuation(session: UInt64,
        gesture: UInt64, candidateScene: UInt64, transfer: UInt64, version: Int64, revision: Int64): Int32
    func cjgui_internal_renderer_discard_pointer_capture_continuation(session: UInt64,
        gesture: UInt64, candidateScene: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererOfferTextCaptureContinuation(session: UInt64, capture: CjguiMacTextCaptureFacts,
    completed: CjguiInstalledSelectionCompletion, record: CjguiComposableUiScrollBindingRecord,
    focus: CjguiComposableUiLayoutNode, oldScene: Int64, nextScene: Int64): Int32 {
    var offer = CjguiInternalPointerCaptureContinuationOffer()
    offer.gestureEpoch = capture.gestureEpoch
    offer.sessionGeneration = capture.nativeGeneration
    offer.windowInstanceToken = completed.windowInstanceToken
    offer.coordinateGeneration = capture.coordinateGeneration
    offer.originNodeId = UInt64(capture.node.nodeId); offer.originResourceId = capture.node.resourceId
    offer.originNodeKind = UInt32(capture.node.nodeKind); offer.originProjectionVersion = UInt64(oldScene)
    offer.candidateSceneVersion = UInt64(nextScene)
    offer.viewportNodeId = UInt64(record.nodeId); offer.viewportResourceId = record.resourceId
    offer.viewportNodeKind = UInt32(record.nodeKind); offer.viewportBindingEpoch = record.acceptedBindingEpoch
    offer.viewportIdentity = UInt64(record.viewportIdentity)
    offer.requestGeneration = record.viewport.requestGeneration()
    offer.requestedOffset = record.viewport.offset(); offer.acceptedOffset = record.viewport.acceptedOffset()
    offer.selectionTransferId = completed.transferId
    offer.selectionReceiptSceneVersion = UInt64(completed.targetSceneVersion)
    offer.selectionBindingEpoch = completed.targetBindingEpoch
    offer.proxyGeneration = completed.targetProxyGeneration
    offer.nativeSelectionRevision = completed.targetSelectionRevision
    offer.ownerVersion = completed.sourceSelection.version; offer.ownerRevision = completed.sourceSelection.revision
    offer.focusNodeId = UInt64(focus.nodeId); offer.focusResourceId = focus.resourceId
    offer.focusNodeKind = UInt32(focus.nodeKind); offer.focusSemanticIncarnation = focus.semanticIncarnation
    return unsafe { cjgui_internal_renderer_offer_pointer_capture_continuation(session, inout offer) }
}

@When[os != "macOS"]
func internalRendererOfferTextCaptureContinuation(session: UInt64, capture: CjguiMacTextCaptureFacts,
    completed: CjguiInstalledSelectionCompletion, record: CjguiComposableUiScrollBindingRecord,
    focus: CjguiComposableUiLayoutNode, oldScene: Int64, nextScene: Int64): Int32 {
    return CJGUI_INTERNAL_RENDERER_SCENE_STALE
}

@When[os == "macOS"]
func internalRendererCompleteTextCaptureContinuation(session: UInt64,
    continuation: CjguiMacTextPointerContinuation): Int32 {
    let chosen = continuation.completed.sourceSelection
    return unsafe { cjgui_internal_renderer_complete_pointer_capture_continuation(session,
        continuation.capture.gestureEpoch, UInt64(continuation.offeredScene),
        continuation.completed.transferId, chosen.version, chosen.revision) }
}
@When[os != "macOS"]
func internalRendererCompleteTextCaptureContinuation(session: UInt64,
    continuation: CjguiMacTextPointerContinuation): Int32 { return CJGUI_INTERNAL_RENDERER_SCENE_STALE }

@When[os == "macOS"]
func internalRendererDiscardTextCaptureContinuation(session: UInt64, gesture: UInt64, scene: Int64): Unit {
    let _ = unsafe { cjgui_internal_renderer_discard_pointer_capture_continuation(session, gesture, UInt64(scene)) }
}
@When[os != "macOS"]
func internalRendererDiscardTextCaptureContinuation(session: UInt64, gesture: UInt64, scene: Int64): Unit {}
