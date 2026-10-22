/// Minimal visual counterexamples for three Linux paint seams:
/// node-local gradient coordinates with non-midpoint 3/4 stops, thick borders
/// whose radius is smaller than the stroke width, and an empty rounded-clip
/// intersection that must stay empty instead of reverting to no clip.
package cjgui_linux_render_seam_probe

import cjgui.*
import std.env.*

private func seamThreeStopGradient(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
        stops: [
            CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.92, 0.16, 0.18, 1.0)),
            CjguiComposableUiGradientStop(position: 0.25, color: CjguiComposableUiColor(0.16, 0.82, 0.32, 1.0)),
            CjguiComposableUiGradientStop(position: 0.80, color: CjguiComposableUiColor(0.18, 0.36, 0.95, 1.0))
        ])
}

private func seamFourStopGradient(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
        stops: [
            CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.95, 0.85, 0.20, 1.0)),
            CjguiComposableUiGradientStop(position: 0.10, color: CjguiComposableUiColor(0.92, 0.20, 0.55, 1.0)),
            CjguiComposableUiGradientStop(position: 0.35, color: CjguiComposableUiColor(0.16, 0.72, 0.86, 1.0)),
            CjguiComposableUiGradientStop(position: 0.90, color: CjguiComposableUiColor(0.30, 0.90, 0.40, 1.0))
        ])
}

// Two-stop gradient whose axis covers only the middle half of the box. Outside
// [startX, endX] the endpoint colours must stay flat; clamping the normalized
// parameter at the box vertices would stretch the ramp across the whole box.
private func seamBoundedGradient(): CjguiComposableUiLinearGradient {
    return CjguiComposableUiLinearGradient(startX: 0.25, startY: 0.0, endX: 0.75, endY: 0.0,
        stops: [
            CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0)),
            CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(0.0, 0.0, 1.0, 1.0))
        ])
}

private func seamGradientBox(nodeId: Int64, label: String,
    gradient: CjguiComposableUiLinearGradient): CjguiComposableUiNode {
    let box = cjguiComposableVertical(nodeId, "seam-gradient-${nodeId}",
        CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 70, gradient: gradient, padding: 6))
    box.add(cjguiComposableText(nodeId + 30, "seam-gradient-label-${nodeId}", label,
        CjguiComposableUiStyle(fixedHeight: 18, textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            fontSize: 11.0)))
    return box
}

private func seamBorderBox(nodeId: Int64, label: String, radius: Int64, width: Int64,
    color: CjguiComposableUiColor): CjguiComposableUiNode {
    let box = cjguiComposableVertical(nodeId, "seam-border-${nodeId}", CjguiComposableUiStyle(
        fixedWidth: 150, fixedHeight: 76, cornerRadius: radius, borderWidth: width, border: color,
        background: CjguiComposableUiColor(0.10, 0.14, 0.22, 1.0), padding: 8))
    box.add(cjguiComposableText(nodeId + 30, "seam-border-label-${nodeId}", label,
        CjguiComposableUiStyle(fixedHeight: 18, textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            fontSize: 12.0)))
    return box
}

class SeamProbeController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 {
        return 1
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let root = cjguiComposableVertical(1, "seam-root",
            CjguiComposableUiStyle(padding: 16, gap: 8, background: theme.page.background))
        root.add(cjguiComposableText(2, "seam-title", "Linux 渲染接缝反例",
            CjguiComposableUiStyle(fixedHeight: 30, fontSize: 22.0, fontWeight: 700, textColor: theme.heading.textColor)))
        root.add(cjguiComposableText(3, "seam-note",
            "同一渐变在两个不同横坐标节点上必须完全一致；粗描边半径小于线宽时整圈仍存在；空圆角裁剪不得退化为无裁剪。",
            CjguiComposableUiStyle(fixedHeight: 22, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        let threeRow = cjguiComposableHorizontal(4, "seam-three-row", CjguiComposableUiStyle(fixedHeight: 76, gap: 16))
        threeRow.add(seamGradientBox(5, "3-stop @ x=16", seamThreeStopGradient()))
        threeRow.add(seamGradientBox(6, "3-stop @ x=252", seamThreeStopGradient()))
        root.add(threeRow)
        let fourRow = cjguiComposableHorizontal(7, "seam-four-row", CjguiComposableUiStyle(fixedHeight: 76, gap: 16))
        fourRow.add(seamGradientBox(8, "4-stop @ x=16", seamFourStopGradient()))
        fourRow.add(seamGradientBox(9, "4-stop @ x=252", seamFourStopGradient()))
        root.add(fourRow)
        let boundedRow = cjguiComposableHorizontal(25, "seam-bounded-row",
            CjguiComposableUiStyle(fixedHeight: 76, gap: 16))
        boundedRow.add(seamGradientBox(26, "bounded 0.25..0.75 @ x=16", seamBoundedGradient()))
        root.add(boundedRow)
        let borderRow = cjguiComposableHorizontal(10, "seam-border-row", CjguiComposableUiStyle(fixedHeight: 88, gap: 16))
        borderRow.add(seamBorderBox(11, "r=6 w=12", 6, 12, CjguiComposableUiColor(1.0, 0.72, 0.20, 1.0)))
        borderRow.add(seamBorderBox(12, "r=4 w=10", 4, 10, CjguiComposableUiColor(0.30, 0.94, 0.62, 1.0)))
        borderRow.add(seamBorderBox(13, "r=0 w=12", 0, 12, CjguiComposableUiColor(0.96, 0.36, 0.72, 1.0)))
        root.add(borderRow)
        let clipRow = cjguiComposableHorizontal(14, "seam-clip-row", CjguiComposableUiStyle(fixedHeight: 216, gap: 20))
        // Empty intersection: the 20x20 child sits at the square top-left
        // corner, entirely outside the parent's r=100 aperture.
        let emptyParent = cjguiComposableVertical(15, "seam-clip-empty", CjguiComposableUiStyle(
            fixedWidth: 200, fixedHeight: 200, cornerRadius: 100, clipsContent: true,
            background: CjguiComposableUiColor(0.14, 0.20, 0.32, 1.0),
            borderWidth: 2, border: CjguiComposableUiColor(0.40, 0.58, 0.90, 1.0)))
        emptyParent.add(cjguiComposableVertical(16, "seam-clip-empty-child",
            CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 20, cornerRadius: 6,
                background: CjguiComposableUiColor(1.0, 0.10, 0.10, 1.0))))
        clipRow.add(emptyParent)
        // Non-empty control: the same child at the aperture centre stays painted.
        let keptParent = cjguiComposableVertical(17, "seam-clip-kept", CjguiComposableUiStyle(
            fixedWidth: 200, fixedHeight: 200, cornerRadius: 100, clipsContent: true, padding: 90,
            background: CjguiComposableUiColor(0.14, 0.20, 0.32, 1.0),
            borderWidth: 2, border: CjguiComposableUiColor(0.40, 0.58, 0.90, 1.0)))
        keptParent.add(cjguiComposableVertical(18, "seam-clip-kept-child",
            CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 20, cornerRadius: 6,
                background: CjguiComposableUiColor(0.10, 0.90, 0.30, 1.0))))
        clipRow.add(keptParent)
        let labelColumn = cjguiComposableVertical(19, "seam-clip-labels",
            CjguiComposableUiStyle(fixedWidth: 260, gap: 8))
        labelColumn.add(cjguiComposableText(20, "seam-clip-label-a", "左：空裁剪（角外子节点不可见）",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        labelColumn.add(cjguiComposableText(21, "seam-clip-label-b", "中：同尺寸子节点在孔径中心可见",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        labelColumn.add(cjguiComposableText(22, "seam-clip-label-c", "裁剪只作用于子树，不撤销祖先孔径",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 12.0, textColor: theme.body.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        clipRow.add(labelColumn)
        root.add(clipRow)
        let actions = cjguiComposableHorizontal(23, "seam-actions", CjguiComposableUiStyle(fixedHeight: 38))
        actions.add(cjguiComposableButton(24, "seam-close", "关闭", "CLOSE", -1,
            CjguiComposableUiStyle(fixedWidth: 90, fixedHeight: 34, background: theme.card.background,
                border: theme.card.border, textColor: theme.body.textColor)))
        root.add(actions)
        let host = cjguiComposableLayerHost(100, "seam-layer-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(root)
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let host = cjguiCreatePlatformApplicationHost(SeamProbeController(),
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Linux 渲染接缝反例", 900u32, 720u32))
    if (!host.start()) {
        host.close()
        return 1
    }
    println("CJGUI_SEAM_PROBE_READY")
    getStdOut().flush()
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    println("CJGUI_SEAM_PROBE_CLOSED")
    getStdOut().flush()
    host.close()
    return 0
}
