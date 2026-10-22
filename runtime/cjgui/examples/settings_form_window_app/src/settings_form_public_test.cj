package cjgui_settings_form_window_app

import cjgui.*
import cjgui_settings_form_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func settingsTestPolicy(): CjguiFormFeedbackPolicy {
    return CjguiFormFeedbackPolicy(
        displayMessage: { fieldId, reason => "显示：${reason}" },
        focusSemanticId: { fieldId => cjguiFormFieldSemanticId("settings-form", fieldId) })
}

private func settingsTestProjection(domain: CjguiSettingsFormDomain,
    snapshot!: ?CjguiSharedFormSnapshot = None): CjguiFormFeedbackProjection {
    let current = match (snapshot) {
        case Some(value) => value
        case None => domain.formSnapshot()
    }
    return CjguiFormFeedbackProjection(current, domain.formBinding(),
        CjguiSettingsFormDomain.resourceId, policy: settingsTestPolicy(),
        readOnlyFields: ArrayList<String>(["workspaceId", "lastPublished"]))
}

private func settingsTwoErrors(domain: CjguiSettingsFormDomain): Unit {
    let _ = domain.editTextFromHuman(CjguiSettingsFormDomain.endpointResourceId, "ftp://bad", 0, 0)
    let _ = domain.editTextFromHuman(CjguiSettingsFormDomain.displayNameResourceId, "", 0, 0)
}

@Test
func settingsFeedbackProjectionUsesOneSnapshotAndStableIdentity(): Unit {
    let domain = CjguiSettingsFormDomain()
    settingsTwoErrors(domain)
    let snapshot = domain.formSnapshot()
    let feedback = settingsTestProjection(domain, snapshot: snapshot)
    @Assert(feedback.errorCount(), 2)
    @Assert(feedback.known)
    @Assert(!feedback.canApply)
    @Assert(feedback.submitBlocker(), "field_errors")
    @Assert(feedback.fieldErrors()[0].fieldId, "endpoint")
    @Assert(feedback.fieldErrors()[1].fieldId, "displayName")
    @Assert(feedback.fieldErrors()[0].reasonCode, CjguiSettingsFormDomain.endpointRequiredMessage)
    @Assert(feedback.fieldErrors()[0].displayMessage,
        "显示：${CjguiSettingsFormDomain.endpointRequiredMessage}")
    // The inline hint and the summary entry are the same owner fact.
    @Assert(snapshot.fieldForResourceId(CjguiSettingsFormDomain.endpointResourceId).validationError,
        feedback.fieldErrors()[0].reasonCode)
    @Assert(snapshot.fieldForResourceId(CjguiSettingsFormDomain.displayNameResourceId).validationError,
        feedback.fieldErrors()[1].reasonCode)
    // Stable identity, not display order.
    @Assert(feedback.fieldIdForResourceId(CjguiSettingsFormDomain.displayNameResourceId), "displayName")
    @Assert(feedback.focusResolution("endpoint").semanticId, "settings-form-field-endpoint")
    @Assert(feedback.focusResolution("endpoint").ready())
    @Assert(feedback.focusResolution("displayName").ready())
    // Read-only and blocked states are separate from field errors.
    @Assert(feedback.notes().size, 2)
    @Assert(feedback.focusResolution("workspaceId").reason, "field_read_only")
    @Assert(feedback.focusResolution("lastPublished").reason, "field_read_only")
    @Assert(feedback.focusResolution("missing").reason, "field_not_declared")
}

@Test
func settingsFeedbackTargetRemovalAndIdentityChangeAreExplicit(): Unit {
    let domain = CjguiSettingsFormDomain()
    settingsTwoErrors(domain)
    let full = domain.formSnapshot()
    let kept = ArrayList<CjguiSharedFormFieldProjection>()
    for (field in full.allFields()) {
        if (field.fieldId != "displayName") {
            kept.add(field)
        }
    }
    let partial = CjguiSharedFormSnapshot(full.contextVersion, full.appliedConfigVersion, full.draftVersion,
        full.baseAppliedConfigVersion, kept, full.canApply, full.statusMessage)
    let feedback = settingsTestProjection(domain, snapshot: partial)
    @Assert(!feedback.known)
    @Assert(feedback.focusResolution("displayName").reason, "field_not_in_snapshot")
    @Assert(!feedback.ready())
    // A removed target is never redirected to a neighbouring field.
    @Assert(feedback.focusResolution("displayName").semanticId, "settings-form-field-displayName")
    let changed = ArrayList<CjguiSharedFormFieldProjection>()
    for (field in full.allFields()) {
        if (field.fieldId == "endpoint") {
            changed.add(CjguiSharedFormFieldProjection(9999, "endpoint", field.appliedValue, field.draftText,
                field.validationError, field.draftFieldVersion, false, 0, 0))
        } else {
            changed.add(field)
        }
    }
    let mismatched = CjguiSharedFormSnapshot(full.contextVersion, full.appliedConfigVersion, full.draftVersion,
        full.baseAppliedConfigVersion, changed, full.canApply, full.statusMessage)
    let identityFeedback = settingsTestProjection(domain, snapshot: mismatched)
    @Assert(identityFeedback.focusResolution("endpoint").reason, "field_identity_changed")
}

@Test
func settingsApplyRejectionKeepsAppliedValuesThenAppliesFixedDraft(): Unit {
    let domain = CjguiSettingsFormDomain()
    let appliedBefore = domain.appliedEndpoint()
    settingsTwoErrors(domain)
    let rejectedSnapshot = domain.formSnapshot()
    let rejected = domain.applyDraftFromHuman(rejectedSnapshot.draftVersion,
        rejectedSnapshot.baseAppliedConfigVersion)
    @Assert(!rejected.applied)
    @Assert(domain.appliedEndpoint(), appliedBefore)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiSettingsFormDomain.endpointResourceId).validationError,
        CjguiSettingsFormDomain.endpointRequiredMessage)
    let fixedEndpoint = domain.editTextFromHuman(CjguiSettingsFormDomain.endpointResourceId,
        "https://settings.example.com", 0, 0)
    @Assert(fixedEndpoint.applied)
    let fixedName = domain.editTextFromHuman(CjguiSettingsFormDomain.displayNameResourceId, "发布工作区", 0, 0)
    @Assert(fixedName.applied)
    let readySnapshot = domain.formSnapshot()
    @Assert(readySnapshot.canApply)
    @Assert(settingsTestProjection(domain, snapshot: readySnapshot).ready())
    let applied = domain.applyDraftFromHuman(readySnapshot.draftVersion, readySnapshot.baseAppliedConfigVersion)
    @Assert(applied.applied)
    @Assert(domain.appliedEndpoint(), "https://settings.example.com")
    @Assert(domain.appliedDisplayName(), "发布工作区")
    @Assert(domain.lastPublishedText(), "已应用 v1")
    @Assert(domain.formSnapshot().draftVersion > readySnapshot.draftVersion)
}

@Test
func settingsGroupReorderIsPresentationOnly(): Unit {
    let domain = CjguiSettingsFormDomain()
    let before = domain.formSnapshot()
    let appliedBefore = domain.appliedEndpoint()
    let connection = CjguiComposableFormGroupPlacement("connection", "连接", 2100,
        ArrayList<CjguiComposableFormFieldPlacement>([CjguiComposableFormFieldPlacement("endpoint", 2110)]))
    let publishing = CjguiComposableFormGroupPlacement("publishing", "发布", 2200,
        ArrayList<CjguiComposableFormFieldPlacement>([CjguiComposableFormFieldPlacement("displayName", 2210)]))
    let normal = CjguiComposableFormPlacement(
        ArrayList<CjguiComposableFormGroupPlacement>([connection, publishing]))
    let reordered = normal.withGroupOrder(ArrayList<String>(["publishing", "connection"]))
    @Assert(normal.fieldCount(), 2)
    @Assert(reordered.fieldCount(), 2)
    @Assert(reordered.groups[0].key, "publishing")
    @Assert(reordered.groups[0].fields[0].fieldId, "displayName")
    let after = domain.formSnapshot()
    @Assert(after.draftVersion, before.draftVersion)
    @Assert(domain.appliedEndpoint(), appliedBefore)
}

@Test
func settingsSummaryCarriesFieldResourceNotDisplayIndex(): Unit {
    let domain = CjguiSettingsFormDomain()
    settingsTwoErrors(domain)
    let feedback = settingsTestProjection(domain)
    let summary = cjguiComposableFormFeedbackSummary(102, "settings-feedback", feedback,
        "FOCUS_SETTINGS_FIELD")
    var foundEndpoint = false
    var foundName = false
    for (child in summary.children()) {
        if (child.operationResourceId == CjguiSettingsFormDomain.endpointResourceId &&
            child.actionName == "FOCUS_SETTINGS_FIELD") {
            foundEndpoint = true
        }
        if (child.operationResourceId == CjguiSettingsFormDomain.displayNameResourceId &&
            child.actionName == "FOCUS_SETTINGS_FIELD") {
            foundName = true
        }
    }
    @Assert(foundEndpoint)
    @Assert(foundName)
    @Assert(feedback.fieldIdForResourceId(CjguiSettingsFormDomain.endpointResourceId), "endpoint")
}

@Test
func settingsGroupedFieldKeepsRequiredHelpAndReadOnlyNodesDistinct(): Unit {
    let domain = CjguiSettingsFormDomain()
    let _ = domain.editTextFromHuman(CjguiSettingsFormDomain.displayNameResourceId, "", 0, 0)
    let feedback = settingsTestProjection(domain)
    let publishing = CjguiComposableFormGroupPlacement("publishing", "发布", 2200,
        ArrayList<CjguiComposableFormFieldPlacement>([
            CjguiComposableFormFieldPlacement("displayName", 2210,
                helpText: "显示在发布记录和失败通知中。", readOnly: true)
        ]))
    let placement = CjguiComposableFormPlacement(ArrayList<CjguiComposableFormGroupPlacement>([publishing]))
    let root = cjguiComposableBoundFormGroups(201, "settings-form", placement, feedback)
    let ids = HashMap<Int64, Bool>()
    var note = ""
    var readOnlySeen = false
    for (groupNode in root.children()) {
        for (fieldGroup in groupNode.children()) {
            for (child in fieldGroup.children()) {
                @Assert(ids.get(child.nodeId).isNone())
                ids.add(child.nodeId, true)
                if (child.nodeId == 2213) {
                    note = child.value
                }
                if (child.nodeId == 2214) {
                    readOnlySeen = true
                }
            }
        }
    }
    @Assert(ids.get(2211).isSome())
    @Assert(ids.get(2212).isSome())
    @Assert(ids.get(2213).isSome())
    @Assert(ids.get(2214).isSome())
    @Assert(note.contains("必填"))
    @Assert(note.contains("显示在发布记录和失败通知中。"))
    @Assert(readOnlySeen)
    @Assert(placement.editorNodeId("displayName"), 2211)
    @Assert(placement.editorNodeId("missing"), -1)
}

@Test
func settingsHealthyUndeclaredFieldIsNotAnUnmappedError(): Unit {
    let domain = CjguiSettingsFormDomain()
    let full = domain.formSnapshot()
    let healthy = ArrayList<CjguiSharedFormFieldProjection>(full.allFields())
    healthy.add(CjguiSharedFormFieldProjection(9998, "legacyHealthy", CjguiSharedOperationValue.string("ok"), "ok", "", 0, true, 0, 0))
    let healthySnapshot = CjguiSharedFormSnapshot(full.contextVersion, full.appliedConfigVersion,
        full.draftVersion, full.baseAppliedConfigVersion, healthy, full.canApply, full.statusMessage)
    let healthyFeedback = settingsTestProjection(domain, snapshot: healthySnapshot)
    @Assert(healthyFeedback.unmappedErrors().size, 0)
    @Assert(!healthyFeedback.hasErrors())
    @Assert(healthyFeedback.known)

    let broken = ArrayList<CjguiSharedFormFieldProjection>(full.allFields())
    broken.add(CjguiSharedFormFieldProjection(9997, "legacyBroken", CjguiSharedOperationValue.string("ok"), "bad", "旧字段校验失败", 0, true, 0, 0))
    let brokenSnapshot = CjguiSharedFormSnapshot(full.contextVersion, full.appliedConfigVersion,
        full.draftVersion, full.baseAppliedConfigVersion, broken, full.canApply, full.statusMessage)
    let brokenFeedback = settingsTestProjection(domain, snapshot: brokenSnapshot)
    @Assert(brokenFeedback.unmappedErrors().size, 1)
    @Assert(brokenFeedback.unmappedErrors()[0].fieldId, "legacyBroken")
    @Assert(brokenFeedback.hasErrors())
    // An unmapped business error is reported but never rewrites the owner's canApply.
    @Assert(brokenFeedback.canApply, full.canApply)
}

@Test
func settingsCommandToolbarAndPaletteShareStableKeys(): Unit {
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("settings.apply", CjguiComposableUiNodeReference.manual(301),
            "应用设置", "Settings", 0, false, false),
        CjguiComposableUiCommand("settings.reset", CjguiComposableUiNodeReference.manual(302),
            "恢复已应用值", "Settings", 0, true, false),
        CjguiComposableUiCommand("settings.search-commands", CjguiComposableUiNodeReference.manual(305),
            "搜索命令", CjguiComposableUiShortcut("k"), "View", 1, true, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("settings.apply", "APPLY", 9300, detail: "应用草稿",
            disabledReason: "草稿仍有字段错误"),
        CjguiCommandToolbarMetadata("settings.reset", "RESET", 9300, detail: "恢复已应用值"),
        CjguiCommandToolbarMetadata("settings.search-commands", "SEARCH_COMMANDS", 9300,
            detail: "打开命令面板")
    ])
    let placement = cjguiCommandToolbarPlacement(commands, metadata,
        searchCommandId: "settings.search-commands")
    let toolbar = cjguiComposableCommandToolbar(300, "settings-actions", placement,
        searchResourceId: 9300)
    var applySeen = false
    var searchSeen = false
    for (child in toolbar.children()) {
        if (child.nodeId == 301) {
            applySeen = child.actionName == "APPLY" && child.operationActionName == "APPLY" && !child.isEnabled &&
                child.semanticId == "settings-actions-settings-apply"
        }
        if (child.nodeId == 305) {
            searchSeen = child.actionName == "SEARCH_COMMANDS" && child.resourceId == 9300
        }
    }
    @Assert(applySeen)
    @Assert(searchSeen)
    let items = cjguiCommandPaletteItems(placement)
    @Assert(items.size, 2)
    // Command ids keep dots; presentation keys and semantic ids cannot, because
    // the public window projection accepts only identifier-safe keys.
    @Assert(items[0].key, "settings-apply")
    @Assert(!items[0].key.contains("."))
    @Assert(items[0].isEnabled, false)
    @Assert(items[0].disabledReason, "草稿仍有字段错误")
    @Assert(items[1].key, "settings-reset")
    // The command shortcut is projected, not copied into a second definition.
    @Assert(items[0].shortcut, "")
    @Assert(commands[2].hasShortcut())
    @Assert(commands[2].shortcut.encoded(), "shortcut:command+k")
    @Assert(placement.itemForCommand("settings.apply").getOrThrow().key, "settings-apply")
    @Assert(placement.itemForKey("settings-apply").isSome())
    let searchItem = placement.itemForCommand("settings.search-commands")
    @Assert(searchItem.isNone())
    @Assert(placement.searchNodeBase, 305)
    @Assert(placement.itemForCommand("settings.reset").isSome())
    @Assert(placement.itemForCommand("missing").isNone())
    // Metadata that names no command is a declaration error, not a hidden
    // toolbar button with its own execution definition.
    var rejected = false
    try {
        cjguiCommandToolbarPlacement(commands,
            ArrayList<CjguiCommandToolbarMetadata>([
                CjguiCommandToolbarMetadata("settings.missing", "MISSING", 9300)
            ]), searchCommandId: "settings.search-commands")
    } catch (error: IllegalArgumentException) {
        rejected = true
    }
    @Assert(rejected)
}
