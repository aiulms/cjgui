package cjgui

import std.collection.*

private class GestureTerminalController <: CjguiComposableUiController {
    public var fieldId: String = "A"
    public var invalidDuplicate: Bool = false
    public var targetOffsetY: Int64 = 0
    public var revision: Int64 = 1
    public let phases = ArrayList<Int64>()

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(800, "gesture-root", CjguiComposableUiStyle())
        root.add(cjguiComposableText(801, "gesture-target", "target",
            CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 50, pointerInteractive: true,
                offsetY: targetOffsetY),
            fieldId: fieldId))
        if (invalidDuplicate) {
            root.add(cjguiComposableText(801, "duplicate-gesture-target", "duplicate",
                CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 50)))
        }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        phases.add(event.eventKind)
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func frozenPointerEvent(kind: Int64, gestureEpoch: UInt64, bindingEpoch: UInt64,
    sceneVersion: Int64): InternalRendererPumpResult {
    return InternalRendererPumpResult(CJGUI_INTERNAL_RENDERER_OK, UInt32(kind), 0u32, 0u32, 0u32,
        801u64, UInt64(sceneVersion), -1, UInt32(CJGUI_COMPOSABLE_UI_TEXT), 20, 20,
        20.0, 20.0, 0.0, 0.0, false, 0, 0u32, -1, 0, -1, 0,
        0u64, 0u64, 0u64, 11u64, 12u64, 13u64, 0, gestureEpoch, bindingEpoch)
}

private func countPointerPhase(phases: ArrayList<Int64>, kind: Int64): Int64 {
    var count: Int64 = 0
    for (phase in phases) { if (phase == kind) { count += 1 } }
    return count
}

@Test
func stalePlatformCancelDoesNotEndNewCoreCapture(): Unit {
    let controller = GestureTerminalController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let version = window.windowProgress().acceptedSceneVersion
    let binding = window.acceptedBindingEpochForTest(801)
    @Assert(binding != 0u64, true)

    let aBegin = frozenPointerEvent(CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, 71u64, binding, version)
    let bBegin = frozenPointerEvent(CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, 72u64, binding, version)
    let aCancel = frozenPointerEvent(CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL, 71u64, binding, version)
    let bEnd = frozenPointerEvent(CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, 72u64, binding, version)
    @Assert(window.dispatchPointerEventForTest(aBegin).didApply, true)
    @Assert(window.dispatchPointerEventForTest(bBegin).didApply, true)
    @Assert(countPointerPhase(controller.phases, CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL), 1)
    let _ = window.dispatchPointerEventForTest(aCancel)
    @Assert(countPointerPhase(controller.phases, CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL), 1)
    @Assert(window.dispatchPointerEventForTest(bEnd).didApply, true)
    @Assert(countPointerPhase(controller.phases, CJGUI_COMPOSABLE_UI_EVENT_POINTER_END), 1)
    let _ = window.dispatchPointerEventForTest(aCancel)
    @Assert(countPointerPhase(controller.phases, CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL), 1)
    window.close()
}

@Test
func acceptedBindingAbaRejectsOldPointerBeforeController(): Unit {
    let controller = GestureTerminalController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let firstVersion = window.windowProgress().acceptedSceneVersion
    let firstEpoch = window.acceptedBindingEpochForTest(801)
    @Assert(firstEpoch != 0u64, true)
    controller.invalidDuplicate = true
    controller.fieldId = "REJECTED"
    controller.revision += 1
    let _ = window.refresh()
    @Assert(window.acceptedBindingEpochForTest(801), firstEpoch)
    controller.invalidDuplicate = false
    controller.fieldId = "B"
    controller.revision += 1
    @Assert(window.refresh(), true)
    let secondEpoch = window.acceptedBindingEpochForTest(801)
    @Assert(secondEpoch != firstEpoch, true)
    controller.fieldId = "A"
    controller.revision += 1
    @Assert(window.refresh(), true)
    let restoredEpoch = window.acceptedBindingEpochForTest(801)
    @Assert(restoredEpoch != firstEpoch && restoredEpoch != secondEpoch, true)

    let stale = frozenPointerEvent(CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, 73u64,
        firstEpoch, firstVersion)
    @Assert(window.dispatchPointerEventForTest(stale).didApply, false)
    @Assert(controller.phases.size, 0)
    window.close()
}

@Test
func acceptedBindingEpochSurvivesSameBindingGeometryChange(): Unit {
    let controller = GestureTerminalController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let initialVersion = window.windowProgress().acceptedSceneVersion
    let bindingEpoch = window.acceptedBindingEpochForTest(801)
    @Assert(bindingEpoch != 0u64, true)

    controller.targetOffsetY = 12
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().acceptedSceneVersion > initialVersion, true)
    @Assert(window.acceptedBindingEpochForTest(801), bindingEpoch)
    window.close()
}
