// A reusable sorted table projection over an existing variable-height list.
//
// WHY THIS EXISTS
// A business table is not a second copy of the records. It is a VIEW over the
// owner's stable-key rows: the caller declares columns, comparators and the
// text a cell displays; the source only chooses which already-filtered
// positions are visible and in what order. Row identity stays the base row's
// stable key, never the sorted display position.
//
// The same column constraints are used by `buildHeader()` and `buildRow()`, so
// header and body cells share widths across window resizing. One column may be
// flexible (`width <= 0`); all others are fixed. This component does not drag,
// freeze, span or virtualize columns, and it does not own validation, writes,
// Apply or Cancel.
//
// Order construction is lazy and invalidated only by `setQuery`, `setSort`,
// `dataChanged` (revision change) or `invalidate`. It is never recomputed per
// layout pass. Equal sort values keep the filtered source order because the
// merge below takes the left run first.
package cjgui

import std.collection.*
import std.overflow.*

/// Display-only declaration of one table column. `fieldId` names the owner
/// field the column projects; it is metadata for consumers, not a write path.
/// `width <= 0` marks the single flexible column (normally the name column).
public class CjguiComposableUiTableColumn {
    public let key: String
    public let title: String
    public let fieldId: String
    public let width: Int64
    public let sortActionName: String
    public let valueOf: (CjguiComposableUiVariableHeightListItem) -> String
    public let compare: (CjguiComposableUiVariableHeightListItem, CjguiComposableUiVariableHeightListItem) -> Int64
    /// The flexible column keeps this minimum when space is tight. The maximum
    /// bounds a caller-assigned fixed width; it does not cap flexible growth.
    public let minWidth: Int64
    public let maxWidth: Int64

    public init(key: String, title: String, fieldId: String, width: Int64, sortActionName: String,
        valueOf: (CjguiComposableUiVariableHeightListItem) -> String,
        compare: (CjguiComposableUiVariableHeightListItem, CjguiComposableUiVariableHeightListItem) -> Int64,
        minWidth!: Int64 = 56, maxWidth!: Int64 = 480) {
        this.key = key
        this.title = title
        this.fieldId = fieldId
        this.width = width
        this.sortActionName = sortActionName
        this.valueOf = valueOf
        this.compare = compare
        this.minWidth = if (minWidth > 0) { minWidth } else { 56 }
        this.maxWidth = if (maxWidth >= this.minWidth) { maxWidth } else { this.minWidth }
    }
}

/// Shared table presentation. Header and body read every width/padding value
/// from this one object, so they cannot drift apart.
public class CjguiComposableUiTableStyle {
    public let rowHeight: Int64
    public let headerHeight: Int64
    public let cellPadding: Int64
    public let fontSize: Float64
    public let fontFamily: String
    public let background: CjguiComposableUiColor
    public let selectedBackground: CjguiComposableUiColor
    public let headerBackground: CjguiComposableUiColor
    public let border: CjguiComposableUiColor
    public let textColor: CjguiComposableUiColor
    public let selectedTextColor: CjguiComposableUiColor
    public let mutedTextColor: CjguiComposableUiColor
    public let accentColor: CjguiComposableUiColor

    public init(rowHeight: Int64, headerHeight: Int64, cellPadding: Int64, fontSize: Float64,
        fontFamily: String, background: CjguiComposableUiColor,
        selectedBackground: CjguiComposableUiColor, headerBackground: CjguiComposableUiColor,
        border: CjguiComposableUiColor, textColor: CjguiComposableUiColor,
        selectedTextColor: CjguiComposableUiColor, mutedTextColor: CjguiComposableUiColor,
        accentColor: CjguiComposableUiColor) {
        this.rowHeight = if (rowHeight > 0) { rowHeight } else { 34 }
        this.headerHeight = if (headerHeight > 0) { headerHeight } else { 30 }
        this.cellPadding = if (cellPadding >= 0) { cellPadding } else { 6 }
        this.fontSize = if (fontSize > 0.0) { fontSize } else { 11.5 }
        this.fontFamily = fontFamily
        this.background = background
        this.selectedBackground = selectedBackground
        this.headerBackground = headerBackground
        this.border = border
        this.textColor = textColor
        this.selectedTextColor = selectedTextColor
        this.mutedTextColor = mutedTextColor
        this.accentColor = accentColor
    }
}

/// Caller-declared activation for one table row. The table forwards exactly
/// these values to the row's cells and never synthesizes an action or resource
/// id. An empty action name means display-only: cells are static text and the
/// row exposes no business operation.
public class CjguiComposableUiTableRowAction {
    public let actionName: String
    public let resourceId: Int64

    public init(actionName: String, resourceId: Int64) {
        this.actionName = actionName
        this.resourceId = resourceId
    }

    public static func none(): CjguiComposableUiTableRowAction {
        return CjguiComposableUiTableRowAction("", -1)
    }

    public func isActive(): Bool {
        return actionName.size > 0
    }
}

private func cjguiTableMergeSort(items: ArrayList<CjguiComposableUiVariableHeightListItem>,
    column: CjguiComposableUiTableColumn, ascending: Bool): ArrayList<CjguiComposableUiVariableHeightListItem> {
    if (items.size <= 1) {
        return ArrayList<CjguiComposableUiVariableHeightListItem>(items)
    }
    let middle = items.size / 2
    let leftItems = ArrayList<CjguiComposableUiVariableHeightListItem>()
    let rightItems = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < middle) {
        leftItems.add(items[index])
        index += 1
    }
    while (index < items.size) {
        rightItems.add(items[index])
        index += 1
    }
    let left = cjguiTableMergeSort(leftItems, column, ascending)
    let right = cjguiTableMergeSort(rightItems, column, ascending)
    let merged = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var leftIndex: Int64 = 0
    var rightIndex: Int64 = 0
    while (leftIndex < left.size && rightIndex < right.size) {
        let comparison = column.compare(left[leftIndex], right[rightIndex])
        // Ties take the left run, preserving the filtered source order.
        let takeLeft = if (ascending) { comparison <= 0 } else { comparison >= 0 }
        if (takeLeft) {
            merged.add(left[leftIndex])
            leftIndex += 1
        } else {
            merged.add(right[rightIndex])
            rightIndex += 1
        }
    }
    while (leftIndex < left.size) {
        merged.add(left[leftIndex])
        leftIndex += 1
    }
    while (rightIndex < right.size) {
        merged.add(right[rightIndex])
        rightIndex += 1
    }
    return merged
}

/// Sorted, column-projected view over an existing filtered source.
///
/// The filtered source remains authoritative for WHICH rows are visible. This
/// source adds an order over those visible positions and builds table rows plus
/// a matching header. It holds only lightweight item projections and a key to
/// display-position map for the current sorted order.
public class CjguiComposableUiTableSource <: CjguiComposableUiVariableHeightListSource {
    private let filtered: CjguiComposableUiFilteredListSource
    private let instanceKey: String
    private let columns: Array<CjguiComposableUiTableColumn>
    private let columnByKey: HashMap<String, CjguiComposableUiTableColumn>
    // ONE presentation state shared by header and body. Existing callers that
    // pass only columns keep working: this layout is created from them and is
    // fully visible at the declared widths.
    private let layoutState: CjguiComposableUiTableColumnLayout
    private let rowAction: ?((CjguiComposableUiVariableHeightListItem) -> CjguiComposableUiTableRowAction)
    // Optional multi-selection projection. The caller's selection object stays
    // the single owner; the table only asks whether a stable key is selected so
    // every selected visible row paints as selected.
    private let rowSelected: ?((String) -> Bool)
    private var tableStyle: CjguiComposableUiTableStyle
    private var sortedItems = ArrayList<CjguiComposableUiVariableHeightListItem>()
    private var positionByKey = HashMap<String, Int64>()
    private var sortKeyValue: String = ""
    private var sortAscendingValue: Bool = true
    private var orderBuilt: Bool = true
    private var dataRevisionValue: Int64 = -1
    // Shared geometry (fixed row height, cell padding, font metrics) is a
    // measurement input; paint-only changes must not invalidate row geometry.
    private var measurementGenerationValue: Int64 = 0
    private var lastBaseMeasurementGeneration: Int64
    private var measuredRowHeight: Int64
    private var measuredCellPadding: Int64
    private var measuredFontSize: Float64
    private var measuredFontFamily: String

    public init(filtered: CjguiComposableUiFilteredListSource, instanceKey: String,
        columns: Array<CjguiComposableUiTableColumn>, style: CjguiComposableUiTableStyle,
        rowAction!: ?((CjguiComposableUiVariableHeightListItem) -> CjguiComposableUiTableRowAction) = None,
        rowSelected!: ?((String) -> Bool) = None,
        layout!: ?CjguiComposableUiTableColumnLayout = None) {
        this.filtered = filtered
        this.instanceKey = instanceKey
        this.columns = Array<CjguiComposableUiTableColumn>(columns.size, { index => columns[index] })
        this.columnByKey = HashMap<String, CjguiComposableUiTableColumn>()
        for (column in this.columns) {
            if (!this.columnByKey.contains(column.key)) {
                this.columnByKey[column.key] = column
            }
        }
        this.layoutState = layout ?? CjguiComposableUiTableColumnLayout(columns)
        this.rowAction = rowAction
        this.rowSelected = rowSelected
        this.tableStyle = style
        this.lastBaseMeasurementGeneration = filtered.measurementGeneration()
        this.measuredRowHeight = style.rowHeight
        this.measuredCellPadding = style.cellPadding
        this.measuredFontSize = style.fontSize
        this.measuredFontFamily = style.fontFamily
    }

    /// The caller-owned layout object. Human controls and external verbs must
    /// mutate THIS instance; the table reads it during header/body building.
    public func layout(): CjguiComposableUiTableColumnLayout {
        return layoutState
    }

    public func layoutRevision(): Int64 {
        return layoutState.revision()
    }

    /// Declared titles in layout order, including hidden columns. This is
    /// declaration metadata for a column menu, not a second layout state.
    public func columnTitle(key: String): String {
        if (let Some(column) <- columnByKey.get(key)) {
            return column.title
        }
        return key
    }

    private func visibleColumns(): ArrayList<CjguiComposableUiTableColumn> {
        let result = ArrayList<CjguiComposableUiTableColumn>()
        for (key in layoutState.visibleKeys()) {
            if (let Some(column) <- columnByKey.get(key)) {
                result.add(column)
            }
        }
        return result
    }

    public func updatePresentation(style: CjguiComposableUiTableStyle): Unit {
        let geometryChanged = style.rowHeight != measuredRowHeight ||
            style.cellPadding != measuredCellPadding ||
            style.fontSize != measuredFontSize ||
            style.fontFamily != measuredFontFamily
        if (geometryChanged) {
            measuredRowHeight = style.rowHeight
            measuredCellPadding = style.cellPadding
            measuredFontSize = style.fontSize
            measuredFontFamily = style.fontFamily
            measurementGenerationValue = measurementGenerationValue.saturatingAdd(1)
        }
        this.tableStyle = style
    }

    public func style(): CjguiComposableUiTableStyle {
        return tableStyle
    }

    public func columnCount(): Int64 {
        return visibleColumns().size
    }

    public func columnAt(index: Int64): ?CjguiComposableUiTableColumn {
        let visible = visibleColumns()
        if (index < 0 || index >= visible.size) {
            return None
        }
        return Some(visible[index])
    }

    public func query(): String {
        return filtered.query()
    }

    /// Delegates to the same filter used by the list view, then invalidates the
    /// sorted projection only when the query actually changed.
    public func setQuery(value: String): Bool {
        let changed = filtered.setQuery(value)
        if (changed) {
            orderBuilt = false
        }
        return changed
    }

    public func dataChanged(revision: Int64): Unit {
        if (revision != dataRevisionValue) {
            dataRevisionValue = revision
            orderBuilt = false
        }
        filtered.dataChanged(revision)
    }

    public func invalidate(): Unit {
        filtered.invalidate()
        orderBuilt = false
    }

    public func sortColumnKey(): String {
        return sortKeyValue
    }

    public func sortAscending(): Bool {
        return sortAscendingValue
    }

    /// Toggle this column: a new column starts ascending; clicking the active
    /// column flips direction. Returns false for an unknown column.
    public func setSort(columnKey: String): Bool {
        if (columnIndex(columnKey) < 0) {
            return false
        }
        if (sortKeyValue == columnKey) {
            sortAscendingValue = !sortAscendingValue
        } else {
            sortKeyValue = columnKey
            sortAscendingValue = true
        }
        orderBuilt = false
        return true
    }

    /// Sets an explicit sort target instead of toggling the active column.
    /// Restoring a saved view uses this entry so it cannot depend on how many
    /// times "toggle sort" happened before. An empty key clears sorting; an
    /// unknown column is rejected and the current order stays untouched.
    public func setSortState(columnKey: String, ascending: Bool): Bool {
        if (columnKey.size == 0) {
            return clearSort()
        }
        if (columnIndex(columnKey) < 0) {
            return false
        }
        if (sortKeyValue == columnKey && sortAscendingValue == ascending) {
            return false
        }
        sortKeyValue = columnKey
        sortAscendingValue = ascending
        orderBuilt = false
        return true
    }

    public func clearSort(): Bool {
        if (sortKeyValue.size == 0) {
            return false
        }
        sortKeyValue = ""
        sortAscendingValue = true
        orderBuilt = false
        return true
    }

    public func sortIndicator(columnKey: String): String {
        if (sortKeyValue != columnKey) {
            return ""
        }
        return if (sortAscendingValue) { " ↑" } else { " ↓" }
    }

    public func itemCount(): Int64 {
        if (sortKeyValue.size == 0) {
            return filtered.itemCount()
        }
        ensureOrder()
        return sortedItems.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (sortKeyValue.size == 0) {
            return projected(filtered.itemAt(index))
        }
        ensureOrder()
        if (index < 0 || index >= sortedItems.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return projected(sortedItems[index])
    }

    public func indexForKey(key: String): Int64 {
        if (sortKeyValue.size == 0) {
            return filtered.indexForKey(key)
        }
        ensureOrder()
        if (let Some(position) <- positionByKey.get(key)) {
            return position
        }
        return -1
    }

    /// Advances for a shared geometry change in this table's presentation and
    /// for the wrapped source's own generation. Color-only updates leave it
    /// unchanged, so the virtual list keeps valid measured heights.
    public func measurementGeneration(): Int64 {
        let baseGeneration = filtered.measurementGeneration()
        if (baseGeneration != lastBaseMeasurementGeneration) {
            lastBaseMeasurementGeneration = baseGeneration
            measurementGenerationValue = measurementGenerationValue.saturatingAdd(1)
        }
        return measurementGenerationValue
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        var selected = isSelected || isFocused
        if (let Some(predicate) <- rowSelected) {
            if (predicate(item.key)) {
                selected = true
            }
        }
        let rowTextColor = if (selected) { tableStyle.selectedTextColor } else { tableStyle.textColor }
        let action = if (let Some(provider) <- rowAction) {
            provider(item)
        } else {
            CjguiComposableUiTableRowAction.none()
        }
        let row = cjguiComposableHorizontal(-1, "${instanceKey}-row-${item.key}",
            CjguiComposableUiStyle(fixedHeight: tableStyle.rowHeight, growX: 1,
                background: if (selected) { tableStyle.selectedBackground } else { tableStyle.background },
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, clipsContent: true),
            identity: Some(rowIdentity(item.key)))
        for (column in visibleColumns()) {
            let columnWidth = layoutState.width(column.key)
            let cellStyle = CjguiComposableUiStyle(fixedHeight: tableStyle.rowHeight,
                fixedWidth: if (columnWidth > 0) { columnWidth } else { 0 },
                growX: if (columnWidth > 0) { 0 } else { 1 },
                minWidth: if (columnWidth > 0) { 0 } else { column.minWidth },
                padding: tableStyle.cellPadding, fontSize: tableStyle.fontSize,
                fontFamily: tableStyle.fontFamily, textColor: rowTextColor,
                textMaxLines: 1, textOverflow: "ellipsis",
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_START)
            let semanticId = "${instanceKey}-cell-${item.key}-${column.key}"
            let cellIdentity = Some(cellIdentityFor(item.key, column.key))
            if (action.isActive()) {
                row.add(cjguiComposableButton(-1, semanticId, column.valueOf(item),
                    action.actionName, action.resourceId, cellStyle,
                    operationActionName: action.actionName, operationResourceId: action.resourceId,
                    ownerInteractionState: if (selected) {
                        CjguiComposableUiInteractionState.SELECTED
                    } else {
                        CjguiComposableUiInteractionState.NONE
                    }, identity: cellIdentity))
            } else {
                row.add(cjguiComposableText(-1, semanticId, column.valueOf(item), cellStyle,
                    resourceId: item.resourceId, identity: cellIdentity))
            }
        }
        return row
    }

    /// Header uses the SAME width, padding, order and visibility state as
    /// `buildRow`. Each cell is a container so a fixed column can carry a thin
    /// split-handle grip at its trailing edge without changing its identity.
    public func buildHeader(): CjguiComposableUiNode {
        let header = cjguiComposableHorizontal(-1, "${instanceKey}-header",
            CjguiComposableUiStyle(fixedHeight: tableStyle.headerHeight, growX: 1,
                background: tableStyle.headerBackground,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, clipsContent: true),
            identity: Some(headerIdentity()))
        for (column in visibleColumns()) {
            let columnWidth = layoutState.width(column.key)
            let active = sortKeyValue == column.key
            let cellStyle = CjguiComposableUiStyle(fixedHeight: tableStyle.headerHeight,
                fixedWidth: if (columnWidth > 0) { columnWidth } else { 0 },
                growX: if (columnWidth > 0) { 0 } else { 1 },
                minWidth: if (columnWidth > 0) { 0 } else { column.minWidth },
                padding: tableStyle.cellPadding,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER, clipsContent: true)
            let cell = cjguiComposableHorizontal(-1, "${instanceKey}-header-cell-${column.key}",
                cellStyle, identity: Some(headerCellIdentityFor(column.key)))
            let contentStyle = CjguiComposableUiStyle(growX: 1, fontSize: tableStyle.fontSize,
                fontFamily: tableStyle.fontFamily,
                textColor: if (active) { tableStyle.accentColor } else { tableStyle.mutedTextColor },
                textMaxLines: 1, textOverflow: "ellipsis",
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_START)
            let label = "${column.title}${sortIndicator(column.key)}"
            if (column.sortActionName.size > 0) {
                cell.add(cjguiComposableButton(-1, "${instanceKey}-header-sort-${column.key}", label,
                    column.sortActionName, -1, contentStyle,
                    operationActionName: column.sortActionName, operationResourceId: -1,
                    identity: Some(headerSortIdentityFor(column.key))))
            } else {
                cell.add(cjguiComposableText(-1, "${instanceKey}-header-sort-${column.key}", label,
                    contentStyle, identity: Some(headerSortIdentityFor(column.key))))
            }
            // Only a resolved fixed width has a draggable edge. The flexible
            // column stays flexible until a caller gives it a positive width.
            if (columnWidth > 0) {
                let gripStyle = CjguiComposableUiStyle(fixedWidth: 6, growY: 1,
                    background: tableStyle.border)
                cell.add(CjguiComposableUiNode(-1, "${instanceKey}-header-resize-${column.key}",
                    CJGUI_COMPOSABLE_UI_SPLIT_HANDLE, "", "",
                    CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION, -1, gripStyle,
                    operationActionName: CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION,
                    operationResourceId: -1, pointerControlRole: "table_column_resize",
                    pointerControlAxis: CjguiComposableUiSplitAxis.HORIZONTAL,
                    pointerControlMinimum: column.minWidth, pointerControlMaximum: column.maxWidth,
                    pointerControlStep: 8, pointerControlHandleThickness: 6,
                    pointerControlFirstSize: columnWidth,
                    identity: Some(resizeIdentityFor(column.key))))
            }
            header.add(cell)
        }
        return header
    }

    /// Experimental. Read-only width required by the current visible columns:
    /// fixed widths plus each flexible column's declared minimum. Consumers can
    /// compose a readable workspace without writing or rescaling preferences.
    public func minimumContentWidth(): Int64 {
        var width: Int64 = 0
        for (column in visibleColumns()) {
            let current = layoutState.width(column.key)
            width = width.saturatingAdd(if (current > 0) { current } else { column.minWidth })
        }
        return width
    }

    /// Scoped references use the same namespaces as the built nodes, so a
    /// caller can anchor a layer or focus target without reserving numeric ids.
    public func headerReference(): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(identityRoot(), "header")
    }

    public func headerCellReference(columnKey: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(identityRoot().child("header"), columnKey)
    }

    public func rowReference(rowKey: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(identityRoot().child("rows"), rowKey)
    }

    public func cellReference(rowKey: String, columnKey: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(identityRoot().child("cells").child(rowKey),
            columnKey)
    }

    private func identityRoot(): CjguiComposableUiIdentityScope {
        return CjguiComposableUiIdentityScope(instanceKey)
    }

    private func headerIdentity(): CjguiComposableUiIdentity {
        return identityRoot().local("header")
    }

    private func headerCellIdentityFor(columnKey: String): CjguiComposableUiIdentity {
        return identityRoot().child("header").local(columnKey)
    }

    private func headerSortIdentityFor(columnKey: String): CjguiComposableUiIdentity {
        return identityRoot().child("header").child(columnKey).local("sort")
    }

    /// The grip needs a stable scoped identity so pointer capture survives the
    /// scene rebuilds that happen while its width is changing.
    private func resizeIdentityFor(columnKey: String): CjguiComposableUiIdentity {
        return identityRoot().child("header").child(columnKey).local("resize")
    }

    private func rowIdentity(rowKey: String): CjguiComposableUiIdentity {
        return identityRoot().child("rows").local(rowKey)
    }

    private func cellIdentityFor(rowKey: String, columnKey: String): CjguiComposableUiIdentity {
        return identityRoot().child("cells").child(rowKey).local(columnKey)
    }

    private func columnIndex(key: String): Int64 {
        var index: Int64 = 0
        while (index < columns.size) {
            if (columns[index].key == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    /// Tag the table view so the shared virtual-list measurement cache does not
    /// reuse a list-row height for a table row of the same stable key. Sorted
    /// position is deliberately NOT part of the tag: moving a record must not
    /// change its identity or force unrelated content to be rebound.
    private func projected(item: CjguiComposableUiVariableHeightListItem): CjguiComposableUiVariableHeightListItem {
        return CjguiComposableUiVariableHeightListItem(item.key, item.resourceId, item.title,
            item.layoutRevision.saturatingMul(4).saturatingAdd(2),
            estimatedHeight: tableStyle.rowHeight)
    }

    private func ensureOrder(): Unit {
        if (orderBuilt) {
            return
        }
        sortedItems.clear()
        positionByKey = HashMap<String, Int64>()
        if (sortKeyValue.size > 0) {
            let index = columnIndex(sortKeyValue)
            if (index >= 0) {
                let column = columns[index]
                let visible = filtered.itemCount()
                let candidates = ArrayList<CjguiComposableUiVariableHeightListItem>()
                var visibleIndex: Int64 = 0
                while (visibleIndex < visible) {
                    let item = filtered.itemAt(visibleIndex)
                    if (item.key.size > 0) {
                        candidates.add(item)
                    }
                    visibleIndex += 1
                }
                sortedItems = cjguiTableMergeSort(candidates, column, sortAscendingValue)
                var position: Int64 = 0
                for (item in sortedItems) {
                    positionByKey[item.key] = position
                    position += 1
                }
            }
        }
        orderBuilt = true
    }
}
