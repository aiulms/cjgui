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
    private let reversedOrder: Bool
    private let cardScope: CjguiComposableUiIdentityScope

    init(workspace: CjguiTextDocumentWorkspace, theme: CjguiComposableUiTheme, reversed!: Bool = false,
        cardScope!: CjguiComposableUiIdentityScope = CjguiComposableUiIdentityScope("shared-document-card")) {
        this.workspace = workspace
        this.theme = theme
        this.cardScope = cardScope
        this.reversedOrder = reversed
    }
    private func visibleSummaries(): ArrayList<CjguiTextDocumentSummary> {
        let visible = ArrayList<CjguiTextDocumentSummary>()
        let summaries = workspace.openDocumentSummaries()
        if (reversedOrder) {
            var index = summaries.size - 1
            while (index >= 0) {
                if (summaries[index].documentId != READ_ONLY_ARCHIVE_ID) { visible.add(summaries[index]) }
                index -= 1
            }
        } else {
            for (summary in summaries) {
                if (summary.documentId != READ_ONLY_ARCHIVE_ID) { visible.add(summary) }
            }
        }
        return visible
    }
    public func itemCount(): Int64 {
        return visibleSummaries().size
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let summaries = visibleSummaries()
        if (index < 0 || index >= summaries.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let summary = summaries[index]
        return CjguiComposableUiVariableHeightListItem("document_${summary.documentId}", summary.documentId,
            summary.title, summary.version, estimatedHeight: 96)
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
        let itemScope = cardScope.child("document_${item.resourceId}")
        row.add(
            cjguiComposableScopedActionRow(
                itemScope.child("actions"),
                "shared-document-card-actions-${item.resourceId}",
                ArrayList<CjguiComposableUiActionItem>(
                    [
                        CjguiComposableUiActionItem("menu", "操作", "OPEN_DOCUMENT_CARD_MENU", item.resourceId,
                            CjguiComposableUiStyle(fixedHeight: 26, textColor: textColor,
                                fontFamily: theme.body.fontFamily),
                            semanticId: "shared-document-card-menu-${item.resourceId}"),
                        CjguiComposableUiActionItem("edit", "编辑", "OPEN_DOCUMENT_CARD_EDIT", item.resourceId,
                            CjguiComposableUiStyle(fixedHeight: 26, textColor: textColor,
                                fontFamily: theme.body.fontFamily),
                            semanticId: "shared-document-card-edit-${item.resourceId}")
                    ]
                ),
                CjguiComposableUiStyle(fixedHeight: 30, gap: 5)
            )
        )
        return row
    }
}

/// This consumer repeats the same scoped document card for every visible
/// document. Keyboard/menu declarations still participate in the same scene
/// acceptance transaction as its editor and virtual list.
private class CjguiSharedDocumentController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiDataTransferProvider & CjguiMacosApplicationExitDecisionProvider & CjguiMacosApplicationExitDecisionLifecycle & CjguiTextDocumentLifecycleDomain {
    private let workspace: CjguiTextDocumentWorkspace
    private let fileBinding: CjguiTextDocumentFileBinding
    private let savePath: String
    private let exitGuardEnabled: Bool
    private var localRevision: Int64
    private var status: String
    private var lastDocumentSaveReason: String
    // `status` is a consumer-local explanation of the last action.  Keep its
    // owner version separately so an external workspace mutation cannot leave
    // a success message that claims an older document revision.
    private var statusDocumentVersion: Int64
    private let documentListState: CjguiComposableUiVirtualListState
    private let cardScope: CjguiComposableUiIdentityScope
    private let actionScope: CjguiComposableUiIdentityScope
    private var layerMode: String
    private var activeDocumentId: Int64
    private var documentOrderReversed: Bool
    // Consumer-owned observations for a real window transfer event. These
    // counters are diagnostics only; workspace state remains the sole owner.
    private var transferDeclarationReadCount: Int64
    private var transferEventCount: Int64
    private var transferAcceptedCount: Int64
    private var transferRejectedCount: Int64
    private var transferPeakPayloadBytes: Int64
    private var transferLastApplyNanoseconds: Int64
    private var pendingLocalCloseRequest: Bool
    private var closeIntentKind: String
    private var closeGuardActive: Bool
    private var closeGuardDocumentId: Int64
    private var closeGuardNotice: String
    private var discardedDescriptionVersion: Int64
    private var discardedNotesVersion: Int64
    private let discardedVersionsByDocumentId: HashMap<Int64, Int64>
    private let queuedOpenPaths: ArrayList<String>
    private var lastClosedPath: String
    private var documentOpenedObserver: ?((Int64) -> Unit)
    private var documentClosedObserver: ?((Int64) -> Unit)
    private var retryApplicationExit: ?(() -> Bool)
    private var cancelApplicationExit: ?(() -> Unit)
    private var retryWindowClose: ?(() -> Bool)

    init(
        workspace: CjguiTextDocumentWorkspace,
        fileBinding: CjguiTextDocumentFileBinding,
        savePath: String,
        status: String,
        exitGuardEnabled!: Bool = false,
        openPaths!: ArrayList<String> = ArrayList<String>()
    ) {
        this.workspace = workspace
        this.fileBinding = fileBinding
        this.savePath = savePath
        this.exitGuardEnabled = exitGuardEnabled
        let initialSelection = workspace.selection()
        this.localRevision = 1
        this.status = status
        this.lastDocumentSaveReason = ""
        this.statusDocumentVersion = if (initialSelection.isAvailable) {
            initialSelection.documentVersion
        } else {
            -1
        }
        this.documentListState = CjguiComposableUiVirtualListState()
        this.cardScope = CjguiComposableUiIdentityScope("shared-document-card")
        this.actionScope = CjguiComposableUiIdentityScope("shared-document-actions")
        this.layerMode = ""
        this.activeDocumentId = -1
        this.documentOrderReversed = false
        this.transferDeclarationReadCount = 0
        this.transferEventCount = 0
        this.transferAcceptedCount = 0
        this.transferRejectedCount = 0
        this.transferPeakPayloadBytes = 0
        this.transferLastApplyNanoseconds = 0
        this.pendingLocalCloseRequest = false
        this.closeIntentKind = ""
        this.closeGuardActive = false
        this.closeGuardDocumentId = -1
        this.closeGuardNotice = ""
        this.discardedDescriptionVersion = -1
        this.discardedNotesVersion = -1
        this.discardedVersionsByDocumentId = HashMap<Int64, Int64>()
        this.queuedOpenPaths = ArrayList<String>(openPaths)
        this.lastClosedPath = ""
        this.documentOpenedObserver = None
        this.documentClosedObserver = None
        this.retryApplicationExit = None
        this.cancelApplicationExit = None
        this.retryWindowClose = None
    }

    func bindDocumentOpenedObserver(observer: (Int64) -> Unit): Unit {
        documentOpenedObserver = Some(observer)
    }

    func bindDocumentClosedObserver(observer: (Int64) -> Unit): Unit {
        documentClosedObserver = Some(observer)
    }

    func bindHostContinuations(applicationExit: () -> Bool, cancelExit: () -> Unit, windowClose: () -> Bool): Unit {
        retryApplicationExit = Some(applicationExit)
        cancelApplicationExit = Some(cancelExit)
        retryWindowClose = Some(windowClose)
    }

    func takePendingLocalCloseRequest(): Bool {
        let pending = pendingLocalCloseRequest
        pendingLocalCloseRequest = false
        return pending
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

    /// Transfer target/offer/accept seam for the future native clipboard and
    /// drag adapter. The controller delegates text mutation to the existing
    /// workspace range owner and retains no clipboard or drag state.
    public func offerSelectedTextTransfer(): ?CjguiSharedOperationTransferOffer {
        let selection = workspace.selection()
        if (!selection.isAvailable) { return None }
        return workspace.textTransferOfferForRangeFromHuman(
            selection.documentId, CjguiTextDocumentRange(selection.start, selection.end))
    }
    public func acceptTransferFromHuman(
        offer: CjguiSharedOperationTransferOffer
    ): CjguiSharedOperationTransferResult {
        let selection = workspace.selection()
        if (!selection.isAvailable) {
            return CjguiSharedOperationTransferResult.rejected(-1, "no_target")
        }
        let result = workspace.acceptTextTransferFromHuman(
            selection.documentId, CjguiTextDocumentRange(selection.start, selection.end), offer)
        if (result.applied) {
            status = "已接收传输文本：v${result.versionAfter}"
            statusDocumentVersion = result.versionAfter
            localRevision += 1
        }
        return result
    }
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        transferDeclarationReadCount += 1
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (let Some(offer) <- offerSelectedTextTransfer()) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source("shared-document-transfer-copy", offer))
            declarations.add(CjguiComposableUiDataTransferDeclaration.target("shared-document-transfer-paste",
                CjguiSharedOperationTransferFormat.utf8Text()))
        }
        return declarations
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        transferEventCount += 1
        if (event.offer.payloadByteCount > transferPeakPayloadBytes) {
            transferPeakPayloadBytes = event.offer.payloadByteCount
        }
        let started = MonoTime.now()
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
            status = "已复制当前选区；可拖到“粘贴到选区”或在其上粘贴。"
            localRevision += 1
            transferAcceptedCount += 1
            transferLastApplyNanoseconds = (MonoTime.now() - started).toNanoseconds()
            getStdOut().writeln("CJGUI_DOCUMENT_TRANSFER_EVENT kind=${event.eventKind} payload_bytes=${event.offer.payloadByteCount} accepted=true apply_ns=${transferLastApplyNanoseconds}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        let result = acceptTransferFromHuman(event.offer)
        if (!result.applied) {
            status = if (result.isVersionConflict) {
                "传输未应用：目标版本已变化。"
            } else {
                "传输未应用：${result.reason}"
            }
            localRevision += 1
        }
        if (result.applied) {
            transferAcceptedCount += 1
        } else {
            transferRejectedCount += 1
        }
        transferLastApplyNanoseconds = (MonoTime.now() - started).toNanoseconds()
        getStdOut().writeln("CJGUI_DOCUMENT_TRANSFER_EVENT kind=${event.eventKind} payload_bytes=${event.offer.payloadByteCount} accepted=${result.applied} apply_ns=${transferLastApplyNanoseconds}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(true)
    }

    func transferMetricsSummary(): String {
        return "declaration_reads=${transferDeclarationReadCount} events=${transferEventCount} " +
            "accepted=${transferAcceptedCount} rejected=${transferRejectedCount} " +
            "peak_payload_bytes=${transferPeakPayloadBytes} last_apply_ns=${transferLastApplyNanoseconds}"
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let selection = workspace.selection()
        let selectedDocumentId = if (selection.isAvailable) {
            selection.documentId
        } else {
            -1
        }
        let snapshot = if (let Some(value) <- workspace.documentSnapshot(selectedDocumentId)) {
            value
        } else {
            CjguiTextDocumentSnapshot(selectedDocumentId, "没有打开的文档", "", 0)
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
                CjguiSharedDocumentVirtualListSource(workspace, theme, reversed: documentOrderReversed,
                    cardScope: cardScope), documentListState, 96, 4, 2,
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
        let actions = cjguiComposableScopedActionRow(
            actionScope,
            "shared-document-actions",
            ArrayList<CjguiComposableUiActionItem>(
                [
                    CjguiComposableUiActionItem("undo", "撤销", "UNDO", selectedDocumentId, secondary,
                        operationActionName: "UNDO", semanticId: "shared-document-undo"),
                    CjguiComposableUiActionItem("redo", "重做", "REDO", selectedDocumentId, secondary,
                        operationActionName: "REDO", semanticId: "shared-document-redo"),
                    CjguiComposableUiActionItem("transfer-copy", "复制选区", "TRANSFER_COPY", selectedDocumentId,
                        secondary, semanticId: "shared-document-transfer-copy"),
                    CjguiComposableUiActionItem("transfer-paste", "粘贴到选区", "TRANSFER_PASTE", selectedDocumentId,
                        secondary, semanticId: "shared-document-transfer-paste"),
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
        root.add(actions)
        root.add(
            cjguiComposableScopedActionRow(
                actionScope.child("lifecycle"),
                "shared-document-lifecycle-actions",
                ArrayList<CjguiComposableUiActionItem>(
                    [
                        CjguiComposableUiActionItem("open", "打开", "OPEN_QUEUED_DOCUMENT", -1, secondary,
                            semanticId: "shared-document-open"),
                        CjguiComposableUiActionItem("close-document", "关闭文档", "CLOSE_DOCUMENT",
                            selectedDocumentId, secondary, semanticId: "shared-document-close-document")
                    ]
                ),
                CjguiComposableUiStyle(fixedHeight: 36, gap: 10)
            )
        )
        let previewSlider = cjguiComposableSlider(36, "shared-document-preview-limit", previewLimit, 128, 512, 32,
            CjguiComposableUiStyle(minWidth: 180, idealWidth: 220, fixedHeight: 28),
            operationActionName: "SET_PREVIEW_LIMIT", operationResourceId: selectedDocumentId)
        previewSlider.semanticLabel = "预览字节上限"
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
        if (layerMode == "document-card-menu" && activeDocumentId >= 0) {
            let cardScope = this.cardScope.child("document_${activeDocumentId}")
            let menu = cjguiComposableAnchoredLayerWithReference(60, "shared-document-card-menu-${activeDocumentId}",
                "shared-document-card-menu-${activeDocumentId}", "menu", "shared-document-row-${activeDocumentId}",
                CjguiComposableUiNodeReference.scoped(cardScope.child("actions").child("item"), "menu"),
                CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 70,
                    background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0), padding: 6, gap: 4))
            menu.add(
                cjguiComposableButton(61, "shared-document-card-menu-edit-${activeDocumentId}", "编辑内容",
                    "OPEN_DOCUMENT_CARD_EDIT", activeDocumentId, secondary))
            menu.add(
                cjguiComposableButton(62, "shared-document-card-menu-close-${activeDocumentId}", "关闭菜单",
                    "CLOSE_LAYER", activeDocumentId, secondary))
            host.add(menu)
        }
        if (layerMode == "document-card-edit" && activeDocumentId >= 0) {
            let snapshotForDialog = if (let Some(value) <- workspace.documentSnapshot(activeDocumentId)) {
                value
            } else {
                CjguiTextDocumentSnapshot(activeDocumentId, "已关闭文档", "", 0)
            }
            let editorScope = this.cardScope.child("document_${activeDocumentId}").child("editor")
            let dialog = cjguiComposableDialogLayerWithReference(63,
                "shared-document-card-edit-dialog-${activeDocumentId}",
                "shared-document-card-edit-dialog-${activeDocumentId}", "shared-document-row-${activeDocumentId}",
                CjguiComposableUiNodeReference.scoped(
                    this.cardScope.child("document_${activeDocumentId}").child("actions").child("item"), "edit"),
                CjguiComposableUiStyle(fixedWidth: 520, fixedHeight: 300,
                    background: CjguiComposableUiColor(0.035, 0.06, 0.11, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0), padding: 12, gap: 8),
                initialFocus: Some(CjguiComposableUiNodeReference.scoped(editorScope, "editor-content")))
            dialog.add(cjguiComposableText(64, "shared-document-card-edit-title", "编辑文档内容", theme.heading))
            dialog.add(
                CjguiComposableUiNode(65, "shared-document-card-editor-content",
                    CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "内容", snapshotForDialog.content, "EDIT_MULTILINE_TEXT",
                    activeDocumentId, editorStyle, fieldId: "documentContent", operationActionName: "REPLACE_RANGE",
                    operationResourceId: activeDocumentId, displayValueRole: "document",
                    identity: Some(editorScope.local("editor-content"))))
            dialog.add(
                cjguiComposableButton(66, "shared-document-card-edit-close", "完成", "CLOSE_LAYER", activeDocumentId,
                    secondary))
            host.add(dialog)
        }
        if (closeGuardActive) {
            let intentLabel = if (closeIntentKind == "application") {
                "退出"
            } else {
                "关闭"
            }
            let guardReturnAnchor = if (layerMode == "document-card-edit" && activeDocumentId >= 0) {
                let editorScope = this.cardScope.child("document_${activeDocumentId}").child("editor")
                CjguiComposableUiNodeReference.scoped(editorScope, "editor-content")
            } else {
                CjguiComposableUiNodeReference.manual(20)
            }
            let dialog = cjguiComposableDialogLayerWithReference(70, "shared-document-exit-guard",
                "shared-document-exit-guard", "shared-document-root", guardReturnAnchor,
                CjguiComposableUiStyle(fixedWidth: 500, fixedHeight: 220,
                    background: CjguiComposableUiColor(0.035, 0.06, 0.11, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0), padding: 12, gap: 8),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(75)))
            dialog.add(
                cjguiComposableText(71, "shared-document-exit-guard-title", "${intentLabel}前处理未保存内容",
                    theme.heading))
            dialog.add(
                cjguiComposableText(72, "shared-document-exit-guard-reason", closeGuardNotice,
                    CjguiComposableUiStyle(fontSize: 12.5, textColor: theme.body.textColor)))
            if (closeGuardCanSave()) {
                dialog.add(
                    cjguiComposableButton(73, "shared-document-exit-guard-save", "保存后继续${intentLabel}",
                        "EXIT_GUARD_SAVE", closeGuardDocumentId, theme.primaryAction))
            }
            dialog.add(
                cjguiComposableButton(74, "shared-document-exit-guard-discard", "明确放弃并继续${intentLabel}",
                    "EXIT_GUARD_DISCARD", closeGuardDocumentId, secondary))
            dialog.add(
                cjguiComposableButton(75, "shared-document-exit-guard-cancel", "取消${intentLabel}并继续编辑",
                    "EXIT_GUARD_CANCEL", closeGuardDocumentId, secondary))
            host.add(dialog)
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && (event.node.actionName == "TRANSFER_COPY" || event.node.actionName ==
            "TRANSFER_PASTE")) {
            status = if (event.node.actionName == "TRANSFER_COPY") {
                "在此按钮上使用 Cmd-C 或从此处拖出选区。"
            } else {
                "在此按钮上使用 Cmd-V 或拖入文本。"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
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
            layerMode = ""
            activeDocumentId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 31 && event.node.actionName == "SELECT_DOCUMENT") {
            documentListState.setFocusedKey("document_${event.node.resourceId}");
            layerMode = ""
            activeDocumentId = -1
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
        if (event.eventKind == 28 && event.node.nodeId == 65) {
            let result = workspace.replaceProjectionTextFromHuman(event.node.resourceId, event.text)
            if (result.applied) {
                status = "文档已更新：v${result.versionAfter}"
                statusDocumentVersion = result.versionAfter
            } else {
                status = "文档未更新：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "EXIT_GUARD_SAVE") {
            let target = closeGuardDocumentId
            let documentIntent = closeIntentKind == "document"
            let saved = saveDocumentFromHuman(target)
            if (saved) {
                if (documentIntent) {
                    let _ = finishDocumentClose(target)
                } else {
                    continuePendingCloseIntent()
                }
            }
            return CjguiComposableUiDispatchResult(saved)
        }
        if (event.node.actionName == "EXIT_GUARD_DISCARD") {
            if (let Some(snapshot) <- workspace.documentSnapshot(closeGuardDocumentId)) {
                let _ = discardedVersionsByDocumentId.add(closeGuardDocumentId, snapshot.version)
                if (closeGuardDocumentId == DESCRIPTION_DOCUMENT_ID) {
                    discardedDescriptionVersion = snapshot.version
                } else if (closeGuardDocumentId == NOTES_DOCUMENT_ID) {
                    discardedNotesVersion = snapshot.version
                }
                if (closeIntentKind == "document") {
                    let _ = finishDocumentClose(closeGuardDocumentId)
                } else {
                    continuePendingCloseIntent()
                }
                return CjguiComposableUiDispatchResult(true)
            }
            status = "未关闭：document_closed"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "EXIT_GUARD_CANCEL") {
            if (closeIntentKind == "application") {
                if (let Some(cancel) <- cancelApplicationExit) {
                    cancel()
                } else {
                    clearCloseIntent("已取消退出，文档仍可继续编辑")
                }
            } else {
                clearCloseIntent("已取消关闭，文档仍可继续编辑")
            }
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "OPEN_DOCUMENT_MENU") {
            layerMode = "menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "OPEN_DOCUMENT_CARD_MENU") {
            activeDocumentId = event.node.resourceId
            layerMode = "document-card-menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "OPEN_DOCUMENT_CARD_EDIT") {
            activeDocumentId = event.node.resourceId
            layerMode = "document-card-edit"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CLOSE_LAYER") {
            layerMode = ""
            activeDocumentId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "OPEN_QUEUED_DOCUMENT") {
            return CjguiComposableUiDispatchResult(openNextDocument())
        }
        if (event.node.actionName == "CLOSE_DOCUMENT") {
            return CjguiComposableUiDispatchResult(closeDocumentById(event.node.resourceId))
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
            return CjguiComposableUiDispatchResult(saveDocumentFromHuman(event.node.resourceId))
        }
        if (event.node.actionName == "CLOSE") {
            if (exitGuardEnabled) {
                pendingLocalCloseRequest = true
                localRevision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    /// The one explicit save route for both the ordinary Save action and the
    /// application-exit decision. This file binding belongs only to the
    /// description document; selecting the unbound notes document must never
    /// redirect its contents into the description file.
    private func controllerBindingFor(documentId: Int64): ?CjguiTextDocumentFileBinding {
        if (let Some(binding) <- workspace.fileBindingForDocument(documentId)) { return Some(binding) }
        if (documentId == DESCRIPTION_DOCUMENT_ID) { return Some(fileBinding) }
        return None
    }

    private func controllerPathFor(documentId: Int64): String {
        let path = workspace.filePathForDocument(documentId)
        if (path.size > 0) { return path }
        if (documentId == DESCRIPTION_DOCUMENT_ID) { return savePath }
        return ""
    }

    private func saveDocumentFromHuman(documentId: Int64): Bool {
        let binding = match (controllerBindingFor(documentId)) {
            case Some(value) => value
            case None =>
                lastDocumentSaveReason = "no_file_binding"
                status = "未保存：当前文档未绑定文件"
                localRevision += 1
                return false
        }
        let path = controllerPathFor(documentId)
        if (path.size == 0) {
            lastDocumentSaveReason = "no_file_path"
            status = "未保存：当前文档没有可写路径"
            localRevision += 1
            return false
        }
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            let bindingState = binding.persistedState(snapshot, path)
            if (bindingState == "different_document" || bindingState == "different_path" || (bindingState != "clean" &&
                bindingState != "dirty" && bindingState != "unbound")) {
                lastDocumentSaveReason = "binding_mismatch"
                status = "未保存：当前文档与文件绑定不匹配（${bindingState}）"
                localRevision += 1
                return false
            }
            let result = binding.saveFromHuman(snapshot, path)
            lastDocumentSaveReason = result.reason
            status = if (result.applied) {
                "已原子保存到 ${result.path}"
            } else {
                "未保存：${result.reason}"
            }
            // Both success and rejection report this actual owner snapshot.
            // Otherwise the generic external-update acknowledgement masks a
            // local save failure at the very revision it is explaining.
            statusDocumentVersion = snapshot.version
            if (!result.applied && closeGuardActive) {
                closeGuardNotice = status
            }
            localRevision += 1
            return result.applied
        }
        lastDocumentSaveReason = "document_closed"
        status = "未保存：document_closed"
        localRevision += 1
        return false
    }

    private func documentNeedsCloseDecision(documentId: Int64): Bool {
        if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
            if (let Some(discardedVersion) <- discardedVersionsByDocumentId.get(documentId)) {
                if (discardedVersion == snapshot.version) { return false }
            }
            if (documentId == DESCRIPTION_DOCUMENT_ID && workspace.fileBindingForDocument(documentId).isNone()) {
                let state = fileBinding.persistedState(snapshot, savePath)
                if (state == "clean") {
                    return false
                }
                if (snapshot.version == 0 && savePath.size == 0 && state == "no_file_path") {
                    return false
                }
                return discardedDescriptionVersion != snapshot.version
            }
            if (documentId == NOTES_DOCUMENT_ID && workspace.fileBindingForDocument(documentId).isNone()) {
                if (snapshot.version == 0) {
                    return false
                }
                return discardedNotesVersion != snapshot.version
            }
            if (let Some(binding) <- controllerBindingFor(documentId)) {
                let path = controllerPathFor(documentId)
                let state = binding.persistedState(snapshot, path)
                if (state == "clean") { return false }
                if (state == "different_document" || state == "different_path") { return true }
                if (snapshot.version == 0 && path.size == 0 && state == "no_file_path") { return false }
                return true
            }
            return snapshot.version != 0
        }
        return false
    }

    private func firstUndecidedDocument(): Int64 {
        for (summary in workspace.openDocumentSummaries()) {
            if (documentNeedsCloseDecision(summary.documentId)) { return summary.documentId }
        }
        return -1
    }

    private func closeGuardCanSave(): Bool {
        if (let Some(binding) <- controllerBindingFor(closeGuardDocumentId)) {
            let path = controllerPathFor(closeGuardDocumentId)
            if (path.size == 0) { return false }
            if (let Some(snapshot) <- workspace.documentSnapshot(closeGuardDocumentId)) {
                let state = binding.persistedState(snapshot, path)
                return state == "clean" || state == "dirty" || state == "unbound"
            }
        }
        return false
    }

    private func requestCloseDecision(): Bool {
        let blocker = firstUndecidedDocument()
        if (blocker < 0) {
            let hadGuard = closeGuardActive
            closeGuardActive = false
            closeGuardDocumentId = -1
            closeGuardNotice = ""
            if (hadGuard) {
                localRevision += 1
            }
            return true
        }
        return showCloseDecision(blocker)
    }

    private func showCloseDecision(blocker: Int64): Bool {
        closeGuardActive = true
        closeGuardDocumentId = blocker
        let snapshot = match (workspace.documentSnapshot(blocker)) {
            case Some(value) => value
            case None =>
                closeGuardActive = false
                closeGuardDocumentId = -1
                closeGuardNotice = ""
                status = "未关闭：文档已关闭"
                localRevision += 1
                return false
        }
        let intentLabel = if (closeIntentKind == "application") {
            "退出"
        } else {
            "关闭"
        }
        if (blocker == DESCRIPTION_DOCUMENT_ID && workspace.fileBindingForDocument(blocker).isNone()) {
            let state = fileBinding.persistedState(snapshot, savePath)
            closeGuardNotice = if (savePath.size == 0) {
                "${snapshot.title} v${snapshot.version} 有未保存内容，但没有 --file 路径。只能明确放弃或取消${intentLabel}。"
            } else if (state == "different_document" || state == "different_path") {
                "${snapshot.title} 的文件绑定身份不匹配（${state}）；不能安全保存，只能明确放弃或取消${intentLabel}。"
            } else if (state == "unbound") {
                "${snapshot.title} v${snapshot.version} 尚未绑定文件。保存只会创建不存在的目标；已有文件仍受冲突保护。也可明确放弃或取消${intentLabel}。"
            } else {
                "${snapshot.title} v${snapshot.version} 尚未保存。可保存到原文件、明确放弃或取消${intentLabel}。"
            }
        } else if (blocker == NOTES_DOCUMENT_ID && workspace.fileBindingForDocument(blocker).isNone()) {
            closeGuardNotice = "${snapshot.title} v${snapshot.version} 是未绑定文件的笔记；不能写入说明文档文件。只能明确放弃或取消${intentLabel}。"
        } else {
            let path = controllerPathFor(blocker)
            let state = if (let Some(binding) <- controllerBindingFor(blocker)) {
                binding.persistedState(snapshot, path)
            } else {
                "unbound"
            }
            closeGuardNotice = if (path.size == 0) {
                "${snapshot.title} v${snapshot.version} 有未保存内容，但没有可写路径。只能明确放弃或取消${intentLabel}。"
            } else if (state == "different_document" || state == "different_path") {
                "${snapshot.title} 的文件绑定身份不匹配（${state}）；不能安全保存，只能明确放弃或取消${intentLabel}。"
            } else if (state == "unbound") {
                "${snapshot.title} v${snapshot.version} 尚未绑定文件。保存只会创建不存在的目标；已有文件仍受冲突保护。也可明确放弃或取消${intentLabel}。"
            } else {
                "${snapshot.title} v${snapshot.version} 尚未保存。可保存到原文件、明确放弃或取消${intentLabel}。"
            }
        }
        localRevision += 1
        return false
    }

    private func performOpen(path: String): CjguiTextDocumentOpenResult {
        let result = if (path.size > 0) {
            workspace.openDocumentFromFileFromHuman(sharedDocumentTitleForPath(path),
                CjguiTextDocumentFileBinding(), path, createIfMissing: true)
        } else {
            workspace.openDocumentFromHuman("新文档 ${workspace.openDocumentCount() + 1}", "")
        }
        if (result.applied) {
            if (let Some(observer) <- documentOpenedObserver) {
                observer(result.resourceId)
            }
            documentListState.setSelectedKey("document_${result.resourceId}")
            documentListState.setFocusedKey("document_${result.resourceId}")
            status = "已打开文档 v0（${result.resourceId}）"
            getStdOut().writeln(
                "CJGUI_DOCUMENT_LIFECYCLE action=opened resource_id=${result.resourceId} path=${path}")
            getStdOut().flush()
        } else {
            status = "未打开：${result.reason}"
        }
        localRevision += 1
        return result
    }

    private func openNextDocument(): Bool {
        var path = ""
        if (queuedOpenPaths.size > 0) {
            path = queuedOpenPaths.remove(at: 0)
        } else if (lastClosedPath.size > 0) {
            path = lastClosedPath
        }
        return performOpen(path).applied
    }

    /// Public lifecycle open: only a path the application already queued is
    /// eligible. The external request carries no arbitrary filesystem path.
    public func openAuthorizedDocumentFromExternal(): CjguiSharedOperationActionResult {
        let before = workspace.contextSnapshot().version
        if (queuedOpenPaths.size == 0) {
            status = "未打开：没有应用授权的待打开路径"
            localRevision += 1
            return CjguiSharedOperationActionResult(false, false, before, before, "no_authorized_document")
        }
        let path = queuedOpenPaths.remove(at: 0)
        let result = performOpen(path)
        let after = workspace.contextSnapshot().version
        return CjguiSharedOperationActionResult(result.applied, false, before, after, result.reason)
    }

    private func closeDocumentById(documentId: Int64): Bool {
        if (workspace.documentSnapshot(documentId).isNone()) {
            status = "未关闭：${workspace.documentLiveness(documentId)}"
            localRevision += 1
            return false
        }
        if (documentNeedsCloseDecision(documentId)) {
            closeIntentKind = "document"
            return showCloseDecision(documentId)
        }
        return finishDocumentClose(documentId)
    }

    private func closeSelectedDocument(): Bool {
        let selection = workspace.selection()
        if (!selection.isAvailable) {
            status = "未关闭：当前没有打开的文档"
            localRevision += 1
            return false
        }
        return closeDocumentById(selection.documentId)
    }

    /// Public lifecycle close: the target and its expected document version
    /// are explicit. A dirty target without `save`/`discard` is retained; an
    /// unknown, retired or unauthorized target never falls back to selection.
    public func closeDocumentFromExternal(
        documentId: Int64,
        expectedVersion: Int64,
        decision: String
    ): CjguiSharedOperationActionResult {
        let before = workspace.contextSnapshot().version
        let snapshot = match (workspace.documentSnapshot(documentId)) {
            case Some(value) => value
            case None =>
                let reason = workspace.documentLiveness(documentId)
                status = "未关闭：${reason}"
                localRevision += 1
                return CjguiSharedOperationActionResult(false, false, before, before, reason)
        }
        if (snapshot.version != expectedVersion) {
            status = "未关闭：版本冲突"
            localRevision += 1
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (decision != "" && decision != "close" && decision != "save" && decision != "discard" && decision != "cancel") {
            status = "未关闭：无效的未保存决定"
            localRevision += 1
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_decision")
        }
        if (decision == "cancel") {
            status = "已取消关闭，文档仍可继续编辑"
            localRevision += 1
            return CjguiSharedOperationActionResult(false, false, before, before, "close_cancelled")
        }
        if (documentNeedsCloseDecision(documentId)) {
            if (decision == "" || decision == "close") {
                status = "未关闭：需要保存或明确放弃未保存内容"
                localRevision += 1
                return CjguiSharedOperationActionResult(false, false, before, before, "unsaved_decision_required")
            }
            if (decision == "save") {
                if (!saveDocumentFromHuman(documentId)) {
                    let reason = if (lastDocumentSaveReason.size > 0) { lastDocumentSaveReason } else { "save_failed" }
                    return CjguiSharedOperationActionResult(false, false, before,
                        workspace.contextSnapshot().version, reason)
                }
            } else if (decision == "discard") {
                let _ = discardedVersionsByDocumentId.add(documentId, snapshot.version)
                if (documentId == DESCRIPTION_DOCUMENT_ID) {
                    discardedDescriptionVersion = snapshot.version
                } else if (documentId == NOTES_DOCUMENT_ID) {
                    discardedNotesVersion = snapshot.version
                }
            }
        }
        let closed = finishDocumentClose(documentId)
        let after = workspace.contextSnapshot().version
        return CjguiSharedOperationActionResult(closed, false, before, after,
            if (closed) { "document_closed" } else { "close_refused" })
    }

    private func finishDocumentClose(documentId: Int64): Bool {
        let path = workspace.filePathForDocument(documentId)
        let result = workspace.closeDocumentFromHuman(documentId)
        if (result.applied) {
            if (path.size > 0) { lastClosedPath = path }
            if (let Some(observer) <- documentClosedObserver) {
                observer(documentId)
            }
            resetCloseIntent()
            status = "已关闭文档（${documentId}）"
            getStdOut().writeln(
                "CJGUI_DOCUMENT_LIFECYCLE action=closed resource_id=${documentId} path=${path}")
            getStdOut().flush()
            localRevision += 1
            return true
        }
        status = "未关闭：${result.reason}"
        localRevision += 1
        return false
    }

    private func continuePendingCloseIntent(): Unit {
        if (closeIntentKind == "application") {
            if (let Some(retry) <- retryApplicationExit) {
                let _ = retry()
            }
        } else if (closeIntentKind == "window") {
            if (let Some(retry) <- retryWindowClose) {
                let _ = retry()
            }
        }
    }

    private func clearCloseIntent(message: String): Unit {
        resetCloseIntent()
        status = message
        localRevision += 1
    }

    private func resetCloseIntent(): Unit {
        closeIntentKind = ""
        closeGuardActive = false
        closeGuardDocumentId = -1
        closeGuardNotice = ""
        discardedDescriptionVersion = -1
        discardedNotesVersion = -1
        discardedVersionsByDocumentId.clear()
    }

    func reportLocalCloseRequestRejected(): Unit {
        status = "未关闭：窗口关闭请求未被宿主接收"
        localRevision += 1
    }

    public func requestApplicationExit(): Bool {
        closeIntentKind = "application"
        return requestCloseDecision()
    }

    public func applicationExitDidCommit(): Unit {
        resetCloseIntent()
    }

    public func applicationExitDidCancel(): Unit {
        clearCloseIntent("已取消退出，文档仍可继续编辑")
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
        if (!exitGuardEnabled) {
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        closeIntentKind = "window"
        if (requestCloseDecision()) {
            resetCloseIntent()
            return CjguiComposableUiDispatchResult(true, shouldClose: true)
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: false)
    }

    public func beginSceneRefresh(): Bool {
        return true
    }
    public func prepareSceneRefresh(): Bool {
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        // A visible self-drawn menu owns the Cangjie focus scope. Rebind its
        // shared command vocabulary to the actions inside that layer, so the
        // native application menu never reaches through the focused layer to
        // a covered document action.
        let menuIsOpen = layerMode == "menu"
        let commandActionScope = if (menuIsOpen) {
            actionScope.child("menu").child("item")
        } else {
            actionScope.child("item")
        }
        let commandFocusScope = if (menuIsOpen) {
            "shared-document-menu"
        } else {
            ""
        }
        return ArrayList<CjguiComposableUiCommand>(
            [
                CjguiComposableUiCommand(
                    "shared-document.undo",
                    CjguiComposableUiNodeReference.scoped(commandActionScope, "undo"),
                    "撤销",
                    CjguiComposableUiShortcut("z"),
                    "Document",
                    0,
                    true,
                    false,
                    focusScopeId: commandFocusScope
                ),
                CjguiComposableUiCommand(
                    "shared-document.redo",
                    CjguiComposableUiNodeReference.scoped(commandActionScope, "redo"),
                    "重做",
                    CjguiComposableUiShortcut("z", usesShift: true),
                    "Document",
                    0,
                    true,
                    false,
                    focusScopeId: commandFocusScope
                ),
                CjguiComposableUiCommand(
                    "shared-document.save",
                    CjguiComposableUiNodeReference.scoped(actionScope.child("item"), "save"),
                    "保存",
                    CjguiComposableUiShortcut("s"),
                    "Document",
                    1,
                    !menuIsOpen,
                    false
                ),
                CjguiComposableUiCommand(
                    "shared-document.open-menu",
                    CjguiComposableUiNodeReference.scoped(actionScope.child("item"), "menu-trigger"),
                    "菜单",
                    CjguiComposableUiShortcut("m"),
                    "Document",
                    2,
                    !menuIsOpen,
                    false
                )
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
        layerMode = ""
        activeDocumentId = -1
        localRevision += 1
    }

    func focusedDocumentKeyForTest(): String {
        return documentListState.focusedKey()
    }

    private func currentDocumentListSource(): CjguiSharedDocumentVirtualListSource {
        return CjguiSharedDocumentVirtualListSource(workspace, CjguiComposableUiTheme.beaconDark(),
            reversed: documentOrderReversed, cardScope: cardScope)
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

private func assertSharedDocumentCardProjection(projection: CjguiSharedOperationWindowProjection, documentId: Int64): Unit {
    let menu = sharedDocumentProjectionNode(projection, "shared-document-card-menu-${documentId}")
    let edit = sharedDocumentProjectionNode(projection, "shared-document-card-edit-${documentId}")
    @Assert(menu.nodeId > 0, true)
    @Assert(edit.nodeId > 0, true)
    @Assert(menu.nodeId != edit.nodeId, true)
    @Assert(firstResourceId(menu), documentId)
    @Assert(firstResourceId(edit), documentId)
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
func composableDocumentTransferConsumerUsesExistingRangeOwner(): Unit {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "传输文档", "甲乙")
    ]))
    let controller = CjguiSharedDocumentController(workspace, CjguiTextDocumentFileBinding(), "", "测试")
    let _ = workspace.setSelectionFromHuman(DESCRIPTION_DOCUMENT_ID, CjguiTextDocumentRange(0, 3))
    if (let Some(offer) <- controller.offerSelectedTextTransfer()) {
        let _ = workspace.setSelectionFromHuman(DESCRIPTION_DOCUMENT_ID, CjguiTextDocumentRange(3, 6))
        let declarations = controller.dataTransferDeclarations()
        @Assert(declarations.size, 2)
        let targetNode = CjguiComposableUiLayoutNode(
            cjguiComposableButton(9902, "shared-document-transfer-paste", "粘贴到选区", "TRANSFER_PASTE",
                DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30)), CjguiComposableUiRect(0, 0, 100, 30),
            CjguiComposableUiRect(0, 0, 100, 30))
        let accepted = controller.applyDataTransfer(CjguiComposableUiDataTransferEvent(
            targetNode, CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_PASTE, offer, offer.format, 1))
        @Assert(accepted.didApply, true)
        if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
            @Assert(snapshot.content, "甲甲")
        } else {
            @Assert(false, true)
        }
    } else {
        @Assert(false, true)
    }
}

private func transferCostDocumentText(length: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < length) {
        builder.append("x")
        index += 1
    }
    return builder.toString()
}

// The document consumer measures bounded UTF-8 offers without retaining a
// pasteboard or re-entering the workspace owner. The sizes cover a small,
// middle and near-maximum supported text selection.
@Test
func composableDocumentTransferCostIsBoundedAcrossPayloadSizesAndIdleRepeats(): Unit {
    let small = transferCostDocumentText(128)
    let medium = transferCostDocumentText(4096)
    let nearLimit = transferCostDocumentText(512 * 1024)
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "成本小", small),
        CjguiTextDocument(NOTES_DOCUMENT_ID, "成本中", medium),
        CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "成本近上限", nearLimit)
    ]))
    var payloadBytes = ArrayList<Int64>()
    let started = MonoTime.now()
    let documentIds = ArrayList<Int64>([DESCRIPTION_DOCUMENT_ID, NOTES_DOCUMENT_ID, READ_ONLY_ARCHIVE_ID])
    let selections = ArrayList<Int64>([128, 4096, 512 * 1024])
    var index: Int64 = 0
    while (index < selections.size) {
        @Assert(workspace.setSelectionFromHuman(documentIds[index],
            CjguiTextDocumentRange(0, selections[index])).isAvailable, true)
        if (let Some(offer) <- workspace.textTransferOfferForRangeFromHuman(
            documentIds[index], CjguiTextDocumentRange(0, selections[index]))) {
            payloadBytes.add(offer.payloadByteCount)
        } else {
            @Assert(false, true)
        }
        index += 1
    }
    let elapsedMs = (MonoTime.now() - started).toMilliseconds()
    @Assert(payloadBytes.size, 3)
    @Assert(payloadBytes[0], 128)
    @Assert(payloadBytes[1], 4096)
    @Assert(payloadBytes[2], 512 * 1024)
    getStdOut().writeln("CJGUI_DOCUMENT_TRANSFER_COST sizes=${payloadBytes[0]},${payloadBytes[1]},${payloadBytes[2]} " +
        "repeated_offers=3 owner_version=${workspace.contextSnapshot().version} elapsed_ms=${elapsedMs} passed=true")
    getStdOut().flush()
}

// Command-menu regression: external owner content is projected, then the
// self-drawn document menu uses the same command IDs as the window command
// declarations. Undo remains a workspace operation, and closing the window
// removes the command target rather than retaining a stale callback.
@Test
func commandMenuRouteKeepsDocumentOwnerAndLayerInSync(): Unit {
    let workspace = CjguiTextDocumentWorkspace(
        ArrayList<CjguiTextDocument>([
            CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "说明文档", "说明内容"),
            CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "笔记内容")
        ])
    )
    let controller = CjguiSharedDocumentController(workspace, CjguiTextDocumentFileBinding(), "", "测试")
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let edited = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "外部修改后的说明")
    @Assert(edited.applied, true)
    @Assert(window.refresh(), true)
    @Assert(window.windowProjection().pendingRefreshReason, "none")
    @Assert(window.invokeCommand("shared-document.open-menu"), true)
    @Assert(sharedDocumentProjectionNode(window.windowProjection(), "shared-document-menu").nodeId > 0, true)
    @Assert(window.invokeCommand("shared-document.undo"), true)
    if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
        @Assert(snapshot.content, "说明内容")
    } else {
        @Assert(false, true)
    }
    window.close()
    @Assert(!window.invokeCommand("shared-document.undo"), true)
}

@Test
func documentSaveActionCannotWriteUnboundNotesToDescriptionFile(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    try {
        File.writeTo(Path(path), "bound description".toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "独立笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试")
        let notesSave = cjguiComposableButton(117105, "shared-document-save-notes", "保存", "SAVE", NOTES_DOCUMENT_ID,
            CjguiComposableUiStyle(fixedHeight: 26))
        let rejected = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(notesSave, CjguiComposableUiRect(0, 0, 80, 26),
                    CjguiComposableUiRect(0, 0, 80, 26)), 27, "", 0, 0, 1))
        @Assert(rejected.didApply, false)
        @Assert(String.fromUtf8(File.readFrom(path)), "bound description")
        @Assert(binding.persistedState(primary.snapshot(), path), "clean")
        if (let Some(notes) <- workspace.documentSnapshot(NOTES_DOCUMENT_ID)) {
            @Assert(notes.content, "独立笔记")
        } else {
            @Assert(false, true)
        }

        @Assert(workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "updated description").applied,
            true)
        let descriptionSave = cjguiComposableButton(117106, "shared-document-save-description", "保存", "SAVE",
            DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
        let saved = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(descriptionSave, CjguiComposableUiRect(0, 0, 80, 26),
                    CjguiComposableUiRect(0, 0, 80, 26)), 27, "", 0, 0, 1))
        @Assert(saved.didApply, true)
        @Assert(String.fromUtf8(File.readFrom(path)), "updated description")
        if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
            @Assert(binding.persistedState(snapshot, path), "clean")
        } else {
            @Assert(false, true)
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func dirtyDocumentCloseIsCanceledWithoutLosingTheOriginalOwner(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    try {
        File.writeTo(Path(path), "saved baseline".toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "模板笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试", exitGuardEnabled: true)
        let edit = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "edited before close")
        @Assert(edit.applied, true)

        let closeRequest = controller.requestWindowClose()
        @Assert(closeRequest.shouldClose, false)

        let cancel = cjguiComposableButton(117107, "shared-document-exit-guard-cancel", "取消关闭并继续编辑",
            "EXIT_GUARD_CANCEL", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
        let canceled = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(cancel, CjguiComposableUiRect(0, 0, 180, 30),
                    CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
        @Assert(canceled.didApply, true)
        if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
            @Assert(snapshot.content, "edited before close")
            @Assert(snapshot.version, 1)
            @Assert(binding.persistedState(snapshot, path), "dirty")
        } else {
            @Assert(false, true)
        }
        @Assert(String.fromUtf8(File.readFrom(path)), "saved baseline")

        let continued = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "continued after cancel")
        @Assert(continued.applied, true)
        @Assert(continued.versionAfter, 2)
        if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
            @Assert(snapshot.content, "continued after cancel")
            @Assert(binding.persistedState(snapshot, path), "dirty")
        } else {
            @Assert(false, true)
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

private class SharedDocumentExitContinuationProbe {
    var accepted: Bool = false
    var calls: Int64 = 0
}

@Test
func dirtyUnboundNotesRequireDiscardAndCannotBorrowDescriptionSave(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    try {
        File.writeTo(Path(path), "bound description".toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "模板笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试", exitGuardEnabled: true)
        let edit = workspace.replaceProjectionTextFromHuman(NOTES_DOCUMENT_ID, "edited unbound notes")
        @Assert(edit.applied, true)
        let probe = SharedDocumentExitContinuationProbe()
        controller.bindHostContinuations(
            {=> false},
            {=> ()},
            {
                =>
                    let retried = controller.requestWindowClose()
                    probe.accepted = retried.shouldClose
                    return retried.shouldClose
            }
        )

        let closeRequest = controller.requestWindowClose()
        @Assert(closeRequest.shouldClose, false)
        let notesSave = cjguiComposableButton(117108, "shared-document-exit-guard-save-notes", "保存", "EXIT_GUARD_SAVE",
            NOTES_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
        let rejectedSave = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(notesSave, CjguiComposableUiRect(0, 0, 80, 30),
                    CjguiComposableUiRect(0, 0, 80, 30)), 27, "", 0, 0, 1))
        @Assert(rejectedSave.didApply, false)
        @Assert(String.fromUtf8(File.readFrom(path)), "bound description")

        let discard = cjguiComposableButton(117109, "shared-document-exit-guard-discard-notes", "明确放弃并继续关闭",
            "EXIT_GUARD_DISCARD", NOTES_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
        let discarded = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(discard, CjguiComposableUiRect(0, 0, 180, 30),
                    CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
        @Assert(discarded.didApply, true)
        @Assert(probe.accepted, true)
        @Assert(String.fromUtf8(File.readFrom(path)), "bound description")
        if (let Some(snapshot) <- workspace.documentSnapshot(NOTES_DOCUMENT_ID)) {
            @Assert(snapshot.content, "edited unbound notes")
            @Assert(snapshot.version, 1)
        } else {
            @Assert(false, true)
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func dirtyDescriptionSaveClosesOnlyAfterTheBoundOwnerIsClean(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    try {
        File.writeTo(Path(path), "original description".toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "模板笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试", exitGuardEnabled: true)
        @Assert(workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "edited description").applied, true)
        let probe = SharedDocumentExitContinuationProbe()
        controller.bindHostContinuations(
            {=> false},
            {=> ()},
            {
                =>
                    let retried = controller.requestWindowClose()
                    probe.accepted = retried.shouldClose
                    return retried.shouldClose
            }
        )

        @Assert(controller.requestWindowClose().shouldClose, false)
        let save = cjguiComposableButton(117110, "shared-document-exit-guard-save-description", "保存后继续关闭",
            "EXIT_GUARD_SAVE", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
        let saved = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(save, CjguiComposableUiRect(0, 0, 180, 30),
                    CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
        @Assert(saved.didApply, true)
        @Assert(probe.accepted, true)
        @Assert(String.fromUtf8(File.readFrom(path)), "edited description")
        if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
            @Assert(snapshot.content, "edited description")
            @Assert(binding.persistedState(snapshot, path), "clean")
        } else {
            @Assert(false, true)
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

private func awaitSharedDocumentGuardProjection(host: CjguiMacosApplicationHost,
    window: CjguiComposableUiWindow, controller: CjguiSharedDocumentController, expectedVisible: Bool,
    requireSaveFailureNotice!: Bool = false): Bool {
    let started = MonoTime.now()
    while (host.isOpen() && (MonoTime.now() - started).toMilliseconds() < 3000) {
        pumpSharedDocumentTurn(host, controller)
        if (!window.refreshIfNeeded()) { continue }
        let projection = window.windowProjection()
        if (projection.acceptedSceneVersion != projection.sceneVersion) { continue }
        let visible = sharedDocumentProjectionNode(projection, "shared-document-exit-guard").nodeId > 0
        let cancelVisible = sharedDocumentProjectionNode(projection, "shared-document-exit-guard-cancel").nodeId > 0
        var saveFailureNoticeVisible = !requireSaveFailureNotice
        if (requireSaveFailureNotice) {
            for (node in window.acceptedSceneNodes()) {
                if (node.semanticId == "shared-document-status" && node.value.startsWith("未保存：")) {
                    saveFailureNoticeVisible = true
                }
            }
        }
        if (visible == expectedVisible && (!expectedVisible || cancelVisible) && saveFailureNoticeVisible) {
            return true
        }
    }
    return false
}

func failedGuardSavePreservesExternalDiskAndDirtyOwnerForCancelBody(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    let diskBaseline = "已保存基线 café 🙂\n第二行。\n"
    let ownerDraft = "A 的未保存正文：owner🙂\n继续。\n"
    let externalDisk = "外部进程新内容 Ω\nrevision 2\n"
    try {
        File.writeTo(Path(path), diskBaseline.toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "模板笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试", exitGuardEnabled: true)
        let edit = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, ownerDraft)
        @Assert(edit.applied, true)
        @Assert(edit.versionAfter, 1)
        let probe = SharedDocumentExitContinuationProbe()
        let host = CjguiMacosApplicationHost(
            controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Shared document failed save test", 700u32, 460u32),
            exitDecisionProvider: Some(controller)
        )
        controller.bindHostContinuations(
            {=> host.requestApplicationExit()},
            {=> host.cancelPendingApplicationExit()},
            {
                =>
                    probe.calls += 1
                    return host.requestClose()
            }
        )
        let window = host.window()
        try {
            @Assert(host.start(), true)
            @Assert(awaitInitialFrame(host, window, controller), true)
            @Assert(controller.requestWindowClose().shouldClose, false)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, true), true)
            @Assert(sharedDocumentProjectionNode(window.windowProjection(), "shared-document-exit-guard").nodeId > 0,
                true)
            File.writeTo(Path(path), externalDisk.toArray())
            let save = cjguiComposableButton(117111, "shared-document-exit-guard-save-description", "保存后继续关闭",
                "EXIT_GUARD_SAVE", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
            let rejectedSave = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(save, CjguiComposableUiRect(0, 0, 180, 30),
                        CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
            @Assert(rejectedSave.didApply, false)
            @Assert(probe.calls, 0)
            @Assert(String.fromUtf8(File.readFrom(path)), externalDisk)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, true,
                requireSaveFailureNotice: true), true)
            @Assert(sharedDocumentProjectionNode(window.windowProjection(), "shared-document-exit-guard-cancel").nodeId > 0,
                true)
            if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
                @Assert(snapshot.content, ownerDraft)
                @Assert(snapshot.version, 1)
                @Assert(binding.persistedState(snapshot, path), "dirty")
            } else {
                @Assert(false, true)
            }

            let cancel = cjguiComposableButton(117112, "shared-document-exit-guard-cancel", "取消关闭并继续编辑",
                "EXIT_GUARD_CANCEL", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
            let canceled = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(cancel, CjguiComposableUiRect(0, 0, 180, 30),
                        CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
            @Assert(canceled.didApply, true)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, false), true)
            @Assert(sharedDocumentProjectionNode(window.windowProjection(), "shared-document-exit-guard").nodeId, -1)
            let continued = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, "取消后继续编辑🙂\n")
            @Assert(continued.applied, true)
            @Assert(continued.versionAfter, 2)
            @Assert(String.fromUtf8(File.readFrom(path)), externalDisk)
            if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
                @Assert(snapshot.content, "取消后继续编辑🙂\n")
                @Assert(snapshot.version, 2)
                @Assert(binding.persistedState(snapshot, path), "dirty")
            } else {
                @Assert(false, true)
            }
        } finally {
            if (host.isOpen()) { host.close() }
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

func canceledWindowCloseRetainsCardEditorOwnerAcrossDifferentSelectionBody(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("description.txt").toString()
    let ownerDraft = "说明卡片的未保存正文🙂\n"
    try {
        File.writeTo(Path(path), "已保存基线\n".toArray())
        let binding = CjguiTextDocumentFileBinding()
        let primary = initialPrimaryDocument(binding, path)
        let workspace = CjguiTextDocumentWorkspace(
            ArrayList<CjguiTextDocument>(
                [
                    primary,
                    CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档", "模板笔记")
                ]
            )
        )
        let controller = CjguiSharedDocumentController(workspace, binding, path, "测试", exitGuardEnabled: true)
        let edit = workspace.replaceProjectionTextFromHuman(DESCRIPTION_DOCUMENT_ID, ownerDraft)
        @Assert(edit.applied, true)
        @Assert(edit.versionAfter, 1)
        let host = CjguiMacosApplicationHost(
            controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Shared document cancel focus test", 700u32, 460u32),
            exitDecisionProvider: Some(controller)
        )
        controller.bindHostContinuations(
            {=> host.requestApplicationExit()},
            {=> host.cancelPendingApplicationExit()},
            {=> host.requestClose()}
        )
        let window = host.window()
        try {
            @Assert(host.start(), true)
            @Assert(awaitInitialFrame(host, window, controller), true)

            let selectNotes = cjguiComposableButton(117113, "shared-document-select-notes-for-card-cancel", "选择笔记",
                "SELECT_DOCUMENT", NOTES_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
            let selected = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(selectNotes, CjguiComposableUiRect(0, 0, 100, 26),
                        CjguiComposableUiRect(0, 0, 100, 26)), 27, "", 0, 0, 1))
            @Assert(selected.didApply, true)
            @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, false), true)

            let openCard = cjguiComposableButton(117114, "shared-document-open-description-card-for-cancel", "编辑说明卡片",
                "OPEN_DOCUMENT_CARD_EDIT", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
            let opened = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(openCard, CjguiComposableUiRect(0, 0, 120, 26),
                        CjguiComposableUiRect(0, 0, 120, 26)), 27, "", 0, 0, 1))
            @Assert(opened.didApply, true)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, false), true)
            let projectionBefore = window.windowProjection()
            let cardDialogBefore = sharedDocumentProjectionNode(projectionBefore,
                "shared-document-card-edit-dialog-${DESCRIPTION_DOCUMENT_ID}")
            let cardEditorBefore = sharedDocumentProjectionNode(projectionBefore, "shared-document-card-editor-content")
            @Assert(cardDialogBefore.nodeId > 0, true)
            @Assert(cardEditorBefore.nodeId > 0, true)
            @Assert(firstResourceId(cardEditorBefore), DESCRIPTION_DOCUMENT_ID)
            let editorNodeId = cardEditorBefore.nodeId
            @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)

            @Assert(controller.requestWindowClose().shouldClose, false)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, true), true)
            let guarded = window.windowProjection()
            let editorUnderGuard = sharedDocumentProjectionNode(guarded, "shared-document-card-editor-content")
            @Assert(sharedDocumentProjectionNode(guarded, "shared-document-exit-guard").nodeId > 0, true)
            @Assert(editorUnderGuard.nodeId, editorNodeId)
            @Assert(firstResourceId(editorUnderGuard), DESCRIPTION_DOCUMENT_ID)
            @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)

            let cancel = cjguiComposableButton(117115, "shared-document-exit-guard-cancel", "取消关闭并继续编辑",
                "EXIT_GUARD_CANCEL", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 30))
            let canceled = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(cancel, CjguiComposableUiRect(0, 0, 180, 30),
                        CjguiComposableUiRect(0, 0, 180, 30)), 27, "", 0, 0, 1))
            @Assert(canceled.didApply, true)
            @Assert(awaitSharedDocumentGuardProjection(host, window, controller, false), true)
            let restored = window.windowProjection()
            let restoredDialog = sharedDocumentProjectionNode(restored,
                "shared-document-card-edit-dialog-${DESCRIPTION_DOCUMENT_ID}")
            let restoredEditor = sharedDocumentProjectionNode(restored, "shared-document-card-editor-content")
            @Assert(sharedDocumentProjectionNode(restored, "shared-document-exit-guard").nodeId, -1)
            @Assert(restoredDialog.nodeId, cardDialogBefore.nodeId)
            @Assert(restoredEditor.nodeId, editorNodeId)
            @Assert(firstResourceId(restoredEditor), DESCRIPTION_DOCUMENT_ID)
            @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)

            let cardContent = cjguiComposableMultilineTextInput(65, "shared-document-card-editor-content", "内容",
                "取消后仍在说明卡片继续编辑🙂\n", DESCRIPTION_DOCUMENT_ID,
                CjguiComposableUiStyle(fixedHeight: 80))
            let continued = controller.applyUiEvent(
                CjguiComposableUiEvent(
                    CjguiComposableUiLayoutNode(cardContent, CjguiComposableUiRect(0, 0, 200, 80),
                        CjguiComposableUiRect(0, 0, 200, 80)), 28, "取消后仍在说明卡片继续编辑🙂\n", 0, 0, 1))
            @Assert(continued.didApply, true)
            if (let Some(snapshot) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
                @Assert(snapshot.content, "取消后仍在说明卡片继续编辑🙂\n")
                @Assert(snapshot.version, 2)
            } else {
                @Assert(false, true)
            }
            @Assert(workspace.selection().documentId, NOTES_DOCUMENT_ID)
        } finally {
            if (host.isOpen()) { host.close() }
        }
    } finally {
        let _ = removeIfExists(directory, recursive: true)
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
    assertSharedDocumentCardProjection(window.windowProjection(), DESCRIPTION_DOCUMENT_ID)
    assertSharedDocumentCardProjection(window.windowProjection(), NOTES_DOCUMENT_ID)

    let cardMenu = cjguiComposableButton(117103, "shared-document-card-menu-7101", "操作", "OPEN_DOCUMENT_CARD_MENU",
        DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
    let cardMenuEvent = controller.applyUiEvent(
        CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(cardMenu, CjguiComposableUiRect(0, 0, 80, 26), CjguiComposableUiRect(0, 0, 80,
                26)), 27, "", 0, 0, 1))
    @Assert(cardMenuEvent.didApply, true)
    @Assert(window.refresh(), true)
    let openedCardMenu = sharedDocumentProjectionNode(window.windowProjection(), "shared-document-card-menu-7101")
    @Assert(openedCardMenu.nodeId > 0, true)
    let cardEdit = cjguiComposableButton(117104, "shared-document-card-edit-7101", "编辑", "OPEN_DOCUMENT_CARD_EDIT",
        DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 26))
    let cardEditEvent = controller.applyUiEvent(
        CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(cardEdit, CjguiComposableUiRect(0, 0, 80, 26), CjguiComposableUiRect(0, 0, 80,
                26)), 27, "", 0, 0, 1))
    @Assert(cardEditEvent.didApply, true)
    @Assert(window.refresh(), true)
    let openedCardDialog = sharedDocumentProjectionNode(window.windowProjection(),
        "shared-document-card-edit-dialog-7101")
    @Assert(openedCardDialog.nodeId > 0, true)
    let cardContent = cjguiComposableMultilineTextInput(65, "shared-document-card-editor-content", "内容",
        "更新后的说明", DESCRIPTION_DOCUMENT_ID, CjguiComposableUiStyle(fixedHeight: 80))
    let cardContentEvent = controller.applyUiEvent(
        CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(cardContent, CjguiComposableUiRect(0, 0, 200, 80),
                CjguiComposableUiRect(0, 0, 200, 80)), 28, "更新后的说明", 0, 0, 1))
    @Assert(cardContentEvent.didApply, true)
    if (let Some(updatedDescription) <- workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
        @Assert(updatedDescription.content, "更新后的说明")
    } else {
        @Assert(false, true)
    }
    @Assert(window.refresh(), true)

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
    assertSharedDocumentCardProjection(window.windowProjection(), NOTES_DOCUMENT_ID)

    // Reorder the source while keeping the selected/focused business key.
    // The next accepted scene must retain the same action targets rather than
    // binding them to the row's new display position.
    controller.reverseDocumentOrder()
    @Assert(window.refresh(), true)
    let reordered = window.windowProjection()
    assertSharedDocumentActionProjection(reordered, NOTES_DOCUMENT_ID)
    assertSharedDocumentCardProjection(reordered, NOTES_DOCUMENT_ID)
    let selectedRow = sharedDocumentProjectionNode(reordered, "shared-document-select-7102")
    @Assert(selectedRow.nodeId > 0, true)
    @Assert(firstResourceId(selectedRow), NOTES_DOCUMENT_ID)
    @Assert(controller.focusedDocumentKeyForTest(), "document_7102")
    window.close()
}

/// D: a typed request that carries its OWN identity and the monotonic instant it
/// became ready. It waits in the consumer's queue until a later turn applies it
/// through the same owner entry the native text-change event uses, so the
/// measured owner latency includes a real queue wait instead of being a
/// synchronous write performed during measurement. The marker is written into
/// the document content, so the accepted scene can be checked for EXACTLY this
/// request's content rather than only "something grew".
private class CjguiSharedTypedRequest {
    let requestId: String
    let marker: String
    let readyAt: MonoTime
    let readyTurn: Int64

    init(requestId: String, marker: String, readyAt: MonoTime, readyTurn: Int64) {
        this.requestId = requestId
        this.marker = marker
        this.readyAt = readyAt
        this.readyTurn = readyTurn
    }
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
    private let responseEffectMode: String
    private var localRevision: Int64
    // P1/P2 same-host evidence: the primary view carries a real shadow +
    // gradient node whose paint alpha is animated through the public window
    // entry, so the multi-window resource/ownership story includes effects.
    private var effectWindow: ?CjguiComposableUiWindow = None
    private var effectPhaseHigh: Bool = false
    private var effectSummary: String = "效果节点：阴影 + 渐变（动效就绪）"
    private var effectGroupOpacity: Float64 = 1.0
    // D: queued typed requests that carry their own identity. Applied at most
    // one per turn through the owner path, so the queue wait is part of the
    // observed owner latency.
    private let typedRequestQueue = ArrayList<CjguiSharedTypedRequest>()
    private var lastTypedRequestId: String = ""
    private var lastTypedRequestMarker: String = ""
    private var lastTypedRequestReadyAt: ?MonoTime = None
    private var lastTypedRequestOwnerMs: Int64 = -1
    private var lastTypedRequestReadyTurn: Int64 = -1

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64, viewName: String, viewSemanticId: String,
        responseEffectMode!: String = "static") {
        this.workspace = workspace
        this.documentId = documentId
        this.viewName = viewName
        this.viewSemanticId = viewSemanticId
        this.responseEffectMode = responseEffectMode
        this.localRevision = 1
    }

    /// The three comparison legs retain the exact same effect node content.
    /// Only the group declaration differs: absent, static, or driven opacity.
    private func responseEffectGroup(): ?CjguiComposableUiEffectGroup {
        if (!viewSemanticId.startsWith("primary") || responseEffectMode == "no_effect") {
            return None
        }
        return Some(CjguiComposableUiEffectGroup(opacity: effectGroupOpacity, blendMode: "normal", mask: None))
    }

    public func effectGroupDeclared(): Bool {
        return responseEffectGroup().isSome()
    }

    public func effectGroupOpacityValue(): Float64 {
        return effectGroupOpacity
    }

    /// Change only the public EffectGroup opacity between accepted scene builds.
    /// The response workload calls this once per A/B turn in active mode.
    public func tickEffectGroupOpacity(): Bool {
        if (!viewSemanticId.startsWith("primary") || responseEffectMode != "active") {
            return false
        }
        // Keep the group's leg visually distinct from the separate P3 node
        // animation that this workload retains for the real AX control check.
        effectGroupOpacity = if (effectGroupOpacity < 1.0) { 1.0 } else { 0.55 }
        localRevision = localRevision.saturatingAdd(1)
        return true
    }

    /// Attach the exact window this view was opened for, so the effect node is
    /// addressed in THIS window's accepted scene (never a sibling's).
    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        effectWindow = Some(window)
    }

    /// Drive the primary view's effect node through the public paint-alpha entry
    /// once, returning a greppable observation. Used by the multi-window run so
    /// the same-host scenario carries a real animation fact.
    public func driveEffectProbe(): String {
        let identity = "semantic:shared-document-multi-effect-${viewSemanticId}"
        let window = match (effectWindow) {
            case Some(value) => value
            case None => return "window=none"
        }
        let started = window.animateNodeOpacity(identity, 0.35,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 120,
                easing: CjguiComposableUiAnimationEasing.EASE_OUT), atTime: MonoTime.now())
        let presented = match (window.animatedNodeOpacity(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        return "view=${viewSemanticId} identity=${identity} started=${if (started) { 1 } else { 0 }} " +
            "target=0.350000 presented=${presented} active=${window.activeAnimationCount()} " +
            "bindings=${window.animationBindingCount()}"
    }

    /// D: enqueue a typed request carrying its own identity. It is applied on a
    /// LATER turn, so the queue wait is included in the owner latency.
    public func enqueueTypedRequest(requestId: String, marker: String, readyTurn: Int64): Bool {
        if (requestId.size == 0 || marker.size == 0 || typedRequestQueue.size >= 16) {
            return false
        }
        typedRequestQueue.add(CjguiSharedTypedRequest(requestId, marker, MonoTime.now(), readyTurn))
        return true
    }

    public func queuedTypedRequestCount(): Int64 {
        return typedRequestQueue.size
    }

    /// Apply exactly one queued typed request through the same owner entry the
    /// native text-change event uses. Returns the request identity, or "" when
    /// the queue is empty or the owner refused the edit.
    public func applyNextTypedRequest(): String {
        if (typedRequestQueue.size == 0) {
            return ""
        }
        let request = typedRequestQueue.remove(at: 0)
        let version = humanAppendText(request.marker)
        if (version < 0) {
            return ""
        }
        lastTypedRequestId = request.requestId
        lastTypedRequestMarker = request.marker
        lastTypedRequestReadyAt = Some(request.readyAt)
        lastTypedRequestReadyTurn = request.readyTurn
        lastTypedRequestOwnerMs = (MonoTime.now() - request.readyAt).toMilliseconds()
        return request.requestId
    }

    public func lastTypedRequestIdentity(): String {
        return lastTypedRequestId
    }

    public func lastTypedRequestMarkerValue(): String {
        return lastTypedRequestMarker
    }

    public func lastTypedRequestOwnerLatencyMs(): Int64 {
        return lastTypedRequestOwnerMs
    }

    /// The monotonic instant the last-applied request became ready; the caller
    /// uses it to measure the remaining ready -> accepted-scene latency.
    public func lastTypedRequestReadyAtValue(): ?MonoTime {
        return lastTypedRequestReadyAt
    }

    public func lastTypedRequestReadyTurnValue(): Int64 {
        return lastTypedRequestReadyTurn
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
        // The effect card and its real control are present in every comparison
        // leg. The accepted group declaration alone distinguishes no-effect,
        // static-effect and active-group-opacity runs.
        if (viewSemanticId.startsWith("primary")) {
            let effectNode = cjguiComposableVertical(6, "shared-document-multi-effect-${viewSemanticId}",
                CjguiComposableUiStyle(fixedHeight: 56, growX: 1, padding: 8, cornerRadius: 10,
                    background: CjguiComposableUiColor(0.16, 0.20, 0.30, 1.0), textColor: theme.body.textColor,
                    gradient: Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
                        stops: [
                            CjguiComposableUiGradientStop(position: 0.0,
                                color: CjguiComposableUiColor(0.11, 0.31, 0.57, 1.0)),
                            CjguiComposableUiGradientStop(position: 1.0,
                                color: CjguiComposableUiColor(0.25, 0.66, 0.96, 1.0))
                        ])),
                    shadow: Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.02, 0.04, 0.10, 0.85),
                        offsetX: 0, offsetY: 10, blurRadius: 12, spread: 2)),
                    effectGroup: responseEffectGroup()))
            effectNode.add(cjguiComposableText(7, "shared-document-multi-effect-label-${viewSemanticId}",
                effectSummary, theme.body))
            root.add(effectNode)
            root.add(cjguiComposableButton(8, "shared-document-multi-effect-toggle-${viewSemanticId}",
                "动效过渡", "ANIMATE_VIEW_OPACITY", 0,
                CjguiComposableUiStyle(fixedHeight: 30, background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
                    border: CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0), textColor: theme.body.textColor)))
        }
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
        if (event.eventKind == 27 && event.node.actionName == "ANIMATE_VIEW_OPACITY") {
            effectPhaseHigh = !effectPhaseHigh
            let target: Float64 = if (effectPhaseHigh) { 1.0 } else { 0.3 }
            let identity = "semantic:shared-document-multi-effect-${viewSemanticId}"
            let window = match (effectWindow) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let started = window.animateNodeOpacity(identity, target,
                spec: CjguiComposableUiAnimationSpec.tween(durationMs: 160,
                    easing: CjguiComposableUiAnimationEasing.EASE_IN_OUT), atTime: MonoTime.now())
            let presented = match (window.animatedNodeOpacity(identity)) {
                case Some(value) => value
                case None => -1.0
            }
            effectSummary = "动效 目标=${target} 当前=${presented}"
            localRevision = localRevision.saturatingAdd(1)
            getStdOut().writeln("CJGUI_MULTI_WINDOW_ANIMATION_STATE view=${viewSemanticId} identity=${identity} " +
                "started=${if (started) { 1 } else { 0 }} target=${target} presented=${presented} " +
                "active=${window.activeAnimationCount()} bindings=${window.animationBindingCount()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(started)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        localRevision = localRevision.saturatingAdd(1)
        return CjguiComposableUiDispatchResult(false)
    }

    /// Keep this view's effect animation live for one application turn. A
    /// retarget from the current presented value followed by an explicit-clock
    /// advance keeps the channel active across the whole response run, so A is
    /// continuously animating while B is being typed into.
    public func tickEffectAnimation(): String {
        let window = match (effectWindow) {
            case Some(value) => value
            case None => return "window=none"
        }
        let atTime = MonoTime.now()
        let identity = "semantic:shared-document-multi-effect-${viewSemanticId}"
        effectPhaseHigh = !effectPhaseHigh
        let target: Float64 = if (effectPhaseHigh) { 1.0 } else { 0.3 }
        let started = window.animateNodeOpacity(identity, target,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 240,
                easing: CjguiComposableUiAnimationEasing.EASE_IN_OUT), atTime: atTime)
        let advanced = window.advanceAnimations(atTime: atTime)
        return "view=${viewSemanticId} identity=${identity} started=${if (started) { 1 } else { 0 }} " +
            "target=${target} active=${window.activeAnimationCount()} advanced=${if (advanced) { 1 } else { 0 }}"
    }

    public func activeEffectAnimationCount(): Int64 {
        return match (effectWindow) {
            case Some(window) => window.activeAnimationCount()
            case None => 0
        }
    }

    /// Simulate a person typing this snippet into the view's editor. The text is
    /// submitted through the same owner method the native text-change event
    /// uses, so the owner version and this window's accepted scene both have to
    /// advance for the input to be observed. Returns the owner version after
    /// the edit, or -1 when the document is unavailable/closed.
    public func humanAppendText(snippet: String): Int64 {
        let current = match (workspace.documentSnapshot(documentId)) {
            case Some(snapshot) => snapshot.content
            case None => return -1
        }
        let result = workspace.replaceProjectionTextFromHuman(documentId, current + snippet)
        if (!result.applied) { return -1 }
        localRevision = localRevision.saturatingAdd(1)
        return match (workspace.documentSnapshot(documentId)) {
            case Some(snapshot) => snapshot.version
            case None => -1
        }
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        // P2: closing THIS view cancels only its own effect binding; a sibling
        // view keeps its own bindings and input.
        if (let Some(window) <- effectWindow) {
            let identity = "semantic:shared-document-multi-effect-${viewSemanticId}"
            let cancelled = window.cancelNodeOpacityAnimation(identity)
            getStdOut().writeln("CJGUI_MULTI_WINDOW_ANIMATION_CANCELLED view=${viewSemanticId} " +
                "cancelled=${if (cancelled) { 1 } else { 0 }} active=${window.activeAnimationCount()}")
            getStdOut().flush()
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func authorization(
    includeSingleWindowReads!: Bool = true,
    includeTargetedWindowReads!: Bool = false,
    staticallyEditable!: Bool = true
): CjguiSharedOperationExternalAuthorization {
    let editableTargets = if (staticallyEditable) {
        ArrayList<Int64>([DESCRIPTION_DOCUMENT_ID, NOTES_DOCUMENT_ID])
    } else {
        // The single-window lifecycle grants editable actions per live
        // document so closing one document can retire exactly its grants.
        ArrayList<Int64>()
    }
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
    // Lifecycle open consumes only application-queued paths; close is granted
    // per exact live document and revoked when that document retires.
    scopes.add(CjguiSharedOperationExternalActionScope("OPEN_DOCUMENT", ArrayList<Int64>(), false))
    scopes.add(CjguiSharedOperationExternalActionScope("CLOSE_DOCUMENT", ArrayList<Int64>(), false))
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

private func sharedDocumentTitleForPath(path: String): String {
    let parts = path.split("/")
    var title = path
    if (parts.size > 0 && parts[parts.size - 1].size > 0) {
        title = parts[parts.size - 1]
    }
    return title
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
    /// Opt-in response workload: A's effect animation is driven every turn while
    /// B keeps taking text through the owner path, and each turn records the
    /// owner/accepted latency. Requires --multi-window.
    let recordsResponseWorkload: Bool
    let responseEffectMode: String
    let responseInputIntervalTurns: Int64
    let responsePublicClientOnly: Bool
    let extraOpenPaths: ArrayList<String>

    init(filePath: String, enablesExternalConnection: Bool, expectsConnectionStartFailure: Bool,
        opensMultipleWindows: Bool, measurementDurationMs: Int64, measurementWarmupMs: Int64,
        closeFirstWindowAfterMs: Int64, recordsTurnObservations: Bool, reopensFirstWindowAfterClose: Bool,
        recordsResponseWorkload: Bool, responseEffectMode: String, responseInputIntervalTurns: Int64,
        responsePublicClientOnly: Bool, extraOpenPaths: ArrayList<String>) {
        this.filePath = filePath
        this.enablesExternalConnection = enablesExternalConnection
        this.expectsConnectionStartFailure = expectsConnectionStartFailure
        this.opensMultipleWindows = opensMultipleWindows
        this.measurementDurationMs = measurementDurationMs
        this.measurementWarmupMs = measurementWarmupMs
        this.closeFirstWindowAfterMs = closeFirstWindowAfterMs
        this.recordsTurnObservations = recordsTurnObservations
        this.reopensFirstWindowAfterClose = reopensFirstWindowAfterClose
        this.recordsResponseWorkload = recordsResponseWorkload
        this.responseEffectMode = responseEffectMode
        this.responseInputIntervalTurns = responseInputIntervalTurns
        this.responsePublicClientOnly = responsePublicClientOnly
        this.extraOpenPaths = ArrayList<String>(extraOpenPaths)
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
    var recordsResponseWorkload = false
    var responsePublicClientOnly = false
    var responseEffectMode = "active"
    var extraOpenPaths = ArrayList<String>()
    var responseInputIntervalTurns: Int64 = 2
    var hasResponseInputInterval = false
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
        } else if (args[index] == "--open-extra" && index + 1 < args.size && args[index + 1].size > 0) {
            extraOpenPaths.add(args[index + 1])
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
        } else if (args[index] == "--multi-window-response" && !recordsResponseWorkload) {
            recordsResponseWorkload = true
            index += 1
        } else if (args[index] == "--response-public-client" && !responsePublicClientOnly) {
            responsePublicClientOnly = true
            index += 1
        } else if (args[index] == "--response-effect-mode" && index + 1 < args.size && responseEffectMode == "active") {
            let mode = args[index + 1]
            if (mode != "no_effect" && mode != "static" && mode != "active") { return None }
            responseEffectMode = mode
            index += 2
        } else if (args[index] == "--response-input-interval-turns" && index + 1 < args.size &&
            !hasResponseInputInterval) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value < 1 || value > 120) { return None }
                responseInputIntervalTurns = value
                hasResponseInputInterval = true
            } else {
                return None
            }
            index += 2
        } else {
            return None
        }
    }
    if ((responsePublicClientOnly && (!opensMultipleWindows || !recordsResponseWorkload || !enablesExternalConnection)) ||
        (hasCloseFirstWindowAfter && !opensMultipleWindows) || (recordsTurnObservations && !opensMultipleWindows) || (reopensFirstWindowAfterClose &&
        (!opensMultipleWindows || !hasCloseFirstWindowAfter)) || (hasCloseFirstWindowAfter &&
        expectsConnectionStartFailure) || (recordsResponseWorkload && !opensMultipleWindows) ||
        (responseEffectMode != "active" && !recordsResponseWorkload) ||
        (hasResponseInputInterval && !recordsResponseWorkload) ||
        (extraOpenPaths.size > 0 && opensMultipleWindows)) {
        return None
    }
    return Some(
        CjguiSharedDocumentLaunchOptions(filePath, enablesExternalConnection, expectsConnectionStartFailure,
            opensMultipleWindows, measurementDurationMs, measurementWarmupMs, closeFirstWindowAfterMs,
            recordsTurnObservations, reopensFirstWindowAfterClose, recordsResponseWorkload, responseEffectMode,
            responseInputIntervalTurns, responsePublicClientOnly, extraOpenPaths))
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
    recordsTurnObservations: Bool, reopensFirstWindowAfterClose: Bool, recordsResponseWorkload: Bool,
    responseEffectMode: String, responseInputIntervalTurns: Int64, responsePublicClientOnly: Bool): Int32 {
    let fileBinding = CjguiTextDocumentFileBinding()
    let primary = initialPrimaryDocument(fileBinding, path)
    let notes = CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档",
        "这是一份独立文档；在多窗口中不会因说明文档的编辑而重建。")
    let archive = CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，但不授予远程内容范围读取或替换。")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([primary, notes, archive]))
    let application = CjguiMacosApplication(maximumWindowCount: 4)
    // Same-host views share the workspace but keep separate controller/view
    // identities; A owns the effect node, both share the one owner document.
    let controllerA = CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID, "说明主视图", "primary",
        responseEffectMode: responseEffectMode)
    let controllerB = CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID, "说明审阅视图", "review")
    var activeConnection: ?CjguiSharedOperationExternalConnection = None
    var servicedExternalActions: Int64 = 0
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI Shared Document", 900u32, 580u32)
    let openedA = application.openWindow(
        controllerA,
        configuration: configuration)
    let openedB = application.openWindow(
        controllerB,
        configuration: configuration)
    let openedC = application.openWindow(
        CjguiSharedDocumentMultiWindowController(workspace, NOTES_DOCUMENT_ID, "笔记视图", "notes"),
        configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen || !openedC.didOpen || application.windowIdentifiers().size != 3) {
        application.close()
        return 1
    }
    // Bind each controller to its OWN window so an effect on the primary view
    // can only ever address that window's accepted scene.
    if (let Some(identifierA) <- openedA.identifier) {
        if (let Some(windowA) <- application.window(identifierA)) {
            controllerA.attachWindow(windowA)
        }
    }
    if (let Some(identifierB) <- openedB.identifier) {
        if (let Some(windowB) <- application.window(identifierB)) {
            controllerB.attachWindow(windowB)
        }
    }
    // The response workload exposes A's published control for supervised
    // input. Bring A above the review/notes windows once, before measuring B.
    if (recordsResponseWorkload) {
        if (let Some(identifierA) <- openedA.identifier) {
            if (let Some(windowA) <- application.window(identifierA)) {
                let front = windowA.activateWindow()
                var key = false
                var mainWindow = false
                var appActive = false
                if (let Some(state) <- windowA.windowActivationState()) {
                    let (isKey, isMain, isActive) = state
                    key = isKey
                    mainWindow = isMain
                    appActive = isActive
                }
                getStdOut().writeln("CJGUI_MULTI_WINDOW_RESPONSE_PRIMARY_ACTIVATION accepted=${front} key=${key} main=${mainWindow} app_active=${appActive}")
                getStdOut().flush()
                if (!front) {
                    application.close()
                    return 1
                }
            }
        }
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
    var pumpedTurns: Int64 = 0
    // Response workload bookkeeping: A keeps its selected EffectGroup mode, B
    // keeps taking text, and each submitted input is timed through acceptance.
    var bInputCount: Int64 = 0
    var pendingInputTurn: Int64 = -1
    var pendingBaseScene: Int64 = -1
    var lastLatencyTurns: Int64 = -1
    var acceptedInputCount: Int64 = 0
    var maxLatencyTurns: Int64 = -1
    var bProgressAfterCloseTurns: Int64 = 0
    var aAnimationActiveTurns: Int64 = 0
    var aEffectGroupActiveTurns: Int64 = 0
    // D: identity-carrying request bookkeeping. `pendingRequestMarker` is the
    // exact content a queued request wrote, so the accepted scene check proves
    // THIS request's content was accepted (not merely that something changed).
    var bQueuedRequests: Int64 = 0
    var pendingRequestMarker: String = "-"
    var pendingRequestReadyAt: ?MonoTime = None
    var requestOwnerLatencyMs: Int64 = -1
    var requestSceneLatencyMs: Int64 = -1
    var maxRequestSceneMs: Int64 = -1
    var acceptedIdentityChecks: Int64 = 0
    // Keep A's ordinary animation active while the external public client
    // owns and measures its writes; this mode creates no internal typing.
    let responseRequestLimit: Int64 = if (responsePublicClientOnly) { 0 } else { 120 }
    if (responsePublicClientOnly) {
        output.writeln("CJGUI_MULTI_WINDOW_PUBLIC_CLIENT ready=true internal_requests=0 cpu_stage_observation=unavailable")
        output.flush()
    }
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
                    let reopenedController = CjguiSharedDocumentMultiWindowController(workspace, DESCRIPTION_DOCUMENT_ID,
                        "说明重建视图", "primary-reopened")
                    let reopened = application.openWindow(reopenedController, configuration: configuration)
                    if (!reopened.didOpen) {
                        application.close()
                        return 1
                    }
                    if (let Some(reopenedIdentifier) <- reopened.identifier) {
                        if (let Some(reopenedWindow) <- application.window(reopenedIdentifier)) {
                            reopenedController.attachWindow(reopenedWindow)
                        }
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
        // --- opt-in response workload (before the turn is pumped) ----------
        var responseInputSubmitted = false
        var responseAState = "disabled"
        if (recordsResponseWorkload) {
            // All legs keep the same A effect node, controls and B owner/scene
            // workload. Only its EffectGroup declaration is absent, static, or
            // actively changing opacity.
            if (let Some(identifierA) <- openedA.identifier) {
                if (application.window(identifierA).isSome()) {
                    responseAState = if (responseEffectMode == "active") {
                        controllerA.tickEffectAnimation()
                    } else {
                        responseEffectMode
                    }
                    if (controllerA.tickEffectGroupOpacity()) {
                        aEffectGroupActiveTurns += 1
                    }
                    if (controllerA.activeEffectAnimationCount() > 0) {
                        aAnimationActiveTurns += 1
                    }
                }
            }
            // B: enqueue one identity-carrying typed request every few turns, and
            // apply at most one PREVIOUSLY queued request before this turn's pump.
            // The request therefore waits in a real queue; the applied marker is
            // written into the owner, so the accepted scene can be checked for
            // EXACTLY this request's content.
            if (controllerB.applyNextTypedRequest().size > 0) {
                if (let Some(identifierB) <- openedB.identifier) {
                    if (let Some(windowB) <- application.window(identifierB)) {
                        pendingBaseScene = windowB.windowProjection().sceneVersion
                    }
                }
                pendingRequestMarker = controllerB.lastTypedRequestMarkerValue()
                pendingRequestReadyAt = controllerB.lastTypedRequestReadyAtValue()
                requestOwnerLatencyMs = controllerB.lastTypedRequestOwnerLatencyMs()
                requestSceneLatencyMs = -1
                bInputCount += 1
                pendingInputTurn = controllerB.lastTypedRequestReadyTurnValue()
                responseInputSubmitted = true
            }
            // Enqueue after this turn's dequeue. Even the first request must
            // spend one complete application turn ready before owner apply.
            if (bQueuedRequests < responseRequestLimit && observedTurnIndex % responseInputIntervalTurns == 0) {
                let requestNumber = bQueuedRequests + 1
                let marker = "#${requestNumber}#"
                if (controllerB.enqueueTypedRequest("req-${requestNumber}", marker, observedTurnIndex)) {
                    bQueuedRequests += 1
                }
            }
        }
        let turn = application.pumpOneTurn()
        servicedExternalActions += turn.externalActionCount
        pumpedTurns += 1
        if (pumpedTurns == 2 && (!recordsResponseWorkload || responseEffectMode == "active")) {
            // P2: one real animation drive on the primary view only. A sibling
            // window is not touched, and closing A later leaves B's input intact.
            output.writeln("CJGUI_MULTI_WINDOW_ANIMATION_VERIFY ${controllerA.driveEffectProbe()}")
            output.flush()
        }
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
        }
        if (recordsResponseWorkload) {
            var responseBScene: Int64 = -1
            var responseBSubmit: Int64 = -1
            if (let Some(identifierB) <- openedB.identifier) {
                if (let Some(windowB) <- application.window(identifierB)) {
                    let projectionB = windowB.windowProjection()
                    responseBScene = projectionB.sceneVersion
                    responseBSubmit = projectionB.nativeSubmissionCount
                }
            }
            let ownerVersion = match (workspace.documentSnapshot(DESCRIPTION_DOCUMENT_ID)) {
                case Some(snapshot) => snapshot.version
                case None => -1
            }
            // The queued request's EXACT content reached B's accepted scene this
            // turn, so this request's identity is verified, not just "something
            // grew". Both the turn latency and the monotonic ready -> scene ms
            // are recorded.
            if (pendingInputTurn >= 0 && responseBScene > pendingBaseScene) {
                var acceptedText = ""
                if (let Some(identifierB) <- openedB.identifier) {
                    if (let Some(windowB) <- application.window(identifierB)) {
                        // An editable control's displayed content is its accepted
                        // VALUE; the label is only the accessible caption.
                        acceptedText = match (windowB.acceptedNodeValue("shared-document-multi-editor-review")) {
                            case Some(value) => value
                            case None => ""
                        }
                    }
                }
                if (acceptedText.contains(pendingRequestMarker)) {
                    lastLatencyTurns = observedTurnIndex - pendingInputTurn
                    acceptedInputCount += 1
                    acceptedIdentityChecks += 1
                    if (lastLatencyTurns > maxLatencyTurns) { maxLatencyTurns = lastLatencyTurns }
                    requestSceneLatencyMs = match (pendingRequestReadyAt) {
                        case Some(readyAt) => (MonoTime.now() - readyAt).toMilliseconds()
                        case None => -1
                    }
                    if (requestSceneLatencyMs > maxRequestSceneMs) { maxRequestSceneMs = requestSceneLatencyMs }
                    pendingInputTurn = -1
                }
            }
            // After A closes, count turns in which B still accepts submitted
            // input (its accepted scene keeps advancing without A).
            if (firstWindowCloseRequested && responseInputSubmitted && responseBScene > pendingBaseScene) {
                bProgressAfterCloseTurns += 1
            }
            output.writeln(
                "CJGUI_MULTI_WINDOW_RESPONSE index ${observedTurnIndex} effect_mode ${responseEffectMode} a_closed ${if (firstWindowCloseRequested) { 1 } else { 0 }} a_active ${controllerA.activeEffectAnimationCount()} a_animation_state ${responseAState} a_group_declared ${if (controllerA.effectGroupDeclared()) { 1 } else { 0 }} a_group_opacity ${controllerA.effectGroupOpacityValue()} a_group_active_turns ${aEffectGroupActiveTurns} owner_version ${ownerVersion} b_scene ${responseBScene} b_submit ${responseBSubmit} b_inputs ${bInputCount} b_queued ${bQueuedRequests} req_owner_ms ${requestOwnerLatencyMs} req_scene_ms ${requestSceneLatencyMs} req_marker ${pendingRequestMarker} submitted_now ${if (responseInputSubmitted) { 1 } else { 0 }} latency_turns ${lastLatencyTurns}")
            output.flush()
        }
        if (recordsTurnObservations || recordsResponseWorkload) {
            observedTurnIndex += 1
        }
    }
    if (closeFirstWindowAfterMs > 0 && !firstWindowCloseRequested) {
        application.close()
        return 1
    }
    if (recordsResponseWorkload) {
        // Response summary: A's animation stayed active across turns, every
        // submitted B input was observed by B's accepted scene, and B kept
        // accepting after A closed.
        let responseHeld = bInputCount == responseRequestLimit && acceptedInputCount == responseRequestLimit &&
            acceptedIdentityChecks >= bInputCount &&
            (if (responseEffectMode == "active") { aAnimationActiveTurns > 0 }
                else { aAnimationActiveTurns == 0 }) &&
            (if (responseEffectMode == "active") { aEffectGroupActiveTurns > 0 }
                else { aEffectGroupActiveTurns == 0 }) &&
            (closeFirstWindowAfterMs == 0 || (firstWindowCloseRequested && bProgressAfterCloseTurns > 0))
        output.writeln(
            "CJGUI_MULTI_WINDOW_RESPONSE_SUMMARY effect_mode ${responseEffectMode} inputs ${bInputCount} accepted ${acceptedInputCount} identity_checked ${acceptedIdentityChecks} queued ${bQueuedRequests} max_latency_turns ${maxLatencyTurns} max_req_scene_ms ${maxRequestSceneMs} last_req_owner_ms ${requestOwnerLatencyMs} a_animation_active_turns ${aAnimationActiveTurns} a_effect_group_active_turns ${aEffectGroupActiveTurns} after_close_accept_turns ${bProgressAfterCloseTurns} closed ${if (firstWindowCloseRequested) { 1 } else { 0 }} held ${responseHeld}")
        output.flush()
        if (!responseHeld) {
            application.close()
            return 1
        }
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

// Host start accepts Preparing as well as Ready. Progress through its normal
// pump instead of treating an unsubmitted first frame as a closed window.
private func pumpSharedDocumentTurn(host: CjguiMacosApplicationHost, controller: CjguiSharedDocumentController): Unit {
    let _ = host.pumpOneTurn()
    if (controller.takePendingLocalCloseRequest() && !host.requestClose()) {
        controller.reportLocalCloseRequestRejected()
    }
}

private func awaitInitialFrame(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    controller: CjguiSharedDocumentController): Bool {
    let started = MonoTime.now()
    while (host.isOpen() && (MonoTime.now() - started).toMilliseconds() < 5000) {
        let projection = window.windowProjection()
        if (projection.isActive && projection.sessionIdentity.size > 0 && projection.submittedFrameIndex > 0) {
            return true
        }
        pumpSharedDocumentTurn(host, controller)
    }
    return false
}

private func runWindow(path: String, enablesExternalConnection: Bool, expectsConnectionStartFailure: Bool,
    measurementDurationMs: Int64, measurementWarmupMs: Int64,
    extraOpenPaths: ArrayList<String>): Int32 {
    let fileBinding = CjguiTextDocumentFileBinding()
    let primary = initialPrimaryDocument(fileBinding, path)
    let notes = CjguiTextDocument(NOTES_DOCUMENT_ID, "笔记文档",
        "这是一份独立文档；切换、撤销和外部版本校验均不串到说明。")
    let archive = CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，但不授予远程内容范围读取或替换。")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([primary, notes, archive]))
    let _ = workspace.attachFileBindingFromHuman(DESCRIPTION_DOCUMENT_ID, fileBinding, path)
    let startupStatus = if (path.size == 0) {
        "编辑后可用 --file PATH 启动受控保存"
    } else if (exists(path)) {
        "已打开受控文件 ${path}"
    } else {
        "新文档将保存到 ${path}"
    }
    let controller = CjguiSharedDocumentController(workspace, fileBinding, path, startupStatus,
        exitGuardEnabled: true, openPaths: extraOpenPaths)
    let _ = workspace.attachLifecycleDomainFromHuman(controller)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Shared Document", 980u32, 620u32),
        exitDecisionProvider: Some(controller)
    )
    controller.bindHostContinuations(
        {=> host.requestApplicationExit()},
        {=> host.cancelPendingApplicationExit()},
        {=> host.requestClose()}
    )
    let window = host.window()
    // The controller's participant supplies these semantic commands with the
    // scene candidate.  Host startup therefore cannot publish shortcuts that
    // point at a scene native has not accepted.
    if (enablesExternalConnection) {
        let connectionAuthorization = if (expectsConnectionStartFailure) {
            CjguiSharedOperationExternalAuthorization("", "", ArrayList<CjguiSharedOperationExternalActionScope>())
        } else {
            authorization(staticallyEditable: false)
        }
        controller.bindDocumentOpenedObserver { documentId =>
            for (action in ["READ_RANGE", "INSERT_TEXT", "DELETE_RANGE", "REPLACE_RANGE",
                "REPLACE_RANGES", "SET_PREVIEW_LIMIT", "CLOSE_DOCUMENT"]) {
                let _ = connectionAuthorization.grantResource(action, documentId)
            }
        }
        controller.bindDocumentClosedObserver { documentId =>
            for (action in ["READ_RANGE", "INSERT_TEXT", "DELETE_RANGE", "REPLACE_RANGE",
                "REPLACE_RANGES", "SET_PREVIEW_LIMIT", "CLOSE_DOCUMENT"]) {
                let _ = connectionAuthorization.revokeResource(action, documentId)
            }
        }
        for (summary in workspace.openDocumentSummaries()) {
            if (summary.documentId != READ_ONLY_ARCHIVE_ID) {
                for (action in ["READ_RANGE", "INSERT_TEXT", "DELETE_RANGE", "REPLACE_RANGE",
                    "REPLACE_RANGES", "SET_PREVIEW_LIMIT"]) {
                    let _ = connectionAuthorization.grantResource(action, summary.documentId)
                }
            }
            let _ = connectionAuthorization.grantResource("CLOSE_DOCUMENT", summary.documentId)
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
            if (!awaitInitialFrame(host, window, controller)) {
                output.flush();
                host.close();
                return 1
            }
            let projection = window.windowProjection()
            output.writeln(
                "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY ${projection.sessionIdentity} ${projection.submittedFrameIndex}")
            output.flush()
        }
        let warmupStarted = MonoTime.now()
        while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < measurementWarmupMs) {
            pumpSharedDocumentTurn(host, controller)
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
            pumpSharedDocumentTurn(host, controller)
        }
    } else {
        if (!host.start()) {
            host.close();
            return 1
        }
        let output = getStdOut();
        if (!awaitInitialFrame(host, window, controller)) {
            output.flush();
            host.close();
            return 1
        }
        let initialProjection = window.windowProjection()
        output.writeln(
            "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY ${initialProjection.sessionIdentity} ${initialProjection.submittedFrameIndex}")
        output.flush()
        let warmupStarted = MonoTime.now()
        while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < measurementWarmupMs) {
            pumpSharedDocumentTurn(host, controller)
        }
        if (host.isOpen()) {
            let projection = window.windowProjection()
            output.writeln("CJGUI_SHARED_DOCUMENT_READY MEASUREMENT_START ${projection.sessionIdentity}");
            output.flush()
        }
        let measurementStarted = MonoTime.now()
        while (host.isOpen() && (measurementDurationMs <= 0 || (MonoTime.now() - measurementStarted).toMilliseconds() <
                measurementDurationMs)) {
            pumpSharedDocumentTurn(host, controller)
        }
    }
    getStdOut().writeln("CJGUI_DOCUMENT_TRANSFER_METRICS ${controller.transferMetricsSummary()}")
    getStdOut().flush()
    host.close()
    return 0
}

// Public-consumer cost mode. It starts the ordinary composable window,
// measures three bounded owner offers, then proves idle refresh convergence
// without a second layout or business mutation.
private func runTransferCostProbe(): Int32 {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(DESCRIPTION_DOCUMENT_ID, "成本小", transferCostDocumentText(128)),
        CjguiTextDocument(NOTES_DOCUMENT_ID, "成本中", transferCostDocumentText(4096)),
        CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "成本近上限", transferCostDocumentText(512 * 1024))
    ]))
    let controller = CjguiSharedDocumentController(workspace, CjguiTextDocumentFileBinding(), "", "成本探针")
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 1 }
    var sizes = ArrayList<Int64>()
    let documentIds = ArrayList<Int64>([DESCRIPTION_DOCUMENT_ID, NOTES_DOCUMENT_ID, READ_ONLY_ARCHIVE_ID])
    let selections = ArrayList<Int64>([128, 4096, 512 * 1024])
    var index: Int64 = 0
    while (index < selections.size) {
        let selection = workspace.setSelectionFromHuman(documentIds[index],
            CjguiTextDocumentRange(0, selections[index]))
        if (!selection.isAvailable) { window.close(); return 1 }
        if (let Some(offer) <- controller.offerSelectedTextTransfer()) {
            sizes.add(offer.payloadByteCount)
        } else {
            window.close()
            return 1
        }
        index += 1
    }
    if (!window.refresh()) { window.close(); return 1 }
    let before = window.windowProjection()
    let started = MonoTime.now()
    var repeats: Int64 = 0
    while (repeats < 128) {
        if (!window.refreshIfNeeded()) { window.close(); return 1 }
        repeats += 1
    }
    let elapsedMs = (MonoTime.now() - started).toMilliseconds()
    let after = window.windowProjection()
    let passed = sizes.size == 3 && sizes[0] < sizes[1] && sizes[1] < sizes[2] &&
        after.buildPassCount == before.buildPassCount && after.layoutPassCount == before.layoutPassCount &&
        after.nativeSubmissionCount == before.nativeSubmissionCount
    getStdOut().writeln("CJGUI_DOCUMENT_TRANSFER_COST sizes=${sizes[0]},${sizes[1]},${sizes[2]} " +
        "repeats=${repeats} idle_build_delta=${after.buildPassCount - before.buildPassCount} " +
        "idle_layout_delta=${after.layoutPassCount - before.layoutPassCount} " +
        "idle_submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount} elapsed_ms=${elapsedMs} passed=${passed}")
    getStdOut().flush()
    window.close()
    return if (passed) { 0 } else { 1 }
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--verify-transfer-cost") {
        return Int64(runTransferCostProbe())
    }
    if (let Some(options) <- launchOptionsFromArgs(args)) {
        if (options.opensMultipleWindows) {
            return Int64(runMultiWindow(options.filePath, options.enablesExternalConnection,
                options.expectsConnectionStartFailure, options.measurementDurationMs, options.measurementWarmupMs,
                options.closeFirstWindowAfterMs, options.recordsTurnObservations, options.reopensFirstWindowAfterClose,
                options.recordsResponseWorkload, options.responseEffectMode, options.responseInputIntervalTurns,
                options.responsePublicClientOnly))
        }
        return Int64(runWindow(options.filePath, options.enablesExternalConnection,
            options.expectsConnectionStartFailure, options.measurementDurationMs, options.measurementWarmupMs,
            options.extraOpenPaths))
    }
    getStdErr().writeln(
        "usage: CJGUISharedDocument [--file PATH] [--open-extra PATH] [--multi-window] [--with-connection] [--verify-connection-start-failure] [--verify-transfer-cost] [--measurement-warmup-ms 0..60000] [--measurement-duration-ms 1..900000] [--close-first-window-after-ms 1..60000] [--reopen-first-window-after-close] [--record-turn-observations] [--multi-window-response] [--response-input-interval-turns 1..120]")
    CjguiMacosApplicationHost.stopApplicationLoop()
    return 2
}
