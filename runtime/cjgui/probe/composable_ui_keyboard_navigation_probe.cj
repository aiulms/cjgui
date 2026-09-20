// Cross-layer regression for the tree's keyboard navigation payload.
//
// The desktop probe proves that a real CGEvent arrow reaches the window, but a
// synthesized *modified* arrow does not reach this application on this host
// (measured: plain Down navigates, Shift+Down and Command+Down both leave the
// selection version untouched, while Command+letter chords are delivered).
// This probe therefore drives the other half through the production path that
// the OS would reach: a real NSEvent with the requested modifiers is built in
// the test-only seam and handed to `[NSApp sendEvent:]`, so the production
// `keyDown` -> queue -> FFI -> window -> controller route decides what happens.
//
// It asserts, for one window whose controller owns a real tree projection:
//   1. an unmodified Down navigates and moves only the focus;
//   2. Shift+Down / Shift+Up reach the controller with the key event's own
//      Shift payload and extend/shrink the range from the anchor;
//   3. Left/Right collapse and expand the focused group;
//   4. Home/End move the focus to the first/last visible row;
//   5. Command-A reaches the controller as `select_all` and selects every
//      visible selectable row;
//   6. Command-A while a text input holds the focus is NOT delivered to the
//      tree (the text scope keeps its own select-all).
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_press_composable_node(session: UInt64, nodeIndex: UInt32): Int32
    func cjgui_internal_renderer_test_dispatch_current_composable_key(
        keyCode: UInt16, modifiers: UInt64, characters: CString
    ): Int32
}

// Real macOS virtual key codes and modifier bits, as a key event carries them.
private let KEY_LEFT: UInt16 = 123
private let KEY_RIGHT: UInt16 = 124
private let KEY_DOWN: UInt16 = 125
private let KEY_UP: UInt16 = 126
private let KEY_HOME: UInt16 = 115
private let KEY_END: UInt16 = 119
private let KEY_A: UInt16 = 0
private let MODIFIER_SHIFT: UInt64 = 131072      // NSEventModifierFlagShift
private let MODIFIER_COMMAND: UInt64 = 1048576   // NSEventModifierFlagCommand

private let ROW_SCOPE = CjguiComposableUiIdentityScope("keyboard-probe-rows")

private class KeyboardProbeTreeSource <: CjguiComposableUiTreeDataSource {
    // One non-selectable group with four selectable leaves, so a range, a
    // collapse and a select-all all have something real to act on.
    public func childCount(parentKey: String): Int64 {
        if (parentKey.size == 0) {
            return 1
        }
        if (parentKey == "group-a") {
            return 4
        }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        if (parentKey.size == 0) {
            return CjguiComposableUiTreeNode("group-a", "组 A", 100, true, selectable: false)
        }
        return CjguiComposableUiTreeNode("leaf-${index + 1}", "条目 ${index + 1}", index + 1, false)
    }
}

private class KeyboardProbeController <: CjguiComposableUiController {
    private let projection: CjguiComposableUiTreeProjection
    private let selection: CjguiComposableUiTreeSelection
    private let listState: CjguiComposableUiVirtualListState
    private var version: Int64 = 1
    private var lastKind: Int64 = -1
    private var lastAction: String = ""
    private var lastText: String = ""
    private var lastFlags: Int64 = -2
    // Every delivery since the last reset, so a Command chord that produces a
    // declared shortcut plus the generic navigation route is visible instead of
    // collapsing to "the last one".
    private let delivered: ArrayList<String> = ArrayList<String>()

    public init() {
        this.projection = CjguiComposableUiTreeProjection(KeyboardProbeTreeSource())
        this.selection = CjguiComposableUiTreeSelection(this.projection)
        this.listState = CjguiComposableUiVirtualListState()
        // Expand once here: doing it in buildUi would re-expand the group on
        // every rebuild and silently undo the keyboard collapse.
        let _ = this.projection.setExpanded("group-a", true)
    }

    public func uiSceneVersion(): Int64 {
        return version
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "keyboard-probe-root", CjguiComposableUiStyle(gap: 4))
        let listSource = CjguiComposableUiTreeListSource(projection, selection,
            { row, isSelected, isFocused =>
                cjguiComposableButton(0, "keyboard-probe-row-${row.key}", row.label, "PROBE_ROW", row.resourceId,
                    CjguiComposableUiStyle(fixedHeight: 24),
                    identity: Some(ROW_SCOPE.child(row.key).local("row")))
            })
        root.add(cjguiComposableVirtualList(2, "keyboard-probe-list", 3, listSource, listState, 26, 2, 2,
            CjguiComposableUiStyle(fixedHeight: 160)))
        root.add(cjguiComposableTextInput(4, "keyboard-probe-text", "文本", "abc", 77,
            CjguiComposableUiStyle(fixedHeight: 24), fieldId: "probe"))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        lastKind = event.eventKind
        lastAction = event.node.actionName
        lastText = event.text
        lastFlags = event.modifierFlags
        delivered.add("kind=${event.eventKind}:text=${event.text}:flags=${event.modifierFlags}")
        if (event.eventKind == 27 && event.node.actionName == "PROBE_ROW") {
            let key = keyForResource(event.node.resourceId)
            if (key.size == 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            selection.click(key, (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0,
                (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0)
            version += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35) {
            let result = selection.navigate(event.text, (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0)
            if (result.didChange) {
                version += 1
            } else {
                return CjguiComposableUiDispatchResult(false)
            }
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        lastKind = eventKind
        lastAction = "rejected"
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func keyForResource(resourceId: Int64): String {
        var index: Int64 = 0
        while (index < projection.rowCount()) {
            let row = projection.rowAt(index)
            if (row.resourceId == resourceId) {
                return row.key
            }
            index += 1
        }
        return ""
    }

    public func resetRecording(): Unit {
        lastKind = -1
        lastAction = ""
        lastText = ""
        lastFlags = -2
        delivered.clear()
    }

    /// Whether a navigation with this command was delivered since the reset.
    public func sawNavigation(command: String): Bool {
        for (entry in delivered) {
            if (entry.startsWith("kind=35:") && entry.contains(":text=${command}:")) {
                return true
            }
        }
        return false
    }

    public func deliveryLog(): String {
        let builder = StringBuilder()
        for (entry in delivered) {
            builder.append(entry)
            builder.append(" ")
        }
        return builder.toString()
    }

    public func recordedKind(): Int64 { return lastKind }
    public func recordedAction(): String { return lastAction }
    public func recordedText(): String { return lastText }
    public func recordedFlags(): Int64 { return lastFlags }
    public func focus(): String { return selection.focus() }
    public func anchor(): String { return selection.anchor() }
    public func selectedCount(): Int64 { return selection.selectedCount() }
    public func isSelected(key: String): Bool { return selection.isSelected(key) }
    public func rowCount(): Int64 { return projection.rowCount() }
}

private func dispatchKey(keyCode: UInt16, modifiers: UInt64, characters: String): Int32 {
    let nativeText = unsafe { LibC.mallocCString(characters) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_dispatch_current_composable_key(
                keyCode, modifiers, textResource.value)
        }
    }
    return status
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
    let controller = KeyboardProbeController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start() || !window.refresh()) {
        println("CJGUI_KEYBOARD_NAV start=false reason=${window.windowProjection().pendingRefreshReason} " +
            "failure=${window.windowProjection().lastNativeFailure}")
        window.close()
        return 1
    }
    let session = window.testSessionToken()

    // Locate the row button for leaf-1 (pressing it also gives the list the
    // native focus, exactly like a human click) and the text input.
    var rowIndex: UInt32 = 0
    var rowFound = false
    var textIndex: UInt32 = 0
    var textFound = false
    var index: UInt32 = 0
    while (index < 24) {
        if (!rowFound) {
            controller.resetRecording()
            let _ = unsafe { cjgui_internal_renderer_test_press_composable_node(session, index) }
            let _ = window.pump(0u32)
            if (controller.recordedAction() == "PROBE_ROW" && controller.keyForResource(1) == "leaf-1" &&
                controller.recordedKind() == 27 && controller.focus() == "leaf-1") {
                rowIndex = index
                rowFound = true
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
    if (!rowFound || !textFound) {
        println("CJGUI_KEYBOARD_NAV located=false row=${rowFound} text=${textFound}")
        window.close()
        return 1
    }
    // Start from a known state: leaf-1 focused and selected by the row press.
    let startOk = controller.focus() == "leaf-1" && controller.isSelected("leaf-1") &&
        controller.selectedCount() == 1
    println("CJGUI_KEYBOARD_NAV start_state ok=${startOk} row_index=${rowIndex} focus=${controller.focus()} " +
        "selected=${controller.selectedCount()}")

    // 1. Unmodified Down: focus moves, selection does not.
    controller.resetRecording()
    let downStatus = dispatchKey(KEY_DOWN, 0, "\u{F701}")
    let _ = window.pump(0u32)
    let downOk = downStatus == CJGUI_INTERNAL_RENDERER_OK && controller.recordedKind() == 35 &&
        controller.recordedText() == "down" && controller.recordedFlags() == 0 &&
        controller.focus() == "leaf-2" && controller.selectedCount() == 1 && controller.isSelected("leaf-1")
    println("CJGUI_KEYBOARD_NAV down ok=${downOk} status=${downStatus} kind=${controller.recordedKind()} " +
        "text=${controller.recordedText()} flags=${controller.recordedFlags()} focus=${controller.focus()} " +
        "selected=${controller.selectedCount()}")

    // 2. Shift+Down reaches the controller with the key event's Shift payload.
    controller.resetRecording()
    let shiftDownStatus = dispatchKey(KEY_DOWN, MODIFIER_SHIFT, "\u{F701}")
    let _ = window.pump(0u32)
    let shiftDownOk = shiftDownStatus == CJGUI_INTERNAL_RENDERER_OK && controller.recordedKind() == 35 &&
        controller.recordedText() == "down" && controller.recordedFlags() == Int64(MODIFIER_SHIFT) &&
        controller.anchor() == "leaf-1" && controller.focus() == "leaf-3" && controller.selectedCount() == 3 &&
        controller.isSelected("leaf-1") && controller.isSelected("leaf-3")
    println("CJGUI_KEYBOARD_NAV shift_down ok=${shiftDownOk} status=${shiftDownStatus} " +
        "flags=${controller.recordedFlags()} anchor=${controller.anchor()} focus=${controller.focus()} " +
        "selected=${controller.selectedCount()}")

    // 3. Shift+Up shrinks the same range in reverse.
    controller.resetRecording()
    let shiftUpStatus = dispatchKey(KEY_UP, MODIFIER_SHIFT, "\u{F700}")
    let _ = window.pump(0u32)
    let shiftUpOk = shiftUpStatus == CJGUI_INTERNAL_RENDERER_OK && controller.recordedText() == "up" &&
        controller.recordedFlags() == Int64(MODIFIER_SHIFT) && controller.anchor() == "leaf-1" &&
        controller.focus() == "leaf-2" && controller.selectedCount() == 2
    println("CJGUI_KEYBOARD_NAV shift_up ok=${shiftUpOk} status=${shiftUpStatus} anchor=${controller.anchor()} " +
        "focus=${controller.focus()} selected=${controller.selectedCount()}")

    // 3b. Native focus follows the model focus through the public
    //     focus-by-identity entry, so the next key event is routed at the row
    //     the tree model actually focused.
    let followedFocus = window.focusScopedNode(ROW_SCOPE.child("leaf-2"), "row")
    let followedProjection = window.windowProgress().focusedControlId
    let followsOk = followedFocus && followedProjection == "keyboard-probe-row-leaf-2"
    println("CJGUI_KEYBOARD_NAV focus_follows ok=${followsOk} resolved=${followedFocus} " +
        "focused_control=${followedProjection}")

    // 4. Left ascends to the group, the next Left collapses it, Right expands.
    controller.resetRecording()
    let leftStatus = dispatchKey(KEY_LEFT, 0, "\u{F702}")
    let _ = window.pump(0u32)
    let ascendOk = leftStatus == CJGUI_INTERNAL_RENDERER_OK && controller.sawNavigation("left") &&
        controller.focus() == "group-a"
    controller.resetRecording()
    let collapseStatus = dispatchKey(KEY_LEFT, 0, "\u{F702}")
    let _ = window.pump(0u32)
    let collapsedRows = controller.rowCount()
    let collapseOk = collapseStatus == CJGUI_INTERNAL_RENDERER_OK && controller.sawNavigation("left") &&
        collapsedRows == 1 && controller.focus() == "group-a"
    controller.resetRecording()
    let expandStatus = dispatchKey(KEY_RIGHT, 0, "\u{F703}")
    let _ = window.pump(0u32)
    // The collapse removed the row that held the native focus. This expand is
    // the regression guard for the re-anchor: without it the next key event is
    // dropped before it can reach the model.
    let expandOk = expandStatus == CJGUI_INTERNAL_RENDERER_OK && controller.sawNavigation("right") &&
        controller.rowCount() == 5
    println("CJGUI_KEYBOARD_NAV left_right ok=${ascendOk && collapseOk && expandOk} " +
        "ascend=${ascendOk} collapse=${collapseOk} collapsed_rows=${collapsedRows} expand=${expandOk} " +
        "rows=${controller.rowCount()} status=${leftStatus}/${collapseStatus}/${expandStatus}")

    // 5. End and Home move the focus to the last and first visible rows.
    controller.resetRecording()
    let endStatus = dispatchKey(KEY_END, 0, "\u{F72B}")
    let _ = window.pump(0u32)
    let endOk = endStatus == CJGUI_INTERNAL_RENDERER_OK && controller.recordedText() == "end" &&
        controller.focus() == "leaf-4"
    controller.resetRecording()
    let homeStatus = dispatchKey(KEY_HOME, 0, "\u{F729}")
    let _ = window.pump(0u32)
    let homeOk = homeStatus == CJGUI_INTERNAL_RENDERER_OK && controller.recordedText() == "home" &&
        controller.focus() == "group-a"
    println("CJGUI_KEYBOARD_NAV home_end ok=${homeOk && endOk} end=${endOk} home=${homeOk} " +
        "status=${endStatus}/${homeStatus}")

    // 6. Command-A over the tree reaches the controller as select_all.
    controller.resetRecording()
    let selectAllStatus = dispatchKey(KEY_A, MODIFIER_COMMAND, "a")
    let _ = window.pump(0u32)
    let selectAllOk = selectAllStatus == CJGUI_INTERNAL_RENDERER_OK &&
        controller.sawNavigation("select_all") && controller.selectedCount() == 4 &&
        !controller.isSelected("group-a")
    println("CJGUI_KEYBOARD_NAV select_all ok=${selectAllOk} status=${selectAllStatus} " +
        "selected=${controller.selectedCount()} delivered='${controller.deliveryLog()}'")

    // 7. The same chord with the text input focused is not tree navigation.
    let textPressStatus = unsafe { cjgui_internal_renderer_test_press_composable_node(session, textIndex) }
    let _ = window.pump(0u32)
    controller.resetRecording()
    let textSelectAllStatus = dispatchKey(KEY_A, MODIFIER_COMMAND, "a")
    let _ = window.pump(0u32)
    let textScopeOk = textPressStatus == CJGUI_INTERNAL_RENDERER_OK &&
        !controller.sawNavigation("select_all")
    println("CJGUI_KEYBOARD_NAV text_scope ok=${textScopeOk} press=${textPressStatus} " +
        "cmd_a_status=${textSelectAllStatus} delivered='${controller.deliveryLog()}'")

    let passed = startOk && downOk && shiftDownOk && shiftUpOk && followsOk && ascendOk && collapseOk &&
        expandOk && endOk && homeOk && selectAllOk && textScopeOk
    println("CJGUI_KEYBOARD_NAV passed=${passed}")
    window.close()
    return if (passed) { 0 } else { 1 }
}
