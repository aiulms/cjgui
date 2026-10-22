package cjgui

import std.collection.*

/// Experimental compiled collection adapter. The application registers ONE real
/// source/table/selection declaration; a description can choose only its key and
/// list/table presentation. Data, callbacks and permission scopes never arrive
/// in the description. Register distinct, scoped sources for simultaneous views.
///
/// The existing table owns filtering/sorting, selection remains caller-owned,
/// and builds perform no owner or view-state writes. Each build gets a private
/// measurement state; the ordinary scroll viewport stages/accepts geometry.
public class CjguiGeneratedUiCollection <: CjguiCompositeComponentFactory {
    public let key: String
    public let kind: String
    public let table: CjguiComposableUiTableSource
    public let selection: CjguiComposableUiCollectionSelection
    public let viewport: CjguiComposableUiScrollViewport
    private let listSource: CjguiComposableUiVariableHeightListSource
    // The rows wrapper the CURRENT accepted build materialized (the same object
    // the viewport scrolls with), so a reveal addresses exactly that source.
    private var lastRowsSource: ?CjguiGeneratedCollectionRows = None

    public init(key: String, kind: String, listSource: CjguiComposableUiVariableHeightListSource,
        table: CjguiComposableUiTableSource, selection: CjguiComposableUiCollectionSelection,
        viewport!: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()) {
        this.key = key
        this.kind = kind
        this.listSource = listSource
        this.table = table
        this.selection = selection
        this.viewport = viewport
    }

    /// The same compiled declaration used by handwritten buildNode. Explicit
    /// collection enum is discoverable in the existing catalog; no new RPC.
    public func register(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
        if (key.isEmpty() || key.size > 80 || kind.isEmpty()) {
            return false
        }
        let properties = CjguiGeneratedUiPresentation.leafStyleProperties()
        properties.add(
            CjguiGeneratedUiPropertySpec("collection", "STRING", required: true, maxLength: 80,
                values: ArrayList<String>([key]),
                semantics: "application-registered collection reference; data and actions stay application-owned",
                stability: "experimental", backendSupport: "macOS verified; other backends not_run"))
        properties.add(
            CjguiGeneratedUiPropertySpec("presentation", "STRING", required: true,
                values: ArrayList<String>(["list", "table"]),
                semantics: "view projection only; preserves source, selection and owner draft"))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(kind, properties,
                ArrayList<CjguiCompositeElementSpec>(
                    [CjguiCompositeElementSpec("viewport", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
                        CjguiCompositeElementSpec("content", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "viewport")]),
                expandedNodeLimit: 2, expandedDepthLimit: 2), this)
    }

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("viewport").getOrThrow()
        let content = context.element("content").getOrThrow()
        return buildNode(root.nodeId, root.semanticId, content.nodeId, content.semanticId,
            context.property("presentation"), context.resolvedStyle)
    }

    /// Handwritten and generated consumers call this same projection. The table
    /// header is a normal first virtual row (scrolls with content in this slice).
    /// No row node is created until the existing bounded materializer asks for it.
    public func buildNode(nodeId: Int64, semanticId: String, contentId: Int64, contentSemanticId: String,
        presentation: String, style: CjguiComposableUiStyle): CjguiComposableUiNode {
        let rows = CjguiGeneratedCollectionRows(key, listSource, table, selection, presentation == "table")
        this.lastRowsSource = rows
        let state = CjguiComposableUiVirtualListState()
        state.setSelectedKey("data:${selection.focus()}")
        state.setFocusedKey("data:${selection.focus()}")
        let root = CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
            style, scrollOffset: viewport.offset(), scrollViewport: Some(viewport), variableHeightListSource: Some(rows),
            virtualListState: Some(state), virtualListContentNodeId: contentId,
            virtualListRowHeight: table.style().rowHeight, virtualListRowGap: 0, virtualListOverscan: 2,
            semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_SCROLL_AREA)
        // Reuse the materializer's existing content-template seam. Both static
        // identities are allocated/audited by the ordinary composite holder;
        // row identities are resolved by the ordinary virtual-list registry.
        root.add(cjguiComposableVertical(contentId, contentSemanticId, CjguiComposableUiStyle()))
        return root
    }

    public func order(): CjguiComposableUiCollectionOrder {
        return CjguiComposableUiFlatCollectionOrder(table, {item => !item.key.isEmpty()})
    }

    /// Scrolls the collection's OWN viewport to one business key. This is the
    /// public "select an object and bring it into view" entry a list/detail
    /// editor needs; it changes only the viewport position, never the selection,
    /// the data or the owner.
    public func revealItem(key: String): Bool {
        if (key.isEmpty()) {
            return false
        }
        // The viewport's requested offset is the scroll channel the accepted
        // build consumes; a virtual list key maps to its row index through the
        // SAME wrapper the view materializes from.
        let rows = match (lastRowsSource) {
            case Some(value) => value
            case None => CjguiGeneratedCollectionRows(this.key, listSource, table, selection, false)
        }
        let index = rows.indexForKey("data:${key}")
        if (index < 0) {
            return false
        }
        let rowHeight = table.style().rowHeight
        let offset = if (rowHeight > 0) { index * rowHeight } else { index }
        return viewport.requestOffset(offset)
    }
}

private class CjguiGeneratedCollectionRows <: CjguiComposableUiVariableHeightListSource {
    private let headerKey: String
    private let list: CjguiComposableUiVariableHeightListSource
    private let table: CjguiComposableUiTableSource
    private let selection: CjguiComposableUiCollectionSelection
    private let showTable: Bool
    init(key: String, list: CjguiComposableUiVariableHeightListSource, table: CjguiComposableUiTableSource,
        selection: CjguiComposableUiCollectionSelection, showTable: Bool) {
        // Prefix a length-framed key, impossible to equal an unchanged data key
        // in this wrapper: all data keys below are framed in the other namespace.
        this.headerKey = "header:${key.size}:${key}"
        this.list = list
        this.table = table
        this.selection = selection
        this.showTable = showTable
    }
    public func itemCount(): Int64 {
        return table.itemCount() + if (showTable) {
            1
        } else {
            0
        }
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= itemCount()) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        if (showTable && index == 0) {
            return CjguiComposableUiVariableHeightListItem(headerKey, -1, "", table.layoutRevision(),
                estimatedHeight: table.style().headerHeight)
        }
        let item = table.itemAt(index - if (showTable) {
            1
        } else {
            0
        })
        return CjguiComposableUiVariableHeightListItem("data:${item.key}", item.resourceId, item.title,
            item.layoutRevision, estimatedHeight: item.estimatedHeight)
    }
    public func indexForKey(key: String): Int64 {
        if (showTable && key == headerKey) {
            return 0
        }
        if (!key.startsWith("data:")) {
            return -1
        }
        let index = table.indexForKey(key[5..])
        return if (index >= 0) {
            index + if (showTable) {
                1
            } else {
                0
            }
        } else {
            -1
        }
    }
    public func measurementGeneration(): Int64 {
        return table.measurementGeneration()
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        if (showTable && item.key == headerKey) {
            return table.buildHeader()
        }
        let index = table.indexForKey(item.key[5..])
        let original = table.itemAt(index)
        let selected = selection.isSelected(original.key)
        let focused = selection.focus() == original.key
        return if (showTable) {
            table.buildRow(original, selected, focused)
        } else {
            list.buildRow(original, selected, focused)
        }
    }
}
