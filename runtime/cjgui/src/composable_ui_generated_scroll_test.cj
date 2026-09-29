// Generated scroll container tests.
//
// What is pinned here:
//   * the CATALOG publishes a scroll container (discovery + strict property and
//     child validation), so a public client can submit one into an ordinary
//     NON-scrolling host;
//   * the builder produces a real SCROLL_AREA bound to the SAME public
//     `CjguiComposableUiScrollViewport` the handwritten tree uses, with the
//     accepted facts promoted through the viewport's own commit;
//   * the view state belongs to the stable INSTANCE key, so a second commit of
//     the same key keeps the human's scroll position, and two windows (two
//     holders over one catalog) never share one viewport.
package cjgui

import std.collection.*

private func scrollTestFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- scrollTestFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func scrollTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 32))
    let labelProperties = ArrayList<CjguiGeneratedUiPropertySpec>()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200))
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        labelProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        scrollProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
        childLimit: 1))
    return catalog
}

private func scrollTestLabel(key: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("text", "行${key}")
    return CjguiGeneratedUiNodeSpec(key, "label", properties: properties)
}

/// A structure whose scroll node declares its own initial offset and padding and
/// holds `lineCount` ordinary children — more than two screens of content.
private func scrollTestStructure(lineCount: Int64, scrollChildren!: Int64 = 1,
                                 unknownProperty!: Bool = false): CjguiGeneratedUiNodeSpec {
    let content = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index: Int64 = 0
    while (index < lineCount) {
        content.add(scrollTestLabel("line${index}"))
        index += 1
    }
    let scrollChildrenList = ArrayList<CjguiGeneratedUiNodeSpec>()
    if (scrollChildren >= 2) {
        // A second child of the scroll node itself: illegal shape.
        scrollChildrenList.add(scrollTestLabel("content"))
        scrollChildrenList.add(scrollTestLabel("extra"))
    } else {
        let group = CjguiGeneratedUiNodeSpec("content", "vertical", children: content)
        scrollChildrenList.add(group)
    }
    let scrollProperties = HashMap<String, String>()
    scrollProperties.add("offset", "40")
    if (unknownProperty) {
        scrollProperties.add("axis", "vertical")
    }
    let scroll = CjguiGeneratedUiNodeSpec("panel", "scrollArea", properties: scrollProperties,
        children: scrollChildrenList)
    let rootChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    rootChildren.add(scroll)
    return CjguiGeneratedUiNodeSpec("root", "vertical", children: rootChildren)
}

/// Accepts one structure through the real holder transaction.
private func scrollTestAccept(holder: CjguiGeneratedUiStructureHolder, provider: GeneratedTestProvider,
                              spec: CjguiGeneratedUiNodeSpec): Bool {
    if (!holder.submit(spec, provider).candidateAccepted) {
        return false
    }
    if (!holder.beginCandidateRefresh()) {
        return false
    }
    let _ = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        return false
    }
    return holder.commitCandidateRefresh()
}

@Test
func generatedScrollStructureBuildsAPublicViewportInANonScrollingHost(): Unit {
    let catalog = scrollTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(scrollTestAccept(holder, provider, scrollTestStructure(12)), true)

    let scrollNodeId = holder.nodeIdForKey("panel")
    @Assert(scrollNodeId > 0, true)
    let built = holder.buildRefreshNode(provider)
    let scrollNode = match (scrollTestFind(built, scrollNodeId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(scrollNode.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    @Assert(scrollNode.scrollViewport.isSome(), true)
    let viewport = scrollNode.scrollViewport.getOrThrow()
    // The declaration's offset is a real property, not decoration: the builder
    // reads it as the instance's INITIAL request.
    @Assert(scrollNode.scrollOffset, 40)

    // The solve stages candidate facts; the WINDOW's commit promotes them (the
    // test does exactly what the window does, through the viewport itself).
    let rootChildren = ArrayList<CjguiComposableUiNode>()
    rootChildren.add(built)
    let root = cjguiComposableHorizontal(1, "host", CjguiComposableUiStyle(gap: 0))
    for (child in rootChildren) {
        root.add(child)
    }
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, 300, 90), 2, CjguiComposableUiFallbackTextMeasurer())
    @Assert(result.scene.isValid(), true)
    @Assert(result.viewports.size > 0, true)
    @Assert(viewport.hasStagedExtents(), true)
    viewport.commitStagedExtents()
    // More than two screens of content: the viewport really clips.
    @Assert(viewport.contentExtent() > viewport.viewportExtent() * 2, true)

    // Same stable key, second commit: the SAME viewport object keeps the view
    // state, so re-submitting the structure cannot reset a human's scroll.
    @Assert(viewport.requestOffset(120), true)
    @Assert(scrollTestAccept(holder, provider, scrollTestStructure(12)), true)
    let rebuilt = holder.buildRefreshNode(provider)
    let rebuiltScroll = match (scrollTestFind(rebuilt, scrollNodeId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(rebuiltScroll.scrollViewport.getOrThrow().offset(), 120)
}

@Test
func generatedScrollRejectsIllegalShapeAndUnknownProperty(): Unit {
    let catalog = scrollTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let tooManyChildren = holder.submit(scrollTestStructure(4, scrollChildren: 2), provider)
    @Assert(tooManyChildren.candidateAccepted, false)
    @Assert(tooManyChildren.reason, "child_limit_exceeded")
    let unknownProperty = holder.submit(scrollTestStructure(4, unknownProperty: true), provider)
    @Assert(unknownProperty.candidateAccepted, false)
    @Assert(unknownProperty.reason, "unknown_property")
}

@Test
func twoHoldersDoNotShareGeneratedScrollViewportState(): Unit {
    let catalog = scrollTestCatalog()
    let provider = GeneratedTestProvider()
    let holderA = CjguiGeneratedUiStructureHolder(catalog)
    let holderB = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(scrollTestAccept(holderA, provider, scrollTestStructure(8)), true)
    @Assert(scrollTestAccept(holderB, provider, scrollTestStructure(8)), true)
    let nodeA = match (scrollTestFind(holderA.buildRefreshNode(provider), holderA.nodeIdForKey("panel"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    let nodeB = match (scrollTestFind(holderB.buildRefreshNode(provider), holderB.nodeIdForKey("panel"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    let viewportA = nodeA.scrollViewport.getOrThrow()
    let viewportB = nodeB.scrollViewport.getOrThrow()
    // One accepted solve on A only: B never sees A's accepted facts.
    viewportA.stageExtents(400, 100, 120)
    viewportA.commitStagedExtents()
    @Assert(viewportA.acceptedOffset(), 120)
    @Assert(viewportA.contentExtent(), 400)
    @Assert(viewportB.acceptedOffset(), 0)
    @Assert(viewportB.contentExtent(), 0)
    // B's own declared initial request is untouched.
    @Assert(viewportB.offset(), 40)
}

/// The generated catalog does NOT support nesting one scroll inside another: the
/// candidate is pre-rejected with its own reason instead of letting the wheel
/// route guess which viewport owns a gesture.
@Test
func generatedNestedScrollIsPreRejected(): Unit {
    let catalog = scrollTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let innerProperties = HashMap<String, String>()
    innerProperties.add("offset", "0")
    let inner = CjguiGeneratedUiNodeSpec("inner", "scrollArea", properties: innerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("line0")]))
    let outerProperties = HashMap<String, String>()
    outerProperties.add("offset", "0")
    let outer = CjguiGeneratedUiNodeSpec("outer", "scrollArea", properties: outerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([inner]))
    let result = holder.submit(CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([outer])), provider)
    @Assert(result.candidateAccepted, false)
    @Assert(result.reason, "nested_scroll_not_supported")
}

/// The nesting refusal follows the ANCESTOR chain, not just the direct children:
/// `scroll -> vertical -> scroll` used to slip past a shallow check and be
/// accepted with two viewports, which is exactly the ambiguous wheel route the
/// refusal exists to prevent. The reported path names the offending descendant.
@Test
func generatedDeeplyNestedScrollIsPreRejected(): Unit {
    let catalog = scrollTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let innerProperties = HashMap<String, String>()
    innerProperties.add("offset", "0")
    let inner = CjguiGeneratedUiNodeSpec("inner", "scrollArea", properties: innerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("line0")]))
    let middle = CjguiGeneratedUiNodeSpec("middle", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([inner]))
    let outerProperties = HashMap<String, String>()
    outerProperties.add("offset", "0")
    let outer = CjguiGeneratedUiNodeSpec("outer", "scrollArea", properties: outerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([middle]))
    let result = holder.submit(CjguiGeneratedUiNodeSpec("main", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([outer])), provider)
    @Assert(result.candidateAccepted, false)
    @Assert(result.reason, "nested_scroll_not_supported")
    // The path names the real offending descendant, through the intermediate
    // container, not just the direct child.
    @Assert(result.path, "root/main/outer/middle/inner")
    // Two scrolls that are SIBLINGS (neither is a descendant of the other) stay
    // legal: the refusal is about one viewport nesting another, not about count.
    let leftScroll = CjguiGeneratedUiNodeSpec("left", "scrollArea", properties: outerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("line1")]))
    let rightScroll = CjguiGeneratedUiNodeSpec("right", "scrollArea", properties: outerProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("line2")]))
    let siblings = ArrayList<CjguiGeneratedUiNodeSpec>()
    siblings.add(leftScroll)
    siblings.add(rightScroll)
    let accepted = holder.submit(CjguiGeneratedUiNodeSpec("main2", "vertical", children: siblings), provider)
    @Assert(accepted.candidateAccepted, true)
}

/// The generated split container: two declared children, the scoped split view
/// (divider identity from the scope), and a clear refusal for an illegal shape.
private func splitTestFindSplit(node: CjguiComposableUiNode): ?CjguiComposableUiNode {
    if (node.isSplitView()) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- splitTestFindSplit(child)) {
            return Some(found)
        }
    }
    return None
}

private func splitTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = scrollTestCatalog()
    let splitProperties = CjguiGeneratedUiPresentation.splitContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        splitProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("split", splitProperties, true,
        childLimit: 2))
    return catalog
}

private func splitTestStructure(childCount: Int64, unknownProperty!: Bool = false):
    CjguiGeneratedUiNodeSpec {
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index: Int64 = 0
    while (index < childCount) {
        children.add(CjguiGeneratedUiNodeSpec("pane${index}", "vertical",
            children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("row${index}")])))
        index += 1
    }
    let properties = HashMap<String, String>()
    properties.add("firstSize", "140")
    properties.add("firstMinimum", "80")
    properties.add("secondMinimum", "90")
    if (unknownProperty) {
        properties.add("ratio", "50")
    }
    let split = CjguiGeneratedUiNodeSpec("split", "split", properties: properties, children: children)
    return CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([split]))
}

/// The same split shape, with the bounds the AUTHOR declares expressed exactly:
/// `None` means the property is ABSENT from the description, `Some(0)` is a legal
/// minimum of zero.
private func splitTestStructureWithBounds(firstSize: Int64, firstMinimum!: ?Int64 = None,
    secondMinimum!: ?Int64 = None): CjguiGeneratedUiNodeSpec {
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("pane0", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("row0")])))
    children.add(CjguiGeneratedUiNodeSpec("pane1", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("row1")])))
    let properties = HashMap<String, String>()
    properties.add("firstSize", "${firstSize}")
    if (let Some(value) <- firstMinimum) {
        properties.add("firstMinimum", "${value}")
    }
    if (let Some(value) <- secondMinimum) {
        properties.add("secondMinimum", "${value}")
    }
    let split = CjguiGeneratedUiNodeSpec("split", "split", properties: properties, children: children)
    return CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([split]))
}

@Test
func generatedSplitBuildsTheScopedSplitViewFromTwoChildren(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let submitted = holder.submit(splitTestStructure(2), provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let built = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let split = match (splitTestFindSplit(built)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    // The scoped split adds its own handle node, so two panes yield >= 3 nodes.
    @Assert(split.isSplitView(), true)
    // The public generated key must address the actual accepted container;
    // a scoped-only synthetic id made geometry discovery report a ghost node.
    @Assert(split.nodeId, holder.nodeIdForKey("split"))
    @Assert(split.children().size >= 2, true)
    // The instance's shared view state is reachable from the divider itself,
    // which is how a real drag reaches the next solve. The container and the
    // handle carry the SAME state object.
    @Assert(split.splitState.isSome(), true)
    @Assert(split.children()[1].splitState.isSome(), true)

    // An illegal shape and an unconsumed property are refused as a whole.
    let oneChild = holder.submit(splitTestStructure(1), provider)
    @Assert(oneChild.candidateAccepted, false)
    @Assert(oneChild.reason, "split_requires_two_children")
    let unknown = holder.submit(splitTestStructure(2, unknownProperty: true), provider)
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "unknown_property")
}

/// The declaration's `firstSize` only seeds a NEW split instance: after a human
/// size change the instance keeps its own value, and two instances never share it.
@Test
func generatedSplitKeepsItsInstanceSizeAcrossRefreshes(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(holder.splitSizeForInstance("split", 180), 180)
    // A human drag (or the keyboard rule) records the new size once.
    holder.updateSplitSizeForInstance("split", 260)
    @Assert(holder.splitSizeForInstance("split", 180), 260)
    @Assert(scrollTestAccept(holder, provider, splitTestStructure(2)), true)
    // Re-submitting the same declaration does not overwrite it.
    @Assert(holder.splitSizeForInstance("split", 180), 260)
    // Another instance never inherits it.
    @Assert(holder.splitSizeForInstance("other", 180), 180)
    // Removing an instance frees its view state.
    holder.retainSplitSizesFor(ArrayList<String>(["other"]))
    @Assert(holder.splitSizeForInstance("split", 120), 120)
}

/// A generated split whose TWO panes are generated scroll containers: each side
/// gets its own public viewport, and the split itself is one scoped split view.
@Test
func generatedSplitWithScrollingPanesBuildsIndependentViewports(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let leftScroll = CjguiGeneratedUiNodeSpec("leftScroll", "scrollArea",
        properties: HashMap<String, String>([("offset", "0")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("leftContent", "vertical",
                children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("l0"), scrollTestLabel("l1")]))
        ]))
    let rightScroll = CjguiGeneratedUiNodeSpec("rightScroll", "scrollArea",
        properties: HashMap<String, String>([("offset", "0")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("rightContent", "vertical",
                children: ArrayList<CjguiGeneratedUiNodeSpec>([scrollTestLabel("r0"), scrollTestLabel("r1")]))
        ]))
    let split = CjguiGeneratedUiNodeSpec("split", "split",
        properties: HashMap<String, String>([("firstSize", "160")]), children:
        ArrayList<CjguiGeneratedUiNodeSpec>([leftScroll, rightScroll]))
    let root = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([split]))
    let submitted = holder.submit(root, provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let built = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let splitNode = match (splitTestFindSplit(built)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(splitNode.isSplitView(), true)
    let leftNode = match (scrollTestFind(built, holder.nodeIdForKey("leftScroll"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    let rightNode = match (scrollTestFind(built, holder.nodeIdForKey("rightScroll"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(leftNode.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    @Assert(rightNode.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
    // Each pane owns its OWN viewport: a request on one never moves the other.
    let leftViewport = leftNode.scrollViewport.getOrThrow()
    let rightViewport = rightNode.scrollViewport.getOrThrow()
    leftViewport.stageExtents(300, 100, 80)
    leftViewport.commitStagedExtents()
    @Assert(leftViewport.acceptedOffset(), 80)
    @Assert(rightViewport.acceptedOffset(), 0)
}

/// The generated split's view state uses the SAME size rule as the layout
/// (`CjguiComposableUiSplitGeometry.firstSizeForTrack`): BOTH declared minimums
/// and the real track bound the value, so the size the state records is exactly
/// the width the layout solves. A second, laxer rule here used to record 492
/// while the scene only ever showed 372.
@Test
func generatedSplitStateAppliesTheLayoutSizeRule(): Unit {
    let state = CjguiComposableUiSplitState(180, 120, 120)
    @Assert(state.firstSize(), 180)
    // A requested size below the first minimum keeps the minimum.
    @Assert(state.applyFirstSize(40, 1000, 8), 120)
    // 500-track minus 8 handle minus the SECOND minimum (120) bounds the first
    // pane at 372 - the same number the layout really allocates.
    @Assert(state.applyFirstSize(9000, 500, 8), 372)
    // A track narrower than both minimums cannot honour the second minimum, so the
    // rule degrades to the first minimum instead of an impossible width.
    @Assert(state.applyFirstSize(600, 200, 8), 120)
    @Assert(state.firstSize(), 120)
    // The keyboard path shares the same rule against the ACCEPTED track.
    state.acceptSplitTrack(500, 8, 372)
    @Assert(state.applyAcceptedFirstSize(9000), 372)
    @Assert(state.acceptedFirstSize(), 372)
    @Assert(state.applyAcceptedFirstSize(200), 200)
    @Assert(state.firstSize(), 200)
    // The same rule serves the keyboard path: +8 on a wide track stays +8.
    @Assert(state.applyFirstSize(state.firstSize() + 8, 1000, 8), 208)
}

/// A legal re-declaration of the SAME split key that changes the CONSTRAINTS must
/// be consumed by the existing instance: the person's own size is preserved, and
/// the new minimums (with the real track) bound it from then on.
@Test
func generatedSplitConsumesNewDeclaredConstraintsForAnExistingInstance(): Unit {
    let catalog = splitTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let state = holder.splitStateForInstance("split", 200, firstMinimum: 80, secondMinimum: 80)
    @Assert(state.firstMinimum(), 80)
    @Assert(state.secondMinimum(), 80)
    state.setFirstSize(300)
    // The SAME key re-declares wider minimums.
    let reused = holder.splitStateForInstance("split", 200, firstMinimum: 260, secondMinimum: 260)
    @Assert(reused.firstMinimum(), 260)
    @Assert(reused.secondMinimum(), 260)
    @Assert(reused.firstSize(), 300)
    // It is the SAME instance, not a fresh one.
    holder.splitStateForInstance("split", 200).setFirstSize(111)
    @Assert(holder.splitSizeForInstance("split", 200), 111)
    // The ONE rule bounds the preserved size with the NEW minimums: on a 500 track
    // the second minimum forces the first pane back to its own minimum.
    @Assert(reused.applyFirstSize(300, 500, 8), 260)
    // On a wider track the preserved size is legal.
    @Assert(reused.applyFirstSize(300, 1000, 8), 300)
}

/// A plain split whose author bound shared view state, used to pin the layout
/// half of the contract without a generated structure or a window.
private func splitStateLayoutTree(state: CjguiComposableUiSplitState): CjguiComposableUiNode {
    let container = CjguiComposableUiNode(1, "split-state-root", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
        CjguiComposableUiStyle(growX: 1, growY: 1), pointerControlRole: "split_view",
        pointerControlAxis: CjguiComposableUiSplitAxis.HORIZONTAL, pointerControlMinimum: 40,
        pointerControlFirstSize: state.firstSize(), pointerControlHandleThickness: 8,
        pointerControlSecondMinimum: 40, splitState: state)
    container.add(cjguiComposableText(101, "left-pane", "left", CjguiComposableUiStyle()))
    container.add(CjguiComposableUiNode(2, "split-state-root-handle", CJGUI_COMPOSABLE_UI_SPLIT_HANDLE, "", "",
        "SPLIT_HANDLE", -1, CjguiComposableUiStyle(fixedWidth: 8, growY: 1), pointerControlRole: "split_handle",
        pointerControlAxis: CjguiComposableUiSplitAxis.HORIZONTAL, pointerControlMinimum: 40,
        pointerControlFirstSize: state.firstSize(), pointerControlHandleThickness: 8,
        pointerControlSecondMinimum: 40))
    container.add(cjguiComposableText(102, "right-pane", "right", CjguiComposableUiStyle()))
    return container
}

/// The accepted track a real drag is clamped against comes from the scene the
/// window ACCEPTED: a candidate solve only stages it, an instance size change is
/// presented by the next solve without rebuilding, and a narrow window degrades
/// inside bounds instead of at a sample width.
@Test
func splitLayoutStagesTheRealTrackAndKeepsTheInstanceState(): Unit {
    let state = CjguiComposableUiSplitState(180, 40, 40)
    // Before any accepted layout only the declared minimums bound a request; no
    // sample track is invented.
    @Assert(state.acceptedTrack(), 0)
    let untracked = CjguiComposableUiSplitState(180, 40, 40)
    @Assert(untracked.applyAcceptedFirstSize(0), 40)
    @Assert(untracked.firstSize(), 40)
    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(splitStateLayoutTree(state),
        CjguiComposableUiRect(0, 0, 500, 200), 1, CjguiComposableUiFallbackTextMeasurer())
    @Assert(first.scene.isValid(), true)
    // The candidate solve staged exactly one track fact and published nothing.
    @Assert(first.splitTracks.size, 1)
    @Assert(state.acceptedTrack(), 0)
    @Assert(first.splitTracks[0].track, 500)
    @Assert(first.splitTracks[0].handleSize, 8)
    @Assert(first.scene.nodeForId(101).bounds.width, 180)
    @Assert(first.scene.nodeForId(102).bounds.x, 188)
    // Only acceptance makes the real track the drag bound.
    first.splitTracks[0].state.acceptSplitTrack(first.splitTracks[0].track, first.splitTracks[0].handleSize,
        first.splitTracks[0].firstSize)
    @Assert(state.acceptedTrack(), 500)
    @Assert(state.acceptedHandleSize(), 8)
    // The staged fact carries the width the solve really allocated, and the
    // accepted geometry keeps it after promotion.
    @Assert(first.splitTracks[0].firstSize, 180)
    @Assert(state.acceptedFirstSize(), 180)
    // min 40/40 on a 500 track with an 8 handle bounds the first pane at 452.
    @Assert(state.applyAcceptedFirstSize(900), 452)
    @Assert(state.applyAcceptedFirstSize(400), 400)
    // The next solve presents the instance size without any rebuild, and without
    // touching the accepted track.
    let second = CjguiComposableUiLayoutEngine.layoutWithMetrics(splitStateLayoutTree(state),
        CjguiComposableUiRect(0, 0, 500, 200), 2, CjguiComposableUiFallbackTextMeasurer())
    @Assert(second.scene.isValid(), true)
    @Assert(second.scene.nodeForId(101).bounds.width, 400)
    @Assert(second.scene.nodeForId(102).bounds.x, 408)
    // A trial solve on a narrow track only stages its own bounds: the accepted
    // track is untouched and both panes stay inside the real width.
    let narrow = CjguiComposableUiLayoutEngine.layoutWithMetrics(splitStateLayoutTree(state),
        CjguiComposableUiRect(0, 0, 120, 200), 3, CjguiComposableUiFallbackTextMeasurer())
    @Assert(narrow.scene.isValid(), true)
    @Assert(narrow.splitTracks.size, 1)
    @Assert(narrow.splitTracks[0].track, 120)
    @Assert(state.acceptedTrack(), 500)
    let left = narrow.scene.nodeForId(101)
    let right = narrow.scene.nodeForId(102)
    @Assert(left.bounds.width > 0, true)
    @Assert(right.bounds.width > 0, true)
    @Assert(left.bounds.width + 8 + right.bounds.width <= 120, true)
}

/// Per-instance view state is released with the element: the same instance key
/// resolves to the SAME state, and once the accepted structure no longer contains
/// it a later declaration seeds a fresh one that a stale writer cannot change.
@Test
func generatedInstanceViewStateIsReleasedForRemovedElements(): Unit {
    let catalog = splitTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let seeded = holder.splitStateForInstance("split", 180, firstMinimum: 120, secondMinimum: 90)
    @Assert(seeded.firstMinimum(), 120)
    @Assert(seeded.secondMinimum(), 90)
    seeded.setFirstSize(260)
    @Assert(holder.splitStateForInstance("split", 180, firstMinimum: 120, secondMinimum: 90).firstSize(), 260)
    @Assert(holder.splitSizeForInstance("split", 180), 260)
    // A structure that no longer contains the instance releases it.
    holder.retainInstanceViewStatesFor(ArrayList<String>(["other"]))
    let fresh = holder.splitStateForInstance("split", 140, firstMinimum: 120, secondMinimum: 90)
    @Assert(fresh.firstSize(), 140)
    // The released object is no longer the holder's, so a stale writer cannot
    // reach the current instance.
    seeded.setFirstSize(999)
    @Assert(holder.splitStateForInstance("split", 140, firstMinimum: 120, secondMinimum: 90).firstSize(), 140)
    // The same release covers a scroll instance's viewport.
    let staleViewport = holder.scrollViewportForInstance("scroll", 0)
    staleViewport.requestInitialOffset(40)
    @Assert(staleViewport.offset(), 40)
    holder.retainInstanceViewStatesFor(ArrayList<String>())
    @Assert(holder.scrollViewportForInstance("scroll", 0).offset(), 0)
}

/// A1: the instance view-state tables are only SHALLOW copies, so restoring them
/// cannot undo a re-declaration that a candidate build wrote into the shared
/// object. This is the real反例: a legal accepted split, a same-key candidate that
/// widens the constraints, a candidate build, then rejection. The accepted bounds
/// and the person's own size must both survive, and only a LEGAL candidate may
/// publish new constraints.
@Test
func rejectedCandidateRestoresTheAcceptedSplitConstraintsAndKeepsTheSize(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(scrollTestAccept(holder, provider, splitTestStructureWithBounds(140, firstMinimum: 80, secondMinimum: 90)), true)
    let state = holder.splitStateForInstance("split", 140)
    @Assert(state.firstMinimum(), 80)
    @Assert(state.secondMinimum(), 90)
    // A person drags the divider: the instance owns its size from now on.
    state.setFirstSize(260)
    // The SAME key re-declares wider minimums and the candidate is really BUILT.
    @Assert(holder.submit(splitTestStructureWithBounds(140, firstMinimum: 300, secondMinimum: 300), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    // The candidate scene uses the candidate bounds, but nothing is published yet.
    @Assert(state.firstMinimum(), 300)
    @Assert(state.hasStagedBoundsDeclaration(), true)
    // The scene is rejected.
    holder.rollbackCandidateRefresh()
    @Assert(holder.hasPendingCandidate(), false)
    // The ACCEPTED contract is intact: bounds back to the accepted values, the
    // person's size untouched, no staging left armed.
    @Assert(state.firstMinimum(), 80)
    @Assert(state.secondMinimum(), 90)
    @Assert(state.firstSize(), 260)
    @Assert(state.hasStagedBoundsDeclaration(), false)
    // The old bounds still bound the ONE size rule.
    @Assert(state.applyFirstSize(300, 500, 8), 300)
    // (The rule writes the size it solved; put the person's own size back before
    // checking that a later legal candidate does not disturb it.)
    state.setFirstSize(260)
    // A LEGAL candidate with new constraints IS published with its accepted scene.
    @Assert(holder.submit(splitTestStructureWithBounds(140, firstMinimum: 40, secondMinimum: 40), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(state.firstMinimum(), 40)
    @Assert(state.secondMinimum(), 40)
    @Assert(state.firstSize(), 260)
    @Assert(state.hasStagedBoundsDeclaration(), false)
}

/// A1: superseding an uncommitted candidate must also give the accepted bounds
/// back, not only drop the candidate's new keys.
@Test
func supersededCandidateRestoresTheAcceptedSplitConstraints(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(scrollTestAccept(holder, provider, splitTestStructureWithBounds(140, firstMinimum: 80, secondMinimum: 90)), true)
    let state = holder.splitStateForInstance("split", 140)
    @Assert(state.firstMinimum(), 80)
    @Assert(holder.submit(splitTestStructureWithBounds(140, firstMinimum: 300, secondMinimum: 300), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(state.firstMinimum(), 300)
    // A SECOND candidate supersedes the first before the scene accepts it.
    @Assert(holder.submit(splitTestStructureWithBounds(140, firstMinimum: 120, secondMinimum: 120), provider).candidateAccepted, true)
    @Assert(state.firstMinimum(), 80)
    @Assert(state.hasStagedBoundsDeclaration(), false)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 120)
}

/// A1: a declaration is EXPLICIT. `0` is a legal minimum, while REMOVING the
/// property falls back to the public default instead of silently keeping an older
/// value.
@Test
func generatedSplitDeclarationTreatsZeroAsLegalAndRemovalAsTheDefault(): Unit {
    let catalog = splitTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(scrollTestAccept(holder, provider, splitTestStructureWithBounds(140, firstMinimum: 120, secondMinimum: 90)), true)
    let state = holder.splitStateForInstance("split", 140)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 90)
    // An explicit 0 is a real minimum, not "undeclared".
    @Assert(scrollTestAccept(holder, provider, splitTestStructureWithBounds(140, firstMinimum: 0, secondMinimum: 0)), true)
    @Assert(state.firstMinimum(), 0)
    @Assert(state.secondMinimum(), 0)
    @Assert(state.applyFirstSize(300, 500, 8), 300)
    // Removing both properties re-applies the PUBLIC default.
    @Assert(scrollTestAccept(holder, provider, splitTestStructureWithBounds(140)), true)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 120)
}

/// A1: a read-only query of an instance's size must never rewrite its declared
/// constraints, and neither may recording a human drag result.
@Test
func readOnlySplitSizeQueryNeverRewritesDeclaredBounds(): Unit {
    let catalog = splitTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let state = holder.splitStateForInstance("split", 140, firstMinimum: 120, secondMinimum: 90)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 90)
    @Assert(holder.splitSizeForInstance("split", 140), 140)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 90)
    holder.updateSplitSizeForInstance("split", 200)
    @Assert(state.firstMinimum(), 120)
    @Assert(state.secondMinimum(), 90)
    @Assert(state.firstSize(), 200)
    @Assert(state.applyFirstSize(300, 500, 8), 300)
}

/// A control the owner marked unavailable is NOT focusable in the accepted scene.
/// That is exactly the flag the window submits to native focus traversal
/// (`canReceiveInput() || canReceiveFocus()`), so a disabled control can never
/// receive the Tab focus a generated reveal would otherwise act on.
@Test
func disabledControlIsNotFocusableInTheAcceptedScene(): Unit {
    let root = cjguiComposableVertical(1, "focus-root", CjguiComposableUiStyle(gap: 4))
    root.add(cjguiComposableTextInput(2, "focus-enabled", "可用", "", 1, CjguiComposableUiStyle(),
        enabled: true))
    root.add(cjguiComposableTextInput(3, "focus-disabled", "禁用", "", 2, CjguiComposableUiStyle(),
        enabled: false))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 400, 300), 1)
    @Assert(scene.isValid(), true)
    @Assert(scene.nodeForId(2).canReceiveFocus(), true)
    @Assert(scene.nodeForId(2).canReceiveInput(), true)
    @Assert(scene.nodeForId(3).canReceiveFocus(), false)
    @Assert(scene.nodeForId(3).canReceiveInput(), false)
}

/// A1: both clamp ends, a narrow track, and continuing AFTER a resize. The point
/// is that the size rule is applied to the ACCEPTED geometry, so a resize cannot
/// leave a request behind that the next drag or keypress would build on.
@Test
func splitSizeRuleClampsBothEndsAndSurvivesResize(): Unit {
    let state = CjguiComposableUiSplitState(200, 120, 120)
    // Both ends of the SAME rule on a healthy track (available = 492).
    @Assert(state.applyFirstSize(0, 500, 8), 120)
    @Assert(state.applyFirstSize(9000, 500, 8), 372)
    // A NARROW track that cannot honor the second minimum degrades to the first
    // minimum instead of producing an impossible width.
    @Assert(state.applyFirstSize(400, 200, 8), 120)
    @Assert(state.firstSize(), 120)
    // The accepted geometry is what later interactions start from.
    state.acceptSplitTrack(500, 8, 372)
    @Assert(state.acceptedFirstSize(), 372)
    // A person drags on the accepted track: the request lands between the bounds.
    @Assert(state.applyFirstSize(300, state.acceptedTrack(), state.acceptedHandleSize()), 300)
    // Then the window RESIZES: a new solve accepts a much narrower track.
    state.acceptSplitTrack(300, 8, 172)
    @Assert(state.acceptedFirstSize(), 172)
    // Continuing with the keyboard after the resize uses the ACCEPTED track, so
    // the nudge is clamped by the NEW geometry, not by the pre-resize one.
    @Assert(state.applyAcceptedFirstSize(400), 172)
    @Assert(state.firstSize(), 172)
    @Assert(state.applyAcceptedFirstSize(100), 120)
    // A drag after the resize is likewise bounded by the new track.
    @Assert(state.applyFirstSize(9000, state.acceptedTrack(), state.acceptedHandleSize()), 172)
}

/// The public generated grammar carries the same outline/row facts as the
/// handwritten virtual tree. A rejected state change cannot replace the
/// accepted owner binding or its accessibility projection.
@Test
func generatedOutlineSemanticStateAcceptsAndRejectsAtomically(): Unit {
    let catalog = scrollTestCatalog()
    let actionProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    actionProperties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 40))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action", actionProperties, false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("EXPAND", "展开"))
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)

    let rowProperties = HashMap<String, String>()
    rowProperties.add("label", "分组")
    rowProperties.add("semanticRole", "row")
    rowProperties.add("semanticRowKey", "group")
    rowProperties.add("semanticExpandable", "true")
    rowProperties.add("semanticExpanded", "true")
    rowProperties.add("disabled", "true")
    let row = CjguiGeneratedUiNodeSpec("row", "action", properties: rowProperties, actionName: "EXPAND")
    let content = CjguiGeneratedUiNodeSpec("content", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([row]))
    let outlineProperties = HashMap<String, String>()
    outlineProperties.add("semanticRole", "outline")
    outlineProperties.add("semanticLabel", "测试树")
    let outline = CjguiGeneratedUiNodeSpec("outline", "scrollArea", properties: outlineProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([content]))
    let root = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([outline]))
    @Assert(scrollTestAccept(holder, provider, root), true)
    let acceptedVersion = holder.structureVersion()
    let built = holder.buildRefreshNode(provider)
    let outlineNode = scrollTestFind(built, holder.nodeIdForKey("outline")).getOrThrow()
    let rowNode = scrollTestFind(built, holder.nodeIdForKey("row")).getOrThrow()
    @Assert(outlineNode.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_TREE)
    @Assert(rowNode.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_TREE_ROW)
    @Assert(rowNode.semanticKey, "group")
    @Assert(rowNode.semanticExpandable, true)
    @Assert(rowNode.semanticExpanded, true)
    @Assert(rowNode.isEnabled, false)

    let invalidProperties = HashMap<String, String>()
    invalidProperties.add("label", "分组")
    invalidProperties.add("semanticRole", "row")
    invalidProperties.add("semanticRowKey", "group")
    invalidProperties.add("semanticExpanded", "true")
    let invalidRow = CjguiGeneratedUiNodeSpec("row", "action", properties: invalidProperties,
        actionName: "EXPAND")
    let invalidContent = CjguiGeneratedUiNodeSpec("content", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([invalidRow]))
    let invalidOutline = CjguiGeneratedUiNodeSpec("outline", "scrollArea", properties: outlineProperties,
        children: ArrayList<CjguiGeneratedUiNodeSpec>([invalidContent]))
    let invalid = holder.submit(CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([invalidOutline])), provider)
    @Assert(invalid.candidateAccepted, false)
    @Assert(invalid.reason, "semantic_expanded_without_group")
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(scrollTestFind(holder.buildRefreshNode(provider), holder.nodeIdForKey("row")).getOrThrow()
        .semanticExpanded, true)
}
