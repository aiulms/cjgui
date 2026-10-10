package cjgui

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_mark_caret_edit_applied(session: UInt64, generation: UInt64,
        sequence: UInt64, previous: UInt64, before: Int64, after: Int64,
        context: UInt64, window: UInt64): Int32
}
@When[os == "macOS"]
func internalRendererMarkCaretEditApplied(session: UInt64, input: InternalRendererInputProvenance,
    before: Int64, after: Int64, context: Int64, window: Int64): Int32 {
    return unsafe { cjgui_internal_renderer_mark_caret_edit_applied(session,
        input.sessionGeneration, input.sequence, input.previousSequence, before, after,
        UInt64(context), UInt64(window)) }
}
@When[os != "macOS"]
func internalRendererMarkCaretEditApplied(session: UInt64, input: InternalRendererInputProvenance,
    before: Int64, after: Int64, context: Int64, window: Int64): Int32 {
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
}
