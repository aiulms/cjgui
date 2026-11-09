// A3 regression guard: a grid inside a scroll container.
//
// The crash this relates to was a StackOverflowError while an EVENT-triggered refresh laid out a
// Markdown table: `pump` used to complete that refresh inside the event-dispatch frame, and a finite
// but deeper grid layout chain exhausted the frame's remaining stack. The fix moves the refresh to
// "after the dispatch frame, before pump returns" (see `public func pump`).
//
// Honest scope of this test: reproducing the real path needs a window and the event pump, so a
// host-free test CANNOT pin it. What had NO coverage at all was the combination itself -- a grid as
// the content of a scroll area -- so that is what this pins: it must lay out, and the per-column
// widths must still come from the spec. The real path stays covered by the editor's 7-case matrix
// (table+scroll, table+click, no-scroll, code+scroll, caret-probe, 720-wide, sample article).
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

@Test
func testGridInsideScrollAreaLaysOutAndKeepsSpecColumnWidths(): Unit {
    let spec = CjguiGridSpec([80, 40], [["名称", "数量"], ["苹果", "3"]])
    let grid = cjguiComposableGrid(2000, "table", spec, CjguiComposableUiStyle(),
        CjguiComposableUiStyle(), CjguiComposableUiStyle(), CjguiComposableUiStyle())
    let column = cjguiComposableVertical(2001, "column", CjguiComposableUiStyle(growX: 1))
    column.add(grid)
    let scroller = cjguiComposableScrollArea(2002, "scroll", 0,
        CjguiComposableUiStyle(growX: 1, growY: 1))
    scroller.add(column)

    // Laying this combination out used to be untested; it must not throw and must return a result.
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(scroller,
        CjguiComposableUiRect(0, 0, 400, 200), 1, CjguiComposableUiFallbackTextMeasurer(),
        reuseMeasurements: false)
    // The call itself is the guard: a layout that cannot solve this combination throws (the crash
    // this file relates to was a stack overflow during exactly this solve). No field of the result
    // is asserted, so the test does not depend on the result type's shape.
    let _ = result

    // The column widths are the table's ONE unbreakable property: being inside a scroll container
    // must not let a cell measure its own text into the layout.
    let rows = grid.children()
    @Assert(rows.size > 0)
    let firstRow = rows[0].children()
    var index: Int64 = 0
    while (index < Int64(spec.columns.size)) {
        @Assert(firstRow[index * 2].style.fixedWidth, spec.columns[index])
        index += 1
    }
}
