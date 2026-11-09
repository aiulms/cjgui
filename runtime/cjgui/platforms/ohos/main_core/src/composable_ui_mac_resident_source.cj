package cjgui

// Package-private macOS custody transport. The common candidate supplies a
// genuine passive-origin proof; native freezes/rechecks the actual installed
// source and publishes this role only with that successful candidate Present.
@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_stage_resident_text_source(session: UInt64, preparation: UInt64,
        transfer: UInt64, proxy: UInt64, window: UInt64, context: UInt64, binding: UInt64,
        nativeRevision: UInt64, ownerVersion: Int64, selectionStart: UInt32, selectionEnd: UInt32,
        viewportNode: UInt64, viewportResource: Int64, viewportKind: UInt32): Int32
}

@When[os == "macOS"]
func internalRendererResidentTextSourceSupported(): Bool { return true }
@When[os != "macOS"]
func internalRendererResidentTextSourceSupported(): Bool { return false }

@When[os == "macOS"]
func internalRendererStageResidentTextSource(session: UInt64, preparation: UInt64,
    completed: CjguiInstalledSelectionCompletion, viewportNode: Int64, viewportResource: Int64): Int32 {
    return unsafe { cjgui_internal_renderer_stage_resident_text_source(session, preparation,
        completed.transferId, completed.targetProxyGeneration, completed.windowInstanceToken,
        UInt64(completed.semantic.contextEpoch), completed.targetBindingEpoch,
        completed.targetSelectionRevision, completed.sourceSelection.version,
        UInt32(completed.targetSelectionStart16), UInt32(completed.targetSelectionEnd16),
        UInt64(viewportNode), viewportResource, UInt32(CJGUI_COMPOSABLE_UI_SCROLL_AREA)) }
}

@When[os != "macOS"]
func internalRendererStageResidentTextSource(session: UInt64, preparation: UInt64,
    completed: CjguiInstalledSelectionCompletion, viewportNode: Int64, viewportResource: Int64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}

@When[os == "macOS"]
foreign func cjgui_internal_renderer_resident_caret_source(session: UInt64, generation: UInt64,
    sequence: UInt64, previous: UInt64, meta: CPointer<Int64>, bytes: CPointer<UInt8>, capacity: UInt64): Int32

@When[os == "macOS"]
func internalRendererResidentCaretSource(session: UInt64, input: InternalRendererInputProvenance,
    capacity: Int64): (Int32, Array<Int64>, String) {
    let meta = Array<Int64>(21, repeat: 0)
    if (capacity < 0 || capacity > 8 * 1024 * 1024) { return (CJGUI_INTERNAL_RENDERER_SCENE_STALE, meta, "") }
    let bytes = Array<UInt8>(max(1, capacity), repeat: 0u8)
    let status = unsafe {
        let m = acquireArrayRawData(meta)
        let b = acquireArrayRawData(bytes)
        let value = cjgui_internal_renderer_resident_caret_source(session, input.sessionGeneration,
            input.sequence, input.previousSequence, m.pointer, b.pointer, UInt64(bytes.size))
        releaseArrayRawData(b); releaseArrayRawData(m)
        value
    }
    return (status, meta, if (status == CJGUI_INTERNAL_RENDERER_OK && meta[17] >= 0 && meta[17] <= bytes.size) {
        String.fromUtf8(bytes.slice(0, meta[17]))
    } else { "" })
}
@When[os != "macOS"]
func internalRendererResidentCaretSource(session: UInt64, input: InternalRendererInputProvenance,
    capacity: Int64): (Int32, Array<Int64>, String) {
    return (CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED, [], "")
}
