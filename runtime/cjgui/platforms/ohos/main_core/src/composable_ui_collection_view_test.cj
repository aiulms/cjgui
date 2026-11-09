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
            CjguiComposableUiStyle(fixedHeight: 30),
            identity: Some(CjguiComposableUiIdentityScope("local-list").child(item.key).local("row")))
    }
}

private class RegionScopedRowSource <: CjguiComposableUiVariableHeightListSource {
    public func itemCount(): Int64 {
        return 1
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index != 0) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return CjguiComposableUiVariableHeightListItem("cardA", 7, "卡片 A", 0, estimatedHeight: 30)
    }
    public func indexForKey(key: String): Int64 {
        return if (key == "cardA") { 0 } else { -1 }
    }
    public func measurementGeneration(): Int64 {
        return 0
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableButton(-1, "region-scoped-row", item.title, "SELECT_ROW", item.resourceId,
            CjguiComposableUiStyle(fixedHeight: 30),
            identity: Some(CjguiComposableUiIdentityScope("local-list").child(item.key).local("row")))
    }
}

private func regionScopedCollection(): CjguiGeneratedUiCollection {
    let source = RegionScopedRowSource()
    let filtered = CjguiComposableUiFilteredListSource(source, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "region-scoped-table",
        [collectionViewColumn("name", "名称", 200)], collectionViewStyle())
    return CjguiGeneratedUiCollection("regionRows", "regionRowList", source, table,
        CjguiComposableUiCollectionSelection())
}

private func regionScopedRowIdentity(collection: CjguiGeneratedUiCollection,
    scope!: ?CjguiComposableUiIdentityScope = None): String {
    let root = collection.buildNode(1, "region-list", 2, "region-content", "list",
        CjguiComposableUiStyle(), identityScope: scope)
    let rows = root.variableHeightListSource().getOrThrow()
    let built = rows.buildRow(rows.itemAt(0), false, false)
    return built.scopedIdentity().getOrThrow().canonicalKey()
}

@Test
func collectionRowsAreScopedPerRegionMount(): Unit {
    let collection = regionScopedCollection()
    let first = regionScopedRowIdentity(collection,
        scope: Some(CjguiComposableUiIdentityScope("print-preset-runtime")))
    let second = regionScopedRowIdentity(collection,
        scope: Some(CjguiComposableUiIdentityScope("print-preset-summary")))
    let handwritten = regionScopedRowIdentity(collection)
    @Expect(first != second)
    @Expect(first != handwritten)
    @Expect(second != handwritten)
    @Expect(first.contains("print-preset-runtime"))
    @Expect(second.contains("print-preset-summary"))
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

// --- DS51 §11: independent accepted mounts, lifecycle and targeted reveal ---

private func collectionMountNode(collection: CjguiGeneratedUiCollection,
    scope: CjguiComposableUiIdentityScope, instanceKey: String, incarnation: Int64,
    presentation: String, accepted!: Bool = true, viewportNodeId!: Int64 = 920001,
    acceptedKeys!: ?HashSet<String> = None): CjguiComposableUiNode {
    let elements = ArrayList<CjguiCompositeElementBinding>()
    elements.add(CjguiCompositeElementBinding("viewport", CJGUI_COMPOSITE_ELEMENT_CONTAINER,
        viewportNodeId, "${instanceKey}-viewport", "视口", instanceKey: instanceKey,
        instanceIncarnation: incarnation))
    elements.add(CjguiCompositeElementBinding("content", CJGUI_COMPOSITE_ELEMENT_CONTAINER,
        viewportNodeId + 1, "${instanceKey}-content", "内容", instanceKey: instanceKey,
        instanceIncarnation: incarnation))
    let properties = HashMap<String, String>()
    properties.add("collection", collection.key)
    properties.add("presentation", presentation)
    return collection.buildComposite(CjguiCompositeBuildContext(instanceKey, properties, elements,
        holderScope: Some(scope), instanceIncarnation: incarnation, acceptedBuild: accepted,
        acceptedSceneKeys: acceptedKeys))
}

/// Six 30pt rows behind one filtered table, so a reveal has real variable
/// geometry beyond index zero and the table header occupies a real first row.
private func mountableCollection(): CjguiGeneratedUiCollection {
    let base = CollectionViewTestSource(collectionViewRows())
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, "mount-table",
        [collectionViewColumn("name", "名称", 200)], collectionViewStyle())
    return CjguiGeneratedUiCollection("mountRows", "mountRowList", base, table,
        CjguiComposableUiCollectionSelection())
}

@Test
func collectionMountsOwnIndependentViewStateAndRetireOldHandles(): Unit {
    let collection = mountableCollection()
    let scope = CjguiComposableUiIdentityScope("mount-region")
    let tableNode = collectionMountNode(collection, scope, "table", 1, "table",
        viewportNodeId: 920001)
    let listNode = collectionMountNode(collection, scope, "list", 1, "list",
        viewportNodeId: 920101)
    // Header, data rows and their children carry the mount domain, and two
    // mounts never share one registry key.
    let tableRows = tableNode.variableHeightListSource().getOrThrow()
    let listRows = listNode.variableHeightListSource().getOrThrow()
    let tableHeader = tableRows.buildRow(tableRows.itemAt(0), false, false)
    let tableRow = tableRows.buildRow(tableRows.itemAt(1), false, false)
    let listRow = listRows.buildRow(listRows.itemAt(0), false, false)
    let headerKey = tableHeader.scopedIdentity().getOrThrow().canonicalKey()
    let tableRowKey = tableRow.scopedIdentity().getOrThrow().canonicalKey()
    let listRowKey = listRow.scopedIdentity().getOrThrow().canonicalKey()
    @Assert(headerKey.contains("mount-region"), true)
    @Assert(headerKey != tableRowKey, true)
    @Assert(tableRowKey != listRowKey, true)
    @Assert(tableRowKey.contains("table"), true)
    @Assert(listRowKey.contains("list"), true)

    let table = collection.acceptedView(scope, "table").getOrThrow()
    let list = collection.acceptedView(scope, "list").getOrThrow()
    @Assert(table.mountKey != list.mountKey, true)
    // Real accepted geometry: both mounts know 30pt rows in a 60pt viewport,
    // including the table's header row, so requestOffset is clamped against
    // the same extents a laid-out scene would have published.
    table.listState().updateVariableMaterializedRange(tableRows, 30, 0, 60, 2)
    list.listState().updateVariableMaterializedRange(listRows, 30, 0, 60, 2)
    table.viewport.stageExtents(210, 60, 0)
    table.viewport.commitStagedExtents()
    list.viewport.stageExtents(180, 60, 0)
    list.viewport.commitStagedExtents()
    // Targeted reveal moves ONLY the named mount, and the table's header row
    // shifts its data indices by one.
    @Assert(collection.revealItem("row_4", scope, "table"), true)
    @Assert(table.scrollOffset(), 150)
    @Assert(list.scrollOffset(), 0)
    @Assert(collection.revealItem("row_4", scope, "ghost"), false)

    // A candidate with a new generation must not retire or capture the
    // accepted view: reveal still addresses incarnation 1.
    let _ = collectionMountNode(collection, scope, "table", 2, "table", accepted: false,
        viewportNodeId: 920201)
    @Assert(collection.acceptedView(scope, "table").getOrThrow().incarnation, 1)
    @Assert(collection.revealItem("row_4", scope, "table"), true)
    @Assert(table.scrollOffset(), 150)

    // An ACCEPTED replacement retires the old handle; the new mount works.
    let replacementNode = collectionMountNode(collection, scope, "table", 2, "list",
        accepted: true, viewportNodeId: 920301)
    @Assert(table.isRetired(), true)
    @Assert(table.revealItem("row_4"), false)
    let replacement = collection.acceptedView(scope, "table").getOrThrow()
    @Assert(replacement.incarnation, 2)
    let replacementRows = replacementNode.variableHeightListSource().getOrThrow()
    replacement.listState().updateVariableMaterializedRange(replacementRows, 30, 0, 60, 2)
    replacement.viewport.stageExtents(180, 60, 0)
    replacement.viewport.commitStagedExtents()
    @Assert(collection.revealItem("row_4", scope, "table"), true)
    @Assert(replacement.scrollOffset(), 120)
    @Assert(list.isRetired(), false)
    @Assert(list.scrollOffset(), 0)
}

@Test
func removedCollectionInstanceRetiresItsMountAndReAddIsFresh(): Unit {
    let collection = mountableCollection()
    let scope = CjguiComposableUiIdentityScope("remove-region")
    let both = HashSet<String>()
    both.add("table")
    both.add("list")
    let tableNode = collectionMountNode(collection, scope, "table", 1, "table",
        acceptedKeys: both, viewportNodeId: 921001)
    let _ = collectionMountNode(collection, scope, "list", 1, "list",
        acceptedKeys: both, viewportNodeId: 921101)
    let table = collection.acceptedView(scope, "table").getOrThrow()
    let rows = tableNode.variableHeightListSource().getOrThrow()
    table.listState().updateVariableMaterializedRange(rows, 30, 0, 60, 2)
    table.viewport.stageExtents(210, 60, 0)
    table.viewport.commitStagedExtents()
    @Assert(collection.revealItem("row_4", scope, "table"), true)
    @Assert(table.scrollOffset(), 150)

    // The next accepted structure still declares the list and drops the table.
    // No replacement build exists for the removed instance, so only the scene's
    // key set can retire it - and the old handle must refuse afterwards.
    let listOnly = HashSet<String>()
    listOnly.add("list")
    let _ = collectionMountNode(collection, scope, "list", 1, "list",
        acceptedKeys: listOnly, viewportNodeId: 921201)
    @Assert(table.isRetired(), true)
    @Assert(collection.acceptedView(scope, "table").isNone(), true)
    @Assert(collection.revealItem("row_4", scope, "table"), false)
    @Assert(collection.acceptedView(scope, "list").getOrThrow().isRetired(), false)

    // A later re-add is a NEW accepted mount, not the old view state.
    let readdedNode = collectionMountNode(collection, scope, "table", 2, "table",
        acceptedKeys: both, viewportNodeId: 921301)
    let readded = collection.acceptedView(scope, "table").getOrThrow()
    @Assert(readded.incarnation, 2)
    @Assert(readded.isRetired(), false)
    let readdedRows = readdedNode.variableHeightListSource().getOrThrow()
    readded.listState().updateVariableMaterializedRange(readdedRows, 30, 0, 60, 2)
    readded.viewport.stageExtents(210, 60, 0)
    readded.viewport.commitStagedExtents()
    @Assert(collection.revealItem("row_4", scope, "table"), true)
    @Assert(readded.scrollOffset(), 150)
}

// --- DS51 §12: mounts live in the REAL holder accept transaction -------------
//
// The two tests above hand-build a CjguiCompositeBuildContext and pass
// acceptedBuild=true directly. They cannot prove that a scene commit publishes,
// that a rollback keeps the accepted mount, or that a removal with no
// replacement build retires it: only the real CjguiGeneratedUiStructureHolder
// transaction can.

class CollectionTransactionProbeFactory <: CjguiCompositeComponentFactory {
    public var failNow: Bool = false

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        if (failNow) {
            // No expansion allocated this identity: the composite audit must
            // refuse the WHOLE render even though an earlier sibling (the
            // collection) already built successfully.
            return cjguiComposableText(989899, "transaction-probe-foreign", "", CjguiComposableUiStyle())
        }
        let element = match (context.element("probe")) {
            case Some(value) => value
            case None => throw Exception("transaction probe element missing")
        }
        return cjguiComposableText(element.nodeId, element.semanticId, "probe", CjguiComposableUiStyle())
    }
}

private func collectionTransactionCatalog(collection: CjguiGeneratedUiCollection,
    probe: CollectionTransactionProbeFactory): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8)), true)
    let labelProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 200))
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false)), true)
    let probeProperties = CjguiGeneratedUiPresentation.containerStyleProperties()
    @Assert(catalog.registerComposite(CjguiCompositeComponentSpec("transactionProbe", probeProperties,
        ArrayList<CjguiCompositeElementSpec>([CjguiCompositeElementSpec("probe",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER)]), expandedNodeLimit: 4, expandedDepthLimit: 4), probe), true)
    @Assert(collection.register(catalog), true)
    return catalog
}

private func collectionTransactionCollectionSpec(instanceKey: String,
    presentation!: String = "table"): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("collection", "mountRows")
    properties.add("presentation", presentation)
    return CjguiGeneratedUiNodeSpec(instanceKey, "mountRowList", properties: properties)
}

private func collectionTransactionLabelSpec(key: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("text", "标签")
    return CjguiGeneratedUiNodeSpec(key, "label", properties: properties)
}

private func collectionTransactionProbeSpec(key: String): CjguiGeneratedUiNodeSpec {
    return CjguiGeneratedUiNodeSpec(key, "transactionProbe")
}

private func collectionTransactionRoot(
    children: ArrayList<CjguiGeneratedUiNodeSpec>): CjguiGeneratedUiNodeSpec {
    return CjguiGeneratedUiNodeSpec("transaction-root", "vertical", children: children)
}

/// Accepts ONE structure through the real holder transaction the window uses and
/// returns the node the scene built (its materialisation is the accepted one).
private func collectionTransactionAcceptNode(holder: CjguiGeneratedUiStructureHolder,
    provider: CjguiGeneratedUiBindingProvider, spec: CjguiGeneratedUiNodeSpec): ?CjguiComposableUiNode {
    if (!holder.submit(spec, provider).candidateAccepted) { return None }
    if (!holder.beginCandidateRefresh()) { return None }
    let node = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        holder.rollbackCandidateRefresh()
        return None
    }
    if (!holder.commitCandidateRefresh()) { return None }
    return Some(node)
}

private func collectionTransactionAccept(holder: CjguiGeneratedUiStructureHolder,
    provider: CjguiGeneratedUiBindingProvider, spec: CjguiGeneratedUiNodeSpec): Bool {
    return collectionTransactionAcceptNode(holder, provider, spec).isSome()
}

private func collectionTransactionRows(node: CjguiComposableUiNode): ?CjguiGeneratedCollectionRows {
    if (let Some(source) <- node.variableHeightListSource()) {
        if (let Some(rows) <- (source as CjguiGeneratedCollectionRows)) {
            return Some(rows)
        }
    }
    for (child in node.children()) {
        if (let Some(rows) <- collectionTransactionRows(child)) { return Some(rows) }
    }
    return None
}

/// Replays the accepted layout facts a real window would publish: 30pt rows in a
/// 60pt viewport (7 rows including the table header).
private func collectionTransactionPublishGeometry(view: CjguiGeneratedCollectionView,
    node: CjguiComposableUiNode): Unit {
    let rows = match (collectionTransactionRows(node)) {
        case Some(value) => value
        case None => throw Exception("accepted collection node has no rows")
    }
    view.listState().updateVariableMaterializedRange(rows, 30, 0, 60, 2)
    view.viewport.stageExtents(210, 60, 0)
    view.viewport.commitStagedExtents()
}

@Test
func holderCommitPublishesAndRetiresCollectionMounts(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    let scope = CjguiComposableUiIdentityScope("holder-mount-region")
    let holder = CjguiGeneratedUiStructureHolder(catalog, rootScope: scope)
    let provider = GeneratedTestProvider()

    let first = ArrayList<CjguiGeneratedUiNodeSpec>()
    first.add(collectionTransactionCollectionSpec("cardA"))
    let firstNode = match (collectionTransactionAcceptNode(holder, provider,
        collectionTransactionRoot(first))) {
        case Some(value) => value
        case None => throw Exception("first scene was not accepted")
    }
    // The scene commit, not a later accepted build, publishes the mount.
    let view = match (collection.acceptedView(scope, "cardA")) {
        case Some(value) => value
        case None => throw Exception("accepted mount missing right after commit")
    }
    @Assert(view.isRetired(), false)
    @Assert(view.incarnation, 1)
    collectionTransactionPublishGeometry(view, firstNode)
    @Assert(view.revealItem("row_4"), true)
    @Assert(view.scrollOffset(), 150)

    // A committed structure that declares the same KEY with another component
    // kind retires the collection mount although the factory is never called.
    let second = ArrayList<CjguiGeneratedUiNodeSpec>()
    second.add(collectionTransactionLabelSpec("cardA"))
    @Assert(collectionTransactionAccept(holder, provider, collectionTransactionRoot(second)), true)
    @Assert(view.isRetired(), true)
    @Assert(collection.acceptedView(scope, "cardA").isNone(), true)
    @Assert(collection.revealItem("row_4", scope, "cardA"), false)
    @Assert(collection.mountCount(), 0)

    // A structure that declares nothing under the key retires it too.
    let third = ArrayList<CjguiGeneratedUiNodeSpec>()
    third.add(collectionTransactionLabelSpec("other"))
    @Assert(collectionTransactionAccept(holder, provider, collectionTransactionRoot(third)), true)
    @Assert(collection.mountCount(), 0)
}

@Test
func holderRollbackKeepsAcceptedCollectionMount(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    let scope = CjguiComposableUiIdentityScope("holder-rollback-region")
    let holder = CjguiGeneratedUiStructureHolder(catalog, rootScope: scope)
    let provider = GeneratedTestProvider()

    let first = ArrayList<CjguiGeneratedUiNodeSpec>()
    first.add(collectionTransactionCollectionSpec("cardA"))
    let firstNode = match (collectionTransactionAcceptNode(holder, provider,
        collectionTransactionRoot(first))) {
        case Some(value) => value
        case None => throw Exception("first scene was not accepted")
    }
    let accepted = collection.acceptedView(scope, "cardA").getOrThrow()
    collectionTransactionPublishGeometry(accepted, firstNode)
    @Assert(accepted.revealItem("row_4"), true)
    @Assert(accepted.scrollOffset(), 150)
    let mountKey = accepted.mountKey

    // A candidate adds a NEW instance and re-declares the surviving one. Its
    // build may prepare views, but the accepted lookup and geometry are the
    // previous accepted facts until the scene commits.
    let candidate = ArrayList<CjguiGeneratedUiNodeSpec>()
    candidate.add(collectionTransactionCollectionSpec("cardA", presentation: "list"))
    candidate.add(collectionTransactionCollectionSpec("list", presentation: "list"))
    @Assert(holder.submit(collectionTransactionRoot(candidate), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(collection.revealItem("row_4", scope, "cardA"), true)
    @Assert(accepted.scrollOffset(), 150)

    holder.rollbackCandidateRefresh()
    // The rejected candidate leaves no staged mount or view state behind.
    @Assert(collection.mountCount(), 1)
    @Assert(collection.acceptedView(scope, "cardA").getOrThrow().mountKey, mountKey)
    @Assert(collection.acceptedView(scope, "cardA").getOrThrow().isRetired(), false)
    @Assert(collection.acceptedView(scope, "list").isNone(), true)
    @Assert(collection.revealItem("row_4", scope, "cardA"), true)
    @Assert(accepted.scrollOffset(), 150)
}

@Test
func holderReAddIsANewAcceptedGeneration(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    let scope = CjguiComposableUiIdentityScope("holder-readd-region")
    let holder = CjguiGeneratedUiStructureHolder(catalog, rootScope: scope)
    let provider = GeneratedTestProvider()

    let first = ArrayList<CjguiGeneratedUiNodeSpec>()
    first.add(collectionTransactionCollectionSpec("cardA"))
    let firstNode = match (collectionTransactionAcceptNode(holder, provider,
        collectionTransactionRoot(first))) {
        case Some(value) => value
        case None => throw Exception("first scene was not accepted")
    }
    let firstView = collection.acceptedView(scope, "cardA").getOrThrow()
    collectionTransactionPublishGeometry(firstView, firstNode)
    @Assert(firstView.revealItem("row_4"), true)
    @Assert(firstView.scrollOffset(), 150)

    // Remove the instance in one accepted structure...
    let removed = ArrayList<CjguiGeneratedUiNodeSpec>()
    removed.add(collectionTransactionLabelSpec("other"))
    @Assert(collectionTransactionAccept(holder, provider, collectionTransactionRoot(removed)), true)
    @Assert(firstView.isRetired(), true)
    @Assert(collection.acceptedView(scope, "cardA").isNone(), true)

    // ...then add it back: the new accepted generation is published at commit.
    let readded = ArrayList<CjguiGeneratedUiNodeSpec>()
    readded.add(collectionTransactionCollectionSpec("cardA"))
    readded.add(collectionTransactionProbeSpec("probe"))
    let readdedNode = match (collectionTransactionAcceptNode(holder, provider,
        collectionTransactionRoot(readded))) {
        case Some(value) => value
        case None => throw Exception("re-added scene was not accepted")
    }
    let second = match (collection.acceptedView(scope, "cardA")) {
        case Some(value) => value
        case None => throw Exception("re-added mount missing right after commit")
    }
    @Assert(second.incarnation, 2)
    @Assert(second.mountKey != firstView.mountKey, true)
    @Assert(second.isRetired(), false)
    collectionTransactionPublishGeometry(second, readdedNode)
    @Assert(second.revealItem("row_4"), true)
    @Assert(second.scrollOffset(), 150)
    @Assert(collection.mountCount(), 1)
}

@Test
func sharedCollectionSourceKeepsTwoHoldersIndependent(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    let scopeA = CjguiComposableUiIdentityScope("holder-region-a")
    let scopeB = CjguiComposableUiIdentityScope("holder-region-b")
    let holderA = CjguiGeneratedUiStructureHolder(catalog, rootScope: scopeA)
    let holderB = CjguiGeneratedUiStructureHolder(catalog, rootScope: scopeB)
    let provider = GeneratedTestProvider()
    let structure = ArrayList<CjguiGeneratedUiNodeSpec>()
    structure.add(collectionTransactionCollectionSpec("cardA"))
    let nodeA = match (collectionTransactionAcceptNode(holderA, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("region A scene was not accepted")
    }
    let nodeB = match (collectionTransactionAcceptNode(holderB, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("region B scene was not accepted")
    }
    let viewA = collection.acceptedView(scopeA, "cardA").getOrThrow()
    let viewB = collection.acceptedView(scopeB, "cardA").getOrThrow()
    @Assert(viewA.mountKey != viewB.mountKey, true)
    collectionTransactionPublishGeometry(viewA, nodeA)
    collectionTransactionPublishGeometry(viewB, nodeB)
    @Assert(viewA.revealItem("row_4"), true)
    @Assert(viewA.scrollOffset(), 150)
    @Assert(viewB.scrollOffset(), 0)
    @Assert(viewB.revealItem("row_2"), true)
    @Assert(viewA.scrollOffset(), 150)

    // Removing the mount in ONE holder must not retire the other region's mount
    // of the SAME registered collection declaration.
    let removed = ArrayList<CjguiGeneratedUiNodeSpec>()
    removed.add(collectionTransactionLabelSpec("other"))
    @Assert(collectionTransactionAccept(holderA, provider, collectionTransactionRoot(removed)), true)
    @Assert(viewA.isRetired(), true)
    @Assert(collection.acceptedView(scopeA, "cardA").isNone(), true)
    @Assert(collection.acceptedView(scopeB, "cardA").getOrThrow().mountKey, viewB.mountKey)
    @Assert(viewB.isRetired(), false)
    @Assert(collection.revealItem("row_4", scopeB, "cardA"), true)
}

/// A1 RED/GREEN counterexample: two independent holders may legitimately use
/// the SAME local root scope (the default is `generated-root`) and the SAME
/// instance key. A path-only accepted index lets B's commit retire A's mount and
/// makes the scope-only lookup ambiguous. Every step below goes through the real
/// holder prepare/commit/rollback/dispose transaction.
@Test
func sameLocalScopeAcrossHoldersKeepsIndependentAcceptedMounts(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    // The local scope name is identical on purpose: independent windows share
    // the generated-root default and must not be forced to invent global names.
    let scope = CjguiComposableUiIdentityScope("generated-root")
    let holderA = CjguiGeneratedUiStructureHolder(catalog, rootScope: scope)
    let holderB = CjguiGeneratedUiStructureHolder(catalog, rootScope: scope)
    let holderAId = holderA.holderIdentity()
    let holderBId = holderB.holderIdentity()
    @Assert(holderAId != holderBId, true)
    let provider = GeneratedTestProvider()

    let structure = ArrayList<CjguiGeneratedUiNodeSpec>()
    structure.add(collectionTransactionCollectionSpec("cardA"))
    let nodeA = match (collectionTransactionAcceptNode(holderA, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("holder A scene was not accepted")
    }
    let viewA = match (collection.acceptedView(scope, "cardA", holderAId)) {
        case Some(value) => value
        case None => throw Exception("holder A accepted mount missing")
    }
    collectionTransactionPublishGeometry(viewA, nodeA)
    @Assert(viewA.revealItem("row_4"), true)
    @Assert(viewA.scrollOffset(), 150)

    // B accepts the SAME scope and instance key. Both holders stay independent:
    // A must not be retired or rebound, and its offset is not B's offset.
    let nodeB = match (collectionTransactionAcceptNode(holderB, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("holder B scene was not accepted")
    }
    @Assert(viewA.isRetired(), false)
    let viewB = match (collection.acceptedView(scope, "cardA", holderBId)) {
        case Some(value) => value
        case None => throw Exception("holder B accepted mount missing")
    }
    @Assert(viewB.isRetired(), false)
    @Assert(viewA.mountKey != viewB.mountKey, true)
    @Assert(viewA.holderIdentity() != viewB.holderIdentity(), true)
    // Scope-only lookup is ambiguous now: it must not pick "the last accepted".
    @Assert(collection.acceptedView(scope, "cardA").isNone(), true)
    collectionTransactionPublishGeometry(viewB, nodeB)
    @Assert(viewB.revealItem("row_2"), true)
    @Assert(viewB.scrollOffset() != viewA.scrollOffset(), true)
    @Assert(viewA.scrollOffset(), 150)

    // A rejected candidate only drops its own staging: B's published mount and
    // A's accepted mount must both survive, and no third mount is published.
    let candidate = ArrayList<CjguiGeneratedUiNodeSpec>()
    candidate.add(collectionTransactionCollectionSpec("cardA"))
    candidate.add(collectionTransactionCollectionSpec("list", presentation: "list"))
    @Assert(holderA.submit(collectionTransactionRoot(candidate), provider).candidateAccepted, true)
    @Assert(holderA.beginCandidateRefresh(), true)
    let _ = holderA.buildRefreshNode(provider)
    holderA.rollbackCandidateRefresh()
    @Assert(viewA.isRetired(), false)
    @Assert(viewB.isRetired(), false)
    @Assert(collection.mountCount(), 2)
    @Assert(collection.acceptedView(scope, "cardA", holderAId).getOrThrow().scrollOffset(), 150)

    // A compatible reorder keeps A's accepted handle (adopt) without touching B.
    let reordered = ArrayList<CjguiGeneratedUiNodeSpec>()
    reordered.add(collectionTransactionProbeSpec("probe"))
    reordered.add(collectionTransactionCollectionSpec("cardA"))
    @Assert(collectionTransactionAccept(holderA, provider, collectionTransactionRoot(reordered)), true)
    let adoptedA = match (collection.acceptedView(scope, "cardA", holderAId)) {
        case Some(value) => value
        case None => throw Exception("adopted A mount missing")
    }
    @Assert(adoptedA.mountKey, viewA.mountKey)
    @Assert(adoptedA.scrollOffset(), 150)
    @Assert(viewB.isRetired(), false)

    // Disposing B releases only B's mount. A continues and becomes the unique
    // scope-only answer again.
    holderB.disposeViewState()
    @Assert(viewB.isRetired(), true)
    @Assert(collection.acceptedView(scope, "cardA", holderBId).isNone(), true)
    @Assert(viewA.isRetired(), false)
    @Assert(collection.acceptedView(scope, "cardA").getOrThrow().mountKey, viewA.mountKey)
    @Assert(collection.revealItem("row_4", scope, "cardA", holderAId), true)
    @Assert(viewA.scrollOffset(), 150)

    // Re-adding in B produces a NEW accepted generation, not the disposed one.
    let readded = match (collectionTransactionAcceptNode(holderB, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("re-added B scene was not accepted")
    }
    let viewB2 = match (collection.acceptedView(scope, "cardA", holderBId)) {
        case Some(value) => value
        case None => throw Exception("re-added B mount missing")
    }
    // dispose does not change the accepted binding coordinates, so the new
    // generation reuses the same (holder, path, incarnation) key; it is a NEW
    // object and the disposed object must no longer be the accepted mount.
    @Assert(viewB2.mountKey, viewB.mountKey)
    @Assert(refEq(viewB2, viewB), false)
    @Assert(viewB2.isRetired(), false)
    @Assert(collection.isAcceptedMount(viewB), false)
    @Assert(collection.isAcceptedMount(viewB2), true)
    @Assert(collection.acceptedView(scope, "cardA").isNone(), true)
    collectionTransactionPublishGeometry(viewB2, readded)
    @Assert(viewB2.revealItem("row_2"), true)
    @Assert(viewA.scrollOffset(), 150)

    // B removing its LAST instance retires only B's new generation; A survives
    // and the retired/disposed handles can no longer operate.
    let removed = ArrayList<CjguiGeneratedUiNodeSpec>()
    removed.add(collectionTransactionLabelSpec("other"))
    @Assert(collectionTransactionAccept(holderB, provider, collectionTransactionRoot(removed)), true)
    @Assert(viewB2.isRetired(), true)
    @Assert(collection.revealItem("row_2", scope, "cardA", holderBId), false)
    @Assert(collection.isAcceptedMount(viewB2), false)
    @Assert(collection.isAcceptedMount(viewA), true)

    // Re-adding after a REAL removal is a new incarnation/key, unlike the
    // dispose/re-add above. The retired generation cannot operate the new one.
    let again = match (collectionTransactionAcceptNode(holderB, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("second re-added B scene was not accepted")
    }
    let viewB3 = match (collection.acceptedView(scope, "cardA", holderBId)) {
        case Some(value) => value
        case None => throw Exception("second re-added B mount missing")
    }
    @Assert(viewB3.mountKey != viewB2.mountKey, true)
    @Assert(collection.isAcceptedMount(viewB2), false)
    @Assert(collection.isAcceptedMount(viewB3), true)
    @Assert(refEq(viewB3, viewB2), false)
    collectionTransactionPublishGeometry(viewB3, again)
    @Assert(viewB3.revealItem("row_2"), true)
    @Assert(viewB2.revealItem("row_4"), false)
    @Assert(viewA.revealItem("row_4"), true)
    @Assert(viewA.scrollOffset(), 150)
}

/// B counterexample: the old keyboard helper only matched the handwritten
/// `collection.viewport`; a generated mount owns a DIFFERENT viewport object, so
/// its real key event was refused. The accepted-mount overload must navigate the
/// mount whose viewport the event carries and reveal only that mount.
@Test
func generatedCollectionKeyboardUsesOnlyTheEventMount(): Unit {
    let collection = mountableCollection()
    let probe = CollectionTransactionProbeFactory()
    let catalog = collectionTransactionCatalog(collection, probe)
    let scopeA = CjguiComposableUiIdentityScope("keyboard-region-a")
    let scopeB = CjguiComposableUiIdentityScope("keyboard-region-b")
    let holderA = CjguiGeneratedUiStructureHolder(catalog, rootScope: scopeA)
    let holderB = CjguiGeneratedUiStructureHolder(catalog, rootScope: scopeB)
    let provider = GeneratedTestProvider()
    let structure = ArrayList<CjguiGeneratedUiNodeSpec>()
    structure.add(collectionTransactionCollectionSpec("cardA"))
    let nodeA = match (collectionTransactionAcceptNode(holderA, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("region A scene was not accepted")
    }
    let nodeB = match (collectionTransactionAcceptNode(holderB, provider,
        collectionTransactionRoot(structure))) {
        case Some(value) => value
        case None => throw Exception("region B scene was not accepted")
    }
    let viewA = collection.acceptedView(scopeA, "cardA").getOrThrow()
    let viewB = collection.acceptedView(scopeB, "cardA").getOrThrow()
    collectionTransactionPublishGeometry(viewA, nodeA)
    collectionTransactionPublishGeometry(viewB, nodeB)
    let bounds = CjguiComposableUiRect(0, 0, 200, 60)
    func scrollEvent(view: CjguiGeneratedCollectionView, text: String): CjguiComposableUiEvent {
        let scroll = CjguiComposableUiNode(-1, "keyboard-scroll-${view.mountKey}",
            CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "", -1, CjguiComposableUiStyle(),
            scrollViewport: Some(view.viewport))
        let layout = CjguiComposableUiLayoutNode(scroll, bounds, bounds)
        return CjguiComposableUiEvent(layout, 35, text, 0, 0, 1)
    }

    // A generated mount accepts the match and only ITS viewport moves.
    let beforeB = viewB.scrollOffset()
    let result = cjguiNavigateGeneratedCollection(collection, viewA, scrollEvent(viewA, "down"), None)
    @Assert(result.isHandled, true)
    @Assert(result.didChange, true)
    @Assert(viewB.scrollOffset(), beforeB)

    // The event carries A's viewport, so B's accepted handle must refuse it
    // instead of acting as "the last built"/any generated mount.
    let beforeA = viewA.scrollOffset()
    let foreignNav = cjguiNavigateGeneratedCollection(collection, viewB, scrollEvent(viewA, "down"), None)
    @Assert(foreignNav.isHandled, false)
    @Assert(viewA.scrollOffset(), beforeA)

    // A retired generation is refused even when it still carries its old
    // viewport object; no selection write happens for the stale event.
    holderA.disposeViewState()
    @Assert(viewA.isRetired(), true)
    let focusBefore = collection.selection.focus()
    let stale = cjguiNavigateGeneratedCollection(collection, viewA, scrollEvent(viewA, "down"), None)
    @Assert(stale.isHandled, false)
    @Assert(collection.selection.focus(), focusBefore)
}
