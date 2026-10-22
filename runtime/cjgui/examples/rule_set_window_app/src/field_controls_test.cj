// Focused contracts for the shared field/status compositions. These use the
// public builders and the canonical layout engine; no product coordinates or
// second business value are introduced in the consumer.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func numericStepRefusesBoundariesAndInvalidInput(): Unit {
    let up = CjguiNumericStepper.resolve("10", CJGUI_NUMERIC_STEP_UP, 1, 20, 2)
    @Assert(up.canWrite(), true)
    @Assert(up.text, "12")
    let down = CjguiNumericStepper.resolve("10", CJGUI_NUMERIC_STEP_DOWN, 1, 20, 2)
    @Assert(down.text, "8")
    let above = CjguiNumericStepper.resolve("19", CJGUI_NUMERIC_STEP_UP, 1, 20, 2)
    @Assert(above.canWrite(), false)
    @Assert(above.issue, "above_maximum")
    @Assert(above.text, "19")
    let below = CjguiNumericStepper.resolve("2", CJGUI_NUMERIC_STEP_DOWN, 1, 20, 2)
    @Assert(below.canWrite(), false)
    @Assert(below.issue, "below_minimum")
    let invalid = CjguiNumericStepper.resolve("not-a-number", CJGUI_NUMERIC_STEP_UP, 1, 20, 1)
    @Assert(invalid.canWrite(), false)
    @Assert(invalid.issue, "invalid_current_value")
    let badStep = CjguiNumericStepper.resolve("5", CJGUI_NUMERIC_STEP_UP, 1, 20, 0)
    @Assert(badStep.issue, "invalid_step")
    let positiveOverflow = CjguiNumericStepper.resolve("9223372036854775807", CJGUI_NUMERIC_STEP_UP,
        Int64.Min, Int64.Max, 1)
    @Assert(positiveOverflow.canWrite(), false)
    @Assert(positiveOverflow.issue, "step_overflow")
    @Assert(positiveOverflow.text, "9223372036854775807")
    @Assert(positiveOverflow.value, Int64.Max)
    let negativeOverflow = CjguiNumericStepper.resolve("-9223372036854775808", CJGUI_NUMERIC_STEP_DOWN,
        Int64.Min, Int64.Max, 1)
    @Assert(negativeOverflow.canWrite(), false)
    @Assert(negativeOverflow.issue, "step_overflow")
    @Assert(negativeOverflow.text, "-9223372036854775808")
    @Assert(negativeOverflow.value, Int64.Min)
    // No declared bounds still cannot turn the saturating edge into success.
    let unboundedOverflow = CjguiNumericStepper.resolve("9223372036854775807", CJGUI_NUMERIC_STEP_UP, 0,
        0, 1)
    @Assert(unboundedOverflow.canWrite(), false)
    @Assert(unboundedOverflow.issue, "step_overflow")
    @Assert(unboundedOverflow.text, "9223372036854775807")
}

@Test
func numericStepperOwnsInputStepAndPresetShape(): Unit {
    let binding = CjguiNumericStepperBinding(100, "numeric", 101, 102, 103, "numeric-input", 104,
        "numeric-down", 105, "numeric-up", "保留天数", "10", 1, 20, 2, "retentionCount",
        "EDIT_DRAFT_TEXT", 700, 42, "STEP_DOWN", "STEP_UP", feedbackNodeId: 106)
    let preset = CjguiNumericStepperPreset("max", 107, "设为 20", "20", actionName: "PRESET",
        writerOperation: "EDIT_DRAFT_TEXT", bindingResourceId: 700, ownerTargetResourceId: 42)
    let node = CjguiNumericStepper.build(binding, presets: ArrayList<CjguiNumericStepperPreset>([preset]))
    let scene = CjguiComposableUiLayoutEngine.layout(node, CjguiComposableUiRect(0, 0, 300, 140), 1)
    @Assert(scene.layoutError(), "")
    @Assert(scene.nodeForId(103).ownerInteractionState, CjguiComposableUiInteractionState.NONE)
    @Assert(scene.nodeForId(103).fieldId, "retentionCount")
    @Assert(scene.nodeForId(103).operationActionName, "EDIT_DRAFT_TEXT")
    @Assert(scene.nodeForId(103).operationResourceId, 42)
    @Assert(scene.nodeForId(104).actionName, "STEP_DOWN")
    @Assert(scene.nodeForId(104).isEnabled, true)
    @Assert(scene.nodeForId(105).actionName, "STEP_UP")
    @Assert(scene.nodeForId(107).actionName, "PRESET")
    @Assert(scene.nodeForId(107).operationActionName, "EDIT_DRAFT_TEXT")

    let boundary = CjguiNumericStepperBinding(110, "numeric-boundary", 111, 112, 113, "numeric-boundary-input",
        114, "numeric-boundary-down", 115, "numeric-boundary-up", "保留天数", "20", 1, 20, 2,
        "retentionCount", "EDIT_DRAFT_TEXT", 700, 42, "STEP_DOWN", "STEP_UP")
    let boundaryScene = CjguiComposableUiLayoutEngine.layout(CjguiNumericStepper.build(boundary),
        CjguiComposableUiRect(0, 0, 300, 100), 2)
    @Assert(boundaryScene.nodeForId(115).isEnabled, true)
    @Assert(boundaryScene.nodeForId(114).isEnabled, true)
}

@Test
func numericStepOwnerActionUsesCurrentDraft(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("步进", true, 10, "cache", "field-step-create").applied, true)
    let recordId = domain.selectedRecordId()
    let makeInvocation = { action: String =>
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion",
                CjguiSharedOperationValue.integer(domain.formSnapshot().draftVersion))
        ])
        CjguiSharedOperationActionInvocation(action, domain.version(), ArrayList<Int64>([recordId]), arguments)
    }
    @Assert(domain.executeFromHuman(makeInvocation(CjguiRetentionIntegerEditComposite.STEP_UP_ACTION)).applied,
        true)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "11")
    @Assert(domain.executeFromHuman(makeInvocation(CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION)).applied,
        true)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "10")

    let bounded = CjguiRuleSetEditingDomain.newWithRetentionRange(minimum: 1, maximum: 20)
    @Assert(bounded.createRecordFromHuman("边界", true, 20, "cache", "field-step-boundary").applied, true)
    let boundedId = bounded.selectedRecordId()
    let args = ArrayList<CjguiSharedOperationActionArgument>([
        CjguiSharedOperationActionArgument("expectedDraftVersion",
            CjguiSharedOperationValue.integer(bounded.formSnapshot().draftVersion))
    ])
    let over = bounded.executeFromHuman(CjguiSharedOperationActionInvocation(
        CjguiRetentionIntegerEditComposite.STEP_UP_ACTION, bounded.version(),
        ArrayList<Int64>([boundedId]), args))
    @Assert(over.applied, false)
    @Assert(over.reason, "above_maximum")
    @Assert(bounded.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "20")
}

@Test
func choiceGroupKeepsValueAcrossReorderAndShowsUnmatched(): Unit {
    let standard = CjguiChoiceOption("standard", 201, "标准", "standard", "SET_STANDARD",
        semanticId: "choice-standard")
    let compact = CjguiChoiceOption("compact", 202, "紧凑", "compact", "SET_COMPACT",
        semanticId: "choice-compact")
    let first = CjguiChoiceGroup.build(200, "choice", 203,
        ArrayList<CjguiChoiceOption>([standard, compact]), "compact", 204)
    let firstScene = CjguiComposableUiLayoutEngine.layout(first, CjguiComposableUiRect(0, 0, 240, 80), 1)
    @Assert(firstScene.layoutError(), "")
    @Assert(firstScene.nodeForId(202).ownerInteractionState, CjguiComposableUiInteractionState.SELECTED)
    @Assert(firstScene.nodeForId(201).ownerInteractionState, CjguiComposableUiInteractionState.NONE)

    // Reordered declaration, same keys/values: selection follows the value.
    let second = CjguiChoiceGroup.build(210, "choice-reordered", 213,
        ArrayList<CjguiChoiceOption>([compact, standard]), "compact", 214)
    let secondScene = CjguiComposableUiLayoutEngine.layout(second, CjguiComposableUiRect(0, 0, 240, 80), 2)
    @Assert(secondScene.nodeForId(202).ownerInteractionState, CjguiComposableUiInteractionState.SELECTED)
    @Assert(secondScene.nodeForId(201).ownerInteractionState, CjguiComposableUiInteractionState.NONE)

    let unmatched = CjguiChoiceGroup.build(220, "choice-unmatched", 223,
        ArrayList<CjguiChoiceOption>([standard, compact]), "missing", 224)
    let unmatchedScene = CjguiComposableUiLayoutEngine.layout(unmatched,
        CjguiComposableUiRect(0, 0, 240, 80), 3)
    @Assert(unmatchedScene.nodeForId(224).value.contains("missing"), true)
    @Assert(unmatchedScene.nodeForId(202).ownerInteractionState, CjguiComposableUiInteractionState.NONE)

    @Assert(CjguiChoiceGroup.issue(ArrayList<CjguiChoiceOption>([
        CjguiChoiceOption("a", 1, "A", "same", "A"),
        CjguiChoiceOption("b", 2, "B", "same", "B")
    ])), "choice_duplicate_value:same")
}

@Test
func statusContentAndProgressArePureProjections(): Unit {
    let status = CjguiStatusFeedback.buildMessage(300, "status", 301, 302, 303,
        CjguiStatusMessageSpec(CJGUI_STATUS_ERROR, "保存失败，请检查后重试", actionLabel: "重试",
            actionName: "RETRY"),
        style: CjguiStatusMessageStyle())
    let statusScene = CjguiComposableUiLayoutEngine.layout(status, CjguiComposableUiRect(0, 0, 160, 90), 1)
    @Assert(statusScene.nodeForId(301).value, "[错误]")
    @Assert(statusScene.nodeForId(302).value, "保存失败，请检查后重试")
    @Assert(statusScene.nodeForId(303).actionName, "RETRY")

    @Assert(CjguiContentFeedback.titleFor(CjguiContentStateSpec(CJGUI_CONTENT_EMPTY,
        emptyReason: CJGUI_EMPTY_NO_DATA)), "暂无数据")
    @Assert(CjguiContentFeedback.titleFor(CjguiContentStateSpec(CJGUI_CONTENT_EMPTY,
        emptyReason: CJGUI_EMPTY_NO_MATCH)), "没有匹配结果")

    let progress = CjguiProgressFeedback.build(400, "progress", 401, 402, 403, 404, 405,
        CjguiProgressSpec(false, value: 30, total: 120, label: "已处理 30 / 120", trackWidth: 120),
        style: CjguiProgressStyle(track: CjguiComposableUiStyle(fixedHeight: 8, background:
                CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0)),
            fill: CjguiComposableUiStyle(fixedHeight: 8,
                background: CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0))))
    let progressScene = CjguiComposableUiLayoutEngine.layout(progress,
        CjguiComposableUiRect(0, 0, 240, 80), 2)
    @Assert(progressScene.nodeForId(402).bounds.width, 120)
    @Assert(progressScene.nodeForId(403).bounds.width, 30)

    let busy = CjguiProgressFeedback.build(410, "progress-busy", 411, 412, 413, 414, 415,
        CjguiProgressSpec(true, busyLabel: "正在加载资源"))
    let busyScene = CjguiComposableUiLayoutEngine.layout(busy, CjguiComposableUiRect(0, 0, 240, 80), 3)
    @Assert(busyScene.nodeForId(414).value, "正在加载资源")

    let invalid = CjguiProgressFeedback.build(420, "progress-invalid", 421, 422, 423, 424, 425,
        CjguiProgressSpec(false, value: 8, total: 3))
    let invalidScene = CjguiComposableUiLayoutEngine.layout(invalid, CjguiComposableUiRect(0, 0, 240, 80), 4)
    @Assert(invalidScene.nodeForId(425).value.contains("progress_value_above_total"), true)
}

@Test
func progressZeroAndSubPixelFillUseActualTrackGeometry(): Unit {
    // Public default styles: zero must not inherit the 24pt intrinsic width of
    // an ordinary empty container.
    let zero = CjguiProgressFeedback.build(600, "progress-zero", 601, 602, 603, 604, 605,
        CjguiProgressSpec(false, value: 0, total: 100, trackWidth: 160))
    let zeroScene = CjguiComposableUiLayoutEngine.layout(zero, CjguiComposableUiRect(0, 0, 240, 80), 1)
    @Assert(zeroScene.layoutError(), "")
    @Assert(zeroScene.nodeForId(602).bounds.width, 160)
    @Assert(zeroScene.nodeForId(603).bounds.width, 0)
    @Assert(zeroScene.nodeForId(603).bounds.height, 8)
    @Assert(zeroScene.nodeForId(603).value, "")

    // 1/1000 of a 100pt track is below one integer point but is still visibly
    // positive; it rounds UP to one point, never to a default container width.
    let subPixel = CjguiProgressFeedback.build(610, "progress-subpixel", 611, 612, 613, 614, 615,
        CjguiProgressSpec(false, value: 1, total: 1000, trackWidth: 100))
    let subPixelScene = CjguiComposableUiLayoutEngine.layout(subPixel, CjguiComposableUiRect(0, 0, 240, 80), 2)
    @Assert(subPixelScene.nodeForId(613).bounds.width, 1)

    let normal = CjguiProgressFeedback.build(620, "progress-normal", 621, 622, 623, 624, 625,
        CjguiProgressSpec(false, value: 30, total: 120, trackWidth: 160))
    let normalScene = CjguiComposableUiLayoutEngine.layout(normal, CjguiComposableUiRect(0, 0, 240, 80), 3)
    @Assert(normalScene.nodeForId(622).bounds.width, 160)
    @Assert(normalScene.nodeForId(623).bounds.width, 40)

    let full = CjguiProgressFeedback.build(630, "progress-full", 631, 632, 633, 634, 635,
        CjguiProgressSpec(false, value: 120, total: 120, trackWidth: 160))
    let fullScene = CjguiComposableUiLayoutEngine.layout(full, CjguiComposableUiRect(0, 0, 240, 80), 4)
    @Assert(fullScene.nodeForId(632).bounds.width, 160)
    @Assert(fullScene.nodeForId(633).bounds.width, 160)

    // 900,000,000 * 12,000,000,000 overflows Int64; the legal proportion is
    // still exactly 540,000,000 points. The widths stay below the scene's
    // one-billion-point geometry ceiling even though the product does not.
    let large = CjguiProgressFeedback.build(640, "progress-large", 641, 642, 643, 644, 645,
        CjguiProgressSpec(false, value: 12000000000, total: 20000000000, trackWidth: 900000000))
    let largeScene = CjguiComposableUiLayoutEngine.layout(large, CjguiComposableUiRect(0, 0, 240, 80), 5)
    @Assert(largeScene.layoutError(), "")
    @Assert(largeScene.nodeForId(642).bounds.width, 900000000)
    @Assert(largeScene.nodeForId(643).bounds.width, 540000000)
}

@Test
func defaultStatusAndContentCopyMeasureAtTheirActualWidth(): Unit {
    let longStatus = "外部状态：保存失败，请检查网络连接后重试；当前显示的是外部提交的状态，" +
        "不代表真实任务完成。这是一段用于窄窗口换行验证的较长说明文字，不应被截断或只靠颜色区分。"
    let status = CjguiStatusFeedback.buildMessage(700, "status-default", 701, 702, -1,
        CjguiStatusMessageSpec(CJGUI_STATUS_ERROR, longStatus))
    let narrowStatusScene = CjguiComposableUiLayoutEngine.layout(status,
        CjguiComposableUiRect(0, 0, 160, 180), 1)
    @Assert(narrowStatusScene.layoutError(), "")
    @Assert(narrowStatusScene.nodeForId(702).value, longStatus)
    @Assert(narrowStatusScene.nodeForId(702).bounds.width, 152)
    @Assert(narrowStatusScene.nodeForId(702).bounds.height > 20, true)
    let wideStatusScene = CjguiComposableUiLayoutEngine.layout(status,
        CjguiComposableUiRect(0, 0, 900, 180), 2)
    @Assert(wideStatusScene.nodeForId(702).bounds.height <
        narrowStatusScene.nodeForId(702).bounds.height, true)

    let longTitle = "加载失败：当前规则保存在外部存储中，网络恢复后需要重新读取并确认版本"
    let longDetail = "请检查连接后重试。如果问题持续存在，请保留当前草稿并联系管理员；" +
        "这段详情用于确认标题和正文都按实际宽度测量自然高度。"
    let content = CjguiContentFeedback.build(710, "content-default", 711, 712, -1,
        CjguiContentStateSpec(CJGUI_CONTENT_ERROR, title: longTitle, detail: longDetail))
    let contentScene = CjguiComposableUiLayoutEngine.layout(content,
        CjguiComposableUiRect(0, 0, 140, 240), 3)
    @Assert(contentScene.layoutError(), "")
    @Assert(contentScene.nodeForId(711).value, longTitle)
    @Assert(contentScene.nodeForId(712).value, longDetail)
    @Assert(contentScene.nodeForId(711).bounds.height > 22, true)
    @Assert(contentScene.nodeForId(712).bounds.height > 20, true)

    // An explicit caller height still wins for both components.
    let fixedStatus = CjguiStatusFeedback.buildMessage(720, "status-fixed", 721, 722, -1,
        CjguiStatusMessageSpec(CJGUI_STATUS_ERROR, longStatus),
        style: CjguiStatusMessageStyle(text: CjguiComposableUiStyle(fixedHeight: 20, fontSize: 11.0)))
    let fixedStatusScene = CjguiComposableUiLayoutEngine.layout(fixedStatus,
        CjguiComposableUiRect(0, 0, 160, 180), 4)
    @Assert(fixedStatusScene.nodeForId(722).bounds.height, 20)
    let fixedContent = CjguiContentFeedback.build(730, "content-fixed", 731, 732, -1,
        CjguiContentStateSpec(CJGUI_CONTENT_ERROR, title: longTitle, detail: longDetail),
        style: CjguiContentStateStyle(title: CjguiComposableUiStyle(fixedHeight: 22, fontSize: 12.0),
            detail: CjguiComposableUiStyle(fixedHeight: 20, fontSize: 10.5)))
    let fixedContentScene = CjguiComposableUiLayoutEngine.layout(fixedContent,
        CjguiComposableUiRect(0, 0, 140, 240), 5)
    @Assert(fixedContentScene.nodeForId(731).bounds.height, 22)
    @Assert(fixedContentScene.nodeForId(732).bounds.height, 20)
}

@Test
func readOnlyAndDisabledFieldsDoNotOfferWrites(): Unit {
    let readOnly = CjguiNumericStepperBinding(500, "readonly", 501, 502, 503, "readonly-input", 504,
        "readonly-down", 505, "readonly-up", "保留天数", "10", 1, 20, 1, "retentionCount",
        "EDIT_DRAFT_TEXT", 700, 42, "STEP_DOWN", "STEP_UP", feedbackNodeId: 506, readOnly: true,
        feedback: "只读：由外部流程维护")
    let preset = CjguiNumericStepperPreset("max", 507, "设为 20", "20", actionName: "PRESET",
        writerOperation: "EDIT_DRAFT_TEXT", bindingResourceId: 700, ownerTargetResourceId: 42)
    let readOnlyScene = CjguiComposableUiLayoutEngine.layout(
        CjguiNumericStepper.build(readOnly, presets: ArrayList<CjguiNumericStepperPreset>([preset])),
        CjguiComposableUiRect(0, 0, 300, 140), 1)
    @Assert(readOnlyScene.layoutError(), "")
    @Assert(readOnlyScene.nodeForId(503).isEnabled, false)
    @Assert(readOnlyScene.nodeForId(504).isEnabled, false)
    @Assert(readOnlyScene.nodeForId(505).isEnabled, false)
    @Assert(readOnlyScene.nodeForId(507).isEnabled, false)
    @Assert(readOnlyScene.nodeForId(506).value, "只读：由外部流程维护")

    let disabled = CjguiNumericStepperBinding(510, "disabled", 511, 512, 513, "disabled-input", 514,
        "disabled-down", 515, "disabled-up", "保留天数", "10", 1, 20, 1, "retentionCount",
        "EDIT_DRAFT_TEXT", 700, 42, "STEP_DOWN", "STEP_UP", feedbackNodeId: 516, enabled: false,
        feedback: "禁用：没有可写 owner")
    let disabledScene = CjguiComposableUiLayoutEngine.layout(CjguiNumericStepper.build(disabled),
        CjguiComposableUiRect(0, 0, 300, 100), 2)
    @Assert(disabledScene.nodeForId(513).isEnabled, false)
    @Assert(disabledScene.nodeForId(514).isEnabled, false)
    @Assert(disabledScene.nodeForId(515).isEnabled, false)
    @Assert(disabledScene.nodeForId(516).value, "禁用：没有可写 owner")

    let enabledOption = CjguiChoiceOption("standard", 520, "标准", "standard", "SET_STANDARD")
    let disabledOption = CjguiChoiceOption("compact", 521, "紧凑", "compact", "SET_COMPACT",
        enabled: false)
    let choiceScene = CjguiComposableUiLayoutEngine.layout(
        CjguiChoiceGroup.build(522, "disabled-choice", 523,
            ArrayList<CjguiChoiceOption>([enabledOption, disabledOption]), "compact", 524),
        CjguiComposableUiRect(0, 0, 240, 80), 3)
    @Assert(choiceScene.nodeForId(520).isEnabled, true)
    @Assert(choiceScene.nodeForId(521).isEnabled, false)
    @Assert(choiceScene.nodeForId(521).ownerInteractionState, CjguiComposableUiInteractionState.SELECTED)
}
