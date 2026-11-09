// Hierarchy-independent multi-selection over any ordered stable-key collection.
//
// The tree projection and the flat list/table projections share THIS module:
// the selection stores only stable keys plus focus/anchor/version, and every
// range operation reads the caller's CURRENT order. A sorted or filtered
// projection therefore changes what a range covers, never which business keys
// are selected, and no display row index is ever retained as identity.
//
// Ownership: the application still owns records, drafts and writes. This module
// never resolves a resource id, never writes business state and never builds a
// row. Callers prune only when a key really vanished or stopped being
// selectable; a key merely hidden by a filter stays selected.
package cjgui

import std.collection.*

/// The ordered projection selection operates on. Implementations answer from
/// the authoritative current view; the selection never stores these indices.
public interface CjguiComposableUiCollectionOrder {
    func count(): Int64
    func keyAt(index: Int64): String
    func indexOfKey(key: String): Int64
    func isSelectableAt(index: Int64): Bool
}

/// Adapts any existing variable-height list source (the filtered list or the
/// sorted table projection) to the selection order contract. `selectable`
/// is the caller's eligibility rule; a resource id is never inferred here.
public class CjguiComposableUiFlatCollectionOrder <: CjguiComposableUiCollectionOrder {
    private let source: CjguiComposableUiVariableHeightListSource
    private let selectable: (CjguiComposableUiVariableHeightListItem) -> Bool

    public init(source: CjguiComposableUiVariableHeightListSource,
        selectable: (CjguiComposableUiVariableHeightListItem) -> Bool) {
        this.source = source
        this.selectable = selectable
    }

    public func count(): Int64 {
        return source.itemCount()
    }

    public func keyAt(index: Int64): String {
        if (index < 0 || index >= source.itemCount()) {
            return ""
        }
        return source.itemAt(index).key
    }

    public func indexOfKey(key: String): Int64 {
        return source.indexForKey(key)
    }

    public func isSelectableAt(index: Int64): Bool {
        if (index < 0 || index >= source.itemCount()) {
            return false
        }
        let item = source.itemAt(index)
        return item.key.size > 0 && selectable(item)
    }
}

/// Immutable public snapshot. `viewVersion` is the caller's current
/// filter/sort/data revision, recorded beside the selection version so a
/// reader can tell which projection the keys were chosen over.
public class CjguiComposableUiCollectionSelectionSnapshot {
    public let keys: ArrayList<String>
    public let focus: String
    public let anchor: String
    public let selectionVersion: Int64
    public let viewVersion: Int64

    public init(keys: ArrayList<String>, focus: String, anchor: String,
        selectionVersion: Int64, viewVersion: Int64) {
        this.keys = keys
        this.focus = focus
        this.anchor = anchor
        this.selectionVersion = selectionVersion
        this.viewVersion = viewVersion
    }
}

public class CjguiComposableUiCollectionNavigationResult {
    public let didChange: Bool
    public let focus: String

    public init(didChange: Bool, focus: String) {
        this.didChange = didChange
        this.focus = focus
    }
}

/// Multi-selection, focus and anchor over a caller-supplied ordered projection.
public class CjguiComposableUiCollectionSelection {
    private var selectedKeys: HashSet<String>
    private var selectionOrder: ArrayList<String>
    private var focusKey: String
    private var anchorKey: String
    private var selectionVersionValue: Int64

    public init() {
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

    public func selectedKeysInOrder(): ArrayList<String> {
        return ArrayList<String>(selectionOrder)
    }

    public func snapshot(viewVersion: Int64): CjguiComposableUiCollectionSelectionSnapshot {
        return CjguiComposableUiCollectionSelectionSnapshot(
            ArrayList<String>(selectionOrder), focusKey, anchorKey,
            selectionVersionValue, viewVersion)
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

    private func anchorInOrder(order: CjguiComposableUiCollectionOrder, fallback: String): String {
        if (!anchorKey.isEmpty() && order.indexOfKey(anchorKey) >= 0) {
            return anchorKey
        }
        // A hidden or vanished anchor must not keep acting like an old display
        // position. The next range starts from this gesture's target instead.
        return fallback
    }

    private func applyRange(anchor: String, target: String,
        order: CjguiComposableUiCollectionOrder): Unit {
        let startIndex = order.indexOfKey(anchor)
        let endIndex = order.indexOfKey(target)
        if (startIndex < 0 || endIndex < 0) {
            replaceSelectionWith(target)
            anchorKey = target
            return
        }
        selectedKeys.clear()
        selectionOrder.clear()
        let low = if (startIndex <= endIndex) { startIndex } else { endIndex }
        let high = if (startIndex <= endIndex) { endIndex } else { startIndex }
        var index = low
        while (index <= high) {
            if (order.isSelectableAt(index)) {
                addKey(order.keyAt(index))
            }
            index += 1
        }
        anchorKey = anchor
    }

    /// Mouse click semantics: plain replaces, Command toggles, Shift extends
    /// from the anchor along the CURRENT order. Focus always moves to the
    /// clicked selectable row.
    public func click(key: String, command: Bool, shift: Bool,
        order: CjguiComposableUiCollectionOrder): Unit {
        let index = order.indexOfKey(key)
        if (index < 0 || !order.isSelectableAt(index)) {
            return
        }
        if (shift) {
            let anchor = anchorInOrder(order, key)
            applyRange(anchor, key, order)
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
            anchorKey = key
            focusKey = key
            selectionVersionValue += 1
            return
        }
        replaceSelectionWith(key)
        anchorKey = key
        focusKey = key
        selectionVersionValue += 1
    }

    /// Replaces the selection with every selectable row of the CURRENT order,
    /// including rows outside the viewport. No UI row is materialized here.
    public func selectAll(order: CjguiComposableUiCollectionOrder): Unit {
        selectedKeys.clear()
        selectionOrder.clear()
        var index: Int64 = 0
        while (index < order.count()) {
            if (order.isSelectableAt(index)) {
                addKey(order.keyAt(index))
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

    public func clearKey(key: String): Unit {
        removeKey(key)
        selectionVersionValue += 1
    }

    /// Moves focus and, when extending, replaces the selection with the range
    /// anchor..target in the current order.
    public func moveFocus(targetKey: String, extendSelection: Bool,
        order: CjguiComposableUiCollectionOrder): Unit {
        if (order.indexOfKey(targetKey) < 0) {
            return
        }
        if (extendSelection) {
            let anchor = anchorInOrder(order, targetKey)
            applyRange(anchor, targetKey, order)
        }
        focusKey = targetKey
        selectionVersionValue += 1
    }

    public func moveFocusBy(delta: Int64, extendSelection: Bool,
        order: CjguiComposableUiCollectionOrder): String {
        let count = order.count()
        if (count <= 0) {
            return ""
        }
        var current = order.indexOfKey(focusKey)
        if (current < 0) {
            let fallback = order.indexOfKey(anchorKey)
            current = if (fallback >= 0) {
                fallback
            } else {
                if (delta >= 0) { -1 } else { count }
            }
        }
        var target = current + delta
        if (target < 0) { target = 0 }
        if (target >= count) { target = count - 1 }
        let key = order.keyAt(target)
        if (!extendSelection && key == focusKey) {
            return focusKey
        }
        if (extendSelection) {
            // The first extension starts at the current focus, matching a
            // Shift-click on that row; a valid anchor set by an earlier click
            // wins. A hidden anchor falls back to focus/target.
            var rangeAnchor = anchorInOrder(order, "")
            if (rangeAnchor.isEmpty()) {
                rangeAnchor = if (!focusKey.isEmpty() && order.indexOfKey(focusKey) >= 0) {
                    focusKey
                } else {
                    key
                }
                anchorKey = rangeAnchor
            }
            applyRange(rangeAnchor, key, order)
        }
        focusKey = key
        selectionVersionValue += 1
        return key
    }

    public func moveFocusToEdge(last: Bool, extendSelection: Bool,
        order: CjguiComposableUiCollectionOrder): String {
        let count = order.count()
        if (count <= 0) {
            return ""
        }
        let target = if (last) { count - 1 } else { 0 }
        let key = order.keyAt(target)
        if (!extendSelection && key == focusKey) {
            return focusKey
        }
        if (extendSelection) {
            var rangeAnchor = anchorInOrder(order, "")
            if (rangeAnchor.isEmpty()) {
                rangeAnchor = if (!focusKey.isEmpty() && order.indexOfKey(focusKey) >= 0) {
                    focusKey
                } else {
                    key
                }
                anchorKey = rangeAnchor
            }
            applyRange(rangeAnchor, key, order)
        }
        focusKey = key
        selectionVersionValue += 1
        return key
    }

    /// Keyboard vocabulary shared with the virtual list: up/down/page/home/
    /// end and select_all. Unknown commands change nothing.
    public func navigate(command: String, extendSelection: Bool,
        order: CjguiComposableUiCollectionOrder): CjguiComposableUiCollectionNavigationResult {
        let versionBefore = selectionVersionValue
        if (command == "select_all") {
            selectAll(order)
        } else if (command == "home" || command == "end") {
            let _ = moveFocusToEdge(command == "end", extendSelection, order)
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
                return CjguiComposableUiCollectionNavigationResult(false, focusKey)
            }
            let _ = moveFocusBy(step, extendSelection, order)
        }
        return CjguiComposableUiCollectionNavigationResult(
            selectionVersionValue != versionBefore, focusKey)
    }

    /// Repairs focus after a filter/sort/view change. Selection is untouched:
    /// a hidden selected key stays selected. A hidden focus falls back to the
    /// anchor when it is still in the order, otherwise to the first selectable
    /// row. Returns true when the focus moved.
    public func ensureFocusInOrder(order: CjguiComposableUiCollectionOrder): Bool {
        if (focusKey.isEmpty() || order.indexOfKey(focusKey) >= 0) {
            return false
        }
        var fallback = if (!anchorKey.isEmpty() && order.indexOfKey(anchorKey) >= 0) {
            anchorKey
        } else {
            ""
        }
        if (fallback.isEmpty()) {
            var index: Int64 = 0
            while (index < order.count()) {
                if (order.isSelectableAt(index)) {
                    fallback = order.keyAt(index)
                    break
                }
                index += 1
            }
        }
        if (fallback.isEmpty()) {
            fallback = if (order.count() > 0) { order.keyAt(0) } else { "" }
        }
        if (fallback != focusKey) {
            focusKey = fallback
            selectionVersionValue += 1
            return true
        }
        return false
    }

    /// Number of selected keys not present in the current order (temporarily
    /// hidden by a filter). Deleted or now-ineligible keys never count here:
    /// callers prune those with `pruneToEligible`.
    public func hiddenCount(order: CjguiComposableUiCollectionOrder): Int64 {
        var hidden: Int64 = 0
        for (key in selectionOrder) {
            if (order.indexOfKey(key) < 0) {
                hidden += 1
            }
        }
        return hidden
    }

    /// Drops selected/anchor/focus keys that no longer exist in the caller's
    /// logical data set. A call that changes nothing does not advance the
    /// version, so an unrelated refresh cannot force a scene commit.
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
        if (!anchorKey.isEmpty() && !alive.contains(anchorKey)) {
            let fallbackAnchor = if (selectionOrder.size > 0) { selectionOrder[0] } else { "" }
            if (fallbackAnchor != anchorKey) {
                changed = true
            }
            anchorKey = fallbackAnchor
        }
        if (!focusKey.isEmpty() && !alive.contains(focusKey)) {
            changed = true
            focusKey = ""
        }
        if (changed) {
            selectionVersionValue += 1
        }
    }

    /// Drops keys whose row is gone from the CURRENT projection or is no
    /// longer selectable. The tree keeps hidden-by-collapse selections through
    /// `prune`, so only callers that really mean "current rows only" use this.
    public func pruneToSelectable(order: CjguiComposableUiCollectionOrder): Unit {
        var changed = false
        var index = selectionOrder.size - 1
        while (index >= 0) {
            let key = selectionOrder[index]
            let rowIndex = order.indexOfKey(key)
            if (rowIndex < 0 || !order.isSelectableAt(rowIndex)) {
                selectedKeys.remove(key)
                selectionOrder.remove(at: index)
                changed = true
            }
            index -= 1
        }
        if (!anchorKey.isEmpty()) {
            let anchorRow = order.indexOfKey(anchorKey)
            if (anchorRow < 0 || !order.isSelectableAt(anchorRow)) {
                let fallbackAnchor = if (selectionOrder.size > 0) { selectionOrder[0] } else { "" }
                if (fallbackAnchor != anchorKey) {
                    changed = true
                }
                anchorKey = fallbackAnchor
            }
        }
        if (changed) {
            selectionVersionValue += 1
        }
    }

    /// Full logical eligibility check used by flat views: a key stays selected
    /// when it is merely filtered out, but is removed when its record vanished
    /// or is no longer selectable.
    public func pruneToEligible(eligibleKeys: ArrayList<String>): Unit {
        let eligible = HashSet<String>()
        for (key in eligibleKeys) {
            eligible.add(key)
        }
        pruneToEligibleSet(eligible)
    }

    /// Experimental: prune against the ORIGINAL unfiltered eligibility order.
    /// Reads only until selected/focus/anchor keys have all been resolved;
    /// an empty selection reads no records. Missing keys still require a full
    /// scan, and the worst case remains linear in the original order size.
    /// Passing a filtered order would incorrectly discard hidden selections.
    public func pruneToEligible(order: CjguiComposableUiCollectionOrder): Unit {
        let remaining = HashSet<String>(selectionOrder)
        if (!anchorKey.isEmpty()) { remaining.add(anchorKey) }
        if (!focusKey.isEmpty()) { remaining.add(focusKey) }
        if (remaining.size == 0) { return }
        let eligible = HashSet<String>()
        let count = order.count()
        var index: Int64 = 0
        while (index < count && remaining.size > 0) {
            let key = order.keyAt(index)
            if (remaining.contains(key)) {
                remaining.remove(key)
                if (order.isSelectableAt(index)) { eligible.add(key) }
            }
            index += 1
        }
        pruneToEligibleSet(eligible)
    }

    private func pruneToEligibleSet(eligible: HashSet<String>): Unit {
        var changed = false
        var index = selectionOrder.size - 1
        while (index >= 0) {
            if (!eligible.contains(selectionOrder[index])) {
                selectedKeys.remove(selectionOrder[index])
                selectionOrder.remove(at: index)
                changed = true
            }
            index -= 1
        }
        if (!anchorKey.isEmpty() && !eligible.contains(anchorKey)) {
            let fallbackAnchor = if (selectionOrder.size > 0) { selectionOrder[0] } else { "" }
            if (fallbackAnchor != anchorKey) {
                changed = true
            }
            anchorKey = fallbackAnchor
        }
        if (!focusKey.isEmpty() && !eligible.contains(focusKey)) {
            focusKey = ""
            changed = true
        }
        if (changed) {
            selectionVersionValue += 1
        }
    }

    // Package-internal view mutations used by tree expand/collapse and focus
    // repair. They are not business selection commands.
    func advanceSelectionVersion(): Unit {
        selectionVersionValue += 1
    }

    func setFocusWithoutVersionChange(key: String): Unit {
        focusKey = key
    }
}
