package cjgui

import std.collection.*
import std.overflow.*

// Private inputs for one existing prepared scene. Business declarations are
// read once, before yielding; a retry may only query the bounded copied rows.
// This is not a second operation/commit channel: acceptance promotes only the
// list's derivative geometry through the window's existing scene transaction.
class CjguiPreparedListData <: CjguiComposableUiVariableHeightListSource {
    let originalFixed: ?CjguiComposableUiVirtualListSource
    let originalVariable: ?CjguiComposableUiVariableHeightListSource
    let count: Int64
    let generation: Int64
    let indices = ArrayList<Int64>()
    let items = ArrayList<CjguiComposableUiVariableHeightListItem>()
    let keys = ArrayList<String>()
    let keyIndices = ArrayList<Int64>()
    let rowIndices = ArrayList<Int64>()
    let rows = ArrayList<CjguiComposableUiNode>()
    var contentId: Int64 = -1
    var sealed: Bool = false
    init(node: CjguiComposableUiNode) {
        originalFixed = node.virtualListSource()
        originalVariable = node.variableHeightListSource()
        count = if (let Some(source) <- originalVariable) { source.itemCount() }
            else if (let Some(source) <- originalFixed) { source.itemCount() } else { 0 }
        generation = if (let Some(source) <- originalVariable) { source.measurementGeneration() } else { 0 }
        contentId = node.virtualListContentNodeId()
    }
    public func itemCount(): Int64 { return count }
    public func measurementGeneration(): Int64 { return generation }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= count) { return CjguiComposableUiVariableHeightListItem.missing() }
        for (i in 0..indices.size) { if (indices[i] == index) { return items[i] } }
        if (sealed) { throw CjguiLayoutPreparationFailure("layout_frozen_item_range_${index}") }
        let item = if (let Some(source) <- originalVariable) { source.itemAt(index) }
            else if (let Some(source) <- originalFixed) {
                let value = source.itemAt(index)
                CjguiComposableUiVariableHeightListItem(value.key, value.resourceId, value.title, 0)
            } else { CjguiComposableUiVariableHeightListItem.missing() }
        indices.add(index); items.add(item)
        return item
    }
    public func indexForKey(key: String): Int64 {
        if (key.isEmpty()) { return -1 }
        for (i in 0..keys.size) { if (keys[i] == key) { return keyIndices[i] } }
        if (sealed) { throw CjguiLayoutPreparationFailure("layout_frozen_key_range") }
        let index = if (let Some(source) <- originalVariable) { source.indexForKey(key) }
            else if (let Some(source) <- originalFixed) { source.indexForKey(key) } else { -1 }
        keys.add(key); keyIndices.add(index)
        return index
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem,
        isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        let index = indexForKey(item.key)
        for (i in 0..rowIndices.size) {
            if (rowIndices[i] == index) { return rows[i].cloneForWindowCandidate(preservePreparedLayout: true) }
        }
        throw CjguiLayoutPreparationFailure("layout_frozen_row_range")
    }
    func captureRow(index: Int64, node: CjguiComposableUiNode, state: CjguiComposableUiVirtualListState,
        width: Int64, height: Int64, registry: CjguiComposableUiIdentityRegistry,
        totals: ArrayList<Int64>, depth: Int64): Int64 {
        for (i in 0..rowIndices.size) { if (rowIndices[i] == index) { return rowMinimum(rows[i]) } }
        let item = itemAt(index)
        if (item.key.isEmpty() || indexForKey(item.key) != index) { return node.virtualListRowHeight() }
        if (rows.size >= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS) {
            throw CjguiLayoutPreparationFailure("layout_frozen_row_capacity")
        }
        let declared = if (let Some(source) <- originalVariable) {
            source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
        } else if (let Some(source) <- originalFixed) {
            source.buildRow(CjguiComposableUiVirtualListItem(item.key, item.resourceId, item.title),
                item.key == state.selectedKey(), item.key == state.focusedKey())
        } else { throw CjguiLayoutPreparationFailure("layout_frozen_source_missing") }
        // Resolve each application's dynamic declaration once, never again in
        // a pure layout slice. The ordinary registry retains collision checks.
        let issue = registry.resolveDynamicNode(declared)
        if (!issue.isEmpty()) { throw CjguiLayoutPreparationFailure(issue) }
        let row = declared.cloneForWindowCandidate()
        row.preparedIdentityResolved = true
        cjguiFreezePreparedLayoutNode(row, width, height, registry, totals, depth + 1)
        rowIndices.add(index); rows.add(row)
        return rowMinimum(row)
    }
    private func rowMinimum(row: CjguiComposableUiNode): Int64 {
        if (row.style.fixedHeight > 0) { return row.style.fixedHeight }
        return if (row.style.minHeight > 0) { row.style.minHeight } else { 1 }
    }
    func capture(node: CjguiComposableUiNode, basis: CjguiComposableUiVirtualListState,
        width: Int64, height: Int64, registry: CjguiComposableUiIdentityRegistry,
        totals: ArrayList<Int64>, depth: Int64): Unit {
        // Sparse corrections and durable input keys are resolved in this one
        // owner phase; no source lookups occur in a later measurement slice.
        let requiredKeys = basis.preparedLayoutCacheKeys()
        requiredKeys.add(basis.selectedKey()); requiredKeys.add(basis.focusedKey()); requiredKeys.add(basis.anchorKey())
        for (key in requiredKeys) {
            let index = indexForKey(key)
            if (index >= 0 && index < count) { let _ = itemAt(index) }
        }
        let bound = if (node.style.fixedHeight > 0) { node.style.fixedHeight }
            else { cjguiPreparedMaximum(height, cjguiPreparedMaximum(node.style.minHeight, node.style.idealHeight)) }
        let innerHeight = cjguiPreparedMaximum(1, bound - node.style.padding * 2)
        let fixedAdapter = CjguiPreparedFixedListSource(this)
        // One probe keeps sparse corrections, the other models a width/cache
        // invalidation. Height 1 covers bottom-clamp movement on a shorter slot.
        for (invalidate in [false, true]) {
            for (probeHeight in [1, innerHeight]) {
                let probe = basis.preparedLayoutCopy()
                if (let Some(viewport) <- node.scrollViewport) { probe.adoptSharedViewportRequest(viewport) }
                if (originalVariable.isSome()) {
                    if (invalidate) { probe.prepareVariableMeasurementContext(this, -1) }
                    let _ = probe.updateVariableMaterializedRange(this, node.virtualListRowHeight(),
                        node.virtualListRowGap(), probeHeight, node.virtualListOverscan())
                } else {
                    let _ = probe.updateMaterializedRange(fixedAdapter, node.virtualListRowHeight(),
                        node.virtualListRowGap(), probeHeight, node.virtualListOverscan())
                }
                let start = probe.materializedStart()
                var index = start
                var lowerCovered: Int64 = 0
                var after: Int64 = 0
                while (index < count && index - start < CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
                    (index < probe.materializedEnd().saturatingAdd(node.virtualListOverscan()) || lowerCovered < innerHeight + node.virtualListRowHeight() ||
                     after < node.virtualListOverscan())) {
                    let lower = captureRow(index, node, basis, width, height, registry, totals, depth)
                    if (lowerCovered >= innerHeight + node.virtualListRowHeight()) { after += 1 }
                    lowerCovered = lowerCovered.saturatingAdd(if (originalVariable.isSome()) { lower } else { node.virtualListRowHeight() })
                        .saturatingAdd(node.virtualListRowGap())
                    index += 1
                }
            }
        }
        if (originalVariable.isSome()) {
            let retained = basis.retainedVariableCaptureIndex(this)
            if (retained >= 0) { let _ = captureRow(retained, node, basis, width, height, registry, totals, depth) }
        }
        // Fixed lists without a declared content template create one scoped
        // identity. Resolve it once now; pure passes carry its resulting ID.
        if (originalFixed.isSome() && contentId < 0) {
            if (let Some(identity) <- node.scopedIdentity()) {
                let content = CjguiComposableUiNode(contentId, "${node.semanticId}_materialized",
                    CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, CjguiComposableUiStyle(),
                    identity: Some(identity.materializedContentIdentity()))
                let issue = registry.resolveDynamicNode(content)
                if (!issue.isEmpty()) { throw CjguiLayoutPreparationFailure(issue) }
                contentId = content.nodeId
            }
        }
        sealed = true
    }
    func matches(): Bool {
        if (let Some(source) <- originalVariable) {
            if (source.itemCount() != count || source.measurementGeneration() != generation) { return false }
        } else if (let Some(source) <- originalFixed) { if (source.itemCount() != count) { return false } }
        for (row in rows) { if (!row.preparedLayoutInputsMatch()) { return false } }
        return true
    }
}

private class CjguiPreparedFixedListSource <: CjguiComposableUiVirtualListSource {
    let data: CjguiPreparedListData
    init(data: CjguiPreparedListData) { this.data = data }
    public func itemCount(): Int64 { return data.count }
    public func indexForKey(key: String): Int64 { return data.indexForKey(key) }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        let item = data.itemAt(index)
        return CjguiComposableUiVirtualListItem(item.key, item.resourceId, item.title)
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, selected: Bool, focused: Bool): CjguiComposableUiNode {
        return data.buildRow(CjguiComposableUiVariableHeightListItem(item.key, item.resourceId, item.title, 0), selected, focused)
    }
}

class CjguiPreparedLayoutInputs {
    // Candidate-local derived intrinsic sizes. An incomplete calculation never
    // enters this bounded map, and a different candidate starts empty.
    private let intrinsicHeights = HashMap<Int64, Int64>()
    var intrinsicHeightStable: Bool = false
    func cachedIntrinsicHeight(width: Int64): ?Int64 {
        return if (intrinsicHeightStable) { intrinsicHeights.get(width) } else { None }
    }
    func rememberIntrinsicHeight(width: Int64, height: Int64): Unit {
        if (!intrinsicHeightStable) { return }
        if (intrinsicHeights.size >= 4) { intrinsicHeights.clear() }
        let _ = intrinsicHeights.add(width, height)
    }
    func intrinsicHeightEntryCount(): Int64 { return intrinsicHeights.size }
    let original: CjguiComposableUiNode
    let frozenStyle: CjguiComposableUiStyle
    let splitFirst: Int64
    let splitRevision: Int64
    let tabsKey: String
    let originalState: ?CjguiComposableUiVirtualListState
    let basisState: ?CjguiComposableUiVirtualListState
    let workingState: ?CjguiComposableUiVirtualListState
    let list: ?CjguiPreparedListData
    let fixedSource: ?CjguiComposableUiVirtualListSource
    let variableSource: ?CjguiComposableUiVariableHeightListSource
    let viewportIdentity: Int64
    let viewportGeneration: Int64
    let viewportOffset: Int64
    init(node: CjguiComposableUiNode, frozenStyle: CjguiComposableUiStyle, list: ?CjguiPreparedListData) {
        original = node; this.frozenStyle = frozenStyle; this.list = list
        originalState = node.virtualListState()
        basisState = if (let Some(state) <- originalState) { Some(state.preparedLayoutCopy()) } else { None }
        workingState = if (let Some(state) <- basisState) { Some(state.preparedLayoutCopy()) } else { None }
        splitFirst = if (let Some(state) <- node.splitState) { state.firstSize() } else { node.splitFirstSize() }
        splitRevision = if (let Some(state) <- node.splitState) { state.captureRevision() } else { 0 }
        tabsKey = if (let Some(state) <- node.tabsState) { state.activeKey() } else { "" }
        fixedSource = if (node.virtualListSource().isSome() && list.isSome()) { Some(CjguiPreparedFixedListSource(list.getOrThrow())) } else { None }
        variableSource = if (node.variableHeightListSource().isSome() && list.isSome()) { Some(list.getOrThrow()) } else { None }
        viewportIdentity = if (let Some(viewport) <- node.scrollViewport) { viewport.viewStateIdentity() } else { -1 }
        viewportGeneration = if (let Some(viewport) <- node.scrollViewport) { viewport.requestGeneration() } else { -1 }
        viewportOffset = if (let Some(viewport) <- node.scrollViewport) { viewport.offset() } else { node.scrollOffset }
    }
    func copyForPass(): CjguiPreparedLayoutInputs {
        // The original object is only a guard/acceptance target. All solver
        // inputs below are copied from the frozen basis, not sampled again.
        return CjguiPreparedLayoutInputs(this)
    }
    private init(other: CjguiPreparedLayoutInputs) {
        original = other.original; frozenStyle = other.frozenStyle
        intrinsicHeightStable = other.intrinsicHeightStable
        splitFirst = other.splitFirst; splitRevision = other.splitRevision; tabsKey = other.tabsKey
        originalState = other.originalState; basisState = other.basisState
        workingState = if (let Some(state) <- basisState) { Some(state.preparedLayoutCopy()) } else { None }
        list = other.list; fixedSource = other.fixedSource; variableSource = other.variableSource
        viewportIdentity = other.viewportIdentity; viewportGeneration = other.viewportGeneration; viewportOffset = other.viewportOffset
    }
    func matches(): Bool {
        if (let Some(state) <- originalState) {
            if (!state.preparedLayoutBasisMatches(basisState.getOrThrow())) { return false }
        }
        if (let Some(state) <- original.splitState) {
            if (state.captureRevision() != splitRevision || state.firstSize() != splitFirst) { return false }
        }
        if (let Some(state) <- original.tabsState) { if (state.activeKey() != tabsKey) { return false } }
        if (let Some(viewport) <- original.scrollViewport) {
            if (viewport.requestGeneration() != viewportGeneration || viewport.offset() != viewportOffset) { return false }
        }
        if (let Some(data) <- list) { if (!data.matches()) { return false } }
        if (let Some(old) <- original.style.gradient) {
            let frozen = frozenStyle.gradient.getOrThrow()
            for (i in 0..old.stops.size) {
                let a = old.stops[i]; let b = frozen.stops[i]
                if (a.position != b.position || a.color.red != b.color.red || a.color.green != b.color.green ||
                    a.color.blue != b.color.blue || a.color.alpha != b.color.alpha) { return false }
            }
        }
        return true
    }
    func accept(): Unit {
        if (let Some(state) <- originalState) { state.acceptPreparedLayout(workingState.getOrThrow()) }
    }
}

func cjguiFreezePreparedLayoutInputs(root: CjguiComposableUiNode, width: Int64, height: Int64,
    registry: CjguiComposableUiIdentityRegistry): Unit {
    cjguiFreezePreparedLayoutNode(root, width, height, registry, ArrayList<Int64>([0, 0]), 0)
}

private func cjguiFreezePreparedLayoutNode(node: CjguiComposableUiNode, width: Int64, height: Int64,
    registry: CjguiComposableUiIdentityRegistry, totals: ArrayList<Int64>, depth: Int64): Unit {
    totals[0] += 1
    totals[1] += node.value.size + node.label.size + node.semanticId.size + node.textStyleRuns.size * 160
    if (depth > 64 || totals[0] > 1024 || totals[1] > 1048576 || node.style.effectGroup.isSome()) {
        throw CjguiLayoutPreparationFailure("layout_frozen_input_capacity_or_effect")
    }
    let base = node.style
    let gradient: ?CjguiComposableUiLinearGradient = if (let Some(value) <- base.gradient) {
        Some(CjguiComposableUiLinearGradient(startX: value.startX, startY: value.startY, endX: value.endX,
            endY: value.endY, stops: Array<CjguiComposableUiGradientStop>(value.stops.size, {i => value.stops[i]})))
    } else { None }
    let style = if (gradient.isSome()) { cjguiComposableUiStyleWithPaint(base, base.background, base.border,
        base.textColor, base.borderWidth, base.shadow, gradient, base.effectGroup) } else { base }
    let list: ?CjguiPreparedListData = if (node.virtualListSource().isSome() || node.variableHeightListSource().isSome()) {
        Some(CjguiPreparedListData(node))
    } else { None }
    node.preparedLayoutInputs = Some(CjguiPreparedLayoutInputs(node, style, list))
    for (child in node.children()) { cjguiFreezePreparedLayoutNode(child, width, height, registry, totals, depth + 1) }
    if (let Some(data) <- list) {
        let state = node.virtualListState().getOrThrow()
        data.capture(node, state, width, height, registry, totals, depth)
    }
    // Do not memoize a height that can depend on mutable materialization.
    // A fixed-height child is already an immutable contribution to its parent.
    var stableHeight = list.isNone()
    for (child in node.children()) {
        if (child.style.fixedHeight <= 0 &&
            (child.preparedLayoutInputs.isNone() || !child.preparedLayoutInputs.getOrThrow().intrinsicHeightStable)) {
            stableHeight = false
        }
    }
    node.preparedLayoutInputs.getOrThrow().intrinsicHeightStable = stableHeight
}

private func cjguiPreparedMaximum(a: Int64, b: Int64): Int64 { return if (a > b) { a } else { b } }
