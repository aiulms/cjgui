package cjgui_notification_threshold_window_app
import cjgui.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class OverflowBindingProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult { return CjguiGeneratedUiActionResult(false, "read_only") }
    public func actionAvailable(actionName: String): Bool { return false }
}

@Test
func textOverflowGeneratedDeclarationKeepsFullValueAndSharedStyle(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let props = CjguiGeneratedUiPresentation.readonlyTextStyleProperties()
    props.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 1000))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", props, false))
    let body = "中文👩🏽‍💻和👨‍👩‍👧‍👦完整业务说明，生成界面与手写界面都不能把这个值改短。"
    let values = HashMap<String, String>()
    values.add("text", body); values.add("textMaxLines", "2"); values.add("textOverflow", "ellipsis")
    let spec = CjguiGeneratedUiNodeSpec("description", "label", properties: values)
    let provider = OverflowBindingProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(holder.submit(spec, provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let node = holder.buildRefreshNode(provider)
    @Assert(node.value, body)
    @Assert(node.style.textMaxLines, 2)
    @Assert(node.style.textOverflow, "ellipsis")
    @Assert(CjguiGeneratedUiPresentation.consumesStyleProperty("FIELD_TEXT", "textOverflow"), false)
    values.add("textOverflow", "invented")
    @Assert(CjguiGeneratedUiValidator(catalog).validate(CjguiGeneratedUiNodeSpec("bad", "label", properties: values)).accepted, false)
}

@Test
func textOverflowSurvivesSharedPaintAndTranslationComposition(): Unit {
    let base = CjguiComposableUiStyle(textMaxLines: 2, textOverflow: "ellipsis")
    let moved = cjguiComposableUiStyleWithTranslation(base, 4.0, 0.0)
    let painted = cjguiComposableUiPaintOverlay(moved, CjguiComposableUiStyle())
    @Assert(painted.textMaxLines, 2)
    @Assert(painted.textOverflow, "ellipsis")
    @Assert(CjguiComposableUiStyle().textMaxLines, 0)
    @Assert(CjguiComposableUiStyle().textOverflow, "clip")
}
