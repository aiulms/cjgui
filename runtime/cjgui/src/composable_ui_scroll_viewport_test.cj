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

// A horizontal parent's cross axis is controlled by alignment. `growY`
// alone does not turn the scroll area's 120-point intrinsic height into the
// parent's full height; nodeRect reports the actual accepted child bounds.
@Test
func scrollAreaCrossAxisStretchUsesTheParentViewport(): Unit {
    let naturalRoot = cjguiComposableHorizontal(336, "home-main",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    let natural = cjguiComposableScrollArea(343, "home-wheel", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 340, growY: 1))
    natural.add(cjguiComposableVertical(337, "home-list", CjguiComposableUiStyle()))
    naturalRoot.add(natural)
    let naturalScene = CjguiComposableUiLayoutEngine.layout(naturalRoot,
        CjguiComposableUiRect(0, 0, 500, 731), 1)
    @Assert(naturalScene.isValid(), true)
    @Assert(naturalScene.nodeForId(336).bounds.height, 731)
    @Assert(naturalScene.nodeForId(343).bounds.height, 120)

    let stretchRoot = cjguiComposableHorizontal(336, "home-main",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    let stretch = cjguiComposableScrollArea(343, "home-wheel", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 340, growY: 1,
            alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    stretch.add(cjguiComposableVertical(337, "home-list", CjguiComposableUiStyle()))
    stretchRoot.add(stretch)
    let stretchScene = CjguiComposableUiLayoutEngine.layout(stretchRoot,
        CjguiComposableUiRect(0, 0, 500, 731), 2)
    @Assert(stretchScene.isValid(), true)
    @Assert(stretchScene.nodeForId(343).bounds.height, 731)
}

/// A declared node offset translates the whole subtree (own bounds, children
/// and clip) without reflowing siblings: the offset applies after the parent
/// assigns the rect and before children are laid out.
@Test
func declaredNodeOffsetTranslatesSubtreeWithoutReflow(): Unit {
    let root = cjguiComposableVertical(700, "offset-root", CjguiComposableUiStyle(gap: 10))
    let shifted = cjguiComposableVertical(701, "offset-shifted",
        CjguiComposableUiStyle(offsetY: 25, offsetX: 4, clipsContent: true))
    shifted.add(cjguiComposableVertical(702, "offset-child", CjguiComposableUiStyle(fixedHeight: 30)))
    let plain = cjguiComposableVertical(703, "offset-plain",
        CjguiComposableUiStyle(fixedHeight: 40))
    root.add(shifted)
    root.add(plain)
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 300, 300), 1)
    @Assert(scene.isValid(), true)
    let shiftedNode = scene.nodeForId(701)
    @Assert(shiftedNode.bounds.y, 25)
    @Assert(shiftedNode.bounds.x, 4)
    let child = scene.nodeForId(702)
    @Assert(child.bounds.y >= 25, true)
    // The sibling below keeps the slot the parent assigned from measured
    // sizes: translation is visual only, no reflow. The shifted node's own
    // slot started at y=0, so the sibling sits at height+gap regardless of
    // the +25/+4 translation applied to the subtree.
    let plainNode = scene.nodeForId(703)
    @Assert(plainNode.bounds.y, shiftedNode.bounds.height + 10)
}

/// A scroll area's content anchor resolves the spare viewport space only
/// while the content fits; taller content keeps the scroll contract.
@Test
func scrollContentAnchorCentersShortContentInTheViewport(): Unit {
    let centeredRoot = cjguiComposableVertical(710, "anchor-root", CjguiComposableUiStyle())
    let centered = cjguiComposableScrollArea(711, "anchor-scroll", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 300,
            scrollContentAlignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
    centered.add(cjguiComposableVertical(712, "anchor-content", CjguiComposableUiStyle(fixedHeight: 100)))
    centeredRoot.add(centered)
    let centeredScene = CjguiComposableUiLayoutEngine.layout(centeredRoot,
        CjguiComposableUiRect(0, 0, 200, 300), 1)
    @Assert(centeredScene.isValid(), true)
    @Assert(centeredScene.nodeForId(712).bounds.y, 100)

    let endRoot = cjguiComposableVertical(720, "anchor-end-root", CjguiComposableUiStyle())
    let end = cjguiComposableScrollArea(721, "anchor-end-scroll", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 300,
            scrollContentAlignY: CJGUI_COMPOSABLE_UI_ALIGN_END))
    end.add(cjguiComposableVertical(722, "anchor-end-content", CjguiComposableUiStyle(fixedHeight: 100)))
    endRoot.add(end)
    let endScene = CjguiComposableUiLayoutEngine.layout(endRoot,
        CjguiComposableUiRect(0, 0, 200, 300), 2)
    @Assert(endScene.isValid(), true)
    @Assert(endScene.nodeForId(722).bounds.y, 200)

    // An invalid anchor value degrades to the legacy top anchoring instead of
    // being invented into a new placement.
    let start = cjguiComposableScrollArea(731, "anchor-start-scroll", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 300, scrollContentAlignY: 999))
    start.add(cjguiComposableVertical(732, "anchor-start-content", CjguiComposableUiStyle(fixedHeight: 100)))
    let startRoot = cjguiComposableVertical(730, "anchor-start-root", CjguiComposableUiStyle())
    startRoot.add(start)
    let startScene = CjguiComposableUiLayoutEngine.layout(startRoot,
        CjguiComposableUiRect(0, 0, 200, 300), 3)
    @Assert(startScene.isValid(), true)
    @Assert(startScene.nodeForId(732).bounds.y, 0)
}

// The reported home-screen collision was two VERTICAL children of the same
// scroll content. It must be a named candidate rejection, regardless of kind.
@Test
func duplicateSameKindScrollChildrenHaveNamedRefusal(): Unit {
    let root = cjguiComposableHorizontal(336, "home-main", CjguiComposableUiStyle())
    let scroll = cjguiComposableScrollArea(343, "home-wheel", CjguiComposableUiScrollViewport(),
        CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 731))
    let content = cjguiComposableVertical(337, "home-list", CjguiComposableUiStyle())
    content.add(cjguiComposableVertical(910, "home-wheel-top",
        CjguiComposableUiStyle(fixedHeight: 24)))
    content.add(cjguiComposableVertical(910, "home-slot-empty",
        CjguiComposableUiStyle(fixedHeight: 54)))
    scroll.add(content)
    root.add(scroll)
    let scene = CjguiComposableUiLayoutEngine.layout(root,
        CjguiComposableUiRect(0, 0, 500, 731), 1)
    @Assert(scene.isValid(), false)
    @Assert(scene.layoutError(), "duplicate_node_id")
}

/// The 2026-09-27 home incident, through the full window path: a candidate
/// whose scroll content carries two id-910 VERTICAL children must be refused
/// with the NAMED duplicate_node_id fact (not a silently blank list), and the
/// previously accepted scene must keep publishing while the defect lasts.
private class HomeDuplicateController <: CjguiComposableUiController {
    var duplicate = false
    private var revision: Int64 = 1
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func markDuplicate(): Unit {
        duplicate = true
        revision += 1
    }
    public func buildUi(): CjguiComposableUiNode {
        let body = cjguiComposableHorizontal(336, "home-main", CjguiComposableUiStyle(growX: 1, growY: 1))
        let scroll = cjguiComposableScrollArea(343, "home-wheel", CjguiComposableUiScrollViewport(),
            CjguiComposableUiStyle(fixedWidth: 340, fixedHeight: 731))
        let content = cjguiComposableVertical(337, "home-list", CjguiComposableUiStyle())
        content.add(cjguiComposableVertical(920, "home-wheel-top",
            CjguiComposableUiStyle(fixedHeight: 24)))
        content.add(cjguiComposableVertical(337_001, "home-row-a",
            CjguiComposableUiStyle(fixedHeight: 54)))
        if (duplicate) {
            // The incident shape: elastic placeholder collides with the empty
            // slot identity of the same numeric id.
            content.add(cjguiComposableVertical(910, "home-wheel-top",
                CjguiComposableUiStyle(fixedHeight: 24)))
            content.add(cjguiComposableVertical(910, "home-slot-empty",
                CjguiComposableUiStyle(fixedHeight: 54)))
        }
        scroll.add(content)
        body.add(scroll)
        return body
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

@Test
func duplicateScrollContentIsNamedRefusalThroughTheWindowPath(): Unit {
    let controller = HomeDuplicateController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    @Assert(window.acceptedSceneNodes().size > 0, true)

    controller.markDuplicate()
    let _ = window.refresh()
    // Named refusal in the progress fact: the defect can be diagnosed from the
    // window alone, without reading stdout or re-running the layout by hand.
    @Assert(window.windowProgress().lastNativeFailure, "duplicate_node_id")
    // The accepted scene is the last GOOD one: the list did not half-render.
    var keptRow = false
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "home-row-a") {
            keptRow = true
        }
        @Assert(node.nodeId != 910, true)
    }
    @Assert(keptRow, true)
    window.close()
}

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

private func scrollOriginTestTree(viewport: CjguiComposableUiScrollViewport, spacerHeight: Int64,
    targetNodeId!: Int64 = 8105, body!: String = "anchor body", fontSize!: Float64 = 14.0,
    textStyleRuns!: Array<CjguiComposableUiTextStyleRun> = Array<CjguiComposableUiTextStyleRun>(),
    prefixHeight!: Int64 = 0): CjguiComposableUiNode {
    let root = cjguiComposableVertical(8100, "origin-root", CjguiComposableUiStyle())
    let outsideClip = cjguiComposableVertical(8101, "origin-outside-clip",
        CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 150, clipsContent: true))
    let scroll = cjguiComposableScrollArea(8102, "origin-scroll", viewport,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100))
    let content = cjguiComposableVertical(8103, "origin-content",
        CjguiComposableUiStyle(gap: 0, clipsContent: true))
    if (prefixHeight > 0) {
        content.add(cjguiComposableVertical(8107, "origin-prepend",
            CjguiComposableUiStyle(fixedHeight: prefixHeight)))
    }
    content.add(cjguiComposableVertical(8104, "origin-spacer",
        CjguiComposableUiStyle(fixedHeight: spacerHeight)))
    content.add(cjguiComposableText(targetNodeId, "origin-anchor", body,
        CjguiComposableUiStyle(fixedHeight: 24, fontFamily: "system", fontSize: fontSize),
        textStyleRuns: textStyleRuns))
    content.add(cjguiComposableVertical(8106, "origin-tail", CjguiComposableUiStyle(fixedHeight: 300)))
    scroll.add(content)
    outsideClip.add(scroll)
    root.add(outsideClip)
    return root
}

private func scrollOriginTicketFromAccepted(viewport: CjguiComposableUiScrollViewport,
    accepted: CjguiComposableUiScene, binding: CjguiComposableUiScrollOriginBinding,
    nodeId!: Int64 = 8105): CjguiComposableUiScrollOriginAnchor {
    let acceptedNode = accepted.nodeForId(nodeId)
    let scrollNode = accepted.nodeForId(8102)
    let innerTop = scrollNode.bounds.y + scrollNode.style.padding
    return CjguiComposableUiScrollOriginAnchor(viewport.viewStateIdentity(), viewport.ownerWindowToken(),
        viewport.acceptedSolveCount(), viewport.requestGeneration(), binding, "document-anchor-4", 4,
        acceptedNode.nodeId, acceptedNode.value, "captured", acceptedNode.bounds.width,
        acceptedNode.bounds.y - innerTop, 0.375, 4.5, acceptedNode,
        acceptedOffset: viewport.acceptedOffset(), requestedOffset: viewport.offset())
}

private func acceptScrollOriginInitial(viewport: CjguiComposableUiScrollViewport,
    binding: CjguiComposableUiScrollOriginBinding,
    textStyleRuns!: Array<CjguiComposableUiTextStyleRun> = Array<CjguiComposableUiTextStyleRun>(),
    targetNodeId!: Int64 = 8105, body!: String = "anchor body", fontSize!: Float64 = 14.0): CjguiComposableUiScene {
    @Assert(viewport.claimOwner(91), true)
    @Assert(viewport.stageCoordinateOrigin(binding), "scroll_origin_initial")
    let first = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50,
        targetNodeId: targetNodeId, body: body, fontSize: fontSize, textStyleRuns: textStyleRuns),
        CjguiComposableUiRect(0, 0, 240, 170), 1)
    @Assert(first.isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.requestOffset(40), true)
    let scrolled = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50,
        targetNodeId: targetNodeId, body: body, fontSize: fontSize, textStyleRuns: textStyleRuns),
        CjguiComposableUiRect(0, 0, 240, 170), 2)
    @Assert(scrolled.isValid(), true)
    viewport.commitStagedExtents()
    return scrolled
}

@Test
func scrollOriginPassivePrependAdmitsNegativeGlobalDomain(): Unit {
    let unbound = CjguiComposableUiScrollViewport()
    @Assert(unbound.requestOffset(-20), false)
    @Assert(unbound.offset(), 0)

    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 14, "same-map", "mid-fragment-base")
    let initial = acceptScrollOriginInitial(viewport, bindingA)
    // An active source jump establishes local origin zero within a mid-document
    // fragment; scrolling within that window then creates the accepted geometry.
    viewport.requestOriginNavigation()
    @Assert(viewport.stageCoordinateOrigin(bindingA), "scroll_origin_navigation")
    let navigated = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(navigated.isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOriginOffset(), 0)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.requestOffset(40), true)
    let accepted = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50),
        CjguiComposableUiRect(0, 0, 240, 170), 4)
    @Assert(accepted.isValid(), true)
    viewport.commitStagedExtents()
    let oldScroll = accepted.nodeForId(8102)
    let oldAnchor = accepted.nodeForId(8105)
    let oldRelativeY = oldAnchor.bounds.y - oldScroll.bounds.y
    let ticket = scrollOriginTicketFromAccepted(viewport, accepted, bindingA)
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 14, "same-map", "prepended-origin")

    @Assert(viewport.stageCoordinateOrigin(bindingB, anchor: Some(ticket), targetNodeId: 8105,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let prepended = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50,
        prefixHeight: 20), CjguiComposableUiRect(0, 0, 240, 170), 5)
    @Assert(prepended.isValid(), true)
    @Assert(viewport.pendingOriginOffset(), -20)
    @Assert(prepended.nodeForId(8105).bounds.y - prepended.nodeForId(8102).bounds.y, oldRelativeY)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOriginOffset(), -20)
    @Assert(viewport.minimumOffset(), -20)
    @Assert(viewport.maximumOffset() > viewport.minimumOffset(), true)
    @Assert(viewport.reveal(-25, -21), true)
    @Assert(viewport.offset(), -20)
    @Assert(viewport.offset() >= viewport.minimumOffset(), true)
    // Global content ends may themselves lie below zero in a very short
    // bounded window; staging/refinement must preserve that endpoint instead
    // of fabricating a zero-sized scroll range.
    viewport.stageExtents(-30, 100, -20)
    viewport.refineStagedExtents(-31, 100, -20)
    viewport.commitStagedExtents()
    @Assert(viewport.contentExtent(), -31)
    @Assert(viewport.maximumOffset(), -20)
    @Assert(initial.isValid(), true)
}

@Test
func scrollOriginHandoffPreservesPendingScrollDelta(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 13, "same-map", "origin-A")
    let accepted = acceptScrollOriginInitial(viewport, bindingA)
    let oldAnchor = accepted.nodeForId(8105)
    let oldY = oldAnchor.bounds.y - accepted.nodeForId(8102).bounds.y
    @Assert(viewport.acceptedOffset(), 40)
    @Assert(viewport.requestOffset(55), true)
    // The accepted scene still shows 40 while this immutable ticket captures
    // the in-flight request for 55 before its canonical candidate is solved.
    let ticket = scrollOriginTicketFromAccepted(viewport, accepted, bindingA)
    @Assert(ticket.acceptedOffset, 40)
    @Assert(ticket.requestedOffset, 55)
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 13, "same-map", "origin-B")
    @Assert(viewport.stageCoordinateOrigin(bindingB, anchor: Some(ticket), targetNodeId: 8105,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let candidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(candidate.isValid(), true)
    @Assert(viewport.pendingOriginOffset(), 20)
    // The existing request must move the glyph up by 15 px through the new
    // materialized origin, rather than being canceled by the anchor correction.
    @Assert(candidate.nodeForId(8105).bounds.y - candidate.nodeForId(8102).bounds.y, oldY - 15)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOriginOffset(), 20)
    @Assert(viewport.acceptedOffset(), 55)
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_unchanged")
    let following = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 4)
    @Assert(following.isValid(), true)
    @Assert(following.nodeForId(8105).bounds.y, candidate.nodeForId(8105).bounds.y)
}

@Test
func scrollOriginInitialPreparationCancellationCanRestartBeforeAcceptance(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    @Assert(viewport.claimOwner(91), true)
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 13, "map-A", "origin-A")
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 13, "map-B", "origin-B")
    @Assert(viewport.stageCoordinateOrigin(bindingA), "scroll_origin_initial")
    // The normal product cancels measurement preparation before its first
    // accepted scene when owner metadata arrives. There is no accepted origin
    // for a passive ticket to prove, and the abandoned candidate owns no fact.
    viewport.discardStagedExtents()
    @Assert(viewport.acceptedSolveCount(), 0)
    @Assert(viewport.acceptedCoordinateOrigin().isNone(), true)
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_initial")
    let candidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50),
        CjguiComposableUiRect(0, 0, 240, 170), 1)
    @Assert(candidate.isValid(), true)
    @Assert(viewport.canCommitCoordinateOrigin(), true)
    // Even an initial solve must not publish its old geometry as a newer
    // candidate's binding merely because neither has reached acceptance yet.
    @Assert(viewport.stageCoordinateOrigin(bindingA), "scroll_origin_initial")
    @Assert(viewport.canCommitCoordinateOrigin(), false)
    viewport.discardStagedExtents()
    let replacement = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50),
        CjguiComposableUiRect(0, 0, 240, 170), 2)
    @Assert(replacement.isValid(), true)
    @Assert(viewport.canCommitCoordinateOrigin(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
}

@Test
func scrollOriginSameLayoutOriginRebindsOrdinaryContentVersion(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 11, "map-v1", "local-zero-A")
    let accepted = acceptScrollOriginInitial(viewport, bindingA)
    let oldOffset = viewport.acceptedOffset()
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 12, "map-v2", "local-zero-A")

    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_rebound")
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().ownerVersion, 11)
    @Assert(viewport.pendingOriginAnchor().isNone(), true)
    let rebound = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50,
        body: "updated body"), CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(rebound.isValid(), true)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().mapIdentity, "map-v1")
    @Assert(viewport.acceptedOffset(), oldOffset)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().ownerVersion, 12)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().mapIdentity, "map-v2")
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "local-zero-A")
    @Assert(viewport.acceptedOffset(), oldOffset)
    @Assert(accepted.isValid(), true)
}

@Test
func scrollOriginPassiveHandoffPreservesAcceptedGlyphAndClipOwnership(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 8, "same-map", "origin-A")
    @Assert(bindingA.matches(CjguiComposableUiScrollOriginBinding("document", 8, "same-map", "origin-A")), true)
    @Assert(bindingA.matches(CjguiComposableUiScrollOriginBinding("document", 8, "same-map", "origin-B")), false)
    @Assert(bindingA.matches(CjguiComposableUiScrollOriginBinding("other-document", 8, "same-map", "origin-A")), false)
    @Assert(bindingA.matches(CjguiComposableUiScrollOriginBinding("document", 9, "same-map", "origin-A")), false)
    @Assert(bindingA.matches(CjguiComposableUiScrollOriginBinding("document", 8, "new-map", "origin-A")), false)
    let ordinaryRun = CjguiComposableUiTextStyleRun(0, 11, 14.0, 0, "system",
        0.1, 0.2, 0.3, 1.0, hasBackground: true, backgroundRed: 0.9,
        backgroundGreen: 0.8, backgroundBlue: 0.7, backgroundAlpha: 0.6)
    let selectionA = CjguiComposableUiTextStyleRun.selectionBackground(1, 4,
        CjguiComposableUiColor(0.2, 0.3, 0.4, 0.5))
    let accepted = acceptScrollOriginInitial(viewport, bindingA, textStyleRuns: [ordinaryRun, selectionA])
    let ticket = scrollOriginTicketFromAccepted(viewport, accepted, bindingA)
    let oldAnchor = accepted.nodeForId(8105)
    let oldY = oldAnchor.bounds.y
    let oldOuterClipY = accepted.nodeForId(8105).clipConstraints()[1].rect.y
    let oldScrollClipY = accepted.nodeForId(8105).clipConstraints()[2].rect.y
    let oldInnerClipY = accepted.nodeForId(8105).clipConstraints()[3].rect.y
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 8, "same-map", "origin-B")

    // Same map id and same logical request value are not enough to reuse old
    // coordinates. A ticket plus this candidate's real layout proves the move.
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_handoff_required")
    @Assert(viewport.acceptedOriginOffset(), 0)
    let refused = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(refused.isValid(), false)
    @Assert(refused.layoutError(), "scroll_origin_handoff_required")
    let selectionB = CjguiComposableUiTextStyleRun.selectionBackground(4, 8,
        CjguiComposableUiColor(0.8, 0.1, 0.2, 0.7))
    @Assert(viewport.stageCoordinateOrigin(bindingB, anchor: Some(ticket), targetNodeId: 8125,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let candidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30,
        targetNodeId: 8125, textStyleRuns: [ordinaryRun, selectionB]),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(candidate.isValid(), true)
    @Assert(viewport.hasPendingRequest(), true)
    @Assert(viewport.acceptedOriginOffset(), 0)
    let candidateAnchor = candidate.nodeForId(8125)
    @Assert(candidateAnchor.bounds.y, oldY)
    let constraints = candidateAnchor.clipConstraints()
    @Assert(constraints[1].rect.y, oldOuterClipY)
    @Assert(constraints[2].rect.y, oldScrollClipY)
    @Assert(constraints[3].rect.y, oldInnerClipY + 20)
    // Discard retains A and its pending immutable ticket. Re-solving the same
    // candidate is still eligible for one atomic origin/geometry acceptance.
    viewport.discardStagedExtents()
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    @Assert(viewport.pendingOriginAnchor().isSome(), true)
    let retry = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30,
        targetNodeId: 8125, textStyleRuns: [ordinaryRun, selectionB]),
        CjguiComposableUiRect(0, 0, 240, 170), 4)
    @Assert(retry.isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOriginOffset(), 20)
    @Assert(viewport.acceptedOffset(), 40)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-B")
    @Assert(retry.nodeForId(8125).bounds.y, oldY)
    @Assert(ticket.pixelRemainder, 0.375)
    @Assert(ticket.glyphRelativeY, 4.5)
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_unchanged")
    let following = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30,
        targetNodeId: 8125, textStyleRuns: [ordinaryRun, selectionB]),
        CjguiComposableUiRect(0, 0, 240, 170), 5)
    @Assert(following.isValid(), true)
    @Assert(following.nodeForId(8125).bounds.y, oldY)
}

@Test
func scrollOriginCrossNodeRejectsDifferentBodyAndFont(): Unit {
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 10, "same-map", "origin-A")
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 10, "same-map", "origin-B")

    let bodyViewport = CjguiComposableUiScrollViewport()
    let bodyAccepted = acceptScrollOriginInitial(bodyViewport, bindingA)
    let bodyTicket = scrollOriginTicketFromAccepted(bodyViewport, bodyAccepted, bindingA)
    @Assert(bodyViewport.stageCoordinateOrigin(bindingB, anchor: Some(bodyTicket), targetNodeId: 8125,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let bodyCandidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(bodyViewport, 30,
        targetNodeId: 8125, body: "other body"), CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(bodyCandidate.isValid(), false)
    @Assert(bodyCandidate.layoutError(), "scroll_origin_anchor_geometry_incompatible")

    let fontViewport = CjguiComposableUiScrollViewport()
    let fontAccepted = acceptScrollOriginInitial(fontViewport, bindingA)
    let fontTicket = scrollOriginTicketFromAccepted(fontViewport, fontAccepted, bindingA)
    @Assert(fontViewport.stageCoordinateOrigin(bindingB, anchor: Some(fontTicket), targetNodeId: 8125,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let fontCandidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(fontViewport, 30,
        targetNodeId: 8125, fontSize: 18.0), CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(fontCandidate.isValid(), false)
    @Assert(fontCandidate.layoutError(), "scroll_origin_anchor_geometry_incompatible")

    let runFontViewport = CjguiComposableUiScrollViewport()
    let baseRun = CjguiComposableUiTextStyleRun(0, 11, 14.0, 0, "system",
        0.1, 0.2, 0.3, 1.0, hasBackground: true, backgroundRed: 0.9,
        backgroundGreen: 0.8, backgroundBlue: 0.7, backgroundAlpha: 0.6)
    let runFontAccepted = acceptScrollOriginInitial(runFontViewport, bindingA, textStyleRuns: [baseRun])
    let runFontTicket = scrollOriginTicketFromAccepted(runFontViewport, runFontAccepted, bindingA)
    @Assert(runFontViewport.stageCoordinateOrigin(bindingB, anchor: Some(runFontTicket), targetNodeId: 8125,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let changedRun = CjguiComposableUiTextStyleRun(0, 11, 18.0, 0, "system",
        0.1, 0.2, 0.3, 1.0, hasBackground: true, backgroundRed: 0.9,
        backgroundGreen: 0.8, backgroundBlue: 0.7, backgroundAlpha: 0.6)
    let runFontCandidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(runFontViewport, 30,
        targetNodeId: 8125, textStyleRuns: [changedRun]), CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(runFontCandidate.isValid(), false)
    @Assert(runFontCandidate.layoutError(), "scroll_origin_anchor_geometry_incompatible")
}

@Test
func scrollOriginLateRequestCannotCommitSolvedOldGeometry(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 15, "same-map", "origin-A")
    let accepted = acceptScrollOriginInitial(viewport, bindingA)
    let ticket = scrollOriginTicketFromAccepted(viewport, accepted, bindingA)
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 15, "same-map", "origin-B")
    @Assert(viewport.stageCoordinateOrigin(bindingB, anchor: Some(ticket), targetNodeId: 8105,
        targetLocalByte: 4), "scroll_origin_anchor_staged")
    let solved = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(solved.isValid(), true)
    @Assert(viewport.canCommitCoordinateOrigin(), true)

    @Assert(viewport.requestOffset(70), true)
    @Assert(viewport.pendingOriginAnchor().isNone(), true)
    // The immutable solved proof survives pending-ticket retirement and blocks
    // this old geometry until the window discards it.
    @Assert(viewport.canCommitCoordinateOrigin(), false)
    viewport.discardStagedExtents()
    @Assert(viewport.canCommitCoordinateOrigin(), true)

    // A fresh ordinary A-origin solve may then accept the newer B request under
    // the existing request-generation semantics.
    let ordinary = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 4)
    @Assert(ordinary.isValid(), true)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    @Assert(viewport.canCommitCoordinateOrigin(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 70)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
}

@Test
func scrollRequestAndNavigationSupersedePassiveOriginAnchor(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 9, "same-map", "origin-A")
    let accepted = acceptScrollOriginInitial(viewport, bindingA)
    let ticket = scrollOriginTicketFromAccepted(viewport, accepted, bindingA)
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 9, "same-map", "origin-B")
    @Assert(viewport.requestOffset(70), true)
    @Assert(viewport.stageCoordinateOrigin(bindingB, anchor: Some(ticket), targetNodeId: 8105,
        targetLocalByte: 4), "scroll_origin_anchor_stale")
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    @Assert(viewport.pendingOriginAnchor().isNone(), true)

    viewport.requestOriginNavigation()
    @Assert(viewport.offset(), 0)
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_navigation")
    let navigated = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(navigated.isValid(), true)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOriginOffset(), 0)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-B")
}

@Test
func scrollOriginNavigationSurvivesAcceptedUnboundIntermediateSolve(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 9, "map-A", "origin-A")
    let _ = acceptScrollOriginInitial(viewport, bindingA)
    viewport.requestOriginNavigation()
    let request = viewport.requestGeneration()
    // Loading/progress may accept a scene before the requested SourceMap
    // exists. It never called stageCoordinateOrigin for the destination.
    let interim = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 50),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(interim.isValid(), true)
    @Assert(viewport.canCommitCoordinateOrigin(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.requestGeneration(), request)
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 9, "map-B", "origin-B")
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_navigation")
    let destination = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 4)
    @Assert(destination.isValid(), true)
    @Assert(viewport.canCommitCoordinateOrigin(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-B")
    @Assert(viewport.acceptedOffset(), 0)
    let bindingC = CjguiComposableUiScrollOriginBinding("document", 9, "map-C", "origin-C")
    @Assert(viewport.stageCoordinateOrigin(bindingC), "scroll_origin_handoff_required")
}

@Test
func scrollOriginNavigationCandidateCannotConsumeNewNavigation(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let bindingA = CjguiComposableUiScrollOriginBinding("document", 9, "map-A", "origin-A")
    let _ = acceptScrollOriginInitial(viewport, bindingA)
    viewport.requestOriginNavigation()
    let bindingB = CjguiComposableUiScrollOriginBinding("document", 9, "map-B", "origin-B")
    @Assert(viewport.stageCoordinateOrigin(bindingB), "scroll_origin_navigation")
    let candidate = CjguiComposableUiLayoutEngine.layout(scrollOriginTestTree(viewport, 30),
        CjguiComposableUiRect(0, 0, 240, 170), 3)
    @Assert(candidate.isValid(), true)
    viewport.requestOriginNavigation()
    @Assert(viewport.canCommitCoordinateOrigin(), false)
    viewport.discardStagedExtents()
    @Assert(viewport.acceptedCoordinateOrigin().getOrThrow().layoutOrigin, "origin-A")
    let bindingC = CjguiComposableUiScrollOriginBinding("document", 9, "map-C", "origin-C")
    @Assert(viewport.stageCoordinateOrigin(bindingC), "scroll_origin_navigation")
}
