package cjgui

import std.collection.*

// B1: the tab TITLE keyboard rules on the REAL AppKit responder route.
//
// The pointer/AX paths and the package-internal decision probes are separate
// evidence. This probe drives the SAME synthetic key dispatch the pointer-capture
// probe uses: `cjgui_internal_renderer_test_dispatch_composable_key_through_application`
// posts an NSEvent through NSApplication's responder chain and reports the route
// flags (application / target-is-key / app-key-window-is-target /
// overlay-is-first-responder / overlay-received). A hand-made Cangjie event never
// touches this path, so "Enter/Space switches the page" is verified where a real
// key would arrive.
//
// What is pinned:
//   * Tab enters the selected title, exits the group to the active page's first
//     editor, and Shift-Tab returns to the title and then leaves the group;
//   * Left/Right move the TITLE focus inside one accepted tab group and SKIP a
//     disabled title; the active page does not change;
//   * Return/Space activate the focused title through the ordinary ACTIVATE
//     interaction and the NEXT accepted scene really presents that page;
//   * Tab reaches the accepted split divider and slider, whose existing arrow
//     paths update their view/owner values;
//   * the disabled title never becomes the navigation target.

foreign {
    func cjgui_internal_renderer_test_send_composable_pointer(
        session: UInt64, phase: UInt32, pointX: Float32, pointY: Float32
    ): Int32

    func cjgui_internal_renderer_test_dispatch_composable_key_through_application(
        session: UInt64, keyCode: UInt16, modifiers: UInt64,
        outFocusedNodeId: CPointer<UInt64>, outRouteFlags: CPointer<UInt32>
    ): Int32
}

private class TabsKeyboardProbeController <: CjguiComposableUiController {
    let state: CjguiComposableUiTabsState
    let scope = CjguiComposableUiIdentityScope("tabs-keyboard-probe")
    let splitScope = CjguiComposableUiIdentityScope("tabs-keyboard-split")
    let splitState = CjguiComposableUiSplitState(180, 100, 100)
    private var sliderValue: Int64 = 50
    private var revision: Int64 = 1

    init(state: CjguiComposableUiTabsState) {
        this.state = state
    }
    public func sliderValueNow(): Int64 {
        return sliderValue
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let pages = ArrayList<CjguiComposableUiTabPage>()
        // Use a boolean input as the page's first input. It stays on the
        // composable overlay responder (unlike a text field's hidden
        // NSTextView proxy), so the AppKit Tab/Shift-Tab route itself remains
        // observable in this probe. Text editing has its own input-proxy
        // contract and is not silently treated as this route's evidence.
        let editor = CjguiComposableUiNode(504, "tabs-keyboard-editor",
            CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT, "当前页选择", "false", "EDIT_BOOLEAN", 8504,
            CjguiComposableUiStyle(fixedHeight: 24), identity: scope.local("editor"))
        pages.add(CjguiComposableUiTabPage("basic", "基本",
            editor))
        // The MIDDLE title is disabled: a real move must skip it.
        pages.add(CjguiComposableUiTabPage("advanced", "高级",
            cjguiComposableText(502, "tabs-keyboard-advanced-line", "高级行",
                CjguiComposableUiStyle(fixedHeight: 20)), enabled: false))
        pages.add(CjguiComposableUiTabPage("notes", "备注",
            cjguiComposableText(503, "tabs-keyboard-notes-line", "备注行",
                CjguiComposableUiStyle(fixedHeight: 20))))
        let root = cjguiComposableVertical(490, "tabs-keyboard-root", CjguiComposableUiStyle(gap: 4))
        root.add(cjguiComposableButton(491, "tabs-keyboard-before", "前一控件", "NOOP", -1,
            CjguiComposableUiStyle(fixedHeight: 24), identity: Some(scope.local("before"))))
        root.add(cjguiComposableTabs(scope, "tabs-keyboard-probe", pages, state,
            CjguiComposableUiStyle(fixedHeight: 140, growX: 1), titleHeight: 24))
        let splitFirst = cjguiComposableText(520, "tabs-keyboard-split-first", "分栏一",
            CjguiComposableUiStyle(growX: 1))
        let splitSecond = cjguiComposableText(521, "tabs-keyboard-split-second", "分栏二",
            CjguiComposableUiStyle(growX: 1))
        root.add(cjguiComposableScopedSplitView(splitScope, "tabs-keyboard-split-view", splitFirst, splitSecond,
            CjguiComposableUiSplitAxis.HORIZONTAL, splitState.firstSize(), splitState.firstMinimum(),
            splitState.secondMinimum(), CjguiComposableUiStyle(fixedHeight: 90, growX: 1),
            splitState: Some(splitState)))
        root.add(cjguiComposableSlider(530, "tabs-keyboard-slider", sliderValue, 0, 100, 5,
            CjguiComposableUiStyle(fixedHeight: 28, growX: 1)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 35 && event.node.semanticId == "tabs-keyboard-slider") {
            let direction = if (event.text == "left" || event.text == "up") {
                -1
            } else if (event.text == "right" || event.text == "down") {
                1
            } else {
                0
            }
            if (direction != 0) {
                let next = CjguiComposableUiSliderGeometry.adjustValue(sliderValue, direction, 0, 100, 5)
                if (next != sliderValue) {
                    sliderValue = next
                    revision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
        }
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

private func tabsKeyboardNode(window: CjguiComposableUiWindow, semanticId: String,
    expectedKind!: Int64 = -1): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId && (expectedKind < 0 || node.nodeKind == expectedKind)) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// One key through the real NSApplication responder route. Returns
/// (status, focusedNodeId, routeFlags).
private func dispatchKey(session: UInt64, keyCode: UInt16, modifiers: UInt64): (Int32, UInt64, UInt32) {
    var focused: UInt64 = 0u64
    var flags: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_dispatch_composable_key_through_application(
            session, keyCode, modifiers, inout focused, inout flags)
    }
    return (status, focused, flags)
}

/// The route bits that matter: the overlay is the window's FIRST RESPONDER (8) and
/// it really RECEIVED the key (16). Whether the window happens to be the key
/// window at that instant (bits 2/4) is environment state, reported but not
/// required: the dispatch seam drives the responder chain directly.
private func routeReached(flags: UInt32): Bool {
    return (flags & 24u32) == 24u32
}

main(): Int64 {
    let state = CjguiComposableUiTabsState("basic")
    let controller = TabsKeyboardProbeController(state)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_TABS_KEYBOARD start=false")
        return 1
    }
    let session = window.testSessionToken()
    let basicTitle = tabsKeyboardNode(window, "tabs-keyboard-probe-tab-basic")
    let advancedTitle = tabsKeyboardNode(window, "tabs-keyboard-probe-tab-advanced")
    let notesTitle = tabsKeyboardNode(window, "tabs-keyboard-probe-tab-notes")
    // The active page wrapper intentionally projects the page content's
    // semantic id too; select the actual input node by its public kind so the
    // probe never mistakes that structural wrapper for the focus target.
    let editor = tabsKeyboardNode(window, "tabs-keyboard-editor", expectedKind: CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT)
    let splitHandle = tabsKeyboardNode(window, "tabs-keyboard-split-view-handle")
    let slider = tabsKeyboardNode(window, "tabs-keyboard-slider")
    var valid = basicTitle.nodeId > 0 && advancedTitle.nodeId > 0 && notesTitle.nodeId > 0 &&
        editor.nodeId > 0 && splitHandle.nodeId > 0 && slider.nodeId > 0 &&
        !advancedTitle.isEnabled && basicTitle.canReceiveFocus() && notesTitle.canReceiveFocus() &&
        editor.canReceiveFocus() && splitHandle.canReceiveFocus() && slider.canReceiveFocus() &&
        basicTitle.tabsPageKey == "basic" && notesTitle.tabsPageKey == "notes" &&
        editor.value == "false" && splitHandle.pointerControlFirstSize == 180 && slider.value == "50"
    println("CJGUI_TABS_KEYBOARD_TITLES basic=${basicTitle.nodeId} advanced=${advancedTitle.nodeId} " +
        "notes=${notesTitle.nodeId} editor=${editor.nodeId} split=${splitHandle.nodeId} slider=${slider.nodeId} " +
        "advanced_enabled=${advancedTitle.isEnabled} focus_basic=${basicTitle.canReceiveFocus()} " +
        "focus_notes=${notesTitle.canReceiveFocus()} focus_editor=${editor.canReceiveFocus()} " +
        "focus_split=${splitHandle.canReceiveFocus()} focus_slider=${slider.canReceiveFocus()} " +
        "editor_kind=${editor.nodeKind} editor_enabled=${editor.isEnabled} " +
        "editor_readonly=${editor.isReadOnly} editor_accepts=${editor.acceptsInput()} " +
        "editor_action='${editor.actionName}' editor_scope='${editor.inputScopeId}' " +
        "basic_page='${basicTitle.tabsPageKey}' notes_page='${notesTitle.tabsPageKey}' " +
        "editor_value='${editor.value}' split_first=${splitHandle.pointerControlFirstSize} slider_value='${slider.value}' " +
        "editor_h=${editor.bounds.height} split_h=${splitHandle.bounds.height} slider_h=${slider.bounds.height} " +
        "valid=${valid}")
    if (!valid) {
        println("CJGUI_TABS_KEYBOARD passed=false")
        window.close()
        return 1
    }
    // Establish the responder on the PREVIOUS ordinary control. A pure Tab
    // must enter the tab group at its current usable title. The old native
    // traversal omitted TAB_TITLE and wrapped back to this button.
    let focused = window.focusScopedNode(controller.scope, "before")
    let afterFocus = window.windowProgress()
    println("CJGUI_TABS_KEYBOARD_PRESS focused=${focused} focus_state=${afterFocus.focusState} " +
        "active=${state.activeKey()}")
    let (tabStatus, _, tabFlags) = dispatchKey(session, 48u16, 0u64)
    let _ = window.pump(0u32)
    let tabControl = window.windowProgress().focusedControlId
    let tabOk = tabStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(tabFlags) &&
        tabControl == "tabs-keyboard-probe-tab-basic" && state.activeKey() == "basic"
    println("CJGUI_TABS_KEYBOARD_ENTRY status=${tabStatus} flags=${tabFlags} " +
        "route_reached=${routeReached(tabFlags)} focused_control='${tabControl}' " +
        "active=${state.activeKey()} ok=${tabOk}")

    // 1b. Tab leaves the title group to the first editor in the selected page;
    // Shift-Tab returns to the selected title, then leaves the group to the
    // ordinary control before it. These are accepted identities, not captions.
    let (tabIntoPageStatus, _, tabIntoPageFlags) = dispatchKey(session, 48u16, 0u64)
    let _ = window.pump(0u32)
    let pageControl = window.windowProgress().focusedControlId
    let tabIntoPageOk = tabIntoPageStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(tabIntoPageFlags) &&
        pageControl == "tabs-keyboard-editor"
    println("CJGUI_TABS_KEYBOARD_ENTRY_PAGE status=${tabIntoPageStatus} flags=${tabIntoPageFlags} " +
        "route_reached=${routeReached(tabIntoPageFlags)} focused_control='${pageControl}' ok=${tabIntoPageOk}")

    let (backToTitleStatus, _, backToTitleFlags) = dispatchKey(session, 48u16, UInt64(CJGUI_UI_MODIFIER_SHIFT))
    let _ = window.pump(0u32)
    let backToTitleControl = window.windowProgress().focusedControlId
    let backToTitleOk = backToTitleStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(backToTitleFlags) &&
        backToTitleControl == "tabs-keyboard-probe-tab-basic"
    println("CJGUI_TABS_KEYBOARD_BACK_TITLE status=${backToTitleStatus} flags=${backToTitleFlags} " +
        "route_reached=${routeReached(backToTitleFlags)} focused_control='${backToTitleControl}' ok=${backToTitleOk}")

    let (outGroupStatus, _, outGroupFlags) = dispatchKey(session, 48u16, UInt64(CJGUI_UI_MODIFIER_SHIFT))
    let _ = window.pump(0u32)
    let outGroupControl = window.windowProgress().focusedControlId
    let outGroupOk = outGroupStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(outGroupFlags) &&
        outGroupControl == "tabs-keyboard-before"
    println("CJGUI_TABS_KEYBOARD_BACK_OUT status=${outGroupStatus} flags=${outGroupFlags} " +
        "route_reached=${routeReached(outGroupFlags)} focused_control='${outGroupControl}' ok=${outGroupOk}")

    // Re-enter from the previous control for the remaining group, page and
    // pointer-control checks.
    let _ = window.focusScopedNode(controller.scope, "before")
    let _ = window.pump(0u32)
    let (reentryStatus, _, reentryFlags) = dispatchKey(session, 48u16, 0u64)
    let _ = window.pump(0u32)
    let reentryControl = window.windowProgress().focusedControlId
    let reentryOk = reentryStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(reentryFlags) &&
        reentryControl == "tabs-keyboard-probe-tab-basic"

    // 2. Right moves the title focus past the DISABLED middle title, and the page
    //    does not change.
    let (rightStatus, _, rightFlags) = dispatchKey(session, 124u16, 0u64)
    let _ = window.pump(0u32)
    let rightControl = window.windowProgress().focusedControlId
    let rightOk = rightStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(rightFlags) &&
        rightControl == "tabs-keyboard-probe-tab-notes" && state.activeKey() == "basic"
    println("CJGUI_TABS_KEYBOARD_ROUTE step=right status=${rightStatus} flags=${rightFlags} " +
        "route_reached=${routeReached(rightFlags)} focused_control='${rightControl}' " +
        "active=${state.activeKey()} ok=${rightOk}")

    // 3. Return activates the focused title: the NEXT accepted scene presents the
    //    notes page and hides the basic one.
    let (returnStatus, _, returnFlags) = dispatchKey(session, 36u16, 0u64)
    let returnTurn = window.pump(0u32)
    let refreshed = window.refresh()
    let basicLine = tabsKeyboardNode(window, "tabs-keyboard-basic-line")
    let notesLine = tabsKeyboardNode(window, "tabs-keyboard-notes-line")
    let selectedNotesTitle = tabsKeyboardNode(window, "tabs-keyboard-probe-tab-notes")
    let selectedTitleControl = window.windowProgress().focusedControlId
    let returnOk = returnStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(returnFlags) && refreshed &&
        state.activeKey() == "notes" && notesLine.bounds.height > 0 &&
        (basicLine.nodeId < 0 || basicLine.bounds.height == 0) &&
        selectedNotesTitle.nodeId > 0 && selectedTitleControl == "tabs-keyboard-probe-tab-notes"
    println("CJGUI_TABS_KEYBOARD_PAGE step=return status=${returnStatus} flags=${returnFlags} " +
        "route_reached=${routeReached(returnFlags)} applied=${returnTurn.didApplyHumanAction} " +
        "active=${state.activeKey()} selected_title='${selectedTitleControl}' " +
        "basic_h=${basicLine.bounds.height} notes_h=${notesLine.bounds.height} ok=${returnOk}")

    // 4. Left returns the title focus to the first title without switching back.
    let (leftStatus, _, leftFlags) = dispatchKey(session, 123u16, 0u64)
    let _ = window.pump(0u32)
    let leftControl = window.windowProgress().focusedControlId
    let leftOk = leftStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(leftFlags) &&
        leftControl == "tabs-keyboard-probe-tab-basic" && state.activeKey() == "notes"
    println("CJGUI_TABS_KEYBOARD_ROUTE step=left status=${leftStatus} flags=${leftFlags} " +
        "route_reached=${routeReached(leftFlags)} focused_control='${leftControl}' " +
        "active=${state.activeKey()} ok=${leftOk}")

    // 5. Space activates the first title through the same ACTIVATE interaction.
    let (spaceStatus, _, spaceFlags) = dispatchKey(session, 49u16, 0u64)
    let spaceTurn = window.pump(0u32)
    let refreshedBack = window.refresh()
    let basicBack = tabsKeyboardNode(window, "tabs-keyboard-editor")
    let notesBack = tabsKeyboardNode(window, "tabs-keyboard-notes-line")
    let spaceOk = spaceStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(spaceFlags) && refreshedBack &&
        state.activeKey() == "basic" && basicBack.bounds.height > 0 &&
        (notesBack.nodeId < 0 || notesBack.bounds.height == 0)
    println("CJGUI_TABS_KEYBOARD_PAGE step=space status=${spaceStatus} flags=${spaceFlags} " +
        "route_reached=${routeReached(spaceFlags)} applied=${spaceTurn.didApplyHumanAction} " +
        "active=${state.activeKey()} " +
        "basic_h=${basicBack.bounds.height} notes_h=${notesBack.bounds.height} ok=${spaceOk}")

    // 6. The disabled title is never a navigation target: from the first title,
    //    Right must land on notes (already proven); a direct activation of the
    //    disabled title is refused by the framework.
    let disabledActivation = window.testActivateTabTitle(advancedTitle.nodeId)
    let disabledOk = !disabledActivation && state.activeKey() == "basic"
    println("CJGUI_TABS_KEYBOARD_DISABLED activated=${disabledActivation} active=${state.activeKey()} " +
        "ok=${disabledOk}")

    // 7. Pure Tab reaches the accepted split divider, then the slider. Existing
    // arrow paths remain separate: split updates shared view state, while the
    // probe owner applies the slider's normal bounded value action.
    let _ = window.focusScopedNode(controller.scope, "editor")
    let _ = window.pump(0u32)
    let (splitTabStatus, _, splitTabFlags) = dispatchKey(session, 48u16, 0u64)
    let splitTurn = window.pump(0u32)
    let splitControl = window.windowProgress().focusedControlId
    let splitBefore = controller.splitState.acceptedFirstSize()
    let (splitArrowStatus, _, splitArrowFlags) = dispatchKey(session, 124u16, 0u64)
    let splitArrowTurn = window.pump(0u32)
    let splitAfter = controller.splitState.acceptedFirstSize()
    let splitOk = splitTabStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(splitTabFlags) &&
        splitControl == "tabs-keyboard-split-view-handle" &&
        splitArrowStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(splitArrowFlags) &&
        splitArrowTurn.didApplyHumanAction && splitAfter > splitBefore
    println("CJGUI_TABS_KEYBOARD_SPLIT tab_status=${splitTabStatus} tab_flags=${splitTabFlags} " +
        "route_reached=${routeReached(splitTabFlags)} focused_control='${splitControl}' " +
        "arrow_status=${splitArrowStatus} arrow_flags=${splitArrowFlags} " +
        "arrow_route_reached=${routeReached(splitArrowFlags)} applied=${splitArrowTurn.didApplyHumanAction} " +
        "before=${splitBefore} after=${splitAfter} ok=${splitOk}")

    let (sliderTabStatus, _, sliderTabFlags) = dispatchKey(session, 48u16, 0u64)
    let sliderTurn = window.pump(0u32)
    let sliderControl = window.windowProgress().focusedControlId
    let sliderBefore = controller.sliderValueNow()
    let (sliderArrowStatus, _, sliderArrowFlags) = dispatchKey(session, 124u16, 0u64)
    let sliderArrowTurn = window.pump(0u32)
    let sliderAfter = controller.sliderValueNow()
    let sliderOk = sliderTabStatus == CJGUI_INTERNAL_RENDERER_OK && routeReached(sliderTabFlags) &&
        sliderControl == "tabs-keyboard-slider" && sliderArrowStatus == CJGUI_INTERNAL_RENDERER_OK &&
        routeReached(sliderArrowFlags) && sliderArrowTurn.didApplyHumanAction && sliderAfter > sliderBefore
    println("CJGUI_TABS_KEYBOARD_SLIDER tab_status=${sliderTabStatus} tab_flags=${sliderTabFlags} " +
        "route_reached=${routeReached(sliderTabFlags)} focused_control='${sliderControl}' " +
        "arrow_status=${sliderArrowStatus} arrow_flags=${sliderArrowFlags} " +
        "arrow_route_reached=${routeReached(sliderArrowFlags)} applied=${sliderArrowTurn.didApplyHumanAction} " +
        "before=${sliderBefore} after=${sliderAfter} ok=${sliderOk}")

    let passed = valid && tabOk && tabIntoPageOk && backToTitleOk && outGroupOk && reentryOk &&
        rightOk && returnOk && leftOk && spaceOk && disabledOk && splitOk && sliderOk
    println("CJGUI_TABS_KEYBOARD passed=${passed}")
    window.close()
    return if (passed) {
        0
    } else {
        1
    }
}
