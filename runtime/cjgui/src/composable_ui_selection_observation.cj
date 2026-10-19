package cjgui

/// Experimental, bounded, read-only expectation. This is neither an installed
/// selection receipt nor authority to edit. The original choice remains fixed
/// while its scene is being prepared; callers never replace it with live data.
public class CjguiSelectionGeometryRequest {
    public let window: Int64
    public let binding: UInt64
    public let nodeId: Int64
    public let resourceId: Int64
    public let nodeKind: Int64
    public let semantic: CjguiTextSelectionTicket
    public let source: ?CjguiSourceSelectionSnapshot
    public let mirror: CjguiTextSessionMirrorSnapshot
    public let anchorByte: Int64
    public let focusByte: Int64
    public let anchor16: Int64
    public let focus16: Int64
    init(window: Int64, binding: UInt64, nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        semantic: CjguiTextSelectionTicket, source: ?CjguiSourceSelectionSnapshot,
        mirror: CjguiTextSessionMirrorSnapshot, anchorByte: Int64, focusByte: Int64,
        anchor16: Int64, focus16: Int64) {
        this.window = window; this.binding = binding; this.nodeId = nodeId
        this.resourceId = resourceId; this.nodeKind = nodeKind; this.semantic = semantic
        this.source = source; this.mirror = mirror; this.anchorByte = anchorByte
        this.focusByte = focusByte; this.anchor16 = anchor16; this.focus16 = focus16
    }
}

func cjguiSameSelectionGeometryRequest(a: CjguiSelectionGeometryRequest,
    b: CjguiSelectionGeometryRequest): Bool {
    if (a.window != b.window || a.binding != b.binding || a.nodeId != b.nodeId ||
        a.resourceId != b.resourceId || a.nodeKind != b.nodeKind ||
        a.semantic.contextEpoch != b.semantic.contextEpoch ||
        a.semantic.mirrorRevision != b.semantic.mirrorRevision ||
        a.semantic.contentVersion != b.semantic.contentVersion ||
        a.semantic.sourceVersion != b.semantic.sourceVersion ||
        a.semantic.selectionRevision != b.semantic.selectionRevision ||
        a.mirror.startByte != b.mirror.startByte || a.mirror.text != b.mirror.text ||
        a.mirror.sourceByteLength != b.mirror.sourceByteLength ||
        a.anchorByte != b.anchorByte || a.focusByte != b.focusByte ||
        a.anchor16 != b.anchor16 || a.focus16 != b.focus16) { return false }
    return match ((a.source, b.source)) {
        case (Some(x), Some(y)) => cjguiSameSourceChoice(x, y)
        case (None, None) => true
        case _ => false
    }
}

// Selection-only revisions may reuse pixels. Mirror, owner, mount and binding
// changes may not silently reuse a former native basis, even for equal strings.
func cjguiSelectionGeometryCanReuse(a: ?CjguiSelectionGeometryRequest,
    b: ?CjguiSelectionGeometryRequest): Bool {
    if (a.isNone() || b.isNone()) { return a.isNone() && b.isNone() }
    let x = a.getOrThrow(); let y = b.getOrThrow()
    if (x.window != y.window || x.binding != y.binding || x.nodeId != y.nodeId ||
        x.resourceId != y.resourceId || x.nodeKind != y.nodeKind ||
        x.semantic.contextEpoch != y.semantic.contextEpoch ||
        x.semantic.mirrorRevision != y.semantic.mirrorRevision ||
        x.semantic.contentVersion != y.semantic.contentVersion ||
        x.semantic.sourceVersion != y.semantic.sourceVersion ||
        x.mirror.startByte != y.mirror.startByte || x.mirror.text != y.mirror.text ||
        x.mirror.sourceByteLength != y.mirror.sourceByteLength) { return false }
    return match ((x.source, y.source)) {
        case (Some(p), Some(q)) => p.documentId == q.documentId &&
            p.sessionEpoch == q.sessionEpoch && p.viewGeneration == q.viewGeneration && p.version == q.version
        case (None, None) => true
        case _ => false
    }
}

class CjguiAcceptedSelectionGeometry {
    let request: CjguiSelectionGeometryRequest
    let scene: Int64
    let resize: UInt64
    let transform: Int64
    let nativeBinding: UInt64
    let nativeLayoutLease: UInt64
    init(request: CjguiSelectionGeometryRequest, scene: Int64, resize: UInt64, transform: Int64, nativeBinding: UInt64, nativeLayoutLease!: UInt64 = 0u64) {
        this.request = request; this.scene = scene; this.resize = resize; this.transform = transform
        this.nativeBinding = nativeBinding; this.nativeLayoutLease = nativeLayoutLease
    }
}

/// Ready contains one actual accepted layout position. Pending contains only
/// the original expectation. A named refusal never returns a zero rectangle.
public class CjguiSelectionGeometryObservation {
    public let reason: String
    public let request: CjguiSelectionGeometryRequest
    public let position: ?CjguiAcceptedTextPosition
    public let screenX: Float64
    public let screenY: Float64
    public let dpi: UInt64
    public let bodyHash: UInt64
    public let nativeRange: Array<UInt64>
    public let visibleBounds: Array<Float64>
    init(reason: String, request: CjguiSelectionGeometryRequest,
        position!: ?CjguiAcceptedTextPosition = None,
        screenX!: Float64 = 0.0, screenY!: Float64 = 0.0, dpi!: UInt64 = 0u64,
        bodyHash!: UInt64 = 0u64, nativeRange!: Array<UInt64> = [],
        visibleBounds!: Array<Float64> = []) {
        this.reason = reason; this.request = request; this.position = position
        this.screenX = screenX; this.screenY = screenY; this.dpi = dpi
        this.bodyHash = bodyHash; this.nativeRange = nativeRange; this.visibleBounds = visibleBounds
    }
}

@When[os == "Windows"]
foreign func cjgui_internal_renderer_selection_reveal_accepted(session: UInt64,
    identity: CPointer<UInt64>, body: CString, focusByte: Int64, retainedLease: UInt64,
    changed: CPointer<UInt8>, layoutLease: CPointer<UInt64>): Int32

@When[os == "Windows"]
func cjguiRevealAcceptedSelectionNative(session: UInt64, accepted: CjguiAcceptedSelectionGeometry,
    retainedLease: UInt64): (Int32, Bool, UInt64) {
    let r = accepted.request
    let identity = [UInt64(accepted.scene), UInt64(r.nodeId), UInt64(r.resourceId),
        UInt64(r.nodeKind), accepted.nativeBinding, accepted.resize, UInt64(r.mirror.startByte),
        UInt64(r.mirror.startByte + r.mirror.text.size), UInt64(r.semantic.contextEpoch),
        UInt64(r.semantic.mirrorRevision), UInt64(r.semantic.contentVersion), UInt64(r.window)]
    var changed: UInt8 = 0u8
    var layoutLease: UInt64 = 0u64
    let status = unsafe {
        let i = acquireArrayRawData(identity)
        let body = LibC.mallocCString(r.mirror.text)
        let result = cjgui_internal_renderer_selection_reveal_accepted(session, i.pointer, body,
            r.focusByte - r.mirror.startByte, retainedLease, inout changed, inout layoutLease)
        LibC.free(body); releaseArrayRawData(i)
        result
    }
    return (status, changed != 0u8, layoutLease)
}
@When[os != "Windows"]
func cjguiRevealAcceptedSelectionNative(session: UInt64, accepted: CjguiAcceptedSelectionGeometry,
    retainedLease: UInt64): (Int32, Bool, UInt64) {
    return (CJGUI_INTERNAL_RENDERER_OK, false, 0u64)
}

@When[os == "Windows"]
foreign func cjgui_internal_renderer_selection_position_viewport_readonly(session: UInt64,
    identity: CPointer<UInt64>, body: CString, byte: Int64,
    meta: CPointer<UInt64>, rect: CPointer<Float64>): Int32

@When[os == "Windows"]
func cjguiReadSelectionGeometryNative(session: UInt64, accepted: CjguiAcceptedSelectionGeometry,
    nodeBinding: UInt64, byte: Int64): (CjguiAcceptedTextPosition, Array<Float64>, UInt64, UInt64, Array<UInt64>) {
    let r = accepted.request
    let identity = [UInt64(accepted.scene), UInt64(r.nodeId), UInt64(r.resourceId),
        UInt64(r.nodeKind), nodeBinding, accepted.resize, UInt64(r.mirror.startByte),
        UInt64(r.mirror.startByte + r.mirror.text.size), UInt64(r.semantic.contextEpoch),
        UInt64(r.semantic.mirrorRevision), UInt64(r.semantic.contentVersion), UInt64(r.window)]
    let meta = Array<UInt64>(21, repeat: 0u64)
    let rect = Array<Float64>(10, repeat: 0.0)
    let status = unsafe {
        let i = acquireArrayRawData(identity)
        let m = acquireArrayRawData(meta)
        let p = acquireArrayRawData(rect)
        let body = LibC.mallocCString(r.mirror.text)
        let result = cjgui_internal_renderer_selection_position_viewport_readonly(session, i.pointer, body,
            byte, m.pointer, p.pointer)
        LibC.free(body)
        releaseArrayRawData(p); releaseArrayRawData(m); releaseArrayRawData(i)
        result
    }
    return (CjguiAcceptedTextPosition(status, r.nodeId, UInt64(accepted.scene), meta, rect), rect, meta[8], meta[9], meta[10..21])
}

@When[os != "Windows"]
func cjguiReadSelectionGeometryNative(session: UInt64, accepted: CjguiAcceptedSelectionGeometry,
    nodeBinding: UInt64, byte: Int64): (CjguiAcceptedTextPosition, Array<Float64>, UInt64, UInt64, Array<UInt64>) {
    let meta = Array<UInt64>(8, repeat: 0u64)
    let rect = Array<Float64>(10, repeat: 0.0)
    return (CjguiAcceptedTextPosition(CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED,
        accepted.request.nodeId, UInt64(accepted.scene), meta, rect), rect, 0u64, 0u64, [])
}
