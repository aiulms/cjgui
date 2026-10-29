package cjgui_ui_only_starter

import cjgui.*
import std.env.*

/// A small local controller: it owns only the human-facing note and counter.
/// There is intentionally no descriptor, socket, authorization, or Agent
/// dependency in this starter.
class UiOnlyStarterController <: CjguiComposableUiController {
    private var note: String = ""
    private var count: Int64 = 0
    private var revision: Int64 = 1

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        // ONE role pick gives a component both its base paint and its
        // interaction states: the named style carries the theme's action
        // definition and the component consumes the pair together.
        let action = CjguiComposableUiNamedStyle("ui-only-action",
            theme.primaryAction, interaction: theme.primaryActionInteraction,
            purpose: "主操作按钮")
        // This is ordinary public composition: the base card, image and a
        // normal status row share the one resolved scene and renderer.
        let root = cjguiComposableLayerHost(1, "ui-only-root", theme.page)
        let content = cjguiComposableVertical(2, "ui-only-content", CjguiComposableUiStyle(
            padding: 16, gap: 10, growY: 1, cornerRadius: 18, clipsContent: true,
            background: CjguiComposableUiColor(0.12, 0.18, 0.30, 0.86),
            border: CjguiComposableUiColor(0.25, 0.38, 0.60, 0.82)
        ))
        content.add(cjguiComposableText(3, "ui-only-title", "我的本地工具", theme.heading))
        content.add(cjguiComposableText(4, "ui-only-help", "这是纯 UI 应用；内容仅由此 controller 持有。", theme.body))
        content.add(cjguiComposableImage(5, "ui-only-beacon", "composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 72, cornerRadius: 14, clipsContent: true),
            imageResourceId: "ui-only-beacon", imageResourceVersion: 1))
        // The SAME ordinary image + the thinnest resource composition: a local
        // RGB JPEG resolved from the app bundle, no generated region required.
        let jpegSwatch = CjguiGeneratedUiImageResourceSpec("ui-only-swatch", "JPEG", 1,
            "四色色块 JPEG", "preview-swatch.jpg")
        content.add(cjguiComposableImageResource(9, "ui-only-jpeg", jpegSwatch,
            CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, cornerRadius: 10,
                clipsContent: true), contentMode: 1))
        content.add(cjguiComposableTextInput(6, "ui-only-note", "短注释", note, 0, theme.input,
            fieldId: "note", operationActionName: "EDIT_TEXT", displayValueRole: "local"))
        content.add(cjguiComposableButton(7, "ui-only-increment", "计数 +1", "INCREMENT", 0,
            action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableText(8, "ui-only-status", "已点击 ${count} 次；注释：${note}", theme.body))
        root.add(content)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 6) {
            note = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "INCREMENT") {
            count += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let host = CjguiMacosApplicationHost(
        UiOnlyStarterController(),
        configuration: CjguiMacosApplicationWindowConfiguration("我的本地工具", 680u32, 460u32)
    )
    if (!host.start()) { host.close(); return 1 }
    getStdOut().writeln("CJGUI_UI_ONLY_READY")
    getStdOut().flush()
    while (host.isOpen()) { let _ = host.pumpOneTurn() }
    host.close()
    return 0
}
