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

// R7：绑定字段的可见标签控制、默认回退与可访问名称是三件不同的事。
// 默认（空 editorLabel）回退 descriptor.label；显式 editorLabelVisible=false
// 只隐藏可见标签，不再回退，编辑器仍携带同字段的绑定事实。
@Test
func boundFormFieldExplicitlyHiddenLabelDoesNotFallBackToDescriptorLabel(): Unit {
    let descriptor = CjguiSharedFormFieldDescriptor(7002, "note", "签名", "TEXT", required: true)
    let field = CjguiSharedFormFieldProjection(7002, "note", CjguiSharedOperationValue.string("草稿"),
        "", "", 1, true, 0, 0)
    // 历史默认：空 editorLabel 回退 descriptor.label。
    let fallback = cjguiComposableBoundFormField(30, "fb-fallback", 31, 32, descriptor, field, 80,
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle())
    @Assert(fallback.children()[0].label, "签名")
    // 显式隐藏：可见标签为空，不回退声明 label；同字段路由保持不变。
    let hidden = cjguiComposableBoundFormField(40, "fb-hidden", 41, 42, descriptor, field, 80,
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle(), editorLabelVisible: false)
    @Assert(hidden.children()[0].label, "")
    @Assert(hidden.children()[0].fieldId, "note")
    @Assert(hidden.children()[0].operationActionName, "EDIT_DRAFT_TEXT")
    @Assert(hidden.children()[0].resourceId, 7002)
    // INTEGER 编辑器同样遵守（步进器输入路径共用同一编辑器）。
    let intDescriptor = CjguiSharedFormFieldDescriptor(7003, "count", "数量", "INTEGER", required: false)
    let intField = CjguiSharedFormFieldProjection(7003, "count", CjguiSharedOperationValue.string("5"),
        "", "", 1, true, 0, 0)
    let intHidden = cjguiComposableBoundFormField(50, "fb-int", 51, 52, intDescriptor, intField, 80,
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle(), editorLabelVisible: false)
    @Assert(intHidden.children()[0].label, "")
    @Assert(intHidden.children()[0].fieldId, "count")
    // 显式给出的 editorLabel 在可见时照常使用。
    let explicit = cjguiComposableBoundFormField(60, "fb-explicit", 61, 62, descriptor, field, 80,
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle(), editorLabel: "自定义标签")
    @Assert(explicit.children()[0].label, "自定义标签")
}
