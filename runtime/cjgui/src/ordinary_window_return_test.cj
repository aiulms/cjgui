package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryReturnController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableVertical(1, "ordinary-return-root", CjguiComposableUiStyle())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func ordinaryReturnNode(incarnation!: Int64 = 1, field!: String = "name",
    owner!: Int64 = 41, enabled!: Bool = true, readOnly!: Bool = false,
    body!: String = "before"): CjguiComposableUiLayoutNode {
    let node = CjguiComposableUiNode(99101, "ordinary-return-editor", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        "Name", body, "", 4101, CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 36),
        semanticIncarnation: incarnation, fieldId: field, operationResourceId: owner,
        operationActionName: "EDIT", enabled: enabled, readOnly: readOnly)
    let rect = CjguiComposableUiRect(0, 0, 220, 36)
    return CjguiComposableUiLayoutNode(node, rect, rect)
}

@Test
func ordinaryEditingReturnRejectsReboundOwnerAndIncarnation(): Unit {
    let before = ordinaryReturnNode()
    for (after in [ordinaryReturnNode(incarnation: 2), ordinaryReturnNode(field: "other"),
        ordinaryReturnNode(owner: 42)]) {
        let window = CjguiComposableUiWindow(OrdinaryReturnController())
        @Assert(window.testEditingReturnAfterAcceptedScene(before, Some(after)), false)
    }
}

@Test
func ordinaryEditingReturnKeepsCurrentBodyButRejectsUnavailableOrReopened(): Unit {
    let before = ordinaryReturnNode()
    let valid = CjguiComposableUiWindow(OrdinaryReturnController())
    @Assert(valid.testEditingReturnAfterAcceptedScene(before, Some(ordinaryReturnNode(body: "owner changed"))), true)
    let missing: ?CjguiComposableUiLayoutNode = None
    for (after in [missing, Some(ordinaryReturnNode(enabled: false))]) {
        let window = CjguiComposableUiWindow(OrdinaryReturnController())
        @Assert(window.testEditingReturnAfterAcceptedScene(before, after), false)
    }
    // Read-only input is still a legal selection/copy focus under the existing
    // canReceiveFocus contract; availability and edit permission differ.
    let readOnly = CjguiComposableUiWindow(OrdinaryReturnController())
    @Assert(readOnly.testEditingReturnAfterAcceptedScene(before, Some(ordinaryReturnNode(readOnly: true))), true)
    let reopened = CjguiComposableUiWindow(OrdinaryReturnController())
    @Assert(reopened.testEditingReturnAfterAcceptedScene(before, Some(before), newSession: true), false)
}

@Test
func scopedEditingReturnReferenceCanPrepareTheNextDialog(): Unit {
    let window = CjguiComposableUiWindow(OrdinaryReturnController())
    @Assert(window.testScopedFocusReturnCandidate(true), "")
}

@Test
func scopedFocusedReturnReferenceCanPrepareTheNextDialog(): Unit {
    let window = CjguiComposableUiWindow(OrdinaryReturnController())
    @Assert(window.testScopedFocusReturnCandidate(false), "")
}

@Test
func scopedFocusReturnReferenceFollowsAcceptedIdentityLifetime(): Unit {
    let registry = CjguiComposableUiIdentityRegistry()
    let scope = CjguiComposableUiIdentityScope("return-lifetime")
    let root = cjguiComposableVertical(701, "return-lifetime-root", CjguiComposableUiStyle())
    let field = CjguiComposableUiNode(-1, "return-lifetime-field", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        "Name", "Body", "", 7101, CjguiComposableUiStyle(), identity: Some(scope.local("field")))
    root.add(field)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(root), "")
    @Assert(registry.prepareCandidate(), true)
    registry.commitCandidate()
    let oldId = field.nodeId
    let reference = registry.referenceForAcceptedNode(oldId).getOrThrow()
    @Assert(reference.scopedIdentity().getOrThrow().canonicalKey(), scope.local("field").canonicalKey())
    // A rejected duplicate declaration cannot replace the accepted bookmark.
    let rejected = cjguiComposableVertical(702, "return-lifetime-rejected", CjguiComposableUiStyle())
    rejected.add(field)
    rejected.add(field)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(rejected).startsWith("identity_duplicate"), true)
    registry.rollbackCandidate()
    @Assert(registry.referenceForAcceptedNode(oldId).isSome(), true)
    let empty = cjguiComposableVertical(703, "return-lifetime-empty", CjguiComposableUiStyle())
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(empty), "")
    @Assert(registry.prepareCandidate(), true)
    registry.commitCandidate()
    @Assert(registry.liveCount(), 0)
    @Assert(registry.referenceForAcceptedNode(oldId).isNone(), true)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(root), "")
    @Assert(registry.prepareCandidate(), true)
    registry.commitCandidate()
    @Assert(field.nodeId > oldId, true)
    @Assert(registry.referenceForAcceptedNode(oldId).isNone(), true)
    @Assert(registry.referenceForAcceptedNode(field.nodeId).isSome(), true)
}

@Test
func modalReturnQueryWaitsForExitAfterAcceptedInitialFocus(): Unit {
    let window = CjguiComposableUiWindow(OrdinaryReturnController())
    let facts = window.testInitialLayerFocusPreservesReturnBookmark(observePreExit: true)
    @Assert(facts[0], "true")
    @Assert(facts[1], "true")
    @Assert(facts[2], "pending")
}

@Test
func modalReturnQueryKeepsDifferentAndRefusedTargetsTerminal(): Unit {
    let wrong = CjguiComposableUiWindow(OrdinaryReturnController())
    let changed = wrong.testInitialLayerFocusPreservesReturnBookmark(observePreExit: true, observedTarget: 999)
    @Assert(changed[2], "target_changed")
    let refused = CjguiComposableUiWindow(OrdinaryReturnController())
    let failure = refused.testInitialLayerFocusPreservesReturnBookmark(observePreExit: true,
        preExitRefusal: "candidate_rejected")
    @Assert(failure[2], "target_changed")
}
