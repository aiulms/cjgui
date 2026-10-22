// Public table projection contracts: stable-key order, numeric comparison,
// duplicate ties, filter composition, shared column constraints, visible-row
// materialization, and owner selection/draft across view and sort changes.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.unittest.*
import std.unittest.testmacro.*

private class TableProjectionSource <: CjguiComposableUiVariableHeightListSource {
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
        return cjguiComposableText(910000, "table-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 30))
    }
}

private func tableNumberColumn(): CjguiComposableUiTableColumn {
    return CjguiComposableUiTableColumn("retention", "保留天数", "retentionCount", 60, "SORT_RETENTION",
        { item => item.title },
        { left, right =>
            let leftValue = Int64.tryParse(left.title) ?? 0
            let rightValue = Int64.tryParse(right.title) ?? 0
            if (leftValue < rightValue) {
                -1
            } else if (leftValue > rightValue) {
                1
            } else {
                0
            }
        })
}

private func tableTestColumns(): Array<CjguiComposableUiTableColumn> {
    let columns = ArrayList<CjguiComposableUiTableColumn>()
    columns.add(CjguiComposableUiTableColumn("name", "规则名称", "label", 0, "SORT_NAME",
        { item => item.title }, { left, right => 0 }))
    columns.add(tableNumberColumn())
    return columns.toArray()
}

private func tableTestStyle(): CjguiComposableUiTableStyle {
    return CjguiRuleSetTableColumns.style(CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
}

private func tableRows(titles: Array<String>): Array<CjguiComposableUiVariableHeightListItem> {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < titles.size) {
        rows.add(CjguiComposableUiVariableHeightListItem("row_${index}", index, titles[index], 0,
            estimatedHeight: 30))
        index += 1
    }
    return rows.toArray()
}

private func tableLayoutCandidate(root: CjguiComposableUiNode, version: Int64,
    registry: CjguiComposableUiIdentityRegistry): CjguiComposableUiScene {
    let rect = CjguiComposableUiRect(0, 0, 520, 240)
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    if (!registry.prepareCandidate()) {
        registry.rollbackCandidate()
    } else {
        registry.commitCandidate()
    }
    return scene
}

private func tableSceneWithIdentity(table: CjguiComposableUiTableSource,
    listState: CjguiComposableUiVirtualListState, version: Int64): CjguiComposableUiScene {
    let root = cjguiComposableVariableHeightList(21, "table-identity-scene", 22, table, listState,
        30, 1, 3, CjguiComposableUiStyle(growX: 1, growY: 1))
    return tableLayoutCandidate(root, version, CjguiComposableUiIdentityRegistry())
}

/// Header and rows together: the same candidate registry resolves both
/// namespaces, so a caller can compare their scoped node IDs in one scene.
private func tableIdentityScene(table: CjguiComposableUiTableSource,
    listState: CjguiComposableUiVirtualListState, version: Int64,
    registry: CjguiComposableUiIdentityRegistry): CjguiComposableUiScene {
    let root = cjguiComposableVertical(23, "table-identity-root",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    root.add(table.buildHeader())
    root.add(cjguiComposableVariableHeightList(21, "table-identity-list", 22, table, listState,
        30, 1, 3, CjguiComposableUiStyle(growX: 1, growY: 1)))
    return tableLayoutCandidate(root, version, registry)
}

private func tableItem(key: String, resourceId: Int64,
    title: String): CjguiComposableUiVariableHeightListItem {
    return CjguiComposableUiVariableHeightListItem(key, resourceId, title, 0, estimatedHeight: 30)
}

private func tableStyleForMeasurement(rowHeight: Int64,
    background: CjguiComposableUiColor): CjguiComposableUiTableStyle {
    let theme = CjguiComposableUiTheme.paperLight()
    return CjguiComposableUiTableStyle(rowHeight, 30, 6, 11.5, "",
        background, theme.primaryAction.background, theme.card.background, theme.card.border,
        theme.primaryAction.textColor, theme.primaryAction.textColor, theme.card.textColor,
        theme.primaryAction.background)
}

@Test
func tableSortKeepsStableKeysDuplicatesAndNumericOrder(): Unit {
    let base = TableProjectionSource(tableRows(["10", "2", "100", "10"]))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "test-table", tableTestColumns(), tableTestStyle())
    @Assert(table.setSort("retention"), true)
    @Assert(table.itemCount(), 4)
    // Numeric 2 < 10 < 10 < 100, and the duplicate "10" keeps its base order.
    @Assert(table.itemAt(0).key, "row_1")
    @Assert(table.itemAt(1).key, "row_0")
    @Assert(table.itemAt(2).key, "row_3")
    @Assert(table.itemAt(3).key, "row_2")
    @Assert(table.indexForKey("row_1"), 0)
    @Assert(table.indexForKey("row_2"), 3)
    // A stable key, not the sorted display position, remains the row's identity.
    @Assert(table.itemAt(3).resourceId, 2)
    @Assert(table.setSort("retention"), true)
    @Assert(table.sortAscending(), false)
    @Assert(table.itemAt(0).key, "row_2")
    @Assert(table.itemAt(1).key, "row_0")
    @Assert(table.itemAt(2).key, "row_3")
    @Assert(table.itemAt(3).key, "row_1")
    // The existing text filter composes over the sorted projection. "10" is
    // a substring of "100", so all three rows whose text contains it remain.
    @Assert(table.setQuery("10"), true)
    @Assert(table.itemCount(), 3)
    @Assert(table.itemAt(0).key, "row_2")
    @Assert(table.itemAt(1).key, "row_0")
    @Assert(table.itemAt(2).key, "row_3")
    @Assert(table.indexForKey("row_2"), 0)
    @Assert(table.indexForKey("row_1"), -1)
    @Assert(table.indexForKey("row_0"), 1)
}

@Test
func tableHeaderAndRowsShareColumnConstraintsAndOnlyVisibleRowsBuild(): Unit {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < 400) {
        rows.add(CjguiComposableUiVariableHeightListItem("row_${index}", index, "规则 ${index}", 0,
            estimatedHeight: 30))
        index += 1
    }
    let base = TableProjectionSource(rows.toArray())
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "test-table", tableTestColumns(), tableTestStyle())
    let header = table.buildHeader()
    let row = table.buildRow(table.itemAt(0), false, false)
    let headerCells = header.children()
    let rowCells = row.children()
    @Assert(headerCells.size, rowCells.size)
    var column: Int64 = 0
    while (column < headerCells.size) {
        @Assert(headerCells[column].style.fixedWidth, rowCells[column].style.fixedWidth)
        @Assert(headerCells[column].style.growX, rowCells[column].style.growX)
        @Assert(headerCells[column].style.padding, rowCells[column].style.padding)
        column += 1
    }
    // A 240pt-tall viewport over 400 rows must materialize only a window of rows.
    let _ = tableSceneWithIdentity(table, CjguiComposableUiVirtualListState(), 1)
    @Assert(base.itemReadCount > 0, true)
    @Assert(base.itemReadCount < 400, true)
}

@Test
func tableIdentityUsesScopedNamespacesAndStaysStableAcrossSort(): Unit {
    let base = TableProjectionSource(tableRows(["10", "2", "100"]))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "identity-table", tableTestColumns(),
        tableTestStyle())
    let state = CjguiComposableUiVirtualListState()
    let registry = CjguiComposableUiIdentityRegistry()
    let firstScene = tableIdentityScene(table, state, 1, registry)
    let headerNode = tableNodeBySemantic(firstScene, "identity-table-header")
    let headerCellNode = tableNodeBySemantic(firstScene, "identity-table-header-cell-name")
    let row0Node = tableNodeBySemantic(firstScene, "identity-table-row-row_0")
    let row1Node = tableNodeBySemantic(firstScene, "identity-table-row-row_1")
    let cell0Node = tableNodeBySemantic(firstScene, "identity-table-cell-row_0-name")
    @Assert(tableOptionPresent(headerNode), true)
    @Assert(tableOptionPresent(headerCellNode), true)
    @Assert(tableOptionPresent(row0Node), true)
    @Assert(tableOptionPresent(row1Node), true)
    @Assert(tableOptionPresent(cell0Node), true)
    var headerId: Int64 = -1
    var headerCellId: Int64 = -1
    var row0Id: Int64 = -1
    var row1Id: Int64 = -1
    var cell0Id: Int64 = -1
    if (let Some(node) <- headerNode) {
        headerId = node.nodeId
    }
    if (let Some(node) <- headerCellNode) {
        headerCellId = node.nodeId
    }
    if (let Some(node) <- row0Node) {
        row0Id = node.nodeId
    }
    if (let Some(node) <- row1Node) {
        row1Id = node.nodeId
    }
    if (let Some(node) <- cell0Node) {
        cell0Id = node.nodeId
    }
    // Scoped node ids are registry-owned, not a table-made hash range.
    @Assert(headerId >= 8000000000000000000, true)
    @Assert(headerCellId >= 8000000000000000000, true)
    @Assert(row0Id >= 8000000000000000000, true)
    @Assert(cell0Id >= 8000000000000000000, true)
    // Header, header cell, row and row cell live in distinct namespaces.
    @Assert(headerId != headerCellId, true)
    @Assert(headerId != row0Id, true)
    @Assert(headerCellId != cell0Id, true)
    @Assert(row0Id != cell0Id, true)

    // Sort numerically: 2 < 10 < 100, so row_1 is now displayed first. Its
    // stable business key must keep both the row and cell identity.
    @Assert(table.setSort("retention"), true)
    let secondScene = tableIdentityScene(table, state, 2, registry)
    let sortedFirst = tableNodeBySemantic(secondScene, "identity-table-row-row_1")
    let sortedSecond = tableNodeBySemantic(secondScene, "identity-table-row-row_0")
    let sortedCell0 = tableNodeBySemantic(secondScene, "identity-table-cell-row_0-name")
    @Assert(tableOptionPresent(sortedFirst), true)
    @Assert(tableOptionPresent(sortedSecond), true)
    @Assert(tableOptionPresent(sortedCell0), true)
    if (let Some(first) <- sortedFirst) {
        @Assert(first.nodeId, row1Id)
        if (let Some(second) <- sortedSecond) {
            @Assert(second.nodeId, row0Id)
            @Assert(first.bounds.y < second.bounds.y, true)
        }
    }
    if (let Some(cell) <- sortedCell0) {
        @Assert(cell.nodeId, cell0Id)
    }
}

@Test
func tableIdentityRejectsInvalidBusinessKeysExplicitly(): Unit {
    var longKey = ""
    var index = 0
    while (index < 97) {
        longKey += "a"
        index += 1
    }
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    rows.add(tableItem("bad key!", 7, "含非法字符"))
    rows.add(tableItem(longKey, 8, "超过96段"))
    let base = TableProjectionSource(rows.toArray())
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "invalid-key-table", tableTestColumns(),
        tableTestStyle())
    // The projection still contains the rows; rejection happens at identity
    // resolution, not by silently dropping business data.
    @Assert(table.itemCount(), 2)
    @Assert(table.itemAt(0).key, "bad key!")
    @Assert(table.itemAt(1).key, longKey)
    let row = table.buildRow(table.itemAt(0), false, false)
    @Assert(row.children().size, 2)
    @Assert(row.children()[0].value, "含非法字符")
    let registry = CjguiComposableUiIdentityRegistry()
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(row), "identity_invalid_scope_or_key")
    @Assert(registry.lastIssue(), "identity_invalid_scope_or_key")
    registry.rollbackCandidate()
    let longRow = table.buildRow(table.itemAt(1), false, false)
    @Assert(longRow.children().size, 2)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(longRow), "identity_invalid_scope_or_key")
    @Assert(registry.lastIssue(), "identity_invalid_scope_or_key")
    registry.rollbackCandidate()
}

@Test
func tableRowActionsComeFromCallerAndDisplayRowsStayInert(): Unit {
    let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
    rows.add(tableItem("row_active", 41, "启用行"))
    rows.add(tableItem("row_display", -1, "展示行"))
    rows.add(tableItem("row_static", 43, "静态行"))
    let base = TableProjectionSource(rows.toArray())
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "action-table", tableTestColumns(),
        tableTestStyle(), rowAction: { item =>
            if (item.resourceId >= 0) {
                CjguiComposableUiTableRowAction("CALLER_OPEN_RECORD", item.resourceId)
            } else {
                CjguiComposableUiTableRowAction.none()
            }
        })
    let activeRow = table.buildRow(table.itemAt(0), false, false)
    @Assert(activeRow.children()[0].nodeKind, CJGUI_COMPOSABLE_UI_BUTTON)
    @Assert(activeRow.children()[0].actionName, "CALLER_OPEN_RECORD")
    @Assert(activeRow.children()[0].resourceId, 41)
    @Assert(activeRow.children()[0].operationActionName, "CALLER_OPEN_RECORD")
    @Assert(activeRow.children()[0].operationResourceId, 41)
    // A legal display row with no caller action renders its values as text and
    // emits no business operation.
    let displayRow = table.buildRow(table.itemAt(1), false, false)
    @Assert(displayRow.children()[0].nodeKind, CJGUI_COMPOSABLE_UI_TEXT)
    @Assert(displayRow.children()[0].value, "展示行")
    @Assert(displayRow.children()[0].actionName, "")
    @Assert(displayRow.children()[0].operationActionName, "")
    @Assert(displayRow.children()[0].resourceId, -1)

    // A table with no provider at all is display-only too.
    let passive = CjguiComposableUiTableSource(filtered, "passive-table", tableTestColumns(),
        tableTestStyle())
    let passiveRow = passive.buildRow(passive.itemAt(0), false, false)
    @Assert(passiveRow.children()[0].nodeKind, CJGUI_COMPOSABLE_UI_TEXT)
    @Assert(passiveRow.children()[0].actionName, "")

    // A column without a sort action uses a static header cell.
    let staticColumns = ArrayList<CjguiComposableUiTableColumn>()
    staticColumns.add(CjguiComposableUiTableColumn("name", "规则名称", "label", 0, "",
        { item => item.title }, { left, right => 0 }))
    let staticTable = CjguiComposableUiTableSource(filtered, "static-header-table",
        staticColumns.toArray(), tableTestStyle())
    let staticHeader = staticTable.buildHeader()
    // The header cell is a container so a fixed column can carry its resize
    // grip; a column without a sort action still renders static text inside.
    @Assert(staticHeader.children()[0].nodeKind, CJGUI_COMPOSABLE_UI_HORIZONTAL)
    @Assert(staticHeader.children()[0].children()[0].nodeKind, CJGUI_COMPOSABLE_UI_TEXT)
    @Assert(staticHeader.children()[0].children()[0].actionName, "")

    // The rendered scene carries the caller's action on active cells and no
    // action on the display row; SELECT_RECORD is not synthesized here.
    let scene = tableSceneWithIdentity(table, CjguiComposableUiVirtualListState(), 1)
    let activeCell = tableNodeBySemantic(scene, "action-table-cell-row_active-name")
    let displayCell = tableNodeBySemantic(scene, "action-table-cell-row_display-name")
    @Assert(tableOptionPresent(activeCell), true)
    @Assert(tableOptionPresent(displayCell), true)
    if (let Some(node) <- activeCell) {
        @Assert(node.operationActionName, "CALLER_OPEN_RECORD")
        @Assert(node.operationResourceId, 41)
    }
    if (let Some(node) <- displayCell) {
        @Assert(node.value, "展示行")
        @Assert(node.actionName, "")
        @Assert(node.operationActionName, "")
    }
    var hardcodedSelect = false
    for (node in scene.nodes()) {
        if (node.actionName == "SELECT_RECORD") {
            hardcodedSelect = true
        }
    }
    @Assert(hardcodedSelect, false)
}

@Test
func tableGeometryChangesInvalidateMeasurementButPaintDoesNot(): Unit {
    let base = TableProjectionSource(tableRows(["alpha", "beta", "gamma"]))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "geometry-table", tableTestColumns(),
        tableStyleForMeasurement(30, CjguiComposableUiColor(0.99, 0.99, 0.99, 1.0)))
    let state = CjguiComposableUiVirtualListState()
    let firstScene = tableSceneWithIdentity(table, state, 1)
    let firstRow = tableNodeBySemantic(firstScene, "geometry-table-row-row_0")
    @Assert(tableOptionPresent(firstRow), true)
    if (let Some(node) <- firstRow) {
        @Assert(node.bounds.height, 30)
    }
    @Assert(table.measurementGeneration(), 0)

    // Same list state, geometry changed through the table's public style
    // update: the generation advances and the row is measured again.
    table.updatePresentation(tableStyleForMeasurement(44,
        CjguiComposableUiColor(0.99, 0.99, 0.99, 1.0)))
    @Assert(table.measurementGeneration(), 1)
    let secondScene = tableSceneWithIdentity(table, state, 2)
    let secondRow = tableNodeBySemantic(secondScene, "geometry-table-row-row_0")
    @Assert(tableOptionPresent(secondRow), true)
    if (let Some(node) <- secondRow) {
        @Assert(node.bounds.height, 44)
    }
    @Assert(state.lastDataIssue(), "")

    // Paint-only changes reuse the measured geometry and keep the generation.
    table.updatePresentation(tableStyleForMeasurement(44,
        CjguiComposableUiColor(0.60, 0.60, 0.60, 1.0)))
    @Assert(table.measurementGeneration(), 1)
    let thirdScene = tableSceneWithIdentity(table, state, 3)
    let thirdRow = tableNodeBySemantic(thirdScene, "geometry-table-row-row_0")
    @Assert(tableOptionPresent(thirdRow), true)
    if (let Some(node) <- thirdRow) {
        @Assert(node.bounds.height, 44)
    }
    @Assert(state.lastDataIssue(), "")
}

private func tableCreateRule(domain: CjguiRuleSetEditingDomain, label: String, enabled: Bool,
    retention: Int64, requestId: String): Unit {
    let result = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(domain.snapshot().version,
        label, enabled, retention, "cache", requestId))
    if (!result.applied) {
        throw IllegalArgumentException("table test rule create failed: ${result.reason}")
    }
}

private func tableControllerScene(controller: CjguiRuleSetComposableController,
    version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, 980, 620)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

private func tableNodeByActionAndResource(scene: CjguiComposableUiScene,
    actionName: String, resourceId: Int64): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.actionName == actionName && node.resourceId == resourceId) {
            return Some(node)
        }
    }
    return None
}

private func tableColumnStateFromContext(domain: CjguiRuleSetEditingDomain): String {
    for (resource in domain.contextSnapshot().resources) {
        if (resource.id == CjguiRuleSetEditingDomain.ruleSetResourceId) {
            for (field in resource.fields) {
                if (field.name == "tableColumns") {
                    return field.value.displayText()
                }
            }
        }
    }
    return ""
}

private func tableNodeByAction(scene: CjguiComposableUiScene,
    actionName: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.actionName == actionName) {
            return Some(node)
        }
    }
    return None
}

private func tableNodeBySemantic(scene: CjguiComposableUiScene,
    semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

private func tableOptionPresent<T>(value: ?T): Bool {
    match (value) {
        case Some(_) => true
        case None => false
    }
}

@Test
func tableViewAndSortKeepOwnerSelectionAndUncommittedDraft(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    tableCreateRule(domain, "重复规则", true, 10, "table-1")
    tableCreateRule(domain, "重复规则", false, 2, "table-2")
    tableCreateRule(domain, "长期归档", true, 30, "table-3")
    let targetId: Int64 = 2
    @Assert(domain.selectCollectionItemFromHuman(targetId).applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    var scene = tableControllerScene(controller, 1)

    // Edit through the ordinary detail field; nothing is applied yet.
    let editor = scene.nodeForId(200000000 + targetId * 16)
    @Assert(editor.nodeId, 200000000 + targetId * 16)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(editor, 28, "未应用草稿", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    let draftBefore = domain.formSnapshot()
    @Assert(draftBefore.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "未应用草稿")

    // Switch to the table view.
    let toggle = scene.nodeForId(200)
    @Assert(toggle.actionName, "TOGGLE_RULE_VIEW")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggle, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 2)
    @Assert(tableOptionPresent(tableNodeBySemantic(scene,
        "rule-set-table-row-rule_${targetId}")), true)

    // Click the name header once: display order and selection are independent.
    let nameSort = tableNodeByAction(scene, CjguiRuleSetTableColumns.sortNameAction)
    @Assert(tableOptionPresent(nameSort), true)
    if (let Some(node) <- nameSort) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    scene = tableControllerScene(controller, 3)
    // Sort by the numeric column: 2 < 10 < 100, so record 2 becomes first row.
    let retentionSort = tableNodeByAction(scene, CjguiRuleSetTableColumns.sortRetentionAction)
    @Assert(tableOptionPresent(retentionSort), true)
    if (let Some(node) <- retentionSort) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    scene = tableControllerScene(controller, 4)
    let firstRow = tableNodeBySemantic(scene, "rule-set-table-row-rule_2")
    let secondRow = tableNodeBySemantic(scene, "rule-set-table-row-rule_1")
    @Assert(tableOptionPresent(firstRow), true)
    @Assert(tableOptionPresent(secondRow), true)
    if (let Some(first) <- firstRow) {
        if (let Some(second) <- secondRow) {
            @Assert(first.bounds.y < second.bounds.y, true)
        }
    }
    // The display order changed, but the owner still points at record 2 and its
    // uncommitted draft is intact and visible in the same detail editor.
    @Assert(domain.selectedRecordId(), targetId)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "未应用草稿")
    let editorAfterSort = scene.nodeForId(200000000 + targetId * 16)
    @Assert(editorAfterSort.value, "未应用草稿")
    @Assert(domain.snapshot().recordById(targetId).label, "重复规则")

    // Switch back to the list, change the sort again, and re-check the same key.
    let toggleBack = scene.nodeForId(200)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggleBack, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 5)
    @Assert(domain.selectedRecordId(), targetId)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "未应用草稿")
    let listEditor = scene.nodeForId(200000000 + targetId * 16)
    @Assert(listEditor.value, "未应用草稿")

    // Explicit apply through the owner's existing action applies the draft.
    let applyNode = scene.nodeForId(300000000 + targetId * 4)
    @Assert(applyNode.actionName, "APPLY")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(applyNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(domain.snapshot().recordById(targetId).label, "未应用草稿")
    @Assert(domain.selectedRecordId(), targetId)
}

@Test
func collectionSelectionIsSharedAcrossListTableFilterAndBatch(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    tableCreateRule(domain, "Alpha", true, 10, "collection-1")
    tableCreateRule(domain, "Beta", true, 2, "collection-2")
    tableCreateRule(domain, "Gamma", true, 30, "collection-3")
    tableCreateRule(domain, "Delta", true, 5, "collection-4")
    @Assert(domain.collectionRangeSnapshot().totalCount, 4)
    let targetId: Int64 = 2
    @Assert(domain.selectCollectionItemFromHuman(targetId).applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    var scene = tableControllerScene(controller, 1)

    // An uncommitted label draft on record 2. Nothing applies it on selection,
    // filter, sort or view changes.
    let editor = scene.nodeForId(200000000 + targetId * 16)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(editor, 28, "未应用草稿", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 2)

    // The real pointer sequence is FOCUS (modifiers zero) then ACTIVATE
    // (this gesture's modifiers). FOCUS must not settle a second click.
    var versionBefore = controller.collectionSelectionVersion()
    let row1 = scene.nodeForId(100000 + 1)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row1, 31, "", 0, 0,
        controller.uiSceneVersion())).didApply, false)
    @Assert(controller.collectionSelectionVersion(), versionBefore)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row1, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(controller.collectionSelectionVersion(), versionBefore + 1)
    scene = tableControllerScene(controller, 3)
    var selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 1)
    @Assert(selected[0], "rule_1")

    // Command+click adds record 2. Its FOCUS carries no modifier and changes
    // nothing; the ACTIVATE settles exactly once.
    let row2 = scene.nodeForId(100000 + 2)
    versionBefore = controller.collectionSelectionVersion()
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 31, "", 0, 0,
        controller.uiSceneVersion())).didApply, false)
    @Assert(controller.collectionSelectionVersion(), versionBefore)
    // FOCUS must not clear the existing plain selection before ACTIVATE.
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 1)
    @Assert(selected[0], "rule_1")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 27, "", 0, 0,
        controller.uiSceneVersion(), modifierFlags: CJGUI_UI_MODIFIER_COMMAND)).didApply, true)
    @Assert(controller.collectionSelectionVersion(), versionBefore + 1)
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 2)
    @Assert(selected[0], "rule_1")
    @Assert(selected[1], "rule_2")
    @Assert(domain.selectedRecordId(), targetId)
    @Assert(controller.collectionHiddenCount(), 0)

    // Repeating Command+click on the SAME row toggles once per ACTIVATE:
    // off, then on again, with no FOCUS-side duplicate.
    versionBefore = controller.collectionSelectionVersion()
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 31, "", 0, 0,
        controller.uiSceneVersion())).didApply, false)
    // The multi-selection is still intact before the second ACTIVATE.
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 2)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 27, "", 0, 0,
        controller.uiSceneVersion(), modifierFlags: CJGUI_UI_MODIFIER_COMMAND)).didApply, true)
    @Assert(controller.collectionSelectionVersion(), versionBefore + 1)
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 1)
    @Assert(selected[0], "rule_1")
    @Assert(domain.selectedRecordId(), targetId)
    versionBefore = controller.collectionSelectionVersion()
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 31, "", 0, 0,
        controller.uiSceneVersion())).didApply, false)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row2, 27, "", 0, 0,
        controller.uiSceneVersion(), modifierFlags: CJGUI_UI_MODIFIER_COMMAND)).didApply, true)
    @Assert(controller.collectionSelectionVersion(), versionBefore + 1)
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 2)
    @Assert(selected[0], "rule_1")
    @Assert(selected[1], "rule_2")

    // A view switch is a projection change: the externally visible viewVersion
    // moves (the switch also widens the split, so this is not used to prove
    // "owner version unchanged" - sorting and filtering below do that).
    let viewVersionBeforeViewSwitch = controller.collectionSelectionSnapshot().viewVersion
    scene = tableControllerScene(controller, 4)
    let toggle = scene.nodeForId(200)
    @Assert(toggle.actionName, "TOGGLE_RULE_VIEW")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggle, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(controller.collectionSelectionSnapshot().viewVersion > viewVersionBeforeViewSwitch, true)
    scene = tableControllerScene(controller, 5)
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 2)
    @Assert(selected[0], "rule_1")
    @Assert(selected[1], "rule_2")
    @Assert(domain.selectedRecordId(), targetId)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "未应用草稿")

    // Sorting changes the order only. Selected business keys survive, and the
    // projection version advances although the document version does not.
    let dataVersionBeforeSort = domain.version()
    let viewVersionBeforeSort = controller.collectionSelectionSnapshot().viewVersion
    if (let Some(node) <- tableNodeByAction(scene, CjguiRuleSetTableColumns.sortRetentionAction)) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    @Assert(domain.version(), dataVersionBeforeSort)
    @Assert(controller.collectionSelectionSnapshot().viewVersion > viewVersionBeforeSort, true)
    scene = tableControllerScene(controller, 6)
    selected = controller.collectionSelectionSnapshot().keys
    @Assert(selected.size, 2)
    @Assert(selected[0], "rule_1")
    @Assert(selected[1], "rule_2")
    @Assert(controller.collectionHiddenCount(), 0)

    // Filter hides record 1 but keeps it selected; the batch bar says so.
    // The filter is also a projection-only change and must move viewVersion.
    let dataVersionBeforeFilter = domain.version()
    let viewVersionBeforeFilter = controller.collectionSelectionSnapshot().viewVersion
    let filterNode = scene.nodeForId(24)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(filterNode, 28, "Beta", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(domain.version(), dataVersionBeforeFilter)
    @Assert(controller.collectionSelectionSnapshot().viewVersion > viewVersionBeforeFilter, true)
    scene = tableControllerScene(controller, 7)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 2)
    @Assert(controller.collectionHiddenCount(), 1)
    let countLabel = scene.nodeForId(211)
    @Assert(countLabel.value, "已选 2 项，其中隐藏 1 项")

    // One batch submission over the selected keys, INCLUDING the hidden one.
    let disableNode = scene.nodeForId(214)
    @Assert(disableNode.actionName, "COLLECTION_BATCH_DISABLE")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(disableNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 8)
    @Assert(domain.snapshot().recordById(1).enabled, false)
    @Assert(domain.snapshot().recordById(2).enabled, false)
    @Assert(domain.snapshot().recordById(3).enabled, true)
    @Assert(domain.snapshot().recordById(4).enabled, true)
    @Assert(domain.selectedRecordId(), targetId)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "未应用草稿")

    // Clear the filter: both records are really visible and still selected.
    let clearFilter = scene.nodeForId(24)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(clearFilter, 28, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 9)
    @Assert(controller.collectionHiddenCount(), 0)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 2)

    // A conflicting enabled draft on one target must reject the WHOLE batch
    // and preserve the previous applied values of every target.
    @Assert(domain.editBooleanForCollectionItemFromHuman(targetId,
        CjguiRuleSetEditingDomain.formEnabledResourceId, true).applied, true)
    let conflictVersionBefore = domain.version()
    let enableNode = scene.nodeForId(213)
    @Assert(enableNode.actionName, "COLLECTION_BATCH_ENABLE")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(enableNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, false)
    scene = tableControllerScene(controller, 10)
    @Assert(domain.version(), conflictVersionBefore)
    @Assert(domain.snapshot().recordById(1).enabled, false)
    @Assert(domain.snapshot().recordById(2).enabled, false)
    @Assert(domain.collectionRangeSnapshot().totalCount, 4)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "未应用草稿")

    // Clear selection through the shared entry; the active record stays.
    let clearSelection = scene.nodeForId(215)
    @Assert(clearSelection.actionName, "COLLECTION_CLEAR")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(clearSelection, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 0)
    @Assert(domain.selectedRecordId(), targetId)

    // The explicit owner apply is still the only path that applies the draft.
    scene = tableControllerScene(controller, 11)
    let applyNode = scene.nodeForId(300000000 + targetId * 4)
    @Assert(applyNode.actionName, "APPLY")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(applyNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(domain.snapshot().recordById(targetId).label, "未应用草稿")
    @Assert(domain.snapshot().recordById(targetId).enabled, true)
}

@Test
func collectionRejectedRequestKeepsPreviousSurfaceAndRouting(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    tableCreateRule(domain, "Alpha", true, 10, "reject-1")
    tableCreateRule(domain, "Beta", true, 2, "reject-2")
    let controller = CjguiRuleSetComposableController(domain)
    // Building the ordinary scene attaches the shared collection surface.
    let _ = tableControllerScene(controller, 1)
    let panel = controller.treeSelectionProvider()

    // The tree is the surface the human used last.
    panel.markTreeActive()
    @Assert(panel.applySelection("expand", "group-enabled", panel.selection.selectionVersion()).applied,
        true)
    let treeAll = panel.applySelection("select-all", "", panel.selection.selectionVersion())
    @Assert(treeAll.applied, true)
    @Assert(panel.selection.selectedCount(), 2)
    @Assert(panel.selectionPayload().startsWith("SCOPE tree"), true)

    // Stale version, unknown key and unknown command addressed to the
    // collection are rejected without changing surface, selection or routing.
    let collectionVersion = controller.collectionSelectionVersion()
    let treeVersion = treeAll.selectionVersion
    let stale = panel.applySelection("toggle", "rule_1", collectionVersion + 1)
    @Assert(stale.applied, false)
    @Assert(stale.reason, "selection_version_conflict")
    @Assert(panel.selectionPayload().startsWith("SCOPE tree"), true)
    @Assert(panel.selection.selectedCount(), 2)
    @Assert(panel.selection.selectionVersion(), treeVersion)

    let unknownKey = panel.applySelection("toggle", "rule_99999", collectionVersion)
    @Assert(unknownKey.applied, false)
    @Assert(unknownKey.reason, "unknown_key")
    @Assert(panel.selectionPayload().startsWith("SCOPE tree"), true)
    @Assert(panel.selection.selectedCount(), 2)

    let unknownCommand = panel.applySelection("expand", "rule_1", collectionVersion)
    @Assert(unknownCommand.applied, false)
    @Assert(unknownCommand.reason, "unknown_command")
    @Assert(panel.selectionPayload().startsWith("SCOPE tree"), true)
    @Assert(controller.collectionSelectionVersion(), collectionVersion)

    // Since the rejected requests did not steal the surface, a key-less
    // command still routes to the tree.
    let clearTree = panel.applySelection("clear", "", panel.selection.selectionVersion())
    @Assert(clearTree.applied, true)
    @Assert(panel.selectionPayload().startsWith("SCOPE tree"), true)
    @Assert(panel.selection.selectedCount(), 0)

    // The inverse also holds: a rejected request while the collection is the
    // current surface keeps collection routing.
    panel.markCollectionActive()
    let staleOnCollection = panel.applySelection("toggle", "rule_1",
        controller.collectionSelectionVersion() + 1)
    @Assert(staleOnCollection.applied, false)
    @Assert(panel.selectionPayload().startsWith("SCOPE collection"), true)
    let clearCollection = panel.applySelection("clear", "",
        controller.collectionSelectionVersion())
    @Assert(clearCollection.applied, true)
    @Assert(panel.selectionPayload().startsWith("SCOPE collection"), true)
}

@Test
func tableColumnLayoutHumanAndExternalShareStateAndKeepOwnerData(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    tableCreateRule(domain, "Alpha", true, 10, "column-1")
    tableCreateRule(domain, "Beta", true, 20, "column-2")
    tableCreateRule(domain, "Gamma", false, 30, "column-3")
    let controller = CjguiRuleSetComposableController(domain)
    let layout = controller.tableColumnLayout()
    @Assert(domain.snapshot().version > 0, true)
    var scene = tableControllerScene(controller, 1)
    let viewToggle = scene.nodeForId(200)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(viewToggle, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 2)
    @Assert(layout.columnCount(), 4)

    // Select record 2 first, then leave an uncommitted draft that must survive
    // every column edit.
    if (let Some(row) <- tableNodeByActionAndResource(scene, "SELECT_RECORD", 2)) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(row, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    } else {
        @Assert(false, true)
    }
    @Assert(domain.selectedRecordId(), 2)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    scene = tableControllerScene(controller, 3)
    let editor = scene.nodeForId(200000000 + 2 * 16)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(editor, 28, "列宽草稿", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 4)
    if (let Some(sortNode) <- tableNodeByAction(scene, CjguiRuleSetTableColumns.sortRetentionAction)) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(sortNode, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    scene = tableControllerScene(controller, 5)

    // Human menu: open, hide one column, verify header/body and owner data.
    let openMenu = scene.nodeForId(204)
    @Assert(openMenu.actionName, "OPEN_COLUMN_MENU")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(openMenu, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 5)
    if (let Some(toggle) <- tableNodeBySemantic(scene, "column-toggle-enabled")) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggle, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    } else {
        @Assert(false, true)
    }
    @Assert(layout.isVisible("enabled"), false)
    @Assert(layout.width("enabled"), 68)
    scene = tableControllerScene(controller, 6)
    @Assert(tableOptionPresent(tableNodeBySemantic(scene, "rule-set-table-header-cell-enabled")), false)
    @Assert(tableOptionPresent(tableNodeBySemantic(scene, "rule-set-table-cell-rule_2-enabled")), false)
    @Assert(tableOptionPresent(tableNodeBySemantic(scene, "rule-set-table-cell-rule_2-name")), true)
    @Assert(domain.snapshot().recordById(2).label, "Beta")
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "列宽草稿")
    // Restore it, then reorder and nudge width through the same menu.
    if (let Some(toggle) <- tableNodeBySemantic(scene, "column-toggle-enabled")) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggle, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    scene = tableControllerScene(controller, 7)
    if (let Some(moveLeft) <- tableNodeBySemantic(scene, "column-left-excluded")) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(moveLeft, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    @Assert(layout.visibleKeys(), ArrayList<String>(["name", "enabled", "excluded", "retention"]))
    scene = tableControllerScene(controller, 8)
    if (let Some(wider) <- tableNodeBySemantic(scene, "column-wider-retention")) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(wider, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    @Assert(layout.width("retention"), 94)
    scene = tableControllerScene(controller, 9)
    let headerRetention = tableNodeBySemantic(scene, "rule-set-table-header-cell-retention")
    let bodyRetention = tableNodeBySemantic(scene, "rule-set-table-cell-rule_2-retention")
    if (let Some(header) <- headerRetention) { @Assert(header.style.fixedWidth, 94) }
    if (let Some(body) <- bodyRetention) { @Assert(body.style.fixedWidth, 94) }
    if (let Some(reset) <- tableNodeBySemantic(scene, "column-menu-reset")) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(reset, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    } else {
        @Assert(false, true)
    }
    @Assert(layout.width("retention"), 78)
    @Assert(layout.visibleCount(), 4)
    @Assert(layout.visibleKeys(), ArrayList<String>(["name", "enabled", "retention", "excluded"]))
    scene = tableControllerScene(controller, 10)

    // Close the menu, then drive the real pointer phases on the header grip.
    let closeMenu = scene.nodeForId(560198)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(closeMenu, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = tableControllerScene(controller, 11)
    let grip = tableNodeBySemantic(scene, "rule-set-table-header-resize-retention")
    @Assert(tableOptionPresent(grip), true)
    if (let Some(node) <- grip) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 37, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 100)).didApply, true)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 38, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 140)).didApply, true)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 39, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 140)).didApply, true)
        @Assert(layout.width("retention"), 118)
        // Keyboard nudge uses the same grip and the same layout object.
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "right", 0, 0,
            controller.uiSceneVersion())).didApply, true)
        @Assert(layout.width("retention"), 126)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 37, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 200)).didApply, true)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 38, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 230)).didApply, true)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node, 40, "", 0, 0,
            controller.uiSceneVersion(), pointerX: 230)).didApply, true)
        @Assert(layout.width("retention"), 126)
    }
    scene = tableControllerScene(controller, 12)
    if (let Some(header) <- tableNodeBySemantic(scene, "rule-set-table-header-cell-retention")) {
        @Assert(header.style.fixedWidth, 126)
    }
    if (let Some(body) <- tableNodeBySemantic(scene, "rule-set-table-cell-rule_2-retention")) {
        @Assert(body.style.fixedWidth, 126)
    }

    // External width edit uses the SAME object and its own published revision.
    var revision = layout.revision()
    let widthArgs = ArrayList<CjguiSharedOperationActionArgument>([
        CjguiSharedOperationActionArgument("columnKey", CjguiSharedOperationValue.string("retention")),
        CjguiSharedOperationActionArgument("width", CjguiSharedOperationValue.integer(150))
    ])
    let externalWidth = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        widthArgs))
    @Assert(externalWidth.applied, true)
    @Assert(layout.width("retention"), 150)
    @Assert(externalWidth.versionAfter, revision + 1)
    // A stale presentation revision is rejected and keeps the old width.
    let staleWidth = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("columnKey", CjguiSharedOperationValue.string("retention")),
            CjguiSharedOperationActionArgument("width", CjguiSharedOperationValue.integer(220))
        ])))
    @Assert(staleWidth.applied, false)
    @Assert(staleWidth.isVersionConflict, true)
    @Assert(layout.width("retention"), 150)
    // Hide and reorder externally; the human then continues on the same state.
    revision = layout.revision()
    let hide = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_VISIBLE", revision, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("columnKey", CjguiSharedOperationValue.string("excluded")),
            CjguiSharedOperationActionArgument("visible", CjguiSharedOperationValue.boolean(false))
        ])))
    @Assert(hide.applied, true)
    revision = layout.revision()
    let move = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "MOVE_TABLE_COLUMN", revision, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("columnKey", CjguiSharedOperationValue.string("retention")),
            CjguiSharedOperationActionArgument("offset", CjguiSharedOperationValue.integer(-1))
        ])))
    @Assert(move.applied, true)
    @Assert(layout.isVisible("excluded"), false)
    @Assert(layout.visibleKeys(), ArrayList<String>(["name", "retention", "enabled"]))
    scene = tableControllerScene(controller, 13)
    @Assert(tableOptionPresent(tableNodeBySemantic(scene, "rule-set-table-header-cell-excluded")), false)
    // Human sort after the external edits: only the order changes, not layout.
    if (let Some(sortNode) <- tableNodeByAction(scene, CjguiRuleSetTableColumns.sortNameAction)) {
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(sortNode, 27, "", 0, 0,
            controller.uiSceneVersion())).didApply, true)
    }
    @Assert(controller.tableColumnLayout().visibleKeys(), ArrayList<String>(["name", "retention", "enabled"]))
    @Assert(layout.width("retention"), 150)
    @Assert(domain.selectedRecordId(), 2)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "列宽草稿")
    // Filtering temporarily hides the selected/draft record but keeps both.
    scene = tableControllerScene(controller, 14)
    let filterNode = scene.nodeForId(24)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(filterNode, 28, "Alpha", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(controller.collectionHiddenCount(), 1)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "列宽草稿")
    // The existing context query publishes the SAME layout, not a mirror.
    let state = tableColumnStateFromContext(domain)
    @Assert(state.contains("retention:150:1"), true)
}

@Test
func tableColumnActionsRejectWrongEmptyAndMultipleTargets(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    tableCreateRule(domain, "Alpha", true, 10, "column-target-1")
    let controller = CjguiRuleSetComposableController(domain)
    let layout = controller.tableColumnLayout()
    let revision = layout.revision()
    let widthArguments = ArrayList<CjguiSharedOperationActionArgument>([
        CjguiSharedOperationActionArgument("columnKey", CjguiSharedOperationValue.string("retention")),
        CjguiSharedOperationActionArgument("width", CjguiSharedOperationValue.integer(120))
    ])
    let emptyTargets = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision, ArrayList<Int64>(), widthArguments))
    @Assert(emptyTargets.applied, false)
    @Assert(emptyTargets.reason, "invalid_target")
    @Assert(emptyTargets.isVersionConflict, false)
    let multipleTargets = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision,
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId, 8001]), widthArguments))
    @Assert(multipleTargets.applied, false)
    @Assert(multipleTargets.reason, "invalid_target")
    let wrongTarget = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision,
        ArrayList<Int64>([8001]), widthArguments))
    @Assert(wrongTarget.applied, false)
    @Assert(wrongTarget.reason, "invalid_target")
    @Assert(layout.revision(), revision)
    @Assert(layout.width("retention"), 78)
    // A legal target uses the presentation revision, not the document version.
    let legal = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_TABLE_COLUMN_WIDTH", revision,
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), widthArguments))
    @Assert(legal.applied, true)
    @Assert(legal.reason, "column_width_set")
    @Assert(layout.width("retention"), 120)
    @Assert(layout.revision(), revision + 1)
}
