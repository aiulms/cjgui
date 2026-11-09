package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*
import std.unicode.*
import std.time.*

/// 宿主的 chrome 是少量手写工具栏/状态区 + 项目声明驱动的浏览面板；**原型主体**来自
/// 生成式区域（模型通过公开能力目录生成/修改）。列表复用公共虚拟列表原语，
/// 卡片复用公共 Wrap/图片节点，宿主不新写第二套滚动、选择或虚拟化状态机。
class PrototypeHostController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private var session: PrototypeSession
    private var bridge: PrototypeHostBridge
    private var projectPath: String
    private var window: ?CjguiComposableUiWindow = None
    private var revisionValue: Int64 = 1
    private var buildEpoch: Int64 = 1
    private var statusMessage: String = "就绪"
    private var filterInput: String = ""
    private var diagnosticsVisible: Bool = false
    private var projectsVisible: Bool = false
    private var narrowListVisible: Bool = false
    private var regionViewport: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()
    private var startupDocumentPending: Bool = true
    private var startupDocumentStatus: String = ""
    private var startupSessionStatus: String = ""
    /// 界面文档的启动载入提交了一张候选票据；必须等它在空闲边界结算后才能
    /// 保存/再次载入（否则文档会话会以 ui_document_submitted 正当地拒绝保存）。
    private var documentSettlePending: Bool = false
    private var workSession: ?CjguiComposableUiWorkSession = None
    private var projectRoot: String
    private var projectPathInput: String = ""
    /// 诊断用：>0 时 buildUi 只构造 N 层嵌套裁剪容器，用于复现裁剪约束数量上限。
    private var clipProbeLevels: Int64 = 0
    /// F 项验证入口：纵向 splitState 的最小公开消费者（上/下两栏 + 可拖分隔条）。
    private var splitDemo: Bool = false
    /// F 项验证入口的轴选择：vertical（默认）或 horizontal，仅切换演示 splitState 的轴，
    /// 走同一公开 scopedSplitView/分割拖动路径，不新增私有拖动入口。
    private var splitDemoHorizontal: Bool = false
    public var demoSplit = CjguiComposableUiSplitState(120, 40, 40)
    private var demoTranslation: Float64 = 0.0
    private var demoBinding: Int64 = 1
    private var demoObservedVersion: Int64 = -1
    private var demoLastPointerTrace: String = ""
    private var measurementEnabled = false
    private let measurementOrigin = MonoTime.now()
    private var measurementLastNs: Int64 = -1000000000
    private var measurementRecorder: ?PrototypeMeasurementRecorder = None

    /// 生命周期 trace 默认关闭；只有诊断入口（裁剪探针/窗口诊断）打开，避免正常 stderr 嘈杂。
    private var traceEnabled: Bool = false
    /// 有未保存状态时，同一次“打开项目”的第二次点击作为明确确认；不是静默丢弃。
    private var pendingSwitchPath: String = ""

    init(projectPath: String, clipProbeLevels!: Int64 = 0, splitDemo!: Bool = false,
        splitDemoAxis!: String = "vertical") {
        this.projectPath = projectPath
        this.clipProbeLevels = clipProbeLevels
        this.splitDemo = splitDemo
        this.splitDemoHorizontal = splitDemoAxis == "horizontal"
        this.traceEnabled = clipProbeLevels > 0
        this.projectRoot = prototypeParentDirectory(projectPath)
        this.session = PrototypeSession(PrototypeProjectLoader.load(projectPath), false)
        this.bridge = PrototypeHostBridge(session)
        this.workSession = prototypeOpenWorkSession(session.project, { payload => prototypeValidateSessionPayload(payload) })
        this.projectPathInput = projectPath
        this.filterInput = session.domain.queryText()
        if (let Some(loaded) <- workSession) {
            let result = loaded.load()
            if (result.ok) {
                if (prototypeRestoreSessionPayload(session.domain, result.payload, session)) {
                    filterInput = session.domain.queryText()
                    startupSessionStatus = "restored"
                    statusMessage = "已恢复原型会话（草稿与已应用值，按字段 ID 匹配）"
                } else {
                    let reason = prototypeSessionRestoreReason(session.domain, result.payload)
                    startupSessionStatus = "refused:${reason}"
                    statusMessage = "原型会话未载入：${reason}；保留项目默认值，未使用文件内容"
                }
            } else if (result.reason == "file_read_failed") {
                startupSessionStatus = "new"
                statusMessage = "新建原型会话；尚无保存文件"
            } else if (result.reason == "work_session_schema") {
                // 旧格式（v1）会话：没有字段身份，按位置映射属于猜测。保留原件后改用新格式，
                // 不静默删除、不部分采用旧值。
                let sessionPath = session.project.sessionPath
                let backupPath = "${sessionPath}.v1.bak"
                let preserved = prototypePreserveLegacySessionFile(sessionPath, backupPath)
                startupSessionStatus = if (preserved) { "legacy_preserved" } else { "legacy_preserve_failed" }
                statusMessage = if (preserved) {
                    "旧格式会话已保留为 ${backupPath}（不按位置猜测字段对应）；当前使用项目默认值"
                } else {
                    "旧格式会话未使用；备份 ${backupPath} 失败或已存在，原文件保留原处"
                }
            } else {
                startupSessionStatus = "refused:${result.reason}"
                statusMessage = "原型会话未载入：${result.reason}；未使用文件内容"
            }
        }
    }

    func projectName(): String {
        return session.project.title
    }

    func sessionProject(): PrototypeProject {
        return session.project
    }

    /// 外部连接的 domain/provider 都取这同一个桥；切换项目后它指向新会话。
    func connectionBridge(): PrototypeHostBridge {
        return bridge
    }

    func regionForConnection(): CjguiGeneratedUiWindowRegion {
        return bridge.currentSession().region
    }

    func projectDomain(): PrototypeProjectDomain {
        return bridge.currentSession().domain
    }

    func sdkIdentityLine(): String {
        return "project=${session.project.id} root=${session.project.root}"
    }

    // ——— 场景刷新参与：生成式区域的候选事务由控制器在正常刷新边界开启/提交，
    // 拒绝或异常时回滚到上一份 accepted 界面（不保留半份候选）。 ———

    public func beginSceneRefresh(): Bool {
        let began = session.region.beginSceneRefresh()
        if (traceEnabled) {
        getStdErr().writeln("PROTOTYPE_TRACE beginSceneRefresh=${began}")
        }
        getStdErr().flush()
        return began
    }

    public func prepareSceneRefresh(): Bool {
        let prepared = session.region.prepareSceneRefresh()
        if (traceEnabled) {
        getStdErr().writeln("PROTOTYPE_TRACE prepareSceneRefresh=${prepared}")
        }
        getStdErr().flush()
        return prepared
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return session.region.generatedSceneCommands()
    }

    public func commitSceneRefresh(): Unit {
        session.region.commitSceneRefresh()
    }

    public func rollbackSceneRefresh(): Unit {
        session.region.rollbackSceneRefresh()
    }

    public func rollbackSceneRefresh(reason: String): Unit {
        if (traceEnabled) {
            getStdErr().writeln("PROTOTYPE_TRACE rollback reason=${reason}")
            // R6: the additive location detail (offending node / depth / limit /
            // clip chain). The reason token itself is unchanged.
            if (let Some(value) <- window) {
                let detail = value.lastCandidateLayoutDiagnostic()
                if (detail.size > 0) {
                    getStdErr().writeln("PROTOTYPE_TRACE layoutDiagnostic=${detail}")
                }
            }
        }
        getStdErr().flush()
        session.region.rollbackSceneRefresh(reason)
    }

    public func disposeSceneRefreshResources(): Unit {
        session.region.disposeSceneRefreshResources()
    }

    public func attachWindow(value: CjguiComposableUiWindow): Unit {
        window = Some(value)
        session.region.attachWindow(value)
    }

    public func uiSceneVersion(): Int64 {
        return revisionValue + session.sceneVersion()
    }

    private func refresh(): Unit {
        revisionValue += 1
        if (let Some(value) <- window) {
            value.requestRefresh()
        }
    }

    // ——— 构建界面 ———

    public func buildUi(): CjguiComposableUiNode {
        buildEpoch += 1
        let built = buildUiInner()
        return built
    }

    /// 裁剪约束容量探针：每层都是 clipsContent 容器（与滚动区同一条约束链），
    /// 用于在不改框架的前提下复现“第几层开始整场候选被拒绝”。
    private func buildClipProbe(levels: Int64): CjguiComposableUiNode {
        var node = cjguiComposableVertical(9000, "clip-probe-leaf",
            CjguiComposableUiStyle(fixedHeight: 20, clipsContent: true))
        node.add(cjguiComposableText(9001, "clip-probe-label", "leaf", CjguiComposableUiStyle(fontSize: 12.0)))
        var level = 0
        while (level < levels) {
            let parent = cjguiComposableVertical(8900 + level, "clip-probe-${level}",
                CjguiComposableUiStyle(growX: 1, fixedHeight: 60, clipsContent: true))
            parent.add(node)
            node = parent
            level += 1
        }
        return node
    }

    private func buildUiInner(): CjguiComposableUiNode {
        if (clipProbeLevels > 0) {
            return buildClipProbe(clipProbeLevels)
        }
        if (splitDemo) {
            return buildSplitDemo()
        }
        let theme = session.theme
        let root = cjguiComposableVertical(1, "prototype-root",
            CjguiComposableUiStyle(background: theme.page.background, padding: 10, gap: 8, growX: 1, growY: 1,
                clipsContent: true))
        root.add(buildHeader(theme))
        let body = cjguiComposableHorizontal(2, "prototype-body",
            CjguiComposableUiStyle(gap: 10, growX: 1, growY: 1))
        let width = currentContentWidth()
        let narrow = width > 0 && width < 900
        if (session.project.hasRecords() && session.project.hasView("list")) {
            if (narrow) {
                // issue 08 修正归因：本列位于 horizontal 父容器中，交叉轴伸展
                // 需要显式 alignY STRETCH（见 LAYOUT_PRIMITIVES.md 横排交叉轴配方）；
                // 仅 growY 不足以让列占满父容器高度，导致生成式区域只拿到
                // 剩余测量高度而被裁剪。保持纵向排列，不改成叠放子项的 Stack。
                let column = cjguiComposableVertical(3, "prototype-narrow-body",
                    CjguiComposableUiStyle(gap: 8, growX: 1, growY: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
                column.add(buildHeaderRow(theme, narrow))
                if (narrowListVisible) {
                    column.add(buildRecordList(theme, 220))
                }
                column.add(buildRegionArea(theme))
                body.add(column)
            } else {
                body.add(buildRecordSidebar(theme))
                body.add(buildRegionArea(theme))
            }
        } else if (session.project.hasRecords() && session.project.hasView("cards")) {
            let column = cjguiComposableVertical(4, "prototype-card-body",
                CjguiComposableUiStyle(gap: 8, growX: 1, growY: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
            column.add(buildCardToolbar(theme))
            column.add(buildCardGrid(theme, width))
            // 卡片视图也挂生成式区域（详情面板）：区域不挂载就没有场景事务，
            // 外部候选会以 candidate_not_prepared 被拒。
            column.add(buildRegionArea(theme, fixedHeight: 420))
            body.add(column)
        } else {
            body.add(buildRegionArea(theme))
        }
        root.add(body)
        if (narrow && session.project.hasRecords() && session.project.hasView("list")) {
            // 窄窗的列表开关在头部行（buildHeaderRow）中已经出现。
        }
        root.add(cjguiComposableText(5, "prototype-status", overallStatus(), CjguiComposableUiStyle(
            fontSize: 11.0, textColor: theme.body.textColor, textMaxLines: 2, textOverflow: "ellipsis")))
        if (diagnosticsVisible) {
            root.add(buildDiagnosticsPanel(theme))
        }
        if (projectsVisible) {
            root.add(buildProjectPicker(theme))
        }
        return root
    }

    /// 纵向 splitState 最小消费者：公开 scopedSplitView(axis=VERTICAL, splitState=…)，
    /// 分隔条拖动走框架共同拖动路径；firstSize 经状态文本对外可读。
    private func buildSplitDemo(): CjguiComposableUiNode {
        let theme = session.theme
        let root = cjguiComposableVertical(1, "prototype-root",
            CjguiComposableUiStyle(background: theme.page.background, padding: 10, gap: 8, growX: 1, growY: 1))
        let horizontal = splitDemoHorizontal
        let top = cjguiComposableText(8801, "split-demo-top",
            if (horizontal) { "左栏内容" } else { "上栏内容" }, CjguiComposableUiStyle())
        let bottom = cjguiComposableText(8802, "split-demo-bottom",
            if (horizontal) { "右栏内容" } else { "下栏内容" }, CjguiComposableUiStyle())
        let axis = if (horizontal) {
            CjguiComposableUiSplitAxis.HORIZONTAL
        } else {
            CjguiComposableUiSplitAxis.VERTICAL
        }
        let actions = cjguiComposableHorizontal(8810, "split-demo-actions", CjguiComposableUiStyle(gap: 8))
        actions.add(chromeButton(8811, "split-demo-translate", "平移祖先", "SPLIT_DEMO_TRANSLATE", theme.actionStyle(), theme))
        actions.add(chromeButton(8812, "split-demo-rebind", "切换绑定", "SPLIT_DEMO_REBIND", theme.actionStyle(), theme))
        root.add(actions)
        let ancestor = cjguiComposableVertical(8813, "split-demo-ancestor",
            CjguiComposableUiStyle(growX: 1, growY: 1,
                translateX: if (horizontal) { demoTranslation } else { 0.0 },
                translateY: if (horizontal) { 0.0 } else { demoTranslation }))
        ancestor.add(cjguiComposableScopedSplitView(CjguiComposableUiIdentityScope("split-demo"),
            "split-demo", top, bottom, axis,
            demoSplit.firstSize(), 40, 40, CjguiComposableUiStyle(growX: 1, growY: 1),
            splitState: demoSplit))
        root.add(ancestor)
        root.add(cjguiComposableText(8803, "split-demo-status",
            "axis=${if (horizontal) { "horizontal" } else { "vertical" }} " +
                "firstSize=${demoSplit.firstSize()} accepted=${demoSplit.acceptedFirstSize()} " +
                "track=${demoSplit.acceptedTrack()} translate=${demoTranslation} binding=${demoBinding}",
            CjguiComposableUiStyle(fontSize: 12.0, textColor: theme.body.textColor)))
        return root
    }

    // Bounded observation of the normal public window path, used only by --split-demo.
    // No capture/test API or synthetic owner state is consulted.
    func observeSplitDemo(): Unit {
        if (!splitDemo) { return }
        if (let Some(value) <- window) {
            for (kind in [CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE,
                CJGUI_COMPOSABLE_UI_EVENT_POINTER_END]) {
                let trace = value.consumedPointerTraceIdentity(kind)
                if (!trace.isEmpty() && trace != demoLastPointerTrace) {
                    demoLastPointerTrace = trace
                    getStdOut().writeln("SPLIT_POINTER kind=${kind} fifo=${trace} first=${demoSplit.firstSize()}")
                }
            }
            let version = value.windowProgress().acceptedSceneVersion
            if (version != demoObservedVersion) {
                demoObservedVersion = version
                let snapshot = value.diagnosticSnapshot(maximumNodes: 32, includeNonVisible: true)
                getStdOut().writeln("SPLIT_ACCEPTED version=${version} first=${demoSplit.firstSize()} " +
                    "acceptedFirst=${demoSplit.acceptedFirstSize()} translate=${demoTranslation} binding=${demoBinding}")
                for (node in snapshot.nodes) {
                    if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE) {
                        getStdOut().writeln("SPLIT_GEOMETRY version=${version} id=${node.nodeId} " +
                            "bounds=${node.bounds.x},${node.bounds.y},${node.bounds.width},${node.bounds.height}")
                    }
                }
                getStdOut().flush()
            }
        }
    }

    func enableMeasurement(): Unit {
        measurementEnabled = true
        let recorder = PrototypeMeasurementRecorder(measurementOrigin,
            { => this.uiSceneVersion() }, { => this.session.domain.revision() })
        measurementRecorder = Some(recorder)
        bridge.setMeasurementRecorder(recorder)
        if (let Some(value) <- window) {
            let workload = value.setWorkloadDiagnostics(true)
            let timing = value.setTimingDiagnostics(true)
            getStdOut().writeln("CANDIDATE_COLLECTION workload=${workload} timing=${timing}")
            getStdOut().flush()
        }
    }

    func flushMeasurement(): Unit {
        if (let Some(recorder) <- measurementRecorder) {
            recorder.flushUnresolved()
        }
    }

    func observeMeasurement(): Unit {
        if (!measurementEnabled) { return }
        let elapsed = (MonoTime.now() - measurementOrigin).toNanoseconds()
        if (let Some(value) <- window) {
            if (let Some(recorder) <- measurementRecorder) {
                recorder.observe(value)
            }
            if (elapsed - measurementLastNs < 1000000000) { return }
            measurementLastNs = elapsed
            let d = value.diagnosticSnapshot(maximumNodes: 1)
            getStdOut().writeln("CANDIDATE_COST elapsed_ns=${elapsed} session=${d.sessionIdentity} " +
                "accepted=${d.acceptedSceneVersion} submitted=${d.submittedSceneVersion} frame=${d.submittedFrameIndex} " +
                "completed=${d.completedFrameIndex} failed=${d.failedFrameIndex} gpu_us=${d.gpuDurationMicros} " +
                "build_ns=${d.buildNanoseconds} layout_ns=${d.layoutNanoseconds} native_ns=${d.nativeStageAndSubmitNanoseconds} " +
                "text_live=${d.textTextureLiveBytes} text_peak=${d.textCandidatePeakBytes} reusable=${d.reusableResourceBytes} " +
                "effect_live=${d.effectLiveBytes} effect_cached=${d.effectCachedBytes} in_flight=${d.effectInFlightBytes} " +
                "raster=${d.textRasterCount} upload=${d.textUploadCount} allocations=${d.nodeAllocationCount}")
            getStdOut().flush()
        }
    }

    private func currentContentWidth(): Int64 {
        if (let Some(value) <- window) {
            if (let Some(bounds) <- value.contentBounds()) {
                return bounds.width
            }
        }
        return session.project.windowWidth
    }

    private func overallStatus(): String {
        let dirty = if (session.domain.activeObject().isDirty()) { "草稿未应用" } else { "草稿已应用" }
        return "${session.project.title} · ${dirty} · ${session.domain.statusLine()} · ${statusMessage}"
    }

    private func buildHeader(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let header = cjguiComposableHorizontal(10, "prototype-header",
            CjguiComposableUiStyle(gap: 8, growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        header.add(cjguiComposableText(11, "prototype-title", session.project.title,
            CjguiComposableUiStyle(fontSize: 17.0, fontWeight: 600, textColor: theme.heading.textColor,
                textMaxLines: 1, textOverflow: "ellipsis")))
        header.add(cjguiComposableSpacer(12, "prototype-header-spacer"))
        header.add(chromeButton(13, "prototype-theme", if (session.dark) { "浅色" } else { "深色" },
            "PROTOTYPE_THEME_TOGGLE", theme.actionStyle(), theme))
        header.add(chromeButton(14, "prototype-apply", "应用草稿", "PROTOTYPE_APPLY", theme.actionStyle(primary: true),
            theme))
        header.add(chromeButton(15, "prototype-cancel", "取消草稿", "PROTOTYPE_CANCEL", theme.actionStyle(), theme))
        header.add(chromeButton(16, "prototype-save-ui", "保存界面", "PROTOTYPE_SAVE_UI", theme.actionStyle(), theme))
        header.add(chromeButton(17, "prototype-save-session", "保存会话", "PROTOTYPE_SAVE_SESSION",
            theme.actionStyle(), theme))
        header.add(chromeButton(18, "prototype-reload", "重载声明", "PROTOTYPE_RELOAD", theme.actionStyle(quiet: true),
            theme))
        header.add(chromeButton(19, "prototype-diagnostics", "诊断", "PROTOTYPE_DIAGNOSTICS",
            theme.actionStyle(quiet: true), theme))
        header.add(chromeButton(20, "prototype-projects", "项目", "PROTOTYPE_PROJECTS", theme.actionStyle(quiet: true),
            theme))
        return header
    }

    private func buildHeaderRow(theme: CjguiComposableUiTheme, narrow: Bool): CjguiComposableUiNode {
        let row = cjguiComposableHorizontal(21, "prototype-narrow-row",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        let _ = narrow
        row.add(cjguiComposableTextInput(22, "prototype-filter-compact", "筛选记录", filterInput, 1,
            theme.fieldStyle().boundStyle(growX: Some(1)), fieldId: "prototype-filter",
            displayValueRole: "filter"))
        row.add(chromeButton(23, "prototype-narrow-list", if (narrowListVisible) { "隐藏列表" } else { "显示列表" },
            "PROTOTYPE_NARROW_LIST", theme.actionStyle(quiet: true), theme))
        return row
    }

    private func buildRecordSidebar(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let sidebar = cjguiComposableVertical(30, "prototype-sidebar",
            theme.surfaceStyle().localStyle(fixedWidth: Some(280), growY: Some(1), padding: Some(12),
                gap: Some(8), alignY: Some(CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
        sidebar.add(cjguiComposableText(31, "prototype-sidebar-title",
            "记录 · ${session.project.recordSet.titleField}", CjguiComposableUiStyle(fontSize: 12.0,
                textColor: theme.body.textColor)))
        sidebar.add(cjguiComposableTextInput(32, "prototype-filter", "筛选记录", filterInput, 1,
            theme.fieldStyle().boundStyle(), fieldId: "prototype-filter", displayValueRole: "filter"))
        sidebar.add(buildRecordList(theme, -1))
        return sidebar
    }

    private func buildRecordList(theme: CjguiComposableUiTheme, fixedHeight: Int64): CjguiComposableUiNode {
        let style = if (fixedHeight > 0) {
            CjguiComposableUiStyle(growX: 1, fixedHeight: fixedHeight, cornerRadius: 6, clipsContent: true)
        } else {
            CjguiComposableUiStyle(growX: 1, growY: 1, cornerRadius: 6, clipsContent: true)
        }
        let source = PrototypeListSource(session.domain, buildEpoch, theme)
        return cjguiComposableVirtualList(40, "prototype-record-list", 41, session.listViewport, source,
            session.listState, PROTOTYPE_RECORD_ROW_HEIGHT, 2, 4, style)
    }

    private func buildRegionArea(theme: CjguiComposableUiTheme, fixedHeight!: Int64 = 0): CjguiComposableUiNode {
        let _ = theme
        // 横排父容器里的交叉轴伸展必须由子项自己的 alignY 声明（只写 growY 不够，
        // 这是公开布局配方的明确要求）；否则滚动区只有自然高度，内容被裁剪。
        let areaStyle = if (fixedHeight > 0) {
            CjguiComposableUiStyle(growX: 1, fixedHeight: fixedHeight, gap: 4,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)
        } else {
            CjguiComposableUiStyle(growX: 1, growY: 1, gap: 4,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)
        }
        let area = cjguiComposableVertical(50, "prototype-region-area", areaStyle)
        let feedback = session.binding.formFeedback()
        let regionNode = session.region.buildNode(feedback: feedback)
        if (regionNode.style.growY > 0) {
            // 显式填充根直接消费有界工作区；内部单一 growY ScrollArea 与操作行分工。
            // 不在外面再套自然高度滚动区，否则内部 growY 得不到窗口剩余高度。
            area.add(session.region.attachTransientLayers(regionNode))
        } else {
            // 旧项目及自然高度表单保留原承载：整个文档滚动，内容不强行拉高。
            let scroll = cjguiComposableScrollArea(51, "prototype-region-scroll", regionViewport,
                CjguiComposableUiStyle(growX: 1, growY: 1, cornerRadius: 8, clipsContent: true))
            scroll.add(session.region.attachTransientLayers(regionNode))
            area.add(scroll)
        }
        return area
    }

    private func buildCardToolbar(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let row = cjguiComposableHorizontal(60, "prototype-card-toolbar",
            CjguiComposableUiStyle(gap: 8, growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        row.add(cjguiComposableTextInput(61, "prototype-card-filter", "筛选素材", filterInput, 1,
            theme.fieldStyle().boundStyle(growX: Some(1)), fieldId: "prototype-filter",
            displayValueRole: "filter"))
        for (columns in [2, 3, 4]) {
            let selected = session.domain.columnCount() == columns
            row.add(cjguiComposableButton(62 + columns, "prototype-columns-${columns}", "${columns} 列",
                "PROTOTYPE_COLUMNS_${columns}", 0, theme.actionStyle(primary: selected).boundStyle(),
                ownerInteractionState: if (selected) {
                    CjguiComposableUiInteractionState.SELECTED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }))
        }
        row.add(chromeButton(67, "prototype-clear-filter", "清除筛选", "PROTOTYPE_CLEAR_FILTER",
            theme.actionStyle(quiet: true), theme))
        return row
    }

    private func buildCardGrid(theme: CjguiComposableUiTheme, contentWidth: Int64): CjguiComposableUiNode {
        let scroll = cjguiComposableScrollArea(70, "prototype-card-scroll", session.cardViewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true))
        let grid = cjguiComposableWrap(71, "prototype-card-grid",
            CjguiComposableUiStyle(gap: 10, growX: 1), rowGap: 10)
        let columns = session.domain.columnCount()
        let available = if (contentWidth > 0) { contentWidth - 40 } else { 900 }
        let cardWidth = max(140, (available - (columns - 1) * 10) / columns)
        let visible = session.domain.visibleIndices()
        if (visible.size == 0) {
            grid.add(cjguiComposableText(72, "prototype-card-empty",
                if (session.domain.queryText().trim().size > 0) { "没有匹配的素材" } else { "还没有素材" },
                CjguiComposableUiStyle(fontSize: 13.0, textColor: theme.body.textColor)))
            scroll.add(grid)
            return scroll
        }
        var position: Int64 = 0
        for (index in visible) {
            let record = session.project.recordSet.records[index]
            grid.add(buildCard(theme, record, index, cardWidth, 80 + position * 10))
            position += 1
        }
        scroll.add(grid)
        return scroll
    }

    private func buildCard(theme: CjguiComposableUiTheme, record: PrototypeRecordDeclaration, recordIndex: Int64,
        cardWidth: Int64, nodeBase: Int64): CjguiComposableUiNode {
        let selected = session.domain.activeIndex() == recordIndex
        // 卡片容器本身不建立裁剪：滚动区 + 图片已经消耗嵌套裁剪深度，
        // 再嵌套会以 clip_constraint_capacity 拒绝整场候选（属框架既有上限）。
        let card = cjguiComposableVertical(nodeBase, "prototype-card-${record.key}",
            CjguiComposableUiStyle(fixedWidth: cardWidth, gap: 4, padding: 6, cornerRadius: 8,
                background: theme.card.background, border: theme.card.border))
        let imagePath = if (record.image.size > 0) {
            "${session.project.root}/${record.image}"
        } else {
            ""
        }
        if (imagePath.size > 0 && exists(Path(imagePath))) {
            card.add(cjguiComposableImage(nodeBase + 1, "prototype-card-image-${record.key}", imagePath,
                CjguiComposableUiStyle(fixedWidth: cardWidth - 12, fixedHeight: 96, cornerRadius: 6,
                    clipsContent: true), imageResourceId: record.key, imageResourceVersion: 1))
        } else {
            card.add(cjguiComposableText(nodeBase + 2, "prototype-card-image-missing-${record.key}",
                "图片缺失", CjguiComposableUiStyle(fixedHeight: 96, textColor: theme.feedbackStyle(
                    CjguiComposableUiFeedbackKind.ERROR).base.textColor, fontSize: 12.0)))
        }
        card.add(cjguiComposableButton(nodeBase + 3, "prototype-card-title-${record.key}", record.title,
            "SELECT_RECORD", recordIndex, CjguiComposableUiStyle(fixedHeight: 24, growX: 1, padding: 4,
                fontSize: 12.0, textColor: theme.heading.textColor, textMaxLines: 1, textOverflow: "ellipsis",
                cornerRadius: 4), ownerInteractionState: if (selected) {
                CjguiComposableUiInteractionState.SELECTED
            } else {
                CjguiComposableUiInteractionState.NONE
            }))
        var meta = ""
        for (tag in record.tags) {
            meta += "#${tag} "
        }
        if (record.status.size > 0) {
            meta += "· ${record.status}"
        }
        card.add(cjguiComposableText(nodeBase + 4, "prototype-card-meta-${record.key}", meta,
            CjguiComposableUiStyle(fontSize: 10.5, textColor: theme.body.textColor, textMaxLines: 1,
                textOverflow: "ellipsis")))
        return card
    }

    private func buildDiagnosticsPanel(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let panel = cjguiComposableVertical(90, "prototype-diagnostics",
            CjguiComposableUiStyle(padding: 8, gap: 2, cornerRadius: 6, background: theme.card.background,
                border: theme.card.border))
        let region = session.region
        panel.add(cjguiComposableText(91, "prototype-diagnostics-title", "只读诊断（不改任何 owner 状态）",
            CjguiComposableUiStyle(fontSize: 11.0, fontWeight: 600, textColor: theme.heading.textColor)))
        panel.add(cjguiComposableText(92, "prototype-diagnostics-lines",
            "scene=${region.sceneState()} acceptedVersion=${region.acceptedStructureVersion()} " +
            "candidateVersion=${region.candidateStructureVersion()} idle=${region.sceneTransactionIdle()} " +
            "structures=${region.acceptedStructurePayload().size}B fields=${region.fieldsPayload().size}B",
            CjguiComposableUiStyle(fontSize: 10.5, textColor: theme.body.textColor, textMaxLines: 4,
                textOverflow: "ellipsis")))
        panel.add(cjguiComposableText(93, "prototype-diagnostics-document",
            "uiDocument=${session.project.uiDocumentPath} status=${session.workspace.statusText()}",
            CjguiComposableUiStyle(fontSize: 10.5, textColor: theme.body.textColor, textMaxLines: 3,
                textOverflow: "ellipsis")))
        coreDiagnostics(panel, theme)
        return panel
    }

    private func coreDiagnostics(panel: CjguiComposableUiNode, theme: CjguiComposableUiTheme): Unit {
        let _ = panel
        let _ = theme
    }

    private func buildProjectPicker(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let panel = cjguiComposableHorizontal(95, "prototype-project-picker",
            CjguiComposableUiStyle(gap: 6, growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER, padding: 6,
                cornerRadius: 6, background: theme.card.background, border: theme.card.border))
        panel.add(cjguiComposableText(96, "prototype-project-picker-label", "项目目录：",
            CjguiComposableUiStyle(fontSize: 11.0, textColor: theme.body.textColor)))
        panel.add(cjguiComposableTextInput(97, "prototype-project-path", "绝对路径", projectPathInput, 1,
            theme.fieldStyle().boundStyle(growX: Some(1)), fieldId: "prototype-project-path",
            displayValueRole: "path"))
        panel.add(chromeButton(98, "prototype-open-project", "打开", "PROTOTYPE_OPEN_PROJECT",
            theme.actionStyle(primary: true), theme))
        return panel
    }

    private func chromeButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        role: CjguiComposableUiNamedStyle, theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let _ = theme
        let bound = role.boundStyle()
        return cjguiComposableButton(nodeId, semanticId, label, actionName, -1, bound.style,
            interactionStyle: bound.interaction, semanticHelp: label)
    }

    // ——— 事件 ———

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        var observation: ?PrototypeMeasurementRecord = None
        if (measurementEnabled) {
            if (let Some(recorder) <- measurementRecorder) {
                observation = recorder.begin("window_input", event.node.fieldId, event.inputSequence)
            }
        }
        if (let Some(generated) <- session.region.handleEventIfClaimed(event)) {
            if (generated.didApply) {
                refresh()
            }
            if (let Some(recorder) <- measurementRecorder) {
                recorder.complete(observation, generated.didApply,
                    if (generated.didApply) { "owner_applied" } else { "region_not_applied" })
            }
            return generated
        }
        if (let Some(recorder) <- measurementRecorder) {
            recorder.complete(observation, false, "not_claimed_by_region")
        }
        if (event.eventKind == 28) {
            if (event.node.semanticId == "prototype-project-path") {
                projectPathInput = event.text
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.semanticId == "prototype-filter" || event.node.semanticId == "prototype-filter-compact" ||
                event.node.semanticId == "prototype-card-filter") {
                filterInput = event.text
                if (session.domain.setQuery(event.text)) {
                    refresh()
                }
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == 27) {
            let action = event.node.actionName
            if (splitDemo && (action == "SPLIT_DEMO_TRANSLATE" || action == "SPLIT_DEMO_REBIND")) {
                getStdOut().writeln("SPLIT_CHANGE_REQUEST action=${action} sequence=${event.inputSequence} " +
                    "before=${demoSplit.firstSize()} binding=${demoBinding}")
                if (action == "SPLIT_DEMO_TRANSLATE") {
                    demoTranslation = if (demoTranslation == 0.0) { 24.0 } else { 0.0 }
                } else {
                    demoSplit = CjguiComposableUiSplitState(demoSplit.firstSize(), 40, 40)
                    demoBinding += 1
                }
                refresh()
                getStdOut().flush()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "SELECT_RECORD") {
                let recordIndex = event.node.resourceId
                if (session.domain.selectRecordIndex(recordIndex)) {
                    session.binding.rebind()
                    statusMessage = "已切换到 ${session.domain.selectedRecordTitle()}"
                    refresh()
                }
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_APPLY") {
                let (ok, reason) = session.domain.activeObject().applyDraft()
                statusMessage = if (ok) { "已应用草稿" } else { "应用被拒绝：${reason}" }
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_CANCEL") {
                let _ = session.domain.activeObject().cancelDraft()
                statusMessage = "已取消草稿"
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_THEME_TOGGLE") {
                session.setDark(!session.dark)
                statusMessage = "外观：${session.theme.higAppearanceName()}"
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_SAVE_UI") {
                statusMessage = saveUiDocument()
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_SAVE_SESSION") {
                statusMessage = saveSession()
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_RELOAD") {
                statusMessage = reloadDeclaration()
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_DIAGNOSTICS") {
                diagnosticsVisible = !diagnosticsVisible
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_PROJECTS") {
                projectsVisible = !projectsVisible
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_NARROW_LIST") {
                narrowListVisible = !narrowListVisible
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_CLEAR_FILTER") {
                filterInput = ""
                let _ = session.domain.setQuery("")
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action.startsWith("PROTOTYPE_COLUMNS_")) {
                let parsed = Int64.parse(action["PROTOTYPE_COLUMNS_".size..])
                let _ = session.domain.setColumnCount(parsed)
                statusMessage = "列数：${session.domain.columnCount()}"
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            if (action == "PROTOTYPE_OPEN_PROJECT") {
                statusMessage = switchProject(projectPathInput.trim())
                refresh()
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        // R2: any record in the project may hold an unsaved draft, not only the
        // active one (edit A, select clean B, then close). The UI-document
        // guard below keeps its own independent meaning.
        if (session.domain.hasAnyDraftChanges()) {
            let allowed = secondCloseIntent()
            statusMessage = if (allowed) {
                "放弃未应用草稿并关闭"
            } else {
                "有未应用草稿（含其他记录）：请应用、取消，或再次关闭窗口以放弃"
            }
            refresh()
            return CjguiComposableUiDispatchResult(true, shouldClose: allowed)
        }
        if (!session.workspace.closeDecision().canClose) {
            let allowed = secondCloseIntent()
            statusMessage = if (allowed) {
                "放弃未保存界面并关闭"
            } else {
                "有未保存界面结构：再次关闭窗口以放弃，或先保存界面"
            }
            refresh()
            return CjguiComposableUiDispatchResult(true, shouldClose: allowed)
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    /// 保存界面：导出当前已接受结构到项目 ui 文档；失败保留旧文件与旧界面。
    func saveUiDocument(): String {
        let settled = settleDocument()
        if (settled == "pending_scene" || settled == "pending_ticket") {
            return "界面文档保存稍后再试：${settled}"
        }
        let result = session.documentSession.save(session.workspace.surface())
        return "界面文档保存：${prototypeDescribeSessionResult(result)} path=${session.project.uiDocumentPath}"
    }

    /// 保存原型会话：只写业务草稿/已应用值与视图选择，不隐式 Apply。
    func saveSession(): String {
        if (let Some(loaded) <- workSession) {
            let saved = loaded.save(prototypeSessionPayload(session))
            return if (saved.ok) {
                "已保存原型会话：${session.project.sessionPath}"
            } else {
                "原型会话保存失败：${saved.reason}"
            }
        }
        return "未启用原型会话"
    }

    /// 重新载入项目声明（不重编译、不重启）：新增字段保留同身份字段的草稿与焦点，
    /// 声明不合法时保留旧项目。
    func reloadDeclaration(): String {
        let loaded: ?PrototypeProject = try {
            Some(PrototypeProjectLoader.load(projectPath))
        } catch (error: Exception) {
            None
        }
        if (let Some(updated) <- loaded) {
            if (updated.id != session.project.id) {
                return "声明的项目 id 与当前会话不同：请用“项目”打开另一个项目"
            }
            let outcome = session.adoptDeclaration(updated)
            if (outcome.startsWith("declaration_updated")) {
                session.binding.rebind()
                return "声明重载：${outcome}（owner/目录/绑定已同步）"
            }
            if (outcome == "declaration_unchanged") {
                return "声明重载：没有新增字段或动作"
            }
            return "声明重载被拒绝：${outcome}；保留当前项目与已有草稿"
        }
        return "声明重载被拒绝：prototype_declaration 不合法或文件缺失；保留当前项目"
    }

    /// 打开另一个项目：先完整准备新会话（声明/owner/目录/工作区），成功后才切换；
    /// 外部连接通过桥与新会话成为同一目标，旧会话随后关闭。失败或未确认时保留旧项目。
    func switchProject(path: String): String {
        if (path.size == 0) {
            return "项目目录不能为空"
        }
        if (!session.region.sceneTransactionIdle()) {
            return "场景刷新进行中：请稍后再切换项目"
        }
        let draftDirty = session.domain.hasAnyDraftChanges()
        let documentDirty = !session.workspace.closeDecision().canClose
        if ((draftDirty || documentDirty) && pendingSwitchPath != path) {
            pendingSwitchPath = path
            let reasons = if (draftDirty && documentDirty) {
                "未应用草稿和未保存界面"
            } else if (draftDirty) {
                "未应用草稿"
            } else {
                "未保存的界面结构"
            }
            return "当前项目有${reasons}：再次打开同一项目将放弃${reasons}并切换；旧项目不会被静默覆盖"
        }
        let loaded: ?PrototypeProject = try {
            Some(PrototypeProjectLoader.load(path))
        } catch (error: Exception) {
            None
        }
        if (let None <- loaded) {
            return "项目打开被拒绝：${path} 不是合法原型项目；保留当前项目"
        }
        let updated = loaded.getOrThrow()
        // 新会话完整准备成功后才动旧会话；构造/构建失败时旧项目保持可用。
        let prepared: ?PrototypeSession = try {
            Some(PrototypeSession(updated, session.dark))
        } catch (error: Exception) {
            None
        }
        if (let None <- prepared) {
            return "项目准备失败：${updated.id} 的会话/能力目录无法建立；保留当前项目"
        }
        let nextSession = prepared.getOrThrow()
        session.close()
        session = nextSession
        // 同一个外部连接改指新会话：窗口可见内容与模型读到的 owner 是同一个。
        bridge.adopt(nextSession)
        projectPath = path
        projectRoot = prototypeParentDirectory(path)
        projectPathInput = path
        workSession = prototypeOpenWorkSession(session.project,
            { payload => prototypeValidateSessionPayload(payload) })
        filterInput = session.domain.queryText()
        startupDocumentPending = true
        startupDocumentStatus = ""
        documentSettlePending = false
        pendingSwitchPath = ""
        narrowListVisible = false
        refresh()
        return "已切换到项目 ${updated.title}（${updated.root}；连接目标第 ${bridge.generation()} 代）"
    }

    /// 启动后按空闲场景边界导入项目界面文档；失败保留默认空界面并给出具名原因。
    func startupDocument(): String {
        if (!startupDocumentPending) {
            return startupDocumentStatus
        }
        if (!session.region.sceneTransactionIdle() || session.workspace.startupPending()) {
            return startupDocumentStatus
        }
        startupDocumentPending = false
        if (!exists(Path(session.project.uiDocumentPath))) {
            startupDocumentStatus = "项目界面文档尚不存在（保存界面后会生成）"
            return startupDocumentStatus
        }
        let result = session.workspace.beginStartup(session.project.uiDocumentPath)
        startupDocumentStatus = prototypeDescribeSessionResult(result)
        if (result.submitted) {
            documentSettlePending = true
            refresh()
        }
        return startupDocumentStatus
    }

    /// 每个正常空闲回合消费既有文档会话结算接口。启动载入票据、公开
    /// undo/redo 票据以及“无在途时仍可观察历史”都由 `workspace.finish()`
    /// 统一处理；这里只做门控和状态投影，不手工清 pending、不改 mode。
    /// 返回 "" 表示本回合无终态变化；否则返回最近一次真实结算状态。
    func settleDocument(): String {
        if (!session.region.sceneTransactionIdle()) {
            return if (documentSettlePending) { "pending_scene" } else { "" }
        }
        let result = session.workspace.finish()
        if (result.reason == "ui_document_pending") {
            // 票据仍在途：保留待结算标记，下个空闲回合继续消费同一接口。
            documentSettlePending = true
            return "pending_ticket"
        }
        let hadPending = documentSettlePending
        documentSettlePending = false
        if (result.reason == "ui_document_no_submission") {
            // 普通空闲回合：finish() 只做了历史观察，没有终态变化，
            // 不刷新、不覆盖状态文案，避免制造忙循环。
            return ""
        }
        startupDocumentStatus = prototypeDescribeSessionResult(result)
        if (result.applied || hadPending || result.reason != "ui_document_no_submission") {
            refresh()
        }
        return startupDocumentStatus
    }

    func startupStatus(): String {
        return startupDocumentStatus
    }

    func sessionStartupStatus(): String {
        return startupSessionStatus
    }

    func enableTrace(): Unit {
        traceEnabled = true
    }

    func projectsPanelVisible(): Bool {
        return projectsVisible
    }

    func diagnosticsPayload(): String {
        return "project=${session.project.root} ui=${session.project.uiDocumentPath} " +
            "session=${session.project.sessionPath} dark=${session.dark}"
    }

    private var firstCloseAttempt: Bool = false

    private func secondCloseIntent(): Bool {
        if (firstCloseAttempt) {
            return true
        }
        firstCloseAttempt = true
        return false
    }
}
