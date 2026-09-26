package cjgui

import std.collection.*

// Focus ROLE re-establishment for the export chain's step2c.
//
// step2c resizes the window, which leaves the self-drawn view visible but NOT the
// window's first responder, so a posted Tab is delivered to whatever still owns
// the responder and never reaches the overlay's `keyDown`. The desktop chain's fix
// presses the tab TITLE again with a real Accessibility press: a TITLE is
// deliberately NOT a pointer-capture control, so it routes through the ordinary
// focus path and hands the responder role back to the overlay.
//
// This probe verifies that mechanism in-process, on the SAME responder chain a
// real key arrives on:
//   * the AppKit first-responder role is taken away by focusing a TEXT INPUT
//     (the input proxy becomes first responder) - the reveal probe documents the
//     same precondition;
//   * RED: while the proxy owns the role, a posted key does NOT reach the
//     overlay's `keyDown` (route bit 3 false);
//   * GREEN: the PRODUCTION Accessibility press
//     (`accessibilityPerformPress` on the element the AX client would reach,
//     captured by stable nodeId) both selects the pressed page and gives the
//     responder role back, so the very NEXT key already reaches `keyDown`;
//   * the same holds for the ALREADY-ACTIVE title: the page must not move, yet
//     the role must still be restored.
//
// The dispatch seam encodes the key's characters as an arrow function key; this
// probe therefore pins the ROUTE (who owns first responder, whether `keyDown`
// received the event), not the text view's own Tab semantics.

foreign {
    func cjgui_internal_renderer_test_dispatch_composable_key_through_application(
        session: UInt64, keyCode: UInt16, modifiers: UInt64,
        outFocusedNodeId: CPointer<UInt64>, outRouteFlags: CPointer<UInt32>
    ): Int32

    func cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
        session: UInt64, nodeId: UInt64
    ): Int32

    func cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session: UInt64): Int32
}

private class TabsRefocusProbeController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    let scope = CjguiComposableUiIdentityScope("tabs-refocus-probe")
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState) {
        this.state = state
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let pages = ArrayList<CjguiComposableUiTabPage>()
        // The active page owns a TEXT INPUT: focusing it hands the first-responder
        // role to the AppKit input proxy, which is the state a resize/keying leaves
        // behind in the export chain.
        let editor = CjguiComposableUiNode(601, "tabs-refocus-editor",
            CJGUI_COMPOSABLE_UI_TEXT_INPUT, "草稿标题", "草稿值", "", 8601,
            CjguiComposableUiStyle(fixedHeight: 24), identity: scope.local("editor"))
        pages.add(CjguiComposableUiTabPage("basic", "基本", editor))
        pages.add(CjguiComposableUiTabPage("notes", "备注",
            cjguiComposableText(603, "tabs-refocus-notes-line", "备注行",
                CjguiComposableUiStyle(fixedHeight: 20))))
        return cjguiComposableTabs(scope, "tabs-refocus-probe", pages, state,
            CjguiComposableUiStyle(growX: 1, growY: 1), titleHeight: 24)
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

private func tabsRefocusNode(window: CjguiComposableUiWindow, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// One key through the real NSApplication responder route. Returns
/// (status, focusedNodeId, routeFlags).
private func dispatchKey(session: UInt64, keyCode: UInt16): (Int32, UInt64, UInt32) {
    var focused: UInt64 = 0u64
    var flags: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_dispatch_composable_key_through_application(
            session, keyCode, 0u64, inout focused, inout flags)
    }
    return (status, focused, flags)
}

/// The route bits that matter: the overlay is the window's FIRST RESPONDER (8) and
/// it really RECEIVED the key (16). Whether the window happens to be the key window
/// at that instant (bits 2/4) is environment state, reported but not required.
private func routeReached(flags: UInt32): Bool {
    return (flags & 24u32) == 24u32
}

/// Capture the element an AX client would reach for this node, then invoke its
/// production `accessibilityPerformPress`. Returns (captureStatus, pressStatus).
private func pressNodeThroughAccessibility(session: UInt64, nodeId: Int64): (Int32, Int32) {
    let captured = unsafe {
        cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(session, UInt64(nodeId))
    }
    if (captured != CJGUI_INTERNAL_RENDERER_OK) {
        return (captured, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR)
    }
    let pressed = unsafe {
        cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session)
    }
    return (captured, pressed)
}

main(): Int64 {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsRefocusProbeController(state)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_TABS_REFOCUS start=false")
        return 1
    }
    let session = window.testSessionToken()
    let basicTitle = tabsRefocusNode(window, "tabs-refocus-probe-tab-basic")
    let notesTitle = tabsRefocusNode(window, "tabs-refocus-probe-tab-notes")
    let editor = tabsRefocusNode(window, "tabs-refocus-editor")
    let notesLine = tabsRefocusNode(window, "tabs-refocus-notes-line")
    var valid = basicTitle.nodeId > 0 && notesTitle.nodeId > 0 && editor.nodeId > 0 &&
        editor.bounds.height > 0 && state.activeKey() == "basic" &&
        (notesLine.nodeId < 0 || notesLine.bounds.height == 0)
    println("CJGUI_TABS_REFOCUS_TITLES basic=${basicTitle.nodeId} notes=${notesTitle.nodeId} " +
        "editor=${editor.nodeId} editor_h=${editor.bounds.height} notes_line_h=${notesLine.bounds.height} " +
        "active=${state.activeKey()} valid=${valid}")
    if (!valid) {
        println("CJGUI_TABS_REFOCUS passed=false")
        window.close()
        return 1
    }

    // 1. Take the first-responder role away from the overlay: focus the text input
    //    so the AppKit input proxy owns the role.
    let editorFocus = window.focusScopedNode(controller.scope, "editor")
    let _ = window.pump(0u32)
    let setup = window.windowProgress()
    println("CJGUI_TABS_REFOCUS_SETUP editor_focus=${editorFocus} focused_control='${setup.focusedControlId}' " +
        "focus_state=${setup.focusState} active=${state.activeKey()}")

    // 2. RED: while the proxy owns the role, a posted key does NOT reach the
    //    overlay's `keyDown`, and no page is switched by it.
    let (redStatus, redFocused, redFlags) = dispatchKey(session, 48u16)
    let _ = window.pump(0u32)
    let redOk = !routeReached(redFlags) && state.activeKey() == "basic"
    println("CJGUI_TABS_REFOCUS_RED status=${redStatus} flags=${redFlags} " +
        "route_reached=${routeReached(redFlags)} focused=${redFocused} active=${state.activeKey()} ok=${redOk}")

    // 3. GREEN: the production Accessibility press on the notes TITLE (the same
    //    entry `real_ax_press_identifier` reaches on the desktop) selects that page
    //    AND hands the responder role back, so the NEXT key already reaches
    //    `keyDown`.
    let (captured, pressed) = pressNodeThroughAccessibility(session, notesTitle.nodeId)
    let pressTurn = window.pump(0u32)
    let _ = window.refresh()
    let notesAfter = tabsRefocusNode(window, "tabs-refocus-notes-line")
    let editorAfter = tabsRefocusNode(window, "tabs-refocus-editor")
    let pageOk = captured == CJGUI_INTERNAL_RENDERER_OK && pressed == CJGUI_INTERNAL_RENDERER_OK &&
        state.activeKey() == "notes" && notesAfter.bounds.height > 0 &&
        (editorAfter.nodeId < 0 || editorAfter.bounds.height == 0)
    println("CJGUI_TABS_REFOCUS_AXPRESS node=${notesTitle.nodeId} capture=${captured} press=${pressed} " +
        "applied=${pressTurn.didApplyHumanAction} active=${state.activeKey()} " +
        "notes_h=${notesAfter.bounds.height} editor_h=${editorAfter.bounds.height} ok=${pageOk}")

    let (greenStatus, greenFocused, greenFlags) = dispatchKey(session, 48u16)
    let _ = window.pump(0u32)
    let greenRouteOk = greenStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(greenFlags) &&
        greenFocused != 0u64
    println("CJGUI_TABS_REFOCUS_GREEN status=${greenStatus} flags=${greenFlags} " +
        "route_reached=${routeReached(greenFlags)} focused=${greenFocused} ok=${greenRouteOk}")

    // 4. Press the basic title to return, then take the role away again.
    let (backCapture, backPress) = pressNodeThroughAccessibility(session, basicTitle.nodeId)
    let backTurn = window.pump(0u32)
    let _ = window.refresh()
    let backOk = backCapture == CJGUI_INTERNAL_RENDERER_OK && backPress == CJGUI_INTERNAL_RENDERER_OK &&
        backTurn.didApplyHumanAction && state.activeKey() == "basic"
    let _ = window.focusScopedNode(controller.scope, "editor")
    let _ = window.pump(0u32)
    let (repeatRedStatus, _, repeatRedFlags) = dispatchKey(session, 48u16)
    let _ = window.pump(0u32)
    let repeatRedOk = !routeReached(repeatRedFlags) && state.activeKey() == "basic"
    println("CJGUI_TABS_REFOCUS_REPEAT_RED back_press=${backCapture},${backPress} back_ok=${backOk} " +
        "status=${repeatRedStatus} flags=${repeatRedFlags} route_reached=${routeReached(repeatRedFlags)} " +
        "active=${state.activeKey()} ok=${repeatRedOk}")

    // 5. GREEN repeat on the ALREADY-ACTIVE title: the page does not move, but the
    //    press must still return the responder role to the overlay.
    let (activeCapture, activePress) = pressNodeThroughAccessibility(session, basicTitle.nodeId)
    let _ = window.pump(0u32)
    let _ = window.refresh()
    let (repeatGreenStatus, repeatGreenFocused, repeatGreenFlags) = dispatchKey(session, 48u16)
    let _ = window.pump(0u32)
    let repeatGreenOk = activeCapture == CJGUI_INTERNAL_RENDERER_OK &&
        activePress == CJGUI_INTERNAL_RENDERER_OK && state.activeKey() == "basic" &&
        repeatGreenStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(repeatGreenFlags) &&
        repeatGreenFocused != 0u64
    println("CJGUI_TABS_REFOCUS_REPEAT_GREEN capture=${activeCapture} press=${activePress} " +
        "status=${repeatGreenStatus} flags=${repeatGreenFlags} route_reached=${routeReached(repeatGreenFlags)} " +
        "focused=${repeatGreenFocused} active=${state.activeKey()} ok=${repeatGreenOk}")

    let passed = valid && redOk && pageOk && greenRouteOk && backOk && repeatRedOk && repeatGreenOk
    println("CJGUI_TABS_REFOCUS passed=${passed}")
    window.close()
    return if (passed) {
        0
    } else {
        1
    }
}
