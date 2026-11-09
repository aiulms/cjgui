package cjgui

// Private Windows queue-slot fact. It conveys the original producer identity;
// no public event POD, owner, selection setter or coordinate is synthesized.
@When[os == "Windows"]
foreign func cjgui_windows_selection_gesture_v1(session: UInt64, mode: UInt32,
    identity: CPointer<UInt64>, accepted: UInt8, meta: CPointer<UInt64>): Int32

@When[os == "Windows"]
func cjguiWindowsSelectionGestureNative(session: UInt64, mode: UInt32,
    identity!: Array<UInt64> = [], accepted!: Bool = false): Array<UInt64> {
    let output = Array<UInt64>(19, { _ => 0u64 })
    let input = if (identity.size == 19) { identity } else { Array<UInt64>(19, { _ => 0u64 }) }
    let status = unsafe {
        let i = acquireArrayRawData(input)
        let o = acquireArrayRawData(output)
        let result = cjgui_windows_selection_gesture_v1(session, mode, i.pointer,
            if (accepted) { 1u8 } else { 0u8 }, o.pointer)
        releaseArrayRawData(o); releaseArrayRawData(i)
        result
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { output } else { [] }
}
@When[os != "Windows"]
func cjguiWindowsSelectionGestureNative(session: UInt64, mode: UInt32,
    identity!: Array<UInt64> = [], accepted!: Bool = false): Array<UInt64> { return [] }
