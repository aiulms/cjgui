package cjgui_rule_set_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func recordsKeepStableIdsAndDraftsAcrossSelectionUndoAndRedo(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var lastCreatedId: Int64 = -1
    var index: Int64 = 0
    while (index < 100) {
        let created = domain.createRecordFromHuman("规则-${index}", true, 7, "cache", "human-create-${index}")
        @Assert(created.applied, true)
        lastCreatedId = domain.selectedRecordId()
        index += 1
    }
    @Assert(domain.snapshot().records.size, 100)
    @Assert(lastCreatedId > 0, true)

    @Assert(domain.selectRecordFromHuman(lastCreatedId).applied, true)
    @Assert(domain.editSelectedLabelFromHuman("屏幕外草稿", 5, 5).applied, true)
    let draftVersion = domain.selectedDraftVersion()
    @Assert(domain.selectRecordFromHuman(1).applied, true)
    @Assert(domain.selectRecordFromHuman(lastCreatedId).applied, true)
    @Assert(domain.selectedFormSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "屏幕外草稿")
    @Assert(domain.applySelectedDraftFromHuman(draftVersion).applied, true)
    @Assert(domain.snapshot().recordById(lastCreatedId).label, "屏幕外草稿")

    @Assert(domain.undoFromHuman().applied, true)
    @Assert(domain.snapshot().recordById(lastCreatedId).label, "规则-99")
    @Assert(domain.redoFromHuman().applied, true)
    @Assert(domain.snapshot().recordById(lastCreatedId).label, "屏幕外草稿")
}

@Test
func queuedDetailIntentKeepsItsOriginalRecordWhenSelectionChanges(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("记录A", true, 7, "cache", "create-a").applied, true)
    let recordA = domain.selectedRecordId()
    @Assert(domain.createRecordFromHuman("记录B", true, 7, "cache", "create-b").applied, true)
    let recordB = domain.selectedRecordId()
    @Assert(domain.editTextForCollectionItemFromHuman(recordA, CjguiRuleSetEditingDomain.formLabelResourceId, "A的队列草稿", 6, 6).applied, true)
    let draftA = domain.draftVersionForCollectionItem(recordA)
    let baseA = domain.baseAppliedVersionForCollectionItem(recordA)
    @Assert(domain.selectRecordFromHuman(recordB).applied, true)
    @Assert(domain.applyDraftForCollectionItemFromHuman(recordA, draftA, baseA).applied, true)
    @Assert(domain.snapshot().recordById(recordA).label, "A的队列草稿")
    @Assert(domain.snapshot().recordById(recordB).label, "记录B")
}

@Test
func saveLoadAndExternalFileConflictPreserveTheLastKnownGoodRuleSet(): Unit {
    let directory = Directory.createTemp("/tmp")
    let ruleSetPath = directory.join("rules.cjgui-rules").toString()
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("规则甲", true, 21, "logs", "create-1").applied, true)
    let stableId = domain.selectedRecordId()
    @Assert(domain.saveAsFromHuman(ruleSetPath).applied, true)
    @Assert(exists(ruleSetPath), true)

    let draftPath = directory.join("draft-rules.cjgui-rules").toString()
    let draftDomain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(draftDomain.createRecordFromHuman("待决定草稿", true, 14, "tmp", "draft-create").applied, true)
    @Assert(draftDomain.saveAsFromHuman(draftPath).applied, true)
    @Assert(draftDomain.editSelectedLabelFromHuman("本地未保存", 5, 5).applied, true)
    let requiresDraftDecision = draftDomain.saveFromHuman()
    @Assert(requiresDraftDecision.applied, false)
    @Assert(requiresDraftDecision.reason, "unapplied_drafts_require_apply_or_cancel")
    @Assert(draftDomain.applySelectedDraftFromHuman(draftDomain.selectedDraftVersion()).applied, true)
    File.writeTo(Path(draftPath), "CJGUI_RULE_SET 1\nEXTERNAL\n".toArray())
    let conflict = draftDomain.saveFromHuman()
    @Assert(conflict.applied, false)
    @Assert(conflict.reason, "external_file_conflict")
    @Assert(String.fromUtf8(File.readFrom(draftPath)), "CJGUI_RULE_SET 1\nEXTERNAL\n")

    let reopened = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(reopened.openFromHuman(ruleSetPath).applied, true)
    @Assert(reopened.snapshot().recordById(stableId).label, "规则甲")

    File.writeTo(Path(ruleSetPath), "CJGUI_RULE_SET 1\nTRUNCATED\n".toArray())
    let beforeFailure = reopened.snapshot().recordById(stableId).label
    @Assert(reopened.openFromHuman(ruleSetPath).applied, false)
    @Assert(reopened.snapshot().recordById(stableId).label, beforeFailure)

    let _ = removeIfExists(directory, recursive: true)
}

@Test
func twoIndependentRuleSetInstancesCoordinateSaveLeaseThenDetectWinnerPayload(): Unit {
    let directory = Directory.createTemp("/tmp")
    let ruleSetPath = directory.join("two-instance.cjgui-rules").toString()
    let first = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(first.createRecordFromHuman("第一个实例", true, 14, "logs", "first-create").applied, true)
    @Assert(first.saveAsFromHuman(ruleSetPath).applied, true)

    let second = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(second.openFromHuman(ruleSetPath).applied, true)
    // This is the same atomic lease path held by a live first instance from
    // acquisition through rename. The second independently loaded domain
    // must fail closed rather than entering the former TOCTOU sequence.
    let leasePath = Path("${ruleSetPath}.cjgui-save-lock")
    Directory.create(leasePath, recursive: false)
    let blocked = second.saveFromHuman()
    @Assert(blocked.applied, false)
    @Assert(blocked.reason, "save_in_progress")
    @Assert(removeIfExists(leasePath, recursive: true), true)

    @Assert(first.createRecordFromHuman("第一实例提交", true, 21, "cache", "first-winner").applied, true)
    @Assert(first.saveFromHuman().applied, true)
    @Assert(second.createRecordFromHuman("第二实例草稿", true, 28, "tmp", "second-local").applied, true)
    let stale = second.saveFromHuman()
    @Assert(stale.applied, false)
    @Assert(stale.reason, "external_file_conflict")
    @Assert(removeIfExists(directory, recursive: true), true)
}

@Test
func externalCreateIsIdempotentAndChangesRequireResyncAfterHistoryExpires(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let initialVersion = domain.snapshot().version
    let first = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        initialVersion, "Agent 规则", true, 14, "tmp", "agent-request-1"
    ))
    @Assert(first.applied, true)
    let retry = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        initialVersion, "Agent 规则", true, 14, "tmp", "agent-request-1"
    ))
    @Assert(retry.applied, true)
    @Assert(retry.reason, "already_applied_request")
    @Assert(domain.snapshot().records.size, 1)

    let changes = domain.changesSince(initialVersion, ArrayList<Int64>())
    @Assert(changes.requiresResync, false)
    @Assert(changes.entries.size, 1)
    @Assert(changes.entries[0].resourceId, domain.selectedRecordId())

    var index: Int64 = 0
    while (index < 80) {
        @Assert(domain.createRecordFromHuman("历史-${index}", true, 7, "cache", "history-${index}").applied, true)
        index += 1
    }
    @Assert(domain.changesSince(initialVersion, ArrayList<Int64>()).requiresResync, true)
}

@Test
func formFocusAndRenameKeepAnUnrelatedSelectedDraftOnItsAppliedRevision(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("焦点规则", true, 7, "cache", "focus-create").applied, true)
    @Assert(domain.editTextFromHuman(CjguiRuleSetEditingDomain.formRetentionResourceId, "30", 2, 2).applied, true)
    let form = domain.formSnapshot()
    @Assert(form.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).isFocused, false)
    @Assert(form.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).isFocused, true)

    let selectedId = domain.selectedRecordId()
    let renamed = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "RENAME_RECORD", domain.snapshot().version, ArrayList<Int64>([selectedId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string("已重命名规则")),
            CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string("rename-1"))
        ])
    ))
    @Assert(renamed.applied, true)
    let afterRename = domain.formSnapshot()
    @Assert(afterRename.baseAppliedConfigVersion, afterRename.appliedConfigVersion)
    @Assert(afterRename.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "30")
}

@Test
func batchEnabledPreservesAnUnrelatedHumanDraftOnTheSameRecord(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("待批改", false, 7, "cache", "human-batch-create").applied, true)
    let recordId = domain.selectedRecordId()
    @Assert(domain.editSelectedLabelFromHuman("人类尚未应用的名称", 5, 5).applied, true)

    let batch = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "BATCH_SET_ENABLED", domain.snapshot().version, ArrayList<Int64>([recordId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("enabled", CjguiSharedOperationValue.boolean(true)),
            CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string("agent-batch-enabled"))
        ])
    ))
    @Assert(batch.applied, true)
    let draft = domain.formSnapshot()
    @Assert(draft.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "人类尚未应用的名称")
    @Assert(domain.applySelectedDraftFromHuman(draft.draftVersion).applied, true)
    @Assert(domain.snapshot().recordById(recordId).label, "人类尚未应用的名称")
    @Assert(domain.snapshot().recordById(recordId).enabled, true)
}

@Test
func batchWithOneUnauthorizedTargetIsRejectedBeforeAnyRuleMutation(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("已授权规则", false, 7, "cache", "authorized-create").applied, true)
    let authorizedId = domain.selectedRecordId()
    @Assert(domain.createRecordFromHuman("未授权规则", false, 7, "cache", "unauthorized-create").applied, true)
    let unauthorizedId = domain.selectedRecordId()
    let beforeVersion = domain.snapshot().version
    let connection = CjguiSharedOperationExternalConnection(
        domain,
        CjguiSharedOperationExternalAuthorization(
            "批量范围验收调用者",
            "scoped-batch-capability",
            ArrayList<CjguiSharedOperationExternalActionScope>([
                CjguiSharedOperationExternalActionScope("BATCH_SET_ENABLED", ArrayList<Int64>([authorizedId]), false)
            ])
        )
    )

    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH scoped-batch-capability\nINVOKE ${beforeVersion} BATCH_SET_ENABLED 2 2\nID ${authorizedId}\nID ${unauthorizedId}\nARG enabled BOOLEAN 1\nARG requestId STRING 22 73636F7065642D62617463682D72657175657374"
    )
    @Assert(response.contains("ERROR unauthorized_resource"), true)
    @Assert(domain.snapshot().version, beforeVersion)
    @Assert(domain.snapshot().recordById(authorizedId).enabled, false)
    @Assert(domain.snapshot().recordById(unauthorizedId).enabled, false)
}

@Test
func fullAuthorizedContextSerializesOneThousandRulesWithinTheProtocolBound(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var index: Int64 = 0
    while (index < 1001) {
        @Assert(domain.createRecordFromHuman("规模规则-${index}", false, 7, "scale", "large-context-${index}").applied, true)
        index += 1
    }
    let connection = CjguiSharedOperationExternalConnection(
        domain,
        CjguiSharedOperationExternalAuthorization(
            "规模上下文调用者",
            "large-context-capability",
            ArrayList<CjguiSharedOperationExternalActionScope>([
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
            ])
        )
    )
    let response = connection.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH large-context-capability\nGET_CONTEXT 0")
    @Assert(response.contains("KIND SNAPSHOT"), true)
    @Assert(response.contains("RESOURCES 1002"), true)
    @Assert(response.contains("FIELD 1001 enabled BOOLEAN 0"), true)
}

@Test
func undoPreservesDraftsOnRecordsOutsideTheRestoredChange(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("规则甲", true, 7, "cache", "undo-a").applied, true)
    let firstId = domain.selectedRecordId()
    @Assert(domain.createRecordFromHuman("规则乙", true, 7, "cache", "undo-b").applied, true)
    let secondId = domain.selectedRecordId()
    @Assert(domain.editSelectedLabelFromHuman("规则乙草稿", 5, 5).applied, true)

    let renamed = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "RENAME_RECORD", domain.snapshot().version, ArrayList<Int64>([firstId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string("规则甲已改")),
            CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string("undo-rename"))
        ])
    ))
    @Assert(renamed.applied, true)
    @Assert(domain.undoFromHuman().applied, true)
    @Assert(domain.selectRecordFromHuman(secondId).applied, true)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则乙草稿")
}

@Test
func undoNeverReusesAnObjectIdAndReportsRemovalAsAChange(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("第一条", true, 7, "cache", "identity-first").applied, true)
    let removedId = domain.selectedRecordId()
    let createdVersion = domain.snapshot().version
    @Assert(domain.undoFromHuman().applied, true)
    let removalChanges = domain.changesSince(createdVersion, ArrayList<Int64>())
    @Assert(removalChanges.entries.size, 1)
    @Assert(removalChanges.entries[0].resourceId, removedId)
    @Assert(domain.createRecordFromHuman("第二条", true, 7, "cache", "identity-second").applied, true)
    @Assert(domain.selectedRecordId() > removedId, true)
}

@Test
func anExternalRequestIdCannotBeReusedForDifferentContent(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let initialVersion = domain.snapshot().version
    @Assert(domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        initialVersion, "请求甲", true, 7, "cache", "same-request"
    )).applied, true)
    let reused = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        initialVersion, "请求乙", false, 21, "logs", "same-request"
    ))
    @Assert(reused.applied, false)
    @Assert(reused.isVersionConflict, true)
    @Assert(reused.reason, "request_id_reused")
    @Assert(domain.snapshot().records.size, 1)
}

@Test
func externalUndoRequiresTheWholeRuleSetScopeAndFutureChangeCursorsResync(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("范围规则", true, 7, "cache", "scope-create").applied, true)
    let recordId = domain.selectedRecordId()
    let scopedUndo = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "UNDO", domain.snapshot().version, ArrayList<Int64>([recordId]), ArrayList<CjguiSharedOperationActionArgument>()
    ))
    @Assert(scopedUndo.applied, false)
    @Assert(scopedUndo.reason, "invalid_target")
    @Assert(domain.changesSince(domain.snapshot().version + 1, ArrayList<Int64>()).requiresResync, true)
}

@Test
func openingAnotherFileCannotDiscardUnsavedContentImplicitly(): Unit {
    let directory = Directory.createTemp("/tmp")
    let firstPath = directory.join("first.cjgui-rules").toString()
    let secondPath = directory.join("second.cjgui-rules").toString()
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("已保存", true, 7, "cache", "open-first").applied, true)
    @Assert(domain.saveAsFromHuman(firstPath).applied, true)
    @Assert(domain.createRecordFromHuman("另一个文件", true, 7, "cache", "open-second").applied, true)
    @Assert(domain.saveAsFromHuman(secondPath).applied, true)
    @Assert(domain.openFromHuman(firstPath).applied, true)
    @Assert(domain.editSelectedLabelFromHuman("尚未保存", 4, 4).applied, true)
    let blocked = domain.openFromHuman(secondPath)
    @Assert(blocked.applied, false)
    @Assert(blocked.reason, "unsaved_content_requires_save_or_discard")
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "尚未保存")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func ruleSetTargetedContextReadsOnlyNamedRecordsFromTheOwner(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let first = domain.createRecordFromHuman("目标规则", true, 7, "cache", "targeted-first")
    let second = domain.createRecordFromHuman("不应构造的规则", false, 14, "tmp", "targeted-second")
    @Assert(first.applied, true)
    @Assert(second.applied, true)
    let fullSnapshot = domain.contextSnapshot()
    @Assert(fullSnapshot.streamIdentity.size > 0, true)
    let currentChanges = domain.changesSince(
        fullSnapshot.version, ArrayList<Int64>([1]), fullSnapshot.streamIdentity
    )
    @Assert(currentChanges.streamIdentity, fullSnapshot.streamIdentity)

    if (let Some(snapshot) <- domain.contextSnapshotForExternalTargets(ArrayList<Int64>([1]))) {
        @Assert(snapshot.resources.size, 1)
        @Assert(snapshot.resources[0].id, 1)
        @Assert(snapshot.resources[0].name, "目标规则")
        @Assert(snapshot.version, fullSnapshot.version)
        @Assert(snapshot.streamIdentity, fullSnapshot.streamIdentity)
    } else {
        @Assert(false, true)
    }
    if (let Some(_) <- domain.contextSnapshotForExternalTargets(ArrayList<Int64>([999]))) {
        @Assert(false, true)
    }
}

@Test
func splitSizeUsesTheExistingRuleSetOwnerCasAndRejectsAStaleExternalWrite(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let before = domain.snapshot().version
    @Assert(domain.splitFirstSizeVersion(), 0)
    let applied = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_SPLIT_SIZE", before, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.integer(420))
        ])
    ))
    @Assert(applied.applied, true)
    @Assert(applied.versionBefore, before)
    @Assert(applied.versionAfter, before + 1)
    @Assert(domain.splitFirstSizeVersion(), 1)

    let stale = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_SPLIT_SIZE", before, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.integer(300))
        ])
    ))
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(domain.splitFirstSizeVersion(), 1)

    var hasPublishedValue = false
    for (resource in domain.contextSnapshot().resources) {
        if (resource.id == CjguiRuleSetEditingDomain.ruleSetResourceId) {
            for (field in resource.fields) {
                if (field.name == "splitFirstSize" && field.value.integerValue == 420) {
                    hasPublishedValue = true
                }
            }
        }
    }
    @Assert(hasPublishedValue, true)
}
