// Focused regressions for the runtime composition seam and the declaration
// fixes from the DS44 review. These exercise the framework objects directly;
// the real window chain is verified on the mixed/rules consumers.

package cjgui

import std.collection.*

private func compositionTestFind(root: CjguiComposableUiNode, semanticId: String): ?CjguiComposableUiNode {
    if (root.semanticId == semanticId) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- compositionTestFind(child, semanticId)) { return Some(found) }
    }
    return None
}

private func compositionTestCount(root: CjguiComposableUiNode): Int64 {
    var count: Int64 = 1
    for (child in root.children()) { count += compositionTestCount(child) }
    return count
}


private func compositionTestPayloads(definitions: ArrayList<CjguiRuntimeCompositionDefinition>): ArrayList<CjguiCompositionPayload> {
    let payloads = ArrayList<CjguiCompositionPayload>()
    for (definition in definitions) { payloads.add(CjguiCompositionPayload(definition)) }
    return payloads
}

class CompositionTestAllocator <: CjguiCompositeIdentityAllocator {
    private var next: Int64 = 1000

    public func allocate(slot: String): CjguiCompositeAllocatedIdentity {
        next += 1
        return CjguiCompositeAllocatedIdentity(next, "tpl-${slot}")
    }
}

private func compositionTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog(maxNodes: 64)
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("title", "标题", "TEXT", 501,
        maximumLength: 64, argumentName: "text"))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用"))
    return catalog
}

private func compositionTestSection(definitionName: String, fieldId: String): String {
    return "COMPOSITION ${definitionName} 40 6\n" +
        "CPARAM heading STRING 0 0 64 64 \\e\n" +
        "CELEMENT title field field=${fieldId} argument=text label=标题\n" +
        "CELEMENT apply action action=APPLY_DRAFT label=应用\n" +
        "CTEMPLATE 0 root vertical gap=4\n" +
        "CTEMPLATE 1 heading label text=" + "$" + "{heading}\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "CTEMPLATE 1 apply element element=apply presentation=text\n" +
        "COMPOSITION_END ${definitionName}\n"
}

private func compositionTestTwoPayload(firstName: String, firstField: String,
    secondName: String, secondField: String): String {
    return "GENERATED_UI_STRUCTURE 2\n" +
        compositionTestSection(firstName, firstField) +
        compositionTestSection(secondName, secondField) +
        "NODE 0 form vertical\nEND"
}

private func compositionTestPayload(definitionName: String, fieldId: String): String {
    return "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION ${definitionName} 40 6\n" +
        "CPARAM heading STRING 0 0 64 64 \\e\n" +
        "CELEMENT title field field=${fieldId} argument=text label=标题\n" +
        "CELEMENT apply action action=APPLY_DRAFT label=应用\n" +
        "CTEMPLATE 0 root vertical gap=4\n" +
        "CTEMPLATE 1 heading label text=" + "$" + "{heading}\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "CTEMPLATE 1 apply element element=apply presentation=text\n" +
        "COMPOSITION_END ${definitionName}\n" +
        "NODE 0 form vertical\n" +
        "END"
}

@Test
func testRuntimeCompositionStagesExpandsAndKeepsOldOnRefusal(): Unit {
    let catalog = compositionTestCatalog()
    let decoded = CjguiGeneratedUiEncoding.decode(compositionTestPayload("reportCard", "title"))
    @Assert(decoded.ok)
    let payload = decoded.definition.getOrThrow()
    @Assert(cjguiRuntimeCompositionIssue(payload.definition, catalog), "")
    @Assert(catalog.stageComposite(payload.definition.componentSpec(),
        CjguiRuntimeCompositionFactory(payload.definition, catalog: catalog)))
    @Assert(catalog.compositeFor("reportCard").isSome())
    catalog.commitStagedComposites()
    @Assert(catalog.compositeFor("reportCard").isSome())
    let component = catalog.componentFor("reportCard").getOrThrow()
    @Assert(component.presentation, CJGUI_GENERATED_PRESENTATION_COMPOSITE)

    let elements = ArrayList<CjguiCompositeElementBinding>()
    elements.add(CjguiCompositeElementBinding("title", CJGUI_COMPOSITE_ELEMENT_FIELD, 9001, "test-title", "标题",
        instanceKey: "reportCard-a", fieldId: "title", argumentName: "text",
        writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: 6301, bindingResourceId: 501,
        editorKind: "TEXT", draftText: "资料 A", ownerAvailable: true))
    elements.add(CjguiCompositeElementBinding("apply", CJGUI_COMPOSITE_ELEMENT_ACTION, 9002, "test-apply", "应用",
        instanceKey: "reportCard-a", actionName: "APPLY_DRAFT", actionEnabled: true,
        ownerTargetResourceId: 6301))
    let properties = HashMap<String, String>()
    properties.add("heading", "资料 A")
    let context = CjguiCompositeBuildContext("reportCard-a", properties, elements,
        namedStyles: catalog.namedStyles(), identityAllocator: CompositionTestAllocator())
    let built = CjguiRuntimeCompositionFactory(payload.definition, catalog: catalog).buildComposite(context)
    @Assert(built.nodeId > 0)
    // Parameter substitution reaches the label; the field keeps the resolved
    // element identity and the action keeps its declared element identity.
    let builtNodes = ArrayList<CjguiComposableUiNode>()
    nestedCollectAll(built, builtNodes)
    var substituted = false
    for (node in builtNodes) {
        if (node.value == "资料 A") { substituted = true }
    }
    @Assert(substituted, true)
    @Assert(compositionTestFind(built, "test-title").isSome())
    @Assert(compositionTestFind(built, "test-apply").isSome())
    @Assert(compositionTestCount(built) > 0)

    // A definition update naming an unknown field is refused by the ordinary
    // element validation; the ACCEPTED definition is untouched.
    let invalid = CjguiGeneratedUiEncoding.decode(compositionTestPayload("reportCard", "ghost"))
    @Assert(invalid.ok)
    let invalidDefinition = invalid.definition.getOrThrow().definition
    @Assert(!catalog.stageComposite(invalidDefinition.componentSpec(),
        CjguiRuntimeCompositionFactory(invalidDefinition, catalog: catalog)))
    @Assert(catalog.compositeFor("reportCard").getOrThrow().elements[0].fieldId, "title")
    catalog.rollbackStagedComposites()
    @Assert(catalog.compositeFor("reportCard").getOrThrow().elements[0].fieldId, "title")

}

@Test
func testRuntimeCompositionRefusesRecursionAndOverBudget(): Unit {
    let catalog = compositionTestCatalog()
    let recursive = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION recursiveCard 4 2\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 nested recursiveCard\n" +
        "COMPOSITION_END recursiveCard\n" +
        "NODE 0 form vertical\nEND"
    let decoded = CjguiGeneratedUiEncoding.decode(recursive)
    @Assert(decoded.ok)
    let definition = decoded.definition.getOrThrow().definition
    @Assert(cjguiRuntimeCompositionIssue(definition, catalog).startsWith("composition_unknown_template_kind:"))
    let tooDeep = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION tooDeep 4 1\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 child vertical\n" +
        "CTEMPLATE 2 inner vertical\n" +
        "COMPOSITION_END tooDeep\n" +
        "NODE 0 form vertical\nEND"
    let deepDecoded = CjguiGeneratedUiEncoding.decode(tooDeep)
    @Assert(deepDecoded.ok)
    @Assert(cjguiRuntimeCompositionIssue(deepDecoded.definition.getOrThrow().definition, catalog)
        .startsWith("composition_template_depth:"))
}

@Test
func testRuntimeCompositionDiscoveryStaysAcceptedAndPendingDefinitionSurvivesInvalidB(): Unit {
    let catalog = compositionTestCatalog()
    let acceptedPayload = compositionTestPayload("reportCard", "title")
    let acceptedDefinition = CjguiGeneratedUiEncoding.decode(acceptedPayload).definition.getOrThrow().definition
    @Assert(cjguiStageRuntimeComposition(catalog, acceptedDefinition), "")
    // A staged definition is a CANDIDATE fact: public discovery must not
    // advertise it before the scene accepted the same ticket.
    let pendingDiscovery = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(!pendingDiscovery.contains("COMPOSITE reportCard"), true)
    @Assert(catalog.compositeFor("reportCard").isSome())

    // An invalid B in another ticket must not clear A's pending definition.
    let invalid = CjguiGeneratedUiEncoding.decode(compositionTestPayload("reportCard", "ghost"))
        .definition.getOrThrow().definition
    @Assert(cjguiStageRuntimeComposition(catalog, invalid).startsWith("composition_rejected:"))
    @Assert(catalog.compositeFor("reportCard").getOrThrow().elements[0].fieldId, "title")

    catalog.commitStagedComposites()
    let acceptedDiscovery = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(acceptedDiscovery.contains("COMPOSITE reportCard"), true)
    let readback = catalog.acceptedCompositionPayload()
    @Assert(readback.contains("COMPOSITION reportCard 40 6"), true)
    @Assert(readback.contains("CELEMENT title field field=title argument=text label=标题"), true)
    @Assert(readback.contains("COMPOSITION_END reportCard"), true)
    @Assert(catalog.hasAcceptedComposition("reportCard"), true)

    // Explicit deletion travels in its own candidate and removes the accepted
    // kind from both discovery and the accepted definition snapshot.
    @Assert(catalog.stageCompositionRemoval("reportCard"), "")
    catalog.commitStagedComposites()
    @Assert(catalog.acceptedCompositionPayload(), "")
    @Assert(!CjguiGeneratedUiEncoding.describe(catalog).contains("COMPOSITE reportCard"), true)
    @Assert(catalog.compositeFor("reportCard").isNone())
    @Assert(catalog.stageCompositionRemoval("reportCard").startsWith("composition_remove_unknown:"))
}

@Test
func testRuntimeCompositionStrictDeclarationRefusals(): Unit {
    let catalog = compositionTestCatalog()
    let splitThree = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION splitCard 20 4\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root split axis=horizontal\n" +
        "CTEMPLATE 1 left vertical\n" +
        "CTEMPLATE 1 middle vertical\n" +
        "CTEMPLATE 1 right vertical\n" +
        "NODE 0 form vertical\nEND"
    let splitDecoded = CjguiGeneratedUiEncoding.decode(splitThree)
    @Assert(splitDecoded.ok)
    @Assert(cjguiRuntimeCompositionIssue(splitDecoded.definition.getOrThrow().definition, catalog),
        "composition_split_children:root")

    let leafChild = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION leafCard 20 4\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 entry element element=title presentation=text\n" +
        "CTEMPLATE 2 nested label text=x\n" +
        "NODE 0 form vertical\nEND"
    let leafDecoded = CjguiGeneratedUiEncoding.decode(leafChild)
    @Assert(leafDecoded.ok)
    @Assert(cjguiRuntimeCompositionIssue(leafDecoded.definition.getOrThrow().definition, catalog),
        "composition_leaf_children:entry")

    let badGap = splitThree.replace("axis=horizontal", "axis=horizontal gap=x")
    let badGapDecoded = CjguiGeneratedUiEncoding.decode(badGap)
    @Assert(!badGapDecoded.ok)
    @Assert(badGapDecoded.reason, "malformed_composition_template_value")
    let badAxis = splitThree.replace("axis=horizontal", "axis=sideways")
    let badAxisDecoded = CjguiGeneratedUiEncoding.decode(badAxis)
    @Assert(!badAxisDecoded.ok)
    @Assert(badAxisDecoded.reason, "composition_template_axis")
    let badRequired = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION badParam 20 4\n" +
        "CPARAM heading STRING 2 0 64 64 \\e\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 entry element element=title presentation=text\n" +
        "NODE 0 form vertical\nEND"
    let badRequiredDecoded = CjguiGeneratedUiEncoding.decode(badRequired)
    @Assert(!badRequiredDecoded.ok)
    @Assert(badRequiredDecoded.reason, "malformed_composition_param")
}

@Test
func testChoiceReasonLiteralNoneIsEncodedNotConfusedWithEmpty(): Unit {
    let catalog = compositionTestCatalog()
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("duplex", "双面", "BOOLEAN", 502,
        argumentName: "value"))
    let options = ArrayList<CjguiSelectOption>()
    options.add(CjguiSelectOption("single", "单面", "false"))
    options.add(CjguiSelectOption("double", "双面", "true", enabled: false, disabledReason: "none"))
    let binding = CjguiSelectFieldBinding("duplex", "none-test", "none-select", options,
        commit: { _ => true })
    @Assert(catalog.registerChoiceOptions("duplex", binding.options()))
    let text = CjguiGeneratedUiEncoding.describe(catalog)
    // The literal reason is bytes; the empty reason keeps the reserved token.
    // The shared producer emits UPPERCASE hex for every `u8:` token.
    @Assert(text.contains("key=double value=true enabled=0 reason=u8:6E6F6E65"), true)
    @Assert(text.contains("key=single value=false enabled=1 reason=none"), true)
}

@Test
func testChoiceSearchableFollowsCurrentDeclarationAndWithdraws(): Unit {
    let options = ArrayList<CjguiSelectOption>()
    options.add(CjguiSelectOption("single", "单面", "false"))
    options.add(CjguiSelectOption("double", "双面", "true"))
    let binding = CjguiSelectFieldBinding("duplex", "searchable-test", "searchable-select", options,
        commit: { _ => true }, searchable: true)
    @Assert(binding.isSearchable())
    binding.declare("false", searchable: Some(false))
    @Assert(!binding.isSearchable())
    // A presentation that OMITS the property must not reset the current value.
    binding.declare("false")
    @Assert(!binding.isSearchable())
    binding.declare("false", searchable: Some(true))
    @Assert(binding.isSearchable())
    binding.declare("false")
    @Assert(binding.isSearchable())
}

@Test
func testChoiceDiscoveryUsesLiveOptionsAndBoundedReason(): Unit {
    let catalog = compositionTestCatalog()
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("duplex", "双面", "BOOLEAN", 502,
        argumentName: "value"))
    let options = ArrayList<CjguiSelectOption>()
    options.add(CjguiSelectOption("single", "单面", "false"))
    options.add(CjguiSelectOption("double", "双面", "true", disabledReason: "已锁定"))
    let binding = CjguiSelectFieldBinding("duplex", "discovery-test", "discovery-select", options,
        commit: { _ => true })
    @Assert(catalog.registerChoiceOptions("duplex", binding.options()))
    @Assert(catalog.bindChoiceOptions("duplex", binding))
    let before = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(before.contains("CHOICE_FORMAT version=1"))
    @Assert(before.contains("key=double value=true enabled=1 reason=u8:"))
    // Dynamic option removal reaches the SAME discovery fact, not a stale
    // registration copy.
    let current = ArrayList<CjguiSelectOption>()
    current.add(CjguiSelectOption("single", "单面", "false"))
    @Assert(binding.updateOptions(current), "")
    let after = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(after.contains("key=single value=false"))
    @Assert(!after.contains("key=double"))
    // A refused dynamic update leaves the current options (and their
    // presentation/query state) exactly as they were.
    let duplicate = ArrayList<CjguiSelectOption>()
    duplicate.add(CjguiSelectOption("same", "一", "1"))
    duplicate.add(CjguiSelectOption("same", "二", "2"))
    @Assert(binding.updateOptions(duplicate).startsWith("select_duplicate_key:"))
    @Assert(binding.options().size, 1)
    @Assert(binding.options()[0].key, "single")
}

@Test
func testChoiceGroupStyleResolvedFromDeclarationReachesRows(): Unit {
    let base = CjguiComposableUiStyle(fixedHeight: 34, padding: 8, gap: 6,
        background: CjguiComposableUiColor(0.91, 0.93, 0.98, 1.0),
        border: CjguiComposableUiColor(0.30, 0.40, 0.70, 1.0), borderWidth: 1,
        textColor: CjguiComposableUiColor(0.10, 0.12, 0.18, 1.0), fontSize: 13.0, growX: 1)
    let style = CjguiChoiceGroupStyleTheme.fromResolvedStyle(base)
    @Assert(style.button.fixedHeight, 34)
    @Assert(style.button.padding, 8)
    @Assert(style.button.fontSize, 13.0)
    @Assert(style.button.background.blue > 0.9)
    @Assert(style.container.growX, 1)
    @Assert(style.rowGap, 6)
}

@Test
func testCompositionEndValidatesNameAndBoundary(): Unit {
    let base = compositionTestPayload("reportCard", "title")
    // The old candidate spelling without COMPOSITION_END remains accepted.
    @Assert(CjguiGeneratedUiEncoding.decode(base).ok)
    let closed = base.replace("NODE 0 form vertical", "COMPOSITION_END reportCard\nNODE 0 form vertical")
    @Assert(CjguiGeneratedUiEncoding.decode(closed).ok)
    let wrong = base.replace("NODE 0 form vertical", "COMPOSITION_END otherCard\nNODE 0 form vertical")
    let wrongDecoded = CjguiGeneratedUiEncoding.decode(wrong)
    @Assert(!wrongDecoded.ok)
    @Assert(wrongDecoded.reason, "composition_end_name_mismatch:otherCard")
    let duplicate = base.replace("NODE 0 form vertical",
        "COMPOSITION_END reportCard\nCOMPOSITION_END reportCard\nNODE 0 form vertical")
    let duplicateDecoded = CjguiGeneratedUiEncoding.decode(duplicate)
    @Assert(!duplicateDecoded.ok)
    @Assert(duplicateDecoded.reason, "duplicate_composition_end")
    let after = base.replace("NODE 0 form vertical",
        "COMPOSITION_END reportCard\nCELEMENT late field field=title label=late\nNODE 0 form vertical")
    let afterDecoded = CjguiGeneratedUiEncoding.decode(after)
    @Assert(!afterDecoded.ok)
    @Assert(afterDecoded.reason, "composition_content_after_end")
    let without = "GENERATED_UI_STRUCTURE 2\nCOMPOSITION_END reportCard\nNODE 0 form vertical\nEND"
    let withoutDecoded = CjguiGeneratedUiEncoding.decode(without)
    @Assert(!withoutDecoded.ok)
    @Assert(withoutDecoded.reason, "composition_end_without_header")
}

@Test
func testCompositionParamDefaultMustBeOneRepresentableToken(): Unit {
    let base = compositionTestPayload("reportCard", "title")
    let spaced = base.replace("CPARAM heading STRING 0 0 64 64 \\e",
        "CPARAM heading STRING 0 0 64 64 双面 打印")
    let spacedDecoded = CjguiGeneratedUiEncoding.decode(spaced)
    @Assert(!spacedDecoded.ok)
    @Assert(spacedDecoded.reason, "composition_parameter_extra_tokens:heading")
    let lone = base.replace("CPARAM heading STRING 0 0 64 64 \\e",
        "CPARAM heading STRING 0 0 64 64 \\")
    let loneDecoded = CjguiGeneratedUiEncoding.decode(lone)
    @Assert(!loneDecoded.ok)
    @Assert(loneDecoded.reason, "composition_parameter_default_not_representable:heading")
    let decoded = CjguiGeneratedUiEncoding.decode(base).definition.getOrThrow().definition
    let parameters = ArrayList<CjguiCompositionParameter>()
    parameters.add(CjguiCompositionParameter("heading", "STRING", maxLength: 64, defaultValue: "双面 打印"))
    let spacedDefinition = CjguiRuntimeCompositionDefinition("reportCard", parameters,
        decoded.elements, decoded.template)
    @Assert(cjguiRuntimeCompositionIssue(spacedDefinition, compositionTestCatalog()),
        "composition_parameter_default_not_single:heading")
    let representable = ArrayList<CjguiCompositionParameter>()
    representable.add(CjguiCompositionParameter("heading", "STRING", maxLength: 64, defaultValue: "a=b"))
    let representableDefinition = CjguiRuntimeCompositionDefinition("reportCard", representable,
        decoded.elements, decoded.template)
    @Assert(cjguiRuntimeCompositionIssue(representableDefinition, compositionTestCatalog()), "")
}

@Test
func testCompositionBooleanChoiceReflectsCurrentValue(): Unit {
    let catalog = compositionTestCatalog()
    let payload = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION boolCard 40 6\n" +
        "CELEMENT mode field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 mode element element=mode presentation=select\n" +
        "NODE 0 form vertical\nEND"
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    @Assert(decoded.ok)
    let definition = decoded.definition.getOrThrow().definition
    let options = ArrayList<CjguiSelectOption>()
    options.add(CjguiSelectOption("single", "单面", "false"))
    options.add(CjguiSelectOption("double", "双面", "true"))
    let elements = ArrayList<CjguiCompositeElementBinding>()
    elements.add(CjguiCompositeElementBinding("mode", CJGUI_COMPOSITE_ELEMENT_FIELD, 9101, "test-mode",
        "双面打印", instanceKey: "bool-a", fieldId: "title", argumentName: "value",
        writerOperation: "EDIT_DRAFT_BOOLEAN", ownerTargetResourceId: 6301,
        bindingResourceId: 501, editorKind: "BOOLEAN", draftBoolean: true,
        choiceOptions: options))
    let context = CjguiCompositeBuildContext("bool-a", HashMap<String, String>(), elements,
        namedStyles: catalog.namedStyles(), identityAllocator: CompositionTestAllocator())
    let built = CjguiRuntimeCompositionFactory(definition, catalog: catalog).buildComposite(context)
    // A BOOLEAN draft lives in draftBoolean; the trigger must label the CURRENT
    // option instead of falling back to "请选择" for the empty draftText.
    let trigger = compositionTestFind(built, "test-mode").getOrThrow()
    @Assert(trigger.value.contains("双面"), true)
}

@Test
func testTwoDefinitionsTravelInOneCandidateAndCommitTogether(): Unit {
    let catalog = compositionTestCatalog()
    let payload = compositionTestTwoPayload("reportCard", "title", "statusCard", "title")
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    @Assert(decoded.ok)
    @Assert(decoded.definitions.size, 2)
    let stageIssue = cjguiStageRuntimeCompositions(catalog, decoded.definitions)
    if (stageIssue.size > 0) { println("NESTED_STAGE_FAIL=${stageIssue}") }
    @Assert(stageIssue, "")
    // Both staged definitions are candidate facts, not accepted ones yet.
    @Assert(catalog.acceptedCompositeFor("reportCard").isNone())
    @Assert(catalog.acceptedCompositeFor("statusCard").isNone())
    @Assert(catalog.compositeFor("reportCard").isSome())
    @Assert(catalog.compositeFor("statusCard").isSome())
    catalog.commitStagedComposites()
    @Assert(catalog.acceptedCompositeFor("reportCard").isSome())
    @Assert(catalog.acceptedCompositeFor("statusCard").isSome())
    let readback = catalog.acceptedCompositionPayload()
    @Assert(readback.contains("COMPOSITION reportCard 40 6"), true)
    @Assert(readback.contains("COMPOSITION statusCard 40 6"), true)
    @Assert(readback.contains("COMPOSITION_END statusCard"), true)
}

@Test
func testMultiDefinitionRefusalsAreNamedAndLeaveACceptedUntouched(): Unit {
    let duplicate = "GENERATED_UI_STRUCTURE 2\n" +
        compositionTestSection("sameCard", "title") +
        compositionTestSection("sameCard", "title") +
        "NODE 0 form vertical\nEND"
    let duplicateDecoded = CjguiGeneratedUiEncoding.decode(duplicate)
    @Assert(!duplicateDecoded.ok)
    @Assert(duplicateDecoded.reason, "composition_duplicate_name:sameCard")

    let missingEnd = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION firstCard 40 6\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical\n" +
        "COMPOSITION secondCard 40 6\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical\n" +
        "COMPOSITION_END secondCard\n" +
        "NODE 0 form vertical\nEND"
    let missingDecoded = CjguiGeneratedUiEncoding.decode(missingEnd)
    @Assert(!missingDecoded.ok)
    @Assert(missingDecoded.reason, "composition_end_missing:firstCard")

    let defineAndRemove = "GENERATED_UI_STRUCTURE 2\n" +
        compositionTestSection("keptCard", "title") +
        "COMPOSITION_REMOVE keptCard\n" +
        "NODE 0 form vertical\nEND"
    let defineAndRemoveDecoded = CjguiGeneratedUiEncoding.decode(defineAndRemove)
    @Assert(!defineAndRemoveDecoded.ok)
    @Assert(defineAndRemoveDecoded.reason, "composition_remove_and_define:keptCard")
}

@Test
func testMultiDefinitionInvalidSectionStagesNoPrefix(): Unit {
    let catalog = compositionTestCatalog()
    let accepted = CjguiGeneratedUiEncoding.decode(compositionTestPayload("reportCard", "title"))
        .definition.getOrThrow().definition
    @Assert(cjguiStageRuntimeComposition(catalog, accepted), "")
    catalog.commitStagedComposites()
    let before = catalog.acceptedCompositionPayload()

    // B names a field the catalog does not declare. A (declared first) must
    // not become accepted, and the previously accepted definition must stay.
    let batch = CjguiGeneratedUiEncoding.decode(
        compositionTestTwoPayload("newCard", "title", "badCard", "ghost"))
    @Assert(batch.ok)
    let previous = catalog.snapshotStagedComposites()
    catalog.rollbackStagedComposites()
    let issue = cjguiStageRuntimeCompositions(catalog, batch.definitions)
    @Assert(issue.startsWith("composition_rejected:"), true)
    @Assert(issue.contains("composition_unknown_field:ghost"), true)
    catalog.restoreStagedComposites(previous)
    @Assert(catalog.acceptedCompositeFor("newCard").isNone())
    @Assert(catalog.compositeFor("newCard").isNone())
    @Assert(catalog.acceptedCompositionPayload(), before)
    @Assert(catalog.compositeFor("reportCard").isSome())
}

/// §16: TWO instances of the same nested composition keep separate owners,
/// drafts and identities. The panel references the card composition, which
/// references the field group; each instance builds from its OWN element
/// bindings, so owner A's draft never appears in owner B's tree.
@Test
func testNestedCompositionTwoInstancesKeepOwnersSeparate(): Unit {
    let catalog = compositionTestCatalog()
    let fieldGroup = "COMPOSITION fieldGroup 24 4\n" +
        "CPARAM heading STRING 0 0 64 64 \\e\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical gap=2\n" +
        "CTEMPLATE 1 heading label text=" + "$" + "{heading}\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "COMPOSITION_END fieldGroup\n"
    let card = "COMPOSITION card 40 6\n" +
        "CELEMENT apply action action=APPLY_DRAFT label=应用\n" +
        "CTEMPLATE 0 root vertical gap=4\n" +
        "CTEMPLATE 1 group composition compose=fieldGroup\n" +
        "CTEMPLATE 1 apply element element=apply presentation=text\n" +
        "COMPOSITION_END card\n"
    let panel = "COMPOSITION panel 64 8\n" +
        "CELEMENT heading projection source=owner_status label=面板标题\n" +
        "CTEMPLATE 0 root horizontal gap=8\n" +
        "CTEMPLATE 1 head element element=heading presentation=text\n" +
        "CTEMPLATE 1 cardA composition compose=card\n" +
        "CTEMPLATE 1 cardB composition compose=card\n" +
        "COMPOSITION_END panel\n"
    let payload = "GENERATED_UI_STRUCTURE 2\n" + fieldGroup + card + panel +
        "NODE 0 form vertical\n" +
        "NODE 1 left panel\n" +
        "NODE 1 right panel\n" +
        "END"
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    @Assert(decoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, decoded.definitions), "")
    catalog.commitStagedComposites()

    // Instance left: every element binds owner A; instance right: owner B.
    let elementsA = ArrayList<CjguiCompositeElementBinding>()
    elementsA.add(CjguiCompositeElementBinding("title", CJGUI_COMPOSITE_ELEMENT_FIELD, 9101,
        "left-group-title", "标题", instanceKey: "left", fieldId: "title", argumentName: "text",
        writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: 6301, bindingResourceId: 501,
        editorKind: "TEXT", draftText: "甲的草稿", ownerAvailable: true))
    elementsA.add(CjguiCompositeElementBinding("apply", CJGUI_COMPOSITE_ELEMENT_ACTION, 9102,
        "left-apply", "应用", instanceKey: "left", actionName: "APPLY_DRAFT", actionEnabled: true,
        ownerTargetResourceId: 6301))
    elementsA.add(CjguiCompositeElementBinding("heading", CJGUI_COMPOSITE_ELEMENT_PROJECTION, 9103,
        "left-heading", "面板标题", instanceKey: "left", projectionText: "面板就绪",
        ownerAvailable: true, ownerTargetResourceId: 6301))
    let elementsB = ArrayList<CjguiCompositeElementBinding>()
    elementsB.add(CjguiCompositeElementBinding("title", CJGUI_COMPOSITE_ELEMENT_FIELD, 9201,
        "right-group-title", "标题", instanceKey: "right", fieldId: "title", argumentName: "text",
        writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: 6302, bindingResourceId: 501,
        editorKind: "TEXT", draftText: "乙的草稿", ownerAvailable: true))
    elementsB.add(CjguiCompositeElementBinding("apply", CJGUI_COMPOSITE_ELEMENT_ACTION, 9202,
        "right-apply", "应用", instanceKey: "right", actionName: "APPLY_DRAFT", actionEnabled: true,
        ownerTargetResourceId: 6302))
    elementsB.add(CjguiCompositeElementBinding("heading", CJGUI_COMPOSITE_ELEMENT_PROJECTION, 9203,
        "right-heading", "面板标题", instanceKey: "right", projectionText: "面板就绪",
        ownerAvailable: true, ownerTargetResourceId: 6302))
    let factory = catalog.compositeFactoryFor("panel").getOrThrow()
    let properties = HashMap<String, String>()
    let builtA = factory.buildComposite(CjguiCompositeBuildContext("left", properties, elementsA,
        namedStyles: catalog.namedStyles(), identityAllocator: CompositionTestAllocator()))
    let builtB = factory.buildComposite(CjguiCompositeBuildContext("right", properties, elementsB,
        namedStyles: catalog.namedStyles(), identityAllocator: CompositionTestAllocator()))
    // Each instance shows ITS OWN owner's draft in the nested field, and the
    // identity sets are disjoint.
    let fieldA = compositionTestFind(builtA, "left-group-title").getOrThrow()
    let fieldB = compositionTestFind(builtB, "right-group-title").getOrThrow()
    @Assert(fieldA.value, "甲的草稿")
    @Assert(fieldB.value, "乙的草稿")
    @Assert(fieldA.nodeId != fieldB.nodeId, true)
    @Assert(compositionTestFind(builtA, "right-group-title").isNone(), true)
    @Assert(compositionTestFind(builtB, "left-group-title").isNone(), true)
}

/// §16 RED: a legal bounded nesting — 面板(panel)→卡片(card)→字段组(field group) —
/// where the panel template REFERENCES the card composition and the card
/// template REFERENCES the field-group composition. All three travel in ONE
/// candidate; two panel instances bind DIFFERENT owners through the ordinary
/// instance resolution. The current implementation refuses the nested
/// reference with `composition_unknown_template_kind:<name>`, which is exactly
/// the gap this package closes.
@Test
func testNestedPanelCardFieldGroupDefinitionStagesAndExpands(): Unit {
    let catalog = compositionTestCatalog()
    let fieldGroup = "COMPOSITION fieldGroup 24 4\n" +
        "CPARAM heading STRING 0 0 64 64 \\e\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical gap=2\n" +
        "CTEMPLATE 1 heading label text=" + "$" + "{heading}\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "COMPOSITION_END fieldGroup\n"
    let card = "COMPOSITION card 40 6\n" +
        "CELEMENT apply action action=APPLY_DRAFT label=应用\n" +
        "CTEMPLATE 0 root vertical gap=4\n" +
        "CTEMPLATE 1 group composition compose=fieldGroup\n" +
        "CTEMPLATE 1 apply element element=apply presentation=text\n" +
        "COMPOSITION_END card\n"
    let panel = "COMPOSITION panel 64 8\n" +
        "CELEMENT heading projection source=owner_status label=面板标题\n" +
        "CTEMPLATE 0 root horizontal gap=8\n" +
        "CTEMPLATE 1 head element element=heading presentation=text\n" +
        "CTEMPLATE 1 cardA composition compose=card\n" +
        "CTEMPLATE 1 cardB composition compose=card\n" +
        "COMPOSITION_END panel\n"
    let payload = "GENERATED_UI_STRUCTURE 2\n" + fieldGroup + card + panel +
        "NODE 0 form vertical\n" +
        "NODE 1 left panel\n" +
        "NODE 1 right panel\n" +
        "END"
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    @Assert(decoded.ok, true)
    @Assert(decoded.definitions.size, 3)
    // All THREE validate against the candidate's own effective set (the
    // forward reference from panel/card to a LATER definition is legal).
    var index = 0
    while (index < decoded.definitions.size) {
        let issue = cjguiRuntimeCompositionIssue(decoded.definitions[index].definition, catalog)
        if (issue.size > 0) { println("NESTED_ISSUE[${index}]=${issue}") }
        @Assert(issue, "")
        index += 1
    }
    let stageIssue = cjguiStageRuntimeCompositions(catalog, decoded.definitions)
    if (stageIssue.size > 0) { println("NESTED_STAGE_FAIL=${stageIssue}") }
    @Assert(stageIssue, "")
    catalog.commitStagedComposites()
    @Assert(catalog.compositeFor("panel").isSome(), true)
    @Assert(catalog.compositeFor("card").isSome(), true)
    @Assert(catalog.compositeFor("fieldGroup").isSome(), true)
    // The real instance path allocates the TRANSITIVE element set: a nested
    // element has no identity otherwise, and the expansion used to be refused
    // as composite_unidentified_node.
    let effective = cjguiEffectiveCompositeElements(catalog, "panel")
    @Assert(effective.size, 3)
    var keys = ArrayList<String>()
    for (element in effective) { keys.add(element.elementKey) }
    @Assert(keys.contains("heading"), true)
    @Assert(keys.contains("apply"), true)
    @Assert(keys.contains("title"), true)
    @Assert(cjguiCompositionElementKeyConflict(catalog, decoded.definitions[2].definition) == "", true)
}

/// §16 RED (negative half of the same seam): a direct cycle and an indirect
/// cycle are refused with named reasons; a deletion still referenced by a
/// remaining definition is refused; unknown compose targets are refused.
@Test
func testNestedCompositionCycleUnknownAndStillReferencedRefusals(): Unit {
    let catalog = compositionTestCatalog()
    // Direct cycle: panel → panel.
    let direct = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION panel 40 6\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 inner composition compose=panel\n" +
        "COMPOSITION_END panel\n" +
        "NODE 0 form vertical\nEND"
    // A DIRECT cycle (self-reference) is refused at DECODE time with the same
    // named reason; the batch graph check covers every indirect path.
    let directDecoded = CjguiGeneratedUiEncoding.decode(direct)
    @Assert(directDecoded.ok, false)
    @Assert(directDecoded.reason.startsWith("composition_compose_cycle:"), true)
    // Indirect cycle: a → b → a.
    catalog.rollbackStagedComposites()
    let indirect = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION outerA 40 6\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 inner composition compose=outerB\n" +
        "COMPOSITION_END outerA\n" +
        "COMPOSITION outerB 40 6\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 inner composition compose=outerA\n" +
        "COMPOSITION_END outerB\n" +
        "NODE 0 form vertical\nEND"
    let indirectDecoded = CjguiGeneratedUiEncoding.decode(indirect)
    @Assert(indirectDecoded.ok, true)
    let indirectIssue = cjguiStageRuntimeCompositions(catalog, indirectDecoded.definitions)
    @Assert(indirectIssue.startsWith("composition_rejected:composition_compose_cycle:"), true)
    catalog.rollbackStagedComposites()
    // Unknown compose target.
    let unknown = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION usesGhost 40 6\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 inner composition compose=ghostPanel\n" +
        "COMPOSITION_END usesGhost\n" +
        "NODE 0 form vertical\nEND"
    let unknownDecoded = CjguiGeneratedUiEncoding.decode(unknown)
    @Assert(unknownDecoded.ok, true)
    let unknownIssue = cjguiStageRuntimeCompositions(catalog, unknownDecoded.definitions)
    @Assert(unknownIssue.startsWith("composition_rejected:composition_compose_unknown:"), true)
    // Deletion still referenced: stage a legal pair, commit, then remove the
    // referenced definition while the referencing one remains.
    let pair = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION fieldGroup 24 4\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "COMPOSITION_END fieldGroup\n" +
        "COMPOSITION holder 40 6\n" +
        "CELEMENT title field field=title argument=text\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 inner composition compose=fieldGroup\n" +
        "COMPOSITION_END holder\n" +
        "NODE 0 form vertical\nEND"
    let pairDecoded = CjguiGeneratedUiEncoding.decode(pair)
    @Assert(pairDecoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, pairDecoded.definitions), "")
    catalog.commitStagedComposites()
    let removalIssue = catalog.stageCompositionRemoval("fieldGroup")
    @Assert(removalIssue.startsWith("composition_remove_still_referenced:"), true)
}

/// §16.6: the REAL holder/render/audit path with a legal repeated reference.
/// A panel references the same card twice; each reference must mount its own
/// presentation identity (distinct node ids) while both keep the panel
/// instance's owner binding. Before the fix the second reference reused the
/// first reference's element node id and the audit refused the whole candidate.
private class NestedRepeatedOwnerProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return 501 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 42 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        if (instanceKey == "left") { return 6301 }
        if (instanceKey == "right") { return 6302 }
        return 42
    }
    public func draftText(fieldId: String): String { return "draft" }
    public func draftText(fieldId: String, instanceKey: String): String {
        if (instanceKey == "left") { return "甲的草稿" }
        if (instanceKey == "right") { return "乙的草稿" }
        return "draft"
    }
    public func appliedText(fieldId: String): String { return "applied" }
    public func draftBoolean(fieldId: String): ?Bool { return Some(false) }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        if (instanceKey == "left") { return 6301 }
        if (instanceKey == "right") { return 6302 }
        return -1
    }
}

private func nestedRepeatedCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = compositionTestCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    return catalog
}

private func nestedRepeatedPayload(): String {
    // Reference and element keys deliberately contain ':' so a naive
    // concatenated scope path would collide (base "a:"/"b" vs "a"/":b").
    let fieldGroup = "COMPOSITION fieldGroup 24 4\n" +
        "CPARAM heading STRING 0 0 64 64 \\e\n" +
        "CELEMENT title:1 field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical gap=2\n" +
        "CTEMPLATE 1 heading label text=" + "$" + "{heading}\n" +
        "CTEMPLATE 1 title:1 element element=title:1 presentation=text\n" +
        "COMPOSITION_END fieldGroup\n"
    let card = "COMPOSITION card 40 6\n" +
        "CELEMENT apply:1 action action=APPLY_DRAFT label=应用\n" +
        "CTEMPLATE 0 root vertical gap=4\n" +
        "CTEMPLATE 1 group:1 composition compose=fieldGroup\n" +
        "CTEMPLATE 1 apply:1 element element=apply:1 presentation=text\n" +
        "COMPOSITION_END card\n"
    let panel = "COMPOSITION panel 64 8\n" +
        "CELEMENT heading projection source=owner_status label=面板标题\n" +
        "CTEMPLATE 0 root horizontal gap=8\n" +
        "CTEMPLATE 1 head element element=heading presentation=text\n" +
        "CTEMPLATE 1 card:1 composition compose=card\n" +
        "CTEMPLATE 1 card:2 composition compose=card\n" +
        "COMPOSITION_END panel\n"
    return "GENERATED_UI_STRUCTURE 2\n" + fieldGroup + card + panel +
        "NODE 0 form vertical\nEND"
}

private func nestedCollectAll(root: CjguiComposableUiNode, result: ArrayList<CjguiComposableUiNode>): Unit {
    result.add(root)
    for (child in root.children()) { nestedCollectAll(child, result) }
}

@Test
func testNestedRepeatedReferenceMountsDistinctIdentitiesThroughHolder(): Unit {
    // Paths are length-prefixed, so reference keys containing the separator
    // cannot make two different nesting paths share one element slot.
    let pathA = cjguiCompositionScopePath("a:", "b")
    let pathB = cjguiCompositionScopePath("a", ":b")
    @Assert(pathA != pathB, true)
    @Assert(cjguiCompositionElementSlotKey(pathA, "c:d") !=
        cjguiCompositionElementSlotKey(pathB, "c:d"), true)
    let catalog = nestedRepeatedCatalog()
    let decoded = CjguiGeneratedUiEncoding.decode(nestedRepeatedPayload())
    @Assert(decoded.ok, true)
    @Assert(decoded.definitions.size, 3)
    let stageIssue = cjguiStageRuntimeCompositions(catalog, decoded.definitions)
    @Assert(stageIssue, "")
    catalog.commitStagedComposites()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = NestedRepeatedOwnerProvider()
    let left = CjguiGeneratedUiNodeSpec("left", "panel")
    let right = CjguiGeneratedUiNodeSpec("right", "panel")
    let root = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([left, right]))
    let result = holder.submit(root, provider)
    @Assert(result.candidateAccepted, true)
    @Assert(result.sceneAccepted, false)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    let built = holder.buildRefreshNode(provider)
    let all = ArrayList<CjguiComposableUiNode>()
    nestedCollectAll(built, all)
    let fields = ArrayList<CjguiComposableUiNode>()
    let actions = ArrayList<CjguiComposableUiNode>()
    for (node in all) {
        if (node.fieldId == "title") { fields.add(node) }
        // Runtime compositions mount actions as generated actions: the writer
        // arrives through the binding resource, not through operationActionName.
        if (node.actionName == "GENERATED_ACTION") { actions.add(node) }
    }
    // Two references in EACH of the two panel instances.
    @Assert(fields.size, 4)
    @Assert(actions.size, 4)
    let ids = HashSet<Int64>()
    var leftFields = 0
    var rightFields = 0
    for (node in fields) {
        @Assert(ids.add(node.nodeId), true)
        if (node.operationResourceId == 6301) {
            leftFields += 1
            @Assert(node.value, "甲的草稿")
        } else if (node.operationResourceId == 6302) {
            rightFields += 1
            @Assert(node.value, "乙的草稿")
        }
    }
    @Assert(leftFields, 2)
    @Assert(rightFields, 2)
    let actionIds = HashSet<Int64>()
    var leftActions = 0
    var rightActions = 0
    for (node in actions) {
        @Assert(actionIds.add(node.nodeId), true)
        if (node.operationResourceId == 6301) { leftActions += 1 }
        if (node.operationResourceId == 6302) { rightActions += 1 }
    }
    @Assert(leftActions, 2)
    @Assert(rightActions, 2)
}

@Test
func testNestedRepeatedReferenceWideFanOutRejectedBeforeAllocation(): Unit {
    let catalog = nestedRepeatedCatalog()
    let base = CjguiGeneratedUiEncoding.decode(nestedRepeatedPayload())
    @Assert(base.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, base.definitions), "")
    catalog.commitStagedComposites()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = NestedRepeatedOwnerProvider()
    let acceptedRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("left", "panel")]))
    let accepted = holder.submit(acceptedRoot, provider)
    @Assert(accepted.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    let acceptedNode = holder.nodeIdForKey("left")
    // A legal acyclic fan-out: one panel references the card 33 times. The
    // declaration is small, but the expanded tree (and the element identity
    // demand) exceeds the instance budget. The plan must refuse it BEFORE the
    // 66 element identities are allocated; the accepted scene and its draft
    // stay operable.
    var wide = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION panelWide 64 8\n" +
        "CELEMENT badge projection source=owner_status label=宽度\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n"
    var index = 0
    while (index < 33) {
        wide += "CTEMPLATE 1 card${index} composition compose=card\n"
        index += 1
    }
    wide += "COMPOSITION_END panelWide\nNODE 0 form vertical\nEND"
    let wideDecoded = CjguiGeneratedUiEncoding.decode(wide)
    @Assert(wideDecoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, wideDecoded.definitions), "")
    catalog.commitStagedComposites()
    let wideRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("wide", "panelWide")]))
    let rejected = holder.submit(wideRoot, provider)
    @Assert(rejected.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.lastSceneOutcome().startsWith("scene_rejected:composite_expansion_node_limit"), true)
    @Assert(holder.prepareCandidateRefresh(), false)
    holder.rollbackCandidateRefresh()
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.nodeIdForKey("left"), acceptedNode)
    let stillBuilt = holder.buildRefreshNode(provider)
    let all = ArrayList<CjguiComposableUiNode>()
    nestedCollectAll(stillBuilt, all)
    var draftSeen = false
    for (node in all) {
        if (node.fieldId == "title" && node.operationResourceId == 6301 && node.value == "甲的草稿") {
            draftSeen = true
        }
    }
    @Assert(draftSeen, true)
}

@Test
func testNestedExpansionByteBudgetRejectedBeforeAllocation(): Unit {
    let catalog = nestedRepeatedCatalog()
    let big = StringBuilder()
    var index = 0
    while (index < 90000) {
        big.append("x")
        index += 1
    }
    let payload = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION textCard 24 4\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 heading label text=" + big.toString() + "\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "COMPOSITION_END textCard\n" +
        "COMPOSITION panelText 40 6\n" +
        "CELEMENT badge projection source=owner_status label=字节\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n" +
        "CTEMPLATE 1 a composition compose=textCard\n" +
        "CTEMPLATE 1 b composition compose=textCard\n" +
        "CTEMPLATE 1 c composition compose=textCard\n" +
        "COMPOSITION_END panelText\n" +
        "NODE 0 form vertical\nEND"
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    if (!decoded.ok) { println("BYTE_PAYLOAD_REJECT=${decoded.reason}") }
    @Assert(decoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, decoded.definitions), "")
    catalog.commitStagedComposites()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = NestedRepeatedOwnerProvider()
    let safeRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("safe", "textCard")]))
    let safe = holder.submit(safeRoot, provider)
    @Assert(safe.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let byteRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("textPanel", "panelText")]))
    let rejected = holder.submit(byteRoot, provider)
    @Assert(rejected.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.lastSceneOutcome().startsWith("scene_rejected:composite_expansion_byte_limit"), true)
    @Assert(holder.prepareCandidateRefresh(), false)
    holder.rollbackCandidateRefresh()
    @Assert(holder.structureVersion(), 1)
}

@Test
func testNestedExpansionDepthBudgetRejectedBeforeAllocation(): Unit {
    let catalog = nestedRepeatedCatalog()
    let payload = "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION depthA 64 4\n" +
        "CELEMENT badge projection source=owner_status label=深度\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n" +
        "COMPOSITION_END depthA\n" +
        "COMPOSITION depthB 64 4\n" +
        "CELEMENT badge projection source=owner_status label=深度\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n" +
        "CTEMPLATE 1 down composition compose=depthA\n" +
        "COMPOSITION_END depthB\n" +
        "COMPOSITION depthC 64 4\n" +
        "CELEMENT badge projection source=owner_status label=深度\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n" +
        "CTEMPLATE 1 down composition compose=depthB\n" +
        "COMPOSITION_END depthC\n" +
        "COMPOSITION depthD 64 4\n" +
        "CELEMENT badge projection source=owner_status label=深度\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 badge element element=badge presentation=text\n" +
        "CTEMPLATE 1 down composition compose=depthC\n" +
        "COMPOSITION_END depthD\n" +
        "NODE 0 form vertical\nEND"
    let decoded = CjguiGeneratedUiEncoding.decode(payload)
    if (!decoded.ok) { println("DEPTH_PAYLOAD_REJECT=${decoded.reason}") }
    @Assert(decoded.ok, true)
    @Assert(decoded.definitions.size, 4)
    @Assert(cjguiStageRuntimeCompositions(catalog, decoded.definitions), "")
    catalog.commitStagedComposites()
    // The pre-expansion plan counts the REAL nested depth: C is exactly at the
    // declared limit, D is one level past it. The plan must name the depth
    // limit before the holder allocates presentation identities.
    let safePlan = cjguiCompositionExpansionPlan(catalog, "depthC", 64, 4)
    @Assert(safePlan.issue, "")
    @Assert(safePlan.maxDepth, 4)
    let deepPlan = cjguiCompositionExpansionPlan(catalog, "depthD", 64, 4)
    @Assert(deepPlan.issue, "composite_expansion_depth_limit")
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = NestedRepeatedOwnerProvider()
    let safeRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("safe", "depthC")]))
    let safe = holder.submit(safeRoot, provider)
    @Assert(safe.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.lastSceneOutcome(), "scene_pending")
    let prepared = holder.prepareCandidateRefresh()
    @Assert(holder.lastSceneOutcome(), "scene_pending")
    @Assert(prepared, true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(holder.structureVersion(), 1)
    let acceptedNode = holder.nodeIdForKey("safe")
    @Assert(acceptedNode > 0, true)
    let acceptedBuild = holder.buildRefreshNode(provider)
    let acceptedAll = ArrayList<CjguiComposableUiNode>()
    nestedCollectAll(acceptedBuild, acceptedAll)
    let acceptedCount = acceptedAll.size
    let deepRoot = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("deep", "depthD")]))
    let rejected = holder.submit(deepRoot, provider)
    @Assert(rejected.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.lastSceneOutcome().startsWith("scene_rejected:composite_expansion_depth_limit"), true)
    @Assert(holder.prepareCandidateRefresh(), false)
    holder.rollbackCandidateRefresh()
    @Assert(holder.structureVersion(), 1)
    let stillBuilt = holder.buildRefreshNode(provider)
    let all = ArrayList<CjguiComposableUiNode>()
    nestedCollectAll(stillBuilt, all)
    // The rejected deeper candidate neither replaced the accepted nested scene
    // nor left a partial expansion behind: same instance identity, same nodes.
    @Assert(holder.nodeIdForKey("safe"), acceptedNode)
    @Assert(all.size, acceptedCount)
}

/// §16.6: a scene carrier cancelled for `native_source_superseded` is a
/// transport supersession, not a content refusal. The pending candidate must
/// SURVIVE the rollback (same token, still pending) so the next scene
/// transaction re-carries it — the first-frame pipeline racing the startup
/// document carrier used to terminally reject the document and permanently
/// fail the first load. A content refusal keeps terminating.
@Test
func testTransportSupersededCarrierKeepsCandidatePending(): Unit {
    let catalog = nestedRepeatedCatalog()
    let panel = "COMPOSITION panel 24 4\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "COMPOSITION_END panel\n"
    let decoded = CjguiGeneratedUiEncoding.decode("GENERATED_UI_STRUCTURE 2\n" + panel +
        "NODE 0 form vertical\nEND")
    @Assert(decoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, decoded.definitions), "")
    catalog.commitStagedComposites()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = NestedRepeatedOwnerProvider()
    let root = CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("solo", "panel")]))
    let submitted = holder.submit(root, provider)
    if (!submitted.candidateAccepted) { println("SUP_TEST submit reason=${submitted.reason}") }
    @Assert(submitted.candidateAccepted, true)
    let token = holder.pendingCandidateToken()
    @Assert(token > 0, true)
    // The carrier is cancelled at native promote time: the scene transaction
    // is open with THIS token and the cancellation reason is the transport
    // supersession. (The window requests a new refresh right after, exactly
    // as cancelSubmittedPreparedCandidate does in production.)
    holder.beginCandidateRefresh()
    holder.buildRefreshNode(provider)
    holder.rollbackCandidateRefresh("native_source_superseded")
    // The candidate survived: same token, still pending, not terminally
    // rejected, so the next scene transaction re-carries it without any
    // resubmission from the application.
    @Assert(holder.hasPendingCandidate(), true)
    @Assert(holder.pendingCandidateToken(), token)
    @Assert(holder.structureVersion(), 0)
    // The next scene transaction re-carries and commits it.
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.hasPendingCandidate(), false)
}

/// A genuine refusal must stay terminal: a carrier cancelled for any reason
/// other than the transport supersession is a judgement of this candidate's
/// content or basis and does not resurrect it. (An unknown component is refused
/// even earlier, at submit, and never becomes a pending candidate at all.)
@Test
func testContentRefusalStillTerminatesPendingCandidate(): Unit {
    let bare = CjguiGeneratedUiStructureHolder(compositionTestCatalog())
    let provider = NestedRepeatedOwnerProvider()
    let unknown = bare.submit(CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("solo", "panel")])), provider)
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "unknown_component")
    @Assert(bare.hasPendingCandidate(), false)

    let catalog = nestedRepeatedCatalog()
    let panel = "COMPOSITION panel 24 4\n" +
        "CELEMENT title field field=title argument=text label=标题\n" +
        "CTEMPLATE 0 root vertical\n" +
        "CTEMPLATE 1 title element element=title presentation=text\n" +
        "COMPOSITION_END panel\n"
    let decoded = CjguiGeneratedUiEncoding.decode("GENERATED_UI_STRUCTURE 2\n" + panel +
        "NODE 0 form vertical\nEND")
    @Assert(decoded.ok, true)
    @Assert(cjguiStageRuntimeCompositions(catalog, decoded.definitions), "")
    catalog.commitStagedComposites()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let submitted = holder.submit(CjguiGeneratedUiNodeSpec("root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("solo", "panel")])), provider)
    @Assert(submitted.candidateAccepted, true)
    let token = holder.pendingCandidateToken()
    holder.beginCandidateRefresh()
    holder.buildRefreshNode(provider)
    holder.rollbackCandidateRefresh("owner_or_view_changed")
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(holder.structureVersion(), 0)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:owner_or_view_changed")
    let ticket = holder.candidateTicketPayload(token)
    @Assert(ticket.contains("TERMINAL_STATE REJECTED"), true)
    @Assert(ticket.contains("REASON owner_or_view_changed"), true)
}
