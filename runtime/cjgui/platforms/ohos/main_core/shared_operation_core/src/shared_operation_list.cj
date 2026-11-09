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
    /// Generic optional text field. It exists so an application can declare a
    /// second text field and have all three entry points serve it without a new
    /// generation-specific branch; the application's rule for it is installed
    /// as a `CjguiSharedFieldRule`, never hardcoded here.
    public let notes: String

    public init(id: Int64, title: String, isMarked: Bool, notes!: String = "") {
        this.id = id
        this.title = title
        this.isMarked = isMarked
        this.notes = notes
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
    var notes: String

    init(id: Int64, title: String, isMarked: Bool, notes: String) {
        this.id = id
        this.title = title
        this.isMarked = isMarked
        this.notes = notes
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
    /// Declared field write rules, keyed by `<writer>@<target resource>`. An
    /// application installs them once; every entry point (handwritten pane,
    /// generated editor, external invocation) then reaches the same owner
    /// transaction and the same rule, so no UI layer has to restate it.
    private let fieldRules: HashMap<String, CjguiSharedFieldRule>

    public init(records: ArrayList<CjguiSharedOperationRecord>) {
        this.lock = Mutex()
        this.mutableRecords = ArrayList<CjguiSharedOperationMutableRecord>()
        this.currentVersion = 0
        this.currentSelectedRecordId = -1
        this.fieldRules = HashMap<String, CjguiSharedFieldRule>()
        for (record in records) {
            if (containsRecord(record.id)) {
                throw IllegalArgumentException("duplicate_record_id")
            }
            mutableRecords.add(CjguiSharedOperationMutableRecord(record.id, record.title, record.isMarked,
                record.notes))
        }
    }

    /// Installs one declared field rule on this owner. A conflicting duplicate
    /// (same writer+resource bound to a different field or argument) is refused
    /// instead of silently replacing the binding.
    public func installFieldRule(rule: CjguiSharedFieldRule): Bool {
        return synchronized(lock) {
            if (rule.fieldId.size == 0 || rule.writer.size == 0 || rule.argument.size == 0) {
                return false
            }
            let key = ruleKey(rule.writer, rule.targetResourceId)
            if (let Some(existing) <- fieldRules.get(key)) {
                return existing.fieldId == rule.fieldId && existing.argument == rule.argument &&
                    existing.editorKind == rule.editorKind
            }
            fieldRules.add(key, rule)
            return true
        }
    }

    /// The rule the owner will apply for this writer on this resource, or None
    /// when the action is not a declared field write.
    public func fieldRule(writer: String, targetResourceId: Int64): ?CjguiSharedFieldRule {
        return synchronized(lock) { fieldRules.get(ruleKey(writer, targetResourceId)) }
    }

    /// The one owner entry for a declared field write. The handwritten pane and
    /// the generated editor both call it, so neither can bypass the rule the
    /// owner also applies to an external invocation.
    public func writeDeclaredFieldFromHuman(rule: CjguiSharedFieldRule, targetResourceId: Int64,
        value: CjguiSharedOperationValue): CjguiSharedOperationResult {
        return legacyResult(
            executeFromHuman(CjguiSharedOperationActionInvocation(
                rule.writer,
                version(),
                ArrayList<Int64>([targetResourceId]),
                ArrayList<CjguiSharedOperationActionArgument>(
                    [CjguiSharedOperationActionArgument(rule.argument, value)]
                )
            ))
        )
    }

    private func ruleKey(writer: String, targetResourceId: Int64): String {
        return "${writer}@${targetResourceId}"
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
                ),
                CjguiSharedOperationActionDescriptor(
                    "SET_NOTES",
                    "设置记录备注",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [CjguiSharedOperationParameterDescriptor("notes", "STRING", true)]
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
                            CjguiSharedOperationField("notes", CjguiSharedOperationValue.string(record.notes)),
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
            copy.add(CjguiSharedOperationRecord(record.id, record.title, record.isMarked, notes: record.notes))
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
        // The application's declared field rule runs inside the owner
        // transaction, before any mutation, so a rejected request can never
        // leave a partial write behind and an external caller cannot bypass the
        // rule that the handwritten pane and the generated editor also hit.
        let ruleRejection = declaredWriteRejectionUnlocked(invocation)
        if (ruleRejection.size > 0) {
            return rejected(versionBefore, false, ruleRejection)
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
        if (invocation.actionName == "SET_NOTES") {
            return setNotesUnlocked(invocation, versionBefore)
        }
        return rejected(versionBefore, false, "unknown_action")
    }

    /// Evaluates the installed rule for a declared field write. Actions without
    /// a declared rule (SELECT/TOGGLE and any other generic action) are not
    /// affected. A declared writer invoked with a different argument name or a
    /// value of the wrong type is refused instead of being routed to another
    /// field by default. Every target is checked before anything is mutated, so
    /// a refused multi-target write cannot leave a partial write behind.
    private func declaredWriteRejectionUnlocked(
        invocation: CjguiSharedOperationActionInvocation
    ): String {
        for (resourceId in invocation.targetResourceIds) {
            if (let Some(rule) <- fieldRules.get(ruleKey(invocation.actionName, resourceId))) {
                var requestedText = ""
                var requestedBoolean = false
                if (let Some(text) <- stringArgument(invocation, rule.argument)) {
                    requestedText = text
                } else if (let Some(flag) <- booleanArgument(invocation, rule.argument)) {
                    requestedBoolean = flag
                } else {
                    return if (invocation.arguments.size == 0) { "missing_argument" } else { "unknown_argument" }
                }
                for (record in mutableRecords) {
                    if (record.id == resourceId) {
                        let request = CjguiSharedFieldWriteRequest(
                            rule.fieldId, rule.writer, rule.argument, resourceId,
                            requestedText, requestedBoolean, record.title, record.isMarked, currentVersion
                        )
                        let rejection = rule.rejectionFor(request)
                        if (rejection.size > 0) {
                            return rejection
                        }
                    }
                }
            }
        }
        return ""
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

    /// The generic second text field. Its constraint comes from the installed
    /// `CjguiSharedFieldRule`; this domain hardcodes none.
    private func setNotesUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        versionBefore: Int64
    ): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 1) {
            return rejected(versionBefore, false, "invalid_parameters")
        }
        if (let Some(notes) <- stringArgument(invocation, "notes")) {
            let recordId = invocation.targetResourceIds[0]
            for (record in mutableRecords) {
                if (record.id == recordId) {
                    if (record.notes == notes) {
                        return CjguiSharedOperationActionResult(true, false, versionBefore, currentVersion, "already_at_target")
                    }
                    record.notes = notes
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
