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
    var dropElement: Bool = false
    var foreignId: Int64 = -1

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        buildCount += 1
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let container = cjguiComposableVertical(root.nodeId, root.semanticId,
            CjguiComposableUiStyle(gap: 4))
        if (!dropElement) {
            if (let Some(field) <- context.element("edit")) {
                container.add(cjguiComposableIntegerInput(field.nodeId, field.semanticId, field.label,
                    field.draftText, field.bindingResourceId, CjguiComposableUiStyle(fixedHeight: 26),
                    fieldId: field.fieldId, operationActionName: field.writerOperation,
                    operationResourceId: field.ownerTargetResourceId, displayValueRole: "draft"))
            }
            if (let Some(preset) <- context.element("preset")) {
                container.add(cjguiComposableButton(preset.nodeId, preset.semanticId, preset.label,
                    "GENERATED_ACTION", preset.bindingResourceId, CjguiComposableUiStyle(fixedHeight: 26)))
            }
            if (let Some(action) <- context.element("apply")) {
                container.add(cjguiComposableButton(action.nodeId, action.semanticId, action.label,
                    "GENERATED_ACTION", action.nodeId, CjguiComposableUiStyle(fixedHeight: 26),
                    enabled: action.actionEnabled))
            }
        }
        var index: Int64 = 0
        while (index < extraNodes) {
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
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("retentionCount", "保留天数", "INTEGER", 81003))
    return catalog
}

func compositeSpec(kind: String, expandedNodeLimit!: Int64 = 8): CjguiCompositeComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER"))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "retentionCount", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
        fieldId: "retentionCount", presetValue: "90", label: "设为 90", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "APPLY_DRAFT", label: "应用", parentKey: "root"))
    return CjguiCompositeComponentSpec(kind, properties, elements, expandedNodeLimit: expandedNodeLimit)
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
    let presetNode = cjguiComposableButton(presetNodeId, "s", "设为 90", "GENERATED_ACTION", 81003,
        CjguiComposableUiStyle())
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
