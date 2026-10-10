package cjgui

import std.collection.*

// The synchronous pointer callback may submit a retained source selection.
// Capture its provenance here, before that callback. Completion must carry
// this value; observing a later active gesture cannot manufacture it.
class CjguiMacTextPointerSelectionDispatch {
    let capture: CjguiMacTextCaptureFacts
    let sequence: UInt64
    let eventKind: Int64
    let previousChoice: CjguiSourceSelectionSnapshot
    // A mapped reinstall may retain this dispatch only by freezing the actual
    // predecessor installation at request admission. It is not a new input.
    let reinstallationSource: ?CjguiInstalledSelectionCompletion
    // A reinstall retains the physical dispatch unchanged. Its current lease
    // can only be the successor frozen after native continuation completed.
    let installedCapture: ?CjguiMacTextCaptureFacts
    init(capture: CjguiMacTextCaptureFacts, sequence: UInt64, eventKind: Int64,
        choice: CjguiSourceSelectionSnapshot,
        reinstallationSource!: ?CjguiInstalledSelectionCompletion = None,
        installedCapture!: ?CjguiMacTextCaptureFacts = None) {
        this.capture = capture; this.sequence = sequence; this.eventKind = eventKind; this.previousChoice = choice
        this.reinstallationSource = reinstallationSource
        this.installedCapture = installedCapture
    }
}

class CjguiMacTextPointerContinuation {
    let dispatch: CjguiMacTextPointerSelectionDispatch
    let capture: CjguiMacTextCaptureFacts
    let completed: CjguiInstalledSelectionCompletion
    let targetRevision: Int64
    var offeredScene: Int64 = -1
    init(dispatch: CjguiMacTextPointerSelectionDispatch, completed: CjguiInstalledSelectionCompletion,
        targetRevision: Int64, acceptedCapture!: ?CjguiMacTextCaptureFacts = None) {
        this.dispatch = dispatch; this.completed = completed; this.targetRevision = targetRevision
        this.capture = acceptedCapture ?? dispatch.installedCapture ?? dispatch.capture
    }
}

func cjguiSameSourceChoice(a: CjguiSourceSelectionSnapshot, b: CjguiSourceSelectionSnapshot): Bool {
    return a.documentId == b.documentId && a.sessionEpoch == b.sessionEpoch &&
        a.viewGeneration == b.viewGeneration && a.version == b.version && a.revision == b.revision &&
        a.anchorByte == b.anchorByte && a.focusByte == b.focusByte
}

// Private mac queued-TEXT capture facts. One original accepted target, bounded
// arrays, no owner body materialization or native object in the public API.
func cjguiFreezeMacCaptureStyle(style: CjguiComposableUiStyle): CjguiComposableUiStyle {
    var gradient: ?CjguiComposableUiLinearGradient = None
    if (let Some(g) <- style.gradient) {
        gradient = Some(CjguiComposableUiLinearGradient(startX: g.startX, startY: g.startY,
            endX: g.endX, endY: g.endY,
            stops: Array<CjguiComposableUiGradientStop>(g.stops.size, { i => g.stops[i] })))
    }
    var effect: ?CjguiComposableUiEffectGroup = None
    if (let Some(e) <- style.effectGroup) {
        var mask: ?CjguiComposableUiLinearAlphaMask = None
        if (let Some(m) <- e.mask) {
            mask = Some(CjguiComposableUiLinearAlphaMask(startX: m.startX, startY: m.startY,
                endX: m.endX, endY: m.endY,
                stops: Array<CjguiComposableUiAlphaMaskStop>(m.stops.size, { i => m.stops[i] })))
        }
        effect = Some(CjguiComposableUiEffectGroup(opacity: e.opacity, blendMode: e.blendMode,
            mask: mask, backdropBlurRadiusPoints: e.backdropBlurRadiusPoints,
            backdropBlurFallback: e.backdropBlurFallback))
    }
    return CjguiComposableUiStyle(
        background: style.background,
        border: style.border,
        textColor: style.textColor,
        padding: style.padding,
        gap: style.gap,
        fixedWidth: style.fixedWidth,
        fixedHeight: style.fixedHeight,
        growX: style.growX,
        growY: style.growY,
        borderWidth: style.borderWidth,
        cornerRadius: style.cornerRadius,
        clipsContent: style.clipsContent,
        pointerInteractive: style.pointerInteractive,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontFamily: style.fontFamily,
        minWidth: style.minWidth,
        maxWidth: style.maxWidth,
        idealWidth: style.idealWidth,
        minHeight: style.minHeight,
        maxHeight: style.maxHeight,
        idealHeight: style.idealHeight,
        alignX: style.alignX,
        alignY: style.alignY,
        offsetX: style.offsetX,
        offsetY: style.offsetY,
        translateX: style.translateX,
        translateY: style.translateY,
        wheelScrollable: style.wheelScrollable,
        scrollContentAlignY: style.scrollContentAlignY,
        shadow: style.shadow,
        gradient: gradient,
        effectGroup: effect,
        effectRejection: style.effectRejection)
}

// One immutable accepted scroll ancestry. Requested offsets are never proof.
// Multiple ancestors remain fail-closed until their motion can be composed.
class CjguiMacTextCaptureScrollFacts {
    let binding: CjguiComposableUiScrollBindingRecord
    let ownerWindow: Int64
    let offset: Int64
    let contentExtent: Int64
    let viewportExtent: Int64
    let containerBounds: CjguiComposableUiRect
    init(binding: CjguiComposableUiScrollBindingRecord, container: CjguiComposableUiLayoutNode) {
        this.binding = binding
        this.ownerWindow = binding.viewport.ownerWindowToken()
        this.offset = binding.viewport.acceptedOffset()
        this.contentExtent = binding.viewport.contentExtent()
        this.viewportExtent = binding.viewport.viewportExtent()
        this.containerBounds = container.bounds
    }
}

class CjguiMacTextCaptureFacts {
    let serial: UInt64
    let node: CjguiComposableUiLayoutNode
    let style: CjguiComposableUiStyle
    let declaredStyle: CjguiComposableUiStyle
    let runs: Array<CjguiComposableUiTextStyleRun>
    let geometry: CjguiComposableUiVisualGeometry
    let viewport: CjguiComposableUiRect
    let ownerRevision: Int64
    let bindingEpoch: UInt64
    let gestureEpoch: UInt64
    let nativeSession: UInt64
    let nativeGeneration: UInt64
    let coordinateGeneration: UInt64
    let modalLayer: String
    let clipOwners: ArrayList<CjguiComposableUiLayoutNode>
    let clipEpochs: ArrayList<UInt64>
    let scroll: ?CjguiMacTextCaptureScrollFacts
    let acceptedScenes = ArrayList<Int64>()
    var revokedReason: String = ""
    init(serial: UInt64, node: CjguiComposableUiLayoutNode,
        geometry: CjguiComposableUiVisualGeometry, viewport: CjguiComposableUiRect,
        ownerRevision: Int64, bindingEpoch: UInt64, gestureEpoch: UInt64,
        nativeSession: UInt64, nativeGeneration: UInt64, coordinateGeneration: UInt64,
        modalLayer: String, clipOwners: ArrayList<CjguiComposableUiLayoutNode>,
        clipEpochs: ArrayList<UInt64>, scene: Int64,
        scroll!: ?CjguiMacTextCaptureScrollFacts = None) {
        this.serial = serial
        this.node = node
        this.style = cjguiFreezeMacCaptureStyle(node.style)
        this.declaredStyle = cjguiFreezeMacCaptureStyle(node.declaredStyle)
        this.runs = Array<CjguiComposableUiTextStyleRun>(node.textStyleRuns.size,
            { i => node.textStyleRuns[i] })
        this.geometry = geometry
        this.viewport = viewport
        this.ownerRevision = ownerRevision
        this.bindingEpoch = bindingEpoch
        this.gestureEpoch = gestureEpoch
        this.nativeSession = nativeSession
        this.nativeGeneration = nativeGeneration
        this.coordinateGeneration = coordinateGeneration
        this.modalLayer = modalLayer
        this.clipOwners = ArrayList<CjguiComposableUiLayoutNode>(clipOwners)
        this.clipEpochs = ArrayList<UInt64>(clipEpochs)
        this.scroll = scroll
        acceptedScenes.add(scene)
    }
    func revoke(reason: String): Unit {
        if (revokedReason.size == 0) { revokedReason = reason }
    }
    func certify(scene: Int64): Bool {
        if (revokedReason.size > 0 || scene < acceptedScenes[acceptedScenes.size - 1]) {
            revoke("accepted_scene_regression")
            return false
        }
        if (scene == acceptedScenes[acceptedScenes.size - 1]) { return true }
        if (acceptedScenes.size >= 1024) {
            revoke("accepted_scene_capacity")
            return false
        }
        acceptedScenes.add(scene)
        return true
    }
    func containsScene(scene: Int64): Bool {
        if (revokedReason.size > 0) { return false }
        for (accepted in acceptedScenes) { if (accepted == scene) { return true } }
        return false
    }
}

// One accepted publication's immutable owner/mapping/geometry facts. Native
// BEGIN receipts pin only the frames they actually reference, not all redraws.
class CjguiMacTextPointerBeginFrame {
    let publication: UInt64
    let scene: Int64
    let targets: ArrayList<CjguiMacTextCaptureFacts>
    init(publication: UInt64, scene: Int64, targets: ArrayList<CjguiMacTextCaptureFacts>) {
        this.publication = publication; this.scene = scene; this.targets = targets
    }
}
