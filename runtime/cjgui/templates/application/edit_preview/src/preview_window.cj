package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_notification_threshold_application.*
import std.collection.*
import std.env.*

// Application-owned font declarations. Paths are relative to the launched
// application root: the source tree while developing and the package root
// after `package` (which copies resources/ verbatim).
private let CJGUI_PREVIEW_FONT_V1 = "resources/fonts/DejaVuSerif-Bold.ttf"
private let CJGUI_PREVIEW_FONT_V2 = "resources/fonts/DejaVuSans-Bold.ttf"

func cjguiPreviewLog(message: String): Unit {
    let out = getStdOut()
    out.writeln(message)
    out.flush()
}

/// Shared declaration for the handwritten `textStyleRuns` and the generated
/// label `textRuns`. Both consumers read one text and one run table; only the
/// transport differs (Cangjie values vs. the generated 7-field wire).
class CjguiNotificationPreviewDeclaration {
    let text: String
    let handwrittenRuns: Array<CjguiComposableUiTextStyleRun>
    let generatedWire: String
    let fileVersion: Int64
    init(text: String, handwrittenRuns: Array<CjguiComposableUiTextStyleRun>, generatedWire: String, fileVersion: Int64) {
        this.text = text
        this.handwrittenRuns = handwrittenRuns
        this.generatedWire = generatedWire
        this.fileVersion = fileVersion
    }
}

private func cjguiPreviewDeclaration(fonts: CjguiNotificationPreviewFonts): CjguiNotificationPreviewDeclaration {
    let a = "字体代际 "
    let b = "Aa 多样式 "
    let c = "文本 Style 𝒞 "
    let d = "第二行 English 与中文，窄窗换行并省略。"
    let text = a + b + c + d
    let aStart: Int64 = 0
    let aEnd: Int64 = a.toArray().size
    let bStart = aEnd
    let bEnd = bStart + b.toArray().size
    let cStart = bEnd
    let cEnd = cStart + c.toArray().size
    let fileFamily = fonts.fileReference.fontFamily
    let systemFamily = fonts.systemReference.fontFamily
    let runs: Array<CjguiComposableUiTextStyleRun> = [
        CjguiComposableUiTextStyleRun(aStart, aEnd, 26.0, 700, fileFamily, 0.96, 0.54, 0.36, 1.0,
            hasBackground: true, backgroundRed: 0.26, backgroundGreen: 0.17, backgroundBlue: 0.13,
            backgroundAlpha: 1.0),
        CjguiComposableUiTextStyleRun(bStart, bEnd, 15.0, 500, systemFamily, 0.40, 0.76, 0.98, 1.0),
        CjguiComposableUiTextStyleRun(cStart, cEnd, 18.0, 400, fileFamily, 0.50, 0.92, 0.62, 1.0)
    ]
    let wire = StringBuilder()
    wire.append("${aStart}:${aEnd}:26:700:preview-file:${fonts.fileVersion}:#F58A5C;")
    wire.append("${bStart}:${bEnd}:15:500:preview-system:${fonts.systemVersion}:#66C2FA;")
    wire.append("${cStart}:${cEnd}:18:400:preview-file:${fonts.fileVersion}:#80EB9E")
    return CjguiNotificationPreviewDeclaration(text, runs, wire.toString(), fonts.fileVersion)
}

/// One explicit application font owner. The preview window leases its accepted
/// generations; replacing a version keeps the old native generation alive until
/// the last window using it is rebuilt or closed.
class CjguiNotificationPreviewFonts {
    let registry = CjguiFontResourceRegistry()
    var fileReference: CjguiFontResourceReference
    let systemReference: CjguiFontResourceReference
    let missingReference: CjguiFontResourceReference
    let systemVersion: Int64 = 1
    var fileVersion: Int64 = 1
    init() {
        this.systemReference = registry.register(
            CjguiFontResourceSpec.systemFamily("preview-system", 1, "DejaVu Sans", name: "预览系统字体"))
        this.fileReference = registry.register(
            CjguiFontResourceSpec.file("preview-file", 1, CJGUI_PREVIEW_FONT_V1, name: "预览衬线文件字体",
                fallback: "system"))
        // Declared on purpose: the app must report the explicit fallback rather
        // than crash or silently substitute a different ready family.
        this.missingReference = registry.register(
            CjguiFontResourceSpec.file("preview-missing", 1, "resources/fonts/missing-preview.ttf",
                name: "预览缺失字体", fallback: "system"))
    }
    func switchFileVersion(): CjguiFontResourceReference {
        let next = fileVersion + 1
        let path = if (next % 2 == 0) { CJGUI_PREVIEW_FONT_V2 } else { CJGUI_PREVIEW_FONT_V1 }
        fileReference = registry.replace(
            CjguiFontResourceSpec.file("preview-file", next, path, name: "预览文件字体 v${next}",
                fallback: "system"))
        fileVersion = next
        return fileReference
    }
    func close(): Unit {
        registry.close()
    }
}

class CjguiNotificationPreviewController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let domain: CjguiNotificationThresholdDomain
    private let fonts: CjguiNotificationPreviewFonts
    private let binding: CjguiGeneratedUiFormBinding
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let generated: CjguiGeneratedUiWindowRegion
    private var attachedWindow: ?CjguiComposableUiWindow = None
    private var localRevision: Int64 = 1
    private var lastSubmittedPayload: String = ""
    private var lastRejection: String = ""
    private var lastRefusal: String = ""

    init(domain: CjguiNotificationThresholdDomain, fonts: CjguiNotificationPreviewFonts) {
        this.domain = domain
        this.fonts = fonts
        this.binding = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
        this.catalog = binding.capabilityCatalog()
        let _ = catalog.registerFontResource(fonts.fileReference)
        let _ = catalog.registerFontResource(fonts.systemReference)
        this.generated = CjguiGeneratedUiWindowRegion(catalog, binding, "notification-preview-generated")
    }

    func bindWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
        generated.attachWindow(window)
    }

    func currentDeclaration(): CjguiNotificationPreviewDeclaration {
        return cjguiPreviewDeclaration(fonts)
    }

    func adoptFontReference(reference: CjguiFontResourceReference): Unit {
        let registered = catalog.registerFontResource(reference)
        if (!registered) {
            lastRefusal = "font_resource_registration_refused"
        }
        // The generated structure must be resubmitted with the new generation;
        // the handwritten runs already read the same reference on the next build.
        lastSubmittedPayload = ""
        localRevision += 1
    }

    /// Submits a structure that still names the previous generation after the
    /// new one was published. The decoder must refuse it by name; the accepted
    /// scene and its font leases stay untouched.
    func rejectExpiredFontCandidate(oldVersion: Int64): String {
        let declaration = cjguiPreviewDeclaration(fonts)
        let wire = "0:${declaration.handwrittenRuns[0].end}:26:700:preview-file:${oldVersion}:#F58A5C"
        let payload = previewPayload(declaration.text, wire)
        let result = generated.submitStructure(payload, generated.acceptedStructureVersion())
        if (result.candidateAccepted) {
            return "unexpected_accept"
        }
        lastRejection = result.reason
        cjguiPreviewLog("CJGUI_PREVIEW_EXPIRED_FONT rejected reason=${result.reason} accepted_version=${generated.acceptedStructureVersion()}")
        return result.reason
    }

    func requestRefresh(): Unit {
        match (attachedWindow) {
            case Some(window) => window.requestRefresh()
            case None => ()
        }
    }

    public func uiSceneVersion(): Int64 {
        let draft = domain.draftSnapshot()
        let current = domain.notificationSnapshot()
        return localRevision + draft.draftVersion * 1000003 + current.version * 7919 + generated.revision() +
            fonts.fileVersion * 104729
    }

    private func previewPayload(text: String, wire: String): String {
        let draft = domain.draftSnapshot()
        let channel = draft.fieldForResourceId(domain.formBinding().fieldAtControlIndex(0).resourceId).draftText
        let builder = StringBuilder()
        builder.append("GENERATED_UI_STRUCTURE 1\n")
        builder.append("NODE 0 preview-root vertical\n")
        builder.append("PROPERTY 0 preview-root gap 8\n")
        builder.append("NODE 1 preview-generated label\n")
        builder.append("PROPERTY 1 preview-generated text ${text}\n")
        builder.append("PROPERTY 1 preview-generated textRuns ${wire}\n")
        builder.append("PROPERTY 1 preview-generated fontSize 16\n")
        builder.append("PROPERTY 1 preview-generated fontWeight 0\n")
        builder.append("PROPERTY 1 preview-generated textColor #DCE6F7\n")
        builder.append("PROPERTY 1 preview-generated textMaxLines 3\n")
        builder.append("PROPERTY 1 preview-generated textOverflow ellipsis\n")
        builder.append("PROPERTY 1 preview-generated fixedHeight 124\n")
        builder.append("PROPERTY 1 preview-generated growX 1\n")
        builder.append("NODE 1 preview-channel label\n")
        builder.append("PROPERTY 1 preview-channel text 生成读取 · ${channel}\n")
        builder.append("PROPERTY 1 preview-channel fontSize 13\n")
        builder.append("PROPERTY 1 preview-channel textColor #9FB2CF\n")
        builder.append("PROPERTY 1 preview-channel textMaxLines 1\n")
        builder.append("PROPERTY 1 preview-channel textOverflow ellipsis\n")
        builder.append("PROPERTY 1 preview-channel fixedHeight 22\n")
        builder.append("PROPERTY 1 preview-channel growX 1\n")
        builder.append("END")
        return builder.toString()
    }

    private func publishCandidate(): Unit {
        let declaration = currentDeclaration()
        let payload = previewPayload(declaration.text, declaration.generatedWire)
        if (payload == lastSubmittedPayload) {
            return
        }
        let result = generated.submitStructure(payload, generated.acceptedStructureVersion())
        if (result.candidateAccepted) {
            lastSubmittedPayload = payload
            lastRejection = ""
            cjguiPreviewLog("CJGUI_PREVIEW_STRUCTURE submitted font_version=${declaration.fileVersion} " +
                "accepted_before=${result.versionBefore} candidate=${result.candidateVersion}")
        } else {
            lastRejection = result.reason
            cjguiPreviewLog("CJGUI_PREVIEW_STRUCTURE refused reason=${result.reason} " +
                "accepted_version=${generated.acceptedStructureVersion()}")
        }
    }

    public func buildUi(): CjguiComposableUiNode {
        let declaration = currentDeclaration()
        let draft = domain.draftSnapshot()
        let theme = CjguiComposableUiTheme.beaconDark()
        let root = cjguiComposableVertical(1, "preview-root",
            CjguiComposableUiStyle(padding: 16, gap: 8, background: theme.page.background))
        root.add(
            cjguiComposableText(2, "preview-title", "通知预览 · 主窗编辑，本窗展示",
                CjguiComposableUiStyle(fontSize: 18.0, fontWeight: 700, textColor: theme.heading.textColor,
                    fontFamily: theme.heading.fontFamily, textMaxLines: 1, fixedHeight: 28)))
        root.add(
            cjguiComposableText(3, "preview-handwritten", declaration.text,
                CjguiComposableUiStyle(fontSize: 16.0, textColor: CjguiComposableUiColor(0.86, 0.90, 0.98, 1.0),
                    textMaxLines: 3, textOverflow: "ellipsis", fixedHeight: 132, growX: 1),
                textStyleRuns: declaration.handwrittenRuns))
        root.add(
            cjguiComposableText(4, "preview-handwritten-caption",
                "手写 textStyleRuns · ${declaration.text.toArray().size} 字节原文 · 字体代 v${declaration.fileVersion}",
                CjguiComposableUiStyle(fontSize: 12.0, textColor: CjguiComposableUiColor(0.58, 0.66, 0.80, 1.0),
                    textMaxLines: 1, fixedHeight: 20)))
        let generatedHost = cjguiComposableVertical(5, "preview-generated-host",
            CjguiComposableUiStyle(padding: 8, gap: 4, background: theme.card.background,
                border: theme.card.border, fixedHeight: 170))
        generatedHost.add(generated.buildNode())
        root.add(generatedHost)
        let status = "草稿 v${draft.draftVersion} · 通道 ${draft.fieldForResourceId(domain.formBinding().fieldAtControlIndex(0).resourceId).draftText}" +
            " / ${draft.fieldForResourceId(domain.formBinding().fieldAtControlIndex(1).resourceId).draftText}" +
            " / ${if (draft.fieldForResourceId(domain.formBinding().fieldAtControlIndex(2).resourceId).draftText == "true") { "启用" } else { "停用" }}" +
            " · 已应用 v${draft.baseAppliedConfigVersion}" +
            (if (lastRejection.size > 0) { " · 候选拒绝 ${lastRejection}" } else { "" })
        root.add(
            cjguiComposableText(6, "preview-status", status,
                CjguiComposableUiStyle(fontSize: 12.0, textColor: CjguiComposableUiColor(0.70, 0.78, 0.90, 1.0),
                    textMaxLines: 2, textOverflow: "ellipsis", fixedHeight: 36)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func beginSceneRefresh(): Bool {
        publishCandidate()
        return generated.beginSceneRefresh()
    }

    public func prepareSceneRefresh(): Bool {
        return generated.prepareSceneRefresh()
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }

    public func commitSceneRefresh(): Unit {
        generated.commitSceneRefresh()
    }

    public func rollbackSceneRefresh(): Unit {
        generated.rollbackSceneRefresh()
    }

    public func disposeSceneRefreshResources(): Unit {
        generated.disposeSceneRefreshResources()
    }
}

@When[os == "Linux"]
class CjguiNotificationPreviewSession {
    private let group: CjguiLinuxApplicationHostGroup
    private let fonts: CjguiNotificationPreviewFonts
    // A generated region is bound to exactly one window: a region whose window
    // was discarded is never adopted by a later window. The business domain
    // and the font registry stay shared; the controller (and its region) are
    // created by the host's window factory for exactly one generation.
    private let createController: () -> CjguiNotificationPreviewController
    private var windowController: ?CjguiNotificationPreviewController = None
    private var activeWindowId: Int64 = 0

    init(group: CjguiLinuxApplicationHostGroup, fonts: CjguiNotificationPreviewFonts,
        createController!: () -> CjguiNotificationPreviewController) {
        this.group = group
        this.fonts = fonts
        this.createController = createController
    }

    /// The host executes this factory at its turn boundary when the request is
    /// issued from a window dispatch, or immediately when the application is
    /// starting before the loop. The session no longer owns a pending flag.
    private func requestPreviewOpen(): (Bool, String) {
        let request = group.requestOpen("preview", { windowId =>
            let controller = createController()
            let created = CjguiLinuxApplicationHost(controller,
                configuration: CjguiMacosApplicationWindowConfiguration("通知预览 · 多样式文本", 760u32, 440u32))
            controller.bindWindow(created.window())
            windowController = Some(controller)
            activeWindowId = windowId
            created
        })
        activeWindowId = request.windowId
        match (request.status()) {
            case CjguiLinuxWindowRequestStatus.Applied =>
                return (true, "预览窗已打开：手写与生成 label 共享草稿与字体 v${fonts.fileVersion}")
            case CjguiLinuxWindowRequestStatus.Pending =>
                return (true, "预览窗将在本轮回合结束后打开；主窗与预览窗共用同一草稿与字体 owner")
            case CjguiLinuxWindowRequestStatus.Superseded =>
                return (false, "预览窗打开请求被取消：${request.message()}")
            case CjguiLinuxWindowRequestStatus.Failed =>
                if (request.message() == "window_already_open") {
                    return (true, "预览窗已打开；主窗与预览窗共用同一草稿与字体 owner")
                }
                return (false, "预览窗启动失败：${request.message()}")
        }
    }

    private func openPreview(): (Bool, String) {
        return requestPreviewOpen()
    }

    /// Startup path: runs before the group loop, so the host applies the
    /// open immediately. The same request shape is used by the button path.
    public func openPreviewNow(): (Bool, String) {
        return requestPreviewOpen()
    }

    private func closePreview(): (Bool, String) {
        let request = group.requestCloseKey("preview")
        match (request.status()) {
            case CjguiLinuxWindowRequestStatus.Applied =>
                if (request.message() == "cancelled_pending_open") {
                    return (true, "已取消尚未执行的预览窗打开请求")
                }
                return (false, "预览窗未打开")
            case CjguiLinuxWindowRequestStatus.Pending =>
                return (true, "预览窗将在本轮回合结束后关闭；主窗继续使用共享字体")
            case CjguiLinuxWindowRequestStatus.Failed =>
                return (false, "预览窗未打开：${request.message()}")
            case CjguiLinuxWindowRequestStatus.Superseded =>
                return (false, "预览窗关闭请求已被替代：${request.message()}")
        }
    }

    private func switchFontVersion(): (Bool, String) {
        if (activeWindowId <= 0 || !group.isWindowOpen(activeWindowId)) {
            return (false, "预览窗未打开")
        }
        let active = match (windowController) {
            case Some(value) => value
            case None => return (false, "预览窗未打开")
        }
        let oldVersion = fonts.fileVersion
        let newReference = fonts.switchFileVersion()
        active.adoptFontReference(newReference)
        let rejection = active.rejectExpiredFontCandidate(oldVersion)
        active.requestRefresh()
        return (true, "字体代 v${oldVersion}→v${fonts.fileVersion}（${newReference.state}）；" +
            "旧代候选被拒 ${rejection}")
    }

    func perform(action: String): (Bool, String) {
        if (action == "OPEN_PREVIEW") { return openPreview() }
        if (action == "CLOSE_PREVIEW") { return closePreview() }
        if (action == "SWITCH_PREVIEW_FONT") { return switchFontVersion() }
        return (false, "未知预览动作：${action}")
    }
}

@When[os == "Linux"]
func cjguiNotificationPreviewFontReport(fonts: CjguiNotificationPreviewFonts): Unit {
    cjguiPreviewLog("CJGUI_PREVIEW_FONT key=preview-file version=${fonts.fileReference.version} " +
        "state=${fonts.fileReference.state} family=${fonts.fileReference.fontFamily}")
    cjguiPreviewLog("CJGUI_PREVIEW_FONT key=preview-system version=${fonts.systemReference.version} " +
        "state=${fonts.systemReference.state} family=${fonts.systemReference.fontFamily}")
    cjguiPreviewLog("CJGUI_PREVIEW_FONT key=preview-missing version=${fonts.missingReference.version} " +
        "state=${fonts.missingReference.state} family=${fonts.missingReference.fontFamily}")
}

@When[os != "Linux"]
func cjguiNotificationPreviewFontReport(fonts: CjguiNotificationPreviewFonts): Unit {}
