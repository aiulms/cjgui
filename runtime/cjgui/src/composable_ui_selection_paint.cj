package cjgui

// Package-private Darwin bridge. Public completion remains platform-neutral;
// paint publication neither creates a receipt nor grants input authority.
@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_finish_selection_paint_publication(session: UInt64,
        transfer: UInt64, generation: UInt64, binding: UInt64, proxy: UInt64,
        nativeRevision: UInt64, ownerVersion: Int64, ownerRevision: Int64,
        proxyOnly: UInt8, needsProjection: CPointer<UInt8>): Int32
    func cjgui_internal_renderer_stage_selection_paint_publication(session: UInt64,
        transfer: UInt64, generation: UInt64, binding: UInt64, ownerVersion: Int64,
        ownerRevision: Int64, scene: UInt64): Int32
}

@When[os == "macOS"]
func internalRendererFinishSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    proxyOnly: Bool): (Int32, Bool) {
    var needs: UInt8 = 0
    let status = unsafe { cjgui_internal_renderer_finish_selection_paint_publication(
        completion.windowSession, completion.transferId, completion.rendererSessionGeneration,
        completion.targetBindingEpoch, completion.targetProxyGeneration,
        completion.targetSelectionRevision, completion.sourceOwnerVersion,
        completion.sourceSelection.revision, if (proxyOnly) { 1u8 } else { 0u8 }, inout needs) }
    return (status, needs == 1u8)
}

@When[os != "macOS"]
func internalRendererFinishSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    proxyOnly: Bool): (Int32, Bool) { return (CJGUI_INTERNAL_RENDERER_OK, false) }

@When[os == "macOS"]
func internalRendererStageSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    scene: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_stage_selection_paint_publication(
        completion.windowSession, completion.transferId, completion.rendererSessionGeneration,
        completion.targetBindingEpoch, completion.sourceOwnerVersion,
        completion.sourceSelection.revision, scene) }
}

@When[os != "macOS"]
func internalRendererStageSelectionPaint(completion: CjguiInstalledSelectionCompletion,
    scene: UInt64): Int32 { return CJGUI_INTERNAL_RENDERER_OK }
