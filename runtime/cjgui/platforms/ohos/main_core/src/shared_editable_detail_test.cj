package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private let detailOwner: Int64 = 7200

private func detailBinding(): CjguiSharedFormBinding {
    return CjguiSharedFormBinding(ArrayList<CjguiSharedFormFieldDescriptor>([
        CjguiSharedFormFieldDescriptor(82001, "title", "标题", "TEXT"),
        CjguiSharedFormFieldDescriptor(82002, "count", "保留天数", "INTEGER", minimum: 1, maximum: 30),
        CjguiSharedFormFieldDescriptor(82003, "enabled", "启用", "BOOLEAN"),
        CjguiSharedFormFieldDescriptor(82004, "note", "备注", "TEXT")
    ]))
}

private func detailSnapshot(countError!: String = "", countResource!: Int64 = 82002): CjguiSharedFormSnapshot {
    return CjguiSharedFormSnapshot(7, 3, 4, 3, ArrayList<CjguiSharedFormFieldProjection>([
        CjguiSharedFormFieldProjection(82001, "title", CjguiSharedOperationValue.string("甲"),
            "甲草稿", "", 4, false, 0, 0),
        CjguiSharedFormFieldProjection(countResource, "count", CjguiSharedOperationValue.integer(5),
            "5", countError, 4, false, 0, 0),
        CjguiSharedFormFieldProjection(82003, "enabled", CjguiSharedOperationValue.boolean(true),
            "true", "", 4, false, 0, 0),
        CjguiSharedFormFieldProjection(82004, "note", CjguiSharedOperationValue.string(""),
            "备注草稿", "", 4, false, 0, 0)
    ]), true, "草稿已修改")
}

private func detailTheme(): CjguiComposableUiTheme {
    let style = CjguiComposableUiStyle()
    return CjguiComposableUiTheme(style, style, style, style, style, style)
}

private func findEditor(node: CjguiComposableUiNode, fieldId: String): ?CjguiComposableUiNode {
    for (child in node.children()) {
        if (child.fieldId == fieldId) {
            return Some(child)
        }
        if (let Some(found) <- findEditor(child, fieldId)) {
            return Some(found)
        }
    }
    return None
}

@Test
func sharedDetailDispatchesEveryEditorKindThroughBoundFormField(): Unit {
    let node = cjguiSharedEditableDetailFields(30000, 30010, 30009, "detail", detailOwner,
        detailBinding(), detailSnapshot(), { _ => CjguiSharedDetailFieldState(true) }, "状态", detailTheme())
    let title = findEditor(node, "title").getOrThrow()
    let count = findEditor(node, "count").getOrThrow()
    let enabled = findEditor(node, "enabled").getOrThrow()
    // TEXT/INTEGER/BOOLEAN keep their REAL editor kind (no INTEGER-as-TEXT).
    @Assert(title.nodeKind, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(count.nodeKind, CJGUI_COMPOSABLE_UI_INTEGER_INPUT)
    @Assert(enabled.nodeKind, CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT)
    // Every editor addresses the SAME owner with its declared field identity.
    @Assert(count.operationResourceId, detailOwner)
    @Assert(count.fieldId, "count")
    @Assert(count.semanticId, "detail-count")
    // Editor ids stay compatible with the previous layout (firstEditor + i*10).
    @Assert(title.nodeId, 30010)
    @Assert(count.nodeId, 30020)
    @Assert(enabled.nodeId, 30030)
}

@Test
func sharedDetailRejectsAMismatchedFieldIdentity(): Unit {
    var rejected = false
    try {
        let _ = cjguiSharedEditableDetailFields(31000, 31010, 31009, "detail", detailOwner,
            detailBinding(), detailSnapshot(countResource: 99999), { _ => CjguiSharedDetailFieldState(true) },
            "状态", detailTheme())
    } catch (error: IllegalArgumentException) {
        rejected = error.message.contains("identity")
    }
    @Assert(rejected, true)
}

@Test
func sharedDetailProjectsReadOnlyDisabledAndErrorFromOneFeedback(): Unit {
    let readOnly = ArrayList<String>(["title"])
    let node = cjguiSharedEditableDetailFields(32000, 32010, 32009, "detail", detailOwner,
        detailBinding(), detailSnapshot(countError: "count_out_of_range"),
        { fieldId => if (fieldId == "count") {
            CjguiSharedDetailFieldState(false, unavailableReason: "超出允许范围")
        } else {
            CjguiSharedDetailFieldState(true)
        } }, "状态", detailTheme(), readOnlyFields: readOnly,
        displayMessage: { ignored, reason =>
            let _ = ignored
            if (reason == "count_out_of_range") { "保留天数超出允许范围" } else { reason } })
    let title = findEditor(node, "title").getOrThrow()
    let count = findEditor(node, "count").getOrThrow()
    // Read-only and disabled are visible in the accessible help, not only in a
    // private flag.
    @Assert(title.semanticHelp.contains("只读"), true)
    @Assert(count.semanticHelp.contains("当前不可用"), true)
    @Assert(count.semanticHelp.contains("保留天数超出允许范围"), true)
    // The validation line carries the display message from the same projection.
    var validationText = ""
    for (child in node.children()) {
        for (inner in child.children()) {
            if (inner.fieldId == "count" && inner.displayValueRole == "validation") {
                validationText = inner.value
            }
        }
    }
    @Assert(validationText, "保留天数超出允许范围")
}

@Test
func sharedDetailKeepsTheCallersValidationWording(): Unit {
    // The old caller passes its display wording through stateOf(). That wording
    // must still be what the validation line shows, while the fact "invalid"
    // still comes from the owner projection (no second validation).
    let node = cjguiSharedEditableDetailFields(33000, 33010, 33009, "detail", detailOwner,
        detailBinding(), detailSnapshot(countError: "count_out_of_range"),
        { fieldId => if (fieldId == "count") {
            CjguiSharedDetailFieldState(true, validationError: "保留天数需在 1-30 之间")
        } else {
            CjguiSharedDetailFieldState(true)
        } }, "状态", detailTheme())
    var validationText = ""
    for (child in node.children()) {
        for (inner in child.children()) {
            if (inner.fieldId == "count" && inner.displayValueRole == "validation") {
                validationText = inner.value
            }
        }
    }
    @Assert(validationText, "保留天数需在 1-30 之间")
    // A message for a field the OWNER reports as valid must not fabricate an
    // error line: the projection (not the wording) decides validity.
    let valid = cjguiSharedEditableDetailFields(33100, 33110, 33109, "detail", detailOwner,
        detailBinding(), detailSnapshot(), { _ => CjguiSharedDetailFieldState(true, validationError: "不该出现的错误") },
        "状态", detailTheme())
    var fabricated = ""
    for (child in valid.children()) {
        for (inner in child.children()) {
            if (inner.displayValueRole == "validation") { fabricated = inner.value }
        }
    }
    @Assert(fabricated, "")
}
