package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func originalListConsumerUsesTheGenericDomainHandlerForHumanAndExternalActions(): Unit {
    let list = CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>(
            [
                CjguiSharedOperationRecord(101, "屏幕外候选", false),
                CjguiSharedOperationRecord(102, "另一条记录", false)
            ]
        )
    )

    let actions = list.actionDescriptors()
    @Assert(actions.size, 4)
    @Assert(actions[2].name, "SET_MARKED")
    @Assert(actions[2].parameters[0].valueType, "BOOLEAN")
    @Assert(actions[3].name, "SET_TITLE")
    @Assert(actions[3].parameters[0].valueType, "STRING")

    let selected = list.executeFromHuman(
        CjguiSharedOperationActionInvocation(
            "SELECT", 0, ArrayList<Int64>([101]), ArrayList<CjguiSharedOperationActionArgument>()
        )
    )
    @Assert(selected.applied, true)
    @Assert(list.snapshot().selectedRecordId, 101)

    let marked = list.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "SET_MARKED",
            selected.versionAfter,
            ArrayList<Int64>([101, 101]),
            ArrayList<CjguiSharedOperationActionArgument>(
                [CjguiSharedOperationActionArgument("isMarked", CjguiSharedOperationValue.boolean(true))]
            )
        )
    )
    @Assert(marked.applied, true)
    @Assert(marked.versionAfter, 2)
    @Assert(list.snapshot().recordAt(0).isMarked, true)

    let stale = list.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "TOGGLE", 0, ArrayList<Int64>([101]), ArrayList<CjguiSharedOperationActionArgument>()
        )
    )
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(list.snapshot().recordAt(0).isMarked, true)
}

/// A normal window must not keep editable task text in its controller while
/// an external consumer edits a different record.  The same resource/action
/// pair carries a human's transient empty value, an external replacement and
/// the subsequent human update; only external calls require a fresh version.
@Test
func titleIsOneSharedOperationForHumanAndExternalConsumers(): Unit {
    let list = CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>([
            CjguiSharedOperationRecord(8101, "初始任务", false)
        ])
    )

    let clearedByHuman = list.executeFromHuman(
        CjguiSharedOperationActionInvocation(
            "SET_TITLE", 0, ArrayList<Int64>([8101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.string(""))
            ])
        )
    )
    @Assert(clearedByHuman.applied, true)
    @Assert(list.snapshot().recordAt(0).title, "")
    let clearedContext = list.contextSnapshot()
    @Assert(clearedContext.resources[0].name, "记录 8101")
    @Assert(clearedContext.resources[0].fields[0].value.stringValue, "")

    let malformed = list.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "SET_TITLE", clearedByHuman.versionAfter, ArrayList<Int64>([8101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.boolean(true))
            ])
        )
    )
    @Assert(malformed.applied, false)
    @Assert(malformed.reason, "invalid_parameters")
    @Assert(list.snapshot().recordAt(0).title, "")

    let replacedByExternal = list.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "SET_TITLE", clearedByHuman.versionAfter, ArrayList<Int64>([8101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.string("外部接手后的任务"))
            ])
        )
    )
    @Assert(replacedByExternal.applied, true)
    @Assert(list.snapshot().recordAt(0).title, "外部接手后的任务")

    let stale = list.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "SET_TITLE", clearedByHuman.versionAfter, ArrayList<Int64>([8101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.string("过期写入"))
            ])
        )
    )
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)

    let continuedByHuman = list.executeFromHuman(
        CjguiSharedOperationActionInvocation(
            "SET_TITLE", 0, ArrayList<Int64>([8101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("title", CjguiSharedOperationValue.string("人继续编辑"))
            ])
        )
    )
    @Assert(continuedByHuman.applied, true)
    @Assert(list.snapshot().recordAt(0).title, "人继续编辑")
}
