package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// Hit-priority rule (2026-09-26), extracted as the package-level pure function
// `cjguiComposableHitMayTakeOver` so it can be pinned WITHOUT building a scene:
//   TOPMOST wins; a LATER (lower) candidate may take over ONLY when it lies strictly inside the current best.
// Counterexample this file pins: comparing AREA alone let a small sibling in a LOWER layer beat a large upper
// layer that also contained the point. Containment must keep the 2026-09-25 fix (the interactive text node
// inside its scroll container still wins over the container).

@Test
func testLowerSiblingOutsideUpperLayerCannotTakeOver(): Unit {
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 400, 300, -5, 20, 40, 40))     // pokes out on x
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 400, 300, 20, -5, 40, 40))     // pokes out on y
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 100, 100, 200, 200, 10, 10))   // disjoint
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 100, 100, 50, 50, 200, 200))   // bigger, partial overlap
}

@Test
func testInnerNodeMayTakeOverItsContainer(): Unit {
    @Assert(cjguiComposableHitMayTakeOver(0, 0, 400, 300, 20, 20, 40, 40))
    @Assert(cjguiComposableHitMayTakeOver(10, 10, 50, 50, 10, 10, 50, 50))       // equal rects: topmost keeps
    @Assert(cjguiComposableHitMayTakeOver(10, 10, 50, 50, 10, 10, 10, 10))       // touching the top-left
    @Assert(cjguiComposableHitMayTakeOver(10, 10, 50, 50, 50, 50, 10, 10))       // touching the bottom-right
}

@Test
func testCandidateTouchingTheBoundaryIsInside(): Unit {
    @Assert(cjguiComposableHitMayTakeOver(0, 0, 100, 100, 0, 0, 100, 100))
    @Assert(cjguiComposableHitMayTakeOver(0, 0, 100, 100, 0, 50, 100, 50))
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 100, 100, 1, 0, 100, 100))       // one pixel too wide
    @Assert(!cjguiComposableHitMayTakeOver(0, 0, 100, 100, 0, 1, 100, 100))       // one pixel too tall
}
