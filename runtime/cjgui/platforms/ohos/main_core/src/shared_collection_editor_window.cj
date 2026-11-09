package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

/// Bounded result from a normal collection/detail window pump.
public class CjguiSharedCollectionEditorWindowPumpResult {
    public let isOpen: Bool
    public let didApplyHumanAction: Bool
    public let nativeStatus: Int32
    public init(isOpen: Bool, didApplyHumanAction: Bool, nativeStatus: Int32) {
        this.isOpen = isOpen; this.didApplyHumanAction = didApplyHumanAction; this.nativeStatus = nativeStatus
    }
}

/// Reusable macOS collection/detail projection. The renderer receives only a
/// bounded page of titles and reports an index intent; the Cangjie domain
/// resolves that index to its stable record ID before executing its ordinary
/// human action path. No row slot is application identity.
public class CjguiSharedCollectionEditorWindow {
    private let domain: CjguiSharedCollectionEditorDomain
    private var sessionToken: UInt64
    private var isWindowOpen: Bool
    private var lastNativeStatus: Int32
    private var viewportStart: Int64
    private var renderedVisibleItems: ArrayList<CjguiSharedCollectionItemProjection>
    private var renderedSelectedItemId: Int64
    private var renderedDraftVersion: Int64
    private var renderedBaseAppliedVersion: Int64
    // A view query, deliberately separate from the shared domain state.
    private var filterText: String

    public init(domain: CjguiSharedCollectionEditorDomain) {
        this.domain = domain
        this.sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        this.isWindowOpen = false
        this.lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        this.viewportStart = 0
        this.renderedVisibleItems = ArrayList<CjguiSharedCollectionItemProjection>()
        this.renderedSelectedItemId = -1
        this.renderedDraftVersion = -1
        this.renderedBaseAppliedVersion = -1
        this.filterText = ""
    }

    public func start(): Bool {
        if (isWindowOpen) { return true }
        let binding = domain.formBinding()
        if (binding.fieldCount() <= 0 || binding.fieldCount() > 8) { return false }
        let created = internalRendererCreate(CjguiInternalRendererConfig(
            windowWidth: 980u32, windowHeight: 620u32,
            clearColorRed: 0.94, clearColorGreen: 0.95, clearColorBlue: 0.97, clearColorAlpha: 1.0
        ))
        if (created.status != CJGUI_INTERNAL_RENDERER_OK || created.token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            lastNativeStatus = created.status; return false
        }
        sessionToken = created.token
        isWindowOpen = true
        if (!syncProjection()) { discardSession(); return false }
        let frame = internalRendererPresentClear(sessionToken, CjguiInternalRendererClearColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0))
        if (frame.status != CJGUI_INTERNAL_RENDERER_OK) { lastNativeStatus = frame.status; discardSession(); return false }
        return true
    }

    public func pump(timeoutMs: UInt32): CjguiSharedCollectionEditorWindowPumpResult {
        if (!isWindowOpen) { return CjguiSharedCollectionEditorWindowPumpResult(false, false, lastNativeStatus) }
        let event = internalRendererPumpEvent(sessionToken, timeoutMs)
        lastNativeStatus = event.status
        if (event.status != CJGUI_INTERNAL_RENDERER_OK || event.eventKind == 1u32) {
            discardSession(); return CjguiSharedCollectionEditorWindowPumpResult(false, false, lastNativeStatus)
        }
        var didApply = false
        if (event.eventKind == 12u32) {
            if (Int64(event.recordIndex) < renderedVisibleItems.size) { didApply = domain.selectCollectionItemFromHuman(renderedVisibleItems[Int64(event.recordIndex)].resourceId).applied }
        } else if (event.eventKind == 13u32) {
            if (viewportStart >= maximumVisibleRecords()) { viewportStart -= maximumVisibleRecords() } else { viewportStart = 0 }
        } else if (event.eventKind == 14u32) {
            let count = filteredItems(domain.collectionSnapshot()).size
            if (viewportStart + maximumVisibleRecords() < count) { viewportStart += maximumVisibleRecords() }
        } else if (event.eventKind == 15u32) {
            didApply = domain.createCollectionItemFromHuman().applied
        } else if (event.eventKind == 16u32) {
            didApply = domain.deleteSelectedCollectionItemFromHuman().applied
        } else if (event.eventKind == 17u32) {
            didApply = domain.undoFromHuman().applied
        } else if (event.eventKind == 18u32) {
            didApply = domain.redoFromHuman().applied
        } else if (event.eventKind == 19u32) {
            didApply = domain.saveFromHuman().applied
        } else if (event.eventKind == 20u32) {
            didApply = domain.copySelectedCollectionItemFromHuman().applied
        } else if (event.eventKind == 21u32) {
            didApply = domain.newUntitledFromHuman().applied
        } else if (event.eventKind == 22u32) {
            didApply = domain.openFromHuman(internalRendererFormEventText(sessionToken)).applied
        } else if (event.eventKind == 23u32) {
            didApply = domain.saveAsFromHuman(internalRendererFormEventText(sessionToken)).applied
        } else if (event.eventKind == 24u32) {
            let decision = domain.requestCloseFromHuman()
            didApply = decision.applied
            if (decision.applied) {
                close()
                return CjguiSharedCollectionEditorWindowPumpResult(false, true, lastNativeStatus)
            }
        } else if (event.eventKind == 25u32) {
            didApply = domain.discardUnsavedContentFromHuman().applied
        } else if (event.eventKind == 26u32) {
            filterText = internalRendererFormEventText(sessionToken)
            viewportStart = 0
        } else {
            didApply = applyFormEvent(event)
        }
        if (!syncProjection()) { discardSession(); return CjguiSharedCollectionEditorWindowPumpResult(false, didApply, lastNativeStatus) }
        return CjguiSharedCollectionEditorWindowPumpResult(true, didApply, lastNativeStatus)
    }

    public func close() {
        if (isWindowOpen) { let _ = internalRendererRequestClose(sessionToken) }
        discardSession()
    }
    public func isOpen(): Bool { return isWindowOpen }
    public func nativeStatus(): Int32 { return lastNativeStatus }

    private func applyFormEvent(event: InternalRendererPumpResult): Bool {
        let binding = domain.formBinding()
        if (event.recordIndex < UInt32(binding.fieldCount())) {
            let descriptor = binding.fieldAtControlIndex(Int64(event.recordIndex))
            if (event.eventKind == 6u32 || event.eventKind == 7u32) {
                if (renderedSelectedItemId < 0) { return false }
                return domain.editTextForCollectionItemFromHuman(renderedSelectedItemId, descriptor.resourceId, internalRendererFormEventText(sessionToken), Int64(event.selectionStart), Int64(event.selectionEnd)).applied
            }
            if (event.eventKind == 8u32) {
                if (renderedSelectedItemId < 0) { return false }
                return domain.editBooleanForCollectionItemFromHuman(renderedSelectedItemId, descriptor.resourceId, internalRendererFormEventText(sessionToken) == "true").applied
            }
        }
        if (event.eventKind == 9u32) {
            if (renderedSelectedItemId < 0) { return false }
            return domain.applyDraftForCollectionItemFromHuman(renderedSelectedItemId, renderedDraftVersion, renderedBaseAppliedVersion).applied
        }
        if (event.eventKind == 10u32) {
            if (renderedSelectedItemId < 0) { return false }
            return domain.cancelDraftForCollectionItemFromHuman(renderedSelectedItemId, renderedDraftVersion, renderedBaseAppliedVersion).applied
        }
        // Event 11 means native capacity was reached. Its visible retry
        // message remains local to the renderer; no domain edit is invented.
        return false
    }

    private func syncProjection(): Bool {
        let collection = domain.collectionSnapshot()
        let filtered = filteredItems(collection)
        clampViewport(filtered.size)
        let visible = visibleItems(filtered)
        let binding = domain.formBinding()
        let form = domain.formSnapshot()
        renderedVisibleItems = ArrayList<CjguiSharedCollectionItemProjection>(visible)
        renderedSelectedItemId = collection.selectedResourceId
        renderedDraftVersion = form.draftVersion
        renderedBaseAppliedVersion = form.baseAppliedConfigVersion
        lastNativeStatus = internalRendererConfigureSharedCollectionForm(
            sessionToken, UInt32(binding.fieldCount()), UInt32(visible.size)
        )
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
        lastNativeStatus = internalRendererSetSharedCollectionFilter(sessionToken, filterText)
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
        var row: Int64 = 0
        while (row < visible.size) {
            let item = visible[row]
            lastNativeStatus = internalRendererSetSharedCollectionRow(
                sessionToken, UInt32(row), item.title, item.isSelected,
                UInt32(viewportStart), UInt32(filtered.size)
            )
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
            row += 1
        }
        var field: Int64 = 0
        while (field < binding.fieldCount()) {
            let descriptor = binding.fieldAtControlIndex(field)
            let projection = form.fieldForResourceId(descriptor.resourceId)
            lastNativeStatus = internalRendererSetSharedFormField(
                sessionToken, UInt32(field), descriptor.label, projection.draftText,
                projection.validationError, editorKindCode(descriptor.editorKind), projection.isFocused,
                nonnegativeUInt32(projection.selectionStart), nonnegativeUInt32(projection.selectionEnd)
            )
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
            field += 1
        }
        lastNativeStatus = internalRendererSetSharedFormStatus(
            sessionToken,
            "记录 ${filtered.size}/${collection.allItems().size} 条 · 已应用 v${form.appliedConfigVersion} · 草稿 v${form.draftVersion} · ${form.statusMessage}"
        )
        return lastNativeStatus == CJGUI_INTERNAL_RENDERER_OK
    }

    private func filteredItems(snapshot: CjguiSharedCollectionSnapshot): ArrayList<CjguiSharedCollectionItemProjection> {
        let result = ArrayList<CjguiSharedCollectionItemProjection>()
        for (item in snapshot.allItems()) {
            if (filterText == "" || item.title.contains(filterText)) { result.add(item) }
        }
        return result
    }

    private func visibleItems(filtered: ArrayList<CjguiSharedCollectionItemProjection>): ArrayList<CjguiSharedCollectionItemProjection> {
        clampViewport(filtered.size)
        let result = ArrayList<CjguiSharedCollectionItemProjection>()
        var index = viewportStart
        var remaining = maximumVisibleRecords()
        while (index < filtered.size && remaining > 0) {
            result.add(filtered[index]); index += 1; remaining -= 1
        }
        return result
    }

    private func clampViewport(total: Int64) {
        let maximumStart = if (total > maximumVisibleRecords()) { total - maximumVisibleRecords() } else { 0 }
        if (viewportStart < 0) { viewportStart = 0 }
        if (viewportStart > maximumStart) { viewportStart = maximumStart }
    }
    private func maximumVisibleRecords(): Int64 { return 8 }
    private func editorKindCode(editorKind: String): UInt32 {
        if (editorKind == "INTEGER") { return 2u32 }
        if (editorKind == "BOOLEAN") { return 3u32 }
        return 1u32
    }
    private func nonnegativeUInt32(value: Int64): UInt32 {
        if (value <= 0) { return 0u32 }
        if (value > 4294967295) { return 4294967295u32 }
        return UInt32(value)
    }
    private func discardSession() {
        if (sessionToken != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            let status = internalRendererDestroy(sessionToken)
            if (status != CJGUI_INTERNAL_RENDERER_OK) { lastNativeStatus = status }
        }
        sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        isWindowOpen = false
    }
}
