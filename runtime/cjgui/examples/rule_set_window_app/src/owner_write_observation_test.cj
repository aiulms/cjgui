package cjgui_rule_set_window_app
import cjgui_rule_set_application.*
import cjgui.*
import cjgui_shared_operation_core.*
import std.unittest.*
import std.unittest.testmacro.*
@Test
func rulesOwnerVersionObservationsDoNotEstablishTheContinuationContract(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("owner-text", true, 7, "tmp", "create-proof").applied, true)
    let owner = domain.selectedRecordId()
    let label = CjguiRuleSetEditingDomain.formLabelResourceId
    let retention = CjguiRuleSetEditingDomain.formRetentionResourceId
    let initial = domain.formSnapshotForRecord(owner).getOrThrow()
    let observer = RuleSetOwnerWriteObservation()
    let declared = cjguiComposableTextInput(1, "owner-clock-probe", "label", "owner-text", label,
        CjguiComposableUiStyle(), fieldId: "label", operationActionName: "EDIT_DRAFT_TEXT",
        operationResourceId: owner, displayValueRole: "draft")
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let event = CjguiComposableUiEvent(CjguiComposableUiLayoutNode(declared, bounds, bounds),
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "owner-text", 2, 3, 1)
    let observed = observer.begin(domain, owner, label)
    let same = domain.editTextForCollectionItemFromHuman(owner, label, "owner-text", 2, 3)
    observer.finish(observed, event, owner, label, same, domain)
    @Assert(same.applied, true)
    @Assert(same.reason, "already_at_target")
    let afterSame = domain.formSnapshotForRecord(owner).getOrThrow()
    @Assert(afterSame.contextVersion, initial.contextVersion)
    @Assert(afterSame.draftVersion, initial.draftVersion)
    @Assert(afterSame.fieldForResourceId(label).selectionStart, 2)
    @Assert(afterSame.fieldForResourceId(label).selectionEnd, 3)
    @Assert(domain.editTextForCollectionItemFromHuman(owner, label, "changed-owner", 13, 13).applied, true)
    let changed = domain.formSnapshotForRecord(owner).getOrThrow()
    @Assert(changed.contextVersion, initial.contextVersion + 1)
    // Public field basis is FORM-wide here, not the private per-field counter.
    @Assert(changed.fieldForResourceId(retention).draftFieldVersion, changed.draftVersion)
    @Assert(changed.fieldForResourceId(retention).draftText, initial.fieldForResourceId(retention).draftText)
    @Assert(domain.editTextForCollectionItemFromHuman(owner, retention, "invalid", 7, 7).applied, true)
    let invalid = domain.formSnapshotForRecord(owner).getOrThrow()
    let refused = domain.applyDraftForCollectionItemFromHuman(owner, invalid.draftVersion, invalid.baseAppliedConfigVersion)
    @Assert(refused.applied, false)
    let afterRefusal = domain.formSnapshotForRecord(owner).getOrThrow()
    @Assert(afterRefusal.contextVersion > invalid.contextVersion, true)
    @Assert(afterRefusal.draftVersion > invalid.draftVersion, true)
}

@Test
func rulesOwnerUnknownResolvedKeyNeverFallsBackToSelected(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("original-owner", true, 7, "tmp", "create-route").applied, true)
    let owner = domain.selectedRecordId()
    let region = CjguiRuleSetGeneratedRegion(domain)
    let intent = CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, "label", "",
        fieldId: "label", writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: owner,
        argumentName: "text", value: CjguiSharedOperationValue.string("must-not-write"),
        instanceKey: "unknown-nonrule-key")
    @Assert(intent.isFieldEdit(), true)
    @Assert(region.fieldResourceId("label"), CjguiRuleSetEditingDomain.formLabelResourceId)
    let declared = cjguiComposableTextInput(1, "owner-route-probe", "label", "original-owner",
        CjguiRuleSetEditingDomain.formLabelResourceId, CjguiComposableUiStyle(), fieldId: "label",
        operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: owner, displayValueRole: "draft")
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let event = CjguiComposableUiEvent(CjguiComposableUiLayoutNode(declared, bounds, bounds),
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "must-not-write", 0, 0, 1)
    let before = domain.formSnapshotForRecord(owner).getOrThrow()
    let result = region.dispatchResolvedFieldIntent(intent, event)
    let after = domain.formSnapshotForRecord(owner).getOrThrow()
    println("unknown_key_post_route owner=${owner} applied=${result.didApply} before=${before.contextVersion} after=${after.contextVersion} label=${after.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText}")
    @Assert(result.didApply, false)
    @Assert(after.contextVersion, before.contextVersion)
    @Assert(after.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "original-owner")
}

@Test
func rulesOwnerNormalDifferentOwnerMismatchAndRetirementKeepOriginalBindingGuards(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("owner-A", true, 7, "tmp", "create-A").applied, true)
    let a = domain.selectedRecordId()
    @Assert(domain.createRecordFromHuman("owner-B", true, 7, "tmp", "create-B").applied, true)
    let b = domain.selectedRecordId()
    let region = CjguiRuleSetGeneratedRegion(domain)
    let declared = cjguiComposableTextInput(2, "owner-legitimate-probe", "label", "owner-A",
        CjguiRuleSetEditingDomain.formLabelResourceId, CjguiComposableUiStyle(), fieldId: "label",
        operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: a, displayValueRole: "draft")
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let event = CjguiComposableUiEvent(CjguiComposableUiLayoutNode(declared, bounds, bounds),
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "A-edited", 0, 0, 1)
    let legal = CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, "label", "",
        fieldId: "label", writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: a,
        argumentName: "text", value: CjguiSharedOperationValue.string("A-edited"), instanceKey: "rule${a}")
    @Assert(region.dispatchResolvedFieldIntent(legal, event).didApply, true)
    @Assert(domain.selectedRecordId(), b)
    @Assert(domain.formSnapshotForRecord(a).getOrThrow().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "A-edited")
    @Assert(domain.formSnapshotForRecord(b).getOrThrow().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "owner-B")
    let beforeMismatch = domain.version()
    let mismatch = CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, "label", "",
        fieldId: "label", writerOperation: "EDIT_DRAFT_TEXT", ownerTargetResourceId: b,
        argumentName: "text", value: CjguiSharedOperationValue.string("must-not-redirect"), instanceKey: "rule${a}")
    @Assert(region.dispatchResolvedFieldIntent(mismatch, event).didApply, false)
    @Assert(domain.version(), beforeMismatch)
    @Assert(domain.selectRecordFromHuman(a).applied, true)
    // Respect the existing delete_conflicts_with_draft guard: cancel the
    // test-owned draft through the real business command before retirement.
    @Assert(domain.cancelDraftForCollectionItemFromHuman(a,
        domain.draftVersionForCollectionItem(a), domain.baseAppliedVersionForCollectionItem(a)).applied, true)
    @Assert(domain.deleteSelectedCollectionItemFromHuman().applied, true)
    let beforeRetired = domain.version()
    @Assert(region.dispatchResolvedFieldIntent(legal, event).didApply, false)
    @Assert(domain.version(), beforeRetired)
    @Assert(domain.formSnapshotForRecord(a).isNone(), true)
    @Assert(domain.formSnapshotForRecord(b).getOrThrow().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "owner-B")
}
