// Experimental generic tree view: hierarchical data source, expanded-state
// projection, multi-selection and keyboard navigation over the existing
// virtual list machinery.
//
// Ownership: the application's data source owns all business content and
// stable keys; this file owns only the expanded-set, the visible-row
// projection, selection/focus/anchor bookkeeping and their versions. It
// never retains business subtrees beyond the bounded projection and never
// exposes native handles.
//
// Determinism: duplicate keys, cycles and illegal parent references are
// detected during projection rebuild — the offending subtree is skipped, the
// projection stays acyclic and the first error is reported via lastError().
package cjgui

import std.collection.*

/// One node handed out by the application's tree data source. `key` is the
/// durable stable identity used by selection, expansion and external reads;
/// `resourceId` stays application-owned data.
public class CjguiComposableUiTreeNode {
    public let key: String
    public let label: String
    public let resourceId: Int64
    public let isGroup: Bool
    public let selectable: Bool

    public init(key: String, label: String, resourceId: Int64, isGroup: Bool,
                selectable!: Bool = true) {
        this.key = key
        this.label = label
        this.resourceId = resourceId
        this.isGroup = isGroup
        this.selectable = selectable
    }
}

/// Hierarchical data source implemented by the application. The empty parent
/// key addresses the roots. Implementations must answer from their own
/// business state; the framework never writes through this interface.
public interface CjguiComposableUiTreeDataSource {
    func childCount(parentKey: String): Int64
    func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode
}

/// One visible row of the expanded projection.
public struct CjguiComposableUiTreeRow {
    public let key: String
    public let label: String
    public let resourceId: Int64
    public let depth: Int64
    public let isGroup: Bool
    public let expanded: Bool
    public let selectable: Bool

    public init(key: String, label: String, resourceId: Int64, depth: Int64,
                isGroup: Bool, expanded: Bool, selectable: Bool) {
        this.key = key
        this.label = label
        this.resourceId = resourceId
        this.depth = depth
        this.isGroup = isGroup
        this.expanded = expanded
        this.selectable = selectable
    }
}

/// Expanded-state, visible-row projection and data-version bookkeeping.
/// Rebuild is O(visible) after the first O(N) index pass; hot scroll, hover
/// and local selection never re-walk hidden subtrees.
public class CjguiComposableUiTreeProjection {
    private let source: CjguiComposableUiTreeDataSource
    private var expandedKeys: HashSet<String>
    private var rows: ArrayList<CjguiComposableUiTreeRow>
    private var keyToRowIndex: HashMap<String, Int64>
    private var keyToParent: HashMap<String, String>
    private var dataVersionValue: Int64
    private var lastErrorValue: String

    public init(source: CjguiComposableUiTreeDataSource) {
        this.source = source
        this.expandedKeys = HashSet<String>()
        this.rows = ArrayList<CjguiComposableUiTreeRow>()
        this.keyToRowIndex = HashMap<String, Int64>()
        this.keyToParent = HashMap<String, String>()
        this.dataVersionValue = 0
        this.lastErrorValue = ""
        let _ = rebuild()
    }

    public func dataVersion(): Int64 {
        return dataVersionValue
    }

    public func rowCount(): Int64 {
        return rows.size
    }

    public func rowAt(index: Int64): CjguiComposableUiTreeRow {
        return rows[index]
    }

    public func indexForKey(key: String): Int64 {
        if (let Some(index) <- keyToRowIndex.get(key)) {
            return index
        }
        return -1
    }

    /// Parent key of a projected node ("" for roots); empty when unknown.
    public func parentKeyOf(key: String): String {
        if (let Some(parent) <- keyToParent.get(key)) {
            return parent
        }
        return ""
    }

    /// True when the key currently projects as a visible row.
    public func isVisible(key: String): Bool {
        return indexForKey(key) >= 0
    }

    /// Nearest visible ancestor of a key that is currently hidden (for
    /// example because a group holding it was collapsed). Falls back to the
    /// key itself when the key has no visible ancestor.
    public func nearestVisibleAncestor(key: String): String {
        var current = key
        var guard: Int64 = 0
        while (guard < 64) {
            if (isVisible(current)) {
                return current
            }
            let parent = parentKeyOf(current)
            if (parent.isEmpty()) {
                return key
            }
            current = parent
            guard += 1
        }
        return key
    }

    public func isExpanded(key: String): Bool {
        return expandedKeys.contains(key)
    }

    public func setExpanded(key: String, expanded: Bool): Bool {
        if (expanded) {
            expandedKeys.add(key)
        } else {
            expandedKeys.remove(key)
        }
        return rebuild()
    }

    public func toggleExpand(key: String): Bool {
        return setExpanded(key, !isExpanded(key))
    }

    /// Bulk expanded-state update: the whole set is modified first and the
    /// projection is rebuilt exactly once. Returns true when anything changed
    /// (so callers can avoid a version bump / scene commit when nothing did).
    public func setExpandedBatch(keys: ArrayList<String>, expanded: Bool): Bool {
        var changed = false
        for (key in keys) {
            if (expanded) {
                if (!expandedKeys.contains(key)) {
                    expandedKeys.add(key)
                    changed = true
                }
            } else {
                if (expandedKeys.contains(key)) {
                    expandedKeys.remove(key)
                    changed = true
                }
            }
        }
        if (!changed) {
            return false
        }
        let _ = rebuild()
        return true
    }

    /// All group keys of the current projection (visible or not is irrelevant:
    /// groups are roots or descendants that carry children).
    public func groupKeys(): ArrayList<String> {
        let result = ArrayList<String>()
        var index: Int64 = 0
        while (index < rows.size) {
            if (rows[index].isGroup) {
                result.add(rows[index].key)
            }
            index += 1
        }
        return result
    }

    public func lastError(): String {
        return lastErrorValue
    }

    /// Marks the business data changed and rebuilds the projection. Keys that
    /// no longer exist are pruned from the expanded set; selection pruning is
    /// the selection layer's responsibility.
    public func invalidate(): Bool {
        dataVersionValue += 1
        return rebuild()
    }

    /// Depth-first projection of the expanded tree. Duplicate keys, cycles
    /// and illegal parents skip the offending node/subtree deterministically.
    public func rebuild(): Bool {
        let newRows = ArrayList<CjguiComposableUiTreeRow>()
        let newIndex = HashMap<String, Int64>()
        // Parent links survive a collapse: a hidden node keeps the parent it
        // had while it was visible, so a hidden focus can still fall back to
        // its visible ancestor without walking the hidden subtree.
        let newParents = HashMap<String, String>(keyToParent)
        let seenKeys = HashSet<String>()
        let priorError = lastErrorValue
        lastErrorValue = ""
        walk("", 0, newRows, newIndex, newParents, seenKeys)
        rows = newRows
        keyToRowIndex = newIndex
        keyToParent = newParents
        return lastErrorValue.isEmpty()
    }

    private func walk(parentKey: String, depth: Int64,
                      newRows: ArrayList<CjguiComposableUiTreeRow>,
                      newIndex: HashMap<String, Int64>, newParents: HashMap<String, String>,
                      seenKeys: HashSet<String>): Unit {
        let count = source.childCount(parentKey)
        var index: Int64 = 0
        while (index < count) {
            let node = source.childAt(parentKey, index)
            if (node.key.isEmpty() || seenKeys.contains(node.key)) {
                // Duplicate or empty key: skip deterministically.
                if (lastErrorValue.isEmpty()) {
                    lastErrorValue = "duplicate_or_empty_key:" + node.key
                }
                index += 1
                continue
            }
            seenKeys.add(node.key)
            if (depth > 64) {
                // Cycle guard: absurd depth means a parent reference loop.
                if (lastErrorValue.isEmpty()) {
                    lastErrorValue = "cycle:" + node.key
                }
                return
            }
            let expanded = node.isGroup && expandedKeys.contains(node.key)
            newRows.add(CjguiComposableUiTreeRow(node.key, node.label, node.resourceId,
                depth, node.isGroup, expanded, node.selectable))
            newIndex.add(node.key, newRows.size - 1)
            newParents.add(node.key, parentKey)
            if (node.isGroup && expanded) {
                walk(node.key, depth + 1, newRows, newIndex, newParents, seenKeys)
            }
            index += 1
        }
    }
}

/// Immutable selection snapshot handed to consumers and external readers.
public class CjguiComposableUiTreeSelectionSnapshot {
    public let keys: ArrayList<String>
    public let focus: String
    public let anchor: String
    public let selectionVersion: Int64
    public let projectionVersion: Int64

    public init(keys: ArrayList<String>, focus: String, anchor: String,
                selectionVersion: Int64, projectionVersion: Int64) {
        this.keys = keys
        this.focus = focus
        this.anchor = anchor
        this.selectionVersion = selectionVersion
        this.projectionVersion = projectionVersion
    }
}

/// Outcome of one tree navigation command. `didChange` is false when the
/// command could not move focus, expand/collapse or change the selection, so
/// the caller must not advance its own view/scene revision for it.
public class CjguiComposableUiTreeNavigationResult {
    public let didChange: Bool
    public let focus: String

    public init(didChange: Bool, focus: String) {
        this.didChange = didChange
        this.focus = focus
    }
}

/// Multi-selection, focus and anchor over the tree projection. Selection is
/// a set of stable keys; anchor/focus/expand stay explicit. All mutating
/// operations take the projection so range semantics follow the current
/// visible order and the data version is recorded with every change.
public class CjguiComposableUiTreeSelection {
    private let projection: CjguiComposableUiTreeProjection
    private var selectedKeys: HashSet<String>
    private var selectionOrder: ArrayList<String>
    private var focusKey: String
    private var anchorKey: String
    private var selectionVersionValue: Int64

    public init(projection: CjguiComposableUiTreeProjection) {
        this.projection = projection
        this.selectedKeys = HashSet<String>()
        this.selectionOrder = ArrayList<String>()
        this.focusKey = ""
        this.anchorKey = ""
        this.selectionVersionValue = 0
    }

    public func selectionVersion(): Int64 {
        return selectionVersionValue
    }

    public func focus(): String {
        return focusKey
    }

    public func anchor(): String {
        return anchorKey
    }

    public func isSelected(key: String): Bool {
        return selectedKeys.contains(key)
    }

    public func selectedCount(): Int64 {
        return selectionOrder.size
    }

    /// Ordered stable keys of the current selection.
    public func selectedKeysInOrder(): ArrayList<String> {
        return selectionOrder
    }

    /// Public snapshot of the selection for windows, components and external
    /// readers: exact stable keys, focus, anchor and both versions. Values come
    /// from the live selection state, never from rendered labels.
    public func snapshot(): CjguiComposableUiTreeSelectionSnapshot {
        return CjguiComposableUiTreeSelectionSnapshot(
            ArrayList<String>(selectionOrder), focusKey, anchorKeyEffective(),
            selectionVersionValue, projection.dataVersion())
    }

    private func addKey(key: String): Unit {
        if (!selectedKeys.contains(key)) {
            selectedKeys.add(key)
            selectionOrder.add(key)
        }
    }

    private func removeKey(key: String): Unit {
        if (selectedKeys.contains(key)) {
            selectedKeys.remove(key)
            var index = 0
            while (index < selectionOrder.size) {
                if (selectionOrder[index] == key) {
                    selectionOrder.remove(at: index)
                    break
                }
                index += 1
            }
        }
    }

    private func replaceSelectionWith(key: String): Unit {
        selectedKeys.clear()
        selectionOrder.clear()
        addKey(key)
    }

    /// Range selection over the current visible order. `anchorKey` and
    /// `targetKey` form a closed interval; the interval is always walked in
    /// visible order (ascending row index), so the selected-key list a public
    /// reader sees is the same for a forward and for a reverse Shift range.
    /// The anchor itself is unchanged, so later extensions still measure from
    /// it. Groups stay focusable but contribute no selected key.
    private func applyRange(anchorKey: String, targetKey: String, extendSelection: Bool): Unit {
        if (!extendSelection) {
            replaceSelectionWith(targetKey)
            return
        }
        let startIndex = projection.indexForKey(anchorKey)
        let endIndex = projection.indexForKey(targetKey)
        if (startIndex < 0 || endIndex < 0) {
            replaceSelectionWith(targetKey)
            return
        }
        selectedKeys.clear()
        selectionOrder.clear()
        let low = if (startIndex <= endIndex) { startIndex } else { endIndex }
        let high = if (startIndex <= endIndex) { endIndex } else { startIndex }
        var index = low
        while (index <= high) {
            let row = projection.rowAt(index)
            if (row.selectable) {
                addKey(row.key)
            }
            index += 1
        }
    }

    /// Mouse click semantics: plain click selects one row; Cmd toggles the
    /// row and moves anchor/focus to it; Shift extends from the anchor along
    /// the current visible order.
    public func click(key: String, command: Bool, shift: Bool): Unit {
        let index = projection.indexForKey(key)
        if (index < 0) { return }
        let row = projection.rowAt(index)
        if (!row.selectable) { return }
        if (shift) {
            let rangeAnchor = pickAnchor(key)
            applyRange(rangeAnchor, key, true)
            focusKey = key
            selectionVersionValue += 1
            return
        }
        if (command) {
            if (selectedKeys.contains(key)) {
                removeKey(key)
            } else {
                addKey(key)
            }
            anchorKeyEffectiveSet(key)
            focusKey = key
            selectionVersionValue += 1
            return
        }
        replaceSelectionWith(key)
        anchorKeyEffectiveSet(key)
        focusKey = key
        selectionVersionValue += 1
    }

    private var anchorKeyEffectiveValue: String = ""

    private func anchorKeyEffective(): String {
        return anchorKeyEffectiveValue
    }

    private func pickAnchor(fallback: String): String {
        if (anchorKeyEffective().isEmpty()) {
            return fallback
        }
        return anchorKeyEffective()
    }

    private func anchorKeyEffectiveSet(key: String): Unit {
        anchorKeyEffectiveValue = key
        anchorKey = key
    }

    /// Selects every selectable row of the current expanded projection
    /// (including rows outside the viewport).
    public func selectAllVisible(): Unit {
        selectedKeys.clear()
        selectionOrder.clear()
        var index: Int64 = 0
        while (index < projection.rowCount()) {
            let row = projection.rowAt(index)
            if (row.selectable) {
                addKey(row.key)
            }
            index += 1
        }
        selectionVersionValue += 1
    }

    public func clearSelection(): Unit {
        selectedKeys.clear()
        selectionOrder.clear()
        selectionVersionValue += 1
    }

    /// Removes one key without touching the rest of the selection (used by
    /// toggle-style consumers).
    public func clearKey(key: String): Unit {
        removeKey(key)
        selectionVersionValue += 1
    }

    /// Focus movement along the visible projection. `extendSelection` keeps the
    /// anchor and applies a range from it to the new focus.
    public func moveFocus(targetKey: String, extendSelection: Bool): Unit {
        let index = projection.indexForKey(targetKey)
        if (index < 0) { return }
        if (extendSelection) {
            applyRange(anchorKeyEffective(), targetKey, true)
        } else {
            focusKey = targetKey
        }
        focusKey = targetKey
        selectionVersionValue += 1
    }

    /// One visible step of tree focus. `delta` is negative toward the first
    /// row. Groups are focusable (they are navigation stops) even though an
    /// extended range only ever selects rows that declare `selectable`.
    /// Returns the resulting focus key, or "" for an empty projection. A
    /// command that cannot move the focus does not advance the version.
    public func moveFocusBy(delta: Int64, extendSelection: Bool): String {
        let count = projection.rowCount()
        if (count <= 0) {
            return ""
        }
        var current = projection.indexForKey(focusKey)
        if (current < 0) {
            let fallback = projection.indexForKey(anchorKeyEffective())
            current = if (fallback >= 0) {
                fallback
            } else {
                if (delta >= 0) { -1 } else { count }
            }
        }
        var target = current + delta
        if (target < 0) { target = 0 }
        if (target >= count) { target = count - 1 }
        let key = projection.rowAt(target).key
        if (!extendSelection && key == focusKey) {
            return focusKey
        }
        if (extendSelection) {
            applyRange(beginOrContinueRange(key), key, true)
        }
        focusKey = key
        selectionVersionValue += 1
        return key
    }

    /// Anchor for a keyboard range extension. The first extension starts at the
    /// current focus (so Shift+Down selects from the focused row, exactly like
    /// a Shift-click from it) and remembers that anchor for later extensions in
    /// the same gesture; an explicit anchor set by a click always wins.
    private func beginOrContinueRange(targetKey: String): String {
        let current = anchorKeyEffective()
        if (!current.isEmpty() && projection.indexForKey(current) >= 0) {
            return current
        }
        let start = if (!focusKey.isEmpty() && projection.indexForKey(focusKey) >= 0) {
            focusKey
        } else {
            targetKey
        }
        anchorKeyEffectiveSet(start)
        return start
    }

    /// First or last visible row of the current projection.
    public func moveFocusToEdge(last: Bool, extendSelection: Bool): String {
        let count = projection.rowCount()
        if (count <= 0) {
            return ""
        }
        let target = if (last) { count - 1 } else { 0 }
        let key = projection.rowAt(target).key
        if (!extendSelection && key == focusKey) {
            return focusKey
        }
        if (extendSelection) {
            applyRange(beginOrContinueRange(key), key, true)
        }
        focusKey = key
        selectionVersionValue += 1
        return key
    }

    /// Keyboard "left": collapse an expanded group, otherwise move the focus
    /// to the visible ancestor. Returns the resulting focus key.
    public func collapseOrAscend(): String {
        if (focusKey.isEmpty() || !projection.isVisible(focusKey)) {
            return focusKey
        }
        let row = projection.rowAt(projection.indexForKey(focusKey))
        if (row.isGroup && row.expanded) {
            let _ = projection.setExpanded(focusKey, false)
            selectionVersionValue += 1
            return focusKey
        }
        let parent = projection.parentKeyOf(focusKey)
        if (parent.isEmpty() || !projection.isVisible(parent)) {
            return focusKey
        }
        focusKey = parent
        selectionVersionValue += 1
        return focusKey
    }

    /// Keyboard "right": expand a collapsed group, or descend to its first
    /// child when it is already expanded. Returns the resulting focus key.
    public func expandOrDescend(): String {
        if (focusKey.isEmpty() || !projection.isVisible(focusKey)) {
            return focusKey
        }
        let index = projection.indexForKey(focusKey)
        let row = projection.rowAt(index)
        if (!row.isGroup) {
            return focusKey
        }
        if (!row.expanded) {
            let _ = projection.setExpanded(focusKey, true)
            selectionVersionValue += 1
            return focusKey
        }
        if (index + 1 < projection.rowCount()) {
            let child = projection.rowAt(index + 1)
            if (child.depth > row.depth) {
                focusKey = child.key
                selectionVersionValue += 1
                return focusKey
            }
        }
        return focusKey
    }

    /// One navigation command inside the tree focus scope. Commands match the
    /// framework's existing navigation vocabulary (`up`, `down`, `page_up`,
    /// `page_down`, `home`, `end`) plus the tree-specific `left`, `right` and
    /// `select_all`. `didChange` distinguishes a real focus/selection/expansion
    /// change from a command that could not move, so a caller never advances
    /// its revision for a no-op. The returned focus key lets the caller
    /// materialize/reveal that row in its virtual list; grouping stays here so
    /// no consumer re-implements tree navigation.
    public func navigate(command: String, extendSelection: Bool): CjguiComposableUiTreeNavigationResult {
        let focusBefore = focusKey
        let versionBefore = selectionVersionValue
        let rowsBefore = projection.rowCount()
        if (command == "left") {
            let _ = collapseOrAscend()
        } else if (command == "right") {
            let _ = expandOrDescend()
        } else if (command == "select_all") {
            selectAllVisible()
        } else if (command == "home" || command == "end") {
            let _ = moveFocusToEdge(command == "end", extendSelection)
        } else {
            var step: Int64 = 0
            if (command == "up") {
                step = -1
            } else if (command == "down") {
                step = 1
            } else if (command == "page_up") {
                step = -10
            } else if (command == "page_down") {
                step = 10
            } else {
                return CjguiComposableUiTreeNavigationResult(false, focusBefore)
            }
            let _ = moveFocusBy(step, extendSelection)
        }
        let changed = selectionVersionValue != versionBefore || projection.rowCount() != rowsBefore
        return CjguiComposableUiTreeNavigationResult(changed, focusKey)
    }

    /// Keeps the focus honest after an expand/collapse change: a focus hidden
    /// by a collapsed group falls back to its nearest visible ancestor instead
    /// of pointing at an invisible row.
    public func ensureFocusVisible(): Unit {
        let current = focusKey
        if (current.isEmpty() || projection.isVisible(current)) {
            return
        }
        let fallback = projection.nearestVisibleAncestor(current)
        if (fallback != current && !fallback.isEmpty()) {
            focusKey = fallback
            selectionVersionValue += 1
        }
    }

    /// Prunes selection/anchor/focus entries whose keys no longer exist in the
    /// logical data set (not merely in the current expansion). Call after a
    /// data-version change. Collapsed groups keep their hidden logical
    /// selection; pruning only touches vanished keys, and a call that changes
    /// nothing does not advance the selection version (so a no-op refresh
    /// cannot force a scene commit).
    public func prune(existingKeys: ArrayList<String>): Unit {
        let alive = HashSet<String>()
        for (key in existingKeys) {
            alive.add(key)
        }
        var changed = false
        var index = selectionOrder.size - 1
        while (index >= 0) {
            if (!alive.contains(selectionOrder[index])) {
                selectedKeys.remove(selectionOrder[index])
                selectionOrder.remove(at: index)
                changed = true
            }
            index -= 1
        }
        if (!alive.contains(anchorKeyEffective())) {
            // A vanished anchor falls back to the first surviving selected key
            // (never extends the selection to unrelated branches).
            let fallbackAnchor = if (selectionOrder.size > 0) { selectionOrder[0] } else { "" }
            if (fallbackAnchor != anchorKeyEffectiveValue) {
                changed = true
            }
            anchorKeyEffectiveValue = fallbackAnchor
            anchorKey = fallbackAnchor
        }
        if (!alive.contains(focusKey)) {
            if (!focusKey.isEmpty()) {
                changed = true
            }
            focusKey = ""
        }
        if (changed) {
            selectionVersionValue += 1
        }
    }
}

/// Adapter that exposes the expanded tree projection through the existing
/// fixed-row virtual list engine, so only viewport + overscan rows ever
/// become component subtrees. The row builder receives the real projected
/// row (stable key, depth, group/expanded state), never a key re-derived from
/// display text or a resource id.
public class CjguiComposableUiTreeListSource <: CjguiComposableUiVirtualListSource {
    private let projection: CjguiComposableUiTreeProjection
    private let selection: CjguiComposableUiTreeSelection
    private let builder: (CjguiComposableUiTreeRow, Bool, Bool) -> CjguiComposableUiNode

    public init(projection: CjguiComposableUiTreeProjection,
                selection: CjguiComposableUiTreeSelection,
                builder: (CjguiComposableUiTreeRow, Bool, Bool) -> CjguiComposableUiNode) {
        this.projection = projection
        this.selection = selection
        this.builder = builder
    }

    public func itemCount(): Int64 {
        return projection.rowCount()
    }

    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        let row = projection.rowAt(index)
        return CjguiComposableUiVirtualListItem(row.key, row.resourceId, row.label)
    }

    public func indexForKey(key: String): Int64 {
        return projection.indexForKey(key)
    }

    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
        let index = projection.indexForKey(item.key)
        if (index < 0) {
            // The materialized row's key no longer projects (removed or
            // collapsed away). Build a stable placeholder for that key only;
            // never bind a stale input to a different object.
            let stale = CjguiComposableUiTreeRow(item.key, item.title, item.resourceId, 0, false, false, false)
            return builder(stale, false, false)
        }
        return builder(projection.rowAt(index), isSelected, isFocused)
    }
}
