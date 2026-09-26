// A3: reveal resolves its scroll ANCESTORS by accepted identity, never by equal
// rectangles.
//
// The counterexample this file pins: two scroll areas that occupy EXACTLY the
// same rectangle and are NOT ancestors of one another. A target inside the first
// one must reveal through the first one only; the second one's request, offset
// and version must not move. Matching a viewport by an equal inner rectangle (the
// previous rule) matched both, because equal geometry is not evidence of
// containment.
package cjgui

import std.collection.*

private class OverlapRevealController <: CjguiComposableUiController {
    let viewportA: CjguiComposableUiScrollViewport
    let viewportB: CjguiComposableUiScrollViewport
    let targetScope = CjguiComposableUiIdentityScope("overlap-target")
    private var revision: Int64 = 1

    init(viewportA: CjguiComposableUiScrollViewport, viewportB: CjguiComposableUiScrollViewport) {
        this.viewportA = viewportA
        this.viewportB = viewportB
    }
    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let host = cjguiComposableLayerHost(1, "overlap-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        // The BASE is scroll area A and fills the host.
        let contentA = cjguiComposableVertical(10, "overlap-content-a", CjguiComposableUiStyle(gap: 0))
        var index: Int64 = 0
        while (index < 40) {
            if (index == 39) {
                contentA.add(CjguiComposableUiNode(100 + index, "overlap-target-row",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "目标", "", "", -1,
                    CjguiComposableUiStyle(fixedHeight: 24), identity: targetScope.local("row")))
            } else {
                contentA.add(cjguiComposableText(100 + index, "overlap-row-${index}", "行${index}",
                    CjguiComposableUiStyle(fixedHeight: 24)))
            }
            index += 1
        }
        let scrollA = cjguiComposableScrollArea(2, "overlap-scroll-a", viewportA,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        scrollA.add(contentA)
        host.add(scrollA)
        // A NON-modal layer resolves to the host's OWN rectangle (its requested
        // size is clamped to the host), so scroll area B is an exact rectangle
        // twin of A without being an ancestor of A's content.
        let layerStyle = CjguiComposableUiStyle(fixedWidth: 100000, fixedHeight: 100000)
        let layer = CjguiComposableUiNode(3, "overlap-layer-b", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
            layerStyle, layerId: "overlap-layer", layerKind: "popup", layerOwnerSemanticId: "overlap-host",
            layerAnchorSemanticId: "overlap-host", layerAnchorNodeId: -1)
        let contentB = cjguiComposableVertical(20, "overlap-content-b", CjguiComposableUiStyle(gap: 0))
        index = 0
        while (index < 40) {
            contentB.add(cjguiComposableText(200 + index, "overlap-b-row-${index}", "B${index}",
                CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let scrollB = cjguiComposableScrollArea(4, "overlap-scroll-b", viewportB,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        scrollB.add(contentB)
        layer.add(scrollB)
        host.add(layer)
        return host
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func overlapNodeBySemanticId(window: CjguiComposableUiWindow, semanticId: String):
    CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// The real counterexample: a reveal inside A must leave the exactly overlapping
/// sibling B completely untouched.
@Test
func revealFollowsAcceptedAncestorIdentityNotEqualRectangles(): Unit {
    let viewportA = CjguiComposableUiScrollViewport()
    let viewportB = CjguiComposableUiScrollViewport()
    let controller = OverlapRevealController(viewportA, viewportB)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let a = overlapNodeBySemanticId(window, "overlap-scroll-a")
    let b = overlapNodeBySemanticId(window, "overlap-scroll-b")
    @Assert(a.nodeId > 0, true)
    @Assert(b.nodeId > 0, true)
    // The two viewports really share x/y/width/height (and padding is zero on
    // both), so the previous rectangle rule could not tell them apart.
    @Assert(a.bounds.x, b.bounds.x)
    @Assert(a.bounds.y, b.bounds.y)
    @Assert(a.bounds.width, b.bounds.width)
    @Assert(a.bounds.height, b.bounds.height)
    @Assert(a.bounds.width > 0, true)
    @Assert(a.bounds.height > 0, true)
    // Both are at rest before the reveal.
    @Assert(viewportA.offset(), 0)
    @Assert(viewportB.offset(), 0)
    @Assert(viewportB.acceptedOffset(), 0)
    @Assert(viewportB.acceptedSolveCount() > 0, true)
    let bSolveCountBefore = viewportB.acceptedSolveCount()
    // The target is the LAST row of A's content, far below the visible band.
    @Assert(window.focusScopedNode(controller.targetScope, "row"), false)
    // A really revealed: its request moved toward the target.
    @Assert(viewportA.offset() > 0, true)
    @Assert(viewportA.hasPendingRequest(), true)
    // B was NOT touched: same request, same accepted offset, no new solve.
    @Assert(viewportB.offset(), 0)
    @Assert(viewportB.hasPendingRequest(), false)
    @Assert(viewportB.acceptedOffset(), 0)
    @Assert(viewportB.acceptedSolveCount(), bSolveCountBefore)
    // A rejected/absent target reveals nothing at all.
    @Assert(window.focusScopedNode(controller.targetScope, "missing-row"), false)
    @Assert(viewportA.offset() > 0, true)
    @Assert(viewportB.offset(), 0)
    window.close()
}

/// The same rule across a REAL clip chain: an inner scroll area inside an outer
/// one still reveals through both, innermost first, and the outer one only moves
/// when the inner one cannot make the target visible.
@Test
func revealWalksTheRealNestedClipChainInnermostFirst(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let controller = NestedRevealController(outer, inner)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(outer.offset(), 0)
    @Assert(inner.offset(), 0)
    @Assert(window.focusScopedNode(controller.targetScope, "row"), false)
    // The inner viewport reveals the row inside its own content.
    @Assert(inner.offset() > 0, true)
    // The outer viewport must not be dragged along while the inner one alone can
    // bring the target into the visible band: the target's band inside the outer
    // content is already the inner viewport's own rectangle.
    @Assert(outer.offset(), 0)
    @Assert(outer.hasPendingRequest(), false)
    window.close()
}

/// A direction-sensitive two-layer case. The inner reveal moves the target up
/// in the next accepted scene because layout applies `contentY - offset`. The
/// outer reveal must therefore consume the accepted-to-pending delta with the
/// same sign. A wrong `top += delta` propagation overscrolls the outer viewport
/// and leaves the target outside the real outer clip after the next commit.
@Test
func revealCoordinatesUseAcceptedToPendingDeltaForEveryAncestor(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let controller = CoordinatedRevealController(outer, inner)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(outer.offset(), 0)
    @Assert(inner.offset(), 0)
    @Assert(window.focusScopedNode(controller.targetScope, "row"), false)
    // Both real ancestors must carry a pending request before any new scene is
    // accepted. The target is below the inner clip and the inner clip itself is
    // initially below the outer clip.
    @Assert(inner.offset() > 0, true)
    @Assert(inner.hasPendingRequest(), true)
    @Assert(outer.offset() > 0, true)
    @Assert(outer.hasPendingRequest(), true)
    let innerPending = inner.offset()
    let outerPending = outer.offset()
    // The outer request is the amount needed after the inner pending movement,
    // rather than the amount computed from the old target position.
    @Assert(innerPending, 760)
    @Assert(outerPending, 272)

    // A rejected candidate keeps the old accepted scene and both pending
    // requests. The next legal candidate can still present those requests.
    controller.rejectNext()
    controller.bump()
    @Assert(window.refresh(), false)
    @Assert(outer.acceptedOffset(), 0)
    @Assert(inner.acceptedOffset(), 0)
    @Assert(outer.offset(), outerPending)
    @Assert(inner.offset(), innerPending)
    controller.bump()

    // A legal accepted scene presents both requests. All assertions below read
    // the accepted scene, including every real clip in the target's chain.
    @Assert(window.refresh(), true)
    let target = revealNodeBySemanticId(window, "coordinated-target-row")
    let innerNode = revealNodeBySemanticId(window, "coordinated-inner-scroll")
    let outerNode = revealNodeBySemanticId(window, "coordinated-outer-scroll")
    @Assert(target.nodeId > 0, true)
    @Assert(innerNode.nodeId > 0, true)
    @Assert(outerNode.nodeId > 0, true)
    let innerTop = innerNode.bounds.y + innerNode.style.padding
    let innerBottom = innerTop + innerNode.bounds.height - innerNode.style.padding * 2
    let outerTop = outerNode.bounds.y + outerNode.style.padding
    let outerBottom = outerTop + outerNode.bounds.height - outerNode.style.padding * 2
    @Assert(target.bounds.y >= innerTop, true)
    @Assert(target.bounds.y + target.bounds.height <= innerBottom, true)
    @Assert(target.bounds.y >= outerTop, true)
    @Assert(target.bounds.y + target.bounds.height <= outerBottom, true)
    @Assert(outer.acceptedOffset(), outerPending)
    @Assert(inner.acceptedOffset(), innerPending)

    // Repeating the same accepted focus is idempotent: neither accepted nor
    // requested state moves, and the already visible target is focused directly.
    let outerSolveCount = outer.acceptedSolveCount()
    let innerSolveCount = inner.acceptedSolveCount()
    @Assert(window.focusScopedNode(controller.targetScope, "row"), true)
    @Assert(outer.offset(), outerPending)
    @Assert(inner.offset(), innerPending)
    @Assert(outer.acceptedSolveCount(), outerSolveCount)
    @Assert(inner.acceptedSolveCount(), innerSolveCount)
    window.close()
}

/// An already pending inner request still changes the target's next accepted
/// coordinate even when the target is visible in the CURRENT accepted inner
/// clip. The outer decision must consume that pending shift before testing its
/// own clip, otherwise it reveals an outer viewport that the next scene does
/// not need to move.
@Test
func revealPropagatesAnExistingPendingInnerDeltaBeforeOuterVisibilityCheck(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let controller = CoordinatedRevealController(outer, inner)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(inner.requestOffset(100), true)
    @Assert(window.focusScopedNode(controller.pendingScope, "visible"), false)
    @Assert(inner.offset(), 100)
    @Assert(inner.acceptedOffset(), 0)
    // The accepted row is below outer's 120-point clip, but the pending inner
    // shift moves it up to y=92 in the next scene, so outer must stay at rest.
    @Assert(outer.offset(), 0)
    @Assert(outer.hasPendingRequest(), false)
    controller.bump()
    @Assert(window.refresh(), true)
    let target = revealNodeBySemanticId(window, "coordinated-pending-visible-row")
    let outerNode = revealNodeBySemanticId(window, "coordinated-outer-scroll")
    @Assert(outer.acceptedOffset(), 0)
    @Assert(inner.acceptedOffset(), 100)
    @Assert(target.bounds.y >= outerNode.bounds.y, true)
    @Assert(target.bounds.y + target.bounds.height <= outerNode.bounds.y + outerNode.bounds.height, true)
    window.close()
}

private func revealNodeBySemanticId(window: CjguiComposableUiWindow, semanticId: String):
    CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private class NestedRevealController <: CjguiComposableUiController {
    let outer: CjguiComposableUiScrollViewport
    let inner: CjguiComposableUiScrollViewport
    let targetScope = CjguiComposableUiIdentityScope("nested-target")
    private var revision: Int64 = 1

    init(outer: CjguiComposableUiScrollViewport, inner: CjguiComposableUiScrollViewport) {
        this.outer = outer
        this.inner = inner
    }
    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let outerContent = cjguiComposableVertical(50, "nested-outer-content", CjguiComposableUiStyle(gap: 0))
        outerContent.add(cjguiComposableText(51, "nested-pad-0", "上", CjguiComposableUiStyle(fixedHeight: 24)))
        let innerContent = cjguiComposableVertical(60, "nested-inner-content", CjguiComposableUiStyle(gap: 0))
        var index: Int64 = 0
        while (index < 40) {
            if (index == 39) {
                innerContent.add(CjguiComposableUiNode(300 + index, "nested-target-row",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "深层目标", "", "", -1,
                    CjguiComposableUiStyle(fixedHeight: 24), identity: targetScope.local("row")))
            } else {
                innerContent.add(cjguiComposableText(300 + index, "nested-row-${index}", "内${index}",
                    CjguiComposableUiStyle(fixedHeight: 24)))
            }
            index += 1
        }
        let innerScroll = cjguiComposableScrollArea(61, "nested-inner-scroll", inner,
            CjguiComposableUiStyle(fixedHeight: 200, growX: 1))
        innerScroll.add(innerContent)
        outerContent.add(innerScroll)
        let outerScroll = cjguiComposableScrollArea(40, "nested-outer-scroll", outer,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        outerScroll.add(outerContent)
        return outerScroll
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// The inner viewport is deliberately below a short outer viewport and has a
/// long tail after it. This keeps the wrong-sign outer request below its clamp,
/// so the resulting accepted bounds expose the direction error instead of
/// hiding it behind the outer maximum.
private class CoordinatedRevealController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let outer: CjguiComposableUiScrollViewport
    let inner: CjguiComposableUiScrollViewport
    let targetScope = CjguiComposableUiIdentityScope("coordinated-target")
    let pendingScope = CjguiComposableUiIdentityScope("coordinated-pending")
    private var revision: Int64 = 1
    private var rejectNextValue: Bool = false

    init(outer: CjguiComposableUiScrollViewport, inner: CjguiComposableUiScrollViewport) {
        this.outer = outer
        this.inner = inner
    }
    public func bump(): Unit {
        revision += 1
    }
    public func rejectNext(): Unit {
        rejectNextValue = true
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func beginSceneRefresh(): Bool {
        return true
    }
    public func prepareSceneRefresh(): Bool {
        if (rejectNextValue) {
            rejectNextValue = false
            return false
        }
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
    }
    public func rollbackSceneRefresh(): Unit {
    }
    public func buildUi(): CjguiComposableUiNode {
        let outerContent = cjguiComposableVertical(400, "coordinated-outer-content",
            CjguiComposableUiStyle(gap: 0))
        var spacer: Int64 = 0
        while (spacer < 8) {
            outerContent.add(cjguiComposableText(410 + spacer, "coordinated-spacer-${spacer}",
                "上${spacer}", CjguiComposableUiStyle(fixedHeight: 24)))
            spacer += 1
        }
        let innerContent = cjguiComposableVertical(500, "coordinated-inner-content",
            CjguiComposableUiStyle(gap: 0))
        var row: Int64 = 0
        while (row < 40) {
            if (row == 39) {
                innerContent.add(CjguiComposableUiNode(600 + row, "coordinated-target-row",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "协调目标", "", "", -1,
                    CjguiComposableUiStyle(fixedHeight: 24), identity: targetScope.local("row")))
            } else if (row == 0) {
                innerContent.add(CjguiComposableUiNode(600 + row, "coordinated-pending-visible-row",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "待呈现目标", "", "", -1,
                    CjguiComposableUiStyle(fixedHeight: 24), identity: pendingScope.local("visible")))
            } else {
                innerContent.add(cjguiComposableText(600 + row, "coordinated-row-${row}",
                    "内${row}", CjguiComposableUiStyle(fixedHeight: 24)))
            }
            row += 1
        }
        let innerScroll = cjguiComposableScrollArea(501, "coordinated-inner-scroll", inner,
            CjguiComposableUiStyle(fixedHeight: 200, growX: 1))
        innerScroll.add(innerContent)
        outerContent.add(innerScroll)
        var tail: Int64 = 0
        while (tail < 30) {
            outerContent.add(cjguiComposableText(700 + tail, "coordinated-tail-${tail}",
                "下${tail}", CjguiComposableUiStyle(fixedHeight: 24)))
            tail += 1
        }
        let outerScroll = cjguiComposableScrollArea(401, "coordinated-outer-scroll", outer,
            CjguiComposableUiStyle(fixedHeight: 120, growX: 1))
        outerScroll.add(outerContent)
        let root = cjguiComposableVertical(390, "coordinated-root",
            CjguiComposableUiStyle(growX: 1, growY: 1))
        root.add(outerScroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}
