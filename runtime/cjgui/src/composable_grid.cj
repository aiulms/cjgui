// A grid composition helper (Astra's `cjguiComposableGrid` / `CjguiGridSpec`).
//
// WHY THIS EXISTS
// A table rendered by padding a single text node can never align: with a proportional UI
// font the real glyph advance differs from any column count, so the right-hand separators
// drift (measured: ~6 px between two rows whose cells held "3" and "12"). Real cells need
// real layout. This helper builds a grid from ordinary containers and text nodes -- no new
// native type -- and it makes the ONE thing that a table cannot get wrong explicit:
// **every cell in a column uses the SAME resolved width**, handed down from the spec
// rather than measured per row. A per-row measurement is what makes a table look ragged.
//
// Each internal boundary is drawn by exactly ONE node, so adjacent cells never double
// their border. Cells own their text; separator and rule nodes are decoration and carry
// no interaction, so they never enter text navigation or take focus.
package cjgui

import std.collection.*

/// Shared geometry and content of one grid. Column widths are RESOLVED once by the
/// caller; a cell never measures itself into the layout.
public class CjguiGridSpec {
    /// One width in logical points per column. Every cell of that column uses it.
    public let columns: Array<Int64>
    /// Row-major cell texts. A short row is padded with empty cells, so every row has a
    /// rectangle for every column even when the content is ragged.
    public let rows: Array<Array<String>>
    public let cellPadding: Int64
    public let separatorWidth: Int64
    /// Draw one rule under the first row: the header separator. Drawn once, not per cell.
    public let headerRule: Bool
    public let headerRuleHeight: Int64

    public init(columns: Array<Int64>, rows: Array<Array<String>>, cellPadding!: Int64 = 6,
        separatorWidth!: Int64 = 1, headerRule!: Bool = true, headerRuleHeight!: Int64 = 1) {
        this.columns = columns
        this.rows = rows
        this.cellPadding = cellPadding
        this.separatorWidth = separatorWidth
        this.headerRule = headerRule
        this.headerRuleHeight = headerRuleHeight
    }

    /// Node ids are derived from the grid's base id so a caller can address a cell:
    /// row r is `nodeId + 1 + r * rowStride`, cell (r, c) is `rowId + 1 + 2 * c`, and the
    /// separator after column c is `rowId + 2 + 2 * c`.
    public func rowStride(): Int64 {
        return 2 * Int64(this.columns.size) + 2
    }

    public func rowNodeId(gridNodeId: Int64, row: Int64): Int64 {
        return gridNodeId + 1 + row * this.rowStride()
    }

    public func cellNodeId(gridNodeId: Int64, row: Int64, column: Int64): Int64 {
        return this.rowNodeId(gridNodeId, row) + 1 + 2 * column
    }

    public func separatorNodeId(gridNodeId: Int64, row: Int64, column: Int64): Int64 {
        return this.rowNodeId(gridNodeId, row) + 2 + 2 * column
    }

    public func headerRuleNodeId(gridNodeId: Int64): Int64 {
        return gridNodeId + 1 + Int64(this.rows.size) * this.rowStride()
    }
}

/// Compose a grid for `spec`. The root is a vertical container; each row is a horizontal
/// container of fixed-width cells with one separator node between neighbours.
///
/// Derived node styles are built explicitly (the style type is immutable and has no
/// builder methods), so the grid never mutates a caller's style.
/// `caretNodeId`/`caretOffset` place a caret run inside ONE cell: a cell is its own text
/// node, so the product's fragment-level caret drawing cannot reach it. Passing the caret
/// through the composition keeps the caret geometry in the framework's text pipeline
/// instead of inventing a second drawing path. An EMPTY cell has no character to mark, so
/// it gets no caret yet (that needs an insertion rectangle, not a run).
public func cjguiComposableGrid(nodeId: Int64, semanticId: String, spec: CjguiGridSpec,
    style: CjguiComposableUiStyle, cellStyle: CjguiComposableUiStyle,
    separatorStyle: CjguiComposableUiStyle, ruleStyle: CjguiComposableUiStyle,
    caretNodeId!: Int64 = -1, caretOffset!: Int64 = -1,
    caretColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)): CjguiComposableUiNode {
    // The grid and its rows must be as wide as the columns actually are: a container
    // measured only from its own content came out 24pt wide, so the header rule (added to
    // the grid) spanned just the first column instead of the table.
    var totalWidth: Int64 = 0
    var widthIndex: Int64 = 0
    while (widthIndex < Int64(spec.columns.size)) {
        totalWidth += spec.columns[widthIndex]
        widthIndex += 1
    }
    if (Int64(spec.columns.size) > 1) {
        totalWidth += (Int64(spec.columns.size) - 1) * spec.separatorWidth
    }
    // Height is part of the style CONTRACT: the caller's min/ideal/max heights used to be dropped
    // here, so `cjguiComposableGrid(..., style: CjguiComposableUiStyle(minHeight: N))` silently
    // ignored N and a parent could shrink the whole grid to 0 (measured: every grid node h=0 while
    // the same grid was 76pt tall in another layout). Forwarding them does not by itself protect
    // content in a non-scrolling parent -- that needs an explicit overflow policy -- but a style
    // field that is accepted and then discarded is worse than one that is refused.
    let grid = cjguiComposableVertical(nodeId, semanticId,
        CjguiComposableUiStyle(background: style.background, padding: style.padding,
            fixedWidth: totalWidth, alignX: style.alignX, alignY: style.alignY,
            minHeight: style.minHeight, idealHeight: style.idealHeight,
            maxHeight: style.maxHeight))
    let columns = Int64(spec.columns.size)
    var rowIndex: Int64 = 0
    while (rowIndex < Int64(spec.rows.size)) {
        let rowNode = cjguiComposableHorizontal(spec.rowNodeId(nodeId, rowIndex),
            "${semanticId}-row-${rowIndex}",
            CjguiComposableUiStyle(background: style.background, fixedWidth: totalWidth,
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_START,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
        var column: Int64 = 0
        while (column < columns) {
            let cellText = if (column < Int64(spec.rows[rowIndex].size)) {
                spec.rows[rowIndex][column]
            } else {
                ""
            }
            // The width comes from the SPEC, never from this cell's own text: that is what
            // keeps every row of a column aligned.
            let cellNodeId = spec.cellNodeId(nodeId, rowIndex, column)
            let cellRuns = ArrayList<CjguiComposableUiTextStyleRun>()
            var displayCellText = cellText
            if (cellNodeId == caretNodeId && caretOffset >= 0) {
                // The caret offset is in DISPLAY BYTES (the renderer consumes UTF-8 byte
                // ranges), so the run must cover the whole character at that offset --
                // not one byte. A CJK first character collapsed to an empty range and was
                // dropped, so a cell caret never appeared.
                let bytes = cellText.toArray()
                if (Int64(bytes.size) == 0) {
                    // An EMPTY cell has no character for a run to mark, so an insertion
                    // caret there needs a real rectangle. Painting one run over a single
                    // synthetic space gives the same visible result with existing
                    // primitives; the column width still comes from the spec, so giving
                    // this cell a space cannot shift the table.
                    displayCellText = " "
                    cellRuns.add(CjguiComposableUiTextStyleRun(0, 1,
                        cellStyle.fontSize, cellStyle.fontWeight, cellStyle.fontFamily,
                        0.0, 0.0, 0.0, 1.0, hasBackground: true,
                        backgroundRed: caretColor.red, backgroundGreen: caretColor.green,
                        backgroundBlue: caretColor.blue, backgroundAlpha: 1.0))
                } else if (caretOffset < Int64(bytes.size)) {
                    var byteStart = caretOffset
                    while (byteStart > 0 && (bytes[byteStart] & 0xC0) == 0x80) {
                        byteStart -= 1
                    }
                    var byteEnd = byteStart + 1
                    while (byteEnd < Int64(bytes.size) && (bytes[byteEnd] & 0xC0) == 0x80) {
                        byteEnd += 1
                    }
                    cellRuns.add(CjguiComposableUiTextStyleRun(byteStart, byteEnd,
                        cellStyle.fontSize, cellStyle.fontWeight, cellStyle.fontFamily,
                        0.0, 0.0, 0.0, 1.0, hasBackground: true,
                        backgroundRed: caretColor.red, backgroundGreen: caretColor.green,
                        backgroundBlue: caretColor.blue, backgroundAlpha: 1.0))
                }
            }
            rowNode.add(cjguiComposableText(cellNodeId,
                "${semanticId}-cell-${rowIndex}-${column}", displayCellText,
                // A cell IS interactive (it must receive pointer events so a click can be
                // bound to a source anchor); separator and rule nodes below are NOT, so
                // decoration never takes focus or joins text navigation.
                CjguiComposableUiStyle(background: cellStyle.background, textColor: cellStyle.textColor,
                    padding: spec.cellPadding, fixedWidth: spec.columns[column],
                    fontSize: cellStyle.fontSize, fontWeight: cellStyle.fontWeight,
                    fontFamily: cellStyle.fontFamily, minHeight: cellStyle.minHeight,
                    alignX: cellStyle.alignX, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
                    pointerInteractive: true), textStyleRuns: cellRuns.toArray()))
            if (column < columns - 1) {
                // ONE node per internal boundary: neighbouring cells never both draw it.
                rowNode.add(cjguiComposableVertical(spec.separatorNodeId(nodeId, rowIndex, column),
                    "${semanticId}-sep-${rowIndex}-${column}",
                    CjguiComposableUiStyle(background: separatorStyle.background,
                        fixedWidth: spec.separatorWidth, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
            }
            column += 1
        }
        grid.add(rowNode)
        if (rowIndex == 0 && spec.headerRule) {
            grid.add(cjguiComposableHorizontal(spec.headerRuleNodeId(nodeId), "${semanticId}-header-rule",
                CjguiComposableUiStyle(background: ruleStyle.background, fixedWidth: totalWidth,
                    fixedHeight: spec.headerRuleHeight)))
        }
        rowIndex += 1
    }
    return grid
}
