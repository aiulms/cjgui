package cjgui

import std.collection.*
import std.time.*

/// Scale fixture for the variable-height index. Its direct key map is source
/// metadata, built separately from a sample; `itemAt` never constructs a row
/// body. The measured body exists only in `buildRow` for the current range.
private class VariableHeightScaleSource <: CjguiComposableUiVariableHeightListSource {
    private let countValue: Int64
    private let indexes: HashMap<String, Int64>
    private var changedStart: Int64
    private var changedEnd: Int64
    private var itemReadsValue: Int64
    private var buildsValue: Int64

    init(count: Int64) {
        this.countValue = count; this.indexes = HashMap<String, Int64>()
        this.changedStart = -1; this.changedEnd = -1; this.itemReadsValue = 0; this.buildsValue = 0
        var index: Int64 = 0
        while (index < count) { let _ = indexes.add("scale_${index}", index); index += 1 }
    }
    public func itemCount(): Int64 { return countValue }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        itemReadsValue += 1
        if (index < 0 || index >= countValue) { return CjguiComposableUiVariableHeightListItem.missing() }
        let changed = index >= changedStart && index < changedEnd
        let longForm = index % 5 == 0 || changed
        return CjguiComposableUiVariableHeightListItem("scale_${index}", 990000 + index, "缩放条目 ${index}",
            if (changed) { 2 } else { 1 }, estimatedHeight: if (changed) { 140 } else if (longForm) { 88 } else { 34 })
    }
    public func indexForKey(key: String): Int64 {
        if (let Some(index) <- indexes.get(key)) { return index }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        buildsValue += 1
        let index = indexForKey(item.key)
        let changed = index >= changedStart && index < changedEnd
        let row = cjguiComposableVertical(9000000 + item.resourceId, "scale-row-${item.key}",
            CjguiComposableUiStyle(padding: 4, gap: 2, background: if (isSelected || isFocused) {
                CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0)
            } else { CjguiComposableUiColor(0.98, 0.98, 0.99, 1.0) }))
        row.add(cjguiComposableText(9100000 + item.resourceId, "scale-title-${item.key}", item.title,
            CjguiComposableUiStyle(fontWeight: 1)))
        row.add(cjguiComposableText(9200000 + item.resourceId, "scale-summary-${item.key}",
            if (index % 5 == 0 || changed) {
                "此普通文本摘要依据可用列宽换行；它只会在当前可见范围被构造和测量。"
            } else { "短摘要" }, CjguiComposableUiStyle(fontSize: 12.0)))
        return row
    }
    func mutateOne(index: Int64): Unit { changedStart = index; changedEnd = index + 1 }
    func mutateScreenOffBatch(start: Int64, length: Int64): Unit {
        changedStart = start; changedEnd = if (start + length < countValue) { start + length } else { countValue }
    }
    func resetObservations(): Unit { itemReadsValue = 0; buildsValue = 0 }
    func itemReads(): Int64 { return itemReadsValue }
    func builds(): Int64 { return buildsValue }
}

private func layoutScale(root: CjguiComposableUiNode, width: Int64, version: Int64): CjguiComposableUiLayoutResult {
    return CjguiComposableUiLayoutEngine.layoutWithMetrics(root, CjguiComposableUiRect(0, 0, width, 132), version,
        CjguiComposableUiFallbackTextMeasurer())
}

private func emitSample(count: Int64, kind: String, ordinal: Int64): Unit {
    let setupStarted = MonoTime.now()
    let source = VariableHeightScaleSource(count)
    let setupMs = (MonoTime.now() - setupStarted).toMilliseconds()
    let state = CjguiComposableUiVirtualListState()
    let root = cjguiComposableVertical(1, "scale-root", CjguiComposableUiStyle())
    root.add(cjguiComposableVariableHeightList(2, "scale-scroll", 3, source, state, 34, 3, 2,
        CjguiComposableUiStyle(fixedHeight: 132)))
    var version: Int64 = ordinal * 10
    var result: CjguiComposableUiLayoutResult
    let sampleStarted = MonoTime.now()
    if (kind == "cold_startup") {
        result = layoutScale(root, 168, version)
    } else {
        let _ = layoutScale(root, 168, version)
        source.resetObservations(); version += 1
        if (kind == "warm_back_and_forth") {
            let _ = state.revealKey(source, "scale_${count * 3 / 4}")
            let _ = layoutScale(root, 168, version); version += 1
            let _ = state.revealKey(source, "scale_1")
            result = layoutScale(root, 168, version)
        } else if (kind == "single_row_change") {
            source.mutateOne(0)
            result = layoutScale(root, 168, version)
        } else if (kind == "screen_off_batch") {
            source.mutateScreenOffBatch(count * 3 / 4, 32)
            result = layoutScale(root, 168, version)
        } else {
            let _ = layoutScale(root, 320, version); version += 1
            source.resetObservations()
            result = layoutScale(root, 168, version)
        }
    }
    let elapsedMs = (MonoTime.now() - sampleStarted).toMilliseconds()
    println("CJGUI_VARIABLE_HEIGHT_SAMPLE count=${count} kind=${kind} ordinal=${ordinal} setup_ms=${setupMs} elapsed_ms=${elapsedMs} item_reads=${source.itemReads()} row_builds=${source.builds()} measurements=${result.metrics.measurerCallCount} materialized=${state.materializedEnd() - state.materializedStart()} scene_nodes=${result.scene.nodes().size}")
}

main(): Int64 {
    for (count in ArrayList<Int64>([1000, 10000])) {
        for (kind in ArrayList<String>(["cold_startup", "warm_back_and_forth", "single_row_change", "screen_off_batch", "width_invalidation"])) {
            var ordinal: Int64 = 0
            while (ordinal < 30) { emitSample(count, kind, ordinal); ordinal += 1 }
        }
    }
    println("composable variable-height scale probe: passed samples_per_case=30")
    return 0
}
