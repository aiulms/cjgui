// Stable-key column layout state for the public table projection.
//
// The layout owns ONLY presentation: per-column width, visibility and order.
// It never owns records, sorting, filtering or drafts. Header and body cells
// read the same object, so they cannot disagree about which columns exist or
// how wide they are. A hidden column keeps its width and order entry; hiding is
// a projection choice, never a deletion of business data.
//
// Width 0 is reserved for the caller-declared flexible column. Dragging starts
// only from a resolved positive width; callers that want to resize a flexible
// column first give it a fixed width through the same public setter.
package cjgui

import std.collection.*
import std.overflow.*

/// Public interaction action carried by a table header resize handle. This is a
/// component gesture name, not a business action: the application routes the
/// pointer phases into the same layout object it uses for its own buttons.
public let CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION: String = "TABLE_COLUMN_RESIZE"

/// One stable-key column entry in a saved or restored layout. `width <= 0`
/// means the declared flexible width; positive values are clamped to the
/// declaration's current bounds. `visible == false` is a projection choice,
/// not a deletion.
public class CjguiComposableUiTableColumnState {
    public let key: String
    public let width: Int64
    public let visible: Bool

    public init(key: String, width: Int64, visible: Bool) {
        this.key = key
        this.width = width
        this.visible = visible
    }
}

/// Stable-key layout over a fixed column declaration. Keys must be unique;
/// a duplicate declaration keeps the first entry. All operations are O(n) in
/// the column count (small, declared once) and never touch row data.
public class CjguiComposableUiTableColumnLayout {
    private let declaredWidths: HashMap<String, Int64>
    private let minimumWidths: HashMap<String, Int64>
    private let maximumWidths: HashMap<String, Int64>
    private let declaredOrderValue: ArrayList<String>
    private var orderedKeysValue: ArrayList<String>
    private var widths: HashMap<String, Int64>
    private var visibility: HashMap<String, Bool>
    private var revisionValue: Int64
    private var resizeKeyValue: String
    private var resizeStartX: Int64
    private var resizeStartWidth: Int64
    private var resizeCurrentWidth: Int64
    // Target version for the window's existing pointer-capture contract.
    // Normal drag updates keep it stable; an independent write that kills the
    // gesture advances it so the old capture cannot continue.
    private var resizeCaptureVersionValue: Int64

    public init(columns: Array<CjguiComposableUiTableColumn>) {
        this.declaredWidths = HashMap<String, Int64>()
        this.minimumWidths = HashMap<String, Int64>()
        this.maximumWidths = HashMap<String, Int64>()
        this.declaredOrderValue = ArrayList<String>()
        this.orderedKeysValue = ArrayList<String>()
        this.widths = HashMap<String, Int64>()
        this.visibility = HashMap<String, Bool>()
        this.revisionValue = 0
        this.resizeKeyValue = ""
        this.resizeStartX = 0
        this.resizeStartWidth = 0
        this.resizeCurrentWidth = 0
        this.resizeCaptureVersionValue = 0
        for (column in columns) {
            if (this.declaredWidths.contains(column.key)) {
                continue
            }
            this.declaredWidths[column.key] = column.width
            this.minimumWidths[column.key] = column.minWidth
            this.maximumWidths[column.key] = column.maxWidth
            this.orderedKeysValue.add(column.key)
            this.widths[column.key] = column.width
            this.visibility[column.key] = true
            this.declaredOrderValue.add(column.key)
        }
    }

    /// Monotonic revision of the presentation state. It advances once per real
    /// width/visibility/order change; a no-op call leaves it unchanged.
    public func revision(): Int64 {
        return revisionValue
    }

    public func columnCount(): Int64 {
        return orderedKeysValue.size
    }

    public func hasColumn(key: String): Bool {
        return declaredWidths.contains(key)
    }

    /// Declaration order, including columns that the current projection hides.
    public func declaredKeys(): ArrayList<String> {
        return ArrayList<String>(declaredOrderValue)
    }

    /// Width declared for this column by the current component declaration.
    /// `0` still means the flexible column.
    public func declaredWidth(key: String): Int64 {
        return declaredWidths.get(key) ?? 0
    }

    public func columnKeys(): ArrayList<String> {
        return ArrayList<String>(orderedKeysValue)
    }

    public func visibleKeys(): ArrayList<String> {
        let result = ArrayList<String>()
        for (key in orderedKeysValue) {
            if (isVisible(key)) {
                result.add(key)
            }
        }
        return result
    }

    public func visibleCount(): Int64 {
        var count: Int64 = 0
        for (key in orderedKeysValue) {
            if (isVisible(key)) {
                count += 1
            }
        }
        return count
    }

    public func isVisible(key: String): Bool {
        return visibility.get(key) ?? false
    }

    /// Current width; 0 means the declared flexible column.
    public func width(key: String): Int64 {
        return widths.get(key) ?? 0
    }

    public func minWidth(key: String): Int64 {
        return minimumWidths.get(key) ?? 0
    }

    public func maxWidth(key: String): Int64 {
        return maximumWidths.get(key) ?? 0
    }

    /// Sets a fixed width. A value <= 0 restores the declared value (including
    /// flexible 0). Positive values are clamped to the declared bounds.
    public func setWidth(key: String, width: Int64): Bool {
        if (!widths.contains(key)) {
            return false
        }
        let normalized = if (width <= 0) {
            declaredWidths.get(key) ?? 0
        } else {
            clampWidth(key, width)
        }
        if (normalized == (widths.get(key) ?? 0)) {
            return false
        }
        widths[key] = normalized
        revisionValue = revisionValue.saturatingAdd(1)
        if (resizeKeyValue == key) {
            invalidateResizeSession()
        }
        return true
    }

    /// Keyboard/menu width step. Flexible columns are left untouched: there is
    /// no resolved width to step from until the caller assigns one.
    public func nudgeWidth(key: String, delta: Int64): Bool {
        let current = width(key)
        if (current <= 0) {
            return false
        }
        return setWidth(key, current.saturatingAdd(delta))
    }

    public func resetWidth(key: String): Bool {
        if (!widths.contains(key)) {
            return false
        }
        let declared = declaredWidths.get(key) ?? 0
        if (declared == (widths.get(key) ?? 0)) {
            return false
        }
        widths[key] = declared
        revisionValue = revisionValue.saturatingAdd(1)
        if (resizeKeyValue == key) {
            invalidateResizeSession()
        }
        return true
    }

    /// Hides or shows one column. The last visible column cannot be hidden:
    /// an all-hidden table would be indistinguishable from an empty one.
    public func setVisible(key: String, visible: Bool): Bool {
        if (!visibility.contains(key)) {
            return false
        }
        let current = isVisible(key)
        if (current == visible) {
            return false
        }
        if (!visible && visibleCount() <= 1) {
            return false
        }
        visibility[key] = visible
        revisionValue = revisionValue.saturatingAdd(1)
        if (!visible && resizeKeyValue == key) {
            invalidateResizeSession()
        }
        return true
    }

    public func toggleVisible(key: String): Bool {
        return setVisible(key, !isVisible(key))
    }

    /// Moves a column by one or more slots in the full declaration order,
    /// including hidden entries. The move is clamped to the ends.
    public func move(key: String, offset: Int64): Bool {
        let from = indexOfKey(key)
        if (from < 0 || offset == 0) {
            return false
        }
        var to = from.saturatingAdd(offset)
        if (to < 0) { to = 0 }
        if (to >= orderedKeysValue.size) { to = orderedKeysValue.size - 1 }
        if (to == from) {
            return false
        }
        moveWithin(from, to)
        revisionValue = revisionValue.saturatingAdd(1)
        if (resizeKeyValue == key) {
            invalidateResizeSession()
        }
        return true
    }

    /// Moves a column to an explicit slot in the full declaration order.
    public func moveToIndex(key: String, targetIndex: Int64): Bool {
        let from = indexOfKey(key)
        if (from < 0) {
            return false
        }
        var to = targetIndex
        if (to < 0) { to = 0 }
        if (to >= orderedKeysValue.size) { to = orderedKeysValue.size - 1 }
        if (to == from) {
            return false
        }
        moveWithin(from, to)
        revisionValue = revisionValue.saturatingAdd(1)
        if (resizeKeyValue == key) {
            invalidateResizeSession()
        }
        return true
    }

    /// Restores declaration order, widths and visibility. Returns true when
    /// anything actually changed.
    public func reset(): Bool {
        var changed = false
        var index: Int64 = 0
        while (index < orderedKeysValue.size) {
            let key = orderedKeysValue[index]
            let declared = declaredWidths.get(key) ?? 0
            if ((widths.get(key) ?? 0) != declared) {
                widths[key] = declared
                changed = true
            }
            if (!isVisible(key)) {
                visibility[key] = true
                changed = true
            }
            index += 1
        }
        if (!sameOrder(orderedKeysValue, declaredOrderValue)) {
            orderedKeysValue.clear()
            for (key in declaredOrderValue) {
                orderedKeysValue.add(key)
            }
            changed = true
        }
        if (changed) {
            revisionValue = revisionValue.saturatingAdd(1)
            invalidateResizeSession()
        }
        return changed
    }

    /// Applies one complete stable-key layout plan. The whole plan is validated
    /// first; a malformed or all-hidden plan returns false without changing any
    /// width, visibility or order. Keys absent from the current declaration are
    /// reported by the caller (this method rejects them) and columns that the
    /// current declaration added are appended at their declared default.
    ///
    /// Width `0` restores the declared width; positive widths are clamped to
    /// the declaration's current min/max, so an old saved width cannot escape
    /// today's constraints.
    public func applyState(states: ArrayList<CjguiComposableUiTableColumnState>): Bool {
        let seen = HashSet<String>()
        let newOrder = ArrayList<String>()
        let newWidths = HashMap<String, Int64>()
        let newVisibility = HashMap<String, Bool>()
        for (state in states) {
            if (!declaredWidths.contains(state.key) || seen.contains(state.key) || state.width < 0) {
                return false
            }
            seen.add(state.key)
            newOrder.add(state.key)
            let declared = declaredWidths.get(state.key) ?? 0
            newWidths[state.key] = if (state.width <= 0) {
                declared
            } else {
                clampWidth(state.key, state.width)
            }
            newVisibility[state.key] = state.visible
        }
        for (key in declaredOrderValue) {
            if (!seen.contains(key)) {
                seen.add(key)
                newOrder.add(key)
                newWidths[key] = declaredWidths.get(key) ?? 0
                newVisibility[key] = true
            }
        }
        if (newOrder.size == 0) {
            return false
        }
        var anyVisible = false
        for (key in newOrder) {
            if (newVisibility.get(key) ?? false) {
                anyVisible = true
                break
            }
        }
        if (!anyVisible) {
            return false
        }
        var changed = !sameOrder(orderedKeysValue, newOrder)
        if (!changed) {
            for (key in newOrder) {
                if ((widths.get(key) ?? 0) != (newWidths.get(key) ?? 0) ||
                    isVisible(key) != (newVisibility.get(key) ?? false)) {
                    changed = true
                    break
                }
            }
        }
        if (!changed) {
            return true
        }
        orderedKeysValue = newOrder
        widths = newWidths
        visibility = newVisibility
        revisionValue = revisionValue.saturatingAdd(1)
        invalidateResizeSession()
        return true
    }

    public func beginResize(key: String, startX: Int64, currentWidth: Int64): Bool {
        if (!widths.contains(key) || !isVisible(key) || width(key) <= 0 || currentWidth <= 0) {
            return false
        }
        resizeKeyValue = key
        resizeStartX = startX
        resizeStartWidth = currentWidth
        resizeCurrentWidth = clampWidth(key, currentWidth)
        return true
    }

    public func resizeActive(): Bool {
        return resizeKeyValue.size > 0
    }

    /// Stable while the SAME gesture is updating its width; advances when an
    /// independent write, hide, move or reset invalidates that gesture. The
    /// application returns this from its existing pointer-capture provider.
    public func resizeCaptureVersion(): Int64 {
        return resizeCaptureVersionValue
    }

    public func resizingKey(): String {
        return resizeKeyValue
    }

    /// Applies one pointer move. Returns the clamped width for the active
    /// column, or 0 when no resize is active.
    public func updateResize(pointerX: Int64): Int64 {
        if (resizeKeyValue.size == 0) {
            return 0
        }
        let delta = pointerX.saturatingSub(resizeStartX)
        let requested = resizeStartWidth.saturatingAdd(delta)
        let clamped = clampWidth(resizeKeyValue, requested)
        resizeCurrentWidth = clamped
        if (clamped != (widths.get(resizeKeyValue) ?? 0)) {
            widths[resizeKeyValue] = clamped
            revisionValue = revisionValue.saturatingAdd(1)
        }
        return clamped
    }

    /// Applies the terminal pointer coordinate of the ORIGINAL gesture, then
    /// ends it. CANCEL deliberately has no coordinate overload: a cancelled
    /// gesture never applies the cancel position.
    public func endResizeAt(pointerX: Int64): Int64 {
        if (resizeKeyValue.size == 0) {
            return 0
        }
        let _ = updateResize(pointerX)
        return endResize()
    }

    /// Ends the gesture, keeping the last applied width.
    public func endResize(): Int64 {
        let finalWidth = resizeCurrentWidth
        resizeKeyValue = ""
        resizeStartX = 0
        resizeStartWidth = 0
        resizeCurrentWidth = 0
        return finalWidth
    }

    /// Ends the gesture and restores the width it started from.
    public func cancelResize(): Int64 {
        let key = resizeKeyValue
        if (key.size == 0) {
            return 0
        }
        let restored = resizeStartWidth
        if ((widths.get(key) ?? 0) != restored) {
            widths[key] = restored
            revisionValue = revisionValue.saturatingAdd(1)
        }
        resizeKeyValue = ""
        resizeStartX = 0
        resizeStartWidth = 0
        resizeCurrentWidth = 0
        return restored
    }

    /// Stable, bounded serialization for diagnostics and external queries.
    /// Format: `TABLE_COLUMNS 1 | key:width:visible:min:max`.
    public func encodeState(): String {
        let builder = StringBuilder()
        builder.append("TABLE_COLUMNS 1")
        for (key in orderedKeysValue) {
            builder.append(" | ")
            builder.append(key)
            builder.append(":")
            builder.append(widths.get(key)?.toString() ?? "0")
            builder.append(":")
            builder.append(if (isVisible(key)) { "1" } else { "0" })
            builder.append(":")
            builder.append(minimumWidths.get(key)?.toString() ?? "0")
            builder.append(":")
            builder.append(maximumWidths.get(key)?.toString() ?? "0")
        }
        return builder.toString()
    }

    private func moveWithin(from: Int64, to: Int64): Unit {
        let moved = orderedKeysValue[from]
        let reordered = ArrayList<String>()
        var index: Int64 = 0
        while (index < orderedKeysValue.size) {
            if (reordered.size == to) {
                reordered.add(moved)
            }
            if (index != from) {
                reordered.add(orderedKeysValue[index])
            }
            index += 1
        }
        if (reordered.size == to) {
            reordered.add(moved)
        }
        orderedKeysValue = reordered
    }

    // An independent write to the dragged column, hiding it, or resetting the
    // layout ends this gesture. Later update/end/cancel phases from the old
    // capture are then ordinary no-ops instead of overwriting newer state.
    private func invalidateResizeSession(): Unit {
        if (resizeKeyValue.size == 0) {
            return
        }
        resizeKeyValue = ""
        resizeStartX = 0
        resizeStartWidth = 0
        resizeCurrentWidth = 0
        resizeCaptureVersionValue = resizeCaptureVersionValue.saturatingAdd(1)
    }

    private func indexOfKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < orderedKeysValue.size) {
            if (orderedKeysValue[index] == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    private func clampWidth(key: String, value: Int64): Int64 {
        let minimum = minimumWidths.get(key) ?? 0
        let maximum = maximumWidths.get(key) ?? 0
        var clamped = value
        if (clamped < minimum) { clamped = minimum }
        if (maximum > 0 && clamped > maximum) { clamped = maximum }
        return clamped
    }

    private func sameOrder(left: ArrayList<String>, right: ArrayList<String>): Bool {
        if (left.size != right.size) {
            return false
        }
        var index: Int64 = 0
        while (index < left.size) {
            if (left[index] != right[index]) {
                return false
            }
            index += 1
        }
        return true
    }
}
