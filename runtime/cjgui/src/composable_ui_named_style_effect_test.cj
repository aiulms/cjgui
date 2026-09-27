// 命名样式的「共同效果语义」收口测试（A2/A3）。
//
// 固定事实：
//   * 命名目录的 revision 纳入 shadow/gradient/拒绝语义：仅改 blur 或一个
//     stop 也会移动 revision，从而让观察 tracker 发出 STYLES，客户端据守卫
//     分段读回新定义；语义相同（stop 顺序归一、颜色等价字节）则不移动。
//   * 无变化不产生通知：同一 revision 的第二次采样不新增 cursor。
//   * 非法命名定义在 register/update 边界被具名拒绝，目录与 accepted 原子：
//     拒绝时不改动原名目、不进入目录；合法恢复与合法显式清除照常可用。
//   * 同一非法定义对照手写（Style 保留 effectRejection 并经组合工具传播）、
//     生成（未注册引用 / 畸形属性 token 被拒）、组合（register/update）三条
//     路径都被拒绝，绝不被静默归一为合法 None。
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private let EFFECT_REVISION_NAME = "effect_revision"

private func effectRevisionCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(
        CjguiGeneratedUiComponentSpec("vertical", CjguiGeneratedUiPresentation.containerStyleProperties(), true,
            childLimit: 8))
    let labelProperties = ArrayList<CjguiGeneratedUiPropertySpec>(
        [CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200)])
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        labelProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    return catalog
}

private func effectRevisionShadow(blur: Int64): CjguiComposableUiShadowStyle {
    return CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.5), offsetX: 0, offsetY: 3,
        blurRadius: blur, spread: 0)
}

private func effectRevisionStop(position: Float64, red: Float64, green: Float64, blue: Float64): CjguiComposableUiGradientStop {
    return CjguiComposableUiGradientStop(position: position, color: CjguiComposableUiColor(red, green, blue, 1.0))
}

/// The canonical 3-stop gradient: positions 0 / 0.5 / 1.
private func effectRevisionGradient(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(
        startX: 0.0,
        startY: 0.0,
        endX: 1.0,
        endY: 0.0,
        stops: [
            effectRevisionStop(0.0, 0.11, 0.31, 0.57),
            effectRevisionStop(0.5, 0.2, 0.4, 0.6),
            effectRevisionStop(1.0, 0.75, 0.86, 0.98)
        ]
    )
}

/// The canonical gradient with ONE stop colour changed (mid stop 0.4/0.6/0.8):
/// a single-stop change is a real definition change.
private func effectRevisionGradientMoved(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(
        startX: 0.0,
        startY: 0.0,
        endX: 1.0,
        endY: 0.0,
        stops: [
            effectRevisionStop(0.0, 0.11, 0.31, 0.57),
            effectRevisionStop(0.5, 0.4, 0.6, 0.8),
            effectRevisionStop(1.0, 0.75, 0.86, 0.98)
        ]
    )
}

/// The moved stops DECLARED in reverse order: the style layer orders admitted
/// stops, so this is the same effect and must hash identically.
private func effectRevisionGradientMovedReordered(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(
        startX: 0.0,
        startY: 0.0,
        endX: 1.0,
        endY: 0.0,
        stops: [
            effectRevisionStop(1.0, 0.75, 0.86, 0.98),
            effectRevisionStop(0.5, 0.4, 0.6, 0.8),
            effectRevisionStop(0.0, 0.11, 0.31, 0.57)
        ]
    )
}

/// The moved colours spelled with explicit byte fractions: the strict-color
/// token rounds to the same bytes, so this is the same effect and must hash
/// alike.
private func effectRevisionGradientMovedAlias(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(
        startX: 0.0,
        startY: 0.0,
        endX: 1.0,
        endY: 0.0,
        stops: [
            effectRevisionStop(0.0, 0.11, 0.31, 0.57),
            effectRevisionStop(0.5, 102.0 / 255.0, 153.0 / 255.0, 204.0 / 255.0),
            effectRevisionStop(1.0, 0.75, 0.86, 0.98)
        ]
    )
}

/// A deterministic base definition with parameterized effects; every OTHER
/// field is fixed, so a revision change is attributable to the effect alone.
private func effectRevisionStyle(shadow: ?CjguiComposableUiShadowStyle, gradient: ?CjguiComposableUiLinearGradient): CjguiComposableUiNamedStyle {
    return CjguiComposableUiNamedStyle(EFFECT_REVISION_NAME,
        CjguiComposableUiStyle(background: CjguiComposableUiColor(0.16, 0.20, 0.30, 0.96),
            border: CjguiComposableUiColor(0.10, 0.10, 0.10, 1.0), textColor: CjguiComposableUiColor(0.93, 0.96, 1.0,
                1.0), padding: 8, borderWidth: 2, cornerRadius: 6, shadow: shadow, gradient: gradient),
        purpose: "效果修订")
}

private func effectRevisionGroup(opacity: Float64, blurRadiusPoints: Int64): CjguiComposableUiEffectGroup {
    return CjguiComposableUiEffectGroup(opacity: opacity, blendMode: "multiply",
        mask: Some(CjguiComposableUiLinearAlphaMask(startX: 0.0, startY: 0.5, endX: 1.0, endY: 0.5,
            stops: [CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
                CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.4),
                CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)])),
        backdropBlurRadiusPoints: blurRadiusPoints)
}

private func effectRevisionGroupStyle(group: ?CjguiComposableUiEffectGroup): CjguiComposableUiNamedStyle {
    return CjguiComposableUiNamedStyle("effect_group_revision",
        CjguiComposableUiStyle(background: CjguiComposableUiColor(0.2, 0.3, 0.4, 1.0), effectGroup: group),
        purpose: "效果组修订")
}

private func effectRevisionNode(labelProperties: ArrayList<(String, String)>): CjguiGeneratedUiNodeSpec {
    let map = HashMap<String, String>()
    map.add("text", "效果卡片")
    for ((name, value) in labelProperties) {
        map.add(name, value)
    }
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("card", "label", properties: map))
    return CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
}

private func effectRevisionFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- effectRevisionFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func effectRevisionBuild(catalog: CjguiGeneratedUiCapabilityCatalog, spec: CjguiGeneratedUiNodeSpec): (CjguiGeneratedUiStructureHolder,
    CjguiComposableUiNode) {
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let submitted = holder.submit(spec, provider)
    if (!submitted.candidateAccepted) {
        return (holder, cjguiComposableText(-1, "rejected:${submitted.reason}", "", CjguiComposableUiStyle()))
    }
    let _ = holder.beginCandidateRefresh()
    let node = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    return (holder, node)
}

private func effectRevisionCardStyle(holder: CjguiGeneratedUiStructureHolder, root: CjguiComposableUiNode): CjguiComposableUiStyle {
    return match (effectRevisionFind(root, holder.nodeIdForKey("card"))) {
        case Some(value) => value.style
        case None => CjguiComposableUiStyle()
    }
}

/// One observation source whose ONLY moving fact is the style revision; every
/// business/structure/scene field is held constant, so STYLES is the only
/// category a change can produce.
private func effectRevisionSource(styleRevision: Int64): CjguiGeneratedUiObservationSource {
    return CjguiGeneratedUiObservationSource("effect-session", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4, false,
        styleRevision: styleRevision)
}

/// A2: the revision fingerprints the shared effect semantics, not only geometry
/// and paint. A blur-only or single-stop change is a REAL definition change and
/// must move the revision; semantically equal declarations must not.
@Test
func namedStyleRevisionMovesWithSharedEffectSemantics(): Unit {
    let catalog = effectRevisionCatalog()
    let styles = catalog.namedStyles()
    @Assert(styles.register(effectRevisionStyle(Some(effectRevisionShadow(8)), Some(effectRevisionGradient()))), true)
    let baseline = styles.revision()

    // A blur-only change moves the revision.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(12)), Some(effectRevisionGradient()))), true)
    let blurMoved = styles.revision()
    @Assert(blurMoved != baseline, true)

    // The SAME value restores the SAME revision (no phantom change).
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(8)), Some(effectRevisionGradient()))), true)
    @Assert(styles.revision(), baseline)

    // A single stop change moves the revision.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(8)),
        Some(effectRevisionGradientMoved()))), true)
    let stopMoved = styles.revision()
    @Assert(stopMoved != baseline, true)

    // Semantically equal declarations hash alike: reordered stops (admitted
    // ordering) and byte-equivalent colours are NOT definition changes.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(8)),
        Some(effectRevisionGradientMovedReordered()))), true)
    @Assert(styles.revision(), stopMoved)
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(8)),
        Some(effectRevisionGradientMovedAlias()))), true)
    @Assert(styles.revision(), stopMoved)

    // A gradient CLEAR is distinct from the gradient being present.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(8)), None)), true)
    let gradientCleared = styles.revision()
    @Assert(gradientCleared != stopMoved, true)

    // Same for the shadow: a clear is a real change.
    @Assert(styles.update(effectRevisionStyle(None, None)), true)
    @Assert(styles.revision() != gradientCleared, true)
}

@Test
func namedStyleRevisionAndDescriptionIncludeEffectGroup(): Unit {
    let catalog = effectRevisionCatalog()
    let styles = catalog.namedStyles()
    let group = effectRevisionGroup(0.75, 0)
    @Assert(styles.register(effectRevisionGroupStyle(Some(group))), true)
    let firstRevision = styles.revision()
    let token = cjguiComposableUiEffectGroupToken(group)
    @Assert(styles.describe().contains("effectGroup=${token}"), true)

    @Assert(styles.update(effectRevisionGroupStyle(Some(effectRevisionGroup(0.5, 0)))), true)
    @Assert(styles.revision() != firstRevision, true)
    let movedRevision = styles.revision()
    @Assert(styles.update(effectRevisionGroupStyle(Some(effectRevisionGroup(0.5, 0)))), true)
    @Assert(styles.revision(), movedRevision)
    @Assert(styles.update(effectRevisionGroupStyle(Some(effectRevisionGroup(0.5, 8)))), true)
    let blurredRevision = styles.revision()
    @Assert(blurredRevision != movedRevision, true)
    @Assert(styles.describe().contains("effectGroup=50,multiply,0,50,100,50,0:0|50:40|100:100;blur=8,unblurred"), true)
    @Assert(styles.update(effectRevisionGroupStyle(Some(effectRevisionGroup(0.5, 8)))), true)
    @Assert(styles.revision(), blurredRevision)
    @Assert(styles.update(effectRevisionGroupStyle(None)), true)
    @Assert(styles.revision() != blurredRevision, true)
}

/// A2 end-to-end through the PUBLIC observation seam: an effect-only change is
/// reported as STYLES alone, and a client re-reads the STYLES section at its
/// guarded cursor to learn the new definition. No change produces no cursor.
@Test
func effectOnlyStyleChangePublishesStylesAndGuardedSection(): Unit {
    let catalog = effectRevisionCatalog()
    let styles = catalog.namedStyles()
    @Assert(styles.register(effectRevisionStyle(Some(effectRevisionShadow(8)), Some(effectRevisionGradient()))), true)

    let tracker = CjguiGeneratedUiObservationTracker()
    let initialRevision = styles.revision()
    @Assert(tracker.observeSource(effectRevisionSource(initialRevision)), 0)

    // ONLY the shadow blur changes: the style revision moves, no business fact.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(14)), Some(effectRevisionGradient()))), true)
    let movedRevision = styles.revision()
    @Assert(movedRevision != initialRevision, true)
    @Assert(tracker.observeSource(effectRevisionSource(movedRevision)), 1)
    let changes = tracker.changesPayload(tracker.streamEpoch(), 0)
    @Assert(changes.contains("CHANGE 1 STYLES revision=${movedRevision}"), true)
    @Assert(changes.contains("STRUCTURE"), false)
    @Assert(changes.contains("SCENE"), false)
    @Assert(changes.contains("FIELDS"), false)
    @Assert(changes.contains("RESOURCES"), false)
    @Assert(changes.contains("INSTANCES"), false)

    // The guarded section read at the new cursor returns the NEW definition.
    let description = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(description.contains("shadow=0,3,14,0,#00000080"), true)
    let section = cjguiGeneratedUiSectionPayload(tracker, "STYLES", 1, description)
    @Assert(section.contains("SECTION STYLES"), true)
    @Assert(section.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(section.contains("SNAPSHOT_STYLE STYLE ${EFFECT_REVISION_NAME}"), true)
    @Assert(section.contains("shadow=0,3,14,0,#00000080"), true)
    // A stale cursor is refused instead of being answered with old content.
    let stale = cjguiGeneratedUiSectionPayload(tracker, "STYLES", 0, description)
    @Assert(stale.contains("SNAPSHOT_REVISION_CHANGED 1"), true)

    // No change at all: the cursor stays where it was.
    @Assert(tracker.observeSource(effectRevisionSource(movedRevision)), 1)
}

/// A3: an illegal named definition is refused BY NAME at both registration and
/// update, and the directory stays exactly as it was (atomic). A legal recovery
/// and a legal explicit clear still work.
@Test
func illegalNamedEffectIsRejectedByNameWithoutTouchingTheDirectory(): Unit {
    let catalog = effectRevisionCatalog()
    let styles = catalog.namedStyles()

    // Handwritten illegal shadow: the named definition carries the refusal.
    let illegalShadowBase = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(blurRadius: 257)))
    match (illegalShadowBase.effectRejection) {
        case Some(value) =>
            @Assert(value.reason, "shadow_value_invalid")
            @Assert(value.path, "/shadow")
        case None => @Assert(false, true)
    }

    let emptyRevision = styles.revision()
    @Assert(styles.register(CjguiComposableUiNamedStyle("illegal_panel", illegalShadowBase)), false)
    @Assert(styles.lastIssue(), "shadow_value_invalid")
    @Assert(styles.size(), 0)
    @Assert(styles.forName("illegal_panel").isNone(), true)
    // The refused registration did not move the directory revision.
    @Assert(styles.revision(), emptyRevision)

    // A legal definition registers normally and becomes the accepted one.
    @Assert(styles.register(effectRevisionStyle(Some(effectRevisionShadow(8)), None)), true)
    let legalRevision = styles.revision()
    @Assert(styles.size(), 1)

    // An illegal UPDATE is refused by name and the PREVIOUS definition stays
    // registered: nothing is written on a refusal.
    let singleStop = CjguiComposableUiLinearGradient(
        stops: [CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0))])
    let illegalGradientBase = CjguiComposableUiStyle(gradient: Some(singleStop))
    @Assert(styles.update(CjguiComposableUiNamedStyle(EFFECT_REVISION_NAME, illegalGradientBase)), false)
    @Assert(styles.lastIssue(), "gradient_value_invalid")
    @Assert(styles.revision(), legalRevision)
    match (styles.forName(EFFECT_REVISION_NAME)) {
        case Some(value) => match (value.base.shadow) {
            case Some(shadow) => @Assert(shadow.blurRadius, 8)
            case None => @Assert(false, true)
        }
        case None => @Assert(false, true)
    }

    // A legal recovery is admitted and moves the revision again.
    @Assert(styles.update(effectRevisionStyle(Some(effectRevisionShadow(12)), None)), true)
    @Assert(styles.revision() != legalRevision, true)
}

/// A3: the three consumption roads agree on the SAME illegal definition:
/// handwritten, generated and composed. None of them silently normalizes it.
@Test
func illegalNamedEffectIsRefusedOnHandwrittenGeneratedAndComposedPaths(): Unit {
    let catalog = effectRevisionCatalog()
    let styles = catalog.namedStyles()
    let illegalBase = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(blurRadius: 257)))

    // Composed path: the directory refuses it, so it can never be referenced.
    @Assert(styles.register(CjguiComposableUiNamedStyle("illegal_panel", illegalBase)), false)
    @Assert(styles.lastIssue(), "shadow_value_invalid")
    @Assert(styles.size(), 0)

    // Generated path (a): the refused name is not registered, so a candidate
    // referencing it is refused instead of getting a normalized default.
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let unregistered = holder.submit(effectRevisionNode(ArrayList<(String, String)>([("style", "illegal_panel")])),
        provider)
    @Assert(unregistered.candidateAccepted, false)
    @Assert(unregistered.reason, "style_reference_not_registered")

    // Generated path (b): a legal named definition plus a malformed effect token
    // is refused whole with the shared reason and path.
    @Assert(styles.register(effectRevisionStyle(Some(effectRevisionShadow(8)), None)), true)
    let malformed = holder.submit(
        effectRevisionNode(
            ArrayList<(String, String)>([("style", EFFECT_REVISION_NAME), ("shadow", "0,2,257,0,#00000080")])), provider)
    @Assert(malformed.candidateAccepted, false)
    @Assert(malformed.reason, "shadow_value_invalid")
    @Assert(malformed.path.contains("/shadow"), true)

    // Handwritten path: the refusal survives the composition helpers, including
    // a named-style rebuild (`localStyle`), so it reaches the window check.
    @Assert(cjguiComposableUiPaintOverlay(illegalBase, CjguiComposableUiStyle()).effectRejection.isSome(), true)
    @Assert(CjguiComposableUiInteractionStyle().resolve(illegalBase, 0).effectRejection.isSome(), true)
    let rebuilt = CjguiComposableUiNamedStyle("handwritten_illegal", illegalBase).localStyle(fontSize: 12.0)
    @Assert(rebuilt.effectRejection.isSome(), true)
}

/// A3: registering/enforcing the named boundary does not break the legal paths.
/// A legal named effect is inherited, an explicit `none`/empty CLEARS it and a
/// legal token REPLACES it - the three-way contract still holds.
@Test
func legalNamedEffectResolvesWithThreeWayClearSemantics(): Unit {
    let catalog = effectRevisionCatalog()
    @Assert(catalog.namedStyles().register(
        effectRevisionStyle(Some(effectRevisionShadow(8)), Some(effectRevisionGradient()))), true)

    // (a) Absent: the named base's effects are inherited.
    let (inheritHolder, inheritRoot) = effectRevisionBuild(catalog,
        effectRevisionNode(ArrayList<(String, String)>([("style", EFFECT_REVISION_NAME)])))
    let inherited = effectRevisionCardStyle(inheritHolder, inheritRoot)
    @Assert(inherited.shadow.isSome(), true)
    @Assert(inherited.gradient.isSome(), true)
    @Assert(inherited.effectRejection.isNone(), true)

    // (b) Explicit `none` and the empty string CLEAR both effects.
    let (clearHolder, clearRoot) = effectRevisionBuild(catalog,
        effectRevisionNode(
            ArrayList<(String, String)>([("style", EFFECT_REVISION_NAME), ("shadow", "none"), ("gradient", "")])))
    let cleared = effectRevisionCardStyle(clearHolder, clearRoot)
    @Assert(cleared.shadow.isNone(), true)
    @Assert(cleared.gradient.isNone(), true)
    @Assert(cleared.effectRejection.isNone(), true)

    // (c) A legal token REPLACES the inherited shadow.
    let (replaceHolder, replaceRoot) = effectRevisionBuild(catalog,
        effectRevisionNode(
            ArrayList<(String, String)>([("style", EFFECT_REVISION_NAME), ("shadow", "0,5,20,0,#00000060")])))
    let replaced = effectRevisionCardStyle(replaceHolder, replaceRoot)
    let replacedShadow = match (replaced.shadow) {
        case Some(value) => value
        case None => CjguiComposableUiShadowStyle()
    }
    @Assert(replacedShadow.blurRadius, 20)
    @Assert(replacedShadow.offsetY, 5)
    @Assert(replaced.effectRejection.isNone(), true)
}
