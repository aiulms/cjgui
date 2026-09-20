package cjgui_rule_set_application

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.fs.*
import std.random.*
import std.sync.*
import std.env.*

/// Applied rule projection. The stable identifier survives reordering, saving
/// and reopening; UI row positions are intentionally never used as identity.
public class CjguiRuleSetRecord {
    public let id: Int64
    public let label: String
    public let enabled: Bool
    public let retentionCount: Int64
    public let excludedType: String
    public init(id: Int64, label: String, enabled: Bool, retentionCount: Int64, excludedType: String) {
        this.id = id; this.label = label; this.enabled = enabled
        this.retentionCount = retentionCount; this.excludedType = excludedType
    }
}

/// A version-scoped content-only change of this domain: the changed record ids and
/// their new applied labels. Consumed by the tree projection's local-update path;
/// a caller that cannot be served exactly must rebuild (see
/// `CjguiRuleSetEditingDomain.contentChangeSince`).
public class CjguiRuleSetContentChange {
    public let beforeVersion: Int64
    public let version: Int64
    public let recordIds: ArrayList<Int64>
    public let labels: ArrayList<String>
    public init(beforeVersion: Int64, version: Int64, recordIds: ArrayList<Int64>, labels: ArrayList<String>) {
        this.beforeVersion = beforeVersion
        this.version = version
        this.recordIds = recordIds
        this.labels = labels
    }
}

public class CjguiRuleSetSnapshot {
    public let version: Int64
    public let selectedRecordId: Int64
    public let records: ArrayList<CjguiRuleSetRecord>
    public let filePath: String
    public let isSaved: Bool
    public init(version: Int64, selectedRecordId: Int64, records: ArrayList<CjguiRuleSetRecord>, filePath: String, isSaved: Bool) {
        this.version = version; this.selectedRecordId = selectedRecordId
        this.records = ArrayList<CjguiRuleSetRecord>(records); this.filePath = filePath; this.isSaved = isSaved
    }
    public func recordById(id: Int64): CjguiRuleSetRecord {
        for (record in records) { if (record.id == id) { return record } }
        throw IllegalArgumentException("unknown_rule_record")
    }
}

private class CjguiMutableRuleSetRecord {
    let id: Int64
    var label: String
    var enabled: Bool
    var retentionCount: Int64
    var excludedType: String
    var draftLabel: String
    var draftEnabled: Bool
    var draftRetentionCount: String
    var draftExcludedType: String
    var labelError: String
    var retentionError: String
    var excludedError: String
    var appliedRevision: Int64
    var draftVersion: Int64
    var baseAppliedRevision: Int64
    var labelFieldVersion: Int64
    var enabledFieldVersion: Int64
    var retentionFieldVersion: Int64
    var excludedFieldVersion: Int64
    var selectionStart: Int64
    var selectionEnd: Int64
    var activeFieldId: String

    init(id: Int64, label: String, enabled: Bool, retentionCount: Int64, excludedType: String) {
        this.id = id; this.label = label; this.enabled = enabled
        this.retentionCount = retentionCount; this.excludedType = excludedType
        this.draftLabel = label; this.draftEnabled = enabled
        this.draftRetentionCount = retentionCount.toString(); this.draftExcludedType = excludedType
        this.labelError = ""; this.retentionError = ""; this.excludedError = ""
        this.appliedRevision = 0; this.draftVersion = 0; this.baseAppliedRevision = 0
        this.labelFieldVersion = 0; this.enabledFieldVersion = 0
        this.retentionFieldVersion = 0; this.excludedFieldVersion = 0
        this.selectionStart = 0; this.selectionEnd = 0; this.activeFieldId = ""
    }
    func appliedProjection(): CjguiRuleSetRecord {
        return CjguiRuleSetRecord(id, label, enabled, retentionCount, excludedType)
    }
}

private class CjguiRuleSetHistoryEntry {
    let records: ArrayList<CjguiRuleSetRecord>
    let selectedRecordId: Int64
    init(records: ArrayList<CjguiRuleSetRecord>, selectedRecordId: Int64) {
        this.records = ArrayList<CjguiRuleSetRecord>(records)
        this.selectedRecordId = selectedRecordId
    }
}

/// A completed external request is replayable only when its semantic payload
/// matches exactly. A request identifier alone cannot safely name an action.
private class CjguiRuleSetAppliedRequest {
    let fingerprint: String
    let appliedVersion: Int64
    init(fingerprint: String, appliedVersion: Int64) {
        this.fingerprint = fingerprint; this.appliedVersion = appliedVersion
    }
}

private class CjguiRuleSetLoadedFile {
    let records: ArrayList<CjguiRuleSetRecord>
    let selectedRecordId: Int64
    let nextRecordId: Int64
    init(records: ArrayList<CjguiRuleSetRecord>, selectedRecordId: Int64, nextRecordId: Int64) {
        this.records = records; this.selectedRecordId = selectedRecordId; this.nextRecordId = nextRecordId
    }
}

private class CjguiRuleSetTransferRecord {
    let label: String
    let enabled: Bool
    let retentionCount: Int64
    let excludedType: String

    init(label: String, enabled: Bool, retentionCount: Int64, excludedType: String) {
        this.label = label; this.enabled = enabled; this.retentionCount = retentionCount
        this.excludedType = excludedType
    }
}

/// Test and independent-consumer convenience builders. Production callers can
/// discover the same action schema through the shared descriptor.
public class CjguiRuleSetInvocationFactory {
    public static func create(expectedVersion: Int64, label: String, enabled: Bool, retentionCount: Int64, excludedType: String, requestId: String): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation(
            "CREATE_RECORD", expectedVersion, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string(label)),
                CjguiSharedOperationActionArgument("enabled", CjguiSharedOperationValue.boolean(enabled)),
                CjguiSharedOperationActionArgument("retentionCount", CjguiSharedOperationValue.integer(retentionCount)),
                CjguiSharedOperationActionArgument("excludedType", CjguiSharedOperationValue.string(excludedType)),
                CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string(requestId))
            ])
        )
    }
}

/// Pure-Cangjie reference application truth for the usable-framework preview.
/// Both human helpers and socket operations enter executeUnlocked under this
/// one lock. Renderer, AppKit and storage format are deliberately outside the
/// shared core package.
public class CjguiRuleSetEditingDomain <: CjguiSharedRangeCollectionEditorDomain & CjguiSharedOperationChangeDomain & CjguiSharedOperationTargetedContextDomain {
    public static let ruleSetResourceId: Int64 = 8000
    public static let formLabelResourceId: Int64 = 81001
    public static let formEnabledResourceId: Int64 = 81002
    public static let formRetentionResourceId: Int64 = 81003
    /// The default retention boundary of this domain. It is declared once here,
    /// travels with the shared field binding, and is the same value the draft
    /// validator enforces - so the handwritten form, the generated editor and
    /// an external capability query cannot disagree. A deployment may configure
    /// a different declared boundary (see `newUntitled`), which is how the
    /// "the declared rule changed" acceptance is verified without editing the
    /// example's own convention.
    public static let defaultRetentionMinimum: Int64 = 1
    public static let defaultRetentionMaximum: Int64 = 90
    public static let formExcludedTypeResourceId: Int64 = 81004
    public static let transferFormatIdentifier: String = "cjgui.rule.record"
    public static let transferFormatVersion: Int64 = 1
    private static let maximumChanges: Int64 = 64
    private static let maximumRememberedRequests: Int64 = 128

    private let lock: Mutex
    private let binding: CjguiSharedFormBinding
    private let records: ArrayList<CjguiMutableRuleSetRecord>
    // Derived owner-local ID index.  The array remains the ordered business
    // truth; structural writes update this index in the same domain lock.
    private let recordsById: HashMap<Int64, CjguiMutableRuleSetRecord>
    private let undoHistory: ArrayStack<CjguiRuleSetHistoryEntry>
    private let redoHistory: ArrayStack<CjguiRuleSetHistoryEntry>
    private let changes: ArrayDeque<CjguiSharedOperationChangeEntry>
    private let appliedRequests: HashMap<String, CjguiRuleSetAppliedRequest>
    private let appliedRequestOrder: ArrayList<String>
    private let instanceIdentity: String
    private var versionValue: Int64
    private var selectedId: Int64
    private var nextId: Int64
    private var historyFloorVersion: Int64
    // Version-scoped signal for the tree projection's content-only path: the last
    // committed change is reusable ONLY when it could not create, delete, move or
    // re-parent a row (a pure label rewrite). Everything else leaves this
    // unusable, so the projection rebuilds instead of guessing.
    private var contentChangeBeforeVersion: Int64 = -1
    private var contentChangeKeys: ArrayList<Int64> = ArrayList<Int64>()
    private var contentChangeUsable: Bool = false
    private var documentGeneration: Int64
    private var currentFilePath: String
    private var lastPersistedPayload: String
    private var status: String
    // This is window presentation state, but its single owner is still the
    // rule-set domain so local pointer input and authorized external writes
    // share one CAS/version boundary. It is intentionally not serialized as
    // rule content or folded into save/dirty decisions.
    /// The declared retention boundary this domain enforces and publishes.
    private let retentionMinimumValue: Int64
    private let retentionMaximumValue: Int64
    private var splitFirstSizeValue: Int64
    // This target-scoped owner revision invalidates only an active split drag.
    // The aggregate rule-set version continues to invalidate the full scene.
    private var splitFirstSizeVersionValue: Int64

    public init(retentionMinimum!: Int64 = CjguiRuleSetEditingDomain.defaultRetentionMinimum,
                retentionMaximum!: Int64 = CjguiRuleSetEditingDomain.defaultRetentionMaximum) {
        this.retentionMinimumValue = retentionMinimum
        this.retentionMaximumValue = retentionMaximum
        this.lock = Mutex()
        this.binding = CjguiSharedFormBinding(ArrayList<CjguiSharedFormFieldDescriptor>([
            CjguiSharedFormFieldDescriptor(CjguiRuleSetEditingDomain.formLabelResourceId, "label", "规则名称", "TEXT"),
            CjguiSharedFormFieldDescriptor(CjguiRuleSetEditingDomain.formEnabledResourceId, "enabled", "启用规则", "BOOLEAN"),
            CjguiSharedFormFieldDescriptor(CjguiRuleSetEditingDomain.formRetentionResourceId, "retentionCount", "保留天数", "INTEGER",
                minimum: retentionMinimum, maximum: retentionMaximum),
            CjguiSharedFormFieldDescriptor(CjguiRuleSetEditingDomain.formExcludedTypeResourceId, "excludedType", "排除类型", "TEXT")
        ]))
        this.records = ArrayList<CjguiMutableRuleSetRecord>()
        this.recordsById = HashMap<Int64, CjguiMutableRuleSetRecord>()
        this.undoHistory = ArrayStack<CjguiRuleSetHistoryEntry>()
        this.redoHistory = ArrayStack<CjguiRuleSetHistoryEntry>()
        this.changes = ArrayDeque<CjguiSharedOperationChangeEntry>()
        this.appliedRequests = HashMap<String, CjguiRuleSetAppliedRequest>()
        this.appliedRequestOrder = ArrayList<String>()
        this.instanceIdentity = Random().nextUInt64().toString()
        this.versionValue = 0; this.selectedId = -1; this.nextId = 1; this.historyFloorVersion = 0
        this.documentGeneration = 0
        this.currentFilePath = ""; this.lastPersistedPayload = ""
        this.status = "新建规则集；请新增一条规则"
        this.splitFirstSizeValue = 260
        this.splitFirstSizeVersionValue = 0
    }

    public static func newUntitled(): CjguiRuleSetEditingDomain { return CjguiRuleSetEditingDomain() }

    /// A domain whose declared retention boundary is configured explicitly. The
    /// application's own convention stays the default above; this exists so the
    /// "declared rule" acceptance can move the boundary and verify that the
    /// binding, the external capability description and the owner validation
    /// all follow the same declaration.
    public static func newWithRetentionRange(minimum!: Int64, maximum!: Int64): CjguiRuleSetEditingDomain {
        return CjguiRuleSetEditingDomain(retentionMinimum: minimum, retentionMaximum: maximum)
    }
    public func resourceType(): String { return "backup_rule_set" }
    public static func transferFormat(): CjguiSharedOperationTransferFormat {
        return CjguiSharedOperationTransferFormat.structured(
            CjguiRuleSetEditingDomain.transferFormatIdentifier,
            version: CjguiRuleSetEditingDomain.transferFormatVersion,
            maximumBytes: 16 * 1024)
    }
    public func transferTargetIdentity(): String { return synchronized(lock) { instanceIdentity } }
    public func formBinding(): CjguiSharedFormBinding { return binding }
    public func selectedRecordId(): Int64 { return synchronized(lock) { selectedId } }
    /// Constant-time business version. `snapshot()` copies every record, so a
    /// caller that only needs freshness (the tree projection's content-update
    /// path) must not pay that.
    public func version(): Int64 { return synchronized(lock) { versionValue } }
    public func splitFirstSize(): Int64 { return synchronized(lock) { splitFirstSizeValue } }
    public func splitFirstSizeVersion(): Int64 { return synchronized(lock) { splitFirstSizeVersionValue } }
    public func selectedDraftVersion(): Int64 {
        return synchronized(lock) {
            if (let Some(record) <- selectedUnlocked()) { return record.draftVersion }
            return -1
        }
    }
    public func draftVersionForCollectionItem(resourceId: Int64): Int64 {
        return synchronized(lock) { if (let Some(record) <- recordForIdUnlocked(resourceId)) { return record.draftVersion }; return -1 }
    }
    public func baseAppliedVersionForCollectionItem(resourceId: Int64): Int64 {
        return synchronized(lock) { if (let Some(record) <- recordForIdUnlocked(resourceId)) { return record.baseAppliedRevision }; return -1 }
    }
    public func snapshot(): CjguiRuleSetSnapshot { return synchronized(lock) { snapshotUnlocked() } }
    public func selectedFormSnapshot(): CjguiSharedFormSnapshot { return formSnapshot() }
    public func formSnapshot(): CjguiSharedFormSnapshot { return synchronized(lock) { formSnapshotUnlocked() } }
    public func collectionSnapshot(): CjguiSharedCollectionSnapshot { return synchronized(lock) { collectionSnapshotUnlocked() } }
    public func collectionRangeSnapshot(): CjguiSharedCollectionRangeSnapshot {
        return synchronized(lock) { CjguiSharedCollectionRangeSnapshot(versionValue, records.size, selectedId, status) }
    }
    public func collectionItemAt(index: Int64): CjguiSharedCollectionItemProjection {
        return synchronized(lock) {
            if (index < 0 || index >= records.size) { return CjguiSharedCollectionItemProjection.missing() }
            let record = records[index]
            return CjguiSharedCollectionItemProjection(record.id, record.label, record.id == selectedId)
        }
    }
    public func collectionIndexForResourceId(resourceId: Int64): Int64 {
        return synchronized(lock) {
            var index: Int64 = 0
            while (index < records.size) {
                if (records[index].id == resourceId) { return index }
                index += 1
            }
            return -1
        }
    }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot { return synchronized(lock) { contextSnapshotUnlocked() } }
    public func contextSnapshotForExternalTargets(
        targets: ArrayList<Int64>
    ): ?CjguiSharedOperationContextSnapshot {
        return synchronized(lock) { contextSnapshotForTargetsUnlocked(targets) }
    }

    /// Builds an immutable structured copy offer from the actual applied
    /// record. The offer contains no mutable record or native object.
    public func transferOfferForRecordFromHuman(recordId: Int64): ?CjguiSharedOperationTransferOffer {
        return synchronized(lock) {
            if (let Some(record) <- recordForIdUnlocked(recordId)) {
                let payload = serializeTransferRecord(record.label, record.enabled, record.retentionCount, record.excludedType)
                return CjguiSharedOperationTransferOffer.create(
                    "COPY", "rule_record", instanceIdentity, record.id, CjguiRuleSetEditingDomain.transferFormat(), payload)
            }
            return None
        }
    }

    public func selectedRecordTransferOfferFromHuman(): ?CjguiSharedOperationTransferOffer {
        return synchronized(lock) {
            if (let Some(record) <- selectedUnlocked()) {
                let payload = serializeTransferRecord(record.label, record.enabled, record.retentionCount, record.excludedType)
                return CjguiSharedOperationTransferOffer.create(
                    "COPY", "rule_record", instanceIdentity, record.id, CjguiRuleSetEditingDomain.transferFormat(), payload)
            }
            return None
        }
    }

    /// Accepts a structured rule offer through the same owner mutation used by
    /// the normal human command. Same-owner offers use COPY_RECORD after the
    /// payload is checked against the source; foreign offers use CREATE_RECORD.
    public func acceptTransferFromHuman(
        offer: CjguiSharedOperationTransferOffer
    ): CjguiSharedOperationTransferResult {
        return synchronized(lock) {
            if (let Some(request) <- CjguiSharedOperationTransferAcceptRequest.create(
                "rule_set", instanceIdentity, CjguiRuleSetEditingDomain.ruleSetResourceId,
                offer, CjguiRuleSetEditingDomain.transferFormat(), versionValue)) {
                return acceptTransferUnlocked(request, false, "")
            }
            return CjguiSharedOperationTransferResult.rejected(
                versionValue, "invalid_transfer", format: Some(CjguiRuleSetEditingDomain.transferFormat()))
        }
    }

    /// External acceptance retains capability/CAS at the transport boundary;
    /// this method adds the application request id before entering the same
    /// locked owner dispatcher.
    public func acceptTransferFromExternal(
        offer: CjguiSharedOperationTransferOffer,
        expectedVersion: Int64,
        requestId: String
    ): CjguiSharedOperationTransferResult {
        return synchronized(lock) {
            if (requestId.size == 0 || requestId.size > 128) {
                return CjguiSharedOperationTransferResult.rejected(
                    versionValue, "invalid_request_id", format: Some(CjguiRuleSetEditingDomain.transferFormat()))
            }
            if (let Some(request) <- CjguiSharedOperationTransferAcceptRequest.create(
                "rule_set", instanceIdentity, CjguiRuleSetEditingDomain.ruleSetResourceId,
                offer, CjguiRuleSetEditingDomain.transferFormat(), expectedVersion)) {
                return acceptTransferUnlocked(request, true, requestId)
            }
            return CjguiSharedOperationTransferResult.rejected(
                versionValue, "invalid_transfer", format: Some(CjguiRuleSetEditingDomain.transferFormat()))
        }
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            descriptor("CREATE_RECORD", "新增规则", createParameters(), 1, 1),
            descriptor("COPY_RECORD", "复制规则", copyParameters(), 1, 1),
            descriptor("RENAME_RECORD", "重命名规则", renameParameters(), 1, 1),
            descriptor("DELETE_RECORD", "删除规则", requestParameters(), 1, 1),
            descriptor("SELECT_RECORD", "选择规则", ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            descriptor("EDIT_DRAFT_TEXT", "编辑规则草稿文本", draftTextParameters(), 1, 1),
            descriptor("EDIT_DRAFT_BOOLEAN", "编辑规则草稿开关", draftBooleanParameters(), 1, 1),
            descriptor("APPLY_DRAFT", "应用规则草稿", draftApplyParameters(), 1, 1),
            descriptor("CANCEL_DRAFT", "取消规则草稿", draftApplyParameters(), 1, 1),
            descriptor("BATCH_SET_ENABLED", "批量设置启用", batchParameters(), 1, 1024),
            descriptor("UNDO", "撤销内容修改", ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            descriptor("REDO", "重做内容修改", ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            descriptor("SAVE_RULE_SET", "保存当前规则集", ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            descriptor("SET_SPLIT_SIZE", "设置规则面板宽度", splitSizeParameters(), 1, 1)
        ])
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, false) }
    }
    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, true) }
    }

    public func createRecordFromHuman(label: String, enabled: Bool, retentionCount: Int64, excludedType: String, requestId: String): CjguiSharedOperationActionResult {
        return executeFromHuman(CjguiRuleSetInvocationFactory.create(versionValue, label, enabled, retentionCount, excludedType, requestId))
    }
    public func selectRecordFromHuman(recordId: Int64): CjguiSharedOperationActionResult {
        return executeFromHuman(CjguiSharedOperationActionInvocation("SELECT_RECORD", versionValue, ArrayList<Int64>([recordId]), ArrayList<CjguiSharedOperationActionArgument>()))
    }
    public func selectCollectionItemFromHuman(resourceId: Int64): CjguiSharedOperationActionResult { return selectRecordFromHuman(resourceId) }
    public func createCollectionItemFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            let label = "新规则 ${nextId}"
            return createUnlocked(CjguiRuleSetInvocationFactory.create(versionValue, label, true, 7, "cache", "human-ui-create-${nextId}"))
        }
    }
    public func copySelectedCollectionItemFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (let Some(record) <- selectedUnlocked()) {
                let label = "副本 ${nextId}"
                return copyUnlocked(CjguiSharedOperationActionInvocation(
                    "COPY_RECORD", versionValue, ArrayList<Int64>([record.id]),
                    ArrayList<CjguiSharedOperationActionArgument>([
                        CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string(label)),
                        CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string("human-ui-copy-${nextId}"))
                    ])
                ))
            }
            return rejected(false, "no_selected_record")
        }
    }
    public func deleteSelectedCollectionItemFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (selectedId < 0) { return rejected(false, "no_selected_record") }
            return deleteUnlocked(CjguiSharedOperationActionInvocation("DELETE_RECORD", versionValue, ArrayList<Int64>([selectedId]), ArrayList<CjguiSharedOperationActionArgument>()))
        }
    }
    public func editSelectedLabelFromHuman(label: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        return editTextFromHuman(CjguiRuleSetEditingDomain.formLabelResourceId, label, selectionStart, selectionEnd)
    }
    public func applySelectedDraftFromHuman(expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { applyDraftUnlocked(selectedId, expectedDraftVersion) }
    }
    public func undoFromHuman(): CjguiSharedOperationActionResult { return executeFromHuman(CjguiSharedOperationActionInvocation("UNDO", versionValue, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), ArrayList<CjguiSharedOperationActionArgument>())) }
    public func redoFromHuman(): CjguiSharedOperationActionResult { return executeFromHuman(CjguiSharedOperationActionInvocation("REDO", versionValue, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), ArrayList<CjguiSharedOperationActionArgument>())) }
    public func setSplitFirstSizeFromHuman(value: Int64): CjguiSharedOperationActionResult {
        return executeFromHuman(CjguiSharedOperationActionInvocation(
            "SET_SPLIT_SIZE", versionValue, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.integer(value))
            ])
        ))
    }

    public func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { editSelectedTextUnlocked(formFieldName(resourceId), text, selectionStart, selectionEnd) }
    }
    public func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        return synchronized(lock) { editSelectedBooleanUnlocked(formFieldName(resourceId), value) }
    }
    public func editTextForCollectionItemFromHuman(itemResourceId: Int64, resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            let fieldId = formFieldName(resourceId)
            if (fieldId.size == 0) { return rejected(false, "unknown_form_field") }
            if (let Some(record) <- recordForIdUnlocked(itemResourceId)) {
                let result = editRecordTextUnlocked(record.id, fieldId, text, selectionStart, selectionEnd, record.draftVersion)
                if (result.applied) { record.activeFieldId = fieldId }
                return result
            }
            return rejected(false, "unknown_record")
        }
    }
    public func editBooleanForCollectionItemFromHuman(itemResourceId: Int64, resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            let fieldId = formFieldName(resourceId)
            if (fieldId.size == 0) { return rejected(false, "unknown_form_field") }
            if (let Some(record) <- recordForIdUnlocked(itemResourceId)) {
                let result = editRecordBooleanUnlocked(record.id, fieldId, value, record.draftVersion)
                if (result.applied) { record.activeFieldId = fieldId }
                return result
            }
            return rejected(false, "unknown_record")
        }
    }
    public func applyDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let _ = expectedBaseAppliedConfigVersion
        return synchronized(lock) { applyDraftUnlocked(selectedId, expectedDraftVersion) }
    }
    public func cancelDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let _ = expectedBaseAppliedConfigVersion
        return synchronized(lock) { cancelDraftUnlocked(selectedId, expectedDraftVersion) }
    }
    public func applyDraftForCollectionItemFromHuman(itemResourceId: Int64, expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let _ = expectedBaseAppliedConfigVersion
        return synchronized(lock) { applyDraftUnlocked(itemResourceId, expectedDraftVersion) }
    }
    public func cancelDraftForCollectionItemFromHuman(itemResourceId: Int64, expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let _ = expectedBaseAppliedConfigVersion
        return synchronized(lock) { cancelDraftUnlocked(itemResourceId, expectedDraftVersion) }
    }

    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>): CjguiSharedOperationChanges {
        return changesSince(sinceVersion, resourceFilter, "")
    }
    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>, expectedStreamIdentity: String): CjguiSharedOperationChanges {
        return synchronized(lock) { changesSinceUnlocked(sinceVersion, resourceFilter, expectedStreamIdentity) }
    }

    public func saveAsFromHuman(path: String): CjguiSharedOperationActionResult { return synchronized(lock) { saveUnlocked(path, true) } }
    public func saveFromHuman(): CjguiSharedOperationActionResult { return synchronized(lock) { saveUnlocked(currentFilePath, false) } }
    public func openFromHuman(path: String): CjguiSharedOperationActionResult { return openPath(path) }
    public func hasUnsavedContent(): Bool { return synchronized(lock) { hasUnsavedContentUnlocked() } }

    /// An explicit user decision is required before replacing the current
    /// document. This retains the allocator so an old authorization can never
    /// land on an object newly created after a discard/new cycle.
    public func discardUnsavedContentFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (!hasUnsavedContentUnlocked()) { return accepted("nothing_to_discard") }
            if (currentFilePath.size == 0) {
                clearDocumentUnlocked()
                documentGeneration += 1; versionValue += 1; status = "未保存内容已放弃；已回到新建规则集"
                appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "document_discarded")
                return accepted("discarded")
            }
            if (let Some(loaded) <- parseRuleSet(lastPersistedPayload)) {
                replaceLoadedDocumentUnlocked(loaded, currentFilePath, lastPersistedPayload)
                versionValue += 1; status = "未保存内容已放弃；已回到上次成功保存状态"
                appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "document_discarded")
                return accepted("discarded")
            }
            return rejected(false, "persisted_snapshot_invalid")
        }
    }

    public func newUntitledFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (hasUnsavedContentUnlocked()) { return rejected(false, "unsaved_content_requires_save_or_discard") }
            clearDocumentUnlocked()
            documentGeneration += 1; versionValue += 1; status = "新建规则集；请新增一条规则"
            appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "document_created")
            return accepted("new_document")
        }
    }
    public func requestCloseFromHuman(): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (hasUnsavedContentUnlocked()) {
                status = "存在未保存内容：请保存、明确放弃，或取消关闭"
                return rejected(false, "unsaved_content_requires_save_or_discard")
            }
            status = "可以关闭；没有未保存内容"
            return accepted("close_permitted")
        }
    }

    private func descriptor(name: String, display: String, parameters: ArrayList<CjguiSharedOperationParameterDescriptor>, minimum: Int64, maximum: Int64): CjguiSharedOperationActionDescriptor {
        return CjguiSharedOperationActionDescriptor(name, display, parameters, minimum, maximum)
    }
    private func parameter(name: String, valueType: String): CjguiSharedOperationParameterDescriptor { return CjguiSharedOperationParameterDescriptor(name, valueType, true) }
    private func createParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("label", "STRING"), parameter("enabled", "BOOLEAN"), parameter("retentionCount", "INTEGER"), parameter("excludedType", "STRING"), parameter("requestId", "STRING")]) }
    private func copyParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("label", "STRING"), parameter("requestId", "STRING")]) }
    private func renameParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("label", "STRING"), parameter("requestId", "STRING")]) }
    private func requestParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("requestId", "STRING")]) }
    private func draftTextParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("fieldId", "STRING"), parameter("text", "STRING"), parameter("expectedDraftVersion", "INTEGER")]) }
    private func draftBooleanParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("fieldId", "STRING"), parameter("value", "BOOLEAN"), parameter("expectedDraftVersion", "INTEGER")]) }
    private func draftApplyParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("expectedDraftVersion", "INTEGER")]) }
    private func batchParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> { return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("enabled", "BOOLEAN"), parameter("requestId", "STRING")]) }
    private func splitSizeParameters(): ArrayList<CjguiSharedOperationParameterDescriptor> {
        return ArrayList<CjguiSharedOperationParameterDescriptor>([parameter("value", "INTEGER")])
    }

    private func snapshotUnlocked(): CjguiRuleSetSnapshot {
        let result = ArrayList<CjguiRuleSetRecord>()
        for (record in records) { result.add(record.appliedProjection()) }
        return CjguiRuleSetSnapshot(versionValue, selectedId, result, currentFilePath, currentFilePath.size > 0 && lastPersistedPayload == serializeUnlocked())
    }

    private func collectionSnapshotUnlocked(): CjguiSharedCollectionSnapshot {
        let items = ArrayList<CjguiSharedCollectionItemProjection>()
        for (record in records) { items.add(CjguiSharedCollectionItemProjection(record.id, record.label, record.id == selectedId)) }
        return CjguiSharedCollectionSnapshot(versionValue, selectedId, items, status)
    }

    private func formSnapshotUnlocked(): CjguiSharedFormSnapshot {
        if (let Some(record) <- selectedUnlocked()) {
            // The published field version is the record's own draft version: the
            // one `EDIT_DRAFT_TEXT` and `APPLY_DRAFT` compare against. Publishing
            // a per-field counter made the token an external reader sees differ
            // from the token the write operations expect as soon as two fields
            // were edited in one flow.
            return CjguiSharedFormSnapshot(
                versionValue, record.appliedRevision, record.draftVersion, record.baseAppliedRevision,
                ArrayList<CjguiSharedFormFieldProjection>([
                    formProjection(CjguiRuleSetEditingDomain.formLabelResourceId, "label", CjguiSharedOperationValue.string(record.label), record.draftLabel, record.labelError, record.draftVersion, record.activeFieldId == "label", record.selectionStart, record.selectionEnd),
                    formProjection(CjguiRuleSetEditingDomain.formEnabledResourceId, "enabled", CjguiSharedOperationValue.boolean(record.enabled), if (record.draftEnabled) { "true" } else { "false" }, "", record.draftVersion, record.activeFieldId == "enabled", 0, 0),
                    formProjection(CjguiRuleSetEditingDomain.formRetentionResourceId, "retentionCount", CjguiSharedOperationValue.integer(record.retentionCount), record.draftRetentionCount, record.retentionError, record.draftVersion, record.activeFieldId == "retentionCount", record.selectionStart, record.selectionEnd),
                    formProjection(CjguiRuleSetEditingDomain.formExcludedTypeResourceId, "excludedType", CjguiSharedOperationValue.string(record.excludedType), record.draftExcludedType, record.excludedError, record.draftVersion, record.activeFieldId == "excludedType", record.selectionStart, record.selectionEnd)
                ]), record.baseAppliedRevision == record.appliedRevision, status
            )
        }
        return CjguiSharedFormSnapshot(
            versionValue, 0, 0, -1,
            ArrayList<CjguiSharedFormFieldProjection>([
                formProjection(CjguiRuleSetEditingDomain.formLabelResourceId, "label", CjguiSharedOperationValue.string(""), "", "select_or_create_rule", 0, false, 0, 0),
                formProjection(CjguiRuleSetEditingDomain.formEnabledResourceId, "enabled", CjguiSharedOperationValue.boolean(false), "false", "", 0, false, 0, 0),
                formProjection(CjguiRuleSetEditingDomain.formRetentionResourceId, "retentionCount", CjguiSharedOperationValue.integer(0), "", "", 0, false, 0, 0),
                formProjection(CjguiRuleSetEditingDomain.formExcludedTypeResourceId, "excludedType", CjguiSharedOperationValue.string(""), "", "", 0, false, 0, 0)
            ]), false, status
        )
    }

    private func formProjection(resourceId: Int64, fieldId: String, applied: CjguiSharedOperationValue, draft: String, error: String, fieldVersion: Int64, focused: Bool, selectionStart: Int64, selectionEnd: Int64): CjguiSharedFormFieldProjection {
        return CjguiSharedFormFieldProjection(resourceId, fieldId, applied, draft, error, fieldVersion, focused, selectionStart, selectionEnd)
    }

    private func contextSnapshotUnlocked(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        let relations = ArrayList<CjguiSharedOperationRelation>()
        resources.add(CjguiSharedOperationResource(CjguiRuleSetEditingDomain.ruleSetResourceId, "本地备份规则集", ArrayList<CjguiSharedOperationField>([
            CjguiSharedOperationField("selectedRecordId", CjguiSharedOperationValue.integer(selectedId)),
            CjguiSharedOperationField("recordCount", CjguiSharedOperationValue.integer(records.size)),
            CjguiSharedOperationField("filePath", CjguiSharedOperationValue.string(currentFilePath)),
            CjguiSharedOperationField("splitFirstSize", CjguiSharedOperationValue.integer(splitFirstSizeValue)),
            CjguiSharedOperationField("hasUnsavedContent", CjguiSharedOperationValue.boolean(currentFilePath.size == 0 || lastPersistedPayload != serializeUnlocked()))
        ])))
        for (record in records) {
            resources.add(CjguiSharedOperationResource(record.id, record.label, ArrayList<CjguiSharedOperationField>([
                CjguiSharedOperationField("label", CjguiSharedOperationValue.string(record.label)),
                CjguiSharedOperationField("enabled", CjguiSharedOperationValue.boolean(record.enabled)),
                CjguiSharedOperationField("retentionCount", CjguiSharedOperationValue.integer(record.retentionCount)),
                CjguiSharedOperationField("excludedType", CjguiSharedOperationValue.string(record.excludedType)),
                CjguiSharedOperationField("draftVersion", CjguiSharedOperationValue.integer(record.draftVersion)),
                CjguiSharedOperationField("isSelected", CjguiSharedOperationValue.boolean(record.id == selectedId))
            ])))
        }
        if (selectedId >= 0) {
            relations.add(CjguiSharedOperationRelation("selection", "currentRule", "SELECTS", "resource", "rule${selectedId}", resourceIds: ArrayList<Int64>([selectedId])))
            relations.add(CjguiSharedOperationRelation("resource", "rule${selectedId}", "HAS", "draft", "selectedRuleDraft", resourceIds: ArrayList<Int64>([selectedId])))
        }
        return CjguiSharedOperationContextSnapshot(
            versionValue, "可恢复备份规则集", resourceType(), resources,
            relations: relations, streamIdentity: changeStreamIdentityUnlocked()
        )
    }

    /// Builds only explicitly named owner records.  In particular, a normal
    /// record lookup uses `recordsById`, so its cost is independent of other
    /// off-screen records.  The synthetic rule-set resource remains global by
    /// design because its fields describe the complete owning document.
    private func contextSnapshotForTargetsUnlocked(
        targets: ArrayList<Int64>
    ): ?CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        let relations = ArrayList<CjguiSharedOperationRelation>()
        for (target in targets) {
            if (target == CjguiRuleSetEditingDomain.ruleSetResourceId) {
                resources.add(CjguiSharedOperationResource(CjguiRuleSetEditingDomain.ruleSetResourceId, "本地备份规则集", ArrayList<CjguiSharedOperationField>([
                    CjguiSharedOperationField("selectedRecordId", CjguiSharedOperationValue.integer(selectedId)),
                    CjguiSharedOperationField("recordCount", CjguiSharedOperationValue.integer(records.size)),
                    CjguiSharedOperationField("filePath", CjguiSharedOperationValue.string(currentFilePath)),
                    CjguiSharedOperationField("splitFirstSize", CjguiSharedOperationValue.integer(splitFirstSizeValue)),
                    CjguiSharedOperationField("hasUnsavedContent", CjguiSharedOperationValue.boolean(currentFilePath.size == 0 || lastPersistedPayload != serializeUnlocked()))
                ])))
            } else if (let Some(record) <- recordsById.get(target)) {
                resources.add(CjguiSharedOperationResource(record.id, record.label, ArrayList<CjguiSharedOperationField>([
                    CjguiSharedOperationField("label", CjguiSharedOperationValue.string(record.label)),
                    CjguiSharedOperationField("enabled", CjguiSharedOperationValue.boolean(record.enabled)),
                    CjguiSharedOperationField("retentionCount", CjguiSharedOperationValue.integer(record.retentionCount)),
                    CjguiSharedOperationField("excludedType", CjguiSharedOperationValue.string(record.excludedType)),
                    CjguiSharedOperationField("draftVersion", CjguiSharedOperationValue.integer(record.draftVersion)),
                    CjguiSharedOperationField("isSelected", CjguiSharedOperationValue.boolean(record.id == selectedId))
                ])))
            } else {
                return None
            }
        }
        if (selectedId >= 0 && containsId(targets, selectedId)) {
            relations.add(CjguiSharedOperationRelation("selection", "currentRule", "SELECTS", "resource", "rule${selectedId}", resourceIds: ArrayList<Int64>([selectedId])))
            relations.add(CjguiSharedOperationRelation("resource", "rule${selectedId}", "HAS", "draft", "selectedRuleDraft", resourceIds: ArrayList<Int64>([selectedId])))
        }
        return Some(CjguiSharedOperationContextSnapshot(
            versionValue, "可恢复备份规则集", resourceType(), resources,
            relations: relations, streamIdentity: changeStreamIdentityUnlocked()
        ))
    }

    private func selectedUnlocked(): ?CjguiMutableRuleSetRecord { return recordForIdUnlocked(selectedId) }
    private func recordForIdUnlocked(id: Int64): ?CjguiMutableRuleSetRecord { return recordsById.get(id) }
    private func formFieldName(resourceId: Int64): String {
        if (resourceId == CjguiRuleSetEditingDomain.formLabelResourceId) { return "label" }
        if (resourceId == CjguiRuleSetEditingDomain.formEnabledResourceId) { return "enabled" }
        if (resourceId == CjguiRuleSetEditingDomain.formRetentionResourceId) { return "retentionCount" }
        if (resourceId == CjguiRuleSetEditingDomain.formExcludedTypeResourceId) { return "excludedType" }
        return ""
    }

    private func acceptTransferUnlocked(
        request: CjguiSharedOperationTransferAcceptRequest,
        external: Bool,
        requestId: String
    ): CjguiSharedOperationTransferResult {
        if (request.targetId != CjguiRuleSetEditingDomain.ruleSetResourceId ||
            request.offer.format.kind != "STRUCTURED" ||
            request.offer.format.identifier != CjguiRuleSetEditingDomain.transferFormatIdentifier ||
            request.offer.format.version != CjguiRuleSetEditingDomain.transferFormatVersion) {
            return CjguiSharedOperationTransferResult.rejected(
                versionValue, "unsupported_transfer_format", format: Some(request.acceptedFormat))
        }
        if (let Some(parsed) <- parseTransferRecord(request.offer.payload)) {
            var actionName = "CREATE_RECORD"
            var targets = ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId])
            if (request.offer.sourceKind == "rule_record" && request.offer.sourceIdentity == instanceIdentity) {
                if (let Some(source) <- recordForIdUnlocked(request.offer.sourceId)) {
                    if (source.label != parsed.label || source.enabled != parsed.enabled ||
                        source.retentionCount != parsed.retentionCount || source.excludedType != parsed.excludedType) {
                        return CjguiSharedOperationTransferResult.rejected(
                            versionValue, "source_payload_mismatch", format: Some(request.acceptedFormat))
                    }
                    actionName = "COPY_RECORD"
                    targets = ArrayList<Int64>([source.id])
                }
            }
            let arguments = ArrayList<CjguiSharedOperationActionArgument>()
            arguments.add(CjguiSharedOperationActionArgument(
                "label", CjguiSharedOperationValue.string(parsed.label)))
            if (actionName == "CREATE_RECORD") {
                arguments.add(CjguiSharedOperationActionArgument(
                    "enabled", CjguiSharedOperationValue.boolean(parsed.enabled)))
                arguments.add(CjguiSharedOperationActionArgument(
                    "retentionCount", CjguiSharedOperationValue.integer(parsed.retentionCount)))
                arguments.add(CjguiSharedOperationActionArgument(
                    "excludedType", CjguiSharedOperationValue.string(parsed.excludedType)))
            }
            if (external) {
                arguments.add(CjguiSharedOperationActionArgument(
                    "requestId", CjguiSharedOperationValue.string(requestId)))
            }
            // We already hold the owner lock; call the existing dispatcher
            // directly instead of recursively acquiring it.
            let action = executeUnlocked(
                CjguiSharedOperationActionInvocation(actionName, request.expectedVersion, targets, arguments),
                external)
            return CjguiSharedOperationTransferResult.fromActionResult(action, request.offer)
        }
        return CjguiSharedOperationTransferResult.rejected(
            versionValue, "invalid_structured_payload", format: Some(request.acceptedFormat))
    }

    private func executeUnlocked(invocation: CjguiSharedOperationActionInvocation, external: Bool): CjguiSharedOperationActionResult {
        let requestId = stringArgument(invocation, "requestId")
        if (external) {
            if (let Some(id) <- requestId) {
                if (id.size == 0 || id.size > 128) { return rejected(false, "invalid_request_id") }
                let fingerprint = requestFingerprint(invocation)
                if (let Some(previous) <- appliedRequests.get(id)) {
                    if (previous.fingerprint != fingerprint) { return rejected(true, "request_id_reused") }
                    return CjguiSharedOperationActionResult(true, false, previous.appliedVersion, previous.appliedVersion, "already_applied_request")
                }
            }
            if (invocation.expectedVersion != versionValue) { return rejected(true, "version_conflict") }
        }
        var result = rejected(false, "unknown_action")
        if (invocation.actionName == "CREATE_RECORD") { result = createUnlocked(invocation) }
        else if (invocation.actionName == "SELECT_RECORD") { result = selectUnlocked(invocation) }
        else if (invocation.actionName == "EDIT_DRAFT_TEXT") { result = externalEditTextUnlocked(invocation) }
        else if (invocation.actionName == "EDIT_DRAFT_BOOLEAN") { result = externalEditBooleanUnlocked(invocation) }
        else if (invocation.actionName == "APPLY_DRAFT") { result = applyExternalDraftUnlocked(invocation) }
        else if (invocation.actionName == "CANCEL_DRAFT") { result = cancelExternalDraftUnlocked(invocation) }
        else if (invocation.actionName == "RENAME_RECORD") { result = renameUnlocked(invocation) }
        else if (invocation.actionName == "COPY_RECORD") { result = copyUnlocked(invocation) }
        else if (invocation.actionName == "DELETE_RECORD") { result = deleteUnlocked(invocation) }
        else if (invocation.actionName == "BATCH_SET_ENABLED") { result = batchSetEnabledUnlocked(invocation) }
        else if (invocation.actionName == "UNDO") { result = undoUnlocked(invocation) }
        else if (invocation.actionName == "REDO") { result = redoUnlocked(invocation) }
        else if (invocation.actionName == "SAVE_RULE_SET") { result = if (isRuleSetTarget(invocation)) { saveUnlocked(currentFilePath, false) } else { rejected(false, "invalid_target") } }
        else if (invocation.actionName == "SET_SPLIT_SIZE") { result = setSplitSizeUnlocked(invocation) }
        if (result.applied && external) {
            if (let Some(id) <- requestId) { rememberAppliedRequestUnlocked(id, requestFingerprint(invocation), result.versionAfter) }
        }
        return result
    }

    private func setSplitSizeUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (!isRuleSetTarget(invocation)) { return rejected(false, "invalid_target") }
        if (let Some(value) <- integerArgument(invocation, "value")) {
            if (value < 160 || value > 720) { return rejected(false, "invalid_split_size") }
            if (value == splitFirstSizeValue) { return accepted("already_at_target") }
            let versionBefore = versionValue
            splitFirstSizeValue = value
            splitFirstSizeVersionValue += 1
            versionValue += 1
            // A pane boundary is a domain-owned presentation preference, not
            // saved rule content. Keep it visible to change cursors without
            // turning it into an unsaved business document mutation.
            appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "split_size_changed")
            return CjguiSharedOperationActionResult(true, false, versionBefore, versionValue, "split_size_set")
        }
        return rejected(false, "invalid_parameters")
    }

    private func createUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (!isRuleSetTarget(invocation)) { return rejected(false, "invalid_target") }
        if (let Some(label) <- stringArgument(invocation, "label")) {
            if (let Some(enabled) <- booleanArgument(invocation, "enabled")) {
                if (let Some(retention) <- integerArgument(invocation, "retentionCount")) {
                    if (let Some(excluded) <- stringArgument(invocation, "excludedType")) {
                        if (!validRule(label, retention, excluded)) { return rejected(false, "invalid_rule") }
                        recordUndoUnlocked()
                        let record = CjguiMutableRuleSetRecord(nextId, label, enabled, retention, excluded)
                        nextId += 1; records.add(record); let _ = recordsById.add(record.id, record); selectedId = record.id
                        commitContentUnlocked(ArrayList<Int64>([record.id]), "record_created")
                        return accepted("created")
                    }
                }
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func selectUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 0) { return rejected(false, "invalid_parameters") }
        let target = invocation.targetResourceIds[0]
        if (let Some(_) <- recordForIdUnlocked(target)) {
            if (selectedId == target) { return accepted("already_selected") }
            selectedId = target; versionValue += 1; status = "已切换规则；该规则的草稿被保留"
            return accepted("selected")
        }
        return rejected(false, "unknown_record")
    }

    private func externalEditTextUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
            if (let Some(text) <- stringArgument(invocation, "text")) {
                if (let Some(expectedDraft) <- integerArgument(invocation, "expectedDraftVersion")) {
                    return editRecordTextUnlocked(invocation.targetResourceIds[0], fieldId, text, 0, 0, expectedDraft)
                }
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func externalEditBooleanUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(fieldId) <- stringArgument(invocation, "fieldId")) {
            if (let Some(value) <- booleanArgument(invocation, "value")) {
                if (let Some(expectedDraft) <- integerArgument(invocation, "expectedDraftVersion")) {
                    return editRecordBooleanUnlocked(invocation.targetResourceIds[0], fieldId, value, expectedDraft)
                }
            }
        }
        return rejected(false, "invalid_parameters")
    }

    private func applyExternalDraftUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return applyDraftUnlocked(invocation.targetResourceIds[0], expected) }
        return rejected(false, "invalid_parameters")
    }
    private func cancelExternalDraftUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(expected) <- integerArgument(invocation, "expectedDraftVersion")) { return cancelDraftUnlocked(invocation.targetResourceIds[0], expected) }
        return rejected(false, "invalid_parameters")
    }

    private func editSelectedTextUnlocked(fieldId: String, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        if (fieldId.size == 0) { return rejected(false, "unknown_form_field") }
        if (let Some(record) <- selectedUnlocked()) {
            let result = editRecordTextUnlocked(record.id, fieldId, text, selectionStart, selectionEnd, record.draftVersion)
            if (result.applied) { record.activeFieldId = fieldId }
            return result
        }
        return rejected(false, "no_selected_record")
    }
    private func editSelectedBooleanUnlocked(fieldId: String, value: Bool): CjguiSharedOperationActionResult {
        if (fieldId.size == 0) { return rejected(false, "unknown_form_field") }
        if (let Some(record) <- selectedUnlocked()) {
            let result = editRecordBooleanUnlocked(record.id, fieldId, value, record.draftVersion)
            if (result.applied) { record.activeFieldId = fieldId }
            return result
        }
        return rejected(false, "no_selected_record")
    }
    private func editRecordTextUnlocked(recordId: Int64, fieldId: String, text: String, selectionStart: Int64, selectionEnd: Int64, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (let Some(record) <- recordForIdUnlocked(recordId)) {
            if (expectedDraftVersion != record.draftVersion) { return rejected(true, "draft_version_conflict") }
            if (fieldId == "label") {
                if (record.draftLabel == text) { record.selectionStart = selectionStart; record.selectionEnd = selectionEnd; return accepted("already_at_target") }
                record.draftLabel = text; record.labelFieldVersion += 1
            } else if (fieldId == "retentionCount") {
                if (record.draftRetentionCount == text) { record.selectionStart = selectionStart; record.selectionEnd = selectionEnd; return accepted("already_at_target") }
                record.draftRetentionCount = text; record.retentionFieldVersion += 1
            } else if (fieldId == "excludedType") {
                if (record.draftExcludedType == text) { record.selectionStart = selectionStart; record.selectionEnd = selectionEnd; return accepted("already_at_target") }
                record.draftExcludedType = text; record.excludedFieldVersion += 1
            } else { return rejected(false, "field_requires_boolean") }
            record.selectionStart = selectionStart; record.selectionEnd = selectionEnd
            record.draftVersion += 1; versionValue += 1; status = "草稿已修改，尚未应用"
            return accepted("draft_updated")
        }
        return rejected(false, "unknown_record")
    }
    private func editRecordBooleanUnlocked(recordId: Int64, fieldId: String, value: Bool, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (let Some(record) <- recordForIdUnlocked(recordId)) {
            if (expectedDraftVersion != record.draftVersion) { return rejected(true, "draft_version_conflict") }
            if (fieldId != "enabled") { return rejected(false, "field_requires_text") }
            if (record.draftEnabled == value) { return accepted("already_at_target") }
            record.draftEnabled = value; record.enabledFieldVersion += 1; record.draftVersion += 1; versionValue += 1
            status = "草稿已修改，尚未应用"; return accepted("draft_updated")
        }
        return rejected(false, "unknown_record")
    }

    private func applyDraftUnlocked(recordId: Int64, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (let Some(record) <- recordForIdUnlocked(recordId)) {
            if (expectedDraftVersion != record.draftVersion || record.baseAppliedRevision != record.appliedRevision) { return rejected(true, "stale_draft") }
            if (!validateDraftUnlocked(record)) { record.draftVersion += 1; versionValue += 1; status = "草稿校验失败，已保留原输入"; return rejected(false, "invalid_draft") }
            if (record.draftLabel == record.label && record.draftEnabled == record.enabled && record.draftRetentionCount == record.retentionCount.toString() && record.draftExcludedType == record.excludedType) { return accepted("already_applied") }
            if (let Some(retention) <- Int64.tryParse(record.draftRetentionCount)) {
                // A label-only apply cannot move the row between groups or change
                // its order, so the tree projection may patch it by key. Any
                // other field makes this a structural change (rebuild).
                let labelOnly = record.draftLabel != record.label &&
                    record.draftEnabled == record.enabled &&
                    record.draftRetentionCount == record.retentionCount.toString() &&
                    record.draftExcludedType == record.excludedType
                recordUndoUnlocked()
                record.label = record.draftLabel; record.enabled = record.draftEnabled; record.retentionCount = retention; record.excludedType = record.draftExcludedType
                record.appliedRevision += 1; record.baseAppliedRevision = record.appliedRevision; record.activeFieldId = ""
                clearValidationUnlocked(record); record.draftVersion += 1
                commitContentUnlocked(ArrayList<Int64>([record.id]),
                    if (labelOnly) { "draft_applied_label_only" } else { "draft_applied" })
                return accepted("draft_applied")
            }
            return rejected(false, "invalid_draft")
        }
        return rejected(false, "unknown_record")
    }
    private func cancelDraftUnlocked(recordId: Int64, expectedDraftVersion: Int64): CjguiSharedOperationActionResult {
        if (let Some(record) <- recordForIdUnlocked(recordId)) {
            if (expectedDraftVersion != record.draftVersion || record.baseAppliedRevision != record.appliedRevision) { return rejected(true, "stale_draft") }
            resetDraftUnlocked(record); record.draftVersion += 1; versionValue += 1; status = "草稿已取消并重载已应用规则"
            return accepted("draft_cancelled")
        }
        return rejected(false, "unknown_record")
    }

    private func renameUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(label) <- stringArgument(invocation, "label")) {
            if (label.size == 0 || label.size > 128) { return rejected(false, "invalid_rule_label") }
            if (let Some(record) <- recordForIdUnlocked(invocation.targetResourceIds[0])) {
                if (record.label == label) { return accepted("already_at_target") }
                if (record.draftLabel != record.label) { return rejected(true, "rename_conflicts_with_label_draft") }
                recordUndoUnlocked(); record.label = label; record.draftLabel = label
                record.labelFieldVersion += 1; record.appliedRevision += 1; record.baseAppliedRevision = record.appliedRevision
                commitContentUnlocked(ArrayList<Int64>([record.id]), "record_renamed"); return accepted("renamed")
            }
            return rejected(false, "unknown_record")
        }
        return rejected(false, "invalid_parameters")
    }
    private func copyUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        if (let Some(source) <- recordForIdUnlocked(invocation.targetResourceIds[0])) {
            if (let Some(label) <- stringArgument(invocation, "label")) {
                if (label.size == 0 || label.size > 128) { return rejected(false, "invalid_rule_label") }
                recordUndoUnlocked(); let copy = CjguiMutableRuleSetRecord(nextId, label, source.enabled, source.retentionCount, source.excludedType)
                nextId += 1; records.add(copy); let _ = recordsById.add(copy.id, copy); selectedId = copy.id; commitContentUnlocked(ArrayList<Int64>([copy.id]), "record_copied"); return accepted("copied")
            }
            return rejected(false, "invalid_parameters")
        }
        return rejected(false, "unknown_record")
    }
    private func deleteUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (invocation.targetResourceIds.size != 1) { return rejected(false, "invalid_target") }
        var index: Int64 = 0
        while (index < records.size) {
            if (records[index].id == invocation.targetResourceIds[0]) {
                if (hasUnappliedDraftUnlocked(records[index])) { return rejected(true, "delete_conflicts_with_draft") }
                recordUndoUnlocked(); let deletedId = records[index].id; let _ = records.remove(at: index); let _ = recordsById.remove(deletedId)
                if (selectedId == deletedId) { selectedId = if (records.size > 0) { records[0].id } else { -1 } }
                commitContentUnlocked(ArrayList<Int64>([deletedId]), "record_deleted"); return accepted("deleted")
            }
            index += 1
        }
        return rejected(false, "unknown_record")
    }

    private func batchSetEnabledUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (let Some(enabled) <- booleanArgument(invocation, "enabled")) {
            if (invocation.targetResourceIds.size == 0 || invocation.targetResourceIds.size > 1024) { return rejected(false, "invalid_targets") }
            for (id in invocation.targetResourceIds) { if (let None <- recordForIdUnlocked(id)) { return rejected(false, "unknown_record") } }
            var changed = false
            for (id in invocation.targetResourceIds) { if (let Some(record) <- recordForIdUnlocked(id)) { if (record.enabled != enabled) { changed = true } } }
            if (!changed) { return accepted("already_at_target") }
            for (id in invocation.targetResourceIds) {
                if (let Some(record) <- recordForIdUnlocked(id)) {
                    if (record.enabled != enabled && record.draftEnabled != record.enabled) { return rejected(true, "batch_conflicts_with_enabled_draft") }
                }
            }
            recordUndoUnlocked()
            for (id in invocation.targetResourceIds) {
                if (let Some(record) <- recordForIdUnlocked(id)) {
                    if (record.enabled != enabled) {
                        record.enabled = enabled; record.draftEnabled = enabled; record.enabledFieldVersion += 1
                        record.appliedRevision += 1; record.baseAppliedRevision = record.appliedRevision
                    }
                }
            }
            commitContentUnlocked(uniqueIds(invocation.targetResourceIds), "batch_enabled")
            return accepted("batch_applied")
        }
        return rejected(false, "invalid_parameters")
    }

    private func undoUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (!isRuleSetTarget(invocation) || invocation.arguments.size != 0) { return rejected(false, "invalid_target") }
        if (let Some(previous) <- undoHistory.remove()) {
            let beforeIds = changedIdsForHistory(previous)
            let current = historyEntryUnlocked()
            if (!canRestoreHistoryUnlocked(previous)) { undoHistory.add(previous); return rejected(true, "undo_conflicts_with_draft") }
            redoHistory.add(current)
            restoreHistoryUnlocked(previous); commitContentUnlocked(beforeIds, "undo")
            return accepted("undone")
        }
        return rejected(false, "nothing_to_undo")
    }
    private func redoUnlocked(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        if (!isRuleSetTarget(invocation) || invocation.arguments.size != 0) { return rejected(false, "invalid_target") }
        if (let Some(next) <- redoHistory.remove()) {
            let beforeIds = changedIdsForHistory(next)
            let current = historyEntryUnlocked()
            if (!canRestoreHistoryUnlocked(next)) { redoHistory.add(next); return rejected(true, "redo_conflicts_with_draft") }
            undoHistory.add(current)
            restoreHistoryUnlocked(next); commitContentUnlocked(beforeIds, "redo")
            return accepted("redone")
        }
        return rejected(false, "nothing_to_redo")
    }

    private func recordUndoUnlocked() { undoHistory.add(historyEntryUnlocked()); while (let Some(_) <- redoHistory.remove()) {} }
    private func historyEntryUnlocked(): CjguiRuleSetHistoryEntry {
        let applied = ArrayList<CjguiRuleSetRecord>()
        for (record in records) { applied.add(record.appliedProjection()) }
        return CjguiRuleSetHistoryEntry(applied, selectedId)
    }
    private func canRestoreHistoryUnlocked(entry: CjguiRuleSetHistoryEntry): Bool {
        for (current in records) {
            if (let Some(target) <- recordForHistoryEntry(entry, current.id)) {
                if (!sameAppliedRecord(current, target) && hasUnappliedDraftUnlocked(current)) { return false }
            } else if (hasUnappliedDraftUnlocked(current)) { return false }
        }
        return true
    }
    private func restoreHistoryUnlocked(entry: CjguiRuleSetHistoryEntry) {
        let restored = ArrayList<CjguiMutableRuleSetRecord>()
        for (target in entry.records) {
            if (let Some(current) <- recordForIdUnlocked(target.id)) {
                if (!sameAppliedRecord(current, target)) {
                    current.label = target.label; current.enabled = target.enabled; current.retentionCount = target.retentionCount; current.excludedType = target.excludedType
                    current.appliedRevision += 1; resetDraftUnlocked(current); current.draftVersion += 1
                }
                restored.add(current)
            } else {
                restored.add(CjguiMutableRuleSetRecord(target.id, target.label, target.enabled, target.retentionCount, target.excludedType))
            }
        }
        for (record in records) { let _ = recordsById.remove(record.id) }
        while (records.size > 0) { let _ = records.remove(at: records.size - 1) }
        records.add(all: restored)
        for (record in restored) { let _ = recordsById.add(record.id, record) }
        selectedId = entry.selectedRecordId
        if (let None <- recordForIdUnlocked(selectedId)) { selectedId = if (records.size > 0) { records[0].id } else { -1 } }
    }
    private func changedIdsForHistory(entry: CjguiRuleSetHistoryEntry): ArrayList<Int64> {
        let ids = ArrayList<Int64>()
        for (record in records) { ids.add(record.id) }
        for (record in entry.records) { if (!containsId(ids, record.id)) { ids.add(record.id) } }
        return ids
    }

    private func commitContentUnlocked(resourceIds: ArrayList<Int64>, kind: String) {
        versionValue += 1; status = "内容已更新；尚未保存"
        // Classify the change for the tree projection in ONE place. Only a pure
        // label rewrite can be patched by key; creation, deletion, copy,
        // enabled-group moves, batch writes and undo/redo change structure (or
        // cannot be proven not to), so they must fall back to a rebuild.
        let contentOnly = kind == "record_renamed" || kind == "draft_applied_label_only"
        contentChangeUsable = contentOnly
        contentChangeBeforeVersion = if (contentOnly) { versionValue - 1 } else { -1 }
        contentChangeKeys = if (contentOnly) { ArrayList<Int64>(resourceIds) } else { ArrayList<Int64>() }
        for (id in resourceIds) { appendChangeUnlocked(id, kind) }
    }

    /// Content-only change set for a caller that is exactly one version behind,
    /// or None when it must rebuild. Labels are read for the changed keys only,
    /// so the answer costs O(changed), not O(records).
    public func contentChangeSince(version: Int64): ?CjguiRuleSetContentChange {
        synchronized(lock) {
            if (version == versionValue) {
                return Some(CjguiRuleSetContentChange(version, versionValue,
                    ArrayList<Int64>(), ArrayList<String>()))
            }
            if (!contentChangeUsable || version != contentChangeBeforeVersion) {
                return None
            }
            let ids = ArrayList<Int64>()
            let labels = ArrayList<String>()
            for (id in contentChangeKeys) {
                if (let Some(record) <- recordsById.get(id)) {
                    ids.add(id)
                    labels.add(record.label)
                } else {
                    // The changed key no longer exists: structural.
                    return None
                }
            }
            return Some(CjguiRuleSetContentChange(version, versionValue, ids, labels))
        }
    }
    private func appendChangeUnlocked(resourceId: Int64, kind: String) {
        changes.addLast(CjguiSharedOperationChangeEntry(versionValue, resourceId, kind))
        if (changes.size > CjguiRuleSetEditingDomain.maximumChanges) {
            if (let Some(removed) <- changes.removeFirst()) { historyFloorVersion = removed.version }
        }
    }
    private func changesSinceUnlocked(sinceVersion: Int64, resourceFilter: ArrayList<Int64>, expectedStreamIdentity: String): CjguiSharedOperationChanges {
        let streamIdentity = changeStreamIdentityUnlocked()
        if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) ||
            sinceVersion < 0 || sinceVersion > versionValue || sinceVersion < historyFloorVersion) {
            return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, true, ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let result = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changes) {
            if (entry.version > sinceVersion && (resourceFilter.size == 0 || containsId(resourceFilter, entry.resourceId))) { result.add(entry) }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, result)
    }

    private func validateDraftUnlocked(record: CjguiMutableRuleSetRecord): Bool {
        clearValidationUnlocked(record)
        if (record.draftLabel.size == 0) { record.labelError = "rule_label_required" }
        else if (record.draftLabel.size > 128) { record.labelError = "rule_label_too_long" }
        if (record.draftRetentionCount.size == 0) { record.retentionError = "retention_count_required" }
        else if (let Some(value) <- Int64.tryParse(record.draftRetentionCount)) { if (value < retentionMinimumValue || value > retentionMaximumValue) { record.retentionError = "retention_count_out_of_range" } }
        else { record.retentionError = "retention_count_invalid" }
        if (record.draftExcludedType.size == 0) { record.excludedError = "excluded_type_required" }
        else if (record.draftExcludedType.size > 128) { record.excludedError = "excluded_type_too_long" }
        return record.labelError.size == 0 && record.retentionError.size == 0 && record.excludedError.size == 0
    }
    private func clearValidationUnlocked(record: CjguiMutableRuleSetRecord) { record.labelError = ""; record.retentionError = ""; record.excludedError = "" }
    private func hasUnappliedDraftUnlocked(record: CjguiMutableRuleSetRecord): Bool {
        return record.draftLabel != record.label || record.draftEnabled != record.enabled ||
            record.draftRetentionCount != record.retentionCount.toString() || record.draftExcludedType != record.excludedType
    }
    private func resetDraftUnlocked(record: CjguiMutableRuleSetRecord) {
        record.draftLabel = record.label; record.draftEnabled = record.enabled; record.draftRetentionCount = record.retentionCount.toString(); record.draftExcludedType = record.excludedType
        record.baseAppliedRevision = record.appliedRevision; record.activeFieldId = ""; clearValidationUnlocked(record)
        record.labelFieldVersion += 1; record.enabledFieldVersion += 1; record.retentionFieldVersion += 1; record.excludedFieldVersion += 1
    }
    /// The same declared retention boundary the binding publishes and the draft
    /// validator enforces. It used to be restated here as literal 1/90, which is
    /// exactly how a "declared rule" can drift away from what is enforced.
    private func validRule(label: String, retention: Int64, excluded: String): Bool { return label.size > 0 && label.size <= 128 && retention >= retentionMinimumValue && retention <= retentionMaximumValue && excluded.size > 0 && excluded.size <= 128 }
    private func isRuleSetTarget(invocation: CjguiSharedOperationActionInvocation): Bool { return invocation.targetResourceIds.size == 1 && invocation.targetResourceIds[0] == CjguiRuleSetEditingDomain.ruleSetResourceId }
    private func accepted(reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(true, false, versionValue, versionValue, reason) }
    private func rejected(conflict: Bool, reason: String): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(false, conflict, versionValue, versionValue, reason) }

    private func openPath(path: String): CjguiSharedOperationActionResult {
        if (path.size == 0) { return synchronized(lock) { rejected(false, "invalid_file_path") } }
        return synchronized(lock) {
            if (hasUnsavedContentUnlocked()) { return rejected(false, "unsaved_content_requires_save_or_discard") }
            try {
            let payload = String.fromUtf8(File.readFrom(path))
            if (let Some(loaded) <- parseRuleSet(payload)) {
                replaceLoadedDocumentUnlocked(loaded, path, payload)
                versionValue += 1; status = "已打开规则集文件"
                appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "file_opened")
                return accepted("opened")
            }
            return rejected(false, "invalid_or_unsupported_file")
            } catch (_) {
                return rejected(false, "file_read_failed")
            }
        }
    }

    private func saveUnlocked(path: String, isSaveAs: Bool): CjguiSharedOperationActionResult {
        if (path.size == 0) { return rejected(false, "no_file_path") }
        if (hasUnappliedDraftUnlocked()) {
            status = "请先应用草稿或取消并重载，再保存规则集"
            return rejected(false, "unapplied_drafts_require_apply_or_cancel")
        }
        // `Directory.create` is an atomic filesystem operation. Every CJGUI
        // writer cooperates through this adjacent lease for the full
        // recheck/write/rename sequence; a second live instance fails closed
        // instead of crossing the old temp-compare-rename window.
        if (let Some(leasePath) <- acquireSaveLease(path)) {
            holdLeaseForCrashProbeIfRequested()
            let result = saveWithLeaseUnlocked(path, isSaveAs)
            releaseSaveLease(leasePath)
            return result
        }
        status = "另一个规则集实例正在保存；请稍后重试"
        return rejected(false, "save_in_progress")
    }

    private func saveWithLeaseUnlocked(path: String, isSaveAs: Bool): CjguiSharedOperationActionResult {
        // Both validation reads happen after the lease is held. A cooperating
        // first writer can therefore commit, after which this instance reads a
        // changed payload and reports a conflict rather than overwriting it.
        if (isSaveAs && currentFilePath != path && exists(path)) { return rejected(false, "save_target_exists") }
        if (!isSaveAs && currentFilePath == path) {
            try {
                if (!exists(path) || String.fromUtf8(File.readFrom(path)) != lastPersistedPayload) { return rejected(false, "external_file_conflict") }
            } catch (_) { return rejected(false, "file_read_failed") }
        }
        let payload = serializeUnlocked()
        let targetPath = Path(path)
        try {
            let temporaryDirectory = Directory.createTemp(targetPath.parent)
            let temporaryPath = temporaryDirectory.join("cjgui-write")
            try {
                File.writeTo(temporaryPath, payload.toArray())
                // Recheck after producing a fully written private temp file. This
                // cannot make an arbitrary third-party writer cooperate, but it
                // closes the application-to-application race before replacement.
                if (!isSaveAs && currentFilePath == path &&
                    (!exists(path) || String.fromUtf8(File.readFrom(path)) != lastPersistedPayload)) {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                    return rejected(false, "external_file_conflict")
                }
                rename(temporaryPath, to: targetPath, overwrite: true)
                let _ = removeIfExists(temporaryDirectory, recursive: true)
                currentFilePath = path; lastPersistedPayload = payload; versionValue += 1; status = "规则集已原子保存"
                appendChangeUnlocked(CjguiRuleSetEditingDomain.ruleSetResourceId, "file_saved")
                return accepted("saved")
            } catch (_) {
                try { let _ = removeIfExists(temporaryDirectory, recursive: true) } catch (_) {}
                return rejected(false, "file_write_failed")
            }
        } catch (_) {
            return rejected(false, "file_write_failed")
        }
    }

    private func acquireSaveLease(path: String): ?Path {
        let leasePath = Path("${path}.cjgui-save-lock")
        try {
            Directory.create(leasePath, recursive: false)
            return Some(leasePath)
        } catch (_) {
            return None
        }
    }
    private func releaseSaveLease(leasePath: Path): Unit {
        try { let _ = removeIfExists(leasePath, recursive: true) } catch (_) {}
    }
    // A process-test seam only. It is inert unless a private path is supplied
    // in the environment, never cleans a lease itself, and lets the test kill
    // a real writer after production acquisition but before rename.
    private func holdLeaseForCrashProbeIfRequested(): Unit {
        if (let Some(path) <- getVariable("CJGUI_RULE_SET_SAVE_HOLD_AFTER_LEASE")) {
            while (path.size > 0 && exists(path)) { sleep(Duration.millisecond) }
        }
    }

    private func serializeUnlocked(): String {
        let payload = StringBuilder()
        payload.append("CJGUI_RULE_SET 1\nNEXT_ID ${nextId}\nSELECTED ${selectedId}\n")
        for (record in records) {
            payload.append("RECORD ${record.id} ${if (record.enabled) { 1 } else { 0 }} ${record.retentionCount} ${encodeHex(record.label)} ${encodeHex(record.excludedType)}\n")
        }
        payload.append("END\n")
        return payload.toString()
    }
    private func hasUnappliedDraftUnlocked(): Bool {
        for (record in records) {
            if (hasUnappliedDraftUnlocked(record)) { return true }
        }
        return false
    }
    private func hasUnsavedContentUnlocked(): Bool {
        if (hasUnappliedDraftUnlocked()) { return true }
        if (records.size == 0 && currentFilePath.size == 0) { return false }
        return currentFilePath.size == 0 || lastPersistedPayload != serializeUnlocked()
    }
    private func changeStreamIdentityUnlocked(): String { return "stream_${instanceIdentity}_${documentGeneration}" }
    private func clearDocumentUnlocked() {
        for (record in records) { let _ = recordsById.remove(record.id) }
        while (records.size > 0) { let _ = records.remove(at: records.size - 1) }
        selectedId = -1; currentFilePath = ""; lastPersistedPayload = ""
        while (let Some(_) <- undoHistory.remove()) {}; while (let Some(_) <- redoHistory.remove()) {}
        clearRememberedRequestsUnlocked()
    }
    private func replaceLoadedDocumentUnlocked(loaded: CjguiRuleSetLoadedFile, path: String, payload: String) {
        for (record in records) { let _ = recordsById.remove(record.id) }
        while (records.size > 0) { let _ = records.remove(at: records.size - 1) }
        for (record in loaded.records) {
            let restored = CjguiMutableRuleSetRecord(record.id, record.label, record.enabled, record.retentionCount, record.excludedType)
            records.add(restored); let _ = recordsById.add(restored.id, restored)
        }
        selectedId = loaded.selectedRecordId
        if (loaded.nextRecordId > nextId) { nextId = loaded.nextRecordId }
        if (let None <- recordForIdUnlocked(selectedId)) { selectedId = if (records.size > 0) { records[0].id } else { -1 } }
        while (let Some(_) <- undoHistory.remove()) {}; while (let Some(_) <- redoHistory.remove()) {}
        currentFilePath = path; lastPersistedPayload = payload; documentGeneration += 1
        clearRememberedRequestsUnlocked()
    }
    private func parseRuleSet(payload: String): ?CjguiRuleSetLoadedFile {
        let lines = payload.split("\n")
        if (lines.size < 4 || lines[0] != "CJGUI_RULE_SET 1") { return None }
        let nextParts = lines[1].split(" "); let selectedParts = lines[2].split(" ")
        if (nextParts.size != 2 || nextParts[0] != "NEXT_ID" || selectedParts.size != 2 || selectedParts[0] != "SELECTED") { return None }
        if (let Some(next) <- Int64.tryParse(nextParts[1])) {
            if (let Some(selected) <- Int64.tryParse(selectedParts[1])) {
                if (next < 1) { return None }
                let parsed = ArrayList<CjguiRuleSetRecord>(); var highest: Int64 = 0; var index: Int64 = 3; var sawEnd = false
                while (index < lines.size) {
                    let line = lines[index]
                    if (line == "END") { sawEnd = true; index += 1; break }
                    if (line.size == 0) { index += 1; continue }
                    let parts = line.split(" ")
                    if (parts.size != 6 || parts[0] != "RECORD") { return None }
                    if (let Some(id) <- Int64.tryParse(parts[1])) {
                        if (let Some(retention) <- Int64.tryParse(parts[3])) {
                            if (parts[2] != "0" && parts[2] != "1") { return None }
                            if (let Some(label) <- decodeHex(parts[4])) {
                                if (let Some(excluded) <- decodeHex(parts[5])) {
                                    if (id < 1 || !validRule(label, retention, excluded) || containsParsedId(parsed, id)) { return None }
                                    parsed.add(CjguiRuleSetRecord(id, label, parts[2] == "1", retention, excluded))
                                    if (id > highest) { highest = id }
                                    index += 1
                                    continue
                                }
                            }
                        }
                    }
                    return None
                }
                if (!sawEnd || next <= highest) { return None }
                while (index < lines.size) { if (lines[index].size != 0) { return None }; index += 1 }
                return Some(CjguiRuleSetLoadedFile(parsed, selected, next))
            }
        }
        return None
    }

    private func recordForHistoryEntry(entry: CjguiRuleSetHistoryEntry, id: Int64): ?CjguiRuleSetRecord {
        for (record in entry.records) { if (record.id == id) { return Some(record) } }
        return None
    }
    private func sameAppliedRecord(current: CjguiMutableRuleSetRecord, target: CjguiRuleSetRecord): Bool {
        return current.id == target.id && current.label == target.label && current.enabled == target.enabled &&
            current.retentionCount == target.retentionCount && current.excludedType == target.excludedType
    }
    private func requestFingerprint(invocation: CjguiSharedOperationActionInvocation): String {
        var fingerprint = "ACTION:${encodeHex(invocation.actionName)}|TARGETS:${invocation.targetResourceIds.size}|"
        for (id in invocation.targetResourceIds) { fingerprint = "${fingerprint}${id}|" }
        fingerprint = "${fingerprint}ARGS:${invocation.arguments.size}|"
        for (argument in invocation.arguments) {
            fingerprint = "${fingerprint}${encodeHex(argument.name)}:${argument.value.valueType}:"
            if (argument.value.valueType == "STRING") { fingerprint = "${fingerprint}${encodeHex(argument.value.stringValue)}" }
            else if (argument.value.valueType == "INTEGER") { fingerprint = "${fingerprint}${argument.value.integerValue}" }
            else if (argument.value.valueType == "BOOLEAN") { fingerprint = "${fingerprint}${argument.value.booleanValue}" }
            else { fingerprint = "${fingerprint}INVALID" }
            fingerprint = "${fingerprint}|"
        }
        return fingerprint
    }
    private func rememberAppliedRequestUnlocked(requestId: String, fingerprint: String, appliedVersion: Int64) {
        let _ = appliedRequests.add(requestId, CjguiRuleSetAppliedRequest(fingerprint, appliedVersion))
        appliedRequestOrder.add(requestId)
        if (appliedRequestOrder.size > CjguiRuleSetEditingDomain.maximumRememberedRequests) {
            let evicted = appliedRequestOrder.remove(at: 0)
            let _ = appliedRequests.remove(evicted)
        }
    }
    private func clearRememberedRequestsUnlocked() {
        appliedRequests.clear(); appliedRequestOrder.clear()
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
}

private func serializeTransferRecord(label: String, enabled: Bool, retentionCount: Int64, excludedType: String): String {
    return "CJGUI_RULE_RECORD/1\nLABEL ${label.size} ${encodeHex(label)}\nENABLED ${if (enabled) { 1 } else { 0 }}\nRETENTION ${retentionCount}\nEXCLUDED ${excludedType.size} ${encodeHex(excludedType)}\nEND"
}

private func parseTransferRecord(payload: String): ?CjguiRuleSetTransferRecord {
    let lines = payload.split("\n")
    if (lines.size != 6 || lines[0] != "CJGUI_RULE_RECORD/1" || lines[5] != "END") { return None }
    let labelParts = lines[1].split(" ")
    let enabledParts = lines[2].split(" ")
    let retentionParts = lines[3].split(" ")
    let excludedParts = lines[4].split(" ")
    if (labelParts.size != 3 || labelParts[0] != "LABEL" || enabledParts.size != 2 ||
        enabledParts[0] != "ENABLED" || retentionParts.size != 2 || retentionParts[0] != "RETENTION" ||
        excludedParts.size != 3 || excludedParts[0] != "EXCLUDED") {
        return None
    }
    if (let Some(labelBytes) <- Int64.tryParse(labelParts[1])) {
        if (let Some(label) <- decodeHex(labelParts[2])) {
            if (label.size != labelBytes) { return None }
            if (let Some(retention) <- Int64.tryParse(retentionParts[1])) {
                if (let Some(excludedBytes) <- Int64.tryParse(excludedParts[1])) {
                    if (let Some(excluded) <- decodeHex(excludedParts[2])) {
                        if (excluded.size != excludedBytes ||
                            (enabledParts[1] != "0" && enabledParts[1] != "1") ||
                            !validTransferRule(label, retention, excluded)) {
                            return None
                        }
                        return Some(CjguiRuleSetTransferRecord(
                            label, enabledParts[1] == "1", retention, excluded))
                    }
                }
            }
        }
    }
    return None
}

private func validTransferRule(label: String, retention: Int64, excluded: String): Bool {
    return label.size > 0 && label.size <= 128 && retention >= 1 && retention <= 90 &&
        excluded.size > 0 && excluded.size <= 128
}

private func containsId(ids: ArrayList<Int64>, id: Int64): Bool {
    for (candidate in ids) { if (candidate == id) { return true } }
    return false
}
private func uniqueIds(ids: ArrayList<Int64>): ArrayList<Int64> {
    let result = ArrayList<Int64>()
    for (id in ids) { if (!containsId(result, id)) { result.add(id) } }
    return result
}
private func containsParsedId(records: ArrayList<CjguiRuleSetRecord>, id: Int64): Bool {
    for (record in records) { if (record.id == id) { return true } }
    return false
}
private func encodeHex(value: String): String {
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let result = StringBuilder()
    for (byte in value) {
        let numeric = Int64(byte)
        result.append(digits[numeric / 16])
        result.append(digits[numeric % 16])
    }
    return result.toString()
}
private func decodeHex(value: String): ?String {
    if (value.size % 2 != 0 || value.size == 0 || value.size > 1024) { return None }
    let source = value.toArray(); let bytes = ArrayList<Byte>(); var index: Int64 = 0
    while (index < source.size) { if (let Some(high) <- hexNibble(source[index])) { if (let Some(low) <- hexNibble(source[index + 1])) { bytes.add(UInt8(high * 16 + low)); index += 2; continue } }; return None }
    try { return Some(String.fromUtf8(bytes.toArray())) } catch (_) { return None }
}
private func hexNibble(value: Byte): ?Int64 {
    if (value >= b'0' && value <= b'9') { return Some(Int64(value) - Int64(b'0')) }
    if (value >= b'A' && value <= b'F') { return Some(Int64(value) - Int64(b'A') + 10) }
    return None
}
