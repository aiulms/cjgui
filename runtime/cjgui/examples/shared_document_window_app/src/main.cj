package cjgui_shared_document_window_app

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*
import std.overflow.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private let DESCRIPTION_DOCUMENT_ID: Int64 = 7101
private let NOTES_DOCUMENT_ID: Int64 = 7102
private let READ_ONLY_ARCHIVE_ID: Int64 = 7199
/// A second, ordinary composable-window consumer of the variable-height
/// virtual-list API. The document workspace remains the source of title,
/// content and selection truth; this adapter has no native state. Each row's
/// layout revision is the document snapshot version, so a document update
/// invalidates only that row's measured subtree.
private class CjguiSharedDocumentVirtualListSource <: CjguiComposableUiVariableHeightListSource {
    private let workspace: CjguiTextDocumentWorkspace
    private let theme: CjguiComposableUiTheme
    private let documentIds: ArrayList<Int64>

    init(workspace: CjguiTextDocumentWorkspace, theme: CjguiComposableUiTheme, reversed!: Bool = false) {
        this.workspace = workspace
        this.theme = theme
        this.documentIds = if (reversed) {
            ArrayList<Int64>([NOTES_DOCUMENT_ID, DESCRIPTION_DOCUMENT_ID])
        } else {
            ArrayList<Int64>([DESCRIPTION_DOCUMENT_ID, NOTES_DOCUMENT_ID])
        }
    }
    public func itemCount(): Int64 {
        return documentIds.size
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= documentIds.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let documentId = documentIds[index]
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            return CjguiComposableUiVariableHeightListItem("document_${documentId}", documentId, snapshot.title,
                snapshot.version, estimatedHeight: 96)
        }
        return CjguiComposableUiVariableHeightListItem.missing()
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < itemCount()) {
            if (itemAt(index).key == key) {
                return index
            }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        // The current document theme has one stable font metric generation;
        // colors/selection are row state and must not invalidate all heights.
        return if (theme.body.fontFamily == "monospaced") {
            2
        } else {
            1
        }
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        let selected = isSelected || isFocused
        let textColor = if (selected) {
            CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
        } else {
            theme.body.textColor
        }
        let background = if (selected) {
            CjguiComposableUiColor(0.15, 0.42, 0.72, 1.0)
        } else {
            CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0)
        }
        let row = cjguiComposableVertical(210000 + item.resourceId, "shared-document-row-${item.resourceId}",
            CjguiComposableUiStyle(minHeight: 96, padding: 7, gap: 4, background: background,
                border: CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0), textColor: textColor,
                fontFamily: theme.body.fontFamily))
        row.add(
            cjguiComposableText(220000 + item.resourceId, "shared-document-row-title-${item.resourceId}", item.title,
                CjguiComposableUiStyle(textColor: textColor, fontWeight: if (selected) {
                    1
                } else {
                    0
                }, fontFamily: theme.body.fontFamily), resourceId: item.resourceId, displayValueRole: "applied"))
        let summary = if (let Some(snapshot) <- workspace.documentSnapshot(item.resourceId)) {
            cjguiExperimentalDocumentPreview(snapshot.content).preview
        } else {
            "文档内容不可用"
        }
        row.add(
            cjguiComposableText(230000 + item.resourceId, "shared-document-row-summary-${item.resourceId}", summary,
                CjguiComposableUiStyle(fontSize: 11.0, textColor: textColor, fontFamily: theme.body.fontFamily,
                    maxWidth: 300, maxHeight: 72), resourceId: item.resourceId, displayValueRole: "document"))
        // Preserve the existing external SELECT_DOCUMENT descriptor and
        // controller event path; only the surrounding row becomes natural
        // multi-line content.
        row.add(
            cjguiComposableButton(110000 + item.resourceId, "shared-document-select-${item.resourceId}", "选择",
                "SELECT_DOCUMENT", item.resourceId,
                CjguiComposableUiStyle(fixedHeight: 26, textColor: textColor, fontFamily: theme.body.fontFamily),
                operationActionName: "SELECT_DOCUMENT", operationResourceId: item.resourceId))
        return row
    }
}

/// This consumer has no repeated component identity of its own, but its
/// keyboard/menu declarations still participate in the same scene acceptance
/// transaction as its document editor and virtual list.  That retires the
/// legacy post-start command registration path.
private class CjguiSharedDocumentController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiPointerCaptureVersionProvider {
    private let workspace: CjguiTextDocumentWorkspace
    private let fileBinding: CjguiTextDocumentFileBinding
    private let savePath: String
    private var localRevision: Int64
    private var status: String
    // `status` is a consumer-local explanation of the last action.  Keep its
    // owner version separately so an external workspace mutation cannot leave
    // a success message that claims an older document revision.
    private var statusDocumentVersion: Int64
    private let documentListState: CjguiComposableUiVirtualListState
    private var layerMode: String
    private var documentOrderReversed: Bool
    private var actionRowForCommands: ?CjguiComposableUiNode

    init(
        workspace: CjguiTextDocumentWorkspace,
        fileBinding: CjguiTextDocumentFileBinding,
        savePath: String,
        status: String
    ) {
        this.workspace = workspace
        this.fileBinding = fileBinding
        this.savePath = savePath
        let initialSelection = workspace.selection()
        this.localRevision = 1
        this.status = status
        this.statusDocumentVersion = if (initialSelection.isAvailable) {
            initialSelection.documentVersion
        } else {
            -1
        }
        this.documentListState = CjguiComposableUiVirtualListState()
        this.layerMode = ""
        this.documentOrderReversed = false
        this.actionRowForCommands = None
    }

    public func uiSceneVersion(): Int64 {
        // Aggregate workspace state rebuilds the scene; captured slider
        // invalidation below remains specific to its selected document.
        return workspace.contextSnapshot().version.saturatingAdd(localRevision)
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) {
            return workspace.previewLimitVersionForDocument(node.resourceId)
        }
        return uiSceneVersion()
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let selection = workspace.selection()
        let selectedDocumentId = if (selection.isAvailable) {
            selection.documentId
        } else {
            DESCRIPTION_DOCUMENT_ID
        }
        let snapshot = if (let Some(value) <- workspace.documentSnapshot(selectedDocumentId)) {
            value
        } else {
            CjguiTextDocumentSnapshot(selectedDocumentId, "已关闭文档", "", 0)
        }
        let previewLimit = workspace.previewLimitForDocument(selectedDocumentId)
        let host = cjguiComposableLayerHost(1, "shared-document-layer-host", theme.page)
        let root = cjguiComposableVertical(2, "shared-document-root", theme.page)
        root.add(cjguiComposableText(4, "shared-document-title", "共享文档编辑", theme.heading))
        root.add(
            cjguiComposableText(3, "shared-document-subtitle",
                "内容、版本、选区和历史由仓颉文档核心持有；原生控件只投影并回送输入。", theme.body))

        // Both panels retain their stable identities while the normal window
        // reallocates width. The list reaches its readable minimum before the
        // editor yields space, and either panel may stretch with window height.
        let workspacePanel = cjguiComposableHorizontal(9, "shared-document-workspace",
            CjguiComposableUiStyle(growY: 1, gap: 12))
        documentListState.setSelectedKey("document_${selectedDocumentId}")
        workspacePanel.add(
            cjguiComposableVariableHeightList(10, "shared-document-list-scroll", 15,
                CjguiSharedDocumentVirtualListSource(workspace, theme, reversed: documentOrderReversed),
                documentListState, 96, 4, 2,
                CjguiComposableUiStyle(minWidth: 160, idealWidth: 220, maxWidth: 320, growX: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: CjguiComposableUiColor(0.06, 0.10, 0.18, 1.0),
                    border: CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0))))
        let editorStyle = CjguiComposableUiStyle(
            minWidth: 300,
            idealWidth: 640,
            growX: 2,
            minHeight: 240,
            idealHeight: 326,
            alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
            background: CjguiComposableUiColor(0.035, 0.06, 0.11, 1.0),
            border: CjguiComposableUiColor(0.30, 0.47, 0.72, 1.0),
            textColor: CjguiComposableUiColor(0.93, 0.96, 1.0, 1.0),
            padding: 10,
            fontSize: 15.0,
            borderWidth: 1
        )
        workspacePanel.add(
            cjguiComposableMultilineTextInput(
                20,
                "shared-document-editor",
                snapshot.title,
                snapshot.content,
                selectedDocumentId,
                editorStyle,
                fieldId: "documentContent",
                operationActionName: "REPLACE_RANGE",
                operationResourceId: selectedDocumentId,
                displayValueRole: "document"
            )
        );
        root.add(workspacePanel)

        let secondary = CjguiComposableUiStyle(minWidth: 56, idealWidth: 90, maxWidth: 100, fixedHeight: 34,
            background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
            border: CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0), textColor: CjguiComposableUiColor(0.90, 0.94, 1.0,
                1.0))
        // The action bar has no document text/selection descendant. Its
        // target identity is the sole domain-derived layout/semantic input,
        // so document body edits can keep this region warm without
        // making the action target stale after a document switch. The row
        // and its five buttons use a caller-owned scope; handlers and the
        // document owner remain exactly the same as the legacy buttons.
        let actionScope = CjguiComposableUiIdentityScope("shared-document-actions")
        let actions = cjguiComposableScopedActionRow(
            actionScope,
            "shared-document-actions",
            ArrayList<CjguiComposableUiActionItem>(
                [
                    CjguiComposableUiActionItem("undo", "撤销", "UNDO", selectedDocumentId, secondary,
                        operationActionName: "UNDO", semanticId: "shared-document-undo"),
                    CjguiComposableUiActionItem("redo", "重做", "REDO", selectedDocumentId, secondary,
                        operationActionName: "REDO", semanticId: "shared-document-redo"),
                    CjguiComposableUiActionItem("save", "保存", "SAVE", selectedDocumentId, theme.primaryAction,
                        semanticId: "shared-document-save"),
                    CjguiComposableUiActionItem("close", "关闭", "CLOSE", selectedDocumentId, secondary,
                        semanticId: "shared-document-close"),
                    CjguiComposableUiActionItem("menu-trigger", "菜单", "OPEN_DOCUMENT_MENU", selectedDocumentId,
                        secondary, semanticId: "shared-document-menu-trigger")
                ]
            ),
            CjguiComposableUiStyle(fixedHeight: 36, gap: 10)
        )
        actionRowForCommands = Some(actions)
        root.add(actions)
        let previewSlider = cjguiComposableSlider(36, "shared-document-preview-limit", previewLimit, 128, 512, 32,
            CjguiComposableUiStyle(minWidth: 180, idealWidth: 220, fixedHeight: 28),
            operationActionName: "SET_PREVIEW_LIMIT", operationResourceId: selectedDocumentId)
        root.add(previewSlider)
        let selectionText = if (selection.isAvailable) {
            "选区 UTF-8 字节 ${selection.start}..${selection.end}，文档 v${selection.documentVersion}"
        } else {
            "当前没有可编辑文档"
        }
        // The workspace is the durable owner and can advance independently
        // through the authorized external connection.  Derive the visible
        // acknowledgement from that owner snapshot until a local action
        // reports the same revision; do not make `status` a second owner.
        let statusText = if (selection.isAvailable && selection.documentVersion != statusDocumentVersion) {
            "已同步外部文档：v${selection.documentVersion}"
        } else {
            status
        }
        root.add(
            cjguiComposableText(40, "shared-document-selection", selectionText, theme.body,
                resourceId: selectedDocumentId, fieldId: "selection", displayValueRole: "view"))
        root.add(cjguiComposableText(41, "shared-document-status", statusText, theme.body));
        let previewText = cjguiExperimentalDocumentPreview(snapshot.content, maxBytes: previewLimit, maxClusters: 160)
            .preview
        root.add(
            cjguiComposableText(42, "shared-document-preview-limit-value",
                "预览字节上限 ${previewLimit}：${previewText}", theme.body, resourceId: selectedDocumentId,
                displayValueRole: "view"))
        host.add(root)
        if (layerMode == "menu") {
            let menu = cjguiComposableAnchoredLayer(50, "shared-document-menu", "shared-document-menu", "menu",
                "shared-document-menu-trigger", 35,
                CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 54,
                    background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0), padding: 6, gap: 4))
            let menuScope = actionScope.child("menu")
            menu.add(
                cjguiComposableScopedActionRow(
                    menuScope,
                    "shared-document-menu-actions",
                    ArrayList<CjguiComposableUiActionItem>(
                        [
                            CjguiComposableUiActionItem("undo", "撤销", "UNDO", selectedDocumentId, secondary,
                                operationActionName: "UNDO", semanticId: "shared-document-menu-undo"),
                            CjguiComposableUiActionItem("redo", "重做", "REDO", selectedDocumentId, secondary,
                                operationActionName: "REDO", semanticId: "shared-document-menu-redo"),
                            CjguiComposableUiActionItem("close", "关闭菜单", "CLOSE_LAYER", selectedDocumentId,
                                secondary, semanticId: "shared-document-menu-close")
                        ]
                    ),
                    CjguiComposableUiStyle(fixedHeight: 34, gap: 4)
                )
            )
            host.add(menu)
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && event.eventKind == 35) {
            let direction = if (event.text == "left" || event.text == "down" || event.text == "previous") {
                -1
            } else if (event.text == "right" || event.text == "up" || event.text == "next") {
                1
            } else {
                0
            }
            if (direction != 0) {
                let nextValue = CjguiComposableUiSliderGeometry.adjustValue(
                    workspace.previewLimitForDocument(event.node.resourceId), direction,
                    event.node.pointerControlMinimum, event.node.pointerControlMaximum, event.node.pointerControlStep)
                let result = workspace.setPreviewLimitFromHuman(event.node.resourceId, nextValue)
                if (result.applied) {
                    localRevision += 1
                }
                return CjguiComposableUiDispatchResult(result.applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && (event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN || event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            let nextValue = CjguiComposableUiSliderGeometry.valueForPointer(event.pointerX, event.node.bounds.x,
                event.node.bounds.width, event.node.pointerControlMinimum, event.node.pointerControlMaximum,
                event.node.pointerControlStep)
            let result = workspace.setPreviewLimitFromHuman(event.node.resourceId, nextValue)
            if (result.applied) {
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if ((event.eventKind == 36 && layerMode == "menu") || (event.eventKind == 27 && event.node.actionName ==
            "LAYER_OUTSIDE")) {
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && event.node.nodeId == 10) {
            documentListState.scrollByViewport(event.text);
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 31 && event.node.actionName == "SELECT_DOCUMENT") {
            documentListState.setFocusedKey("document_${event.node.resourceId}");
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35 && event.node.nodeId == 10) {
            let target = documentListState.moveFocus(currentDocumentListSource(), event.text)
            if (target.resourceId < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            let result = workspace.selectDocumentFromHuman(target.resourceId)
            status = if (result.applied) {
                "已通过列表导航切换文档"
            } else {
                "未切换：${result.reason}"
            }
            if (result.applied) {
                documentListState.setSelectedKey(target.key);
                documentListState.setFocusedKey(target.key)
                let currentSelection = workspace.selection()
                if (currentSelection.isAvailable) {
                    statusDocumentVersion = currentSelection.documentVersion
                }
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 33 && event.node.nodeId == 20) {
            let selection = workspace.setSelectionFromNativeUtf16(event.node.resourceId, event.selectionStart,
                event.selectionEnd)
            if (!selection.isAvailable) {
                status = "选区未接受：${selection.reason}"
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(selection.isAvailable)
        }
        if (event.eventKind == 28 && event.node.nodeId == 20) {
            // The native adapter reports its committed projection here. The
            // workspace resolves the UTF-8 cluster-safe delta; it must not
            // encode the full visible document as one business replacement.
            let result = workspace.replaceProjectionTextFromHuman(event.node.resourceId, event.text)
            let selection = workspace.setSelectionFromNativeUtf16(event.node.resourceId, event.selectionStart,
                event.selectionEnd)
            status = if (result.applied && selection.isAvailable) {
                "文档已更新：v${result.versionAfter}"
            } else if (result.applied) {
                "文档已更新；选区未接受：${selection.reason}"
            } else {
                "文档未更新：${result.reason}"
            }
            if (result.applied) {
                statusDocumentVersion = result.versionAfter
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "OPEN_DOCUMENT_MENU") {
            layerMode = "menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CLOSE_LAYER") {
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "SELECT_DOCUMENT") {
            let result = workspace.selectDocumentFromHuman(event.node.resourceId)
            status = if (result.applied) {
                "已切换文档"
            } else {
                "未切换：${result.reason}"
            }
            if (result.applied) {
                documentListState.setSelectedKey("document_${event.node.resourceId}")
                documentListState.setFocusedKey("document_${event.node.resourceId}")
                let currentSelection = workspace.selection()
                if (currentSelection.isAvailable) {
                    statusDocumentVersion = currentSelection.documentVersion
                }
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.actionName == "UNDO") {
            let result = workspace.undoDocumentFromHuman(event.node.resourceId)
            status = if (result.applied) {
                "已撤销，文档 v${result.versionAfter}"
            } else {
                "未撤销：${result.reason}"
            }
            if (result.applied) {
                statusDocumentVersion = result.versionAfter
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.actionName == "REDO") {
            let result = workspace.redoDocumentFromHuman(event.node.resourceId)
            status = if (result.applied) {
                "已重做，文档 v${result.versionAfter}"
            } else {
                "未重做：${result.reason}"
            }
            if (result.applied) {
                statusDocumentVersion = result.versionAfter
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.node.actionName == "SAVE") {
            if (savePath.size == 0) {
                status = "未保存：用 --file PATH 指定受控文本文件"
                localRevision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            if (let Some(snapshot) <- workspace.documentSnapshot(event.node.resourceId)) {
                let result = fileBinding.saveFromHuman(snapshot, savePath)
                status = if (result.applied) {
                    "已原子保存到 ${result.path}"
                } else {
                    "未保存：${result.reason}"
                }
                if (result.applied) {
                    statusDocumentVersion = snapshot.version
                }
                localRevision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
            status = "未保存：document_closed"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        status = if (eventKind == 11) {
            "输入队列已满，本次输入未应用，请重试"
        } else {
            "输入未应用：节点 ${nodeId} 已在事件处理前变更"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func beginSceneRefresh(): Bool {
        return true
    }
    public func prepareSceneRefresh(): Bool {
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>(
            [
                CjguiComposableUiCommand("undo", actionNodeIdForCommands("shared-document-undo"),
                    CjguiComposableUiShortcut("z")),
                CjguiComposableUiCommand("redo", actionNodeIdForCommands("shared-document-redo"),
                    CjguiComposableUiShortcut("z", usesShift: true)),
                CjguiComposableUiCommand("save", actionNodeIdForCommands("shared-document-save"),
                    CjguiComposableUiShortcut("s")),
                CjguiComposableUiCommand("shared-document.open-menu",
                    actionNodeIdForCommands("shared-document-menu-trigger"), CjguiComposableUiShortcut("m"))
            ]
        )
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}

    // Test/diagnostic seam for a live reorder: the list source keeps business
    // keys stable while changing only their display order. Selection and
    // focus therefore remain keyed to the same document across refresh.
    func reverseDocumentOrder(): Unit {
        documentOrderReversed = !documentOrderReversed
        localRevision += 1
    }

    func focusedDocumentKeyForTest(): String {
        return documentListState.focusedKey()
    }

    private func actionNodeIdForCommands(semanticId: String): Int64 {
        if (let Some(row) <- actionRowForCommands) {
            for (node in row.children()) {
                if (node.semanticId == semanticId) {
                    return node.nodeId
                }
            }
        }
        return -1
    }

    private func currentDocumentListSource(): CjguiSharedDocumentVirtualListSource {
        return CjguiSharedDocumentVirtualListSource(workspace, CjguiComposableUiTheme.beaconDark(),
            reversed: documentOrderReversed)
    }
}

private func sharedDocumentProjectionNode(projection: CjguiSharedOperationWindowProjection, semanticId: String): CjguiSharedOperationWindowNode {
    for (node in projection.nodes) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiSharedOperationWindowNode(-1, "", "", ArrayList<Int64>())
}

private func assertSharedDocumentActionProjection(projection: CjguiSharedOperationWindowProjection, documentId: Int64): Unit {
    let undo = sharedDocumentProjectionNode(projection, "shared-document-undo")
    let redo = sharedDocumentProjectionNode(projection, "shared-document-redo")
    let save = sharedDocumentProjectionNode(projection, "shared-document-save")
    let close = sharedDocumentProjectionNode(projection, "shared-document-close")
    let menu = sharedDocumentProjectionNode(projection, "shared-document-menu-trigger")
    @Assert(undo.nodeId > 0, true)
    @Assert(redo.nodeId > 0, true)
    @Assert(save.nodeId > 0, true)
    @Assert(close.nodeId > 0, true)
    @Assert(menu.nodeId > 0, true)
    @Assert(firstResourceId(undo), documentId)
    @Assert(firstResourceId(redo), documentId)
    @Assert(firstResourceId(save), documentId)
    @Assert(firstResourceId(close), documentId)
    @Assert(firstResourceId(menu), documentId)
}

private func firstResourceId(node: CjguiSharedOperationWindowNode): Int64 {
    let resourceIds = node.resourceIds()
    return if (resourceIds.size > 0) {
        resourceIds[0]
    } else {
        -1
    }
}

@Test
func scopedDocumentActionsRetainOwnerAcrossSelectionAndReorder(): Unit {
    let fileBinding = CjguiTextDocumentFileBinding()
    let workspace = CjguiTextDocumentWorkspace(
        ArrayList<CjguiTextDocument>(
            [
                CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "说明文档", "说明内容"),
                CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "笔记内容"),
                CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "归档内容")
            ]
        )
    )
    let controller = CjguiSharedDocumentController(workspace, fileBinding, "", "测试")
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    assertSharedDocumentActionProjection(window.windowProjection(), DESCRIPTION_DOCUMENT_ID)

    // Use the same semantic/action/resource tuple emitted by the list row;
    // controller dispatch remains the sole owner-side selection path.
    let selectNotes = cjguiComposableButton(117102, "shared-document-select-7102", "选择", "SELECT_DOCUMENT",
        NOTES_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
    let selectedLayoutNode = CjguiComposableUiLayoutNode(selectNotes, CjguiComposableUiRect(0, 0, 100, 26),
        CjguiComposableUiRect(0, 0, 100, 26))
    let selected = controller.applyUiEvent(CjguiComposableUiEvent(selectedLayoutNode, 27, "", 0, 0, 1))
    @Assert(selected.didApply, true)
    @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)
    @Assert(controller.focusedDocumentKeyForTest(), "document_7102")
    @Assert(window.refresh(), true)
    assertSharedDocumentActionProjection(window.windowProjection(), NOTES_DOCUMENT_ID)

    // Reorder the source while keeping the selected/focused business key.
    // The next accepted scene must retain the same action targets rather than
    // binding them to the row's new display position.
    controller.reverseDocumentOrder()
    @Assert(window.refresh(), true)
    let reordered = window.windowProjection()
    assertSharedDocumentActionProjection(reordered, NOTES_DOCUMENT_ID)
    let selectedRow = sharedDocumentProjectionNode(reordered, "shared-document-select-7102")
    @Assert(selectedRow.nodeId > 0, true)
    @Assert(firstResourceId(selectedRow), NOTES_DOCUMENT_ID)
    @Assert(controller.focusedDocumentKeyForTest(), "document_7102")
    window.close()
}

/// A deliberately smaller projection for the application-owned multi-window
/// example. Its document binding is fixed per window: focus and selection
/// remain Cangjie window-local, while text mutations still travel to the one
/// workspace/document owner. It does not reuse the workspace-global selected
/// document as a hidden per-window state channel.
private class CjguiSharedDocumentMultiWindowController <: CjguiComposableUiController {
    private let workspace: CjguiTextDocumentWorkspace
    private let documentId: Int64
    private let viewName: String
    private let viewSemanticId: String
    private var localRevision: Int64

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64, viewName: String, viewSemanticId: String) {
        this.workspace = workspace
        this.documentId = documentId
        this.viewName = viewName
        this.viewSemanticId = viewSemanticId
        this.localRevision = 1
    }

    public func uiSceneVersion(): Int64 {
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            return snapshot.version.saturatingAdd(localRevision)
        }
        return localRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let snapshot = if (let Some(value) <- workspace.documentSnapshot(documentId)) {
            value
        } else {
            CjguiTextDocumentSnapshot(documentId, "已关闭文档", "", 0)
        }
        let root = cjguiComposableVertical(1, "shared-document-multi-root-${viewSemanticId}",
            CjguiComposableUiStyle(padding: 12, gap: 10, background: theme.page.background,
                textColor: theme.body.textColor, fontFamily: theme.body.fontFamily))
        root.add(
            cjguiComposableText(2, "shared-document-multi-title-${viewSemanticId}",
                "${viewName}：${snapshot.title}（v${snapshot.version}）", theme.heading, resourceId: documentId,
                displayValueRole: "document"))
        root.add(
            cjguiComposableMultilineTextInput(3, "shared-document-multi-editor-${viewSemanticId}", snapshot.title,
                snapshot.content, documentId,
                CjguiComposableUiStyle(growY: 1, minHeight: 220, background: CjguiComposableUiColor(0.035, 0.06, 0.11,
                    1.0), border: CjguiComposableUiColor(0.30, 0.47, 0.72, 1.0), textColor: theme.body.textColor,
                    padding: 10, fontSize: 15.0, borderWidth: 1), fieldId: "documentContent",
                operationActionName: "REPLACE_RANGE", operationResourceId: documentId, displayValueRole: "document"))
        root.add(
            cjguiComposableText(4, "shared-document-multi-preview-${viewSemanticId}",
                cjguiExperimentalDocumentPreview(snapshot.content).preview,
                CjguiComposableUiStyle(fontSize: 11.0, textColor: theme.body.textColor, maxHeight: 48),
                resourceId: documentId, displayValueRole: "document"))
        root.add(
            cjguiComposableButton(5, "shared-document-multi-close-${viewSemanticId}", "关闭此窗口", "CLOSE", documentId,
                CjguiComposableUiStyle(fixedHeight: 32, background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
                    border: CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0), textColor: theme.body.textColor)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 3 && event.node.resourceId == documentId) {
            return CjguiComposableUiDispatchResult(
                workspace.replaceProjectionTextFromHuman(documentId, event.text).applied)
        }
        if (event.eventKind == 27 && event.node.actionName == "CLOSE") {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        localRevision = localRevision.saturatingAdd(1)
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func authorization(
    includeSingleWindowReads!: Bool = true,
    includeTargetedWindowReads!: Bool = false
): CjguiSharedOperationExternalAuthorization {
    let editableTargets = ArrayList<Int64>([DESCRIPTION_DOCUMENT_ID, NOTES_DOCUMENT_ID])
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>(
        [
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", ArrayList<Int64>(), true)
        ]
    )
    if (includeSingleWindowReads) {
        // The single-window path retains the legacy omitted-target reads.
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true))
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true))
    }
    if (includeTargetedWindowReads) {
        // A multi-window application uses the same action names with an
        // explicit target argument. The transport binds that target to the
        // live window and never substitutes a sibling.
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true))
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true))
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true))
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_CONTEXT", ArrayList<Int64>(), true))
    }
    scopes.add(CjguiSharedOperationExternalActionScope("READ_RANGE", editableTargets, false))
    scopes.add(CjguiSharedOperationExternalActionScope("SELECT_DOCUMENT", ArrayList<Int64>(), true))
    scopes.add(CjguiSharedOperationExternalActionScope("INSERT_TEXT", editableTargets, false))
    scopes.add(CjguiSharedOperationExternalActionScope("DELETE_RANGE", editableTargets, false))
    scopes.add(CjguiSharedOperationExternalActionScope("REPLACE_RANGE", editableTargets, false))
    scopes.add(CjguiSharedOperationExternalActionScope("REPLACE_RANGES", editableTargets, false))
    scopes.add(CjguiSharedOperationExternalActionScope("SET_PREVIEW_LIMIT", editableTargets, false))
    return CjguiSharedOperationExternalAuthorization(
        "共享文档窗口 Agent",
        "cjgui-shared-document-window-agent-20260912",
        scopes
    )
}

private class CjguiSharedDocumentLaunchOptions {
    let filePath: String
    let enablesExternalConnection: Bool
    let expectsConnectionStartFailure: Bool
    let opensMultipleWindows: Bool
    let measurementDurationMs: Int64
    let measurementWarmupMs: Int64
    let closeFirstWindowAfterMs: Int64
    let recordsTurnObservations: Bool
    let reopensFirstWindowAfterClose: Bool

    init(filePath: String, enablesExternalConnection: Bool, expectsConnectionStartFailure: Bool,
        opensMultipleWindows: Bool, measurementDurationMs: Int64, measurementWarmupMs: Int64,
        closeFirstWindowAfterMs: Int64, recordsTurnObservations: Bool, reopensFirstWindowAfterClose: Bool) {
        this.filePath = filePath
        this.enablesExternalConnection = enablesExternalConnection
        this.expectsConnectionStartFailure = expectsConnectionStartFailure
        this.opensMultipleWindows = opensMultipleWindows
        this.measurementDurationMs = measurementDurationMs
        this.measurementWarmupMs = measurementWarmupMs
        this.closeFirstWindowAfterMs = closeFirstWindowAfterMs
        this.recordsTurnObservations = recordsTurnObservations
        this.reopensFirstWindowAfterClose = reopensFirstWindowAfterClose
    }
}

private func launchOptionsFromArgs(args: Array<String>): ?CjguiSharedDocumentLaunchOptions {
    var filePath = "";
    var enablesExternalConnection = false;
    var expectsConnectionStartFailure = false;
    var opensMultipleWindows = false;
    var measurementDurationMs: Int64 = 0
    var measurementWarmupMs: Int64 = 0;
    var closeFirstWindowAfterMs: Int64 = 0
    var recordsTurnObservations = false
    var reopensFirstWindowAfterClose = false
    var hasMeasurementWarmup = false;
    var hasCloseFirstWindowAfter = false
    var index: Int64 = 0
    while (index < args.size) {
        if (args[index] == "--with-connection" && !enablesExternalConnection) {
            enablesExternalConnection = true
            index += 1
        } else if (args[index] == "--multi-window" && !opensMultipleWindows) {
            opensMultipleWindows = true
            index += 1
        } else if (args[index] == "--verify-connection-start-failure" && !expectsConnectionStartFailure &&
            !enablesExternalConnection) {
            // Probe-only admission failure: the window is created normally,
            // then Host must close it when a rejected connection stops start.
            expectsConnectionStartFailure = true
            enablesExternalConnection = true
            index += 1
        } else if (args[index] == "--file" && index + 1 < args.size && filePath.size == 0 && args[index + 1].size > 0) {
            filePath = args[index + 1]
            index += 2
        } else if (args[index] == "--measurement-duration-ms" && index + 1 < args.size && measurementDurationMs == 0) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0 && value <= 900000) {
                    measurementDurationMs = value
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--measurement-warmup-ms" && index + 1 < args.size && !hasMeasurementWarmup) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value >= 0 && value <= 60000) {
                    measurementWarmupMs = value
                    hasMeasurementWarmup = true
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--close-first-window-after-ms" && index + 1 < args.size && !hasCloseFirstWindowAfter) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0 && value <= 60000) {
                    closeFirstWindowAfterMs = value
                    hasCloseFirstWindowAfter = true
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--record-turn-observations" && !recordsTurnObservations) {
            recordsTurnObservations = true
            index += 1
        } else if (args[index] == "--reopen-first-window-after-close" && !reopensFirstWindowAfterClose) {
            reopensFirstWindowAfterClose = true
            index += 1
        } else {
            return None
        }
    }
    if ((hasCloseFirstWindowAfter && !opensMultipleWindows) || (recordsTurnObservations && !opensMultipleWindows) || (reopensFirstWindowAfterClose &&
        (!opensMultipleWindows || !hasCloseFirstWindowAfter)) || (hasCloseFirstWindowAfter &&
        expectsConnectionStartFailure)) {
        return None
    }
    return Some(
        CjguiSharedDocumentLaunchOptions(filePath, enablesExternalConnection, expectsConnectionStartFailure,
            opensMultipleWindows, measurementDurationMs, measurementWarmupMs, closeFirstWindowAfterMs,
            recordsTurnObservations, reopensFirstWindowAfterClose))
}

private func initialPrimaryDocument(binding: CjguiTextDocumentFileBinding, path: String): CjguiTextDocument {
    if (path.size > 0 && exists(path)) {
        if (let Some(document) <- binding.openFromHuman(DESCRIPTION_DOCUMENT_ID, "说明文档", path).document) {
            return document
        }
    }
    return CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "说明文档",
        "第一行：把实际输入交给仓颉文档。\n第二行：选区使用 UTF-8 字节位置。\n第三行：emoji 🙂 不会被拆开。")
}

/// Normal framework-consumer entry for same-process windows. A/B deliberately
/// bind the same owner through different controller/view identities; C binds
/// the notes document. The public application owns their lifecycle and the
/// optional transport, so closing A cannot close B or the endpoint.
private func runMultiWindow(path: String, enablesExternalConnection: Bool, expectsConnectionStartFailure: Bool,
    measurementDurationMs: Int64, measurementWarmupMs: Int64, closeFirstWindowAfterMs: Int64,
    recordsTurnObservations: Bool, reopensFirstWindowAfterClose: Bool): Int32 {
    let fileBinding = CjguiTextDocumentFileBinding()
    let primary = initialPrimaryDocument(fileBinding, path)
    let notes = CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档",
        "这是一份独立文档；在多窗口中不会因说明文档的编辑而重建。")
    let archive = CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，但不授予远程内容范围读取或替换。")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([primary, notes, archive]))
    let application = CjguiMacosApplication(maximumWindowCount: 4)
    var activeConnection: ?CjguiSharedOperationExternalConnection = None
    var servicedExternalActions: Int64 = 0
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI Shared Document", 900u32, 580u32)
    let openedA = application.openWindow(
        CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID, "说明主视图", "primary"),
        configuration: configuration)
    let openedB = application.openWindow(
        CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID, "说明审阅视图", "review"),
        configuration: configuration)
    let openedC = application.openWindow(
        CjguiSharedDocumentMultiWindowController(workspace, NOTES_DOCUMENT_ID, "笔记视图", "notes"),
        configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen || !openedC.didOpen || application.windowIdentifiers().size != 3) {
        application.close()
        return 1
    }
    if (enablesExternalConnection) {
        let connectionAuthorization = if (expectsConnectionStartFailure) {
            CjguiSharedOperationExternalAuthorization("", "", ArrayList<CjguiSharedOperationExternalActionScope>())
        } else {
            authorization(includeSingleWindowReads: false, includeTargetedWindowReads: true)
        }
        let connection = CjguiSharedOperationExternalConnection(workspace, connectionAuthorization, workspace)
        if (!connection.enableTargetedContextReads(workspace) || !connection.enableRangeReads(workspace) ||
            !connection.enableWindowProjectionTargetReads(application) ||
            !connection.enableWindowProgressTargetReads(application)) {
            application.close()
            return 1
        }
        if (expectsConnectionStartFailure) {
            // A rejected process-level connection must not tear down windows
            // that were already started successfully. The explicit final
            // application close then owns the connection/session convergence.
            var endpointWasAbsent = false
            if (let None <- connection.connectionInfo()) {
                endpointWasAbsent = true
            }
            if (application.attachExternalConnection(connection) || !endpointWasAbsent || !application.isOpen() ||
                application.windowIdentifiers().size != 3) {
                application.close()
                return 1
            }
            application.close()
            var endpointRemainedAbsent = false
            if (let None <- connection.connectionInfo()) {
                endpointRemainedAbsent = true
            }
            if (application.isOpen() || application.windowIdentifiers().size != 0 || !endpointRemainedAbsent) {
                return 1
            }
            getStdOut().writeln(
                "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW connection_start_failure_preserved_windows=true endpoint_absent_before_and_after=true application_closed=true")
            return 0
        }
        if (!application.attachExternalConnection(connection)) {
            application.close()
            return 1
        }
        activeConnection = Some(connection)
        if (let Some(info) <- connection.connectionInfo()) {
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY DESCRIPTOR_PATH ${info.descriptorPath}")
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY PROTOCOL ${info.protocol}")
        } else {
            application.close()
            return 1
        }
    }
    let identifiers = application.windowIdentifiers()
    let output = getStdOut()
    output.writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY WINDOW_COUNT ${identifiers.size}")
    for (identifier in identifiers) {
        output.writeln(
            "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY WINDOW ${identifier.value} GENERATION ${identifier.generation}")
    }
    output.flush()
    let warmupStarted = MonoTime.now()
    while (application.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < measurementWarmupMs) {
        servicedExternalActions += application.pumpOneTurn().externalActionCount
    }
    let measurementStarted = MonoTime.now()
    var firstWindowCloseRequested = false
    var observedTurnIndex: Int64 = 0
    while (application.isOpen() && (measurementDurationMs <= 0 ||
            (MonoTime.now() - measurementStarted).toMilliseconds() < measurementDurationMs)) {
        // This opt-in, bounded probe switch exercises the same public
        // application close route as a human controller action. It exists so
        // a separate public socket client can prove that a closed target is
        // rejected while its live sibling remains addressable; it is not an
        // external mutation capability.
        if (!firstWindowCloseRequested && closeFirstWindowAfterMs > 0 &&
            (MonoTime.now() - measurementStarted).toMilliseconds() >= closeFirstWindowAfterMs) {
            if (let Some(identifier) <- openedA.identifier) {
                if (!application.requestClose(identifier)) {
                    application.close()
                    return 1
                }
                firstWindowCloseRequested = true
                output.writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT CLOSED_TARGET ${identifier.value}")
                if (reopensFirstWindowAfterClose) {
                    let reopened = application.openWindow(
                        CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID, "说明重建视图",
                            "primary-reopened"), configuration: configuration)
                    if (!reopened.didOpen) {
                        application.close()
                        return 1
                    }
                    if (let Some(reopenedIdentifier) <- reopened.identifier) {
                        output.writeln(
                            "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT REOPENED_TARGET ${reopenedIdentifier.value} GENERATION ${reopenedIdentifier.generation}")
                    } else {
                        application.close()
                        return 1
                    }
                }
                output.flush()
            } else {
                application.close()
                return 1
            }
        }
        let turn = application.pumpOneTurn()
        servicedExternalActions += turn.externalActionCount
        if (recordsTurnObservations) {
            var bSceneVersion: Int64 = -1
            var bSubmissionVersion: Int64 = -1
            if (let Some(identifierB) <- openedB.identifier) {
                if (let Some(windowB) <- application.window(identifierB)) {
                    let projectionB = windowB.windowProjection()
                    bSceneVersion = projectionB.sceneVersion
                    bSubmissionVersion = projectionB.nativeSubmissionCount
                }
            }
            let waitedTarget = if (let Some(waited) <- turn.waitedWindow) {
                waited.value
            } else {
                "none"
            }
            output.writeln(
                "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_TURN index ${observedTurnIndex} served_actions ${turn.externalActionCount} b_scene ${bSceneVersion} b_submit ${bSubmissionVersion} event_wait_budget_ms ${turn.eventWaitBudgetMs} elapsed_before_wait_ms ${turn.elapsedBeforeEventWaitMs} waited_target ${waitedTarget}")
            output.flush()
            observedTurnIndex += 1
        }
    }
    if (closeFirstWindowAfterMs > 0 && !firstWindowCloseRequested) {
        application.close()
        return 1
    }
    // Normal-process scalar evidence: this distinguishes the durable owner
    // version from each affected/unaffected window's submitted projection. A
    // submitted frame is intentionally not a claim of foreground visibility.
    if (let Some(description) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
        output.writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT DESCRIPTION_VERSION ${description.version}")
    }
    if (let Some(notesSnapshot) <- workspace.documentSnapshot(NOTES_DOCUMENT_ID)) {
        output.writeln("CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT NOTES_VERSION ${notesSnapshot.version}")
    }
    if (let Some(connection) <- activeConnection) {
        if (let Some(diagnostics) <- connection.transportDiagnostics()) {
            output.writeln(
                "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT TRANSPORT accepted_high_water ${diagnostics.acceptedClientHighWater} ready_high_water ${diagnostics.readyRequestHighWater} active_clients ${diagnostics.activeClientCount} serviced_actions ${servicedExternalActions}")
        }
    }
    for (identifier in application.windowIdentifiers()) {
        if (let Some(window) <- application.window(identifier)) {
            let projection = window.windowProjection()
            output.writeln(
                "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT WINDOW ${identifier.value} GENERATION ${identifier.generation} SCENE ${projection.sceneVersion} BUILD ${projection.buildPassCount} SUBMIT ${projection.nativeSubmissionCount}")
        }
    }
    output.flush()
    application.close()
    return 0
}

private func runWindow(path: String, enablesExternalConnection: Bool, expectsConnectionStartFailure: Bool,
    measurementDurationMs: Int64, measurementWarmupMs: Int64): Int32 {
    let fileBinding = CjguiTextDocumentFileBinding()
    let primary = initialPrimaryDocument(fileBinding, path)
    let notes = CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档",
        "这是一份独立文档；切换、撤销和外部版本校验均不串到说明。")
    let archive = CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，但不授予远程内容范围读取或替换。")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([primary, notes, archive]))
    let startupStatus = if (path.size == 0) {
        "编辑后可用 --file PATH 启动受控保存"
    } else if (exists(path)) {
        "已打开受控文件 ${path}"
    } else {
        "新文档将保存到 ${path}"
    }
    let host = CjguiMacosApplicationHost(
        CjguiSharedDocumentController(workspace, fileBinding, path, startupStatus),
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Shared Document", 980u32, 620u32)
    )
    let window = host.window()
    // The controller's participant supplies these semantic commands with the
    // scene candidate.  Host startup therefore cannot publish shortcuts that
    // point at a scene native has not accepted.
    if (enablesExternalConnection) {
        let connectionAuthorization = if (expectsConnectionStartFailure) {
            CjguiSharedOperationExternalAuthorization("", "", ArrayList<CjguiSharedOperationExternalActionScope>())
        } else {
            authorization()
        }
        let connection = CjguiSharedOperationExternalConnection(workspace, connectionAuthorization, workspace, window)
        if (!connection.enableTargetedContextReads(workspace) || !connection.enableWindowProgressReads(window) ||
            !connection.enableRangeReads(workspace) || !host.attachExternalConnection(connection)) {
            host.close();
            return 1
        }
        if (expectsConnectionStartFailure) {
            if (host.start() || host.isOpen()) {
                host.close();
                return 1
            }
            if (let Some(_) <- connection.connectionInfo()) {
                host.close();
                return 1
            }
            // The native window was created before connection.start failed;
            // both calls exercise the actual Host's idempotent close path.
            host.close();
            host.close()
            getStdOut().writeln("CJGUI_SHARED_DOCUMENT_HOST_PROBE connection_start_failure_cleaned")
            return 0
        }
        if (!host.start()) {
            host.close();
            return 1
        }
        if (let Some(info) <- connection.connectionInfo()) {
            let output = getStdOut()
            output.writeln("CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH ${info.descriptorPath}")
            output.writeln("CJGUI_SHARED_DOCUMENT_READY PROTOCOL ${info.protocol}")
            output.writeln("CJGUI_SHARED_DOCUMENT_READY ACTION_COUNT ${info.actions.size}")
            let projection = window.windowProjection()
            if (!projection.isActive || projection.sessionIdentity.size == 0 || projection.submittedFrameIndex <= 0) {
                output.flush();
                host.close();
                return 1
            }
            output.writeln(
                "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY ${projection.sessionIdentity} ${projection.submittedFrameIndex}")
            output.flush()
        }
        let warmupStarted = MonoTime.now()
        while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < measurementWarmupMs) {
            let _ = host.pumpOneTurn()
        }
        if (host.isOpen()) {
            let output = getStdOut();
            let projection = window.windowProjection()
            output.writeln("CJGUI_SHARED_DOCUMENT_READY MEASUREMENT_START ${projection.sessionIdentity}");
            output.flush()
        }
        let measurementStarted = MonoTime.now()
        while (host.isOpen() && (measurementDurationMs <= 0 || (MonoTime.now() - measurementStarted).toMilliseconds() <
                measurementDurationMs)) {
            let _ = host.pumpOneTurn()
        }
    } else {
        if (!host.start()) {
            host.close();
            return 1
        }
        let output = getStdOut();
        let initialProjection = window.windowProjection()
        if (!initialProjection.isActive || initialProjection.sessionIdentity.size == 0 ||
            initialProjection.submittedFrameIndex <= 0) {
            output.flush();
            host.close();
            return 1
        }
        output.writeln(
            "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY ${initialProjection.sessionIdentity} ${initialProjection.submittedFrameIndex}")
        output.flush()
        let warmupStarted = MonoTime.now()
        while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < measurementWarmupMs) {
            let _ = host.pumpOneTurn()
        }
        if (host.isOpen()) {
            let projection = window.windowProjection()
            output.writeln("CJGUI_SHARED_DOCUMENT_READY MEASUREMENT_START ${projection.sessionIdentity}");
            output.flush()
        }
        let measurementStarted = MonoTime.now()
        while (host.isOpen() && (measurementDurationMs <= 0 || (MonoTime.now() - measurementStarted).toMilliseconds() <
                measurementDurationMs)) {
            let _ = host.pumpOneTurn()
        }
    }
    host.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (let Some(options) <- launchOptionsFromArgs(args)) {
        if (options.opensMultipleWindows) {
            return Int64(runMultiWindow(options.filePath, options.enablesExternalConnection,
                options.expectsConnectionStartFailure, options.measurementDurationMs, options.measurementWarmupMs,
                options.closeFirstWindowAfterMs, options.recordsTurnObservations, options.reopensFirstWindowAfterClose))
        }
        return Int64(runWindow(options.filePath, options.enablesExternalConnection,
            options.expectsConnectionStartFailure, options.measurementDurationMs, options.measurementWarmupMs))
    }
    getStdErr().writeln(
        "usage: CJGUISharedDocument [--file PATH] [--multi-window] [--with-connection] [--verify-connection-start-failure] [--measurement-warmup-ms 0..60000] [--measurement-duration-ms 1..900000] [--close-first-window-after-ms 1..60000] [--reopen-first-window-after-close] [--record-turn-observations]")
    CjguiMacosApplicationHost.stopApplicationLoop()
    return 2
}
