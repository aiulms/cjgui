package cjgui

import std.collection.*

private func bindingNode(incarnation: Int64): CjguiComposableUiLayoutNode {
    return CjguiComposableUiLayoutNode(77, "semantic:editor", "editor", "EDIT_TEXT", "draft",
        "EDIT_DRAFT", 9901, 9901, 5, incarnation)
}

@Test
func ohosAcceptedBindingEpochRejectsSameValueNewIncarnationAndAba(): Unit {
    let window = CjguiComposableUiWindow()
    let a = bindingNode(1)
    window.acceptScene(1, ArrayList<CjguiComposableUiLayoutNode>([a]))
    let pendingFocusEpoch = window.epochFor(a)
    @Assert(pendingFocusEpoch, 1u64)

    // Equal geometry and strings preserve the accepted binding epoch.
    let sameA = bindingNode(1)
    window.acceptScene(2, ArrayList<CjguiComposableUiLayoutNode>([sameA]))
    @Assert(window.epochFor(sameA), pendingFocusEpoch)

    // An accepted replacement under the same numeric slot retires the pending
    // request, even if a later candidate restores the original strings.
    let b = bindingNode(2)
    window.acceptScene(3, ArrayList<CjguiComposableUiLayoutNode>([b]))
    @Assert(window.epochFor(b), 3u64)
    @Assert(window.epochFor(b) == pendingFocusEpoch, false)
    let restoredA = bindingNode(1)
    window.acceptScene(4, ArrayList<CjguiComposableUiLayoutNode>([restoredA]))
    @Assert(window.epochFor(restoredA), 4u64)
    @Assert(window.epochFor(restoredA) == pendingFocusEpoch, false)
}

@Test
func ohosRejectedBindingCandidateDoesNotPublishItsEpoch(): Unit {
    let window = CjguiComposableUiWindow()
    let a = bindingNode(1)
    window.acceptScene(1, ArrayList<CjguiComposableUiLayoutNode>([a]))
    let b = bindingNode(2)
    @Assert(window.candidateEpochFor(b, 2), 2u64)
    @Assert(window.epochFor(a), 1u64)
    window.acceptScene(3, ArrayList<CjguiComposableUiLayoutNode>([bindingNode(1)]))
    @Assert(window.epochFor(bindingNode(1)), 1u64)
}
