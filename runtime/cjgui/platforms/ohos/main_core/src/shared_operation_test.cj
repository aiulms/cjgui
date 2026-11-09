package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func sharedOperationAppliesHumanAndCurrentExternalChangesButRejectsStaleWrites(): Unit {
    let records = ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(11, "First record", false),
        CjguiSharedOperationRecord(12, "Second record", false)
    ])
    let list = CjguiSharedOperationList(records)

    let humanSelection = list.selectFromHuman(12)
    @Assert(humanSelection.applied, true)
    @Assert(list.version(), 1)
    @Assert(list.snapshot().selectedRecordId, 12)

    let externalSelection = list.selectFromExternal(11, humanSelection.versionAfter)
    @Assert(externalSelection.applied, true)
    @Assert(list.version(), 2)
    @Assert(list.snapshot().selectedRecordId, 11)

    let externalToggle = list.toggleFromExternal(12, externalSelection.versionAfter)
    @Assert(externalToggle.applied, true)
    @Assert(list.version(), 3)
    @Assert(list.snapshot().recordAt(1).isMarked, true)

    let humanToggle = list.toggleFromHuman(12)
    @Assert(humanToggle.applied, true)
    @Assert(list.version(), 4)
    @Assert(list.snapshot().recordAt(1).isMarked, false)

    let staleExternalToggle = list.toggleFromExternal(12, externalToggle.versionAfter)
    @Assert(staleExternalToggle.applied, false)
    @Assert(staleExternalToggle.isVersionConflict, true)
    @Assert(list.version(), 4)
    @Assert(list.snapshot().recordAt(1).isMarked, false)
}

@Test
func sharedOperationBatchSetIsAtomicIdempotentAndVersionGuarded(): Unit {
    let records = ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(41, "First batch record", false),
        CjguiSharedOperationRecord(42, "Second batch record", false),
        CjguiSharedOperationRecord(43, "Outside target", false)
    ])
    let list = CjguiSharedOperationList(records)

    let applied = list.setMarkedFromExternal(
        ArrayList<Int64>([41, 42, 42]),
        true,
        0
    )
    @Assert(applied.applied, true)
    @Assert(applied.isVersionConflict, false)
    @Assert(applied.versionBefore, 0)
    @Assert(applied.versionAfter, 1)
    @Assert(list.snapshot().recordAt(0).isMarked, true)
    @Assert(list.snapshot().recordAt(1).isMarked, true)
    @Assert(list.snapshot().recordAt(2).isMarked, false)

    let idempotentRetry = list.setMarkedFromExternal(
        ArrayList<Int64>([41, 42]),
        true,
        1
    )
    @Assert(idempotentRetry.applied, true)
    @Assert(idempotentRetry.reason, "already_at_target")
    @Assert(idempotentRetry.versionBefore, 1)
    @Assert(idempotentRetry.versionAfter, 1)

    let staleWrite = list.setMarkedFromExternal(ArrayList<Int64>([43]), true, 0)
    @Assert(staleWrite.applied, false)
    @Assert(staleWrite.isVersionConflict, true)
    @Assert(list.version(), 1)
    @Assert(list.snapshot().recordAt(2).isMarked, false)

    let unknownTarget = list.setMarkedFromExternal(
        ArrayList<Int64>([41, 999]),
        false,
        1
    )
    @Assert(unknownTarget.applied, false)
    @Assert(unknownTarget.reason, "unknown_record")
    @Assert(list.version(), 1)
    @Assert(list.snapshot().recordAt(0).isMarked, true)
    @Assert(list.snapshot().recordAt(1).isMarked, true)
}

@Test
func sharedOperationRejectsDuplicateStableRecordIds(): Unit {
    @AssertThrows[IllegalArgumentException](
        CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
            CjguiSharedOperationRecord(71, "First stable record", false),
            CjguiSharedOperationRecord(71, "Duplicate stable record", false)
        ]))
    )
}
