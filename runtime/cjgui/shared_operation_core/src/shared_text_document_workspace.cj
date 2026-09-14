package cjgui_shared_operation_core

import std.collection.*
import std.convert.*
import std.random.*
import std.sync.*

private const CJGUI_TEXT_DOCUMENT_WORKSPACE_MAXIMUM_CHANGES: Int64 = 128

/// Experimental current view selection. It is deliberately not held in a
/// text document: changing focus or a cursor must not rewrite document truth.
public class CjguiTextDocumentSelection {
    public let isAvailable: Bool
    public let documentId: Int64
    public let documentVersion: Int64
    public let start: Int64
    public let end: Int64
    public let reason: String

    public init(
        isAvailable: Bool,
        documentId: Int64,
        documentVersion: Int64,
        start: Int64,
        end: Int64,
        reason: String
    ) {
        this.isAvailable = isAvailable
        this.documentId = documentId
        this.documentVersion = documentVersion
        this.start = start
        this.end = end
        this.reason = reason
    }
}

private class CjguiTextDocumentWorkspaceEntry {
    let document: CjguiTextDocument
    var isOpen: Bool

    init(document: CjguiTextDocument) {
        this.document = document
        this.isOpen = true
    }
}

/// Pure-Cangjie document owner used equally by a normal window and a
/// headless consumer. It presents document metadata to context discovery,
/// keeps view selection separate, and applies every human or external edit to
/// the same `CjguiTextDocument` instance.
public class CjguiTextDocumentWorkspace <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain & CjguiSharedOperationRangeReadDomain & CjguiSharedOperationTargetedContextDomain {
    private static let previewLimitMinimum: Int64 = 128
    private static let previewLimitMaximum: Int64 = 512
    private static let defaultPreviewLimit: Int64 = 512
    private let lock: Mutex
    private let documents: ArrayList<CjguiTextDocumentWorkspaceEntry>
    // A derived owner-local lookup index.  It never stores document content
    // or version truth and documents are not structurally added after init.
    private let documentsById: HashMap<Int64, CjguiTextDocumentWorkspaceEntry>
    // Per-document preview limits are workspace-owned presentation truth.
    // They never duplicate document text or its content version.
    private let previewLimitsByDocumentId: HashMap<Int64, Int64>
    // One revision per preview control. It advances only when that document's
    // preview limit changes, allowing other workspace updates to coexist with
    // an active slider drag.
    private let previewLimitVersionsByDocumentId: HashMap<Int64, Int64>
    private let changes: ArrayList<CjguiSharedOperationChangeEntry>
    private let streamIdentity: String
    private var historyFloorVersion: Int64
    private var contextVersionValue: Int64
    private var selectedDocumentIdValue: Int64
    private var selectionStartValue: Int64
    private var selectionEndValue: Int64
    private var selectionDocumentVersionValue: Int64

    public init(documents: ArrayList<CjguiTextDocument>) {
        if (documents.size == 0) { throw IllegalArgumentException("text_workspace_requires_document") }
        this.lock = Mutex()
        this.documents = ArrayList<CjguiTextDocumentWorkspaceEntry>()
        this.documentsById = HashMap<Int64, CjguiTextDocumentWorkspaceEntry>()
        this.previewLimitsByDocumentId = HashMap<Int64, Int64>()
        this.previewLimitVersionsByDocumentId = HashMap<Int64, Int64>()
        this.changes = ArrayList<CjguiSharedOperationChangeEntry>()
        this.streamIdentity = "text-document-${Random().nextUInt64()}"
        this.historyFloorVersion = 0
        this.contextVersionValue = 0
        this.selectedDocumentIdValue = -1
        this.selectionStartValue = 0
        this.selectionEndValue = 0
        this.selectionDocumentVersionValue = -1
        var firstId: Int64 = -1
        var firstVersion: Int64 = -1
        for (document in documents) {
            var duplicate = false
            for (existing in this.documents) {
                if (existing.document.documentId() == document.documentId()) { duplicate = true }
            }
            if (duplicate) {
                throw IllegalArgumentException("duplicate_text_document_id")
            }
            let entry = CjguiTextDocumentWorkspaceEntry(document)
            this.documents.add(entry)
            let _ = this.documentsById.add(document.documentId(), entry)
            let _ = this.previewLimitsByDocumentId.add(document.documentId(), CjguiTextDocumentWorkspace.defaultPreviewLimit)
            let _ = this.previewLimitVersionsByDocumentId.add(document.documentId(), 0)
            if (firstId < 0) {
                firstId = document.documentId()
                firstVersion = document.version()
            }
        }
        this.selectedDocumentIdValue = firstId
        this.selectionStartValue = 0
        this.selectionEndValue = 0
        this.selectionDocumentVersionValue = firstVersion
    }

    public func resourceType(): String { return "text_document" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return synchronized(lock) { contextSnapshotUnlocked() }
    }

    /// Explicit targets use the existing workspace owner and lock, but only
    /// materialize the named open documents.  `None` preserves the transport
    /// distinction between an unknown/closed target and an empty projection.
    public func contextSnapshotForExternalTargets(
        targets: ArrayList<Int64>
    ): ?CjguiSharedOperationContextSnapshot {
        return synchronized(lock) { contextSnapshotForTargetsUnlocked(targets) }
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            descriptor("SELECT_DOCUMENT", "选择文档", ArrayList<CjguiSharedOperationParameterDescriptor>()),
            descriptor("INSERT_TEXT", "插入文本", ArrayList<CjguiSharedOperationParameterDescriptor>([
                parameter("offset", "INTEGER"), parameter("text", "STRING")
            ])),
            descriptor("DELETE_RANGE", "删除片段", ArrayList<CjguiSharedOperationParameterDescriptor>([
                parameter("start", "INTEGER"), parameter("end", "INTEGER")
            ])),
            descriptor("REPLACE_RANGE", "替换片段", ArrayList<CjguiSharedOperationParameterDescriptor>([
                parameter("start", "INTEGER"), parameter("end", "INTEGER"), parameter("text", "STRING")
            ])),
            descriptor("REPLACE_RANGES", "原版本多段替换", ArrayList<CjguiSharedOperationParameterDescriptor>([
                parameter("replacements", "TEXT_REPLACEMENTS")
            ])),
            descriptor("UNDO", "撤销文档修改", ArrayList<CjguiSharedOperationParameterDescriptor>()),
            descriptor("REDO", "重做文档修改", ArrayList<CjguiSharedOperationParameterDescriptor>())
            , descriptor("SET_PREVIEW_LIMIT", "设置预览字节上限", ArrayList<CjguiSharedOperationParameterDescriptor>([
                parameter("value", "INTEGER")
            ]))
        ])
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, false) }
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return synchronized(lock) { executeUnlocked(invocation, true) }
    }

    public func selection(): CjguiTextDocumentSelection {
        return synchronized(lock) { selectionUnlocked() }
    }

    public func previewLimitForDocument(documentId: Int64): Int64 {
        return synchronized(lock) {
            if (let Some(value) <- previewLimitsByDocumentId.get(documentId)) { return value }
            return CjguiTextDocumentWorkspace.defaultPreviewLimit
        }
    }

    public func previewLimitVersionForDocument(documentId: Int64): Int64 {
        return synchronized(lock) {
            if (let Some(value) <- previewLimitVersionsByDocumentId.get(documentId)) { return value }
            return 0
        }
    }

    public func setPreviewLimitFromHuman(documentId: Int64, value: Int64): CjguiSharedOperationActionResult {
        return executeFromHuman(CjguiSharedOperationActionInvocation(
            "SET_PREVIEW_LIMIT", contextSnapshot().version, ArrayList<Int64>([documentId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.integer(value))
            ])
        ))
    }

    /// Direct in-process UI consumers may render an open document from this
    /// snapshot. External consumers must use the separately bounded,
    /// version-checked range-read protocol instead.
    public func documentSnapshot(documentId: Int64): ?CjguiTextDocumentSnapshot {
        return synchronized(lock) {
            if (let Some(entry) <- openEntryForIdUnlocked(documentId)) {
                return Some(entry.document.snapshot())
            }
            return None
        }
    }

    public func setSelectionFromHuman(documentId: Int64, range: CjguiTextDocumentRange): CjguiTextDocumentSelection {
        return synchronized(lock) { setSelectionUtf8Unlocked(documentId, range) }
    }

    /// AppKit reports `NSTextRange` in UTF-16 code units. Convert it exactly
    /// once at the UI/document boundary; the workspace and external protocol
    /// keep UTF-8 byte positions exclusively.
    public func setSelectionFromNativeUtf16(
        documentId: Int64,
        startUtf16: Int64,
        endUtf16: Int64
    ): CjguiTextDocumentSelection {
        return synchronized(lock) {
            if (let Some(entry) <- openEntryForIdUnlocked(documentId)) {
                if (let Some(range) <- entry.document.rangeFromUtf16(startUtf16, endUtf16)) {
                    return setSelectionUtf8Unlocked(documentId, range)
                }
                return CjguiTextDocumentSelection(false, documentId, entry.document.version(), 0, 0, "invalid_text_boundary")
            }
            return unavailableSelectionUnlocked(documentId)
        }
    }

    public func selectDocumentFromHuman(documentId: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { selectDocumentUnlocked(documentId) }
    }

    public func closeDocumentFromHuman(documentId: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (let Some(entry) <- entryForIdUnlocked(documentId)) {
                if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
                entry.isOpen = false
                if (selectedDocumentIdValue == documentId) {
                    selectFirstOpenUnlocked()
                }
                appendContextChangeUnlocked(documentId, "document_closed")
                return acceptedUnlocked("document_closed")
            }
            return rejectedUnlocked(false, "unknown_document")
        }
    }

    public func replaceRangeFromHuman(
        documentId: Int64,
        range: CjguiTextDocumentRange,
        text: String
    ): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            editUnlocked(documentId, "REPLACE_RANGE", range, text, 0, false)
        }
    }

    /// Accepts a committed native text projection through the document's
    /// cluster-safe delta owner. Marked-text updates never reach this method;
    /// one committed projection becomes at most one human undo entry.
    public func replaceProjectionTextFromHuman(
        documentId: Int64,
        text: String
    ): CjguiSharedOperationActionResult {
        return synchronized(lock) {
            if (let Some(entry) <- entryForIdUnlocked(documentId)) {
                if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
                let result = entry.document.replaceProjectionTextFromHuman(text)
                if (result.applied && result.versionAfter > result.versionBefore) {
                    if (selectedDocumentIdValue == documentId) {
                        selectionStartValue = result.range.start
                        selectionEndValue = result.range.end
                        selectionDocumentVersionValue = result.versionAfter
                    }
                    appendContextChangeUnlocked(documentId, "document_edited")
                }
                return documentResultUnlocked(result)
            }
            return rejectedUnlocked(false, "unknown_document")
        }
    }

    public func undoDocumentFromHuman(documentId: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { historyUnlocked(documentId, false, true) }
    }

    public func redoDocumentFromHuman(documentId: Int64): CjguiSharedOperationActionResult {
        return synchronized(lock) { historyUnlocked(documentId, false, false) }
    }

    public func readRangeFromExternal(
        resourceId: Int64,
        start: Int64,
        end: Int64,
        expectedVersion: Int64
    ): CjguiSharedOperationRangeRead {
        return synchronized(lock) {
            if (let Some(entry) <- entryForIdUnlocked(resourceId)) {
                if (!entry.isOpen) {
                    return CjguiSharedOperationRangeRead(false, false, resourceId, entry.document.version(), 0, 0, "", "document_closed")
                }
                let read = entry.document.readRangeFromExternal(CjguiTextDocumentRange(start, end), expectedVersion)
                return CjguiSharedOperationRangeRead(
                    read.isAvailable,
                    read.isVersionConflict,
                    resourceId,
                    read.version,
                    read.range.start,
                    read.range.end,
                    read.content,
                    read.reason
                )
            }
            return CjguiSharedOperationRangeRead(false, false, resourceId, 0, 0, 0, "", "unknown_document")
        }
    }

    public func changesSince(
        sinceVersion: Int64,
        resourceFilter: ArrayList<Int64>,
        expectedStreamIdentity: String
    ): CjguiSharedOperationChanges {
        return synchronized(lock) {
            if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) ||
                sinceVersion < 0 || sinceVersion > contextVersionValue || sinceVersion < historyFloorVersion) {
                return CjguiSharedOperationChanges(sinceVersion, contextVersionValue, streamIdentity, true,
                    ArrayList<CjguiSharedOperationChangeEntry>())
            }
            let result = ArrayList<CjguiSharedOperationChangeEntry>()
            for (change in changes) {
                if (change.version > sinceVersion && (resourceFilter.size == 0 || containsWorkspaceId(resourceFilter, change.resourceId))) {
                    result.add(change)
                }
            }
            return CjguiSharedOperationChanges(sinceVersion, contextVersionValue, streamIdentity, false, result)
        }
    }

    private func executeUnlocked(invocation: CjguiSharedOperationActionInvocation, isExternal: Bool): CjguiSharedOperationActionResult {
        if (invocation.actionName == "SELECT_DOCUMENT") {
            if (invocation.targetResourceIds.size != 1 || invocation.arguments.size != 0) { return rejectedUnlocked(false, "invalid_parameters") }
            return selectDocumentUnlocked(invocation.targetResourceIds[0])
        }
        if (invocation.targetResourceIds.size != 1) { return rejectedUnlocked(false, "invalid_target") }
        let documentId = invocation.targetResourceIds[0]
        if (invocation.actionName == "SET_PREVIEW_LIMIT") {
            return setPreviewLimitUnlocked(documentId, invocation, isExternal)
        }
        if (invocation.actionName == "INSERT_TEXT") {
            if (let Some(offset) <- integerArgumentUnlocked(invocation, "offset")) {
                if (let Some(text) <- stringArgumentUnlocked(invocation, "text")) {
                    return editUnlocked(documentId, "INSERT_TEXT", CjguiTextDocumentRange(offset, offset), text, invocation.expectedVersion, isExternal)
                }
            }
            return rejectedUnlocked(false, "invalid_parameters")
        }
        if (invocation.actionName == "DELETE_RANGE") {
            if (let Some(start) <- integerArgumentUnlocked(invocation, "start")) {
                if (let Some(end) <- integerArgumentUnlocked(invocation, "end")) {
                    return editUnlocked(documentId, "DELETE_RANGE", CjguiTextDocumentRange(start, end), "", invocation.expectedVersion, isExternal)
                }
            }
            return rejectedUnlocked(false, "invalid_parameters")
        }
        if (invocation.actionName == "REPLACE_RANGE") {
            if (let Some(start) <- integerArgumentUnlocked(invocation, "start")) {
                if (let Some(end) <- integerArgumentUnlocked(invocation, "end")) {
                    if (let Some(text) <- stringArgumentUnlocked(invocation, "text")) {
                        return editUnlocked(documentId, "REPLACE_RANGE", CjguiTextDocumentRange(start, end), text, invocation.expectedVersion, isExternal)
                    }
                }
            }
            return rejectedUnlocked(false, "invalid_parameters")
        }
        if (invocation.actionName == "REPLACE_RANGES") {
            if (let Some(replacements) <- textReplacementsArgumentUnlocked(invocation, "replacements")) {
                return batchEditUnlocked(documentId, replacements, invocation.expectedVersion, isExternal)
            }
            return rejectedUnlocked(false, "invalid_parameters")
        }
        if (invocation.actionName == "UNDO" && invocation.arguments.size == 0) { return historyUnlocked(documentId, isExternal, true) }
        if (invocation.actionName == "REDO" && invocation.arguments.size == 0) { return historyUnlocked(documentId, isExternal, false) }
        return rejectedUnlocked(false, "unknown_action")
    }

    private func setPreviewLimitUnlocked(
        documentId: Int64,
        invocation: CjguiSharedOperationActionInvocation,
        isExternal: Bool
    ): CjguiSharedOperationActionResult {
        if (let None <- openEntryForIdUnlocked(documentId)) { return rejectedUnlocked(false, "unknown_document") }
        if (isExternal && invocation.expectedVersion != contextVersionValue) {
            return rejectedUnlocked(true, "version_conflict")
        }
        if (let Some(value) <- integerArgumentUnlocked(invocation, "value")) {
            if (value < CjguiTextDocumentWorkspace.previewLimitMinimum ||
                value > CjguiTextDocumentWorkspace.previewLimitMaximum) {
                return rejectedUnlocked(false, "invalid_preview_limit")
            }
            let current = if (let Some(existing) <- previewLimitsByDocumentId.get(documentId)) {
                existing
            } else {
                CjguiTextDocumentWorkspace.defaultPreviewLimit
            }
            if (current == value) { return acceptedUnlocked("already_at_target") }
            let versionBefore = contextVersionValue
            let _ = previewLimitsByDocumentId.add(documentId, value)
            let previousControlVersion = if (let Some(existing) <- previewLimitVersionsByDocumentId.get(documentId)) {
                existing
            } else {
                0
            }
            let _ = previewLimitVersionsByDocumentId.add(documentId, previousControlVersion + 1)
            appendContextChangeUnlocked(documentId, "preview_limit_changed")
            return CjguiSharedOperationActionResult(true, false, versionBefore, contextVersionValue,
                "preview_limit_set")
        }
        return rejectedUnlocked(false, "invalid_parameters")
    }

    private func editUnlocked(
        documentId: Int64,
        actionName: String,
        range: CjguiTextDocumentRange,
        text: String,
        expectedVersion: Int64,
        isExternal: Bool
    ): CjguiSharedOperationActionResult {
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
            let result = if (isExternal) {
                entry.document.replaceRangeFromExternal(range, text, expectedVersion)
            } else {
                entry.document.replaceRangeFromHuman(range, text)
            }
            if (result.applied && result.versionAfter > result.versionBefore) {
                if (selectedDocumentIdValue == documentId) {
                    selectionStartValue = result.range.start
                    selectionEndValue = result.range.end
                    selectionDocumentVersionValue = result.versionAfter
                }
                let _ = actionName
                appendContextChangeUnlocked(documentId, "document_edited")
            }
            return documentResultUnlocked(result)
        }
        return rejectedUnlocked(false, "unknown_document")
    }

    private func historyUnlocked(documentId: Int64, isExternal: Bool, undo: Bool): CjguiSharedOperationActionResult {
        if (isExternal) { return rejectedUnlocked(false, "human_history_only") }
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
            let result = if (undo) { entry.document.undoFromHuman() } else { entry.document.redoFromHuman() }
            if (result.applied && result.versionAfter > result.versionBefore) {
                if (selectedDocumentIdValue == documentId) {
                    selectionStartValue = result.range.start
                    selectionEndValue = result.range.end
                    selectionDocumentVersionValue = result.versionAfter
                }
                appendContextChangeUnlocked(documentId, if (undo) { "undo" } else { "redo" })
            }
            return documentResultUnlocked(result)
        }
        return rejectedUnlocked(false, "unknown_document")
    }

    private func batchEditUnlocked(
        documentId: Int64,
        replacements: ArrayList<CjguiTextDocumentReplacement>,
        expectedVersion: Int64,
        isExternal: Bool
    ): CjguiSharedOperationActionResult {
        if (!isExternal) { return rejectedUnlocked(false, "external_batch_only") }
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
            let result = entry.document.replaceRangesFromExternal(replacements, expectedVersion)
            if (result.applied && result.versionAfter > result.versionBefore) {
                if (selectedDocumentIdValue == documentId && result.ranges.size > 0) {
                    let finalRange = result.ranges[result.ranges.size - 1]
                    selectionStartValue = finalRange.start
                    selectionEndValue = finalRange.end
                    selectionDocumentVersionValue = result.versionAfter
                }
                appendContextChangeUnlocked(documentId, "document_edited")
            }
            return CjguiSharedOperationActionResult(result.applied, result.isVersionConflict,
                result.versionBefore, result.versionAfter, result.reason)
        }
        return rejectedUnlocked(false, "unknown_document")
    }

    private func selectDocumentUnlocked(documentId: Int64): CjguiSharedOperationActionResult {
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (!entry.isOpen) { return rejectedUnlocked(false, "document_closed") }
            selectedDocumentIdValue = documentId
            selectionStartValue = 0
            selectionEndValue = 0
            selectionDocumentVersionValue = entry.document.version()
            appendContextChangeUnlocked(documentId, "selection")
            return acceptedUnlocked("selected")
        }
        return rejectedUnlocked(false, "unknown_document")
    }

    private func selectFirstOpenUnlocked() {
        selectedDocumentIdValue = -1
        selectionStartValue = 0
        selectionEndValue = 0
        selectionDocumentVersionValue = -1
        for (entry in documents) {
            if (entry.isOpen) {
                selectedDocumentIdValue = entry.document.documentId()
                selectionDocumentVersionValue = entry.document.version()
                return
            }
        }
    }

    private func contextSnapshotUnlocked(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        for (entry in documents) {
            if (!entry.isOpen) { continue }
            let snapshot = entry.document.snapshot()
            let fields = ArrayList<CjguiSharedOperationField>([
                CjguiSharedOperationField("documentVersion", CjguiSharedOperationValue.integer(snapshot.version)),
                CjguiSharedOperationField("byteLength", CjguiSharedOperationValue.integer(snapshot.content.size)),
                CjguiSharedOperationField("previewLimit", CjguiSharedOperationValue.integer(previewLimitForDocumentUnlocked(snapshot.documentId))),
                CjguiSharedOperationField("positionUnit", CjguiSharedOperationValue.string("UTF8_BYTE")),
                CjguiSharedOperationField("isSelected", CjguiSharedOperationValue.boolean(snapshot.documentId == selectedDocumentIdValue))
            ])
            if (snapshot.documentId == selectedDocumentIdValue) {
                fields.add(CjguiSharedOperationField("selectionStart", CjguiSharedOperationValue.integer(selectionStartValue)))
                fields.add(CjguiSharedOperationField("selectionEnd", CjguiSharedOperationValue.integer(selectionEndValue)))
                fields.add(CjguiSharedOperationField("selectionDocumentVersion", CjguiSharedOperationValue.integer(selectionDocumentVersionValue)))
            }
            resources.add(CjguiSharedOperationResource(snapshot.documentId, snapshot.title, fields))
        }
        return CjguiSharedOperationContextSnapshot(
            contextVersionValue, "共享文档", resourceType(), resources,
            streamIdentity: streamIdentity
        )
    }

    private func contextSnapshotForTargetsUnlocked(
        targets: ArrayList<Int64>
    ): ?CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        for (documentId in targets) {
            if (let Some(entry) <- openEntryForIdUnlocked(documentId)) {
                let snapshot = entry.document.snapshot()
                let fields = ArrayList<CjguiSharedOperationField>([
                    CjguiSharedOperationField("documentVersion", CjguiSharedOperationValue.integer(snapshot.version)),
                    CjguiSharedOperationField("byteLength", CjguiSharedOperationValue.integer(snapshot.content.size)),
                    CjguiSharedOperationField("previewLimit", CjguiSharedOperationValue.integer(previewLimitForDocumentUnlocked(snapshot.documentId))),
                    CjguiSharedOperationField("positionUnit", CjguiSharedOperationValue.string("UTF8_BYTE")),
                    CjguiSharedOperationField("isSelected", CjguiSharedOperationValue.boolean(snapshot.documentId == selectedDocumentIdValue))
                ])
                if (snapshot.documentId == selectedDocumentIdValue) {
                    fields.add(CjguiSharedOperationField("selectionStart", CjguiSharedOperationValue.integer(selectionStartValue)))
                    fields.add(CjguiSharedOperationField("selectionEnd", CjguiSharedOperationValue.integer(selectionEndValue)))
                    fields.add(CjguiSharedOperationField("selectionDocumentVersion", CjguiSharedOperationValue.integer(selectionDocumentVersionValue)))
                }
                resources.add(CjguiSharedOperationResource(snapshot.documentId, snapshot.title, fields))
            } else {
                return None
            }
        }
        return Some(CjguiSharedOperationContextSnapshot(
            contextVersionValue, "共享文档", resourceType(), resources,
            streamIdentity: streamIdentity
        ))
    }

    private func selectionUnlocked(): CjguiTextDocumentSelection {
        if (let Some(entry) <- openEntryForIdUnlocked(selectedDocumentIdValue)) {
            return CjguiTextDocumentSelection(true, selectedDocumentIdValue, selectionDocumentVersionValue,
                selectionStartValue, selectionEndValue, "available")
        }
        return CjguiTextDocumentSelection(false, -1, -1, 0, 0, "no_open_document")
    }

    private func previewLimitForDocumentUnlocked(documentId: Int64): Int64 {
        if (let Some(value) <- previewLimitsByDocumentId.get(documentId)) { return value }
        return CjguiTextDocumentWorkspace.defaultPreviewLimit
    }

    private func setSelectionUtf8Unlocked(documentId: Int64, range: CjguiTextDocumentRange): CjguiTextDocumentSelection {
        if (let Some(entry) <- openEntryForIdUnlocked(documentId)) {
            if (entry.document.acceptsRange(range)) {
                let version = entry.document.version()
                selectedDocumentIdValue = documentId
                selectionStartValue = range.start
                selectionEndValue = range.end
                selectionDocumentVersionValue = version
                appendContextChangeUnlocked(documentId, "selection")
                return selectionUnlocked()
            }
            return CjguiTextDocumentSelection(false, documentId, entry.document.version(), 0, 0, "invalid_text_boundary")
        }
        return unavailableSelectionUnlocked(documentId)
    }

    private func unavailableSelectionUnlocked(documentId: Int64): CjguiTextDocumentSelection {
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (!entry.isOpen) { return CjguiTextDocumentSelection(false, documentId, entry.document.version(), 0, 0, "document_closed") }
        }
        return CjguiTextDocumentSelection(false, documentId, -1, 0, 0, "unknown_document")
    }

    private func appendContextChangeUnlocked(resourceId: Int64, kind: String) {
        contextVersionValue += 1
        changes.add(CjguiSharedOperationChangeEntry(contextVersionValue, resourceId, kind))
        if (changes.size > CJGUI_TEXT_DOCUMENT_WORKSPACE_MAXIMUM_CHANGES) {
            let removed = changes.remove(at: 0)
            historyFloorVersion = removed.version
        }
    }

    private func documentResultUnlocked(result: CjguiTextDocumentEditResult): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(result.applied, result.isVersionConflict,
            result.versionBefore, result.versionAfter, result.reason)
    }

    private func acceptedUnlocked(reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(true, false, contextVersionValue, contextVersionValue, reason)
    }

    private func rejectedUnlocked(conflict: Bool, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, contextVersionValue, contextVersionValue, reason)
    }

    private func descriptor(
        name: String,
        displayName: String,
        parameters: ArrayList<CjguiSharedOperationParameterDescriptor>
    ): CjguiSharedOperationActionDescriptor {
        return CjguiSharedOperationActionDescriptor(name, displayName, parameters, 1, 1)
    }

    private func parameter(name: String, valueType: String): CjguiSharedOperationParameterDescriptor {
        return CjguiSharedOperationParameterDescriptor(name, valueType, true)
    }

    private func integerArgumentUnlocked(invocation: CjguiSharedOperationActionInvocation, name: String): ?Int64 {
        var result: ?Int64 = None
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "INTEGER") {
                if (let Some(_) <- result) { return None }
                result = Some(argument.value.integerValue)
            }
        }
        return result
    }

    private func stringArgumentUnlocked(invocation: CjguiSharedOperationActionInvocation, name: String): ?String {
        var result: ?String = None
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "STRING") {
                if (let Some(_) <- result) { return None }
                result = Some(argument.value.stringValue)
            }
        }
        return result
    }

    private func textReplacementsArgumentUnlocked(
        invocation: CjguiSharedOperationActionInvocation,
        name: String
    ): ?ArrayList<CjguiTextDocumentReplacement> {
        var encoded: ?String = None
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "TEXT_REPLACEMENTS") {
                if (let Some(_) <- encoded) { return None }
                encoded = Some(argument.value.stringValue)
            }
        }
        if (let Some(value) <- encoded) { return parseTextReplacements(value) }
        return None
    }

    private func parseTextReplacements(value: String): ?ArrayList<CjguiTextDocumentReplacement> {
        let lines = value.split("\n")
        if (lines.size < 2 || lines[0] != "CJGUI_TEXT_REPLACEMENTS/1" ||
            lines.size - 1 > 64) {
            return None
        }
        let replacements = ArrayList<CjguiTextDocumentReplacement>()
        var index: Int64 = 1
        while (index < lines.size) {
            let fields = lines[index].split(" ")
            if (fields.size != 4) { return None }
            if (let Some(start) <- Int64.tryParse(fields[0])) {
                if (let Some(end) <- Int64.tryParse(fields[1])) {
                    if (let Some(byteCount) <- Int64.tryParse(fields[2])) {
                        if (let Some(text) <- decodeWorkspaceUtf8Hex(fields[3], byteCount)) {
                            replacements.add(CjguiTextDocumentReplacement(CjguiTextDocumentRange(start, end), text))
                            index += 1
                            continue
                        }
                    }
                }
            }
            return None
        }
        return Some(replacements)
    }

    private func entryForIdUnlocked(documentId: Int64): ?CjguiTextDocumentWorkspaceEntry {
        return documentsById.get(documentId)
    }

    private func openEntryForIdUnlocked(documentId: Int64): ?CjguiTextDocumentWorkspaceEntry {
        if (let Some(entry) <- entryForIdUnlocked(documentId)) {
            if (entry.isOpen) { return Some(entry) }
        }
        return None
    }
}

private func containsWorkspaceId(values: ArrayList<Int64>, value: Int64): Bool {
    for (candidate in values) { if (candidate == value) { return true } }
    return false
}

/// The outer transport has already decoded its typed argument. The batch
/// grammar keeps each replacement's arbitrary UTF-8 text unambiguous without
/// interpreting it as a command or splitting it on a user-supplied newline.
private func decodeWorkspaceUtf8Hex(encoded: String, byteCount: Int64): ?String {
    if (byteCount == 0 && encoded == "-") {
        return Some("")
    }
    if (byteCount < 0 || byteCount > 64 * 1024 || encoded.size != byteCount * 2) {
        return None
    }
    let encodedBytes = encoded.toArray()
    let bytes = ArrayList<Byte>()
    var index = 0
    while (index < encodedBytes.size) {
        if (let Some(high) <- workspaceHexValue(encodedBytes[index])) {
            if (let Some(low) <- workspaceHexValue(encodedBytes[index + 1])) {
                bytes.add(UInt8(high * 16 + low))
            } else {
                return None
            }
        } else {
            return None
        }
        index += 2
    }
    try {
        return Some(String.fromUtf8(bytes.toArray()))
    } catch (_) {
        return None
    }
}

private func workspaceHexValue(value: Byte): ?Int64 {
    if (value >= b'0' && value <= b'9') { return Some(Int64(value) - Int64(b'0')) }
    if (value >= b'A' && value <= b'F') { return Some(Int64(value) - Int64(b'A') + 10) }
    if (value >= b'a' && value <= b'f') { return Some(Int64(value) - Int64(b'a') + 10) }
    return None
}
