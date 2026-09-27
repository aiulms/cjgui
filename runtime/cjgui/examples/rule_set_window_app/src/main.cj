package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.overflow.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

/// The rule window's detail workspace: "基本" (draft fields) and "保留策略" (file
/// and retention work) as ONE public tab container. The composition lives here so
/// the shipping window and its contract test build the SAME tree instead of two
/// lookalike declarations.
public func ruleDetailTabWorkspace(state: CjguiComposableUiTabsState, basicPage: CjguiComposableUiNode,
    retentionPage: CjguiComposableUiNode): CjguiComposableUiNode {
    let scope = CjguiComposableUiIdentityScope("rule-detail-pages")
    let pages = ArrayList<CjguiComposableUiTabPage>()
    pages.add(CjguiComposableUiTabPage("basic", "基本", basicPage))
    pages.add(CjguiComposableUiTabPage("retention", "保留策略", retentionPage))
    return cjguiComposableTabs(scope, "rule-detail-tabs", pages, state,
        CjguiComposableUiStyle(growX: 1), titleHeight: 26)
}

private class CjguiRuleSetStartupFiles {
    let openPath: String
    let saveAsPath: String
    let verifiesHostCloseDecisions: Bool
    /// A finite duration is only a measurement-run lifecycle bound. It does
    /// not alter domain truth or the normal event scheduler.
    let measurementDurationMs: Int64
    /// The same ordinary scheduler pumps during this explicit pre-measurement
    /// interval; it keeps startup outside the steady-state sample window.
    let measurementWarmupMs: Int64
    /// The declared retention boundary this run uses. It exists so the
    /// "declared rule changed" acceptance can point the SAME application at a
    /// different boundary without editing the example's own convention.
    let retentionMinimum: Int64
    let retentionMaximum: Int64
    /// Explicit preset override for the composite integer editor. Empty means
    /// "derive the presets from the declared field bounds"; a value is used only
    /// by the dedicated out-of-range negative control.
    let retentionPreset: String
    init(openPath: String, saveAsPath: String, verifiesHostCloseDecisions: Bool, measurementDurationMs: Int64,
        measurementWarmupMs: Int64, retentionMinimum: Int64, retentionMaximum: Int64,
        retentionPreset!: String = "") {
        this.openPath = openPath
        this.saveAsPath = saveAsPath
        this.verifiesHostCloseDecisions = verifiesHostCloseDecisions
        this.measurementDurationMs = measurementDurationMs
        this.measurementWarmupMs = measurementWarmupMs
        this.retentionMinimum = retentionMinimum
        this.retentionMaximum = retentionMaximum
        this.retentionPreset = retentionPreset
    }
}

/// Rule-set presentation adapter for the variable-height range source. It
/// asks the domain for one item only when the composable list materializes
/// that row; it does not copy `collectionSnapshot().allItems()` into a
/// component tree. A row revision is the record's own draft revision, never
/// the collection-wide version, so one changed draft invalidates one cache
/// entry without moving the viewport or selection.
class CjguiRuleSetVirtualListSource <: CjguiComposableUiVariableHeightListSource {
    private let domain: CjguiRuleSetEditingDomain
    private let theme: CjguiComposableUiTheme
    private let bodyStyle: CjguiComposableUiStyle
    private let cardScope: CjguiComposableUiIdentityScope

    init(domain: CjguiRuleSetEditingDomain, theme: CjguiComposableUiTheme, bodyStyle: CjguiComposableUiStyle,
        cardScope!: CjguiComposableUiIdentityScope = CjguiComposableUiIdentityScope("rule-record-card")) {
        this.domain = domain
        this.theme = theme
        this.bodyStyle = bodyStyle
        this.cardScope = cardScope
    }
    public func itemCount(): Int64 {
        return domain.collectionRangeSnapshot().totalCount
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let item = domain.collectionItemAt(index)
        if (item.resourceId < 0) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let draftRevision = domain.draftVersionForCollectionItem(item.resourceId)
        let revision = if (draftRevision >= 0) {
            draftRevision.saturatingMul(2).saturatingAdd(if (domain.selectedRecordId() == item.resourceId) {
                1
            } else {
                0
            })
        } else {
            0
        }
        return CjguiComposableUiVariableHeightListItem("rule_${item.resourceId}", item.resourceId, item.title, revision,
            estimatedHeight: 76)
    }
    public func indexForKey(key: String): Int64 {
        // The range domain already owns a direct resource-id index. Parsing
        // this framework-owned key avoids a hidden full collection scan for
        // every sparse-height correction or keyboard navigation request.
        let parts = key.split("_")
        if (parts.size == 2 && parts[0] == "rule") {
            if (let Some(resourceId) <- Int64.tryParse(parts[1])) {
                return domain.collectionIndexForResourceId(resourceId)
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        // Selection changes are local row projections, not a shared text
        // measurement dependency.  The selected bit is folded into each
        // item's layoutRevision above, so A/B are lazily refreshed while all
        // unrelated measured rows remain warm.
        return if (bodyStyle.fontFamily == "monospaced") {
            1
        } else {
            0
        }
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        let rowTextColor = if (isSelected || isFocused) {
            theme.primaryAction.textColor
        } else {
            bodyStyle.textColor
        }
        let rowBackground = if (isSelected || isFocused) {
            theme.primaryAction.background
        } else {
            theme.card.background
        }
        let row = cjguiComposableVertical(10000000 + item.resourceId, "rule-row-${item.resourceId}",
            CjguiComposableUiStyle(minHeight: 76, padding: 6, gap: 3, background: rowBackground,
                border: theme.card.border, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily))
        row.add(
            cjguiComposableText(11000000 + item.resourceId, "rule-title-${item.resourceId}", item.title,
                CjguiComposableUiStyle(textColor: rowTextColor, fontFamily: bodyStyle.fontFamily, fontWeight: 0),
                resourceId: item.resourceId, displayValueRole: "applied"))
        let revision = domain.draftVersionForCollectionItem(item.resourceId)
        // The range projection intentionally exposes only applied labels. For
        // the selected record, the existing form snapshot is the domain's
        // authoritative draft projection, so external/human draft text can
        // change this off-screen row's ordinary wrapped subtree without
        // creating a second record or draft store. Other rows retain a small
        // status summary and their own revision.
        let summary = if (revision < 0) {
            "规则草稿不可用"
        } else if (domain.selectedRecordId() == item.resourceId) {
            let form = domain.formSnapshot()
            let draftLabel = form.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText
            "草稿：${draftLabel} · 版本 ${revision}"
        } else {
            "草稿版本 ${revision} · 可继续编辑此规则"
        }
        row.add(
            cjguiComposableText(12000000 + item.resourceId, "rule-summary-${item.resourceId}", summary,
                CjguiComposableUiStyle(fontSize: 11.0, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily,
                    maxWidth: 300), resourceId: item.resourceId, displayValueRole: "draft"))
        // Keep the existing externally discoverable SELECT_RECORD descriptor
        // and action routing while making title/summary ordinary wrapping
        // text children whose height is solved by the regular layout path.
        row.add(
            cjguiComposableButton(100000 + item.resourceId, "rule-select-${item.resourceId}", "选择", "SELECT_RECORD",
                item.resourceId,
                CjguiComposableUiStyle(fixedHeight: 26, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily),
                operationActionName: "SELECT_RECORD", operationResourceId: item.resourceId,
                interactionStyle: theme.primaryActionInteraction,
                ownerInteractionState: if (isSelected) { CjguiComposableUiInteractionState.SELECTED } else {
                    CjguiComposableUiInteractionState.NONE
                }))
        let itemScope = cardScope.child("rule_${item.resourceId}")
        row.add(
            cjguiComposableScopedActionRow(
                itemScope.child("actions"),
                "rule-card-actions-${item.resourceId}",
                ArrayList<CjguiComposableUiActionItem>(
                    [
                        CjguiComposableUiActionItem("menu", "操作", "OPEN_RULE_CARD_MENU", item.resourceId,
                            CjguiComposableUiStyle(fixedHeight: 26, textColor: rowTextColor,
                                fontFamily: bodyStyle.fontFamily), semanticId: "rule-card-menu-${item.resourceId}"),
                        CjguiComposableUiActionItem("edit", "编辑", "OPEN_RULE_CARD_EDIT", item.resourceId,
                            CjguiComposableUiStyle(fixedHeight: 26, textColor: rowTextColor,
                                fontFamily: bodyStyle.fontFamily), semanticId: "rule-card-edit-${item.resourceId}")
                    ]
                ),
                CjguiComposableUiStyle(fixedHeight: 30, gap: 5)
            )
        )
        return row
    }
}

/// A normal consumer of the experimental composable window. The component
/// tree deliberately lives here, beside the rule-set choices and actions;
/// native code receives no rule field names or fixed form layout.
private class CjguiRuleSetComposableController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiDataTransferProvider & CjguiComposableUiPlatformThemeConsumer {
    private let domain: CjguiRuleSetEditingDomain
    private let listState: CjguiComposableUiVirtualListState
    private let componentRegistry: CjguiComposableUiComponentRegistry
    private let recordCardScope: CjguiComposableUiIdentityScope
    private let presentationScope: CjguiComposableUiIdentityScope
    private var filePath: String
    private var localRevision: Int64
    private var renderedSelectedId: Int64
    private var inputNotice: String
    private var usesDarkAppearance: Bool
    private var usesCoralBeacon: Bool
    private var usesMonospacedText: Bool
    private var layerMode: String
    private var activeRecordId: Int64
    // Diagnostic counters are consumer-owned observations of the real window
    // transfer route. They never become a second transfer state machine.
    private var transferDeclarationReadCount: Int64
    private var transferEventCount: Int64
    private var transferAcceptedCount: Int64
    private var transferRejectedCount: Int64
    private var transferPeakPayloadBytes: Int64
    private var transferLastApplyNanoseconds: Int64
    private let treePanel: CjguiRuleSetTreePanel
    private let generatedRegion: CjguiRuleSetGeneratedRegion
    // ONE public viewport for the whole mixed panel: the handwritten form, the
    // tree panel and the generated section all scroll through the same object.
    private let rootViewport: CjguiComposableUiScrollViewport
    // ONE public tab view state for the rule detail pane: "基本" keeps the draft
    // fields, "保留策略" keeps the file/retention work. Which page is ACTIVE is
    // window view state, so an ordinary refresh never moves a person back.
    private let detailTabs: CjguiComposableUiTabsState = CjguiComposableUiTabsState("basic")

    init(domain: CjguiRuleSetEditingDomain, presetOverride!: String = "") {
        this.domain = domain
        this.treePanel = CjguiRuleSetTreePanel(domain)
        this.generatedRegion = CjguiRuleSetGeneratedRegion(domain, presetOverride: presetOverride)
        this.rootViewport = CjguiComposableUiScrollViewport()
        this.listState = CjguiComposableUiVirtualListState()
        this.componentRegistry = CjguiComposableUiComponentRegistry()
        this.recordCardScope = CjguiComposableUiIdentityScope("rule-record-card")
        this.presentationScope = CjguiComposableUiIdentityScope("rule-set-presentation")
        this.filePath = ""
        this.localRevision = 1
        this.renderedSelectedId = -1
        this.inputNotice = ""
        this.usesDarkAppearance = false
        this.usesCoralBeacon = false
        this.usesMonospacedText = false
        this.layerMode = ""
        this.activeRecordId = -1
        this.transferDeclarationReadCount = 0
        this.transferEventCount = 0
        this.transferAcceptedCount = 0
        this.transferRejectedCount = 0
        this.transferPeakPayloadBytes = 0
        this.transferLastApplyNanoseconds = 0
    }

    /// The detail pane's shared tab view state. Switching a page is a WINDOW view
    /// fact, so the application exposes it instead of mirroring the page into its
    /// business domain; `requestDetailPage` makes the next commit present it.
    public func detailPageState(): CjguiComposableUiTabsState {
        return detailTabs
    }

    /// Presents the currently selected detail page on the next refresh. Returns
    /// false when the selection did not move.
    public func requestDetailPage(pageKey: String): Bool {
        if (!detailTabs.select(pageKey)) {
            return false
        }
        localRevision += 1
        return true
    }

    public func uiSceneVersion(): Int64 {
        // Aggregate owner state still rebuilds the whole declaration. Pointer
        // capture below uses its narrower split owner revision instead.
        return domain.snapshot().version.saturatingAdd(localRevision).saturatingAdd(
            generatedRegion.revision()).saturatingAdd(treePanel.viewRevision())
    }

    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        let dark = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme) ==
            CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        if (usesDarkAppearance == dark) {
            return false
        }
        usesDarkAppearance = dark
        let _ = generatedRegion.setAccentAppearance(dark)
        localRevision += 1
        return true
    }

    /// The generated region is the application-side owner of the accepted
    /// structure; the connection forwards bounded payloads to it.
    public func generatedUiRegion(): CjguiRuleSetGeneratedRegion {
        return generatedRegion
    }

    /// The window's own tree panel is the single owner of the tree selection;
    /// the connection forwards external snapshot reads and commands to it.
    public func treeSelectionProvider(): CjguiRuleSetTreePanel {
        return treePanel
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && node.resourceId == CjguiRuleSetEditingDomain
            .ruleSetResourceId) {
            return domain.splitFirstSizeVersion()
        }
        return uiSceneVersion()
    }

    /// Transfer target/offer/accept seam for the future native clipboard and
    /// drag adapter. The controller only forwards immutable values to the
    /// existing rule-set owner; it does not retain a second record store.
    public func offerSelectedRecordTransfer(): ?CjguiSharedOperationTransferOffer {
        return domain.selectedRecordTransferOfferFromHuman()
    }
    public func acceptTransferFromHuman(
        offer: CjguiSharedOperationTransferOffer
    ): CjguiSharedOperationTransferResult {
        let result = domain.acceptTransferFromHuman(offer)
        if (result.applied) { localRevision += 1 }
        return result
    }
    /// The existing Copy/New controls become explicit platform transfer
    /// endpoints only while a matching immutable owner offer exists. Their
    /// ordinary click actions remain owned by the rule-set domain.
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        transferDeclarationReadCount += 1
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (let Some(offer) <- offerSelectedRecordTransfer()) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source("copy", offer))
        }
        declarations.add(CjguiComposableUiDataTransferDeclaration.target("create",
            CjguiSharedOperationTransferFormat.structured(CjguiRuleSetEditingDomain.transferFormatIdentifier)))
        return declarations
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        transferEventCount += 1
        if (event.offer.payloadByteCount > transferPeakPayloadBytes) {
            transferPeakPayloadBytes = event.offer.payloadByteCount
        }
        let started = MonoTime.now()
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
            inputNotice = "已复制当前规则；可拖到“新增”或在“新增”上粘贴。"
            localRevision += 1
            transferAcceptedCount += 1
            transferLastApplyNanoseconds = (MonoTime.now() - started).toNanoseconds()
            getStdOut().writeln("CJGUI_RULE_TRANSFER_EVENT kind=${event.eventKind} payload_bytes=${event.offer.payloadByteCount} accepted=true apply_ns=${transferLastApplyNanoseconds}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        let result = acceptTransferFromHuman(event.offer)
        inputNotice = if (result.applied) {
            "已通过规则集领域导入：v${result.versionAfter}"
        } else if (result.isVersionConflict) {
            "导入未应用：目标版本已变化。"
        } else {
            "导入未应用：${result.reason}"
        }
        // An owner rejection still changes only this consumer-local notice;
        // it never reports a successful rule mutation.
        if (!result.applied) { localRevision += 1 }
        if (result.applied) {
            transferAcceptedCount += 1
        } else {
            transferRejectedCount += 1
        }
        transferLastApplyNanoseconds = (MonoTime.now() - started).toNanoseconds()
        getStdOut().writeln("CJGUI_RULE_TRANSFER_EVENT kind=${event.eventKind} payload_bytes=${event.offer.payloadByteCount} accepted=${result.applied} apply_ns=${transferLastApplyNanoseconds}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(true)
    }

    func transferMetricsSummary(): String {
        return "declaration_reads=${transferDeclarationReadCount} events=${transferEventCount} " +
            "accepted=${transferAcceptedCount} rejected=${transferRejectedCount} " +
            "peak_payload_bytes=${transferPeakPayloadBytes} last_apply_ns=${transferLastApplyNanoseconds}"
    }

    public func buildUi(): CjguiComposableUiNode {
        let collection = domain.collectionRangeSnapshot();
        let form = domain.formSnapshot();
        let binding = domain.formBinding()
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        let headingStyle = presentationTextStyle(theme.heading)
        let bodyStyle = presentationTextStyle(theme.body)
        let inputStyle = presentationTextStyle(theme.input)
        let validationStyle = CjguiComposableUiStyle(fixedHeight: 20,
            textColor: CjguiComposableUiColor(0.75, 0.12, 0.14, 1.0), fontFamily: bodyStyle.fontFamily)
        // The handwritten beacon takes path/key/version from the SAME application
        // declaration the generated side resolves against; the toggle only moves
        // the declared version.
        let beacon = generatedRegion.beaconResource()
        renderedSelectedId = collection.selectedResourceId
        listState.setSelectedKey(if (renderedSelectedId >= 0) {
            "rule_${renderedSelectedId}"
        } else {
            ""
        })
        let host = cjguiComposableLayerHost(1, "rule-set-layer-host", theme.page)
        // The header, the split panes, the tree panel and the generated section
        // together are longer than one screen. ONE public scroll container shares
        // ONE public viewport, so a real wheel gesture and the framework's focus
        // reveal reach the generated editors at the bottom while every author
        // keeps declaring only its own content.
        let scroll = cjguiComposableScrollArea(480, "rule-set-scroll", rootViewport,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        let root = cjguiComposableVertical(2, "rule-set-root", theme.page)
        // The title owns a full row. Keeping it beside eight fixed actions
        // leaves too little width in a narrow normal window and clips the
        // text; the action row itself still has stable node identities.
        // This region has no range materialization or field draft subtree.
        // Its explicit key therefore covers every value/style dependency
        // below it while allowing the changing list/detail region to remain
        // on the canonical solver path.
        let header = cjguiComposableVertical(5, "rule-set-header", CjguiComposableUiStyle(fixedHeight: 70, gap: 4),
            layoutReuseKey: "rule-header|applied=${form.appliedConfigVersion}|draft=${form.draftVersion}|dark=${usesDarkAppearance}|mono=${usesMonospacedText}")
        header.add(
            cjguiComposableText(3, "rule-set-title",
                "规则集编辑 · 已应用 v${form.appliedConfigVersion} · 草稿 v${form.draftVersion}", headingStyle,
                resourceId: CjguiRuleSetEditingDomain.ruleSetResourceId, fieldId: "ruleSet", displayValueRole: "applied"))
        let commands = cjguiComposableHorizontal(4, "rule-set-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 7))
        commands.add(command(10, "create", "新增", "CREATE_RECORD"))
        commands.add(command(11, "copy", "复制", "COPY_RECORD"))
        commands.add(command(12, "delete", "删除", "DELETE_RECORD"))
        commands.add(command(13, "undo", "撤销", "UNDO"))
        commands.add(command(14, "redo", "重做", "REDO"))
        commands.add(command(15, "save", "保存", "SAVE"))
        commands.add(command(16, "new", "新建", "NEW"))
        commands.add(command(17, "discard", "放弃", "DISCARD"))
        commands.add(scopedLocalPresentationButton(18, "open-rule-set-menu", "菜单", "OPEN_PRESENTATION_MENU", 64,
            presentationScope.local("open-menu")))
        commands.add(scopedLocalPresentationButton(19, "toggle-rule-set-beacon", "图标", "TOGGLE_BEACON", 64,
            presentationScope.local("toggle-beacon")))
        commands.add(localPresentationButton(29, "open-rule-set-editor", "编辑草稿", "OPEN_EDIT_DIALOG", 84))
        header.add(commands);
        root.add(header)

        let listPane = if (collection.totalCount == 0) {
            cjguiComposableText(
                23,
                "empty-list",
                "尚无规则；可用新增创建",
                CjguiComposableUiStyle(
                    minWidth: 160,
                    idealWidth: 260,
                    maxWidth: 340,
                    growX: 1,
                    fixedHeight: 30,
                    textColor: bodyStyle.textColor,
                    fontFamily: bodyStyle.fontFamily
                )
            )
        } else {
            cjguiComposableVariableHeightList(21, "rule-list-scroll", 22,
                CjguiRuleSetVirtualListSource(domain, theme, bodyStyle, cardScope: recordCardScope), listState, 76, 5, 3,
                CjguiComposableUiStyle(minWidth: 160, idealWidth: 260, maxWidth: 340, growX: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: theme.card.background,
                    border: theme.card.border))
        }

        let detail = cjguiComposableVertical(
            30,
            "rule-detail",
            CjguiComposableUiStyle(
                minWidth: 260,
                idealWidth: 520,
                growX: 2,
                gap: 8
            )
        )
        detail.add(cjguiComposableText(31, "detail-title", if (renderedSelectedId >= 0) {
            "当前规则草稿"
        } else {
            "请选择或新增一条规则"
        }, headingStyle))
        detail.add(
            cjguiComposableImage(32, "rule-set-beacon", beacon.rasterPath,
                CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END),
                imageResourceId: beacon.key, imageResourceVersion: beacon.version))
        // The detail pane is a real multi-page workspace through the PUBLIC tab
        // container: "基本" holds the draft fields, "保留策略" holds the file and
        // retention work. Both pages share the app's existing identities, and
        // which page is active is window view state.
        let basicPage = cjguiComposableVertical(60, "rule-detail-basic",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        let retentionPage = cjguiComposableVertical(61, "rule-detail-retention",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        if (renderedSelectedId >= 0 && layerMode != "edit" && layerMode != "edit-menu") {
            var fieldIndex: Int64 = 0
            while (fieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(fieldIndex);
                let field = form.fieldForResourceId(descriptor.resourceId)
                basicPage.add(
                    cjguiComposableBoundFormField(detailFieldGroupNodeId(renderedSelectedId, fieldIndex),
                        "field-group-${descriptor.fieldId}", detailFieldNodeId(renderedSelectedId, fieldIndex),
                        detailValidationNodeId(renderedSelectedId, fieldIndex), descriptor, field, renderedSelectedId,
                        inputStyle, validationStyle, editorSemanticId: "field-${descriptor.fieldId}",
                        validationSemanticId: "error-${descriptor.fieldId}", textOperationActionName: "EDIT_DRAFT_TEXT",
                        booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
                fieldIndex += 1
            }
            let applyRow = cjguiComposableHorizontal(41, "draft-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            applyRow.add(command(detailActionNodeId(renderedSelectedId, 0), "apply", "应用草稿", "APPLY"));
            applyRow.add(command(detailActionNodeId(renderedSelectedId, 1), "cancel", "取消草稿", "CANCEL"));
            basicPage.add(applyRow)
        }
        if (renderedSelectedId >= 0 && (layerMode == "edit" || layerMode == "edit-menu")) {
            basicPage.add(
                cjguiComposableText(34, "detail-layer-editor-notice",
                    "草稿正在通用对话框中编辑；应用/取消仍直接进入规则集领域。", bodyStyle))
        }
        retentionPage.add(
            cjguiComposableTextInput(390, "file-path", "文件路径", filePath, -1, inputStyle,
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
        let fileActions = cjguiComposableHorizontal(40, "file-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
        fileActions.add(command(403, "save-as", "另存为", "SAVE_AS"));
        fileActions.add(command(404, "open", "打开", "OPEN"));
        fileActions.add(command(405, "close", "关闭", "CLOSE"));
        retentionPage.add(fileActions)
        retentionPage.add(cjguiComposableText(50, "status", if (inputNotice.size > 0) {
            inputNotice
        } else {
            collection.statusMessage
        }, fixedTextStyle(bodyStyle, 30)))
        // A distinct normal application also composes the reusable local-key
        // API: neither group reserves a global numeric range or leaks a
        // native menu/product type. Their actions stay on this controller's
        // established owner path.
        let appearance = componentRegistry.use("rule-set-appearance")
        if (appearance.isLive()) {
            let group = cjguiComposableVertical(appearance.nodeId("root"), appearance.semanticId("root"),
                CjguiComposableUiStyle(padding: 4, gap: 2), inputScopeId: appearance.focusScopeId())
            group.add(
                cjguiComposableButton(appearance.nodeId("toggle"), appearance.semanticId("toggle"), "组件：外观/字体",
                    "TOGGLE_PRESENTATION", -1, presentationButtonStyle(150)))
            retentionPage.add(group)
        }
        let resource = componentRegistry.use("rule-set-resource")
        if (resource.isLive()) {
            let group = cjguiComposableVertical(resource.nodeId("root"), resource.semanticId("root"),
                CjguiComposableUiStyle(padding: 4, gap: 2), inputScopeId: resource.focusScopeId())
            group.add(
                cjguiComposableButton(resource.nodeId("toggle"), resource.semanticId("toggle"), "组件：切换图标",
                    "TOGGLE_BEACON", -1, presentationButtonStyle(150)))
            retentionPage.add(group)
        }
        // The public tab container presents exactly ONE page; the other page keeps
        // its identity and its own view state without being measured or drawn.
        detail.add(ruleDetailTabWorkspace(detailTabs, basicPage, retentionPage))
        let splitScope = CjguiComposableUiIdentityScope("rule-set-content")
        let split = cjguiComposableScopedSplitView(splitScope, "rule-set-content", listPane, detail,
            CjguiComposableUiSplitAxis.HORIZONTAL, domain.splitFirstSize(), 160, 260,
            CjguiComposableUiStyle(growX: 1, growY: 1), operationActionName: "SET_SPLIT_SIZE",
            operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId)
        root.add(split)
        // The tree section sits directly under the header so its virtual rows
        // materialize inside the visible viewport (a human can reach them);
        // the generated region follows below.
        root.add(treePanel.buildSection(theme, bodyStyle))
        root.add(generatedRegion.buildSection(theme, bodyStyle))
        scroll.add(root)
        host.add(scroll)
        if (layerMode == "menu") {
            let menu = cjguiComposableAnchoredLayer(500, "rule-set-menu", "rule-set-menu", "menu", "open-rule-set-menu",
                18,
                CjguiComposableUiStyle(fixedWidth: 156, fixedHeight: 96, background: theme.card.background,
                    border: theme.card.border, padding: 6, gap: 4))
            menu.add(localPresentationButton(501, "menu-toggle-presentation", "外观/字体", "TOGGLE_PRESENTATION", 140))
            // The application-menu command follows focus into this layer. Give
            // its visible action a distinct stable identity, rather than
            // allowing the command to point through the active layer at the
            // header action behind it.
            menu.add(scopedLocalPresentationButton(502, "menu-toggle-beacon", "切换图标", "TOGGLE_BEACON", 140,
                presentationScope.local("menu-toggle-beacon")))
            menu.add(localPresentationButton(503, "menu-close", "关闭菜单", "CLOSE_LAYER", 140))
            host.add(menu)
        }
        if (layerMode == "record-menu" && activeRecordId >= 0) {
            let cardScope = recordCardScope.child("rule_${activeRecordId}")
            let menuAnchor = CjguiComposableUiNodeReference.scoped(cardScope.child("actions").child("item"), "menu")
            let menu = cjguiComposableAnchoredLayerWithReference(530, "rule-card-menu-${activeRecordId}",
                "rule-card-menu-${activeRecordId}", "menu", "rule-row-${activeRecordId}", menuAnchor,
                CjguiComposableUiStyle(fixedWidth: 170, fixedHeight: 70, background: theme.card.background,
                    border: theme.card.border, padding: 6, gap: 4))
            menu.add(
                cjguiComposableButton(531, "rule-card-menu-edit-${activeRecordId}", "编辑草稿", "OPEN_RULE_CARD_EDIT",
                    activeRecordId, presentationButtonStyle(150)))
            menu.add(
                cjguiComposableButton(532, "rule-card-menu-close-${activeRecordId}", "关闭菜单", "CLOSE_LAYER",
                    activeRecordId, presentationButtonStyle(150)))
            host.add(menu)
        }
        if (layerMode == "record-edit" && activeRecordId >= 0) {
            let cardScope = recordCardScope.child("rule_${activeRecordId}")
            let editorScope = cardScope.child("editor")
            let dialog = cjguiComposableDialogLayerWithReference(540, "rule-card-edit-dialog-${activeRecordId}",
                "rule-card-edit-dialog-${activeRecordId}", "rule-row-${activeRecordId}",
                CjguiComposableUiNodeReference.scoped(cardScope.child("actions").child("item"), "edit"),
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 360, background: theme.card.background,
                    border: theme.card.border, padding: 14, gap: 8),
                initialFocus: Some(CjguiComposableUiNodeReference.scoped(editorScope, "editor-name")))
            dialog.add(cjguiComposableText(541, "rule-card-edit-title", "编辑规则草稿", headingStyle))
            let labelField = form.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId)
            dialog.add(
                CjguiComposableUiNode(dialogFieldNodeId(activeRecordId, 0), "rule-card-editor-name-${activeRecordId}",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "规则名称", labelField.draftText, "EDIT_TEXT",
                    CjguiRuleSetEditingDomain.formLabelResourceId, inputStyle, fieldId: "label",
                    operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: activeRecordId,
                    displayValueRole: "draft", identity: Some(editorScope.local("editor-name"))))
            var dialogFieldIndex: Int64 = 1
            while (dialogFieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(dialogFieldIndex)
                let field = form.fieldForResourceId(descriptor.resourceId)
                dialog.add(
                    cjguiComposableBoundFormField(dialogFieldGroupNodeId(activeRecordId, dialogFieldIndex),
                        "rule-card-dialog-field-group-${descriptor.fieldId}",
                        dialogFieldNodeId(activeRecordId, dialogFieldIndex),
                        dialogValidationNodeId(activeRecordId, dialogFieldIndex), descriptor, field, activeRecordId,
                        inputStyle, validationStyle, editorSemanticId: "rule-card-dialog-field-${descriptor.fieldId}",
                        validationSemanticId: "rule-card-dialog-error-${descriptor.fieldId}",
                        textOperationActionName: "EDIT_DRAFT_TEXT", booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
                dialogFieldIndex += 1
            }
            let dialogActions = cjguiComposableHorizontal(542, "rule-card-dialog-actions",
                CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            dialogActions.add(command(dialogActionNodeId(activeRecordId, 0), "rule-card-dialog-apply", "应用草稿",
                "APPLY"))
            dialogActions.add(
                command(dialogActionNodeId(activeRecordId, 1), "rule-card-dialog-cancel", "取消草稿", "CANCEL"))
            dialog.add(dialogActions)
            host.add(dialog)
        }
        if ((layerMode == "edit" || layerMode == "edit-menu") && renderedSelectedId >= 0) {
            let dialog = cjguiComposableDialogLayer(510, "rule-set-edit-dialog", "rule-set-edit-dialog", "rule-detail",
                30,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 360, background: theme.card.background,
                    border: theme.card.border, padding: 14, gap: 8),
                initialFocusNodeId: dialogFieldNodeId(renderedSelectedId, 0))
            dialog.add(
                cjguiComposableText(511, "rule-dialog-title", "编辑规则草稿", headingStyle,
                    resourceId: CjguiRuleSetEditingDomain.ruleSetResourceId, fieldId: "ruleSet",
                    displayValueRole: "draft"))
            var dialogFieldIndex: Int64 = 0
            while (dialogFieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(dialogFieldIndex);
                let field = form.fieldForResourceId(descriptor.resourceId)
                if (descriptor.fieldId == "retentionCount") {
                    // The handwritten region uses the SAME composite
                    // implementation the generated region presents: one numeric
                    // input plus the configured preset button, built by
                    // `CjguiRetentionIntegerEditComposite.buildEditor`. The
                    // preset caption/value come from the one config the
                    // registered composite also carries.
                    let compositeRow = CjguiRetentionIntegerEditComposite.buildEditor(
                        dialogFieldGroupNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}",
                        dialogFieldNodeId(renderedSelectedId, dialogFieldIndex),
                        dialogPresetNodeId(renderedSelectedId, dialogFieldIndex), descriptor.label,
                        field.draftText, descriptor.fieldId, "EDIT_DRAFT_TEXT", descriptor.resourceId,
                        renderedSelectedId, generatedRegion.retentionPreset().label,
                        style: inputStyle)
                    if (field.validationError.size > 0) {
                        compositeRow.add(cjguiComposableText(
                            dialogValidationNodeId(renderedSelectedId, dialogFieldIndex),
                            "dialog-error-${descriptor.fieldId}", "请先填写保留天数，再应用规则", validationStyle,
                            resourceId: descriptor.resourceId, fieldId: descriptor.fieldId,
                            displayValueRole: "validation", operationResourceId: renderedSelectedId))
                    }
                    dialog.add(compositeRow)
                    dialogFieldIndex += 1
                    continue
                }
                dialog.add(
                    cjguiComposableBoundFormField(dialogFieldGroupNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}",
                        dialogFieldNodeId(renderedSelectedId, dialogFieldIndex),
                        dialogValidationNodeId(renderedSelectedId, dialogFieldIndex), descriptor, field,
                        renderedSelectedId, inputStyle, validationStyle,
                        editorSemanticId: "dialog-field-${descriptor.fieldId}",
                        validationSemanticId: "dialog-error-${descriptor.fieldId}",
                        // The rule editor chooses contextual human wording for
                        // this dialog. Its shared projection still exposes the
                        // stable `retention_count_required` machine reason to
                        // external consumers.
                        validationDisplayMessage: if (descriptor.fieldId == "retentionCount" &&
                            field.validationError.size > 0) {
                            "请先填写保留天数，再应用规则"
                        } else {
                            ""
                        }, textOperationActionName: "EDIT_DRAFT_TEXT", booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
                dialogFieldIndex += 1
            }
            let dialogActions = cjguiComposableHorizontal(512, "rule-dialog-actions",
                CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            dialogActions.add(localPresentationButton(513, "dialog-more", "更多", "OPEN_DIALOG_MENU", 64))
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 0), "dialog-apply", "应用草稿", "APPLY"))
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 1), "dialog-cancel", "取消草稿", "CANCEL"))
            dialog.add(dialogActions);
            host.add(dialog)
            if (layerMode == "edit-menu") {
                let submenu = cjguiComposableAnchoredLayer(520, "rule-dialog-menu", "rule-dialog-menu", "menu",
                    "rule-set-edit-dialog", 513,
                    CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 64, background: theme.card.background,
                        border: theme.card.border, padding: 6, gap: 4))
                submenu.add(
                    localPresentationButton(521, "dialog-menu-presentation", "外观/字体", "TOGGLE_PRESENTATION", 134))
                submenu.add(localPresentationButton(522, "dialog-menu-close", "关闭菜单", "CLOSE_LAYER", 134))
                host.add(submenu)
            }
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generatedResult = generatedRegion.handleEvent(event)
        if (generatedResult.didApply) {
            localRevision += 1
            return generatedResult
        }
        let treeResult = treePanel.handleTreeEvent(event)
        if (treeResult.didApply) {
            localRevision += 1
            return treeResult
        }
        let node = event.node
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && event.eventKind == 35) {
            let direction = if (event.text == "left" || event.text == "up") {
                -1
            } else if (event.text == "right" || event.text == "down") {
                1
            } else {
                0
            }
            if (direction != 0) {
                // The editing domain owns the public 160..720 boundary. A
                // keyboard nudge remains an ordinary local owner action;
                // it never writes a framework-local pane size.
                let next = if (direction < 0) {
                    max(160, domain.splitFirstSize().saturatingSub(8))
                } else {
                    min(720, domain.splitFirstSize().saturatingAdd(8))
                }
                let result = domain.setSplitFirstSizeFromHuman(next)
                if (result.applied) {
                    localRevision += 1
                }
                return CjguiComposableUiDispatchResult(result.applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && (event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN || event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            let trackOrigin = node.bounds.x - node.pointerControlFirstSize
            let splitFirstSize = CjguiComposableUiSplitGeometry.firstSizeForPointer(event.pointerX, trackOrigin, 720,
                node.pointerControlHandleThickness, 160, 260)
            let result = domain.setSplitFirstSizeFromHuman(splitFirstSize)
            if (result.applied) {
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if ((event.eventKind == 36 && layerMode.size > 0) || (event.eventKind == 27 && node.actionName == "LAYER_OUTSIDE")) {
            layerMode = if (event.eventKind == 36 && layerMode == "edit-menu") {
                "edit"
            } else {
                ""
            };
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && node.nodeId == 21) {
            listState.scrollByViewport(event.text)
            layerMode = ""
            activeRecordId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 31 && node.actionName == "SELECT_RECORD") {
            listState.setFocusedKey("rule_${node.resourceId}")
            layerMode = ""
            activeRecordId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35 && node.nodeId == 21) {
            let target = listState.moveFocus(currentListSource(), event.text)
            if (target.resourceId < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            let selected = domain.selectCollectionItemFromHuman(target.resourceId)
            if (selected.applied) {
                listState.setSelectedKey(target.key);
                listState.setFocusedKey(target.key);
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(selected.applied)
        }
        if (event.eventKind == 28 && node.nodeId == 390) {
            filePath = event.text
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let detailTargetRecordId = detailRecordId(node.nodeId)
        let targetRecordId = if (detailTargetRecordId >= 0) {
            detailTargetRecordId
        } else {
            dialogRecordId(node.nodeId)
        }
        if (event.eventKind == 28 && targetRecordId >= 0) {
            let result = domain.editTextForCollectionItemFromHuman(targetRecordId, node.resourceId, event.text,
                event.selectionStart, event.selectionEnd)
            if (result.applied) {
                localRevision += 1
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 29 && targetRecordId >= 0) {
            let result = domain.editBooleanForCollectionItemFromHuman(targetRecordId, node.resourceId,
                event.text == "true")
            if (result.applied) {
                localRevision += 1
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        // The composite editor's preset button in the HANDWRITTEN region: its
        // activation writes the configured constant through the SAME owner draft
        // entry the typed edit uses, so legality, the draft/applied split and the
        // apply/cancel rule are identical. The constant comes from the one preset
        // configuration the registered composite also carries - an out-of-range
        // preset is refused by the owner, never clamped here.
        let presetTarget = node.operationResourceId
        if (node.actionName == CjguiRetentionIntegerEditComposite.PRESET_ACTION &&
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE && presetTarget >= 0 &&
            node.resourceId == CjguiRuleSetEditingDomain.formRetentionResourceId) {
            let preset = generatedRegion.retentionPreset()
            let result = domain.editTextForCollectionItemFromHuman(presetTarget, node.resourceId,
                preset.value, 0, preset.value.size)
            if (result.applied) {
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (node.actionName == "OPEN_PRESENTATION_MENU") {
            layerMode = "menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_EDIT_DIALOG") {
            if (renderedSelectedId < 0) {
                inputNotice = "请先选择一条规则"
            } else {
                layerMode = "edit"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(renderedSelectedId >= 0)
        }
        if (node.actionName == "OPEN_RULE_CARD_MENU") {
            activeRecordId = node.resourceId
            layerMode = "record-menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_RULE_CARD_EDIT") {
            activeRecordId = node.resourceId
            layerMode = "record-edit"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_DIALOG_MENU" && layerMode == "edit") {
            layerMode = "edit-menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "CLOSE_LAYER") {
            layerMode = if (node.semanticId == "dialog-menu-close") {
                "edit"
            } else {
                ""
            }
            if (layerMode.size == 0) {
                activeRecordId = -1
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_PRESENTATION") {
            usesDarkAppearance = !usesDarkAppearance
            usesMonospacedText = !usesMonospacedText
            // The application's OWN theme switch retargets the one named style, so
            // the handwritten and generated controls change paint together.
            let _ = generatedRegion.setAccentAppearance(usesDarkAppearance)
            inputNotice = if (usesDarkAppearance) {
                "已切换到深色与等宽文字"
            } else {
                "已切换到浅色与系统文字"
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_BEACON") {
            usesCoralBeacon = !usesCoralBeacon
            let _ = generatedRegion.setBeaconVersion(if (usesCoralBeacon) { 2 } else { 1 })
            inputNotice = if (usesCoralBeacon) {
                "已替换为珊瑚灯塔资源"
            } else {
                "已恢复蓝色灯塔资源"
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let result = if (node.actionName == "SELECT_RECORD") {
            domain.selectCollectionItemFromHuman(node.resourceId)
        } else if (node.actionName == "CREATE_RECORD") {
            domain.createCollectionItemFromHuman()
        } else if (node.actionName == "COPY_RECORD") {
            domain.copySelectedCollectionItemFromHuman()
        } else if (node.actionName == "DELETE_RECORD") {
            domain.deleteSelectedCollectionItemFromHuman()
        } else if (node.actionName == "UNDO") {
            domain.undoFromHuman()
        } else if (node.actionName == "REDO") {
            domain.redoFromHuman()
        } else if (node.actionName == "SAVE") {
            domain.saveFromHuman()
        } else if (node.actionName == "NEW") {
            domain.newUntitledFromHuman()
        } else if (node.actionName == "DISCARD") {
            domain.discardUnsavedContentFromHuman()
        } else if (node.actionName == "SAVE_AS") {
            domain.saveAsFromHuman(filePath)
        } else if (node.actionName == "OPEN") {
            domain.openFromHuman(filePath)
        } else if (node.actionName == "APPLY" && actionRecordId(node.nodeId) >= 0) {
            let itemId = actionRecordId(node.nodeId)
            domain.applyDraftForCollectionItemFromHuman(itemId, domain.draftVersionForCollectionItem(itemId),
                domain.baseAppliedVersionForCollectionItem(itemId))
        } else if (node.actionName == "CANCEL" && actionRecordId(node.nodeId) >= 0) {
            let itemId = actionRecordId(node.nodeId)
            domain.cancelDraftForCollectionItemFromHuman(itemId, domain.draftVersionForCollectionItem(itemId),
                domain.baseAppliedVersionForCollectionItem(itemId))
        } else if (node.actionName == "CLOSE") {
            domain.requestCloseFromHuman()
        } else {
            CjguiSharedOperationActionResult(false, false, 0, 0, "unknown_ui_action")
        }
        if (result.applied && node.actionName == "SELECT_RECORD") {
            listState.setSelectedKey("rule_${node.resourceId}");
            listState.setFocusedKey("rule_${node.resourceId}")
        }
        if (result.applied && (node.actionName == "APPLY" || node.actionName == "CANCEL")) {
            layerMode = ""
        }
        if (result.applied) {
            localRevision += 1
        }
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: node.actionName == "CLOSE" && result.applied)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        let result = domain.requestCloseFromHuman();
        if (result.applied) {
            localRevision += 1
        }
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: result.applied)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        inputNotice = if (eventKind == 11) {
            "输入队列已满：本次输入未应用，请重试"
        } else {
            "输入未应用：事件 ${eventKind} 的原控件已刷新或移除（节点 ${nodeId}）"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func beginSceneRefresh(): Bool {
        // The handwritten component identities and the generated candidate
        // identities open in the same transaction, so both are committed or
        // rolled back with the scene the window actually accepts.
        if (!componentRegistry.beginTransaction()) {
            return false
        }
        if (!generatedRegion.beginSceneRefresh()) {
            componentRegistry.rollbackTransaction()
            return false
        }
        return true
    }
    public func prepareSceneRefresh(): Bool {
        if (!componentRegistry.prepareTransaction()) {
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
        // An active anchored menu owns focus. Keep the common command id and
        // metadata, but bind it to the currently visible semantic action so
        // both the self-drawn menu and the native application menu resolve
        // against the accepted scene.
        let toggleBeaconTarget = if (layerMode == "menu") {
            CjguiComposableUiNodeReference.scoped(presentationScope, "menu-toggle-beacon")
        } else {
            CjguiComposableUiNodeReference.scoped(presentationScope, "toggle-beacon")
        }
        return ArrayList<CjguiComposableUiCommand>(
            [
                CjguiComposableUiCommand(
                    "rule-set.open-presentation-menu",
                    CjguiComposableUiNodeReference.scoped(presentationScope, "open-menu"),
                    "菜单",
                    CjguiComposableUiShortcut("m"),
                    "View",
                    0,
                    layerMode != "menu",
                    false
                ),
                CjguiComposableUiCommand(
                    "rule-set.toggle-beacon",
                    toggleBeaconTarget,
                    "切换图标",
                    "View",
                    1,
                    true,
                    usesCoralBeacon,
                    focusScopeId: if (layerMode == "menu") {
                        "rule-set-menu"
                    } else {
                        ""
                    }
                )
            ])
    }
    public func commitSceneRefresh(): Unit {
        componentRegistry.commitTransaction()
        // Published only now: the candidate structure, its version and its
        // event identity table become the accepted interface together with the
        // scene the window accepted.
        generatedRegion.commitSceneRefresh()
    }
    public func disposeSceneRefreshResources(): Unit {
        generatedRegion.releaseImageIdentities()
        // Evidence from the REAL window dispose path: after releasing, the shared
        // catalog must hold nothing for this window. `eprintln` is unbuffered, so
        // a closed window still leaves the line in its log.
        eprintln("CJGUI_IMAGE_IDENTITY_DISPOSE leftover_holds=${generatedRegion.liveImageIdentityHoldCount()}")
    }
    public func rollbackSceneRefresh(): Unit {
        componentRegistry.rollbackTransaction()
        // The old structure, version and instances stay exactly as they were.
        generatedRegion.rollbackSceneRefresh()
    }

    private func command(nodeId: Int64, semanticId: String, label: String, actionName: String): CjguiComposableUiNode {
        return cjguiComposableButton(nodeId, semanticId, label, actionName, CjguiRuleSetEditingDomain.ruleSetResourceId,
            presentationButtonStyle(64), operationActionName: operationActionName(actionName),
            interactionStyle: if (usesDarkAppearance) {
                CjguiComposableUiTheme.beaconDark().primaryActionInteraction
            } else {
                CjguiComposableUiTheme.paperLight().primaryActionInteraction
            })
    }
    private func localPresentationButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        width: Int64): CjguiComposableUiNode {
        return cjguiComposableButton(nodeId, semanticId, label, actionName, -1, presentationButtonStyle(width),
            interactionStyle: if (usesDarkAppearance) {
                CjguiComposableUiTheme.beaconDark().primaryActionInteraction
            } else {
                CjguiComposableUiTheme.paperLight().primaryActionInteraction
            })
    }
    private func scopedLocalPresentationButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        width: Int64, identity: CjguiComposableUiIdentity): CjguiComposableUiNode {
        // ONE definition: the application's named paint role supplies the paint,
        // the helper keeps its own geometry. The same style object is registered in
        // the capability catalog the generated nodes resolve against.
        let sized = presentationButtonStyle(width)
        let accent = generatedRegion.namedStyle("rule_primary_action")
        let painted = match (accent) {
            case Some(value) => cjguiComposableUiPaintOverlay(sized, value.base)
            case None => sized
        }
        let interaction = match (accent) {
            case Some(value) => value.interaction
            case None => CjguiComposableUiTheme.paperLight().primaryActionInteraction
        }
        return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_BUTTON, label, label, actionName, -1,
            painted, interactionStyle: interaction, identity: Some(identity))
    }
    private func presentationButtonStyle(width: Int64): CjguiComposableUiStyle {
        let base = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark().card
        } else {
            CjguiComposableUiTheme.paperLight().card
        }
        return CjguiComposableUiStyle(minWidth: if (width > 48) {
            48
        } else {
            width
        }, idealWidth: width, fixedHeight: 30, background: base.background, border: base.border,
            textColor: if (usesDarkAppearance) {
                CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0)
            } else {
                CjguiComposableUiColor(0.12, 0.16, 0.23, 1.0)
            }, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            })
    }
    private func presentationTextStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
            padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
            growX: base.growX, growY: base.growY, borderWidth: base.borderWidth, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            }, minWidth: base.minWidth, maxWidth: base.maxWidth, idealWidth: base.idealWidth, minHeight: base.minHeight,
            maxHeight: base.maxHeight, idealHeight: base.idealHeight, alignX: base.alignX, alignY: base.alignY)
    }
    private func fixedTextStyle(base: CjguiComposableUiStyle, height: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: height, textColor: base.textColor, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: base.fontFamily)
    }
    private func operationActionName(controllerAction: String): String {
        if (controllerAction == "CREATE_RECORD" || controllerAction == "COPY_RECORD" || controllerAction ==
            "DELETE_RECORD" || controllerAction == "UNDO" || controllerAction == "REDO") {
            return controllerAction
        }
        if (controllerAction == "SAVE") {
            return "SAVE_RULE_SET"
        }
        if (controllerAction == "APPLY") {
            return "APPLY_DRAFT"
        }
        if (controllerAction == "CANCEL") {
            return "CANCEL_DRAFT"
        }
        return ""
    }
    private func currentListSource(): CjguiRuleSetVirtualListSource {
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        return CjguiRuleSetVirtualListSource(domain, theme, presentationTextStyle(theme.body),
            cardScope: recordCardScope)
    }
    private func detailFieldNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 200000000 + recordId * 16 + fieldIndex
    }
    private func detailFieldGroupNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 600000000 + recordId * 16 + fieldIndex
    }
    private func detailValidationNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 700000000 + recordId * 16 + fieldIndex
    }
    private func detailActionNodeId(recordId: Int64, actionIndex: Int64): Int64 {
        return 300000000 + recordId * 4 + actionIndex
    }
    private func dialogFieldNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 400000000 + recordId * 16 + fieldIndex
    }
    private func dialogFieldGroupNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 800000000 + recordId * 16 + fieldIndex
    }
    private func dialogValidationNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 900000000 + recordId * 16 + fieldIndex
    }
    /// Identity of the composite editor's preset button inside the handwritten
    /// dialog. The composite implementation is shared with the generated region,
    /// so its extra element needs its own distinct id range.
    private func dialogPresetNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1000000000 + recordId * 16 + fieldIndex
    }
    private func dialogActionNodeId(recordId: Int64, actionIndex: Int64): Int64 {
        return 500000000 + recordId * 4 + actionIndex
    }
    private func detailRecordId(nodeId: Int64): Int64 {
        if (nodeId < 200000000 || nodeId >= 300000000) {
            return -1
        }
        return (nodeId - 200000000) / 16
    }
    private func detailActionRecordId(nodeId: Int64): Int64 {
        if (nodeId < 300000000) {
            return -1
        }
        return (nodeId - 300000000) / 4
    }
    private func dialogRecordId(nodeId: Int64): Int64 {
        if (nodeId < 400000000 || nodeId >= 500000000) {
            return -1
        }
        return (nodeId - 400000000) / 16
    }
    private func actionRecordId(nodeId: Int64): Int64 {
        let detail = detailActionRecordId(nodeId)
        if (detail >= 0 && nodeId < 400000000) {
            return detail
        }
        if (nodeId < 500000000) {
            return -1
        }
        return (nodeId - 500000000) / 4
    }
}

private func parseStartupFiles(args: Array<String>): ?CjguiRuleSetStartupFiles {
    var openPath = "";
    var saveAsPath = "";
    var verifiesHostCloseDecisions = false;
    var measurementDurationMs: Int64 = 0
    var measurementWarmupMs: Int64 = 0;
    var hasMeasurementWarmup = false;
    var retentionMinimum = CjguiRuleSetEditingDomain.defaultRetentionMinimum
    var retentionMaximum = CjguiRuleSetEditingDomain.defaultRetentionMaximum
    var retentionPreset = ""
    var hasRetentionRange = false
    var index: Int64 = 0
    while (index < args.size) {
        if ((args[index] == "--open" || args[index] == "--save-as") && index + 1 < args.size) {
            if (args[index] == "--open" && openPath.size == 0) {
                openPath = args[index + 1]
            } else if (args[index] == "--save-as" && saveAsPath.size == 0) {
                saveAsPath = args[index + 1]
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--verify-host-close-decisions" && !verifiesHostCloseDecisions && openPath.size == 0 &&
            saveAsPath.size == 0) {
            verifiesHostCloseDecisions = true
            index += 1
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
        } else if (args[index] == "--retention-preset" && index + 1 < args.size) {
            // Typed application configuration for the composite editor's preset
            // button. The command line is the app's existing configuration
            // channel; no environment variable or hidden global is introduced.
            retentionPreset = args[index + 1]
            index += 2
        } else if (args[index] == "--retention-range" && index + 2 < args.size && !hasRetentionRange) {
            if (let Some(minimum) <- Int64.tryParse(args[index + 1])) {
                if (let Some(maximum) <- Int64.tryParse(args[index + 2])) {
                    if (minimum >= 0 && maximum > minimum && maximum <= 100000) {
                        retentionMinimum = minimum
                        retentionMaximum = maximum
                        hasRetentionRange = true
                    } else {
                        return None
                    }
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 3
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
        } else {
            return None
        }
    }
    return Some(
        CjguiRuleSetStartupFiles(openPath, saveAsPath, verifiesHostCloseDecisions, measurementDurationMs,
            measurementWarmupMs, retentionMinimum, retentionMaximum,
            retentionPreset: retentionPreset))
}

// Bounded consumer-side cost probe. It uses the same public controller and
// normal composable window as the application; only the launch mode is
// diagnostic, so no native/private transfer seam is exposed to consumers.
private func runTransferCostProbe(): Int32 {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    if (!domain.createRecordFromHuman(transferCostFixtureText(8), true, 9, transferCostFixtureText(8),
        "transfer-cost-cli-small").applied) {
        return 1
    }
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 1 }
    var payloads = ArrayList<Int64>()
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) { payloads.add(offer.payloadByteCount) }
    let medium = domain.executeFromExternal(
        CjguiRuleSetInvocationFactory.create(domain.snapshot().version, transferCostFixtureText(64), true, 45,
            transferCostFixtureText(64), "transfer-cost-cli-medium"))
    if (!medium.applied || !window.refresh()) { window.close(); return 1 }
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) { payloads.add(offer.payloadByteCount) }
    let near = domain.executeFromExternal(
        CjguiRuleSetInvocationFactory.create(domain.snapshot().version, transferCostFixtureText(128), true, 90,
            transferCostFixtureText(128), "transfer-cost-cli-near-limit"))
    if (!near.applied || !window.refresh()) { window.close(); return 1 }
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) { payloads.add(offer.payloadByteCount) }
    if (payloads.size != 3) { window.close(); return 1 }
    let before = window.windowProjection()
    let started = MonoTime.now()
    var repeats: Int64 = 0
    while (repeats < 128) {
        if (!window.refreshIfNeeded()) { window.close(); return 1 }
        repeats += 1
    }
    let elapsedMs = (MonoTime.now() - started).toMilliseconds()
    let after = window.windowProjection()
    let passed = payloads[0] < payloads[1] && payloads[1] < payloads[2] &&
        after.buildPassCount == before.buildPassCount && after.layoutPassCount == before.layoutPassCount &&
        after.nativeSubmissionCount == before.nativeSubmissionCount
    getStdOut().writeln("CJGUI_RULE_TRANSFER_COST sizes=${payloads[0]},${payloads[1]},${payloads[2]} " +
        "repeats=${repeats} idle_build_delta=${after.buildPassCount - before.buildPassCount} " +
        "idle_layout_delta=${after.layoutPassCount - before.layoutPassCount} " +
        "idle_submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount} elapsed_ms=${elapsedMs} passed=${passed}")
    getStdOut().flush()
    window.close()
    return if (passed) { 0 } else { 1 }
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "规则集本地 Agent",
        "cjgui-rule-set-agent-20260912",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
                CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", all, true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", all, true),
                CjguiSharedOperationExternalActionScope("CREATE_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("COPY_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("RENAME_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("DELETE_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("SELECT_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
                CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("BATCH_SET_ENABLED", all, true),
                CjguiSharedOperationExternalActionScope("UNDO", all, true),
                CjguiSharedOperationExternalActionScope("REDO", all, true),
                CjguiSharedOperationExternalActionScope("SAVE_RULE_SET", all, true),
                CjguiSharedOperationExternalActionScope("SET_SPLIT_SIZE", all, true),
                // Runtime-generated-UI entry points. They are protocol verbs
                // (listed by the connection's visible-action catalog when the
                // generated provider is registered) and only forward bounded
                // payloads to the application's structure holder.
                CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
                CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
                CjguiSharedOperationExternalActionScope("GET_TREE_SELECTION", all, true),
                CjguiSharedOperationExternalActionScope("UPDATE_TREE_SELECTION", all, true)
            ]
        )
    )
}

private func assertRuleSetProjectionIdentity(projection: CjguiSharedOperationWindowProjection): Unit {
    var listContentNodeId: Int64 = -1
    var splitHandleNodeId: Int64 = -1
    for (node in projection.nodes) {
        if (node.semanticId == "rule-list-scroll_materialized") {
            listContentNodeId = node.nodeId
        }
        if (node.semanticId == "rule-set-content-handle") {
            splitHandleNodeId = node.nodeId
        }
    }
    @Assert(listContentNodeId, 22)
    @Assert(splitHandleNodeId > 0, true)
    @Assert(splitHandleNodeId != listContentNodeId, true)
}

private func assertRuleCardProjection(projection: CjguiSharedOperationWindowProjection, resourceId: Int64): Unit {
    var menu = CjguiSharedOperationWindowNode(-1, "", "", ArrayList<Int64>())
    var edit = CjguiSharedOperationWindowNode(-1, "", "", ArrayList<Int64>())
    for (node in projection.nodes) {
        if (node.semanticId == "rule-card-menu-${resourceId}") {
            menu = node
        }
        if (node.semanticId == "rule-card-edit-${resourceId}") {
            edit = node
        }
    }
    @Assert(menu.nodeId > 0, true)
    @Assert(edit.nodeId > 0, true)
    @Assert(menu.nodeId != edit.nodeId, true)
    @Assert(ruleFirstResourceId(menu), resourceId)
    @Assert(ruleFirstResourceId(edit), resourceId)
}

private func ruleFirstResourceId(node: CjguiSharedOperationWindowNode): Int64 {
    let resourceIds = node.resourceIds()
    return if (resourceIds.size > 0) {
        resourceIds[0]
    } else {
        -1
    }
}

// Command-menu regression: a self-drawn presentation layer is opened and its
// existing toggle action is re-entered through the same stable command table
// used by the application menu/shortcut bridge. The real rule owner remains
// the only state writer, and a later owner mutation still refreshes normally.
@Test
func commandMenuRouteKeepsRuleOwnerAndLayerInSync(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(controller.candidateSceneCommands()[1].isChecked, false)
    @Assert(window.invokeCommand("rule-set.open-presentation-menu"), true)
    @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-set-menu").nodeId > 0, true)
    @Assert(window.invokeCommand("rule-set.toggle-beacon"), true)
    @Assert(controller.candidateSceneCommands()[1].isChecked, true)
    @Assert(domain.snapshot().version, 0)
    let external = domain.executeFromExternal(
        CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "命令菜单回归", true, 7, "cache", "command-menu"))
    @Assert(external.applied, true)
    @Assert(window.refresh(), true)
    @Assert(window.windowProjection().pendingRefreshReason, "none")
    window.close()
    @Assert(!window.invokeCommand("rule-set.toggle-beacon"), true)
}

// Regression boundary for the first real collection mutation. The native UI
// event path has already resolved the visible `create` button to this exact
// controller action; this test keeps the owner/controller -> rebuilt
// variable-height-list projection in the normal window transaction. It must
// not strand a successfully-created record behind the former empty-list scene.
@Test
func firstCreateProjectsRuleListThroughNormalWindowTransaction(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let before = window.windowProjection()
    let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(), CjguiComposableUiRect(0, 0, 980, 620),
        1)
    let create = initialScene.nodeForId(10)
    @Assert(create.nodeId, 10)
    let dispatched = controller.applyUiEvent(CjguiComposableUiEvent(create, 27, "", 0, 0, initialScene.version))
    @Assert(dispatched.didApply, true)
    @Assert(domain.collectionRangeSnapshot().totalCount, 1)
    @Assert(window.refresh(), true)
    assertRuleSetProjectionIdentity(window.windowProjection())
    let createdId = domain.collectionRangeSnapshot().selectedResourceId
    assertRuleCardProjection(window.windowProjection(), createdId)
    let cardMenu = cjguiComposableButton(117000, "rule-card-menu-${createdId}", "操作", "OPEN_RULE_CARD_MENU", createdId,
        CjguiComposableUiStyle(fixedHeight: 26))
    let cardMenuEvent = controller.applyUiEvent(
        CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(cardMenu, CjguiComposableUiRect(0, 0, 80, 26), CjguiComposableUiRect(0, 0, 80,
                26)), 27, "", 0, 0, 1))
    @Assert(cardMenuEvent.didApply, true)
    @Assert(window.refresh(), true)
    @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-card-menu-${createdId}").nodeId > 0, true)
    let cardEdit = cjguiComposableButton(117001, "rule-card-edit-${createdId}", "编辑", "OPEN_RULE_CARD_EDIT", createdId,
        CjguiComposableUiStyle(fixedHeight: 26))
    let cardEditEvent = controller.applyUiEvent(
        CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(cardEdit, CjguiComposableUiRect(0, 0, 80, 26), CjguiComposableUiRect(0, 0, 80,
                26)), 27, "", 0, 0, 1))
    @Assert(cardEditEvent.didApply, true)
    @Assert(window.refresh(), true)
    @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-card-edit-dialog-${createdId}").nodeId > 0, true)
    let after = window.windowProjection()
    @Assert(after.acceptedSceneVersion > before.acceptedSceneVersion, true)
    @Assert(after.pendingRefreshReason, "none")
    window.close()
}

private func ruleSetProjectionNode(projection: CjguiSharedOperationWindowProjection, semanticId: String): CjguiSharedOperationWindowNode {
    for (node in projection.nodes) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiSharedOperationWindowNode(-1, "", "", ArrayList<Int64>())
}

@Test
func composableRuleTransferConsumerUsesExistingCopyOwner(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("传输控件规则", true, 9, "cache", "transfer-consumer-source").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let declarations = controller.dataTransferDeclarations()
    @Assert(declarations.size, 2)
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) {
        let targetNode = CjguiComposableUiLayoutNode(
            cjguiComposableButton(9901, "create", "新增", "CREATE_RECORD", CjguiRuleSetEditingDomain.ruleSetResourceId,
                CjguiComposableUiStyle(fixedHeight: 30)), CjguiComposableUiRect(0, 0, 80, 30),
            CjguiComposableUiRect(0, 0, 80, 30))
        let accepted = controller.applyDataTransfer(CjguiComposableUiDataTransferEvent(
            targetNode, CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_PASTE, offer, offer.format, 1))
        @Assert(accepted.didApply, true)
        @Assert(domain.collectionRangeSnapshot().totalCount, 2)
    } else {
        @Assert(false, true)
    }
}

private func transferCostFixtureText(length: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < length) {
        builder.append("x")
        index += 1
    }
    return builder.toString()
}

// Cost evidence for the normal rule consumer: offers stay immutable and
// bounded at the domain's own field limits, while an unchanged live window
// does not rebuild layout or business projection for repeated observations.
@Test
func composableRuleTransferCostIsBoundedAcrossPayloadSizesAndIdleRepeats(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman(transferCostFixtureText(8), true, 9, transferCostFixtureText(8),
        "transfer-cost-small").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    var smallBytes: Int64 = -1
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) {
        smallBytes = offer.payloadByteCount
        @Assert(offer.format.maximumBytes, 16 * 1024)
    } else {
        @Assert(false, true)
    }

    let medium = domain.executeFromExternal(
        CjguiRuleSetInvocationFactory.create(domain.snapshot().version, transferCostFixtureText(64), true, 45,
            transferCostFixtureText(64), "transfer-cost-medium"))
    @Assert(medium.applied, true)
    @Assert(window.refresh(), true)
    var mediumBytes: Int64 = -1
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) {
        mediumBytes = offer.payloadByteCount
    } else {
        @Assert(false, true)
    }

    let near = domain.executeFromExternal(
        CjguiRuleSetInvocationFactory.create(domain.snapshot().version, transferCostFixtureText(128), true, 90,
            transferCostFixtureText(128), "transfer-cost-near-limit"))
    @Assert(near.applied, true)
    @Assert(window.refresh(), true)
    var nearBytes: Int64 = -1
    if (let Some(offer) <- controller.offerSelectedRecordTransfer()) {
        nearBytes = offer.payloadByteCount
    } else {
        @Assert(false, true)
    }
    @Assert(smallBytes > 0, true)
    @Assert(smallBytes < mediumBytes, true)
    @Assert(mediumBytes < nearBytes, true)

    let before = window.windowProjection()
    let started = MonoTime.now()
    var repeats: Int64 = 0
    while (repeats < 128) {
        @Assert(window.refreshIfNeeded(), true)
        repeats += 1
    }
    let elapsedMs = (MonoTime.now() - started).toMilliseconds()
    let after = window.windowProjection()
    @Assert(after.buildPassCount, before.buildPassCount)
    @Assert(after.layoutPassCount, before.layoutPassCount)
    @Assert(after.nativeSubmissionCount, before.nativeSubmissionCount)
    getStdOut().writeln(
        "CJGUI_RULE_TRANSFER_COST sizes=${smallBytes},${mediumBytes},${nearBytes} repeats=${repeats} " +
        "idle_build_delta=${after.buildPassCount - before.buildPassCount} " +
        "idle_layout_delta=${after.layoutPassCount - before.layoutPassCount} " +
        "idle_submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount} " +
        "elapsed_ms=${elapsedMs} passed=true")
    getStdOut().flush()
    window.close()
}

// The public shared-operation route may add a run of records while the
// window remains open. Each accepted owner version must reach the same list
// projection as a local action; a stale scene is not an acceptable fallback.
@Test
func externalRuleFixtureProjectsEveryVisibleListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    var index: Int64 = 1
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "外部滚动验证规则 ${index}", true, 7,
                "cache", "external-scroll-${index}"))
        @Assert(created.applied, true)
        @Assert(window.refresh(), true)
        let progress = window.windowProjection()
        @Assert(progress.pendingRefreshReason, "none")
        @Assert(progress.lastNativeFailure, "none")
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    assertRuleSetProjectionIdentity(window.windowProjection())
    window.close()
}

// The normal host drains multiple already-accepted external actions in one
// turn, then requests one projection refresh. Keep that coalesced path
// distinct from the per-action case above: virtual-list materialization must
// converge from one visible row to a populated viewport in a single commit.
@Test
func batchedExternalRuleFixtureProjectsCoalescedListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    var index: Int64 = 1
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "批量滚动验证规则 ${index}", true, 7,
                "cache", "batched-scroll-${index}"))
        @Assert(created.applied, true)
        if (index == 1) {
            @Assert(window.refresh(), true)
        }
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    @Assert(window.refresh(), true)
    let progress = window.windowProjection()
    @Assert(progress.pendingRefreshReason, "none")
    @Assert(progress.lastNativeFailure, "none")
    assertRuleSetProjectionIdentity(progress)
    window.close()
}

// A local first create leaves controller-local presentation revision state;
// subsequent externally authored records are still coalesced by the normal
// host. This is the exact mixed-owner sequence exercised by a real button
// followed by a public fixture load.
@Test
func localFirstCreateThenBatchedExternalFixtureProjectsListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(), CjguiComposableUiRect(0, 0, 980, 620),
        1)
    let localCreated = controller.applyUiEvent(
        CjguiComposableUiEvent(initialScene.nodeForId(10), 27, "", 0, 0, initialScene.version))
    @Assert(localCreated.didApply, true)
    @Assert(window.refresh(), true)
    var index: Int64 = 2
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "混合滚动验证规则 ${index}", true, 7,
                "cache", "mixed-scroll-${index}"))
        @Assert(created.applied, true)
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    @Assert(window.refresh(), true)
    let progress = window.windowProjection()
    @Assert(progress.pendingRefreshReason, "none")
    @Assert(progress.lastNativeFailure, "none")
    assertRuleSetProjectionIdentity(progress)
    window.close()
}

private func runRuleSetApp(startup: CjguiRuleSetStartupFiles): Int32 {
    let domain = CjguiRuleSetEditingDomain.newWithRetentionRange(minimum: startup.retentionMinimum,
        maximum: startup.retentionMaximum)
    if (startup.openPath.size > 0 && !domain.openFromHuman(startup.openPath).applied) {
        getStdErr().writeln("rule set: cannot open requested file");
        CjguiMacosApplicationHost.stopApplicationLoop();
        return 2
    }
    if (startup.saveAsPath.size > 0 && !domain.saveAsFromHuman(startup.saveAsPath).applied) {
        getStdErr().writeln("rule set: cannot save requested file");
        CjguiMacosApplicationHost.stopApplicationLoop();
        return 2
    }
    let controller = CjguiRuleSetComposableController(domain,
        presetOverride: startup.retentionPreset)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 规则集编辑器", 980u32, 620u32)
    )
    let window = host.window()
    // Keyboard navigation inside the tree keeps the native focus on the row the
    // tree model focused; the panel needs the window to resolve that row's
    // scoped identity.
    controller.treeSelectionProvider().attachWindow(window)
    // The generated-instance projection needs the same accepted window its
    // identities live in, so an external caller can address them by declared key.
    controller.generatedUiRegion().attachWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableTargetedContextReads(domain) || !connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !connection.enableTreeSelectionProvider(controller.treeSelectionProvider()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close();
        return 1
    }
    if (startup.verifiesHostCloseDecisions) {
        // A window that really HOLDS a shared-catalog image identity, accepted
        // through the same public structure channel an external client uses. The
        // close path below must release it; a zero-hold window would prove
        // nothing.
        let closeProbeRegion = controller.generatedUiRegion()
        let closeProbeStructure = "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
            "NODE 1 beacon image\nPROPERTY 1 beacon resource rule-set-beacon\n" +
            "PROPERTY 1 beacon resourceVersion 1\nEND"
        if (!closeProbeRegion.submitStructure(closeProbeStructure,
            closeProbeRegion.acceptedStructureVersion()).candidateAccepted ||
            !closeProbeRegion.beginSceneRefresh()) {
            host.close()
            return 1
        }
        let _ = closeProbeRegion.buildSection(CjguiComposableUiTheme.beaconDark(),
            CjguiComposableUiStyle(fontSize: 13.0))
        if (!closeProbeRegion.prepareSceneRefresh()) {
            host.close()
            return 1
        }
        closeProbeRegion.commitSceneRefresh()
        getStdOut().writeln(
            "CJGUI_RULE_SET_HOST_PROBE image_holds_before_close=${closeProbeRegion.liveImageIdentityHoldCount()}")
        getStdOut().flush()
        if (!domain.createCollectionItemFromHuman().applied) {
            host.close();
            return 1
        }
        window.requestRefresh()
        // The real controller/domain rejects the first close while data is unsaved.
        if (host.requestClose() || !host.isOpen()) {
            host.close();
            return 1
        }
        if (!domain.discardUnsavedContentFromHuman().applied) {
            host.close();
            return 1
        }
        window.requestRefresh()
        // It then accepts the same Host close decision and cleans its endpoint.
        if (!host.requestClose() || host.isOpen()) {
            host.close();
            return 1
        }
        if (let Some(_) <- connection.connectionInfo()) {
            host.close();
            return 1
        }
        host.close()
        getStdOut().writeln("CJGUI_RULE_SET_HOST_PROBE rejected_then_accepted_close_cleaned")
        return 0
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_RULE_SET_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_RULE_SET_READY PROTOCOL ${info.protocol}")
        let projection = window.windowProjection()
        if (!projection.isActive || projection.sessionIdentity.size == 0 || projection.submittedFrameIndex <= 0) {
            output.flush();
            host.close();
            return 1
        }
        output.writeln(
            "CJGUI_RULE_SET_READY WINDOW_READY ${projection.sessionIdentity} ${projection.submittedFrameIndex}")
        output.flush()
    }
    let warmupStarted = MonoTime.now()
    while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < startup.measurementWarmupMs) {
        let _ = host.pumpOneTurn()
    }
    if (host.isOpen()) {
        let output = getStdOut();
        let projection = window.windowProjection()
        output.writeln("CJGUI_RULE_SET_READY MEASUREMENT_START ${projection.sessionIdentity}");
        output.flush()
    }
    let measurementStarted = MonoTime.now()
    while (host.isOpen() && (startup.measurementDurationMs <= 0 ||
            (MonoTime.now() - measurementStarted).toMilliseconds() < startup.measurementDurationMs)) {
        let _ = host.pumpOneTurn()
    }
    getStdOut().writeln("CJGUI_RULE_TRANSFER_METRICS ${controller.transferMetricsSummary()}")
    getStdOut().flush()
    host.close();
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--verify-transfer-cost") {
        return Int64(runTransferCostProbe())
    }
    if (let Some(startup) <- parseStartupFiles(args)) {
        return Int64(runRuleSetApp(startup))
    }
    getStdErr().writeln(
        "usage: CJGUIRuleSet [--open PATH] [--save-as PATH] [--verify-host-close-decisions] [--retention-range MIN MAX] [--retention-preset VALUE] [--measurement-warmup-ms 0..60000] [--measurement-duration-ms 1..900000]")
    CjguiMacosApplicationHost.stopApplicationLoop()
    return 2
}


// --- tree keyboard navigation (window/controller event path) -------------

/// A virtual-list placeholder source: the controller only resolves the event by
/// the accepted node identity, so this keeps the node kind realistic
/// (SCROLL_AREA) without depending on the panel's private list source.
class TreeNavigationTestSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 0 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem.missing()
    }
    public func indexForKey(key: String): Int64 { return -1 }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
                         isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(1, "test-row", "", CjguiComposableUiStyle())
    }
}

func treeListEventNode(): CjguiComposableUiLayoutNode {
    let bounds = CjguiComposableUiRect(0, 0, 300, 240)
    return CjguiComposableUiLayoutNode(
        cjguiComposableVirtualList(700007, "rule-tree-list", 700008,
            TreeNavigationTestSource(), CjguiComposableUiVirtualListState(), 30, 4, 6,
            CjguiComposableUiStyle(fixedHeight: 240)),
        bounds, bounds)
}

func createNavigationTestRule(domain: CjguiRuleSetEditingDomain, label: String, enabled: Bool, requestId: String): Unit {
    let result = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        domain.snapshot().version, label, enabled, 7, "cache", requestId))
    if (!result.applied) {
        throw IllegalArgumentException("rule create failed: ${result.reason}")
    }
}

@Test
func treeKeyboardNavigationFollowsVisibleOrderAndScene(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    createNavigationTestRule(domain, "导航甲", true, "nav-1")
    createNavigationTestRule(domain, "导航乙", false, "nav-2")
    createNavigationTestRule(domain, "导航丙", false, "nav-3")
    let panel = controller.treeSelectionProvider()
    // Expand both groups through the same shared entry a human click reaches.
    let _ = panel.applySelection("expand", "group-enabled", panel.selectionVersion())
    let _ = panel.applySelection("expand", "group-disabled", panel.selectionVersion())
    @Assert(window.refresh(), true)
    let before = window.windowProjection()
    @Assert(before.lastNativeFailure, "none")
    let listNode = treeListEventNode()

    // Down from no focus lands on the first visible row; the next Down moves one
    // row in visible order (group -> its first leaf).
    let firstMove = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "down", 0, 0,
        controller.uiSceneVersion()))
    @Assert(firstMove.didApply, true)
    @Assert(panel.selection.focus(), "group-enabled")
    let secondMove = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "down", 0, 0,
        controller.uiSceneVersion()))
    @Assert(secondMove.didApply, true)
    @Assert(panel.selection.focus(), "record-1")
    // Moving focus alone never selects: the range only grows with the Shift
    // payload, exactly like a modifier click.
    @Assert(panel.selection.selectedCount(), 0)

    // Shift payload: the first extension anchors at the focused row, so
    // Shift+Down selects the focused row plus the traversed selectable rows.
    let shiftDown = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "down", 0, 0,
        controller.uiSceneVersion(), modifierFlags: CJGUI_UI_MODIFIER_SHIFT))
    @Assert(shiftDown.didApply, true)
    @Assert(panel.selection.anchor(), "record-1")
    @Assert(panel.selection.selectedCount(), 1)
    @Assert(panel.selection.isSelected("record-1"), true)
    // The anchor survives the next extension: Shift+End reaches the last row.
    let shiftEnd = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "end", 0, 0,
        controller.uiSceneVersion(), modifierFlags: CJGUI_UI_MODIFIER_SHIFT))
    @Assert(shiftEnd.didApply, true)
    @Assert(panel.selection.anchor(), "record-1")
    @Assert(panel.selection.focus(), "record-3")
    @Assert(panel.selection.selectedCount(), 3)
    @Assert(panel.selection.isSelected("record-2"), true)
    @Assert(panel.selection.isSelected("record-3"), true)

    // Command-A over the tree scope selects every selectable visible row
    // (groups stay focusable but unselectable).
    let selectAll = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "select_all", 0, 0,
        controller.uiSceneVersion()))
    @Assert(selectAll.didApply, true)
    @Assert(panel.selection.selectedCount(), 3)

    // Left ascends to the visible group; the panel revision advances so the
    // window repaints, and the accepted scene follows the navigation.
    let revisionBefore = panel.viewRevision()
    let left = controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "left", 0, 0,
        controller.uiSceneVersion()))
    @Assert(left.didApply, true)
    @Assert(panel.selection.focus(), "group-disabled")
    @Assert(panel.viewRevision() > revisionBefore, true)
    let _ = window.refreshIfNeeded()
    let after = window.windowProjection()
    @Assert(after.pendingRefreshReason, "none")
    @Assert(after.lastNativeFailure, "none")
    @Assert(after.acceptedSceneVersion >= before.acceptedSceneVersion, true)
    window.close()
}

@Test
func treeNavigationIsRejectedOutsideItsListNode(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let panel = controller.treeSelectionProvider()
    let bounds = CjguiComposableUiRect(0, 0, 300, 240)
    // The tree *section* container carries a different node id: the same
    // command must not move focus or touch the panel revision.
    let sectionNode = CjguiComposableUiLayoutNode(
        cjguiComposableVertical(700000, "rule-tree-section", CjguiComposableUiStyle()),
        bounds, bounds)
    let revisionBefore = panel.viewRevision()
    let _ = controller.applyUiEvent(CjguiComposableUiEvent(sectionNode, 35, "select_all", 0, 0,
        controller.uiSceneVersion()))
    @Assert(panel.viewRevision(), revisionBefore)
    @Assert(panel.selection.selectedCount(), 0)
    @Assert(panel.selection.focus(), "")
    window.close()
}

// --- generated region: window-level transaction and editing continuation ---
//
// The generated structure is submitted through the public provider, but it only
// becomes the accepted interface when the window's own scene transaction
// accepts it. These tests drive that transaction through the real window, then
// address the accepted editor exactly as a delivered input event would.

private let GENERATED_WINDOW_S1: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 greeting label
PROPERTY 1 greeting text 生成续写面板
NODE 1 nameField textInput field=label
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
END
"""

// The same stable key in a new position: identity continuation is asserted for
// an unchanged key, never for a renamed one.
private let GENERATED_WINDOW_S2: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 horizontal
NODE 1 applyBtn2 action action=APPLY_DRAFT
PROPERTY 1 applyBtn2 label 先放按钮
NODE 1 nameField textInput field=label
END
"""

// A changed key is a different object: it must get its own identity instead of
// inheriting the previous editor's.
private let GENERATED_WINDOW_S2B: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel2b horizontal
NODE 1 nameFieldRenamed textInput field=label
END
"""

private let GENERATED_WINDOW_S3: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel3 vertical
NODE 1 hint label
PROPERTY 1 hint text 编辑器已移除
END
"""

private func generatedEditorNode(nodeId: Int64, target: Int64): CjguiComposableUiLayoutNode {
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    return CjguiComposableUiLayoutNode(
        cjguiComposableTextInput(nodeId, "generated-nameField", "规则名称", "",
            CjguiRuleSetEditingDomain.formLabelResourceId, CjguiComposableUiStyle(fixedHeight: 26),
            fieldId: "label", operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: target,
            displayValueRole: "draft"),
        bounds, bounds)
}

@Test
func generatedRegionWindowTransactionKeepsAcceptedEditor(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("生成续写", true, 7, "cache", "gen-window-create").applied, true)
    let recordId = domain.selectedRecordId()
    @Assert(recordId >= 0, true)
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedUiRegion()

    // S1: candidate received, then scene-accepted by the window transaction.
    @Assert(region.submitStructure(GENERATED_WINDOW_S1, 0).candidateAccepted, true)
    @Assert(region.acceptedStructureVersion(), 0)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let nodeIdS1 = region.acceptedNodeIdForKey("nameField")
    @Assert(nodeIdS1 > 0, true)

    // S2 re-orders the same key: the accepted identity must survive.
    @Assert(region.submitStructure(GENERATED_WINDOW_S2, 1).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedNodeIdForKey("nameField"), nodeIdS1)

    // A candidate built against the now-obsolete version changes nothing.
    let stale = region.submitStructure(GENERATED_WINDOW_S2, 1)
    @Assert(stale.accepted, false)
    @Assert(stale.reason, "structure_version_conflict")
    @Assert(region.acceptedStructureVersion(), 2)

    // The accepted editor still writes the record it was rendered for.
    let editor = generatedEditorNode(nodeIdS1, recordId)
    @Assert(region.handleEvent(CjguiComposableUiEvent(editor, 28, "窗口续写", 0, 0, 2)).didApply, true)
    let labelField = domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId)
    @Assert(labelField.draftText, "窗口续写")

    // A renamed key is a new identity, not a continuation of the old editor,
    // and the removed key's old identity must not write the owner either.
    @Assert(region.submitStructure(GENERATED_WINDOW_S2B, 2).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 3)
    let renamedId = region.acceptedNodeIdForKey("nameFieldRenamed")
    @Assert(renamedId > 0, true)
    @Assert(renamedId != nodeIdS1, true)
    @Assert(region.acceptedNodeIdForKey("nameField"), -1)
    @Assert(region.handleEvent(CjguiComposableUiEvent(editor, 28, "不应写入", 0, 0, 3)).didApply, false)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "窗口续写")

    // S3 removes the key. After acceptance the old node identity no longer
    // resolves, and a queued input for it must not write the owner.
    @Assert(region.submitStructure(GENERATED_WINDOW_S3, 3).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 4)
    @Assert(region.acceptedNodeIdForKey("nameFieldRenamed"), -1)
    let renamedEditor = generatedEditorNode(renamedId, recordId)
    @Assert(region.handleEvent(CjguiComposableUiEvent(renamedEditor, 28, "不应写入2", 0, 0, 4)).didApply, false)
    window.close()
}

// --- generated editor: draft/focus/caret continuation across a reorder ------
//
// A same-key reorder must keep the editing state the owner holds for that
// field (draft text, caret/selection, active field) and the human must be able
// to keep typing into the re-accepted editor. The state is read back through
// the same public field projection an external reader uses.

private let EDITOR_STATE_S1: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 nameField textInput field=label
END
"""

private let EDITOR_STATE_S2: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 horizontal
NODE 1 applyBtn action action=APPLY_DRAFT
PROPERTY 1 applyBtn label 应用草稿
NODE 1 nameField textInput field=label
END
"""

private func labelFieldState(domain: CjguiRuleSetEditingDomain): CjguiSharedFormFieldProjection {
    return domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId)
}

private func hexFieldValue(payload: String, field: String, tag: String): String {
    let line = payload.split("\n")
    for (row in line) {
        if (row.startsWith("FIELD ${field} ")) {
            let parts = row.split(" ")
            var index = 0
            while (index < parts.size) {
                if (parts[index] == tag && index + 1 < parts.size) {
                    return parts[index + 1]
                }
                index += 1
            }
        }
    }
    return ""
}

@Test
func generatedEditorKeepsDraftFocusAndSelectionAcrossReorder(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("编辑接续", true, 7, "cache", "editor-state-create").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedUiRegion()

    @Assert(region.submitStructure(EDITOR_STATE_S1, 0).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let nodeId = region.acceptedNodeIdForKey("nameField")
    @Assert(nodeId > 0, true)

    // The accepted editor receives a draft with a caret position.
    let firstEdit = generatedEditorNode(nodeId, recordId)
    @Assert(region.handleEvent(CjguiComposableUiEvent(firstEdit, 28, "草稿甲", 2, 2, 1)).didApply, true)
    let afterFirst = labelFieldState(domain)
    @Assert(afterFirst.draftText, "草稿甲")
    @Assert(afterFirst.selectionStart, 2)
    @Assert(afterFirst.selectionEnd, 2)
    @Assert(afterFirst.isFocused, true)

    // Same key, new position: the owner keeps draft, caret and active field,
    // and the accepted editor keeps its identity.
    @Assert(region.submitStructure(EDITOR_STATE_S2, 1).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedNodeIdForKey("nameField"), nodeId)
    let afterReorder = labelFieldState(domain)
    @Assert(afterReorder.draftText, "草稿甲")
    @Assert(afterReorder.selectionStart, 2)
    @Assert(afterReorder.selectionEnd, 2)
    @Assert(afterReorder.isFocused, true)

    // Public readback agrees with the owner state.
    let payload = region.fieldsPayload()
    @Assert(hexFieldValue(payload, "label", "DRAFT_HEX"), "E88D89E7A8BFE794B2")
    @Assert(hexFieldValue(payload, "label", "FOCUS"), "1")

    // The human keeps typing into the re-accepted editor.
    let continuedEdit = generatedEditorNode(nodeId, recordId)
    @Assert(region.handleEvent(CjguiComposableUiEvent(continuedEdit, 28, "草稿甲乙", 4, 4, 2)).didApply, true)
    let afterContinue = labelFieldState(domain)
    @Assert(afterContinue.draftText, "草稿甲乙")
    @Assert(afterContinue.selectionStart, 4)
    @Assert(afterContinue.selectionEnd, 4)
    @Assert(hexFieldValue(region.fieldsPayload(), "label", "DRAFT_HEX"), "E88D89E7A8BFE794B2E4B999")
    window.close()
}

// --- generated integer editor: numeric transient stays a draft --------------
//
// A partially typed number is a legal transient draft: it must be kept as the
// draft, must not change the applied value, and must be refused at apply time
// with the draft preserved. Once the input is a valid number the ordinary
// apply path writes it. No new input-method machinery is involved.

private let TRANSIENT_STRUCTURE: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionField integerInput field=retentionCount
END
"""

private func retentionField(domain: CjguiRuleSetEditingDomain): CjguiSharedFormFieldProjection {
    return domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId)
}

@Test
func generatedIntegerEditorKeepsNumericTransientAsDraft(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("数字暂态", true, 7, "cache", "transient-create").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(TRANSIENT_STRUCTURE, 0).candidateAccepted, true)
    @Assert(window.refresh(), true)
    let nodeId = region.acceptedNodeIdForKey("retentionField")
    @Assert(nodeId > 0, true)
    let bounds = CjguiComposableUiRect(0, 0, 160, 24)
    let editor = CjguiComposableUiLayoutNode(
        cjguiComposableIntegerInput(nodeId, "generated-retentionField", "保留天数", "",
            CjguiRuleSetEditingDomain.formRetentionResourceId, CjguiComposableUiStyle(fixedHeight: 24),
            fieldId: "retentionCount", operationActionName: "EDIT_DRAFT_TEXT",
            operationResourceId: recordId, displayValueRole: "draft"),
        bounds, bounds)

    // A partially typed number: the draft holds exactly what was typed and the
    // applied value is untouched.
    @Assert(region.handleEvent(CjguiComposableUiEvent(editor, 28, "12a", 3, 3, 1)).didApply, true)
    @Assert(retentionField(domain).draftText, "12a")
    @Assert(retentionField(domain).appliedValue.integerValue, 7)
    // Applying the transient is refused; the draft survives.
    let refused = region.executeAction("APPLY_DRAFT", "")
    @Assert(refused.applied, false)
    @Assert(retentionField(domain).draftText, "12a")
    @Assert(retentionField(domain).appliedValue.integerValue, 7)

    // Completing the number applies normally.
    @Assert(region.handleEvent(CjguiComposableUiEvent(editor, 28, "12", 2, 2, 2)).didApply, true)
    @Assert(retentionField(domain).draftText, "12")
    let applied = region.executeAction("APPLY_DRAFT", "")
    @Assert(applied.applied, true)
    @Assert(retentionField(domain).appliedValue.integerValue, 12)
    @Assert(retentionField(domain).draftText, "12")
    window.close()
}

/// The external field query must expose every field of the application's single
/// shared form definition - not a subset. A missing field here would make the
/// generated capability payload look complete while an external caller silently
/// loses a business field (the window's own "enabled" projection is the case
/// that exposed it).
@Test
func generatedRegionPublishesEveryBindingField(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let payload = controller.generatedUiRegion().fieldsPayload()
    for (fieldId in ["label", "enabled", "retentionCount", "excludedType"]) {
        @Assert(payload.contains("FIELD ${fieldId} "), true)
    }
    @Assert(payload.contains("END"), true)
}

/// The external capability description publishes what an outside caller needs
/// to use a field: business type, shared resource, declared constraints, the
/// owner operation that performs a write and whether that write is callable.
/// It is derived from the same binding the handwritten form and the generated
/// editor use, including the retention boundary declared by the domain.
@Test
func generatedCapabilitiesPublishFieldContracts(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let payload = controller.generatedUiRegion().capabilitiesPayload()
    @Assert(payload.contains("FIELD retentionCount INTEGER resource=81003 " +
        "writer=EDIT_DRAFT_TEXT required=0 min=1 max=90 maxlen=0 callable=1"), true)
    @Assert(payload.contains("FIELD enabled BOOLEAN resource=81002 writer=EDIT_DRAFT_BOOLEAN"), true)
    @Assert(payload.contains("FIELD label TEXT resource=81001 writer=EDIT_DRAFT_TEXT"), true)
    @Assert(payload.contains("FIELD excludedType TEXT resource=81004"), true)
    @Assert(payload.contains("ACTION APPLY_DRAFT"), true)
}

/// A deployment that declares a different retention boundary publishes exactly
/// that boundary: the description is derived, not restated.
@Test
func generatedCapabilitiesFollowTheDeclaredRetentionBoundary(): Unit {
    let domain = CjguiRuleSetEditingDomain.newWithRetentionRange(minimum: 365, maximum: 730)
    let controller = CjguiRuleSetComposableController(domain)
    let payload = controller.generatedUiRegion().capabilitiesPayload()
    @Assert(payload.contains("FIELD retentionCount INTEGER resource=81003 " +
        "writer=EDIT_DRAFT_TEXT required=0 min=365 max=730 maxlen=0 callable=1"), true)
}

// --- B1: the shared retention integer-edit composite -------------------------

private let RETENTION_COMPOSITE_S1: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionEdit retentionIntegerEdit
END
"""

/// Node identity plus the business-facing attributes only: ids allocated by the
/// framework or the consumer are deliberately excluded, which is exactly the
/// difference between the two presentations.
private func compositeShapeOf(node: CjguiComposableUiNode, intoLines: ArrayList<String>): Unit {
    intoLines.add("${node.nodeKind}|${node.label}|${node.fieldId}|${node.operationActionName}|${node.actionName}")
    for (child in node.children()) {
        compositeShapeOf(child, intoLines)
    }
}

private func findNodeBySemanticId(node: CjguiComposableUiNode, semanticId: String): ?CjguiComposableUiNode {
    if (node.semanticId == semanticId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- findNodeBySemanticId(child, semanticId)) {
            return found
        }
    }
    return None
}

private func findNodeById(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- findNodeById(child, nodeId)) {
            return found
        }
    }
    return None
}

/// The preset is the ONE configuration: a normal launch derives it from the
/// field's own declared bounds (never a copied business limit), while a
/// dedicated negative control may declare an explicit out-of-range value.
@Test
func retentionCompositePresetComesFromTheDeclaredBounds(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let region = CjguiRuleSetGeneratedRegion(domain)
    @Assert(region.retentionPreset().value, "${CjguiRuleSetEditingDomain.defaultRetentionMaximum}")
    let wide = CjguiRuleSetEditingDomain.newWithRetentionRange(minimum: 365, maximum: 730)
    let wideRegion = CjguiRuleSetGeneratedRegion(wide)
    @Assert(wideRegion.retentionPreset().value, "730")
    let override = CjguiRuleSetGeneratedRegion(domain, presetOverride: "200")
    @Assert(override.retentionPreset().value, "200")
    @Assert(override.retentionPreset().label.contains("200"), true)
}

/// The handwritten dialog presents the composite through the ONE build
/// implementation: its retention row is byte-for-byte the same node shape
/// `buildEditor` produces for the same declared inputs, and the generated region
/// resolves the same field/preset elements for that kind.
@Test
func retentionCompositeHandwrittenAndGeneratedShareOneShape(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("组合复用", true, 30, "shared", "composite-share").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)

    // Generated side: the app's generated region accepts the composite kind and
    // resolves its field + preset elements.
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.acceptedNodeIdForKey("retentionEdit") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("retentionEdit", "edit") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("retentionEdit", "preset") > 0, true)

    // Handwritten side: open the edit dialog and take the retention row.
    let scene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(),
        CjguiComposableUiRect(0, 0, 980, 620), 1)
    let openButton = scene.nodeForId(29)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(openButton,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, scene.version)).didApply, true)
    let handwrittenTree = controller.buildUi()
    let handwrittenRow = findNodeBySemanticId(handwrittenTree, "dialog-field-group-retentionCount") ??
        cjguiComposableVertical(-1, "missing-retention-row", CjguiComposableUiStyle())
    @Assert(handwrittenRow.semanticId, "dialog-field-group-retentionCount")
    let handwrittenShape = ArrayList<String>()
    compositeShapeOf(handwrittenRow, handwrittenShape)

    // The same implementation, called directly with the same declared inputs.
    let form = domain.formSnapshot()
    let field = form.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId)
    var descriptorLabel = "保留天数"
    for (descriptor in domain.formBinding().allFields()) {
        if (descriptor.fieldId == "retentionCount") {
            descriptorLabel = descriptor.label
        }
    }
    let directBuild = CjguiRetentionIntegerEditComposite.buildEditor(1, "direct-row", 2, 3,
        descriptorLabel, field.draftText, "retentionCount", "EDIT_DRAFT_TEXT",
        CjguiRuleSetEditingDomain.formRetentionResourceId, recordId,
        region.retentionPreset().label)
    let directShape = ArrayList<String>()
    compositeShapeOf(directBuild, directShape)
    @Assert(handwrittenShape.size, directShape.size)
    var index: Int64 = 0
    while (index < handwrittenShape.size) {
        @Assert(handwrittenShape[index], directShape[index])
        index += 1
    }
    // The shape really is input + preset, not a plain editor.
    @Assert(handwrittenShape.size >= 3, true)
    // shape[0] is the row container, [1] the shared integer input and [2] the
    // configured preset button.
    @Assert(handwrittenShape[1].contains("|retentionCount|EDIT_DRAFT_TEXT|"), true)
    @Assert(handwrittenShape[2].contains("|${CjguiRetentionIntegerEditComposite.PRESET_ACTION}"), true)
    window.close()
}

/// A generated preset activation becomes a field edit carrying the CONFIGURED
/// constant, and the owner's rule (not the widget) decides legality: an
/// out-of-range preset reaches the draft unchanged and is refused at apply.
@Test
func compositePresetWritesConfiguredValueAndOwnerRefusesOutOfRange(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("预设写入", true, 30, "preset", "composite-preset").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    @Assert(window.refresh(), true)
    let presetNodeId = region.acceptedCompositeElementNodeId("retentionEdit", "preset")
    @Assert(presetNodeId > 0, true)
    let presetValue = region.retentionPreset().value
    @Assert(presetValue, "${CjguiRuleSetEditingDomain.defaultRetentionMaximum}")

    // The preset control must carry the RESOLVED writer/owner target, exactly as
    // the shared builder does; the adapter verifies the event node against the
    // accepted binding.
    let presetBinding = match (region.acceptedCompositeElement("retentionEdit", "preset")) {
        case Some(value) => value
        case None => CjguiCompositeElementBinding("preset", CJGUI_COMPOSITE_ELEMENT_PRESET, -1, "", "")
    }
    let presetNode = CjguiComposableUiLayoutNode(
        cjguiComposableButton(presetNodeId, "retention-preset",
            region.retentionPreset().label, CjguiRetentionIntegerEditComposite.PRESET_ACTION,
            presetBinding.bindingResourceId, CjguiComposableUiStyle(),
            operationActionName: presetBinding.writerOperation,
            operationResourceId: presetBinding.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 120, 26), CjguiComposableUiRect(0, 0, 120, 26))
    @Assert(region.handleEvent(CjguiComposableUiEvent(presetNode,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1)).didApply, true)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, presetValue)
    // 90 is legal in 1..90: the owner applies it through the ordinary rule.
    let applied = domain.applyDraftForCollectionItemFromHuman(recordId,
        domain.draftVersionForCollectionItem(recordId), domain.baseAppliedVersionForCollectionItem(recordId))
    @Assert(applied.applied, true)
    window.close()

    // Negative control: the same composite with an explicitly out-of-range preset
    // must hand 200 to the owner (no clamping here) and the owner refuses it.
    let outOfRangeDomain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(outOfRangeDomain.createRecordFromHuman("越界预设", true, 30, "x", "composite-preset-oor").applied, true)
    let outOfRangeRecord = outOfRangeDomain.selectedRecordId()
    let outOfRangeRegion = CjguiRuleSetGeneratedRegion(outOfRangeDomain, presetOverride: "200")
    @Assert(outOfRangeRegion.retentionPreset().value, "200")
    let outOfRangeController = CjguiRuleSetComposableController(outOfRangeDomain, presetOverride: "200")
    let outOfRangeWindow = CjguiComposableUiWindow(outOfRangeController)
    @Assert(outOfRangeWindow.start(), true)
    let outOfRangeLive = outOfRangeController.generatedUiRegion()
    @Assert(outOfRangeLive.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    @Assert(outOfRangeWindow.refresh(), true)
    let outOfRangePresetId = outOfRangeLive.acceptedCompositeElementNodeId("retentionEdit", "preset")
    @Assert(outOfRangePresetId > 0, true)
    let outOfRangeBinding = match (outOfRangeLive.acceptedCompositeElement("retentionEdit", "preset")) {
        case Some(value) => value
        case None => CjguiCompositeElementBinding("preset", CJGUI_COMPOSITE_ELEMENT_PRESET, -1, "", "")
    }
    let outOfRangeNode = CjguiComposableUiLayoutNode(
        cjguiComposableButton(outOfRangePresetId, "retention-preset", "设为 200",
            CjguiRetentionIntegerEditComposite.PRESET_ACTION,
            outOfRangeBinding.bindingResourceId, CjguiComposableUiStyle(),
            operationActionName: outOfRangeBinding.writerOperation,
            operationResourceId: outOfRangeBinding.ownerTargetResourceId),
        CjguiComposableUiRect(0, 0, 120, 26), CjguiComposableUiRect(0, 0, 120, 26))
    @Assert(outOfRangeLive.handleEvent(CjguiComposableUiEvent(outOfRangeNode,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1)).didApply, true)
    // The declared constant reached the draft unchanged - no silent clamp.
    @Assert(outOfRangeDomain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "200")
    let refused = outOfRangeDomain.applyDraftForCollectionItemFromHuman(outOfRangeRecord,
        outOfRangeDomain.draftVersionForCollectionItem(outOfRangeRecord),
        outOfRangeDomain.baseAppliedVersionForCollectionItem(outOfRangeRecord))
    @Assert(refused.applied, false)
    @Assert(outOfRangeDomain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).validationError, "retention_count_out_of_range")
    outOfRangeWindow.close()
}

/// The handwritten preset button goes through the same owner draft entry the
/// typed edit uses, reading the same one configuration.
@Test
func handwrittenCompositePresetWritesTheOwnerDraft(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("手写预设", true, 30, "hand", "composite-hand-preset").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let scene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(),
        CjguiComposableUiRect(0, 0, 980, 620), 1)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(scene.nodeForId(29),
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, scene.version)).didApply, true)
    let tree = controller.buildUi()
    let presetRow = findNodeBySemanticId(tree, "dialog-field-group-retentionCount") ??
        cjguiComposableVertical(-1, "missing-retention-row", CjguiComposableUiStyle())
    @Assert(presetRow.semanticId, "dialog-field-group-retentionCount")
    // The row's preset button is the one built by the shared composite.
    let button = findPresetButton(presetRow) ??
        cjguiComposableButton(-1, "missing-preset", "", "", -1, CjguiComposableUiStyle())
    @Assert(button.actionName, CjguiRetentionIntegerEditComposite.PRESET_ACTION)
    let layout = CjguiComposableUiLayoutNode(button, CjguiComposableUiRect(0, 0, 120, 26),
        CjguiComposableUiRect(0, 0, 120, 26))
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(layout,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1)).didApply, true)
    let presetValue = controller.generatedUiRegion().retentionPreset().value
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, presetValue)
    window.close()
}

private func findPresetButton(node: CjguiComposableUiNode): ?CjguiComposableUiNode {
    if (node.actionName == CjguiRetentionIntegerEditComposite.PRESET_ACTION) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- findPresetButton(child)) {
            return found
        }
    }
    return None
}

/// The registered `gap` property really reaches the shared builder: the composite
/// row built for a description that declares a gap uses that gap, and one that
/// declares none uses the builder's own fallback.
@Test
func retentionCompositeAppliesItsDeclaredGap(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("间距", true, 30, "x", "composite-gap").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedUiRegion()

    let declared = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionEdit retentionIntegerEdit
PROPERTY 1 retentionEdit gap 12
PROPERTY 1 retentionEdit presetLabel 间距预设
END"""
    @Assert(region.submitStructure(declared, 0).candidateAccepted, true)
    @Assert(window.refresh(), true)
    let section = region.buildSection(CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
    let rowId = region.acceptedCompositeElementNodeId("retentionEdit", "root")
    @Assert(rowId > 0, true)
    let row = findNodeById(section, rowId) ??
        cjguiComposableVertical(-1, "missing-composite-row", CjguiComposableUiStyle())
    @Assert(row.nodeId, rowId)
    @Assert(row.style.gap, 12)
    window.close()
}
