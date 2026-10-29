package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class PreparedHeightSliceProbe <: CjguiComposableUiTextMeasurer & CjguiComposableUiLayoutPacer {
    var steps: Int64 = 0
    var limit: Int64 = 18
    public func checkpointLayoutSlice(): Unit {
        steps += 1
        if (steps >= limit) { throw CjguiLayoutMeasurementNeedBudget() }
    }
    public func measure(value: String, style: CjguiComposableUiStyle,
        maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        return CjguiComposableUiTextMeasurement(40, 18, 1, 8)
    }
}

private func preparedHeightTree(): CjguiComposableUiNode {
    let root = cjguiComposableVertical(98700, "height-root", CjguiComposableUiStyle(gap: 3))
    for (i in 0..12) {
        let group = cjguiComposableVertical(98710 + i * 2, "group-${i}", CjguiComposableUiStyle(gap: 2))
        group.add(cjguiComposableText(98711 + i * 2, "leaf-${i}", "label-${i}", CjguiComposableUiStyle()))
        root.add(group)
    }
    return root
}

private func preparedHeightEntries(node: CjguiComposableUiNode): Int64 {
    var total: Int64 = 0
    if (let Some(inputs) <- node.preparedLayoutInputs) { total += inputs.intrinsicHeightEntryCount() }
    for (child in node.children()) { total += preparedHeightEntries(child) }
    return total
}

@Test
func preparedIntrinsicProgressSurvivesYieldAndStaysCandidateLocal(): Unit {
    let frozen = preparedHeightTree()
    cjguiFreezePreparedLayoutInputs(frozen, 220, 800, CjguiComposableUiIdentityRegistry())
    let working = frozen.cloneForWindowCandidate(preservePreparedLayout: true)
    let probe = PreparedHeightSliceProbe()
    let bounds = CjguiComposableUiRect(0, 0, 220, 800)
    var yielded = false
    try { let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(working, bounds, 1, probe) }
    catch (_: CjguiLayoutMeasurementNeedBudget) { yielded = true }
    @Assert(yielded, true)
    @Assert(preparedHeightEntries(working) > 0, true)
    @Assert(preparedHeightEntries(frozen), 0)
    probe.limit = Int64.Max
    let resumed = CjguiComposableUiLayoutEngine.layoutWithMetrics(working, bounds, 1, probe).scene
    let oracle = CjguiComposableUiLayoutEngine.layoutWithMetrics(preparedHeightTree(), bounds, 1, probe).scene
    @Assert(resumed.isValid(), true)
    @Assert(resumed.nodes().size, oracle.nodes().size)
    for (expected in oracle.nodes()) {
        let actual = resumed.nodeForId(expected.nodeId)
        @Assert(actual.bounds.x, expected.bounds.x)
        @Assert(actual.bounds.y, expected.bounds.y)
        @Assert(actual.bounds.width, expected.bounds.width)
        @Assert(actual.bounds.height, expected.bounds.height)
    }
    let replacement = working.cloneForWindowCandidate(preservePreparedLayout: true)
    @Assert(preparedHeightEntries(replacement), 0)
    let inputs = working.preparedLayoutInputs.getOrThrow()
    for (width in 1..10) { inputs.rememberIntrinsicHeight(width, 18) }
    @Assert(inputs.intrinsicHeightEntryCount() <= 4, true)
    @Assert(inputs.cachedIntrinsicHeight(1).isNone(), true)
}
