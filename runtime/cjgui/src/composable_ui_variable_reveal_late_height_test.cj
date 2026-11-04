package cjgui

class LateHeightRevealSource <: CjguiComposableUiVariableHeightListSource {
    let finalHeight: Int64
    init(finalHeight: Int64) { this.finalHeight = finalHeight }
    public func itemCount(): Int64 { return 20 }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        return CjguiComposableUiVariableHeightListItem("item-${index}", index, "item ${index}", 1,
            estimatedHeight: 20)
    }
    public func indexForKey(key: String): Int64 {
        for (index in 0..20) { if (key == "item-${index}") { return index } }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(40000 + item.resourceId, "late-row-${item.resourceId}", item.title,
            CjguiComposableUiStyle(fixedHeight: if (item.resourceId == 19) { finalHeight } else { 20 }))
    }
}

@Test
func variableRevealKeepsFullyFittingLastKeyAfterLateHeight(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let state = CjguiComposableUiVirtualListState()
    let source = LateHeightRevealSource(80)
    let style = CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100)
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    let initial = cjguiComposableVariableHeightList(100, "late-list", 101, viewport, source, state,
        20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(initial, bounds, 1).isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.maximumOffset(), 300)
    @Assert(state.revealKey(source, "item-19"), true)
    @Assert(viewport.requestOffset(state.scrollOffset()), true)
    // Window/generated consumers use this same bookkeeping immediately after
    // their successful reveal request, before freezing a candidate.
    state.completeRevealViewportRequest(viewport)
    @Assert(viewport.offset(), 300)
    @Assert(viewport.acceptedOffset(), 0)
    let candidate = cjguiComposableVariableHeightList(100, "late-list", 101, viewport, source, state,
        20, 0, 0, style)
    let scene = CjguiComposableUiLayoutEngine.layout(candidate, bounds, 2)
    @Assert(scene.isValid(), true)
    let target = scene.nodeForId(40019)
    @Assert(target.nodeId, 40019)
    @Assert(target.bounds.height, 80)
    @Assert(target.bounds.y >= 0, true)
    @Assert(target.bounds.y + target.bounds.height <= 100, true)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(state.selectedKey(), "")
    @Assert(state.focusedKey(), "")
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 360)
    // A later genuine viewport request gets a new generation and remains a
    // user scroll, not a continuation of the earlier semantic reveal.
    @Assert(viewport.requestOffset(100), true)
    let wheelNode = cjguiComposableVariableHeightList(100, "late-list", 101, viewport, source, state,
        20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(wheelNode, bounds, 3).isValid(), true)
    @Assert(state.scrollOffset(), 100)
    @Assert(viewport.acceptedOffset(), 360)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 100)
}

@Test
func variableRevealTallLastRowIsLegitimatelyClipped(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let state = CjguiComposableUiVirtualListState()
    let source = LateHeightRevealSource(160)
    let style = CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100)
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    let initial = cjguiComposableVariableHeightList(100, "late-list", 101, viewport, source, state,
        20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(initial, bounds, 1).isValid(), true)
    viewport.commitStagedExtents()
    @Assert(state.revealKey(source, "item-19"), true)
    @Assert(viewport.requestOffset(state.scrollOffset()), true)
    state.completeRevealViewportRequest(viewport)
    let candidate = cjguiComposableVariableHeightList(100, "late-list", 101, viewport, source, state,
        20, 0, 0, style)
    let scene = CjguiComposableUiLayoutEngine.layout(candidate, bounds, 2)
    @Assert(scene.isValid(), true)
    let target = scene.nodeForId(40019)
    @Assert(target.nodeId, 40019)
    @Assert(target.bounds.height, 160)
    @Assert(target.bounds.y < 100, true)
    @Assert(target.bounds.y + target.bounds.height > 100, true)
    @Assert(viewport.acceptedOffset(), 0)
}
