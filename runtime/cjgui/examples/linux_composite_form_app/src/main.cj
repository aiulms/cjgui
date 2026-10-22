/// Linux normal-application consumer: rounded/gradient visuals, a scrollable
/// image-and-form page, and one shared-operation owner used by both the human
/// window and an independent client. The Cangjie list remains the only truth;
/// the UI projects it and the external connection mutates the same object.
package cjgui_linux_composite_form_app

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

private let COMPOSITE_TITLE_NODE: Int64 = 40
private let COMPOSITE_NOTES_NODE: Int64 = 41

private func compositeRectText(window: CjguiComposableUiWindow, nodeId: Int64): String {
    return match (window.nodeRect(nodeId)) {
        case Some(rect) => "${nodeId}:${rect[0]},${rect[1]},${rect[2]},${rect[3]}"
        case None => "${nodeId}:none"
    }
}

private func compositeHex(bytes: Array<UInt8>): String {
    let digits = "0123456789abcdef".toArray()
    let output = ArrayList<UInt8>()
    for (byte in bytes) {
        let value = UInt64(byte)
        output.add(digits[Int64(value / 16u64)])
        output.add(digits[Int64(value % 16u64)])
    }
    return String.fromUtf8(output.toArray())
}

private func compositeRecords(): ArrayList<CjguiSharedOperationRecord> {
    let records = ArrayList<CjguiSharedOperationRecord>()
    let titles = ["北区晨检", "南区复核", "西区补录", "东区盘点", "中区回访", "夜间值守"]
    let notes = ["首轮检查完成", "等待复核", "已补录两张图", "库存差异待确认", "回访已预约", "交接班记录"]
    var index = 0
    while (index < titles.size) {
        records.add(CjguiSharedOperationRecord(1000 + Int64(index), titles[index], index == 1,
            notes: notes[index]))
        index += 1
    }
    return records
}

private func compositeAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "普通应用验收客户端",
        "linux-composite-20261021",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_NOTES", ArrayList<Int64>([1000]), false),
            CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([1000]), false),
            CjguiSharedOperationExternalActionScope("SELECT", ArrayList<Int64>([1000, 1001]), false)
        ])
    )
}

class CompositeFormController <: CjguiComposableUiController {
    private let owner: CjguiSharedOperationList
    private let viewport = CjguiComposableUiScrollViewport()
    private var revision: Int64 = 1
    private var selectedId: Int64 = 1000
    private var imageAVersion: Int64 = 1
    private var imageAMode: Int64 = 2
    private var imageBVisible: Bool = true

    public init(owner: CjguiSharedOperationList) {
        this.owner = owner
    }

    public func uiSceneVersion(): Int64 {
        // External writes advance the owner version; human writes also bump
        // the local revision. Either one must produce a new accepted scene.
        return revision + owner.version() * 1000
    }

    public func scrollOffset(): Int64 {
        return viewport.acceptedOffset()
    }

    public func requestedScrollOffset(): Int64 {
        return viewport.offset()
    }

    private func selectedRecord(): CjguiSharedOperationRecord {
        let snapshot = owner.snapshot()
        if (snapshot.selectedRecordId >= 0) {
            selectedId = snapshot.selectedRecordId
        }
        var index = 0
        while (index < snapshot.records.size) {
            let record = snapshot.recordAt(Int64(index))
            if (record.id == selectedId) {
                return record
            }
            index += 1
        }
        let first = snapshot.recordAt(0)
        selectedId = first.id
        return first
    }

    private func printOwner(reason: String): Unit {
        let snapshot = owner.snapshot()
        let record = selectedRecord()
        println("CJGUI_COMPOSITE_OWNER reason=${reason} version=${snapshot.version} " +
            "selected=${record.id} marked=${record.isMarked} " +
            "title_hex=${compositeHex(record.title.toArray())} " +
            "notes_hex=${compositeHex(record.notes.toArray())} " +
            "image_version=${imageAVersion} image_b_visible=${imageBVisible}")
        getStdOut().flush()
    }

    private func applyTitle(text: String): Unit {
        let before = owner.version()
        let result = owner.setTitleFromHuman(selectedId, text)
        if (result.applied) {
            revision += 1
            printOwner("title")
            return
        }
        println("CJGUI_COMPOSITE_REJECT field=title reason=${result.reason} " +
            "version_before=${before} version_after=${result.versionAfter}")
        getStdOut().flush()
    }

    private func applyNotes(text: String): Unit {
        let before = owner.version()
        let result = owner.executeFromHuman(CjguiSharedOperationActionInvocation(
            "SET_NOTES", owner.version(), ArrayList<Int64>([selectedId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("notes", CjguiSharedOperationValue.string(text))
            ])))
        if (result.applied) {
            revision += 1
            printOwner("notes")
            return
        }
        println("CJGUI_COMPOSITE_REJECT field=notes reason=${result.reason} " +
            "version_before=${before} version_after=${result.versionAfter}")
        getStdOut().flush()
    }

    private func toggleMarked(): Unit {
        let record = selectedRecord()
        let result = owner.setMarkedFromHuman(record.id, !record.isMarked)
        if (result.applied) {
            revision += 1
            printOwner("marked")
        }
    }

    private func selectNext(): Unit {
        let snapshot = owner.snapshot()
        var found = -1
        var index = 0
        while (index < snapshot.records.size) {
            if (snapshot.recordAt(Int64(index)).id == selectedId) {
                found = index
                break
            }
            index += 1
        }
        let next = if (found < 0) {
            0
        } else {
            (found + 1) % snapshot.records.size
        }
        let result = owner.selectFromHuman(snapshot.recordAt(Int64(next)).id)
        if (result.applied) {
            revision += 1
            printOwner("select")
        }
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let snapshot = owner.snapshot()
        let record = selectedRecord()
        let action = CjguiComposableUiNamedStyle("composite-action",
            theme.primaryAction, interaction: theme.primaryActionInteraction,
            purpose: "普通应用主操作")
        let page = cjguiComposableLayerHost(1, "composite-root", CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.055, 0.075, 0.12, 1.0)))
        let shell = cjguiComposableVertical(2, "composite-shell", CjguiComposableUiStyle(
            padding: 18, gap: 12, growX: 1, growY: 1))
        let hero = cjguiComposableVertical(3, "composite-hero", CjguiComposableUiStyle(
            padding: 16, gap: 4, cornerRadii:
                CjguiComposableUiCornerRadii(topLeft: 30, topRight: 8, bottomRight: 30, bottomLeft: 8),
            borderWidth: 2, border: CjguiComposableUiColor(0.85, 0.93, 1.0, 0.42),
            gradient: CjguiComposableUiLinearGradient(
                startX: 0.0, startY: 0.0, endX: 1.0, endY: 1.0,
                stops: [
                    CjguiComposableUiGradientStop(position: 0.0,
                        color: CjguiComposableUiColor(0.08, 0.28, 0.62, 1.0)),
                    CjguiComposableUiGradientStop(position: 0.55,
                        color: CjguiComposableUiColor(0.20, 0.58, 0.82, 1.0)),
                    CjguiComposableUiGradientStop(position: 1.0,
                        color: CjguiComposableUiColor(0.94, 0.56, 0.24, 1.0))
                ])))
        hero.add(cjguiComposableText(4, "composite-hero-title",
            "Linux 普通应用能力", CjguiComposableUiStyle(fontSize: 26.0, fontWeight: 700,
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))))
        hero.add(cjguiComposableText(5, "composite-hero-subtitle",
            "圆角/渐变、滚动图文与共享 owner。",
            CjguiComposableUiStyle(fontSize: 13.0,
                textColor: CjguiComposableUiColor(0.88, 0.94, 1.0, 0.92))))
        shell.add(hero)

        let scroll = cjguiComposableScrollArea(6, "composite-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, cornerRadius: 18,
                clipsContent: true, background: CjguiComposableUiColor(0.08, 0.11, 0.18, 0.96),
                borderWidth: 1, border: CjguiComposableUiColor(0.25, 0.38, 0.58, 0.75)))
        let content = cjguiComposableVertical(7, "composite-scroll-content",
            CjguiComposableUiStyle(padding: 14, gap: 12, growX: 1))
        content.add(cjguiComposableText(8, "composite-section-images", "现场图片", theme.heading))
        // The frame clips its child to a rounded aperture; the image is
        // larger than the frame on one axis, so a rectangular clip would show
        // a square corner or overflow.
        let clipFrame = cjguiComposableVertical(9, "composite-clip-frame",
            CjguiComposableUiStyle(padding: 0, fixedHeight: 118, cornerRadius: 26,
                clipsContent: true, background: CjguiComposableUiColor(0.04, 0.06, 0.10, 1.0)))
        let strip = cjguiComposableHorizontal(10, "composite-image-strip",
            CjguiComposableUiStyle(gap: 10, padding: 8))
        let frameA = cjguiComposableVertical(11, "composite-frame-a",
            CjguiComposableUiStyle(fixedWidth: 132, fixedHeight: 102, cornerRadius: 20,
                clipsContent: true, background: CjguiComposableUiColor(0.02, 0.04, 0.08, 1.0)))
        frameA.add(cjguiComposableImage(12, "composite-image-a", "composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 130),
            imageResourceId: "composite-image-a", imageResourceVersion: imageAVersion,
            contentMode: imageAMode))
        strip.add(frameA)
        if (imageBVisible) {
            let frameB = cjguiComposableVertical(13, "composite-frame-b",
                CjguiComposableUiStyle(fixedWidth: 132, fixedHeight: 102, cornerRadius: 20,
                    clipsContent: true, background: CjguiComposableUiColor(0.02, 0.04, 0.08, 1.0)))
            frameB.add(cjguiComposableImage(14, "composite-image-b", "composable-beacon-coral.png",
                CjguiComposableUiStyle(fixedWidth: 132, fixedHeight: 102),
                imageResourceId: "composite-image-b", imageResourceVersion: 1,
                contentMode: 2))
            strip.add(frameB)
        }
        clipFrame.add(strip)
        content.add(clipFrame)

        let inputStyle = CjguiComposableUiStyle(
            fixedHeight: theme.input.fixedHeight, background: theme.input.background,
            border: theme.input.border, textColor: theme.input.textColor,
            pointerInteractive: true)
        content.add(cjguiComposableTextInput(COMPOSITE_TITLE_NODE, "composite-title",
            "标题", record.title, 0, inputStyle, fieldId: "title",
            operationActionName: "SET_TITLE", operationResourceId: record.id,
            displayValueRole: "owner", interactionStyle: theme.inputInteraction))
        content.add(cjguiComposableTextInput(COMPOSITE_NOTES_NODE, "composite-notes",
            "备注", record.notes, 0, inputStyle, fieldId: "notes",
            operationActionName: "SET_NOTES", operationResourceId: record.id,
            displayValueRole: "owner", interactionStyle: theme.inputInteraction))
        content.add(cjguiComposableButton(42, "composite-toggle-mark", "标记 / 取消标记",
            "TOGGLE_MARK", 0, action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableButton(43, "composite-next-record", "下一条记录",
            "NEXT_RECORD", 0, action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableButton(44, "composite-replace-image", "换一张图",
            "REPLACE_IMAGE", 0, action.localStyle(), interactionStyle: action.interaction))
        content.add(cjguiComposableButton(45, "composite-toggle-image-b", "显示 / 隐藏第二张图",
            "TOGGLE_IMAGE_B", 0, action.localStyle(), interactionStyle: action.interaction))

        var row = 0
        while (row < 12) {
            content.add(cjguiComposableText(100 + Int64(row), "composite-row-${row}",
                "第 ${row + 1} 节 · owner v${snapshot.version} · 记录 ${record.id} · " +
                "备注 ${record.notes}", theme.body))
            row += 1
        }
        scroll.add(content)
        shell.add(scroll)
        shell.add(cjguiComposableText(60, "composite-status",
            "owner v${snapshot.version}｜选择 ${record.id}｜标记 ${record.isMarked}｜" +
            "滚动 ${viewport.acceptedOffset()}｜图片 v${imageAVersion}", theme.body))
        page.add(shell)
        return page
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 30) {
            println("CJGUI_COMPOSITE_WHEEL applied=${event.frameworkScrollApplied} " +
                "requested=${event.scrollRequestedBefore}->${event.scrollRequestedAfter} " +
                "accepted=${event.scrollAcceptedBefore}->${event.scrollAcceptedAfter}")
            getStdOut().flush()
        }
        if (event.eventKind == 28 && event.node.nodeId == COMPOSITE_TITLE_NODE) {
            applyTitle(event.text)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && event.node.nodeId == COMPOSITE_NOTES_NODE) {
            applyNotes(event.text)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_MARK") {
            toggleMarked()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "NEXT_RECORD") {
            selectNext()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "REPLACE_IMAGE") {
            imageAVersion += 1
            imageAMode = if (imageAMode == 2) { 1 } else { 2 }
            revision += 1
            printOwner("image")
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_IMAGE_B") {
            imageBVisible = !imageBVisible
            revision += 1
            printOwner("image_visible")
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

private func printExternalChange(list: CjguiSharedOperationList): Unit {
    let snapshot = list.snapshot()
    var record = snapshot.recordAt(0)
    var index = 0
    while (index < snapshot.records.size) {
        let candidate = snapshot.recordAt(Int64(index))
        if (candidate.id == snapshot.selectedRecordId || (snapshot.selectedRecordId < 0 && index == 0)) {
            record = candidate
            break
        }
        index += 1
    }
    println("CJGUI_COMPOSITE_EXTERNAL version=${snapshot.version} selected=${record.id} " +
        "marked=${record.isMarked} title_hex=${compositeHex(record.title.toArray())} " +
        "notes_hex=${compositeHex(record.notes.toArray())}")
    getStdOut().flush()
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let list = CjguiSharedOperationList(compositeRecords())
    let authorization = compositeAuthorization()
    let connection = CjguiSharedOperationExternalConnection(list, authorization)
    let controller = CompositeFormController(list)
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Linux 普通应用", 760u32, 620u32))
    if (!host.attachExternalConnection(connection)) {
        println("CJGUI_COMPOSITE_ATTACH false")
        host.close()
        return 3
    }
    if (!host.start()) {
        println("CJGUI_COMPOSITE_START false")
        host.close()
        return 1
    }
    println("CJGUI_COMPOSITE_READY")
    if (let Some(info) <- connection.connectionInfo()) {
        println("CJGUI_COMPOSITE_DESCRIPTOR ${info.descriptorPath}")
        println("CJGUI_COMPOSITE_PROTOCOL ${info.protocol}")
    } else {
        println("CJGUI_COMPOSITE_DESCRIPTOR unavailable")
    }
    getStdOut().flush()
    var accepted = false
    while (host.isOpen() && !accepted) {
        let _ = host.pumpOneTurn()
        accepted = host.window().acceptedNodeCount() > 0
    }
    if (accepted && host.window().focusAcceptedNodeById(COMPOSITE_TITLE_NODE)) {
        println("CJGUI_COMPOSITE_FOCUS node=${COMPOSITE_TITLE_NODE}")
        getStdOut().flush()
    }
    var lastVersion = list.version()
    var lastScroll = controller.scrollOffset()
    var turn: Int64 = 0
    let _ = host.window().setWorkloadDiagnostics(true)
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        turn += 1
        if (turn % 120 == 0) {
            let live = host.window().diagnosticScalarSnapshot()
            println("CJGUI_COMPOSITE_LOAD turn=${turn} builds=${live.buildPassCount} " +
                "layouts=${live.layoutPassCount} submissions=${live.nativeSubmissionCount} " +
                "frame=${live.submittedFrameIndex} completed=${live.completedFrameIndex} " +
                "build_ns=${live.totalBuildNanoseconds} layout_ns=${live.totalLayoutNanoseconds} " +
                "stage_ns=${live.totalNativeStageAndSubmitNanoseconds}")
            if (getVariable("CJGUI_COMPOSITE_RECTS") == Some("1")) {
                println("CJGUI_COMPOSITE_RECTS requested=${controller.requestedScrollOffset()} " +
                    "accepted=${controller.scrollOffset()} " +
                    compositeRectText(host.window(), 6) + " " +
                    compositeRectText(host.window(), 42) + " " +
                    compositeRectText(host.window(), 44) + " " +
                    compositeRectText(host.window(), 45))
            }
            getStdOut().flush()
        }
        let version = list.version()
        if (version != lastVersion) {
            lastVersion = version
            printExternalChange(list)
        }
        let scroll = controller.scrollOffset()
        if (scroll != lastScroll) {
            lastScroll = scroll
            println("CJGUI_COMPOSITE_SCROLL offset=${scroll}")
            getStdOut().flush()
        }
    }
    println("CJGUI_COMPOSITE_CLOSED version=${list.version()}")
    getStdOut().flush()
    host.close()
    return 0
}
