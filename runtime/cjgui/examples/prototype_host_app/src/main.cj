package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*

/// 最小控制器：只验证宿主/原生窗口链本身，不参与原型界面（诊断与回归用）。
class PrototypeMinimalController <: CjguiComposableUiController {
    private var revision: Int64 = 1

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "minimal-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "minimal-title", "minimal", CjguiComposableUiStyle(fontSize: 16.0)))
        root.add(cjguiComposableButton(3, "minimal-button", "计数 +1", "INC", 0,
            CjguiComposableUiStyle(fixedHeight: 28)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "INC") {
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

/// 宿主本地公开连接的最小授权：只开放生成式界面的发现/提交与本项目的业务读回。
/// 这是可重复的本机 demo capability，不是生产凭据；协作 descriptor 关闭即失效。
func prototypeLocalAuthorization(): CjguiSharedOperationExternalAuthorization {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>()
    for (action in ["GET_CONTEXT", "GET_GENERATED_UI", "SUBMIT_GENERATED_UI"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, ArrayList<Int64>(), true))
    }
    let targets = ArrayList<Int64>()
    targets.add(2000)
    var targetIndex: Int64 = 0
    while (targetIndex < 400) {
        targets.add(3000 + targetIndex)
        targetIndex += 1
    }
    // 只授权项目 owner 真正声明过的动作：未声明的动作会让授权安全校验失败，
    // 连接启动被拒（这里不"顺手"放开一个没有声明的能力）。
    for (action in ["SELECT_RECORD", "FILTER_RECORDS", "RESTORE_DEFAULTS"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, targets, false))
    }
    return CjguiSharedOperationExternalAuthorization("prototype-host-local-model",
        "prototype-host-local-model-capability", scopes)
}

func prototypeArgumentValue(args: Array<String>, flag: String): String {
    var index: Int64 = 0
    while (index + 1 < args.size) {
        if (args[index] == flag) {
            return args[index + 1]
        }
        index += 1
    }
    return ""
}

func prototypeHasArgument(args: Array<String>, flag: String): Bool {
    for (argument in args) {
        if (argument == flag) {
            return true
        }
    }
    return false
}

main(args: Array<String>): Int64 {
    if (prototypeHasArgument(args, "--minimal")) {
        let minimalController = PrototypeMinimalController()
        let minimalHost = CjguiMacosApplicationHost(minimalController,
            configuration: CjguiMacosApplicationWindowConfiguration("prototype minimal", 640u32, 420u32))
        let started = minimalHost.start()
        getStdErr().writeln("PROTOTYPE_MINIMAL started=${started} open=${minimalHost.isOpen()}")
        getStdErr().flush()
        if (started) {
            var turns: Int64 = 0
            while (turns < 40 && minimalHost.isOpen()) {
                let _ = minimalHost.pumpOneTurn()
                turns += 1
            }
        }
        minimalHost.close()
        return if (started) { 0 } else { 1 }
    }
    let parsed = prototypeProjectPathFromArguments(args)
    if (parsed[1] == "usage") {
        getStdErr().writeln("usage: CJGUIPrototypeHost --project /absolute/project/dir [--collaboration]" +
            " [--self-check]")
        return 2
    }
    var projectPath = parsed[0]
    if (projectPath.size == 0) {
        getStdErr().writeln("usage: CJGUIPrototypeHost --project /absolute/project/dir [--collaboration]")
        return 2
    }
    let splitDemo = prototypeHasArgument(args, "--split-demo")
    // F 补证入口：同一 --split-demo 可切横向轴，拖动仍走公开 splitState 路径。
    let splitDemoAxis = prototypeArgumentValue(args, "--split-demo-axis")
    let clipProbe = if (prototypeArgumentValue(args, "--clip-probe").size > 0) {
        Int64.parse(prototypeArgumentValue(args, "--clip-probe"))
    } else {
        0
    }
    let controller = try {
        PrototypeHostController(projectPath, clipProbeLevels: clipProbe, splitDemo: splitDemo,
            splitDemoAxis: splitDemoAxis)
    } catch (error: Exception) {
        getStdErr().writeln("CJGUI_PROTOTYPE_HOST_PROJECT_REFUSED reason=${error.message}")
        return 2
    }
    // 无窗口自检：只构建一次手写+生成式场景树，用来区分“场景构建失败”和窗口/运行期问题。
    if (prototypeHasArgument(args, "--self-check")) {
        let tree: ?CjguiComposableUiNode = try {
            Some(controller.buildUi())
        } catch (error: Exception) {
            getStdErr().writeln("PROTOTYPE_SELF_CHECK_FAILED reason=${error.message}")
            None
        }
        if (let Some(root) <- tree) {
            var stack = ArrayList<CjguiComposableUiNode>()
            stack.add(root)
            var count: Int64 = 0
            while (stack.size > 0) {
                let node = stack.remove(at: stack.size - 1)
                count += 1
                for (child in node.children()) {
                    stack.add(child)
                }
            }
            getStdOut().writeln("PROTOTYPE_SELF_CHECK_OK nodes=${count}")
            getStdOut().flush()
            return 0
        }
        return 3
    }
    let project = controller.sessionProject()
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(project.title, UInt32(project.windowWidth),
            UInt32(project.windowHeight)))
    let window = host.window()
    controller.attachWindow(window)
    let withConnection = !prototypeHasArgument(args, "--no-connection")
    var connection: ?CjguiSharedOperationExternalConnection = None
    if (withConnection) {
        // 连接必须在宿主 start() 之前创建并挂载（宿主在 start 内启动它）；
        // descriptor 只有真正启动成功后才对外发布。
        // 一个稳定连接目标是桥：切换项目后它指向新会话（domain + 生成式区域一起换）。
        let candidate = CjguiSharedOperationExternalConnection(controller.connectionBridge(),
            prototypeLocalAuthorization(), window)
        let providerEnabled = candidate.enableGeneratedUiProvider(controller.connectionBridge())
        let connectionStarted = candidate.start()
        let attached = providerEnabled && connectionStarted && host.attachExternalConnection(candidate)
        getStdErr().writeln("PROTOTYPE_TRACE provider=${providerEnabled} conn_start=${connectionStarted} " +
            "attached=${attached}")
        getStdErr().flush()
        if (!attached) {
            candidate.close()
            host.close()
            getStdErr().writeln("CJGUI_PROTOTYPE_HOST_CONNECTION_REFUSED provider=${providerEnabled} " +
                "start=${connectionStarted}")
            return 1
        }
        connection = Some(candidate)
    }
    let started = host.start()
    if (!started) {
        getStdErr().writeln("CJGUI_PROTOTYPE_HOST_START_FAILED open=${host.isOpen()}")
        if (let Some(value) <- connection) {
            value.close()
        }
        host.close()
        return 1
    }
    if (prototypeHasArgument(args, "--diagnose-window")) {
        // 只读布局诊断：读取 accepted scene 的有界快照（不重放事件、不写 owner）。
        var stableVersion: Int64 = -1
        var turns: Int64 = 0
        while (turns < 240) {
            let _ = host.pumpOneTurn()
            let _ = controller.startupDocument()
            let version = window.diagnosticSnapshot(maximumNodes: 1).acceptedSceneVersion
            // 等“导入后的场景”真正被接受并稳定：只在初始场景停在 1 会读到空生成区。
            if (version >= 2 && version == stableVersion &&
                controller.regionForConnection().acceptedStructureVersion() >= 1) {
                break
            }
            stableVersion = version
            turns += 1
        }
        let snapshot = window.diagnosticSnapshot(maximumNodes: 512, includeNonVisible: true)
        getStdOut().writeln("CJGUI_PROTOTYPE_DIAGNOSE status=${snapshot.status} " +
            "session=${snapshot.sessionIdentity} accepted=${snapshot.acceptedSceneVersion} " +
            "startup=${controller.startupStatus()} " +
            "regionVersion=${controller.regionForConnection().acceptedStructureVersion()} " +
            "total=${snapshot.totalNodes} truncated=${snapshot.truncated} " +
            "layoutDiagnostic=${window.lastCandidateLayoutDiagnostic()}")
        for (node in snapshot.nodes) {
            getStdOut().writeln("DIAG depth=${node.depth} kind=${node.nodeKind} id=${node.nodeId} " +
                "semantic=${node.semanticId} bounds=${node.bounds.x},${node.bounds.y}," +
                "${node.bounds.width}x${node.bounds.height} clip=${node.clipBounds.x},${node.clipBounds.y}," +
                "${node.clipBounds.width}x${node.clipBounds.height} style=${node.styleSummary}")
        }
        getStdOut().flush()
        if (let Some(value) <- connection) {
            value.close()
        }
        host.close()
        return 0
    }
    if (prototypeHasArgument(args, "--measure")) { controller.enableMeasurement() }
    getStdOut().writeln("CJGUI_PROTOTYPE_HOST_READY project=${project.id} root=${project.root} " +
        "fields=${project.fields.size} records=${project.recordSet.records.size} view=${project.viewKind} " +
        "session=${controller.sessionStartupStatus()}")
    if (let Some(value) <- connection) {
        if (let Some(info) <- value.connectionInfo()) {
            getStdOut().writeln("CJGUI_PROTOTYPE_HOST_DESCRIPTOR ${info.descriptorPath}")
        }
    }
    getStdOut().flush()
    var startupReported = false
    let observeLayout = prototypeHasArgument(args, "--observe-layout")
    var observedLayoutVersion: Int64 = -1
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
        controller.observeSplitDemo()
        controller.observeMeasurement()
        let _ = controller.settleDocument()
        let startupStatus = controller.startupDocument()
        if (!startupReported && controller.regionForConnection().acceptedStructureVersion() > 0) {
            startupReported = true
            getStdOut().writeln("CJGUI_PROTOTYPE_HOST_STRUCTURE_ACCEPTED version=" +
                "${controller.regionForConnection().acceptedStructureVersion()} document=${startupStatus}")
            getStdOut().flush()
        }
        // 可选的只读布局原件：按 accepted 变化输出，既不刷新也不写 owner。
        if (observeLayout) {
            let progress = window.diagnosticSnapshot(maximumNodes: 1)
            if (progress.acceptedSceneVersion != observedLayoutVersion) {
                observedLayoutVersion = progress.acceptedSceneVersion
                if (let Some(bounds) <- window.contentBounds()) {
                    let snapshot = window.diagnosticSnapshot(maximumNodes: 256, includeNonVisible: true)
                    getStdOut().writeln("PROTOTYPE_LAYOUT accepted=${snapshot.acceptedSceneVersion} " +
                        "content=${bounds.x},${bounds.y},${bounds.width}x${bounds.height} " +
                        "total=${snapshot.totalNodes} truncated=${snapshot.truncated} " +
                        "diagnostic=${window.lastCandidateLayoutDiagnostic()}")
                    for (node in snapshot.nodes) {
                        getStdOut().writeln("LAYOUT semantic=${node.semanticId} kind=${node.nodeKind} " +
                            "bounds=${node.bounds.x},${node.bounds.y},${node.bounds.width}x${node.bounds.height} " +
                            "clip=${node.clipBounds.x},${node.clipBounds.y},${node.clipBounds.width}x${node.clipBounds.height} " +
                            "style=${node.styleSummary}")
                    }
                    getStdOut().flush()
                }
            }
        }
    }
    if (let Some(value) <- connection) {
        value.close()
    }
    controller.flushMeasurement()
    host.close()
    getStdOut().writeln("CJGUI_PROTOTYPE_HOST_CLOSED endpoint=cleared")
    getStdOut().flush()
    return 0
}
