package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.unicode.*

private let TASK_RESOURCE_ID: Int64 = 8101

/// A small normal-window consumer.  Its task content and submitted state are
/// fields on one CjguiSharedOperationList resource: controller state holds
/// only presentation revision/status and never a second writable task copy.
class CollaborationStarterController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
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

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.components = CjguiComposableUiComponentRegistry()
        this.textInputFields = HashMap<Int64, String>()
        this.generatedRegion = CjguiTaskGeneratedRegion(domain, TASK_RESOURCE_ID)
        this.editorViewport = CjguiComposableUiScrollViewport()
    }

    public func generatedUiRegion(): CjguiTaskGeneratedRegion { return generatedRegion }

    public func uiSceneVersion(): Int64 {
        return revision + domain.snapshot().version + generatedRegion.revision()
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let snapshot = domain.snapshot()
        let task = taskFromSnapshot(snapshot)
        let root = cjguiComposableHorizontal(1, "collaboration-root", theme.page)
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
                background: CjguiComposableUiColor(0.12, 0.18, 0.30, 0.88),
                border: CjguiComposableUiColor(0.25, 0.38, 0.60, 0.82)))
        let editorContent = cjguiComposableVertical(2002, "collaboration-editor-content",
            CjguiComposableUiStyle(padding: 14, gap: 8))
        editorContent.add(cjguiComposableText(3, "collaboration-title", "协作任务板", theme.heading))
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
                    operationActionName: field.writer, displayValueRole: "applied"))
            }
            textIndex += 1
        }
        editorContent.add(cjguiComposableButton(7, "collaboration-submit", "提交当前任务", "HUMAN_SUBMIT", TASK_RESOURCE_ID,
            theme.primaryAction, operationActionName: markedField.writer))
        editorContent.add(cjguiComposableText(8, "collaboration-status", status, theme.body))
        editorContent.add(generatedRegion.buildSection(theme))
        let activityPane = cjguiComposableVertical(20, "collaboration-activity", CjguiComposableUiStyle(
            growX: 1, padding: 14, gap: 8, cornerRadius: 16, clipsContent: true,
            background: CjguiComposableUiColor(0.07, 0.12, 0.22, 0.82),
            border: CjguiComposableUiColor(0.22, 0.34, 0.56, 0.78)
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
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
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

main(args: Array<String>): Int64 {
    let verifiesNormalClose = args.size == 1 && args[0] == "--verify-normal-close"
    if (args.size != 0 && !verifiesNormalClose) { return 2 }
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
        configuration: CjguiMacosApplicationWindowConfiguration("协作任务板", 840u32, 520u32)
    )
    let window = host.window()
    // Address generated instances by declared key: the projection needs the
    // window whose accepted scene carries them.
    controller.generatedUiRegion().attachWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), window)
    if (!connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        getStdOut().writeln("CJGUI_COLLABORATION_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        getStdOut().flush()
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
    while (host.isOpen()) { let _ = host.pumpOneTurn() }
    host.close()
    return 0
}
