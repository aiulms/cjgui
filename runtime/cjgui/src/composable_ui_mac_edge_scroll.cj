package cjgui

// Frozen at the phase1 ACK which starts this exact native request. A later
// failure never reconstructs its generation or coordinates from a viewport.
class CjguiMacDragEdgeAwaitedViewport {
    let session: UInt64
    let gesture: UInt64
    let record: CjguiComposableUiScrollBindingRecord
    let scene: Int64
    let generation: Int64
    let requested: Int64
    let accepted: Int64
    init(session: UInt64, gesture: UInt64, record: CjguiComposableUiScrollBindingRecord, scene: Int64) {
        this.session = session; this.gesture = gesture; this.record = record; this.scene = scene
        this.generation = record.viewport.requestGeneration()
        this.requested = record.viewport.offset()
        this.accepted = record.viewport.acceptedOffset()
    }
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_ack_drag_edge_viewport(session: UInt64, gesture: UInt64,
        node: UInt64, resource: Int64, binding: UInt64, identity: UInt64,
        requestGeneration: Int64, requested: Int64, accepted: Int64, scene: UInt64, phase: UInt32): Int32
}
@When[os == "macOS"]
func internalRendererAckDragEdgeViewport(session: UInt64, gesture: UInt64,
    record: CjguiComposableUiScrollBindingRecord, scene: Int64, phase: UInt32): Int32 {
    let viewport = record.viewport
    return unsafe { cjgui_internal_renderer_ack_drag_edge_viewport(session, gesture,
        UInt64(record.nodeId), record.resourceId, record.acceptedBindingEpoch,
        UInt64(record.viewportIdentity), viewport.requestGeneration(), viewport.offset(),
        viewport.acceptedOffset(), UInt64(scene), phase) }
}
@When[os != "macOS"]
func internalRendererAckDragEdgeViewport(session: UInt64, gesture: UInt64,
    record: CjguiComposableUiScrollBindingRecord, scene: Int64, phase: UInt32): Int32 {
    return CJGUI_INTERNAL_RENDERER_OK
}

@When[os == "macOS"]
func internalRendererTerminateDragEdgeRequest(ticket: CjguiMacDragEdgeAwaitedViewport): Int32 {
    let record = ticket.record
    return unsafe { cjgui_internal_renderer_ack_drag_edge_viewport(ticket.session, ticket.gesture,
        UInt64(record.nodeId), record.resourceId, record.acceptedBindingEpoch,
        UInt64(record.viewportIdentity), ticket.generation, ticket.requested,
        ticket.accepted, UInt64(ticket.scene), 5u32) }
}
@When[os != "macOS"]
func internalRendererTerminateDragEdgeRequest(ticket: CjguiMacDragEdgeAwaitedViewport): Int32 {
    return CJGUI_INTERNAL_RENDERER_OK
}
