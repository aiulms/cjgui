// Shared named-style tests: ONE application declaration resolved by the
// framework's generated nodes and by registered composites, discovered through
// the same capability text an external author already reads.
//
// What is pinned here:
//   * declaration validation (name shape, duplicate/update/remove semantics) and
//     the deterministic revision;
//   * strict color tokens (#RRGGBB / #RRGGBBAA) with a round trip;
//   * resolution order: framework default -> named base -> explicit property
//     override, with the named style's interaction paint carried into the node;
//   * a color-only change moves NO layout or typography, so identity/binding do
//     not need to be rebuilt and the paint fast path is not a re-layout;
//   * unknown style references and illegal colors are refused as a whole.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private func namedStyleCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8))
    let labelProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
        CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200)
    ])
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        labelProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
        CjguiGeneratedUiPresentation.leafStyleProperties(), false))
    return catalog
}

private func namedStyleAccent(): CjguiComposableUiNamedStyle {
    return CjguiComposableUiNamedStyle("panel_accent",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.9, 0.2, 0.2, 1.0),
            border: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0),
            textColor: CjguiComposableUiColor(0.12, 0.13, 0.16, 1.0),
            borderWidth: 3, padding: 9, fontSize: 20.0),
        interaction: CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.1, 0.8, 0.3, 1.0))),
            pressed: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.2, 0.4, 0.9, 1.0))),
            focused: CjguiComposableUiPaintStyle(borderWidth: Some(4))),
        purpose: "强调面板")
}

private func namedStyleLabelSpec(key: String, properties: ArrayList<(String, String)>): CjguiGeneratedUiNodeSpec {
    let map = HashMap<String, String>()
    for ((name, value) in properties) {
        map.add(name, value)
    }
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec(key, "label", properties: map))
    return CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
}

private func namedStyleFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- namedStyleFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func namedStyleBuild(catalog: CjguiGeneratedUiCapabilityCatalog,
                             spec: CjguiGeneratedUiNodeSpec): (CjguiGeneratedUiStructureHolder, CjguiComposableUiNode) {
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let submitted = holder.submit(spec, provider)
    if (!submitted.candidateAccepted) {
        return (holder, cjguiComposableText(-1, "rejected:${submitted.reason}", "",
            CjguiComposableUiStyle()))
    }
    let _ = holder.beginCandidateRefresh()
    let node = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    return (holder, node)
}

@Test
func namedStyleDeclarationIsValidatedAndPublished(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let styles = catalog.namedStyles()
    @Assert(styles.register(namedStyleAccent()), true)
    // One declaration per name: a duplicate is a registration error, a change
    // goes through update. A published reference is a protocol identifier.
    @Assert(styles.register(CjguiComposableUiNamedStyle("panel_accent", CjguiComposableUiStyle())), false)
    @Assert(styles.lastIssue(), "duplicate_named_style")
    @Assert(styles.register(CjguiComposableUiNamedStyle("1bad", CjguiComposableUiStyle())), false)
    @Assert(styles.lastIssue(), "named_style_name_invalid")
    @Assert(styles.register(CjguiComposableUiNamedStyle("", CjguiComposableUiStyle())), false)
    @Assert(styles.update(CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())), false)
    @Assert(styles.lastIssue(), "named_style_not_registered")

    // Discovery is derived from the definition: the real base values, the
    // interaction paint overrides and a revision, with no platform object.
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(described.contains("STYLE_REVISION "), true)
    @Assert(described.contains("STYLE panel_accent background=#e63333ff border=#1a1a1aff " +
        "textColor=#1f2129ff borderWidth=3 padding=9 gap=0"), true)
    @Assert(described.contains("STYLE_STATE panel_accent normal["), true)
    @Assert(described.contains("hover[background=#1acc4dff"), true)
    @Assert(described.contains("pressed[background=#3366e6ff"), true)
    @Assert(described.contains("focused[background=- border=- textColor=- borderWidth=4]"), true)
    @Assert(described.contains("purpose_hex="), true)

    // A metadata-only change moves the revision of the SAME declaration.
    let before = catalog.namedStyles().revision()
    @Assert(styles.update(CjguiComposableUiNamedStyle("panel_accent",
        CjguiComposableUiStyle(background: CjguiComposableUiColor(0.9, 0.2, 0.2, 1.0),
            borderWidth: 3, padding: 9, fontSize: 20.0),
        purpose: "改名后的用途")), true)
    @Assert(catalog.namedStyles().revision() != before, true)
    @Assert(styles.remove("panel_accent"), true)
    @Assert(styles.remove("panel_accent"), false)
    @Assert(catalog.namedStyles().revision() != before, true)

    // Strict color tokens with an exact round trip.
    let token = cjguiComposableUiColorToken(CjguiComposableUiColor(0.5, 0.25, 1.0, 1.0))
    @Assert(token, "#8040ffff")
    let parsed = cjguiComposableUiParseColorToken(token)
    @Assert(parsed.isSome(), true)
    let parsedColor = match (parsed) {
        case Some(value) => value
        case None => CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)
    }
    @Assert(cjguiComposableUiColorToken(parsedColor), token)
    @Assert(cjguiComposableUiParseColorToken("#12345").isNone(), true)
    @Assert(cjguiComposableUiParseColorToken("#GGGGGG").isNone(), true)
    @Assert(cjguiComposableUiParseColorToken("0.5,0.5,0.5").isNone(), true)
    @Assert(cjguiComposableUiParseColorToken("").isNone(), true)
}

@Test
func generatedNodeResolvesNamedStyleAndExplicitOverrides(): Unit {
    let catalog = namedStyleCatalog()
    @Assert(catalog.namedStyles().register(namedStyleAccent()), true)

    // (a) A reference alone: the named base supplies paint AND geometry.
    let (holder, root) = namedStyleBuild(catalog,
        namedStyleLabelSpec("accent", ArrayList<(String, String)>([
            ("style", "panel_accent"), ("text", "强调")
        ])))
    @Assert(holder.structureVersion(), 1)
    let nodeId = holder.nodeIdForKey("accent")
    @Assert(nodeId > 0, true)
    let nodeOption = namedStyleFind(root, nodeId)
    @Assert(nodeOption.isSome(), true)
    let node = match (nodeOption) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(node.style.background.red, 0.9)
    @Assert(node.style.borderWidth, 3)
    @Assert(node.style.padding, 9)
    @Assert(node.style.fontSize, 20.0)
    @Assert(node.interactionStyle.hover.background.isSome(), true)
    // The interaction paint resolves through the EXISTING priority machine.
    let covered = node.interactionStyle.resolve(node.style,
        CjguiComposableUiInteractionState.HOVER)
    @Assert(covered.background.red, 0.1)
    @Assert(covered.background.green, 0.8)
    let focused = node.interactionStyle.resolve(node.style,
        CjguiComposableUiInteractionState.FOCUSED)
    @Assert(focused.borderWidth, 4)
    @Assert(focused.background.red, 0.9)

    // (b) An explicit property wins over the named base, and undeclared values
    // still come from the named base.
    let (holder2, root2) = namedStyleBuild(catalog,
        namedStyleLabelSpec("accent", ArrayList<(String, String)>([
            ("style", "panel_accent"), ("text", "显式覆盖"), ("background", "#0000ffff"), ("fixedWidth", "123")
        ])))
    let node2Option = namedStyleFind(root2, holder2.nodeIdForKey("accent"))
    @Assert(node2Option.isSome(), true)
    let node2 = match (node2Option) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(node2.style.background.blue, 1.0)
    @Assert(node2.style.background.red, 0.0)
    @Assert(node2.style.borderWidth, 3)
    @Assert(node2.style.padding, 9)
    @Assert(node2.style.fixedWidth, 123)
    @Assert(node2.style.fontSize, 20.0)

    // (c) A color-only change moves NO layout/typography: same bounds, same font.
    let (holderA, rootA) = namedStyleBuild(catalog,
        namedStyleLabelSpec("accent", ArrayList<(String, String)>([
            ("style", "panel_accent"), ("text", "同一段文字"), ("background", "#e63333ff")
        ])))
    let (holderB, rootB) = namedStyleBuild(catalog,
        namedStyleLabelSpec("accent", ArrayList<(String, String)>([
            ("style", "panel_accent"), ("text", "同一段文字"), ("background", "#3366e6ff")
        ])))
    // The declared geometry/typography are identical while the paint differs.
    let nodeA = match (namedStyleFind(rootA, holderA.nodeIdForKey("accent"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    let nodeB = match (namedStyleFind(rootB, holderB.nodeIdForKey("accent"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(nodeA.style.fontSize, nodeB.style.fontSize)
    @Assert(nodeA.style.fontWeight, nodeB.style.fontWeight)
    @Assert(nodeA.style.fixedWidth, nodeB.style.fixedWidth)
    @Assert(nodeA.style.padding, nodeB.style.padding)
    @Assert(nodeA.style.borderWidth, nodeB.style.borderWidth)
    @Assert(cjguiComposableUiColorToken(nodeA.style.background), "#e63333ff")
    @Assert(cjguiComposableUiColorToken(nodeB.style.background), "#3366e6ff")

    // (d) Unknown references and illegal colors are refused as a whole.
    let unknown = holder.submit(namedStyleLabelSpec("accent",
        ArrayList<(String, String)>([("style", "not_registered"), ("text", "未知")])), GeneratedTestProvider())
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "style_reference_not_registered")
    let badColor = holder.submit(namedStyleLabelSpec("accent",
        ArrayList<(String, String)>([("style", "panel_accent"), ("text", "非法颜色"), ("border", "red")])), GeneratedTestProvider())
    @Assert(badColor.candidateAccepted, false)
    @Assert(badColor.reason, "color_value_invalid")
    let badWidth = holder.submit(namedStyleLabelSpec("accent",
        ArrayList<(String, String)>([("style", "panel_accent"), ("text", "越界"), ("borderWidth", "90")])), GeneratedTestProvider())
    @Assert(badWidth.candidateAccepted, false)
    @Assert(badWidth.reason, "property_out_of_range")
    // The refused candidates did not disturb the accepted interface.
    @Assert(holder.structureVersion(), 1)
}

/// An accepted instance keeps the resolution it was committed with when the
/// named style disappears from the catalog, and a still-registered name's legal
/// update reaches the next successful refresh. Losing a named style is NOT a
/// silent fall back to framework defaults: the name may carry geometry and
/// typography, so the accepted panel would visibly change shape.
@Test
func acceptedNamedStyleSurvivesCatalogRemovalAndAdoptsLegalUpdate(): Unit {
    let catalog = namedStyleCatalog()
    let styles = catalog.namedStyles()
    @Assert(styles.register(namedStyleAccent()), true)

    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let spec = namedStyleLabelSpec("accent", ArrayList<(String, String)>([
        ("style", "panel_accent"), ("text", "连续性")
    ]))
    let submitted = holder.submit(spec, provider)
    @Assert(submitted.candidateAccepted, true)
    let _ = holder.beginCandidateRefresh()
    let first = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    @Assert(holder.commitCandidateRefresh(), true)

    let acceptedId = holder.nodeIdForKey("accent")
    @Assert(acceptedId > 0, true)
    let acceptedNode = match (namedStyleFind(first, acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(acceptedNode.style.background.red, 0.9)
    @Assert(acceptedNode.style.borderWidth, 3)
    @Assert(acceptedNode.style.padding, 9)
    @Assert(acceptedNode.style.fontSize, 20.0)
    @Assert(acceptedNode.interactionStyle.hover.background.isSome(), true)

    // A legal update of a still-registered name reaches the next SUCCESSFUL
    // ordinary refresh: the build must be committed with an accepted scene, not
    // merely resolved.
    @Assert(styles.update(CjguiComposableUiNamedStyle("panel_accent",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.05, 0.6, 0.7, 1.0),
            borderWidth: 5, padding: 11, fontSize: 22.0),
        interaction: CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.3, 0.3, 0.3, 1.0)))))), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let refreshed = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let updatedNode = match (namedStyleFind(holder.buildRefreshNode(provider), acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(updatedNode.style.background.green, 0.6)
    @Assert(updatedNode.style.borderWidth, 5)
    @Assert(updatedNode.style.padding, 11)
    @Assert(updatedNode.style.fontSize, 22.0)

    // Removing the declaration must NOT silently reset the accepted instance to
    // framework defaults; the committed resolution stays in use.
    @Assert(styles.remove("panel_accent"), true)
    let afterRemoval = holder.buildRefreshNode(provider)
    let keptNode = match (namedStyleFind(afterRemoval, acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(keptNode.style.background.green, 0.6)
    @Assert(keptNode.style.background.red, 0.05)
    @Assert(keptNode.style.borderWidth, 5)
    @Assert(keptNode.style.padding, 11)
    @Assert(keptNode.style.fontSize, 22.0)
    let keptHover = keptNode.interactionStyle.resolve(keptNode.style,
        CjguiComposableUiInteractionState.HOVER)
    @Assert(keptHover.background.green, 0.3)

    // A NEW candidate that references the removed name is still refused, and the
    // refused candidate leaves the accepted interface untouched.
    let refused = holder.submit(namedStyleLabelSpec("accent2",
        ArrayList<(String, String)>([("style", "panel_accent"), ("text", "已移除")])), provider)
    @Assert(refused.candidateAccepted, false)
    @Assert(refused.reason, "style_reference_not_registered")
    @Assert(holder.structureVersion(), 1)

    // Re-registering the name under the same seam resolves again for fresh
    // candidates while the accepted instance keeps working.
    @Assert(styles.register(namedStyleAccent()), true)
    let reRegistered = holder.buildRefreshNode(provider)
    let again = match (namedStyleFind(reRegistered, acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(again.style.background.red, 0.9)
}

/// A style resolution belongs to the SCENE it was rendered for. A refresh that
/// resolved a new definition but was REJECTED must not replace the accepted
/// resolution - and a name withdrawn afterwards must not make the accepted
/// interface fall back to framework defaults.
@Test
func rejectedNamedStyleRefreshDoesNotReplaceTheAcceptedResolution(): Unit {
    let catalog = namedStyleCatalog()
    let styles = catalog.namedStyles()
    @Assert(styles.register(namedStyleAccent()), true)
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(holder.submit(namedStyleLabelSpec("accent", ArrayList<(String, String)>([
        ("style", "panel_accent"), ("text", "S0")
    ])), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let acceptedId = holder.nodeIdForKey("accent")
    @Assert(acceptedId > 0, true)
    let acceptedNode = match (namedStyleFind(holder.buildRefreshNode(provider), acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(acceptedNode.style.background.red, 0.9)
    @Assert(acceptedNode.style.borderWidth, 3)

    // The catalog now declares a NEW definition (S1) and a refresh resolves it,
    // but that scene is rejected before it is accepted.
    @Assert(styles.update(CjguiComposableUiNamedStyle("panel_accent",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.05, 0.6, 0.7, 1.0),
            borderWidth: 5, padding: 11, fontSize: 22.0))), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let rejectedBuild = holder.buildRefreshNode(provider)
    let rejectedNode = match (namedStyleFind(rejectedBuild, acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(rejectedNode.style.background.green, 0.6)
    holder.rollbackCandidateRefresh()

    // The name is withdrawn BEFORE any scene accepts S1: the accepted interface
    // must still be the S0 resolution, not the uncommitted S1 and not defaults.
    @Assert(styles.remove("panel_accent"), true)
    let rebuilt = holder.buildRefreshNode(provider)
    let kept = match (namedStyleFind(rebuilt, acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(kept.style.background.red, 0.9)
    @Assert(kept.style.background.green, 0.2)
    @Assert(kept.style.borderWidth, 3)
    @Assert(kept.style.padding, 9)
    @Assert(kept.style.fontSize, 20.0)
    @Assert(holder.structureVersion(), 1)

    // A still-registered legal update is adopted by the next SUCCESSFUL refresh.
    @Assert(styles.register(CjguiComposableUiNamedStyle("panel_accent",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.05, 0.6, 0.7, 1.0),
            borderWidth: 5, padding: 11, fontSize: 22.0))), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let adopted = match (namedStyleFind(holder.buildRefreshNode(provider), acceptedId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(adopted.style.background.green, 0.6)
    @Assert(adopted.style.borderWidth, 5)
}

/// The ONE-SHOT consumption entry: a developer picks the named style once and
/// receives base paint plus interaction together. `localStyle` may adjust the
/// consuming site's layout/typography only; paint always stays with the
/// definition, and the definition itself is never mutated.
@Test
func localStyleAdjustsGeometryOnlyWhilePaintStaysWithTheDefinition(): Unit {
    let styles = CjguiComposableUiNamedStyleCatalog()
    let registered = styles.register(CjguiComposableUiNamedStyle("accent_action",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0),
            border: CjguiComposableUiColor(0.36, 0.58, 0.96, 1.0),
            textColor: CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0),
            borderWidth: 3, padding: 9, fontSize: 20.0, fontWeight: 1, fixedHeight: 34),
        interaction: CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.28, 0.56, 0.94, 1.0))))))
    @Assert(registered, true)
    let role = match (styles.forName("accent_action")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    // The consuming site keeps its own geometry/typography; paint fields carry
    // the definition's values without a re-assembly helper at the call site.
    let local = role.localStyle(fixedHeight: 26, fontSize: 11.0, padding: 2, growX: 1)
    @Assert(local.fixedHeight, 26)
    @Assert(local.fontSize, 11.0)
    @Assert(local.padding, 2)
    @Assert(local.growX, 1)
    @Assert(local.background.red, 0.20)
    @Assert(local.border.green, 0.58)
    @Assert(local.textColor.red, 0.96)
    @Assert(local.borderWidth, 3)
    @Assert(local.fontWeight, 1)
    // The untouched definition keeps its own values, and the interaction pair
    // passes to the component unchanged.
    let kept = match (styles.forName("accent_action")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    @Assert(kept.base.fixedHeight, 34)
    @Assert(kept.base.fontSize, 20.0)
    @Assert(kept.interaction.hover.background.isSome(), true)
    // A second site can consume the same role with DIFFERENT local geometry.
    let other = role.localStyle(fixedHeight: 42)
    @Assert(other.fixedHeight, 42)
    @Assert(other.fontSize, 20.0)
}

/// Whole-group binding: `boundStyle` resolves the SAME local geometry as
/// `localStyle` AND packages the definition's interaction paint, so a
/// component accepts one argument and hover/pressed/focused/disabled arrive
/// together. The builder overload installs both fields into the node with
/// the same coverage order as the explicit `style`+`interactionStyle` pair.
@Test
func boundStyleCarriesInteractionTogetherWithLocalGeometry(): Unit {
    let styles = CjguiComposableUiNamedStyleCatalog()
    let registered = styles.register(CjguiComposableUiNamedStyle("bound_action",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0),
            textColor: CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0),
            borderWidth: 3, fixedHeight: 30),
        interaction: CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.28, 0.56, 0.94, 1.0))),
            disabled: CjguiComposableUiPaintStyle(
                textColor: Some(CjguiComposableUiColor(0.60, 0.60, 0.60, 1.0))))))
    @Assert(registered, true)
    let role = match (styles.forName("bound_action")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    let bound = role.boundStyle(fixedHeight: 24, fontSize: 9.0)
    // Geometry is resolved in the same entry; paint stays with the definition.
    @Assert(bound.style.fixedHeight, 24)
    @Assert(bound.style.fontSize, 9.0)
    @Assert(bound.style.background.red, 0.20)
    @Assert(bound.style.borderWidth, 3)
    @Assert(bound.interaction.hover.background.isSome(), true)
    // The builder overload installs base + interaction into the node together.
    let node = cjguiComposableButton(91, "bound_button", "确定", "submit", 91, bound)
    @Assert(node.style.fixedHeight, 24)
    @Assert(node.style.background.red, 0.20)
    @Assert(node.interactionStyle.hover.background.isSome(), true)
    // The untouched definition keeps its own values.
    let kept = match (styles.forName("bound_action")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    @Assert(kept.base.fixedHeight, 30)
    // TextInput accepts the same bound value.
    let input = cjguiComposableTextInput(92, "bound_input", "标签", "值", 92, bound)
    @Assert(input.style.fixedHeight, 24)
    @Assert(input.interactionStyle.hover.background.isSome(), true)
}
