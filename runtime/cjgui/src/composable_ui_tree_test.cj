// Correctness tests for the experimental generic tree projection and
// multi-selection (composable_ui_tree.cj). Pure standard Cangjie: runs on
// the host without windows or native modules.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

// Synthetic hierarchical source: `groups` top-level groups, each with
// `leavesPerGroup` selectable leaf children. Group keys are "group-<n>",
// leaf keys "group-<n>-leaf-<m>".
class TreeTestSource <: CjguiComposableUiTreeDataSource {
    let groups: Int64
    let leavesPerGroup: Int64
    let labelPrefix: String

    init(groups: Int64, leavesPerGroup: Int64, labelPrefix!: String = "node") {
        this.groups = groups
        this.leavesPerGroup = leavesPerGroup
        this.labelPrefix = labelPrefix
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return groups }
        if (parentKey.startsWith("group-")) { return leavesPerGroup }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        if (parentKey.isEmpty()) {
            return CjguiComposableUiTreeNode(
                "group-${index}", "${labelPrefix}-group-${index}", 100 + index,
                true, selectable: false)
        }
        return CjguiComposableUiTreeNode(
            "${parentKey}-leaf-${index}", "${labelPrefix}-leaf-${index}", 200 + index,
            false, selectable: true)
    }
}

// A source that re-uses the same key for two siblings (duplicate detection).
class DuplicateKeySource <: CjguiComposableUiTreeDataSource {
    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return 2 }
        return 0
    }
    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        return CjguiComposableUiTreeNode("dup", "duplicate", 1, false, selectable: true)
    }
}

@Test
func treeEmptyProjection(): Unit {
    let source = TreeTestSource(0, 0)
    let projection = CjguiComposableUiTreeProjection(source)
    @Assert(projection.rowCount(), 0)
    @Assert(projection.dataVersion(), 0)
    projection.invalidate()
    @Assert(projection.rowCount(), 0)
}

@Test
func treeExpandCollapseProjection(): Unit {
    let source = TreeTestSource(2, 3)
    let projection = CjguiComposableUiTreeProjection(source)
    // Collapsed: only the 2 group rows are visible.
    @Assert(projection.rowCount(), 2)
    @Assert(projection.rowAt(0).key, "group-0")
    @Assert(projection.rowAt(0).depth, 0)
    // Expand group 0: 1 group row + 3 leaves + 1 group row = 5 rows.
    projection.setExpanded("group-0", true)
    @Assert(projection.rowCount(), 5)
    @Assert(projection.rowAt(1).key, "group-0-leaf-0")
    @Assert(projection.rowAt(1).depth, 1)
    // Collapse again.
    projection.setExpanded("group-0", false)
    @Assert(projection.rowCount(), 2)
}

@Test
func treeDuplicateKeysSkipped(): Unit {
    let source = DuplicateKeySource()
    let projection = CjguiComposableUiTreeProjection(source)
    projection.rebuild()
    // Both siblings share the key "dup"; only the first projects.
    @Assert(projection.rowCount(), 1)
    @Assert(!projection.lastError().isEmpty(), true)
}

@Test
func selectionClickAndCommandToggle(): Unit {
    let source = TreeTestSource(1, 4)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)

    // Plain click selects exactly one row.
    selection.click("group-0-leaf-0", false, false)
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.isSelected("group-0-leaf-0"), true)

    // Second plain click replaces the selection.
    selection.click("group-0-leaf-1", false, false)
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-0"), false)

    // Cmd click toggles a second row into the selection.
    selection.click("group-0-leaf-2", true, false)
    @Assert(selection.selectedCount(), 2)
    @Assert(selection.isSelected("group-0-leaf-2"), true)

    // Cmd click again removes it.
    selection.click("group-0-leaf-2", true, false)
    @Assert(selection.selectedCount(), 1)
}

@Test
func selectionShiftRangeUsesVisibleOrder(): Unit {
    let source = TreeTestSource(1, 6)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)

    // Anchor on leaf 1, Shift to leaf 4: leaves 1..4 selected in order.
    selection.click("group-0-leaf-1", false, false)
    selection.moveFocus("group-0-leaf-4", true)
    @Assert(selection.selectedCount(), 4)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-4"), true)
    @Assert(selection.isSelected("group-0-leaf-5"), false)
}

@Test
func selectionPruneRemovesVanishedKeys(): Unit {
    let source = TreeTestSource(1, 3)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.click("group-0-leaf-0", false, false)
    selection.click("group-0-leaf-1", true, false)
    @Assert(selection.selectedCount(), 2)

    // Simulate a data change that removes leaf 1: prune with only leaf 0
    // and leaf 2 still projecting.
    let existing = ArrayList<String>(["group-0-leaf-0", "group-0-leaf-2"])
    selection.prune(existing)
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.isSelected("group-0-leaf-0"), true)
    @Assert(selection.isSelected("group-0-leaf-1"), false)
}

@Test
func treeScale100ProjectionAndSelection(): Unit {
    // 20 groups x 5 leaves = 100 logical nodes.
    let source = TreeTestSource(20, 5)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.rebuild()
    @Assert(projection.rowCount(), 20)
    var groupIndex: Int64 = 0
    while (groupIndex < 20) {
        projection.setExpanded("group-${groupIndex}", true)
        groupIndex += 1
    }
    @Assert(projection.rowCount(), 120)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.selectAllVisible()
    @Assert(selection.selectedCount(), 100)
    selection.clearSelection()
    @Assert(selection.selectedCount(), 0)
}

@Test
func treeScale1kProjectionAndSelection(): Unit {
    // 40 groups x 25 leaves = 1,000 logical nodes.
    let source = TreeTestSource(40, 25)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.rebuild()
    @Assert(projection.rowCount(), 40)
    var groupIndex: Int64 = 0
    while (groupIndex < 40) {
        projection.setExpanded("group-${groupIndex}", true)
        groupIndex += 1
    }
    @Assert(projection.rowCount(), 1040)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.selectAllVisible()
    @Assert(selection.selectedCount(), 1000)
    selection.clearSelection()
    @Assert(selection.selectedCount(), 0)
}

@Test
func treeScale10kProjection(): Unit {
    // 200 groups x 50 leaves = 10,000 logical nodes.
    let source = TreeTestSource(200, 50)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.rebuild()
    @Assert(projection.rowCount(), 200)
    var groupIndex: Int64 = 0
    while (groupIndex < 200) {
        projection.setExpanded("group-${groupIndex}", true)
        groupIndex += 1
    }
    @Assert(projection.rowCount(), 10200)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.selectAllVisible()
    @Assert(selection.selectedCount(), 10000)
    selection.clearSelection()
    @Assert(selection.selectedCount(), 0)
}

@Test
func selectionFocusFallsBackToVisibleAncestorOnCollapse(): Unit {
    let source = TreeTestSource(1, 4)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.click("group-0-leaf-2", false, false)
    @Assert(selection.focus(), "group-0-leaf-2")
    // Collapsing hides the focused leaf: the focus must land on the visible
    // group row, and the logical selection stays in the set.
    projection.setExpanded("group-0", false)
    selection.ensureFocusVisible()
    @Assert(selection.focus(), "group-0")
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
    // Expanding again keeps the logical selection intact.
    projection.setExpanded("group-0", true)
    selection.ensureFocusVisible()
    @Assert(selection.selectedCount(), 1)
}

@Test
func selectionAnchorFallbackDoesNotExtendSelection(): Unit {
    let source = TreeTestSource(1, 4)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.click("group-0-leaf-0", false, false)
    selection.click("group-0-leaf-2", true, false)
    @Assert(selection.selectedCount(), 2)
    @Assert(selection.anchor(), "group-0-leaf-2")
    // The anchor's key vanishes: the fallback is the first surviving selected
    // key, and the selection is not extended.
    let existing = ArrayList<String>(["group-0-leaf-0", "group-0-leaf-3"])
    selection.prune(existing)
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.anchor(), "group-0-leaf-0")
    @Assert(selection.isSelected("group-0-leaf-3"), false)
}

// --- generated-UI routing invariants (pure model) --------------------------

class GeneratedTestProvider <: CjguiGeneratedUiBindingProvider {
    // Draft and applied differ so a test can prove which one is presented.
    public func fieldResourceId(fieldId: String): Int64 { return 7001 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 42 }
    public func draftText(fieldId: String): String { return "draft" }
    public func appliedText(fieldId: String): String { return "applied" }
    public func draftBoolean(fieldId: String): ?Bool { return Some(false) }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// Provider whose field holds a legally empty draft over a non-empty applied
/// value; the presented value must stay the empty draft.
class GeneratedEmptyDraftProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return 7001 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 42 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "applied" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

func generatedTextCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿"))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称", "TEXT", 7001))
    return catalog
}

/// Drives one full candidate -> scene-accept transaction the way the window
/// does: begin, build the refresh node, prepare, then commit.
func generatedCommit(holder: CjguiGeneratedUiStructureHolder,
                     provider: CjguiGeneratedUiBindingProvider): Bool {
    if (!holder.beginCandidateRefresh()) {
        return false
    }
    let _ = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        holder.rollbackCandidateRefresh()
        return false
    }
    return holder.commitCandidateRefresh()
}

@Test
func generatedRoutingResolvesAcceptedKeysOnly(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    leaves.add(CjguiGeneratedUiNodeSpec("btnA", "action", actionName: "APPLY_DRAFT"))
    let root = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: leaves)
    let result = holder.submit(root, provider)
    @Assert(result.candidateAccepted, true)
    // Candidate acceptance is NOT scene acceptance: the accepted structure and
    // version stay where they were until the window commits.
    @Assert(result.sceneAccepted, false)
    @Assert(holder.structureVersion(), 0)
    @Assert(holder.candidateStructureVersion(), 1)
    @Assert(holder.hasPendingCandidate(), true)
    @Assert(holder.acceptedNodeForKey("fieldA").isNone(), true)
    // The scene-accept transaction publishes everything together.
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(holder.candidateStructureVersion(), 0)
    @Assert(holder.lastSceneOutcome(), "scene_accepted")
    // The accepted node resolves for a live key and never for a forged one.
    if (let Some(spec) <- holder.acceptedNodeForKey("fieldA")) {
        @Assert(spec.fieldId, "label")
    } else {
        @Assert(false, true)
    }
    @Assert(holder.acceptedNodeForKey("forgedKey").isNone(), true)
    @Assert(holder.actionNameForKey("btnA"), "APPLY_DRAFT")
    @Assert(holder.actionNameForKey("forgedKey").isEmpty(), true)
    // A rejected candidate keeps the previous accepted structure and version.
    let rejected = holder.submit(CjguiGeneratedUiNodeSpec("", "vertical"), provider)
    @Assert(rejected.candidateAccepted, false)
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.rejectedReason().size > 0, true)
}

@Test
func generatedCandidateRollbackKeepsAcceptedInterfaceOperable(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    let first = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: leaves)
    @Assert(holder.submit(first, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let acceptedId = holder.nodeIdForKey("fieldA")
    @Assert(acceptedId > 0, true)

    // A valid candidate whose scene is rejected (layout/native failure) must
    // not publish anything: old version, old structure, old node identity.
    let secondChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    secondChildren.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    secondChildren.add(CjguiGeneratedUiNodeSpec("fieldB", "textInput", fieldId: "label"))
    let second = CjguiGeneratedUiNodeSpec("panelB", "vertical", children: secondChildren)
    @Assert(holder.submit(second, provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    holder.rollbackCandidateRefresh()
    @Assert(holder.structureVersion(), 1)
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:layout_or_native")
    @Assert(holder.keyForNodeId(acceptedId), "fieldA")
    @Assert(holder.acceptedNodeForKey("fieldA").isSome(), true)
    @Assert(holder.acceptedNodeForKey("fieldB").isNone(), true)

    // After the rejected candidate the accepted interface still accepts a new
    // legal structure.
    let thirdChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    thirdChildren.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    thirdChildren.add(CjguiGeneratedUiNodeSpec("fieldB", "textInput", fieldId: "label"))
    let third = CjguiGeneratedUiNodeSpec("panelC", "vertical", children: thirdChildren)
    @Assert(holder.submit(third, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), 2)
    @Assert(holder.nodeIdForKey("fieldA"), acceptedId)
}

@Test
func generatedValidatorEnforcesDeclaredPropertyContracts(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32)
        ]), true, childLimit: 8))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 4)
        ]), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿"))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称", "TEXT", 7001))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("enabled", "启用", "BOOLEAN", 7002))
    let validator = CjguiGeneratedUiValidator(catalog)

    // required property missing
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("l1", "label")).reason, "missing_required_property")
    // declared STRING maxLength
    let longText = HashMap<String, String>()
    longText.add("text", "12345")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("l2", "label", properties: longText)).reason,
        "property_too_long")
    // declared INTEGER type and range
    let badText = HashMap<String, String>()
    badText.add("gap", "wide")
    let labelChild = ArrayList<CjguiGeneratedUiNodeSpec>()
    labelChild.add(CjguiGeneratedUiNodeSpec("l3", "label", properties: longText))
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("v1", "vertical", properties: badText,
        children: labelChild)).reason, "property_not_integer")
    let outOfRange = HashMap<String, String>()
    outOfRange.add("gap", "64")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("v2", "vertical", properties: outOfRange,
        children: labelChild)).reason, "property_out_of_range")
    // field/control compatibility
    let shortText = HashMap<String, String>()
    shortText.add("text", "ok")
    let okLeaf = ArrayList<CjguiGeneratedUiNodeSpec>()
    okLeaf.add(CjguiGeneratedUiNodeSpec("l4", "label", properties: shortText))
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("v3", "vertical", children: okLeaf)).accepted, true)
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("b1", "booleanInput", fieldId: "label")).reason,
        "field_editor_kind_mismatch")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("b2", "booleanInput", fieldId: "enabled")).accepted, true)
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("t1", "textInput")).reason, "field_binding_required")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("t2", "textInput", fieldId: "missing")).reason,
        "unknown_field")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("a1", "action")).reason, "action_binding_required")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("a2", "action", actionName: "NOPE")).reason,
        "unknown_action")
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("a3", "action", actionName: "APPLY_DRAFT")).accepted, true)
    @Assert(validator.validate(CjguiGeneratedUiNodeSpec("v4", "vertical", fieldId: "label", children: okLeaf)).reason,
        "field_not_allowed")
}

@Test
func generatedRegistrationRejectsUnimplementedComponents(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    // A custom kind without an implemented presentation is refused at
    // registration - it can never be accepted and then degrade into a label.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("slider",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false)), false)
    @Assert(catalog.lastRegistrationRejection(), "component_presentation_not_implemented:slider")
    @Assert(catalog.componentFor("slider").isNone(), true)
    // A declared property the presentation never reads is refused too.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("rotation", "INTEGER")
        ]), true, childLimit: 4)), false)
    @Assert(catalog.lastRegistrationRejection(), "property_not_implemented:vertical:rotation")
    // The implemented subset registers, and duplicate kinds/fields are refused.
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32)
        ]), true, childLimit: 4)), true)
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 4)), false)
    @Assert(catalog.lastRegistrationRejection(), "duplicate_component_kind:vertical")
    @Assert(catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称", "TEXT", 7001)), true)
    @Assert(catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称2", "TEXT", 7003)), false)
    @Assert(catalog.lastRegistrationRejection(), "duplicate_field:label")
    @Assert(catalog.registerField(CjguiGeneratedUiFieldSpec("orphan", "无资源", "TEXT", -1)), false)
    @Assert(catalog.lastRegistrationRejection(), "field_without_resource:orphan")
}

@Test
func generatedFieldDefinitionDrivesWriteActionAndPresentation(): Unit {
    // One authored definition (the shared form binding) derives the field spec
    // used by both the handwritten form and the generated editor.
    let binding = CjguiSharedFormBinding(ArrayList<CjguiSharedFormFieldDescriptor>([
        CjguiSharedFormFieldDescriptor(7001, "label", "名称", "TEXT"),
        CjguiSharedFormFieldDescriptor(7002, "enabled", "启用", "BOOLEAN"),
        CjguiSharedFormFieldDescriptor(7003, "retentionCount", "保留天数", "INTEGER")
    ]))
    let specs = CjguiGeneratedUiFieldSpec.fromFormBinding(binding)
    @Assert(specs.size, 3)
    @Assert(specs[0].fieldId, "label")
    @Assert(specs[0].resourceId, 7001)
    @Assert(specs[0].writeActionName, "EDIT_DRAFT_TEXT")
    @Assert(specs[0].inputKind(), "textInput")
    @Assert(specs[1].writeActionName, "EDIT_DRAFT_BOOLEAN")
    @Assert(specs[1].inputKind(), "booleanInput")
    @Assert(specs[2].writeActionName, "EDIT_DRAFT_TEXT")
    @Assert(specs[2].inputKind(), "integerInput")
    // A registered component uses the derived definitions without a second
    // hand-written catalog, and the generated editor carries the field's own
    // write action rather than a hardcoded one.
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    @Assert(catalog.registerFields(specs), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let node = CjguiGeneratedUiNodeSpec("mark", "booleanInput", fieldId: "enabled")
    @Assert(holder.submit(node, GeneratedTestProvider()).candidateAccepted, true)
    @Assert(generatedCommit(holder, GeneratedTestProvider()), true)
    let built = holder.buildAccepted(GeneratedTestProvider())
    @Assert(built.operationActionName, "EDIT_DRAFT_BOOLEAN")
    @Assert(built.resourceId, 7002)
    @Assert(built.fieldId, "enabled")
}

@Test
func generatedEmptyDraftIsNotReplacedByAppliedValue(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedEmptyDraftProvider()
    let node = CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label")
    @Assert(holder.submit(node, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    // The declared field value comes from the live draft, exactly like the
    // handwritten form: an empty draft stays empty instead of showing the
    // applied value.
    let built = holder.buildAccepted(provider)
    @Assert(built.value, "")
    @Assert(built.value != "applied", true)
}

@Test
func generatedStructureUpdateKeepsSurvivingIdentity(): Unit {
    let catalog = generatedTextCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()

    let firstChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    firstChildren.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    let first = holder.submit(CjguiGeneratedUiNodeSpec("panelA", "vertical", children: firstChildren), provider)
    @Assert(first.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let idBefore = holder.nodeIdForKey("fieldA")
    @Assert(idBefore > 0, true)

    // Re-order the same key and add a new one: the surviving key keeps its
    // identity (focus/selection continuation), the new key gets a new one.
    let secondChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    secondChildren.add(CjguiGeneratedUiNodeSpec("fieldB", "textInput", fieldId: "label"))
    secondChildren.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    let second = holder.submit(CjguiGeneratedUiNodeSpec("panelB", "vertical", children: secondChildren), provider)
    @Assert(second.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.nodeIdForKey("fieldA"), idBefore)
    @Assert(holder.nodeIdForKey("fieldB") > 0, true)
    @Assert(holder.nodeIdForKey("fieldB") != idBefore, true)
    @Assert(holder.keyForNodeId(idBefore), "fieldA")

    // A key removed by the accepted update no longer resolves for events.
    let third = holder.submit(CjguiGeneratedUiNodeSpec("panelC", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>()), provider)
    @Assert(third.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.nodeIdForKey("fieldA"), -1)
    @Assert(holder.acceptedNodeForKey("fieldA").isNone(), true)
    @Assert(holder.actionNameForKey("fieldA").isEmpty(), true)
}

@Test
func generatedValidatorEnforcesNodeBoundAcrossSiblings(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog(maxDepth: 8, maxNodes: 32,
        maxPropertiesPerNode: 4, maxStringLength: 32)
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 64))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let groups = ArrayList<CjguiGeneratedUiNodeSpec>()
    var groupIndex: Int64 = 0
    while (groupIndex < 4) {
        let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
        var leafIndex: Int64 = 0
        while (leafIndex < 20) {
            leaves.add(CjguiGeneratedUiNodeSpec("g${groupIndex}-l${leafIndex}", "label"))
            leafIndex += 1
        }
        groups.add(CjguiGeneratedUiNodeSpec("g${groupIndex}", "vertical", children: leaves))
        groupIndex += 1
    }
    let root = CjguiGeneratedUiNodeSpec("root", "vertical", children: groups)
    let result = holder.submit(root, provider)
    @Assert(result.candidateAccepted, false)
    @Assert(result.reason, "max_nodes_exceeded")
    @Assert(holder.structureVersion(), 0)
}

// --- range/navigation regressions (visible-order semantics) -----------------

@Test
func treeShiftRangeSelectsInBothDirections(): Unit {
    let source = TreeTestSource(1, 5)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    // Forward range: leaf-1 .. leaf-3.
    selection.click("group-0-leaf-1", false, false)
    selection.click("group-0-leaf-3", false, true)
    @Assert(selection.selectedCount(), 3)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
    @Assert(selection.isSelected("group-0-leaf-3"), true)
    // Reverse range from the same anchor: leaf-3 back to leaf-1. The earlier
    // implementation walked startIndex..endIndex upward and cleared the
    // selection without adding anything.
    selection.click("group-0-leaf-1", false, false)
    selection.click("group-0-leaf-3", false, false)
    selection.click("group-0-leaf-1", false, true)
    @Assert(selection.selectedCount(), 3)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
    @Assert(selection.isSelected("group-0-leaf-3"), true)
    @Assert(selection.anchor(), "group-0-leaf-3")
    @Assert(selection.focus(), "group-0-leaf-1")
    // A reverse range that starts before the anchor but ends on the anchor.
    selection.click("group-0-leaf-4", false, false)
    selection.click("group-0-leaf-2", false, true)
    @Assert(selection.selectedCount(), 3)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
    @Assert(selection.isSelected("group-0-leaf-3"), true)
    @Assert(selection.isSelected("group-0-leaf-4"), true)
    // Command toggling after a reverse range keeps the anchor at the toggled
    // row, and the next Shift range follows that row.
    selection.click("group-0-leaf-0", true, false)
    @Assert(selection.anchor(), "group-0-leaf-0")
    selection.click("group-0-leaf-2", false, true)
    @Assert(selection.selectedCount(), 3)
    @Assert(selection.isSelected("group-0-leaf-0"), true)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
}

@Test
func treeCollapseKeepsHiddenSelectionUntilRecordVanishes(): Unit {
    let source = TreeTestSource(2, 3)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    projection.setExpanded("group-1", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.click("group-0-leaf-0", false, false)
    selection.click("group-0-leaf-2", false, true)
    @Assert(selection.selectedCount(), 3)
    // Collapse group-0: the rows disappear from the projection, but the
    // selection is logical and must survive a business update that does not
    // delete those records.
    projection.setExpanded("group-0", false)
    @Assert(projection.isVisible("group-0-leaf-0"), false)
    let logical = ArrayList<String>(["group-0", "group-1"])
    var leafIndex: Int64 = 0
    while (leafIndex < 3) {
        logical.add("group-0-leaf-${leafIndex}")
        logical.add("group-1-leaf-${leafIndex}")
        leafIndex += 1
    }
    selection.prune(logical)
    @Assert(selection.selectedCount(), 3)
    @Assert(selection.isSelected("group-0-leaf-0"), true)
    @Assert(selection.isSelected("group-0-leaf-1"), true)
    @Assert(selection.isSelected("group-0-leaf-2"), true)
    // Re-expanding shows the same keys, still selected.
    projection.setExpanded("group-0", true)
    @Assert(projection.rowAt(1).key, "group-0-leaf-0")
    @Assert(selection.isSelected(projection.rowAt(1).key), true)
    // A record that really vanished is the only thing pruned.
    let afterDelete = ArrayList<String>()
    for (key in logical) {
        if (key != "group-0-leaf-1") {
            afterDelete.add(key)
        }
    }
    selection.prune(afterDelete)
    @Assert(selection.selectedCount(), 2)
    @Assert(selection.isSelected("group-0-leaf-1"), false)
    @Assert(selection.isSelected("group-0-leaf-0"), true)
    // A no-op prune must not advance the selection version, so an unchanged
    // refresh cannot force a scene commit.
    let versionBefore = selection.selectionVersion()
    selection.prune(afterDelete)
    @Assert(selection.selectionVersion(), versionBefore)
}

@Test
func treeNavigationMovesFocusAndMaterializesTarget(): Unit {
    let source = TreeTestSource(2, 12)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    projection.setExpanded("group-1", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.click("group-0-leaf-0", false, false)
    // Down/up walk the visible order, including the group row after the last
    // leaf of group-0.
    @Assert(selection.navigate("down", false).focus, "group-0-leaf-1")
    @Assert(selection.navigate("down", false).focus, "group-0-leaf-2")
    @Assert(selection.navigate("up", false).focus, "group-0-leaf-1")
    // Home/end reach the projection edges.
    @Assert(selection.navigate("home", false).focus, "group-0")
    @Assert(selection.navigate("end", false).focus, "group-1-leaf-11")
    // Shift-extended navigation selects the range from the anchor. The first
    // extension anchors at the focused row (like a Shift-click from it) and the
    // anchor then stays put for later extensions in the same gesture.
    selection.click("group-1-leaf-0", false, false)
    let extended = selection.navigate("down", true)
    @Assert(extended.didChange, true)
    @Assert(selection.selectedCount(), 2)
    @Assert(selection.isSelected("group-1-leaf-1"), true)
    @Assert(selection.anchor(), "group-1-leaf-0")
    let extendedToEnd = selection.navigate("end", true)
    @Assert(extendedToEnd.didChange, true)
    @Assert(selection.anchor(), "group-1-leaf-0")
    @Assert(selection.selectedCount(), 12)
    @Assert(selection.isSelected("group-1-leaf-11"), true)
    // A plain navigation after that clears the range on the next extension
    // start? No: the explicit anchor survives until another click sets one.
    selection.click("group-1-leaf-0", false, false)
    @Assert(selection.anchor(), "group-1-leaf-0")
    // Left ascends from a leaf to its group; a second Left on the expanded
    // group collapses it, and Right re-expands and descends again.
    selection.click("group-0-leaf-0", false, false)
    @Assert(selection.navigate("left", false).focus, "group-0")
    @Assert(projection.isExpanded("group-0"), true)
    let collapsed = selection.navigate("left", false)
    @Assert(collapsed.didChange, true)
    @Assert(collapsed.focus, "group-0")
    @Assert(projection.isExpanded("group-0"), false)
    // A collapsed root group has no visible ancestor: the command cannot move
    // and must not advance any revision.
    let noMove = selection.navigate("left", false)
    @Assert(noMove.didChange, false)
    @Assert(noMove.focus, "group-0")
    let reExpanded = selection.navigate("right", false)
    @Assert(reExpanded.didChange, true)
    @Assert(projection.isExpanded("group-0"), true)
    // Select-all covers the whole visible projection.
    let all = selection.navigate("select_all", false)
    @Assert(all.didChange, true)
    @Assert(selection.selectedCount(), projection.rowCount() - 2)
    @Assert(selection.isSelected("group-0-leaf-11"), true)
    @Assert(selection.isSelected("group-1-leaf-11"), true)
}

@Test
func treeNavigationRevealsOffscreenRowThroughListState(): Unit {
    let source = TreeTestSource(1, 400)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.setExpanded("group-0", true)
    let selection = CjguiComposableUiTreeSelection(projection)
    let listState = CjguiComposableUiVirtualListState()
    let listSource = CjguiComposableUiTreeListSource(projection, selection,
        { row, isSelected, isFocused => cjguiComposableText(1, row.key, row.label,
            CjguiComposableUiStyle()) })
    selection.click("group-0-leaf-0", false, false)
    // Navigate far past any fixed viewport; the framework list state must
    // reveal the target index rather than leaving the focus off-screen.
    var step: Int64 = 0
    while (step < 120) {
        let _ = selection.navigate("down", false)
        step += 1
    }
    let focus = selection.focus()
    @Assert(focus, "group-0-leaf-120")
    let revealed = listState.revealKey(listSource, focus)
    @Assert(revealed, true)
    @Assert(listState.scrollOffset() > 0, true)
    @Assert(listSource.indexForKey(focus), projection.indexForKey(focus))
    // Off-screen materialization still resolves the real stable key.
    let item = listSource.itemAt(projection.indexForKey(focus))
    @Assert(item.key, focus)
    @Assert(item.resourceId, 320)
}

// --- generated editor change-kind contract ----------------------------------
//
// A generated editor's *writer* and the human event kind that carries its
// change are both part of the field definition. The native bridge reports a
// toggled boolean as a boolean change (with the projected next value) and an
// edited text projection as a text change; a bare activation is not a change.
// A consumer that hardcodes 27 for a boolean silently drops every real press,
// so the mapping is asserted here in one place.

@Test
func generatedFieldSpecDeclaresTheChangeEventKind(): Unit {
    let booleanField = CjguiGeneratedUiFieldSpec("marked", "已提交", "BOOLEAN", 8102)
    let textField = CjguiGeneratedUiFieldSpec("title", "标题", "TEXT", 8101)
    let integerField = CjguiGeneratedUiFieldSpec("count", "数量", "INTEGER", 8103)
    @Assert(booleanField.changeEventKind(), CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED)
    @Assert(textField.changeEventKind(), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED)
    @Assert(integerField.changeEventKind(), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED)
    @Assert(booleanField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED), true)
    @Assert(booleanField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE), false)
    @Assert(booleanField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED), false)
    @Assert(textField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED), true)
    @Assert(textField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED), false)
    @Assert(textField.acceptsChangeEventKind(CJGUI_COMPOSABLE_UI_EVENT_FOCUS), false)
    // The writer mapping and the change kind stay one definition: a boolean
    // writer with a text change kind (or the reverse) is exactly the mismatch
    // this contract exists to prevent.
    @Assert(booleanField.writeActionName, "EDIT_DRAFT_BOOLEAN")
    @Assert(textField.writeActionName, "EDIT_DRAFT_TEXT")
    @Assert(integerField.writeActionName, "EDIT_DRAFT_TEXT")
    @Assert(CjguiGeneratedUiFieldSpec("unknown", "未知", "VECTOR", 8104).isWritable(), false)
}
