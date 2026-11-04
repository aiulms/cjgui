package cjgui_ui_only_starter

import cjgui.*
import std.collection.*
import std.env.*

/// Shared UI-only form starter. The controller is platform-neutral; the
/// window host comes from the common factory, so Linux/macOS consume the same
/// business and UI code and only their build adapters differ.
private func uiOnlyHex(bytes: Array<UInt8>): String {
    let digits = "0123456789abcdef".toArray()
    let output = ArrayList<UInt8>()
    for (byte in bytes) {
        let value = UInt64(byte)
        output.add(digits[Int64(value / 16u64)])
        output.add(digits[Int64(value % 16u64)])
    }
    return String.fromUtf8(output.toArray())
}

class UiOnlyStarterController <: CjguiComposableUiController {
    private var noteA: String = ""
    private var noteB: String = ""
    private var count: Int64 = 0
    private var revision: Int64 = 1
    private var dialogOpen: Bool = false
    private var imageAVersion: Int64 = 1
    private var imageAMode: Int64 = 1
    private var imageBVisible: Bool = true

    public func uiSceneVersion(): Int64 { return revision }

    /// One owner receipt per accepted edit; external truth is the same
    /// controller state the status row renders, not a second draft.
    private func ownerReceipt(): Unit {
        getStdOut().writeln("CJGUI_UI_ONLY_OWNER a_hex=${uiOnlyHex(noteA.toArray())} " +
            "b_hex=${uiOnlyHex(noteB.toArray())} count=${count} revision=${revision} dialog=${dialogOpen} " +
            "image_a_version=${imageAVersion} image_a_mode=${imageAMode} " +
            "image_b_visible=${imageBVisible} image_b_version=1")
        getStdOut().flush()
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let action = CjguiComposableUiNamedStyle("ui-only-action",
            theme.primaryAction, interaction: theme.primaryActionInteraction,
            purpose: "主操作按钮")
        let root = cjguiComposableLayerHost(1, "ui-only-root", theme.page)
        let content = cjguiComposableVertical(2, "ui-only-content", CjguiComposableUiStyle(
            padding: 16, gap: 8, growY: 1, cornerRadius: 18, clipsContent: true,
            background: CjguiComposableUiColor(0.12, 0.18, 0.30, 0.86),
            border: CjguiComposableUiColor(0.25, 0.38, 0.60, 0.82)
        ))
        content.add(cjguiComposableText(3, "ui-only-title", "我的本地工具", theme.heading))
        content.add(cjguiComposableText(4, "ui-only-help",
            "两张本地图片、两个字段、轻量弹层；内容仅由此 controller 持有。", theme.body))
        // 两张图片同时声明、同时准备；替换只递增 A 的版本，移除 B 只是不声明
        // 该节点。解码、缓存、纹理与回收全部由框架图片域负责。
        let imageStrip = cjguiComposableHorizontal(12, "ui-only-image-strip",
            CjguiComposableUiStyle(gap: 8))
        let imageFrameA = cjguiComposableVertical(5, "ui-only-image-frame-a",
            CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 96, cornerRadius: 12,
                clipsContent: true, background: CjguiComposableUiColor(0.06, 0.09, 0.16, 1.0)))
        imageFrameA.add(cjguiComposableImage(10, "ui-only-beacon-a", "composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 90),
            imageResourceId: "ui-only-beacon-a", imageResourceVersion: imageAVersion,
            contentMode: imageAMode))
        imageStrip.add(imageFrameA)
        if (imageBVisible) {
            let imageFrameB = cjguiComposableVertical(14, "ui-only-image-frame-b",
                CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 96, cornerRadius: 12,
                    clipsContent: true,
                    background: CjguiComposableUiColor(0.06, 0.09, 0.16, 1.0)))
            imageFrameB.add(cjguiComposableImage(15, "ui-only-beacon-b",
                "composable-beacon-coral.png",
                CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 96),
                imageResourceId: "ui-only-beacon-b", imageResourceVersion: 1,
                contentMode: 2))
            imageStrip.add(imageFrameB)
        }
        content.add(imageStrip)
        let input = CjguiComposableUiStyle(
            fixedHeight: theme.input.fixedHeight, background: theme.input.background,
            border: theme.input.border, textColor: theme.input.textColor,
            pointerInteractive: true)
        content.add(cjguiComposableTextInput(6, "ui-only-note-a", "字段 A", noteA, 0, input,
            fieldId: "noteA", operationActionName: "EDIT_TEXT", displayValueRole: "local",
            interactionStyle: theme.inputInteraction))
        content.add(cjguiComposableTextInput(7, "ui-only-note-b", "字段 B", noteB, 0, input,
            fieldId: "noteB", operationActionName: "EDIT_TEXT", displayValueRole: "local",
            interactionStyle: theme.inputInteraction))
        content.add(cjguiComposableButton(8, "ui-only-open-dialog", "打开弹层", "OPEN_DIALOG", 0,
            action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableButton(11, "ui-only-replace-image", "替换图片", "REPLACE_IMAGE", 0,
            action.localStyle(), interactionStyle: action.interaction))
        if (imageBVisible) {
            content.add(cjguiComposableButton(16, "ui-only-remove-image", "移除图片", "REMOVE_IMAGE", 0,
                action.localStyle(), interactionStyle: action.interaction))
        }
        content.add(cjguiComposableText(9, "ui-only-status",
            "A：${noteA}｜B：${noteB}｜点击 ${count}", theme.body))
        root.add(content)
        if (dialogOpen) {
            // The field is the dialog owner so the modal's return transaction
            // restores the text field (and its bookmark) after cancel/Escape.
            let dialog = cjguiComposableDialogLayer(20, "ui-only-dialog", "ui-only-dialog",
                "ui-only-note-a", 6,
                CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 190, padding: 16, gap: 10,
                    cornerRadius: 16, background: CjguiComposableUiColor(0.08, 0.12, 0.22, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0)),
                initialFocusNodeId: 23)
            dialog.add(cjguiComposableText(21, "ui-only-dialog-title", "轻量弹层", theme.heading))
            dialog.add(cjguiComposableText(22, "ui-only-dialog-hint", "取消后返回字段 A 继续编辑。", theme.body))
            dialog.add(cjguiComposableButton(23, "ui-only-dialog-cancel", "取消", "CANCEL_DIALOG", 0,
                action.localStyle(), interactionStyle: action.interaction))
            root.add(dialog)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28) {
            if (event.node.nodeId == 6) {
                noteA = event.text
                revision += 1
                ownerReceipt()
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.nodeId == 7) {
                noteB = event.text
                revision += 1
                ownerReceipt()
                return CjguiComposableUiDispatchResult(true)
            }
        }
        if (event.eventKind == 27 && event.node.actionName == "OPEN_DIALOG") {
            dialogOpen = true
            revision += 1
            ownerReceipt()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "REPLACE_IMAGE") {
            // 只递增 A 的资源版本并切换 fit/fill；路径与文件内容由打包/测试夹具
            // 替换，框架图片域负责重新解码、上传并回收旧纹理。
            imageAVersion += 1
            imageAMode = if (imageAMode == 1) { 2 } else { 1 }
            revision += 1
            ownerReceipt()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "REMOVE_IMAGE") {
            if (imageBVisible) {
                imageBVisible = false
                revision += 1
                ownerReceipt()
            }
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "CANCEL_DIALOG") {
            dialogOpen = false
            noteA = noteA + "!"
            revision += 1
            ownerReceipt()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 36) {
            // Escape dismisses the active layer through the common channel;
            // closing the dialog is this controller's business decision.
            if (dialogOpen) {
                dialogOpen = false
                revision += 1
                ownerReceipt()
                return CjguiComposableUiDispatchResult(true)
            }
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

/// Two thin edit windows over one owner. Each window declares exactly one
/// existing A/B text field and the same public EDIT_TEXT operation; the host,
/// not the application, owns open/close/reopen/exit settlement. The default
/// single-window entry below is unchanged.
@When[os == "Linux"]
class UiOnlyTwoWindowNotes {
    private var noteA: String = ""
    private var noteB: String = ""
    private var revision: Int64 = 1

    func value(field: Int64): String {
        return if (field == 6) { noteA } else { noteB }
    }

    func version(): Int64 { return revision }

    func write(field: Int64, text: String): Unit {
        if (field == 6) { noteA = text } else { noteB = text }
        revision += 1
        getStdOut().writeln("CJGUI_UI_ONLY_OWNER a_hex=${uiOnlyHex(noteA.toArray())} " +
            "b_hex=${uiOnlyHex(noteB.toArray())} count=0 revision=${revision} dialog=false " +
            "image_a_version=1 image_a_mode=1 image_b_visible=true image_b_version=1")
        getStdOut().flush()
    }
}

@When[os == "Linux"]
private func uiOnlyRequestName(status: CjguiLinuxWindowRequestStatus): String {
    return match (status) {
        case CjguiLinuxWindowRequestStatus.Pending => "pending"
        case CjguiLinuxWindowRequestStatus.Applied => "applied"
        case CjguiLinuxWindowRequestStatus.Failed => "failed"
        case CjguiLinuxWindowRequestStatus.Superseded => "superseded"
    }
}

@When[os == "Linux"]
class UiOnlyThinEditController <: CjguiComposableUiController {
    private let notes: UiOnlyTwoWindowNotes
    private let fieldId: Int64
    private let title: String
    private let secondaryLabel: String
    private let secondaryAction: (Int64) -> String
    private var window: ?CjguiComposableUiWindow = None
    private var dialogOpen: Bool = false
    private var localRevision: Int64 = 1
    private var secondaryClicks: Int64 = 0
    private var actionMessage: String = ""

    init(notes: UiOnlyTwoWindowNotes, fieldId: Int64, title: String, secondaryLabel: String,
        secondaryAction: (Int64) -> String) {
        this.notes = notes
        this.fieldId = fieldId
        this.title = title
        this.secondaryLabel = secondaryLabel
        this.secondaryAction = secondaryAction
    }

    func bindWindow(window: CjguiComposableUiWindow): Unit {
        this.window = Some(window)
    }

    public func uiSceneVersion(): Int64 {
        return notes.version() * 1000003 + localRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let action = CjguiComposableUiNamedStyle("ui-only-two-action",
            theme.primaryAction, interaction: theme.primaryActionInteraction,
            purpose: "薄编辑窗操作")
        let root = cjguiComposableLayerHost(1, "ui-only-two-root", theme.page)
        let content = cjguiComposableVertical(2, "ui-only-two-content", CjguiComposableUiStyle(
            padding: 16, gap: 8, growY: 1, cornerRadius: 18,
            background: CjguiComposableUiColor(0.12, 0.18, 0.30, 0.86),
            border: CjguiComposableUiColor(0.25, 0.38, 0.60, 0.82)
        ))
        content.add(cjguiComposableText(3, "ui-only-two-title", title, theme.heading))
        content.add(cjguiComposableText(4, "ui-only-two-help",
            "本窗只声明一个既有 A/B 字段；输入只写入该字段。", theme.body))
        let input = CjguiComposableUiStyle(
            fixedHeight: theme.input.fixedHeight, background: theme.input.background,
            border: theme.input.border, textColor: theme.input.textColor,
            pointerInteractive: true)
        let fieldName = if (fieldId == 6) { "字段 A" } else { "字段 B" }
        content.add(cjguiComposableTextInput(fieldId, "ui-only-two-input", fieldName,
            notes.value(fieldId), 0, input,
            fieldId: if (fieldId == 6) { "noteA" } else { "noteB" },
            operationActionName: "EDIT_TEXT", displayValueRole: "local",
            interactionStyle: theme.inputInteraction))
        content.add(cjguiComposableButton(8, "ui-only-two-dialog-open", "打开说明", "OPEN_DIALOG", 0,
            action.localStyle(), interactionStyle: action.interaction))
        if (secondaryLabel.size > 0) {
            content.add(cjguiComposableButton(11, "ui-only-two-secondary", secondaryLabel, "THIN_SECONDARY", 0,
                action.localStyle(), interactionStyle: action.interaction))
        }
        content.add(cjguiComposableText(9, "ui-only-two-status",
            "A：${notes.value(6)}｜B：${notes.value(7)}｜v${notes.version()}" +
                (if (actionMessage.size > 0) { "｜${actionMessage}" } else { "" }), theme.body))
        root.add(content)
        if (dialogOpen) {
            // The field is the dialog owner so the modal's return transaction
            // restores this window's text field (and its bookmark) after
            // cancel/Escape, rather than the button that opened the dialog.
            let dialog = cjguiComposableDialogLayer(20, "ui-only-two-dialog", "ui-only-two-dialog",
                "ui-only-two-input", fieldId,
                CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 190, padding: 16, gap: 10,
                    cornerRadius: 16, background: CjguiComposableUiColor(0.08, 0.12, 0.22, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0)),
                initialFocusNodeId: 23)
            dialog.add(cjguiComposableText(21, "ui-only-two-dialog-title", "轻量弹层", theme.heading))
            dialog.add(cjguiComposableText(22, "ui-only-two-dialog-hint",
                "取消后返回${fieldName}继续编辑。", theme.body))
            dialog.add(cjguiComposableButton(23, "ui-only-two-dialog-cancel", "取消", "CANCEL_DIALOG", 0,
                action.localStyle(), interactionStyle: action.interaction))
            root.add(dialog)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == fieldId) {
            notes.write(fieldId, event.text)
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "OPEN_DIALOG") {
            dialogOpen = true
            localRevision += 1
            getStdOut().writeln("CJGUI_UI_ONLY_TWO field=${fieldId} dialog=open")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "THIN_SECONDARY") {
            actionMessage = secondaryAction(secondaryClicks)
            getStdOut().writeln("CJGUI_UI_ONLY_TWO field=${fieldId} secondary index=${secondaryClicks} ${actionMessage}")
            getStdOut().flush()
            secondaryClicks += 1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "CANCEL_DIALOG") {
            dialogOpen = false
            localRevision += 1
            // The dialog declares this field as its owner; the common return
            // transaction restores the field and its caret/bookmark. Calling
            // focusAcceptedNodeById here resets the caret and breaks that.
            getStdOut().writeln("CJGUI_UI_ONLY_TWO field=${fieldId} dialog=cancel")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 36 && dialogOpen) {
            dialogOpen = false
            localRevision += 1
            getStdOut().writeln("CJGUI_UI_ONLY_TWO field=${fieldId} dialog=escape")
            getStdOut().flush()
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

@When[os == "Linux"]
class UiOnlyTwoWindowApp {
    let group = CjguiLinuxApplicationHostGroup()
    let notes = UiOnlyTwoWindowNotes()
    var firstAId: Int64 = 0
    var activeAId: Int64 = 0

    func makeA(windowId: Int64): CjguiLinuxApplicationHost {
        activeAId = windowId
        let controller = UiOnlyThinEditController(notes, 6, "字段 A · 薄编辑窗", "", { _ => "" })
        let host = CjguiLinuxApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("字段 A · 薄编辑窗", 520u32, 320u32))
        controller.bindWindow(host.window())
        return host
    }

    func makeB(windowId: Int64): CjguiLinuxApplicationHost {
        let _ = windowId
        let controller = UiOnlyThinEditController(notes, 7, "字段 B · 薄编辑窗",
            "重开 A 窗 / 旧引用检查", { index => secondary(index) })
        let host = CjguiLinuxApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("字段 B · 薄编辑窗", 520u32, 320u32))
        controller.bindWindow(host.window())
        return host
    }

    /// First click closes and reopens A (the host queues the open behind the
    /// retained close). Later clicks address the old identity: it must fail as
    /// stale rather than close the replacement window.
    func secondary(index: Int64): String {
        if (index == 0) {
            let previous = activeAId
            let close = group.requestClose(previous)
            let open = group.requestOpen("editor-a", { windowId => makeA(windowId) })
            return "重开 A：close=${uiOnlyRequestName(close.status())} " +
                "open=${uiOnlyRequestName(open.status())} old=${previous} new=${open.windowId}"
        }
        if (firstAId == 0 || activeAId == firstAId) {
            return "旧引用检查：替换窗尚未生效"
        }
        let stale = group.requestClose(firstAId)
        return "旧引用检查：${uiOnlyRequestName(stale.status())}:${stale.message()} new=${activeAId}"
    }
}

@When[os == "Linux"]
private func runUiOnlyTwoWindows(): Int64 {
    let app = UiOnlyTwoWindowApp()
    let group = app.group
    let a = group.requestOpen("editor-a", { windowId => app.makeA(windowId) })
    app.firstAId = a.windowId
    let b = group.requestOpen("editor-b", { windowId => app.makeB(windowId) })
    match (a.status()) {
        case CjguiLinuxWindowRequestStatus.Applied => ()
        case _ =>
            let _ = group.closeAll()
            return 1
    }
    match (b.status()) {
        case CjguiLinuxWindowRequestStatus.Applied => ()
        case _ =>
            let _ = group.closeAll()
            return 1
    }
    getStdOut().writeln("CJGUI_UI_ONLY_WINDOWS ready=2 a=${app.firstAId} b=${b.windowId}")
    getStdOut().flush()
    // Initial focus is per window generation, not a per-turn grab: a reopened
    // A (new host id) gets one focus attempt after its scene is accepted, and
    // the loop then leaves focus alone.
    var focusedAId: Int64 = 0
    var focusedBId: Int64 = 0
    let bId = b.windowId
    while (group.pumpOneTurn()) {
        if (app.activeAId != 0 && app.activeAId != focusedAId) {
            match (group.window("editor-a")) {
                case Some(host) =>
                    if (host.window().acceptedNodeCount() > 0 && host.window().focusAcceptedNodeById(6)) {
                        focusedAId = app.activeAId
                        getStdOut().writeln("CJGUI_UI_ONLY_WINDOWS focus=a id=${focusedAId}")
                        getStdOut().flush()
                    }
                case None => ()
            }
        }
        if (bId != 0 && focusedBId != bId) {
            match (group.window("editor-b")) {
                case Some(host) =>
                    if (host.window().acceptedNodeCount() > 0 && host.window().focusAcceptedNodeById(7)) {
                        focusedBId = bId
                        getStdOut().writeln("CJGUI_UI_ONLY_WINDOWS focus=b id=${bId}")
                        getStdOut().flush()
                    }
                case None => ()
            }
        }
    }
    let settled = group.closeAll()
    getStdOut().writeln("CJGUI_UI_ONLY_WINDOWS exit settled=${settled} windows=${group.count()}")
    getStdOut().flush()
    return if (settled) { 0 } else { 1 }
}

@When[os != "Linux"]
private func runUiOnlyTwoWindows(): Int64 {
    return 2
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--two-windows") {
        return Int64(runUiOnlyTwoWindows())
    }
    if (args.size != 0) { return 2 }
    let controller = UiOnlyStarterController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI UI Only Starter", 680u32, 560u32))
    if (!host.start()) { host.close(); return 1 }
    getStdOut().writeln("CJGUI_UI_ONLY_READY")
    getStdOut().flush()
    // wait for the first accepted scene, then focus field A exactly once.
    // pumpOneTurn() returning true only means the host is open; it does not
    // mean a scene was accepted. Never re-focus in the pump loop.
    var acceptedReady = false
    while (host.isOpen() && !acceptedReady) {
        let _ = host.pumpOneTurn()
        acceptedReady = host.window().acceptedNodeCount() > 0
    }
    if (acceptedReady && host.window().focusAcceptedNodeById(6)) {
        getStdOut().writeln("CJGUI_UI_ONLY_FOCUS node=6")
        getStdOut().flush()
    }
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    host.close()
    return 0
}
