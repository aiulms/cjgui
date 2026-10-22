// Tests for the public application-composite seam (composable_ui_composite_component.cj
// plus the composite branch of composable_ui_generated.cj).
//
// What is pinned here:
//   * registration is as strict as a built-in kind (no built-in override, no
//     duplicate, real field/action references, budgets inside the catalog's) and
//     unknown kind/property rejection is unchanged;
//   * the factory's REAL expanded subtree is validated: node/depth budget,
//     framework-allocated identities only, no duplicate and no dropped element;
//     a failing expansion keeps the previously accepted structure and routes;
//   * the public intent adapter turns a control event into a field edit (from a
//     real field control or from a preset button carrying a declared constant)
//     or an action, so a preset on an INTEGER field is never swallowed;
//   * the same kind used twice gets independent scoped identities, and a
//     same-key reorder keeps the element identity.
//
// Pure host tests: no window and no native module.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

/// A composite whose declared shape is the integer-edit pattern: a container, an
/// editable field element and a preset button element, plus one action element.
class CompositeTestFactory <: CjguiCompositeComponentFactory {
    var buildCount: Int64 = 0
    // Knobs for the negative cases.
    var extraNodes: Int64 = 0
    // Fail exactly ONE build. A rejected candidate must then still be able to
    // rebuild the accepted scene, which is what proves the fallback carries the
    // accepted binding instead of re-resolving the live provider.
    var extraNodesOnce: Int64 = 0
    var dropElement: Bool = false
    var foreignId: Int64 = -1
    /// Negative knob: mount the field element with a DIFFERENT field binding than
    /// the framework resolved, which the binding audit must refuse.
    var breakBinding: Bool = false
    /// Negative knob: mount the field editor with a different binding RESOURCE
    /// than the resolved binding, which the audit must refuse (the declaration
    /// would route the owner write for a control bound elsewhere).
    var breakEditorResource: Bool = false
    /// Negative knob: mount the preset button with a different resource.
    var breakPresetResource: Bool = false
    /// Negative knob: mount the preset button with a different owner target than
    /// the framework resolved (the exact same-key rebind the field check covers).
    var breakPresetTarget: Bool = false
    /// Negative knob: mount the action element as a raw business-action button
    /// instead of the framework's generic action token.
    var breakActionToken: Bool = false
    /// Negative knob: mount the action control with the opposite enabled state.
    var breakActionEnabled: Bool = false

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        buildCount += 1
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        // The declared layout property is applied: a registered property must
        // reach the built subtree, not be dropped by the builder.
        let container = cjguiComposableVertical(root.nodeId, root.semanticId,
            CjguiComposableUiStyle(gap: context.propertyInteger("gap", fallback: 4)))
        if (!dropElement) {
            if (let Some(field) <- context.element("edit")) {
                let boundFieldId = if (breakBinding) { "notTheDeclaredField" } else { field.fieldId }
                let editorResource = if (breakEditorResource) { 999999 } else { field.bindingResourceId }
                container.add(cjguiComposableIntegerInput(field.nodeId, field.semanticId, field.label,
                    field.draftText, editorResource, CjguiComposableUiStyle(fixedHeight: 26),
                    // The owner's answer must reach the real control: an editor the
                    // owner has blocked may not stay enabled (the audit refuses it).
                    enabled: field.ownerAvailable,
                    fieldId: boundFieldId, operationActionName: field.writerOperation,
                    operationResourceId: field.ownerTargetResourceId, displayValueRole: "draft"))
            }
            if (let Some(preset) <- context.element("preset")) {
                let presetResource = if (breakPresetResource) { 999999 } else { preset.bindingResourceId }
                let presetTarget = if (breakPresetTarget) { 12345 } else { preset.ownerTargetResourceId }
                container.add(cjguiComposableButton(preset.nodeId, preset.semanticId, preset.label,
                    "GENERATED_ACTION", presetResource, CjguiComposableUiStyle(fixedHeight: 26),
                    operationActionName: preset.writerOperation, operationResourceId: presetTarget))
            }
            if (let Some(action) <- context.element("apply")) {
                let actionToken = if (breakActionToken) { "APPLY_DRAFT" } else { "GENERATED_ACTION" }
                let actionEnabled = if (breakActionEnabled) { !action.actionEnabled } else { action.actionEnabled }
                container.add(cjguiComposableButton(action.nodeId, action.semanticId, action.label,
                    actionToken, action.ownerTargetResourceId, CjguiComposableUiStyle(fixedHeight: 26),
                    enabled: actionEnabled, operationResourceId: action.ownerTargetResourceId))
            }
        }
        var extra = extraNodes
        if (extraNodesOnce > 0) {
            extraNodesOnce -= 1
            extra += 1
        }
        var index: Int64 = 0
        while (index < extra) {
            // Deliberately reuses an allocated id: the audit must catch the
            // duplicate rather than letting an unbounded expansion through.
            container.add(cjguiComposableText(root.nodeId, "extra-${index}", "x", CjguiComposableUiStyle()))
            index += 1
        }
        if (foreignId > 0) {
            container.add(cjguiComposableText(foreignId, "foreign", "x", CjguiComposableUiStyle()))
        }
        return container
    }
}

func compositeCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = generatedTextCatalog()
    // The shared test catalog registers the container/field/action kinds but not
    // a plain label; the child-host case needs one real leaf kind.
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 64)
        ]), false))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("retentionCount", "保留天数", "INTEGER", 81003))
    return catalog
}

func compositeSpec(kind: String, expandedNodeLimit!: Int64 = 8): CjguiCompositeComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER"))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "retentionCount", argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
        fieldId: "retentionCount", argumentName: "text", presetValue: "90", label: "设为 90",
        parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "APPLY_DRAFT", label: "应用", parentKey: "root"))
    return CjguiCompositeComponentSpec(kind, properties, elements, expandedNodeLimit: expandedNodeLimit)
}

@Test
func compositeElementArgumentMustMatchTheFieldWriterArgument(): Unit {
    let catalog = compositeCatalog()
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("boundedDays", "上限天数", "INTEGER", 81005,
        argumentName: "text"))
    let factory = CompositeTestFactory()
    // The field declares that its writer takes `text`; an element that declares a
    // different argument would hand the consumer an argument the owner operation
    // does not accept, so registration refuses it instead of publishing drift.
    let mismatched = ArrayList<CjguiCompositeElementSpec>()
    mismatched.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "boundedDays", argumentName: "message"))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("boundedEdit",
        ArrayList<CjguiGeneratedUiPropertySpec>(), mismatched), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_element_argument_mismatch"), true)
    // The field's OWN declared argument is accepted, and the published element
    // carries it.
    let matched = ArrayList<CjguiCompositeElementSpec>()
    matched.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "boundedDays", argumentName: "text"))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("boundedEditOk",
        ArrayList<CjguiGeneratedUiPropertySpec>(), matched), factory), true)
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(described.contains(
        "ELEMENT boundedEditOk edit field parent=root field=boundedDays argument=text preset=none action=none label=\n"),
        true)
    @Assert(described.contains(
        "FIELD boundedDays INTEGER resource=81005 writer=EDIT_DRAFT_TEXT required=0 min=0 max=0 maxlen=0 " +
        "callable=1 argument=text input=integerInput label=上限天数\n"), true)
}

@Test
func compositeRegistrationIsAsStrictAsBuiltIns(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    // A built-in kind cannot be overridden by a composite.
    @Assert(catalog.registerComposite(compositeSpec("label"), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("built_in_kind_not_overridable"), true)
    // Unknown field reference.
    let unknownFieldElements = ArrayList<CjguiCompositeElementSpec>()
    unknownFieldElements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "missingField"))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("cardA", ArrayList<CjguiGeneratedUiPropertySpec>(),
        unknownFieldElements), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("unknown_field"), true)
    // Unknown action reference.
    let unknownActionElements = ArrayList<CjguiCompositeElementSpec>()
    unknownActionElements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "NO_SUCH_ACTION"))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("cardB", ArrayList<CjguiGeneratedUiPropertySpec>(),
        unknownActionElements), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("unknown_action"), true)
    // A preset without a value cannot be registered (the constant is the contract).
    let presetElements = ArrayList<CjguiCompositeElementSpec>()
    presetElements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
        fieldId: "retentionCount"))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("cardC", ArrayList<CjguiGeneratedUiPropertySpec>(),
        presetElements), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_preset_value_required"), true)
    // A budget larger than the catalog's real capacity is refused.
    @Assert(catalog.registerComposite(compositeSpec("cardD",
        expandedNodeLimit: catalog.maxNodes + 1), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_expanded_node_limit"), true)
    // Duplicate element keys are refused.
    let duplicateElements = ArrayList<CjguiCompositeElementSpec>()
    duplicateElements.add(CjguiCompositeElementSpec("same", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    duplicateElements.add(CjguiCompositeElementSpec("same", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("cardE", ArrayList<CjguiGeneratedUiPropertySpec>(),
        duplicateElements), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_duplicate_element_key"), true)

    // The valid registration succeeds and is discoverable beside built-ins.
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    @Assert(catalog.compositeFor("integerEdit").isSome(), true)
    @Assert(catalog.compositeFactoryFor("integerEdit").isSome(), true)
    @Assert(catalog.componentFor("integerEdit").isSome(), true)
    let kinds = catalog.compositeKinds()
    @Assert(kinds.size, 1)
    @Assert(kinds[0], "integerEdit")
    // Registering the same kind twice is a duplicate, exactly like a built-in.
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("duplicate_component_kind"), true)

    // Unknown kind/property rejection is UNCHANGED: the extension did not loosen it.
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("x", "notRegistered"), provider).candidateAccepted, false)
    @Assert(holder.rejectedReason(), "unknown_component")
    let badProperty = HashMap<String, String>()
    badProperty.add("gapp", "4")
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("y", "integerEdit", properties: badProperty),
        provider).candidateAccepted, false)
    @Assert(holder.rejectedReason(), "unknown_property")
}

@Test
func compositeExpansionIsValidatedAgainstRealSubtree(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()

    let root = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    // The real expansion was 4 nodes (container + field + preset + action).
    @Assert(holder.lastCompositeExpansionNodes() >= 4, true)
    @Assert(holder.lastCompositeExpansionDepth() >= 2, true)
    let editorId = holder.nodeIdForKey("editor")
    @Assert(editorId > 0, true)
    // Every composite element maps to the same stable key.
    @Assert(holder.keyForNodeId(editorId), "editor")

    let second = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    // A duplicate identity inside the expansion is refused, and the accepted
    // structure/identity survives.
    factory.extraNodes = 1
    @Assert(holder.submit(second, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_duplicate_node_id")
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.nodeIdForKey("editor") > 0, true)

    // A foreign (not framework-allocated) identity is refused too.
    factory.extraNodes = 0
    factory.foreignId = 4242
    @Assert(holder.submit(second, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_foreign_node_id")
    @Assert(holder.structureVersion(), 1)

    // Dropping a declared element is refused as well: the factory cannot silently
    // omit a binding it registered.
    factory.foreignId = -1
    factory.dropElement = true
    @Assert(holder.submit(second, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_element_missing")
    factory.dropElement = false
    @Assert(holder.structureVersion(), 1)
    // The accepted editor still resolves for a live key after those rejections.
    @Assert(holder.acceptedNodeForKey("editor").isSome(), true)
}

@Test
func compositeIntentAdapterResolvesFieldPresetAndAction(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let root = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)

    // Find the accepted element bindings through the published identity table.
    var fieldNodeId: Int64 = -1
    var presetNodeId: Int64 = -1
    var actionNodeId: Int64 = -1
    let editorIds = holder.compositeElementNodeIdsForKey("editor")
    for (info in editorIds) {
        if (info.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
            fieldNodeId = info.nodeId
        }
        if (info.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            presetNodeId = info.nodeId
        }
        if (info.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
            actionNodeId = info.nodeId
        }
    }
    @Assert(fieldNodeId > 0, true)
    @Assert(presetNodeId > 0, true)
    @Assert(actionNodeId > 0, true)

    // The field element: a text change is a field edit through the owner writer.
    let fieldNode = cjguiComposableIntegerInput(fieldNodeId, "s", "保留天数", "draft", 81003,
        CjguiComposableUiStyle(), fieldId: "retentionCount", operationActionName: "EDIT_DRAFT_TEXT",
        operationResourceId: 42, displayValueRole: "draft")
    let fieldLayout = CjguiComposableUiLayoutNode(fieldNode, CjguiComposableUiRect(0, 0, 100, 26),
        CjguiComposableUiRect(0, 0, 100, 26))
    let edit = holder.resolveIntent(fieldLayout, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(edit.isFieldEdit(), true)
    @Assert(edit.fieldId, "retentionCount")
    @Assert(edit.writerOperation, "EDIT_DRAFT_TEXT")
    @Assert(edit.ownerTargetResourceId, 42)

    // The PRESET element on the SAME INTEGER field: an activation must become a
    // field edit with the declared constant, not be swallowed by the
    // change-kind gate.
    // The preset control carries the resolved writer/target, exactly like the
    // shared builder does; the audit requires it.
    let presetNode = cjguiComposableButton(presetNodeId, "s", "设为 90", "GENERATED_ACTION", 81003,
        CjguiComposableUiStyle(), operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 42)
    let presetLayout = CjguiComposableUiLayoutNode(presetNode, CjguiComposableUiRect(0, 0, 100, 26),
        CjguiComposableUiRect(0, 0, 100, 26))
    let presetEdit = holder.resolveIntent(presetLayout, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(presetEdit.isFieldEdit(), true)
    @Assert(presetEdit.fieldId, "retentionCount")
    @Assert(presetEdit.value.displayText(), "90")

    // The ACTION element: an activation resolves to the declared action.
    let actionNode = cjguiComposableButton(actionNodeId, "s", "应用", "GENERATED_ACTION", actionNodeId,
        CjguiComposableUiStyle())
    let actionLayout = CjguiComposableUiLayoutNode(actionNode, CjguiComposableUiRect(0, 0, 100, 26),
        CjguiComposableUiRect(0, 0, 100, 26))
    let actionIntent = holder.resolveIntent(actionLayout, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(actionIntent.isAction(), true)
    @Assert(actionIntent.actionName, "APPLY_DRAFT")

    // A forged/unknown node id resolves to nothing.
    let forged = cjguiComposableButton(777777, "s", "x", "GENERATED_ACTION", 1, CjguiComposableUiStyle())
    let forgedLayout = CjguiComposableUiLayoutNode(forged, CjguiComposableUiRect(0, 0, 10, 10),
        CjguiComposableUiRect(0, 0, 10, 10))
    @Assert(holder.resolveIntent(forgedLayout, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "").kind,
        CJGUI_GENERATED_INTENT_NONE)
}

@Test
func compositeInstancesUseIndependentScopesAndKeepIdentityAcrossReorder(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("editorA", "integerEdit"))
    children.add(CjguiGeneratedUiNodeSpec("editorB", "integerEdit"))
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical", children: children),
        provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let idsA = holder.compositeElementNodeIdsForKey("editorA")
    let idsB = holder.compositeElementNodeIdsForKey("editorB")
    @Assert(idsA.size >= 4, true)
    @Assert(idsB.size >= 4, true)
    // Same kind, independent scopes: no element identity is shared.
    let seen = HashSet<Int64>()
    for (info in idsA) {
        seen.add(info.nodeId)
    }
    for (info in idsB) {
        @Assert(seen.contains(info.nodeId), false)
    }
    let fieldA = holder.nodeIdForKey("editorA")

    // Same keys, different order: each element keeps its identity.
    let reordered = ArrayList<CjguiGeneratedUiNodeSpec>()
    reordered.add(CjguiGeneratedUiNodeSpec("editorB", "integerEdit"))
    reordered.add(CjguiGeneratedUiNodeSpec("editorA", "integerEdit"))
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical", children: reordered),
        provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 2)
    @Assert(holder.nodeIdForKey("editorA"), fieldA)
    @Assert(holder.nodeIdForKey("editorA") > 0, true)
    // The old identity routes to the same accepted key, so a queued event from
    // the previous scene still resolves to the right object.
    @Assert(holder.keyForNodeId(fieldA), "editorA")
}

/// A composite that accepts generated children: its own elements and the
/// caller-provided children carry identities from different instances.
class CompositeChildHostFactory <: CjguiCompositeComponentFactory {
    var dropChildren: Bool = false

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let host = cjguiComposableVertical(root.nodeId, root.semanticId,
            CjguiComposableUiStyle(gap: context.propertyInteger("gap", fallback: 2)))
        if (!dropChildren) {
            for (child in context.children) {
                host.add(child)
            }
        }
        return host
    }
}

private func childHostSpec(): CjguiCompositeComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 16))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    return CjguiCompositeComponentSpec("childHost", properties, elements,
        allowsChildren: true, childLimit: 1, expandedNodeLimit: 4, expandedDepthLimit: 3)
}

/// A declared layout property really reaches the built subtree, through the SAME
/// builder: the registered `gap` is applied, and an omitted property uses the
/// application's fallback.
@Test
func compositeDeclaredPropertiesReachTheBuilder(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()

    // Declared gap 10 must appear in the built subtree.
    let declared = HashMap<String, String>()
    declared.add("gap", "10")
    let withGap = CjguiGeneratedUiNodeSpec("editor", "integerEdit", properties: declared)
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([withGap])), provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let builtWithGap = holder.buildAccepted(provider)
    let gaps = compositeGaps(builtWithGap)
    @Assert(gaps.contains(10), true)

    // No declared gap: the builder's own fallback is used, not a stale value.
    let bare = CjguiGeneratedUiNodeSpec("editor2", "integerEdit")
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([bare])), provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let builtBare = holder.buildAccepted(provider)
    let bareGaps = compositeGaps(builtBare)
    @Assert(bareGaps.contains(4), true)
    @Assert(bareGaps.contains(10), false)
}

/// The writer's ARGUMENT declared by the application travels with the framework's
/// resolved binding and with every intent it resolves, so a consumer never has to
/// guess which argument the owner operation takes.
@Test
func compositeElementArgumentTravelsToBindingAndIntent(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let root = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)

    var fieldElement: ?CjguiCompositeElementBinding = None
    var presetElement: ?CjguiCompositeElementBinding = None
    for (element in holder.compositeElementNodeIdsForKey("editor")) {
        if (element.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
            fieldElement = Some(element)
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            presetElement = Some(element)
        }
    }
    let boundField = match (fieldElement) {
        case Some(value) => value
        case None => CjguiCompositeElementBinding("", "", -1, "", "")
    }
    let boundPreset = match (presetElement) {
        case Some(value) => value
        case None => CjguiCompositeElementBinding("", "", -1, "", "")
    }
    @Assert(boundField.argumentName, "text")
    @Assert(boundField.instanceKey, "editor")
    @Assert(boundPreset.argumentName, "text")
    @Assert(boundPreset.instanceKey, "editor")

    // The same argument reaches the intent for both a real change and a preset
    // press, so the consumer hands the owner the declared argument.
    let fieldNode = CjguiComposableUiLayoutNode(
        cjguiComposableIntegerInput(boundField.nodeId, "s", "保留天数", "1", boundField.bindingResourceId,
            CjguiComposableUiStyle(), fieldId: boundField.fieldId,
            operationActionName: boundField.writerOperation,
            operationResourceId: boundField.ownerTargetResourceId, displayValueRole: "draft"),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
    let editIntent = holder.resolveIntent(fieldNode, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(editIntent.isFieldEdit(), true)
    @Assert(editIntent.argumentName, "text")

    let presetNode = CjguiComposableUiLayoutNode(
        cjguiComposableButton(boundPreset.nodeId, "s", "设为 90", "GENERATED_ACTION",
            boundPreset.bindingResourceId, CjguiComposableUiStyle(),
            operationActionName: boundPreset.writerOperation,
            operationResourceId: boundPreset.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
    let presetIntent = holder.resolveIntent(presetNode, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(presetIntent.isFieldEdit(), true)
    @Assert(presetIntent.argumentName, "text")
    @Assert(presetIntent.value.displayText(), "90")
}

/// Identity/count/depth alone cannot prove a composite mounted the elements it
/// registered: a factory that binds an element to ANOTHER field is refused.
@Test
func compositeElementBindingMismatchIsRefused(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let root = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)

    // A SECOND kind whose factory mounts the field element with a different field
    // binding. Using its own kind keeps the accepted structure renderable, so the
    // "kept old interface" claim is really tested instead of a broken factory
    // being asked to re-render the accepted panel.
    let brokenFactory = CompositeTestFactory()
    brokenFactory.breakBinding = true
    @Assert(catalog.registerComposite(compositeSpec("integerEditBroken"), brokenFactory), true)
    let broken = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editorB", "integerEditBroken")]))
    @Assert(holder.submit(broken, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_element_binding_mismatch")
    @Assert(holder.structureVersion(), 1)
    // The accepted composite still resolves and writes after the rejection.
    @Assert(holder.compositeElementNodeIdsForKey("editor").size >= 4, true)
}

/// Children declared under a composite are allocated by ANOTHER instance: they
/// must be accepted (not mistaken for foreign identities), counted against the
/// budget, and really mounted - a factory that silently drops them is refused.
@Test
func compositePlacedChildrenAreAllowedBudgetedAndRequired(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeChildHostFactory()
    @Assert(catalog.registerComposite(childHostSpec(), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let child = CjguiGeneratedUiNodeSpec("inner", "label")
    let properties = HashMap<String, String>()
    properties.add("text", "子节点")
    let childWithText = CjguiGeneratedUiNodeSpec("inner", "label", properties: properties)
    let _ = child
    let host = CjguiGeneratedUiNodeSpec("host", "childHost",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([childWithText]))
    let acceptedHost = holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([host])), provider)
    @Assert(acceptedHost.reason, "")
    @Assert(acceptedHost.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    // The caller's child keeps its own stable identity inside the accepted scene.
    @Assert(holder.keyForNodeId(holder.nodeIdForKey("inner")), "inner")

    // Dropping the declared child is refused instead of silently ignored.
    factory.dropChildren = true
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([host])), provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_children_missing")
    @Assert(holder.structureVersion(), 1)
}

/// A late event from an object that was rebound/removed must be refused: the
/// adapter only resolves identities of the CURRENT accepted structure.
@Test
func compositeRebindRefusesLateEventsFromTheOldInstance(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let first = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(first, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let oldElement = holder.compositeElementNodeIdsForKey("cardA")[0]
    @Assert(oldElement.nodeId > 0, true)

    // The composite instance is now keyed differently: the old binding is gone.
    let second = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardB", "integerEdit")]))
    @Assert(holder.submit(second, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 2)
    @Assert(holder.compositeElementNodeIdsForKey("cardA").size, 0)

    let lateNode = CjguiComposableUiLayoutNode(
        cjguiComposableIntegerInput(oldElement.nodeId, "old", "保留天数", "1", 81003,
            CjguiComposableUiStyle(), fieldId: "retentionCount",
            operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 1),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
    let late = holder.resolveIntent(lateNode, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(late.kind, CJGUI_GENERATED_INTENT_NONE)
}

/// A provider whose owner target and binding resource can differ between two
/// generations of the SAME stable key: that is what makes a same-key rebind
/// observable instead of an identical replacement.
/// Resolves owner target and draft per composite INSTANCE, not only per field.
/// This is the seam that lets two instances of one kind write different owners.
private class CompositePerInstanceProvider <: CjguiGeneratedUiBindingProvider {
    private let targets: HashMap<String, Int64>
    private let drafts: HashMap<String, String>

    init(targets: HashMap<String, Int64>, drafts: HashMap<String, String>) {
        this.targets = targets
        this.drafts = drafts
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }
    public func draftText(fieldId: String): String { return "" }
    public func draftText(fieldId: String, instanceKey: String): String {
        return drafts.get(instanceKey) ?? ""
    }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

private class CompositeTargetProvider <: CjguiGeneratedUiBindingProvider {
    private let target: Int64
    private let resource: Int64

    init(target: Int64, resource!: Int64 = 81003) {
        this.target = target
        this.resource = resource
    }

    public func fieldResourceId(fieldId: String): Int64 { return resource }
    public func fieldOperationResourceId(fieldId: String): Int64 { return target }
    public func draftText(fieldId: String): String { return "7" }
    public func appliedText(fieldId: String): String { return "7" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// The element binding of one accepted composite instance for a given role.
private func compositeRoleBinding(holder: CjguiGeneratedUiStructureHolder, key: String,
                                  role: String): CjguiCompositeElementBinding {
    for (binding in holder.compositeElementNodeIdsForKey(key)) {
        if (binding.role == role) {
            return binding
        }
    }
    return CjguiCompositeElementBinding("", "", -1, "", "")
}

/// The FIELD-role element binding of one accepted composite instance. The first
/// binding is the container, so tests must select by role instead of by index.
private func compositeFieldBinding(holder: CjguiGeneratedUiStructureHolder,
                                   key: String): CjguiCompositeElementBinding {
    return compositeRoleBinding(holder, key, CJGUI_COMPOSITE_ELEMENT_FIELD)
}

/// The layout node a preset button presents once its factory carries the
/// resolved writer/target (the contract the audit enforces).
private func compositePresetLayoutNode(binding: CjguiCompositeElementBinding): CjguiComposableUiLayoutNode {
    return CjguiComposableUiLayoutNode(
        cjguiComposableButton(binding.nodeId, binding.semanticId, binding.label, "GENERATED_ACTION",
            binding.bindingResourceId, CjguiComposableUiStyle(),
            operationActionName: binding.writerOperation,
            operationResourceId: binding.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
}

private func compositeLayoutNode(binding: CjguiCompositeElementBinding): CjguiComposableUiLayoutNode {
    return CjguiComposableUiLayoutNode(
        cjguiComposableIntegerInput(binding.nodeId, binding.semanticId, binding.label, "7",
            binding.bindingResourceId, CjguiComposableUiStyle(), fieldId: binding.fieldId,
            operationActionName: binding.writerOperation,
            operationResourceId: binding.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
}

/// The control an ACTION element presents once its factory carries the resolved
/// enabled state and per-instance owner target (the shape the audit enforces).
private func compositeActionLayoutNode(binding: CjguiCompositeElementBinding): CjguiComposableUiLayoutNode {
    return CjguiComposableUiLayoutNode(
        cjguiComposableButton(binding.nodeId, binding.semanticId, binding.label, "GENERATED_ACTION",
            binding.ownerTargetResourceId, CjguiComposableUiStyle(), enabled: binding.actionEnabled,
            operationResourceId: binding.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 100, 26), CjguiComposableUiRect(0, 0, 100, 26))
}

@Test
func compositeElementResourceAndActionDriftIsRefused(): Unit {
    let catalog = compositeCatalog()
    let healthy = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), healthy), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let root = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editor", "integerEdit")]))
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)

    // Each drift uses its OWN registered kind so the accepted structure stays
    // renderable and "the old interface is kept" is really tested.
    let cases = ArrayList<(String, CompositeTestFactory)>()
    let editorDrift = CompositeTestFactory()
    editorDrift.breakEditorResource = true
    cases.add(("integerEditEditorDrift", editorDrift))
    let presetDrift = CompositeTestFactory()
    presetDrift.breakPresetResource = true
    cases.add(("integerEditPresetDrift", presetDrift))
    let presetTargetDrift = CompositeTestFactory()
    presetTargetDrift.breakPresetTarget = true
    cases.add(("integerEditPresetTargetDrift", presetTargetDrift))
    let actionToken = CompositeTestFactory()
    actionToken.breakActionToken = true
    cases.add(("integerEditActionToken", actionToken))
    let actionEnabled = CompositeTestFactory()
    actionEnabled.breakActionEnabled = true
    cases.add(("integerEditActionEnabled", actionEnabled))
    for ((kind, factory) in cases) {
        @Assert(catalog.registerComposite(compositeSpec(kind), factory), true)
        let candidate = CjguiGeneratedUiNodeSpec("panel", "vertical",
            children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("editorDrift", kind)]))
        @Assert(holder.submit(candidate, provider).candidateAccepted, true)
        @Assert(generatedCommit(holder, provider), false)
        @Assert(holder.lastSceneOutcome(), "scene_rejected:composite_element_binding_mismatch")
        @Assert(holder.structureVersion(), 1)
        // The previously accepted composite still carries its own bindings.
        @Assert(holder.compositeElementNodeIdsForKey("editor").size >= 4, true)
    }
}

@Test
func compositeTwoInstancesKeepTheirOwnOwnerAcrossReorderAndReplacement(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    targets.add("cardB", 20)
    let drafts = HashMap<String, String>()
    drafts.add("cardA", "A")
    drafts.add("cardB", "B")
    let provider = CompositePerInstanceProvider(targets, drafts)
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit")
        ]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let a = compositeFieldBinding(holder, "cardA")
    let b = compositeFieldBinding(holder, "cardB")
    @Assert(a.ownerTargetResourceId, 10)
    @Assert(b.ownerTargetResourceId, 20)
    @Assert(a.draftText, "A")
    @Assert(b.draftText, "B")
    @Assert(holder.resolveIntent(compositeLayoutNode(a), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
        .ownerTargetResourceId, 10)
    @Assert(holder.resolveIntent(compositeLayoutNode(b), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "46")
        .ownerTargetResourceId, 20)

    // Physical reorder: the same two stable keys, B first. Each key keeps its
    // own owner instead of inheriting the other instance's target.
    let reordered = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit")
        ]))
    @Assert(holder.submit(reordered, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(compositeFieldBinding(holder, "cardA").ownerTargetResourceId, 10)
    @Assert(compositeFieldBinding(holder, "cardB").ownerTargetResourceId, 20)

    // Replacement: both keys now denote new owner objects. The bindings follow
    // the keys, and the old instance objects cannot write the replacement.
    let replacementTargets = HashMap<String, Int64>()
    replacementTargets.add("cardA", 30)
    replacementTargets.add("cardB", 40)
    let replacement = CompositePerInstanceProvider(replacementTargets, drafts)
    @Assert(holder.submit(reordered, replacement).candidateAccepted, true)
    @Assert(generatedCommit(holder, replacement), true)
    @Assert(compositeFieldBinding(holder, "cardA").ownerTargetResourceId, 30)
    @Assert(compositeFieldBinding(holder, "cardB").ownerTargetResourceId, 40)
    let oldLate = holder.resolveIntent(compositeLayoutNode(a), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(oldLate.kind, CJGUI_GENERATED_INTENT_NONE)
}

@Test
func compositeSameKeyRebindRefusesTheOldObjectsLateEvent(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let twoCards = ArrayList<CjguiGeneratedUiNodeSpec>([
        CjguiGeneratedUiNodeSpec("cardA", "integerEdit"),
        CjguiGeneratedUiNodeSpec("cardB", "integerEdit")
    ])
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical", children: twoCards)

    // Generation A: the stable keys are bound to owner target 1.
    let providerA = CompositeTargetProvider(1)
    @Assert(holder.submit(structure, providerA).candidateAccepted, true)
    @Assert(generatedCommit(holder, providerA), true)
    let elementA = compositeFieldBinding(holder, "cardA")
    @Assert(elementA.ownerTargetResourceId, 1)
    let lateNode = compositeLayoutNode(elementA)

    // Generation B: the SAME keys and the SAME kind, new objects bound to target
    // 2. The identity survives (same node id), so only the binding tells them
    // apart - exactly the case the delete-style test did not cover.
    let providerB = CompositeTargetProvider(2)
    @Assert(holder.submit(structure, providerB).candidateAccepted, true)
    @Assert(generatedCommit(holder, providerB), true)
    @Assert(holder.structureVersion(), 2)
    let elementB = compositeFieldBinding(holder, "cardA")
    @Assert(elementB.nodeId, elementA.nodeId)
    @Assert(elementB.ownerTargetResourceId, 2)

    // The old object's late change is REFUSED instead of writing B's owner.
    let late = holder.resolveIntent(lateNode, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(late.kind, CJGUI_GENERATED_INTENT_NONE)
    @Assert(late.reason, "element_binding_mismatch")

    // The current object still resolves, to the current target.
    let current = holder.resolveIntent(compositeLayoutNode(elementB), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(current.kind, CJGUI_GENERATED_INTENT_FIELD_EDIT)
    @Assert(current.ownerTargetResourceId, 2)
    @Assert(current.fieldId, "retentionCount")

    // A real reorder of the SAME key keeps the accepted route usable.
    let reordered = ArrayList<CjguiGeneratedUiNodeSpec>([
        CjguiGeneratedUiNodeSpec("cardB", "integerEdit"),
        CjguiGeneratedUiNodeSpec("cardA", "integerEdit")
    ])
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical", children: reordered), providerB)
        .candidateAccepted, true)
    @Assert(generatedCommit(holder, providerB), true)
    @Assert(holder.structureVersion(), 3)
    let afterReorder = compositeFieldBinding(holder, "cardA")
    let reorderedIntent = holder.resolveIntent(compositeLayoutNode(afterReorder),
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "45")
    @Assert(reorderedIntent.kind, CJGUI_GENERATED_INTENT_FIELD_EDIT)
    @Assert(reorderedIntent.ownerTargetResourceId, 2)
}

/// The accepted binding must carry a framework-owned instance generation: a
/// pure reorder keeps it, a same-key rebind keeps the key but changes the
/// target, and a remove + re-add of the same key is a NEW instance.
@Test
func compositeInstanceIncarnationSeparatesReorderRebindAndReAdd(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    targets.add("cardB", 20)
    let drafts = HashMap<String, String>()
    drafts.add("cardA", "same")
    drafts.add("cardB", "same")
    let provider = CompositePerInstanceProvider(targets, drafts)
    let two = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit")
        ]))
    @Assert(holder.submit(two, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let a1 = compositeFieldBinding(holder, "cardA")
    let b1 = compositeFieldBinding(holder, "cardB")
    @Assert(a1.instanceIncarnation > 0, true)
    @Assert(a1.instanceIncarnation != b1.instanceIncarnation, true)

    // Reorder: same keys, same owners, SAME generation.
    let reordered = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit")
        ]))
    @Assert(holder.submit(reordered, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let a2 = compositeFieldBinding(holder, "cardA")
    @Assert(a2.instanceIncarnation, a1.instanceIncarnation)
    @Assert(a2.ownerTargetResourceId, 10)

    // Same-key rebind: the key stays but the bound object changes, so this is a
    // REAL binding change. Its generation must be new; a session or intent held
    // for the old target can never be revived by comparing the key alone.
    targets.add("cardA", 30)
    @Assert(holder.submit(reordered, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let a3 = compositeFieldBinding(holder, "cardA")
    @Assert(a3.instanceIncarnation != a1.instanceIncarnation, true)
    @Assert(a3.instanceIncarnation > a1.instanceIncarnation, true)
    @Assert(a3.ownerTargetResourceId, 30)
    @Assert(a3.instanceOwnerTargetResourceId, 30)

    // Remove cardA, then re-add the SAME key and owner. The new acceptance is a
    // new instance generation, so an old held session cannot resume.
    let onlyB = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardB", "integerEdit")]))
    @Assert(holder.submit(onlyB, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.compositeElementNodeIdsForKey("cardA").size, 0)
    @Assert(holder.submit(reordered, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let a4 = compositeFieldBinding(holder, "cardA")
    @Assert(a4.ownerTargetResourceId, 30)
    @Assert(a4.instanceIncarnation > a1.instanceIncarnation, true)
    @Assert(a4.instanceIncarnation != a3.instanceIncarnation, true)
}

/// A multi-object provider with a real versioned text owner, so range sessions
/// can be exercised end to end (same text and same numeric version across
/// A→B→A is the counterexample that a version alone cannot separate).
private class CompositeRangeProvider <: CjguiGeneratedUiBindingProvider {
    private let targets: HashMap<String, Int64>
    private let drafts: HashMap<String, String>
    var writes: ArrayList<String> = ArrayList<String>()

    init(targets: HashMap<String, Int64>, drafts: HashMap<String, String>) {
        this.targets = targets
        this.drafts = drafts
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }
    public func draftText(fieldId: String): String { return "" }
    public func draftText(fieldId: String, instanceKey: String): String {
        return drafts.get(instanceKey) ?? ""
    }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "instance_required")
    }
    public func actionAvailable(actionName: String): Bool { return true }
    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        return (targets.get(instanceKey) ?? -1) >= 0
    }
    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 { return 5 }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        let target = targets.get(instanceKey) ?? -1
        if (target < 0) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, "unknown_instance")
        }
        if (expectedVersion != 5) {
            return CjguiRangeTextEditOutcome.conflict(expectedVersion, "owner_version_moved")
        }
        writes.add("${instanceKey}:${target}:${newText}")
        return CjguiRangeTextEditOutcome.accepted(expectedVersion, expectedVersion + 1)
    }
}

/// Resolution and execution are separate steps. If the provider's mapping moves
/// in between, the resolved ACTION must be bound to the exact accepted element
/// it came from - never re-resolved by key - and the owner transaction must see
/// the ORIGINAL target and refuse a key that now denotes another object.
@Test
func compositeResolvedActionCannotFollowAMappingChangeBeforeDispatch(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    let availability = HashMap<String, CjguiSharedAvailability>()
    availability.add("cardA", CjguiSharedAvailability.allowed(10, 3))
    let provider = CompositeActionProvider(targets, availability)
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let action = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION)
    let resolved = holder.resolveIntent(compositeActionLayoutNode(action),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(resolved.isAction(), true)
    @Assert(resolved.ownerTargetResourceId, 10)
    @Assert(holder.compositeActionIntentIsBound(resolved.nodeId, resolved.actionName, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation), true)

    // The mapping changes AFTER resolution, and the new scene is accepted.
    targets.add("cardA", 30)
    availability.add("cardA", CjguiSharedAvailability.allowed(30, 5))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.compositeActionIntentIsBound(resolved.nodeId, resolved.actionName, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation), false)

    // Even handed to the provider, the retired target is refused: the owner
    // transaction never silently follows the key to the new object.
    let stale = provider.executeAction(resolved.actionName, resolved.nodeKey, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation)
    @Assert(stale.applied, false)
    @Assert(stale.reason, "owner_target_retired")
    @Assert(provider.executed.size, 0)

    // The new accepted object resolves and executes immediately.
    let current = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION)
    let fresh = holder.resolveIntent(compositeActionLayoutNode(current),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(holder.compositeActionIntentIsBound(fresh.nodeId, fresh.actionName, fresh.instanceKey,
        fresh.ownerTargetResourceId, fresh.instanceIncarnation), true)
    @Assert(provider.executeAction(fresh.actionName, fresh.nodeKey, fresh.instanceKey,
        fresh.ownerTargetResourceId, fresh.instanceIncarnation).applied, true)
    @Assert(provider.executed[0], "cardA:30:APPLY_DRAFT")

    // A stale target is refused even with the CURRENT generation.
    @Assert(provider.executeAction(fresh.actionName, fresh.nodeKey, fresh.instanceKey, 10,
        fresh.instanceIncarnation).applied, false)
    @Assert(provider.executed.size, 1)
}

/// "Same text, same version, A→B→A": neither the instance key nor the owner
/// version separates the old session from the new object, so the accepted
/// generation must. A legitimate session still reads and writes at every step.
@Test
func compositeRangeSessionIsRetiredAcrossARebindAndReturningToTheOldOwner(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    let drafts = HashMap<String, String>()
    drafts.add("cardA", "same")
    let provider = CompositeRangeProvider(targets, drafts)
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)

    let elementA1 = compositeFieldBinding(holder, "cardA")
    let nodeA1 = elementA1.nodeId
    let incarnationA1 = elementA1.instanceIncarnation
    let sessionA1 = CjguiGeneratedFieldRangeSession(provider, "retentionCount", instanceKey: "cardA",
        ownerTarget: 10,
        bindingCurrent: { => holder.compositeInstanceIncarnationForNodeId(nodeA1) == incarnationA1 })
    @Assert(sessionA1.readRangeText(0, 4).pendingReason, "")
    @Assert(sessionA1.rangeTextVersion(), 5)
    @Assert(sessionA1.applyRangeTextEdit(5, 0, 0, "9").applied, true)
    @Assert(provider.writes[0], "cardA:10:9same")

    // B: the same key, the same text and the same numeric version, a new object.
    targets.add("cardA", 30)
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(sessionA1.readRangeText(0, 1).pendingReason, "binding_retired")
    let elementB = compositeFieldBinding(holder, "cardA")
    @Assert(elementB.ownerTargetResourceId, 30)
    @Assert(elementB.instanceIncarnation != incarnationA1, true)
    let sessionB = CjguiGeneratedFieldRangeSession(provider, "retentionCount", instanceKey: "cardA",
        ownerTarget: 30,
        bindingCurrent: { => holder.compositeInstanceIncarnationForNodeId(elementB.nodeId) ==
            elementB.instanceIncarnation })
    @Assert(sessionB.rangeTextVersion(), 5)
    @Assert(sessionB.applyRangeTextEdit(5, 0, 0, "8").applied, true)
    @Assert(provider.writes[1], "cardA:30:8same")

    // Back to A: same key, same text, same version - and a NEW generation. The
    // old sessions stay retired instead of becoming valid again.
    targets.add("cardA", 10)
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(sessionA1.readRangeText(0, 1).pendingReason, "binding_retired")
    @Assert(sessionB.readRangeText(0, 1).pendingReason, "binding_retired")
    let elementA2 = compositeFieldBinding(holder, "cardA")
    @Assert(elementA2.ownerTargetResourceId, 10)
    @Assert(elementA2.instanceIncarnation != incarnationA1, true)
    @Assert(elementA2.instanceIncarnation != elementB.instanceIncarnation, true)
    let sessionA2 = CjguiGeneratedFieldRangeSession(provider, "retentionCount", instanceKey: "cardA",
        ownerTarget: 10,
        bindingCurrent: { => holder.compositeInstanceIncarnationForNodeId(elementA2.nodeId) ==
            elementA2.instanceIncarnation })
    @Assert(sessionA2.readRangeText(0, 4).pendingReason, "")
    @Assert(sessionA2.applyRangeTextEdit(5, 0, 0, "7").applied, true)
    @Assert(provider.writes[2], "cardA:10:7same")
}

/// A rejected candidate must not consume or move the accepted identity: the old
/// generation stays authoritative until a scene really commits, and only then
/// does the new target become a new binding.
@Test
func compositeRejectedCandidateKeepsTheAcceptedBindingAndGeneration(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    let provider = CompositeActionProvider(targets, HashMap<String, CjguiSharedAvailability>())
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let before = compositeFieldBinding(holder, "cardA")
    let actionBefore = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION)
    let resolved = holder.resolveIntent(compositeActionLayoutNode(actionBefore),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(resolved.ownerTargetResourceId, 10)
    @Assert(holder.compositeInstanceKeyForOwnerTarget(10), "cardA")

    // The candidate maps the same key to a new owner but fails its expansion.
    // The failure is transient, so the accepted fallback really rebuilds the
    // card: that rebuild must carry the ACCEPTED binding (owner 10, generation
    // unchanged) instead of resolving the provider's new mapping.
    targets.add("cardA", 30)
    factory.extraNodesOnce = 1
    let buildsBefore = factory.buildCount
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(factory.buildCount, buildsBefore + 2)
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.nodeIdForKey("cardA") > 0, true)
    @Assert(holder.compositeElementNodeIdsForKey("cardA").size >= 4, true)
    let afterFailure = compositeFieldBinding(holder, "cardA")
    @Assert(afterFailure.instanceIncarnation, before.instanceIncarnation)
    @Assert(afterFailure.ownerTargetResourceId, 10)
    @Assert(afterFailure.instanceOwnerTargetResourceId, 10)
    @Assert(holder.compositeOwnerTargetForInstance("cardA"), 10)
    @Assert(holder.compositeInstanceKeyForOwnerTarget(10), "cardA")
    @Assert(holder.compositeInstanceKeyForOwnerTarget(30), "")
    @Assert(holder.compositeActionIntentIsBound(resolved.nodeId, resolved.actionName, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation), true)
    // While the provider itself resolves the key elsewhere, its owner-side
    // guard refuses the old target: the accepted binding is kept, it is not a
    // licence to write a different object.
    @Assert(provider.executeAction(resolved.actionName, resolved.nodeKey, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation).applied, false)
    @Assert(provider.executed.size, 0)

    // The external mapping returns to the accepted owner (it never became a
    // scene). The SAME accepted intent is live again and its owner transaction
    // really executes.
    targets.add("cardA", 10)
    @Assert(provider.executeAction(resolved.actionName, resolved.nodeKey, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation).applied, true)
    @Assert(provider.executed[0], "cardA:10:APPLY_DRAFT")

    // A later legal rebind commits and DOES retire the old binding.
    targets.add("cardA", 30)
    factory.extraNodes = 0
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let rebound = compositeFieldBinding(holder, "cardA")
    @Assert(rebound.ownerTargetResourceId, 30)
    @Assert(rebound.instanceIncarnation != before.instanceIncarnation, true)
    @Assert(holder.compositeActionIntentIsBound(resolved.nodeId, resolved.actionName, resolved.instanceKey,
        resolved.ownerTargetResourceId, resolved.instanceIncarnation), false)
    @Assert(holder.compositeInstanceKeyForOwnerTarget(10), "")
    @Assert(holder.compositeInstanceKeyForOwnerTarget(30), "cardA")
}

@Test
func compositeSameKeyRebindRefusesTheOldPresetPress(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let twoCards = ArrayList<CjguiGeneratedUiNodeSpec>([
        CjguiGeneratedUiNodeSpec("cardA", "integerEdit"),
        CjguiGeneratedUiNodeSpec("cardB", "integerEdit")
    ])
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical", children: twoCards)

    // Generation A: the preset resolves to owner target 1.
    let providerA = CompositeTargetProvider(1)
    @Assert(holder.submit(structure, providerA).candidateAccepted, true)
    @Assert(generatedCommit(holder, providerA), true)
    let presetA = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_PRESET)
    @Assert(presetA.ownerTargetResourceId, 1)
    let latePreset = compositePresetLayoutNode(presetA)

    // Generation B: SAME key, SAME kind, SAME binding resource - only the owner
    // TARGET changes. A check that only compared identity/resource would let the
    // old object's press through to B's owner.
    let providerB = CompositeTargetProvider(2)
    @Assert(holder.submit(structure, providerB).candidateAccepted, true)
    @Assert(generatedCommit(holder, providerB), true)
    let presetB = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_PRESET)
    @Assert(presetB.nodeId, presetA.nodeId)
    @Assert(presetB.bindingResourceId, presetA.bindingResourceId)
    @Assert(presetB.ownerTargetResourceId, 2)

    let late = holder.resolveIntent(latePreset, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(late.kind, CJGUI_GENERATED_INTENT_NONE)
    @Assert(late.reason, "element_binding_mismatch")

    // The CURRENT preset button still resolves, to the current target.
    let current = holder.resolveIntent(compositePresetLayoutNode(presetB),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(current.kind, CJGUI_GENERATED_INTENT_FIELD_EDIT)
    @Assert(current.ownerTargetResourceId, 2)
    @Assert(current.fieldId, "retentionCount")

    // A same-binding reorder keeps the preset route usable.
    let reorderedCards = ArrayList<CjguiGeneratedUiNodeSpec>([
        CjguiGeneratedUiNodeSpec("cardB", "integerEdit"),
        CjguiGeneratedUiNodeSpec("cardA", "integerEdit")
    ])
    let reordered = CjguiGeneratedUiNodeSpec("panel", "vertical", children: reorderedCards)
    @Assert(holder.submit(reordered, providerB).candidateAccepted, true)
    @Assert(generatedCommit(holder, providerB), true)
    let afterReorder = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_PRESET)
    let reorderedIntent = holder.resolveIntent(compositePresetLayoutNode(afterReorder),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(reorderedIntent.kind, CJGUI_GENERATED_INTENT_FIELD_EDIT)
    @Assert(reorderedIntent.ownerTargetResourceId, 2)
}

/// A provider whose ACTION availability, owner target and execution route are
/// resolved per composite INSTANCE. Two instances of one kind therefore see
/// their own enabled state and act on their own owner object.
private class CompositeActionProvider <: CjguiGeneratedUiBindingProvider {
    private let targets: HashMap<String, Int64>
    private let availability: HashMap<String, CjguiSharedAvailability>
    var executed: ArrayList<String> = ArrayList<String>()

    init(targets: HashMap<String, Int64>, availability: HashMap<String, CjguiSharedAvailability>) {
        this.targets = targets
        this.availability = availability
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return CjguiSharedAvailability.unknown()
    }
    public func actionAvailability(actionName: String, instanceKey: String): CjguiSharedAvailability {
        return availability.get(instanceKey) ?? CjguiSharedAvailability.unknown()
    }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "instance_required")
    }
    public func actionAvailable(actionName: String): Bool { return true }
    public func executeAction(actionName: String, nodeKey: String,
        instanceKey: String): CjguiGeneratedUiActionResult {
        let target = targets.get(instanceKey) ?? -1
        return executeAction(actionName, nodeKey, instanceKey, target, 0)
    }
    public func executeAction(actionName: String, nodeKey: String, instanceKey: String,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64): CjguiGeneratedUiActionResult {
        let _ = instanceIncarnation
        let target = targets.get(instanceKey) ?? -1
        if (target < 0) {
            return CjguiGeneratedUiActionResult(false, "unknown_instance")
        }
        // The ORIGINAL accepted target must still be this key's object. A key
        // that moved is a retired binding, not a reason to follow it.
        if (target != ownerTargetResourceId) {
            return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        let fact = availability.get(instanceKey) ?? CjguiSharedAvailability.unknown()
        if (fact.known && !fact.isAvailable) {
            return CjguiGeneratedUiActionResult(false, fact.reason)
        }
        executed.add("${instanceKey}:${target}:${actionName}")
        return CjguiGeneratedUiActionResult(true, "")
    }
}

/// The public action seam must carry the INSTANCE it belongs to, not only the
/// action name: enabled state, refusal reason and owner target are per object,
/// survive a reorder and stay retired after a same-key rebind.
@Test
func compositeInstancesKeepTheirOwnActionsAcrossReorderAndRebind(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    targets.add("cardB", 20)
    let availability = HashMap<String, CjguiSharedAvailability>()
    availability.add("cardA", CjguiSharedAvailability.allowed(10, 3))
    availability.add("cardB", CjguiSharedAvailability.blocked("locked_by_owner", 20, 4))
    let provider = CompositeActionProvider(targets, availability)
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit")
        ]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let actionA = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION)
    let actionB = compositeRoleBinding(holder, "cardB", CJGUI_COMPOSITE_ELEMENT_ACTION)
    @Assert(actionA.ownerTargetResourceId, 10)
    @Assert(actionB.ownerTargetResourceId, 20)
    @Assert(actionA.actionEnabled, true)
    @Assert(actionB.actionEnabled, false)
    @Assert(actionA.blockedReason, "")
    @Assert(actionB.blockedReason, "locked_by_owner")

    // Each control resolves to its OWN instance and target.
    let intentA = holder.resolveIntent(compositeActionLayoutNode(actionA),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    let intentB = holder.resolveIntent(compositeActionLayoutNode(actionB),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(intentA.isAction(), true)
    @Assert(intentA.actionName, "APPLY_DRAFT")
    @Assert(intentA.ownerTargetResourceId, 10)
    @Assert(intentA.instanceKey, "cardA")
    @Assert(intentB.ownerTargetResourceId, 20)
    @Assert(intentB.instanceKey, "cardB")

    // Execution routes by instance: A reaches its owner, B's owner refuses with
    // its own reason and records nothing.
    @Assert(provider.executeAction(intentA.actionName, intentA.nodeKey, intentA.instanceKey).applied, true)
    let refusedB = provider.executeAction(intentB.actionName, intentB.nodeKey, intentB.instanceKey)
    @Assert(refusedB.applied, false)
    @Assert(refusedB.reason, "locked_by_owner")
    @Assert(provider.executed.size, 1)
    @Assert(provider.executed[0], "cardA:10:APPLY_DRAFT")

    // Reorder: both instances keep their own target and enabled state.
    let reordered = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([
            CjguiGeneratedUiNodeSpec("cardB", "integerEdit"),
            CjguiGeneratedUiNodeSpec("cardA", "integerEdit")
        ]))
    @Assert(holder.submit(reordered, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION).ownerTargetResourceId, 10)
    @Assert(compositeRoleBinding(holder, "cardB", CJGUI_COMPOSITE_ELEMENT_ACTION).ownerTargetResourceId, 20)
    @Assert(compositeRoleBinding(holder, "cardB", CJGUI_COMPOSITE_ELEMENT_ACTION).actionEnabled, false)

    // Same-key rebind: the old control's late press is refused, while the new
    // object's action resolves and executes against its NEW owner.
    let reboundTargets = HashMap<String, Int64>()
    reboundTargets.add("cardA", 30)
    reboundTargets.add("cardB", 20)
    let reboundAvailability = HashMap<String, CjguiSharedAvailability>()
    reboundAvailability.add("cardA", CjguiSharedAvailability.allowed(30, 5))
    reboundAvailability.add("cardB", CjguiSharedAvailability.allowed(20, 5))
    let rebound = CompositeActionProvider(reboundTargets, reboundAvailability)
    @Assert(holder.submit(reordered, rebound).candidateAccepted, true)
    @Assert(generatedCommit(holder, rebound), true)
    let late = holder.resolveIntent(compositeActionLayoutNode(actionA),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(late.kind, CJGUI_GENERATED_INTENT_NONE)
    @Assert(late.reason, "element_binding_mismatch")
    let currentA = compositeRoleBinding(holder, "cardA", CJGUI_COMPOSITE_ELEMENT_ACTION)
    @Assert(currentA.ownerTargetResourceId, 30)
    @Assert(currentA.actionEnabled, true)
    let currentIntent = holder.resolveIntent(compositeActionLayoutNode(currentA),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "")
    @Assert(currentIntent.isAction(), true)
    @Assert(currentIntent.ownerTargetResourceId, 30)
    @Assert(rebound.executeAction(currentIntent.actionName, currentIntent.nodeKey,
        currentIntent.instanceKey).applied, true)
    @Assert(rebound.executed[0], "cardA:30:APPLY_DRAFT")
}

/// Every element of one accepted instance must carry the SAME instance owner
/// target, including a container element that has no writer of its own. The
/// public instances projection reads this value, so a -1 there would hide the
/// instance's object from an external client.
@Test
func compositeEveryElementCarriesTheInstanceOwnerTarget(): Unit {
    let catalog = compositeCatalog()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), CompositeTestFactory()), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 6200)
    let provider = CompositeActionProvider(targets, HashMap<String, CjguiSharedAvailability>())
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let bindings = holder.compositeElementNodeIdsForKey("cardA")
    @Assert(bindings.size >= 4, true)
    var root: ?CjguiCompositeElementBinding = None
    for (binding in bindings) {
        @Assert(binding.instanceOwnerTargetResourceId, 6200)
        if (binding.elementKey == "root") {
            root = Some(binding)
        }
    }
    @Assert(root.isSome(), true)
    let rootBinding = root.getOrThrow()
    @Assert(rootBinding.ownerTargetResourceId, -1)
}

/// Every `gap` value in a built subtree, so a declared layout property can be
/// checked in the tree the window would really commit.
private func compositeGaps(node: CjguiComposableUiNode): ArrayList<Int64> {
    let gaps = ArrayList<Int64>()
    compositeCollectGaps(node, gaps)
    return gaps
}

private func compositeCollectGaps(node: CjguiComposableUiNode, into: ArrayList<Int64>): Unit {
    into.add(node.style.gap)
    for (child in node.children()) {
        compositeCollectGaps(child, into)
    }
}
