package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.time.*

let TYPOGRAPHY_SAMPLE = "中文排版 é / 👩🏽‍💻 / 家人👨‍👩‍👧‍👦：字距与行高来自同一声明；窄栏换行和末行省略保留完整业务文本。"
let TYPOGRAPHY_OWNER: Int64 = 8101

// Opt-in ordinary page in the existing task-board consumer. The original task
// owner/rules/region handle every field edit; these bits are presentation only.
class TypographyConsumerController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiPlatformThemeConsumer {
    let domain: CjguiSharedOperationList
    let region: CjguiTaskGeneratedRegion
    private var revision: Int64 = 1
    private var spacing: Float64 = 0.0
    private var height: Float64 = 0.0
    private var font: Float64 = 16.0
    private var narrow: Bool = false
    private var dark: Bool = true
    private var feedback: String = "正文与生成标题直接读写原任务 owner。"
    private let viewport = CjguiComposableUiScrollViewport()

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.region = CjguiTaskGeneratedRegion(domain, TYPOGRAPHY_OWNER)
        let _ = updateGeneratedTypography()
    }

    private func updateGeneratedTypography(): Bool {
        let tracking = if (spacing == 1.5) { "1.5" } else if (spacing < 0.0) { "-0.75" } else { "0" }
        let payload = "GENERATED_UI_STRUCTURE 1\nNODE 0 typography vertical\n" +
            "NODE 1 titleEditor textInput field=title\nPROPERTY 1 titleEditor label 生成标题\n" +
            "PROPERTY 1 titleEditor fontSize ${Int64(font)}\n" +
            "PROPERTY 1 titleEditor letterSpacing ${tracking}\nPROPERTY 1 titleEditor lineHeight ${Int64(height)}\n" +
            "PROPERTY 1 titleEditor fixedHeight 48\n" +
            "PROPERTY 1 titleEditor textColor #edf4ffff\n" +
            "NODE 1 prose longLabel\nPROPERTY 1 prose text ${TYPOGRAPHY_SAMPLE}\n" +
            "PROPERTY 1 prose textColor #edf4ffff\n" +
            "PROPERTY 1 prose letterSpacing ${tracking}\nPROPERTY 1 prose lineHeight ${Int64(height)}\nEND"
        return region.submitStructure(payload, region.acceptedStructureVersion()).candidateAccepted
    }

    public func uiSceneVersion(): Int64 { return revision + domain.version() + region.revision() }
    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        let next = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme) ==
            CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        if (next == dark) { return false }
        dark = next
        let _ = region.applyPlatformColorScheme(scheme)
        revision += 1
        return true
    }
    public func buildUi(): CjguiComposableUiNode {
        let theme = if (dark) { CjguiComposableUiTheme.beaconDark() } else { CjguiComposableUiTheme.paperLight() }
        let root = cjguiComposableVertical(701, "typography-page", theme.page)
        let scroll = cjguiComposableScrollArea(702, "typography-scroll", viewport,
            CjguiComposableUiStyle(growX: if (narrow) { 0 } else { 1 }, growY: 1,
                fixedWidth: if (narrow) { 320 } else { 0 }, maxWidth: if (narrow) { 320 } else { 0 },
                alignX: CJGUI_COMPOSABLE_UI_ALIGN_START, clipsContent: true))
        let body = cjguiComposableVertical(703, "typography-body",
            CjguiComposableUiStyle(growX: 1, padding: 16, gap: 8))
        let header = cjguiComposableHorizontal(704, "typography-header", CjguiComposableUiStyle(gap: 12))
        let beacon = region.beaconResource()
        header.add(cjguiComposableImage(705, "typography-beacon", beacon.rasterPath,
            CjguiComposableUiStyle(fixedWidth: 40, fixedHeight: 40),
            imageResourceId: beacon.key, imageResourceVersion: beacon.version))
        header.add(cjguiComposableText(706, "typography-heading", "公共文字 · 排版与编辑", theme.heading))
        body.add(header)
        let actions = cjguiComposableHorizontal(707, "typography-actions", CjguiComposableUiStyle(gap: 6))
        let moreActions = cjguiComposableHorizontal(708, "typography-more-actions", CjguiComposableUiStyle(gap: 6))
        var index: Int64 = 0
        for ((action, label) in [("SPACED", "宽松排版"), ("TIGHT", "紧凑排版"), ("DEFAULT", "恢复默认"),
            ("WIDTH", "窄栏/宽栏"), ("FONT", "切换字号")]) {
            let button = cjguiComposableButton(710 + index, "typography-${action}", label, action, 0,
                CjguiComposableUiNamedStyle("action", theme.primaryAction).localStyle(fixedWidth: Some(96),
                    fixedHeight: Some(34)), interactionStyle: theme.primaryActionInteraction)
            if (index < 3) { actions.add(button) } else { moreActions.add(button) }
            index += 1
        }
        body.add(actions)
        body.add(moreActions)
        body.add(cjguiComposableText(719, "typography-facts", "letterSpacing=${spacing} pt · lineHeight=${height} pt（0 自然）· font=${font}", theme.body))
        let named = CjguiComposableUiNamedStyle("paragraph", theme.body)
        let textStyle = named.localStyle(fontSize: Some(font), letterSpacing: Some(spacing), lineHeight: Some(height))
        body.add(cjguiComposableText(720, "typography-prose", TYPOGRAPHY_SAMPLE, textStyle))
        body.add(cjguiComposableText(721, "typography-tail", TYPOGRAPHY_SAMPLE,
            named.localStyle(fontSize: Some(font), letterSpacing: Some(spacing), lineHeight: Some(height),
                textMaxLines: Some(2), textOverflow: Some("ellipsis"))))
        body.add(region.buildSection(theme))
        let record = domain.snapshot().recordAt(0)
        body.add(cjguiComposableMultilineTextInput(722, "typography-notes", "手写多行备注", record.notes,
            CjguiTaskFields.notesResourceId,
            CjguiComposableUiNamedStyle("editor", theme.input).localStyle(fontSize: Some(font),
                letterSpacing: Some(spacing), lineHeight: Some(height), fixedHeight: Some(152), growX: Some(1)),
            fieldId: "notes", operationActionName: "SET_NOTES", operationResourceId: TYPOGRAPHY_OWNER,
            displayValueRole: "applied", interactionStyle: theme.inputInteraction))
        body.add(cjguiComposableText(723, "typography-owner", "owner v${domain.version()} · ${feedback}\n标题：${record.title}\n备注：${record.notes}", theme.body))
        scroll.add(body)
        root.add(scroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generated = region.handleEvent(event)
        if (generated.didApply) { revision += 1; return generated }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.nodeId == 722) {
            let field = CjguiTaskFields.definition("notes")
            let result = domain.writeDeclaredFieldFromHuman(field.rule(TYPOGRAPHY_OWNER), TYPOGRAPHY_OWNER,
                CjguiSharedOperationValue.string(event.text))
            feedback = if (result.applied) { "备注已更新" } else { result.reason }
            revision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) { return CjguiComposableUiDispatchResult(false) }
        match (event.node.actionName) {
            case "SPACED" => spacing = 1.5; height = 32.0
            case "TIGHT" => spacing = -0.75; height = 18.0
            case "DEFAULT" => spacing = 0.0; height = 0.0; font = 16.0
            case "WIDTH" => narrow = !narrow
            case "FONT" => font = if (font == 16.0) { 20.0 } else { 16.0 }
            case _ => return CjguiComposableUiDispatchResult(false)
        }
        feedback = if (updateGeneratedTypography()) { "排版已更新，owner 文本未变" } else { "生成候选被拒绝，保留原结构" }
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        region.prepareWindowClose()
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { region.releaseImageIdentities() }
}

func runTypographyConsumer(): Int64 {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(TYPOGRAPHY_OWNER, "中文 é 👩🏽‍💻 标题", false)
    ]))
    if (!CjguiTaskFields.installIntoEveryRecord(domain)) { return 1 }
    let _ = domain.selectFromHuman(TYPOGRAPHY_OWNER)
    let _ = domain.writeDeclaredFieldFromHuman(CjguiTaskFields.definition("notes").rule(TYPOGRAPHY_OWNER),
        TYPOGRAPHY_OWNER, CjguiSharedOperationValue.string("第一行 中文 é 👩🏽‍💻\n第二行 家人👨‍👩‍👧‍👦，继续编辑。\n末行用于滚动和选区。"))
    let controller = TypographyConsumerController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("公共文字 · 排版与编辑", 1000u32, 850u32))
    let window = host.window()
    controller.region.attachWindow(window)
    let auth = CjguiSharedOperationExternalAuthorization("typography-client", "demo-only-typography-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_TITLE", ArrayList<Int64>([TYPOGRAPHY_OWNER]), false),
            CjguiSharedOperationExternalActionScope("SET_NOTES", ArrayList<Int64>([TYPOGRAPHY_OWNER]), false),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", ArrayList<Int64>(), true)
        ]))
    let connection = CjguiSharedOperationExternalConnection(domain, auth, window)
    if (!connection.enableWindowProgressReads(window) || !connection.enableGeneratedUiProvider(controller.region) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        let progress = window.windowProgress()
        eprintln("CJGUI_TYPOGRAPHY_START_FAILED phase=${progress.pendingRefreshReason} " +
            "failure=${progress.lastNativeFailure} region=${controller.region.statusText()}")
        getStdOut().flush()
        host.close(); return 1
    }
    let _ = window.setWorkloadDiagnostics(true)
    if (let Some(info) <- connection.connectionInfo()) {
        getStdOut().writeln("CJGUI_TYPOGRAPHY_READY descriptor=${info.descriptorPath}")
        getStdOut().flush()
    }
    var observedVersion: Int64 = -1
    var changedAt = MonoTime.now()
    var quietRead = false
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        let next = controller.uiSceneVersion()
        if (next != observedVersion) {
            observedVersion = next
            changedAt = MonoTime.now()
            quietRead = false
            typographyCost(window, "change", domain.version())
        } else if (!quietRead && (MonoTime.now() - changedAt).toMilliseconds() >= 1500) {
            typographyCost(window, "quiet", domain.version())
            quietRead = true
        }
    }
    host.close()
    getStdOut().writeln("CJGUI_TYPOGRAPHY_CLOSED endpoint_cleared=${connection.connectionInfo().isNone()}")
    getStdOut().flush()
    return 0
}

private func typographyCost(window: CjguiComposableUiWindow, phase: String, ownerVersion: Int64): Unit {
    let cost = window.diagnosticScalarSnapshot()
    getStdOut().writeln("CJGUI_TYPOGRAPHY_COST phase=${phase} owner=${ownerVersion} " +
        "scene=${cost.acceptedSceneVersion} status=${cost.workloadStatus} " +
        "build=${cost.buildPassCount} layout=${cost.layoutPassCount} submissions=${cost.nativeSubmissionCount} " +
        "textPrepare=${cost.textLayoutPreparationCount} textRaster=${cost.textRasterCount} " +
        "textUpload=${cost.textUploadCount} textBytes=${cost.textTextureLiveBytes}")
    getStdOut().flush()
}
