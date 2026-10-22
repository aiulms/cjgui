package cjgui

import cjgui_shared_operation_core.*

@Test
func accessibilityFeedbackRetainsValueAndSurvivesProjectionCopies(): Unit {
    let descriptor = CjguiSharedFormFieldDescriptor(7001, "label", "名称", "TEXT", required: true)
    let field = CjguiSharedFormFieldProjection(7001, "label", CjguiSharedOperationValue.string("原值"),
        "", "label_required", 3, true, 0, 0)
    let group = cjguiComposableBoundFormField(10, "form-label", 11, 12, descriptor, field, 80,
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle(), helpText: "规则的显示名称")
    let editor = group.children()[0]
    @Assert(editor.value, "")
    @Assert(editor.semanticHelp.contains("请填写名称"), true)
    @Assert(editor.semanticHelp.contains("label_required"), true)
    @Assert(editor.semanticHelp.contains("必填"), true)
    @Assert(editor.semanticHelp.contains("规则的显示名称"), true)
    let scene = CjguiComposableUiLayoutEngine.layout(group, CjguiComposableUiRect(0, 0, 300, 100), 1)
    @Assert(scene.isValid(), true)
    var found = false
    for (node in scene.nodes()) {
        if (node.nodeId == 11) {
            @Assert(node.semanticHelp, editor.semanticHelp)
            @Assert(node.value, "")
            found = true
        }
    }
    @Assert(found, true)
    let repaired = CjguiSharedFormFieldProjection(7001, "label", CjguiSharedOperationValue.string("原值"),
        "修复", "", 4, true, 6, 6)
    let help = cjguiComposableFormFieldHelp(descriptor, repaired, readOnly: true, enabled: false,
        unavailableReason: "permission_denied")
    @Assert(help.contains("label_required"), false)
    @Assert(help.contains("只读"), true)
    @Assert(help.contains("permission_denied"), true)
}
