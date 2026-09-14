package cjgui_backup_rule_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.sync.*

/// Application-owned editable truth for the backup-rule example. This package
/// is deliberately free of AppKit/FFI so the window and the no-window socket
/// consumer exercise exactly the same applied/draft state and dispatcher.
public class CjguiBackupRuleEditingDomain <: CjguiSharedEditableFormDomain {
    public static let configurationResourceId: Int64 = 4201
    public static let ruleLabelResourceId: Int64 = 42011
    public static let enabledResourceId: Int64 = 42012
    public static let retentionCountResourceId: Int64 = 42013
    public static let excludedTypeResourceId: Int64 = 42014

    private let lock: Mutex
    private let binding: CjguiSharedFormBinding
    private var contextVersion: Int64
    private var appliedConfigVersion: Int64
    private var draftVersion: Int64
    private var baseAppliedConfigVersion: Int64
    private var activeResourceId: Int64
    private var activeSelectionStart: Int64
    private var activeSelectionEnd: Int64
    private var appliedRuleLabel: String
    private var appliedEnabled: Bool
    private var appliedRetentionCount: Int64
    private var appliedExcludedType: String
    private var draftRuleLabel: String
    private var draftEnabled: Bool
    private var draftRetentionCount: String
    private var draftExcludedType: String
    private var ruleLabelError: String
    private var retentionCountError: String
    private var excludedTypeError: String
    private var ruleLabelFieldVersion: Int64
    private var enabledFieldVersion: Int64
    private var retentionCountFieldVersion: Int64
    private var excludedTypeFieldVersion: Int64
    private var statusMessage: String

    public init() {
        this.lock = Mutex()
        this.binding = CjguiSharedFormBinding(
            ArrayList<CjguiSharedFormFieldDescriptor>(
                [
                    CjguiSharedFormFieldDescriptor(CjguiBackupRuleEditingDomain.ruleLabelResourceId, "ruleLabel", "规则名称", "TEXT"),
                    CjguiSharedFormFieldDescriptor(CjguiBackupRuleEditingDomain.enabledResourceId, "enabled", "启用备份", "BOOLEAN"),
                    CjguiSharedFormFieldDescriptor(CjguiBackupRuleEditingDomain.retentionCountResourceId, "retentionCount", "保留天数", "INTEGER"),
                    CjguiSharedFormFieldDescriptor(CjguiBackupRuleEditingDomain.excludedTypeResourceId, "excludedType", "排除类型", "TEXT")
                ]
            )
        )
        this.contextVersion = 0
        this.appliedConfigVersion = 0
        this.draftVersion = 0
        this.baseAppliedConfigVersion = 0
        this.activeResourceId = -1
        this.activeSelectionStart = 0
        this.activeSelectionEnd = 0
        this.appliedRuleLabel = "默认规则"
        this.appliedEnabled = false
        this.appliedRetentionCount = 7
        this.appliedExcludedType = "cache"
        this.draftRuleLabel = appliedRuleLabel
        this.draftEnabled = appliedEnabled
        this.draftRetentionCount = appliedRetentionCount.toString()
        this.draftExcludedType = appliedExcludedType
        this.ruleLabelError = ""
        this.retentionCountError = ""
        this.excludedTypeError = ""
        this.ruleLabelFieldVersion = 0
        this.enabledFieldVersion = 0
        this.retentionCountFieldVersion = 0
        this.excludedTypeFieldVersion = 0
        this.statusMessage = "草稿与已应用配置一致"
    }

    public func resourceType(): String { return "backup_rule_editing" }

    public func formBinding(): CjguiSharedFormBinding { return binding }

    public func resourceIdForField(fieldId: String): Int64 {
        for (field in binding.allFields()) {
            if (field.fieldId == fieldId) { return field.resourceId }
        }
        return -1
    }

    public func formSnapshot(): CjguiSharedFormSnapshot {
        return synchronized(lock) { formSnapshotUnlocked() }
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return synchronized(lock) { contextSnapshotUnlocked() }
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>(
            [
                CjguiSharedOperationActionDescriptor("EDIT_DRAFT_TEXT", "编辑草稿文本", textEditParameters(), 1, 1),
                CjguiSharedOperationActionDescriptor("EDIT_DRAFT_BOOLEAN", "编辑草稿开关", booleanEditParameters(), 1, 1),
                CjguiSharedOperationActionDescriptor("APPLY_DRAFT", "应用草稿", applyParameters(), 1, 1),
                CjguiSharedOperationActionDescriptor("CANCEL_DRAFT", "取消并重载草稿", applyParameters(), 1, 1),
                // Retained generic consumer actions update applied configuration
                // without bypassing this domain's stale-draft protection.
                CjguiSharedOperationActionDescriptor("APPLY_BACKUP_RULE", "应用备份规则", legacyApplyParameters(), 1, 1),
                CjguiSharedOperationActionDescriptor("SET_RULE_LABEL", "设置已应用规则标签", labelParameters(), 1, 1)
            ]
        )
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, false) }
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, true) }
    }

    public func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            activeResourceId = resourceId
            activeSelectionStart = selectionStart
            activeSelectionEnd = selectionEnd
            executeUnlocked(
                CjguiSharedOperationActionInvocation(
                    "EDIT_DRAFT_TEXT", contextVersion, ArrayList<Int64>([resourceId]),
                    ArrayList<CjguiSharedOperationActionArgument>(
                        [
                            CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text)),
                            CjguiSharedOperationActionArgument("expectedFieldVersion", CjguiSharedOperationValue.integer(fieldVersionUnlocked(resourceId)))
                        ]
                    )
                ), false
            )
        }
    }

    public func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            activeResourceId = resourceId
            activeSelectionStart = 0
            activeSelectionEnd = 0
            executeUnlocked(
                CjguiSharedOperationActionInvocation(
                    "EDIT_DRAFT_BOOLEAN", contextVersion, ArrayList<Int64>([resourceId]),
                    ArrayList<CjguiSharedOperationActionArgument>(
                        [
                            CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.boolean(value)),
                            CjguiSharedOperationActionArgument("expectedFieldVersion", CjguiSharedOperationValue.integer(fieldVersionUnlocked(resourceId)))
                        ]
                    )
                ), false
            )
        }
    }

    public func applyDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { applyOrCancelUnlocked("APPLY_DRAFT", expectedDraftVersion, expectedBaseAppliedConfigVersion) }
    }

    public func cancelDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { applyOrCancelUnlocked("CANCEL_DRAFT", expectedDraftVersion, expectedBaseAppliedConfigVersion) }
    }

    private func executeUnlocked(invocation: CjguiSharedOperationActionInvocation, external: Bool): CjguiSharedOperationActionResult {
        if (invocation.actionName == "EDIT_DRAFT_TEXT") { return editTextUnlocked(invocation) }
        if (invocation.actionName == "EDIT_DRAFT_BOOLEAN") { return editBooleanUnlocked(invocation) }
        if (invocation.actionName == "APPLY_DRAFT" || invocation.actionName == "CANCEL_DRAFT") {
            if (let Some(expectedDraft) <- integerArgument(invocation, "expectedDraftVersion")) {
                if (let Some(expectedBase) <- integerArgument(invocation, "expectedBaseAppliedConfigVersion")) {
                    return applyOrCancelUnlocked(invocation.actionName, expectedDraft, expectedBase)
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "APPLY_BACKUP_RULE") { return legacyApplyUnlocked(invocation, external) }
        if (invocation.actionName == "SET_RULE_LABEL") { return legacyLabelUnlocked(invocation, external) }
        return rejected(false, "unknown_action")
    }

    private func editTextUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (!singleEditableTarget(invocation)) { return rejected(false, "unknown_form_field") }
        let resourceId = invocation.targetResourceIds[0]
        if (resourceId == CjguiBackupRuleEditingDomain.enabledResourceId) { return rejected(false, "field_requires_boolean") }
        if (let Some(text) <- stringArgument(invocation, "text")) {
            if (let Some(expected) <- integerArgument(invocation, "expectedFieldVersion")) {
                if (expected != fieldVersionUnlocked(resourceId)) { return rejected(true, "field_version_conflict") }
                if (draftTextUnlocked(resourceId) == text) { return accepted("already_at_target") }
                setDraftTextUnlocked(resourceId, text)
                incrementDraftUnlocked("草稿已修改，尚未应用")
                return accepted("draft_updated")
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func editBooleanUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.targetResourceIds[0] != CjguiBackupRuleEditingDomain.enabledResourceId) {
            return rejected(false, "field_requires_text")
        }
        if (let Some(value) <- booleanArgument(invocation, "value")) {
            if (let Some(expected) <- integerArgument(invocation, "expectedFieldVersion")) {
                if (expected != enabledFieldVersion) { return rejected(true, "field_version_conflict") }
                if (draftEnabled == value) { return accepted("already_at_target") }
                draftEnabled = value
                enabledFieldVersion += 1
                incrementDraftUnlocked("草稿已修改，尚未应用")
                return accepted("draft_updated")
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func applyOrCancelUnlocked(actionName: String, expectedDraft: Int64, expectedBase: Int64): CjguiSharedOperationActionResult {
        if (expectedDraft != draftVersion || expectedBase != baseAppliedConfigVersion || baseAppliedConfigVersion != appliedConfigVersion) {
            statusMessage = "草稿基于旧配置，未覆盖已应用配置"
            return rejected(true, "stale_draft")
        }
        if (actionName == "CANCEL_DRAFT") {
            resetDraftToAppliedUnlocked()
            incrementDraftUnlocked("草稿已取消并重载已应用配置")
            return accepted("draft_cancelled")
        }
        if (!validateDraftUnlocked()) {
            incrementDraftUnlocked("草稿包含校验错误，尚未应用")
            return rejected(false, "invalid_draft")
        }
        if (!isDraftDifferentFromAppliedUnlocked()) { return accepted("already_applied") }
        if (let Some(retention) <- Int64.tryParse(draftRetentionCount)) {
            appliedRuleLabel = draftRuleLabel
            appliedEnabled = draftEnabled
            appliedRetentionCount = retention
            appliedExcludedType = draftExcludedType
            appliedConfigVersion += 1
            baseAppliedConfigVersion = appliedConfigVersion
            clearValidationUnlocked()
            incrementDraftUnlocked("草稿已原子应用")
            return accepted("draft_applied")
        }
        return rejected(false, "invalid_draft")
    }

    private func legacyApplyUnlocked(invocation: CjguiSharedOperationActionInvocation, external: Bool): CjguiSharedOperationActionResult {
        if (!configurationTarget(invocation) || (external && invocation.expectedVersion != contextVersion)) { return rejected(external, if (external) { "version_conflict" } else { "unknown_backup_rule" }) }
        if (let Some(enabled) <- booleanArgument(invocation, "enabled")) {
            if (let Some(retention) <- integerArgument(invocation, "retentionCount")) {
                if (let Some(excluded) <- stringArgument(invocation, "excludedType")) {
                    if (retention < 1 || retention > 90 || excluded.size == 0 || excluded.size > 128) { return rejected(false, "invalid_backup_rule") }
                    if (appliedEnabled == enabled && appliedRetentionCount == retention && appliedExcludedType == excluded) { return accepted("already_at_target") }
                    let hadDraft = isDraftDifferentFromAppliedUnlocked()
                    appliedEnabled = enabled; appliedRetentionCount = retention; appliedExcludedType = excluded
                    appliedConfigVersion += 1
                    if (!hadDraft) { resetDraftToAppliedUnlocked() }
                    contextVersion += 1
                    statusMessage = "外部已更新已应用配置；现有草稿会在应用时检测版本"
                    return accepted("applied")
                }
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func legacyLabelUnlocked(invocation: CjguiSharedOperationActionInvocation, external: Bool): CjguiSharedOperationActionResult {
        if (!configurationTarget(invocation) || (external && invocation.expectedVersion != contextVersion)) { return rejected(external, if (external) { "version_conflict" } else { "unknown_backup_rule" }) }
        if (let Some(label) <- stringArgument(invocation, "label")) {
            if (label.size == 0 || label.size > 128) { return rejected(false, "invalid_rule_label") }
            if (appliedRuleLabel == label) { return accepted("already_at_target") }
            let hadDraft = isDraftDifferentFromAppliedUnlocked()
            appliedRuleLabel = label; appliedConfigVersion += 1
            if (!hadDraft) { resetDraftToAppliedUnlocked() }
            contextVersion += 1
            statusMessage = "已应用规则标签已更新"
            return accepted("applied")
        }
        return rejected(false, "invalid_parameters")
    }

    private func contextSnapshotUnlocked(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        resources.add(CjguiSharedOperationResource(
            CjguiBackupRuleEditingDomain.configurationResourceId, "备份规则配置",
            ArrayList<CjguiSharedOperationField>(
                [
                    CjguiSharedOperationField("appliedConfigVersion", CjguiSharedOperationValue.integer(appliedConfigVersion)),
                    CjguiSharedOperationField("draftVersion", CjguiSharedOperationValue.integer(draftVersion)),
                    CjguiSharedOperationField("baseAppliedConfigVersion", CjguiSharedOperationValue.integer(baseAppliedConfigVersion)),
                    CjguiSharedOperationField("canApply", CjguiSharedOperationValue.boolean(baseAppliedConfigVersion == appliedConfigVersion))
                ]
            )
        ))
        for (projection in formSnapshotUnlocked().allFields()) {
            resources.add(CjguiSharedOperationResource(
                projection.resourceId, projection.fieldId,
                ArrayList<CjguiSharedOperationField>(
                    [
                        CjguiSharedOperationField("appliedValue", projection.appliedValue),
                        CjguiSharedOperationField("draftText", CjguiSharedOperationValue.string(projection.draftText)),
                        CjguiSharedOperationField("validationError", CjguiSharedOperationValue.string(projection.validationError)),
                        CjguiSharedOperationField("draftFieldVersion", CjguiSharedOperationValue.integer(projection.draftFieldVersion)),
                        CjguiSharedOperationField("isFocused", CjguiSharedOperationValue.boolean(projection.isFocused))
                    ]
                )
            ))
        }
        return CjguiSharedOperationContextSnapshot(contextVersion, "备份规则共享编辑", resourceType(), resources)
    }

    private func formSnapshotUnlocked(): CjguiSharedFormSnapshot {
        return CjguiSharedFormSnapshot(
            contextVersion, appliedConfigVersion, draftVersion, baseAppliedConfigVersion,
            ArrayList<CjguiSharedFormFieldProjection>(
                [
                    projection(CjguiBackupRuleEditingDomain.ruleLabelResourceId, "ruleLabel", CjguiSharedOperationValue.string(appliedRuleLabel), draftRuleLabel, ruleLabelError, ruleLabelFieldVersion),
                    projection(CjguiBackupRuleEditingDomain.enabledResourceId, "enabled", CjguiSharedOperationValue.boolean(appliedEnabled), if (draftEnabled) { "true" } else { "false" }, "", enabledFieldVersion),
                    projection(CjguiBackupRuleEditingDomain.retentionCountResourceId, "retentionCount", CjguiSharedOperationValue.integer(appliedRetentionCount), draftRetentionCount, retentionCountError, retentionCountFieldVersion),
                    projection(CjguiBackupRuleEditingDomain.excludedTypeResourceId, "excludedType", CjguiSharedOperationValue.string(appliedExcludedType), draftExcludedType, excludedTypeError, excludedTypeFieldVersion)
                ]
            ), baseAppliedConfigVersion == appliedConfigVersion, statusMessage
        )
    }

    private func projection(resourceId: Int64, fieldId: String, applied: CjguiSharedOperationValue, draft: String, error: String, fieldVersion: Int64): CjguiSharedFormFieldProjection {
        return CjguiSharedFormFieldProjection(resourceId, fieldId, applied, draft, error, fieldVersion, activeResourceId == resourceId, if (activeResourceId == resourceId) { activeSelectionStart } else { 0 }, if (activeResourceId == resourceId) { activeSelectionEnd } else { 0 })
    }

    private func singleEditableTarget(invocation: CjguiSharedOperationActionInvocation): Bool {
        return invocation.targetResourceIds.size == 1 && binding.controlIndexForResourceId(invocation.targetResourceIds[0]) >= 0
    }

    private func configurationTarget(invocation: CjguiSharedOperationActionInvocation): Bool {
        return invocation.targetResourceIds.size == 1 && invocation.targetResourceIds[0] == CjguiBackupRuleEditingDomain.configurationResourceId
    }

    private func fieldVersionUnlocked(resourceId: Int64): Int64 {
        if (resourceId == CjguiBackupRuleEditingDomain.ruleLabelResourceId) { return ruleLabelFieldVersion }
        if (resourceId == CjguiBackupRuleEditingDomain.enabledResourceId) { return enabledFieldVersion }
        if (resourceId == CjguiBackupRuleEditingDomain.retentionCountResourceId) { return retentionCountFieldVersion }
        if (resourceId == CjguiBackupRuleEditingDomain.excludedTypeResourceId) { return excludedTypeFieldVersion }
        return -1
    }

    private func draftTextUnlocked(resourceId: Int64): String {
        if (resourceId == CjguiBackupRuleEditingDomain.ruleLabelResourceId) { return draftRuleLabel }
        if (resourceId == CjguiBackupRuleEditingDomain.retentionCountResourceId) { return draftRetentionCount }
        if (resourceId == CjguiBackupRuleEditingDomain.excludedTypeResourceId) { return draftExcludedType }
        return ""
    }

    private func setDraftTextUnlocked(resourceId: Int64, text: String) {
        if (resourceId == CjguiBackupRuleEditingDomain.ruleLabelResourceId) { draftRuleLabel = text; ruleLabelFieldVersion += 1 }
        else if (resourceId == CjguiBackupRuleEditingDomain.retentionCountResourceId) { draftRetentionCount = text; retentionCountFieldVersion += 1 }
        else if (resourceId == CjguiBackupRuleEditingDomain.excludedTypeResourceId) { draftExcludedType = text; excludedTypeFieldVersion += 1 }
    }

    private func incrementDraftUnlocked(message: String) { contextVersion += 1; draftVersion += 1; statusMessage = message }

    private func clearValidationUnlocked() { ruleLabelError = ""; retentionCountError = ""; excludedTypeError = "" }

    private func resetDraftToAppliedUnlocked() {
        draftRuleLabel = appliedRuleLabel; draftEnabled = appliedEnabled; draftRetentionCount = appliedRetentionCount.toString(); draftExcludedType = appliedExcludedType
        baseAppliedConfigVersion = appliedConfigVersion; clearValidationUnlocked()
        ruleLabelFieldVersion += 1; enabledFieldVersion += 1; retentionCountFieldVersion += 1; excludedTypeFieldVersion += 1
    }

    private func validateDraftUnlocked(): Bool {
        clearValidationUnlocked()
        if (draftRuleLabel.size == 0) { ruleLabelError = "rule_label_required" }
        else if (draftRuleLabel.size > 128) { ruleLabelError = "rule_label_too_long" }
        if (draftRetentionCount.size == 0) { retentionCountError = "retention_count_required" }
        else if (let Some(value) <- Int64.tryParse(draftRetentionCount)) {
            if (value < 1 || value > 90) { retentionCountError = "retention_count_out_of_range" }
        } else { retentionCountError = "retention_count_invalid" }
        if (draftExcludedType.size == 0) { excludedTypeError = "excluded_type_required" }
        else if (draftExcludedType.size > 128) { excludedTypeError = "excluded_type_too_long" }
        return ruleLabelError.size == 0 && retentionCountError.size == 0 && excludedTypeError.size == 0
    }

    private func isDraftDifferentFromAppliedUnlocked(): Bool {
        return draftRuleLabel != appliedRuleLabel || draftEnabled != appliedEnabled || draftRetentionCount != appliedRetentionCount.toString() || draftExcludedType != appliedExcludedType
    }

    private func accepted(reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(true, false, contextVersion, contextVersion, reason) }
    private func rejected(conflict: Bool, reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(false, conflict, contextVersion, contextVersion, reason) }

    private func textEditParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([CjguiSharedOperationParameterDescriptor("text", "STRING", true), CjguiSharedOperationParameterDescriptor("expectedFieldVersion", "INTEGER", true)]) }
    private func booleanEditParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true), CjguiSharedOperationParameterDescriptor("expectedFieldVersion", "INTEGER", true)]) }
    private func applyParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true), CjguiSharedOperationParameterDescriptor("expectedBaseAppliedConfigVersion", "INTEGER", true)]) }
    private func legacyApplyParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([CjguiSharedOperationParameterDescriptor("enabled", "BOOLEAN", true), CjguiSharedOperationParameterDescriptor("retentionCount", "INTEGER", true), CjguiSharedOperationParameterDescriptor("excludedType", "STRING", true)]) }
    private func labelParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([CjguiSharedOperationParameterDescriptor("label", "STRING", true)]) }

    private func stringArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?String { for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "STRING") { return Some(argument.value.stringValue) } }; return None }
    private func integerArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Int64 { for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "INTEGER") { return Some(argument.value.integerValue) } }; return None }
    private func booleanArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Bool { for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "BOOLEAN") { return Some(argument.value.booleanValue) } }; return None }
}
