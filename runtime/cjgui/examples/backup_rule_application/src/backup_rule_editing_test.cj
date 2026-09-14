package cjgui_backup_rule_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func textArgument(name: String, value: String): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.string(value))
}

private func integerArgument(name: String, value: Int64): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.integer(value))
}

@Test
func humanDraftSurvivesExternalEditOfAnotherFieldAndAppliesAtomically(): Unit {
    let domain = CjguiBackupRuleEditingDomain()
    let labelId = domain.resourceIdForField("ruleLabel")
    let retentionId = domain.resourceIdForField("retentionCount")

    let humanEdit = domain.editTextFromHuman(labelId, "我的初稿", 2, 2)
    @Assert(humanEdit.applied, true)
    let beforeExternal = domain.formSnapshot()
    let retentionRevision = beforeExternal.fieldForResourceId(retentionId).draftFieldVersion
    let externalEdit = domain.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "EDIT_DRAFT_TEXT",
            beforeExternal.contextVersion,
            ArrayList<Int64>([retentionId]),
            ArrayList<CjguiSharedOperationActionArgument>(
                [
                    textArgument("text", "30"),
                    integerArgument("expectedFieldVersion", retentionRevision)
                ]
            )
        )
    )
    @Assert(externalEdit.applied, true)
    let afterExternal = domain.formSnapshot()
    let label = afterExternal.fieldForResourceId(labelId)
    @Assert(label.draftText, "我的初稿")
    @Assert(label.isFocused, true)
    @Assert(label.selectionStart, 2)
    @Assert(afterExternal.fieldForResourceId(retentionId).draftText, "30")

    let applied = domain.applyDraftFromHuman(afterExternal.draftVersion, afterExternal.baseAppliedConfigVersion)
    @Assert(applied.applied, true)
    @Assert(domain.formSnapshot().fieldForResourceId(labelId).appliedValue.stringValue, "我的初稿")
    @Assert(domain.formSnapshot().fieldForResourceId(retentionId).appliedValue.integerValue, 30)
}

@Test
func invalidDraftStaysVisibleAndStaleSameFieldWriteIsRejected(): Unit {
    let domain = CjguiBackupRuleEditingDomain()
    let retentionId = domain.resourceIdForField("retentionCount")
    let labelId = domain.resourceIdForField("ruleLabel")

    @Assert(domain.editTextFromHuman(retentionId, "", 0, 0).applied, true)
    let invalid = domain.applyDraftFromHuman(domain.formSnapshot().draftVersion, domain.formSnapshot().baseAppliedConfigVersion)
    @Assert(invalid.applied, false)
    @Assert(domain.formSnapshot().fieldForResourceId(retentionId).draftText, "")
    @Assert(domain.formSnapshot().fieldForResourceId(retentionId).validationError, "retention_count_required")
    @Assert(domain.formSnapshot().fieldForResourceId(retentionId).appliedValue.integerValue, 7)

    let beforeHuman = domain.formSnapshot()
    let staleRevision = beforeHuman.fieldForResourceId(labelId).draftFieldVersion
    @Assert(domain.editTextFromHuman(labelId, "本地更新", 4, 4).applied, true)
    let stale = domain.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "EDIT_DRAFT_TEXT",
            beforeHuman.contextVersion,
            ArrayList<Int64>([labelId]),
            ArrayList<CjguiSharedOperationActionArgument>(
                [textArgument("text", "过期写入"), integerArgument("expectedFieldVersion", staleRevision)]
            )
        )
    )
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(domain.formSnapshot().fieldForResourceId(labelId).draftText, "本地更新")
}

@Test
func cancelAndStaleAppliedConfigurationPreserveTheHumanDraft(): Unit {
    let domain = CjguiBackupRuleEditingDomain()
    let labelId = domain.resourceIdForField("ruleLabel")
    let retentionId = domain.resourceIdForField("retentionCount")

    @Assert(domain.editTextFromHuman(labelId, "规则甲", 3, 3).applied, true)
    @Assert(domain.editTextFromHuman(retentionId, "91", 2, 2).applied, true)
    let beforeCancel = domain.formSnapshot()
    @Assert(domain.cancelDraftFromHuman(beforeCancel.draftVersion, beforeCancel.baseAppliedConfigVersion).applied, true)
    @Assert(domain.formSnapshot().fieldForResourceId(labelId).draftText, "默认规则")
    @Assert(domain.formSnapshot().fieldForResourceId(retentionId).draftText, "7")

    @Assert(domain.editTextFromHuman(labelId, "保留中的草稿", 6, 6).applied, true)
    let staleHumanView = domain.formSnapshot()
    let externalUpdate = domain.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "SET_RULE_LABEL", staleHumanView.contextVersion,
            ArrayList<Int64>([CjguiBackupRuleEditingDomain.configurationResourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([textArgument("label", "外部已应用")])
        )
    )
    @Assert(externalUpdate.applied, true)
    let staleApply = domain.applyDraftFromHuman(staleHumanView.draftVersion, staleHumanView.baseAppliedConfigVersion)
    @Assert(staleApply.applied, false)
    @Assert(staleApply.isVersionConflict, true)
    @Assert(domain.formSnapshot().fieldForResourceId(labelId).draftText, "保留中的草稿")
    @Assert(domain.formSnapshot().fieldForResourceId(labelId).appliedValue.stringValue, "外部已应用")
}
