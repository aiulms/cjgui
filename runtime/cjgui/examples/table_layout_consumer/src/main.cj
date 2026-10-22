// Minimal independent consumer of the public table column layout.
// Different columns, widths and keys than the rule-set sample: nothing here
// copies the table's ordering, visibility or resize implementation.
package table_layout_consumer

import cjgui.*
import std.collection.*

class StockRowSource <: CjguiComposableUiVariableHeightListSource {
    private let rows: Array<CjguiComposableUiVariableHeightListItem>
    init(rows: Array<CjguiComposableUiVariableHeightListItem>) { this.rows = rows }
    public func itemCount(): Int64 { return rows.size }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= rows.size) { return CjguiComposableUiVariableHeightListItem.missing() }
        return rows[index]
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < rows.size) {
            if (rows[index].key == key) { return index }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 { return 0 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(1, "stock-row", item.title, CjguiComposableUiStyle(fixedHeight: 28))
    }
}

func fail(message: String): Int32 {
    println("TABLE_LAYOUT_CONSUMER FAILED ${message}")
    return 1
}

main(): Int32 {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    rows.add(CjguiComposableUiVariableHeightListItem("sku-a", 1, "A-100", 0, estimatedHeight: 28))
    rows.add(CjguiComposableUiVariableHeightListItem("sku-b", 2, "B-200", 0, estimatedHeight: 28))
    let source = CjguiComposableUiFilteredListSource(StockRowSource(rows.toArray()),
        { item => item.title })
    let columns = ArrayList<CjguiComposableUiTableColumn>()
    columns.add(CjguiComposableUiTableColumn("sku", "SKU", "sku", 90, "SORT_SKU",
        { item => item.key }, { left, right => 0 }, minWidth: 60, maxWidth: 160))
    columns.add(CjguiComposableUiTableColumn("stock", "库存", "stock", 70, "SORT_STOCK",
        { item => item.title }, { left, right => 0 }, minWidth: 48, maxWidth: 140))
    columns.add(CjguiComposableUiTableColumn("price", "价格", "price", 0, "",
        { item => "¥0.00" }, { left, right => 0 }, minWidth: 80, maxWidth: 240))
    columns.add(CjguiComposableUiTableColumn("note", "备注", "note", 110, "",
        { item => "—" }, { left, right => 0 }, minWidth: 64, maxWidth: 220))
    let layout = CjguiComposableUiTableColumnLayout(columns.toArray())
    let table = CjguiComposableUiTableSource(source, "stock-table", columns.toArray(),
        CjguiComposableUiTableStyle(28, 28, 6, 11.0, "PingFang SC",
            CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0),
            CjguiComposableUiColor(0.95, 0.95, 0.95, 1.0), CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0),
            CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.4, 0.4, 0.4, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0)),
        layout: layout)
    if (table.columnCount() != 4) { return fail("initial column count") }
    if (layout.setWidth("stock", 999) != true || layout.width("stock") != 140) { return fail("width clamp") }
    if (layout.setVisible("note", false) != true || layout.visibleCount() != 3) { return fail("hide") }
    if (layout.move("price", -2) != true) { return fail("move") }
    if (layout.visibleKeys()[0] != "price") { return fail("order") }
    let header = table.buildHeader()
    let row = table.buildRow(table.itemAt(0), false, false)
    if (header.children().size != 3 || row.children().size != 3) { return fail("projection count") }
    if (header.children()[0].semanticId != "stock-table-header-cell-price" ||
        row.children()[0].semanticId != "stock-table-cell-sku-a-price") { return fail("projection order") }
    if (header.children()[0].children()[0].nodeKind != CJGUI_COMPOSABLE_UI_TEXT) { return fail("static header") }
    if (!layout.encodeState().contains("stock:140:1")) { return fail("state") }

    // A typed view snapshot over the same public components. This consumer uses
    // a different column declaration than the rule-set sample, so restore also
    // exercises the declared-column compatibility rule.
    let view = CjguiComposableUiCollectionViewState(table, ["table", "list"], "table")
    if (!view.setQuery("B-200") || !view.setSortState("stock", false)) {
        return fail("view state")
    }
    let encoded = view.encodedSnapshot()
    if (!encoded.startsWith("CJGUI_COLLECTION_VIEW 1")) { return fail("view format") }
    if (!CjguiComposableUiCollectionViewCodec.decode(encoded).isValid()) { return fail("view decode") }
    let replacementColumns = ArrayList<CjguiComposableUiTableColumn>()
    replacementColumns.add(CjguiComposableUiTableColumn("sku", "SKU", "sku", 90, "SORT_SKU",
        { item => item.key }, { left, right => 0 }, minWidth: 60, maxWidth: 160))
    replacementColumns.add(CjguiComposableUiTableColumn("stock", "库存", "stock", 70, "SORT_STOCK",
        { item => item.title }, { left, right => 0 }, minWidth: 48, maxWidth: 120))
    replacementColumns.add(CjguiComposableUiTableColumn("currency", "币种", "currency", 100, "",
        { item => "CNY" }, { left, right => 0 }, minWidth: 50, maxWidth: 160))
    let replacementLayout = CjguiComposableUiTableColumnLayout(replacementColumns.toArray())
    let replacementTable = CjguiComposableUiTableSource(source, "stock-table-v2",
        replacementColumns.toArray(),
        CjguiComposableUiTableStyle(28, 28, 6, 11.0, "PingFang SC",
            CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0),
            CjguiComposableUiColor(0.95, 0.95, 0.95, 1.0), CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0),
            CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.4, 0.4, 0.4, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0)),
        layout: replacementLayout)
    let replacementView = CjguiComposableUiCollectionViewState(replacementTable,
        ["table", "list"], "list")
    let restored = replacementView.restoreEncoded(encoded)
    if (!restored.applied) { return fail("view restore rejected: ${restored.reason}") }
    if (restored.ignoredColumnKeys.size != 2 || restored.addedColumnKeys.size != 1) {
        return fail("declaration compatibility counts")
    }
    if (restored.addedColumnKeys[0] != "currency" || restored.sortCleared) {
        return fail("declaration compatibility result")
    }
    if (replacementLayout.columnKeys() != ArrayList<String>(["sku", "stock", "currency"])) {
        return fail("declaration order")
    }
    if (replacementLayout.width("stock") != 120 || replacementLayout.width("currency") != 100) {
        return fail("declaration width")
    }
    if (replacementView.mode() != "table" || replacementView.query() != "B-200" ||
        replacementView.sortColumnKey() != "stock" || replacementView.sortAscending()) {
        return fail("view target state")
    }
    let preserved = replacementView.encodedSnapshot()
    let invalid = replacementView.restoreEncoded(
        "CJGUI_COLLECTION_VIEW 9 | MODE 7461626C65 | QUERY - | SORT NONE | COL 736B75 90 1")
    if (invalid.applied || invalid.reason != "unsupported_view_version") {
        return fail("invalid view accepted")
    }
    if (replacementView.encodedSnapshot() != preserved) { return fail("invalid view changed state") }

    println("TABLE_LAYOUT_CONSUMER OK columns=${layout.visibleCount()} order=${layout.visibleKeys()} " +
        "stock=${layout.width("stock")} revision=${layout.revision()}")
    println("TABLE_VIEW_CONSUMER OK ignored=${restored.ignoredColumnKeys.size} " +
        "added=${restored.addedColumnKeys.size} stock=${replacementLayout.width("stock")} " +
        "order=${replacementLayout.visibleKeys()} mode=${replacementView.mode()}")
    return 0
}
