package cjgui

import std.collection.*

// Reveal through the REAL AppKit key route.
//
// The export chain's step2c exercises "a control that exists but is clipped by the
// shared scroll viewport must be brought into view by keyboard focus". That step
// needs a desktop session; this probe verifies the SAME mechanism in-process,
// through the same responder chain a real key arrives on:
//
//   * `cjgui_internal_renderer_test_dispatch_composable_key_through_application`
//     posts an NSEvent through NSApplication and reports the route flags;
//   * the framework's own focus entry (`focusScopedNode`) is used to establish the
//     responder first, exactly as the tabs keyboard probe does.
//
// What is pinned:
//   * a control below the fold of a shared viewport is NOT addressable at its full
//     height before any focus;
//   * the framework's focus entry reveals it: the accepted bounds grow and the
//     viewport's ACCEPTED offset moves (the request alone is not accepted state);
//   * a real Tab reaches the same result through native focus traversal.

foreign {
    func cjgui_internal_renderer_test_dispatch_composable_key_through_application(
        session: UInt64, keyCode: UInt16, modifiers: UInt64,
        outFocusedNodeId: CPointer<UInt64>, outRouteFlags: CPointer<UInt32>
    ): Int32
}

private class RevealKeyboardProbeController <: CjguiComposableUiController {
    let viewport = CjguiComposableUiScrollViewport()
    let scope = CjguiComposableUiIdentityScope("reveal-keyboard-probe")
    private var revision: Int64 = 1

    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "reveal-probe-root", CjguiComposableUiStyle(gap: 4))
        let scroll = cjguiComposableScrollArea(2, "reveal-probe-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 160))
        let stack = cjguiComposableVertical(3, "reveal-probe-stack", CjguiComposableUiStyle(gap: 0))
        // A focusable NON-TEXT control at the TOP (always visible) establishes the
        // responder: focusing a text input would give the AppKit input proxy the
        // first-responder role, and a posted Tab would never reach `keyDown`.
        stack.add(cjguiComposableButton(10, "reveal-probe-top-button", "顶部", "REVEAL_TOP", 8401,
            CjguiComposableUiStyle(fixedHeight: 24), identity: scope.local("top-button")))
        var index: Int64 = 0
        while (index < 12) {
            stack.add(cjguiComposableText(20 + index, "reveal-probe-row-${index}", "行 ${index}",
                CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        // ...and one BELOW the fold of the 160pt viewport: clipped until focus.
        stack.add(CjguiComposableUiNode(40, "reveal-probe-bottom-input", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
            "底部", "底部值", "", 8402, CjguiComposableUiStyle(fixedHeight: 24),
            identity: scope.local("bottom-input")))
        scroll.add(stack)
        root.add(scroll)
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

private func revealProbeHeight(window: CjguiComposableUiWindow, semanticId: String): Int64 {
    return match (window.acceptedNodeBounds(semanticId)) {
        case Some(rect) => rect.height
        case None => 0
    }
}

/// Whether one accepted node is INSIDE the accepted band of the shared viewport.
/// Being outside it is what "clipped" means here: the node still exists with its
/// own layout rectangle, it is simply not in the visible band.
private func revealProbeVisible(window: CjguiComposableUiWindow, semanticId: String): Bool {
    let outer = match (window.acceptedNodeBounds("reveal-probe-scroll")) {
        case Some(rect) => rect
        case None => return false
    }
    let inner = match (window.acceptedNodeBounds(semanticId)) {
        case Some(rect) => rect
        case None => return false
    }
    return inner.y >= outer.y && inner.y + inner.height <= outer.y + outer.height
}

main(): Int64 {
    let controller = RevealKeyboardProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_REVEAL_KEYBOARD start=false")
        return 1
    }
    let session = window.testSessionToken()
    let topHeight = revealProbeHeight(window, "reveal-probe-top-button")
    let bottomHeight = revealProbeHeight(window, "reveal-probe-bottom-input")
    let bottomVisibleBefore = revealProbeVisible(window, "reveal-probe-bottom-input")
    let offsetBefore = controller.viewport.acceptedOffset()
    println("CJGUI_REVEAL_KEYBOARD_LAYOUT top_h=${topHeight} bottom_h=${bottomHeight} " +
        "bottom_visible_before=${bottomVisibleBefore} offset_before=${offsetBefore}")
    // The top control is inside the viewport's band; the bottom one exists with its
    // own rectangle but is NOT inside that band.
    var valid = topHeight > 0 && bottomHeight > 0 && !bottomVisibleBefore && offsetBefore == 0
    // 1. A real Tab through the responder chain must reveal the clipped control.
    //    The responder is established with the framework's own focus entry on the
    //    VISIBLE control first (the same precondition a person's click gives).
    let topFocused = window.focusScopedNode(controller.scope, "top-button")
    let _ = window.refresh()
    let bottomResetVisible = revealProbeVisible(window, "reveal-probe-bottom-input")
    var tabTurns: Int64 = 0
    var tabRouteOk = false
    var tabRevealed = false
    while (tabTurns < 6) {
        var focused: UInt64 = 0u64
        var flags: UInt32 = 0u32
        let status = unsafe {
            cjgui_internal_renderer_test_dispatch_composable_key_through_application(
                session, 48u16, 0u64, inout focused, inout flags)
        }
        let _ = window.pump(0u32)
        let _ = window.refresh()
        if ((flags & 24u32) == 24u32 && status == CJGUI_INTERNAL_RENDERER_OK) {
            tabRouteOk = true
        }
        let visible = revealProbeVisible(window, "reveal-probe-bottom-input")
        println("CJGUI_REVEAL_KEYBOARD_TAB_STEP turn=${tabTurns} status=${status} flags=${flags} " +
            "focused=${focused} bottom_visible=${visible} offset=${controller.viewport.acceptedOffset()}")
        if (visible) {
            tabRevealed = true
            break
        }
        tabTurns += 1
    }
    let tabOk = topFocused && tabRouteOk && tabRevealed && !bottomResetVisible
    println("CJGUI_REVEAL_KEYBOARD_TAB top_focused=${topFocused} route_ok=${tabRouteOk} " +
        "revealed=${tabRevealed} tabs=${tabTurns} bottom_reset_visible=${bottomResetVisible} ok=${tabOk}")

    // 2. The framework's focus entry alone reaches the same result: put the shared
    //    viewport back at the top so the target is clipped again, then focus it.
    let _ = controller.viewport.requestOffset(0)
    let _ = window.refresh()
    let clippedAgain = !revealProbeVisible(window, "reveal-probe-bottom-input")
    let offsetReset = controller.viewport.acceptedOffset()
    let focusRequested = window.focusScopedNode(controller.scope, "bottom-input")
    let refreshed = window.refresh()
    let bottomVisibleAfterFocus = revealProbeVisible(window, "reveal-probe-bottom-input")
    let offsetAfterFocus = controller.viewport.acceptedOffset()
    let focusOk = clippedAgain && offsetReset == 0 && !focusRequested && refreshed &&
        bottomVisibleAfterFocus && offsetAfterFocus > offsetReset
    println("CJGUI_REVEAL_KEYBOARD_FOCUS clipped_again=${clippedAgain} offset_reset=${offsetReset} " +
        "requested=${focusRequested} refreshed=${refreshed} " +
        "bottom_visible_after=${bottomVisibleAfterFocus} offset=${offsetReset}->${offsetAfterFocus} " +
        "ok=${focusOk}")

    let passed = valid && focusOk && tabOk
    println("CJGUI_REVEAL_KEYBOARD passed=${passed}")
    window.close()
    return if (passed) {
        0
    } else {
        1
    }
}
