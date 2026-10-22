// Public collection-view snapshot contracts: encode/decode round trip, atomic
// restore that keeps the current view on failure, and the simple column
// declaration compatibility rule. No app controller or native module is used.
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class CollectionViewTestSource <: CjguiComposableUiVariableHeightListSource {
    private let items: Array<CjguiComposableUiVariableHeightListItem>

    init(items: Array<CjguiComposableUiVariableHeightListItem>) {
        this.items = items
    }

    public func itemCount(): Int64 {
        return items.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
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
        return cjguiComposableText(970000, "collection-view-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 30))
    }
}

private func collectionViewRows(): Array<CjguiComposableUiVariableHeightListItem> {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < 6) {
        rows.add(CjguiComposableUiVariableHeightListItem("row_${index}", index, "规则 ${index}", 0,
            estimatedHeight: 30))
        index += 1
    }
    return rows.toArray()
}

private func collectionViewColumn(key: String, title: String, width: Int64,
    minWidth!: Int64 = 56, maxWidth!: Int64 = 480): CjguiComposableUiTableColumn {
    return CjguiComposableUiTableColumn(key, title, key, width, "SORT_${key}",
        { item => item.title }, { _, _ => 0 },
        minWidth: minWidth, maxWidth: maxWidth)
}

private func collectionViewStyle(): CjguiComposableUiTableStyle {
    return CjguiComposableUiTableStyle(30, 30, 6, 11.5, "PingFang SC",
        CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0),
        CjguiComposableUiColor(0.96, 0.96, 0.96, 1.0), CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0),
        CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        CjguiComposableUiColor(0.4, 0.4, 0.4, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0))
}

private func collectionViewTable(columns: Array<CjguiComposableUiTableColumn>,
    key: String): CjguiComposableUiTableSource {
    let base = CollectionViewTestSource(collectionViewRows())
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    return CjguiComposableUiTableSource(filtered, key, columns, collectionViewStyle())
}

private func collectionViewStandardColumns(): Array<CjguiComposableUiTableColumn> {
    let columns = ArrayList<CjguiComposableUiTableColumn>()
    columns.add(collectionViewColumn("name", "名称", 0))
    columns.add(collectionViewColumn("status", "状态", 68, maxWidth: 120))
    columns.add(collectionViewColumn("detail", "详情", 96))
    return columns.toArray()
}

private func collectionViewSnapshotOf(encoded: String): CjguiComposableUiCollectionViewSnapshot {
    let decoded = CjguiComposableUiCollectionViewCodec.decode(encoded)
    match (decoded.snapshot) {
        case Some(snapshot) => return snapshot
        case None => throw IllegalArgumentException("view snapshot did not decode: ${decoded.reason}")
    }
}

@Test
func collectionViewSnapshotRoundTripsThroughText(): Unit {
    let table = collectionViewTable(collectionViewStandardColumns(), "view-round-trip")
    let view = CjguiComposableUiCollectionViewState(table, ["list", "table"], "list")
    let layout = table.layout()
    @Assert(view.setMode("table"), true)
    @Assert(view.setQuery("规则 1"), true)
    @Assert(view.setSortState("detail", false), true)
    @Assert(layout.setWidth("status", 90), true)
    @Assert(layout.setVisible("detail", false), true)
    @Assert(layout.move("name", 2), true)
    @Assert(layout.columnKeys(), ArrayList<String>(["status", "detail", "name"]))

    let snapshot = view.snapshot()
    @Assert(snapshot.mode, "table")
    @Assert(snapshot.query, "规则 1")
    @Assert(snapshot.sortColumnKey, "detail")
    @Assert(snapshot.sortAscending, false)
    @Assert(snapshot.columns.size, 3)
    @Assert(snapshot.columns[0].key, "status")
    @Assert(snapshot.columns[0].width, 90)
    @Assert(snapshot.columns[1].key, "detail")
    @Assert(snapshot.columns[1].visible, false)
    @Assert(snapshot.columns[2].key, "name")
    @Assert(snapshot.columns[2].width, 0)

    let encoded = view.encodedSnapshot()
    let decoded = CjguiComposableUiCollectionViewCodec.decode(encoded)
    @Assert(decoded.isValid(), true)
    let restored = collectionViewSnapshotOf(encoded)
    @Assert(restored.mode, "table")
    @Assert(restored.query, "规则 1")
    @Assert(restored.sortColumnKey, "detail")
    @Assert(restored.sortAscending, false)
    @Assert(restored.columns.size, 3)
    @Assert(CjguiComposableUiCollectionViewCodec.encode(restored), encoded)

    // The same text restores an independently constructed table with the same
    // declaration, using the explicit target state (not repeated sort toggles).
    let targetTable = collectionViewTable(collectionViewStandardColumns(), "view-round-trip-target")
    let target = CjguiComposableUiCollectionViewState(targetTable, ["list", "table"], "list")
    let applied = target.restoreEncoded(encoded)
    @Assert(applied.applied, true)
    @Assert(applied.reason, "view_restored")
    @Assert(applied.ignoredColumnKeys.size, 0)
    @Assert(applied.addedColumnKeys.size, 0)
    @Assert(applied.sortCleared, false)
    @Assert(target.mode(), "table")
    @Assert(target.query(), "规则 1")
    @Assert(target.sortColumnKey(), "detail")
    @Assert(target.sortAscending(), false)
    @Assert(targetTable.layout().columnKeys(), ArrayList<String>(["status", "detail", "name"]))
    @Assert(targetTable.layout().width("status"), 90)
    @Assert(targetTable.layout().isVisible("detail"), false)
    @Assert(target.encodedSnapshot(), encoded)
    // Applying the identical snapshot again reports no revision change.
    let revision = target.revision()
    let repeated = target.restoreEncoded(encoded)
    @Assert(repeated.applied, true)
    @Assert(repeated.reason, "view_unchanged")
    @Assert(target.revision(), revision)
}

@Test
func collectionViewRestoreKeepsCurrentViewOnInvalidInput(): Unit {
    let table = collectionViewTable(collectionViewStandardColumns(), "view-invalid")
    let view = CjguiComposableUiCollectionViewState(table, ["list", "table"], "list")
    @Assert(view.setMode("table"), true)
    @Assert(view.setQuery("alpha"), true)
    @Assert(view.setSortState("name", true), true)
    @Assert(table.layout().setWidth("status", 100), true)
    @Assert(table.layout().setVisible("detail", false), true)
    let before = view.encodedSnapshot()
    let revisionBefore = view.revision()

    let unsupported = view.restoreEncoded("CJGUI_COLLECTION_VIEW 2 | MODE 6C697374")
    @Assert(unsupported.applied, false)
    @Assert(unsupported.reason, "unsupported_view_version")
    let malformed = view.restoreEncoded(
        "CJGUI_COLLECTION_VIEW 1 | MODE 6C697374 | QUERY - | SORT NONE | COL 626164 10")
    @Assert(malformed.applied, false)
    @Assert(malformed.reason, "invalid_view_format")
    // Typed snapshots get the same all-or-nothing validation.
    let current = view.snapshot()
    let unknownMode = CjguiComposableUiCollectionViewSnapshot("grid", current.query,
        current.sortColumnKey, current.sortAscending, current.columns)
    let modeResult = view.applySnapshot(unknownMode)
    @Assert(modeResult.applied, false)
    @Assert(modeResult.reason, "unknown_view_mode")
    let hiddenColumns = ArrayList<CjguiComposableUiTableColumnState>()
    for (column in current.columns) {
        hiddenColumns.add(CjguiComposableUiTableColumnState(column.key, column.width, false))
    }
    let hiddenResult = view.applySnapshot(CjguiComposableUiCollectionViewSnapshot(current.mode,
        current.query, current.sortColumnKey, current.sortAscending, hiddenColumns))
    @Assert(hiddenResult.applied, false)
    @Assert(hiddenResult.reason, "all_columns_hidden")
    let duplicates = ArrayList<CjguiComposableUiTableColumnState>()
    duplicates.add(CjguiComposableUiTableColumnState("status", 80, true))
    duplicates.add(CjguiComposableUiTableColumnState("status", 90, true))
    let duplicateResult = view.applySnapshot(CjguiComposableUiCollectionViewSnapshot(current.mode,
        current.query, current.sortColumnKey, current.sortAscending, duplicates))
    @Assert(duplicateResult.applied, false)
    @Assert(duplicateResult.reason, "duplicate_column")

    @Assert(view.encodedSnapshot(), before)
    @Assert(view.revision(), revisionBefore)
}

@Test
func collectionViewRestoreHandlesColumnDeclarationChanges(): Unit {
    let sourceColumns = ArrayList<CjguiComposableUiTableColumn>()
    sourceColumns.add(collectionViewColumn("name", "名称", 0))
    sourceColumns.add(collectionViewColumn("status", "状态", 68, maxWidth: 120))
    sourceColumns.add(collectionViewColumn("legacy", "旧列", 90))
    let sourceTable = collectionViewTable(sourceColumns.toArray(), "view-old-declaration")
    let source = CjguiComposableUiCollectionViewState(sourceTable, ["list", "table"], "list")
    @Assert(source.setMode("table"), true)
    @Assert(source.setQuery("x"), true)
    @Assert(source.setSortState("legacy", true), true)
    @Assert(sourceTable.layout().setWidth("status", 999), true)
    @Assert(sourceTable.layout().setWidth("legacy", 120), true)
    let encoded = source.encodedSnapshot()

    let targetColumns = ArrayList<CjguiComposableUiTableColumn>()
    targetColumns.add(collectionViewColumn("name", "名称", 0))
    targetColumns.add(collectionViewColumn("status", "状态", 68, maxWidth: 120))
    targetColumns.add(collectionViewColumn("detail", "详情", 96))
    let targetTable = collectionViewTable(targetColumns.toArray(), "view-new-declaration")
    let target = CjguiComposableUiCollectionViewState(targetTable, ["list", "table"], "list")
    let applied = target.restoreEncoded(encoded)
    @Assert(applied.applied, true)
    @Assert(applied.ignoredColumnKeys, ArrayList<String>(["legacy"]))
    @Assert(applied.addedColumnKeys, ArrayList<String>(["detail"]))
    @Assert(applied.sortCleared, true)
    @Assert(target.sortColumnKey(), "")
    @Assert(target.mode(), "table")
    @Assert(target.query(), "x")
    // Surviving keys keep the saved order; the new declaration key is appended
    // at its declared width and default visibility.
    @Assert(targetTable.layout().columnKeys(), ArrayList<String>(["name", "status", "detail"]))
    @Assert(targetTable.layout().width("status"), 120)
    @Assert(targetTable.layout().width("detail"), 96)
    @Assert(targetTable.layout().isVisible("detail"), true)
    @Assert(targetTable.layout().width("legacy"), 0)

    // Resetting restores declaration defaults for every current key.
    let reset = target.resetToDefault()
    @Assert(reset.applied, true)
    @Assert(reset.reason, "view_reset")
    @Assert(target.mode(), "list")
    @Assert(target.query(), "")
    @Assert(target.sortColumnKey(), "")
    @Assert(targetTable.layout().columnKeys(), ArrayList<String>(["name", "status", "detail"]))
    @Assert(targetTable.layout().width("status"), 68)
    @Assert(targetTable.layout().visibleCount(), 3)
}
