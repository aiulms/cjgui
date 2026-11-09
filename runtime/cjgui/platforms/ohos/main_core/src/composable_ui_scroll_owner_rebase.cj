package cjgui

// Per-viewport identity of the actual range source installed in its accepted
// subtree. This is an owner binding stamp, not another selection or anchor store.
class CjguiScrollOriginSourceContext {
    let selected: CjguiSourceSelectionSnapshot
    let contextEpoch: Int64
    let bindingEpoch: UInt64
    init(selected: CjguiSourceSelectionSnapshot, contextEpoch: Int64, bindingEpoch: UInt64) {
        this.selected = selected; this.contextEpoch = contextEpoch; this.bindingEpoch = bindingEpoch
    }
    func matches(session: CjguiTextSession, binding: UInt64): Bool {
        let current = match (session.sourceSelectionSnapshot()) { case Some(value) => value; case None => return false }
        return session.isBound() && session.contextEpochValue() == contextEpoch && binding == bindingEpoch &&
            current.documentId == selected.documentId && current.sessionEpoch == selected.sessionEpoch &&
            current.viewGeneration == selected.viewGeneration
    }
}

class CjguiScrollOriginRebaseLifetime {
    var active: Bool = true
}

/// Experimental reading-position proof. The old accepted geometry remains an
/// old-version fact. Only the bound range source can supply its new source point.
/// It grants no input, native installation, caret or navigation authority.
public class CjguiComposableUiScrollOriginOwnerRebase {
    public let sourceByte: Int64
    public let targetByte: Int64
    public let targetBinding: CjguiComposableUiScrollOriginBinding
    let anchor: CjguiComposableUiScrollOriginAnchor
    let targetNodeId: Int64
    let targetLocalByte: Int64
    private let currentSource: () -> Bool
    private let lifetime: CjguiScrollOriginRebaseLifetime
    init(anchor: CjguiComposableUiScrollOriginAnchor, target: CjguiComposableUiScrollOriginBinding,
        sourceByte: Int64, targetByte: Int64, currentSource: () -> Bool,
        targetNodeId!: Int64 = -1, targetLocalByte!: Int64 = -1,
        lifetime!: ?CjguiScrollOriginRebaseLifetime = None) {
        this.anchor = anchor; this.targetBinding = target; this.sourceByte = sourceByte
        this.targetByte = targetByte; this.currentSource = currentSource
        this.targetNodeId = targetNodeId; this.targetLocalByte = targetLocalByte
        this.lifetime = match (lifetime) { case Some(value) => value; case None => CjguiScrollOriginRebaseLifetime() }
    }
    func forTarget(node: Int64, local: Int64): CjguiComposableUiScrollOriginOwnerRebase {
        return CjguiComposableUiScrollOriginOwnerRebase(anchor, targetBinding, sourceByte, targetByte,
            currentSource, targetNodeId: node, targetLocalByte: local, lifetime: Some(lifetime))
    }
    func isCurrent(): Bool { return lifetime.active && currentSource() }
    func retire(): Unit { lifetime.active = false }
    func matches(ticket: CjguiComposableUiScrollOriginAnchor,
        target: CjguiComposableUiScrollOriginBinding, node: Int64, local: Int64): Bool {
        return sourceByte >= 0 && targetByte >= 0 && target.ownerVersion > ticket.acceptedBinding.ownerVersion &&
            targetBinding.matches(target) && anchor.acceptedBinding.matches(ticket.acceptedBinding) &&
            anchor.viewportIdentity == ticket.viewportIdentity && anchor.windowToken == ticket.windowToken &&
            anchor.acceptedSolve == ticket.acceptedSolve && anchor.requestGeneration == ticket.requestGeneration &&
            anchor.sourceAnchor == ticket.sourceAnchor && anchor.nodeId == ticket.nodeId &&
            anchor.localByte == ticket.localByte && targetNodeId == node && targetLocalByte == local &&
            local == ticket.localByte && isCurrent()
    }
}

func cjguiRebaseScrollOriginFromSource(viewport: CjguiComposableUiScrollViewport,
    anchor: CjguiComposableUiScrollOriginAnchor, target: CjguiComposableUiScrollOriginBinding,
    sourceByte: Int64, session: CjguiTextSession, bindingEpoch: UInt64,
    windowCurrent: () -> Bool): ?CjguiComposableUiScrollOriginOwnerRebase {
    let accepted = match (viewport.acceptedCoordinateOrigin()) { case Some(value) => value; case None => return None }
    let source = match (viewport.acceptedOriginSourceContext()) { case Some(value) => value; case None => return None }
    if (!windowCurrent() || !source.matches(session, bindingEpoch) || sourceByte < 0 ||
        !accepted.matches(anchor.acceptedBinding) || source.selected.version != accepted.ownerVersion ||
        target.ownerIdentity != accepted.ownerIdentity || target.ownerVersion <= accepted.ownerVersion ||
        anchor.viewportIdentity != viewport.viewStateIdentity() || anchor.windowToken != viewport.ownerWindowToken() ||
        anchor.acceptedSolve != viewport.acceptedSolveCount() || anchor.requestGeneration != viewport.requestGeneration() ||
        anchor.acceptedOffset != viewport.acceptedOffset() || anchor.requestedOffset != viewport.offset()) { return None }
    let rebased = match (session.rebaseReadingAnchorPoint(accepted.ownerVersion, sourceByte, target.ownerVersion)) {
        case Some(value) => value; case None => return None
    }
    let selected = rebased[0]
    if (selected.documentId != source.selected.documentId || selected.sessionEpoch != source.selected.sessionEpoch ||
        selected.viewGeneration != source.selected.viewGeneration) { return None }
    let context = session.contextEpochValue()
    let current = { => windowCurrent() && session.readingAnchorOwnerIsCurrent(selected, context) }
    if (!current()) { return None }
    return Some(CjguiComposableUiScrollOriginOwnerRebase(anchor, target, sourceByte, rebased[1], current))
}
