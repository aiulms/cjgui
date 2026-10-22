// Generated-region status/content/progress projections. The factories are thin
// adapters over the public CjguiStatusFeedback/CjguiContentFeedback/
// CjguiProgressFeedback builders; they never hold task state or start work.
package cjgui_rule_set_window_app

import cjgui.*
import std.collection.*

private func feedbackContainerElements(): ArrayList<CjguiCompositeElementSpec> {
    return ArrayList<CjguiCompositeElementSpec>([
        CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
        CjguiCompositeElementSpec("chip", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
        CjguiCompositeElementSpec("text", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root")
    ])
}

private class CjguiRuleStatusComposite <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("root") ?? CjguiCompositeElementBinding("root",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let chip = context.element("chip") ?? CjguiCompositeElementBinding("chip",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let text = context.element("text") ?? CjguiCompositeElementBinding("text",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let kind = context.property("kind")
        let spec = CjguiStatusMessageSpec(if (kind.size > 0) { kind } else { CJGUI_STATUS_INFO },
            context.property("text"))
        return CjguiStatusFeedback.buildMessage(root.nodeId, root.semanticId, chip.nodeId, text.nodeId, -1,
            spec, style: CjguiStatusMessageStyle(container: CjguiComposableUiStyle(padding: 2, gap: 4),
                chip: CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 20, fontSize: 10.5),
                text: CjguiComposableUiStyle(fontSize: 11.0)))
    }
}

private class CjguiRuleContentStateComposite <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("root") ?? CjguiCompositeElementBinding("root",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let title = context.element("title") ?? CjguiCompositeElementBinding("title",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let detail = context.element("detail") ?? CjguiCompositeElementBinding("detail",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let kind = context.property("kind")
        let reason = context.property("emptyReason")
        let spec = CjguiContentStateSpec(if (kind.size > 0) { kind } else { CJGUI_CONTENT_EMPTY },
            emptyReason: if (reason.size > 0) { reason } else { CJGUI_EMPTY_NO_DATA },
            title: context.property("title"), detail: context.property("detail"))
        return CjguiContentFeedback.build(root.nodeId, root.semanticId, title.nodeId, detail.nodeId, -1, spec,
            style: CjguiContentStateStyle(container: CjguiComposableUiStyle(padding: 6, gap: 4),
                title: CjguiComposableUiStyle(fontSize: 12.0),
                detail: CjguiComposableUiStyle(fontSize: 10.5)))
    }
}

private class CjguiRuleProgressComposite <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("root") ?? CjguiCompositeElementBinding("root",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let label = context.element("label") ?? CjguiCompositeElementBinding("label",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let track = context.element("track") ?? CjguiCompositeElementBinding("track",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let fill = context.element("fill") ?? CjguiCompositeElementBinding("fill",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let busy = context.element("busy") ?? CjguiCompositeElementBinding("busy",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let issue = context.element("issue") ?? CjguiCompositeElementBinding("issue",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let spec = CjguiProgressSpec(context.property("busy") == "true",
            value: context.propertyInteger("value"), total: context.propertyInteger("total"),
            label: context.property("label"), trackWidth: context.propertyInteger("trackWidth", fallback: 160))
        return CjguiProgressFeedback.build(root.nodeId, root.semanticId, label.nodeId, track.nodeId,
            fill.nodeId, busy.nodeId, issue.nodeId, spec)
    }
}


private class CjguiDetailLayoutChoiceComposite <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("root") ?? CjguiCompositeElementBinding("root",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let options = context.element("options") ?? CjguiCompositeElementBinding("options",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let unmatched = context.element("unmatched") ?? CjguiCompositeElementBinding("unmatched",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let standard = context.element("standard") ?? CjguiCompositeElementBinding("standard",
            CJGUI_COMPOSITE_ELEMENT_ACTION, -1, "", "")
        let compact = context.element("compact") ?? CjguiCompositeElementBinding("compact",
            CJGUI_COMPOSITE_ELEMENT_ACTION, -1, "", "")
        let choices = ArrayList<CjguiChoiceOption>([
            CjguiChoiceOption("standard", standard.nodeId, "标准", "standard", "GENERATED_ACTION",
                semanticId: standard.semanticId, enabled: standard.actionEnabled),
            CjguiChoiceOption("compact", compact.nodeId, "紧凑", "compact", "GENERATED_ACTION",
                semanticId: compact.semanticId, enabled: compact.actionEnabled)
        ])
        return CjguiChoiceGroup.build(root.nodeId, root.semanticId, options.nodeId, choices,
            context.property("selected"), unmatched.nodeId,
            style: CjguiChoiceGroupStyle(button: CjguiComposableUiStyle(fixedHeight: 28)))
    }
}

public class CjguiRuleSetFeedbackComposites {
    public static let STATUS_KIND: String = "ruleStatus"
    public static let CONTENT_KIND: String = "ruleContentState"
    public static let PROGRESS_KIND: String = "ruleProgress"
    public static let DETAIL_CHOICE_KIND: String = "detailLayoutChoice"

    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
        let statusProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("kind", "STRING", maxLength: 16),
            CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 400)
        ])
        let statusOK = catalog.registerComposite(CjguiCompositeComponentSpec(STATUS_KIND, statusProperties,
            feedbackContainerElements(), expandedNodeLimit: 4, expandedDepthLimit: 2),
            CjguiRuleStatusComposite())
        let contentProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("kind", "STRING", maxLength: 16),
            CjguiGeneratedUiPropertySpec("emptyReason", "STRING", maxLength: 16),
            CjguiGeneratedUiPropertySpec("title", "STRING", maxLength: 120),
            CjguiGeneratedUiPropertySpec("detail", "STRING", maxLength: 240)
        ])
        let contentElements = ArrayList<CjguiCompositeElementSpec>([
            CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
            CjguiCompositeElementSpec("title", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("detail", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root")
        ])
        let contentOK = catalog.registerComposite(CjguiCompositeComponentSpec(CONTENT_KIND, contentProperties,
            contentElements, expandedNodeLimit: 4, expandedDepthLimit: 2), CjguiRuleContentStateComposite())
        let progressProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("busy", "BOOLEAN"),
            CjguiGeneratedUiPropertySpec("value", "INTEGER", minimum: 0, maximum: 1000000),
            CjguiGeneratedUiPropertySpec("total", "INTEGER", minimum: 0, maximum: 1000000),
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 120),
            CjguiGeneratedUiPropertySpec("trackWidth", "INTEGER", minimum: 1, maximum: 4096)
        ])
        let progressElements = ArrayList<CjguiCompositeElementSpec>([
            CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
            CjguiCompositeElementSpec("label", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("track", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("fill", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "track"),
            CjguiCompositeElementSpec("busy", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("issue", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root")
        ])
        let progressOK = catalog.registerComposite(CjguiCompositeComponentSpec(PROGRESS_KIND, progressProperties,
            progressElements, expandedNodeLimit: 8, expandedDepthLimit: 3), CjguiRuleProgressComposite())
        let choiceElements = ArrayList<CjguiCompositeElementSpec>([
            CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
            CjguiCompositeElementSpec("options", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("unmatched", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"),
            CjguiCompositeElementSpec("standard", CJGUI_COMPOSITE_ELEMENT_ACTION,
                actionName: "SET_DETAIL_LAYOUT_STANDARD", parentKey: "options"),
            CjguiCompositeElementSpec("compact", CJGUI_COMPOSITE_ELEMENT_ACTION,
                actionName: "SET_DETAIL_LAYOUT_COMPACT", parentKey: "options")
        ])
        let choiceOK = catalog.registerComposite(CjguiCompositeComponentSpec(DETAIL_CHOICE_KIND,
            ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("selected", "STRING", maxLength: 32)
            ]), choiceElements, expandedNodeLimit: 8, expandedDepthLimit: 3),
            CjguiDetailLayoutChoiceComposite())
        return statusOK && contentOK && progressOK && choiceOK
    }
}
