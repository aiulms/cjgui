package cjgui

private class BoundFixedViewportTestSource <: CjguiComposableUiVirtualListSource {
    var prepend: Int64 = 0
    public func itemCount(): Int64 { return 100 + prepend }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (prepend > 0 && index == 0) { return CjguiComposableUiVirtualListItem("new", 1000, "new") }
        let original = index - prepend
        return CjguiComposableUiVirtualListItem("item-${original}", original, "item ${original}")
    }
    public func indexForKey(key: String): Int64 {
        if (key == "stale-key") { return 0 }
        for (index in 0..100) {
            if (key == "item-${index}") { return index + prepend }
        }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(10000 + item.resourceId, "row-${item.resourceId}", item.title,
            CjguiComposableUiStyle(fixedHeight: 20))
    }
}

@Test
func collectionBoundFixedAdoptsSharedViewportRequest(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(2000, 100, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.requestOffset(200), true)
    let state = CjguiComposableUiVirtualListState()
    let source = BoundFixedViewportTestSource()
    // The lower-level Node form already permits this production binding. The
    // fixed-list solver must honor it just as the variable-height solver does.
    let node = CjguiComposableUiNode(100, "bound-list", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100), scrollOffset: state.scrollOffset(),
        scrollViewport: Some(viewport), virtualListSource: Some(source), virtualListState: Some(state),
        virtualListContentNodeId: 101, virtualListRowHeight: 20, virtualListRowGap: 0,
        virtualListOverscan: 0, semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_SCROLL_AREA)
    let scene = CjguiComposableUiLayoutEngine.layout(node, CjguiComposableUiRect(0, 0, 200, 100), 1)
    @Assert(scene.isValid(), true)
    @Assert(state.scrollOffset(), 200)
    @Assert(state.materializedStart(), 10)
    @Assert(viewport.acceptedOffset(), 0)
}

@Test
func collectionFixedRevealRejectsStaleSourceKeyWithoutMutation(): Unit {
    let source = BoundFixedViewportTestSource()
    let state = CjguiComposableUiVirtualListState()
    state.scrollToIndex(4)
    let before = state.scrollOffset()
    @Assert(state.revealKey(source, "stale-key"), false)
    @Assert(state.scrollOffset(), before)
    @Assert(state.selectedKey(), "")
    @Assert(state.focusedKey(), "")
}

@Test
func collectionFixedStableKeyReorderUsesCandidateOffset(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let state = CjguiComposableUiVirtualListState()
    let source = BoundFixedViewportTestSource()
    let node = CjguiComposableUiNode(100, "bound-list", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100), scrollViewport: Some(viewport),
        virtualListSource: Some(source), virtualListState: Some(state), virtualListContentNodeId: 101,
        virtualListRowHeight: 20, virtualListRowGap: 0, virtualListOverscan: 0,
        semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_SCROLL_AREA)
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    @Assert(CjguiComposableUiLayoutEngine.layout(node, bounds, 1).isValid(), true)
    viewport.commitStagedExtents()
    @Assert(state.revealKey(source, "item-10"), true)
    @Assert(viewport.requestOffset(state.scrollOffset()), true)
    @Assert(CjguiComposableUiLayoutEngine.layout(node, bounds, 2).isValid(), true)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 200)
    source.prepend = 1
    let candidate = CjguiComposableUiLayoutEngine.layout(node, bounds, 3)
    @Assert(candidate.isValid(), true)
    @Assert(state.scrollOffset(), 220)
    @Assert(viewport.acceptedOffset(), 200)
    @Assert(candidate.nodeForId(10010).bounds.y, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 220)
}

private class BoundVariableViewportTestSource <: CjguiComposableUiVariableHeightListSource {
    public func itemCount(): Int64 { return 100 }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        return CjguiComposableUiVariableHeightListItem("row-${index}", index, "row ${index}", 1,
            estimatedHeight: if (index % 2 == 0) { 20 } else { 40 })
    }
    public func indexForKey(key: String): Int64 {
        for (index in 0..100) { if (key == "row-${index}") { return index } }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(20000 + item.resourceId, "var-${item.resourceId}", item.title,
            CjguiComposableUiStyle(fixedHeight: if (item.resourceId % 2 == 0) { 20 } else { 40 }))
    }
}

@Test
func collectionPublicFactoriesBindViewportAndKeepLegacySignatures(): Unit {
    let fixedSource = BoundFixedViewportTestSource()
    let variableSource = BoundVariableViewportTestSource()
    let fixedState = CjguiComposableUiVirtualListState()
    let variableState = CjguiComposableUiVirtualListState()
    let viewport = CjguiComposableUiScrollViewport()
    let style = CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100)
    let legacyFixed = cjguiComposableVirtualList(100, "old-fixed", 101, fixedSource, fixedState,
        20, 0, 0, style)
    let legacyVariable = cjguiComposableVariableHeightList(200, "old-variable", 201, variableSource, variableState,
        20, 0, 0, style)
    @Assert(legacyFixed.scrollViewport.isNone(), true)
    @Assert(legacyVariable.scrollViewport.isNone(), true)
    let fixed = cjguiComposableVirtualList(100, "fixed", 101, viewport, fixedSource, fixedState,
        20, 0, 0, style)
    let variable = cjguiComposableVariableHeightList(200, "variable", 201, viewport, variableSource, variableState,
        20, 0, 0, style)
    @Assert(refEq(fixed.scrollViewport.getOrThrow(), viewport), true)
    @Assert(refEq(variable.scrollViewport.getOrThrow(), viewport), true)
}

@Test
func collectionSameGeometryViewportIdentityAndVariableRows(): Unit {
    let first = CjguiComposableUiScrollViewport()
    let second = CjguiComposableUiScrollViewport()
    first.stageExtents(3000, 100, 0)
    first.commitStagedExtents()
    second.stageExtents(3000, 100, 0)
    second.commitStagedExtents()
    @Assert(first.requestOffset(120), true)
    @Assert(second.requestOffset(280), true)
    let state = CjguiComposableUiVirtualListState()
    let source = BoundFixedViewportTestSource()
    let style = CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100)
    let bounds = CjguiComposableUiRect(0, 0, 200, 100)
    let firstNode = cjguiComposableVirtualList(100, "list-a", 101, first, source, state, 20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(firstNode, bounds, 1).isValid(), true)
    @Assert(state.scrollOffset(), 120)
    let secondNode = cjguiComposableVirtualList(200, "list-b", 201, second, source, state, 20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(secondNode, bounds, 2).isValid(), true)
    @Assert(state.scrollOffset(), 280)
    @Assert(first.acceptedOffset(), 0)
    @Assert(second.acceptedOffset(), 0)
    let variableState = CjguiComposableUiVirtualListState()
    let variableSource = BoundVariableViewportTestSource()
    let variable = cjguiComposableVariableHeightList(300, "variable", 301, first, variableSource,
        variableState, 20, 0, 0, style)
    @Assert(CjguiComposableUiLayoutEngine.layout(variable, bounds, 3).isValid(), true)
    @Assert(variableState.scrollOffset() > 0, true)
    @Assert(first.acceptedOffset(), 0)
    @Assert(variableState.revealKey(variableSource, "missing"), false)
    @Assert(variableState.selectedKey(), "")
    @Assert(variableState.focusedKey(), "")
}

@Test
func collectionFixedPreparedCandidateFreezesAndRejectsNewerRequest(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(2000, 100, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.requestOffset(200), true)
    let source = BoundFixedViewportTestSource()
    let state = CjguiComposableUiVirtualListState()
    let node = cjguiComposableVirtualList(100, "list", 101, viewport, source, state, 20, 0, 0,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 100))
    let registry = CjguiComposableUiIdentityRegistry()
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(node), "")
    cjguiFreezePreparedLayoutInputs(node, 200, 100, registry)
    @Assert(viewport.requestOffset(400), true)
    let result = CjguiComposableUiLayoutEngine.layout(node, CjguiComposableUiRect(0, 0, 200, 100), 1)
    @Assert(result.isValid(), true)
    let inputs = node.preparedLayoutInputs.getOrThrow()
    @Assert(inputs.workingState.getOrThrow().scrollOffset(), 200)
    @Assert(inputs.matches(), false)
    @Assert(state.scrollOffset(), 0)
    viewport.discardStagedExtents()
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.offset(), 400)
}
