// MODEL MICRO-BENCHMARKS for the tree projection/selection value model at
// 100 / 1,000 / 10,000 logical nodes. The `model_*` labels say what these are:
// direct value-model operations (cold index, bulk expand/collapse, select-all,
// rowAt lookups). They are NOT the production path - the real scroll,
// materialization, row construction and generated/handwritten build+layout
// costs live in composable_ui_generated_perf_test.cj. Timings are reported per
// operation (not divided out of a whole-case number); correctness assertions
// run outside the timed regions.
package cjgui

import std.collection.*
import std.time.*
import std.fs.*

class TreePerfSource <: CjguiComposableUiTreeDataSource {
    let groups: Int64
    let leavesPerGroup: Int64
    var childAtCalls: Int64 = 0

    init(groups: Int64, leavesPerGroup: Int64) {
        this.groups = groups
        this.leavesPerGroup = leavesPerGroup
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return groups }
        if (parentKey.startsWith("group-")) { return leavesPerGroup }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        childAtCalls += 1
        if (parentKey.isEmpty()) {
            return CjguiComposableUiTreeNode("group-${index}", "组 ${index}", 100 + index, true, selectable: false)
        }
        return CjguiComposableUiTreeNode("${parentKey}-leaf-${index}", "叶 ${index}", 200 + index,
            false, selectable: true)
    }
}

// The test harness owns stdout, so samples accumulate here and are flushed to
// a fixed evidence file (overwrite) after each sample group.
let treePerfLines = ArrayList<String>()

func reportElapsed(label: String, started: MonoTime): Unit {
    let micros = (MonoTime.now() - started).toMicroseconds()
    treePerfLines.add("TREE_PERF ${label} micros=${micros}")
    flushTreePerf()
}

/// Warms up the projection/selection paths with one throwaway run so the
/// first timed sample is not dominated by first-call effects.
func warmTreePerf(groups: Int64, leaves: Int64): Unit {
    let source = TreePerfSource(groups, leaves)
    let projection = CjguiComposableUiTreeProjection(source)
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    let selection = CjguiComposableUiTreeSelection(projection)
    selection.selectAllVisible()
    var index: Int64 = 0
    while (index < projection.rowCount()) {
        let _ = projection.rowAt(index).key
        index += 1
    }
}

func flushTreePerf(): Unit {
    let builder = StringBuilder()
    for (line in treePerfLines) {
        builder.append(line)
        builder.append("\n")
    }
    try {
        File.writeTo("/private/tmp/cjgui-tree-perf.log", builder.toString().toArray())
    } catch (error: Exception) {
        // Evidence file is best-effort; assertions do not depend on it.
    }
}

/// Flat virtual-list baseline: the same viewport iteration over the existing
/// fixed-row list source, so tree costs can be compared against the engine the
/// tree reuses.
class TreePerfFlatSource <: CjguiComposableUiVirtualListSource {
    let count: Int64
    var itemAtCalls: Int64 = 0

    init(count: Int64) {
        this.count = count
    }

    public func itemCount(): Int64 {
        return count
    }

    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        itemAtCalls += 1
        return CjguiComposableUiVirtualListItem("flat-${index}", index, "flat ${index}")
    }

    public func indexForKey(key: String): Int64 {
        if (key.startsWith("flat-")) {
            return 0
        }
        return -1
    }

    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(1, "flat-row", item.title, CjguiComposableUiStyle())
    }
}

@Test
func treePerfFlatBaseline10k(): Unit {
    let source = TreePerfFlatSource(10000)
    let started = MonoTime.now()
    var frame: Int64 = 0
    var checksum: Int64 = 0
    while (frame < 1000) {
        var index: Int64 = frame % 10000
        while (index < frame % 10000 + 40) {
            checksum += source.itemAt(index).resourceId
            index += 1
        }
        frame += 1
    }
    treePerfLines.add("TREE_PERF model_flat_hot_scroll_10k_frames micros=" +
        "${(MonoTime.now() - started).toMicroseconds()} itemAtCalls=${source.itemAtCalls}")
    flushTreePerf()
    @Assert(checksum > 0, true)
}

@Test
func treePerfSamples100(): Unit {
    warmTreePerf(20, 5)
    let source = TreePerfSource(20, 5)
    let started = MonoTime.now()
    let projection = CjguiComposableUiTreeProjection(source)
    reportElapsed("cold_index_100", started)
    let expandStarted = MonoTime.now()
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    reportElapsed("bulk_expand_100", expandStarted)
    @Assert(projection.rowCount(), 120)
    let selection = CjguiComposableUiTreeSelection(projection)
    let selectStarted = MonoTime.now()
    selection.selectAllVisible()
    reportElapsed("select_all_100", selectStarted)
    @Assert(selection.selectedCount(), 100)
    // Hot scroll: repeated O(1) row lookups over one viewport-sized window.
    let scrollStarted = MonoTime.now()
    var frame: Int64 = 0
    var checksum: Int64 = 0
    while (frame < 1000) {
        var index: Int64 = frame % 60
        while (index < frame % 60 + 40) {
            checksum += projection.rowAt(index).resourceId
            index += 1
        }
        frame += 1
    }
    reportElapsed("model_hot_scroll_100_frames_rowAt", scrollStarted)
    @Assert(checksum > 0, true)
    let collapseStarted = MonoTime.now()
    let _ = projection.setExpandedBatch(projection.groupKeys(), false)
    reportElapsed("bulk_collapse_100", collapseStarted)
    @Assert(projection.rowCount(), 20)
}

@Test
func treePerfSamples1k(): Unit {
    warmTreePerf(40, 25)
    let source = TreePerfSource(40, 25)
    let started = MonoTime.now()
    let projection = CjguiComposableUiTreeProjection(source)
    reportElapsed("cold_index_1k", started)
    let expandStarted = MonoTime.now()
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    reportElapsed("bulk_expand_1k", expandStarted)
    @Assert(projection.rowCount(), 1040)
    let selection = CjguiComposableUiTreeSelection(projection)
    let selectStarted = MonoTime.now()
    selection.selectAllVisible()
    reportElapsed("select_all_1k", selectStarted)
    @Assert(selection.selectedCount(), 1000)
    let scrollStarted = MonoTime.now()
    var frame: Int64 = 0
    var checksum: Int64 = 0
    while (frame < 1000) {
        var index: Int64 = frame % 1000
        while (index < frame % 1000 + 40) {
            checksum += projection.rowAt(index).resourceId
            index += 1
        }
        frame += 1
    }
    reportElapsed("model_hot_scroll_1k_frames_rowAt", scrollStarted)
    @Assert(checksum > 0, true)
    // Local update: one group's leaves change, one rebuild.
    let updateStarted = MonoTime.now()
    let _ = projection.invalidate()
    reportElapsed("local_update_1k_rebuild", updateStarted)
}

@Test
func treePerfSamples10k(): Unit {
    warmTreePerf(200, 50)
    let source = TreePerfSource(200, 50)
    let started = MonoTime.now()
    let projection = CjguiComposableUiTreeProjection(source)
    reportElapsed("cold_index_10k", started)
    let expandStarted = MonoTime.now()
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    reportElapsed("bulk_expand_10k", expandStarted)
    @Assert(projection.rowCount(), 10200)
    let selection = CjguiComposableUiTreeSelection(projection)
    let selectStarted = MonoTime.now()
    selection.selectAllVisible()
    reportElapsed("select_all_10k", selectStarted)
    @Assert(selection.selectedCount(), 10000)
    let scrollStarted = MonoTime.now()
    var frame: Int64 = 0
    var checksum: Int64 = 0
    while (frame < 1000) {
        var index: Int64 = frame % 10000
        while (index < frame % 10000 + 40) {
            checksum += projection.rowAt(index).resourceId
            index += 1
        }
        frame += 1
    }
    reportElapsed("model_hot_scroll_10k_frames_rowAt", scrollStarted)
    @Assert(checksum > 0, true)
    let updateStarted = MonoTime.now()
    let _ = projection.invalidate()
    reportElapsed("local_update_10k_rebuild", updateStarted)
    treePerfLines.add("TREE_PERF source_childAt_calls_10k=${source.childAtCalls} materialized=viewport_plus_overscan")
    flushTreePerf()
    @Assert(projection.rowCount(), 10200)
}
