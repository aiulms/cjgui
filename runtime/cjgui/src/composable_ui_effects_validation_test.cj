// 效果数值/工作量边界、生成准入与公开发现的收口测试（A1/A3/A4/P4）。
//
// 固定事实：
//   * 数量与数值准入在排序/分配之前：>4 stops 与 <2 stops 都具名拒绝，列表
//     不被截断；坐标/position 越界与非有限一律具名拒绝，不做 clamp 后宣称合法。
//   * 生成侧畸形 shadow/gradient 整候选拒绝，带稳定 reason 与 path；旧 accepted
//     结构、版本与身份不变，随后合法候选仍可生效。
//   * 继承语义三分：未声明=继承，显式 none/空串=清除，合法 token=替换。
//   * 合法边界（4 stops、坐标/position 0 或 1、shadow 上限）接受；透明色与合法
//     无效果可用。
//   * 编码器产出的 token 能被解析器接受（往返一致），非法对象编码为 none。
//   * describe 由共同定义发布编码/单位/范围/none 语义/experimental/后端支持面。
//   * appendStyle 结构签名随 shadow/gradient 变化而变化。
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private func effectsCatalog(): CjguiGeneratedUiCapabilityCatalog {
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
    return catalog
}

private func effectsNamedStyle(): CjguiComposableUiNamedStyle {
    return CjguiComposableUiNamedStyle("effect_panel",
        CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.16, 0.20, 0.30, 0.96),
            textColor: CjguiComposableUiColor(0.93, 0.96, 1.0, 1.0),
            shadow: Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.5),
                offsetX: 0, offsetY: 3, blurRadius: 10, spread: 0)),
            gradient: Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
                stops: [
                    CjguiComposableUiGradientStop(position: 0.0,
                        color: CjguiComposableUiColor(0.11, 0.31, 0.57, 1.0)),
                    CjguiComposableUiGradientStop(position: 1.0,
                        color: CjguiComposableUiColor(0.25, 0.66, 0.96, 1.0))
                ])),
            effectGroup: Some(effectsLegalGroup())),
        purpose: "效果面板")
}

private func effectsLegalMask(): CjguiComposableUiLinearAlphaMask {
    return CjguiComposableUiLinearAlphaMask(startX: 0.0, startY: 0.5, endX: 1.0, endY: 0.5, stops: [
        CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
        CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)
    ])
}

private func effectsLegalGroup(): CjguiComposableUiEffectGroup {
    return CjguiComposableUiEffectGroup(opacity: 0.75, blendMode: "multiply", mask: Some(effectsLegalMask()))
}

private func effectsLegalStops(): ArrayList<CjguiComposableUiGradientStop> {
    let stops = ArrayList<CjguiComposableUiGradientStop>()
    stops.add(CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)))
    stops.add(CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)))
    return stops
}

/// A root vertical with ONE label child carrying the given extra properties.
private func effectsNode(labelProperties: ArrayList<(String, String)>): CjguiGeneratedUiNodeSpec {
    let map = HashMap<String, String>()
    map.add("text", "效果卡片")
    for ((name, value) in labelProperties) {
        map.add(name, value)
    }
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("card", "label", properties: map))
    return CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
}

/// Drives one full candidate -> scene transaction and returns the resolved tree.
private func effectsBuild(catalog: CjguiGeneratedUiCapabilityCatalog,
    spec: CjguiGeneratedUiNodeSpec): (CjguiGeneratedUiStructureHolder, CjguiComposableUiNode) {
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

private func effectsCommit(holder: CjguiGeneratedUiStructureHolder, spec: CjguiGeneratedUiNodeSpec): Bool {
    let provider = GeneratedTestProvider()
    if (!holder.submit(spec, provider).candidateAccepted) {
        return false
    }
    let _ = holder.beginCandidateRefresh()
    let _ = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    return holder.commitCandidateRefresh()
}

private func effectsFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- effectsFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func effectsCardStyle(holder: CjguiGeneratedUiStructureHolder,
    root: CjguiComposableUiNode): CjguiComposableUiStyle {
    let card = match (effectsFind(root, holder.nodeIdForKey("card"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    return card.style
}

private func effectsReason(reason: ?String): String {
    return match (reason) {
        case Some(value) => value
        case None => ""
    }
}

private func effectsNaN(): Float64 {
    let zero: Float64 = 0.0
    return zero / zero
}

private func effectsInfinity(): Float64 {
    let zero: Float64 = 0.0
    return 1.0 / zero
}

@Test
func effectAdmissionRefusesStopCountBeforeOrdering(): Unit {
    // >4 stops: refused by name, never truncated to four.
    let fiveStops = ArrayList<CjguiComposableUiGradientStop>()
    var index: Int64 = 0
    while (index < 5) {
        fiveStops.add(CjguiComposableUiGradientStop(position: Float64(index) / 10.0,
            color: CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0)))
        index += 1
    }
    let tooMany = CjguiComposableUiLinearGradient(stops: fiveStops.toArray())
    @Assert(effectsReason(tooMany.rejectionReason()), "gradient_stop_count_above_maximum")
    @Assert(tooMany.isValid(), false)
    // The refused declaration keeps all five stops inspectable: it is refused,
    // not silently truncated.
    @Assert(tooMany.stops.size, 5)

    // <2 stops: refused by name; the style layer normalizes it away.
    let single = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0))
    ])
    @Assert(effectsReason(single.rejectionReason()), "gradient_stop_count_below_minimum")
    @Assert(single.isValid(), false)
    @Assert(CjguiComposableUiStyle(gradient: single).gradient.isNone(), true)

    // ==4 stops is a legal boundary and IS ordered ascending; the refused list
    // above was never ordered.
    let fourStops = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(0.9, 0.0, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.0, 0.9, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(0.0, 0.0, 0.9, 1.0)),
        CjguiComposableUiGradientStop(position: 0.25, color: CjguiComposableUiColor(0.9, 0.9, 0.0, 1.0))
    ])
    @Assert(fourStops.rejectionReason().isNone(), true)
    @Assert(fourStops.isValid(), true)
    @Assert(fourStops.stops.size, 4)
    @Assert(fourStops.stops[0].position, 0.0)
    @Assert(fourStops.stops[1].position, 0.25)
    @Assert(fourStops.stops[2].position, 0.5)
    @Assert(fourStops.stops[3].position, 1.0)
}

@Test
func effectAdmissionRefusesNonFiniteAndOutOfRangeValues(): Unit {
    let nan = effectsNaN()
    let inf = effectsInfinity()

    // Non-finite colour components are refused by name (never folded to 0).
    @Assert(effectsReason(CjguiComposableUiColor(nan, 0.0, 0.0, 1.0).rejectionReason()),
        "color_component_not_finite")
    @Assert(effectsReason(CjguiComposableUiColor(0.0, inf, 0.0, 1.0).rejectionReason()),
        "color_component_not_finite")
    let infStop = CjguiComposableUiGradientStop(position: 0.5,
        color: CjguiComposableUiColor(0.0, 0.0, inf, 1.0))
    @Assert(effectsReason(infStop.rejectionReason()), "color_component_not_finite")

    // Non-finite coordinates / positions are refused, not clamped to 0.
    @Assert(effectsReason(CjguiComposableUiLinearGradient(startX: nan,
        stops: effectsLegalStops().toArray()).rejectionReason()), "gradient_coordinate_not_finite")
    @Assert(effectsReason(CjguiComposableUiLinearGradient(endY: inf,
        stops: effectsLegalStops().toArray()).rejectionReason()), "gradient_coordinate_not_finite")
    @Assert(effectsReason(CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: nan, color: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))
    ]).rejectionReason()), "gradient_stop_position_not_finite")

    // Finite out-of-range coordinates / positions are refused, not clamped.
    @Assert(effectsReason(CjguiComposableUiLinearGradient(startX: 1.5,
        stops: effectsLegalStops().toArray()).rejectionReason()), "gradient_coordinate_out_of_range")
    @Assert(effectsReason(CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: -0.1, color: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))
    ]).rejectionReason()), "gradient_stop_position_out_of_range")

    // Shadow scalars are admitted against the published bounds.
    @Assert(effectsReason(CjguiComposableUiShadowStyle(offsetX: 4097).rejectionReason()),
        "shadow_offset_out_of_range")
    @Assert(effectsReason(CjguiComposableUiShadowStyle(offsetY: -4097).rejectionReason()),
        "shadow_offset_out_of_range")
    @Assert(effectsReason(CjguiComposableUiShadowStyle(blurRadius: 257).rejectionReason()),
        "shadow_blur_out_of_range")
    @Assert(effectsReason(CjguiComposableUiShadowStyle(spread: 129).rejectionReason()),
        "shadow_spread_out_of_range")
    @Assert(effectsReason(CjguiComposableUiShadowStyle(
        color: CjguiComposableUiColor(nan, 0.0, 0.0, 0.4)).rejectionReason()), "color_component_not_finite")

    // Legal boundaries stay usable: coordinates/positions 0 or 1, shadow maxima.
    @Assert(CjguiComposableUiLinearGradient(startX: 0.0, startY: 1.0, endX: 1.0, endY: 0.0,
        stops: effectsLegalStops().toArray()).rejectionReason().isNone(), true)
    @Assert(CjguiComposableUiShadowStyle(offsetX: 4096, offsetY: -4096, blurRadius: 256,
        spread: 128).rejectionReason().isNone(), true)

    // Transparent colour and a legal "no effect" stay usable.
    @Assert(CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0).rejectionReason().isNone(), true)
    let transparentShadow = CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0))
    @Assert(CjguiComposableUiStyle(shadow: transparentShadow).shadow.isNone(), true)
    @Assert(CjguiComposableUiStyle().shadow.isNone(), true)
    @Assert(CjguiComposableUiStyle().gradient.isNone(), true)
}

@Test
func generatedEffectInheritsWhenAbsentAndClearsOnNoneOrEmpty(): Unit {
    let catalog = effectsCatalog()
    @Assert(catalog.namedStyles().register(effectsNamedStyle()), true)

    // (a) No effect declared: all named base effects are INHERITED.
    let (inheritHolder, inheritRoot) = effectsBuild(catalog,
        effectsNode(ArrayList<(String, String)>([("style", "effect_panel")])))
    let inherited = effectsCardStyle(inheritHolder, inheritRoot)
    @Assert(inherited.shadow.isSome(), true)
    @Assert(inherited.gradient.isSome(), true)
    @Assert(inherited.effectGroup.isSome(), true)

    // (b) Explicit `none` CLEARS all effects.
    let (noneHolder, noneRoot) = effectsBuild(catalog,
        effectsNode(ArrayList<(String, String)>([("style", "effect_panel"), ("shadow", "none"),
            ("gradient", "none"), ("effectGroup", "none")])))
    let cleared = effectsCardStyle(noneHolder, noneRoot)
    @Assert(cleared.shadow.isNone(), true)
    @Assert(cleared.gradient.isNone(), true)
    @Assert(cleared.effectGroup.isNone(), true)

    // (c) An empty string means the SAME as `none`: it CLEARS, never inherits.
    let (emptyHolder, emptyRoot) = effectsBuild(catalog,
        effectsNode(ArrayList<(String, String)>([("style", "effect_panel"), ("shadow", ""), ("gradient", ""), ("effectGroup", "")])))
    let emptied = effectsCardStyle(emptyHolder, emptyRoot)
    @Assert(emptied.shadow.isNone(), true)
    @Assert(emptied.gradient.isNone(), true)
    @Assert(emptied.effectGroup.isNone(), true)

    // (d) A legal token REPLACES the inherited effect.
    let (replaceHolder, replaceRoot) = effectsBuild(catalog,
        effectsNode(ArrayList<(String, String)>([("style", "effect_panel"), ("shadow", "0,3,10,0,#00000080"),
            ("gradient", "0,0,100,0,0:#112233ff|100:#445566ff"),
            ("effectGroup", "55,normal,none")])))
    let replaced = effectsCardStyle(replaceHolder, replaceRoot)
    @Assert(replaced.shadow.isSome(), true)
    @Assert(replaced.gradient.isSome(), true)
    @Assert(replaced.effectGroup.isSome(), true)
    let replacedGroup = match (replaced.effectGroup) {
        case Some(value) => value
        case None => CjguiComposableUiEffectGroup()
    }
    @Assert(replacedGroup.opacity, 0.55)
    @Assert(replacedGroup.blendMode, "normal")
    @Assert(replacedGroup.mask.isNone(), true)
    let replacedShadow = match (replaced.shadow) {
        case Some(value) => value
        case None => CjguiComposableUiShadowStyle()
    }
    @Assert(replacedShadow.blurRadius, 10)
    @Assert(replacedShadow.offsetY, 3)
}

@Test
func malformedGeneratedEffectRefusesWholeCandidateAndKeepsAccepted(): Unit {
    let catalog = effectsCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    // Seed an accepted structure carrying a legal shadow.
    @Assert(effectsCommit(holder,
        effectsNode(ArrayList<(String, String)>([("shadow", "0,2,8,0,#00000059")]))), true)
    let acceptedVersion = holder.structureVersion()
    let acceptedNodeId = holder.nodeIdForKey("card")

    // Malformed shadow text refuses the WHOLE candidate with a stable reason
    // and path; the accepted structure, version and identity are untouched.
    let provider = GeneratedTestProvider()
    let shadowResult = holder.submit(
        effectsNode(ArrayList<(String, String)>([("shadow", "12,oops,8,0,#000000")])), provider)
    @Assert(shadowResult.candidateAccepted, false)
    @Assert(shadowResult.reason, "shadow_value_invalid")
    @Assert(shadowResult.path.contains("/shadow"), true)
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.nodeIdForKey("card"), acceptedNodeId)
    @Assert(holder.acceptedNodeForKey("card").isSome(), true)

    // Malformed gradient text is refused the same way.
    let gradientResult = holder.submit(
        effectsNode(ArrayList<(String, String)>([("gradient", "0,0,140,0,0:#112233ff|100:#445566ff")])), provider)
    @Assert(gradientResult.candidateAccepted, false)
    @Assert(gradientResult.reason, "gradient_value_invalid")
    @Assert(gradientResult.path.contains("/gradient"), true)
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.nodeIdForKey("card"), acceptedNodeId)

    // An out-of-range token is a malformed token too.
    let rangeResult = holder.submit(
        effectsNode(ArrayList<(String, String)>([("shadow", "0,3,9999,0,#00000080")])), provider)
    @Assert(rangeResult.candidateAccepted, false)
    @Assert(rangeResult.reason, "shadow_value_invalid")

    let groupResult = holder.submit(
        effectsNode(ArrayList<(String, String)>([("effectGroup", "50,screen,none")])), provider)
    @Assert(groupResult.candidateAccepted, false)
    @Assert(groupResult.reason, "effect_group_value_invalid")
    @Assert(groupResult.path.contains("/effectGroup"), true)
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.nodeIdForKey("card"), acceptedNodeId)

    // A legal token after the refusals still takes effect.
    @Assert(effectsCommit(holder,
        effectsNode(ArrayList<(String, String)>([("shadow", "0,4,12,0,#00000060")]))), true)
    @Assert(holder.structureVersion(), acceptedVersion + 1)
    @Assert(holder.nodeIdForKey("card"), acceptedNodeId)
}

@Test
func effectEncodingRoundTripsAndPublishesSharedContract(): Unit {
    // Shadow: encode -> parse -> encode is stable.
    let shadow = CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.5),
        offsetX: -6, offsetY: 8, blurRadius: 30, spread: 3)
    let shadowToken = cjguiComposableUiShadowToken(shadow)
    let parsedShadow = match (cjguiComposableUiParseShadowToken(shadowToken)) {
        case Some(value) => value
        case None => CjguiComposableUiShadowStyle()
    }
    @Assert(cjguiComposableUiShadowToken(parsedShadow), shadowToken)

    // Gradient: encode -> parse -> encode is stable.
    let gradient = CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 1.0, stops: [
        CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.05, 0.48, 0.40, 1.0)),
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(0.5, 0.5, 0.5, 1.0)),
        CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(1.0, 0.82, 0.40, 1.0))
    ])
    let gradientToken = cjguiComposableUiGradientToken(gradient)
    let parsedGradient = match (cjguiComposableUiParseGradientToken(gradientToken)) {
        case Some(value) => value
        case None => CjguiComposableUiLinearGradient()
    }
    @Assert(cjguiComposableUiGradientToken(parsedGradient), gradientToken)

    let group = effectsLegalGroup()
    let groupToken = cjguiComposableUiEffectGroupToken(group)
    let parsedGroup = match (cjguiComposableUiParseEffectGroupToken(groupToken)) {
        case Some(value) => value
        case None => CjguiComposableUiEffectGroup()
    }
    @Assert(cjguiComposableUiEffectGroupToken(parsedGroup), groupToken)

    // A refused object is not describable and encodes as the explicit clear,
    // which the parser accepts as "no effect".
    @Assert(cjguiComposableUiShadowToken(CjguiComposableUiShadowStyle(blurRadius: 9999)), "none")
    let singleStop = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0))
    ])
    @Assert(cjguiComposableUiGradientToken(singleStop), "none")
    @Assert(cjguiComposableUiParseShadowToken("none").isNone(), true)
    @Assert(cjguiComposableUiParseGradientToken("").isNone(), true)
    @Assert(cjguiComposableUiParseShadowToken("0,3,9999,0,#00000080").isNone(), true)
    @Assert(cjguiComposableUiParseGradientToken("0,0,140,0,0:#112233ff|100:#445566ff").isNone(), true)

    // Discovery publishes the shared contract from the ONE definition.
    let catalog = effectsCatalog()
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(described.contains("encoding=offX,offY,blur,spread,#RRGGBBAA"), true)
    @Assert(described.contains("unit=logical_points"), true)
    @Assert(described.contains("range=offset:-4096..4096,blur:0..256,spread:0..128"), true)
    @Assert(described.contains("encoding=sx,sy,ex,ey,pos:color|pos:color"), true)
    @Assert(described.contains("unit=wire_percent_0..100,normalized_0..1"), true)
    @Assert(described.contains("range=coordinate:0..1,position:0..1,stops:2..4"), true)
    @Assert(described.contains("encoding=opacityPercent,mode,maskOrNone(sx,sy,ex,ey,pos:alpha|...)"), true)
    @Assert(described.contains("range=opacity:0..1,blend:normal|multiply,mask_coordinate:0..1,mask_position:0..1,mask_alpha:0..1,mask_stops:2..4,target_edge:4096,target_pixels:4194304,total_budget_bytes:100663296,groups:16,depth:4"), true)
    @Assert(described.contains("semantics=none_or_empty=clear,absent=inherit,mask=sx,sy,ex,ey,pos:alpha|...,stops=2..4"), true)
    @Assert(described.contains("stability=experimental"), true)
    @Assert(described.contains("support=macos:supported,ohos:unpublished_snapshot"), true)
}

@Test
func appendStyleSignatureMovesWithEffects(): Unit {
    let cache = CjguiComposableUiLayoutReuseCache(allowStructuralSignatures: true)
    let empty = CjguiComposableUiRect(0, 0, 120, 24)

    // Same content -> same signature.
    let plainA = cache.signatureFor(cjguiComposableText(7, "sig", "value", CjguiComposableUiStyle()), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    let plainB = cache.signatureFor(cjguiComposableText(7, "sig", "value", CjguiComposableUiStyle()), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    @Assert(plainA.value, plainB.value)
    @Assert(plainA.isCacheable, true)

    // A shadow-only change moves the signature.
    let shadowBase = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(blurRadius: 8)))
    let shadowMoved = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(blurRadius: 12)))
    let withShadow = cache.signatureFor(cjguiComposableText(7, "sig", "value", shadowBase), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    let shadowMovedSig = cache.signatureFor(cjguiComposableText(7, "sig", "value", shadowMoved), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    @Assert(plainA.value != withShadow.value, true)
    @Assert(withShadow.value != shadowMovedSig.value, true)

    // A gradient stop-only change moves the signature too.
    let gradientBase = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))
    ])
    let gradientMoved = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.0, 0.0, 0.0, 1.0)),
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))
    ])
    let withGradient = cache.signatureFor(cjguiComposableText(7, "sig", "value",
        CjguiComposableUiStyle(gradient: Some(gradientBase))), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    let gradientMovedSig = cache.signatureFor(cjguiComposableText(7, "sig", "value",
        CjguiComposableUiStyle(gradient: Some(gradientMoved))), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    @Assert(withGradient.value != gradientMovedSig.value, true)

    let effectGroupBase = CjguiComposableUiEffectGroup(opacity: 0.5, blendMode: "normal")
    let effectGroupMoved = CjguiComposableUiEffectGroup(opacity: 0.75, blendMode: "normal")
    let effectGroupBlurred = CjguiComposableUiEffectGroup(opacity: 0.5, blendMode: "normal",
        backdropBlurRadiusPoints: 8)
    let withEffectGroup = cache.signatureFor(cjguiComposableText(7, "sig", "value",
        CjguiComposableUiStyle(effectGroup: Some(effectGroupBase))), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    let effectGroupMovedSig = cache.signatureFor(cjguiComposableText(7, "sig", "value",
        CjguiComposableUiStyle(effectGroup: Some(effectGroupMoved))), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    let effectGroupBlurredSig = cache.signatureFor(cjguiComposableText(7, "sig", "value",
        CjguiComposableUiStyle(effectGroup: Some(effectGroupBlurred))), empty,
        ArrayList<CjguiComposableUiClipConstraint>(), "", "effect-signature-env")
    @Assert(withEffectGroup.value != effectGroupMovedSig.value, true)
    @Assert(withEffectGroup.value != effectGroupBlurredSig.value, true)
}
/// ⑥：手写非法效果必须保留具名拒绝（与生成侧同一词汇 + 声明路径），而不是被
/// 静默归一为 None；组合工具必须把该拒绝一路传递。
@Test
func handwrittenIllegalEffectKeepsNamedRejection(): Unit {
    let legal = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(blurRadius: 8)))
    @Assert(legal.effectRejection.isNone(), true)

    let illegalShadow = CjguiComposableUiStyle(shadow: Some(CjguiComposableUiShadowStyle(offsetX: 99999)))
    match (illegalShadow.effectRejection) {
        case Some(value) =>
            @Assert(value.reason, "shadow_value_invalid")
            @Assert(value.path, "/shadow")
        case None => @Assert(false, true)
    }

    let singleStop = CjguiComposableUiLinearGradient(stops: [
        CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0))
    ])
    let illegalGradient = CjguiComposableUiStyle(gradient: Some(singleStop))
    match (illegalGradient.effectRejection) {
        case Some(value) =>
            @Assert(value.reason, "gradient_value_invalid")
            @Assert(value.path, "/gradient")
        case None => @Assert(false, true)
    }

    // 组合工具（paint overlay / interaction resolve）必须携带具名拒绝。
    @Assert(cjguiComposableUiPaintOverlay(illegalShadow, CjguiComposableUiStyle()).effectRejection.isSome(), true)
    @Assert(CjguiComposableUiInteractionStyle().resolve(illegalShadow, 0).effectRejection.isSome(), true)
}

/// ⑥：效果整数字段必须在累加前判界。超出 Int64 的 token 必须返回 invalid
/// （None），而不是先触发算术异常；合法边缘仍可解析，旧控件不受影响。
@Test
func effectIntegerParsingRejectsOverflowWithoutThrowing(): Unit {
    @Assert(cjguiComposableUiParseShadowToken("9223372036854775808,0,0,0,#000000ff").isNone(), true)
    @Assert(cjguiComposableUiParseShadowToken("-9223372036854775809,0,0,0,#000000ff").isNone(), true)
    // Int64 最大值可解析，但超出 shadow offset 域，仍按 invalid 拒绝。
    @Assert(cjguiComposableUiParseShadowToken("9223372036854775807,0,0,0,#000000ff").isNone(), true)
    @Assert(cjguiComposableUiParseGradientToken(
        "99999999999999999999,0,100,0,0:#112233ff|100:#445566ff").isNone(), true)

    // 正负边缘仍在合法域内：解析成功且可回写。
    @Assert(cjguiComposableUiParseShadowToken("-4096,4096,0,0,#000000ff").isSome(), true)
    @Assert(cjguiComposableUiParseShadowToken("4096,-4096,256,128,#000000ff").isSome(), true)
    @Assert(cjguiComposableUiParseShadowToken("0,2,8,0,#00000080").isSome(), true)
}

@Test
func linearAlphaMaskValidatesSortsSamplesAndRejectsDegenerateInput(): Unit {
    let repeated = CjguiComposableUiLinearAlphaMask(startX: 0.0, startY: 0.5, endX: 1.0, endY: 0.5, stops: [
        CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0),
        CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.25),
        CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.75),
        CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0)
    ])
    @Assert(repeated.isValid(), true)
    @Assert(repeated.stops[0].position, 0.0)
    @Assert(repeated.stops[1].position, 0.5)
    @Assert(repeated.stops[1].alpha, 0.25)
    @Assert(repeated.stops[2].position, 0.5)
    @Assert(repeated.stops[2].alpha, 0.75)
    @Assert(repeated.alphaAt(0.5, 0.5), 0.75)
    @Assert(repeated.alphaAt(-0.01, 0.5), 0.0)
    @Assert(repeated.alphaAt(1.01, 0.5), 0.0)

    let tooMany = CjguiComposableUiLinearAlphaMask(stops: [
        CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0),
        CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
        CjguiComposableUiAlphaMaskStop(position: 0.25, alpha: 0.25),
        CjguiComposableUiAlphaMaskStop(position: 0.75, alpha: 0.75),
        CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.5)
    ])
    @Assert(effectsReason(tooMany.rejectionReason()), "effect_mask_stop_count_above_maximum")
    @Assert(tooMany.stops.size, 5)
    // Rejected stop counts preserve declaration order: sorting starts only after
    // count and scalar admission have completed.
    @Assert(tooMany.stops[0].position, 1.0)

    let zeroLength = CjguiComposableUiLinearAlphaMask(startX: 0.5, startY: 0.5, endX: 0.5, endY: 0.5,
        stops: [CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
            CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)])
    @Assert(effectsReason(zeroLength.rejectionReason()), "effect_mask_endpoints_coincident")

    let nan = effectsNaN()
    let inf = effectsInfinity()
    @Assert(effectsReason(CjguiComposableUiAlphaMaskStop(position: nan, alpha: 0.5).rejectionReason()),
        "effect_mask_stop_position_not_finite")
    @Assert(effectsReason(CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: inf).rejectionReason()),
        "effect_mask_stop_alpha_not_finite")
    @Assert(effectsReason(CjguiComposableUiLinearAlphaMask(startX: -0.1,
        stops: [CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
            CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)]).rejectionReason()),
        "effect_mask_coordinate_out_of_range")
    @Assert(effectsReason(CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 1.1).rejectionReason()),
        "effect_mask_stop_alpha_out_of_range")
}

@Test
func effectGroupValidationAndStyleCopiesKeepTheSharedDeclaration(): Unit {
    let group = effectsLegalGroup()
    @Assert(group.rejectionReason().isNone(), true)
    @Assert(CjguiComposableUiEffectGroup(opacity: effectsNaN()).rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(opacity: 1.01).rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(blendMode: "screen").rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(backdropBlurRadiusPoints: 17).rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(backdropBlurFallback: "drop").rejectionReason().isSome(), true)

    let illegal = CjguiComposableUiStyle(effectGroup: Some(CjguiComposableUiEffectGroup(blendMode: "screen")))
    @Assert(illegal.effectGroup.isNone(), true)
    match (illegal.effectRejection) {
        case Some(value) =>
            @Assert(value.reason, "effect_group_value_invalid")
            @Assert(value.path, "/effectGroup")
        case None => @Assert(false, true)
    }
    let illegalBlur = CjguiComposableUiStyle(effectGroup: Some(
        CjguiComposableUiEffectGroup(backdropBlurRadiusPoints: 17)))
    match (illegalBlur.effectRejection) {
        case Some(value) =>
            @Assert(value.reason, "effect_group_value_invalid")
            @Assert(value.path, "/effectGroup")
        case None => @Assert(false, true)
    }

    let style = CjguiComposableUiStyle(effectGroup: Some(group))
    @Assert(cjguiComposableUiPaintOverlay(style, CjguiComposableUiStyle()).effectGroup.isSome(), true)
    let resolved = CjguiComposableUiInteractionStyle().resolve(style, 0)
    @Assert(resolved.effectGroup.isSome(), true)
    let named = CjguiComposableUiNamedStyle("p4", style)
    @Assert(named.localStyle().effectGroup.isSome(), true)
}

@Test
func backdropBlurAdmissionAndEncodingStayBounded(): Unit {
    @Assert(CjguiComposableUiEffectGroup(backdropBlurRadiusPoints: -1).rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(backdropBlurRadiusPoints: 17).rejectionReason().isSome(), true)
    @Assert(CjguiComposableUiEffectGroup(backdropBlurFallback: "drop").rejectionReason().isSome(), true)
    let clear = CjguiComposableUiEffectGroup()
    @Assert(clear.backdropBlurRadiusPoints, 0)
    @Assert(clear.backdropBlurFallback, "unblurred")
    @Assert(cjguiComposableUiEffectGroupToken(clear), "100,normal,none")
    let blurred = CjguiComposableUiEffectGroup(opacity: 0.65, blendMode: "multiply",
        backdropBlurRadiusPoints: 8, backdropBlurFallback: "unblurred")
    let token = cjguiComposableUiEffectGroupToken(blurred)
    @Assert(token, "65,multiply,none;blur=8,unblurred")
    let parsed = match (cjguiComposableUiParseEffectGroupToken(token)) {
        case Some(value) => value
        case None => CjguiComposableUiEffectGroup()
    }
    @Assert(parsed.backdropBlurRadiusPoints, 8)
    @Assert(parsed.backdropBlurFallback, "unblurred")
    @Assert(cjguiComposableUiEffectGroupToken(parsed), token)
    @Assert(cjguiComposableUiParseEffectGroupToken("65,multiply,none;blur=17,unblurred").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("65,multiply,none;blur=8,drop").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("65,multiply,none;blur=8").isNone(), true)
}

@Test
func effectGroupTokenRoundTripsTheBoundedWireEncoding(): Unit {
    let group = CjguiComposableUiEffectGroup(opacity: 0.65, blendMode: "multiply",
        mask: Some(CjguiComposableUiLinearAlphaMask(startX: 0.25, startY: 0.5, endX: 0.75, endY: 0.5,
            stops: [CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
                CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.5),
                CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)])))
    let token = cjguiComposableUiEffectGroupToken(group)
    @Assert(token, "65,multiply,25,50,75,50,0:0|50:50|100:100")
    let parsed = match (cjguiComposableUiParseEffectGroupToken(token)) {
        case Some(value) => value
        case None => CjguiComposableUiEffectGroup()
    }
    @Assert(cjguiComposableUiEffectGroupToken(parsed), token)
    @Assert(cjguiComposableUiParseEffectGroupToken("none").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("50,screen,none").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("50,normal,50,50,50,50,0:0|100:100").isNone(), true)
    @Assert(cjguiComposableUiParseEffectGroupToken("50,normal,0,50,100,50,0:0|100:101").isNone(), true)
}

@Test
func effectGroupTokenIsAcceptedByGeneratedCandidateAndPublishedByDiscovery(): Unit {
    let catalog = effectsCatalog()
    @Assert(catalog.namedStyles().register(effectsNamedStyle()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(effectsCommit(holder, effectsNode(ArrayList<(String, String)>([("style", "effect_panel")]))), true)
    let acceptedVersion = holder.structureVersion()
    let acceptedNodeId = holder.nodeIdForKey("card")
    let provider = GeneratedTestProvider()
    let bad = holder.submit(effectsNode(ArrayList<(String, String)>([("effectGroup", "50,screen,none")])), provider)
    @Assert(bad.candidateAccepted, false)
    @Assert(bad.reason, "effect_group_value_invalid")
    @Assert(bad.path, "root/root/card/effectGroup")
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.nodeIdForKey("card"), acceptedNodeId)
    let badBlur = holder.submit(
        effectsNode(ArrayList<(String, String)>([("effectGroup", "50,normal,none;blur=17,unblurred")])), provider)
    @Assert(badBlur.candidateAccepted, false)
    @Assert(badBlur.reason, "effect_group_value_invalid")
    @Assert(badBlur.path, "root/root/card/effectGroup")
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(effectsCommit(holder,
        effectsNode(ArrayList<(String, String)>([("effectGroup", "50,normal,none")]))), true)
    let (blurredHolder, blurredRoot) = effectsBuild(catalog,
        effectsNode(ArrayList<(String, String)>([("effectGroup", "55,normal,none;blur=6,unblurred")])) )
    let blurredStyle = effectsCardStyle(blurredHolder, blurredRoot)
    let acceptedGroup = match (blurredStyle.effectGroup) {
        case Some(value) => value
        case None => CjguiComposableUiEffectGroup()
    }
    @Assert(acceptedGroup.backdropBlurRadiusPoints, 6)
    let acceptedInstance = CjguiGeneratedUiAcceptedInstance("card", "", "", 11, "card", "label", "", "",
        "blur card", true, CjguiComposableUiRect(1, 2, 3, 4), effectGroupToken: "55,normal,none;blur=6,unblurred")
    let acceptedPayload = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        ArrayList<CjguiGeneratedUiAcceptedInstance>([acceptedInstance]))
    @Assert(acceptedPayload.contains("effectGroup=55,normal,none;blur=6,unblurred"), true)

    let catalogDescription = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(catalogDescription.contains("encoding=opacityPercent,mode,maskOrNone(sx,sy,ex,ey,pos:alpha|...);blur=radiusPoints,unblurred"), true)
    @Assert(catalogDescription.contains("unit=wire_percent_0..100,normalized_0..1,blur_radius_logical_points"), true)
    @Assert(catalogDescription.contains("range=opacity:0..1,blend:normal|multiply,mask_coordinate:0..1,mask_position:0..1,mask_alpha:0..1,mask_stops:2..4,target_edge:4096,target_pixels:4194304,total_budget_bytes:100663296,groups:16,depth:4,backdrop_blur_radius_points:0..16,backdrop_blur_fallback:unblurred"), true)
    @Assert(catalogDescription.contains("semantics=none_or_empty=clear,absent=inherit,mask=sx,sy,ex,ey,pos:alpha|...,stops=2..4,blur=radiusPoints,unblurred"), true)
    @Assert(catalogDescription.contains("stability=experimental"), true)
    @Assert(catalogDescription.contains("support=macos:supported,ohos:unpublished_snapshot;backdrop_blur=macos:experimental_supported,ohos:unpublished_snapshot"), true)
}

@Test
func layoutSubtreeSpansIncludeSelfAndRemainRelativeWhenCached(): Unit {
    let root = cjguiComposableVertical(101, "span-root", CjguiComposableUiStyle())
    let cached = cjguiComposableVertical(102, "span-cached", CjguiComposableUiStyle(),
        layoutReuseKey: "span-cache")
    let branch = cjguiComposableVertical(103, "span-branch", CjguiComposableUiStyle())
    branch.add(cjguiComposableText(104, "span-leaf", "leaf", CjguiComposableUiStyle()))
    cached.add(branch)
    root.add(cached)
    root.add(cjguiComposableText(105, "span-sibling", "sibling", CjguiComposableUiStyle()))
    let cache = CjguiComposableUiLayoutReuseCache(allowStructuralSignatures: true)
    let viewport = CjguiComposableUiRect(0, 0, 400, 240)

    let first = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, viewport, 1,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: Some(cache))
    let replay = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, viewport, 2,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: Some(cache))
    @Assert(first.scene.nodeForId(101).subtreeNodeCount, 5)
    @Assert(first.scene.nodeForId(102).subtreeNodeCount, 3)
    @Assert(first.scene.nodeForId(103).subtreeNodeCount, 2)
    @Assert(first.scene.nodeForId(104).subtreeNodeCount, 1)
    @Assert(replay.metrics.subtreeReuseHitCount > 0, true)
    @Assert(replay.scene.nodeForId(101).subtreeNodeCount, 5)
    @Assert(replay.scene.nodeForId(102).subtreeNodeCount, 3)
    @Assert(replay.scene.nodeForId(103).subtreeNodeCount, 2)
    @Assert(replay.scene.nodeForId(104).subtreeNodeCount, 1)

    let withGroup = cjguiComposableVertical(201, "span-effect-root", CjguiComposableUiStyle())
    withGroup.add(cjguiComposableText(202, "span-effect-child", "effect",
        CjguiComposableUiStyle(effectGroup: Some(effectsLegalGroup()))))
    let effectScene = CjguiComposableUiLayoutEngine.layout(withGroup, viewport, 3)
    let effectNode = effectScene.nodeForId(202)
    let resolvedNode = effectNode.withResolvedPaintStyle(
        CjguiComposableUiInteractionStyle().resolve(effectNode.declaredStyle, 0))
    @Assert(resolvedNode.subtreeNodeCount, 1)
    @Assert(resolvedNode.style.effectGroup.isSome(), true)
}
