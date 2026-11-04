package cjgui_ui_only_starter

import cjgui.*
import std.env.*
import std.fs.*

/// A small local controller: it owns only the human-facing note and counter.
/// There is intentionally no descriptor, socket, authorization, or Agent
/// dependency in this starter.
class UiOnlyStarterController <: CjguiComposableUiController {
    private var work: UiOnlyWorkState = UiOnlyWorkState("", 0, 1)
    private var revision: Int64 = 1
    private var workSession: ?CjguiComposableUiWorkSession = None
    private var workStatus: String = ""
    private var startupIssue: String = ""

    public init(workSessionPath!: String = "") {
        if (workSessionPath.size > 0) {
            let session = CjguiComposableUiWorkSession(workSessionPath,
                "ui-only.note-counter.v1", 65536,
                { payload => uiOnlyDecodeWorkPayload(payload).isSome() })
            this.workSession = Some(session)
            if (exists(workSessionPath)) {
                let loaded = session.load()
                if (!loaded.ok) {
                    startupIssue = loaded.reason
                } else {
                    // The app's complete candidate was checked before the shared
                    // binding adopted its baseline. No native identity is loaded.
                    work = uiOnlyDecodeWorkPayload(loaded.payload).getOrThrow()
                    workStatus = "已恢复工作会话"
                }
            } else {
                workStatus = "工作会话尚未保存"
            }
        }
    }

    public func startupFailure(): String { return startupIssue }

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
        content.add(cjguiComposableTextInput(6, "ui-only-note", "短注释", work.note, 0, theme.input,
            fieldId: "note", operationActionName: "EDIT_TEXT", displayValueRole: "local"))
        content.add(cjguiComposableButton(7, "ui-only-increment", "计数 +1", "INCREMENT", 0,
            action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableText(8, "ui-only-status", "已点击 ${work.count} 次；注释：${work.note}", theme.body))
        if (let Some(session) <- workSession) {
            content.add(cjguiComposableButton(10, "ui-only-save-work-session", "保存工作会话",
                "SAVE_WORK_SESSION", 0, action.localStyle(), interactionStyle: action.interaction))
            content.add(cjguiComposableButton(11, "ui-only-discard-work-session", "放弃会话更改并关闭",
                "DISCARD_WORK_SESSION_CLOSE", 0, action.localStyle(), interactionStyle: action.interaction))
            let dirty = if (session.isDirty(work.payload())) { "未保存" } else { "已保存" }
            content.add(cjguiComposableText(12, "ui-only-work-session-status",
                "${workStatus} · ${dirty} · 业务版本 ${work.revision}", theme.body))
        }
        root.add(content)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 6) {
            if (event.text.size > 8192) { return CjguiComposableUiDispatchResult(false) }
            work.note = event.text
            work.revision += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "INCREMENT") {
            if (work.count >= 1000000) { return CjguiComposableUiDispatchResult(false) }
            work.count += 1
            work.revision += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "SAVE_WORK_SESSION") {
            if (let Some(session) <- workSession) {
                let saved = session.save(work.payload())
                workStatus = if (saved.ok) { "已保存工作会话" } else { "工作会话保存失败：${saved.reason}" }
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        if (event.eventKind == 27 && event.node.actionName == "DISCARD_WORK_SESSION_CLOSE" &&
            workSession.isSome()) {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        if (let Some(session) <- workSession) {
            if (session.isDirty(work.payload())) {
                workStatus = "请先保存工作会话，或选择放弃会话更改并关闭"
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    var workSessionPath = ""
    if (args.size == 2 && args[0] == "--work-session" && args[1].size > 0) {
        workSessionPath = args[1]
    } else if (args.size != 0) { return 2 }
    let controller = UiOnlyStarterController(workSessionPath: workSessionPath)
    if (controller.startupFailure().size > 0) {
        getStdErr().writeln("CJGUI_UI_ONLY_WORK_SESSION_REFUSED ${controller.startupFailure()}")
        return 2
    }
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("我的本地工具", 680u32,
            if (workSessionPath.size > 0) { 620u32 } else { 460u32 })
    )
    if (!host.start()) { host.close(); return 1 }
    getStdOut().writeln("CJGUI_UI_ONLY_READY")
    getStdOut().flush()
    while (host.isOpen()) { let _ = host.pumpOneTurn() }
    host.close()
    return 0
}
