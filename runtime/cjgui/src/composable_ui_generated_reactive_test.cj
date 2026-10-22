// Anti-regression tests for two composable-UI generated fixes.
//
// What is pinned here:
//   * an ACCEPTED rebuild is a DATA refresh, not a rebind: while the provider
//     still resolves an instance to the accepted owner, every identity fact
//     (node id, incarnation, accepted owner target, field/writer/action) is
//     kept and only the live projection (draft, availability, blocked reason,
//     action enabled) is read again from that instance's provider data;
//   * a data refresh does not advance the accepted structure version;
//   * a rejected candidate whose provider mapping already moved to another
//     owner keeps the ACCEPTED binding and the accepted owner's data instead of
//     following the live mapping, and the new owner never becomes a key;
//   * the five-argument executeAction default: a legacy owner-less provider
//     still delegates to the older overloads, while a provider that declares a
//     real owner target is refused by name instead of silently re-resolving
//     the instance key against a newer object.
//
// Pure host tests: no window and no native module.
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*
import cjgui_shared_operation_core.*

/// The element binding of one accepted composite instance for a given role.
/// The old composite test's helpers are private to that file, so this file
/// keeps its own tiny equivalent instead of touching the existing tests.
private func reactiveRoleBinding(holder: CjguiGeneratedUiStructureHolder, key: String,
                                 role: String): CjguiCompositeElementBinding {
    for (binding in holder.compositeElementNodeIdsForKey(key)) {
        if (binding.role == role) {
            return binding
        }
    }
    return CjguiCompositeElementBinding("", "", -1, "", "")
}

private func reactiveFieldBinding(holder: CjguiGeneratedUiStructureHolder,
                                  key: String): CjguiCompositeElementBinding {
    return reactiveRoleBinding(holder, key, CJGUI_COMPOSITE_ELEMENT_FIELD)
}

private func reactiveActionBinding(holder: CjguiGeneratedUiStructureHolder,
                                   key: String): CjguiCompositeElementBinding {
    return reactiveRoleBinding(holder, key, CJGUI_COMPOSITE_ELEMENT_ACTION)
}

/// Provider whose projection can change without the structure changing: the
/// instance keeps resolving to the same owner while its draft, field
/// availability and action availability move.
private class ReactiveDataRefreshProvider <: CjguiGeneratedUiBindingProvider {
    let target: Int64
    var draftValue: String
    var booleanValue: ?Bool
    var fieldState: CjguiSharedAvailability
    var actionState: CjguiSharedAvailability

    init(target: Int64, draftValue: String) {
        this.target = target
        this.draftValue = draftValue
        this.booleanValue = None
        this.fieldState = CjguiSharedAvailability.allowed(target, 1)
        this.actionState = CjguiSharedAvailability.allowed(target, 1)
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return target }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 { return target }
    public func draftText(fieldId: String): String { return draftValue }
    public func draftText(fieldId: String, instanceKey: String): String { return draftValue }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return booleanValue }
    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool { return booleanValue }
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability { return fieldState }
    public func fieldAvailability(fieldId: String, instanceKey: String): CjguiSharedAvailability {
        return fieldState
    }
    public func actionAvailability(actionName: String): CjguiSharedAvailability { return actionState }
    public func actionAvailability(actionName: String, instanceKey: String): CjguiSharedAvailability {
        return actionState
    }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 { return target }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// Provider whose field owner target AND draft are resolved from the CURRENT
/// instance mapping, so a live mapping change would be visible in a rebuild if
/// the accepted binding were re-resolved instead of preserved.
private class ReactiveTargetDraftProvider <: CjguiGeneratedUiBindingProvider {
    let targets: HashMap<String, Int64>

    init(targets: HashMap<String, Int64>) {
        this.targets = targets
    }

    private func currentTarget(instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return currentTarget(instanceKey)
    }
    public func draftText(fieldId: String): String { return "" }
    public func draftText(fieldId: String, instanceKey: String): String {
        return "draft-of-${currentTarget(instanceKey)}"
    }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        return currentTarget(instanceKey)
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// Legacy provider: no per-instance action target (interface default -1) and
/// only the two/three-argument execution overloads. Its field owner target is
/// real, but that is field data, not an action owner declaration.
private class LegacyOwnerlessActionProvider <: CjguiGeneratedUiBindingProvider {
    let fieldOwner: Int64
    var threeArgumentCalls: Int64 = 0
    var twoArgumentCalls: Int64 = 0

    init(fieldOwner: Int64) {
        this.fieldOwner = fieldOwner
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return fieldOwner }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 { return fieldOwner }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        twoArgumentCalls += 1
        return CjguiGeneratedUiActionResult(true, "legacy_ownerless")
    }
    public func executeAction(actionName: String, nodeKey: String,
        instanceKey: String): CjguiGeneratedUiActionResult {
        threeArgumentCalls += 1
        return executeAction(actionName, nodeKey)
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// Provider that declares a real action owner target AND implements only the
/// three-argument execution overload, which follows the CURRENT instance
/// mapping. The five-argument default must refuse before that overload can run.
private class OwnerTargetOnlyLegacyProvider <: CjguiGeneratedUiBindingProvider {
    let targets: HashMap<String, Int64>
    var threeArgumentCalls: Int64 = 0
    var executed: ArrayList<String> = ArrayList<String>()

    init(targets: HashMap<String, Int64>) {
        this.targets = targets
    }

    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        return targets.get(instanceKey) ?? -1
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return executeAction(actionName, nodeKey, "")
    }
    public func executeAction(actionName: String, nodeKey: String,
        instanceKey: String): CjguiGeneratedUiActionResult {
        threeArgumentCalls += 1
        let target = targets.get(instanceKey) ?? -1
        if (target < 0) {
            return CjguiGeneratedUiActionResult(false, "unknown_instance")
        }
        executed.add("${instanceKey}:${target}:${actionName}")
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// An accepted rebuild for a value/error/availability update must keep the
/// accepted identity (so focus, held sessions and late events stay valid) and
/// only refresh the live projection from the SAME owner's provider data.
@Test
func compositeDataRefreshKeepsIdentityAndRefreshesProjection(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = ReactiveDataRefreshProvider(10, "draft-1")
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let version = holder.structureVersion()
    let beforeField = reactiveFieldBinding(holder, "cardA")
    let beforeAction = reactiveActionBinding(holder, "cardA")
    @Assert(beforeField.nodeId > 0, true)
    @Assert(beforeField.ownerTargetResourceId, 10)
    @Assert(beforeField.instanceOwnerTargetResourceId, 10)
    @Assert(beforeField.draftText, "draft-1")
    @Assert(beforeField.ownerAvailable, true)
    @Assert(beforeField.blockedReason, "")
    @Assert(beforeAction.nodeId > 0, true)
    @Assert(beforeAction.ownerTargetResourceId, 10)
    @Assert(beforeAction.actionEnabled, true)

    // Pure DATA refresh: the provider still resolves cardA to the accepted
    // owner 10, but the draft and both availability projections moved.
    provider.draftValue = "draft-2"
    provider.fieldState = CjguiSharedAvailability.blocked("field_locked_by_owner", 10, 2)
    provider.actionState = CjguiSharedAvailability.blocked("action_locked_by_owner", 10, 2)
    let rebuilt = holder.buildAccepted(provider)
    @Assert(rebuilt.nodeId > 0, true)

    let afterField = reactiveFieldBinding(holder, "cardA")
    let afterAction = reactiveActionBinding(holder, "cardA")
    // Identity stays exactly the accepted one.
    @Assert(afterField.nodeId, beforeField.nodeId)
    @Assert(afterField.instanceIncarnation, beforeField.instanceIncarnation)
    @Assert(afterField.ownerTargetResourceId, beforeField.ownerTargetResourceId)
    @Assert(afterField.instanceOwnerTargetResourceId, beforeField.instanceOwnerTargetResourceId)
    @Assert(afterField.fieldId, beforeField.fieldId)
    @Assert(afterField.argumentName, beforeField.argumentName)
    @Assert(afterField.writerOperation, beforeField.writerOperation)
    // ... while the projection is the provider's CURRENT answer.
    @Assert(afterField.draftText, "draft-2")
    @Assert(afterField.ownerAvailable, false)
    @Assert(afterField.blockedReason, "field_locked_by_owner")
    @Assert(afterAction.nodeId, beforeAction.nodeId)
    @Assert(afterAction.instanceIncarnation, beforeAction.instanceIncarnation)
    @Assert(afterAction.ownerTargetResourceId, beforeAction.ownerTargetResourceId)
    @Assert(afterAction.actionName, beforeAction.actionName)
    @Assert(afterAction.actionEnabled, false)
    @Assert(afterAction.blockedReason, "action_locked_by_owner")
    // A data refresh must not advance the accepted structure version.
    @Assert(holder.structureVersion(), version)
}

/// A rejected candidate must not consume or auto-follow the provider's new
/// mapping: the accepted fallback rebuild keeps owner 10, its generation and
/// its DATA, and owner 30 never becomes an accepted instance key.
@Test
func compositeFailedCandidateKeepsAcceptedOwnerNotAutoRebound(): Unit {
    let catalog = compositeCatalog()
    let factory = CompositeTestFactory()
    @Assert(catalog.registerComposite(compositeSpec("integerEdit"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    let provider = ReactiveTargetDraftProvider(targets)
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "integerEdit")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let before = reactiveFieldBinding(holder, "cardA")
    @Assert(before.ownerTargetResourceId, 10)
    @Assert(before.draftText, "draft-of-10")
    @Assert(holder.compositeInstanceKeyForOwnerTarget(10), "cardA")

    // The live mapping moves to 30 and the candidate expansion fails. The
    // accepted fallback rebuild must carry the ACCEPTED binding, not resolve
    // the provider's new mapping (which would yield owner 30 / draft-of-30).
    targets.add("cardA", 30)
    // The provider's LIVE data has already moved; only the accepted scene has
    // not, so a rebuild that resolved it would show draft-of-30 / owner 30.
    @Assert(provider.draftText("retentionCount", "cardA"), "draft-of-30")
    factory.extraNodesOnce = 1
    let buildsBefore = factory.buildCount
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    // Candidate build + accepted fallback rebuild: the accepted scene was
    // really rebuilt, and that rebuild still carries the accepted binding.
    @Assert(factory.buildCount, buildsBefore + 2)
    @Assert(holder.structureVersion(), 1)

    let after = reactiveFieldBinding(holder, "cardA")
    @Assert(after.ownerTargetResourceId, 10)
    @Assert(after.instanceOwnerTargetResourceId, 10)
    @Assert(after.instanceIncarnation, before.instanceIncarnation)
    @Assert(after.draftText, "draft-of-10")
    @Assert(after.ownerAvailable, true)
    @Assert(holder.compositeOwnerTargetForInstance("cardA"), 10)
    @Assert(holder.compositeInstanceKeyForOwnerTarget(10), "cardA")
    @Assert(holder.compositeInstanceKeyForOwnerTarget(30), "")
}

/// Legacy single-owner compatibility: a provider with no per-instance action
/// target (the interface default is -1) and no five-argument overload keeps the
/// old delegation chain instead of being refused.
@Test
func legacyProviderWithoutOwnerTargetKeepsFiveArgumentCompatibility(): Unit {
    let concrete = LegacyOwnerlessActionProvider(10)
    // The framework holds providers through the interface, so the default
    // methods are exercised on that static type.
    let provider: CjguiGeneratedUiBindingProvider = concrete
    // The default really is the owner-less one: no per-instance action target.
    @Assert(provider.actionOperationResourceId("APPLY_DRAFT", "cardA"), -1)
    // The field owner is real; only the ACTION owner declaration is absent.
    @Assert(provider.fieldOperationResourceId("retentionCount", "cardA"), 10)
    let result = provider.executeAction("APPLY_DRAFT", "node", "cardA", -1, 0)
    @Assert(result.applied, true)
    @Assert(result.reason == CJGUI_GENERATED_ACTION_OWNER_TARGET_UNSUPPORTED, false)
    @Assert(result.reason, "legacy_ownerless")
    // Five-argument -> three-argument -> two-argument, as before the fix.
    @Assert(concrete.threeArgumentCalls, 1)
    @Assert(concrete.twoArgumentCalls, 1)
}

/// A provider that declares a real action owner target but only implements the
/// older overloads must be refused by name. Refusing happens BEFORE any
/// delegation, so a moved instance mapping can never be silently followed.
@Test
func legacyProviderWithOwnerTargetRefusesInsteadOfFollowingMapping(): Unit {
    let targets = HashMap<String, Int64>()
    targets.add("cardA", 10)
    let concrete = OwnerTargetOnlyLegacyProvider(targets)
    let provider: CjguiGeneratedUiBindingProvider = concrete
    @Assert(provider.actionOperationResourceId("APPLY_DRAFT", "cardA"), 10)

    let first = provider.executeAction("APPLY_DRAFT", "node", "cardA", 10, 0)
    @Assert(first.applied, false)
    @Assert(first.reason == CJGUI_GENERATED_ACTION_OWNER_TARGET_UNSUPPORTED, true)
    @Assert(first.reason, "instance_owner_target_requires_five_argument_execute")
    @Assert(concrete.threeArgumentCalls, 0)
    @Assert(concrete.executed.size, 0)

    // The mapping moves to 30 but the accepted scene did not. The same
    // accepted target (10) must still be refused by name: no silent execution
    // against the newly mapped object 30.
    targets.add("cardA", 30)
    @Assert(provider.actionOperationResourceId("APPLY_DRAFT", "cardA"), 30)
    let second = provider.executeAction("APPLY_DRAFT", "node", "cardA", 10, 0)
    @Assert(second.applied, false)
    @Assert(second.reason == CJGUI_GENERATED_ACTION_OWNER_TARGET_UNSUPPORTED, true)
    @Assert(second.reason, "instance_owner_target_requires_five_argument_execute")
    @Assert(concrete.threeArgumentCalls, 0)
    @Assert(concrete.executed.size, 0)
}

// ---------------------------------------------------------------------------
// ONE frozen snapshot per composite instance
//
// The reader of a composite (a card, a row, any multi-object component) gets
// draft values, field errors, availability, blocking reasons and owner status
// from ONE sample of its owner. These tests pin the two projections that used to
// escape that rule and the audit that must stop a factory from painting over the
// owner's own answer.
// ---------------------------------------------------------------------------

/// A provider that publishes PER-INSTANCE feedback whose draft boolean, error,
/// availability and status can move independently of its legacy single-owner
/// values. The legacy calls deliberately return the OPPOSITE draft boolean, so a
/// projection that reads them instead of the frozen snapshot is visible.
private class ReactiveSnapshotProvider <: CjguiGeneratedUiBindingProvider {
    var feedbackValue: ?CjguiGeneratedUiFormFeedback = None
    var legacyBoolean: Bool = false

    init() {}

    public func formFeedback(instanceKey: String): ?CjguiGeneratedUiFormFeedback { return feedbackValue }
    public func fieldResourceId(fieldId: String): Int64 { return 81003 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 10 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 { return 10 }
    public func draftText(fieldId: String): String { return "legacy-draft" }
    public func draftText(fieldId: String, instanceKey: String): String { return "legacy-draft" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return legacyBoolean }
    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool { return legacyBoolean }
    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 { return 10 }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// The one snapshot every projection in these tests is resolved from.
private func reactiveSnapshotFeedback(owner: Int64, booleanDraft: String, copiesDraft: String,
    copiesError: String, nameError: String, status: String, fieldAvailable: Bool,
    fieldReason: String, actionAvailable: Bool, actionReason: String,
    contextVersion: Int64): CjguiGeneratedUiFormFeedback {
    let descriptors = ArrayList<CjguiSharedFormFieldDescriptor>()
    descriptors.add(CjguiSharedFormFieldDescriptor(81003, "retentionCount", "保留天数", "INTEGER"))
    descriptors.add(CjguiSharedFormFieldDescriptor(81007, "enabledFlag", "启用", "BOOLEAN"))
    let declarations = CjguiSharedFormBinding(descriptors)
    let fields = ArrayList<CjguiSharedFormFieldProjection>()
    fields.add(CjguiSharedFormFieldProjection(81003, "retentionCount",
        CjguiSharedOperationValue.integer(3), copiesDraft, copiesError, 1, false, 0, 0))
    fields.add(CjguiSharedFormFieldProjection(81007, "enabledFlag",
        CjguiSharedOperationValue.boolean(false), booleanDraft, nameError, 1, false, 0, 0))
    let snapshot = CjguiSharedFormSnapshot(contextVersion, 1, 2, 1, fields, copiesError.isEmpty(), status)
    let fieldStates = HashMap<String, CjguiSharedAvailability>()
    fieldStates.add("retentionCount", if (fieldAvailable) {
        CjguiSharedAvailability.allowed(owner, contextVersion)
    } else {
        CjguiSharedAvailability.blocked(fieldReason, owner, contextVersion)
    })
    fieldStates.add("enabledFlag", CjguiSharedAvailability.allowed(owner, contextVersion))
    let actionStates = HashMap<String, CjguiSharedAvailability>()
    actionStates.add("APPLY_DRAFT", if (actionAvailable) {
        CjguiSharedAvailability.allowed(owner, contextVersion)
    } else {
        CjguiSharedAvailability.blocked(actionReason, owner, contextVersion)
    })
    return CjguiGeneratedUiFormFeedback(snapshot, declarations, owner, fieldStates, actionStates)
}

/// Factory over a composite with one INTEGER field, one BOOLEAN field, two
/// projections and one action. The negative knobs make the two audit refusals
/// reachable without a second factory.
private class ReactiveSnapshotFactory <: CjguiCompositeComponentFactory {
    var ignoreOwnerAvailability: Bool = false
    var rewriteProjection: Bool = false

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let box = cjguiComposableVertical(root.nodeId, root.semanticId, CjguiComposableUiStyle(gap: 2))
        if (let Some(field) <- context.element("edit")) {
            let enabled = if (ignoreOwnerAvailability) { true } else { field.ownerAvailable }
            box.add(cjguiComposableIntegerInput(field.nodeId, field.semanticId, field.label, field.draftText,
                field.bindingResourceId, CjguiComposableUiStyle(fixedHeight: 26), enabled: enabled,
                fieldId: field.fieldId, operationActionName: field.writerOperation,
                operationResourceId: field.ownerTargetResourceId, displayValueRole: "draft"))
        }
        if (let Some(field) <- context.element("flag")) {
            box.add(cjguiComposableBooleanInput(field.nodeId, field.semanticId, field.label, field.draftBoolean,
                field.bindingResourceId, CjguiComposableUiStyle(fixedHeight: 26),
                enabled: if (ignoreOwnerAvailability) { true } else { field.ownerAvailable },
                fieldId: field.fieldId, operationActionName: field.writerOperation,
                operationResourceId: field.ownerTargetResourceId, displayValueRole: "draft"))
        }
        for (key in ["editError", "flagError", "editReason"]) {
            if (let Some(projection) <- context.element(key)) {
                let text = if (rewriteProjection) { "rewritten-by-factory" } else { projection.projectionText }
                box.add(cjguiComposableText(projection.nodeId, projection.semanticId, text,
                    CjguiComposableUiStyle(fontSize: 11.0)))
            }
        }
        if (let Some(projection) <- context.element("status")) {
            let text = if (rewriteProjection) { "rewritten-by-factory" } else { projection.projectionText }
            box.add(
                cjguiComposableText(projection.nodeId, projection.semanticId, text,
                    CjguiComposableUiStyle(fontSize: 11.0)))
        }
        if (let Some(action) <- context.element("apply")) {
            box.add(cjguiComposableButton(action.nodeId, action.semanticId, action.label, "GENERATED_ACTION",
                action.ownerTargetResourceId, CjguiComposableUiStyle(fixedHeight: 26),
                enabled: action.actionEnabled, operationResourceId: action.ownerTargetResourceId))
        }
        return box
    }
}

private func reactiveSnapshotSpec(kind: String): CjguiCompositeComponentSpec {
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD, fieldId: "retentionCount",
        argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("flag", CJGUI_COMPOSITE_ELEMENT_FIELD, fieldId: "enabledFlag",
        argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("editError", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        fieldId: "retentionCount", source: CJGUI_COMPOSITE_PROJECTION_FIELD_ERROR, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("flagError", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        fieldId: "enabledFlag", source: CJGUI_COMPOSITE_PROJECTION_FIELD_ERROR, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("editReason", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        fieldId: "retentionCount", source: CJGUI_COMPOSITE_PROJECTION_FIELD_REASON, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("status", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        source: CJGUI_COMPOSITE_PROJECTION_OWNER_STATUS, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "APPLY_DRAFT", label: "应用", parentKey: "root"))
    return CjguiCompositeComponentSpec(kind, ArrayList<CjguiGeneratedUiPropertySpec>(), elements,
        expandedNodeLimit: 16)
}

private func reactiveSnapshotCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = compositeCatalog()
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("enabledFlag", "启用", "BOOLEAN", 81007))
    return catalog
}

private func reactiveProjectionText(holder: CjguiGeneratedUiStructureHolder, key: String,
                                    elementKey: String): String {
    for (binding in holder.compositeElementNodeIdsForKey(key)) {
        if (binding.elementKey == elementKey && binding.role == CJGUI_COMPOSITE_ELEMENT_PROJECTION) {
            return binding.projectionText
        }
    }
    return "<missing>"
}

private func reactiveBooleanBinding(holder: CjguiGeneratedUiStructureHolder,
                                    key: String): CjguiCompositeElementBinding {
    for (binding in holder.compositeElementNodeIdsForKey(key)) {
        if (binding.fieldId == "enabledFlag" && binding.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
            return binding
        }
    }
    return CjguiCompositeElementBinding("", "", -1, "", "")
}

/// The reason a candidate scene was refused, from its own attempt record.
private func reactiveCandidateReason(holder: CjguiGeneratedUiStructureHolder, token: Int64): String {
    return match (holder.candidateRecord(token)) {
        case Some(value) => value.reason()
        case None => "<no-record>"
    }
}

/// Finds one mounted node by its framework identity, so a test can assert what
/// the REAL control carries rather than only the binding record.
private func reactiveFindNode(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) { return Some(node) }
    for (child in node.children()) {
        if (let Some(hit) <- reactiveFindNode(child, nodeId)) { return Some(hit) }
    }
    return None
}

@Test
func compositeBooleanPrefersTheFrozenInstanceSnapshot(): Unit {
    let catalog = reactiveSnapshotCatalog()
    let factory = ReactiveSnapshotFactory()
    @Assert(catalog.registerComposite(reactiveSnapshotSpec("snapshotCard"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = ReactiveSnapshotProvider()
    // FIRST build: the live provider and the frozen snapshot DISAGREE (live=true,
    // snapshot=false). The mounted checkbox must show the frozen value.
    provider.legacyBoolean = true
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "false", "4", "", "", "卡片", true, "",
        true, "", 5))
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "snapshotCard")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let version = holder.structureVersion()
    var booleanNodeId: Int64 = -1
    for (binding in holder.compositeElementNodeIdsForKey("cardA")) {
        if (binding.fieldId == "enabledFlag" && binding.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
            booleanNodeId = binding.nodeId
        }
    }
    @Assert(booleanNodeId > 0, true)
    @Assert(reactiveBooleanBinding(holder, "cardA").draftBoolean, false)
    let firstScene = holder.buildAccepted(provider)
    @Assert(reactiveFindNode(firstScene, booleanNodeId).getOrThrow().value, "false")

    // DATA refresh: the sides now disagree the OTHER way (live=false,
    // snapshot=true). Only the frozen snapshot may drive the refreshed control;
    // identity and structure version stay put.
    provider.legacyBoolean = false
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "true", "5", "", "", "卡片", true, "",
        true, "", 6))
    let refreshed = holder.buildAccepted(provider)
    @Assert(refreshed.nodeId > 0, true)
    @Assert(reactiveBooleanBinding(holder, "cardA").draftBoolean, true)
    @Assert(reactiveFindNode(refreshed, booleanNodeId).getOrThrow().value, "true")
    @Assert(reactiveBooleanBinding(holder, "cardA").nodeId, booleanNodeId)
    @Assert(holder.structureVersion(), version)

    // And back: a second refresh with live=true / snapshot=false must follow the
    // snapshot again, so neither side can win by being the live provider.
    provider.legacyBoolean = true
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "false", "6", "", "", "卡片", true, "",
        true, "", 7))
    let refreshedAgain = holder.buildAccepted(provider)
    @Assert(reactiveBooleanBinding(holder, "cardA").draftBoolean, false)
    @Assert(reactiveFindNode(refreshedAgain, booleanNodeId).getOrThrow().value, "false")
    @Assert(holder.structureVersion(), version)
}

@Test
func compositeProjectionTextIsFrozenRefreshedAndIdentityStable(): Unit {
    let catalog = reactiveSnapshotCatalog()
    let factory = ReactiveSnapshotFactory()
    @Assert(catalog.registerComposite(reactiveSnapshotSpec("snapshotCard"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = ReactiveSnapshotProvider()
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "true", "99", "份数超出范围", "名称无效",
        "卡片 A", true, "", false, "草稿无效", 5))
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "snapshotCard")]))
    @Assert(holder.submit(structure, provider).candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    let version = holder.structureVersion()
    let nodeBefore = reactiveProjectionText(holder, "cardA", "editError")
    @Assert(nodeBefore, "份数超出范围")
    @Assert(reactiveProjectionText(holder, "cardA", "flagError"), "名称无效")
    @Assert(reactiveProjectionText(holder, "cardA", "editReason"), "")
    @Assert(reactiveProjectionText(holder, "cardA", "status"), "卡片 A")
    var projectionNodeId: Int64 = -1
    for (binding in holder.compositeElementNodeIdsForKey("cardA")) {
        if (binding.elementKey == "editError") {
            projectionNodeId = binding.nodeId
        }
    }
    @Assert(projectionNodeId > 0, true)

    // Lock the owner: the SAME projection element now publishes the owner's
    // reason, the error is gone and the action is blocked. No structure resubmit.
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "true", "99", "", "",
        "份数超出范围", false, "预设已锁定，暂不可编辑", false, "预设已锁定，暂不可编辑", 6))
    let rebuilt = holder.buildAccepted(provider)
    @Assert(rebuilt.nodeId > 0, true)
    @Assert(reactiveProjectionText(holder, "cardA", "editError"), "")
    @Assert(reactiveProjectionText(holder, "cardA", "flagError"), "")
    @Assert(reactiveProjectionText(holder, "cardA", "editReason"), "预设已锁定，暂不可编辑")
    @Assert(reactiveProjectionText(holder, "cardA", "status"), "份数超出范围")
    var projectionNodeAfter: Int64 = -1
    for (binding in holder.compositeElementNodeIdsForKey("cardA")) {
        if (binding.elementKey == "editError") {
            projectionNodeAfter = binding.nodeId
        }
    }
    @Assert(projectionNodeAfter, projectionNodeId)
    @Assert(reactiveFieldBinding(holder, "cardA").ownerAvailable, false)
    @Assert(reactiveActionBinding(holder, "cardA").actionEnabled, false)
    @Assert(holder.structureVersion(), version)
}

@Test
func compositeFactoryCannotMountAnEditableControlForABlockedField(): Unit {
    let catalog = reactiveSnapshotCatalog()
    let factory = ReactiveSnapshotFactory()
    factory.ignoreOwnerAvailability = true
    @Assert(catalog.registerComposite(reactiveSnapshotSpec("snapshotCard"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = ReactiveSnapshotProvider()
    // The owner blocks the INTEGER field while the factory still mounts an
    // ENABLED editor: the accepted control would promise a write the owner
    // refuses, so the expansion is refused by name instead of shown as editable.
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "true", "4", "", "", "卡片", false,
        "预设已锁定，暂不可编辑", true, "", 5))
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "snapshotCard")]))
    let submitted = holder.submit(structure, provider)
    // The description itself is legal; the REAL expanded scene must refuse an
    // enabled editor for a field the owner has blocked.
    @Assert(submitted.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(reactiveCandidateReason(holder, submitted.candidateToken), "composite_element_availability_mismatch")
}

@Test
func compositeProjectionNodeMustCarryTheResolvedOwnerText(): Unit {
    let catalog = reactiveSnapshotCatalog()
    let factory = ReactiveSnapshotFactory()
    factory.rewriteProjection = true
    @Assert(catalog.registerComposite(reactiveSnapshotSpec("snapshotCard"), factory), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = ReactiveSnapshotProvider()
    provider.feedbackValue = Some(reactiveSnapshotFeedback(10, "true", "99", "份数超出范围", "", "卡片 A",
        true, "", true, "", 5))
    let structure = CjguiGeneratedUiNodeSpec("panel", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("cardA", "snapshotCard")]))
    // The projection is the OWNER's text; a factory may place and paint it, never
    // re-word it.
    let submitted = holder.submit(structure, provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), false)
    @Assert(reactiveCandidateReason(holder, submitted.candidateToken), "composite_element_projection_mismatch")
}

@Test
func compositeProjectionRegistrationRefusesAnUnknownSource(): Unit {
    let catalog = reactiveSnapshotCatalog()
    let factory = ReactiveSnapshotFactory()
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("status", CJGUI_COMPOSITE_ELEMENT_PROJECTION, source: "invented"))
    @Assert(catalog.registerComposite(
        CjguiCompositeComponentSpec("inventedCard", ArrayList<CjguiGeneratedUiPropertySpec>(), elements),
        factory), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_unknown_projection_source"), true)
    // A projection that smuggles a writer is refused too: it may never write.
    let writing = ArrayList<CjguiCompositeElementSpec>()
    writing.add(CjguiCompositeElementSpec("status", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        source: CJGUI_COMPOSITE_PROJECTION_OWNER_STATUS, fieldId: "retentionCount"))
    @Assert(catalog.registerComposite(
        CjguiCompositeComponentSpec("writingCard", ArrayList<CjguiGeneratedUiPropertySpec>(), writing), factory),
        false)
    @Assert(catalog.lastRegistrationRejection().startsWith("composite_projection_status_binding"), true)
    // The discovery line publishes the source so an external caller can compose
    // an instance from the description alone.
    @Assert(catalog.registerComposite(reactiveSnapshotSpec("publishedCard"), factory), true)
    @Assert(CjguiGeneratedUiEncoding.describe(catalog).contains(
        "ELEMENT publishedCard editError projection parent=root field=retentionCount argument=none " +
        "preset=none action=none source=field_error label=\n"), true)
}

