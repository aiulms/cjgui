// Tests for the grid composition helper.
//
// What is pinned here is the ONE property a table cannot get wrong, plus the two that
// make borders look right:
//   * every cell of a column uses the SAME width, taken from the spec -- a cell never
//     measures its own text into the layout, which is what makes a table look ragged;
//   * a short row still has a rectangle for every column;
//   * each internal boundary is ONE node, so neighbouring cells cannot double a border;
//   * the header rule exists exactly once.
//
// Pure host test: no window and no native module.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

@Test
func testGridSharesOneResolvedWidthPerColumn(): Unit {
    let spec = CjguiGridSpec([80, 40, 120],
        [["名称", "数量", "说明"], ["苹果", "3", "水果"], ["x"]])
    // column 2 of the last row is MISSING: it must still get a cell with the shared width
    let grid = cjguiComposableGrid(1000, "table", spec, CjguiComposableUiStyle(),
        CjguiComposableUiStyle(), CjguiComposableUiStyle(), CjguiComposableUiStyle())
    let rows = grid.children()
    // three content rows plus the header rule inserted right after the first row
    @Assert(rows.size, 4)
    @Assert(rows[1].nodeId, spec.headerRuleNodeId(1000))
    let firstRow = rows[0].children()
    let secondRow = rows[2].children()
    // three cells + two separators
    @Assert(firstRow.size, 5)
    var column: Int64 = 0
    while (column < 3) {
        let width = firstRow[column * 2].style.fixedWidth
        @Assert(width, spec.columns[column])
        // the SAME width in the next content row, even though its text is shorter
        @Assert(secondRow[column * 2].style.fixedWidth, width)
        column += 1
    }
    // the ragged row is padded to three cells -- checked BY ID, because a separator
    // node also has a fixed width and would otherwise be counted as a cell
    let lastRow = rows[3].children()
    column = 0
    while (column < 3) {
        var found = false
        var index: Int64 = 0
        while (index < Int64(lastRow.size)) {
            if (lastRow[index].nodeId == spec.cellNodeId(1000, 2, column)) {
                found = true
                @Assert(lastRow[index].style.fixedWidth, spec.columns[column])
            }
            index += 1
        }
        @Assert(found)
        column += 1
    }
}

@Test
func testGridDrawsEachInternalBoundaryOnce(): Unit {
    let spec = CjguiGridSpec([40, 40, 40], [["a", "b", "c"]], headerRule: false)
    let grid = cjguiComposableGrid(2000, "table", spec, CjguiComposableUiStyle(),
        CjguiComposableUiStyle(), CjguiComposableUiStyle(), CjguiComposableUiStyle())
    let row = grid.children()[0].children()
    // 3 cells + exactly 2 separators: n columns need n-1 boundaries, never 2*(n-1)
    @Assert(row.size, 5)
    @Assert(row[1].nodeId, spec.separatorNodeId(2000, 0, 0))
    @Assert(row[3].nodeId, spec.separatorNodeId(2000, 0, 1))
    @Assert(row[1].style.fixedWidth, spec.separatorWidth)
}

@Test
func testGridCanOmitTheHeaderRule(): Unit {
    let spec = CjguiGridSpec([40], [["a"]], headerRule: false)
    let grid = cjguiComposableGrid(3000, "table", spec, CjguiComposableUiStyle(),
        CjguiComposableUiStyle(), CjguiComposableUiStyle(), CjguiComposableUiStyle())
    @Assert(grid.children().size, 1)
}

// A style field that is accepted and then silently discarded is worse than one that is refused:
// the grid used to drop the caller's height constraints, so a minHeight never reached the layout.
@Test
func testGridForwardsTheCallersHeightConstraints(): Unit {
    let spec = CjguiGridSpec([40, 40], [["a", "b"], ["c", "d"]], cellPadding: 4, separatorWidth: 1,
        headerRule: false, headerRuleHeight: 0)
    let node = cjguiComposableGrid(7001, "grid-height-contract", spec,
        CjguiComposableUiStyle(minHeight: 123, idealHeight: 456, maxHeight: 789),
        CjguiComposableUiStyle(), CjguiComposableUiStyle(), CjguiComposableUiStyle())
    @Assert(node.style.minHeight, 123)
    @Assert(node.style.idealHeight, 456)
    @Assert(node.style.maxHeight, 789)
}
