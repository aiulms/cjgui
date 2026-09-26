// Tests for the shared practical style vocabulary of the generated UI
// (composable_ui_generated.cj): size constraints, growth, alignment and font are
// defined once, published honestly, validated at registration, and applied to
// the SAME Cangjie Style/layout the handwritten tree uses.
//
// What is pinned here:
//   * a generated node's declared style really reaches the accepted geometry:
//     grow consumes slack, alignment moves the node, and a declared font size
//     changes measured height;
//   * the capability description publishes the enumerated vocabulary and the
//     effective default instead of making a reader guess;
//   * a property the presentation would ignore is REJECTED at registration, so
//     nothing is advertised that the renderer never applies;
//   * an application-registered composite receives the resolved style through
//     the shared build context.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

class StyleEchoComposite <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        // The declared style reaches the built subtree through the framework's
        // resolved style, not through a second parser in this factory.
        return cjguiComposableVertical(root.nodeId, root.semanticId, context.resolvedStyle)
    }
}

private class StyleBuilt {
    let holder: CjguiGeneratedUiStructureHolder
    let node: CjguiComposableUiNode

    init(holder: CjguiGeneratedUiStructureHolder, node: CjguiComposableUiNode) {
        this.holder = holder
        this.node = node
    }
}

private func styleCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        styleContentProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 64)
        ])), false))
    return catalog
}

private func styleContentProperties(content: ArrayList<CjguiGeneratedUiPropertySpec>):
    ArrayList<CjguiGeneratedUiPropertySpec> {
    let combined = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in content) {
        combined.add(property)
    }
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        combined.add(property)
    }
    return combined
}

private func stylePropertiesOf(entries: ArrayList<(String, String)>): HashMap<String, String> {
    let map = HashMap<String, String>()
    for ((name, value) in entries) {
        map.add(name, value)
    }
    return map
}

private func styleEntries(style: Array<(String, String)>):
    ArrayList<(String, String)> {
    let entries = ArrayList<(String, String)>()
    for (entry in style) {
        entries.add(entry)
    }
    return entries
}

private func styleLabel(key: String, text: String, style: Array<(String, String)>):
    CjguiGeneratedUiNodeSpec {
    let entries = styleEntries(style)
    entries.add(("text", text))
    return CjguiGeneratedUiNodeSpec(key, "label", properties: stylePropertiesOf(entries))
}

private func styleRow(firstStyle: Array<(String, String)>, secondStyle: Array<(String, String)>):
    CjguiGeneratedUiNodeSpec {
    let children = ArrayList<CjguiGeneratedUiNodeSpec>([
        styleLabel("first", "A", firstStyle),
        styleLabel("second", "B", secondStyle)
    ])
    let rootProperties = HashMap<String, String>()
    rootProperties.add("gap", "0")
    return CjguiGeneratedUiNodeSpec("row", "horizontal", properties: rootProperties, children: children)
}

private func styleBuild(catalog: CjguiGeneratedUiCapabilityCatalog, spec: CjguiGeneratedUiNodeSpec):
    StyleBuilt {
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    if (!holder.submit(spec, provider).candidateAccepted) {
        return StyleBuilt(holder, cjguiComposableText(-1, "rejected", "", CjguiComposableUiStyle()))
    }
    // The candidate transaction the window really uses: only a committed
    // candidate publishes the accepted identity table a test resolves keys in.
    let _ = holder.beginCandidateRefresh()
    let node = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    return StyleBuilt(holder, node)
}

/// The accepted layout node for one DECLARED key, resolved through the holder's
/// own accepted identity. A test therefore addresses the node the window really
/// accepted, not a name it guessed.
private func styleAcceptedNode(scene: CjguiComposableUiScene, built: StyleBuilt, key: String):
    CjguiComposableUiLayoutNode {
    let nodeId = built.holder.nodeIdForKey(key)
    if (nodeId > 0) {
        return scene.nodeForId(nodeId)
    }
    return CjguiComposableUiLayoutNode.missing()
}

@Test
func generatedStyleGrowsChangesWithTheViewport(): Unit {
    let catalog = styleCatalog()
    let built = styleBuild(catalog, styleRow([("fixedWidth", "40")], [("growX", "1")]))
    let narrow = CjguiComposableUiLayoutEngine.layout(built.node, CjguiComposableUiRect(0, 0, 200, 60), 1)
    let wide = CjguiComposableUiLayoutEngine.layout(built.node, CjguiComposableUiRect(0, 0, 400, 60), 1)
    let narrowFirst = styleAcceptedNode(narrow, built, "first")
    let narrowSecond = styleAcceptedNode(narrow, built, "second")
    let wideFirst = styleAcceptedNode(wide, built, "first")
    let wideSecond = styleAcceptedNode(wide, built, "second")
    // The fixed label keeps its width; the growing label takes the slack and
    // every extra pixel the wider viewport provides.
    @Assert(narrowFirst.bounds.width, 40)
    @Assert(narrowSecond.bounds.width > narrowFirst.bounds.width, true)
    @Assert(wideFirst.bounds.width, 40)
    @Assert(wideSecond.bounds.width > narrowSecond.bounds.width, true)
    @Assert(narrowSecond.bounds.x > narrowFirst.bounds.x, true)
}

@Test
func generatedStyleAlignmentAndFontChangeTheGeometry(): Unit {
    let catalog = styleCatalog()
    let plain = styleBuild(catalog, styleRow([("fixedHeight", "40")], [("fixedHeight", "20")]))
    let plainScene = CjguiComposableUiLayoutEngine.layout(plain.node, CjguiComposableUiRect(0, 0, 200, 60), 1)
    let plainSecond = styleAcceptedNode(plainScene, plain, "second")
    @Assert(plainSecond.bounds.y, 0)

    let centered = styleBuild(catalog, styleRow([("fixedHeight", "40")],
        [("fixedHeight", "20"), ("alignY", "center")]))
    let centeredScene = CjguiComposableUiLayoutEngine.layout(centered.node,
        CjguiComposableUiRect(0, 0, 200, 60), 1)
    let centeredSecond = styleAcceptedNode(centeredScene, centered, "second")
    // The centering target is the row's own cross-axis extent, which the
    // viewport stretches; deriving it from the accepted row keeps the assertion
    // honest instead of hardcoding one viewport's number.
    let rowHeight = styleAcceptedNode(centeredScene, centered, "row").bounds.height
    @Assert(rowHeight > 20, true)
    @Assert(centeredSecond.bounds.y, (rowHeight - 20) / 2)
    @Assert(centeredSecond.bounds.y > plainSecond.bounds.y, true)

    // A declared font size changes the measured height of the same node.
    let small = styleBuild(catalog, styleRow([("fixedHeight", "40")], [("fontSize", "12")]))
    let smallScene = CjguiComposableUiLayoutEngine.layout(small.node, CjguiComposableUiRect(0, 0, 200, 60), 1)
    let large = styleBuild(catalog, styleRow([("fixedHeight", "40")], [("fontSize", "24")]))
    let largeScene = CjguiComposableUiLayoutEngine.layout(large.node, CjguiComposableUiRect(0, 0, 200, 60), 1)
    @Assert(styleAcceptedNode(largeScene, large, "second").bounds.height >
        styleAcceptedNode(smallScene, small, "second").bounds.height, true)
}

@Test
func generatedStyleRejectsPropertiesTheNodeWouldIgnore(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    // A leaf never applies padding: publishing it would advertise a style the
    // leaf builder does not consume.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([CjguiGeneratedUiPropertySpec("padding", "INTEGER")]),
        false)), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("property_not_implemented"), true)
    // Alignment is an enumerated STRING; an INTEGER claim is a type error.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([CjguiGeneratedUiPropertySpec("alignX", "INTEGER")]),
        false)), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("property_not_implemented"), true)
    // A container consumes padding, a leaf consumes font size: both register.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 4)), true)
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        CjguiGeneratedUiPresentation.leafStyleProperties(), false)), true)
}

@Test
func generatedStyleDescriptionPublishesEnumsAndDefaults(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 4)), true)
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        CjguiGeneratedUiPresentation.leafStyleProperties(), false)), true)
    let text = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(text.contains("PROPERTY vertical gap INTEGER 0 0 32 0 default=4\n"), true)
    @Assert(text.contains(
        "PROPERTY vertical alignX STRING 0 0 0 8 values=start,center,end,stretch default=stretch\n"), true)
    @Assert(text.contains("PROPERTY label fontSize INTEGER 0 1 128 0 default=13\n"), true)
    @Assert(text.contains("PROPERTY label growX INTEGER 0 0 8 0 default=0\n"), true)
}

@Test
func compositeResolvedStyleReachesTheFactory(): Unit {
    let catalog = styleCatalog()
    let properties = CjguiGeneratedUiPresentation.leafStyleProperties()
    properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("styledCard", properties, elements),
        StyleEchoComposite()), true)
    let cardProperties = HashMap<String, String>()
    cardProperties.add("growX", "1")
    cardProperties.add("alignX", "end")
    cardProperties.add("fontSize", "17")
    cardProperties.add("fixedHeight", "44")
    let built = styleBuild(catalog, CjguiGeneratedUiNodeSpec("card", "styledCard",
        properties: cardProperties))
    @Assert(built.node.style.growX, 1)
    @Assert(built.node.style.alignX, CJGUI_COMPOSABLE_UI_ALIGN_END)
    @Assert(built.node.style.fontSize, 17.0)
    @Assert(built.node.style.fixedHeight, 44)
}

/// A paint-only projection must retain every owner and identity fact that the
/// accepted layout exposed. Rebuilding the node without these fields silently
/// turns a resolved paint update into a value-only copy: scroll/split/tab state
/// and scoped identity are then unavailable to the next consumer.
@Test
func paintOnlyCopyPreservesViewOwnersAndScopedIdentity(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let _ = viewport.step("next", 5)
    let split = CjguiComposableUiSplitState(180, 80, 70)
    let tabs = CjguiComposableUiTabsState("retention")
    let scope = CjguiComposableUiIdentityScope("paint-copy")
    let node = CjguiComposableUiNode(71, "paint-copy-scroll", CJGUI_COMPOSABLE_UI_SCROLL_AREA,
        "", "", "SCROLL", -1, CjguiComposableUiStyle(),
        scrollViewport: Some(viewport), splitState: Some(split), tabsState: Some(tabs),
        tabsPageKey: "retention", tabsPageActive: true, tabsTitleHeight: 24,
        identity: Some(scope.local("editor")))
    let layout = CjguiComposableUiLayoutNode(node, CjguiComposableUiRect(11, 13, 97, 43),
        CjguiComposableUiRect(11, 13, 97, 43), inputScopeId: "paint-scope")
    let painted = layout.withResolvedPaintStyle(CjguiComposableUiStyle(
        background: CjguiComposableUiColor(0.2, 0.3, 0.4, 1.0)))

    @Assert(painted.scrollViewport.isSome(), true)
    @Assert(painted.scrollViewport.getOrThrow().offset(), viewport.offset())
    @Assert(painted.splitState.isSome(), true)
    @Assert(painted.splitState.getOrThrow().firstSize(), split.firstSize())
    @Assert(painted.tabsState.isSome(), true)
    @Assert(painted.tabsState.getOrThrow().activeKey(), "retention")
    @Assert(painted.tabsPageKey, "retention")
    @Assert(painted.tabsPageActive, true)
    @Assert(painted.tabsTitleHeight, 24)
    @Assert(painted.identityKey, layout.identityKey)
    @Assert(painted.bounds.x, 11)
    @Assert(painted.bounds.y, 13)
    @Assert(painted.bounds.width, 97)
    @Assert(painted.bounds.height, 43)
}
