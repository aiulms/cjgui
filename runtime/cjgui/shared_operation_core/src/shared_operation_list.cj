package cjgui_shared_operation_core

import std.collection.*
import std.sync.*

/// Experimental list consumer of the generic shared-operation contract. The
/// list owns its records and adapts its historic convenience methods to the
/// same generic handlers used by a human entry or an external socket call.
public class CjguiSharedOperationRecord {
    public let id: Int64
    public let title: String
    public let isMarked: Bool

    public init(id: Int64, title: String, isMarked: Bool) {
        this.id = id
        this.title = title
        this.isMarked = isMarked
    }
}

public class CjguiSharedOperationSnapshot {
    public let version: Int64
    public let selectedRecordId: Int64
    public let records: ArrayList<CjguiSharedOperationRecord>

    public init(
        version: Int64,
        selectedRecordId: Int64,
        records: ArrayList<CjguiSharedOperationRecord>
    ) {
        this.version = version
        this.selectedRecordId = selectedRecordId
        this.records = records
    }

    public func recordAt(index: Int64): CjguiSharedOperationRecord {
        return records[index]
    }
}

/// Compatibility projection for callers that used the list before the
/// generic domain contract was introduced.
public class CjguiSharedOperationResult {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        reason: String
    ) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.reason = reason
    }
}

private class CjguiSharedOperationMutableRecord {
    let id: Int64
    var title: String
    var isMarked: Bool

    init(id: Int64, title: String, isMarked: Bool) {
        this.id = id
        this.title = title
        this.isMarked = isMarked
    }
}

/// The original 101-record UI consumer. All list mutations, including its
/// older convenience API, end in `executeUnlocked`; transport never carries
/// list-specific branches.
public class CjguiSharedOperationList <: CjguiSharedOperationDomain {
    private let lock: Mutex
    private let mutableRecords: ArrayList<CjguiSharedOperationMutableRecord>
    private var currentVersion: Int64
    private var currentSelectedRecordId: Int64

    public init(records: ArrayList<CjguiSharedOperationRecord>) {
        this.lock = Mutex()
        this.mutableRecords = ArrayList<CjguiSharedOperationMutableRecord>()
        this.currentVersion = 0
        this.currentSelectedRecordId = -1
        for (record in records) {
            if (containsRecord(record.id)) {
                throw IllegalArgumentException("duplicate_record_id")
            }
            mutableRecords.add(CjguiSharedOperationMutableRecord(record.id, record.title, record.isMarked))
        }
    }

    public func resourceType(): String {
        return "neutral_list"
    }

    public func version(): Int64 {
        return synchronized(lock) { currentVersion }
    }

    public func snapshot(): CjguiSharedOperationSnapshot {
        return synchronized(lock) { snapshotUnlocked() }
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return synchronized(lock) { contextSnapshotUnlocked() }
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>(
            [
                CjguiSharedOperationActionDescriptor(
                    "SELECT",
                    "选择记录",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(),
                    1,
                    1
                ),
                CjguiSharedOperationActionDescriptor(
                    "TOGGLE",
                    "切换标记",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(),
                    1,
                    1
                ),
                CjguiSharedOperationActionDescriptor(
                    "SET_MARKED",
                    "设置标记",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [CjguiSharedOperationParameterDescriptor("isMarked", "BOOLEAN", true)]
                    ),
                    1,
                    1024
                ),
                CjguiSharedOperationActionDescriptor(
                    "SET_TITLE",
                    "设置记录标题",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [CjguiSharedOperationParameterDescriptor("title", "STRING", true)]
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
        return synchronized(lock) { executeUnlocked(invocation, false) }
    }

    public func executeFromExternal(
        invocation: CjguiSharedOperationActionInvocation
    ): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, true) }
    }

    public func selectFromHuman(recordId: Int64): CjguiSharedOperationResult {
        return legacyResult(
            executeFromHuman(CjguiSharedOperationActionInvocation(
                "SELECT", version(), ArrayList<Int64>([recordId]), emptyArguments()
            ))
        )
    }

    public func toggleFromHuman(recordId: Int64): CjguiSharedOperationResult {
        return legacyResult(
            executeFromHuman(CjguiSharedOperationActionInvocation(
                "TOGGLE", version(), ArrayList<Int64>([recordId]), emptyArguments()
            ))
        )
    }

    public func selectFromExternal(recordId: Int64, expectedVersion: Int64): CjguiSharedOperationResult {
        return legacyResult(
            executeFromExternal(CjguiSharedOperationActionInvocation(
                "SELECT", expectedVersion, ArrayList<Int64>([recordId]), emptyArguments()
            ))
        )
    }

    public func toggleFromExternal(recordId: Int64, expectedVersion: Int64): CjguiSharedOperationResult {
        return legacyResult(
            executeFromExternal(CjguiSharedOperationActionInvocation(
                "TOGGLE", expectedVersion, ArrayList<Int64>([recordId]), emptyArguments()
            ))
        )
    }

    public func setMarkedFromExternal(
        recordIds: ArrayList<Int64>,
        isMarked: Bool,
        expectedVersion: Int64
    ): CjguiSharedOperationResult {
        return legacyResult(
            executeFromExternal(CjguiSharedOperationActionInvocation(
                "SET_MARKED",
                expectedVersion,
                recordIds,
                ArrayList<CjguiSharedOperationActionArgument>(
                    [CjguiSharedOperationActionArgument("isMarked", CjguiSharedOperationValue.boolean(isMarked))]
                )
            ))
        )
    }

    /// A direct normal-window adapter for the same generic action used by an
    /// external invocation.  Human edits intentionally have no optimistic
    /// version precondition; an empty title is a valid transient projection
    /// and any application-required check belongs to its submit boundary.
    public func setTitleFromHuman(recordId: Int64, title: String): CjguiSharedOperationResult {
        return legacyResult(
            executeFromHuman(CjguiSharedOperationActionInvocation(
                "SET_TITLE", version(), ArrayList<Int64>([recordId]),
                ArrayList<CjguiSharedOperationActionArgument>([
                    CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.string(title))
                ])
            ))
        )
    }

    /// This is the human counterpart of `SET_MARKED`, not a controller-local
    /// task flag.  It lets a small consumer expose a submission state without
    /// creating a second state machine.
    public func setMarkedFromHuman(recordId: Int64, isMarked: Bool): CjguiSharedOperationResult {
        return legacyResult(
            executeFromHuman(CjguiSharedOperationActionInvocation(
                "SET_MARKED", version(), ArrayList<Int64>([recordId]),
                ArrayList<CjguiSharedOperationActionArgument>([
                    CjguiSharedOperationActionArgument("isMarked", CjguiSharedOperationValue.boolean(isMarked))
                ])
            ))
        )
    }

    private func contextSnapshotUnlocked(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        for (record in mutableRecords) {
            resources.add(
                CjguiSharedOperationResource(
                    record.id,
                    // `name` is transport metadata, while `title` is this
                    // record's editable field.  A human may transiently
                    // clear the field before an application submit check;
                    // keep the resource discoverable instead of letting an
                    // empty display value invalidate the whole snapshot.
                    resourceName(record),
                    ArrayList<CjguiSharedOperationField>(
                        [
                            CjguiSharedOperationField("title", CjguiSharedOperationValue.string(record.title)),
                            CjguiSharedOperationField("isMarked", CjguiSharedOperationValue.boolean(record.isMarked)),
                            CjguiSharedOperationField(
                                "selected",
                                CjguiSharedOperationValue.boolean(currentSelectedRecordId == record.id)
                            )
                        ]
                    )
                )
            )
        }
        return CjguiSharedOperationContextSnapshot(
            currentVersion,
            "共享中性列表",
            resourceType(),
            resources
        )
    }

    private func snapshotUnlocked(): CjguiSharedOperationSnapshot {
        let copy = ArrayList<CjguiSharedOperationRecord>()
        for (record in mutableRecords) {
            copy.add(CjguiSharedOperationRecord(record.id, record.title, record.isMarked))
        }
        return CjguiSharedOperationSnapshot(currentVersion, currentSelectedRecordId, copy)
    }

    private func executeUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        requiresCurrentVersion: Bool
    ): CjguiSharedOperationActionResult {
        let versionBefore = currentVersion
        if (requiresCurrentVersion && invocation.expectedVersion != currentVersion) {
            return rejected(versionBefore, true, "version_conflict")
        }
        if (invocation.actionName == "SELECT") {
            return selectUnlocked(invocation, versionBefore)
        }
        if (invocation.actionName == "TOGGLE") {
            return toggleUnlocked(invocation, versionBefore)
        }
        if (invocation.actionName == "SET_MARKED") {
            return setMarkedUnlocked(invocation, versionBefore)
        }
        if (invocation.actionName == "SET_TITLE") {
            return setTitleUnlocked(invocation, versionBefore)
        }
        return rejected(versionBefore, false, "unknown_action")
    }

    private func selectUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        versionBefore: Int64
    ): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 0) {
            return rejected(versionBefore, false, "invalid_parameters")
        }
        let recordId = invocation.targetResourceIds[0]
        if (!containsRecord(recordId)) {
            return rejected(versionBefore, false, "unknown_record")
        }
        if (currentSelectedRecordId == recordId) {
            return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "already_selected")
        }
        currentSelectedRecordId = recordId
        currentVersion += 1
        return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "applied")
    }

    private func toggleUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        versionBefore: Int64
    ): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 0) {
            return rejected(versionBefore, false, "invalid_parameters")
        }
        let recordId = invocation.targetResourceIds[0]
        for (record in mutableRecords) {
            if (record.id == recordId) {
                record.isMarked = !record.isMarked
                currentVersion += 1
                return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "applied")
            }
        }
        return rejected(versionBefore, false, "unknown_record")
    }

    private func setMarkedUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        versionBefore: Int64
    ): CjguiSharedOperationActionResult {
        if (invocation.arguments.size != 1) {
            return rejected(versionBefore, false, "invalid_parameters")
        }
        if (let Some(isMarked) <- booleanArgument(invocation, "isMarked")) {
            let uniqueRecordIds = uniqueIds(invocation.targetResourceIds)
            if (uniqueRecordIds.size == 0 || uniqueRecordIds.size > 1024) {
                return rejected(versionBefore, false, "empty_targets")
            }
            for (recordId in uniqueRecordIds) {
                if (!containsRecord(recordId)) {
                    return rejected(versionBefore, false, "unknown_record")
                }
            }
            var hasChange = false
            for (record in mutableRecords) {
                if (containsId(uniqueRecordIds, record.id) && record.isMarked != isMarked) {
                    hasChange = true
                }
            }
            if (!hasChange) {
                return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "already_at_target")
            }
            for (record in mutableRecords) {
                if (containsId(uniqueRecordIds, record.id)) {
                    record.isMarked = isMarked
                }
            }
            currentVersion += 1
            return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "applied")
        }
        return rejected(versionBefore, false, "invalid_parameters")
    }

    private func setTitleUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        versionBefore: Int64
    ): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 1) {
            return rejected(versionBefore, false, "invalid_parameters")
        }
        if (let Some(title) <- stringArgument(invocation, "title")) {
            let recordId = invocation.targetResourceIds[0]
            for (record in mutableRecords) {
                if (record.id == recordId) {
                    if (record.title == title) {
                        return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "already_at_target")
                    }
                    record.title = title
                    currentVersion += 1
                    return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "applied")
                }
            }
            return rejected(versionBefore, false, "unknown_record")
        }
        return rejected(versionBefore, false, "invalid_parameters")
    }

    private func booleanArgument(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?Bool {
        var matched = false
        var result = false
        for (argument in invocation.arguments) {
            if (argument.name == name) {
                if (matched || argument.value.valueType != "BOOLEAN") {
                    return None
                }
                matched = true
                result = argument.value.booleanValue
            }
        }
        if (matched) {
            return Some(result)
        }
        return None
    }

    private func stringArgument(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?String {
        var matched = false
        var result = ""
        for (argument in invocation.arguments) {
            if (argument.name == name) {
                if (matched || argument.value.valueType != "STRING") {
                    return None
                }
                matched = true
                result = argument.value.stringValue
            }
        }
        if (matched) {
            return Some(result)
        }
        return None
    }

    private func containsRecord(recordId: Int64): Bool {
        for (record in mutableRecords) {
            if (record.id == recordId) {
                return true
            }
        }
        return false
    }

    private func resourceName(record: CjguiSharedOperationMutableRecord): String {
        return if (record.title.size == 0) { "记录 ${record.id}" } else { record.title }
    }

    private func uniqueIds(recordIds: ArrayList<Int64>): ArrayList<Int64> {
        let unique = ArrayList<Int64>()
        for (recordId in recordIds) {
            if (!containsId(unique, recordId)) {
                unique.add(recordId)
            }
        }
        return unique
    }

    private func containsId(recordIds: ArrayList<Int64>, recordId: Int64): Bool {
        for (candidate in recordIds) {
            if (candidate == recordId) {
                return true
            }
        }
        return false
    }

    private func rejected(
        versionBefore: Int64,
        conflict: Bool,
        reason: String
    ): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, versionBefore, currentVersion, reason)
    }

    private func legacyResult(result: CjguiSharedOperationActionResult): CjguiSharedOperationResult {
        return CjguiSharedOperationResult(
            result.applied,
            result.isVersionConflict,
            result.versionBefore,
            result.versionAfter,
            result.reason
        )
    }

    private func emptyArguments(): ArrayList<CjguiSharedOperationActionArgument> {
        return ArrayList<CjguiSharedOperationActionArgument>()
    }
}
