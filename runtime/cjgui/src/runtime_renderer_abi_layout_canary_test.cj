// A0 ABI 布局 canary（指导复核要求：struct 大小/alignment/尾部保护验证）。
//
// native（Metal 实现与鸿蒙渲染器）按 C 布局写入 40 字节 FrameObservation；
// 仓颉 @C 镜像与 native 的布局漂移会以三种方式暴露：
//  1) sizeOf 断言——仓颉镜像必须是 40（与 C _Static_assert 对应）；
//  2) 嵌套 canary——把 observation 内嵌进带尾部哨兵的包裹结构，经
//     present_clear 的 outObservation 写入后哨兵必须原样保留；
//  3) 字段事实——clear 的返回值必须是可解释的（INVALID_SESSION 时全零）。
// 任何一条失败都意味着跨语言 ABI 不再兼容，先修镜像再谈平台行为。
package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@Test
func cjguiAbiFrameObservationLayoutLocked(): Unit {
    // 1) 镜像大小锁：8+4+4+8+1+1+1(+7 pad)+8 = 40
    let observed = unsafe { sizeOf<CjguiInternalRendererFrameObservation>() }
    @Assert(observed == 40)
}

@Test
func cjguiAbiWindowBackgroundSnapshotLayoutLocked(): Unit {
    // Five 64-bit identities/revisions followed by eight 32-bit state words.
    @Assert(unsafe { sizeOf<CjguiInternalRendererWindowBackgroundSnapshot>() }, 72)
}

@Test
func cjguiAbiFrameObservationTailCanaryHoldsOnInvalidSession(): Unit {
    // 2/3) 无效会话路径：native 必须只清 observation 的 40 字节；
    // 尾部哨兵在调用前后保持不变，即"写入未越过结构边界"的直接证据。
    @Assert(internalRendererPresentClearCanaryInvalidSession())
}

@Test
func cjguiAbiEventLayoutLocked(): Unit {
    // 事件镜像大小锁：旧 128 字节布局 + 一次性二进制读取票据 dataTransferEventId = 136。
    let observed = unsafe { sizeOf<CjguiInternalRendererEvent>() }
    @Assert(observed, 136)
}

@Test
func cjguiAbiEventTailCanaryHoldsOnInvalidSession(): Unit {
    // pump_event 先按 native sizeof 清零整块：镜像尺寸或尾部写入越界都会踩掉哨兵。
    @Assert(internalRendererPumpEventCanaryInvalidSession())
}
