package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func sharedFormBindingKeepsStableFieldSlotsAcrossDifferentApplications(): Unit {
    let backupBinding = CjguiSharedFormBinding(
        ArrayList<CjguiSharedFormFieldDescriptor>(
            [
                CjguiSharedFormFieldDescriptor(42011, "ruleLabel", "规则名称", "TEXT"),
                CjguiSharedFormFieldDescriptor(42013, "retentionCount", "保留天数", "INTEGER")
            ]
        )
    )
    let notificationBinding = CjguiSharedFormBinding(
        ArrayList<CjguiSharedFormFieldDescriptor>(
            [CjguiSharedFormFieldDescriptor(901, "threshold", "通知阈值", "INTEGER")]
        )
    )

    @Assert(backupBinding.fieldAtControlIndex(0).fieldId, "ruleLabel")
    @Assert(backupBinding.fieldAtControlIndex(1).resourceId, 42013)
    @Assert(backupBinding.controlIndexForResourceId(42011), 0)
    @Assert(notificationBinding.fieldAtControlIndex(0).label, "通知阈值")
    @Assert(notificationBinding.controlIndexForResourceId(901), 0)
}
