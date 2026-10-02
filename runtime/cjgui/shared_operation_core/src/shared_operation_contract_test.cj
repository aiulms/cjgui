package cjgui_shared_operation_core

import std.collection.*
import std.sync.*
import std.unittest.*
import std.unittest.testmacro.*

private class BackupRuleContractDomain <: CjguiSharedOperationDomain {
    private let lock: Mutex
    private var currentVersion: Int64
    private var enabled: Bool
    private var retentionCount: Int64
    private var excludedType: String

    init(excludedType!: String = "cache") {
        this.lock = Mutex()
        this.currentVersion = 0
        this.enabled = false
        this.retentionCount = 7
        this.excludedType = excludedType
    }

    public func resourceType(): String {
        return "backup_rule"
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return synchronized(lock) {
            CjguiSharedOperationContextSnapshot(
                currentVersion,
                "备份规则",
                resourceType(),
                ArrayList<CjguiSharedOperationResource>(
                    [
                        CjguiSharedOperationResource(
                            42,
                            "家庭照片备份",
                            ArrayList<CjguiSharedOperationField>(
                                [
                                    CjguiSharedOperationField(
                                        "enabled",
                                        CjguiSharedOperationValue.boolean(enabled)
                                    ),
                                    CjguiSharedOperationField(
                                        "retentionCount",
                                        CjguiSharedOperationValue.integer(retentionCount)
                                    ),
                                    CjguiSharedOperationField(
                                        "excludedType",
                                        CjguiSharedOperationValue.string(excludedType)
                                    )
                                ]
                            )
                        )
                    ]
                )
            )
        }
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>(
            [
                CjguiSharedOperationActionDescriptor(
                    "APPLY_BACKUP_RULE",
                    "应用备份规则",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("enabled", "BOOLEAN", true),
                            CjguiSharedOperationParameterDescriptor("retentionCount", "INTEGER", true),
                            CjguiSharedOperationParameterDescriptor("excludedType", "STRING", true)
                        ]
                    ),
                    1,
                    1
                )
            ]
        )
    }

    public func executeFromHuman(
        invocation: CjguiSharedOperationActionInvocation
    ): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            executeUnlocked(invocation, false)
        }
    }

    public func executeFromExternal(
        invocation: CjguiSharedOperationActionInvocation
    ): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            executeUnlocked(invocation, true)
        }
    }

    private func executeUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        requiresCurrentVersion: Bool
    ): CjguiSharedOperationActionResult {
        let versionBefore = currentVersion
        if (requiresCurrentVersion && invocation.expectedVersion != currentVersion) {
            return CjguiSharedOperationActionResult(false, true, versionBefore, currentVersion, "version_conflict")
        }
        if (invocation.actionName != "APPLY_BACKUP_RULE") {
            return CjguiSharedOperationActionResult(false, false, versionBefore, currentVersion, "unknown_action")
        }
        if (invocation.targetResourceIds.size != 1 || invocation.targetResourceIds[0] != 42) {
            return CjguiSharedOperationActionResult(false, false, versionBefore, currentVersion, "unknown_resource")
        }
        if (let Some(requestedEnabled) <- booleanArgument(invocation, "enabled")) {
            if (let Some(requestedRetention) <- integerArgument(invocation, "retentionCount")) {
                if (let Some(requestedExcludedType) <- stringArgument(invocation, "excludedType")) {
                    if (requestedRetention < 1 || requestedRetention > 60 || requestedExcludedType.size == 0) {
                        return CjguiSharedOperationActionResult(false, false, versionBefore, currentVersion, "invalid_backup_rule")
                    }
                    if (enabled == requestedEnabled && retentionCount == requestedRetention && excludedType == requestedExcludedType) {
                        return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "already_at_target")
                    }
                    enabled = requestedEnabled
                    retentionCount = requestedRetention
                    excludedType = requestedExcludedType
                    currentVersion += 1
                    return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "applied")
                }
            }
        }
        return CjguiSharedOperationActionResult(false, false, versionBefore, currentVersion, "invalid_backup_rule")
    }

    private func booleanArgument(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?Bool {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "BOOLEAN") {
                return Some(argument.value.booleanValue)
            }
        }
        return None
    }

    private func integerArgument(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?Int64 {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "INTEGER") {
                return Some(argument.value.integerValue)
            }
        }
        return None
    }

    private func stringArgument(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?String {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "STRING") {
                return Some(argument.value.stringValue)
            }
        }
        return None
    }
}

private func backupRuleAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "纯仓颉验收 Agent",
        "core-contract-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([42]), false),
                CjguiSharedOperationExternalActionScope("APPLY_BACKUP_RULE", ArrayList<Int64>([42]), false)
            ]
        )
    )
}

/// The full and explicit-target paths deliberately count independently.  The
/// test proves a target response did not merely serialize a full owner
/// snapshot and filter it later in the transport.
private class TargetedContextProbeDomain <: CjguiSharedOperationDomain & CjguiSharedOperationTargetedContextDomain {
    private var fullSnapshotReads: Int64
    private var targetedSnapshotReads: Int64

    init() {
        this.fullSnapshotReads = 0
        this.targetedSnapshotReads = 0
    }

    public func resourceType(): String { return "target_probe" }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        fullSnapshotReads += 1
        return snapshotFor(ArrayList<Int64>([101, 102]))
    }
    public func contextSnapshotForExternalTargets(targets: ArrayList<Int64>): ?CjguiSharedOperationContextSnapshot {
        targetedSnapshotReads += 1
        for (resourceId in targets) {
            if (resourceId != 101 && resourceId != 102) { return None }
        }
        return Some(snapshotFor(targets))
    }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>()
    }
    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 0, 0, "not_supported")
    }
    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 0, 0, "not_supported")
    }
    public func fullReadCount(): Int64 { return fullSnapshotReads }
    public func targetedReadCount(): Int64 { return targetedSnapshotReads }

    private func snapshotFor(ids: ArrayList<Int64>): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        for (resourceId in ids) {
            resources.add(CjguiSharedOperationResource(resourceId, "resource_${resourceId}",
                ArrayList<CjguiSharedOperationField>([
                    CjguiSharedOperationField("ordinal", CjguiSharedOperationValue.integer(resourceId))
                ])))
        }
        return CjguiSharedOperationContextSnapshot(7, "定向读取", resourceType(), resources)
    }
}

private func targetedContextAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "定向读取验收调用者", "targeted-context-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([101, 102]), false)
        ])
    )
}

private class WindowProgressProbe <: CjguiSharedOperationWindowProgressProvider {
    public func windowProgress(): CjguiSharedOperationWindowProgress {
        return CjguiSharedOperationWindowProgress(
            true, 13, 12, "unavailable", "progress_window_1",
            13, 12, 44, 43, -1, 71, 13, "none", "none",
            9, "field_title", true, 3, 5, "edit_dialog",
            focusState: CJGUI_WINDOW_FOCUS_STATE_VALID,
            effectIdentity: "root_backdrop", effectRequestedRadiusPoints: 8,
            effectSubmittedSceneVersion: 13, effectSubmittedFrameIndex: 44,
            effectSubmittedRadiusPoints: 8, effectSubmittedMode: "unblurred",
            effectFallbackReason: "resource_budget", effectCompletion: "succeeded",
            windowBackgroundRequested: "system_material",
            windowBackgroundBackend: "appkit_behind_window",
            windowBackgroundActual: "opaque",
            windowBackgroundFallbackReason: "reduce_transparency",
            windowBackgroundAcceptedSceneVersion: 13,
            windowBackgroundFrameIndex: 44,
            windowBackgroundRequestRevision: 3,
            windowBackgroundEnvironmentRevision: 4,
            windowBackgroundObservationRevision: 5,
            windowBackgroundCompletion: "succeeded",
            windowBackgroundReduceTransparency: true,
            windowBackgroundActive: true,
            windowBackgroundColorScheme: "dark",
            workload: CjguiSharedOperationWindowWorkload("enabled", 13, 21, 7, 4, 3, 2, 65536,
                "accepted", 1, 1, 0, 0, 0),
            geometry: CjguiSharedOperationWindowGeometry("available", 320.5, 180.25, 2.0,
                641, 361, 7, "committed", 320.5, 180.25, 1.0, 321, 181, 6, 12, 44)
        )
    }
}

/// A probe whose focus fact is scripted, so the three published states can be
/// told apart instead of collapsing into "focused / not focused".
private class ScriptedFocusProbe <: CjguiSharedOperationWindowProgressProvider {
    private let fact: String
    private let controlId: String

    public init(fact: String, controlId: String) {
        this.fact = fact
        this.controlId = controlId
    }

    public func windowProgress(): CjguiSharedOperationWindowProgress {
        return CjguiSharedOperationWindowProgress(
            true, 13, 12, "unavailable", "progress_window_1",
            13, 12, 44, 43, -1, 71, 13, "none", "none",
            9, controlId, false, 0, 0, "none",
            focusState: fact
        )
    }
}

private func windowProgressAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "窗口进度验收调用者", "window-progress-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([42]), false),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true)
        ])
    )
}

private func restrictedWindowInteractionAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "窄交互读取验收调用者", "restricted-window-interaction-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([42]), false),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>([42]), false)
        ])
    )
}

private func fullWindowInteractionAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "完整交互读取验收调用者", "full-window-interaction-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([42]), false),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true)
        ])
    )
}

private func applyBackupRulePayload(
    expectedVersion: Int64,
    targetResourceId: Int64,
    enabled: Bool,
    retentionCount: Int64,
    excludedTypeHex: String
): String {
    let enabledValue = if (enabled) { 1 } else { 0 }
    let excludedTypeByteCount = excludedTypeHex.size / 2
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nINVOKE ${expectedVersion} APPLY_BACKUP_RULE 1 3\nID ${targetResourceId}\nARG enabled BOOLEAN ${enabledValue}\nARG retentionCount INTEGER ${retentionCount}\nARG excludedType STRING ${excludedTypeByteCount} ${excludedTypeHex}"
}

@Test
func genericTransportDescribesAndExecutesDeveloperRegisteredAction(): Unit {
    let domain = BackupRuleContractDomain()
    let connection = CjguiSharedOperationExternalConnection(domain, backupRuleAuthorization())

    let snapshot = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )
    @Assert(snapshot.contains("KIND SNAPSHOT"), true)
    @Assert(snapshot.contains("RESOURCE_TYPE_UTF8_HEX 11 6261636B75705F72756C65"), true)
    @Assert(snapshot.contains("ACTION APPLY_BACKUP_RULE PARAMETERS 3 TARGETS 1 1"), true)
    @Assert(snapshot.contains("PARAMETER APPLY_BACKUP_RULE enabled BOOLEAN REQUIRED"), true)
    @Assert(snapshot.contains("FIELD 42 retentionCount INTEGER 7"), true)

    let applied = connection.dispatchPayload(applyBackupRulePayload(0, 42, true, 14, "746D70"))
    @Assert(applied.contains("KIND RESULT"), true)
    @Assert(applied.contains("APPLIED true"), true)
    @Assert(applied.contains("VERSION_AFTER 1"), true)

    let readBack = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )
    @Assert(readBack.contains("VERSION 1"), true)
    @Assert(readBack.contains("FIELD 42 enabled BOOLEAN 1"), true)
    @Assert(readBack.contains("FIELD 42 retentionCount INTEGER 14"), true)
    @Assert(readBack.contains("FIELD 42 excludedType STRING 3 746D70"), true)
}

@Test
func genericTransportUsesARealTokenForAnEmptyStringField(): Unit {
    let domain = BackupRuleContractDomain(excludedType: "")
    let connection = CjguiSharedOperationExternalConnection(domain, backupRuleAuthorization())
    let snapshot = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )
    // `-` is the explicit zero-byte token. A trailing space would make a
    // public line protocol unparseable even though the domain value is valid.
    @Assert(snapshot.contains("FIELD 42 excludedType STRING 0 -"), true)
}

@Test
func genericTransportRejectsUnauthorizedInvalidAndStaleCallsBeforeBusinessMutation(): Unit {
    let domain = BackupRuleContractDomain()
    let connection = CjguiSharedOperationExternalConnection(domain, backupRuleAuthorization())

    let invalidType = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nINVOKE 0 APPLY_BACKUP_RULE 1 3\nID 42\nARG enabled STRING 1 31\nARG retentionCount INTEGER 14\nARG excludedType STRING 3 746D70"
    )
    @Assert(invalidType.contains("ERROR invalid_parameters"), true)
    @Assert(domain.contextSnapshot().version, 0)

    let unauthorizedTarget = connection.dispatchPayload(applyBackupRulePayload(0, 43, true, 14, "746D70"))
    @Assert(unauthorizedTarget.contains("ERROR unauthorized_resource"), true)
    @Assert(domain.contextSnapshot().version, 0)

    let hiddenRead = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 43"
    )
    @Assert(hiddenRead.contains("ERROR unauthorized_resource"), true)

    let first = connection.dispatchPayload(applyBackupRulePayload(0, 42, true, 14, "746D70"))
    @Assert(first.contains("VERSION_AFTER 1"), true)
    let stale = connection.dispatchPayload(applyBackupRulePayload(0, 42, false, 7, "6361636865"))
    @Assert(stale.contains("CONFLICT true"), true)
    @Assert(domain.contextSnapshot().version, 1)
}

private class ScopedRelationDomain <: CjguiSharedOperationDomain {
    public func resourceType(): String { return "scoped_relation" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(
            4,
            "关系可见性",
            resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(42, "允许对象", ArrayList<CjguiSharedOperationField>()),
                CjguiSharedOperationResource(43, "禁止对象", ArrayList<CjguiSharedOperationField>())
            ]),
            relations: ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", "allowedWindow", "CONTAINS", "control", "allowedControl", resourceIds: ArrayList<Int64>([42])),
                CjguiSharedOperationRelation("control", "allowedControl", "BINDS", "resource", "resource42", resourceIds: ArrayList<Int64>([42])),
                CjguiSharedOperationRelation("window", "hiddenWindow", "CONTAINS", "control", "hiddenControl", resourceIds: ArrayList<Int64>([43])),
                CjguiSharedOperationRelation("control", "hiddenControl", "BINDS", "resource", "resource43", resourceIds: ArrayList<Int64>([43]))
            ])
        )
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 4, 4, "not_supported")
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 4, 4, "not_supported")
    }
}

@Test
func genericTransportFiltersRelationScopesAlongsideExplicitTargets(): Unit {
    let authorization = CjguiSharedOperationExternalAuthorization(
        "关系读取者",
        "scoped-relation-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
    let connection = CjguiSharedOperationExternalConnection(ScopedRelationDomain(), authorization)
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH scoped-relation-capability\nGET_CONTEXT 1\nID 42"
    )

    @Assert(response.contains("RELATION window allowedWindow CONTAINS control allowedControl"), true)
    @Assert(response.contains("RELATION control allowedControl BINDS resource resource42"), true)
    @Assert(response.contains("hiddenWindow"), false)
    @Assert(response.contains("hiddenControl"), false)
}

private class StaticWindowProjection <: CjguiSharedOperationWindowProjectionProvider {
    public func windowProjection(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            true,
            71,
            71,
            "unavailable",
            "allowedControl",
            1,
            3,
            ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", "actualWindow", "CONTAINS", "control", "allowedControl", resourceIds: ArrayList<Int64>([42])),
                CjguiSharedOperationRelation("control", "allowedControl", "BINDS", "resource", "resource42", resourceIds: ArrayList<Int64>([42]))
            ]),
            nodes: ArrayList<CjguiSharedOperationWindowNode>([
                CjguiSharedOperationWindowNode(1, "actualWindow", "window", ArrayList<Int64>()),
                CjguiSharedOperationWindowNode(13, "allowedControl", "control", ArrayList<Int64>([42]))
            ]),
            fieldValues: ArrayList<CjguiSharedOperationWindowFieldValue>([
                CjguiSharedOperationWindowFieldValue(
                    "allowedControl", 42, "excludedType", "draft", "component_value",
                    CjguiSharedOperationValue.string("pending")
                )
            ]),
            collections: ArrayList<CjguiSharedOperationWindowCollection>([
                CjguiSharedOperationWindowCollection("rule_list", 2000, 1497, 1504, "rule_1500", "rule_1500")
            ]),
            hasTextSelection: true
        )
    }
}

private class TargetedWindowProjectionProbe <: CjguiSharedOperationWindowProjectionTargetProvider & CjguiSharedOperationWindowProgressTargetProvider {
    private var includesFirst: Bool

    init() {
        this.includesFirst = true
    }

    public func windowProjectionTargets(): ArrayList<String> {
        if (includesFirst) {
            return ArrayList<String>(["application_a_window_1", "application_a_window_2"])
        }
        return ArrayList<String>(["application_a_window_2"])
    }

    public func windowProjectionForTarget(target: String): ?CjguiSharedOperationWindowProjection {
        if (target == "application_a_window_1" && includesFirst) {
            return Some(targetProjection("first_window"))
        }
        if (target == "application_a_window_2") {
            return Some(targetProjection("second_window"))
        }
        return None
    }

    public func closeFirstWindow(): Unit {
        includesFirst = false
    }

    public func windowProgressForTarget(target: String): ?CjguiSharedOperationWindowProgress {
        if (target == "application_a_window_1" && includesFirst) {
            return Some(targetProgress("first_target_session", "first_control", 3, 5, "first_layer"))
        }
        if (target == "application_a_window_2") {
            return Some(targetProgress("second_target_session", "second_control", 7, 9, "second_layer"))
        }
        return None
    }

    private func targetProjection(rootId: String): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            true, 9, 9, "unavailable", "target_probe_session", 0, 0,
            ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", rootId, "CONTAINS", "control", "allowedControl",
                    resourceIds: ArrayList<Int64>([42]))
            ]),
            nodes: ArrayList<CjguiSharedOperationWindowNode>([
                CjguiSharedOperationWindowNode(1, rootId, "window", ArrayList<Int64>()),
                CjguiSharedOperationWindowNode(2, "allowedControl", "control", ArrayList<Int64>([42]))
            ])
        )
    }

    private func targetProgress(
        session: String,
        focusedControl: String,
        selectionStart: Int64,
        selectionEnd: Int64,
        activeLayer: String
    ): CjguiSharedOperationWindowProgress {
        // The probe must declare the focus fact it really represents: a named
        // control is a confirmable live focus, "none" is unfocused. Declaring a
        // control id while leaving the state unconfirmed is refused on purpose.
        let state = if (focusedControl.size == 0 || focusedControl == "none") {
            CJGUI_WINDOW_FOCUS_STATE_UNFOCUSED
        } else {
            CJGUI_WINDOW_FOCUS_STATE_VALID
        }
        return CjguiSharedOperationWindowProgress(
            true, 9, 9, "unavailable", session, 9, 9, 19, 18, -1, 31, 9,
            "none", "none", 4, focusedControl, true, selectionStart, selectionEnd, activeLayer,
            focusState: state
        )
    }
}

private func targetedWindowProjectionAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "定向窗口读取验收调用者", "targeted-window-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
}

private func targetedWindowObservationAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "定向窗口观测验收调用者", "targeted-window-observation-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true)
        ])
    )
}

@Test
func genericTransportEnumeratesAndReadsAnExactLiveWindowTargetWithoutFallback(): Unit {
    let provider = TargetedWindowProjectionProbe()
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), targetedWindowProjectionAuthorization()
    )
    @Assert(connection.enableWindowProjectionTargetReads(provider), true)

    let targets = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-capability\nGET_WINDOW_TARGETS"
    )
    @Assert(targets.contains("KIND WINDOW_TARGETS"), true)
    @Assert(targets.contains("WINDOW_TARGET application_a_window_1"), true)
    @Assert(targets.contains("WINDOW_TARGET application_a_window_2"), true)

    let first = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-capability\nGET_WINDOW_CONTEXT application_a_window_1"
    )
    @Assert(first.contains("WINDOW_TARGET application_a_window_1"), true)
    @Assert(first.contains("WINDOW_NODE first_window 1 window"), true)
    @Assert(first.contains("second_window"), false)

    let second = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-capability\nGET_WINDOW_CONTEXT application_a_window_2"
    )
    @Assert(second.contains("WINDOW_TARGET application_a_window_2"), true)
    @Assert(second.contains("WINDOW_NODE second_window 1 window"), true)

    provider.closeFirstWindow()
    let closed = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-capability\nGET_WINDOW_CONTEXT application_a_window_1"
    )
    @Assert(closed.contains("ERROR unknown_window_target"), true)
    let stillLive = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-capability\nGET_WINDOW_CONTEXT application_a_window_2"
    )
    @Assert(stillLive.contains("WINDOW_NODE second_window 1 window"), true)
}

@Test
func genericTransportReadsTargetedProgressAndInteractionWithoutSiblingFallback(): Unit {
    let provider = TargetedWindowProjectionProbe()
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), targetedWindowObservationAuthorization()
    )
    @Assert(connection.enableWindowProjectionTargetReads(provider), true)
    @Assert(connection.enableWindowProgressTargetReads(provider), true)

    let firstProgress = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-observation-capability\nGET_WINDOW_PROGRESS application_a_window_1"
    )
    @Assert(firstProgress.contains("WINDOW_TARGET application_a_window_1"), true)
    @Assert(firstProgress.contains("WINDOW_SESSION first_target_session"), true)
    @Assert(firstProgress.contains("second_target_session"), false)

    let secondInteraction = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-observation-capability\nGET_WINDOW_INTERACTION application_a_window_2"
    )
    @Assert(secondInteraction.contains("WINDOW_TARGET application_a_window_2"), true)
    @Assert(secondInteraction.contains("WINDOW_SESSION second_target_session"), true)
    @Assert(secondInteraction.contains("WINDOW_FOCUS second_control"), true)
    @Assert(secondInteraction.contains("WINDOW_SELECTION second_control 7 9"), true)

    provider.closeFirstWindow()
    let closedProgress = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-observation-capability\nGET_WINDOW_PROGRESS application_a_window_1"
    )
    let closedInteraction = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-observation-capability\nGET_WINDOW_INTERACTION application_a_window_1"
    )
    let survivingProgress = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-window-observation-capability\nGET_WINDOW_PROGRESS application_a_window_2"
    )
    @Assert(closedProgress.contains("ERROR unknown_window_target"), true)
    @Assert(closedInteraction.contains("ERROR unknown_window_target"), true)
    @Assert(survivingProgress.contains("WINDOW_TARGET application_a_window_2"), true)
    @Assert(survivingProgress.contains("WINDOW_SESSION second_target_session"), true)
}

@Test
func genericTransportAddsOnlyAnActiveProjectionProvidedByTheWindow(): Unit {
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(),
        backupRuleAuthorization(),
        StaticWindowProjection()
    )
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )
    @Assert(response.contains("WINDOW_PROJECTION ACTIVE"), true)
    @Assert(response.contains("WINDOW_SCENE_VERSION 71"), true)
    @Assert(response.contains("WINDOW_PRESENTATION_STATE unavailable"), true)
    @Assert(response.contains("WINDOW_SESSION unavailable"), true)
    @Assert(response.contains("WINDOW_ACCEPTED_SCENE_VERSION 0"), true)
    @Assert(response.contains("WINDOW_SUBMITTED_SCENE_VERSION -1"), true)
    @Assert(response.contains("WINDOW_OVERLAY_DRAWN_SCENE_VERSION -1"), true)
    @Assert(response.contains("WINDOW_REFRESH_PENDING none"), true)
    @Assert(response.contains("WINDOW_WORK_COUNTS 0 0 0"), true)
    @Assert(response.contains("WINDOW_WORK_TIMING_MS 0 0 0 0"), true)
    @Assert(response.contains("WINDOW_MEASUREMENT_CALL_COUNT 0"), true)
    @Assert(response.contains("WINDOW_LAYOUT_REUSE 0 0 0 0 0"), true)
    @Assert(response.contains("WINDOW_FOCUS control allowedControl"), true)
    @Assert(response.contains("WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT"), true)
    @Assert(response.contains("WINDOW_SELECTION allowedControl 1 3"), true)
    // A target-scoped caller must not infer the logical collection's count or
    // off-screen range from a single visible resource.
    @Assert(response.contains("WINDOW_COLLECTION rule_list"), false)
    @Assert(response.contains("WINDOW_NODE allowedControl 13 control"), true)
    @Assert(response.contains("RELATION window actualWindow CONTAINS control allowedControl"), true)
    @Assert(response.contains("WINDOW_FIELD_VALUE allowedControl 42 excludedType draft component_value STRING 7 70656E64696E67"), true)
    @Assert(connection.consumeWindowRefreshRequest(), false)
    let applied = connection.dispatchPayload(applyBackupRulePayload(0, 42, true, 14, "746D70"))
    @Assert(applied.contains("APPLIED true"), true)
    @Assert(connection.consumeWindowRefreshRequest(), true)
    @Assert(connection.consumeWindowRefreshRequest(), false)
    let stale = connection.dispatchPayload(applyBackupRulePayload(0, 42, false, 7, "6361636865"))
    @Assert(stale.contains("CONFLICT true"), true)
    @Assert(connection.consumeWindowRefreshRequest(), false)
}

@Test
func genericTransportPublishesLogicalCollectionOnlyToFullContextReader(): Unit {
    let fullContextAuthorization = CjguiSharedOperationExternalAuthorization(
        "完整上下文读取者",
        "full-context-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), fullContextAuthorization, StaticWindowProjection()
    )
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-context-capability\nGET_CONTEXT 0"
    )
    @Assert(response.contains("WINDOW_COLLECTION rule_list 2000 1497 1504 rule_1500 rule_1500"), true)
}

private class ButtonFocusedWindowProjection <: CjguiSharedOperationWindowProjectionProvider {
    public func windowProjection(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            true,
            73,
            -1,
            "unavailable",
            "apply-notification",
            5,
            5,
            ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", "notification-root", "CONTAINS", "control", "apply-notification", resourceIds: ArrayList<Int64>([42])),
                CjguiSharedOperationRelation("control", "apply-notification", "INVOKES", "action", "APPLY_DRAFT", resourceIds: ArrayList<Int64>([42]))
            ]),
            nodes: ArrayList<CjguiSharedOperationWindowNode>([
                CjguiSharedOperationWindowNode(1, "notification-root", "window", ArrayList<Int64>()),
                CjguiSharedOperationWindowNode(31, "apply-notification", "control", ArrayList<Int64>([42]))
            ]),
            hasTextSelection: false
        )
    }
}

@Test
func genericTransportDoesNotMislabelButtonFocusAsATextSelection(): Unit {
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(),
        backupRuleAuthorization(),
        ButtonFocusedWindowProjection()
    )
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )

    @Assert(response.contains("WINDOW_FOCUS control apply-notification"), true)
    @Assert(response.contains("WINDOW_SELECTION"), false)
}

private class DashedWindowProjection <: CjguiSharedOperationWindowProjectionProvider {
    public func windowProjection(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            true,
            72,
            -1,
            "unavailable",
            "delivery-channel",
            0,
            0,
            ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", "notification-root", "CONTAINS", "control", "delivery-channel", resourceIds: ArrayList<Int64>([42])),
                CjguiSharedOperationRelation("control", "delivery-channel", "BINDS", "field", "resource42_deliveryChannel", resourceIds: ArrayList<Int64>([42]))
            ]),
            nodes: ArrayList<CjguiSharedOperationWindowNode>([
                CjguiSharedOperationWindowNode(1, "notification-root", "window", ArrayList<Int64>()),
                CjguiSharedOperationWindowNode(13, "delivery-channel", "control", ArrayList<Int64>([42]))
            ])
        )
    }
}

@Test
func genericTransportAcceptsDashedSemanticIdsFromComposableWindowTrees(): Unit {
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(),
        backupRuleAuthorization(),
        DashedWindowProjection()
    )
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )

    @Assert(response.contains("KIND SNAPSHOT"), true)
    @Assert(response.contains("WINDOW_NODE notification-root 1 window"), true)
    @Assert(response.contains("RELATION window notification-root CONTAINS control delivery-channel"), true)
}

// A projection validation failure is not a wire-size failure.  Keep this
// deliberately invalid token in a core-only fixture so a client gets an
// actionable protocol error without disclosing any caller capability or
// application value.
private class UnsafeProjectionIdentifier <: CjguiSharedOperationWindowProjectionProvider {
    public func windowProjection(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(
            true,
            74,
            -1,
            "unavailable",
            "unsafe:control",
            0,
            0,
            ArrayList<CjguiSharedOperationRelation>([
                CjguiSharedOperationRelation("window", "safe-window", "CONTAINS", "control", "unsafe:control", resourceIds: ArrayList<Int64>([42]))
            ]),
            nodes: ArrayList<CjguiSharedOperationWindowNode>([
                CjguiSharedOperationWindowNode(1, "safe-window", "window", ArrayList<Int64>()),
                CjguiSharedOperationWindowNode(13, "unsafe:control", "control", ArrayList<Int64>([42]))
            ])
        )
    }
}

@Test
func genericTransportClassifiesInvalidProjectionInsteadOfClaimingItIsTooLarge(): Unit {
    let connection = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), backupRuleAuthorization(), UnsafeProjectionIdentifier()
    )
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )

    @Assert(response.contains("ERROR invalid_snapshot"), true)
    @Assert(response.contains("response_too_large"), false)
}

@Test
func genericTransportDoesNotInventAWindowForHeadlessDomains(): Unit {
    let connection = CjguiSharedOperationExternalConnection(BackupRuleContractDomain(), backupRuleAuthorization())
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 1\nID 42"
    )

    @Assert(response.contains("WINDOW_PROJECTION NONE"), true)
    @Assert(response.contains("actualWindow"), false)
}

@Test
func genericTransportUsesOwnerTargetedSnapshotWithoutBuildingTheFullContext(): Unit {
    let domain = TargetedContextProbeDomain()
    let connection = CjguiSharedOperationExternalConnection(domain, targetedContextAuthorization())
    @Assert(connection.enableTargetedContextReads(domain), true)

    let targeted = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-context-capability\nGET_CONTEXT 1\nID 101"
    )
    @Assert(targeted.contains("KIND SNAPSHOT"), true)
    @Assert(targeted.contains("RESOURCE 101"), true)
    @Assert(targeted.contains("RESOURCE 102"), false)
    @Assert(domain.fullReadCount(), 0)
    @Assert(domain.targetedReadCount(), 1)

    let complete = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH targeted-context-capability\nGET_CONTEXT 0"
    )
    @Assert(complete.contains("RESOURCE 101"), true)
    @Assert(complete.contains("RESOURCE 102"), true)
    @Assert(domain.fullReadCount(), 1)
    @Assert(domain.targetedReadCount(), 1)
}

@Test
func genericTransportReadsNarrowWindowProgressWithoutSerializingContextResources(): Unit {
    let connection = CjguiSharedOperationExternalConnection(BackupRuleContractDomain(), windowProgressAuthorization())
    @Assert(connection.enableWindowProgressReads(WindowProgressProbe()), true)

    let progress = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH window-progress-capability\nGET_WINDOW_PROGRESS"
    )
    @Assert(progress.contains("KIND WINDOW_PROGRESS"), true)
    @Assert(progress.contains("WINDOW_PROJECTION ACTIVE"), true)
    @Assert(progress.contains("WINDOW_SESSION progress_window_1"), true)
    @Assert(progress.contains("WINDOW_SCENE_VERSION 13"), true)
    @Assert(progress.contains("WINDOW_METAL_COMPLETED_FRAME_INDEX 43"), true)
    @Assert(progress.contains("WINDOW_CURRENT_POINT_SIZE 320.500000 180.250000"), true)
    @Assert(progress.contains("WINDOW_CURRENT_DRAWABLE_PIXELS 641 361"), true)
    @Assert(progress.contains("WINDOW_CURRENT_GEOMETRY_REVISION 7"), true)
    @Assert(progress.contains("WINDOW_SUBMITTED_BACKING_SCALE 1.000000"), true)
    @Assert(progress.contains("WINDOW_SUBMITTED_GEOMETRY_SCENE_VERSION 12"), true)
    @Assert(progress.contains("WINDOW_SUBMITTED_GEOMETRY_FRAME_INDEX 44"), true)
    @Assert(progress.contains("WINDOW_EFFECT_ID root_backdrop"), true)
    @Assert(progress.contains("WINDOW_EFFECT_REQUESTED_RADIUS_POINTS 8"), true)
    @Assert(progress.contains("WINDOW_EFFECT_SUBMITTED_SCENE_VERSION 13"), true)
    @Assert(progress.contains("WINDOW_EFFECT_SUBMITTED_FRAME_INDEX 44"), true)
    @Assert(progress.contains("WINDOW_EFFECT_SUBMITTED_MODE unblurred"), true)
    @Assert(progress.contains("WINDOW_EFFECT_FALLBACK_REASON resource_budget"), true)
    @Assert(progress.contains("WINDOW_EFFECT_COMPLETION succeeded"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_IDENTITY window_content_background"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_REQUESTED system_material"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_BACKEND appkit_behind_window"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_ACTUAL opaque"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_FALLBACK_REASON reduce_transparency"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_ACCEPTED_SCENE_VERSION 13"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_FRAME_INDEX 44"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_REQUEST_REVISION 3"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_ENVIRONMENT_REVISION 4"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_OBSERVATION_REVISION 5"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_COMPLETION succeeded"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_REDUCE_TRANSPARENCY true"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_ACTIVE true"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_VISUAL_RESULT unobserved"), true)
    @Assert(progress.contains("WINDOW_BACKGROUND_COLOR_SCHEME dark"), true)
    @Assert(progress.contains("WINDOW_WORKLOAD_STATUS enabled"), true)
    @Assert(progress.contains("WINDOW_WORKLOAD_SCENE_VERSION 13"), true)
    @Assert(progress.contains("WINDOW_WORKLOAD_NODE_WRITES 21"), true)
    @Assert(progress.contains("WINDOW_WORKLOAD_LAST_ATTEMPT_NODE_WRITES 1"), true)
    @Assert(progress.contains("WINDOW_WORKLOAD_REUSABLE_RESOURCE_BYTES 65536"), true)
    @Assert(progress.contains("WINDOW_INTERACTION_VERSION"), false)
    @Assert(progress.contains("WINDOW_FOCUS"), false)
    @Assert(progress.contains("WINDOW_SELECTION"), false)
    @Assert(progress.contains("WINDOW_ACTIVE_LAYER"), false)
    @Assert(progress.contains("RESOURCE 42"), false)
    @Assert(progress.contains("VERSION 0"), false)

    let missingInteractionGrant = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH window-progress-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(missingInteractionGrant.contains("ERROR unauthorized_action"), true)
}

@Test
func windowBackgroundProgressHasNeutralDefaultsAndNeverClaimsVisualOutput(): Unit {
    let progress = CjguiSharedOperationWindowProgress.inactive()
    @Assert(progress.windowBackgroundIdentity, "window_content_background")
    @Assert(progress.windowBackgroundRequested, "opaque")
    @Assert(progress.windowBackgroundBackend, "unavailable")
    @Assert(progress.windowBackgroundActual, "opaque")
    @Assert(progress.windowBackgroundFallbackReason, "not_requested")
    @Assert(progress.windowBackgroundAcceptedSceneVersion, -1)
    @Assert(progress.windowBackgroundFrameIndex, -1)
    @Assert(progress.windowBackgroundRequestRevision, 0)
    @Assert(progress.windowBackgroundEnvironmentRevision, 0)
    @Assert(progress.windowBackgroundObservationRevision, 0)
    @Assert(progress.windowBackgroundCompletion, "unavailable")
    @Assert(progress.windowBackgroundReduceTransparency, false)
    @Assert(progress.windowBackgroundActive, false)
    @Assert(progress.windowBackgroundVisualResult, "unobserved")
    @Assert(progress.windowBackgroundColorScheme, "unavailable")
}

@Test
func genericTransportRequiresAllResourceInteractionGrantBeforeEmittingInteractionFacts(): Unit {
    let restricted = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), restrictedWindowInteractionAuthorization()
    )
    @Assert(restricted.enableWindowProgressReads(WindowProgressProbe()), true)
    let noLeak = restricted.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH restricted-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(noLeak.contains("ERROR unauthorized_resource"), true)
    @Assert(noLeak.contains("WINDOW_FOCUS"), false)
    @Assert(noLeak.contains("WINDOW_SELECTION"), false)

    let full = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), fullWindowInteractionAuthorization()
    )
    @Assert(full.enableWindowProgressReads(WindowProgressProbe()), true)
    let interaction = full.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(interaction.contains("KIND WINDOW_INTERACTION"), true)
    @Assert(interaction.contains("WINDOW_PROJECTION ACTIVE"), true)
    @Assert(interaction.contains("WINDOW_INTERACTION_VERSION 9"), true)
    @Assert(interaction.contains("WINDOW_FOCUS_STATE valid"), true)
    @Assert(interaction.contains("WINDOW_FOCUS field_title"), true)
    @Assert(interaction.contains("WINDOW_SELECTION field_title 3 5"), true)
    @Assert(interaction.contains("WINDOW_ACTIVE_LAYER edit_dialog"), true)
    // The published facts name their scope: a window interaction projection of
    // the ACCEPTED scene, not a claim about the platform key window / first
    // responder, and it carries the scene revision it was sampled from.
    @Assert(interaction.contains("WINDOW_SCENE_VERSION 13"), true)
    @Assert(interaction.contains("WINDOW_SOURCE window_interaction_projection"), true)
    @Assert(interaction.contains("WINDOW_KNOWN_SCOPE accepted_scene_identity"), true)
    @Assert(interaction.contains("RESOURCE 42"), false)
}

/// The three focus facts must stay distinguishable, and a state that cannot
/// confirm a live identity must never publish a control id.
@Test
func genericTransportPublishesThreeDistinctFocusFacts(): Unit {
    let full = CjguiSharedOperationExternalConnection(
        BackupRuleContractDomain(), fullWindowInteractionAuthorization()
    )
    @Assert(full.enableWindowProgressReads(
        ScriptedFocusProbe(CJGUI_WINDOW_FOCUS_STATE_UNFOCUSED, "none")), true)
    let unfocused = full.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(unfocused.contains("WINDOW_FOCUS_STATE unfocused"), true)
    @Assert(unfocused.contains("WINDOW_FOCUS none"), true)

    // A focus whose accepted identity can no longer be confirmed says so, and
    // does not name the dead control.
    @Assert(full.enableWindowProgressReads(
        ScriptedFocusProbe(CJGUI_WINDOW_FOCUS_STATE_UNKNOWN, "none")), true)
    let unknown = full.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(unknown.contains("WINDOW_FOCUS_STATE unknown"), true)
    @Assert(unknown.contains("WINDOW_FOCUS none"), true)

    // Fabricating a confirmed focus in either unconfirmed state is refused
    // instead of publishing an instance the window cannot vouch for.
    @Assert(full.enableWindowProgressReads(
        ScriptedFocusProbe(CJGUI_WINDOW_FOCUS_STATE_UNKNOWN, "field_title")), true)
    let fabricated = full.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(fabricated.contains("ERROR invalid_window_interaction"), true)
    @Assert(fabricated.contains("field_title"), false)

    // An unknown focus-state token is not published either.
    @Assert(full.enableWindowProgressReads(
        ScriptedFocusProbe("probably", "none")), true)
    let bogus = full.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH full-window-interaction-capability\nGET_WINDOW_INTERACTION"
    )
    @Assert(bogus.contains("ERROR invalid_window_interaction"), true)
}

/// One canonical text form per shared value kind. A consumer that publishes a
/// value as text must not have to know the kind-to-encoding mapping itself: a
/// boolean published through `stringValue` was empty to an external reader even
/// though the business value was set.
@Test
func sharedOperationValueHasOneCanonicalTextForm(): Unit {
    @Assert(CjguiSharedOperationValue.string("外部续写").displayText(), "外部续写")
    @Assert(CjguiSharedOperationValue.integer(730).displayText(), "730")
    @Assert(CjguiSharedOperationValue.boolean(true).displayText(), "true")
    @Assert(CjguiSharedOperationValue.boolean(false).displayText(), "false")
    // The typed accessors keep their own meaning; displayText never invents a
    // value for a kind it does not own.
    @Assert(CjguiSharedOperationValue.boolean(true).stringValue, "")
    @Assert(CjguiSharedOperationValue.integer(7).stringValue, "")
    let empty = CjguiSharedOperationValue.string("")
    @Assert(empty.displayText(), "")
}

private class TimingSentinelProjection <: CjguiSharedOperationWindowProjectionProvider {
    let elapsed: Int64

    init(elapsed: Int64) { this.elapsed = elapsed }

    public func windowProjection(): CjguiSharedOperationWindowProjection {
        return CjguiSharedOperationWindowProjection(true, 1, 1, "unavailable", "none", 0, 0,
            ArrayList<CjguiSharedOperationRelation>(), lastBuildElapsedMs: elapsed,
            lastLayoutElapsedMs: elapsed, lastNativeMeasurementElapsedMs: elapsed,
            lastNativeStageAndSubmitElapsedMs: elapsed)
    }
}

@Test
func unavailableTimingKeepsPublicWindowSnapshotReadable(): Unit {
    let connection = CjguiSharedOperationExternalConnection(BackupRuleContractDomain(),
        backupRuleAuthorization(), TimingSentinelProjection(-1))
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 0")
    @Assert(response.contains("KIND SNAPSHOT"), true)
    @Assert(response.contains("WINDOW_WORK_TIMING_MS -1 -1 -1 -1"), true)
    @Assert(connection.consumeWindowRefreshRequest(), false)
}

@Test
func timingSentinelDoesNotAdmitOtherNegativeValues(): Unit {
    let connection = CjguiSharedOperationExternalConnection(BackupRuleContractDomain(),
        backupRuleAuthorization(), TimingSentinelProjection(-2))
    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH core-contract-capability\nGET_CONTEXT 0")
    @Assert(response.contains("ERROR invalid_snapshot"), true)
    @Assert(connection.consumeWindowRefreshRequest(), false)
}
