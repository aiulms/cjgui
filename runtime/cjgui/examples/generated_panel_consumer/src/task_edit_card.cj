// The task consumer's own composite component: a real composite structure (a
// card with a caption, a title editor and a notes editor) registered with the
// public experimental seam. Adding it changes ONLY this file plus the
// application's registration call - the framework's kind dispatch is untouched.
//
// Both editors write the SAME fields the handwritten pane and the external
// query already use (`CjguiTaskFields`): the title through SET_TITLE (with its
// 120-scalar limit and the submit-time freeze condition) and the notes through
// SET_NOTES (200 scalars). The framework resolves the owner bindings, so this
// component never names an owner or a writer itself.
package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

public class CjguiTaskEditCardComposite <: CjguiCompositeComponentFactory {
    public static let KIND: String = "taskEditCard"

    /// Registers the card kind. The declared properties are the ONLY ones an
    /// external description may submit; the field references are validated
    /// against the consumer's own single field definition list.
    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 24))
        properties.add(CjguiGeneratedUiPropertySpec("caption", "STRING", maxLength: 60))
        let elements = ArrayList<CjguiCompositeElementSpec>()
        elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
        elements.add(CjguiCompositeElementSpec("caption", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("title", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "title", parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("notes", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "notes", parentKey: "root"))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(KIND, properties, elements,
                expandedNodeLimit: 6, expandedDepthLimit: 3),
            CjguiTaskEditCardComposite())
    }

    /// The single build implementation. A handwritten region can call it
    /// directly with its own identities; the generated region reaches it through
    /// `buildComposite` with framework-allocated ones.
    public static func buildCard(nodeId: Int64, semanticId: String, captionNodeId: Int64,
                                 titleNodeId: Int64, notesNodeId: Int64, caption: String,
                                 titleLabel: String, titleValue: String, titleWriter: String,
                                 titleResourceId: Int64, titleTarget: Int64,
                                 notesLabel: String, notesValue: String, notesWriter: String,
                                 notesResourceId: Int64, notesTarget: Int64,
                                 style!: CjguiComposableUiStyle = CjguiComposableUiStyle()): CjguiComposableUiNode {
        let card = cjguiComposableVertical(nodeId, semanticId, CjguiComposableUiStyle(gap: 4))
        card.add(cjguiComposableText(captionNodeId, "${semanticId}-caption", caption,
            CjguiComposableUiStyle(fontSize: 13.0)))
        card.add(cjguiComposableTextInput(titleNodeId, "${semanticId}-title", titleLabel, titleValue,
            titleResourceId, style, enabled: titleTarget >= 0, fieldId: "title",
            operationActionName: titleWriter, operationResourceId: titleTarget,
            displayValueRole: "draft"))
        card.add(cjguiComposableTextInput(notesNodeId, "${semanticId}-notes", notesLabel, notesValue,
            notesResourceId, style, enabled: notesTarget >= 0, fieldId: "notes",
            operationActionName: notesWriter, operationResourceId: notesTarget,
            displayValueRole: "draft"))
        return card
    }

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let captionElement = match (context.element("caption")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("caption", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let title = match (context.element("title")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("title", CJGUI_COMPOSITE_ELEMENT_FIELD, -1, "", "")
        }
        let notes = match (context.element("notes")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("notes", CJGUI_COMPOSITE_ELEMENT_FIELD, -1, "", "")
        }
        let declaredCaption = context.property("caption")
        let caption = if (declaredCaption.size > 0) { declaredCaption } else { "任务编辑卡" }
        return buildCard(root.nodeId, root.semanticId, captionElement.nodeId, title.nodeId, notes.nodeId,
            caption, title.label, title.draftText, title.writerOperation, title.bindingResourceId,
            title.ownerTargetResourceId, notes.label, notes.draftText, notes.writerOperation,
            notes.bindingResourceId, notes.ownerTargetResourceId,
            style: CjguiComposableUiStyle(fixedHeight: 26))
    }
}
