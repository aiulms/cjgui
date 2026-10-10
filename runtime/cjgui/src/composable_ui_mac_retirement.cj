package cjgui

// 私有准备图的退休准入。macOS 与 Windows 都有真实的退休队列：回收按有界单元
// 推进，队列里仍有两个以上未回收的图时不接受新的准备票。没有该责任的平台
// 按“无真实回收可等”返回可以开始，而不是伪装已回收。
@When[os == "macOS" || os == "Windows"]
foreign {
    func cjgui_internal_renderer_drain_composable_retirement(session: UInt64,
        deadline: UInt64, mayBegin: CPointer<UInt8>): Int32
}
@When[os == "macOS" || os == "Windows"]
func internalRendererDrainComposableRetirement(session: UInt64, deadline: UInt64): (Int32, Bool) {
    var mayBegin: UInt8 = 0
    let status = unsafe { cjgui_internal_renderer_drain_composable_retirement(session, deadline, inout mayBegin) }
    return (status, mayBegin == 1u8)
}
@When[os != "macOS" && os != "Windows"]
func internalRendererDrainComposableRetirement(session: UInt64, deadline: UInt64): (Int32, Bool) {
    return (CJGUI_INTERNAL_RENDERER_OK, true)
}
