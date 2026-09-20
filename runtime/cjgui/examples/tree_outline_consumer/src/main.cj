// Independent public consumer of the experimental generic tree view: a
// three-level knowledge catalog (领域 → 主题 → 条目) with a different data
// shape, row presentation and selection handling from the rule window.
// UI-only: it depends on the public cjgui package alone, keeps its own
// in-memory catalog, and never touches files or other applications.
package cjgui_ui_only_starter

import cjgui.*
import std.collection.*
import std.env.*
import std.time.*

/// The tree list is one virtual-list scroll node; native delivers keyboard
/// navigation (35) and wheel scrolling (30) on it.
let CJGUI_CATALOG_LIST_NODE_ID: Int64 = 27
/// One identity scope per projected row, keyed by the row's stable key.
let CJGUI_CATALOG_ROW_IDENTITY_SCOPE: CjguiComposableUiIdentityScope =
    CjguiComposableUiIdentityScope("catalog-rows")

public class CatalogSource <: CjguiComposableUiTreeDataSource {
    public let domains: ArrayList<String>
    public let topicsPerDomain: Int64
    public let entriesPerTopic: Int64

    public init(domains: ArrayList<String>, topicsPerDomain: Int64, entriesPerTopic: Int64) {
        this.domains = domains
        this.topicsPerDomain = topicsPerDomain
        this.entriesPerTopic = entriesPerTopic
    }

    static func domainKey(index: Int64): String {
        return "domain-${index}"
    }

    static func topicKey(domainIndex: Int64, topicIndex: Int64): String {
        return "domain-${domainIndex}-topic-${topicIndex}"
    }

    static func entryKey(domainIndex: Int64, topicIndex: Int64, entryIndex: Int64): String {
        return "domain-${domainIndex}-topic-${topicIndex}-entry-${entryIndex}"
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return domains.size }
        let numbers = numericSegments(parentKey)
        if (numbers.size == 1) { return topicsPerDomain }
        if (numbers.size == 2) { return entriesPerTopic }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        let numbers = numericSegments(parentKey)
        if (numbers.size == 0) {
            let name = domains[index]
            return CjguiComposableUiTreeNode(
                domainKey(index), name, 100 + index, true, selectable: false)
        }
        if (numbers.size == 1) {
            let domainIndex = numbers[0]
            return CjguiComposableUiTreeNode(
                topicKey(domainIndex, index), "主题 ${domainIndex}.${index}",
                200 + domainIndex * 10 + index, true, selectable: false)
        }
        if (numbers.size == 2) {
            let domainIndex = numbers[0]
            let topicIndex = numbers[1]
            return CjguiComposableUiTreeNode(
                entryKey(domainIndex, topicIndex, index),
                "条目 ${domainIndex}.${topicIndex}.${index}",
                300 + domainIndex * 100 + topicIndex * 10 + index, false, selectable: true)
        }
        return CjguiComposableUiTreeNode("missing", "missing", -1, false, selectable: false)
    }

    // "domain-0-topic-1-entry-2" -> [0, 1, 2]
    func numericSegments(key: String): ArrayList<Int64> {
        let result = ArrayList<Int64>()
        if (!key.startsWith("domain-")) { return result }
        var value: Int64 = 0
        var hasDigits = false
        let chars = key.toArray()
        var index: Int64 = 0
        while (index < Int64(chars.size)) {
            let byte = chars[index]
            if (byte == 45) {  // '-'
                if (hasDigits) { result.add(value) }
                value = 0
                hasDigits = false
            } else if (byte >= 48 && byte <= 57) {
                value = value * 10 + Int64(byte - 48)
                hasDigits = true
            }
            index += 1
        }
        if (hasDigits) { result.add(value) }
        return result
    }
}

public class CatalogController <: CjguiComposableUiController {
    private let source: CatalogSource
    private let projection: CjguiComposableUiTreeProjection
    private let selection: CjguiComposableUiTreeSelection
    private let listState: CjguiComposableUiVirtualListState
    // The list source is kept so keyboard navigation can reveal an off-screen
    // focus target through the same virtual list the scene renders.
    private var activeListSource: ?CjguiComposableUiTreeListSource = None
    // Attached by the application so a model-side focus move can keep the
    // native focus on the row the tree model just focused.
    private var attachedWindow: ?CjguiComposableUiWindow = None
    private var revision: Int64 = 1

    public init(source: CatalogSource) {
        this.source = source
        this.projection = CjguiComposableUiTreeProjection(source)
        this.selection = CjguiComposableUiTreeSelection(this.projection)
        this.listState = CjguiComposableUiVirtualListState()
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    public func buildUi(): CjguiComposableUiNode {
        let _ = syncWithData()
        let section = cjguiComposableVertical(20, "catalog-tree-section",
            CjguiComposableUiStyle(padding: 10, gap: 6,
                background: CjguiComposableUiColor(0.06, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.30, 0.50, 0.80, 1.0)))
        section.add(cjguiComposableText(21, "catalog-tree-title", "知识目录（树形多选）",
            CjguiComposableUiStyle(fontSize: 15.0)))

        let actions = cjguiComposableHorizontal(22, "catalog-tree-actions",
            CjguiComposableUiStyle(gap: 6))
        actions.add(cjguiComposableButton(23, "catalog-expand-all", "展开全部", "CATALOG_EXPAND_ALL", 1,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(24, "catalog-collapse-all", "收起全部", "CATALOG_COLLAPSE_ALL", 2,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(25, "catalog-select-all", "全选条目", "CATALOG_SELECT_ALL", 3,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(26, "catalog-clear", "清空多选", "CATALOG_CLEAR", 4,
            CjguiComposableUiStyle(fixedHeight: 28)))
        section.add(actions)

        // Only viewport + overscan rows materialize: the expanded projection
        // is exposed through the existing fixed-row virtual list engine, and
        // each row builder receives the real projected row with its stable key.
        // Row declarations carry a scoped identity derived from that key, so
        // the window's identity registry allocates their node ids instead of a
        // hand-reserved numeric block per consumer.
        section.add(cjguiComposableVirtualList(CJGUI_CATALOG_LIST_NODE_ID, "catalog-tree-list", 28,
            catalogListSource(), listState, 30, 4, 6,
            CjguiComposableUiStyle(minHeight: 220, maxHeight: 320, background:
                CjguiComposableUiColor(0.04, 0.07, 0.11, 1.0))))

        let status = cjguiComposableText(63, "catalog-status",
            "多选 ${selection.selectedCount()} 条 · 可见 ${projection.rowCount()} 行",
            CjguiComposableUiStyle(fontSize: 11.0))
        section.add(status)
        return section
    }

    /// Builds (and remembers) the tree list source. Row declarations carry a
    /// scoped identity derived from the row's stable key, so the window's
    /// identity registry allocates their node ids: there is no hand-reserved
    /// numeric block per consumer, two rows can never collide, and the same key
    /// keeps its identity across reorder, re-parenting and re-materialization.
    private func catalogListSource(): CjguiComposableUiTreeListSource {
        let listSource = CjguiComposableUiTreeListSource(projection, selection,
            { row, isSelected, isFocused =>
                let rowScope = CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child(row.key)
                var indentText = ""
                var depthIndex: Int64 = 0
                while (depthIndex < row.depth) {
                    indentText += "      "
                    depthIndex += 1
                }
                let line = cjguiComposableHorizontal(0, "catalog-vrow-${row.key}",
                    CjguiComposableUiStyle(gap: 4), identity: Some(rowScope.local("line")))
                line.add(cjguiComposableText(0, "catalog-vindent-${row.key}", indentText,
                    CjguiComposableUiStyle(fontSize: 11.0), identity: Some(rowScope.local("indent"))))
                if (row.isGroup) {
                    let marker = if (row.expanded) { "▾" } else { "▸" }
                    line.add(cjguiComposableButton(0, "catalog-vgroup-${row.key}",
                        "${marker} ${row.label}", "CATALOG_GROUP_TOGGLE", row.resourceId,
                        CjguiComposableUiStyle(fixedHeight: 26), identity: Some(rowScope.local("group"))))
                } else {
                    let mark = if (isSelected) { "◉" } else { "○" }
                    line.add(cjguiComposableButton(0, "catalog-vleaf-${row.key}",
                        "${mark} ${row.label}", "CATALOG_LEAF_TOGGLE", row.resourceId,
                        CjguiComposableUiStyle(fixedHeight: 26), identity: Some(rowScope.local("leaf"))))
                }
                line
            })
        activeListSource = Some(listSource)
        return listSource
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // Keyboard navigation / scroll inside the tree focus scope. Native
        // delivers the command on the virtual-list scroll node (27) with the
        // key event's own modifiers, so Shift extends a range; the tree model
        // owns visible order, anchor and expand/collapse, and the list state
        // materializes an off-screen target instead of leaving it unreachable.
        if (event.eventKind == 35 && event.node.nodeId == CJGUI_CATALOG_LIST_NODE_ID) {
            let extendRange = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            let result = selection.navigate(event.text, extendRange)
            if (!result.didChange) {
                return CjguiComposableUiDispatchResult(false)
            }
            if (let Some(listSource) <- activeListSource) {
                let _ = listState.revealKey(listSource, result.focus)
            }
            // Keep native focus, tree focus and the materialized row consistent:
            // the row declaration's scoped identity is what the window resolves.
            if (let Some(window) <- attachedWindow) {
                let index = projection.indexForKey(result.focus)
                if (index >= 0) {
                    let row = projection.rowAt(index)
                    let localKey = if (row.isGroup) { "group" } else { "leaf" }
                    let _ = window.focusScopedNode(CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child(result.focus), localKey)
                }
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && event.node.nodeId == CJGUI_CATALOG_LIST_NODE_ID) {
            let before = listState.scrollOffset()
            listState.scrollByViewport(event.text)
            if (listState.scrollOffset() == before) {
                return CjguiComposableUiDispatchResult(false)
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_GROUP_TOGGLE") {
            let key = keyForResource(event.node.resourceId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let changed = projection.toggleExpand(key)
            if (changed) {
                selection.ensureFocusVisible()
                revision += 1
            }
            return CjguiComposableUiDispatchResult(changed)
        }
        if (event.node.actionName == "CATALOG_LEAF_TOGGLE") {
            let key = keyForResource(event.node.resourceId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let command = (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0
            let shift = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            selection.click(key, command, shift)
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_EXPAND_ALL") {
            expandAll()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_COLLAPSE_ALL") {
            collapseAll()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_SELECT_ALL") {
            selection.selectAllVisible()
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_CLEAR") {
            clearSelection()
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

    public func selectedCount(): Int64 {
        return selection.selectedCount()
    }

    /// Exact public readback of the shared tree selection state. An external
    /// consumer (and the export chain) asserts keys, focus and anchor instead of
    /// a count, so a wrong row cannot hide behind the same total.
    public func selectedKeys(): ArrayList<String> {
        return selection.snapshot().keys
    }

    public func focusKey(): String {
        return selection.focus()
    }

    public func anchorKey(): String {
        return selection.anchor()
    }

    public func clearSelection(): Unit {
        selection.clearSelection()
        revision += 1
    }

    public func visibleRowCount(): Int64 {
        return projection.rowCount()
    }

    // Bulk expand/collapse: one expanded-set update and one projection
    // rebuild, so a 10k-node tree is never rebuilt once per group.
    public func expandAll(): Unit {
        if (projection.setExpandedBatch(projection.groupKeys(), true)) {
            selection.ensureFocusVisible()
            revision += 1
        }
    }

    public func collapseAll(): Unit {
        if (projection.setExpandedBatch(projection.groupKeys(), false)) {
            selection.ensureFocusVisible()
            revision += 1
        }
    }

    // Resolves the stable key of a projected row by its application resource
    // id. The id is only a lookup key into the accepted projection; the
    // selection/toggle always uses the real stable key.
    private func keyForResource(resourceId: Int64): String {
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

    private func syncWithData(): Unit {
        let _ = projection.rebuild()
    }
}

main(): Int64 {
    let domains = ArrayList<String>(["绘制", "布局", "输入"])
    let source = CatalogSource(domains, 3, 3)
    let controller = CatalogController(source)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 知识目录", 640u32, 520u32)
    )
    controller.attachWindow(host.window())
    if (!host.start()) { return 2 }
    println("TREE_OUTLINE_CONSUMER_READY rows=${controller.visibleRowCount()}")
    getStdOut().flush()
    // Pump the public application loop until the window closes; this is the
    // same host the handwritten examples use, so the tree rows, expansion and
    // multi-selection all re-render through the ordinary scene path.
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    return 0
}
