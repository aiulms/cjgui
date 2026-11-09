package cjgui

import std.collection.*

/// One stable-key text projection over any variable-height virtual list source.
///
/// The wrapper only chooses WHICH base item indices are visible. It never
/// renumbers business identity (`item.key` / `item.resourceId` still come from
/// the base source), never materializes row subtrees and never copies item
/// content into a second store. Callers declare:
///
///   * the text a row participates in matching with (`textOf`), and
///   * a monotonic data revision through `dataChanged` so a changed applied
///     value invalidates the cached visible order without rebuilding on every
///     unrelated event.
///
/// An empty query disables filtering and delegates every call to the base
/// source without scanning. Matching is ASCII case-insensitive substring,
/// consistent with the other composable filter entry points; other scripts
/// match exactly.
///
/// A non-empty query builds the visible order with ONE synchronous scan over
/// `base.itemCount()` projection values. It creates no UI nodes and copies no
/// row content, but the scan is O(list length) and therefore bounded by the
/// collection the consumer exposes; it re-runs only after `setQuery` or a
/// `dataChanged` revision, never per layout pass. Row validity follows the
/// variable-height list contract: a row is addressable when its stable `key`
/// is non-empty. `resourceId` may legitimately be -1 for rows that project a
/// non-resource (group/separator/summary) item.
public class CjguiComposableUiFilteredListSource <: CjguiComposableUiVariableHeightListSource {
    private let base: CjguiComposableUiVariableHeightListSource
    private let textOf: (CjguiComposableUiVariableHeightListItem) -> String
    private let visibleBaseIndices = ArrayList<Int64>()
    private var queryValue: String = ""
    private var dataRevisionValue: Int64 = 0
    private var orderBuilt: Bool = true

    public init(base: CjguiComposableUiVariableHeightListSource,
        textOf: (CjguiComposableUiVariableHeightListItem) -> String) {
        this.base = base
        this.textOf = textOf
    }

    public func query(): String {
        return queryValue
    }

    public func isFiltering(): Bool {
        return queryValue.size > 0
    }

    /// Number of rows the list may present. When filtering is off this is the
    /// base source's own count, so the wrapper adds no cost to ordinary use.
    public func visibleCount(): Int64 {
        ensureOrder()
        return if (isFiltering()) {
            visibleBaseIndices.size
        } else {
            base.itemCount()
        }
    }

    /// Base-source index for one visible position. The caller still resolves
    /// business identity through `base.itemAt(baseIndex)`; this is a range
    /// projection, never an identity.
    public func visibleBaseIndex(position: Int64): Int64 {
        ensureOrder()
        if (!isFiltering()) {
            return position
        }
        if (position < 0 || position >= visibleBaseIndices.size) {
            return -1
        }
        return visibleBaseIndices[position]
    }

    /// Change the query and invalidate the cached order. Returns true when the
    /// query actually changed, mirroring ordinary view-state setters.
    public func setQuery(value: String): Bool {
        if (queryValue == value) {
            return false
        }
        queryValue = value
        orderBuilt = false
        return true
    }

    /// Tell the wrapper that the underlying applied data changed. The next
    /// visible-count/position query rebuilds only if filtering is active.
    public func dataChanged(revision: Int64): Unit {
        if (revision != dataRevisionValue) {
            dataRevisionValue = revision
            orderBuilt = false
        }
    }

    /// Force the next query to rebuild the visible order. Used when a caller
    /// changed its own matching text projection without changing the query.
    public func invalidate(): Unit {
        orderBuilt = false
    }

    public func itemCount(): Int64 {
        ensureOrder()
        return if (isFiltering()) {
            visibleBaseIndices.size
        } else {
            base.itemCount()
        }
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        ensureOrder()
        if (!isFiltering()) {
            return base.itemAt(index)
        }
        if (index < 0 || index >= visibleBaseIndices.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return base.itemAt(visibleBaseIndices[index])
    }

    public func indexForKey(key: String): Int64 {
        ensureOrder()
        let baseIndex = base.indexForKey(key)
        if (baseIndex < 0) {
            return -1
        }
        if (!isFiltering()) {
            return baseIndex
        }
        // Visible base indices are strictly ascending; a stable-key lookup
        // therefore never turns a display position into identity.
        var low: Int64 = 0
        var high: Int64 = visibleBaseIndices.size - 1
        while (low <= high) {
            let middle = low + (high - low) / 2
            let candidate = visibleBaseIndices[middle]
            if (candidate == baseIndex) {
                return middle
            }
            if (candidate < baseIndex) {
                low = middle + 1
            } else {
                high = middle - 1
            }
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return base.measurementGeneration()
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return base.buildRow(item, isSelected, isFocused)
    }

    private func ensureOrder(): Unit {
        if (orderBuilt) {
            return
        }
        visibleBaseIndices.clear()
        if (isFiltering()) {
            let needle = queryValue.toAsciiLower()
            let count = base.itemCount()
            var index: Int64 = 0
            while (index < count) {
                let item = base.itemAt(index)
                // Stable key, not resourceId, is the variable-height list's row
                // identity contract. A missing placeholder has an empty key;
                // legal rows may project no business resource (resourceId < 0).
                if (item.key.size > 0 && textOf(item).toAsciiLower().contains(needle)) {
                    visibleBaseIndices.add(index)
                }
                index += 1
            }
        }
        orderBuilt = true
    }
}
