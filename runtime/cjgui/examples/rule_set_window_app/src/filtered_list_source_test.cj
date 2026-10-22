// Public filtered-list contract regression. Lives beside the normal consumer
// so it links through the ordinary application native archive instead of the
// framework's TESTING-only probe symbols.
package cjgui_rule_set_window_app

import cjgui.*
import std.collection.*
import std.convert.*
import std.unittest.*
import std.unittest.testmacro.*

/// A valid variable-height row may project no business resource at all: its
/// stable key, title and measured layout are the list contract, while
/// `resourceId == -1` only means "this row addresses no domain resource".
/// The public text filter must keep such rows addressable.
private class FilteredListIdentityContractSource <: CjguiComposableUiVariableHeightListSource {
    private let titles: ArrayList<String>

    init(titles: ArrayList<String>) {
        this.titles = ArrayList<String>(titles)
    }

    public func itemCount(): Int64 {
        return titles.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= titles.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return CjguiComposableUiVariableHeightListItem("row_${index}", -1, titles[index], 0, estimatedHeight: 32)
    }

    public func indexForKey(key: String): Int64 {
        let parts = key.split("_")
        if (parts.size == 2 && parts[0] == "row") {
            if (let Some(index) <- Int64.tryParse(parts[1])) {
                if (index >= 0 && index < titles.size) {
                    return index
                }
            }
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(900000 + item.resourceId, "filter-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 32))
    }
}

/// A sparse range source reports one placeholder slot (`missing()` has an empty
/// key). The filter must not treat that slot as a row merely because the text
/// projection still returns matchable text for it.
private class SparseFilteredListSource <: CjguiComposableUiVariableHeightListSource {
    private let titles: ArrayList<String>

    init(titles: ArrayList<String>) {
        this.titles = ArrayList<String>(titles)
    }

    public func itemCount(): Int64 {
        return titles.size + 1
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= titles.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return CjguiComposableUiVariableHeightListItem("row_${index}", -1, titles[index], 0, estimatedHeight: 32)
    }

    public func indexForKey(key: String): Int64 {
        let parts = key.split("_")
        if (parts.size == 2 && parts[0] == "row") {
            if (let Some(index) <- Int64.tryParse(parts[1])) {
                if (index >= 0 && index < titles.size) {
                    return index
                }
            }
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(900000 + item.resourceId, "filter-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 32))
    }
}

@Test
func filteredListKeepsLegalRowsWithoutBusinessResourceId(): Unit {
    let base = FilteredListIdentityContractSource(
        ArrayList<String>(["分组标题", "Alpha 记录", "Beta 记录"]))
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    @Assert(filtered.isFiltering(), false)
    @Assert(filtered.visibleCount(), 3)
    @Assert(filtered.itemAt(0).resourceId, -1)

    // The row with no business resource still matches and keeps its stable key.
    @Assert(filtered.setQuery("记录"), true)
    @Assert(filtered.visibleCount(), 2)
    @Assert(filtered.itemAt(0).key, "row_1")
    @Assert(filtered.itemAt(0).resourceId, -1)
    @Assert(filtered.itemAt(1).key, "row_2")
    @Assert(filtered.indexForKey("row_1"), 0)
    @Assert(filtered.indexForKey("row_2"), 1)
    @Assert(filtered.indexForKey("row_0"), -1)

    filtered.setQuery("Alpha")
    @Assert(filtered.visibleCount(), 1)
    @Assert(filtered.itemAt(0).key, "row_1")
    @Assert(filtered.itemAt(0).resourceId, -1)

    // The projection returns matchable text even for the missing placeholder
    // slot; the empty stable key is what keeps that slot out of the range.
    let sparse = SparseFilteredListSource(ArrayList<String>(["Alpha", "Beta"]))
    let matchingEverything = CjguiComposableUiFilteredListSource(sparse, { item => "Alpha" })
    matchingEverything.setQuery("alpha")
    @Assert(matchingEverything.visibleCount(), 2)
    @Assert(matchingEverything.itemAt(0).key, "row_0")
    @Assert(matchingEverything.indexForKey("row_0"), 0)
    @Assert(matchingEverything.indexForKey("row_2"), -1)
}
