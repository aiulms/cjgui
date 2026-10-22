// Column layout and interaction tests for the public table projection.
// These use only public table/layout APIs: no app controller, no native module.
package cjgui

import std.collection.*

private class TableLayoutTestSource <: CjguiComposableUiVariableHeightListSource {
    private let items: Array<CjguiComposableUiVariableHeightListItem>
    var itemReadCount: Int64 = 0

    init(items: Array<CjguiComposableUiVariableHeightListItem>) {
        this.items = items
    }

    public func itemCount(): Int64 {
        return items.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        itemReadCount += 1
        if (index < 0 || index >= items.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return items[index]
    }

    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < items.size) {
            if (items[index].key == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(920000, "layout-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 30))
    }
}

private func layoutTestRows(count: Int64): Array<CjguiComposableUiVariableHeightListItem> {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < count) {
        rows.add(CjguiComposableUiVariableHeightListItem("row_${index}", index, "规则 ${index}", 0,
            estimatedHeight: 30))
        index += 1
    }
    return rows.toArray()
}

private func layoutTestColumn(key: String, title: String, width: Int64,
    minWidth!: Int64 = 56, maxWidth!: Int64 = 480): CjguiComposableUiTableColumn {
    return CjguiComposableUiTableColumn(key, title, key, width, "SORT_${key}",
        { item => item.title }, { _, _ => 0 }, minWidth: minWidth, maxWidth: maxWidth)
}

private func layoutTestColumns(): Array<CjguiComposableUiTableColumn> {
    let columns = ArrayList<CjguiComposableUiTableColumn>()
    columns.add(layoutTestColumn("name", "名称", 0))
    columns.add(layoutTestColumn("status", "状态", 68))
    columns.add(layoutTestColumn("detail", "详情", 96))
    return columns.toArray()
}

private func layoutTestStyle(): CjguiComposableUiTableStyle {
    return CjguiComposableUiTableStyle(30, 30, 6, 11.5, "PingFang SC",
        CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0),
        CjguiComposableUiColor(0.96, 0.96, 0.96, 1.0), CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0),
        CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        CjguiComposableUiColor(0.4, 0.4, 0.4, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0))
}

private func layoutTestTable(layout!: ?CjguiComposableUiTableColumnLayout = None):
    CjguiComposableUiTableSource {
    let base = TableLayoutTestSource(layoutTestRows(4))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    return CjguiComposableUiTableSource(filtered, "layout-table", layoutTestColumns(),
        layoutTestStyle(), layout: layout)
}

private func layoutTestScene(table: CjguiComposableUiTableSource,
    state: CjguiComposableUiVirtualListState, version: Int64,
    registry: CjguiComposableUiIdentityRegistry): CjguiComposableUiScene {
    let root = cjguiComposableVertical(900000, "layout-root",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    root.add(table.buildHeader())
    root.add(cjguiComposableVariableHeightList(900001, "layout-list", 900002, table, state,
        30, 1, 3, CjguiComposableUiStyle(growX: 1, growY: 1)))
    let rect = CjguiComposableUiRect(0, 0, 640, 240)
    let _ = registry.beginCandidate()
    let resolveIssue = registry.resolveCandidate(root)
    @Assert(resolveIssue.size, 0)
    let replaceIssue = registry.replaceCandidateRoot(root)
    @Assert(replaceIssue.size, 0)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    @Assert(registry.prepareCandidate(), true)
    let _ = registry.commitCandidate()
    return scene
}

private func layoutNodeBySemantic(scene: CjguiComposableUiScene,
    semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

// A table can occupy less than the outer scene. Leave the pane itself unclipped
// so the table's own row/header clipping must protect the adjacent detail.
private func narrowTableScene(table: CjguiComposableUiTableSource, width: Int64,
    version: Int64, registry: CjguiComposableUiIdentityRegistry): CjguiComposableUiScene {
    let root = cjguiComposableHorizontal(910000, "narrow-table-root", CjguiComposableUiStyle())
    let pane = cjguiComposableVertical(910001, "narrow-table-pane",
        CjguiComposableUiStyle(fixedWidth: width, fixedHeight: 200))
    pane.add(table.buildHeader())
    let state = CjguiComposableUiVirtualListState()
    state.setSelectedKey("row_0")
    pane.add(cjguiComposableVariableHeightList(910003, "narrow-table-list", 910004, table, state,
        30, 1, 3, CjguiComposableUiStyle(growX: 1, growY: 1)))
    root.add(pane)
    root.add(cjguiComposableButton(910002, "narrow-table-detail", "详情", "DETAIL", 10,
        CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 200)))
    let scroll = cjguiComposableScrollArea(910005, "narrow-table-outer-scroll",
        CjguiComposableUiScrollViewport(), CjguiComposableUiStyle(growX: 1, growY: 1))
    scroll.add(root)
    let _ = registry.beginCandidate()
    @Assert(registry.resolveCandidate(scroll), "")
    @Assert(registry.replaceCandidateRoot(scroll), "")
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(scroll,
        CjguiComposableUiRect(0, 0, 1000, 200), version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    @Assert(scene.layoutError(), "")
    @Assert(registry.prepareCandidate(), true)
    let _ = registry.commitCandidate()
    return scene
}

@Test
func tableNarrowGeometryUsesSameColumnsAndPreservesStableIdentity(): Unit {
    let table = layoutTestTable()
    let registry = CjguiComposableUiIdentityRegistry()
    let before = narrowTableScene(table, 520, 1, registry)
    let key = "layout-table-cell-row_0-detail"
    let original = layoutNodeBySemantic(before, key).getOrThrow()
    let _ = table.layout().nudgeWidth("status", 16)
    let revision = table.layout().revision()
    let narrow = narrowTableScene(table, 320, 2, registry)
    for (column in ["name", "status", "detail"]) {
        let header = layoutNodeBySemantic(narrow, "layout-table-header-cell-${column}").getOrThrow()
        let body = layoutNodeBySemantic(narrow, "layout-table-cell-row_0-${column}").getOrThrow()
        @Assert(header.bounds.x, body.bounds.x)
        @Assert(header.bounds.width, body.bounds.width)
    }
    let after = narrowTableScene(table, 520, 3, registry)
    let restored = layoutNodeBySemantic(after, key).getOrThrow()
    @Assert(restored.nodeId, original.nodeId)
    @Assert(restored.semanticIncarnation, original.semanticIncarnation)
    @Assert(table.layout().revision(), revision)
    @Assert(table.layout().width("status"), 84)
    @Assert(table.minimumContentWidth(), 236)
}

@Test
func tableNarrowOversizedColumnsClipPaintAndHitWithoutChangingPreferences(): Unit {
    let table = layoutTestTable()
    let _ = table.layout().setWidth("status", 480)
    let _ = table.layout().setWidth("detail", 480)
    let revision = table.layout().revision()
    let scene = narrowTableScene(table, 320, 1, CjguiComposableUiIdentityRegistry())
    @Assert(table.minimumContentWidth(), 1016)
    for (node in scene.nodes()) {
        if (node.semanticId.startsWith("layout-table-header-") ||
            node.semanticId.startsWith("layout-table-cell-")) {
            @Assert(node.clip.width == 0 || node.clip.x + node.clip.width <= 320, true)
        }
    }
    @Assert(scene.hitTest(340, 15).actionName, "DETAIL")
    @Assert(scene.hitTest(340, 45).actionName, "DETAIL")
    @Assert(table.layout().width("status"), 480)
    @Assert(table.layout().width("detail"), 480)
    @Assert(table.layout().revision(), revision)
}

@Test
func tableColumnLayoutSharesHeaderBodyWidthsAndKeepsOldConstructor(): Unit {
    let table = layoutTestTable()
    let layout = table.layout()
    @Assert(table.columnCount(), 3)
    @Assert(layout.revision(), 0)
    var header = table.buildHeader()
    var row = table.buildRow(table.itemAt(0), false, false)
    @Assert(header.children().size, 3)
    @Assert(row.children().size, 3)
    var index: Int64 = 0
    while (index < 3) {
        @Assert(header.children()[index].style.fixedWidth, row.children()[index].style.fixedWidth)
        @Assert(header.children()[index].style.growX, row.children()[index].style.growX)
        @Assert(header.children()[index].style.padding, row.children()[index].style.padding)
        index += 1
    }
    // The old constructor created an internal layout, so the caller can still
    // opt into layout edits through the public accessor.
    @Assert(layout.width("status"), 68)
    @Assert(layout.setWidth("status", 120), true)
    @Assert(layout.revision(), 1)
    header = table.buildHeader()
    row = table.buildRow(table.itemAt(0), false, false)
    @Assert(header.children()[1].style.fixedWidth, 120)
    @Assert(row.children()[1].style.fixedWidth, 120)
    @Assert(table.itemCount(), 4)
    @Assert(table.indexForKey("row_2"), 2)
    // Clamp to the declared bounds and restore the declaration width.
    @Assert(layout.setWidth("status", 1), true)
    @Assert(layout.width("status"), 56)
    @Assert(layout.setWidth("status", 9999), true)
    @Assert(layout.width("status"), 480)
    @Assert(layout.resetWidth("status"), true)
    @Assert(layout.width("status"), 68)
}

@Test
func tableColumnLayoutHidesAndReordersWithoutChangingRowIdentity(): Unit {
    let table = layoutTestTable()
    let layout = table.layout()
    let state = CjguiComposableUiVirtualListState()
    let registry = CjguiComposableUiIdentityRegistry()
    let before = layoutTestScene(table, state, 1, registry)
    let rowBefore = layoutNodeBySemantic(before, "layout-table-row-row_0")
    let detailBefore = layoutNodeBySemantic(before, "layout-table-cell-row_0-detail")
    let gripBefore = layoutNodeBySemantic(before, "layout-table-header-resize-status")
    @Assert(tableOptionPresent(rowBefore), true)
    @Assert(tableOptionPresent(detailBefore), true)
    @Assert(tableOptionPresent(gripBefore), true)

    @Assert(layout.setVisible("status", false), true)
    @Assert(table.columnCount(), 2)
    var header = table.buildHeader()
    var row = table.buildRow(table.itemAt(0), false, false)
    @Assert(header.children().size, 2)
    @Assert(row.children().size, 2)
    @Assert(layout.width("status"), 68)
    // The hidden column keeps its declaration entry and can be shown again.
    @Assert(layout.columnKeys(), ArrayList<String>(["name", "status", "detail"]))
    @Assert(layout.setVisible("status", true), true)
    @Assert(layout.move("detail", -2), true)
    @Assert(layout.visibleKeys(), ArrayList<String>(["detail", "name", "status"]))
    header = table.buildHeader()
    row = table.buildRow(table.itemAt(0), false, false)
    @Assert(header.children()[0].semanticId, "layout-table-header-cell-detail")
    @Assert(row.children()[0].semanticId, "layout-table-cell-row_0-detail")

    let after = layoutTestScene(table, state, 2, registry)
    let rowAfter = layoutNodeBySemantic(after, "layout-table-row-row_0")
    let detailAfter = layoutNodeBySemantic(after, "layout-table-cell-row_0-detail")
    @Assert(tableOptionPresent(rowAfter), true)
    @Assert(tableOptionPresent(detailAfter), true)
    var rowIdBefore: Int64 = -1
    var rowIdAfter: Int64 = -1
    var detailIdBefore: Int64 = -1
    var detailIdAfter: Int64 = -1
    if (let Some(node) <- rowBefore) { rowIdBefore = node.nodeId }
    if (let Some(node) <- rowAfter) { rowIdAfter = node.nodeId }
    if (let Some(node) <- detailBefore) { detailIdBefore = node.nodeId }
    if (let Some(node) <- detailAfter) { detailIdAfter = node.nodeId }
    @Assert(rowIdBefore, rowIdAfter)
    @Assert(detailIdBefore, detailIdAfter)
    // The last visible column cannot be hidden.
    @Assert(layout.setVisible("name", false), true)
    @Assert(layout.setVisible("status", false), true)
    @Assert(layout.setVisible("detail", false), false)
    @Assert(layout.visibleCount(), 1)
}

@Test
func tableColumnLayoutDragClampsAndCancelRestores(): Unit {
    let table = layoutTestTable()
    let layout = table.layout()
    @Assert(layout.beginResize("status", 100, 68), true)
    @Assert(layout.resizeActive(), true)
    @Assert(layout.resizingKey(), "status")
    @Assert(layout.updateResize(140), 108)
    @Assert(layout.width("status"), 108)
    @Assert(layout.updateResize(1000), 480)
    @Assert(layout.updateResize(0), 56)
    @Assert(layout.endResize(), 56)
    @Assert(layout.resizeActive(), false)
    let versionAfterDrag = layout.revision()
    @Assert(versionAfterDrag > 0, true)
    @Assert(layout.beginResize("status", 200, 56), true)
    @Assert(layout.updateResize(230), 86)
    @Assert(layout.cancelResize(), 56)
    @Assert(layout.width("status"), 56)
    @Assert(layout.revision(), versionAfterDrag + 2)
    // Flexible and hidden columns have no draggable resolved width.
    @Assert(layout.beginResize("name", 10, 200), false)
    @Assert(layout.setVisible("detail", false), true)
    @Assert(layout.beginResize("detail", 10, 96), false)
}

@Test
func tableColumnLayoutLeavesSortFilterAndSelectionUntouched(): Unit {
    let table = layoutTestTable()
    let layout = table.layout()
    @Assert(table.setSort("detail"), true)
    @Assert(table.setQuery("规则 1"), true)
    @Assert(table.itemCount(), 1)
    let beforeKey = table.itemAt(0).key
    let selection = CjguiComposableUiCollectionSelection()
    let order = CjguiComposableUiFlatCollectionOrder(table, { item => item.resourceId >= 0 })
    selection.click(beforeKey, false, false, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>([beforeKey]))
    @Assert(layout.setWidth("status", 140), true)
    @Assert(layout.setVisible("name", false), true)
    @Assert(layout.move("detail", -1), true)
    @Assert(table.sortColumnKey(), "detail")
    @Assert(table.sortAscending(), true)
    @Assert(table.itemCount(), 1)
    @Assert(table.itemAt(0).key, beforeKey)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>([beforeKey]))
    @Assert(table.layoutRevision(), layout.revision())
}

@Test
func tableDifferentColumnDefinitionsUseTheSameLayout(): Unit {
    // A minimal independent consumer with different names, widths and bounds.
    let base = TableLayoutTestSource(layoutTestRows(3))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let columnsList = ArrayList<CjguiComposableUiTableColumn>()
    columnsList.add(CjguiComposableUiTableColumn("id", "标识", "id", 64, "", { item => item.key },
        { _, _ => 0 }, minWidth: 48, maxWidth: 120))
    columnsList.add(CjguiComposableUiTableColumn("metric", "数值", "metric", 0, "",
        { item => item.title }, { _, _ => 0 }, minWidth: 80, maxWidth: 260))
    columnsList.add(CjguiComposableUiTableColumn("note", "备注", "note", 120, "",
        { item => "备注" }, { _, _ => 0 }, minWidth: 64, maxWidth: 200))
    let columns = columnsList.toArray()
    let layout = CjguiComposableUiTableColumnLayout(columns)
    let table = CjguiComposableUiTableSource(filtered, "consumer-table", columns,
        layoutTestStyle(), layout: layout)
    let header = table.buildHeader()
    let row = table.buildRow(table.itemAt(0), false, false)
    @Assert(header.children().size, 3)
    @Assert(row.children().size, 3)
    @Assert(layout.setWidth("id", 500), true)
    @Assert(layout.width("id"), 120)
    @Assert(layout.setVisible("note", false), true)
    @Assert(layout.move("metric", -1), true)
    @Assert(layout.visibleKeys(), ArrayList<String>(["metric", "id"]))
    @Assert(table.buildHeader().children()[0].semanticId, "consumer-table-header-cell-metric")
    @Assert(table.buildRow(table.itemAt(0), false, false).children()[0].semanticId,
        "consumer-table-cell-row_0-metric")
    @Assert(layout.encodeState().startsWith("TABLE_COLUMNS 1 | metric:"), true)
}

private func tableOptionPresent<T>(value: ?T): Bool {
    return match (value) {
        case Some(_) => true
        case None => false
    }
}

@Test
func tableColumnResizeEndAppliesFinalPointerAndCancelKeepsStart(): Unit {
    let layout = layoutTestTable().layout()
    @Assert(layout.beginResize("status", 100, 68), true)
    @Assert(layout.updateResize(120), 88)
    // END carries the gesture's terminal coordinate, which differs from the
    // last UPDATE; it must be applied before the session closes.
    @Assert(layout.endResizeAt(150), 118)
    @Assert(layout.width("status"), 118)
    @Assert(layout.resizeActive(), false)
    @Assert(layout.updateResize(200), 0)
    @Assert(layout.width("status"), 118)
    // CANCEL has no coordinate: a plain cancellation restores the start width.
    @Assert(layout.beginResize("status", 100, 118), true)
    @Assert(layout.updateResize(140), 158)
    @Assert(layout.cancelResize(), 118)
    @Assert(layout.width("status"), 118)
    @Assert(layout.resizeActive(), false)
}

@Test
func tableColumnResizeIsInvalidatedByIndependentWriteHideMoveOrReset(): Unit {
    let layout = layoutTestTable().layout()
    // Independent width write on the same column.
    @Assert(layout.beginResize("status", 80, 68), true)
    @Assert(layout.updateResize(100), 88)
    @Assert(layout.setWidth("status", 130), true)
    @Assert(layout.resizeActive(), false)
    @Assert(layout.updateResize(120), 0)
    @Assert(layout.endResizeAt(160), 0)
    @Assert(layout.cancelResize(), 0)
    @Assert(layout.width("status"), 130)
    // Hiding the dragged column invalidates the old gesture.
    @Assert(layout.beginResize("status", 80, 130), true)
    @Assert(layout.updateResize(100), 150)
    @Assert(layout.setVisible("status", false), true)
    @Assert(layout.resizeActive(), false)
    @Assert(layout.updateResize(140), 0)
    @Assert(layout.endResizeAt(140), 0)
    @Assert(layout.cancelResize(), 0)
    @Assert(layout.width("status"), 150)
    @Assert(layout.isVisible("status"), false)
    @Assert(layout.setVisible("status", true), true)
    // Reordering the dragged column also ends its old gesture.
    @Assert(layout.beginResize("status", 80, 150), true)
    @Assert(layout.updateResize(100), 170)
    @Assert(layout.move("status", -1), true)
    @Assert(layout.resizeActive(), false)
    @Assert(layout.updateResize(120), 0)
    @Assert(layout.endResizeAt(120), 0)
    @Assert(layout.cancelResize(), 0)
    @Assert(layout.width("status"), 170)
    // Reset restores declared state and invalidates the gesture.
    @Assert(layout.beginResize("status", 80, 170), true)
    @Assert(layout.updateResize(100), 190)
    @Assert(layout.reset(), true)
    @Assert(layout.resizeActive(), false)
    @Assert(layout.updateResize(140), 0)
    @Assert(layout.endResizeAt(140), 0)
    @Assert(layout.cancelResize(), 0)
    @Assert(layout.width("status"), 68)
}

private func settleTableColumnWindow(window: CjguiComposableUiWindow): Bool {
    var turns: Int64 = 0
    while (turns < 48) {
        if (window.refreshIfNeeded()) {
            return true
        }
        let _ = window.pump(0u32)
        turns += 1
    }
    return false
}

private class TableColumnCaptureController <: CjguiComposableUiController & CjguiComposableUiPointerCaptureVersionProvider {
    let layout = CjguiComposableUiTableColumnLayout(layoutTestColumns())
    var revision: Int64 = 1

    public func uiSceneVersion(): Int64 {
        return revision + layout.revision()
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.actionName == CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION) {
            return layout.resizeCaptureVersion()
        }
        return uiSceneVersion()
    }

    public func buildUi(): CjguiComposableUiNode {
        let base = TableLayoutTestSource(layoutTestRows(2))
        let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
        let table = CjguiComposableUiTableSource(filtered, "capture-table", layoutTestColumns(),
            layoutTestStyle(), layout: layout)
        let root = cjguiComposableVertical(980000, "capture-root",
            CjguiComposableUiStyle(fixedWidth: 640, fixedHeight: 60))
        root.add(table.buildHeader())
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.actionName != CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION) {
            return CjguiComposableUiDispatchResult(false)
        }
        let parts = event.node.semanticId.split("capture-table-header-resize-")
        if (parts.size != 2) {
            return CjguiComposableUiDispatchResult(false)
        }
        let key = parts[1]
        if (event.eventKind == 37) {
            return CjguiComposableUiDispatchResult(
                layout.beginResize(key, event.pointerX, layout.width(key)))
        }
        if (!layout.resizeActive() || layout.resizingKey() != key) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == 38) {
            let _ = layout.updateResize(event.pointerX)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 39) {
            let _ = layout.endResizeAt(event.pointerX)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 40) {
            let _ = layout.cancelResize()
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func tableColumnPointerEvent(kind: Int64, nodeId: Int64, version: Int64,
    pointX: Float64): InternalRendererPumpResult {
    return InternalRendererPumpResult(CJGUI_INTERNAL_RENDERER_OK, UInt32(kind), 0u32, 0u32, 0u32,
        UInt64(nodeId), UInt64(version), -1, UInt32(CJGUI_COMPOSABLE_UI_SPLIT_HANDLE), Int64(pointX), 10,
        pointX, 10.0, 0.0, 0.0, true, 0, 0u32, -1, 0, -1, 0,
        0u64, 77u64, 0u64, 0u64, 0u64, 0u64, -1, 0u64, 0u64)
}

@Test
func tableColumnResizeSurvivesAcceptedRedrawThroughWindowCapture(): Unit {
    let controller = TableColumnCaptureController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(settleTableColumnWindow(window), true)
    var grip = CjguiComposableUiLayoutNode.missing()
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "capture-table-header-resize-status") {
            grip = node
        }
    }
    @Assert(grip.nodeId >= 0, true)
    let oldVersion = window.windowProgress().acceptedSceneVersion
    let startX = Float64(grip.bounds.x) + 2.0
    @Assert(window.dispatchPointerEventForTest(tableColumnPointerEvent(
        CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, grip.nodeId, oldVersion, startX)).didApply, true)
    @Assert(controller.layout.resizeActive(), true)
    @Assert(window.pointerCaptureActiveForTest(), true)
    let beforeUpdate = controller.layout.width("status")
    @Assert(window.dispatchPointerEventForTest(tableColumnPointerEvent(
        CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, grip.nodeId, oldVersion, startX + 20.0)).didApply, true)
    let afterUpdate = controller.layout.width("status")
    @Assert(afterUpdate > beforeUpdate, true)
    // The accepted redraw rebuilds the header; the stable grip identity keeps
    // the same capture alive while the width changes.
    @Assert(settleTableColumnWindow(window), true)
    let redrawnVersion = window.windowProgress().acceptedSceneVersion
    @Assert(redrawnVersion > oldVersion, true)
    @Assert(window.pointerCaptureActiveForTest(), true)
    // The next UPDATE still belongs to the original gesture. It names the
    // current accepted projection, exactly as a real pointer move after the
    // redraw would.
    let secondApplied = window.dispatchPointerEventForTest(tableColumnPointerEvent(
        CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, grip.nodeId, redrawnVersion, startX + 40.0))
    @Assert(secondApplied.didApply, true)
    @Assert(controller.layout.width("status") > afterUpdate, true)
    // END uses its own terminal coordinate, different from the last UPDATE.
    let finalX = startX + 55.0
    let _ = window.dispatchPointerEventForTest(tableColumnPointerEvent(
        CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, grip.nodeId, redrawnVersion, finalX))
    @Assert(controller.layout.width("status"), 123)
    @Assert(controller.layout.resizeActive(), false)
    @Assert(window.pointerCaptureActiveForTest(), false)
    @Assert(window.dispatchPointerEventForTest(tableColumnPointerEvent(
        CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, grip.nodeId, redrawnVersion, finalX + 20.0)).didApply, false)
    @Assert(controller.layout.width("status"), 123)
    window.close()
}
