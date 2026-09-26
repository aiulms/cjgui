// Cross-window view-state ownership.
//
// A scroll viewport / split size / active tab page is PER-WINDOW view state. Two
// windows may legitimately share the same declaration, but sharing one MUTABLE
// view object would let either window move the other's accepted geometry, so the
// second window's candidate is refused deterministically instead of silently
// coupling the two windows.
package cjgui

import std.collection.*

private class SharedViewportController <: CjguiComposableUiController {
    let viewport: CjguiComposableUiScrollViewport
    private var revision: Int64 = 1

    init(viewport: CjguiComposableUiScrollViewport) {
        this.viewport = viewport
    }

    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let content = cjguiComposableVertical(701, "shared-content", CjguiComposableUiStyle(gap: 4))
        var index: Int64 = 0
        while (index < 8) {
            content.add(cjguiComposableText(710 + index, "shared-line-${index}", "行${index}",
                CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let scroll = cjguiComposableScrollArea(702, "shared-scroll", viewport, CjguiComposableUiStyle(growX: 1))
        scroll.add(content)
        return scroll
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

/// The FIRST window to accept the declaration owns the view object, and the SAME
/// window may re-claim it any number of times; a claim by any OTHER window
/// instance is refused, which is exactly what the window's candidate path turns
/// into a rejected scene.
///
/// This pins the claim boundary itself. The A2 tests at the bottom of this file
/// drive the same rule through REAL second/third native windows in one process
/// (each `start()` owns its own native session), so the refusal, the failed
/// candidate's staged ownership and the release paths are all covered end to end.
@Test
func aSecondWindowInstanceCannotClaimAnAcceptedViewport(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let controller = SharedViewportController(viewport)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(viewport.ownerWindowToken() > 0, true)
    // The same window may refresh and re-claim as often as it likes.
    @Assert(viewport.claimOwner(viewport.ownerWindowToken()), true)
    // A DIFFERENT window instance is refused...
    @Assert(viewport.claimOwner(viewport.ownerWindowToken() + 100000), false)
    // ...and the refusal changed nothing about the owner or its geometry.
    @Assert(viewport.ownerWindowToken() > 0, true)
    @Assert(viewport.acceptedSolveCount() > 0, true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    window.close()
}

/// The same rule covers the split size and the active tab page: one window's view
/// state cannot be adopted by another.
@Test
func aSecondWindowInstanceCannotClaimAcceptedSplitOrTabState(): Unit {
    let split = CjguiComposableUiSplitState(200, 120, 120)
    @Assert(split.claimOwner(11), true)
    @Assert(split.ownerWindowToken(), 11)
    @Assert(split.claimOwner(11), true)
    @Assert(split.claimOwner(12), false)
    @Assert(split.ownerWindowToken(), 11)
    // The refused claim did not touch the size it holds.
    @Assert(split.applyFirstSize(300, 500, 8), 300)
    @Assert(split.firstSize(), 300)

    let tabs = CjguiComposableUiTabsState("basic")
    @Assert(tabs.claimOwner(11), true)
    @Assert(tabs.claimOwner(12), false)
    @Assert(tabs.ownerWindowToken(), 11)
    @Assert(tabs.select("advanced"), true)
    @Assert(tabs.activeKey(), "advanced")
    // An unclaimed object accepts the first claimant.
    let fresh = CjguiComposableUiTabsState("basic")
    @Assert(fresh.ownerWindowToken(), 0)
    @Assert(fresh.claimOwner(12), true)
    @Assert(fresh.ownerWindowToken(), 12)
}

/// ONE window's own repeated refreshes are unaffected: ownership only refuses a
/// DIFFERENT window.
@Test
func oneWindowKeepsOwningItsViewportAcrossRefreshes(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let controller = SharedViewportController(viewport)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    controller.bump()
    @Assert(window.refresh(), true)
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    @Assert(viewport.acceptedSolveCount() >= 3, true)
    window.close()
}

// --- A2: ownership is published with the ACCEPTED scene ---------------------
//
// The tests above pin the claim boundary. They cannot show what happens when a
// candidate FAILS AFTER it has already seen a free object, because a failed
// candidate used to leave that object claimed by a window whose accepted scene
// never contained it. The controller below lets one process declare a scroll
// viewport and/or a split whose shared view state is chosen by the test, so a
// real second (and third) native window can drive that path end to end.
private class SharedViewStateController <: CjguiComposableUiController {
    var viewport: ?CjguiComposableUiScrollViewport = None
    var split: ?CjguiComposableUiSplitState = None
    private var revision: Int64 = 1

    init() {}

    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(700, "shared-view-root", CjguiComposableUiStyle(gap: 4))
        // The scroll element comes FIRST: a candidate that fails on the split must
        // already have seen the free viewport.
        if (let Some(state) <- viewport) {
            let content = cjguiComposableVertical(701, "shared-view-content", CjguiComposableUiStyle(gap: 4))
            content.add(cjguiComposableText(710, "shared-view-line", "行", CjguiComposableUiStyle(fixedHeight: 24)))
            let scroll = cjguiComposableScrollArea(702, "shared-view-scroll", state, CjguiComposableUiStyle(growX: 1))
            scroll.add(content)
            root.add(scroll)
        }
        if (let Some(state) <- split) {
            let first = cjguiComposableVertical(703, "shared-view-first", CjguiComposableUiStyle(growX: 1))
            first.add(cjguiComposableText(704, "shared-view-first-label", "左", CjguiComposableUiStyle()))
            let second = cjguiComposableVertical(705, "shared-view-second", CjguiComposableUiStyle(growX: 1))
            second.add(cjguiComposableText(706, "shared-view-second-label", "右", CjguiComposableUiStyle()))
            root.add(cjguiComposableScopedSplitView(CjguiComposableUiIdentityScope("shared-view-split"),
                "shared-view-split", first, second, CjguiComposableUiSplitAxis.HORIZONTAL, state.firstSize(), 40, 40,
                CjguiComposableUiStyle(growX: 1), splitState: state))
        }
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

/// A2: a candidate that FAILS after binding a free viewport must leave that
/// viewport free. Two real windows in ONE process, one shared object reference:
/// window A accepts the split and owns it; window B declares the free viewport
/// FIRST and the owned split second, so its candidate fails as a whole; a THIRD
/// window must still be able to take the viewport over.
@Test
func aFailedCandidateLeavesTheSharedViewportUnclaimedForAnotherWindow(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let split = CjguiComposableUiSplitState(200, 40, 40)
    // Window A accepts a scene containing the split, so A owns it.
    let controllerA = SharedViewStateController()
    controllerA.split = Some(split)
    let windowA = CjguiComposableUiWindow(controllerA)
    @Assert(windowA.start(), true)
    @Assert(split.ownerWindowToken() > 0, true)
    let ownerA = split.ownerWindowToken()
    // Window B declares the FREE viewport S and then the owned split D. The
    // candidate must be refused as a whole...
    let controllerB = SharedViewStateController()
    controllerB.viewport = Some(viewport)
    controllerB.split = Some(split)
    let windowB = CjguiComposableUiWindow(controllerB)
    @Assert(windowB.start(), false)
    @Assert(windowB.isOpen(), false)
    // ...the refusal changed nothing about A's right...
    @Assert(split.ownerWindowToken(), ownerA)
    // ...and S is NOT left claimed by B, whose scene never used it.
    @Assert(viewport.ownerWindowToken(), 0)
    // A third window may therefore legally take S.
    let controllerC = SharedViewStateController()
    controllerC.viewport = Some(viewport)
    let windowC = CjguiComposableUiWindow(controllerC)
    @Assert(windowC.start(), true)
    @Assert(viewport.ownerWindowToken() > 0, true)
    @Assert(viewport.ownerWindowToken() != ownerA, true)
    // Closing A gives the split back, and a later window can take it over.
    windowA.close()
    @Assert(split.ownerWindowToken(), 0)
    let controllerD = SharedViewStateController()
    controllerD.split = Some(split)
    let windowD = CjguiComposableUiWindow(controllerD)
    @Assert(windowD.start(), true)
    @Assert(split.ownerWindowToken() > 0, true)
    windowD.close()
    @Assert(split.ownerWindowToken(), 0)
    windowC.close()
    @Assert(viewport.ownerWindowToken(), 0)
}

/// A2: dropping the last reference to a shared view object gives it back, so the
/// next window may take it over instead of inheriting a dead claim.
@Test
func removingTheLastReferenceGivesTheSharedViewportBack(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let controller = SharedViewStateController()
    controller.viewport = Some(viewport)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(viewport.ownerWindowToken() > 0, true)
    @Assert(viewport.acceptedSolveCount() > 0, true)
    // The accepted structure no longer contains the scroll element.
    controller.viewport = None
    controller.bump()
    @Assert(window.refresh(), true)
    @Assert(viewport.ownerWindowToken(), 0)
    // Another window can now legally take the same object over.
    let controllerB = SharedViewStateController()
    controllerB.viewport = Some(viewport)
    let windowB = CjguiComposableUiWindow(controllerB)
    @Assert(windowB.start(), true)
    @Assert(viewport.ownerWindowToken() > 0, true)
    windowB.close()
    @Assert(viewport.ownerWindowToken(), 0)
    window.close()
}

/// A2: one window's own repeated refreshes must not accumulate ownership: the
/// object set is recomputed from the accepted structure on every acceptance.
@Test
func oneWindowRebuildingItsSharedViewStateDoesNotAccumulateOwnership(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let controller = SharedViewStateController()
    controller.viewport = Some(viewport)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let owner = viewport.ownerWindowToken()
    @Assert(owner > 0, true)
    var index: Int64 = 0
    while (index < 6) {
        controller.bump()
        @Assert(window.refresh(), true)
        index += 1
    }
    @Assert(viewport.ownerWindowToken(), owner)
    @Assert(viewport.acceptedSolveCount() >= 6, true)
    window.close()
    @Assert(viewport.ownerWindowToken(), 0)
}

