// Grouped tree view for the rule-set window: the first consumer of the
// experimental generic tree projection/multi-selection. Groups are derived
// from the existing enabled field (no new persistence); leaves carry the
// original record ids, and batch enable goes through the existing
// BATCH_SET_ENABLED owner entry with its authorization/CAS/draft semantics.
package cjgui_rule_set_window_app

import cjgui.*

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*

// A projected row carries two identities at once: a record leaf keeps the real
// record id (business identity), while a group row is view-only. Group ids and
// record ids therefore must stay in disjoint numeric ranges. That invariant is
// still asserted by the panel and by the legacy row-identity regression; the
// declaration node ids themselves now come from the window's identity
// registry through a scope built from each row's stable key, so no hand-written
// numeric block has to be reserved per row kind (see the row builder).
let CJGUI_RULE_SET_TREE_GROUP_RESOURCE_BASE: Int64 = 900000
// Legacy fixture ids from the pre-registry scheme: kept so the historical
// collision regression can still name the exact block it guarded, but no
// production row declaration uses them any more.
let CJGUI_RULE_SET_TREE_GROUP_ROW_NODE_BASE: Int64 = 6100000
let CJGUI_RULE_SET_TREE_LEAF_ROW_NODE_BASE: Int64 = 6200000
let CJGUI_RULE_SET_TREE_ROW_NODE_STRIDE: Int64 = 4
let CJGUI_RULE_SET_TREE_LIST_NODE_ID: Int64 = 700007
/// One scope per projected row, keyed by the row's stable key: the registry
/// allocates the row's node ids and keeps them across reorder, re-parenting,
/// unmount and re-entry.
let CJGUI_RULE_SET_TREE_ROW_IDENTITY_SCOPE: CjguiComposableUiIdentityScope =
    CjguiComposableUiIdentityScope("rule-tree-rows")

/// Grouped data source over one business snapshot. The owner refreshes it
/// exactly once per observed domain version, so a projection rebuild never
/// copies the domain snapshot per row; child lookups are index reads over the
/// already-derived grouping. `logicalKeys()` is the full logical existence set
/// (records plus the two groups), independent of what is currently expanded.
public class CjguiRuleSetTreeSource <: CjguiComposableUiTreeDataSource {
    private let domain: CjguiRuleSetEditingDomain
    private var enabledKeys: ArrayList<String>
    private var disabledKeys: ArrayList<String>
    private var labelByKey: HashMap<String, String>
    private var resourceIdByKey: HashMap<String, Int64>
    private var snapshotVersionValue: Int64

    public init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
        this.enabledKeys = ArrayList<String>()
        this.disabledKeys = ArrayList<String>()
        this.labelByKey = HashMap<String, String>()
        this.resourceIdByKey = HashMap<String, Int64>()
        this.snapshotVersionValue = -1
        refresh()
    }

    public func snapshotVersion(): Int64 {
        return snapshotVersionValue
    }

    /// Rebuilds the grouping index from the current domain snapshot. Called by
    /// the panel once per observed business version, never per child lookup.
    public func refresh(): Unit {
        let snapshot = domain.snapshot()
        snapshotVersionValue = snapshot.version
        let enabled = ArrayList<String>()
        let disabled = ArrayList<String>()
        let labels = HashMap<String, String>()
        let resources = HashMap<String, Int64>()
        for (record in snapshot.records) {
            let key = "record-${record.id}"
            labels.add(key, record.label)
            resources.add(key, record.id)
            if (record.enabled) {
                enabled.add(key)
            } else {
                disabled.add(key)
            }
        }
        this.enabledKeys = enabled
        this.disabledKeys = disabled
        this.labelByKey = labels
        this.resourceIdByKey = resources
    }

    /// Every key that exists in the business data, whether or not its group is
    /// currently expanded. Used to prune the selection against logic instead
    /// of against the visible projection.
    public func logicalKeys(): ArrayList<String> {
        let keys = ArrayList<String>()
        keys.add("group-enabled")
        keys.add("group-disabled")
        for (key in enabledKeys) {
            keys.add(key)
        }
        for (key in disabledKeys) {
            keys.add(key)
        }
        return keys
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return 2 }
        if (parentKey == "group-enabled") { return enabledKeys.size }
        if (parentKey == "group-disabled") { return disabledKeys.size }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        if (parentKey.isEmpty()) {
            if (index == 0) {
                return CjguiComposableUiTreeNode(
                    "group-enabled", "已启用", CJGUI_RULE_SET_TREE_GROUP_RESOURCE_BASE + 1, true, selectable: false)
            }
            if (index == 1) {
                return CjguiComposableUiTreeNode(
                    "group-disabled", "未启用", CJGUI_RULE_SET_TREE_GROUP_RESOURCE_BASE + 2, true, selectable: false)
            }
            return CjguiComposableUiTreeNode("missing", "missing", -1, false, selectable: false)
        }
        let group = if (parentKey == "group-enabled") {
            enabledKeys
        } else if (parentKey == "group-disabled") {
            disabledKeys
        } else {
            ArrayList<String>()
        }
        if (index < 0 || index >= group.size) {
            return CjguiComposableUiTreeNode("missing", "missing", -1, false, selectable: false)
        }
        let key = group[index]
        let label = if (let Some(value) <- labelByKey.get(key)) { value } else { key }
        let resourceId = if (let Some(value) <- resourceIdByKey.get(key)) { value } else { -1 }
        return CjguiComposableUiTreeNode(key, label, resourceId, false, selectable: true)
    }
}

/// Owns the tree projection/selection for the rule window and renders the
/// grouped section. Multi-select feeds the existing BATCH_SET_ENABLED owner
/// entry; the panel never implements business transactions itself.
public class CjguiRuleSetTreePanel <: CjguiSharedOperationTreeSelectionProvider {
    private let domain: CjguiRuleSetEditingDomain
    private let source: CjguiRuleSetTreeSource
    public let projection: CjguiComposableUiTreeProjection
    public let selection: CjguiComposableUiTreeSelection
    public let listState: CjguiComposableUiVirtualListState
    private var observedDataVersion: Int64
    private var viewRevisionValue: Int64
    private var lastBatchStatus: String
    private var selectionVersionValue: Int64
    // The list source of the most recent build; navigation uses it only to
    // reveal (materialize) the new focus row.
    private var activeListSource: ?CjguiComposableUiTreeListSource

    public init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
        this.source = CjguiRuleSetTreeSource(domain)
        this.projection = CjguiComposableUiTreeProjection(source)
        this.selection = CjguiComposableUiTreeSelection(projection)
        this.listState = CjguiComposableUiVirtualListState()
        this.observedDataVersion = -1
        this.viewRevisionValue = 0
        this.lastBatchStatus = ""
        this.selectionVersionValue = 0
        this.activeListSource = None
    }

    public func selectionVersion(): Int64 {
        return selectionVersionValue
    }

    /// Renderer-visible revision of this panel's own view state (expansion,
    /// highlight, status). The window's scene version includes it so an
    /// external selection/expansion update actually repaints the rows.
    public func viewRevision(): Int64 {
        return viewRevisionValue
    }

    public func selectedRecordIds(): ArrayList<Int64> {
        let ids = ArrayList<Int64>()
        for (key in selection.selectedKeysInOrder()) {
            if (key.startsWith("record-")) {
                ids.add(parseIntSuffix(key))
            }
        }
        return ids
    }

    public func clearSelection(): Unit {
        selection.clearSelection()
        selectionVersionValue += 1
    }

    /// Syncs the projection with the domain data version and prunes selection
    /// entries whose records vanished. Returns true when the projection
    /// changed and the section must be rebuilt.
    ///
    /// Existence is judged against the whole logical record set, never against
    /// the currently expanded rows: a collapse followed by any business update
    /// must not delete a legal hidden selection. The grouping index is rebuilt
    /// from exactly one domain snapshot per observed version.
    public func syncWithData(): Bool {
        let version = domain.snapshot().version
        if (version != observedDataVersion) {
            observedDataVersion = version
            source.refresh()
            projection.invalidate()
            selection.prune(source.logicalKeys())
            return true
        }
        return false
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "TREE_GROUP_TOGGLE") {
            let groupKey = keyForResource(event.node.resourceId)
            if (groupKey.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let changed = projection.toggleExpand(groupKey)
            if (changed) {
                // A focus hidden by a collapse falls back to the visible
                // ancestor instead of pointing at an invisible row.
                selection.ensureFocusVisible()
            }
            return CjguiComposableUiDispatchResult(changed)
        }
        if (event.node.actionName == "TREE_ROW_TOGGLE") {
            let key = keyForResource(event.node.resourceId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            // Real desktop modifiers: Command toggles one row into/out of the
            // selection, Shift extends from the anchor along the visible order,
            // a plain click replaces the selection.
            let command = (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0
            let shift = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            selection.click(key, command, shift)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "TREE_SELECT_ALL") {
            selection.selectAllVisible()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "TREE_BATCH_ENABLE") {
            return batchEnable(true)
        }
        if (event.node.actionName == "TREE_BATCH_DISABLE") {
            return batchEnable(false)
        }
        if (event.node.actionName == "TREE_CLEAR") {
            clearSelection()
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    private func batchEnable(enabled: Bool): CjguiComposableUiDispatchResult {
        let keys = selection.selectedKeysInOrder()
        if (keys.size == 0) {
            lastBatchStatus = "批量：未选择记录"
            return CjguiComposableUiDispatchResult(false)
        }
        let ids = selectedRecordIds()
        let version = domain.snapshot().version
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("enabled", CjguiSharedOperationValue.boolean(enabled)),
            CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string("tree-batch-${version}-${ids.size}"))
        ])
        let invocation = CjguiSharedOperationActionInvocation(
            "BATCH_SET_ENABLED", version, ids, arguments)
        let result = domain.executeFromHuman(invocation)
        lastBatchStatus = if (result.applied) {
            "批量已应用：${ids.size} 条 → v${result.versionAfter}"
        } else {
            "批量被拒：${result.reason}"
        }
        return CjguiComposableUiDispatchResult(result.applied)
    }

    // Resolves a projected row's stable key by its application resource id;
    // the id is only a lookup into the accepted projection, never a key guess.
    public func keyForResource(resourceId: Int64): String {
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

    public func batchStatus(): String {
        return lastBatchStatus
    }

    // --- shared selection provider (window/external use the same handlers) --

    public func selectionPayload(): String {
        let snapshot = selection.snapshot()
        let builder = StringBuilder()
        builder.append("SELECTION_VERSION ${snapshot.selectionVersion}\n")
        builder.append("PROJECTION_VERSION ${snapshot.projectionVersion}\n")
        builder.append("FOCUS ${if (snapshot.focus.size > 0) { snapshot.focus } else { "none" }}\n")
        builder.append("ANCHOR ${if (snapshot.anchor.size > 0) { snapshot.anchor } else { "none" }}\n")
        for (key in snapshot.keys) {
            builder.append("KEY ${key}\n")
        }
        builder.append("END")
        return builder.toString()
    }

    public func applySelection(command: String, key: String,
                               expectedSelectionVersion: Int64): CjguiSharedOperationTreeSelectionResult {
        let current = selection.selectionVersion()
        if (expectedSelectionVersion != current) {
            return CjguiSharedOperationTreeSelectionResult(false, "selection_version_conflict", current)
        }
        let resolvedKey = if (key.size > 0) {
            key
        } else {
            // Empty key means "the current focus" for range/toggle commands.
            selection.snapshot().focus
        }
        if (command == "select-all") {
            selection.selectAllVisible()
            viewRevisionValue += 1
            return CjguiSharedOperationTreeSelectionResult(true, "", selection.selectionVersion())
        }
        if (command == "clear") {
            selection.clearSelection()
            viewRevisionValue += 1
            return CjguiSharedOperationTreeSelectionResult(true, "", selection.selectionVersion())
        }
        if (command == "expand" || command == "collapse") {
            let expanded = command == "expand"
            if (resolvedKey.size == 0 || projection.indexForKey(resolvedKey) < 0) {
                return CjguiSharedOperationTreeSelectionResult(false, "unknown_key", current)
            }
            let _ = projection.setExpanded(resolvedKey, expanded)
            selection.ensureFocusVisible()
            viewRevisionValue += 1
            return CjguiSharedOperationTreeSelectionResult(true, "", selection.selectionVersion())
        }
        if (resolvedKey.size == 0 || projection.indexForKey(resolvedKey) < 0) {
            return CjguiSharedOperationTreeSelectionResult(false, "unknown_key", current)
        }
        if (command == "replace") {
            selection.click(resolvedKey, false, false)
        } else if (command == "toggle") {
            selection.click(resolvedKey, true, false)
        } else if (command == "range") {
            selection.moveFocus(resolvedKey, true)
        } else {
            return CjguiSharedOperationTreeSelectionResult(false, "unknown_command", current)
        }
        viewRevisionValue += 1
        return CjguiSharedOperationTreeSelectionResult(true, "", selection.selectionVersion())
    }

    public func handleTreeEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // Keyboard navigation inside the tree focus scope. Native delivers the
        // command on the virtual-list scroll node, the same vocabulary the
        // framework list already uses; the tree model owns visible-order,
        // anchor and expand/collapse semantics. The key event's own modifier
        // state arrives with it, so Shift really extends the range.
        if (event.eventKind == 35 && event.node.nodeId == CJGUI_RULE_SET_TREE_LIST_NODE_ID) {
            let extendRange = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            return navigateTree(event.text, extendRange)
        }
        // Wheel/trackpad scrolling on the same list node keeps going through
        // the existing virtual-list scroll state.
        if (event.eventKind == 30 && event.node.nodeId == CJGUI_RULE_SET_TREE_LIST_NODE_ID) {
            let before = listState.scrollOffset()
            listState.scrollByViewport(event.text)
            if (listState.scrollOffset() == before) {
                return CjguiComposableUiDispatchResult(false)
            }
            viewRevisionValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let handled = handleEvent(event)
        if (handled.didApply) {
            selectionVersionValue += 1
        }
        return handled
    }

    /// The window this panel is mounted in, when the application attached it.
    /// Keyboard navigation uses it to keep the native focus on the row the tree
    /// model just focused.
    private var attachedWindow: ?CjguiComposableUiWindow = None

    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    /// One tree navigation step. Focus/selection/anchor move in the framework
    /// tree model; this panel reveals the resulting row through the existing
    /// virtual list, so an off-screen target is materialized instead of
    /// silently unreachable, and re-anchors the native focus to that row.
    public func navigateTree(command: String, extendSelection: Bool): CjguiComposableUiDispatchResult {
        let result = selection.navigate(command, extendSelection)
        if (!result.didChange) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (let Some(source) <- activeListSource) {
            let _ = listState.revealKey(source, result.focus)
        }
        focusRowIdentity(result.focus)
        viewRevisionValue += 1
        return CjguiComposableUiDispatchResult(true)
    }

    /// Keeps native focus, tree focus and the materialized row one thing. The
    /// scoped identity is the row declaration's own; when the row is not in the
    /// accepted scene yet (just revealed), the native side keeps the keyboard
    /// route on the list scope and this returns without claiming a move.
    private func focusRowIdentity(key: String): Bool {
        if (key.isEmpty()) {
            return false
        }
        let index = projection.indexForKey(key)
        if (index < 0) {
            return false
        }
        let row = projection.rowAt(index)
        let localKey = if (row.isGroup) { "group" } else { "leaf" }
        if (let Some(window) <- attachedWindow) {
            return window.focusScopedNode(CJGUI_RULE_SET_TREE_ROW_IDENTITY_SCOPE.child(key), localKey)
        }
        return false
    }

    public func buildSection(theme: CjguiComposableUiTheme,
                             bodyStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let _ = syncWithData()
        let section = cjguiComposableVertical(700000, "rule-tree-section",
            CjguiComposableUiStyle(padding: 8, gap: 6,
                background: theme.card.background, border: theme.card.border))
        section.add(cjguiComposableText(700001, "rule-tree-title", "分组树视图（多选）",
            CjguiComposableUiStyle(fontSize: 14.0)))

        let actions = cjguiComposableHorizontal(700002, "rule-tree-actions",
            CjguiComposableUiStyle(gap: 6))
        actions.add(cjguiComposableButton(700003, "rule-tree-select-all", "全选可见", "TREE_SELECT_ALL", 30,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(700004, "rule-tree-batch-enable", "批量启用所选", "TREE_BATCH_ENABLE", 31,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(700005, "rule-tree-batch-disable", "批量停用所选", "TREE_BATCH_DISABLE", 32,
            CjguiComposableUiStyle(fixedHeight: 28)))
        actions.add(cjguiComposableButton(700006, "rule-tree-clear", "清空多选", "TREE_CLEAR", 33,
            CjguiComposableUiStyle(fixedHeight: 28)))
        section.add(actions)

        // Only viewport + overscan rows materialize through the existing
        // fixed-row virtual list; the row builder receives the real projected
        // row (stable key, depth, group/expanded) rather than re-deriving it.
        //
        // Row declarations carry a scoped identity built from the row's STABLE
        // KEY, so the window's identity registry allocates their layout node
        // ids. Production binding therefore no longer reserves a hand-computed
        // numeric segment per row kind (the old LEAF/GROUP_ROW_NODE_BASE +
        // resourceId * STRIDE scheme): two rows - or a group and a leaf - can
        // never collide, and the same key keeps its identity across reorder,
        // re-parenting, unmount and re-entry. Event routing still resolves the
        // business object through `keyForResource(event.node.resourceId)`.
        let listSource = CjguiComposableUiTreeListSource(projection, selection,
            { row, isSelected, isFocused =>
                let rowScope = CJGUI_RULE_SET_TREE_ROW_IDENTITY_SCOPE.child(row.key)
                var indentText = ""
                var depthIndex: Int64 = 0
                while (depthIndex < row.depth) {
                    indentText += "    "
                    depthIndex += 1
                }
                let line = cjguiComposableHorizontal(0, "rule-tree-vrow-${row.key}",
                    CjguiComposableUiStyle(gap: 4), identity: Some(rowScope.local("line")))
                line.add(cjguiComposableText(0, "rule-tree-vindent-${row.key}", indentText,
                    CjguiComposableUiStyle(fontSize: 11.0), identity: Some(rowScope.local("indent"))))
                if (row.isGroup) {
                    let marker = if (row.expanded) { "▾" } else { "▸" }
                    line.add(cjguiComposableButton(0, "rule-tree-vgroup-${row.key}",
                        "${marker} ${row.label}", "TREE_GROUP_TOGGLE", row.resourceId,
                        CjguiComposableUiStyle(fixedHeight: 26), identity: Some(rowScope.local("group"))))
                } else {
                    let mark = if (isSelected) { "☑" } else { "☐" }
                    line.add(cjguiComposableButton(0, "rule-tree-vleaf-${row.key}",
                        "${mark} ${row.label}", "TREE_ROW_TOGGLE", row.resourceId,
                        CjguiComposableUiStyle(fixedHeight: 26), identity: Some(rowScope.local("leaf"))))
                }
                line
            })
        this.activeListSource = Some(listSource)
        section.add(cjguiComposableVirtualList(CJGUI_RULE_SET_TREE_LIST_NODE_ID, "rule-tree-list", 700008,
            listSource, listState, 30, 4, 6,
            CjguiComposableUiStyle(fixedHeight: 240,
                background: theme.card.background, border: theme.card.border)))

        let status = cjguiComposableText(700040, "rule-tree-status",
            "多选 ${selection.selectedCount()} 条 · ${batchStatus()}",
            CjguiComposableUiStyle(fontSize: 11.0))
        section.add(status)
        return section
    }
}

private func parseIntSuffix(key: String): Int64 {
    // Scans backwards for the trailing digit run ("record-<id>").
    var value: Int64 = 0
    var multiplier: Int64 = 1
    let chars = key.toArray()
    var index = chars.size - 1
    var sawDigit = false
    while (index >= 0) {
        let code = UInt32(chars[index])
        if (code < 48 || code > 57) { break }
        value += Int64(code - 48) * multiplier
        multiplier *= 10
        sawDigit = true
        index -= 1
    }
    return if (sawDigit) { value } else { -1 }
}
