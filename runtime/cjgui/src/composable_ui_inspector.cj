package cjgui

import std.collection.*

/// Experimental read-only inspector of ONE business window. Sampling is explicit;
/// uiSceneVersion only reads the accepted version scalar to mark frozen data old.
/// Inspector redraws never sample themselves or rebuild the inspected window.
public class CjguiComposableUiInspectorPanel <: CjguiComposableUiController {
    private var source: ?CjguiComposableUiWindow
    private var snapshotValue: ?CjguiComposableUiDiagnosticSnapshot = None
    private var selected: ?CjguiComposableUiDiagnosticNode = None
    private var filtered: ?CjguiComposableUiFilteredListSource = None
    private var listState = CjguiComposableUiVirtualListState()
    private var revision: Int64 = 1
    private var query: String = ""
    private var frozen: Bool = false
    private var showBox: Bool = true
    private var notice: String = ""
    // The command view is a second, on-demand projection over the accepted
    // declarations. It shares the freeze switch but owns no command authority:
    // every refresh reads the window's accepted bindings once.
    private var commandMode: Bool = false
    private var commandSnapshotValue: ?CjguiComposableUiCommandDiagnosticSnapshot = None
    private var selectedCommand: ?CjguiComposableUiDiagnosticCommand = None
    private var commandFiltered: ?CjguiComposableUiFilteredListSource = None
    private var commandListState = CjguiComposableUiVirtualListState()
    private var commandQuery: String = ""
    private var originalCollectionSettings: ?(Bool, Bool) = None
    private var collectionSettingsSession: String = ""
    var overlayOwnerKey: String = ""

    public init(source: CjguiComposableUiWindow, collectCosts!: Bool = false) {
        this.source = Some(source)
        if (collectCosts) {
            originalCollectionSettings = Some(source.diagnosticCollectionSettings())
            collectionSettingsSession = source.liveWindowSessionIdentity().getOrDefault({=> ""})
            let _ = source.setWorkloadDiagnostics(true)
            let _ = source.setTimingDiagnostics(true)
        }
        let _ = refresh()
    }

    public static func metric(value: Int64, unit!: String = ""): String {
        return if (value < 0) {
            "unavailable"
        } else {
            "${value}${unit}"
        }
    }
    private static func rect(value: CjguiComposableUiRect): String {
        return "${value.x},${value.y}  ${value.width}×${value.height}"
    }
    private func isCurrent(value: CjguiComposableUiDiagnosticSnapshot): Bool {
        if (let Some(window) <- source) {
            return window.isOpen() && window.liveWindowSessionIdentity().getOrDefault({=> ""}) == value.sessionIdentity &&
                window.displayedSceneVersion() == value.acceptedSceneVersion
        }
        return false
    }
    public func uiSceneVersion(): Int64 {
        return revision + if (let Some(window) <- source) {
            window.displayedSceneVersion()
        } else {
            0
        }
    }
    private func load(start: Int64, pinned: Bool): Bool {
        if (frozen) {
            notice = "读数已冻结；取消冻结后刷新"
            revision += 1
            return false
        }
        let window = match (source) {
            case Some(value) => value;
            case None => return false
        }
        let previous = snapshotValue
        let page = if (pinned && previous.isSome()) {
            let old = previous.getOrThrow()
            window.diagnosticSnapshot(startIndex: start, maximumNodes: 128, expectedSessionIdentity: old.sessionIdentity,
                expectedAcceptedSceneVersion: old.acceptedSceneVersion)
        } else {
            window.diagnosticSnapshot(startIndex: start, maximumNodes: 128)
        }
        if (page.status != "ok") {
            notice = "快照 ${page.status}；保留旧读数，点击刷新读取当前第一页"
            revision += 1
            return false
        }
        let _ = window.clearDiagnosticOverlay(overlayOwnerKey)
        snapshotValue = Some(page)
        selected = None
        listState = CjguiComposableUiVirtualListState()
        let projection = CjguiComposableUiFilteredListSource(CjguiInspectorRows(page), {item => item.title})
        let _ = projection.setQuery(query)
        filtered = Some(projection)
        notice = "仅已物化且与视口相交的 accepted 节点；不读取业务正文／草稿"
        revision += 1
        return true
    }
    public func refresh(): Bool {
        if (commandMode) {
            return loadCommands()
        }
        return load(0, false)
    }

    private func isCommandCurrent(value: CjguiComposableUiCommandDiagnosticSnapshot): Bool {
        if (let Some(window) <- source) {
            // The accepted publication revision, not only the scene version:
            // replace/revoke can land inside one unchanged scene.
            return window.isOpen() && window.liveWindowSessionIdentity().getOrDefault({=> "" }) == value.sessionIdentity &&
                window.displayedSceneVersion() == value.acceptedSceneVersion &&
                window.commandPublicationRevision() == value.publicationRevision
        }
        return false
    }

    private func loadCommands(startIndex!: Int64 = 0): Bool {
        if (frozen) {
            notice = "读数已冻结；取消冻结后刷新"
            revision += 1
            return false
        }
        let window = match (source) {
            case Some(value) => value
            case None => return false
        }
        // Page and expectation come from the frozen read: a page taken against
        // a replaced publication answers stale_publication and the previous
        // read is kept, so a walk never mixes two publications.
        let expected = if (let Some(previous) <- commandSnapshotValue) {
            previous.publicationRevision
        } else {
            -1
        }
        let page = window.diagnosticCommandSnapshot(maximumCommands: 64, startIndex: startIndex,
            expectedPublicationRevision: if (startIndex > 0) { expected } else { -1 })
        if (page.status != "ok") {
            notice = "命令快照 ${page.status}；保留旧读数，点击刷新读取当前发布"
            revision += 1
            return false
        }
        commandSnapshotValue = Some(page)
        selectedCommand = None
        commandListState = CjguiComposableUiVirtualListState()
        let projection = CjguiComposableUiFilteredListSource(CjguiInspectorCommandRows(page),
            {item => item.title})
        let _ = projection.setQuery(commandQuery)
        commandFiltered = Some(projection)
        notice = "命令视图按需读取声明与 accepted 目标；不执行命令，不读取业务正文"
        revision += 1
        return true
    }

    private func highlight(): Bool {
        let window = match (source) {
            case Some(value) => value;
            case None => return false
        }
        let _ = window.clearDiagnosticOverlay(overlayOwnerKey)
        if (!showBox) {
            notice = "所选节点框已关闭"
            return true
        }
        let node = match (selected) {
            case Some(value) => value;
            case None => return false
        }
        let page = match (snapshotValue) {
            case Some(value) => value;
            case None => return false
        }
        if (!isCurrent(page) || !node.identityAvailable || overlayOwnerKey.isEmpty()) {
            notice = "stale_snapshot / identity unavailable：刷新后重新选取"
            return false
        }
        let shown = window.setDiagnosticOverlay(
            CjguiComposableUiDiagnosticOverlayOptions(true, layout: true, clip: true, effectOutput: false,
                backdropSample: false, selectedIdentityKey: node.identityKey,
                expectedSessionIdentity: page.sessionIdentity, expectedAcceptedSceneVersion: page.acceptedSceneVersion,
                ownerKey: overlayOwnerKey))
        notice = if (shown) {
            "业务窗口已高亮当前身份；源场景变化后自动撤销框"
        } else {
            "高亮 unavailable；保留只读信息"
        }
        return shown
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let body = CjguiComposableUiStyle(fontSize: 12.0, textColor: theme.body.textColor, growX: 1, textMaxLines: 3,
            textOverflow: "ellipsis")
        let root = cjguiComposableVertical(1, "inspector-root", theme.page)
        root.add(cjguiComposableText(2, "inspector-title", "CJGUI Inspector · accepted snapshot", theme.heading))
        let bar = cjguiComposableHorizontal(3, "inspector-toolbar", CjguiComposableUiStyle(gap: 6))
        bar.add(
            cjguiComposableButton(4, "inspector-refresh", "刷新", "INSPECT_REFRESH", -1, theme.primaryAction,
                enabled: !frozen))
        bar.add(
            cjguiComposableButton(5, "inspector-freeze", if (frozen) {
                "取消冻结"
            } else {
                "冻结读数"
            }, "INSPECT_FREEZE", -1, theme.primaryAction))
        bar.add(cjguiComposableButton(6, "inspector-box", if (showBox) {
            "节点框：开"
        } else {
            "节点框：关"
        }, "INSPECT_BOX", -1, theme.primaryAction))
        bar.add(
            cjguiComposableButton(7, "inspector-previous", "首页", "INSPECT_FIRST", -1, theme.primaryAction,
                enabled: !frozen && if (commandMode) {
                    if (let Some(page) <- commandSnapshotValue) { page.startIndex > 0 } else { false }
                } else {
                    true
                }))
        bar.add(
            cjguiComposableButton(8, "inspector-next", "下一页", "INSPECT_NEXT", -1, theme.primaryAction,
                enabled: !frozen && if (commandMode) {
                    if (let Some(page) <- commandSnapshotValue) { page.truncated } else { false }
                } else {
                    if (let Some(page) <- snapshotValue) {
                        page.truncated
                    } else {
                        false
                    }
                }))
        bar.add(
            cjguiComposableButton(24, "inspector-mode", if (commandMode) {
                "节点视图"
            } else {
                "命令视图"
            }, "INSPECT_MODE", -1, theme.primaryAction))
        bar.add(
            cjguiComposableTextInput(9, "inspector-query", if (commandMode) {
                "命令 id／作用域／目标搜索"
            } else {
                "身份搜索"
            }, if (commandMode) { commandQuery } else { query }, -1,
                CjguiComposableUiStyle(fixedHeight: 32, growX: 1, background: theme.input.background,
                    textColor: theme.input.textColor), displayValueRole: "filter",
                interactionStyle: theme.inputInteraction))
        root.add(bar)
        if (commandMode) {
            root.add(
                cjguiComposableText(10, "inspector-mode-note",
                    "只读命令诊断：每条来自 accepted 声明；目标只在 accepted 场景解析，不执行、不改绑、不读取业务正文。",
                    body))
            let snapshot = match (commandSnapshotValue) {
                case Some(value) => value
                case None =>
                    root.add(cjguiComposableText(27, "inspector-commands-unavailable",
                        "command snapshot unavailable · ${notice}", body))
                    return root
            }
            let current = isCommandCurrent(snapshot)
            root.add(
                cjguiComposableText(25, "inspector-command-version",
                    "${if (current) { "CURRENT" } else { "STALE：旧命令快照，刷新后再选取" }} ${if (frozen) { "· FROZEN" } else { "· 手动刷新" }}\naccepted=${snapshot.acceptedSceneVersion} · publication=${snapshot.publicationRevision} · session=${snapshot.sessionIdentity}\n声明 ${snapshot.totalCommands} 条 · 本页第 ${snapshot.startIndex + 1}–${snapshot.nextIndex} 条${if (snapshot.truncated) { " · 已截断，可翻页" } else { "" }}",
                    body))
            let columns = cjguiComposableHorizontal(11, "inspector-command-columns",
                CjguiComposableUiStyle(gap: 14, growX: 1))
            if (let Some(rows) <- commandFiltered) {
                columns.add(
                    cjguiComposableVariableHeightList(12, "inspector-commands", 13, rows, commandListState, 30, 0, 1,
                        CjguiComposableUiStyle(fixedWidth: 520, fixedHeight: 320)))
            }
            let detail = cjguiComposableVertical(14, "inspector-command-detail",
                CjguiComposableUiStyle(gap: 8, growX: 1))
            if (let Some(command) <- selectedCommand) {
                detail.add(
                    cjguiComposableText(15, "inspector-command-id",
                        "id=${command.id}\nname=${command.displayName}\nscope=${if (command.scopeId.size > 0) { command.scopeId } else { "global" }}",
                        body))
                detail.add(
                    cjguiComposableText(16, "inspector-command-target",
                        "ref=${command.targetReference}\nresolved=${if (command.resolvedNodeId >= 0) { "node ${command.resolvedNodeId} kind ${command.resolvedNodeKind}" } else { "unavailable" }} · ${command.resolution}",
                        body))
                detail.add(
                    cjguiComposableText(17, "inspector-command-state",
                        "kind=${if (command.checkable) { "checkable" } else { "action" }} · enabled=${command.enabled} · checked=${command.checked}\nshortcut=${if (command.shortcut.size > 0) { command.shortcut } else { "unavailable" }}\naccepted=${command.acceptedSceneVersion} · publication=${command.publicationRevision} · menu=${if (command.menuGroup.size > 0) { "${command.menuGroup}/${command.menuSection}" } else { "unavailable" }}",
                        body))
                detail.add(
                    cjguiComposableText(18, "inspector-command-reason",
                        if (command.unavailableReason.size > 0) {
                            "reason=${command.unavailableReason}\n展示元数据中的业务禁用原因：unavailable（诊断不持有第二份命令权威）"
                        } else {
                            "reason=unavailable"
                        }, body))
            } else {
                detail.add(
                    cjguiComposableText(15, "inspector-command-help",
                        "选择左侧命令查看作用域、目标解析、enabled/checked、快捷键与 accepted 版本。\n解析只读 accepted 场景；缺失目标与禁用事实分别标注，不通过试执行探测。\n旧快照只能查看，不能把命令指向新场景的其他节点。",
                        body))
            }
            columns.add(detail)
            root.add(columns)
            root.add(
                cjguiComposableText(26, "inspector-command-scope",
                    "只读上限 64 条／页，声明序翻页；未读取部分以总数与截断标记呈现，不视为不存在。${notice}",
                    body))
            return root
        }
        let page = match (snapshotValue) {
            case Some(value) => value
            case None =>
                root.add(cjguiComposableText(10, "inspector-unavailable", "snapshot unavailable · ${notice}", body))
                return root
        }
        root.add(
            cjguiComposableText(10, "inspector-version",
                "${if (isCurrent(page)) { "CURRENT" } else { "STALE：旧快照，刷新后再选取" }} ${if (frozen) { "· FROZEN" } else { "· 手动刷新" }}\naccepted=${page.acceptedSceneVersion}  submitted=${page.submittedSceneVersion}/frame ${page.submittedFrameIndex}  completed frame=${CjguiComposableUiInspectorPanel.metric(page.completedFrameIndex)}\nsession=${page.sessionIdentity}",
                body))
        let columns = cjguiComposableHorizontal(11, "inspector-columns", CjguiComposableUiStyle(gap: 14, growX: 1))
        if (let Some(rows) <- filtered) {
            columns.add(
                cjguiComposableVariableHeightList(12, "inspector-nodes", 13, rows, listState, 30, 0, 1,
                    CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 320)))
        }
        let detail = cjguiComposableVertical(14, "inspector-detail", CjguiComposableUiStyle(gap: 8, growX: 1))
        if (let Some(node) <- selected) {
            var parentInPage = node.parentSceneIndex < 0
            for (ancestor in page.nodes) {
                if (ancestor.sceneIndex == node.parentSceneIndex) {
                    parentInPage = true
                }
            }
            detail.add(
                cjguiComposableText(15, "inspector-identity",
                    "#${node.sceneIndex} node=${node.nodeId} kind=${node.nodeKind}\nsemantic=${node.semanticId}\nidentity=${node.identityKey}",
                    body))
            detail.add(
                cjguiComposableText(16, "inspector-parent",
                    "depth=${node.depth} parent=#${node.parentSceneIndex} ${if (parentInPage) { "本页／根" } else { "不在本页；不是完整树" }}\n${node.parentIdentityKey}",
                    body))
            detail.add(
                cjguiComposableText(17, "inspector-bounds",
                    "bounds ${CjguiComposableUiInspectorPanel.rect(node.bounds)}\nclip ${CjguiComposableUiInspectorPanel.rect(node.clipBounds)} · constraints=${node.clipConstraints.size} complete=${node.clipComplete}",
                    body))
            detail.add(
                cjguiComposableText(18, "inspector-binding",
                    "resource=${node.resourceId} field=${node.fieldId}\naction=${node.actionName} owner=${node.ownerTargetResourceId} incarnation=${node.semanticIncarnation}",
                    body))
            detail.add(cjguiComposableText(19, "inspector-style", "${node.styleSummary}", body))
        } else {
            detail.add(
                cjguiComposableText(15, "inspector-help",
                    "选择左侧节点查看几何、裁剪与绑定。\n列表来自同一 accepted 快照；不采样屏幕外内容。\n旧快照只能查看，不能框到新场景的其他节点。",
                    body))
        }
        columns.add(detail);
        root.add(columns)
        root.add(
            cjguiComposableText(20, "inspector-cpu",
                "CPU 最近刷新尝试（独立于GPU完成帧，不相加）\nbuild ${CjguiComposableUiInspectorPanel.metric(page.buildNanoseconds, unit: " ns")} · layout ${CjguiComposableUiInspectorPanel.metric(page.layoutNanoseconds, unit: " ns")} · nativeStageAndSubmit ${CjguiComposableUiInspectorPanel.metric(page.nativeStageAndSubmitNanoseconds, unit: " ns")}",
                body))
        root.add(
            cjguiComposableText(21, "inspector-gpu",
                "GPU 已完成 frame ${CjguiComposableUiInspectorPanel.metric(page.completedFrameIndex)} · duration ${CjguiComposableUiInspectorPanel.metric(page.gpuDurationMicros, unit: " μs")}（不是物理上屏延迟）",
                body))
        root.add(
            cjguiComposableText(22, "inspector-resources",
                "累计文本资源 raster=${CjguiComposableUiInspectorPanel.metric(page.textRasterCount)} upload=${CjguiComposableUiInspectorPanel.metric(page.textUploadCount)}\n累计字节 raster=${CjguiComposableUiInspectorPanel.metric(page.textRasterBytes)} upload=${CjguiComposableUiInspectorPanel.metric(page.textUploadBytes)} · textureLive=${CjguiComposableUiInspectorPanel.metric(page.textTextureLiveBytes)}\n效果字节 live=${CjguiComposableUiInspectorPanel.metric(page.effectLiveBytes)} cached=${CjguiComposableUiInspectorPanel.metric(page.effectCachedBytes)} inFlight=${CjguiComposableUiInspectorPanel.metric(page.effectInFlightBytes)}",
                body))
        root.add(
            cjguiComposableText(23, "inspector-scope",
                "page ${page.startIndex}..${page.nextIndex}/${page.totalNodes}; 返回${page.nodes.size}个相交节点。${notice}",
                body))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 9 && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED) {
            if (commandMode) {
                commandQuery = event.text
                if (let Some(rows) <- commandFiltered) {
                    let _ = rows.setQuery(commandQuery)
                }
            } else {
                query = event.text
                if (let Some(rows) <- filtered) {
                    let _ = rows.setQuery(query)
                }
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            return CjguiComposableUiDispatchResult(false)
        }
        match (event.node.actionName) {
            case "INSPECT_MODE" =>
                commandMode = !commandMode
                if (commandMode && commandSnapshotValue.isNone()) {
                    let _ = loadCommands()
                }
                revision += 1
            case "INSPECT_REFRESH" =>
                let _ = refresh()
            case "INSPECT_FREEZE" =>
                frozen = !frozen
                revision += 1
            case "INSPECT_BOX" =>
                showBox = !showBox
                let _ = highlight();
                revision += 1
            case "INSPECT_FIRST" =>
                if (commandMode) {
                    if (let Some(page) <- commandSnapshotValue) {
                        if (page.startIndex > 0) {
                            let _ = loadCommands(startIndex: 0)
                        }
                    }
                } else {
                    let _ = load(0, true)
                }
            case "INSPECT_NEXT" =>
                if (commandMode) {
                    if (let Some(page) <- commandSnapshotValue) {
                        if (page.truncated) {
                            let _ = loadCommands(startIndex: page.nextIndex)
                        }
                    }
                } else {
                    if (let Some(page) <- snapshotValue) {
                        let _ = load(page.nextIndex, true)
                    }
                }
            case "INSPECT_SELECT" =>
                if (!commandMode) {
                    if (let Some(page) <- snapshotValue) {
                        for (node in page.nodes) {
                            if (node.sceneIndex == event.node.resourceId && event.node.semanticId ==
                                CjguiInspectorRows.semantic(page, node)) {
                                selected = Some(node)
                                listState.setSelectedKey("${node.sceneIndex}")
                                let _ = highlight();
                                revision += 1
                                break
                            }
                        }
                    }
                }
            case "INSPECT_SELECT_COMMAND" =>
                if (let Some(page) <- commandSnapshotValue) {
                    let index = event.node.resourceId
                    if (index >= 0 && index < page.commands.size &&
                        event.node.semanticId == CjguiInspectorCommandRows.semantic(page, index)) {
                        let command = page.commands[index]
                        selectedCommand = Some(command)
                        commandListState.setSelectedKey("${index}")
                        revision += 1
                    }
                }
            case _ => return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(true)
    }
    public func dispose(): Unit {
        if (let Some(window) <- source) {
            let _ = window.clearDiagnosticOverlay(overlayOwnerKey)
            if (window.liveWindowSessionIdentity().getOrDefault({=> ""}) == collectionSettingsSession) {
                if (let Some(settings) <- originalCollectionSettings) {
                    let _ = window.setWorkloadDiagnostics(settings[0])
                    let _ = window.setTimingDiagnostics(settings[1])
                }
            }
        }
        originalCollectionSettings = None
        source = None
        selected = None
        snapshotValue = None
        filtered = None
        selectedCommand = None
        commandSnapshotValue = None
        commandFiltered = None
        revision += 1
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        let _ = kind;
        let _ = node;
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        dispose();
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private class CjguiInspectorRows <: CjguiComposableUiVariableHeightListSource {
    private let page: CjguiComposableUiDiagnosticSnapshot
    private let scope: CjguiComposableUiIdentityScope
    init(page: CjguiComposableUiDiagnosticSnapshot) {
        this.page = page
        this.scope = CjguiComposableUiIdentityScope("inspector-nodes").child("${page.acceptedSceneVersion}")
    }
    static func semantic(page: CjguiComposableUiDiagnosticSnapshot, node: CjguiComposableUiDiagnosticNode): String {
        return "inspector-node-${page.acceptedSceneVersion}-${node.sceneIndex}"
    }
    public func itemCount(): Int64 {
        return page.nodes.size
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= page.nodes.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let node = page.nodes[index]
        return CjguiComposableUiVariableHeightListItem("${node.sceneIndex}", node.sceneIndex,
            "${node.semanticId} ${node.identityKey} ${node.fieldId} ${node.actionName}", page.acceptedSceneVersion,
            estimatedHeight: 30)
    }
    public func indexForKey(key: String): Int64 {
        for (index in 0..page.nodes.size) {
            if (key == "${page.nodes[index].sceneIndex}") {
                return index
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        return 0
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, selected: Bool, focused: Bool): CjguiComposableUiNode {
        let node = page.nodes[indexForKey(item.key)]
        return cjguiComposableButton(-1, CjguiInspectorRows.semantic(page, node),
            "#${node.sceneIndex} d${node.depth} ${node.semanticId}", "INSPECT_SELECT", node.sceneIndex,
            CjguiComposableUiStyle(fixedHeight: 30, growX: 1, fontSize: 12.0, padding: 5,
                textColor: CjguiComposableUiColor(0.9, 0.94, 1.0, 1.0), background: if (selected || focused) {
                    CjguiComposableUiColor(0.16, 0.34, 0.6, 1.0)
                } else {
                    CjguiComposableUiColor(0.08, 0.1, 0.15, 1.0)
                }, textMaxLines: 1, textOverflow: "ellipsis"), identity: Some(scope.child(item.key).local("row")))
    }
}

private class CjguiInspectorCommandRows <: CjguiComposableUiVariableHeightListSource {
    private let page: CjguiComposableUiCommandDiagnosticSnapshot
    private let scope: CjguiComposableUiIdentityScope
    init(page: CjguiComposableUiCommandDiagnosticSnapshot) {
        this.page = page
        this.scope = CjguiComposableUiIdentityScope("inspector-commands").child("${page.acceptedSceneVersion}")
    }
    static func semantic(page: CjguiComposableUiCommandDiagnosticSnapshot, index: Int64): String {
        return "inspector-command-${page.acceptedSceneVersion}-${index}"
    }
    public func itemCount(): Int64 {
        return page.commands.size
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= page.commands.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let command = page.commands[index]
        // The title is the search projection; the row renders stable fields
        // from the same command and never copies a business value.
        return CjguiComposableUiVariableHeightListItem("${index}", index, command.searchText(),
            page.acceptedSceneVersion, estimatedHeight: 30)
    }
    public func indexForKey(key: String): Int64 {
        for (index in 0..page.commands.size) {
            if (key == "${index}") {
                return index
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        return 0
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, selected: Bool,
        focused: Bool): CjguiComposableUiNode {
        let index = indexForKey(item.key)
        let command = page.commands[index]
        // The mark only restates the declaration's own checkable fact; a plain
        // action never earns one from a checked value or a label glyph.
        let checkedMark = if (command.checkable && command.checked) { " ✓" } else { "" }
        let checkableMark = if (command.checkable && !command.checked) { " ·未勾选" } else { "" }
        let disabledMark = if (command.enabled) { "" } else { " · 禁用" }
        return cjguiComposableButton(-1, CjguiInspectorCommandRows.semantic(page, index),
            "#${index} ${command.id} · ${command.resolution}${disabledMark}${checkedMark}${checkableMark}",
            "INSPECT_SELECT_COMMAND", index,
            CjguiComposableUiStyle(fixedHeight: 30, growX: 1, fontSize: 12.0, padding: 5,
                textColor: CjguiComposableUiColor(0.9, 0.94, 1.0, 1.0), background: if (selected || focused) {
                    CjguiComposableUiColor(0.16, 0.34, 0.6, 1.0)
                } else {
                    CjguiComposableUiColor(0.08, 0.1, 0.15, 1.0)
                }, textMaxLines: 1, textOverflow: "ellipsis"), identity: Some(scope.child(item.key).local("row")))
    }
}

/// macOS opt-in wiring on the EXISTING application/window owner. No new loop,
/// native window manager, IPC or business dependency. Call open outside pump.
public class CjguiMacosInspector {
    private let application: CjguiMacosApplication
    private let target: CjguiMacosApplicationWindowIdentifier
    private var identifier: ?CjguiMacosApplicationWindowIdentifier = None
    private var panel: ?CjguiComposableUiInspectorPanel = None
    public init(application: CjguiMacosApplication, target: CjguiMacosApplicationWindowIdentifier) {
        this.application = application
        this.target = target
    }
    public func isOpen(): Bool {
        return if (let Some(value) <- identifier) {
            application.window(value).isSome()
        } else {
            false
        }
    }
    public func open(collectCosts!: Bool = false): CjguiMacosApplicationWindowOpenResult {
        if (isOpen()) {
            return CjguiMacosApplicationWindowOpenResult(true, identifier, "already_open")
        }
        let source = match (application.window(target)) {
            case Some(value) => value
            case None => return CjguiMacosApplicationWindowOpenResult(false, None, "target_closed")
        }
        let candidate = CjguiComposableUiInspectorPanel(source, collectCosts: collectCosts)
        let result = application.openWindow(candidate,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Inspector · Read Only", 1040u32, 800u32))
        if (result.didOpen) {
            identifier = result.identifier
            panel = Some(candidate)
            candidate.overlayOwnerKey = result.identifier.getOrThrow().value
        } else {
            candidate.dispose()
        }
        return result
    }
    public func close(): Unit {
        if (let Some(value) <- panel) {
            value.dispose()
        }
        if (let Some(value) <- identifier) {
            let _ = application.requestClose(value)
        }
        panel = None
        identifier = None
    }
    /// Lifetime bookkeeping only; never captures a diagnostic snapshot.
    public func synchronizeLifetime(): Unit {
        if (application.window(target).isNone()) {
            close()
        } else if (!isOpen()) {
            if (let Some(value) <- panel) {
                value.dispose()
            };
            panel = None
            identifier = None
        }
    }
}
