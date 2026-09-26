package cjgui

/// Builds one ordinary composable node whose value is a validated, immutable
/// vector declaration. Logical points are in the Geometry viewBox and scale
/// to this node's resolved layout bounds; the component has no Metal/AppKit
/// handle and does not create a canvas/event-loop owner. Decorations are
/// non-interactive by default. Setting `interactive` plus a non-empty action
/// makes only the accepted geometry (not its bounding box) eligible for the
/// existing composable activation route.
public func cjguiComposableVectorGraphic(nodeId: Int64, semanticId: String,
    geometry: CjguiComposableUiVectorGeometry, style: CjguiComposableUiStyle,
    interactive!: Bool = false, actionName!: String = "", resourceId!: Int64 = -1,
    enabled!: Bool = true, operationActionName!: String = "", operationResourceId!: Int64 = -1,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    let resolvedAction = if (interactive && actionName.size > 0) {
        actionName
    } else {
        ""
    }
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VECTOR_GRAPHIC, semanticId,
        cjguiComposableUiVectorNativePayload(geometry), resolvedAction, resourceId, style, enabled: enabled,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState)
}
