// Virtual card grid over the existing variable-height collection list.
//
// The grid is an ADAPTER, not a second collection. It groups the caller's
// business items into row-major rows based on the currently available content
// width, and exposes those rows through the same variable-height list source
// the framework already materializes, scrolls and reveals. Only visible rows
// (plus the list's existing overscan) become component subtrees.
//
// Business identity never comes from a row/column number: every card carries
// instanceKey + itemKey in its identity scope, and the list source maps a
// business key back to its current row for selection/reveal. Changing the
// column count therefore changes the grouping, not which record a click,
// selection or action addresses.
//
// Card content, actions and selection painting stay caller-owned. The source
// only supplies geometry, grouping, stable card slots and the selected/focused
// flags in the context. This module does not create a scroll state, a second
// selection or a business model.
//
// The responsive column math and index-to-row mapping follow the standard
// cross-axis-extent approach used by Flutter's RenderSliverGrid
// (SliverGridDelegateWithMaxCrossAxisExtent): inspect-only reference, no
// dependency or imported runtime.
package cjgui

import std.collection.*
import std.convert.*
import std.overflow.*

/// Caller-declared card geometry. `minimumCardWidth` is a lower bound: the
/// actual card width is the largest evenly distributed width that still fits
/// the available content width. Heights are fixed in this first version.
public class CjguiComposableUiCardGridSpec {
    public let minimumCardWidth: Int64
    public let columnGap: Int64
    public let rowGap: Int64
    public let cardHeight: Int64

    public init(minimumCardWidth: Int64, cardHeight: Int64, columnGap!: Int64 = 10, rowGap!: Int64 = 10) {
        this.minimumCardWidth = if (minimumCardWidth > 0) { minimumCardWidth } else { 1 }
        this.cardHeight = if (cardHeight > 0) { cardHeight } else { 1 }
        this.columnGap = if (columnGap >= 0) { columnGap } else { 0 }
        this.rowGap = if (rowGap >= 0) { rowGap } else { 0 }
    }
}

/// Reversible card identity encoding over a stable business key.
///
/// IdentityScope segments are ASCII `[A-Za-z0-9_-]` and at most 96 characters;
/// this encoding is hex, so the supported business key is at most 48 UTF-8
/// bytes. Longer keys are refused rather than hashed: a hash would silently
/// alias distinct business keys. Callers should validate at their data entry
/// with `issueForItem` and reject the record; do not truncate or hash the
/// business key, because that would change its identity.
public class CjguiComposableUiCardGridIdentity {
    public static let MAXIMUM_ITEM_KEY_BYTES: Int64 = 48
    public static let MAXIMUM_TOKEN_CHARS: Int64 = 96
    public static let ISSUE_KEY_EMPTY: String = "card_grid_identity_key_empty"
    public static let ISSUE_KEY_TOO_LONG: String = "card_grid_identity_key_too_long"

    /// Reversible token, or `None` when the key is empty or outside the
    /// supported byte length. No hash or allocator fallback is used.
    public static func tokenForItem(itemKey: String): ?String {
        if (itemKey.size == 0 || itemKey.size > MAXIMUM_ITEM_KEY_BYTES) {
            return None
        }
        let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        let builder = StringBuilder()
        for (byte in itemKey) {
            let numeric = Int64(byte)
            builder.append(digits[numeric / 16])
            builder.append(digits[numeric % 16])
        }
        return Some(builder.toString())
    }

    /// Empty string means the key has a supported reversible identity.
    public static func issueForItem(itemKey: String): String {
        if (itemKey.size == 0) {
            return ISSUE_KEY_EMPTY
        }
        if (itemKey.size > MAXIMUM_ITEM_KEY_BYTES) {
            return ISSUE_KEY_TOO_LONG
        }
        return ""
    }
}

/// One card's geometry and current selection/focus projection. `identity` is
/// scoped to this instance and this stable item key, so a card's child controls
/// keep the same identity across column reflow. `actionName`/`actionResourceId`
/// are the caller-declared action for this item (empty/-1 means display-only).
public class CjguiComposableUiCardGridCardContext {
    public let key: String
    public let resourceId: Int64
    public let cardWidth: Int64
    public let cardHeight: Int64
    public let columns: Int64
    public let rowIndex: Int64
    public let columnIndex: Int64
    public let selected: Bool
    public let focused: Bool
    public let identity: CjguiComposableUiIdentityScope
    public let actionName: String
    public let actionResourceId: Int64

    public init(key: String, resourceId: Int64, cardWidth: Int64, cardHeight: Int64, columns: Int64,
        rowIndex: Int64, columnIndex: Int64, selected: Bool, focused: Bool,
        identity: CjguiComposableUiIdentityScope, actionName: String, actionResourceId: Int64) {
        this.key = key
        this.resourceId = resourceId
        this.cardWidth = cardWidth
        this.cardHeight = cardHeight
        this.columns = columns
        this.rowIndex = rowIndex
        this.columnIndex = columnIndex
        this.selected = selected
        this.focused = focused
        this.identity = identity
        this.actionName = actionName
        this.actionResourceId = actionResourceId
    }
}

/// Virtual row source for a responsive card grid.
public class CjguiComposableUiCardGridSource <: CjguiComposableUiVariableHeightListSource {
    private let base: CjguiComposableUiVariableHeightListSource
    private let instanceKey: String
    private let gridSpec: CjguiComposableUiCardGridSpec
    private let buildCard: (CjguiComposableUiVariableHeightListItem, CjguiComposableUiCardGridCardContext) -> CjguiComposableUiNode
    private let actionOf: ?((CjguiComposableUiVariableHeightListItem) -> CjguiComposableUiTableRowAction)
    private let selectedOf: ?((String) -> Bool)
    private let focusedKeyOf: ?(() -> String)
    private var availableWidthValue: Int64
    private var columnsValue: Int64
    private var cardWidthValue: Int64
    private var generationValue: Int64
    private var lastIdentityIssueValue: String

    public init(base: CjguiComposableUiVariableHeightListSource, instanceKey: String,
        spec: CjguiComposableUiCardGridSpec,
        buildCard: (CjguiComposableUiVariableHeightListItem, CjguiComposableUiCardGridCardContext) ->
            CjguiComposableUiNode,
        actionOf!: ?((CjguiComposableUiVariableHeightListItem) -> CjguiComposableUiTableRowAction) = None,
        selectedOf!: ?((String) -> Bool) = None,
        focusedKeyOf!: ?(() -> String) = None) {
        this.base = base
        this.instanceKey = instanceKey
        this.gridSpec = spec
        this.buildCard = buildCard
        this.actionOf = actionOf
        this.selectedOf = selectedOf
        this.focusedKeyOf = focusedKeyOf
        this.availableWidthValue = 0
        this.columnsValue = 1
        this.cardWidthValue = spec.minimumCardWidth
        this.generationValue = 0
        this.lastIdentityIssueValue = ""
    }

    public func spec(): CjguiComposableUiCardGridSpec {
        return gridSpec
    }

    public func availableWidth(): Int64 {
        return availableWidthValue
    }

    public func columns(): Int64 {
        return columnsValue
    }

    public func cardWidth(): Int64 {
        return cardWidthValue
    }

    public func rowCount(): Int64 {
        let count = base.itemCount()
        if (count <= 0) {
            return 0
        }
        return (count + columnsValue - 1) / columnsValue
    }

    public func baseItemCount(): Int64 {
        return base.itemCount()
    }

    /// Sets the actual content width supplied by the consumer. The allocation
    /// formula keeps the card width at or above the declared minimum whenever
    /// the width allows it; a width narrower than one minimum card uses one
    /// column and the full width. Returns true when the grouping or card width
    /// changed, so the caller can re-anchor on the previous top business item.
    public func setAvailableWidth(width: Int64): Bool {
        let safeWidth = if (width > 0) { width } else { gridSpec.minimumCardWidth }
        let stride = gridSpec.minimumCardWidth.saturatingAdd(gridSpec.columnGap)
        var nextColumns = if (stride > 0) {
            (safeWidth.saturatingAdd(gridSpec.columnGap)) / stride
        } else {
            1
        }
        if (nextColumns < 1) {
            nextColumns = 1
        }
        var nextCardWidth = (safeWidth - gridSpec.columnGap.saturatingMul(nextColumns - 1)) / nextColumns
        while (nextColumns > 1 && nextCardWidth < gridSpec.minimumCardWidth) {
            nextColumns -= 1
            nextCardWidth = (safeWidth - gridSpec.columnGap.saturatingMul(nextColumns - 1)) / nextColumns
        }
        if (nextCardWidth < 1) {
            nextCardWidth = 1
        }
        if (safeWidth == availableWidthValue && nextColumns == columnsValue &&
            nextCardWidth == cardWidthValue) {
            return false
        }
        availableWidthValue = safeWidth
        columnsValue = nextColumns
        cardWidthValue = nextCardWidth
        generationValue = generationValue.saturatingAdd(1)
        return true
    }

    /// First business key in the current row. This is the anchor a consumer
    /// uses before changing the width; revealing it after the reflow keeps the
    /// reading position on the same business item.
    public func itemKeyForRowStart(rowIndex: Int64): String {
        if (rowIndex < 0) {
            return ""
        }
        let baseIndex = rowIndex.saturatingMul(columnsValue)
        if (baseIndex < 0 || baseIndex >= base.itemCount()) {
            return ""
        }
        return base.itemAt(baseIndex).key
    }

    public func itemCount(): Int64 {
        return rowCount()
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= rowCount()) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let firstIndex = index.saturatingMul(columnsValue)
        let first = base.itemAt(firstIndex)
        return CjguiComposableUiVariableHeightListItem(rowKey(index), -1, first.title,
            rowRevision(index), estimatedHeight: gridSpec.cardHeight)
    }

    /// Resolves ONLY an internal row key produced by `itemAt`.
    ///
    /// Business item keys must not be passed here: a business key may itself
    /// look like an internal row key. Use `rowKeyForItem` for business lookup.
    public func indexForKey(key: String): Int64 {
        let rowKeyPrefix = gridRowPrefix()
        if (!key.startsWith(rowKeyPrefix)) {
            return -1
        }
        let suffix = key.split(rowKeyPrefix)
        if (suffix.size == 2) {
            if (let Some(rowIndex) <- Int64.tryParse(suffix[1])) {
                if (rowIndex >= 0 && rowIndex < rowCount()) {
                    return rowIndex
                }
            }
        }
        return -1
    }

    /// Resolves a business item key through the base source's own index, then
    /// computes its CURRENT grid row. It deliberately does not call
    /// `indexForKey`: a business key that happens to resemble an internal row
    /// key must still resolve by its base position, not by row-key syntax.
    ///
    /// Returns "" when the base source does not contain the item.
    public func rowKeyForItem(itemKey: String): String {
        let baseIndex = base.indexForKey(itemKey)
        if (baseIndex < 0 || baseIndex >= base.itemCount() || columnsValue <= 0) {
            return ""
        }
        let rowIndex = baseIndex / columnsValue
        if (rowIndex < 0 || rowIndex >= rowCount()) {
            return ""
        }
        return rowKey(rowIndex)
    }

    public func measurementGeneration(): Int64 {
        return base.measurementGeneration().saturatingAdd(generationValue)
    }

    /// Why the most recent `buildRow` omitted a card, or "" when every item
    /// had a supported identity. A too-long key is refused, never hashed.
    public func lastIdentityIssue(): String {
        return lastIdentityIssueValue
    }

    /// Pure validation for a business key before it reaches `buildRow`.
    public func identityIssueForKey(itemKey: String): String {
        return CjguiComposableUiCardGridIdentity.issueForItem(itemKey)
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let rowIndex = indexForKey(item.key)
        lastIdentityIssueValue = ""
        let rowScope = CjguiComposableUiIdentityScope(instanceKey).child("rows")
        let row = cjguiComposableHorizontal(-1, "${instanceKey}-card-row-${rowIndex}",
            CjguiComposableUiStyle(fixedHeight: gridSpec.cardHeight, growX: 1,
                gap: gridSpec.columnGap, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH),
            identity: Some(rowScope.local("row_${rowIndex}")))
        let focusedKey = if (let Some(provider) <- focusedKeyOf) { provider() } else { "" }
        var column: Int64 = 0
        while (column < columnsValue) {
            let baseIndex = rowIndex.saturatingMul(columnsValue).saturatingAdd(column)
            let business = base.itemAt(baseIndex)
            if (business.key.size == 0) {
                // Tail row: keep the slot rectangular, but do not invent a
                // business identity or card content for a missing row.
                row.add(cjguiComposableHorizontal(-1,
                    "${instanceKey}-card-empty-${rowIndex}-${column}",
                    CjguiComposableUiStyle(fixedWidth: cardWidthValue, fixedHeight: gridSpec.cardHeight),
                    identity: Some(rowScope.local("empty_${rowIndex}_${column}"))))
                column += 1
                continue
            }
            let identityToken = CjguiComposableUiCardGridIdentity.tokenForItem(business.key) ?? ""
            if (identityToken.size == 0) {
                // A too-long key is refused by name; no hash-based identity
                // alias is invented. The slot deliberately carries an INVALID
                // identity so candidate resolution rejects the whole candidate
                // and the previous accepted scene remains visible. It is not a
                // valid placeholder that could hide the error.
                lastIdentityIssueValue = CjguiComposableUiCardGridIdentity.issueForItem(business.key)
                let rejectedScope = CjguiComposableUiIdentityScope(instanceKey).child("cards").child("")
                row.add(cjguiComposableHorizontal(-1,
                    "${instanceKey}-card-identity-rejected-${rowIndex}-${column}",
                    CjguiComposableUiStyle(fixedWidth: cardWidthValue, fixedHeight: gridSpec.cardHeight),
                    identity: Some(rejectedScope.local("identity_rejected_${rowIndex}_${column}"))))
                column += 1
                continue
            }
            let cardScope = CjguiComposableUiIdentityScope(instanceKey).child("cards")
                .child(identityToken)
            let action = if (let Some(provider) <- actionOf) {
                provider(business)
            } else {
                CjguiComposableUiTableRowAction.none()
            }
            let selected = isSelected || (if (let Some(provider) <- selectedOf) {
                provider(business.key)
            } else {
                false
            })
            let context = CjguiComposableUiCardGridCardContext(business.key, business.resourceId,
                cardWidthValue, gridSpec.cardHeight, columnsValue, rowIndex, column, selected,
                focusedKey == business.key, cardScope, action.actionName, action.resourceId)
            let card = buildCard(business, context)
            let slot = cjguiComposableHorizontal(-1,
                "${instanceKey}-card-slot-${rowIndex}-${column}",
                CjguiComposableUiStyle(fixedWidth: cardWidthValue, fixedHeight: gridSpec.cardHeight,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH),
                identity: Some(cardScope.local("slot")))
            slot.add(card)
            row.add(slot)
            column += 1
        }
        return row
    }

    private func gridRowPrefix(): String {
        return "cjgui.grid.${instanceKey}.row."
    }

    private func rowKey(rowIndex: Int64): String {
        return "${gridRowPrefix()}${rowIndex}"
    }


    private func rowRevision(rowIndex: Int64): Int64 {
        var revision = generationValue
        let start = rowIndex.saturatingMul(columnsValue)
        var column: Int64 = 0
        while (column < columnsValue) {
            let item = base.itemAt(start.saturatingAdd(column))
            if (item.key.size > 0) {
                revision = revision.saturatingAdd(item.layoutRevision.saturatingMul(column + 1))
            }
            column += 1
        }
        return revision
    }
}

/// Row-major keyboard target calculation. It returns a stable business key or
/// an empty string for an unknown command/empty order; the caller passes that
/// key to the SAME `CjguiComposableUiCollectionSelection.moveFocus`, so Shift
/// ranges, hidden selection and reveal semantics stay unchanged.
public class CjguiComposableUiCardGridNavigation {
    public static func targetKey(order: CjguiComposableUiCollectionOrder, focusKey: String,
        command: String, columns: Int64): String {
        let count = order.count()
        if (count <= 0) {
            return ""
        }
        let safeColumns = if (columns > 0) { columns } else { 1 }
        var current = order.indexOfKey(focusKey)
        if (current < 0) {
            current = 0
        }
        var target = current
        if (command == "left") {
            target = current - 1
        } else if (command == "right") {
            target = current + 1
        } else if (command == "up") {
            target = current - safeColumns
        } else if (command == "down") {
            target = current + safeColumns
        } else if (command == "home") {
            target = 0
        } else if (command == "end") {
            target = count - 1
        } else if (command == "page_up") {
            target = current - safeColumns.saturatingMul(10)
        } else if (command == "page_down") {
            target = current + safeColumns.saturatingMul(10)
        } else {
            return ""
        }
        if (target < 0) {
            target = 0
        }
        if (target >= count) {
            target = count - 1
        }
        return order.keyAt(target)
    }
}
