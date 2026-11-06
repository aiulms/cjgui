package cjgui

/// Read-only explanation of an accepted layout declaration and its actual
/// parent allocation. It retains no label, value, controller or native handle.
/// Sources describe declared intent, not a fabricated solver trace.
public class CjguiComposableUiDiagnosticLayout {
    public let declaredStyle: CjguiComposableUiStyle
    public let parentContentBounds: CjguiComposableUiRect
    /// Rectangle facts in layout coordinates, not visual transforms,
    /// rounded-mask containment, sibling occlusion or an error verdict.
    public let overflowsParentContent: Bool
    public let clippedByAncestors: Bool
    /// Both projected label and value are empty; not a business-body query.
    public let labelAndValueEmpty: Bool
    public let interactionState: Int64

    private init(node: CjguiComposableUiLayoutNode, parentContent: CjguiComposableUiRect, state: Int64) {
        this.declaredStyle = node.declaredStyle
        this.parentContentBounds = parentContent
        this.overflowsParentContent = node.bounds.x < parentContent.x || node.bounds.y < parentContent.y ||
            node.bounds.x + node.bounds.width > parentContent.x + parentContent.width ||
            node.bounds.y + node.bounds.height > parentContent.y + parentContent.height
        let visible = node.bounds.intersect(node.clip)
        this.clippedByAncestors = visible.width < node.bounds.width || visible.height < node.bounds.height
        this.labelAndValueEmpty = node.value.size == 0 && node.label.size == 0
        this.interactionState = state
    }

    public static func fromNode(node: CjguiComposableUiLayoutNode, parent: ?CjguiComposableUiLayoutNode,
        viewport: CjguiComposableUiRect, state: Int64): CjguiComposableUiDiagnosticLayout {
        let content = if (let Some(value) <- parent) {
            let padding = value.declaredStyle.padding
            let width = value.bounds.width - 2 * padding
            let height = value.bounds.height - 2 * padding
            CjguiComposableUiRect(value.bounds.x + padding, value.bounds.y + padding, if (width > 0) {
                width
            } else {
                0
            }, if (height > 0) {
                height
            } else {
                0
            })
        } else {
            viewport
        }
        return CjguiComposableUiDiagnosticLayout(node, content, state)
    }

    public func constraintSummary(): String {
        let s = declaredStyle
        return "fixed=${s.fixedWidth}/${s.fixedHeight}; min=${s.minWidth}/${s.minHeight}; " +
            "ideal=${s.idealWidth}/${s.idealHeight}; max=${s.maxWidth}/${s.maxHeight}; " +
            "grow=${s.growX}/${s.growY}; placement=${s.alignX}/${s.alignY}; padding=${s.padding}; gap=${s.gap}; " +
            "parentContent=${parentContentBounds.x},${parentContentBounds.y},${parentContentBounds.width},${parentContentBounds.height}; " +
            "overflow=${overflowsParentContent}; clipped=${clippedByAncestors}; labelAndValueEmpty=${labelAndValueEmpty}"
    }

    public func stateSummary(): String {
        var result = ""
        if ((interactionState & CjguiComposableUiInteractionState.SELECTED) != 0) {
            result += "selected "
        }
        if ((interactionState & CjguiComposableUiInteractionState.CHECKED) != 0) {
            result += "checked "
        }
        if ((interactionState & CjguiComposableUiInteractionState.FOCUSED) != 0) {
            result += "focused "
        }
        if ((interactionState & CjguiComposableUiInteractionState.HOVER) != 0) {
            result += "hover "
        }
        if ((interactionState & CjguiComposableUiInteractionState.PRESSED) != 0) {
            result += "pressed "
        }
        if ((interactionState & CjguiComposableUiInteractionState.DISABLED) != 0) {
            result += "disabled "
        }
        return if (result.size == 0) {
            "normal"
        } else {
            result.trimAscii()
        }
    }
}
