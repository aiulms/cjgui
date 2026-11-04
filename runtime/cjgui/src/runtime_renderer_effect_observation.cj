package cjgui

// Private macOS observation of real submitted effect target references. It
// does not publish native resources or change the cross-platform renderer ABI.
@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_set_effect_observation(session: UInt64, enabled: UInt32): Int32
    func cjgui_internal_renderer_effect_observation(session: UInt64, scene: UInt64, frame: UInt64,
        values: CPointer<UInt64>, capacity: UInt32): Int32
}

@When[os == "macOS"]
func internalRendererSetEffectObservation(session: UInt64, enabled: Bool): Bool {
    return unsafe { cjgui_internal_renderer_set_effect_observation(session, if (enabled) { 1u32 } else { 0u32 }) } ==
        CJGUI_INTERNAL_RENDERER_OK
}

@When[os != "macOS"]
func internalRendererSetEffectObservation(session: UInt64, enabled: Bool): Bool { return true }

@When[os == "macOS"]
func internalRendererEffectObservation(session: UInt64, scene: UInt64, frame: UInt64): (Bool, Int64, Int64) {
    let values = Array<UInt64>(3, repeat: 0u64)
    let status = unsafe {
        let raw = acquireArrayRawData(values)
        try { cjgui_internal_renderer_effect_observation(session, scene, frame, raw.pointer, 3u32) }
        finally { releaseArrayRawData(raw) }
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK || values[0] != 1u64 ||
        values[1] > UInt64(Int64.Max) || values[2] > UInt64(Int64.Max)) { return (false, -1, -1) }
    return (true, Int64(values[1]), Int64(values[2]))
}

@When[os != "macOS"]
func internalRendererEffectObservation(session: UInt64, scene: UInt64, frame: UInt64): (Bool, Int64, Int64) {
    return (false, -1, -1)
}
