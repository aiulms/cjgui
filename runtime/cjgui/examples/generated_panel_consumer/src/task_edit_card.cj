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
    /// The SAME application image declaration the handwritten pane resolves, so
    /// the card's icon and the handwritten beacon cannot drift apart.
    private let icon: CjguiGeneratedUiImageResourceSpec

    public init(icon: CjguiGeneratedUiImageResourceSpec) {
        this.icon = icon
    }

    /// Registers the card kind. The declared properties are the ONLY ones an
    /// external description may submit; the field references are validated
    /// against the consumer's own single field definition list.
    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog,
                                    icon: CjguiGeneratedUiImageResourceSpec): Bool {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 24))
        properties.add(CjguiGeneratedUiPropertySpec("caption", "STRING", maxLength: 60))
        properties.add(CjguiGeneratedUiPropertySpec("iconSize", "INTEGER", minimum: 16, maximum: 96))
        // The framework's shared style vocabulary, so a description can size,
        // grow, align and font the whole card the same way it styles a built-in
        // node; the factory below really applies it.
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            properties.add(property)
        }
        let elements = ArrayList<CjguiCompositeElementSpec>()
        elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
        elements.add(CjguiCompositeElementSpec("caption", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
        // The card's icon is an ordinary container element whose node the factory
        // mounts as the image resolved from the application's declaration; the
        // expansion budget grows by exactly that one node.
        elements.add(CjguiCompositeElementSpec("icon", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
        // The writer's argument comes from the consumer's single field definition,
        // never from a literal repeated here.
        elements.add(CjguiCompositeElementSpec("title", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "title", argumentName: CjguiTaskFields.definition("title").argument,
            parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("notes", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "notes", argumentName: CjguiTaskFields.definition("notes").argument,
            parentKey: "root"))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(KIND, properties, elements,
                expandedNodeLimit: 7, expandedDepthLimit: 3),
            CjguiTaskEditCardComposite(icon))
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
                                 cardGap!: Int64 = 4,
                                 iconNodeId!: Int64 = -1,
                                 icon!: ?CjguiGeneratedUiImageResourceSpec = None,
                                 iconSize!: Int64 = 40,
                                 style!: CjguiComposableUiStyle = CjguiComposableUiStyle(),
                                 rootTranslateX!: Float64 = 0.0, rootTranslateY!: Float64 = 0.0,
                                 interaction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                                 titleEnabled!: Bool = true, notesEnabled!: Bool = true): CjguiComposableUiNode {
        // The card's gap is the caller's declared layout property, applied to the
        // one builder both the generated and a handwritten region call.
        let card = cjguiComposableVertical(nodeId, semanticId,
            CjguiComposableUiStyle(gap: cardGap, translateX: rootTranslateX, translateY: rootTranslateY))
        if (let Some(resource) <- icon) {
            if (iconNodeId > 0) {
                // The icon is mounted from the application declaration, not from a
                // path this file knows: replace the raster by declaring a new
                // version of the same key.
                card.add(cjguiComposableImage(iconNodeId, "${semanticId}-icon", resource.rasterPath,
                    CjguiComposableUiStyle(fixedWidth: iconSize, fixedHeight: iconSize,
                        cornerRadius: 8, clipsContent: true),
                    imageResourceId: resource.key, imageResourceVersion: resource.version))
            }
        }
        card.add(cjguiComposableText(captionNodeId, "${semanticId}-caption", caption,
            CjguiComposableUiStyle(fontSize: 13.0, textColor: style.textColor)))
        // The owner's CURRENT availability is consumed, not inferred from "a
        // target exists": a frozen title is shown disabled with the owner's own
        // reason, while notes stay editable. Target and identity are untouched.
        card.add(cjguiComposableTextInput(titleNodeId, "${semanticId}-title", titleLabel, titleValue,
            titleResourceId, style, enabled: titleEnabled && titleTarget >= 0, fieldId: "title",
            operationActionName: titleWriter, operationResourceId: titleTarget,
            displayValueRole: "draft", interactionStyle: interaction))
        card.add(cjguiComposableTextInput(notesNodeId, "${semanticId}-notes", notesLabel, notesValue,
            notesResourceId, style, enabled: notesEnabled && notesTarget >= 0, fieldId: "notes",
            operationActionName: notesWriter, operationResourceId: notesTarget,
            displayValueRole: "draft", interactionStyle: interaction))
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
        let iconElement = match (context.element("icon")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("icon", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let declaredCaption = context.property("caption")
        let caption = if (declaredCaption.size > 0) { declaredCaption } else { "任务编辑卡" }
        let cardGap = context.propertyInteger("gap", fallback: 4)
        // The declared style really reaches the built subtree: the framework
        // resolved it once, and the card passes the same values to the editors it
        // builds, keeping its own 26pt default height only when none was declared.
        let declared = context.resolvedStyle
        let geometry = CjguiComposableUiStyle(fixedWidth: declared.fixedWidth,
            fixedHeight: if (declared.fixedHeight > 0) { declared.fixedHeight } else { 26 },
            growX: declared.growX, growY: declared.growY, fontSize: declared.fontSize,
            fontWeight: declared.fontWeight, minWidth: declared.minWidth, maxWidth: declared.maxWidth,
            minHeight: declared.minHeight, maxHeight: declared.maxHeight, alignX: declared.alignX,
            alignY: declared.alignY)
        // The composite keeps its own geometry and takes the paint (and the
        // interaction paint) from the SAME named style the framework resolved.
        let editorStyle = cjguiComposableUiPaintOverlay(geometry, declared)
        let iconSize = context.propertyInteger("iconSize", fallback: 40)
        return buildCard(root.nodeId, root.semanticId, captionElement.nodeId, title.nodeId, notes.nodeId,
            caption, title.label, title.draftText, title.writerOperation, title.bindingResourceId,
            title.ownerTargetResourceId, notes.label, notes.draftText, notes.writerOperation,
            notes.bindingResourceId, notes.ownerTargetResourceId, cardGap: cardGap,
            iconNodeId: iconElement.nodeId, icon: Some(icon), iconSize: iconSize, style: editorStyle,
            rootTranslateX: declared.translateX, rootTranslateY: declared.translateY,
            interaction: context.resolvedInteraction,
            titleEnabled: title.ownerAvailable, notesEnabled: notes.ownerAvailable)
    }
}
