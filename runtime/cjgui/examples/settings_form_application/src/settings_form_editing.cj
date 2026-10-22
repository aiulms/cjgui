package cjgui_settings_form_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.random.*
import std.convert.*

/// Small workspace-settings owner used by the grouped-form example. It owns
/// declarations, draft validation, applied values and change versions. The
/// public form composition reads this owner; it never mirrors or validates it.
public class CjguiSettingsFormDomain <: CjguiSharedEditableFormDomain & CjguiSharedOperationChangeDomain {
    public static let resourceId: Int64 = 9300
    public static let endpointResourceId: Int64 = 9301
    public static let retryLimitResourceId: Int64 = 9302
    public static let useProxyResourceId: Int64 = 9303
    public static let workspaceIdResourceId: Int64 = 9304
    public static let displayNameResourceId: Int64 = 9305
    public static let refreshSecondsResourceId: Int64 = 9306
    public static let notifyOnFailureResourceId: Int64 = 9307
    public static let lastPublishedResourceId: Int64 = 9308
    public static let retryMinimum: Int64 = 1
    public static let retryMaximum: Int64 = 10
    public static let refreshMinimum: Int64 = 5
    public static let refreshMaximum: Int64 = 300

    public static let endpointRequiredMessage: String = "请输入以 https:// 开头的地址"
    public static let retryRangeMessage: String = "重试次数需在 1 到 10 之间"
    public static let displayNameRequiredMessage: String = "发布名称不能为空"
    public static let refreshRangeMessage: String = "刷新间隔需在 5 到 300 秒之间"

    private var versionValue: Int64
    private var appliedVersion: Int64
    private var draftVersionValue: Int64
    private var baseAppliedVersion: Int64
    private var endpoint: String
    private var retryLimit: Int64
    private var useProxy: Bool
    private var displayName: String
    private var refreshSeconds: Int64
    private var notifyOnFailure: Bool
    private var draftEndpoint: String
    private var draftRetryLimit: String
    private var draftUseProxy: Bool
    private var draftDisplayName: String
    private var draftRefreshSeconds: String
    private var draftNotifyOnFailure: Bool
    private let streamIdentity: String
    private let changeLog: ArrayList<CjguiSharedOperationChangeEntry>

    public init() {
        this.versionValue = 0
        this.appliedVersion = 0
        this.draftVersionValue = 0
        this.baseAppliedVersion = 0
        this.endpoint = "https://api.example.com"
        this.retryLimit = 3
        this.useProxy = false
        this.displayName = "团队工作区"
        this.refreshSeconds = 60
        this.notifyOnFailure = true
        this.draftEndpoint = endpoint
        this.draftRetryLimit = retryLimit.toString()
        this.draftUseProxy = useProxy
        this.draftDisplayName = displayName
        this.draftRefreshSeconds = refreshSeconds.toString()
        this.draftNotifyOnFailure = notifyOnFailure
        this.streamIdentity = "settings_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
    }

    public func resourceType(): String {
        return "workspace_settings"
    }

    public func formBinding(): CjguiSharedFormBinding {
        return CjguiSharedFormBinding(
            ArrayList<CjguiSharedFormFieldDescriptor>(
                [
                    CjguiSharedFormFieldDescriptor(endpointResourceId, "endpoint", "服务地址", "TEXT",
                        required: true, maximumLength: 64),
                    CjguiSharedFormFieldDescriptor(retryLimitResourceId, "retryLimit", "重试次数", "INTEGER",
                        required: true, minimum: retryMinimum, maximum: retryMaximum),
                    CjguiSharedFormFieldDescriptor(useProxyResourceId, "useProxy", "使用代理", "BOOLEAN"),
                    CjguiSharedFormFieldDescriptor(workspaceIdResourceId, "workspaceId", "工作区标识", "TEXT"),
                    CjguiSharedFormFieldDescriptor(displayNameResourceId, "displayName", "发布名称", "TEXT",
                        required: true, maximumLength: 24),
                    CjguiSharedFormFieldDescriptor(refreshSecondsResourceId, "refreshSeconds", "刷新间隔（秒）",
                        "INTEGER", required: true, minimum: refreshMinimum, maximum: refreshMaximum),
                    CjguiSharedFormFieldDescriptor(notifyOnFailureResourceId, "notifyOnFailure", "失败时通知",
                        "BOOLEAN"),
                    CjguiSharedFormFieldDescriptor(lastPublishedResourceId, "lastPublished", "最近发布", "TEXT")
                ]
            )
        )
    }

    public func formSnapshot(): CjguiSharedFormSnapshot {
        return draftSnapshot()
    }

    public func appliedEndpoint(): String {
        return endpoint
    }

    public func appliedRetryLimit(): Int64 {
        return retryLimit
    }

    public func appliedDisplayName(): String {
        return displayName
    }

    public func appliedRefreshSeconds(): Int64 {
        return refreshSeconds
    }

    public func appliedUseProxy(): Bool {
        return useProxy
    }

    public func appliedNotifyOnFailure(): Bool {
        return notifyOnFailure
    }

    public func appliedVersionNumber(): Int64 {
        return appliedVersion
    }

    public func lastPublishedText(): String {
        return if (appliedVersion == 0) {
            "尚未发布"
        } else {
            "已应用 v${appliedVersion}"
        }
    }

    public func draftSnapshot(): CjguiSharedFormSnapshot {
        let endpointError = endpointValidationMessage(draftEndpoint)
        let retryError = retryValidationMessage(draftRetryLimit)
        let displayNameError = if (draftDisplayName.size == 0) {
            displayNameRequiredMessage
        } else {
            ""
        }
        let refreshError = refreshValidationMessage(draftRefreshSeconds)
        let hasFieldError = endpointError.size > 0 || retryError.size > 0 || displayNameError.size > 0 ||
            refreshError.size > 0
        let baselineMoved = baseAppliedVersion != appliedVersion
        let canApply = !hasFieldError && !baselineMoved
        let status = if (hasFieldError) {
            "请修正标出的字段"
        } else if (baselineMoved) {
            "外部配置已更新，请先恢复草稿或重新编辑"
        } else {
            "可以应用"
        }
        return CjguiSharedFormSnapshot(
            versionValue,
            appliedVersion,
            draftVersionValue,
            baseAppliedVersion,
            ArrayList<CjguiSharedFormFieldProjection>(
                [
                    CjguiSharedFormFieldProjection(endpointResourceId, "endpoint",
                        CjguiSharedOperationValue.string(endpoint), draftEndpoint, endpointError, draftVersionValue,
                        false, 0, 0),
                    CjguiSharedFormFieldProjection(retryLimitResourceId, "retryLimit",
                        CjguiSharedOperationValue.integer(retryLimit), draftRetryLimit, retryError, draftVersionValue,
                        false, 0, 0),
                    CjguiSharedFormFieldProjection(useProxyResourceId, "useProxy",
                        CjguiSharedOperationValue.boolean(useProxy), if (draftUseProxy) {
                            "true"
                        } else {
                            "false"
                        }, "", draftVersionValue, false, 0, 0),
                    CjguiSharedFormFieldProjection(workspaceIdResourceId, "workspaceId",
                        CjguiSharedOperationValue.string("ws-cjgui-01"), "ws-cjgui-01", "", draftVersionValue,
                        false, 0, 0),
                    CjguiSharedFormFieldProjection(displayNameResourceId, "displayName",
                        CjguiSharedOperationValue.string(displayName), draftDisplayName, displayNameError,
                        draftVersionValue, false, 0, 0),
                    CjguiSharedFormFieldProjection(refreshSecondsResourceId, "refreshSeconds",
                        CjguiSharedOperationValue.integer(refreshSeconds), draftRefreshSeconds, refreshError,
                        draftVersionValue, false, 0, 0),
                    CjguiSharedFormFieldProjection(notifyOnFailureResourceId, "notifyOnFailure",
                        CjguiSharedOperationValue.boolean(notifyOnFailure), if (draftNotifyOnFailure) {
                            "true"
                        } else {
                            "false"
                        }, "", draftVersionValue, false, 0, 0),
                    CjguiSharedFormFieldProjection(lastPublishedResourceId, "lastPublished",
                        CjguiSharedOperationValue.string(lastPublishedText()), lastPublishedText(), "",
                        draftVersionValue, false, 0, 0)
                ]
            ),
            canApply,
            status
        )
    }

    public func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64,
        selectionEnd: Int64): CjguiSharedOperationActionResult {
        let _ = selectionStart
        let _ = selectionEnd
        let binding = formBinding()
        let index = binding.controlIndexForResourceId(resourceId)
        if (index < 0) {
            return rejected(false, "unknown_draft_field")
        }
        let descriptor = binding.fieldAtControlIndex(index)
        if (descriptor.editorKind == "BOOLEAN") {
            return rejected(false, "wrong_editor_kind")
        }
        if (isReadOnlyField(descriptor.fieldId)) {
            return rejected(false, "field_read_only")
        }
        return editDraftText(descriptor.fieldId, text)
    }

    public func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        let binding = formBinding()
        let index = binding.controlIndexForResourceId(resourceId)
        if (index < 0) {
            return rejected(false, "unknown_draft_field")
        }
        let descriptor = binding.fieldAtControlIndex(index)
        if (descriptor.editorKind != "BOOLEAN") {
            return rejected(false, "wrong_editor_kind")
        }
        if (isReadOnlyField(descriptor.fieldId)) {
            return rejected(false, "field_read_only")
        }
        return editDraftBoolean(descriptor.fieldId, value)
    }

    public func applyDraftFromHuman(expectedDraftVersion: Int64,
        expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        return applyDraft(expectedDraftVersion, expectedBaseAppliedVersion)
    }

    public func cancelDraftFromHuman(expectedDraftVersion: Int64,
        expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersionValue || expectedBaseAppliedVersion != baseAppliedVersion) {
            return rejected(true, "stale_draft")
        }
        resetDraft()
        draftVersionValue += 1
        versionValue += 1
        recordChange("settings_draft_cancelled")
        return accepted("settings_draft_cancelled")
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(
            versionValue,
            "工作区设置",
            resourceType(),
            ArrayList<CjguiSharedOperationResource>(
                [
                    CjguiSharedOperationResource(
                        resourceId,
                        "工作区",
                        ArrayList<CjguiSharedOperationField>(
                            [
                                CjguiSharedOperationField("endpoint",
                                    CjguiSharedOperationValue.string(endpoint)),
                                CjguiSharedOperationField("retryLimit",
                                    CjguiSharedOperationValue.integer(retryLimit)),
                                CjguiSharedOperationField("useProxy", CjguiSharedOperationValue.boolean(useProxy)),
                                CjguiSharedOperationField("workspaceId",
                                    CjguiSharedOperationValue.string("ws-cjgui-01")),
                                CjguiSharedOperationField("displayName",
                                    CjguiSharedOperationValue.string(displayName)),
                                CjguiSharedOperationField("refreshSeconds",
                                    CjguiSharedOperationValue.integer(refreshSeconds)),
                                CjguiSharedOperationField("notifyOnFailure",
                                    CjguiSharedOperationValue.boolean(notifyOnFailure)),
                                CjguiSharedOperationField("lastPublished",
                                    CjguiSharedOperationValue.string(lastPublishedText())),
                                CjguiSharedOperationField("draftEndpoint",
                                    CjguiSharedOperationValue.string(draftEndpoint)),
                                CjguiSharedOperationField("draftRetryLimit",
                                    CjguiSharedOperationValue.string(draftRetryLimit)),
                                CjguiSharedOperationField("draftUseProxy",
                                    CjguiSharedOperationValue.boolean(draftUseProxy)),
                                CjguiSharedOperationField("draftDisplayName",
                                    CjguiSharedOperationValue.string(draftDisplayName)),
                                CjguiSharedOperationField("draftRefreshSeconds",
                                    CjguiSharedOperationValue.string(draftRefreshSeconds)),
                                CjguiSharedOperationField("draftNotifyOnFailure",
                                    CjguiSharedOperationValue.boolean(draftNotifyOnFailure)),
                                CjguiSharedOperationField("draftVersion",
                                    CjguiSharedOperationValue.integer(draftVersionValue)),
                                CjguiSharedOperationField("baseAppliedVersion",
                                    CjguiSharedOperationValue.integer(baseAppliedVersion))
                            ]
                        )
                    )
                ]
            )
        )
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>(
            [
                CjguiSharedOperationActionDescriptor("EDIT_DRAFT_TEXT", "编辑设置草稿文本",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("fieldId", "STRING", true),
                            CjguiSharedOperationParameterDescriptor("text", "STRING", true),
                            CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
                        ]
                    ), 1, 1),
                CjguiSharedOperationActionDescriptor("EDIT_DRAFT_BOOLEAN", "编辑设置草稿开关",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("fieldId", "STRING", true),
                            CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true),
                            CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
                        ]
                    ), 1, 1),
                CjguiSharedOperationActionDescriptor("APPLY_DRAFT", "应用设置草稿",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true),
                            CjguiSharedOperationParameterDescriptor("expectedBaseAppliedConfigVersion", "INTEGER",
                                true)
                        ]
                    ), 1, 1),
                CjguiSharedOperationActionDescriptor("CANCEL_DRAFT", "取消设置草稿",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true),
                            CjguiSharedOperationParameterDescriptor("expectedBaseAppliedConfigVersion", "INTEGER",
                                true)
                        ]
                    ), 1, 1)
            ]
        )
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>,
        expectedStreamIdentity: String): CjguiSharedOperationChanges {
        if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) || sinceVersion < 0 ||
            sinceVersion > versionValue) {
            return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, true,
                ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let changes = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changeLog) {
            if (entry.version > sinceVersion && (resourceFilter.size == 0 || resourceFilter[0] == resourceId)) {
                changes.add(entry)
            }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, changes)
    }

    private func execute(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = versionValue
        if (invocation.targetResourceIds.size != 1 || invocation.targetResourceIds[0] != resourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != versionValue) {
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (invocation.actionName == "EDIT_DRAFT_TEXT") {
            if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
                if (let Some(text) <- stringArgument(invocation, "text")) {
                    if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) {
                        if (expected != draftVersionValue) {
                            return rejected(true, "draft_version_conflict")
                        }
                        return editDraftText(fieldId, text)
                    }
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "EDIT_DRAFT_BOOLEAN") {
            if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
                if (let Some(value) <- booleanArgument(invocation, "value")) {
                    if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) {
                        if (expected != draftVersionValue) {
                            return rejected(true, "draft_version_conflict")
                        }
                        return editDraftBoolean(fieldId, value)
                    }
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "APPLY_DRAFT") {
            if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) {
                if (let Some(base) <- integerArgument(invocation, "expectedBaseAppliedConfigVersion")) {
                    return applyDraft(expected, base)
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "CANCEL_DRAFT") {
            if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) {
                if (let Some(base) <- integerArgument(invocation, "expectedBaseAppliedConfigVersion")) {
                    return cancelDraftFromHuman(expected, base)
                }
            }
            return rejected(false, "invalid_parameters")
        }
        return rejected(false, "invalid_action")
    }

    private func editDraftText(fieldId: String, text: String): CjguiSharedOperationActionResult {
        if (isReadOnlyField(fieldId)) {
            return rejected(false, "field_read_only")
        }
        if (fieldId == "endpoint") {
            draftEndpoint = text
        } else if (fieldId == "retryLimit") {
            draftRetryLimit = text
        } else if (fieldId == "displayName") {
            draftDisplayName = text
        } else if (fieldId == "refreshSeconds") {
            draftRefreshSeconds = text
        } else {
            return rejected(false, "unknown_draft_field")
        }
        draftVersionValue += 1
        versionValue += 1
        recordChange("settings_draft_updated")
        return accepted("settings_draft_updated")
    }

    private func editDraftBoolean(fieldId: String, value: Bool): CjguiSharedOperationActionResult {
        if (fieldId == "useProxy") {
            draftUseProxy = value
        } else if (fieldId == "notifyOnFailure") {
            draftNotifyOnFailure = value
        } else {
            return rejected(false, "unknown_draft_field")
        }
        draftVersionValue += 1
        versionValue += 1
        recordChange("settings_draft_updated")
        return accepted("settings_draft_updated")
    }

    private func applyDraft(expectedDraftVersion: Int64,
        expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersionValue || expectedBaseAppliedVersion != appliedVersion) {
            return rejected(true, "stale_draft")
        }
        let endpointError = endpointValidationMessage(draftEndpoint)
        if (endpointError.size > 0) {
            return rejected(false, endpointError)
        }
        let retry = match (Int64.tryParse(draftRetryLimit)) {
            case Some(value) => value
            case None => return rejected(false, retryRangeMessage)
        }
        if (retry < retryMinimum || retry > retryMaximum) {
            return rejected(false, retryRangeMessage)
        }
        let refresh = match (Int64.tryParse(draftRefreshSeconds)) {
            case Some(value) => value
            case None => return rejected(false, refreshRangeMessage)
        }
        if (refresh < refreshMinimum || refresh > refreshMaximum) {
            return rejected(false, refreshRangeMessage)
        }
        if (draftDisplayName.size == 0) {
            return rejected(false, displayNameRequiredMessage)
        }
        let before = versionValue
        endpoint = draftEndpoint
        retryLimit = retry
        useProxy = draftUseProxy
        displayName = draftDisplayName
        refreshSeconds = refresh
        notifyOnFailure = draftNotifyOnFailure
        appliedVersion += 1
        versionValue += 1
        resetDraft()
        draftVersionValue += 1
        recordChange("settings_applied")
        return CjguiSharedOperationActionResult(true, false, before, versionValue, "settings_applied")
    }

    private func endpointValidationMessage(text: String): String {
        if (text.size == 0 || !text.startsWith("https://") || text.contains(" ")) {
            return endpointRequiredMessage
        }
        return ""
    }

    private func retryValidationMessage(text: String): String {
        let value = match (Int64.tryParse(text)) {
            case Some(parsed) => parsed
            case None => return retryRangeMessage
        }
        if (value < retryMinimum || value > retryMaximum) {
            return retryRangeMessage
        }
        return ""
    }

    private func refreshValidationMessage(text: String): String {
        let value = match (Int64.tryParse(text)) {
            case Some(parsed) => parsed
            case None => return refreshRangeMessage
        }
        if (value < refreshMinimum || value > refreshMaximum) {
            return refreshRangeMessage
        }
        return ""
    }

    private func isReadOnlyField(fieldId: String): Bool {
        return fieldId == "workspaceId" || fieldId == "lastPublished"
    }

    private func resetDraft() {
        draftEndpoint = endpoint
        draftRetryLimit = retryLimit.toString()
        draftUseProxy = useProxy
        draftDisplayName = displayName
        draftRefreshSeconds = refreshSeconds.toString()
        draftNotifyOnFailure = notifyOnFailure
        baseAppliedVersion = appliedVersion
    }

    private func recordChange(kind: String) {
        changeLog.add(CjguiSharedOperationChangeEntry(versionValue, resourceId, kind))
    }

    private func accepted(reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(true, false, versionValue, versionValue, reason)
    }

    private func rejected(conflict: Bool, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, versionValue, versionValue, reason)
    }

    private func stringArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?String {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "STRING") {
                return Some(argument.value.stringValue)
            }
        }
        return None
    }

    private func integerArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Int64 {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "INTEGER") {
                return Some(argument.value.integerValue)
            }
        }
        return None
    }

    private func booleanArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Bool {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "BOOLEAN") {
                return Some(argument.value.booleanValue)
            }
        }
        return None
    }
}
