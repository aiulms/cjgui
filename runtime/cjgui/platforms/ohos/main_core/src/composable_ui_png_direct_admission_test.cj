package cjgui

import cjgui_shared_operation_core.*
import std.unittest.*
import std.unittest.testmacro.*

private class DirectPngAdmissionController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var image: ?CjguiSharedOperationTransferOffer = None

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "direct-png-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "direct-png-button", "Accept", "PRESS", 0,
            CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 32)))
        if (let Some(offer) <- image) {
            root.add(cjguiComposableImageFromTransfer(3, "direct-png-image", offer,
                CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 40)))
        }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func directPngOverDimension(): Array<Byte> {
    return [0x89u8, 0x50u8, 0x4Eu8, 0x47u8, 0x0Du8, 0x0Au8, 0x1Au8, 0x0Au8,
        0x00u8, 0x00u8, 0x00u8, 0x0Du8, 0x49u8, 0x48u8, 0x44u8, 0x52u8,
        0x00u8, 0x00u8, 0x08u8, 0x01u8, 0x00u8, 0x00u8, 0x00u8, 0x01u8,
        0x08u8, 0x06u8, 0x00u8, 0x00u8, 0x00u8, 0xA5u8, 0xD6u8, 0x25u8,
        0xCCu8, 0x00u8, 0x00u8, 0x00u8, 0x21u8, 0x49u8, 0x44u8, 0x41u8,
        0x54u8, 0x78u8, 0x9Cu8, 0xEDu8, 0xC3u8, 0x01u8, 0x09u8, 0x00u8,
        0x00u8, 0x0Cu8, 0x04u8, 0xA1u8, 0xEBu8, 0x5Fu8, 0x7Au8, 0xCBu8,
        0xF1u8, 0xA0u8, 0x60u8, 0xD5u8, 0xA9u8, 0xAAu8, 0xAAu8, 0xAAu8,
        0xAAu8, 0xAAu8, 0xAAu8, 0xAAu8, 0xFBu8, 0x1Fu8, 0x83u8, 0x55u8,
        0xF9u8, 0x69u8, 0xD2u8, 0x2Cu8, 0x98u8, 0x14u8, 0x00u8, 0x00u8,
        0x00u8, 0x00u8, 0x49u8, 0x45u8, 0x4Eu8, 0x44u8, 0xAEu8, 0x42u8,
        0x60u8, 0x82u8]
}

private func directPngValid(): Array<Byte> {
    return [0x89u8, 0x50u8, 0x4Eu8, 0x47u8, 0x0Du8, 0x0Au8, 0x1Au8, 0x0Au8,
        0x00u8, 0x00u8, 0x00u8, 0x0Du8, 0x49u8, 0x48u8, 0x44u8, 0x52u8,
        0x00u8, 0x00u8, 0x00u8, 0x03u8, 0x00u8, 0x00u8, 0x00u8, 0x02u8,
        0x08u8, 0x06u8, 0x00u8, 0x00u8, 0x00u8, 0x9Du8, 0x74u8, 0x66u8,
        0x1Au8, 0x00u8, 0x00u8, 0x00u8, 0x17u8, 0x49u8, 0x44u8, 0x41u8,
        0x54u8, 0x78u8, 0x9Cu8, 0x63u8, 0xF8u8, 0xCFu8, 0xC0u8, 0xF0u8,
        0x1Fu8, 0x0Cu8, 0x19u8, 0xFEu8, 0xFFu8, 0x87u8, 0xA1u8, 0x06u8,
        0x20u8, 0xF9u8, 0x1Fu8, 0x00u8, 0xA7u8, 0xF4u8, 0x0Eu8, 0x73u8,
        0x39u8, 0x1Cu8, 0xD8u8, 0xA5u8, 0x00u8, 0x00u8,
        0x00u8, 0x00u8, 0x49u8, 0x45u8, 0x4Eu8, 0x44u8, 0xAEu8, 0x42u8,
        0x60u8, 0x82u8]
}

@Test
func directPngDeclarationRejectsBeforeAcceptedScene(): Unit {
    let owner = DirectPngAdmissionController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    let accepted = window.windowProgress()
    owner.image = CjguiSharedOperationTransferOffer.createBinary("COPY", "fixture", "direct-over", 1,
        CjguiSharedOperationTransferFormat.png(), directPngOverDimension())
    owner.revision += 1
    @Assert(window.refresh(), false)
    let rejected = window.windowProgress()
    @Assert(rejected.acceptedSceneVersion, accepted.acceptedSceneVersion)
    @Assert(rejected.submittedFrameIndex, accepted.submittedFrameIndex)
    @Assert(rejected.lastNativeFailure, "png_dimension_exceeded")
    owner.image = CjguiSharedOperationTransferOffer.createBinary("COPY", "fixture", "direct-valid", 2,
        CjguiSharedOperationTransferFormat.png(), directPngValid())
    owner.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().acceptedSceneVersion > accepted.acceptedSceneVersion, true)
    window.close()
}
