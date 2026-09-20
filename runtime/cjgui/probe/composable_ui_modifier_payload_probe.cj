// Cross-layer regression for the pointer modifier payload and the tree
// navigation route.
//
// This probe drives the PRODUCTION native pointer activation path
// (`mouseDownForNode:`, the same entry a real AppKit mouse-down uses) through
// the ordinary FIFO, then observes what the Cangjie window delivers to its
// controller. It asserts:
//
//   1. a pointer-originated activation carries the modifier flags observed for
//      that gesture (native -> queue -> FFI -> window -> controller);
//   2. a keyboard/AX activation enqueued while the pointer flags are still set
//      from an earlier gesture carries none (no residual inheritance);
//   3. the Command-A navigation intent (NAVIGATE + "select_all") reaches the
//      controller through the same window path for a scroll-area node.
//
// Only the native injection seams are test-only; the Cangjie window,
// controller dispatch and native queue/flags handling are production code.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_press_composable_node(session: UInt64, nodeIndex: UInt32): Int32
    func cjgui_internal_renderer_test_set_pointer_modifiers(session: UInt64, modifierFlags: Int64): Unit
}

private class ModifierProbeListSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 5 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem("probe-${index}", index, "行 ${index}")
    }
    public func indexForKey(key: String): Int64 {
        if (key.startsWith("probe-")) {
            return 0
        }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
        // One unique declaration id per row: reusing a single id (or the root's)
        // makes the whole candidate scene a duplicate and the first refresh
        // fails before anything is shown.
        return cjguiComposableText(9000 + item.resourceId, item.key, item.title, CjguiComposableUiStyle())
    }
}

private class ModifierProbeController <: CjguiComposableUiController {
    private var version: Int64 = 1
    private var lastKind: Int64 = -1
    private var lastAction: String = ""
    private var lastText: String = ""
    private var lastFlags: Int64 = -2

    public func uiSceneVersion(): Int64 {
        return version
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "modifier-probe-root", CjguiComposableUiStyle(gap: 4))
        root.add(cjguiComposableButton(2, "modifier-probe-button", "探测按钮", "PROBE_ACTION", 7,
            CjguiComposableUiStyle(fixedHeight: 28)))
        root.add(cjguiComposableVirtualList(3, "modifier-probe-list", 4, ModifierProbeListSource(),
            CjguiComposableUiVirtualListState(), 24, 2, 2, CjguiComposableUiStyle(fixedHeight: 120)))
        root.add(cjguiComposableTextInput(5, "modifier-probe-text", "文本", "abc", 77,
            CjguiComposableUiStyle(fixedHeight: 24), fieldId: "probe"))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        lastKind = event.eventKind
        lastAction = event.node.actionName
        lastText = event.text
        lastFlags = event.modifierFlags
        return CjguiComposableUiDispatchResult(true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func resetRecording(): Unit {
        lastKind = -1
        lastAction = ""
        lastText = ""
        lastFlags = -2
    }

    public func recordedKind(): Int64 { return lastKind }
    public func recordedAction(): String { return lastAction }
    public func recordedText(): String { return lastText }
    public func recordedFlags(): Int64 { return lastFlags }
}

private func enqueueNative(session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(session, nodeIndex, eventKind, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

main(): Int64 {
    let controller = ModifierProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        let failed = window.windowProjection()
        println("CJGUI_MODIFIER_PAYLOAD start=false native_status=${window.nativeStatus()} " +
            "reason=${failed.pendingRefreshReason} failure=${failed.lastNativeFailure} " +
            "accepted=${failed.acceptedSceneVersion} submitted=${failed.submittedSceneVersion}")
        return 1
    }
    if (!window.refresh()) {
        println("CJGUI_MODIFIER_PAYLOAD refresh=false native_status=${window.nativeStatus()} " +
            "reason=${window.windowProjection().pendingRefreshReason} " +
            "failure=${window.windowProjection().lastNativeFailure}")
        window.close()
        return 1
    }
    let session = window.testSessionToken()

    // Locate the button and the scroll area in the native node array by driving
    // each candidate index and observing which one reaches the controller.
    var buttonIndex: UInt32 = 0
    var buttonFound = false
    var scrollIndex: UInt32 = 0
    var scrollFound = false
    var textIndex: UInt32 = 0
    var textFound = false
    var index: UInt32 = 0
    while (index < 16) {
        if (!buttonFound) {
            controller.resetRecording()
            let _ = unsafe { cjgui_internal_renderer_test_press_composable_node(session, index) }
            let _ = window.pump(0u32)
            if (controller.recordedAction() == "PROBE_ACTION") {
                buttonIndex = index
                buttonFound = true
            }
        }
        if (!scrollFound) {
            controller.resetRecording()
            if (enqueueNative(session, index, 35u32, "select_all")) {
                let _ = window.pump(0u32)
                if (controller.recordedKind() == 35 && controller.recordedText() == "select_all") {
                    scrollIndex = index
                    scrollFound = true
                }
            }
        }
        if (!textFound) {
            controller.resetRecording()
            if (enqueueNative(session, index, 28u32, "abc")) {
                let _ = window.pump(0u32)
                if (controller.recordedKind() == 28 && controller.recordedAction() == "EDIT_TEXT") {
                    textIndex = index
                    textFound = true
                }
            }
        }
        index += 1
    }
    if (!buttonFound || !scrollFound) {
        println("CJGUI_MODIFIER_PAYLOAD located=false button=${buttonFound} scroll=${scrollFound} " +
            "text=${textFound}")
        window.close()
        return 1
    }

    // 1. Pointer-originated activation carries this gesture's modifiers.
    let gestureFlags = CJGUI_UI_MODIFIER_COMMAND | CJGUI_UI_MODIFIER_SHIFT
    unsafe { cjgui_internal_renderer_test_set_pointer_modifiers(session, gestureFlags) }
    controller.resetRecording()
    let pressStatus = unsafe {
        cjgui_internal_renderer_test_press_composable_node(session, buttonIndex)
    }
    let _ = window.pump(0u32)
    let pointerOk = pressStatus == CJGUI_INTERNAL_RENDERER_OK &&
        controller.recordedAction() == "PROBE_ACTION" && controller.recordedFlags() == gestureFlags
    println("CJGUI_MODIFIER_PAYLOAD pointer_press ok=${pointerOk} index=${buttonIndex} " +
        "status=${pressStatus} action=${controller.recordedAction()} flags=${controller.recordedFlags()}")

    // 2. Keyboard/AX activation must not inherit the previous mouse gesture.
    //    The pointer flags are deliberately left set from step 1.
    controller.resetRecording()
    let keyboardEnqueued = enqueueNative(session, buttonIndex, 27u32, "")
    let _ = window.pump(0u32)
    let keyboardOk = keyboardEnqueued && controller.recordedAction() == "PROBE_ACTION" &&
        controller.recordedFlags() == 0
    println("CJGUI_MODIFIER_PAYLOAD keyboard_activation ok=${keyboardOk} " +
        "flags=${controller.recordedFlags()}")

    // 3. The Command-A navigation intent reaches the tree/list scope.
    controller.resetRecording()
    let navigateEnqueued = enqueueNative(session, scrollIndex, 35u32, "select_all")
    let _ = window.pump(0u32)
    let navigateOk = navigateEnqueued && controller.recordedKind() == 35 &&
        controller.recordedText() == "select_all"
    println("CJGUI_MODIFIER_PAYLOAD navigate_select_all ok=${navigateOk} index=${scrollIndex} " +
        "kind=${controller.recordedKind()} text=${controller.recordedText()}")

    // 4. The tree/list navigation route must not intercept a text scope: the
    //    same NAVIGATE intent addressed to the text input is not delivered as a
    //    navigation, so the input keeps its ordinary selection behavior.
    var textScopeOk = true
    if (textFound) {
        controller.resetRecording()
        let textNavigate = enqueueNative(session, textIndex, 35u32, "select_all")
        let _ = window.pump(0u32)
        textScopeOk = textNavigate && controller.recordedKind() != 35
        println("CJGUI_MODIFIER_PAYLOAD navigate_on_text_scope ok=${textScopeOk} index=${textIndex} " +
            "delivered_kind=${controller.recordedKind()}")
    } else {
        textScopeOk = false
        println("CJGUI_MODIFIER_PAYLOAD navigate_on_text_scope ok=false text_node_not_located=true")
    }

    let passed = pointerOk && keyboardOk && navigateOk && textScopeOk
    println("CJGUI_MODIFIER_PAYLOAD passed=${passed}")
    window.close()
    return if (passed) { 0 } else { 1 }
}
