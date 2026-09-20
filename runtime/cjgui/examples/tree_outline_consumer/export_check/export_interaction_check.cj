// Exported UI-only consumer interaction chain.
//
// The export chain copies this file into an exported consumer round whose
// application entry has been renamed, so it compiles in the SAME package as the
// exported controller and drives that controller's real event entry. It proves
// the export is consumable for interaction, not only for building and starting:
// the tree expands, keyboard navigation moves focus and selection with the key
// event's own modifiers, select-all is exact, and left/right collapse and expand
// the focused group - all through the public framework APIs the consumer uses.
//
// Output is line-oriented so the shell chain can assert exact values.
package cjgui_ui_only_starter

import cjgui.*
import std.collection.*

private func exportCheckEvent(kind: Int64, text: String, modifiers: Int64): CjguiComposableUiEvent {
    let bounds = CjguiComposableUiRect(0, 0, 320, 240)
    let declared = CjguiComposableUiNode(CJGUI_CATALOG_LIST_NODE_ID, "catalog-tree-list",
        CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1, CjguiComposableUiStyle(),
        virtualListSource: Some(EmptyExportListSource()), virtualListRowHeight: 30,
        virtualListOverscan: 4, virtualListContentNodeId: 28)
    let node = CjguiComposableUiLayoutNode(declared, bounds, bounds)
    return CjguiComposableUiEvent(node, kind, text, 0, 0, 1, modifierFlags: modifiers)
}

private func exportCheckKeys(controller: CatalogController): String {
    let keys = ArrayList<String>(controller.selectedKeys())
    // Deterministic order for the shell comparison: lexicographic, comma joined.
    var outer: Int64 = 1
    while (outer < keys.size) {
        let value = keys[outer]
        var inner = outer - 1
        while (inner >= 0 && keys[inner] > value) {
            keys[inner + 1] = keys[inner]
            inner -= 1
        }
        keys[inner + 1] = value
        outer += 1
    }
    let builder = StringBuilder()
    for (key in keys) {
        builder.append(key)
        builder.append(",")
    }
    return builder.toString()
}

private func exportCheckReport(label: String, controller: CatalogController): Unit {
    println("EXPORT_TREE_CHAIN ${label} focus=${controller.focusKey()} anchor=${controller.anchorKey()} " +
        "keys=${exportCheckKeys(controller)} rows=${controller.visibleRowCount()} " +
        "selected=${controller.selectedCount()}")
}

main(): Int64 {
    let domains = ArrayList<String>(["导出甲", "导出乙"])
    let source = CatalogSource(domains, 2, 2)
    let controller = CatalogController(source)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start() || !window.refresh()) {
        println("EXPORT_TREE_CHAIN start=false reason=${window.windowProjection().pendingRefreshReason}")
        return 1
    }
    println("EXPORT_TREE_CHAIN ready rows=${controller.visibleRowCount()}")

    // Expand the whole catalog through the controller's own public entry. One
    // call expands the groups currently projected, so a second call reaches the
    // next level (domains, then topics).
    controller.expandAll()
    let _ = window.refreshIfNeeded()
    controller.expandAll()
    let _ = window.refreshIfNeeded()
    exportCheckReport("expanded", controller)

    // Keyboard navigation enters through the same event entry the window uses.
    // Three steps reach the first selectable entry (domain, topic, entry).
    var step: Int64 = 0
    while (step < 3) {
        let _ = controller.applyUiEvent(exportCheckEvent(35, "down", 0))
        let _ = window.refreshIfNeeded()
        step += 1
    }
    exportCheckReport("down", controller)

    // A real Shift payload extends the range from the anchor: the focused entry
    // plus the traversed selectable rows.
    let _ = controller.applyUiEvent(exportCheckEvent(35, "down", CJGUI_UI_MODIFIER_SHIFT))
    let _ = window.refreshIfNeeded()
    exportCheckReport("shift_down", controller)

    // Select-all covers every visible selectable row.
    let _ = controller.applyUiEvent(exportCheckEvent(35, "select_all", CJGUI_UI_MODIFIER_COMMAND))
    let _ = window.refreshIfNeeded()
    exportCheckReport("select_all", controller)

    // Home, then left collapses the focused group and right expands it again.
    let _ = controller.applyUiEvent(exportCheckEvent(35, "home", 0))
    let _ = window.refreshIfNeeded()
    exportCheckReport("home", controller)
    let rowsExpanded = controller.visibleRowCount()
    let _ = controller.applyUiEvent(exportCheckEvent(35, "left", 0))
    let _ = window.refreshIfNeeded()
    let rowsCollapsed = controller.visibleRowCount()
    exportCheckReport("left", controller)
    let _ = controller.applyUiEvent(exportCheckEvent(35, "right", 0))
    let _ = window.refreshIfNeeded()
    exportCheckReport("right", controller)
    println("EXPORT_TREE_CHAIN collapse rows_expanded=${rowsExpanded} rows_collapsed=${rowsCollapsed} " +
        "rows_reexpanded=${controller.visibleRowCount()}")

    // End reaches the last visible row and keeps the window scene consistent.
    let _ = controller.applyUiEvent(exportCheckEvent(35, "end", 0))
    let _ = window.refreshIfNeeded()
    exportCheckReport("end", controller)
    let progress = window.windowProgress()
    println("EXPORT_TREE_CHAIN window scene=${progress.sceneVersion} accepted=${progress.acceptedSceneVersion} " +
        "submitted=${progress.submittedSceneVersion} failure=${progress.lastNativeFailure}")
    window.close()
    return 0
}

/// The event entry only needs the list node identity, not a live list source.
private class EmptyExportListSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 0 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem.missing()
    }
    public func indexForKey(key: String): Int64 { return -1 }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(1, "export-check-row", "", CjguiComposableUiStyle())
    }
}
