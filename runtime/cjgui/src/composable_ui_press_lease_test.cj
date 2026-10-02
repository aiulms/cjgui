package cjgui

import std.collection.*
import std.time.*

foreign {
    func cjgui_internal_renderer_test_send_composable_mouse(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>,
        outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_send_composable_key(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, outFocusedNodeId: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
        session: UInt64, nodeId: UInt64
    ): Int32
    func cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session: UInt64): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
}

private class PressLeaseBooleanController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    private var checkedValue: Bool = false
    private var booleanEventCountValue: Int64 = 0
    private var writeCountValue: Int64 = 0
    private var rejectedBooleanEventCountValue: Int64 = 0
    private var bindingVariant: Int64 = 0
    private var incarnationValue: Int64 = 1
    private var paintVariant: Int64 = 0
    private var enabledValue: Bool = true
    private var presentValue: Bool = true
    private var scopeVariant: Int64 = 0
    private var offsetXValue: Int64 = 0
    private var clipWidthValue: Int64 = 180

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let actionName = if (bindingVariant == 0) { "TOGGLE_A" } else { "TOGGLE_B" }
        let fieldId = if (bindingVariant == 0) { "flag_a" } else { "flag_b" }
        let inputScope = if (scopeVariant == 0) { "scope-a" } else { "scope-b" }
        let background = if (paintVariant == 0) {
            CjguiComposableUiColor(0.08, 0.12, 0.20, 1.0)
        } else {
            CjguiComposableUiColor(0.12, 0.20, 0.08, 1.0)
        }
        let root = cjguiComposableVertical(7200, "press-lease-root",
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 50))
        let clipped = cjguiComposableVertical(7204, "press-lease-clip",
            CjguiComposableUiStyle(fixedWidth: clipWidthValue, fixedHeight: 40, clipsContent: true))
        if (presentValue) {
            clipped.add(CjguiComposableUiNode(7201, "press-lease-checkbox", CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT,
                "enabled", if (checkedValue) { "true" } else { "false" }, actionName, 7202,
                CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 30, background: background,
                    offsetX: offsetXValue),
                enabled: enabledValue, fieldId: fieldId, operationActionName: "WRITE_BOOLEAN",
                operationResourceId: 7203, inputScopeId: inputScope,
                interactionStyle: CjguiComposableUiInteractionStyle(
                    pressed: CjguiComposableUiPaintStyle(
                        background: Some(CjguiComposableUiColor(0.96, 0.02, 0.96, 1.0)))),
                semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX,
                semanticKey: "press-lease-checkbox", semanticIncarnation: incarnationValue))
        }
        root.add(clipped)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED) {
            booleanEventCountValue += 1
            let expectedAction = if (bindingVariant == 0) { "TOGGLE_A" } else { "TOGGLE_B" }
            let expectedField = if (bindingVariant == 0) { "flag_a" } else { "flag_b" }
            if (event.node.actionName == expectedAction && event.node.fieldId == expectedField &&
                event.node.operationActionName == "WRITE_BOOLEAN" && event.node.operationResourceId == 7203) {
                checkedValue = event.text == "true"
                writeCountValue += 1
                return CjguiComposableUiDispatchResult(true)
            }
            rejectedBooleanEventCountValue += 1
        }
        // In particular, focus event 31 is observable without changing the
        // owner revision or the Boolean value.
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        if (eventKind == CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED) {
            rejectedBooleanEventCountValue += 1
        }
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func booleanEventCount(): Int64 { return booleanEventCountValue }
    public func writeCount(): Int64 { return writeCountValue }
    public func rejectedBooleanEventCount(): Int64 { return rejectedBooleanEventCountValue }
    public func checked(): Bool { return checkedValue }
    public func incarnation(): Int64 { return incarnationValue }
    public func rebindBooleanAction(): Unit { bindingVariant = 1; revision += 1 }
    public func advanceIncarnation(next: Int64): Unit { incarnationValue = next; revision += 1 }
    public func changeAcceptedPaint(): Unit { paintVariant = 1; revision += 1 }
    public func setEnabled(enabled: Bool): Unit { enabledValue = enabled; revision += 1 }
    public func setPresent(present: Bool): Unit { presentValue = present; revision += 1 }
    public func advanceInputScope(next: Int64): Unit { scopeVariant = next; revision += 1 }
    public func setOwnerValue(value: Bool): Unit { checkedValue = value; revision += 1 }
    public func translateTarget(nextX: Int64): Unit { offsetXValue = nextX; revision += 1 }
    public func changeClipWidth(nextWidth: Int64): Unit { clipWidthValue = nextWidth; revision += 1 }
}

private func pressLeaseRequestPixel(session: UInt64, x!: UInt32 = 70u32, y!: UInt32 = 25u32): Bool {
    return unsafe {
        cjgui_internal_renderer_test_request_composable_drawable_pixel(session, x, y)
    } == 0
}

private func pressLeasePressedPixelRemains(session: UInt64, x!: UInt32 = 70u32, y!: UInt32 = 25u32): Bool {
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let status = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout blue, inout green,
            inout red, inout alpha)
    }
    @Assert(status, 0)
    return status == 0 && alpha > 0u8 && red > 200u8 && blue > 200u8 && green < 60u8
}

@Test
func composableBooleanPressCompletesAcrossAnAcceptedPaint(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let acceptedOnce = down == 0 && downTurn.isOpen && up == 0 && upTurn.isOpen &&
            controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(acceptedOnce, true)
    } finally { window.close() }
}

@Test
func composableBooleanQueuedTerminalSurvivesAcceptedSceneAdvance(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let acceptedBeforeDown = window.displayedSceneVersion()
        let acceptedProjectionBefore = window.acceptedSceneDump()
        let incarnationBefore = controller.incarnation()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pumpEventsWithoutRefresh(0u32)
        let oldVersionRetained = down == 0 && downTurn.isOpen &&
            window.displayedSceneVersion() == acceptedBeforeDown && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked()
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        // This is a paint-only owner revision: it advances the accepted scene
        // while preserving checkbox identity, binding, value and geometry.
        controller.changeAcceptedPaint()
        let acceptedRefresh = window.refreshAfterDeferredPump()
        let acceptedAfterRefresh = window.displayedSceneVersion()
        let advancedExactlyOnce = acceptedRefresh && acceptedAfterRefresh == acceptedBeforeDown + 1
        let acceptedProjectionAfter = window.acceptedSceneDump()
        let projectionStableAcrossPaint = acceptedProjectionAfter == acceptedProjectionBefore &&
            controller.incarnation() == incarnationBefore && !controller.checked()
        @Assert(projectionStableAcrossPaint, true)
        let pixelRequested = pressLeaseRequestPixel(session)
        let upTurn = window.pump(0u32)
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let oneBooleanWrite = controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(controller.rejectedBooleanEventCount(), 0)
        let completed = oldVersionRetained && up == 0 && advancedExactlyOnce && pixelRequested && upTurn.isOpen &&
            oneBooleanWrite && !pressedRemains
        @Assert(completed, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotFollowReboundAction(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.rebindBooleanAction()
        let reboundAccepted = window.refreshIfNeeded()
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let replacementUnaffected = down == 0 && downTurn.isOpen && reboundAccepted && up == 0 && upTurn.isOpen &&
            controller.booleanEventCount() == 0 && controller.writeCount() == 0 && !controller.checked()
        @Assert(replacementUnaffected, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotReviveAfterIncarnationAba(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.advanceIncarnation(2)
        let acceptedB = window.refreshIfNeeded()
        controller.advanceIncarnation(1)
        let acceptedAAgain = window.refreshIfNeeded()
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let oldPressRevived = down == 0 && downTurn.isOpen && acceptedB && acceptedAAgain && up == 0 && upTurn.isOpen &&
            controller.booleanEventCount() == 0 && controller.writeCount() == 0 && !controller.checked()
        @Assert(oldPressRevived, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotReviveAfterDisableEnable(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.setEnabled(false)
        let disabledAccepted = window.refreshIfNeeded()
        controller.setEnabled(true)
        let pixelRequested = pressLeaseRequestPixel(session)
        let enabledAccepted = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let disabledPressStayedDead = down == 0 && downTurn.isOpen && disabledAccepted && enabledAccepted &&
            pixelRequested && !pressedRemains && up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked()
        @Assert(disabledPressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotReviveAfterRemoveReadd(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.setPresent(false)
        let removedAccepted = window.refreshIfNeeded()
        controller.setPresent(true)
        let pixelRequested = pressLeaseRequestPixel(session)
        let readdedAccepted = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let removedPressStayedDead = down == 0 && downTurn.isOpen && removedAccepted && readdedAccepted && pixelRequested &&
            !pressedRemains && up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 && controller.writeCount() == 0 &&
            !controller.checked()
        @Assert(removedPressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotReviveAfterInputScopeAba(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.advanceInputScope(1)
        let acceptedB = window.refreshIfNeeded()
        controller.advanceInputScope(0)
        let pixelRequested = pressLeaseRequestPixel(session)
        let acceptedAAgain = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let scopePressStayedDead = down == 0 && downTurn.isOpen && acceptedB && acceptedAAgain && pixelRequested &&
            !pressedRemains && up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked()
        @Assert(scopePressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotReviveAfterOwnerValueAba(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.setOwnerValue(true)
        let acceptedB = window.refreshIfNeeded()
        controller.setOwnerValue(false)
        let pixelRequested = pressLeaseRequestPixel(session)
        let acceptedAAgain = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let valuePressStayedDead = down == 0 && downTurn.isOpen && acceptedB && acceptedAAgain && pixelRequested &&
            !pressedRemains && up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked()
        @Assert(valuePressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotFollowTranslatedTarget(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.translateTarget(100)
        let pixelRequested = pressLeaseRequestPixel(session, x: 150u32, y: 15u32)
        let translatedAccepted = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session, x: 150u32, y: 15u32)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let translatedPressStayedDead = down == 0 && downTurn.isOpen && translatedAccepted && pixelRequested &&
            !pressedRemains && up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked()
        @Assert(translatedPressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanPressDoesNotCrossChangedClip(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        controller.changeClipWidth(10)
        let pixelRequested = pressLeaseRequestPixel(session, x: 5u32, y: 15u32)
        let clipAccepted = window.refreshIfNeeded()
        let pressedRemains = pressLeasePressedPixelRemains(session, x: 5u32, y: 15u32)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let clippedPressStayedDead = down == 0 && downTurn.isOpen && clipAccepted && pixelRequested && !pressedRemains &&
            up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 && controller.writeCount() == 0 &&
            !controller.checked()
        @Assert(down, 0)
        @Assert(clipAccepted, true)
        @Assert(pixelRequested, true)
        @Assert(up, 0)
        @Assert(controller.booleanEventCount(), 0)
        @Assert(controller.writeCount(), 0)
        @Assert(pressedRemains, false)
        @Assert(clippedPressStayedDead, true)
    } finally { window.close() }
}

@Test
func composableBooleanNativeCancelEndsPressWithoutBooleanWrite(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let cancel = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 4u32, 20.0f32, 15.0f32) }
        let pixelRequested = pressLeaseRequestPixel(session)
        let cancelTurn = window.pump(0u32)
        let pressedRemains = pressLeasePressedPixelRemains(session)
        let cancelled = down == 0 && downTurn.isOpen && cancel == 0 && pixelRequested && cancelTurn.isOpen &&
            controller.booleanEventCount() == 0 && controller.writeCount() == 0 && !controller.checked() && !pressedRemains
        @Assert(cancelled, true)
    } finally { window.close() }
}

@Test
func composableBooleanRepeatedNativeMouseUpWritesOnlyOnce(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let firstUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let repeatedUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let firstTurn = window.pump(0u32)
        let secondTurn = window.pump(0u32)
        let oneWrite = down == 0 && downTurn.isOpen && firstUp == 0 && repeatedUp == 0 && firstTurn.isOpen &&
            firstTurn.didApplyHumanAction && secondTurn.isOpen && !secondTurn.didApplyHumanAction &&
            controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(oneWrite, true)
    } finally { window.close() }
}

@Test
func composableBooleanAccessibilityPressRemainsIndependentOfPointerLease(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let capture = unsafe {
            cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(session, 7201u64)
        }
        let invoke = unsafe { cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session) }
        let turn = window.pump(0u32)
        let axActivatedOnce = capture == 0 && invoke == 0 && turn.isOpen && turn.didApplyHumanAction &&
            controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(axActivatedOnce, true)
    } finally { window.close() }
}

@Test
func composableBooleanKeyboardPressRemainsIndependentOfPointerLease(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let focused = window.focusAcceptedNodeById(7201)
        var focusedNodeId: UInt64 = 0u64
        let keyStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_key(session, 49u16, 0u64, inout focusedNodeId)
        }
        let turn = window.pump(0u32)
        let keyboardActivatedOnce = focused && keyStatus == 0 && focusedNodeId == 7201u64 && turn.isOpen &&
            controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(keyboardActivatedOnce, true)
    } finally { window.close() }
}

@Test
func composableBooleanRejectedClipCandidateKeepsOriginalPressLive(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let acceptedBeforeDown = window.displayedSceneVersion()
        let downPixelRequested = pressLeaseRequestPixel(session)
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let oldPressVisible = pressLeasePressedPixelRemains(session)
        let acceptedPressVersion = window.displayedSceneVersion()
        let acceptedPressProjection = window.acceptedSceneDump()
        let armFailure = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32) }
        controller.changeClipWidth(10)
        let rejectedClipCandidate = !window.refreshIfNeeded()
        let rejectedCandidateKeptAcceptedPress = downPixelRequested && down == 0 && downTurn.isOpen && oldPressVisible &&
            acceptedPressVersion > acceptedBeforeDown && rejectedClipCandidate && armFailure == 0 &&
            window.displayedSceneVersion() == acceptedPressVersion &&
            window.acceptedSceneDump() == acceptedPressProjection && window.nativeStatus() != 0 &&
            controller.booleanEventCount() == 0 && controller.writeCount() == 0 && !controller.checked()
        // No refresh is inserted here: release at the still accepted geometry
        // must consume the lease retained across the rejected candidate.
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        let originalAcceptedPressCompleted = up == 0 && upTurn.isOpen && upTurn.didApplyHumanAction &&
            controller.booleanEventCount() == 1 && controller.writeCount() == 1 && controller.checked()
        @Assert(rejectedCandidateKeptAcceptedPress, true)
        @Assert(originalAcceptedPressCompleted, true)
    } finally { window.close() }
}

@Test
func composableBooleanPendingClipKeepsThenClearsPressOnFirstAcceptedFrame(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let acceptedBeforeDown = window.displayedSceneVersion()
        let downPixelRequested = pressLeaseRequestPixel(session)
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let originalPressedFrame = pressLeasePressedPixelRemains(session)
        let acceptedPressVersion = window.displayedSceneVersion()
        let acceptedPressProjection = window.acceptedSceneDump()
        let held = internalRendererTestHoldNextComposablePresent(session)
        controller.changeClipWidth(10)
        let pendingRefresh = !window.refreshIfNeeded()
        let pendingKeptOriginalPress = held == 0 && pendingRefresh &&
            window.nativeStatus() == CJGUI_INTERNAL_RENDERER_PRESENT_PENDING &&
            window.displayedSceneVersion() == acceptedPressVersion &&
            window.acceptedSceneDump() == acceptedPressProjection && originalPressedFrame &&
            controller.booleanEventCount() == 0 && controller.writeCount() == 0 && !controller.checked()
        @Assert(downPixelRequested && down == 0 && downTurn.isOpen && acceptedPressVersion > acceptedBeforeDown, true)
        @Assert(pendingKeptOriginalPress, true)

        // Ask the native accepted clip frame to capture this pixel. The
        // resolve call performs that frame; core settlement below must not be
        // followed by another pump before the pixel is read.
        let acceptedPixelRequested = pressLeaseRequestPixel(session, x: 5u32, y: 15u32)
        let resolved = internalRendererTestResolvePendingComposablePresent(session)
        let settled = !window.refreshIfNeeded()
        let acceptedClipFrame = resolved == 0 && settled && window.displayedSceneVersion() > acceptedPressVersion &&
            window.acceptedSceneDump() != acceptedPressProjection
        let pressedOnFirstAcceptedClipFrame = pressLeasePressedPixelRemains(session, x: 5u32, y: 15u32)
        @Assert(acceptedPixelRequested && acceptedClipFrame, true)
        @Assert(pressedOnFirstAcceptedClipFrame, false)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        @Assert(up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked(), true)
    } finally { window.close() }
}

@Test
func composableBooleanPositionAnimationClearsPressInItsAcceptedFrame(): Unit {
    let controller = PressLeaseBooleanController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let _ = window.setReduceMotionEnabled(true)
        let session = window.testSessionToken()
        let downPixelRequested = pressLeaseRequestPixel(session)
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, 20.0f32, 15.0f32) }
        let downTurn = window.pump(0u32)
        let oldPressVisible = pressLeasePressedPixelRemains(session)
        let acceptedPressVersion = window.displayedSceneVersion()
        let animationStart = MonoTime.now()
        // Reduce-motion makes the position request present its target in this
        // call, and the pressed colour has no transition waiting period.
        let movedPixelRequested = pressLeaseRequestPixel(session, x: 100u32, y: 15u32)
        let animationStarted = window.animateNodeTranslation("semantic:press-lease-checkbox", 80.0, 0.0,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 1000), atTime: animationStart)
        let movedFrame = window.displayedSceneVersion() > acceptedPressVersion &&
            if (let Some(bounds) <- window.acceptedNodeVisualBounds("press-lease-checkbox")) {
                bounds.x == 80.0
            } else { false }
        let pressedOnMovedFrame = pressLeasePressedPixelRemains(session, x: 100u32, y: 15u32)
        @Assert(downPixelRequested && down == 0 && downTurn.isOpen && oldPressVisible, true)
        @Assert(animationStarted && movedPixelRequested && movedFrame, true)
        // This pixel belongs to the accepted interaction-only position frame;
        // inspect it before any pump or later animation frame.
        @Assert(pressedOnMovedFrame, false)
        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, 20.0f32, 15.0f32) }
        let upTurn = window.pump(0u32)
        @Assert(up == 0 && upTurn.isOpen && controller.booleanEventCount() == 0 &&
            controller.writeCount() == 0 && !controller.checked(), true)
    } finally { window.close() }
}

private class PressLeaseNativeTabsController <: CjguiComposableUiController {
    var tabs = CjguiComposableUiTabsState("basic")
    private var revision: Int64 = 1

    public func uiSceneVersion(): Int64 { return revision }

    public func replaceTabs(state: CjguiComposableUiTabsState): Unit {
        tabs = state
        revision += 1
    }

    public func buildUi(): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("press-lease-native-tabs")
        let basic = cjguiComposableVertical(7301, "press-lease-tabs-basic", CjguiComposableUiStyle(gap: 4))
        basic.add(cjguiComposableText(7302, "press-lease-tabs-basic-line", "Basic page",
            CjguiComposableUiStyle(fontSize: 13.0)))
        let advanced = cjguiComposableVertical(7303, "press-lease-tabs-advanced", CjguiComposableUiStyle(gap: 4))
        advanced.add(cjguiComposableText(7304, "press-lease-tabs-advanced-line", "Advanced page",
            CjguiComposableUiStyle(fontSize: 13.0)))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "Basic", basic))
        pages.add(CjguiComposableUiTabPage("advanced", "Advanced", advanced))
        let tabsNode = cjguiComposableTabs(scope, "press-lease-native-tabs", pages, tabs,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 120, growX: 1, growY: 1), titleHeight: 30)
        let root = cjguiComposableVertical(7300, "press-lease-native-tabs-root",
            CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 140, gap: 2))
        root.add(tabsNode)
        root.add(cjguiComposableText(7305, "press-lease-tabs-stable", "unrelated stable node",
            CjguiComposableUiStyle(fixedHeight: 12)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func pressLeaseTabAcceptedNode(
    window: CjguiComposableUiWindow, semanticId: String
): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) { return node }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private func pressLeaseRenderedTabsOwner(window: CjguiComposableUiWindow): Int64 {
    let title = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
    if (title.nodeId < 0) { return 0 }
    if (let Some(state) <- title.tabsState) { return state.viewStateIdentity() }
    return 0
}

/// Pointer activation must traverse the production native queue: down (45),
/// up (46), then the native ACTIVATE event (27) must switch and accept a page.
@Test
func composableTabNativeMouseUpActivatesAndAcceptsExactlyOnePage(): Unit {
    let controller = PressLeaseNativeTabsController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        let advancedTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        @Assert(advancedTitle.nodeId > 0 && advancedTitle.isTabTitle() && advancedTitle.isEnabled, true)
        let x = Float32(advancedTitle.bounds.x + advancedTitle.bounds.width / 2)
        let y = Float32(advancedTitle.bounds.y + advancedTitle.bounds.height / 2)
        let session = window.testSessionToken()

        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        @Assert(down == 0 && downTurn.isOpen && !downTurn.didApplyHumanAction, true)
        @Assert(controller.tabs.activeKey(), "basic")

        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let upTurn = window.pump(0u32)
        let advancedPage = pressLeaseTabAcceptedNode(window, "press-lease-tabs-advanced")
        let advancedBody = pressLeaseTabAcceptedNode(window, "press-lease-tabs-advanced-line")
        let basicPage = pressLeaseTabAcceptedNode(window, "press-lease-tabs-basic")
        let basicBody = pressLeaseTabAcceptedNode(window, "press-lease-tabs-basic-line")
        var activationCount = 0
        if (downTurn.didApplyHumanAction) { activationCount += 1 }
        if (upTurn.didApplyHumanAction) { activationCount += 1 }

        @Assert(up == 0 && upTurn.isOpen, true)
        @Assert(activationCount, 1)
        @Assert(controller.tabs.activeKey(), "advanced")
        @Assert(advancedPage.nodeId > 0 && advancedPage.tabsPageActive, true)
        @Assert(advancedBody.nodeId > 0 && advancedBody.bounds.height > 0, true)
        // Hidden page roots remain with an empty rectangle, while their
        // descendants are absent from the accepted scene.
        @Assert(basicPage.nodeId > 0 && !basicPage.tabsPageActive, true)
        @Assert(basicPage.bounds.height, 0)
        @Assert(basicBody.nodeId < 0, true)
    } finally { window.close() }
}

/// Replacing the tab view-state owner invalidates an in-flight pointer lease,
/// even when every title keeps the same semantic identity and geometry.
@Test
func composableTabNativeMouseUpDoesNotCrossViewStateOwnerReplacement(): Unit {
    let controller = PressLeaseNativeTabsController()
    let oldOwner = controller.tabs
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let oldTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let stableNodeId = pressLeaseTabAcceptedNode(window, "press-lease-tabs-stable").nodeId
        let (initialInputOwner, initialEpoch, initialLeaseValid) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        let x = Float32(oldTitle.bounds.x + oldTitle.bounds.width / 2)
        let y = Float32(oldTitle.bounds.y + oldTitle.bounds.height / 2)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        let (downInputOwner, downEpoch, downLeaseValid) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let newOwner = CjguiComposableUiTabsState("basic")
        controller.replaceTabs(newOwner)
        let bAccepted = window.refresh()
        let reboundTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let (reboundInputOwner, reboundEpoch, reboundLeaseValid) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let upTurn = window.pump(0u32)
        let (finalInputOwner, finalEpoch, finalLeaseValid) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        let sameGeometry = reboundTitle.nodeId == oldTitle.nodeId &&
            reboundTitle.bounds.x == oldTitle.bounds.x && reboundTitle.bounds.y == oldTitle.bounds.y &&
            reboundTitle.bounds.width == oldTitle.bounds.width && reboundTitle.bounds.height == oldTitle.bounds.height
        println("CJGUI_TAB_OWNER_REPLACEMENT old=${oldOwner.viewStateIdentity()}:${oldOwner.activeKey()} " +
            "new=${newOwner.viewStateIdentity()}:${newOwner.activeKey()} up=${up} native=${window.nativeStatus()} " +
            "open=${upTurn.isOpen} applied=${upTurn.didApplyHumanAction} accepted=${controller.tabs.activeKey()} " +
            "input_owner=${finalInputOwner} epoch=${finalEpoch} lease=${finalLeaseValid} " +
            "initial=${initialInputOwner}/${initialEpoch}/${initialLeaseValid} " +
            "down=${down}/${downInputOwner}/${downEpoch}/${downLeaseValid} " +
            "accepted_b=${bAccepted}/${reboundInputOwner}/${reboundEpoch}/${reboundLeaseValid} " +
            "same_geom=${sameGeometry} stable_node=${stableNodeId}")
        @Assert(initialInputOwner, oldOwner.viewStateIdentity())
        @Assert(initialEpoch > 0u64, true)
        @Assert(initialLeaseValid, false)
        @Assert(down, 0)
        @Assert(downTurn.isOpen, true)
        @Assert(downTurn.didApplyHumanAction, false)
        @Assert(downInputOwner, oldOwner.viewStateIdentity())
        @Assert(downEpoch, initialEpoch)
        @Assert(downLeaseValid, true)
        @Assert(bAccepted, true)
        @Assert(reboundTitle.nodeId == oldTitle.nodeId &&
            reboundTitle.bounds.x == oldTitle.bounds.x && reboundTitle.bounds.y == oldTitle.bounds.y &&
            reboundTitle.bounds.width == oldTitle.bounds.width && reboundTitle.bounds.height == oldTitle.bounds.height, true)
        @Assert(reboundInputOwner, newOwner.viewStateIdentity())
        @Assert(reboundEpoch > downEpoch, true)
        @Assert(reboundLeaseValid, false)
        @Assert(finalInputOwner, newOwner.viewStateIdentity())
        @Assert(finalEpoch, reboundEpoch)
        @Assert(finalLeaseValid, false)
        @Assert(oldOwner.viewStateIdentity() != newOwner.viewStateIdentity(), true)
        @Assert(up, 0)
        @Assert(window.nativeStatus(), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(upTurn.isOpen, true)
        @Assert(upTurn.didApplyHumanAction, false)
        @Assert(oldOwner.activeKey(), "basic")
        @Assert(newOwner.activeKey(), "basic")
        @Assert(controller.tabs.activeKey(), "basic")
        @Assert(pressLeaseTabAcceptedNode(window, "press-lease-tabs-advanced").tabsPageActive, false)
    } finally { window.close() }
}

/// An accepted A→B→A owner sequence does not revive the press captured under
/// the first accepted A, even though the final declarative identity is equal.
@Test
func composableTabNativeMouseUpDoesNotReviveAcrossViewStateOwnerAba(): Unit {
    let controller = PressLeaseNativeTabsController()
    let firstOwner = controller.tabs
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let firstTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let stableNodeId = pressLeaseTabAcceptedNode(window, "press-lease-tabs-stable").nodeId
        let (firstInputOwner, firstEpoch, firstLeaseValid) = window.testAcceptedTabsBinding(firstTitle.nodeId)
        let x = Float32(firstTitle.bounds.x + firstTitle.bounds.width / 2)
        let y = Float32(firstTitle.bounds.y + firstTitle.bounds.height / 2)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        let (downInputOwner, downEpoch, downLeaseValid) = window.testAcceptedTabsBinding(firstTitle.nodeId)

        let secondOwner = CjguiComposableUiTabsState("basic")
        controller.replaceTabs(secondOwner)
        let bAccepted = window.refresh()
        let middleTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let (middleInputOwner, middleEpoch, middleLeaseValid) = window.testAcceptedTabsBinding(firstTitle.nodeId)

        controller.replaceTabs(firstOwner)
        let aReturned = window.refresh()
        let finalTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let (finalAcceptedInputOwner, finalEpochBeforeUp, finalLeaseBeforeUp) =
            window.testAcceptedTabsBinding(firstTitle.nodeId)

        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let upTurn = window.pump(0u32)
        let (finalInputOwner, finalEpoch, finalLeaseValid) = window.testAcceptedTabsBinding(firstTitle.nodeId)
        let sameGeometry = middleTitle.nodeId == firstTitle.nodeId && finalTitle.nodeId == firstTitle.nodeId &&
            middleTitle.bounds.x == firstTitle.bounds.x && middleTitle.bounds.y == firstTitle.bounds.y &&
            middleTitle.bounds.width == firstTitle.bounds.width && middleTitle.bounds.height == firstTitle.bounds.height &&
            finalTitle.bounds.x == firstTitle.bounds.x && finalTitle.bounds.y == firstTitle.bounds.y &&
            finalTitle.bounds.width == firstTitle.bounds.width && finalTitle.bounds.height == firstTitle.bounds.height
        println("CJGUI_TAB_OWNER_ABA first=${firstOwner.viewStateIdentity()}:${firstOwner.activeKey()} " +
            "middle=${secondOwner.viewStateIdentity()}:${secondOwner.activeKey()} final=${controller.tabs.viewStateIdentity()}:" +
            "${controller.tabs.activeKey()} up=${up} native=${window.nativeStatus()} open=${upTurn.isOpen} " +
            "applied=${upTurn.didApplyHumanAction} accepted=${controller.tabs.activeKey()} " +
            "input_owner=${finalInputOwner} epoch=${finalEpoch} lease=${finalLeaseValid} " +
            "initial=${firstInputOwner}/${firstEpoch}/${firstLeaseValid} " +
            "down=${down}/${downInputOwner}/${downEpoch}/${downLeaseValid} " +
            "accepted_b=${bAccepted}/${middleInputOwner}/${middleEpoch}/${middleLeaseValid} " +
            "returned_a=${aReturned}/${finalAcceptedInputOwner}/${finalEpochBeforeUp}/${finalLeaseBeforeUp} " +
            "same_geometry=${sameGeometry} stable_node=${stableNodeId}")
        @Assert(firstInputOwner, firstOwner.viewStateIdentity())
        @Assert(firstEpoch > 0u64, true)
        @Assert(firstLeaseValid, false)
        @Assert(down, 0)
        @Assert(downTurn.isOpen, true)
        @Assert(downTurn.didApplyHumanAction, false)
        @Assert(downInputOwner, firstOwner.viewStateIdentity())
        @Assert(downEpoch, firstEpoch)
        @Assert(downLeaseValid, true)
        @Assert(bAccepted, true)
        @Assert(middleTitle.nodeId == firstTitle.nodeId && middleTitle.bounds.x == firstTitle.bounds.x &&
            middleTitle.bounds.y == firstTitle.bounds.y && middleTitle.bounds.width == firstTitle.bounds.width &&
            middleTitle.bounds.height == firstTitle.bounds.height, true)
        @Assert(middleInputOwner, secondOwner.viewStateIdentity())
        @Assert(middleEpoch > downEpoch, true)
        @Assert(middleLeaseValid, false)
        @Assert(aReturned, true)
        @Assert(finalTitle.nodeId == firstTitle.nodeId && finalTitle.bounds.x == firstTitle.bounds.x &&
            finalTitle.bounds.y == firstTitle.bounds.y && finalTitle.bounds.width == firstTitle.bounds.width &&
            finalTitle.bounds.height == firstTitle.bounds.height, true)
        @Assert(finalAcceptedInputOwner, firstOwner.viewStateIdentity())
        @Assert(finalEpochBeforeUp > middleEpoch, true)
        @Assert(finalLeaseBeforeUp, false)
        @Assert(finalInputOwner, firstOwner.viewStateIdentity())
        @Assert(finalEpoch, finalEpochBeforeUp)
        @Assert(finalLeaseValid, false)
        @Assert(firstOwner.viewStateIdentity() != secondOwner.viewStateIdentity(), true)
        @Assert(up, 0)
        @Assert(window.nativeStatus(), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(upTurn.isOpen, true)
        @Assert(upTurn.didApplyHumanAction, false)
        @Assert(firstOwner.activeKey(), "basic")
        @Assert(secondOwner.activeKey(), "basic")
        @Assert(controller.tabs.activeKey(), "basic")
        @Assert(pressLeaseTabAcceptedNode(window, "press-lease-tabs-advanced").tabsPageActive, false)
    } finally { window.close() }
}

/// A rejected synchronous B candidate cannot revoke A's accepted physical
/// press. The old release must still write A exactly once.
@Test
func composableTabRejectedOwnerCandidateKeepsAcceptedPressLive(): Unit {
    let controller = PressLeaseNativeTabsController()
    let oldOwner = controller.tabs
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let oldTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let stableNodeId = pressLeaseTabAcceptedNode(window, "press-lease-tabs-stable").nodeId
        let x = Float32(oldTitle.bounds.x + oldTitle.bounds.width / 2)
        let y = Float32(oldTitle.bounds.y + oldTitle.bounds.height / 2)
        let session = window.testSessionToken()
        let acceptedBeforeDown = window.displayedSceneVersion()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        let acceptedAfterDown = window.displayedSceneVersion()
        let acceptedPressProjection = window.acceptedSceneDump()
        let (ownerAfterDown, epochAfterDown, leaseAfterDown) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let newOwner = CjguiComposableUiTabsState("basic")
        let armFailure = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32) }
        controller.replaceTabs(newOwner)
        let rejectedB = !window.refreshIfNeeded()
        let rejectedNativeStatus = window.nativeStatus()
        let versionAfterReject = window.displayedSceneVersion()
        let projectionAfterReject = window.acceptedSceneDump()
        let (ownerAfterReject, epochAfterReject, leaseAfterReject) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let upTurn = window.pump(0u32)
        let (ownerAfterUp, epochAfterUp, leaseAfterUp) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        println("CJGUI_TAB_OWNER_SYNC_REJECT old=${oldOwner.viewStateIdentity()}:${oldOwner.activeKey()} " +
            "new=${newOwner.viewStateIdentity()}:${newOwner.activeKey()} arm=${armFailure} rejected=${rejectedB} " +
            "reject_status=${rejectedNativeStatus} before=${acceptedBeforeDown} down=${down}/${downTurn.isOpen}/" +
            "${downTurn.didApplyHumanAction}/${acceptedAfterDown}/${ownerAfterDown}/${epochAfterDown}/${leaseAfterDown} " +
            "held=${versionAfterReject}/${ownerAfterReject}/${epochAfterReject}/${leaseAfterReject} " +
            "up=${up} native=${window.nativeStatus()} open=${upTurn.isOpen} applied=${upTurn.didApplyHumanAction} " +
            "after=${ownerAfterUp}/${epochAfterUp}/${leaseAfterUp} render_owner=${pressLeaseRenderedTabsOwner(window)} " +
            "stable_node=${stableNodeId}")

        @Assert(down, 0)
        @Assert(downTurn.isOpen, true)
        @Assert(downTurn.didApplyHumanAction, false)
        @Assert(acceptedAfterDown > acceptedBeforeDown, true)
        @Assert(ownerAfterDown, oldOwner.viewStateIdentity())
        @Assert(epochAfterDown > 0u64, true)
        @Assert(leaseAfterDown, true)
        @Assert(armFailure, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(rejectedB, true)
        @Assert(rejectedNativeStatus, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
        @Assert(versionAfterReject, acceptedAfterDown)
        @Assert(projectionAfterReject, acceptedPressProjection)
        @Assert(ownerAfterReject, oldOwner.viewStateIdentity())
        @Assert(epochAfterReject, epochAfterDown)
        @Assert(leaseAfterReject, true)
        @Assert(up, 0)
        @Assert(upTurn.isOpen, true)
        @Assert(upTurn.didApplyHumanAction, true)
        @Assert(oldOwner.activeKey(), "advanced")
        @Assert(newOwner.activeKey(), "basic")
        @Assert(controller.tabs.activeKey(), "basic")
        @Assert(ownerAfterUp, newOwner.viewStateIdentity())
        @Assert(epochAfterUp > epochAfterReject, true)
        @Assert(leaseAfterUp, false)
    } finally { window.close() }
}

/// While B is held PENDING, neither its owner binding nor epoch is accepted.
/// Rejecting that saved B after the controller returns to A must retain A's
/// lease and let the original release complete A.
@Test
func composableTabRejectedPendingOwnerCandidateKeepsAcceptedPressLive(): Unit {
    let controller = PressLeaseNativeTabsController()
    let oldOwner = controller.tabs
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let oldTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let stableNodeId = pressLeaseTabAcceptedNode(window, "press-lease-tabs-stable").nodeId
        let x = Float32(oldTitle.bounds.x + oldTitle.bounds.width / 2)
        let y = Float32(oldTitle.bounds.y + oldTitle.bounds.height / 2)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        let acceptedPressVersion = window.displayedSceneVersion()
        let acceptedPressProjection = window.acceptedSceneDump()
        let (ownerAfterDown, epochAfterDown, leaseAfterDown) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let newOwner = CjguiComposableUiTabsState("basic")
        let held = window.testHoldNextComposablePresent()
        controller.replaceTabs(newOwner)
        let submittedPendingB = !window.refreshIfNeeded()
        let pendingStatus = window.nativeStatus()
        let versionWhilePending = window.displayedSceneVersion()
        let projectionWhilePending = window.acceptedSceneDump()
        let (ownerWhilePending, epochWhilePending, leaseWhilePending) =
            window.testAcceptedTabsBinding(oldTitle.nodeId)

        // Change the controller back without refreshing. Settlement must apply
        // the exact saved B transaction, then reject it through the native seam.
        controller.replaceTabs(oldOwner)
        let armFailure = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32) }
        let resolveAccepted = window.testResolvePendingComposablePresent()
        let settled = !window.refreshIfNeeded()
        let versionAfterReject = window.displayedSceneVersion()
        let projectionAfterReject = window.acceptedSceneDump()
        let (ownerAfterReject, epochAfterReject, leaseAfterReject) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let up = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let upTurn = window.pump(0u32)
        let (ownerAfterUp, epochAfterUp, leaseAfterUp) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        println("CJGUI_TAB_OWNER_PENDING_REJECT old=${oldOwner.viewStateIdentity()}:${oldOwner.activeKey()} " +
            "new=${newOwner.viewStateIdentity()}:${newOwner.activeKey()} held=${held} pending=${submittedPendingB}/" +
            "${pendingStatus}/${versionWhilePending}/${ownerWhilePending}/${epochWhilePending}/${leaseWhilePending} " +
            "down=${down}/${downTurn.isOpen}/${downTurn.didApplyHumanAction}/${ownerAfterDown}/${epochAfterDown}/${leaseAfterDown} " +
            "resolve=${resolveAccepted} arm=${armFailure} settled=${settled} reject=${versionAfterReject}/" +
            "${ownerAfterReject}/${epochAfterReject}/${leaseAfterReject} up=${up} native=${window.nativeStatus()} " +
            "open=${upTurn.isOpen} applied=${upTurn.didApplyHumanAction} after=${ownerAfterUp}/${epochAfterUp}/" +
            "${leaseAfterUp} render_owner=${pressLeaseRenderedTabsOwner(window)} stable_node=${stableNodeId}")

        @Assert(down, 0)
        @Assert(downTurn.isOpen, true)
        @Assert(downTurn.didApplyHumanAction, false)
        @Assert(ownerAfterDown, oldOwner.viewStateIdentity())
        @Assert(epochAfterDown > 0u64, true)
        @Assert(leaseAfterDown, true)
        @Assert(held, true)
        @Assert(submittedPendingB, true)
        @Assert(pendingStatus, CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        @Assert(versionWhilePending, acceptedPressVersion)
        @Assert(projectionWhilePending, acceptedPressProjection)
        @Assert(ownerWhilePending, oldOwner.viewStateIdentity())
        @Assert(epochWhilePending, epochAfterDown)
        @Assert(leaseWhilePending, true)
        @Assert(armFailure, CJGUI_INTERNAL_RENDERER_OK)
        @Assert(resolveAccepted, false)
        @Assert(settled, true)
        @Assert(versionAfterReject, acceptedPressVersion)
        @Assert(projectionAfterReject, acceptedPressProjection)
        @Assert(ownerAfterReject, oldOwner.viewStateIdentity())
        @Assert(epochAfterReject, epochAfterDown)
        @Assert(leaseAfterReject, true)
        @Assert(up, 0)
        @Assert(upTurn.isOpen, true)
        @Assert(upTurn.didApplyHumanAction, true)
        @Assert(oldOwner.activeKey(), "advanced")
        @Assert(newOwner.activeKey(), "basic")
        @Assert(ownerAfterUp, oldOwner.viewStateIdentity())
        @Assert(epochAfterUp, epochAfterReject)
        @Assert(leaseAfterUp, false)
    } finally { window.close() }
}

/// A PENDING B transaction is resolved with the saved B object even after the
/// controller returns to A. That accepted boundary revokes the old press, and
/// a fresh press can still operate the final accepted/current A owner.
@Test
func composableTabAcceptedPendingOwnerTransactionRevokesThenAllowsFreshPress(): Unit {
    let controller = PressLeaseNativeTabsController()
    let oldOwner = controller.tabs
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        window.testSetSceneWriteTrace(true)
        let oldTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let stableNodeId = pressLeaseTabAcceptedNode(window, "press-lease-tabs-stable").nodeId
        let x = Float32(oldTitle.bounds.x + oldTitle.bounds.width / 2)
        let y = Float32(oldTitle.bounds.y + oldTitle.bounds.height / 2)
        let session = window.testSessionToken()
        let down = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, x, y) }
        let downTurn = window.pump(0u32)
        let acceptedPressVersion = window.displayedSceneVersion()
        let acceptedPressProjection = window.acceptedSceneDump()
        let (ownerAfterDown, epochAfterDown, leaseAfterDown) = window.testAcceptedTabsBinding(oldTitle.nodeId)

        let newOwner = CjguiComposableUiTabsState("basic")
        let held = window.testHoldNextComposablePresent()
        controller.replaceTabs(newOwner)
        let submittedPendingB = !window.refreshIfNeeded()
        let pendingStatus = window.nativeStatus()
        let versionWhilePending = window.displayedSceneVersion()
        let projectionWhilePending = window.acceptedSceneDump()
        let (ownerWhilePending, epochWhilePending, leaseWhilePending) =
            window.testAcceptedTabsBinding(oldTitle.nodeId)

        // Deliberately restore A before resolving. If settlement reads the
        // controller's latest tree instead of tx.paintScene, accepted owner B
        // and its epoch cannot be observed here.
        controller.replaceTabs(oldOwner)
        let resolveAccepted = window.testResolvePendingComposablePresent()
        let settled = !window.refreshIfNeeded()
        let versionAfterB = window.displayedSceneVersion()
        let projectionAfterB = window.acceptedSceneDump()
        let (ownerAfterB, epochAfterB, leaseAfterB) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        let renderedOwnerAfterB = pressLeaseRenderedTabsOwner(window)
        let sceneUnchangedAcrossOwnerOnlyAccept = projectionAfterB == acceptedPressProjection
        let oldUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, x, y) }
        let oldUpTurn = window.pump(0u32)
        let (ownerAfterOldUp, epochAfterOldUp, leaseAfterOldUp) = window.testAcceptedTabsBinding(oldTitle.nodeId)
        let oldOwnerAfterOldUp = oldOwner.activeKey()
        let newOwnerAfterOldUp = newOwner.activeKey()
        let alignedA = window.refresh()
        let (ownerAfterAlignA, epochAfterAlignA, leaseAfterAlignA) =
            window.testAcceptedTabsBinding(oldTitle.nodeId)
        let alignedRenderedOwnerA = pressLeaseRenderedTabsOwner(window)

        let finalTitle = pressLeaseTabAcceptedNode(window, "press-lease-native-tabs-tab-advanced")
        let finalX = Float32(finalTitle.bounds.x + finalTitle.bounds.width / 2)
        let finalY = Float32(finalTitle.bounds.y + finalTitle.bounds.height / 2)
        let freshDown = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 1u32, finalX, finalY) }
        let freshDownTurn = window.pump(0u32)
        let freshUp = unsafe { cjgui_internal_renderer_test_send_composable_mouse(session, 3u32, finalX, finalY) }
        let freshUpTurn = window.pump(0u32)
        let (ownerAfterFreshUp, epochAfterFreshUp, leaseAfterFreshUp) =
            window.testAcceptedTabsBinding(finalTitle.nodeId)
        println("CJGUI_TAB_OWNER_PENDING_ACCEPT old=${oldOwner.viewStateIdentity()}:${oldOwner.activeKey()} " +
            "new=${newOwner.viewStateIdentity()}:${newOwner.activeKey()} pending=${held}/${submittedPendingB}/" +
            "${pendingStatus}/${versionWhilePending}/${ownerWhilePending}/${epochWhilePending}/${leaseWhilePending} " +
            "down=${down}/${downTurn.isOpen}/${downTurn.didApplyHumanAction}/${ownerAfterDown}/${epochAfterDown}/${leaseAfterDown} " +
            "resolve=${resolveAccepted} settled=${settled} accepted_b=${versionAfterB}/${ownerAfterB}/" +
            "${epochAfterB}/${leaseAfterB}/render${renderedOwnerAfterB} scene_same=${sceneUnchangedAcrossOwnerOnlyAccept} " +
            "old_up=${oldUp}/${oldUpTurn.isOpen}/${oldUpTurn.didApplyHumanAction}/${ownerAfterOldUp}/" +
            "${epochAfterOldUp}/${leaseAfterOldUp}/${oldOwnerAfterOldUp}/${newOwnerAfterOldUp} " +
            "aligned_a=${alignedA}/${ownerAfterAlignA}/${epochAfterAlignA}/${leaseAfterAlignA}/" +
            "render${alignedRenderedOwnerA} fresh=${freshDown}/${freshDownTurn.isOpen}/" +
            "${freshDownTurn.didApplyHumanAction}/${freshUp}/${freshUpTurn.isOpen}/${freshUpTurn.didApplyHumanAction}/" +
            "${ownerAfterFreshUp}/${epochAfterFreshUp}/${leaseAfterFreshUp} final=${oldOwner.activeKey()}/" +
            "${newOwner.activeKey()} stable_node=${stableNodeId}")

        @Assert(down, 0)
        @Assert(downTurn.isOpen, true)
        @Assert(downTurn.didApplyHumanAction, false)
        @Assert(ownerAfterDown, oldOwner.viewStateIdentity())
        @Assert(epochAfterDown > 0u64, true)
        @Assert(leaseAfterDown, true)
        @Assert(held, true)
        @Assert(submittedPendingB, true)
        @Assert(pendingStatus, CJGUI_INTERNAL_RENDERER_PRESENT_PENDING)
        @Assert(versionWhilePending, acceptedPressVersion)
        @Assert(projectionWhilePending, acceptedPressProjection)
        @Assert(ownerWhilePending, oldOwner.viewStateIdentity())
        @Assert(epochWhilePending, epochAfterDown)
        @Assert(leaseWhilePending, true)
        @Assert(resolveAccepted, true)
        @Assert(settled, true)
        @Assert(versionAfterB > acceptedPressVersion, true)
        @Assert(projectionAfterB, acceptedPressProjection)
        @Assert(ownerAfterB, newOwner.viewStateIdentity())
        @Assert(epochAfterB > epochAfterDown, true)
        @Assert(leaseAfterB, false)
        @Assert(renderedOwnerAfterB, newOwner.viewStateIdentity())
        @Assert(controller.tabs.viewStateIdentity(), oldOwner.viewStateIdentity())
        @Assert(oldUp, 0)
        @Assert(oldUpTurn.isOpen, true)
        @Assert(oldUpTurn.didApplyHumanAction, false)
        @Assert(oldOwnerAfterOldUp, "basic")
        @Assert(newOwnerAfterOldUp, "basic")
        @Assert(leaseAfterOldUp, false)
        @Assert(alignedA, true)
        @Assert(ownerAfterAlignA, oldOwner.viewStateIdentity())
        @Assert(epochAfterAlignA > epochAfterB, true)
        @Assert(leaseAfterAlignA, false)
        @Assert(alignedRenderedOwnerA, oldOwner.viewStateIdentity())
        @Assert(freshDown, 0)
        @Assert(freshDownTurn.isOpen, true)
        @Assert(freshDownTurn.didApplyHumanAction, false)
        @Assert(freshUp, 0)
        @Assert(freshUpTurn.isOpen, true)
        @Assert(freshUpTurn.didApplyHumanAction, true)
        @Assert(oldOwner.activeKey(), "advanced")
        @Assert(newOwner.activeKey(), "basic")
        @Assert(ownerAfterFreshUp, oldOwner.viewStateIdentity())
        @Assert(leaseAfterFreshUp, false)
    } finally { window.close() }
}
