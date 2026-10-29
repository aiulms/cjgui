// One declared Select field feeds BOTH the handwritten control and the
// generated factory. This pins the factory branch, the allocated trigger
// identity, and the single owner commit without opening a window.

package cjgui_mixed_form_starter

import std.collection.*
import cjgui.*
import cjgui_shared_operation_core.*

private func findGeneratedNode(node: CjguiComposableUiNode, wanted: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == wanted) { return Some(node) }
    for (child in node.children()) {
        if (let Some(hit) <- findGeneratedNode(child, wanted)) { return Some(hit) }
    }
    return None
}

@Test
func mixedGeneratedSelectConsumesTheSharedFieldBinding(): Unit {
    let domain = PrintPresetDomain()
    let declared = CjguiSelectFieldBinding("duplex", "mixed-gen-select", "mixed-gen-duplex",
        mixedDuplexOptions(), commit: { option =>
            domain.editBooleanFromHuman(6203, option.value == "true").applied
        })
    let selectBindings = ArrayList<CjguiSelectFieldBinding>()
    selectBindings.add(declared)
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId, selectBindings: selectBindings)
    let catalog = form.capabilityCatalog(maxNodes: 32)
    @Assert(catalog.componentFor("select").isSome())
    @Assert(catalog.componentFor("select").getOrThrow().presentation, "FIELD_SELECT")

    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = MixedPresetProvider(form, domain.cards, domain)
    let properties = HashMap<String, String>()
    properties.add("label", "双面打印")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("duplex", "select", properties: properties, fieldId: "duplex"))
    let submitted = holder.submit(CjguiGeneratedUiNodeSpec("form", "vertical", children: children), provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let built = holder.buildAccepted(provider)
    let nodeId = holder.nodeIdForKey("duplex")
    @Assert(nodeId > 0, true)
    @Assert(form.generatedSelectBinding("duplex").isSome(), true)
    @Assert(provider.generatedSelectBinding("duplex").isSome(), true)
    let found = findGeneratedNode(built, nodeId).getOrThrow()
    @Assert(found.actionName, "mixed-gen-duplex-toggle")

    // Confirmation still names the declared stable key and writes the ONE owner.
    @Assert(declared.select.open())
    @Assert(declared.select.confirmKey("double"))
    let option = declared.takeConfirmed().getOrThrow()
    @Assert(declared.commit(option), true)
    @Assert(domain.formSnapshot().fieldForResourceId(6203).draftText, "true")
    declared.declare(domain.formSnapshot().fieldForResourceId(6203).draftText)
    @Assert(declared.select.selectedLabel(), "双面")
}


private func countGeneratedNodesByActionSuffix(root: CjguiComposableUiNode, suffix: String): Int64 {
    var total: Int64 = 0
    if (root.actionName.endsWith(suffix)) { total += 1 }
    for (child in root.children()) {
        total += countGeneratedNodesByActionSuffix(child, suffix)
    }
    return total
}

private func findGeneratedNodeByAction(root: CjguiComposableUiNode, action: String): ?CjguiComposableUiNode {
    if (root.actionName == action) { return Some(root) }
    for (child in root.children()) {
        if (let Some(hit) <- findGeneratedNodeByAction(child, action)) { return Some(hit) }
    }
    return None
}

@Test
func mixedGeneratedChoiceFamilyBuildsThreePresentationsFromOneField(): Unit {
    let domain = PrintPresetDomain()
    let declared = CjguiSelectFieldBinding("duplex", "mixed-gen-choice", "mixed-gen-choice-duplex",
        mixedDuplexOptions(), commit: { option =>
            domain.editBooleanFromHuman(6203, option.value == "true").applied
        })
    let selectBindings = ArrayList<CjguiSelectFieldBinding>()
    selectBindings.add(declared)
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId, selectBindings: selectBindings)
    let catalog = form.capabilityCatalog(maxNodes: 32)
    // The public discovery publishes the field's options and all three kinds.
    @Assert(catalog.componentFor("radioGroup").getOrThrow().presentation, "FIELD_RADIO_GROUP")
    @Assert(catalog.componentFor("segmented").getOrThrow().presentation, "FIELD_SEGMENTED")
    @Assert(catalog.choiceOptionsFor("duplex").getOrThrow().size, 2)
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    // The public discovery format is versioned. Option text keeps the existing
    // bounded token encoding (non-ASCII becomes u8:<hex>), and an unavailable
    // option carries its owner reason instead of dropping the row.
    @Assert(described.contains("CHOICE_FORMAT version=1 encoding=token " +
        "fields=fieldId,key,value,enabled,reason,label"), true)
    @Assert(described.contains("CHOICE duplex key=single value=false enabled=1 reason=none label=u8:"), true)

    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = MixedPresetProvider(form, domain.cards, domain)
    let properties = HashMap<String, String>()
    properties.add("label", "双面打印")
    let searchableProperties = HashMap<String, String>()
    searchableProperties.add("label", "双面打印")
    searchableProperties.add("searchable", "true")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("duplex-select", "select", properties: searchableProperties, fieldId: "duplex"))
    children.add(CjguiGeneratedUiNodeSpec("duplex-radio", "radioGroup", properties: properties, fieldId: "duplex"))
    children.add(CjguiGeneratedUiNodeSpec("duplex-seg", "segmented", properties: properties, fieldId: "duplex"))
    let submitted = holder.submit(CjguiGeneratedUiNodeSpec("form", "vertical", children: children), provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)

    // The declared searchable property is actually consumed by the factory.
    @Assert(declared.select.isSearchable(), true)

    let built = holder.buildAccepted(provider, feedback: form.formFeedback())
    // The dropdown trigger, the radio rows and the segmented rows are all real
    // presentations of the SAME field with the SAME stable-key actions.
    @Assert(findGeneratedNodeByAction(built, "mixed-gen-choice-duplex-toggle").isSome(), true)
    // One radio row and one segmented row, both carrying the field's stable
    // option key through the SAME "-choose:<key>" action vocabulary.
    @Assert(countGeneratedNodesByActionSuffix(built, "-choose:double"), 2)

    // The unmatched/deleted current option is explained, not rewritten.
    var reduced = ArrayList<CjguiSelectOption>()
    reduced.add(CjguiSelectOption("single", "单面", "false"))
    @Assert(declared.updateOptions(reduced), "")
    let reducedScene = holder.buildAccepted(provider, feedback: form.formFeedback())
    @Assert(countGeneratedNodesByActionSuffix(reducedScene, "-choose:double"), 0)
    @Assert(countGeneratedNodesByActionSuffix(reducedScene, "-choose:single"), 2)
    @Assert(declared.currentValue().size > 0, true)
    @Assert(declared.select.selectedLabel().startsWith("未匹配"), true)
}

@Test
func mixedGeneratedChoiceProjectionUsesOneFrozenFeedback(): Unit {
    let domain = PrintPresetDomain()
    let declared = CjguiSelectFieldBinding("duplex", "mixed-gen-frozen", "mixed-gen-frozen-duplex",
        mixedDuplexOptions(), commit: { option =>
            domain.editBooleanFromHuman(6203, option.value == "true").applied
        })
    let selectBindings = ArrayList<CjguiSelectFieldBinding>()
    selectBindings.add(declared)
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId, selectBindings: selectBindings)
    let catalog = form.capabilityCatalog(maxNodes: 32)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = MixedPresetProvider(form, domain.cards, domain)
    let properties = HashMap<String, String>()
    properties.add("label", "双面打印")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("duplex", "select", properties: properties, fieldId: "duplex"))
    let submitted = holder.submit(CjguiGeneratedUiNodeSpec("form", "vertical", children: children), provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)

    // Freeze one feedback snapshot, then move the owner's live draft (the
    // initial draft is 双面). A build with the FROZEN feedback must keep
    // projecting the frozen value; the same build without feedback follows
    // the live provider. The two sources are never mixed in one frame.
    let frozen = form.formFeedback()
    let edited = domain.editBooleanFromHuman(6203, false)
    @Assert(edited.applied, true)
    declared.declare(domain.formSnapshot().fieldForResourceId(6203).draftText)
    @Assert(declared.select.selectedLabel(), "单面")
    let frozenScene = holder.buildAccepted(provider, feedback: frozen)
    let frozenTrigger = findGeneratedNodeByAction(frozenScene, "mixed-gen-frozen-duplex-toggle").getOrThrow()
    @Assert(frozenTrigger.label.contains("双面"), true)
    let liveScene = holder.buildAccepted(provider)
    let liveTrigger = findGeneratedNodeByAction(liveScene, "mixed-gen-frozen-duplex-toggle").getOrThrow()
    @Assert(liveTrigger.label.contains("单面"), true)
}
