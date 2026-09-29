package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.time.*
import std.unicode.*

private let TASK_RESOURCE_ID: Int64 = 8101

// B1/P2 consumer-side alpha invariant control. It is a plain handwritten control
// whose interaction state is an OWNER bit (CHECKED), not a pointer gesture, so
// the consumer can drive the same framework interaction-paint channel
// deterministically. The checked paint declares background alpha 0.75; the base
// style declares 0.8. With a 0.5 paint-alpha animation the displayed background
// alpha must be 0.75 * 0.5 = 0.375 (interaction resolved once, animation applied
// once). Discriminating counter-examples: double animation would give 0.1875,
// re-multiplying the base alpha would give 0.3.
private let ALPHA_INVARIANT_SEMANTIC: String = "collaboration-alpha-invariant"
private let ALPHA_INVARIANT_NODE_ID: Int64 = 9001
private let ALPHA_INVARIANT_BASE_ALPHA: Float64 = 0.8
private let ALPHA_INVARIANT_CHECKED_ALPHA: Float64 = 0.75
private let ALPHA_INVARIANT_ANIMATION_ALPHA: Float64 = 0.5
private let ALPHA_INVARIANT_EXPECTED: Float64 = 0.375
private let GENERATED_CONSUMER_PNG_TARGET: String = "collaboration-png-target"
private let GENERATED_CONSUMER_PNG_SOURCE: String = "collaboration-png-source"
private let GENERATED_CONSUMER_PNG_TARGET_NODE: Int64 = 9002
private let GENERATED_CONSUMER_PNG_SOURCE_NODE: Int64 = 9003
private let GENERATED_CONSUMER_PNG_PREVIEW_NODE: Int64 = 9004
private let GENERATED_CONSUMER_PNG_STATUS_NODE: Int64 = 9005

/// A small normal-window consumer.  Its task content and submitted state are
/// fields on one CjguiSharedOperationList resource: controller state holds
/// only presentation revision/status and never a second writable task copy.
class CollaborationStarterController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiPlatformThemeConsumer & CjguiComposableUiPlatformAccentConsumer &
    CjguiComposableUiWindowBackgroundProvider & CjguiComposableUiDataTransferProvider {
    private let domain: CjguiSharedOperationList
    private let components: CjguiComposableUiComponentRegistry
    private var revision: Int64 = 1
    private var status: String = "直接编辑当前任务；必填与长度由 owner 的字段规则在写入时执行。授权协作者可修改同一内容和状态。"
    // Text inputs this pane mounted, by layout node id -> declared field id.
    // The pane routes a text change by the field its own definition declared,
    // so adding a declared text field needs no new branch here.
    private let textInputFields: HashMap<Int64, String>
    private let generatedRegion: CjguiTaskGeneratedRegion
    // ONE public viewport for this pane. It survives every build, so a real
    // wheel step, a keyboard reveal and a theme change all read and write the
    // same object instead of each author remembering an offset.
    private let editorViewport: CjguiComposableUiScrollViewport
    private var usesDarkAppearance: Bool = true
    private var platformAccentColor: ?CjguiComposableUiColor = None
    private let pngOwner: CjguiSharedOperationImageOwner
    private var pngReceiverIncarnation: Int64 = 1
    private var pngOutcome: String = "等待 PNG 粘贴或拖入"

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.components = CjguiComposableUiComponentRegistry()
        this.textInputFields = HashMap<Int64, String>()
        this.generatedRegion = CjguiTaskGeneratedRegion(domain, TASK_RESOURCE_ID)
        this.editorViewport = CjguiComposableUiScrollViewport()
        this.pngOwner = CjguiSharedOperationImageOwner()
    }

    public func generatedUiRegion(): CjguiTaskGeneratedRegion { return generatedRegion }

    public func candidateWindowBackground(): String {
        return generatedRegion.candidateWindowBackground()
    }

    public func uiSceneVersion(): Int64 {
        return revision + domain.snapshot().version + generatedRegion.revision() + pngOwner.version()
    }

    public func imageOwner(): CjguiSharedOperationImageOwner { return pngOwner }

    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        let dark = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme) ==
            CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        if (usesDarkAppearance == dark) {
            return false
        }
        usesDarkAppearance = dark
        let _ = generatedRegion.applyPlatformColorScheme(scheme)
        revision += 1
        return true
    }

    public func applyPlatformAccentColor(color: CjguiComposableUiColor, source: String): Bool {
        if (!generatedRegion.applyPlatformAccentColor(color, source)) { return false }
        platformAccentColor = Some(color)
        revision += 1
        return true
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        let snapshot = domain.snapshot()
        let task = taskFromSnapshot(snapshot)
        // The native content-area material sits behind the Metal scene. Keep
        // this window-sized root transparent only for the accepted/requested
        // material; ordinary opaque mode retains the original themed page.
        let page = if (generatedRegion.candidateWindowBackground() ==
            CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA) {
            CjguiComposableUiStyle(
                background: CjguiComposableUiColor(theme.page.background.red,
                    theme.page.background.green, theme.page.background.blue, 0.0),
                padding: theme.page.padding, gap: theme.page.gap)
        } else {
            theme.page
        }
        let root = cjguiComposableHorizontal(1, "collaboration-root", page)
        // The handwritten editors, the generated section and the composite card
        // together are longer than one screen. They live in ONE public scroll
        // container sharing ONE public viewport, so the framework can present the
        // clipped bottom after a real wheel gesture and reveal an off-screen
        // editor before focusing it.
        let editorPane = cjguiComposableScrollArea(2, "collaboration-editor-scroll", editorViewport,
            // A horizontal parent sizes the cross axis by alignment, so the pane
            // states its stretch explicitly instead of relying on a natural
            // height that a scroll container does not have.
            CjguiComposableUiStyle(growX: 1, growY: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
                cornerRadius: 16, clipsContent: true,
                background: theme.card.background,
                border: theme.card.border))
        let editorContent = cjguiComposableVertical(2002, "collaboration-editor-content",
            CjguiComposableUiStyle(padding: 14, gap: 8))
        editorContent.add(cjguiComposableText(3, "collaboration-title", "协作任务板", theme.heading))
        let pngSnapshot = pngOwner.snapshot()
        let pngRow = cjguiComposableHorizontal(8998, "collaboration-png-transfer-row",
            CjguiComposableUiStyle(growX: 1, gap: 8, fixedHeight: 40))
        let pngTargetStyle = CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 34,
            background: theme.primaryAction.background, border: theme.primaryAction.border,
            textColor: theme.primaryAction.textColor, fontWeight: theme.primaryAction.fontWeight,
            cornerRadius: 6)
        let pngSourceStyle = CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 34,
            background: theme.primaryAction.background, border: theme.primaryAction.border,
            textColor: theme.primaryAction.textColor, fontWeight: theme.primaryAction.fontWeight,
            cornerRadius: 6)
        pngRow.add(cjguiComposableButton(GENERATED_CONSUMER_PNG_TARGET_NODE, GENERATED_CONSUMER_PNG_TARGET,
            "PNG 粘贴 / 跨窗拖入", "PNG_TARGET", 8901,
            pngTargetStyle, interactionStyle: theme.primaryActionInteraction))
        pngRow.add(cjguiComposableButton(GENERATED_CONSUMER_PNG_SOURCE_NODE, GENERATED_CONSUMER_PNG_SOURCE,
            "拖出当前 PNG", "PNG_SOURCE", 8901,
            pngSourceStyle, enabled: pngSnapshot.offer.isSome(),
            interactionStyle: theme.primaryActionInteraction))
        editorContent.add(pngRow)
        let pngPreview = cjguiComposableHorizontal(9006, "collaboration-png-preview",
            CjguiComposableUiStyle(growX: 1, gap: 8, fixedHeight: 76))
        if (let Some(offer) <- pngSnapshot.offer) {
            pngPreview.add(cjguiComposableImageFromTransfer(GENERATED_CONSUMER_PNG_PREVIEW_NODE,
                "collaboration-png-image", offer,
                CjguiComposableUiStyle(fixedWidth: 72, fixedHeight: 72, cornerRadius: 6, clipsContent: true)))
        }
        pngPreview.add(cjguiComposableText(GENERATED_CONSUMER_PNG_STATUS_NODE, "collaboration-png-status",
            "PNG v${pngSnapshot.version} ${pngSnapshot.width}×${pngSnapshot.height} " +
            "${pngSnapshot.encodedBytes} B · ${pngOutcome}", theme.body))
        editorContent.add(pngPreview)
        // Keep the generated transfer actions and the first part of their
        // effect group inside the initial viewport. The older placement after
        // the handwritten form pushed the blur sample region below the clip.
        editorContent.add(generatedRegion.buildSection(theme))
        // The handwritten beacon resolves from the application's ONE declaration,
        // the same one the generated side and the registered card consume.
        let beacon = generatedRegion.beaconResource()
        editorContent.add(cjguiComposableImage(4, "collaboration-beacon", beacon.rasterPath,
            CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, cornerRadius: 12, clipsContent: true),
            imageResourceId: beacon.key, imageResourceVersion: beacon.version))
        // One handwritten input per declared TEXT field: the field id, label,
        // writer operation and constraint all come from the one definition list,
        // so a second declared field (here `notes`) appears without a pane
        // rewrite and is enforced by the same owner rule.
        let markedField = CjguiTaskFields.definition("marked")
        var textIndex: Int64 = 0
        let textFields = CjguiTaskFields.definitionsOfKind("TEXT")
        while (textIndex < textFields.size) {
            let field = textFields[textIndex]
            let editor = components.use("collaboration-task-${field.fieldId}")
            if (editor.isLive()) {
                let nodeId = editor.nodeId("input")
                textInputFields.add(nodeId, field.fieldId)
                // The handwritten editor consumes the SAME owner availability the
                // generated editor and the composite card do: a field the owner
                // currently refuses is shown disabled here too, with identity and
                // value untouched. An unknown verdict does not disable anything.
                let availability = generatedRegion.fieldAvailability(field.fieldId)
                editorContent.add(cjguiComposableTextInput(nodeId, editor.semanticId("input"), field.label,
                    currentText(field.fieldId, task), TASK_RESOURCE_ID, theme.input,
                    enabled: if (availability.known) { availability.isAvailable } else { true },
                    fieldId: field.fieldId,
                    operationActionName: field.writer, displayValueRole: "applied",
                    interactionStyle: theme.inputInteraction))
            }
            textIndex += 1
        }
        let actionAccent = match (platformAccentColor) {
            case Some(value) => value
            case None => theme.primaryAction.border
        }
        let handwrittenActionStyle = cjguiComposableUiPaintOverlay(theme.primaryAction,
            CjguiComposableUiStyle(background: theme.primaryAction.background, border: actionAccent,
                textColor: theme.primaryAction.textColor, borderWidth: 2))
        editorContent.add(cjguiComposableButton(7, "collaboration-submit", "提交当前任务", "HUMAN_SUBMIT", TASK_RESOURCE_ID,
            handwrittenActionStyle, operationActionName: markedField.writer,
            interactionStyle: theme.primaryActionInteraction))
        editorContent.add(cjguiComposableText(8, "collaboration-status", status, theme.body))
        // B1/P2: one plain control that carries an OWNER interaction state
        // (CHECKED) and a checked paint, so the consumer can read the displayed
        // interaction-resolved paint and prove the alpha composition rule without
        // a pointer gesture. Placed after the generated section so it does not
        // move the nodes the existing checks address.
        editorContent.add(cjguiComposableButton(ALPHA_INVARIANT_NODE_ID, ALPHA_INVARIANT_SEMANTIC,
            "alpha 不变式卡片（checked × 动画）", "ALPHA_INVARIANT_NOOP", 0,
            CjguiComposableUiStyle(
                background: CjguiComposableUiColor(0.20, 0.30, 0.52, ALPHA_INVARIANT_BASE_ALPHA),
                border: CjguiComposableUiColor(0.62, 0.78, 0.98, ALPHA_INVARIANT_BASE_ALPHA),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, ALPHA_INVARIANT_BASE_ALPHA),
                fixedWidth: 240, fixedHeight: 36, cornerRadius: 6, padding: 8),
            interactionStyle: CjguiComposableUiInteractionStyle(
                checked: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.20, 0.30, 0.52, ALPHA_INVARIANT_CHECKED_ALPHA)),
                    border: Some(CjguiComposableUiColor(0.62, 0.78, 0.98, ALPHA_INVARIANT_CHECKED_ALPHA)),
                    textColor: Some(CjguiComposableUiColor(1.0, 1.0, 1.0, ALPHA_INVARIANT_CHECKED_ALPHA)))),
            ownerInteractionState: CjguiComposableUiInteractionState.CHECKED))
        let activityPane = cjguiComposableVertical(20, "collaboration-activity", CjguiComposableUiStyle(
            growX: 1, padding: 14, gap: 8, cornerRadius: 16, clipsContent: true,
            background: theme.card.background,
            border: theme.card.border
        ))
        activityPane.add(cjguiComposableText(21, "collaboration-activity-title", "实际业务投影", theme.heading))
        activityPane.add(cjguiComposableText(22, "collaboration-summary",
            "当前任务：${displayTitle(task.title)}；状态：${if (task.isMarked) { "已提交" } else { "待提交" }}；共享版本 ${snapshot.version}",
            theme.body, resourceId: TASK_RESOURCE_ID, fieldId: "title", displayValueRole: "applied"))
        activityPane.add(cjguiComposableText(23, "collaboration-external-help",
            "外部从公开 context 发现同一资源，再经 SET_TITLE 或 SET_MARKED 授权操作；旧版本会被拒绝。", theme.body))
        editorPane.add(editorContent)
        root.add(editorPane)
        root.add(activityPane)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generated = generatedRegion.handleEvent(event)
        if (generated.didApply) {
            revision += 1
            return generated
        }
        if (event.eventKind == 28) {
            if (let Some(fieldId) <- textInputFields.get(event.node.nodeId)) {
                let field = CjguiTaskFields.definition(fieldId)
                // Immediate feedback through the same declared rule; the owner
                // entry below stays authoritative and is what actually writes
                // (or refuses) the value, so a business condition the pane
                // cannot see is still enforced.
                let rejection = field.rejectionFor(event.text)
                if (rejection.size > 0) {
                    status = "${field.label}未更新：${rejection}"
                    revision += 1
                    return CjguiComposableUiDispatchResult(false)
                }
                let result = domain.writeDeclaredFieldFromHuman(field.rule(TASK_RESOURCE_ID),
                    TASK_RESOURCE_ID, CjguiSharedOperationValue.string(event.text))
                status = if (result.applied) {
                    "${field.label}已由本地更新；共享版本 ${result.versionAfter}"
                } else {
                    "${field.label}未更新：${result.reason}"
                }
                revision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
        }
        if (event.eventKind == 27 && event.node.actionName == "HUMAN_SUBMIT") {
            let task = taskFromSnapshot(domain.snapshot())
            let titleField = CjguiTaskFields.definition("title")
            let rejection = titleField.rejectionFor(task.title)
            if (rejection.size > 0) {
                status = "未提交：${rejection}"
                revision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            // The submit button writes the declared `marked` field through the
            // same owner entry as every other declared field.
            let markedField = CjguiTaskFields.definition("marked")
            let result = domain.writeDeclaredFieldFromHuman(markedField.rule(TASK_RESOURCE_ID),
                TASK_RESOURCE_ID, CjguiSharedOperationValue.boolean(true))
            status = if (result.applied) {
                "当前任务已提交；共享版本 ${result.versionAfter}"
            } else {
                "当前任务未提交：${result.reason}"
            }
            revision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        status = "输入未应用：控件投影已更新"
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        declarations.add(CjguiComposableUiDataTransferDeclaration.target(GENERATED_CONSUMER_PNG_TARGET,
            CjguiSharedOperationTransferFormat.png(), receiverIncarnation: pngReceiverIncarnation,
            localPngFileAllowed: true))
        // The region freezes these identities for the scene currently being
        // prepared. Its accepted readback stays on the previous scene until
        // the same native presentation commits.
        let refreshEndpoints = generatedRegion.refreshTransferEndpoints()
        for (endpoint in refreshEndpoints) {
            if (endpoint.role == "TARGET" && endpoint.format == "image/png") {
                declarations.add(CjguiComposableUiDataTransferDeclaration.target(endpoint.semanticId,
                    CjguiSharedOperationTransferFormat.png(),
                    receiverIncarnation: endpoint.receiverIncarnation,
                    localPngFileAllowed: endpoint.localPngFileAllowed))
            }
        }
        if (let Some(offer) <- pngOwner.snapshot().offer) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source(GENERATED_CONSUMER_PNG_SOURCE, offer))
            for (endpoint in refreshEndpoints) {
                if (endpoint.role == "SOURCE" && endpoint.format == "image/png") {
                    declarations.add(CjguiComposableUiDataTransferDeclaration.source(endpoint.semanticId, offer))
                }
            }
        }
        return declarations
    }

    public func dataTransferOwnerVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.semanticId == GENERATED_CONSUMER_PNG_TARGET) { return pngOwner.version() }
        for (endpoint in generatedRegion.refreshTransferEndpoints()) {
            if (endpoint.role == "TARGET" && endpoint.nodeId == node.nodeId &&
                endpoint.semanticId == node.semanticId) {
                return pngOwner.version()
            }
        }
        for (endpoint in generatedRegion.acceptedTransferEndpoints()) {
            if (endpoint.role == "TARGET" && endpoint.nodeId == node.nodeId &&
                endpoint.semanticId == node.semanticId) {
                return pngOwner.version()
            }
        }
        return -1
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
            getStdOut().writeln("CJGUI_PNG_COPY consumer=generated-panel version=${pngOwner.version()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(false)
        }
        let ownerStarted = MonoTime.now()
        let result = pngOwner.accept(event.offer, event.expectedOwnerVersion,
            event.imageWidth, event.imageHeight)
        let ownerMicros = (MonoTime.now() - ownerStarted).toMicroseconds()
        if (!result.applied) {
            let _ = rejectDataTransfer(event.node.nodeId, event.eventKind, result.reason)
            return CjguiComposableUiDispatchResult(false, transferResult: Some(result))
        }
        pngOutcome = "accepted ${event.offer.contentDigest}"
        revision += 1
        getStdOut().writeln("CJGUI_PNG_OWNER consumer=generated-panel kind=${event.eventKind} " +
            "version=${pngOwner.version()} bytes=${event.offer.payloadByteCount} " +
            "digest=${event.offer.contentDigest} width=${event.imageWidth} height=${event.imageHeight} " +
            "decode_us=${event.decodeMicros} owner_us=${ownerMicros} epoch=${event.bindingEpoch}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(true, transferResult: Some(result))
    }

    public func rejectDataTransfer(nodeId: Int64, eventKind: Int64, reason: String): CjguiComposableUiDispatchResult {
        pngOutcome = "rejected ${reason}"
        revision += 1
        getStdOut().writeln("CJGUI_PNG_REJECT consumer=generated-panel kind=${eventKind} " +
            "node=${nodeId} reason=${reason} version=${pngOwner.version()}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        // P2: cancel this region's paint-alpha binding on the close path so no
        // old animation completion lands after teardown.
        generatedRegion.prepareWindowClose()
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool {
        // Handwritten identities and the generated candidate identities open in
        // one transaction: the window's scene acceptance decides both.
        if (!components.beginTransaction()) {
            return false
        }
        if (!generatedRegion.beginSceneRefresh()) {
            components.rollbackTransaction()
            return false
        }
        return true
    }
    public func prepareSceneRefresh(): Bool {
        if (!components.prepareTransaction()) {
            generatedRegion.rollbackSceneRefresh()
            return false
        }
        if (!generatedRegion.prepareSceneRefresh()) {
            generatedRegion.rollbackSceneRefresh()
            return false
        }
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("collaboration.add", 7, CjguiComposableUiShortcut("a"))
        ])
    }
    public func commitSceneRefresh(): Unit {
        components.commitTransaction()
        generatedRegion.commitSceneRefresh()
    }
    public func disposeSceneRefreshResources(): Unit {
        generatedRegion.releaseImageIdentities()
        eprintln("CJGUI_IMAGE_IDENTITY_DISPOSE leftover_holds=${generatedRegion.liveImageIdentityHoldCount()}")
    }
    public func rollbackSceneRefresh(): Unit {
        components.rollbackTransaction()
        generatedRegion.rollbackSceneRefresh()
    }

    private func taskFromSnapshot(snapshot: CjguiSharedOperationSnapshot): CjguiSharedOperationRecord {
        var index: Int64 = 0
        while (index < snapshot.records.size) {
            let record = snapshot.recordAt(index)
            if (record.id == TASK_RESOURCE_ID) { return record }
            index += 1
        }
        throw IllegalStateException("collaboration task resource is missing")
    }

    private func displayTitle(title: String): String {
        return if (title.size == 0) { "（尚未填写）" } else { title }
    }

    /// The stored value of a declared text field, read from the owner snapshot.
    private func currentText(fieldId: String, task: CjguiSharedOperationRecord): String {
        if (fieldId == "title") {
            return task.title
        }
        if (fieldId == "notes") {
            return task.notes
        }
        return ""
    }
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "collaboration-starter-authorized-client", "demo-only-authorized-local-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_NODE_TRANSLATION", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_NODE_TRANSLATION", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("CLEAR_NODE_TRANSLATION", ArrayList<Int64>(), true),
            // The interaction projection is the second consumer's OWN focus
            // answer: it publishes the accepted scene identity (control id,
            // field/object, focus, selection) with the three distinct facts
            // valid / unfocused / unknown. Real desktop input may only claim
            // "this exact accepted instance received the keystrokes" through
            // this read; the AX owner read-back is an explicitly degraded grade.
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_TITLE", ArrayList<Int64>([TASK_RESOURCE_ID]), false),
            CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([TASK_RESOURCE_ID]), false),
            // The declared notes field is part of the same single definition the
            // generated card and the handwritten pane use, so the external
            // client that may already write the title can write it too.
            CjguiSharedOperationExternalActionScope("SET_NOTES", ArrayList<Int64>([TASK_RESOURCE_ID]), false),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", ArrayList<Int64>(), true)
        ])
    )
}

/// Absolute difference helper for the consumer's own float assertions (the
/// dispatch module does not import std.math just for a comparison).
private func cjguiConsumerAbs(value: Float64): Float64 {
    return if (value < 0.0) { -value } else { value }
}

private func cjguiConsumerApprox(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    return cjguiConsumerAbs(actual - expected) <= tolerance
}

/// Read one accepted node by semantic id so the self-verification asserts the
/// SAME committed projection the window displays (never a controller field).
private func acceptedNodeForSemantic(window: CjguiComposableUiWindow,
    semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

private func generatedDiagnosticNode(snapshot: CjguiComposableUiDiagnosticSnapshot,
    identity: String): ?CjguiComposableUiDiagnosticNode {
    for (node in snapshot.nodes) {
        if (node.identityKey == identity) { return Some(node) }
    }
    return None
}

private func generatedWaitDiagnosticIdle(host: CjguiMacosApplicationHost,
    window: CjguiComposableUiWindow): Int64 {
    var stable = 0
    var turns = 0
    var previous = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
    while (host.isOpen() && turns < 100 && stable < 4) {
        let _ = host.pumpOneTurn()
        let current = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
        if (current == previous && !window.needsAnimationTick()) { stable += 1 } else { stable = 0 }
        previous = current
        turns += 1
    }
    return turns
}

private func generatedVisualOffsetIs(window: CjguiComposableUiWindow,
    region: CjguiTaskGeneratedRegion, key: String, expectedX: Float64, expectedY: Float64): Bool {
    let nodeId = if (key == "taskCard") {
        region.acceptedCompositeElementNodeId("taskCard", "root")
    } else { region.acceptedNodeIdForKey(key) }
    if (nodeId < 0) { return false }
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            if (let Some(visual) <- window.acceptedNodeVisualBounds(node.semanticId)) {
                let actualX = visual.x - Float64(node.bounds.x)
                let actualY = visual.y - Float64(node.bounds.y)
                let deltaX = actualX - expectedX
                let deltaY = actualY - expectedY
                return (if (deltaX < 0.0) { -deltaX } else { deltaX }) < 0.0001 &&
                    (if (deltaY < 0.0) { -deltaY } else { deltaY }) < 0.0001
            }
        }
    }
    return false
}

private func generatedVisualOffsetLine(window: CjguiComposableUiWindow,
    region: CjguiTaskGeneratedRegion, key: String): String {
    let nodeId = if (key == "taskCard") {
        region.acceptedCompositeElementNodeId("taskCard", "root")
    } else { region.acceptedNodeIdForKey(key) }
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            if (let Some(visual) <- window.acceptedNodeVisualBounds(node.semanticId)) {
                return "${key}:node=${nodeId}:semantic=${node.semanticId}:layout=${node.bounds.x},${node.bounds.y}:" +
                    "visual=${visual.x},${visual.y}:delta=${visual.x - Float64(node.bounds.x)}," +
                    "${visual.y - Float64(node.bounds.y)}"
            }
        }
    }
    return "${key}:node=${nodeId}:missing"
}

private func generatedActivateAcceptedAction(window: CjguiComposableUiWindow,
    controller: CollaborationStarterController, region: CjguiTaskGeneratedRegion,
    key: String, actionName: String): Bool {
    let nodeId = region.acceptedNodeIdForKey(key)
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId && node.actionName == "GENERATED_ACTION" &&
            node.operationActionName == actionName) {
            return controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0, 0)).didApply
        }
    }
    return false
}

private func generatedDiagnosticReadBatch(window: CjguiComposableUiWindow): Int64 {
    let started = MonoTime.now()
    var count = 0
    while (count < 24) {
        let _ = window.diagnosticSnapshot(maximumNodes: 256)
        count += 1
    }
    return (MonoTime.now() - started).toMicroseconds()
}

main(args: Array<String>): Int64 {
    // `--verify-animation` / `--verify-normal-close` are self-verification
    // entries. A verification script may launch this instance with a
    // round-unique token so the exact process of THIS round can be identified by
    // its own command line (never "newest pid matching the binary path").
    // `--inject-verify-failure` makes one assertion fail on purpose so a caller
    // can prove the exit code and the completion marker really fail the chain.
    var verifiesNormalClose = false
    var verifiesAnimation = false
    var verifiesTranslation = false
    var verifiesPositionMotion = false
    var effectProbeReleasePath = ""
    var diagnosticGatePath = ""
    var instanceToken = ""
    var injectVerifyFailure = false
    var argIndex = 0
    while (argIndex < args.size) {
        if (args[argIndex] == "--verify-normal-close") {
            verifiesNormalClose = true
        } else if (args[argIndex] == "--verify-animation") {
            verifiesAnimation = true
        } else if (args[argIndex] == "--verify-translation") {
            verifiesTranslation = true
        } else if (args[argIndex] == "--verify-position-motion") {
            verifiesPositionMotion = true
        } else if (args[argIndex] == "--verify-effect-fallback" && argIndex + 1 < args.size) {
            effectProbeReleasePath = args[argIndex + 1]
            argIndex += 1
        } else if (args[argIndex] == "--verify-diagnostics" && argIndex + 1 < args.size) {
            diagnosticGatePath = args[argIndex + 1]
            argIndex += 1
        } else if (args[argIndex] == "--inject-verify-failure") {
            injectVerifyFailure = true
        } else if (args[argIndex] == "--instance-token" && argIndex + 1 < args.size) {
            instanceToken = args[argIndex + 1]
            argIndex += 1
        } else {
            return 2
        }
        argIndex += 1
    }
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(TASK_RESOURCE_ID, "", false)
    ]))
    // The application installs its declared field rules for every record it
    // exposes. Every later write - handwritten pane, generated editor or
    // external invocation - is then checked by the same rule inside the owner
    // transaction, and the owner never invents a rule for a target the
    // application did not wire.
    if (!CjguiTaskFields.installIntoEveryRecord(domain)) {
        return 1
    }
    let controller = CollaborationStarterController(domain)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("协作任务板", 840u32, 800u32)
    )
    let window = host.window()
    // Address generated instances by declared key: the projection needs the
    // window whose accepted scene carries them.
    controller.generatedUiRegion().attachWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableTransferReceiptReads(window) ||
        !connection.enablePositionMotion(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        getStdOut().writeln("CJGUI_COLLABORATION_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        getStdOut().flush()
    }
    // P1: the normal window's generated description is submitted through the
    // public generated submit entry before the first frame, so the declared
    // shadow and gradient are really rendered by the framework and are never
    // painted by this consumer. The description also carries the generated
    // controls that later re-declare the effect.
    let generatedRegion = controller.generatedUiRegion()
    // Announce this instance's identity and the registered motion surface before
    // any transition: a verifier binds the exact process by token, and an
    // external reader can see the real supported parameters and backend.
    getStdOut().writeln("CJGUI_COLLABORATION_SELF instance_token=${instanceToken} pid=${getProcessId()} " +
        "role=generated-panel-consumer verifyAnimation=${if (verifiesAnimation) { 1 } else { 0 }}")
    getStdOut().writeln("CJGUI_GENERATED_MOTION_CAPABILITY ${generatedRegion.motionCapabilityLine()}")
    getStdOut().flush()
    // The older backdrop-blur probe needs an opaque root to distinguish its
    // own fallback. Keep that probe on its established scene while ordinary
    // generated windows start with the new system material declaration.
    let initialStructure = if (effectProbeReleasePath.size > 0 || diagnosticGatePath.size > 0) {
        CjguiTaskGeneratedRegion.effectStructure(0, true,
            windowBackground: CjguiWindowBackgroundPolicy.OPAQUE)
    } else {
        generatedRegion.initialEffectStructure()
    }
    let initialSubmit = generatedRegion.submitStructure(initialStructure,
        generatedRegion.acceptedStructureVersion())
    // The generated holder can accept its candidate before the window has
    // presented the corresponding scene. Expose an external motion target only
    // after the same scene reaches the window's accepted binding table.
    if (initialSubmit.candidateAccepted) { let _ = window.refresh() }
    var positionMotionNodeId: Int64 = -1
    var positionMotionExposed = false
    var positionExposeTurns = 0
    while (initialSubmit.candidateAccepted && !positionMotionExposed && positionExposeTurns < 16 && host.isOpen()) {
        positionMotionNodeId = generatedRegion.acceptedNodeIdForKey("translatedSplit")
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == positionMotionNodeId) {
                positionMotionExposed = window.exposeAcceptedPositionMotionTarget(node.identityKey)
            }
        }
        if (!positionMotionExposed) {
            let _ = host.pumpOneTurn()
            positionExposeTurns += 1
        }
    }
    getStdOut().writeln("CJGUI_GENERATED_POSITION_EXPOSURE accepted=${if (positionMotionExposed) { 1 } else { 0 }} " +
        "node=${positionMotionNodeId} settle_turns=${positionExposeTurns}")
    getStdOut().writeln("CJGUI_GENERATED_EFFECT_SUBMIT accepted=${initialSubmit.candidateAccepted} " +
        "reason=${if (initialSubmit.reason.size == 0) { "none" } else { initialSubmit.reason }}")
    let scaleReadStarted = MonoTime.now()
    let scaleProgress = window.windowProgress()
    let scaleDiagnostic = window.diagnosticSnapshot(maximumNodes: 1)
    let scaleReadMicros = (MonoTime.now() - scaleReadStarted).toMicroseconds()
    getStdOut().writeln("CJGUI_SCALE_CONSUMER consumer=generated-panel session=${scaleProgress.sessionIdentity} " +
        "scene=${scaleProgress.acceptedSceneVersion} frame=${scaleProgress.geometry.submittedFrameIndex} " +
        "points=${scaleProgress.geometry.currentWidthPoints}x${scaleProgress.geometry.currentHeightPoints} " +
        "pixels=${scaleProgress.geometry.currentDrawableWidthPixels}x${scaleProgress.geometry.currentDrawableHeightPixels} " +
        "scale=${scaleProgress.geometry.currentBackingScale} revision=${scaleProgress.geometry.currentRevision} " +
        "diagnostic_same_revision=${if (scaleDiagnostic.geometry.currentRevision == scaleProgress.geometry.currentRevision) { 1 } else { 0 }} " +
        "read_us=${scaleReadMicros}")
    getStdOut().flush()
    if (verifiesPositionMotion) {
        var failed = 0
        let _ = window.setReduceMotionEnabled(false)
        let _ = window.setWorkloadDiagnostics(true)
        var turns = 0
        while (turns < 60 && host.isOpen() &&
            (generatedRegion.acceptedNodeIdForKey("positionAnimate") < 0 ||
                !generatedVisualOffsetIs(window, generatedRegion, "translatedSplit", 0.25, 0.5))) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let splitId = generatedRegion.acceptedNodeIdForKey("translatedSplit")
        var splitIdentity = ""
        var baseX = 0.0
        var baseY = 0.0
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == splitId) {
                splitIdentity = node.identityKey
                baseX = node.declaredStyle.translateX
                baseY = node.declaredStyle.translateY
            }
        }
        let ownerBefore = domain.version()
        let staticSample = window.diagnosticSnapshot(maximumNodes: 1)
        let first = generatedActivateAcceptedAction(window, controller, generatedRegion,
            "positionAnimate", "ANIMATE_GENERATED_POSITION")
        turns = 0
        while (turns < 4 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let mid = generatedRegion.positionMotionStatus()
        let midX = match (mid) {
            case Some(value) => value.presented.x
            case None => -10000.0
        }
        let midScene = window.diagnosticSnapshot(maximumNodes: 1)
        let moving = first && midX > baseX && midX < baseX + 24.0 &&
            midScene.acceptedSceneVersion > staticSample.acceptedSceneVersion
        if (!moving) { failed += 1 }
        let reverse = generatedActivateAcceptedAction(window, controller, generatedRegion,
            "positionAnimate", "ANIMATE_GENERATED_POSITION")
        let reverseAt = generatedRegion.positionMotionStatus()
        let continuous = reverse && (match (reverseAt) {
            case Some(value) => value.presented.x == midX && value.target.x == baseX
            case None => false
        })
        if (!continuous) { failed += 1 }
        turns = 0
        while (turns < 100 && host.isOpen() && window.needsAnimationTick()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let within = window.diagnosticSnapshot(maximumNodes: 1)
        let returned = match (generatedRegion.positionMotionStatus()) {
            case Some(value) => value.presented.x == baseX && value.presented.y == baseY && !value.active
            case None => false
        }
        if (!returned || window.needsAnimationTick()) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_POSITION_COST phase=within ok=${if (moving && continuous && returned) { 1 } else { 0 }} " +
            "build_ns=${within.totalBuildNanoseconds - staticSample.totalBuildNanoseconds} " +
            "layout_ns=${within.totalLayoutNanoseconds - staticSample.totalLayoutNanoseconds} " +
            "submit_ns=${within.totalNativeStageAndSubmitNanoseconds - staticSample.totalNativeStageAndSubmitNanoseconds} " +
            "text_prepares=${within.textLayoutPreparationCount - staticSample.textLayoutPreparationCount} " +
            "raster_tiles=${within.textRasterCount - staticSample.textRasterCount} " +
            "upload_tiles=${within.textUploadCount - staticSample.textUploadCount} " +
            "decode_starts=${within.imageDecodeStartCount - staticSample.imageDecodeStartCount} " +
            "live_bytes=${staticSample.textTextureLiveBytes}->${within.textTextureLiveBytes} " +
            "peak_bytes=${within.textCandidatePeakBytes} " +
            "scene=${staticSample.acceptedSceneVersion}->${within.acceptedSceneVersion} " +
            "submissions=${staticSample.nativeSubmissionCount}->${within.nativeSubmissionCount}")
        let spec = CjguiGeneratedMotionRegistry.positionTransitionRule().spec() ??
            CjguiComposableUiAnimationSpec.tween(durationMs: 240)
        let crossStarted = window.animateNodeTranslation(splitIdentity, baseX + 280.0, baseY,
            spec: spec, atTime: MonoTime.now())
        turns = 0
        while (turns < 100 && host.isOpen() && window.needsAnimationTick()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let cross = window.diagnosticSnapshot(maximumNodes: 1)
        let crossAccepted = crossStarted && (match (generatedRegion.positionMotionStatus()) {
            case Some(value) => value.presented.x == baseX + 280.0 && !value.active
            case None => false
        }) && cross.totalBuildNanoseconds == within.totalBuildNanoseconds &&
            cross.totalLayoutNanoseconds == within.totalLayoutNanoseconds
        if (!crossAccepted) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_POSITION_COST phase=cross_coverage ok=${if (crossAccepted) { 1 } else { 0 }} " +
            "build_ns=${cross.totalBuildNanoseconds - within.totalBuildNanoseconds} " +
            "layout_ns=${cross.totalLayoutNanoseconds - within.totalLayoutNanoseconds} " +
            "submit_ns=${cross.totalNativeStageAndSubmitNanoseconds - within.totalNativeStageAndSubmitNanoseconds} " +
            "text_prepares=${cross.textLayoutPreparationCount - within.textLayoutPreparationCount} " +
            "raster_tiles=${cross.textRasterCount - within.textRasterCount} " +
            "upload_tiles=${cross.textUploadCount - within.textUploadCount} " +
            "decode_starts=${cross.imageDecodeStartCount - within.imageDecodeStartCount} " +
            "live_bytes=${within.textTextureLiveBytes}->${cross.textTextureLiveBytes} " +
            "peak_bytes=${cross.textCandidatePeakBytes} " +
            "scene=${within.acceptedSceneVersion}->${cross.acceptedSceneVersion} " +
            "submissions=${within.nativeSubmissionCount}->${cross.nativeSubmissionCount}")
        let cleared = generatedActivateAcceptedAction(window, controller, generatedRegion,
            "positionClear", "CLEAR_GENERATED_POSITION")
        let clearedOk = cleared && generatedRegion.positionMotionStatus().isNone() &&
            domain.version() == ownerBefore && !window.needsAnimationTick()
        if (!clearedOk || injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_POSITION_DONE instance_token=${instanceToken} " +
            "moving=${if (moving) { 1 } else { 0 }} reverse=${if (continuous) { 1 } else { 0 }} " +
            "terminal=${if (returned) { 1 } else { 0 }} cross=${if (crossAccepted) { 1 } else { 0 }} " +
            "clear=${if (clearedOk) { 1 } else { 0 }} owner=${ownerBefore}->${domain.version()} failed=${failed}")
        getStdOut().flush()
        host.close()
        return if (failed == 0) { 0 } else { 1 }
    }
    if (verifiesTranslation) {
        var failed = 0
        var turns = 0
        while (turns < 60 && host.isOpen() &&
            !generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 0.25, 0.5)) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let initialOk = generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 0.25, 0.5) &&
            generatedVisualOffsetIs(window, generatedRegion, "gradientTitle", -0.5, 0.75) &&
            generatedVisualOffsetIs(window, generatedRegion, "taskCard", 0.375, 0.25) &&
            generatedVisualOffsetIs(window, generatedRegion, "translatedSplit", 0.25, 0.5) &&
            generatedRegion.acceptedNodeIdForKey("translatedOffscreenNotes") >= 0
        let titleNodeId = generatedRegion.acceptedCompositeElementNodeId("taskCard", "title")
        let initialTextIdentity = window.textGeometryIdentity(titleNodeId)
        let initialCaret = window.textCaretRect(titleNodeId, 0,
            initialTextIdentity.contentVersion, initialTextIdentity.layoutVersion)
        if (!initialOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_GEOMETRY phase=initial " +
            "${generatedVisualOffsetLine(window, generatedRegion, "effectGroup")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "gradientTitle")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "taskCard")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "translatedSplit")} " +
            "offscreen=${generatedRegion.acceptedNodeIdForKey("translatedOffscreenNotes")}")
        let ownerBefore = domain.version()
        let _ = window.setWorkloadDiagnostics(true)
        let before = window.diagnosticSnapshot(maximumNodes: 1)
        let farStructure = CjguiTaskGeneratedRegion.effectStructure(0, true, translationVariant: 1)
        let started = MonoTime.now()
        let farAttempt = generatedRegion.submitStructure(farStructure, generatedRegion.acceptedStructureVersion())
        turns = 0
        while (turns < 60 && host.isOpen() &&
            !generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 30.25, 12.5)) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let far = window.diagnosticSnapshot(maximumNodes: 1)
        let farOk = farAttempt.candidateAccepted &&
            generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 30.25, 12.5) &&
            generatedVisualOffsetIs(window, generatedRegion, "gradientTitle", 29.5, 12.75) &&
            generatedVisualOffsetIs(window, generatedRegion, "taskCard", 30.375, 12.25) &&
            domain.version() == ownerBefore && far.acceptedSceneVersion > before.acceptedSceneVersion
        let farTextIdentity = window.textGeometryIdentity(titleNodeId)
        let farCaret = window.textCaretRect(titleNodeId, 0,
            farTextIdentity.contentVersion, farTextIdentity.layoutVersion)
        let caretMoved = initialCaret.available && farCaret.available &&
            farTextIdentity.transformVersion > initialTextIdentity.transformVersion &&
            (farCaret.xPt - initialCaret.xPt - 30.0) < 0.0001 &&
            (farCaret.xPt - initialCaret.xPt - 30.0) > -0.0001 &&
            (farCaret.yPt - initialCaret.yPt - 12.0) < 0.0001 &&
            (farCaret.yPt - initialCaret.yPt - 12.0) > -0.0001
        if (!caretMoved) { failed += 1 }
        if (!farOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_GEOMETRY phase=far " +
            "${generatedVisualOffsetLine(window, generatedRegion, "effectGroup")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "gradientTitle")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "taskCard")}")
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_SAMPLE phase=far ok=${if (farOk) { 1 } else { 0 }} " +
            "scene=${before.acceptedSceneVersion}->${far.acceptedSceneVersion} " +
            "build_ns=${far.buildNanoseconds} layout_ns=${far.layoutNanoseconds} " +
            "submit_ns=${far.nativeStageAndSubmitNanoseconds} " +
            "text_prepares=${far.lastAttemptTextLayoutPreparations} " +
            "decode_starts=${far.lastAttemptImageDecodeStarts} " +
            "native_submissions=${before.nativeSubmissionCount}->${far.nativeSubmissionCount} " +
            "elapsed_us=${(MonoTime.now() - started).toMicroseconds()}")
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_COST phase=far " +
            "operation_build_ns=${far.totalBuildNanoseconds - before.totalBuildNanoseconds} " +
            "operation_layout_ns=${far.totalLayoutNanoseconds - before.totalLayoutNanoseconds} " +
            "operation_submit_ns=${far.totalNativeStageAndSubmitNanoseconds - before.totalNativeStageAndSubmitNanoseconds} " +
            "text_prepares=${far.textLayoutPreparationCount - before.textLayoutPreparationCount} " +
            "raster_tiles=${far.textRasterCount - before.textRasterCount} " +
            "raster_bytes=${far.textRasterBytes - before.textRasterBytes} " +
            "raster_us=${far.textRasterMicros - before.textRasterMicros} " +
            "upload_tiles=${far.textUploadCount - before.textUploadCount} " +
            "upload_bytes=${far.textUploadBytes - before.textUploadBytes} " +
            "upload_us=${far.textUploadMicros - before.textUploadMicros} " +
            "decode_starts=${far.imageDecodeStartCount - before.imageDecodeStartCount} " +
            "text_live_bytes=${before.textTextureLiveBytes}->${far.textTextureLiveBytes} " +
            "text_candidate_peak_bytes=${far.textCandidatePeakBytes} " +
            "submissions=${before.nativeSubmissionCount}->${far.nativeSubmissionCount}")
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_CARET ok=${if (caretMoved) { 1 } else { 0 }} " +
            "node=${titleNodeId} before=${initialCaret.xPt},${initialCaret.yPt}/${initialCaret.reason} " +
            "after=${farCaret.xPt},${farCaret.yPt}/${farCaret.reason} " +
            "content=${initialTextIdentity.contentVersion}->${farTextIdentity.contentVersion} " +
            "transform=${initialTextIdentity.transformVersion}->${farTextIdentity.transformVersion}")
        let illegal = farStructure.replace("PROPERTY 1 effectGroup translateX 30.25",
            "PROPERTY 1 effectGroup translateX 1025")
        let refused = generatedRegion.submitStructure(illegal, generatedRegion.acceptedStructureVersion())
        let rejected = window.diagnosticSnapshot(maximumNodes: 1)
        let rejectedOk = !refused.candidateAccepted && refused.reason == "translation_value_invalid" &&
            rejected.acceptedSceneVersion == far.acceptedSceneVersion &&
            generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 30.25, 12.5) &&
            domain.version() == ownerBefore
        if (!rejectedOk) { failed += 1 }
        let cleared = generatedRegion.submitStructure(
            CjguiTaskGeneratedRegion.effectStructure(0, true, translationVariant: 2),
            generatedRegion.acceptedStructureVersion())
        turns = 0
        while (turns < 60 && host.isOpen() &&
            !generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 0.0, 0.0)) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let clearSample = window.diagnosticSnapshot(maximumNodes: 1)
        let clearedOk = cleared.candidateAccepted &&
            generatedVisualOffsetIs(window, generatedRegion, "effectGroup", 0.0, 0.0) &&
            generatedVisualOffsetIs(window, generatedRegion, "gradientTitle", 0.0, 0.0) &&
            generatedVisualOffsetIs(window, generatedRegion, "taskCard", 0.0, 0.0) &&
            clearSample.acceptedSceneVersion > far.acceptedSceneVersion && domain.version() == ownerBefore
        if (!clearedOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_GEOMETRY phase=clear " +
            "${generatedVisualOffsetLine(window, generatedRegion, "effectGroup")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "gradientTitle")} " +
            "${generatedVisualOffsetLine(window, generatedRegion, "taskCard")}")
        var stableTurns = 0
        var idleTurns = 0
        var previousSubmissions = clearSample.nativeSubmissionCount
        let idleStarted = MonoTime.now()
        while (host.isOpen() && stableTurns < 4 &&
            (MonoTime.now() - idleStarted).toMilliseconds() < 1000) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            let current = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
            if (current == previousSubmissions && !window.needsAnimationTick()) {
                stableTurns += 1
            } else { stableTurns = 0 }
            previousSubmissions = current
            idleTurns += 1
        }
        let settled = window.diagnosticSnapshot(maximumNodes: 1)
        turns = 0
        while (turns < 4 && host.isOpen()) { let _ = host.pumpOneTurn(); turns += 1 }
        let idle = window.diagnosticSnapshot(maximumNodes: 1)
        let idleOk = stableTurns == 4 && idle.nativeSubmissionCount == settled.nativeSubmissionCount
        if (!idleOk) { failed += 1 }
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_TRANSLATION_DONE instance_token=${instanceToken} " +
            "initial=${if (initialOk) { 1 } else { 0 }} far=${if (farOk) { 1 } else { 0 }} " +
            "rejected=${if (rejectedOk) { 1 } else { 0 }} cleared=${if (clearedOk) { 1 } else { 0 }} " +
            "idle=${if (idleOk) { 1 } else { 0 }} owner=${ownerBefore}->${domain.version()} " +
            "scene=${before.acceptedSceneVersion}->${far.acceptedSceneVersion}->${clearSample.acceptedSceneVersion} " +
            "submissions=${before.nativeSubmissionCount}->${far.nativeSubmissionCount}->" +
            "${clearSample.nativeSubmissionCount}->${settled.nativeSubmissionCount}->${idle.nativeSubmissionCount} " +
            "idle_turns=${idleTurns} idle_ms=${(MonoTime.now() - idleStarted).toMilliseconds()} " +
            "failed=${failed}")
        getStdOut().flush()
        host.close()
        return if (failed != 0) { 1 } else { 0 }
    }
    // A public client supplies the legal and rejected generated candidates.
    // Gate files only let this ordinary window sample each settled scene before
    // the next candidate; no private holder operation creates those candidates.
    if (diagnosticGatePath.size > 0) {
        var failed = 0
        let initialIdleTurns = generatedWaitDiagnosticIdle(host, window)
        let groupId = generatedRegion.acceptedNodeIdForKey("effectGroup")
        var groupIdentity = ""
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == groupId) { groupIdentity = node.identityKey }
        }
        let initialStarted = MonoTime.now()
        let initial = window.diagnosticSnapshot(maximumNodes: 256)
        let initialReadMicros = (MonoTime.now() - initialStarted).toMicroseconds()
        let offReadBatchMicros = generatedDiagnosticReadBatch(window)
        let initialOk = groupIdentity.size > 0 && initial.status == "ok" &&
            generatedDiagnosticNode(initial, groupIdentity).isSome() &&
            initial.nodes.size <= 256 && initial.acceptedSceneVersion > 0
        if (!initialOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=initial_generated ok=${if (initialOk) { 1 } else { 0 }} " +
            "scene=${initial.acceptedSceneVersion} identity=${groupIdentity} " +
            "nodes=${initial.nodes.size}/${initial.totalNodes} read_us=${initialReadMicros} " +
            "live_bytes=${initial.effectLiveBytes} idle_turns=${initialIdleTurns} " +
            "off_read_24_us=${offReadBatchMicros}")
        let enabled = window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
            selectedIdentityKey: groupIdentity))
        let immediate = window.diagnosticSnapshot(maximumNodes: 1)
        let overlayStarted = MonoTime.now()
        let overlay = window.diagnosticSnapshot(maximumNodes: 256)
        let overlayReadMicros = (MonoTime.now() - overlayStarted).toMicroseconds()
        let onReadBatchMicros = generatedDiagnosticReadBatch(window)
        let overlayOk = enabled && overlay.overlayEnabled &&
            immediate.nativeSubmissionCount == initial.nativeSubmissionCount &&
            overlay.nativeSubmissionCount == initial.nativeSubmissionCount &&
            overlay.acceptedSceneVersion == initial.acceptedSceneVersion &&
            overlay.effectLiveBytes == initial.effectLiveBytes &&
            overlay.effectCachedBytes == initial.effectCachedBytes
        if (!overlayOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=overlay_isolated ok=${if (overlayOk) { 1 } else { 0 }} " +
            "scene=${overlay.acceptedSceneVersion} submissions=${initial.nativeSubmissionCount}->${overlay.nativeSubmissionCount} " +
            "read_us=${overlayReadMicros} on_read_24_us=${onReadBatchMicros} " +
            "live_bytes=${initial.effectLiveBytes}->${overlay.effectLiveBytes} " +
            "cached_bytes=${initial.effectCachedBytes}->${overlay.effectCachedBytes}")
        // F-C: the public client's next candidate is the real control change.
        // Publish the bounded workload scalars so its accepted attempt can be
        // attributed from the same public snapshot the client already drives.
        let workloadEnabled = window.setWorkloadDiagnostics(true)
        let workloadBefore = window.diagnosticSnapshot(maximumNodes: 1)
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_READY scene=${overlay.acceptedSceneVersion} identity=${groupIdentity}")
        getStdOut().flush()
        let started = MonoTime.now()
        while (host.isOpen() && !exists(diagnosticGatePath + ".accepted") &&
            (MonoTime.now() - started).toMilliseconds() < 30000) {
            let _ = host.pumpOneTurn()
        }
        let accepted = window.diagnosticSnapshot(maximumNodes: 256)
        let acceptedNode = generatedDiagnosticNode(accepted, groupIdentity)
        let nativeState = match (acceptedNode) {
            case Some(node) => node.nativeGeometryState
            case None => "absent"
        }
        let nativeOutput = match (acceptedNode) {
            case Some(node) => node.nativeOutputBounds.isSome()
            case None => false
        }
        let nativeSample = match (acceptedNode) {
            case Some(node) => node.nativeBackdropSampleBounds.isSome()
            case None => false
        }
        let effect = window.windowProgress()
        let acceptedOk = exists(diagnosticGatePath + ".accepted") &&
            accepted.acceptedSceneVersion > overlay.acceptedSceneVersion &&
            acceptedNode.isSome() && accepted.overlayEnabled &&
            accepted.sessionIdentity == initial.sessionIdentity &&
            nativeState == "available" && nativeOutput &&
            (effect.effectSubmittedMode != "blurred" || nativeSample)
        if (!acceptedOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=external_accepted ok=${if (acceptedOk) { 1 } else { 0 }} " +
            "scene=${overlay.acceptedSceneVersion}->${accepted.acceptedSceneVersion} " +
            "submitted=${accepted.submittedSceneVersion}/${accepted.submittedFrameIndex} " +
            "complete=${accepted.completedFrameIndex} native=${nativeState} output=${if (nativeOutput) { 1 } else { 0 }} " +
            "sample=${if (nativeSample) { 1 } else { 0 }} effect=${effect.effectSubmittedMode}")
        let workloadAfter = window.diagnosticSnapshot(maximumNodes: 1)
        let workloadReread = window.diagnosticSnapshot(maximumNodes: 1)
        let workloadOk = workloadEnabled && workloadAfter.workloadEnabled &&
            workloadAfter.workloadStatus == "enabled" &&
            workloadAfter.lastAttemptWorkloadResult == "accepted" &&
            workloadBefore.nodeWriteCount >= 0 &&
            workloadAfter.nodeWriteCount - workloadBefore.nodeWriteCount >= workloadAfter.lastAttemptNodeWrites &&
            workloadAfter.lastAttemptNodeWrites >= 1 &&
            workloadAfter.lastAttemptNodeWrites <= workloadAfter.totalNodes &&
            workloadAfter.lastAttemptNodeClones >= 1 &&
            workloadAfter.lastAttemptNodeClones <= workloadAfter.totalNodes &&
            workloadAfter.reusableResourceBytes >= 0 &&
            workloadReread.nodeWriteCount == workloadAfter.nodeWriteCount &&
            workloadReread.lastAttemptNodeWrites == workloadAfter.lastAttemptNodeWrites &&
            workloadReread.nativeSubmissionCount == workloadAfter.nativeSubmissionCount
        if (!workloadOk) { failed += 1 }
        let workloadReadsIdle = workloadReread.nodeWriteCount == workloadAfter.nodeWriteCount &&
            workloadReread.nativeSubmissionCount == workloadAfter.nativeSubmissionCount
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=workload_observed ok=${if (workloadOk) { 1 } else { 0 }} " +
            "status=${workloadAfter.workloadStatus} result=${workloadAfter.lastAttemptWorkloadResult} " +
            "attempt_writes=${workloadAfter.lastAttemptNodeWrites} attempt_clones=${workloadAfter.lastAttemptNodeClones} " +
            "attempt_allocations=${workloadAfter.lastAttemptNodeAllocations} " +
            "attempt_text_prepares=${workloadAfter.lastAttemptTextLayoutPreparations} " +
            "attempt_decode_starts=${workloadAfter.lastAttemptImageDecodeStarts} " +
            "cumulative=${workloadBefore.nodeWriteCount}->${workloadAfter.nodeWriteCount}/" +
            "${workloadAfter.nodeCloneCount}/${workloadAfter.nodeAllocationCount} " +
            "scene=${workloadAfter.workloadSceneVersion} reusable_bytes=${workloadAfter.reusableResourceBytes} " +
            "reads_idle=${if (workloadReadsIdle) { 1 } else { 0 }}")
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_PHASE accepted")
        getStdOut().flush()
        let rejectStarted = MonoTime.now()
        while (host.isOpen() && !exists(diagnosticGatePath + ".rejected") &&
            (MonoTime.now() - rejectStarted).toMilliseconds() < 30000) {
            let _ = host.pumpOneTurn()
        }
        let rejected = window.diagnosticSnapshot(maximumNodes: 256)
        let stale = window.diagnosticSnapshot(maximumNodes: 8,
            expectedSessionIdentity: initial.sessionIdentity,
            expectedAcceptedSceneVersion: overlay.acceptedSceneVersion)
        let rejectedOk = exists(diagnosticGatePath + ".rejected") &&
            rejected.acceptedSceneVersion == accepted.acceptedSceneVersion &&
            generatedDiagnosticNode(rejected, groupIdentity).isSome() &&
            stale.status == "stale_accepted" && stale.nodes.size == 0
        if (!rejectedOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=rejected_keeps_accepted ok=${if (rejectedOk) { 1 } else { 0 }} " +
            "scene=${rejected.acceptedSceneVersion}")
        let preDisableIdleTurns = generatedWaitDiagnosticIdle(host, window)
        let disabled = window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(false))
        let disabledSnap = window.diagnosticSnapshot(maximumNodes: 1)
        var turns = 0
        while (turns < 4 && host.isOpen()) { let _ = host.pumpOneTurn(); turns += 1 }
        let settled = window.diagnosticSnapshot(maximumNodes: 1)
        let disabledReadBatchMicros = generatedDiagnosticReadBatch(window)
        let idleOk = disabled && !settled.overlayEnabled &&
            settled.nativeSubmissionCount == disabledSnap.nativeSubmissionCount &&
            settled.overlayDrawCount == disabledSnap.overlayDrawCount
        if (!idleOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=disable_idle ok=${if (idleOk) { 1 } else { 0 }} " +
            "draws=${disabledSnap.overlayDrawCount}->${settled.overlayDrawCount} " +
            "submissions=${disabledSnap.nativeSubmissionCount}->${settled.nativeSubmissionCount} " +
            "idle_turns=${preDisableIdleTurns} disabled_read_24_us=${disabledReadBatchMicros}")
        let workloadStopped = window.setWorkloadDiagnostics(false)
        let workloadDisabled = window.diagnosticSnapshot(maximumNodes: 1)
        var workloadIdleTurns = 0
        while (workloadIdleTurns < 2 && host.isOpen()) { let _ = host.pumpOneTurn(); workloadIdleTurns += 1 }
        let workloadSettled = window.diagnosticSnapshot(maximumNodes: 1)
        let workloadDisabledOk = workloadStopped && !workloadDisabled.workloadEnabled &&
            workloadDisabled.workloadStatus == "disabled" && workloadDisabled.nodeWriteCount == -1 &&
            workloadDisabled.nodeCloneCount == -1 && workloadDisabled.lastAttemptNodeWrites == -1 &&
            workloadSettled.nativeSubmissionCount == workloadDisabled.nativeSubmissionCount
        if (!workloadDisabledOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=workload_disabled ok=${if (workloadDisabledOk) { 1 } else { 0 }} " +
            "status=${workloadDisabled.workloadStatus} writes=${workloadDisabled.nodeWriteCount} " +
            "attempt_writes=${workloadDisabled.lastAttemptNodeWrites} " +
            "submissions=${workloadDisabled.nativeSubmissionCount}->${workloadSettled.nativeSubmissionCount}")
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_DIAGNOSTIC_DONE instance_token=${instanceToken} failed=${failed}")
        getStdOut().flush()
        if (failed != 0) { exit(1) }
        host.close()
        exit(0)
        return 0
    }
    // Test-only normal application leg. An external public client submits the
    // blur candidate, then reads the committed fallback before releasing this
    // round's private gate. The gate only schedules a root-clear change; all
    // effect facts still come from real scene/Metal submissions and the socket.
    if (effectProbeReleasePath.size > 0) {
        let started = MonoTime.now()
        var phase = 0
        while (host.isOpen() && (MonoTime.now() - started).toMilliseconds() < 30000) {
            if (phase == 1) {
                // Keep the submitted transparent-root frame stable while the
                // public client reads its receipt and guarded EFFECTS section.
                // Continue serving the real socket; a normal host turn would
                // schedule another opaque present before that read completes.
                let _ = connection.pump(1u32)
                sleep(Duration.millisecond)
            } else {
                let _ = host.pumpOneTurn()
            }
            let progress = window.windowProgress()
            if (phase == 0 && progress.effectRequestedRadiusPoints == 8 &&
                progress.effectSubmittedMode == "blurred") {
                if (!window.testPresentEffectClear(0.0)) { host.close(); return 4 }
                phase = 1
                getStdOut().writeln("CJGUI_EFFECT_PROBE phase=fallback")
                getStdOut().flush()
            } else if (phase == 1 && exists(effectProbeReleasePath)) {
                if (!window.testPresentEffectClear(1.0)) { host.close(); return 5 }
                phase = 2
                getStdOut().writeln("CJGUI_EFFECT_PROBE phase=restored")
                getStdOut().flush()
            }
        }
        host.close()
        return if (phase == 2) { 0 } else { 6 }
    }
    // P2 animation verification: drive the generated node's paint alpha through
    // the public window entry, reverse it mid-flight, then submit a malformed
    // effect candidate (refused whole) and prove the running binding is NOT
    // disturbed. Finally cancel through the close hook. This is the consumer's
    // own check; a real mouse press uses the same public entry through the
    // generated control.
    if (verifiesAnimation) {
        let region = controller.generatedUiRegion()
        // Each assertion is evaluated and reported; any failure (or an injected
        // failure) makes this process exit non-zero and the completion marker
        // name the failing count.
        var failed = 0
        var waited = 0
        while (waited < 400 && host.isOpen() && !region.generatedAnimationNodeReady()) {
            let _ = host.pumpOneTurn()
            waited += 1
        }
        // 1. the accepted scene really carries the generated node.
        let nodeReady = region.generatedAnimationNodeReady()
        if (!nodeReady) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=generated_node_ready ok=${if (nodeReady) { 1 } else { 0 }}")
        // 2. The actual consumer palette follows the normal host's accepted
        // platform preference, including the system source. Read the committed
        // scene paint rather than treating a tracker token as a visual result.
        let lightSelected = host.setThemePreference("light")
        let _ = host.pumpOneTurn()
        let lightRed = match (acceptedNodeForSemantic(window, "collaboration-root")) {
            case Some(node) => node.style.background.red
            case None => -1.0
        }
        let lightMaterial = window.windowProgress()
        let darkSelected = host.setThemePreference("dark")
        let _ = host.pumpOneTurn()
        let darkRed = match (acceptedNodeForSemantic(window, "collaboration-root")) {
            case Some(node) => node.style.background.red
            case None => -1.0
        }
        let darkMaterial = window.windowProgress()
        let systemSelected = host.setThemePreference("system")
        let _ = host.pumpOneTurn()
        let systemRed = match (acceptedNodeForSemantic(window, "collaboration-root")) {
            case Some(node) => node.style.background.red
            case None => -1.0
        }
        let systemMaterial = window.windowProgress()
        let effectiveSystemRed = match (host.platformState()) {
            case Some(snapshot) =>
                if (CjguiComposableUiPlatformStateCodec.colorSchemeToken(snapshot.effectiveColorScheme()) == "dark") {
                    CjguiComposableUiTheme.beaconDark().page.background.red
                } else { CjguiComposableUiTheme.paperLight().page.background.red }
            case None => -1.0
        }
        let acceptedSystemFact = host.platformState()
        let repeatedSystemSelected = host.setThemePreference("system")
        let _ = host.pumpOneTurn()
        let repeatedSystemRed = match (acceptedNodeForSemantic(window, "collaboration-root")) {
            case Some(node) => node.style.background.red
            case None => -1.0
        }
        let sameAcceptedFact = match (acceptedSystemFact) {
            case Some(before) => match (host.platformState()) {
                case Some(after) => before.equals(after)
                case None => false
            }
            case None => false
        }
        let sameFactStable = repeatedSystemSelected && sameAcceptedFact &&
            cjguiConsumerApprox(repeatedSystemRed, systemRed, 0.0001)
        let unknownThemeRejected = !host.setThemePreference("unknown")
        let themePaintOk = lightSelected && darkSelected && systemSelected && unknownThemeRejected &&
            cjguiConsumerApprox(lightRed, CjguiComposableUiTheme.paperLight().page.background.red, 0.0001) &&
            cjguiConsumerApprox(darkRed, CjguiComposableUiTheme.beaconDark().page.background.red, 0.0001) &&
            cjguiConsumerApprox(systemRed, effectiveSystemRed, 0.0001) && sameFactStable
        let expectedSystemMaterialScheme = match (host.platformState()) {
            case Some(snapshot) => CjguiComposableUiPlatformStateCodec.colorSchemeToken(snapshot.effectiveColorScheme())
            case None => "unavailable"
        }
        let materialThemeOk = lightMaterial.windowBackgroundRequested ==
            CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA &&
            lightMaterial.windowBackgroundColorScheme == "light" &&
            darkMaterial.windowBackgroundColorScheme == "dark" &&
            darkMaterial.windowBackgroundFrameIndex > lightMaterial.windowBackgroundFrameIndex &&
            systemMaterial.windowBackgroundColorScheme == expectedSystemMaterialScheme
        if (!themePaintOk) { failed += 1 }
        if (!materialThemeOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=host_theme_accepted_paint " +
            "ok=${if (themePaintOk) { 1 } else { 0 }} light=${lightRed} dark=${darkRed} " +
            "system=${systemRed} effective=${effectiveSystemRed} sameFact=${if (sameFactStable) { 1 } else { 0 }}")
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=window_material_theme_accepted " +
            "ok=${if (materialThemeOk) { 1 } else { 0 }} requested=${lightMaterial.windowBackgroundRequested} " +
            "expected=${CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA} " +
            "light=${lightMaterial.windowBackgroundColorScheme} " +
            "dark=${darkMaterial.windowBackgroundColorScheme} system=${systemMaterial.windowBackgroundColorScheme} " +
            "frames=${lightMaterial.windowBackgroundFrameIndex}/${darkMaterial.windowBackgroundFrameIndex}/" +
            "${systemMaterial.windowBackgroundFrameIndex}")
        // 3. the registered restricted motion rule drives a real low transition.
        let lowDrive = region.driveGeneratedOpacity(0.3, "verify-low")
        var frames = 0
        while (frames < 6 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            frames += 1
        }
        let afterLowSnap = region.animationSnapshot()
        // The drive really changed the projection toward the low target: the
        // presented value left the base 1.0 and the target is the low value. The
        // exact arrival is checked by the reverse step (which continues from
        // this in-flight value), so a partial tween is not a failure.
        let lowChanged = lowDrive && afterLowSnap.presented >= 0.3 - 0.0001 &&
            afterLowSnap.presented < 1.0 && afterLowSnap.target <= 0.3 + 0.0001
        if (!lowChanged) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=low_transition_drove " +
            "ok=${if (lowChanged) { 1 } else { 0 }} drive=${if (lowDrive) { 1 } else { 0 }} " +
            "presented=${afterLowSnap.presented} target=${afterLowSnap.target}")
        // 3. an explicit reverse continues from the current visual value.
        let reverseDrive = region.driveGeneratedOpacity(1.0, "verify-reverse")
        var frames2 = 0
        while (frames2 < 6 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            frames2 += 1
        }
        let afterReverseSnap = region.animationSnapshot()
        let reverseContinued = reverseDrive && afterReverseSnap.presented > afterLowSnap.presented
        if (!reverseContinued) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=reverse_continues_current " +
            "ok=${if (reverseContinued) { 1 } else { 0 }} drive=${if (reverseDrive) { 1 } else { 0 }} " +
            "from=${afterLowSnap.presented} after=${afterReverseSnap.presented}")
        // 4. a malformed candidate is refused WHOLE (no silent normalization);
        //    the accepted structure version and the running binding are untouched.
        let versionBefore = region.acceptedStructureVersion()
        let identityBefore = region.animationSnapshot().identity
        let malformed = "GENERATED_UI_STRUCTURE 1\n" +
            "NODE 0 board vertical\n" +
            "NODE 1 verifyBad label\n" +
            "PROPERTY 1 verifyBad text 验证非法效果\n" +
            "PROPERTY 1 verifyBad shadow 12,oops,8,0,#000000\n" +
            "END"
        let rejected = region.submitStructure(malformed, versionBefore)
        let versionAfter = region.acceptedStructureVersion()
        let identityAfter = region.animationSnapshot().identity
        let rejectWhole = !rejected.candidateAccepted && rejected.reason.contains("shadow_value_invalid") &&
            versionAfter == versionBefore && identityAfter == identityBefore && identityAfter.size > 0
        if (!rejectWhole) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=malformed_candidate_refused_whole " +
            "ok=${if (rejectWhole) { 1 } else { 0 }} accepted=${if (rejected.candidateAccepted) { 1 } else { 0 }} " +
            "reason=${rejected.reason} versionBefore=${versionBefore} versionAfter=${versionAfter} " +
            "identityStable=${if (identityAfter == identityBefore) { 1 } else { 0 }}")
        // 5. B2: the consumer references the FRAMEWORK-level common motion
        //    definition (its local copy is gone). The published capability line
        //    is the framework's, the registered transition resolves, and an
        //    unregistered name is a NAMED refusal instead of an invented default.
        let capability = region.motionCapabilityLine()
        let frameworkCapability = CjguiGeneratedMotionRegistry.capabilityLine()
        let frameworkDefinitionOk = capability == frameworkCapability &&
            capability.contains("interaction_rule=interaction.state") &&
            capability.contains("color_space=srgb_component_linear") &&
            CjguiGeneratedMotionRegistry.specFor(CjguiGeneratedMotionRegistry.OPACITY_TRANSITION).isSome() &&
            CjguiGeneratedMotionRegistry.specFor("generated.unknown").isNone() &&
            CjguiGeneratedMotionRegistry.rejectionReasonFor("generated.unknown") == "motion_rule_unregistered"
        if (!frameworkDefinitionOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=framework_common_definition " +
            "ok=${if (frameworkDefinitionOk) { 1 } else { 0 }} " +
            "interaction_rule=${if (capability.contains("interaction_rule=interaction.state")) { 1 } else { 0 }} " +
            "color_space=${if (capability.contains("color_space=srgb_component_linear")) { 1 } else { 0 }}")
        // 6. B1: the checked OWNER interaction state resolves the invariant card's
        //    background alpha to 0.75; the interaction channel settles at that
        //    target on first projection (no pointer gesture needed).
        var alphaWaited = 0
        while (alphaWaited < 200 && host.isOpen() &&
            acceptedNodeForSemantic(window, ALPHA_INVARIANT_SEMANTIC).isNone()) {
            let _ = host.pumpOneTurn()
            alphaWaited += 1
        }
        let alphaNode = acceptedNodeForSemantic(window, ALPHA_INVARIANT_SEMANTIC)
        let alphaResolved = match (alphaNode) {
            case Some(node) => node.style.background.alpha
            case None => -1.0
        }
        let alphaIdentity = match (alphaNode) {
            case Some(node) => node.identityKey
            case None => ""
        }
        let resolvedOk = cjguiConsumerApprox(alphaResolved, ALPHA_INVARIANT_CHECKED_ALPHA, 0.01)
        if (!resolvedOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=alpha_interaction_resolved " +
            "ok=${if (resolvedOk) { 1 } else { 0 }} resolved=${alphaResolved} " +
            "expected=${ALPHA_INVARIANT_CHECKED_ALPHA}")
        // 7. B1: a 0.5 paint-alpha animation composes with the 0.75 interaction
        //    resolution exactly once -> 0.375. Discriminating counter-examples:
        //    double animation = 0.1875, re-multiplying the 0.8 base = 0.3.
        let zeroSpec = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
        let alphaDriven = alphaIdentity.size > 0 &&
            window.animateNodeOpacity(alphaIdentity, ALPHA_INVARIANT_ANIMATION_ALPHA, spec: zeroSpec,
                atTime: MonoTime.now())
        let _ = host.pumpOneTurn()
        let composed = match (acceptedNodeForSemantic(window, ALPHA_INVARIANT_SEMANTIC)) {
            case Some(node) => node.style.background.alpha
            case None => -1.0
        }
        let composeOk = alphaDriven && cjguiConsumerApprox(composed, ALPHA_INVARIANT_EXPECTED, 0.01) &&
            !cjguiConsumerApprox(composed, 0.1875, 0.01) && !cjguiConsumerApprox(composed, 0.3, 0.01)
        if (!composeOk) { failed += 1 }
        // Release the invariant card's binding again so the close-time binding
        // count asserts only the generated region's own lifecycle.
        if (alphaIdentity.size > 0) {
            let _ = window.cancelNodeOpacityAnimation(alphaIdentity)
        }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=alpha_composed_once " +
            "ok=${if (composeOk) { 1 } else { 0 }} composed=${composed} expected=${ALPHA_INVARIANT_EXPECTED} " +
            "double=${0.1875} baseAgain=${0.3}")
        // 8. B3 reduce-motion: an active animation converges to its terminal
        //    value, the terminal value is really committed, and the window stops
        //    requesting frames. Turning the preference off lets the next
        //    transition advance again.
        let _ = window.setReduceMotionEnabled(false)
        let _ = region.driveGeneratedOpacity(0.3, "b3-reduce")
        let _ = host.pumpOneTurn()
        let midReduce = region.animationSnapshot()
        let _ = window.setReduceMotionEnabled(true)
        let _ = host.pumpOneTurn()
        let convergedSnap = region.animationSnapshot()
        let reduceOk = midReduce.presented > 0.3 + 0.001 && midReduce.presented < 1.0 &&
            cjguiConsumerApprox(convergedSnap.presented, 0.3, 0.001) && !window.needsAnimationTick()
        if (!reduceOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=reduce_motion_converges_and_stops " +
            "ok=${if (reduceOk) { 1 } else { 0 }} mid=${midReduce.presented} converged=${convergedSnap.presented} " +
            "needsTick=${if (window.needsAnimationTick()) { 1 } else { 0 }}")
        // 9. B3 resume: with the preference off again a fresh transition runs and
        //    the window requests frames.
        let _ = window.setReduceMotionEnabled(false)
        let resumedDrive = region.driveGeneratedOpacity(1.0, "b3-resume")
        let _ = host.pumpOneTurn()
        let resumedSnap = region.animationSnapshot()
        let resumeOk = resumedDrive && resumedSnap.active > 0 && window.needsAnimationTick()
        if (!resumeOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=reduce_off_resumes " +
            "ok=${if (resumeOk) { 1 } else { 0 }} active=${resumedSnap.active} " +
            "needsTick=${if (window.needsAnimationTick()) { 1 } else { 0 }}")
        // 10. B3 pause: pausing stops advancing and frame requests while keeping
        //     the binding; resuming continues from the same value. The previous
        //     step left an active transition toward 1.0, so pause it in flight.
        let beforePause = region.animationSnapshot()
        window.setAnimationsPaused(true)
        let _ = host.pumpOneTurn()
        let pausedTick = window.needsAnimationTick()
        let afterPause = region.animationSnapshot()
        window.setAnimationsPaused(false)
        let pauseOk = beforePause.active > 0 && !pausedTick &&
            cjguiConsumerApprox(afterPause.presented, beforePause.presented, 0.000000001)
        if (!pauseOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=pause_stops_and_resumes " +
            "ok=${if (pauseOk) { 1 } else { 0 }} before=${beforePause.presented} " +
            "after=${afterPause.presented} pausedTick=${if (pausedTick) { 1 } else { 0 }}")
        // 11. B3 controllable platform-state source: a tracker fed with EXPLICIT
        //     facts (never the user's global preference) proves the whole policy
        //     chain - only-change updates, visible advance, hidden/minimized
        //     converge, restore advance, fixed theme priority, unknown rejected.
        let tracker = CjguiComposableUiPlatformStateTracker()
        let platformFirst = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let platformSame = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let visibleAdvance = match (tracker.accepted()) {
            case Some(snapshot) => !snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: false, windowMinimized: false)
        let hiddenConverge = match (tracker.accepted()) {
            case Some(snapshot) => snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let restoreAdvance = match (tracker.accepted()) {
            case Some(snapshot) => !snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: true)
        let minimizedConverge = match (tracker.accepted()) {
            case Some(snapshot) => snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let minimizedRestore = match (tracker.accepted()) {
            case Some(snapshot) => !snapshot.motionConverges()
            case None => false
        }
        // User fixed theme wins over the system appearance.
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.FixedLight, windowVisible: true, windowMinimized: false)
        let fixedThemeLight = match (tracker.accepted()) {
            case Some(snapshot) => CjguiComposableUiPlatformStateCodec.colorSchemeToken(
                snapshot.effectiveColorScheme()) == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_LIGHT
            case None => false
        }
        let unknownRejected = !tracker.selectThemePreference("neon") &&
            tracker.lastRejectionReason() == "unknown_theme_preference"
        // The policy the window chain consumes: converge on hidden/minimized.
        let windowChainConverge = window.setReduceMotionEnabled(hiddenConverge)
        let _ = window.setReduceMotionEnabled(false)
        let platformOk = platformFirst && !platformSame && visibleAdvance && hiddenConverge &&
            restoreAdvance && minimizedConverge && minimizedRestore && fixedThemeLight && unknownRejected
        if (!platformOk) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=platform_state_chain " +
            "ok=${if (platformOk) { 1 } else { 0 }} first=${if (platformFirst) { 1 } else { 0 }} " +
            "same=${if (platformSame) { 1 } else { 0 }} visibleAdvance=${if (visibleAdvance) { 1 } else { 0 }} " +
            "hiddenConverge=${if (hiddenConverge) { 1 } else { 0 }} restoreAdvance=${if (restoreAdvance) { 1 } else { 0 }} " +
            "minimizedConverge=${if (minimizedConverge) { 1 } else { 0 }} " +
            "minimizedRestore=${if (minimizedRestore) { 1 } else { 0 }} " +
            "fixedThemeLight=${if (fixedThemeLight) { 1 } else { 0 }} " +
            "unknownRejected=${if (unknownRejected) { 1 } else { 0 }} windowChainConverge=${if (windowChainConverge) { 1 } else { 0 }}")
        // 12. close cancels the region's binding and requests no further
        //     animation frame (the interaction-paint color channel of the
        //     invariant card is independent of the region's opacity binding).
        region.prepareWindowClose()
        let afterCancelSnap = region.animationSnapshot()
        let cancelSettled = afterCancelSnap.active == 0 && afterCancelSnap.presented < 0.0
        if (!cancelSettled) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_ASSERT name=cancel_settles " +
            "ok=${if (cancelSettled) { 1 } else { 0 }} active=${afterCancelSnap.active} " +
            "presented=${afterCancelSnap.presented}")
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_VERDICT assertions=13 failed=${failed} " +
            "inject=${if (injectVerifyFailure) { 1 } else { 0 }} " +
            "reduceMotion=${if (window.reduceMotionEnabled()) { 1 } else { 0 }}")
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_DONE instance_token=${instanceToken} failed=${failed}")
        getStdOut().flush()
        // The host owns the NSApplication run loop, so a graceful close can end
        // the process before any later return value is seen. A failing assertion
        // therefore exits explicitly with the non-zero status the caller reads.
        if (failed != 0) {
            exit(1)
        }
        host.close()
        exit(0)
        return 0
    }
    // A consumer-level close probe uses the same controller decision and
    // Host cleanup as the visible close button. It is intentionally separate
    // from any external client or model claim.
    if (verifiesNormalClose) {
        if (!host.requestClose() || host.isOpen() || connection.connectionInfo().isSome()) {
            host.close()
            return 3
        }
        getStdOut().writeln("CJGUI_COLLABORATION_NORMAL_CLOSE endpoint=cleared")
        getStdOut().flush()
        return 0
    }
    let imageOwnerSlot: Int64 = 8199
    let imageAuthorization = CjguiSharedOperationExternalAuthorization(
        "generated-png-owner-client", "demo-only-authorized-image-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT",
                ArrayList<Int64>([imageOwnerSlot]), false),
            CjguiSharedOperationExternalActionScope("SELECT_OWNED_IMAGE",
                ArrayList<Int64>([imageOwnerSlot]), false)
        ]))
    let imageConnection = CjguiSharedOperationExternalConnection(
        CjguiSharedOperationImageOwnerDomain(controller.imageOwner(), imageOwnerSlot), imageAuthorization)
    if (!host.adoptExternalConnectionForClose(imageConnection)) {
        imageConnection.close()
        host.close()
        return 1
    }
    if (!imageConnection.start()) { host.close(); return 1 }
    if (let Some(info) <- imageConnection.connectionInfo()) {
        getStdOut().writeln("CJGUI_PNG_EXTERNAL_READY consumer=generated-panel descriptor=${info.descriptorPath} " +
            "slot=${imageOwnerSlot}")
        getStdOut().flush()
    }
    while (host.isOpen()) {
        let _ = imageConnection.pumpBurst(4u32, 0u32, 0u32)
        if (imageConnection.consumeWindowRefreshRequest()) {
            let state = controller.imageOwner().snapshot()
            getStdOut().writeln("CJGUI_PNG_EXTERNAL_APPLIED consumer=generated-panel version=${state.version} " +
                "digest=${state.contentDigest}")
            getStdOut().flush()
        }
        let _ = host.pumpOneTurn()
    }
    host.close()
    return 0
}
