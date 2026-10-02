package cjgui

// Host-side focused tests for the H snapshot Node/Event ABI mirror.
//
// The harness (run_node_abi_sentinel_cjpm.py) extracts the production @C
// structs verbatim into this package and links a C shim compiled against the
// REAL snapshot header. Sentinel values are written by Cangjie, read back
// through the C-compiled header view, and vice versa, so a mirror drift in the
// probed fields (epoch, its neighbors and every field group boundary) fails.

import std.unittest.*
import std.unittest.testmacro.*

foreign {
    func cjgui_node_probe_sizeof(): UIntNative
    func cjgui_node_probe_copy(node: CPointer<CjguiInternalRendererComposableNode>,
        out: CPointer<CjguiInternalRendererComposableNode>): Unit
    func cjgui_node_probe_u64(node: CPointer<CjguiInternalRendererComposableNode>, index: Int32): UInt64
    func cjgui_node_probe_f64(node: CPointer<CjguiInternalRendererComposableNode>, index: Int32): Float64
    func cjgui_event_probe_sizeof(): UIntNative
    func cjgui_event_probe_u64(event: CPointer<CjguiInternalRendererEvent>, index: Int32): UInt64
}

private func sentinelNode(): CjguiInternalRendererComposableNode {
    var node = CjguiInternalRendererComposableNode(
        nodeId: 0x1111222233334444,
        projectionVersion: 0x5555666677778888,
        resourceId: 0x12345678,
        x: 101,
        y: -202,
        width: 303,
        height: 404,
        clipX: 5,
        clipY: 6,
        clipWidth: 7,
        clipHeight: 8,
        nodeKind: 9u32,
        isInteractive: 1u32,
        isReadOnly: 0u32,
        tabInsertsText: 1u32,
        borderWidth: 2u32,
        cornerRadius: 4.5,
        clip0CornerRadius: 1.25,
        fontSize: 17.5,
        fontWeight: 2u32,
        fontFamily: 1u32,
        imageContentMode: 2u32,
        fillRed: 0.1,
        fillGreen: 0.2,
        fillBlue: 0.3,
        fillAlpha: 0.4,
        borderRed: 0.5,
        borderGreen: 0.6,
        borderBlue: 0.7,
        borderAlpha: 0.8,
        textRed: 0.9,
        textGreen: 1.1,
        textBlue: 1.2,
        textAlpha: 1.3,
        inputScope: 0xA1A2A3A4A5A6A7A8,
        tabGroupId: 0xB1B2B3B4B5B6B7B8,
        tabSelected: 0x0C0D0E0F,
        semanticRole: 0x11223344u32,
        semanticState: 0x55667788u32,
        semanticLevel: -2233,
        semanticIncarnation: 4455,
        shadowPresent: 1u32,
        shadowOffsetX: 3.25,
        shadowOffsetY: -7.5,
        shadowBlurRadius: 9.0,
        shadowSpread: 1.5,
        shadowAlpha: 0.44,
        gradientPresent: 1u32,
        gradientStopCount: 3u32,
        gradientStartX: 0.125,
        gradientEndY: 0.75,
        gradientStop3Alpha: 0.987,
        effectGroupPresent: 1u32,
        effectGroupSubtreeCount: 7u32,
        effectGroupOpacity: 0.875,
        effectGroupBlendMode: 1u32,
        effectMaskPresent: 1u32,
        effectMaskStopCount: 4u32,
        effectMaskStartX: 0.0625,
        effectMaskEndY: 0.5,
        effectMaskStop3Alpha: 0.375,
        effectBackdropBlurRadiusPoints: 9u32,
        effectBackdropBlurFallback: 1u32
    )
    node.wheelScrollable = 0x0BADF00D
    node.acceptedBindingEpoch = 0xFEEDFACE12345678
    return node
}

private func zeroNode(): CjguiInternalRendererComposableNode {
    return CjguiInternalRendererComposableNode(
        nodeId: 0,
        projectionVersion: 0,
        resourceId: -1,
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        clipX: 0,
        clipY: 0,
        clipWidth: 0,
        clipHeight: 0,
        nodeKind: 0u32,
        isInteractive: 0u32,
        isReadOnly: 0u32,
        tabInsertsText: 0u32,
        borderWidth: 0u32,
        fontSize: 13.0,
        fontWeight: 0u32,
        fontFamily: 0u32,
        imageContentMode: 1u32,
        fillRed: 0.0,
        fillGreen: 0.0,
        fillBlue: 0.0,
        fillAlpha: 0.0,
        borderRed: 0.0,
        borderGreen: 0.0,
        borderBlue: 0.0,
        borderAlpha: 0.0,
        textRed: 0.0,
        textGreen: 0.0,
        textBlue: 0.0,
        textAlpha: 0.0
    )
}

@Test
func ohosNodeAbiMirrorSizeMatchesC(): Unit {
    let cSize = unsafe { cjgui_node_probe_sizeof() }
    let cjSize = unsafe { sizeOf<CjguiInternalRendererComposableNode>() }
    @Assert(cSize, UIntNative(888))
    @Assert(cjSize, cSize)
}

@Test
func ohosNodeSentinelEpochAndNeighborFieldsPassThroughC(): Unit {
    let node = sentinelNode()
    unsafe {
        var u64 = node
        @Assert(cjgui_node_probe_u64(inout u64, 0), 0x1111222233334444)
        @Assert(cjgui_node_probe_u64(inout u64, 1), 0x5555666677778888)
        @Assert(cjgui_node_probe_u64(inout u64, 2), 0x12345678)
        @Assert(cjgui_node_probe_u64(inout u64, 3), 101)
        @Assert(cjgui_node_probe_u64(inout u64, 4), 0xFFFFFFFFFFFFFF36)  // y = -202 的位型
        @Assert(cjgui_node_probe_u64(inout u64, 5), 303)
        @Assert(cjgui_node_probe_u64(inout u64, 6), 404)
        @Assert(cjgui_node_probe_u64(inout u64, 7), 9)
        @Assert(cjgui_node_probe_u64(inout u64, 8), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 9), 0)
        @Assert(cjgui_node_probe_u64(inout u64, 10), 0xA1A2A3A4A5A6A7A8)
        @Assert(cjgui_node_probe_u64(inout u64, 11), 0xB1B2B3B4B5B6B7B8)
        @Assert(cjgui_node_probe_u64(inout u64, 12), 0x0C0D0E0F)
        @Assert(cjgui_node_probe_u64(inout u64, 13), 0x11223344)
        @Assert(cjgui_node_probe_u64(inout u64, 14), 0x55667788)
        @Assert(cjgui_node_probe_u64(inout u64, 15), 0xFFFFFFFFFFFFF747)  // semanticLevel = -2233 的位型
        @Assert(cjgui_node_probe_u64(inout u64, 16), 4455)
        @Assert(cjgui_node_probe_u64(inout u64, 17), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 18), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 19), 3)
        @Assert(cjgui_node_probe_u64(inout u64, 20), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 21), 7)
        @Assert(cjgui_node_probe_u64(inout u64, 22), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 23), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 24), 4)
        @Assert(cjgui_node_probe_u64(inout u64, 25), 9)
        @Assert(cjgui_node_probe_u64(inout u64, 26), 1)
        @Assert(cjgui_node_probe_u64(inout u64, 27), 0x0BADF00D)
        @Assert(cjgui_node_probe_u64(inout u64, 28), 0xFEEDFACE12345678)

        @Assert(cjgui_node_probe_f64(inout u64, 0), 17.5)
        @Assert(cjgui_node_probe_f64(inout u64, 1), 0.4)
        @Assert(cjgui_node_probe_f64(inout u64, 2), 1.3)
        @Assert(cjgui_node_probe_f64(inout u64, 3), 4.5)
        @Assert(cjgui_node_probe_f64(inout u64, 4), 1.25)
        @Assert(cjgui_node_probe_f64(inout u64, 5), 3.25)
        @Assert(cjgui_node_probe_f64(inout u64, 6), -7.5)
        @Assert(cjgui_node_probe_f64(inout u64, 7), 9.0)
        @Assert(cjgui_node_probe_f64(inout u64, 8), 1.5)
        @Assert(cjgui_node_probe_f64(inout u64, 9), 0.44)
        @Assert(cjgui_node_probe_f64(inout u64, 10), 0.125)
        @Assert(cjgui_node_probe_f64(inout u64, 11), 0.75)
        @Assert(cjgui_node_probe_f64(inout u64, 12), 0.987)
        @Assert(cjgui_node_probe_f64(inout u64, 13), 0.875)
        @Assert(cjgui_node_probe_f64(inout u64, 14), 0.0625)
        @Assert(cjgui_node_probe_f64(inout u64, 15), 0.5)
        @Assert(cjgui_node_probe_f64(inout u64, 16), 0.375)
    }
}

@Test
func ohosNodeCopyThroughCReadsBackInCangjie(): Unit {
    let node = sentinelNode()
    var copy = zeroNode()
    unsafe {
        var source = node
        cjgui_node_probe_copy(inout source, inout copy)
    }
    @Assert(copy.nodeId, 0x1111222233334444)
    @Assert(copy.projectionVersion, 0x5555666677778888)
    @Assert(copy.resourceId, 0x12345678)
    @Assert(copy.x, 101)
    @Assert(copy.y, -202)
    @Assert(copy.inputScope, 0xA1A2A3A4A5A6A7A8)
    @Assert(copy.tabGroupId, 0xB1B2B3B4B5B6B7B8)
    @Assert(copy.tabSelected, 0x0C0D0E0F)
    @Assert(copy.semanticRole, 0x11223344)
    @Assert(copy.semanticState, 0x55667788)
    @Assert(copy.semanticLevel, -2233)
    @Assert(copy.semanticIncarnation, 4455)
    @Assert(copy.shadowPresent, 1)
    @Assert(copy.shadowOffsetX, 3.25)
    @Assert(copy.shadowOffsetY, -7.5)
    @Assert(copy.shadowBlurRadius, 9.0)
    @Assert(copy.shadowSpread, 1.5)
    @Assert(copy.shadowAlpha, 0.44)
    @Assert(copy.gradientPresent, 1)
    @Assert(copy.gradientStopCount, 3)
    @Assert(copy.gradientStartX, 0.125)
    @Assert(copy.gradientEndY, 0.75)
    @Assert(copy.gradientStop3Alpha, 0.987)
    @Assert(copy.effectGroupPresent, 1)
    @Assert(copy.effectGroupSubtreeCount, 7)
    @Assert(copy.effectGroupOpacity, 0.875)
    @Assert(copy.effectGroupBlendMode, 1)
    @Assert(copy.effectMaskPresent, 1)
    @Assert(copy.effectMaskStopCount, 4)
    @Assert(copy.effectMaskStartX, 0.0625)
    @Assert(copy.effectMaskEndY, 0.5)
    @Assert(copy.effectMaskStop3Alpha, 0.375)
    @Assert(copy.effectBackdropBlurRadiusPoints, 9)
    @Assert(copy.effectBackdropBlurFallback, 1)
    @Assert(copy.wheelScrollable, 0x0BADF00D)
    @Assert(copy.acceptedBindingEpoch, 0xFEEDFACE12345678)
    @Assert(copy.fillAlpha, 0.4)
    @Assert(copy.textAlpha, 1.3)
    @Assert(copy.fontSize, 17.5)
}

@Test
func ohosEventAbiMirrorSizeAndGestureSentinel(): Unit {
    let cSize = unsafe { cjgui_event_probe_sizeof() }
    let cjSize = unsafe { sizeOf<CjguiInternalRendererEvent>() }
    @Assert(cSize, UIntNative(184))
    @Assert(cjSize, cSize)

    var event = CjguiInternalRendererEvent()
    event.kind = 30u32
    event.recordIndex = 12u32
    event.nodeId = 0x1234ABCD5678EF90
    event.projectionVersion = 0x0F0E0D0C0B0A0908
    event.resourceId = 77
    event.nodeKind = 13u32
    event.pointerX = -5150
    event.pointerY = 6150
    event.gestureAppInstance = 0xAAAA1111AAAA2222
    event.gestureComponentInstance = 0xBBBB3333BBBB4444
    event.gestureSurfaceGeneration = 0xCCCC5555CCCC6666
    event.gesturePointerId = 3
    event.gestureEpoch = 0xDDDD7777DDDD8888
    event.acceptedBindingEpoch = 0xEEEE9999EEEEAAAA
    unsafe {
        var probe = event
        @Assert(cjgui_event_probe_u64(inout probe, 0), 30)
        @Assert(cjgui_event_probe_u64(inout probe, 1), 12)
        @Assert(cjgui_event_probe_u64(inout probe, 2), 0x1234ABCD5678EF90)
        @Assert(cjgui_event_probe_u64(inout probe, 3), 0x0F0E0D0C0B0A0908)
        @Assert(cjgui_event_probe_u64(inout probe, 4), 77)
        @Assert(cjgui_event_probe_u64(inout probe, 5), 13)
        @Assert(cjgui_event_probe_u64(inout probe, 6), 0xFFFFFFFFFFFFEBE2)  // pointerX = -5150 的位型
        @Assert(cjgui_event_probe_u64(inout probe, 7), 6150)
        @Assert(cjgui_event_probe_u64(inout probe, 8), 0xAAAA1111AAAA2222)
        @Assert(cjgui_event_probe_u64(inout probe, 9), 0xBBBB3333BBBB4444)
        @Assert(cjgui_event_probe_u64(inout probe, 10), 0xCCCC5555CCCC6666)
        @Assert(cjgui_event_probe_u64(inout probe, 11), 3)
        @Assert(cjgui_event_probe_u64(inout probe, 12), 0xDDDD7777DDDD8888)
        @Assert(cjgui_event_probe_u64(inout probe, 13), 0xEEEE9999EEEEAAAA)
    }
}
