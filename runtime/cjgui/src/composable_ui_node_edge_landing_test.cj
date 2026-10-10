package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class NodeEdgeLandingController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9710, "node-edge-root", CjguiComposableUiStyle(gap: 0))
        root.add(cjguiComposableText(9711, "node-edge-source", "mmmmmmmm",
            CjguiComposableUiStyle(fixedWidth: 240, fontSize: 14.0)))
        root.add(cjguiComposableText(9712, "node-edge-target", "mmmm🙂mmmm\nmmmm🙂mmmm",
            CjguiComposableUiStyle(fixedWidth: 240, fontSize: 14.0)))
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

private func nodeEdgeLandingNode(window: CjguiComposableUiWindow, semanticId: String):
    CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) { return node }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// RED counterexample: ordinary vertical movement correctly stops at the end
/// of the source TEXT node, but the adjacent accepted TEXT still has a visual
/// row at the same preferred X. Cross-node landing must hit that row using its
/// own accepted layout identity.
@Test
func nodeEdgeLandingHitsPreferredXOnTargetLastVisualLine(): Unit {
    let window = CjguiComposableUiWindow(NodeEdgeLandingController())
    @Assert(window.start(), true)
    try {
        let targetText = "mmmm🙂mmmm\nmmmm🙂mmmm"
        let source = nodeEdgeLandingNode(window, "node-edge-source")
        let target = nodeEdgeLandingNode(window, "node-edge-target")
        @Assert(source.nodeId > 0, true)
        @Assert(target.nodeId > 0, true)
        let sourceStart = window.acceptedTextPosition(source.nodeId, 8)
        let sourceGoal = window.acceptedTextPosition(source.nodeId, 4)
        @Assert(sourceStart.status, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(sourceGoal.status, CJGUI_INTERNAL_RENDERER_OK)
        let oldMovement = window.verticalMoveOnAcceptedLayout(source.nodeId, 8, true,
            preferredX: sourceGoal.x, expectedText: "mmmmmmmm")
        var stoppedAtNodeEdge = false
        match (oldMovement) {
            case CjguiVerticalMoveResult.AtLineBoundary => stoppedAtNodeEdge = true
            case _ => ()
        }
        @Assert(stoppedAtNodeEdge, true)

        let landing = window.landingOnAcceptedNodeEdge(target.nodeId, true, sourceGoal.x, targetText)
        var landedByte: Int64 = -1
        match (landing) {
            case CjguiNodeEdgeLandingResult.Ready(byte, _, _) => landedByte = byte
            case _ => ()
        }
        // The first four glyphs share the source row's geometry. The byte
        // after those four m's is a UTF-8 boundary immediately before the emoji.
        @Assert(landedByte, 17)
        @Assert(cjguiIsUtf8Boundary(targetText.toArray(), landedByte), true)

        let firstLanding = window.landingOnAcceptedNodeEdge(target.nodeId, false, sourceGoal.x, targetText)
        var firstByte: Int64 = -1
        match (firstLanding) {
            case CjguiNodeEdgeLandingResult.Ready(byte, _, _) => firstByte = byte
            case _ => ()
        }
        @Assert(firstByte, 4)

        let stale = window.landingOnAcceptedNodeEdge(target.nodeId, false, sourceGoal.x, "stale text")
        var rejectedStaleText = false
        match (stale) {
            case CjguiNodeEdgeLandingResult.Rejected("text_binding_stale") => rejectedStaleText = true
            case _ => ()
        }
        @Assert(rejectedStaleText, true)
    } finally { window.close() }
}
