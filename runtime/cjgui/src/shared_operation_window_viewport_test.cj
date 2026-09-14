package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func sharedOperationWindowProjectsMoreThanEightStableRecordsThroughOneViewport(): Unit {
    let records = ArrayList<CjguiSharedOperationRecord>()
    var index: Int64 = 0
    while (index < 101) {
        records.add(
            CjguiSharedOperationRecord(
                1000 + index,
                "Viewport record ${index}",
                false
            )
        )
        index += 1
    }

    let list = CjguiSharedOperationList(records)
    let window = CjguiSharedOperationWindow(list)

    // `cjpm test` runs this Cangjie test on its managed worker, while the
    // real AppKit renderer requires the macOS process main thread (or the
    // app-launcher dispatcher). Keep this unit test at the owner-independent
    // viewport boundary. The normal bundled app verifies native start.
    let initialSnapshot = list.snapshot()
    @Assert(window.visibleRecordId(initialSnapshot, 0) ?? -1, 1000)
    @Assert(window.visibleRecordId(initialSnapshot, 7) ?? -1, 1007)

    while (window.moveViewportForHumanBrowsing(initialSnapshot, true)) {
    }
    @Assert(window.visibleRecordId(initialSnapshot, 0) ?? -1, 1093)
    let screenOffTarget = window.visibleRecordId(initialSnapshot, 7) ?? -1
    @Assert(screenOffTarget, 1100)

    let selected = list.selectFromHuman(screenOffTarget)
    @Assert(selected.applied, true)
    @Assert(list.snapshot().selectedRecordId, 1100)
    window.close()
}
