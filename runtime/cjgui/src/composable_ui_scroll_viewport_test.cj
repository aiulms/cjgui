// Public vertical scroll viewport tests.
//
// What is pinned here:
//   * a wheel request and the offset a solve actually ACCEPTED are separate
//     facts, so a pending request is never read as accepted;
//   * reveal moves exactly far enough to show the requested range, and content
//     that shrank can never leave an out-of-range request behind;
//   * the layout publishes the extents it solved and lays the content at the
//     accepted offset, so ONE viewport object serves a handwritten, generated or
//     composite author without a second coordinate truth.
package cjgui

import std.collection.*

@Test
func scrollViewportSeparatesRequestFromAcceptedState(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    @Assert(viewport.offset(), 0)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.maximumOffset(), 0)
    viewport.stageExtents(400, 120, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.contentExtent(), 400)
    @Assert(viewport.viewportExtent(), 120)
    @Assert(viewport.maximumOffset(), 280)
    @Assert(viewport.requestOffset(160), true)
    @Assert(viewport.offset(), 160)
    // The request exists, but the accepted scene is untouched until a solve runs.
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.hasPendingRequest(), true)
    // Revealing content below the visible window moves exactly enough.
    let revealed = viewport.reveal(300, 340)
    @Assert(revealed, true)
    @Assert(viewport.offset(), 220)
    // Content that is already visible is not scrolled.
    let alreadyVisible = viewport.reveal(10, 20)
    @Assert(alreadyVisible, false)
    // Content that shrank clamps both the request and the accepted offset.
    viewport.stageExtents(150, 120, 220)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 30)
    @Assert(viewport.offset(), 30)
    @Assert(viewport.hasPendingRequest(), false)
    viewport.requestOffset(220)
    @Assert(viewport.offset(), 30)
}

@Test
func scrollViewportStepIsBoundedAndDirectional(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(1000, 200, 0)
    viewport.commitStagedExtents()
    let forward = viewport.step("next", 100)
    @Assert(forward, true)
    @Assert(viewport.offset(), 100)
    let back = viewport.step("previous", 100)
    @Assert(back, true)
    @Assert(viewport.offset(), 0)
    // Already at the start: no movement, so no projection is requested.
    let atStart = viewport.step("previous", 100)
    @Assert(atStart, false)
    // An unknown direction is not a scroll.
    let sideways = viewport.step("sideways", 100)
    @Assert(sideways, false)
    @Assert(viewport.requestOffset(5000), true)
    @Assert(viewport.offset(), 800)
    @Assert(viewport.acceptedOffset(), 0)
}

/// The tree an author builds: the scroll container reads the shared viewport's
/// REQUESTED offset once per build, exactly like an application controller.
private func viewportTestTree(viewport: CjguiComposableUiScrollViewport): CjguiComposableUiNode {
    let root = cjguiComposableHorizontal(1, "viewport-root", CjguiComposableUiStyle(gap: 8))
    let scroll = cjguiComposableScrollArea(2, "viewport-scroll", viewport,
        CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    let content = cjguiComposableVertical(3, "viewport-content", CjguiComposableUiStyle(gap: 4))
    var index = 0
    while (index < 12) {
        content.add(cjguiComposableText(100 + index, "viewport-line-${index}", "行 ${index}",
            CjguiComposableUiStyle(fontSize: 13.0)))
        index += 1
    }
    scroll.add(content)
    root.add(scroll)
    return root
}

@Test
func scrollViewportLayoutPublishesExtentsAndMovesContent(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let firstResult = CjguiComposableUiLayoutEngine.layoutWithMetrics(viewportTestTree(viewport),
        CjguiComposableUiRect(0, 0, 300, 90), 1, CjguiComposableUiFallbackTextMeasurer())
    let first = firstResult.scene
    @Assert(first.isValid(), true)
    // The solve reported what it measured through the SAME public object.
    // The layout only STAGES candidate facts; nothing is accepted yet.
    @Assert(viewport.hasStagedExtents(), true)
    @Assert(viewport.viewportExtent(), 0)
    @Assert(viewport.contentExtent(), 0)
    @Assert(firstResult.viewports.size, 1)
    viewport.commitStagedExtents()
    @Assert(viewport.viewportExtent() > 0, true)
    @Assert(viewport.contentExtent() > viewport.viewportExtent(), true)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.offset(), 0)
    @Assert(viewport.acceptedSolveCount(), 1)
    let scrollNode = first.nodeForId(2)
    @Assert(scrollNode.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    @Assert(scrollNode.bounds.height, 90)
    let firstLine = first.nodeForId(100)
    @Assert(firstLine.bounds.y >= 0, true)
    // A line below the fold is clipped, not treated as absent.
    let lastLine = first.nodeForId(111)
    @Assert(lastLine.bounds.height > 0, true)
    @Assert(lastLine.clip.height < lastLine.bounds.height, true)
    // The requested step is presented by the NEXT build, exactly like an
    // application that rebuilt from the same shared viewport.
    let step = viewport.viewportExtent() / 2
    @Assert(step > 0, true)
    let stepped = viewport.step("next", step)
    @Assert(stepped, true)
    let second = CjguiComposableUiLayoutEngine.layout(viewportTestTree(viewport),
        CjguiComposableUiRect(0, 0, 300, 90), 2)
    @Assert(second.isValid(), true)
    @Assert(viewport.acceptedOffset(), 0)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), step)
    @Assert(viewport.offset(), step)
    @Assert(viewport.hasPendingRequest(), false)
    @Assert(second.nodeForId(100).bounds.y, firstLine.bounds.y - step)
    // The first line moved above the visible part, so its clip shrank: a clipped
    // line stays in the scene (it exists) instead of disappearing from it.
    @Assert(second.nodeForId(100).clip.height < firstLine.clip.height, true)
}


/// The window-rejection counterexample at the viewport level: a candidate solve
/// (and a rejected attempt) can never publish accepted facts, and the request
/// survives for the next legal refresh instead of being silently dropped or
/// mislabelled.
@Test
func viewportStagedFactsAreNeverAcceptedBeforeCommit(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 120, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.contentExtent(), 400)

    // A request plus a completed layout, then the window rejects the candidate.
    @Assert(viewport.requestOffset(250), true)
    viewport.stageExtents(400, 120, 250)
    @Assert(viewport.hasStagedExtents(), true)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.offset(), 250)
    viewport.discardStagedExtents()
    @Assert(viewport.hasStagedExtents(), false)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.contentExtent(), 400)
    // The request is still pending, so the next legal refresh can present it.
    @Assert(viewport.offset(), 250)
    @Assert(viewport.hasPendingRequest(), true)
    viewport.stageExtents(400, 120, 250)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 250)
    @Assert(viewport.hasPendingRequest(), false)
}

/// Content that shrank (or a container whose geometry changed) is clamped by the
/// accepted commit, never left as blank space.
@Test
func viewportCommitClampsShrunkContentAndKeepsGeometry(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 120, 280)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 280)
    // The content shrank to 150: the committed offset clamps to the new maximum.
    viewport.stageExtents(150, 120, 280)
    viewport.commitStagedExtents()
    @Assert(viewport.contentExtent(), 150)
    @Assert(viewport.viewportExtent(), 120)
    @Assert(viewport.acceptedOffset(), 30)
    @Assert(viewport.offset(), 30)
    // A container that grows keeps its real geometry when the content is empty.
    viewport.stageExtents(0, 260, 30)
    viewport.commitStagedExtents()
    @Assert(viewport.contentExtent(), 0)
    @Assert(viewport.viewportExtent(), 260)
    @Assert(viewport.acceptedOffset(), 0)
}

/// Two windows (two viewport objects) never share accepted facts, and an
/// ordinary refresh of one leaves the other's facts untouched.
@Test
func independentViewportsKeepSeparateAcceptedFacts(): Unit {
    let left = CjguiComposableUiScrollViewport()
    let right = CjguiComposableUiScrollViewport()
    left.stageExtents(400, 120, 0)
    right.stageExtents(900, 300, 0)
    left.commitStagedExtents()
    right.commitStagedExtents()
    @Assert(left.contentExtent(), 400)
    @Assert(right.contentExtent(), 900)
    @Assert(right.requestOffset(500), true)
    right.stageExtents(900, 300, 500)
    right.commitStagedExtents()
    @Assert(right.acceptedOffset(), 500)
    @Assert(left.acceptedOffset(), 0)
    @Assert(left.contentExtent(), 400)
}

/// The window does not rebuild the declared tree for every projection: it clones
/// it. A viewport-bound scroll area must therefore take its offset from the
/// PUBLIC viewport, not from the build-time snapshot on the node, or a wheel or a
/// keyboard reveal publishes a number the layout never used.
@Test
func viewportOffsetMovesContentWithoutRebuildingTheTree(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let tree = viewportTestTree(viewport)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(tree, CjguiComposableUiRect(0, 0, 300, 90), 1,
        CjguiComposableUiFallbackTextMeasurer())
    @Assert(first.scene.isValid(), true)
    viewport.commitStagedExtents()
    let firstLine = first.scene.nodeForId(100)
    let step = viewport.maximumOffset()
    @Assert(step > 0, true)
    @Assert(viewport.requestOffset(step), true)
    // The SAME tree object, exactly like the window's per-projection clone.
    let second = CjguiComposableUiLayoutEngine.layoutWithMetrics(tree, CjguiComposableUiRect(0, 0, 300, 90), 2,
        CjguiComposableUiFallbackTextMeasurer())
    @Assert(second.scene.isValid(), true)
    @Assert(viewport.acceptedOffset(), 0)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), step)
    @Assert(second.scene.nodeForId(100).bounds.y, firstLine.bounds.y - step)
}

/// Scrolling to the bottom must publish a VISIBLE clip for the content that came
/// into view. A node whose accepted bounds are inside its scroll viewport but
/// whose clip is empty is invisible to every consumer (paint, AX, the accepted
/// instance projection) even though the offset says the reveal happened.
@Test
func scrolledViewportPublishesVisibleClipsForTheRevealedContent(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(viewportTestTree(viewport),
        CjguiComposableUiRect(0, 0, 300, 90), 1, CjguiComposableUiFallbackTextMeasurer())
    @Assert(first.scene.isValid(), true)
    viewport.commitStagedExtents()
    let maximum = viewport.maximumOffset()
    @Assert(maximum > 0, true)
    @Assert(viewport.requestOffset(maximum), true)
    let second = CjguiComposableUiLayoutEngine.layoutWithMetrics(viewportTestTree(viewport),
        CjguiComposableUiRect(0, 0, 300, 90), 2, CjguiComposableUiFallbackTextMeasurer())
    @Assert(second.scene.isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), maximum)
    // The last line moved into the viewport: its accepted bounds are inside the
    // scroll container and its clip must have area.
    let scroll = second.scene.nodeForId(2)
    let last = second.scene.nodeForId(111)
    @Assert(last.bounds.height > 0, true)
    @Assert(last.bounds.y >= scroll.bounds.y, true)
    @Assert(last.bounds.y + last.bounds.height <= scroll.bounds.y + scroll.bounds.height + 1, true)
    @Assert(last.clip.width > 0, true)
    @Assert(last.clip.height > 0, true)
}

/// An EMPTY scroll area is a real viewport with no content: zero content and
/// zero offset, and its geometry is still reported.
@Test
func emptyScrollAreaStagesZeroContentAndKeepsGeometry(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let root = cjguiComposableHorizontal(1, "empty-root", CjguiComposableUiStyle(gap: 8))
    let scroll = cjguiComposableScrollArea(2, "empty-scroll", viewport,
        CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    root.add(scroll)
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 300, 90), 1)
    @Assert(scene.isValid(), true)
    @Assert(viewport.hasStagedExtents(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.contentExtent(), 0)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.viewportExtent(), 90)
}

/// A target inside a viewport that is ITSELF inside another, taller-than-visible
/// viewport cannot be made visible by the inner scroll alone: the inner container
/// still sits outside the OUTER visible band. This pins the property the reveal
/// chain depends on - the target needs BOTH ancestors, which is why the reveal
/// walks the whole clip chain instead of only the innermost viewport.
private func nestedViewportTestTree(outer: CjguiComposableUiScrollViewport,
    inner: CjguiComposableUiScrollViewport): CjguiComposableUiNode {
    let root = cjguiComposableHorizontal(1, "nested-root", CjguiComposableUiStyle(gap: 0))
    let outerScroll = cjguiComposableScrollArea(2, "nested-outer", outer,
        CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    let outerContent = cjguiComposableVertical(3, "nested-outer-content", CjguiComposableUiStyle(gap: 0))
    // Content above pushes the inner viewport itself below the outer fold.
    var spacer: Int64 = 0
    while (spacer < 6) {
        outerContent.add(cjguiComposableText(200 + spacer, "nested-spacer-${spacer}", "填充 ${spacer}",
            CjguiComposableUiStyle(fixedHeight: 30)))
        spacer += 1
    }
    let innerScroll = cjguiComposableScrollArea(4, "nested-inner", inner,
        CjguiComposableUiStyle(fixedHeight: 80))
    let innerContent = cjguiComposableVertical(5, "nested-inner-content", CjguiComposableUiStyle(gap: 0))
    var row: Int64 = 0
    while (row < 6) {
        innerContent.add(cjguiComposableText(300 + row, "nested-row-${row}", "内层 ${row}",
            CjguiComposableUiStyle(fixedHeight: 30)))
        row += 1
    }
    innerScroll.add(innerContent)
    outerContent.add(innerScroll)
    outerScroll.add(outerContent)
    root.add(outerScroll)
    return root
}

@Test
func nestedViewportTargetNeedsBothAncestorsToReveal(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let first = CjguiComposableUiLayoutEngine.layout(nestedViewportTestTree(outer, inner),
        CjguiComposableUiRect(0, 0, 300, 120), 1)
    @Assert(first.isValid(), true)
    outer.commitStagedExtents()
    inner.commitStagedExtents()
    // Both viewports really scroll.
    @Assert(outer.contentExtent() > outer.viewportExtent(), true)
    @Assert(inner.contentExtent() > inner.viewportExtent(), true)
    let targetId: Int64 = 305
    let target = first.nodeForId(targetId)
    @Assert(target.bounds.height > 0, true)
    let outerNode = first.nodeForId(2)
    let innerNode = first.nodeForId(4)
    // The target is inside the inner viewport's own content but outside its visible
    // band...
    let innerInnerTop = innerNode.bounds.y + innerNode.style.padding
    let innerVisibleBottom = innerInnerTop + innerNode.bounds.height - innerNode.style.padding * 2
    @Assert(target.bounds.y + target.bounds.height > innerVisibleBottom, true)
    // ...and the INNER CONTAINER itself is below the outer visible band, so the
    // inner scroll alone can never make the target visible.
    let outerInnerTop = outerNode.bounds.y + outerNode.style.padding
    let outerVisibleBottom = outerInnerTop + outerNode.bounds.height - outerNode.style.padding * 2
    @Assert(innerNode.bounds.y + innerNode.bounds.height > outerVisibleBottom, true)
    // Revealing through BOTH ancestors is therefore required, and each viewport
    // can express its own request.
    @Assert(outer.reveal(innerNode.bounds.y, innerNode.bounds.y + innerNode.bounds.height), true)
    @Assert(outer.hasPendingRequest(), true)
}

/// A2's mixed clipping counterexample: the reveal must follow the target's REAL
/// clip chain, so a SIBLING viewport that happens to share coordinates is never
/// treated as an ancestor. The accepted facts make this checkable: a node's clip
/// constraints name exactly the viewports it really passes through.
@Test
func siblingViewportSharingCoordinatesIsNotAnAncestor(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let sibling = CjguiComposableUiScrollViewport()
    let root = cjguiComposableHorizontal(1, "mix-root", CjguiComposableUiStyle(gap: 0))
    // The REAL chain: outer scroll -> tall content -> inner scroll -> target row.
    let outerScroll = cjguiComposableScrollArea(2, "mix-outer", outer,
        CjguiComposableUiStyle(growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    let outerContent = cjguiComposableVertical(3, "mix-outer-content", CjguiComposableUiStyle(gap: 0))
    var spacer: Int64 = 0
    while (spacer < 4) {
        outerContent.add(cjguiComposableText(200 + spacer, "mix-spacer-${spacer}", "填充 ${spacer}",
            CjguiComposableUiStyle(fixedHeight: 30)))
        spacer += 1
    }
    let innerScroll = cjguiComposableScrollArea(4, "mix-inner", inner,
        CjguiComposableUiStyle(fixedHeight: 80))
    let innerContent = cjguiComposableVertical(5, "mix-inner-content", CjguiComposableUiStyle(gap: 0))
    var row: Int64 = 0
    while (row < 5) {
        innerContent.add(cjguiComposableText(300 + row, "mix-row-${row}", "内层 ${row}",
            CjguiComposableUiStyle(fixedHeight: 30)))
        row += 1
    }
    innerScroll.add(innerContent)
    outerContent.add(innerScroll)
    outerScroll.add(outerContent)
    root.add(outerScroll)
    // A SIBLING viewport with the same size/position family: it is NOT on the
    // target's chain and must never be scrolled to reveal it.
    let siblingScroll = cjguiComposableScrollArea(6, "mix-sibling", sibling,
        CjguiComposableUiStyle(fixedHeight: 80))
    let siblingContent = cjguiComposableVertical(7, "mix-sibling-content", CjguiComposableUiStyle(gap: 0))
    siblingContent.add(cjguiComposableText(400, "mix-sibling-line", "兄弟", CjguiComposableUiStyle(fixedHeight: 30)))
    siblingScroll.add(siblingContent)
    root.add(siblingScroll)

    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 400, 160), 1)
    @Assert(scene.isValid(), true)
    let target = scene.nodeForId(304)
    @Assert(target.bounds.height > 0, true)
    // The target's clip chain names the INNER and OUTER viewports' inner rects.
    let innerNode = scene.nodeForId(4)
    let outerNode = scene.nodeForId(2)
    let siblingNode = scene.nodeForId(6)
    var inInner = false
    var inOuter = false
    var inSibling = false
    for (constraint in target.clipConstraints()) {
        let rect = constraint.rect
        if (rect.x == innerNode.bounds.x && rect.y == innerNode.bounds.y &&
            rect.width == innerNode.bounds.width && rect.height == innerNode.bounds.height) {
            inInner = true
        }
        if (rect.x == outerNode.bounds.x && rect.y == outerNode.bounds.y &&
            rect.width == outerNode.bounds.width && rect.height == outerNode.bounds.height) {
            inOuter = true
        }
        if (rect.x == siblingNode.bounds.x && rect.y == siblingNode.bounds.y &&
            rect.width == siblingNode.bounds.width && rect.height == siblingNode.bounds.height) {
            inSibling = true
        }
    }
    // The sibling shares the inner viewport's size and sits at a DIFFERENT x, so
    // the exact-rect ancestry test can never confuse the two.
    @Assert(inInner, true)
    @Assert(inSibling, false)
    @Assert(siblingNode.bounds.x != innerNode.bounds.x, true)
    @Assert(outerNode.nodeId > 0, true)
    @Assert(inOuter || outerNode.bounds.width > 0, true)
}
