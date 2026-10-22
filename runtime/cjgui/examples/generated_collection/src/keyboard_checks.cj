package cjgui_generated_collection

import cjgui.*

// Pure owner/selection checks, separate from native responder and actual VO.
func checkKeyboard(controller: CollectionController): Int64 {
    let viewport = controller.collection.viewport
    let declaration = CjguiComposableUiNode(8, "manual-collection", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL",
        -1, CjguiComposableUiStyle(), scrollViewport: Some(viewport))
    let rect = CjguiComposableUiRect(0, 0, 400, 360)
    let node = CjguiComposableUiLayoutNode(declaration, rect, rect)
    if (!controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "home", 0, 0, 1)).didApply ||
        controller.domain.selectedRecordId() != 1 || controller.collection.selection.focus() != "rule_1") {
        return 31
    }
    if (!controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "end", 0, 0, 1)).didApply ||
        controller.domain.selectedRecordId() != 80 || controller.collection.selection.focus() != "rule_80") {
        return 32
    }
    if (!controller
        .applyUiEvent(CjguiComposableUiEvent(node, 35, "up", 0, 0, 1, modifierFlags: CJGUI_UI_MODIFIER_SHIFT))
        .didApply || controller.domain.selectedRecordId() != 79 || controller.collection.selection.selectedCount() != 2) {
        return 33
    }
    let beforeOwner = controller.domain.version()
    let beforeSelection = controller.collection.selection.selectionVersion()
    if (controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "unknown", 0, 0, 1)).didApply ||
        controller.domain.version() != beforeOwner || controller.collection.selection.selectionVersion() !=
        beforeSelection) {
        return 34
    }
    let otherList = CjguiComposableUiLayoutNode(
        CjguiComposableUiNode(99, "other-list", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
            CjguiComposableUiStyle(), scrollViewport: Some(CjguiComposableUiScrollViewport())), rect, rect)
    if (controller.applyUiEvent(CjguiComposableUiEvent(otherList, 35, "home", 0, 0, 1)).didApply ||
        controller.domain.version() != beforeOwner || controller.collection.selection.selectionVersion() !=
        beforeSelection) {
        return 35
    }
    let focusNode = CjguiComposableUiLayoutNode(
        cjguiComposableButton(100, "focus-rule-5", "规则5", "SELECT_RECORD", 5, CjguiComposableUiStyle()), rect, rect)
    if (!controller.applyUiEvent(CjguiComposableUiEvent(focusNode, 31, "", 0, 0, 1)).didApply ||
        controller.domain.version() != beforeOwner || controller.collection.selection.focus() != "rule_5") {
        return 36
    }
    if (!controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "down", 0, 0, 1)).didApply ||
        controller.domain.selectedRecordId() != 6) {
        return 37
    }
    // Opening help before any text focus has no selection bookmark. Its
    // return address must be the real trigger, so closing never depends on
    // restoring a text field that the user has not entered.
    let help = CjguiComposableUiLayoutNode(
        cjguiComposableButton(41, "collection-edit-help", "编辑说明", "OPEN_EDIT_HELP", -1,
            CjguiComposableUiStyle()), rect, rect)
    if (!controller.applyUiEvent(CjguiComposableUiEvent(help, 27, "", 0, 0, 1)).didApply) { return 38 }
    let helpTree = controller.buildUi()
    let identities = CjguiComposableUiIdentityRegistry()
    if (!identities.beginCandidate() || identities.resolveCandidate(helpTree).size > 0) { return 39 }
    if (helpTree.children().size != 2 || helpTree.children()[1].layerAnchorNodeId() != 41) { return 40 }
    if (!controller.applyUiEvent(CjguiComposableUiEvent(help, 36, "escape", 0, 0, 1)).didApply ||
        controller.buildUi().children().size != 1) { return 41 }
    println(
        "KEYBOARD_CHECKS_OK stable_key_home_end shift_range unknown_no_write foreign_viewport_no_write focus_no_owner_write")
    return 0
}
