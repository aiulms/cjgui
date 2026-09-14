package cjgui_notification_threshold_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.random.*

/// Shared notification-threshold truth used by both the headless public-core
/// consumer and the normal composable window. It deliberately has no renderer
/// dependency and no backup-rule fields.
public class CjguiNotificationThresholdSnapshot {
    public let version: Int64
    public let channel: String
    public let threshold: Int64
    public let enabled: Bool
    public init(version: Int64, channel: String, threshold: Int64, enabled: Bool) {
        this.version = version; this.channel = channel; this.threshold = threshold; this.enabled = enabled
    }
}

public class CjguiNotificationThresholdDomain <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain {
    public static let resourceId: Int64 = 9100
    private var versionValue: Int64
    private var channel: String
    private var threshold: Int64
    private var enabled: Bool
    private var appliedVersion: Int64
    private var draftChannel: String
    private var draftThreshold: String
    private var draftEnabled: Bool
    private var draftVersion: Int64
    private var baseAppliedVersion: Int64
    private let streamIdentity: String
    private let changeLog: ArrayList<CjguiSharedOperationChangeEntry>

    public init() {
        this.versionValue = 0; this.channel = "邮件"; this.threshold = 70; this.enabled = false
        this.appliedVersion = 0; this.draftChannel = channel; this.draftThreshold = threshold.toString(); this.draftEnabled = enabled
        this.draftVersion = 0; this.baseAppliedVersion = 0
        // The descriptor instance has a fresh capability per launch; retaining
        // its identity in the stream name prevents callers from treating a
        // restarted domain's numeric version as the same cursor.
        this.streamIdentity = "notification_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
    }
    public func resourceType(): String { return "notification_threshold" }
    public func notificationSnapshot(): CjguiNotificationThresholdSnapshot {
        return CjguiNotificationThresholdSnapshot(versionValue, channel, threshold, enabled)
    }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(versionValue, "通知阈值", resourceType(), ArrayList<CjguiSharedOperationResource>([
            CjguiSharedOperationResource(CjguiNotificationThresholdDomain.resourceId, "异常提醒", ArrayList<CjguiSharedOperationField>([
                CjguiSharedOperationField("deliveryChannel", CjguiSharedOperationValue.string(channel)),
                CjguiSharedOperationField("triggerThreshold", CjguiSharedOperationValue.integer(threshold)),
                CjguiSharedOperationField("isEnabled", CjguiSharedOperationValue.boolean(enabled)),
                CjguiSharedOperationField("draftChannel", CjguiSharedOperationValue.string(draftChannel)),
                CjguiSharedOperationField("draftThreshold", CjguiSharedOperationValue.string(draftThreshold)),
                CjguiSharedOperationField("draftEnabled", CjguiSharedOperationValue.boolean(draftEnabled)),
                CjguiSharedOperationField("draftVersion", CjguiSharedOperationValue.integer(draftVersion)),
                CjguiSharedOperationField("baseAppliedVersion", CjguiSharedOperationValue.integer(baseAppliedVersion))
            ]))
        ]))
    }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            CjguiSharedOperationActionDescriptor("EDIT_DRAFT_TEXT", "编辑通知草稿文本", ArrayList<CjguiSharedOperationParameterDescriptor>([
                CjguiSharedOperationParameterDescriptor("fieldId", "STRING", true),
                CjguiSharedOperationParameterDescriptor("text", "STRING", true),
                CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
            ]), 1, 1),
            CjguiSharedOperationActionDescriptor("EDIT_DRAFT_BOOLEAN", "编辑通知草稿开关", ArrayList<CjguiSharedOperationParameterDescriptor>([
                CjguiSharedOperationParameterDescriptor("fieldId", "STRING", true),
                CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true),
                CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
            ]), 1, 1),
            CjguiSharedOperationActionDescriptor("APPLY_DRAFT", "应用通知草稿", ArrayList<CjguiSharedOperationParameterDescriptor>([
                CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
            ]), 1, 1),
            CjguiSharedOperationActionDescriptor("CANCEL_DRAFT", "取消通知草稿", ArrayList<CjguiSharedOperationParameterDescriptor>([
                CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
            ]), 1, 1),
            CjguiSharedOperationActionDescriptor("CONFIGURE_NOTIFICATION_THRESHOLD", "配置通知阈值", ArrayList<CjguiSharedOperationParameterDescriptor>([
                CjguiSharedOperationParameterDescriptor("channel", "STRING", true),
                CjguiSharedOperationParameterDescriptor("threshold", "INTEGER", true),
                CjguiSharedOperationParameterDescriptor("enabled", "BOOLEAN", true)
            ]), 1, 1)
        ])
    }
    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return execute(invocation) }
    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return execute(invocation) }
    public func draftSnapshot(): CjguiSharedFormSnapshot {
        return CjguiSharedFormSnapshot(versionValue, appliedVersion, draftVersion, baseAppliedVersion,
            ArrayList<CjguiSharedFormFieldProjection>([
                CjguiSharedFormFieldProjection(9101, "deliveryChannel", CjguiSharedOperationValue.string(channel), draftChannel, "", draftVersion, false, 0, 0),
                CjguiSharedFormFieldProjection(9102, "triggerThreshold", CjguiSharedOperationValue.integer(threshold), draftThreshold, "", draftVersion, false, 0, 0),
                CjguiSharedFormFieldProjection(9103, "isEnabled", CjguiSharedOperationValue.boolean(enabled), if (draftEnabled) { "true" } else { "false" }, "", draftVersion, false, 0, 0)
            ]), baseAppliedVersion == appliedVersion, "通知草稿")
    }
    public func editDraftTextFromHuman(fieldId: String, text: String, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        return editDraftText(fieldId, text, expectedDraftVersion)
    }
    public func editDraftBooleanFromHuman(fieldId: String, value: Bool, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        return editDraftBoolean(fieldId, value, expectedDraftVersion)
    }
    public func applyDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        return applyDraft(expectedDraftVersion, expectedBaseAppliedVersion)
    }
    public func cancelDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersion || expectedBaseAppliedVersion != baseAppliedVersion) { return rejected(true, "stale_draft") }
        resetDraft(); draftVersion += 1; versionValue += 1; recordChange("draft_cancelled"); return accepted("draft_cancelled")
    }
    public func configureFromHuman(nextChannel: String, nextThreshold: Int64, nextEnabled: Bool): CjguiSharedOperationActionResult {
        return execute(CjguiSharedOperationActionInvocation("CONFIGURE_NOTIFICATION_THRESHOLD", versionValue,
            ArrayList<Int64>([CjguiNotificationThresholdDomain.resourceId]), ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("channel", CjguiSharedOperationValue.string(nextChannel)),
                CjguiSharedOperationActionArgument("threshold", CjguiSharedOperationValue.integer(nextThreshold)),
                CjguiSharedOperationActionArgument("enabled", CjguiSharedOperationValue.boolean(nextEnabled))
            ])))
    }
    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>, expectedStreamIdentity: String): CjguiSharedOperationChanges {
        if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) || sinceVersion < 0 || sinceVersion > versionValue) {
            return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, true, ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let changes = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changeLog) {
            if (entry.version > sinceVersion && (resourceFilter.size == 0 || resourceFilter[0] == CjguiNotificationThresholdDomain.resourceId)) {
                changes.add(entry)
            }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, changes)
    }
    private func execute(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = versionValue
        if (invocation.targetResourceIds.size != 1 || invocation.targetResourceIds[0] != CjguiNotificationThresholdDomain.resourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != versionValue) { return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict") }
        if (invocation.actionName == "EDIT_DRAFT_TEXT") {
            if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
                if (let Some(text) <- stringArgument(invocation, "text")) {
                    if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return editDraftText(fieldId, text, expected) }
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "EDIT_DRAFT_BOOLEAN") {
            if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
                if (let Some(value) <- booleanArgument(invocation, "value")) {
                    if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return editDraftBoolean(fieldId, value, expected) }
                }
            }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "APPLY_DRAFT") {
            if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return applyDraft(expected, baseAppliedVersion) }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName == "CANCEL_DRAFT") {
            if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return cancelDraftFromHuman(expected, baseAppliedVersion) }
            return rejected(false, "invalid_parameters")
        }
        if (invocation.actionName != "CONFIGURE_NOTIFICATION_THRESHOLD") { return rejected(false, "invalid_action") }
        if (let Some(nextChannel) <- stringArgument(invocation, "channel")) {
            if (let Some(nextThreshold) <- integerArgument(invocation, "threshold")) {
                if (let Some(nextEnabled) <- booleanArgument(invocation, "enabled")) {
                    if (nextChannel.size == 0 || nextChannel.size > 32) { return CjguiSharedOperationActionResult(false, false, before, before, "invalid_channel") }
                    if (nextThreshold < 1 || nextThreshold > 100) { return CjguiSharedOperationActionResult(false, false, before, before, "threshold_out_of_range") }
                    let hadDraft = hasUnappliedDraft()
                    channel = nextChannel; threshold = nextThreshold; enabled = nextEnabled; appliedVersion += 1; versionValue += 1
                    if (!hadDraft) { resetDraft() }
                    recordChange("notification_configured")
                    return CjguiSharedOperationActionResult(true, false, before, versionValue, "notification_configured")
                }
            }
        }
        return CjguiSharedOperationActionResult(false, false, before, before, "invalid_parameters")
    }
    private func stringArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?String {
        for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "STRING") { return Some(argument.value.stringValue) } }
        return None
    }
    private func integerArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Int64 {
        for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "INTEGER") { return Some(argument.value.integerValue) } }
        return None
    }
    private func booleanArgument(invocation: CjguiSharedOperationActionInvocation, name: String): ?Bool {
        for (argument in invocation.arguments) { if (argument.name == name && argument.value.valueType == "BOOLEAN") { return Some(argument.value.booleanValue) } }
        return None
    }
    private func editDraftText(fieldId: String, text: String, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersion) { return rejected(true, "draft_version_conflict") }
        if (fieldId == "deliveryChannel") { draftChannel = text }
        else if (fieldId == "triggerThreshold") { draftThreshold = text }
        else { return rejected(false, "unknown_draft_field") }
        draftVersion += 1; versionValue += 1; recordChange("draft_updated"); return accepted("draft_updated")
    }
    private func editDraftBoolean(fieldId: String, value: Bool, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersion) { return rejected(true, "draft_version_conflict") }
        if (fieldId != "isEnabled") { return rejected(false, "unknown_draft_field") }
        draftEnabled = value; draftVersion += 1; versionValue += 1; recordChange("draft_updated"); return accepted("draft_updated")
    }
    private func applyDraft(expectedDraftVersion: Int64, expectedBaseAppliedVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersion || expectedBaseAppliedVersion != appliedVersion) { return rejected(true, "stale_draft") }
        if (draftChannel.size == 0 || draftChannel.size > 32) { return rejected(false, "invalid_channel") }
        if (let Some(value) <- Int64.tryParse(draftThreshold)) {
            if (value >= 1 && value <= 100) {
                let before = versionValue; channel = draftChannel; threshold = value; enabled = draftEnabled
                appliedVersion += 1; versionValue += 1; resetDraft(); draftVersion += 1; recordChange("draft_applied")
                return CjguiSharedOperationActionResult(true, false, before, versionValue, "draft_applied")
            }
        }
        return rejected(false, "threshold_out_of_range")
    }
    private func hasUnappliedDraft(): Bool { return draftChannel != channel || draftThreshold != threshold.toString() || draftEnabled != enabled }
    private func resetDraft() { draftChannel = channel; draftThreshold = threshold.toString(); draftEnabled = enabled; baseAppliedVersion = appliedVersion }
    private func recordChange(kind: String) { changeLog.add(CjguiSharedOperationChangeEntry(versionValue, CjguiNotificationThresholdDomain.resourceId, kind)) }
    private func accepted(reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(true, false, versionValue, versionValue, reason) }
    private func rejected(conflict: Bool, reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(false, conflict, versionValue, versionValue, reason) }
}
