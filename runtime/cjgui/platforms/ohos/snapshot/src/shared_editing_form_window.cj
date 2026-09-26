package cjgui

import cjgui_shared_operation_core.*

/// Experimental bounded event result for a normal editable-form window.
public class CjguiSharedEditingFormWindowPumpResult {
    public let isOpen: Bool
    public let didApplyHumanAction: Bool
    public let nativeStatus: Int32
    public init(isOpen: Bool, didApplyHumanAction: Bool, nativeStatus: Int32) {
        this.isOpen = isOpen; this.didApplyHumanAction = didApplyHumanAction; this.nativeStatus = nativeStatus
    }
}

/// Experimental reusable macOS form projection. The Cangjie form domain is
/// the only owner of applied values, raw drafts, selection and validation.
/// A self-drawn native surface reports intent through the bounded renderer
/// pump and is immediately resynchronized from that domain. Its off-canvas
/// input proxy supplies platform text services without owning form truth.
public class CjguiSharedEditingFormWindow {
    private let domain: CjguiSharedEditableFormDomain
    private var sessionToken: UInt64
    private var isWindowOpen: Bool
    private var lastNativeStatus: Int32

    public init(domain: CjguiSharedEditableFormDomain) {
        this.domain = domain
        this.sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        this.isWindowOpen = false
        this.lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }

    public func start(): Bool {
        if (isWindowOpen) { return true }
        let binding = domain.formBinding()
        if (binding.fieldCount() <= 0 || binding.fieldCount() > 8) { return false }
        let created = internalRendererCreate(CjguiInternalRendererConfig(
            windowWidth: 720u32, windowHeight: UInt32(180 + binding.fieldCount() * 76),
            clearColorRed: 0.94, clearColorGreen: 0.95, clearColorBlue: 0.97, clearColorAlpha: 1.0
        ))
        if (created.status != CJGUI_INTERNAL_RENDERER_OK || created.token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            lastNativeStatus = created.status; return false
        }
        sessionToken = created.token
        lastNativeStatus = internalRendererConfigureSharedForm(sessionToken, UInt32(binding.fieldCount()))
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { discardSession(); return false }
        let frame = internalRendererPresentClear(sessionToken, CjguiInternalRendererClearColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0))
        if (frame.status != CJGUI_INTERNAL_RENDERER_OK) { lastNativeStatus = frame.status; discardSession(); return false }
        isWindowOpen = true
        if (!syncProjection()) { discardSession(); return false }
        return true
    }

    public func pump(timeoutMs: UInt32): CjguiSharedEditingFormWindowPumpResult {
        if (!isWindowOpen) { return CjguiSharedEditingFormWindowPumpResult(false, false, lastNativeStatus) }
        let event = internalRendererPumpEvent(sessionToken, timeoutMs)
        lastNativeStatus = event.status
        if (event.status != CJGUI_INTERNAL_RENDERER_OK || event.eventKind == 1u32) {
            discardSession(); return CjguiSharedEditingFormWindowPumpResult(false, false, lastNativeStatus)
        }
        var didApply = false
        let binding = domain.formBinding()
        if (event.recordIndex < UInt32(binding.fieldCount())) {
            let descriptor = binding.fieldAtControlIndex(Int64(event.recordIndex))
            if (event.eventKind == 6u32 || event.eventKind == 7u32) {
                let result = domain.editTextFromHuman(descriptor.resourceId, internalRendererFormEventText(sessionToken), Int64(event.selectionStart), Int64(event.selectionEnd))
                didApply = result.applied
            } else if (event.eventKind == 8u32) {
                let result = domain.editBooleanFromHuman(descriptor.resourceId, internalRendererFormEventText(sessionToken) == "true")
                didApply = result.applied
            }
        }
        if (event.eventKind == 9u32) {
            let snapshot = domain.formSnapshot()
            didApply = domain.applyDraftFromHuman(snapshot.draftVersion, snapshot.baseAppliedConfigVersion).applied
        } else if (event.eventKind == 10u32) {
            let snapshot = domain.formSnapshot()
            didApply = domain.cancelDraftFromHuman(snapshot.draftVersion, snapshot.baseAppliedConfigVersion).applied
        }
        if (!syncProjection()) { discardSession(); return CjguiSharedEditingFormWindowPumpResult(false, didApply, lastNativeStatus) }
        return CjguiSharedEditingFormWindowPumpResult(true, didApply, lastNativeStatus)
    }

    public func close() {
        if (isWindowOpen) { let _ = internalRendererRequestClose(sessionToken) }
        discardSession()
    }
    public func isOpen(): Bool { return isWindowOpen }
    public func nativeStatus(): Int32 { return lastNativeStatus }

    private func syncProjection(): Bool {
        let binding = domain.formBinding()
        let snapshot = domain.formSnapshot()
        var index: Int64 = 0
        while (index < binding.fieldCount()) {
            let descriptor = binding.fieldAtControlIndex(index)
            let field = snapshot.fieldForResourceId(descriptor.resourceId)
            lastNativeStatus = internalRendererSetSharedFormField(
                sessionToken, UInt32(index), descriptor.label, field.draftText, field.validationError,
                editorKindCode(descriptor.editorKind), field.isFocused,
                nonnegativeUInt32(field.selectionStart), nonnegativeUInt32(field.selectionEnd)
            )
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
            index += 1
        }
        lastNativeStatus = internalRendererSetSharedFormStatus(sessionToken, "已应用 v${snapshot.appliedConfigVersion} · 草稿 v${snapshot.draftVersion} · ${snapshot.statusMessage}")
        return lastNativeStatus == CJGUI_INTERNAL_RENDERER_OK
    }

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
