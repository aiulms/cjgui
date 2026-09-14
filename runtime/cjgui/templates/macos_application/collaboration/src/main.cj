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
    private var status: String = "直接编辑当前任务；提交时才检查必填。授权协作者可修改同一内容和状态。"
    private var taskTitleNodeId: Int64 = -1

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.components = CjguiComposableUiComponentRegistry()
    }

    public func uiSceneVersion(): Int64 { return revision + domain.snapshot().version }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let snapshot = domain.snapshot()
        let task = taskFromSnapshot(snapshot)
        let root = cjguiComposableHorizontal(1, "collaboration-root", theme.page)
        let editorPane = cjguiComposableVertical(2, "collaboration-editor", CjguiComposableUiStyle(
            growX: 1, padding: 14, gap: 8, cornerRadius: 16, clipsContent: true,
            background: CjguiComposableUiColor(0.12, 0.18, 0.30, 0.88),
            border: CjguiComposableUiColor(0.25, 0.38, 0.60, 0.82)
        ))
        editorPane.add(cjguiComposableText(3, "collaboration-title", "协作任务板", theme.heading))
        editorPane.add(cjguiComposableImage(4, "collaboration-beacon", "composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, cornerRadius: 12, clipsContent: true),
            imageResourceId: "collaboration-beacon", imageResourceVersion: 1))
        let editor = components.use("collaboration-task-title")
        if (editor.isLive()) {
            taskTitleNodeId = editor.nodeId("input")
            editorPane.add(cjguiComposableTextInput(taskTitleNodeId, editor.semanticId("input"), "当前任务", task.title, TASK_RESOURCE_ID,
                theme.input, fieldId: "title", operationActionName: "SET_TITLE", displayValueRole: "applied"))
        }
        editorPane.add(cjguiComposableButton(7, "collaboration-submit", "提交当前任务", "HUMAN_SUBMIT", TASK_RESOURCE_ID,
            theme.primaryAction, operationActionName: "SET_MARKED"))
        editorPane.add(cjguiComposableText(8, "collaboration-status", status, theme.body))
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
        root.add(editorPane)
        root.add(activityPane)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == taskTitleNodeId) {
            let result = domain.setTitleFromHuman(TASK_RESOURCE_ID, event.text)
            status = if (result.applied) {
                "当前任务内容已由本地更新；共享版本 ${result.versionAfter}"
            } else {
                "任务内容未更新：${result.reason}"
            }
            revision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 27 && event.node.actionName == "HUMAN_SUBMIT") {
            let task = taskFromSnapshot(domain.snapshot())
            if (task.title.trim().size == 0) {
                status = "未提交：请先填写当前任务"
                revision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            let result = domain.setMarkedFromHuman(TASK_RESOURCE_ID, true)
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
    public func beginSceneRefresh(): Bool { return components.beginTransaction() }
    public func prepareSceneRefresh(): Bool { return components.prepareTransaction() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("collaboration.add", 7, CjguiComposableUiShortcut("a"))
        ])
    }
    public func commitSceneRefresh(): Unit { components.commitTransaction() }
    public func rollbackSceneRefresh(): Unit { components.rollbackTransaction() }

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
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "collaboration-starter-authorized-client", "demo-only-authorized-local-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("SET_TITLE", ArrayList<Int64>([TASK_RESOURCE_ID]), false),
            CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([TASK_RESOURCE_ID]), false)
        ])
    )
}

main(args: Array<String>): Int64 {
    let verifiesNormalClose = args.size == 1 && args[0] == "--verify-normal-close"
    if (args.size != 0 && !verifiesNormalClose) { return 2 }
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(TASK_RESOURCE_ID, "", false)
    ]))
    let host = CjguiMacosApplicationHost(
        CollaborationStarterController(domain),
        configuration: CjguiMacosApplicationWindowConfiguration("协作任务板", 840u32, 520u32)
    )
    let window = host.window()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), window)
    if (!connection.enableWindowProgressReads(window) || !host.attachExternalConnection(connection) || !host.start()) {
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
